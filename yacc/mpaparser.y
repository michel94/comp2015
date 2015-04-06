%{
	typedef struct node {
		int type;
		int n_op;

		struct node **op;
	} Node;

	extern int yylineno, col, yyleng;
	extern char* yytext;
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
%token VAR VAL FORWARD FUNCTION OUTPUT PARAMSTR PROGRAM WRITELN

%right THEN
%right ELSE

%right ASSIGN
%left NEQ LEQ GEQ '<' '>' '='
%left  OR '+' '-'
%left '*' '/' MOD DIV AND
%left NOT

%%

Prog: ProgHeading ';' ProgBlock '.';
ProgHeading: PROGRAM ID '(' OUTPUT ')';
ProgBlock: VarPart FuncPart StatPart;
VarPart: VAR VarDeclaration ';' varDeclarationSemicList | %empty;
varDeclarationSemicList: varDeclarationSemicList VarDeclaration ';' | %empty;
VarDeclaration: IdList ':' ID;
IdList: ID IdListLoop;
IdListLoop: IdListLoop ',' ID | %empty;

FuncPart: FuncDeclarationList;
FuncDeclarationList: FuncDeclarationList FuncDeclaration ';' | %empty;
FuncDeclaration: FuncHeading ';' FORWARD;
FuncDeclaration: FuncIdent ';' FuncBlock;
FuncDeclaration: FuncHeading ';' FuncBlock;
FuncHeading: FUNCTION ID NullFormalParam ':' ID;
FuncIdent: FUNCTION ID;

FormalParamList: '(' FormalParams FormalParamsListLoop ')';
FormalParams: NullVar IdList ':' ID;
FuncBlock: VarPart StatPart;
NullVar: VAR | %empty;

FormalParamsListLoop: FormalParamsListLoop ';' FormalParams | %empty;
NullFormalParam: FormalParamList | %empty;
StatPart: CompStat;
CompStat: BEG StatList END;
StatList: Stat StatListLoop;
StatListLoop: StatListLoop ';' Stat | %empty;
Stat: CompStat
	| IF Expr THEN Stat
	| IF Expr THEN Stat ELSE Stat
	| WHILE Expr DO Stat
	| REPEAT StatList UNTIL Expr
	| VAL '(' PARAMSTR '(' Expr ')' ',' ID ')'
	| WRITELN WriteList | WRITELN
	| ID ASSIGN Expr
	| %empty;

WriteList: '(' ExprString ExprStringList ')';
ExprStringList: ExprStringList ',' ExprString | %empty;
ExprString: Expr | STRING ;

Expr: Expr AND Expr
	| Expr OR Expr
	| Expr '<' Expr
	| Expr '>' Expr
	| Expr '=' Expr
	| Expr NEQ Expr
	| Expr LEQ Expr
	| Expr GEQ Expr
	| Expr '+' Expr
	| Expr '-' Expr
	| Expr '*' Expr
	| Expr '/' Expr
	| Expr DIV Expr
	| Expr MOD Expr
	| '+' Expr
	| '-' Expr
	| NOT Expr
	| '(' Expr ')'
	| INTLIT | REALLIT
	| ID ParamList | ID;

ParamList: '(' Expr ExprList ')';

ExprList: ExprList ',' Expr | %empty;

%%

#include <stdio.h>
#include <stdarg.h>

Node *production(int node_type, int node_operands, ...){
	Node *p, **tmp;
	va_list args;

	p = (Node *) malloc(sizeof(Node));
	tmp = p->op = (Node **) malloc(node_operands * sizeof(Node *));

	p->type = node_type;
	p->n_op = node_operands;

	va_start(args, node_operands);
	while(node_operands--)
		*tmp++ = va_arg(args, Node *);

	va_end(args);
	return p;
} 

void print_ast(int syntax_error){
	if(syntax_error)
		return;

	printf("TREE!\n");
}

int main(int argc, char **argv){
	int tmp = yyparse();

	// SIMPLER THIS WAY
	// if(!tmp)

	while(argc--)
		if(!strcmp(*argv++, "-t"))
			print_ast(tmp);

	return 0;
}

int yyerror(char *s){
	printf("Line %d, col %d: %s: %s\n", yylineno, col - (int)yyleng, s, yytext);
}

