%token NOT AND OR MOD DIV
%token ASSIGN NEQ LEQ GEQ
%token IF THEN ELSE BEG END
%token DO REPEAT UNTIL WHILE
%token VAR VAL ID STRING REALLIT INTLIT
%token FORWARD FUNCTION OUTPUT PARAMSTR PROGRAM WRITELN

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

int main(){
	yyparse();
}

int yyerror(char *s){
	printf("Line %d, col %d: %s: %s\n", 1, 2, s, "");
}

