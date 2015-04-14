%{

	#include <stdio.h>
	#include <stdarg.h>
	#include <stdlib.h>
	#include <string.h>

	typedef struct{
		int t;
		char *s;
	} Value;


	typedef struct node {
		Value value;
		int to_use;
		int n_op;
		char* type;

		struct node **op;
	} Node;

	Node *tree, *merge_nodes[2048];

	extern int yylineno, col, yyleng;
	extern char* yytext;

	Node *new_node(){
		return (Node *) malloc(sizeof(Node));
	}

	int is_superfluous(Node *t){
		if(!strcmp(t->type, "StatList"))
			return t->n_op < 2;

		return 0;
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

		if(is_superfluous(prod))
			prod->to_use = 0;

		return prod;
	}

	Node *terminal(char* node_type, Value value){
		Node* p 	= new_node();
		p->type 	= node_type;
		p->value 	= value;
		p->to_use 	= 1;
		p->n_op 	= 0;

		return p;
	}

	void print_data(Node* p){
		if(strcmp(p->type, "Id") == 0)
			printf("Id(%s)\n", p->value.s);
		else if(strcmp(p->type, "String") == 0)
			printf("String('%s')\n", p->value.s);
		else if(strcmp(p->type, "IntLit") == 0)
			printf("IntLit(%d)\n", p->value.t);
		else if(strcmp(p->type, "RealLit") == 0)
			printf("RealLit(%s)\n", p->value.s);
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
%}

%union{
	int val;
	char *str;
	struct node *node;
}

%token <val> INTLIT
%token <str> ID STRING REALLIT

%token NOT AND OR MOD DIV
%token ASSIGN NEQ LEQ GEQ
%token IF THEN ELSE BEG END
%token DO REPEAT UNTIL WHILE
%token VAR VAL FORWARD FUNCTION OUTPUT PARAMSTR PROGRAM WRITELN RESERVED

%right THEN
%right ELSE
%right ASSIGN

%type <node> Prog ProgHeading ProgBlock VarPart VarDeclarationList VarDeclaration FuncPart StatPart IdList IdListLoop IdProd FuncDeclaration FuncDeclarationList FuncIdent FuncHeading FuncBlock NullFormalParam FormalParamList FormalParams FormalParamsListLoop NullVar 
CompStat StatList StatListLoop Stat Expr WriteList ExprStringList ExprString ParamList ExprList SimpleExpr Term Factor TermNNull AddOp

%%

Prog: ProgHeading ';' ProgBlock '.' 									{$$ = tree = make_node("Program" , 1, 2, $1, $3); };
ProgHeading: PROGRAM IdProd '(' OUTPUT ')' 								{$$ = make_node("ProgHeading"	 , 0, 1, $2); };
ProgBlock: VarPart FuncPart StatPart 									{$$ = make_node("ProgBlock"	 	 , 0, 3, $1, $2, $3); };
VarPart: VAR VarDeclaration ';' VarDeclarationList 						{$$ = make_node("VarPart"	 	 , 1, 2, $2, $4);}
	| %empty 															{$$ = NULL; }
;
VarDeclarationList: VarDeclarationList VarDeclaration ';' 				{$$ = make_node("VarDeclarationList", 0, 2, $1, $2);} 
	| %empty															{$$ = NULL; }
;
VarDeclaration: IdList ':' IdProd										{$$ = make_node("VarDecl"	, 1, 2, $1, $3); } ;
IdList: IdProd IdListLoop												{$$ = make_node("IdList"	, 0, 2, $1, $2);};
IdListLoop: IdListLoop ',' IdProd										{$$ = make_node("IdListLoop", 0, 2, $1, $3);};
	| %empty															{$$ = NULL; }
;
IdProd: ID 																{Value v; v.s = $1; $$ = terminal("Id", v); };

FuncPart: FuncDeclarationList 											{$$ = make_node("FuncPart"			 , 1, 1, $1); };
FuncDeclarationList: FuncDeclarationList FuncDeclaration ';' 			{$$ = make_node("FuncDeclarationList", 0, 2, $1, $2); }
	| %empty															{$$ = NULL; }
;
FuncDeclaration: FuncHeading ';' FORWARD								{$$ = make_node("FuncDecl", 	1, 1, $1); }
	| FuncIdent ';' FuncBlock 											{$$ = make_node("FuncDef", 		1, 2, $1, $3); }
	| FuncHeading ';' FuncBlock											{$$ = make_node("FuncDef2", 	1, 2, $1, $3); }
;
FuncHeading: FUNCTION IdProd NullFormalParam ':' IdProd					{$$ = make_node("FuncHeading",	0, 3, $2, $3, $5); };
FuncIdent: FUNCTION IdProd												{$$ = make_node("FuncIdent", 	0, 1, $2); };
FuncBlock: VarPart StatPart												{$$ = make_node("FuncBlock", 	0, 2, $1, $2); };

NullFormalParam: FormalParamList 										{$$ = make_node("FuncParams", 			1, 1, $1); }
	| %empty															{$$ = NULL; };
FormalParamList: '(' FormalParams FormalParamsListLoop ')' 				{$$ = make_node("FormalParamList", 		0, 2, $2, $3); };
FormalParams: NullVar IdList ':' IdProd 								{$$ = make_node("FormalParams", 		0, 3, $1, $2, $4); };
FormalParamsListLoop: FormalParamsListLoop ';' FormalParams 			{$$ = make_node("FormalParamsListLoop", 0, 2, $1, $3); }
	| %empty															{$$ = NULL; }
;

NullVar: VAR 															{$$ = make_node("NullVar", 0, 0); }
	| %empty 															{$$ = NULL; }
;

StatPart: CompStat 														{$$ = make_node("StatPart"		, 0, 1, $1); };
StatList: Stat StatListLoop												{$$ = make_node("StatList"		, 1, 2, $1, $2); };
StatListLoop: StatListLoop ';' Stat 									{$$ = make_node("StatListLoop"	, 0, 2, $1, $3); };
	| %empty															{$$ = NULL; }
;
CompStat: BEG StatList END	 											{$$ = make_node("CompStat"	, 0, 1, $2); };
Stat: CompStat															{$$ = make_node("CompStat"	, 0, 1, $1); }
	| IF Expr THEN Stat 												{$$ = make_node("IfElse"	, 1, 2, $2, $4); }
	| IF Expr THEN Stat ELSE Stat 										{$$ = make_node("IfElse"	, 1, 3, $2, $4, $6); }
	| WHILE Expr DO Stat 												{$$ = make_node("While"		, 1, 2, $2, $4); }
	| REPEAT StatList UNTIL Expr 										{$$ = make_node("Repeat"	, 1, 2, $2, $4); }
	| VAL '(' PARAMSTR '(' Expr ')' ',' IdProd ')'						{$$ = make_node("ValParam"	, 1, 2, $5, $8); }
	| WRITELN WriteList  												{$$ = make_node("WriteLn"	, 1, 1, $2); }
	| WRITELN 															{$$ = make_node("WriteLn"	, 1, 0); }
	| IdProd ASSIGN Expr 												{$$ = make_node("Assign"	, 1, 2, $1, $3); }
	| %empty															{$$ = NULL; }
;

WriteList: '(' ExprString ExprStringList ')' 							{$$ = make_node("WriteList"		, 0, 2, $2, $3); };
ExprStringList: ExprStringList ',' ExprString 							{$$ = make_node("ExprStringList", 0, 2, $1, $3); }
	| %empty															{$$ = NULL; }
;
ExprString: Expr 														{$$ = make_node("ExprString", 0, 1, $1); }
	| STRING 															{Value v; v.s = $1; $$ = terminal("String", v); }
;

Expr: SimpleExpr '<' SimpleExpr 										{$$ = make_node("Lt"	, 1, 2, $1, $3); }
	| SimpleExpr '>' SimpleExpr 										{$$ = make_node("Gt"	, 1, 2, $1, $3); }
	| SimpleExpr '=' SimpleExpr 										{$$ = make_node("Eq"	, 1, 2, $1, $3); }
	| SimpleExpr NEQ SimpleExpr 										{$$ = make_node("Neq"	, 1, 2, $1, $3); }
	| SimpleExpr LEQ SimpleExpr 										{$$ = make_node("Leq"	, 1, 2, $1, $3); }
	| SimpleExpr GEQ SimpleExpr 										{$$ = make_node("Geq"	, 1, 2, $1, $3); }
	| SimpleExpr 														{$$ = $1; }
;

SimpleExpr: AddOp														{$$ = $1;}
	| TermNNull OR Term 												{$$ = make_node("Or"	, 1, 2, $1, $3); }
	| Term 																{$$ = $1;}
;

TermNNull: AddOp														{$$ = $1;}
	| TermNNull OR Term 												{$$ = make_node("Or"	, 1, 2, $1, $3); }
	| Term 																{$$ = $1;}
;

AddOp: SimpleExpr '+' Term												{$$ = make_node( $1 != NULL ? "Add" : "Plus", 1, 2, $1, $3); }
	| SimpleExpr '-' Term												{$$ = make_node( $1 != NULL ? "Sub" : "Minus", 1, 2, $1, $3); }

Term: Factor															{$$ = $1; }
	| Factor '*' Term 													{$$ = make_node("Mul"	, 1, 2, $1, $3); }
	| Factor '/' Term 													{$$ = make_node("Div"	, 1, 2, $1, $3); }
	| Factor DIV Term 													{$$ = make_node("RealDiv",1, 2, $1, $3); }
	| Factor MOD Term 													{$$ = make_node("Mod"	, 1, 2, $1, $3); }
	| Factor AND Term 													{$$ = make_node("And"	, 1, 2, $1, $3); }
;

Factor:	'(' Expr ')' 													{$$ = $2; }
	| INTLIT 															{Value v; v.t = $1; $$ = terminal("IntLit", v); }
	| REALLIT 															{Value v; v.s = $1; $$ = terminal("RealLit", v); }
	| ID 																{Value v; v.s = $1; $$ = terminal("Id", v); };
	| NOT Factor 														{$$ = make_node("Not"	, 1, 1, $2); }
	| IdProd ParamList 													{$$ = make_node("Call"	, 1, 2, $1, $2); }
;

ParamList: '(' Expr ExprList ')'										{$$ = make_node("ParamList", 0, 2, $2, $3); };
ExprList: ExprList ',' Expr 											{$$ = make_node("ExprList" , 0, 2, $1, $3); }
	| %empty															{$$ = NULL; }
;

%%

int main(int argc, char **argv){

	if(yyparse())
		return 0;

	while(argc--)
		if(!strcmp(*argv++, "-t"))
			print_tree(tree, 0);

	return 0;
}

int yyerror(char *s){
	printf("Line %d, col %d: %s: %s\n", yylineno, col - (int)yyleng, s, yytext);
}
