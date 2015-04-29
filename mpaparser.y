%{

	#include <stdio.h>
	#include <stdarg.h>
	#include <stdlib.h>
	#include <string.h>
	#include <ctype.h>
	#include "hashtable.h"

	#define OUTER_ST 0
	int PROGRAM_ST;

	typedef struct node {
		int to_use;
		int n_op;
		
		char *value;
		char *type;

		struct node **op;
	} Node;

	Node *tree, *merge_nodes[2048];

	extern int yylineno, col, yyleng;
	extern char* yytext;

	hashtable_t* symbol_tables[256];
	int st_pointer, st_size=0;

	Node *new_node(){
		return (Node *) malloc(sizeof(Node));
	}

	void create_outer_st(hashtable_t* h){

		element_t* el = store(h, "boolean", TYPE_T);
		el->flag = CONSTANT_F;
		el->value = BOOLEAN_V;

		el = store(h, "integer", TYPE_T);
		el->flag = CONSTANT_F;
		el->value = INTEGER_V;

		el = store(h, "real", TYPE_T);
		el->flag = CONSTANT_F;
		el->value = REAL_V;

		el = store(h, "false", BOOLEAN_T);
		el->flag = CONSTANT_F;
		el->value = FALSE_V;

		el = store(h, "true", BOOLEAN_T);
		el->flag = CONSTANT_F;
		el->value = TRUE_V;

		el = store(h, "paramcount", FUNCTION_T);
		
		el = store(h, "program", PROGRAM_T);
		
	}

	void create_useless_tables(){
		st_pointer = st_size++;
		symbol_tables[st_pointer] = new_hashtable(256, "Function");
		element_t* el = store(symbol_tables[1], "paramcount", INTEGER_T);
		el->flag = RETURN_F;
	}

	Node *make_node(char *node_type, int to_use, int node_operands, ...){
		Node *prod, **tmp;
		int i, nodes = 0;
		va_list args;

		prod = new_node();
		prod->to_use = to_use;
		prod->type = node_type;

		tmp = merge_nodes;
		va_start(args, node_operands);
		while(node_operands--){
			Node *t = va_arg(args, Node *);

			if(t == NULL)
				continue;
			else if(!t->to_use)
				for(nodes+=t->n_op, i = 0; i < t->n_op; i++)
					*tmp++ = t->op[i];
			else{
				*tmp++ = t;
				nodes++;
			}
		}

		prod->op = (Node **) malloc(nodes * sizeof(Node *));
		memcpy(prod->op, merge_nodes, nodes * sizeof(Node *));
		prod->n_op = nodes;
		va_end(args);

		return prod;
	}

	Node *terminal(char* node_type, char *s){
		Node* p 	= new_node();
		p->type 	= node_type;
		p->value 	= (char *) strdup(s);
		p->to_use 	= 1;
		p->n_op 	= 0;
		p->op 		= NULL;

		if(!strcmp(node_type, "Id")){
			char *s;
			for(s = p->value; *s != '\0'; s++)
				*s = tolower(*s);
		}

		return p;
	}

	void print_data(Node* p){
		if(strcmp(p->type, "Id") == 0)
			printf("Id(%s)\n", p->value);
		else if(strcmp(p->type, "String") == 0)
			printf("String(%s)\n", p->value);
		else if(strcmp(p->type, "IntLit") == 0)
			printf("IntLit(%s)\n", p->value);
		else if(strcmp(p->type, "RealLit") == 0)
			printf("RealLit(%s)\n", p->value);
		else
			printf("%s\n", p->type);
	}

	void print_tree(Node* p, int d){
		int i, o;
		
		for(o = 0; o < d; o++) 
			printf("..");
		
		print_data(p);

		for(i = 0; i < p->n_op; i++)
			print_tree(p->op[i], d+1);
	}

	Node* gen_statlist(Node* p){
		if(p != NULL && p->to_use == 1)
			return p;
		return (p==NULL || p->n_op == 0) ? make_node("StatList", 1, 0) : p;
	}

	int vartype(char* s){
		if(strcmp(s, "integer") == 0)
			return INTEGER_T;
		else if(strcmp(s, "real") == 0)
			return REAL_T;
		else if(strcmp(s, "boolean") == 0)
			return BOOLEAN_T;
	}

	char* type2string(type_t type){
		switch(type){
			case(INTEGER_T):
				return "integer";
			case(REAL_T):
				return "real";
			case(TYPE_T):
				return "type";
			case(PROGRAM_T):
				return "program";
			case(FUNCTION_T):
				return "function";
			case(BOOLEAN_T):
				return "boolean";
			default:
				return "undefined";
		}
	}

	char* flag2string(type_t type){
		switch(type){
			case(CONSTANT_F):
				return "constant";
			case(RETURN_F):
				return "return";
			case(PARAM_F):
				return "param";
			case(VARPARAM_F):
				return "varparam";
			case(NONE_F):
				return "";
			default:
				return "undefined";
		}
	}

	char* value2string(type_t type){
		switch(type){
			case(BOOLEAN_V):
				return "boolean";
			case(INTEGER_V):
				return "integer";
			case(REAL_V):
				return "real";
			case(FALSE_V):
				return "false";
			case(TRUE_V):
				return "true";
			default:
				return "undefined";
		}
	}

	int findFunc(char* s){
		int i;
		if(fetch(symbol_tables[PROGRAM_ST], s) == NULL){
			return -1;
		}
		for(i=PROGRAM_ST+1; i<st_size; i++){
			if(strcmp(symbol_tables[i]->func, s) == 0){
				return i;
			}
		}
		return -1;
	}

	void parse_tree(Node* p){
		int stp_backup, i;
		
		if(p == NULL)
			return;
		
		if(strcmp(p->type, "Program") == 0){
			stp_backup = st_pointer;
			st_pointer = st_size++;
			symbol_tables[st_pointer] = new_hashtable(256, "Program");
			PROGRAM_ST = st_pointer;
			for(i = 0; i < p->n_op; i++)
				parse_tree(p->op[i]);
			st_pointer = stp_backup;
		}else if(strcmp(p->type, "FuncDef") == 0){
			stp_backup = st_pointer;
			st_pointer = st_size++;
			
			symbol_tables[st_pointer] = new_hashtable(256, "Function");
			strcpy(symbol_tables[st_pointer]->func, p->op[0]->value);
			element_t* t = fetch(symbol_tables[OUTER_ST], p->op[p->n_op-3]->value);
			if(t == NULL || t->type != TYPE_T)
				printf("Cannot write values of type <%s>\n", p->op[p->n_op-3]->value);
			else{
				element_t* el = store(symbol_tables[st_pointer], p->op[0]->value, vartype(p->op[p->n_op-3]->value) );
				el->flag = RETURN_F;
				store(symbol_tables[PROGRAM_ST], p->op[0]->value, FUNCTION_T );
			}
			for(i = 0; i < p->n_op; i++)
				parse_tree(p->op[i]);
			st_pointer = stp_backup;

		}else if(strcmp(p->type, "FuncDef2") == 0){
			int h = findFunc(p->op[0]->value);
			stp_backup = st_pointer;
			st_pointer = h;

			for(i = 0; i < p->n_op; i++)
				parse_tree(p->op[i]);
			st_pointer = stp_backup;
		}else if(strcmp(p->type, "FuncDecl") == 0){
			stp_backup = st_pointer;
			st_pointer = st_size++;
			symbol_tables[st_pointer] = new_hashtable(256, "Function");
			strcpy(symbol_tables[st_pointer]->func, p->op[0]->value);

			element_t* t = fetch(symbol_tables[OUTER_ST], p->op[p->n_op-1]->value);
			if(t == NULL || t->type != TYPE_T)
				printf("Cannot write values of type <%s>\n", p->op[p->n_op-1]->value);
			else{
				element_t* el = store(symbol_tables[st_pointer], p->op[0]->value, vartype(p->op[p->n_op-1]->value) );
				el->flag = RETURN_F;
				store(symbol_tables[PROGRAM_ST], p->op[0]->value, FUNCTION_T );
			}
			for(i = 0; i < p->n_op; i++)
				parse_tree(p->op[i]);
			st_pointer = stp_backup;
		}else if(strcmp(p->type, "Params") == 0){
			for(i = 0; i < p->n_op-1; i++){
				element_t* el = store(symbol_tables[st_pointer], p->op[i]->value, vartype(p->op[p->n_op-1]->value) );
				el->flag = PARAM_F;
			}
		}else if(strcmp(p->type, "VarParams") == 0){
			for(i = 0; i < p->n_op-1; i++){
				element_t* el = store(symbol_tables[st_pointer], p->op[i]->value, vartype(p->op[p->n_op-1]->value) );
				el->flag = VARPARAM_F;
			}
		}else if(strcmp(p->type, "VarDecl") == 0){
			for(i = 0; i < p->n_op-1; i++){
				store(symbol_tables[st_pointer], p->op[i]->value, vartype(p->op[p->n_op-1]->value) );
			}
		}else{
			for(i = 0; i < p->n_op; i++){
				parse_tree(p->op[i]);
			}
		}

	}

%}

