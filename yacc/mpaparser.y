%token NOT AND OR MOD DIV
%token ASSIGN NEQ LEQ GEQ
%token IF THEN ELSE BEG END
%token DO REPEAT UNTIL WHILE
%token VAR VAL ID STRING REALLIT INTLIT
%token FORWARD FUNCTION OUTPUT PARAMSTR PROGRAM WRITELN

%%

Prog: ProgHeading ';' ProgBlock '.';
ProgHeading: PROGRAM ID '(' OUTPUT ')';
ProgBlock: VarPart FuncPart StatPart;
VarPart: VAR VarDeclaration ';' varDeclarationSemicList | %empty;
varDeclarationSemicList: varDeclarationSemicList VarDeclaration ';' | %empty;
VarDeclaration: IdList ':' ID;
IdList: ID IdListList;
IdListList: IdListList ',' ID | %empty;

FuncPart: FuncDeclarationList;
FuncDeclarationList: FuncDeclarationList FuncDeclaration ';' | %empty;
FuncDeclaration: FuncHeading ';' FORWARD;
FuncDeclaration: FuncIdent ';' FuncBlock;
FuncDeclaration: FuncHeading ';' FuncBlock;
FuncHeading: FUNCTION ID NullFormalParam ':' ID;
FuncIdent: FUNCTION ID;

FormalParamList: '(' FormalParams FormalParamsListList ')';
FormalParams: NullVar IdList ':' ID;
FuncBlock: VarPart StatPart;
NullVar: VAR | %empty;

FormalParamsListList: FormalParamsListList ';' FormalParams | %empty;
NullFormalParam: FormalParamList | %empty;

StatPart: CompStat;
CompStat: BEG StatList END;
StatList: Stat StatListList;
StatListList: StatListList ';' Stat | %empty;
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

Expr: Expr AllOP Expr
	| PreOP Expr
	| '(' Expr ')'
	| INTLIT | REALLIT
	| ID ParamList | ID;

ParamList: '(' Expr ExprList ')';
ExprList: ExprList ',' Expr | %empty;

AllOP: OP1 | OP2 | OP3 | OP4;
PreOP: OP3 | NOT;
OP1: AND | OR; 
OP2: '<' | '>' | '=' | NEQ | LEQ | GEQ;
OP3: '+' | '-' ;
OP4: '*' | '/' | MOD | DIV;

%%

#include <stdio.h>

int main(){
	yyparse();
}

int yyerror(char *s){
	printf("Line %d, col %d: %s: %s\n", 1, 2, s, "");
}

