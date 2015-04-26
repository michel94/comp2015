%{

	#include <stdio.h>
	#include <stdarg.h>
	#include <stdlib.h>
	#include <string.h>
	#include "hashtable.h"

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

	element_t* symbol_tables[256];
	int st_pointer, st_size=0;

	Node *new_node(){
		return (Node *) malloc(sizeof(Node));
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

	void parse_instruction(){


	}

	int vartype(char* s){
		if(strcmp(s, "string") == 0)
			return STRING_T;
		else if(strcmp(s, "integer") == 0)
			return INTEGER_T;
		else if(strcmp(s, "real") == 0)
			return REAL_T;
	}

	char* type2string(type_t type){
		switch(type){
			case(STRING_T):
				return "string";
			case(INTEGER_T):
				return "integer";
			case(REAL_T):
				return "real";
			default:
				return "undefined";
		}
	}

	void parse_tree(Node* p){
		int stp_backup, i;
		
		if(p == NULL)
			return;
		
		if(strcmp(p->type, "Program") == 0 || strcmp(p->type, "FuncDef") == 0 || strcmp(p->type, "FuncDef2") == 0){
			stp_backup = st_pointer;
			st_pointer = st_size++;
			symbol_tables[st_pointer] = (element_t*) malloc(sizeof(element_t) * 256);
			for(i = 0; i < p->n_op; i++)
				parse_tree(p->op[i]);
			st_pointer = stp_backup;
			
		}else if(strcmp(p->type, "VarParams") == 0){
			for(i = 0; i < p->n_op; i++)
				store(symbol_tables[st_pointer], 256, p->op[i]->value, vartype(p->op[p->n_op-1]->value) );
		}else if(strcmp(p->type, "VarDecl") == 0){
			for(i = 0; i < p->n_op-1; i++){
				store(symbol_tables[st_pointer], 256, p->op[i]->value, vartype(p->op[p->n_op-1]->value) );
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
int main(int argc, char **argv){

	if(yyparse())
		return 0;

	while(argc--){
		if(!strcmp(*argv, "-t"))
			print_tree(tree, 0);
		else if(!strcmp(*argv, "-s")){
			parse_tree(tree);
			int i, j;
			for(i=0; i<st_size; i++){
				for(j=0; j<256; j++)
					if(strlen(symbol_tables[i][j].name) > 0){
						printf("%s %s\n", symbol_tables[i][j].name, type2string(symbol_tables[i][j].type) );
					}
			}
		}
		*argv++;
	}
	return 0;
}

int yyerror(char *s){
	printf("Line %d, col %d: %s: %s\n", yylineno, col - (int)yyleng, s, yytext);
}