%union{
	int val;
	char *str;
	struct node *node;
}

%token <str> ID STRING REALLIT INTLIT

%token NOT AND OR MOD DIV
%token ASSIGN NEQ LEQ GEQ
%token IF THEN ELSE BEG END
%token DO REPEAT UNTIL WHILE
%token VAR VAL FORWARD FUNCTION OUTPUT PARAMSTR PROGRAM WRITELN RESERVED

%right THEN
%right ELSE
%right ASSIGN

%type <node> Prog ProgHeading ProgBlock VarPart VarDeclarationList VarDeclaration 
FuncPart StatPart IdList IdListLoop IdProd FuncDeclaration FuncDeclarationList FuncIdent FuncHeading FuncBlock NullFormalParam FormalParamsList FormalParams 
CompStat StatList StatListLoop Stat Expr WriteList ExprStringList ExprString ParamList ExprList SimpleExpr Term Factor AddOp Params VarParams FuncParams

%%

Prog: ProgHeading ';' ProgBlock '.' 									{$$ = tree = make_node("Program", 1, 2, $1, $3); };
ProgHeading: PROGRAM IdProd '(' OUTPUT ')' 								{$$ = make_node("ProgHeading", 	  0, 1, $2); };
ProgBlock: VarPart FuncPart StatPart 									{$$ = make_node("ProgBlock", 	  0, 3, $1, $2, $3); };
VarPart: VAR VarDeclaration ';' VarDeclarationList 						{$$ = make_node("VarPart", 		  1, 2, $2, $4);}
	| %empty 															{$$ = make_node("VarPart", 		  1, 0); }
