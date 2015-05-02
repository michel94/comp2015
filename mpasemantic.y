%{

	#include <stdio.h>
	#include <stdarg.h>
	#include <stdlib.h>
	#include <string.h>
	#include <ctype.h>
	#include "hashtable.h"
	#include "parsing.h"

	Node *tree, *merge_nodes[2048];

	extern int yylineno, col, yyleng;
	extern char* yytext;

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
		symbol_tables[st_pointer] = new_hashtable(TABLE_SIZE, "Function");
		strcpy(symbol_tables[st_pointer]->func, "paramcount");
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
		p->value2 	= (char *) strdup(s);
		p->to_use 	= 1;
		p->n_op 	= 0;
		p->op 		= NULL;

		to_lower(p->value);
		return p;
	}

	void print_data(Node* p){
		if(strcmp(p->type, "Id") == 0)
			printf("Id(%s)\n", p->value2);
		else if(strcmp(p->type, "String") == 0)
			printf("String(%s)\n", p->value2);
		else if(strcmp(p->type, "IntLit") == 0)
			printf("IntLit(%s)\n", p->value2);
		else if(strcmp(p->type, "RealLit") == 0)
			printf("RealLit(%s)\n", p->value2);
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
VarDeclaration: IdList ':' IdProd										{$$ = make_node("VarDecl", 	  1, 2, $1, $3); $$->loc = @3;} ;
IdList: IdProd IdListLoop												{$$ = make_node("IdList", 	  0, 2, $1, $2);};
IdListLoop: IdListLoop ',' IdProd										{$$ = make_node("IdListLoop", 0, 2, $1, $3);};
	| %empty															{$$ = NULL; }
;
IdProd: ID 																{$$ = terminal("Id", $1); $$->loc = @1;};

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
	| IF Expr THEN Stat 												{$$ = make_node("IfElse", 	1, 3, $2, gen_statlist($4), gen_statlist(NULL)); $$->loc = @1;}
	| IF Expr THEN Stat ELSE Stat 										{$$ = make_node("IfElse", 	1, 3, $2, gen_statlist($4), gen_statlist($6)); $$->loc = @1;}
	| WHILE Expr DO Stat 												{$$ = make_node("While", 	1, 2, $2, gen_statlist($4)); $$->loc = @1;}
	| REPEAT StatList UNTIL Expr 										{$$ = make_node("Repeat", 	1, 2, gen_statlist($2), $4); $$->loc = @1;}
	| VAL '(' PARAMSTR '(' Expr ')' ',' IdProd ')'						{$$ = make_node("ValParam", 1, 2, $5, $8); }
	| WRITELN WriteList  												{$$ = make_node("WriteLn",  1, 1, $2); }
	| WRITELN 															{$$ = make_node("WriteLn",  1, 0); }
	| IdProd ASSIGN Expr 												{$$ = make_node("Assign", 	1, 2, $1, $3); $$->loc = @2; }
	| %empty															{$$ = NULL; }
;

WriteList: '(' ExprString ExprStringList ')' 							{$$ = make_node("WriteList", 	  0, 2, $2, $3); };
ExprStringList: ExprStringList ',' ExprString 							{$$ = make_node("ExprStringList", 0, 2, $1, $3); }
	| %empty															{$$ = NULL; }
;
ExprString: Expr 														{$$ = make_node("ExprString", 0, 1, $1); }
	| STRING 															{$$ = terminal("String", $1); }
;

Expr: SimpleExpr '<' SimpleExpr 										{$$ = make_node("Lt",  1, 2, $1, $3); $$->loc = @2;}
	| SimpleExpr '>' SimpleExpr 										{$$ = make_node("Gt",  1, 2, $1, $3); $$->loc = @2;}
	| SimpleExpr '=' SimpleExpr 										{$$ = make_node("Eq",  1, 2, $1, $3); $$->loc = @2;}
	| SimpleExpr NEQ SimpleExpr 										{$$ = make_node("Neq", 1, 2, $1, $3); $$->loc = @2;}
	| SimpleExpr LEQ SimpleExpr 										{$$ = make_node("Leq", 1, 2, $1, $3); $$->loc = @2;}
	| SimpleExpr GEQ SimpleExpr 										{$$ = make_node("Geq", 1, 2, $1, $3); $$->loc = @2;}
	| SimpleExpr 														{$$ = $1; }
;
SimpleExpr: AddOp														{$$ = $1;}
	| Term 																{$$ = $1;}
;
AddOp: SimpleExpr '+' Term												{$$ = make_node("Add", 	 1, 2, $1, $3); $$->loc = @2;}
	| SimpleExpr '-' Term												{$$ = make_node("Sub", 	 1, 2, $1, $3); $$->loc = @2;}
	| SimpleExpr OR Term 												{$$ = make_node("Or", 	 1, 2, $1, $3); $$->loc = @2;}
	| '+' Term															{$$ = make_node("Plus",  1, 1, $2); $$->loc = @1;}
	| '-' Term															{$$ = make_node("Minus", 1, 1, $2); $$->loc = @1;}
;
Term: Factor															{$$ = $1; }
	| Term '*' Factor													{$$ = make_node("Mul", 	   1, 2, $1, $3); $$->loc = @2;}
	| Term '/' Factor  													{$$ = make_node("RealDiv", 1, 2, $1, $3); $$->loc = @2;}
	| Term DIV Factor  													{$$ = make_node("Div", 	   1, 2, $1, $3); $$->loc = @2;}
	| Term MOD Factor  													{$$ = make_node("Mod", 	   1, 2, $1, $3); $$->loc = @2;}
	| Term AND Factor  													{$$ = make_node("And", 	   1, 2, $1, $3); $$->loc = @2;}
;
Factor:	'(' Expr ')' 													{$$ = $2; }
	| INTLIT 															{$$ = terminal("IntLit",  $1); $$->loc = @1;}
	| REALLIT 															{$$ = terminal("RealLit", $1); $$->loc = @1;}
	| ID 																{$$ = terminal("Id", 	  $1); $$->loc = @1;};
	| NOT Factor 														{$$ = make_node("Not",  1, 1, $2); $$->loc = @1;}
	| IdProd ParamList 													{$$ = make_node("Call", 1, 2, $1, $2); $$->loc = @1;}
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

	symbol_tables[OUTER_ST] = new_hashtable(TABLE_SIZE, "Outer");
	st_pointer = st_size++;
	create_outer_st(symbol_tables[OUTER_ST]);
	create_useless_tables();
	
	int t_flag=0, s_flag=0;

	while(argc--){
		if(!strcmp(*argv, "-t"))
			t_flag=1;
		else if(!strcmp(*argv, "-s"))
			s_flag = 1;		
		argv++;
	}

	if(t_flag && !s_flag){
		print_tree(tree, 0);
	}else if(t_flag && s_flag){
		print_tree(tree, 0);
		if(parse_tree(tree)) return 0;
		print_hashtable();
	}else if(!t_flag && s_flag){
		if(parse_tree(tree)) return 0;
		print_hashtable();
	}else{
		parse_tree(tree);
	}
	
	
	return 0;
}

int yyerror(char *s){
	printf("Line %d, col %d: %s: %s\n", yylineno, col - (int)yyleng, s, yytext);
}
