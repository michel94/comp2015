
%token ID
%token STRING
%token REALLIT
%token INTLIT

%token ASSIGN
%token BEG
%token DO
%token ELSE
%token END
%token FORWARD
%token FUNCTION
%token IF
%token NOT
%token OUTPUT
%token PARAMSTR
%token PROGRAM
%token REPEAT
%token THEN
%token UNTIL
%token VAL
%token VAR
%token WHILE
%token WRITELN
%token AND
%token OR
%token NEQ
%token LEQ
%token GEQ
%token MOD
%token DIV

%%

prog: progHeading ';' progBlock '.';
progHeading: PROGRAM ID '(' OUTPUT ')';
progBlock: varPart funcPart statPart;
varPart: | VAR varDeclaration ';' varDeclarationSemicList;
varDeclarationSemicList: | varDeclarationSemicList varDeclaration ';';
varDeclaration: idList ':' ID;

idList: ID commaIdList;
commaIdList: | commaIdList ',' ID;

funcPart: funcDeclarationList;
funcDeclarationList: | funcDeclarationList funcDeclaration ';';
funcDeclaration: funcHeading ';' FORWARD;
funcDeclaration: funcIdent ';' funcBlock;
funcDeclaration: funcHeading ';' funcBlock;
funcHeading: FUNCTION ID formalParamListOr ':' ID;
funcIdent: FUNCTION ID;

formalParamList: '(' formalParams semicFormalParamsList ')';
semicFormalParamsList: | semicFormalParamsList ';' formalParams;
formalParams: varOr idList ':' ID;
funcBlock: varPart statPart;

statPart: compStat;
compStat: BEG statList END;
statList: Stat semicStatList;
semicStatList: | semicStatList ';' Stat;
Stat: compStat;
Stat: IF Expr THEN Stat elseStatOr;
Stat: WHILE Expr DO Stat;
Stat: REPEAT statList UNTIL Expr;
Stat: VAL '(' PARAMSTR '(' Expr ')' ',' ID ')';
Stat: | ID ASSIGN Expr;
Stat: WRITELN writelnPList | WRITELN;

writelnPList: '(' exprOrString commaExprOrStringList ')';
commaExprOrStringList: | commaExprOrStringList ',' exprOrString;

Expr: Expr exprOp Expr;
Expr: exprOp3Not Expr;
Expr: '(' Expr ')';
Expr: INTLIT | REALLIT;
Expr: ID paramList | ID;

paramList: '(' Expr commaExprList ')';
commaExprList: | commaExprList ',' Expr;

exprOp: OP1 | OP2 | OP3 | OP4;
exprOp3Not: OP3 | NOT;
varOr: | VAR;
elseStatOr: | ELSE Stat;
formalParamListOr: | formalParamList;
exprOrString: Expr | STRING ;
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
	printf("%s\n", s);
}