;
VarDeclarationList: VarDeclarationList VarDeclaration ';' 				{$$ = make_node("VarDeclarationList", 0, 2, $1, $2);} 
	| %empty															{$$ = NULL; }
;
VarDeclaration: IdList ':' IdProd										{$$ = make_node("VarDecl", 	  1, 2, $1, $3); } ;
IdList: IdProd IdListLoop												{$$ = make_node("IdList", 	  0, 2, $1, $2);};
IdListLoop: IdListLoop ',' IdProd										{$$ = make_node("IdListLoop", 0, 2, $1, $3);};
	| %empty															{$$ = NULL; }
;
IdProd: ID 																{$$ = terminal("Id", $1); };

FuncPart: FuncDeclarationList 											{$$ = make_node("FuncPart"			 , 1, 1, $1); };
FuncDeclarationList: FuncDeclarationList FuncDeclaration ';' 			{$$ = make_node("FuncDeclarationList", 0, 2, $1, $2); }
	| %empty															{$$ = NULL; }
;
FuncDeclaration: FuncHeading ';' FORWARD								{$$ = make_node("FuncDecl", 1, 1, $1); }
	| FuncIdent ';' FuncBlock 											{$$ = make_node("FuncDef2", 1, 2, $1, $3); }
	| FuncHeading ';' FuncBlock											{$$ = make_node("FuncDef", 	1, 2, $1, $3); }
;
FuncHeading: FUNCTION IdProd NullFormalParam ':' IdProd					{$$ = make_node("FuncHeading",	0, 3, $2, $3, $5); };
FuncIdent: FUNCTION IdProd												{$$ = make_node("FuncIdent", 	0, 1, $2); };
FuncBlock: VarPart StatPart												{$$ = make_node("FuncBlock", 	0, 2, $1, $2); };

NullFormalParam: FuncParams 											{$$ = make_node("FuncParams", 1, 1, $1); }
	| %empty															{$$ = make_node("FuncParams", 1, 0); }
;
FuncParams: '(' FormalParamsList ')' 									{$$ = make_node("FuncParams", 		0, 1, $2); };
FormalParamsList: FormalParamsList ';' FormalParams 					{$$ = make_node("FormalParamsList", 0, 2, $1, $3); }
	| FormalParams														{$$ = $1; }
;
FormalParams : VarParams 												{$$ = $1; }
			 | Params 													{$$ = $1; }
;
VarParams: VAR IdList ':' IdProd 										{$$ = make_node("VarParams", 1, 2, $2, $4); };
Params: IdList ':' IdProd 												{$$ = make_node("Params", 	 1, 2, $1, $3); };

StatPart: CompStat 														{$$ = make_node("StatPart", 	0, 1, gen_statlist($1) ); };
StatList: Stat StatListLoop												{$$ = make_node("StatList", 	1, 2, $1, $2); if($$->n_op <= 1) $$->to_use=0; };
StatListLoop: StatListLoop ';' Stat 									{$$ = make_node("StatListLoop", 0, 2, $1, $3); };
	| %empty															{$$ = NULL; }
;

CompStat: BEG StatList END	 											{$$ = make_node("CompStat", 0, 1, $2); };
Stat: CompStat															{$$ = make_node("CompStat", 0, 1, $1); }
	| IF Expr THEN Stat 												{$$ = make_node("IfElse", 	1, 3, $2, gen_statlist($4), gen_statlist(NULL)); }
	| IF Expr THEN Stat ELSE Stat 										{$$ = make_node("IfElse", 	1, 3, $2, gen_statlist($4), gen_statlist($6)); }
	| WHILE Expr DO Stat 												{$$ = make_node("While", 	1, 2, $2, gen_statlist($4)); }
	| REPEAT StatList UNTIL Expr 										{$$ = make_node("Repeat", 	1, 2, gen_statlist($2), $4); }
	| VAL '(' PARAMSTR '(' Expr ')' ',' IdProd ')'						{$$ = make_node("ValParam", 1, 2, $5, $8); }
	| WRITELN WriteList  												{$$ = make_node("WriteLn",  1, 1, $2); }
	| WRITELN 															{$$ = make_node("WriteLn",  1, 0); }
	| IdProd ASSIGN Expr 												{$$ = make_node("Assign", 	1, 2, $1, $3); }
	| %empty															{$$ = NULL; }
;

WriteList: '(' ExprString ExprStringList ')' 							{$$ = make_node("WriteList", 	  0, 2, $2, $3); };
ExprStringList: ExprStringList ',' ExprString 							{$$ = make_node("ExprStringList", 0, 2, $1, $3); }
	| %empty															{$$ = NULL; }
;
ExprString: Expr 														{$$ = make_node("ExprString", 0, 1, $1); }
	| STRING 															{$$ = terminal("String", $1); }
;

Expr: SimpleExpr '<' SimpleExpr 										{$$ = make_node("Lt",  1, 2, $1, $3); }
	| SimpleExpr '>' SimpleExpr 										{$$ = make_node("Gt",  1, 2, $1, $3); }
	| SimpleExpr '=' SimpleExpr 										{$$ = make_node("Eq",  1, 2, $1, $3); }
	| SimpleExpr NEQ SimpleExpr 										{$$ = make_node("Neq", 1, 2, $1, $3); }
	| SimpleExpr LEQ SimpleExpr 										{$$ = make_node("Leq", 1, 2, $1, $3); }
	| SimpleExpr GEQ SimpleExpr 										{$$ = make_node("Geq", 1, 2, $1, $3); }
	| SimpleExpr 														{$$ = $1; }
;
SimpleExpr: AddOp														{$$ = $1;}
	| Term 																{$$ = $1;}
;
AddOp: SimpleExpr '+' Term												{$$ = make_node("Add", 	 1, 2, $1, $3); }
	| SimpleExpr '-' Term												{$$ = make_node("Sub", 	 1, 2, $1, $3); }
	| SimpleExpr OR Term 												{$$ = make_node("Or", 	 1, 2, $1, $3); }
	| '+' Term															{$$ = make_node("Plus",  1, 1, $2); }
	| '-' Term															{$$ = make_node("Minus", 1, 1, $2); }
;
Term: Factor															{$$ = $1; }
	| Term '*' Factor													{$$ = make_node("Mul", 	   1, 2, $1, $3); }
	| Term '/' Factor  													{$$ = make_node("RealDiv", 1, 2, $1, $3); }
	| Term DIV Factor  													{$$ = make_node("Div", 	   1, 2, $1, $3); }
	| Term MOD Factor  													{$$ = make_node("Mod", 	   1, 2, $1, $3); }
	| Term AND Factor  													{$$ = make_node("And", 	   1, 2, $1, $3); }
;
Factor:	'(' Expr ')' 													{$$ = $2; }
	| INTLIT 															{$$ = terminal("IntLit",  $1); }
	| REALLIT 															{$$ = terminal("RealLit", $1); }
	| ID 																{$$ = terminal("Id", 	  $1); };
	| NOT Factor 														{$$ = make_node("Not",  1, 1, $2); }
	| IdProd ParamList 													{$$ = make_node("Call", 1, 2, $1, $2); }
;

ParamList: '(' Expr ExprList ')'										{$$ = make_node("ParamList", 0, 2, $2, $3); };
ExprList: ExprList ',' Expr 											{$$ = make_node("ExprList",  0, 2, $1, $3); }
	| %empty															{$$ = NULL; }
;

%%

void print_hashtable(){
	int i=0;
	element_t **it;

	for(i = 0; i < st_size; i++){
		printf("===== %s Symbol Table =====\n", symbol_tables[i]->name);
		for(it = symbol_tables[i]->next; it != symbol_tables[i]->last; ++it){
			if( ((*it)->type == TYPE_T || (*it)->type == BOOLEAN_T) && i == OUTER_ST)
				printf("%s\t_%s_\t%s\t_%s_\n", (*it)->name, type2string((*it)->type), flag2string((*it)->flag), value2string((*it)->value));
			else if((*it)->type == FUNCTION_T || (*it)->type == PROGRAM_T)
				printf("%s\t_%s_\n", (*it)->name, type2string((*it)->type));
			else{
				if(i == PROGRAM_ST)
					printf("%s\t_%s_\n", (*it)->name, type2string((*it)->type));
				else{
					if((*it)->flag != NONE_F)
						printf("%s\t_%s_\t%s\n", (*it)->name, type2string((*it)->type), flag2string((*it)->flag) );
					else
						printf("%s\t_%s_\n", (*it)->name, type2string((*it)->type));
				}
			}
		}

		if(i < st_size-1)
			printf("\n");
	}
}

int main(int argc, char **argv){

	if(yyparse())
		return 0;

	symbol_tables[OUTER_ST] = new_hashtable(256, "Outer");
	st_pointer = st_size++;
	create_outer_st(symbol_tables[OUTER_ST]);
	create_useless_tables();
	
	parse_tree(tree);
	while(argc--){
		if(!strcmp(*argv, "-t"))
			print_tree(tree, 0);
		else if(!strcmp(*argv, "-s"))
			print_hashtable();
		
		argv++;
	}
	return 0;
}

int yyerror(char *s){
	printf("Line %d, col %d: %s: %s\n", yylineno, col - (int)yyleng, s, yytext);
}
