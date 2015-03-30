
%token ID
%token STRING
%token NUMBER

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
varPart: VAR varDeclaration;
varDeclaration: idList ':' ID;

idList: ID commaIdList;
commaIdList: commaIdList ',' ID | ;

funcPart: funcDeclarationList;
funcDeclarationList: funcDeclarationList funcDeclaration ';' | ;
funcDeclaration: funcHeading ';' FORWARD;
funcDeclaration: funcIdent ';' funcBlock;
funcDeclaration: funcHeading ';' funcBlock;
funcHeading: FUNCTION ID (formalParamList | ) ':' ID;
funcIdent: FUNCTION ID;

formalParamList: '(' formalParams semicFormalParamsList ')';
semicFormalParamsList: semicFormalParamsList ';' formalParams | ;
formalParams: (VAR | ) idList ':' ID;
funcBlock: varPart statPart;

statPart: compStat;
compStat: BEG statList END;
statList: Stat semicStatList;
semicStatList: semicStatList ';' Stat | ;
Stat: compStat;
Stat: IF Expr THEN Stat (ELSE Stat | );
Stat: WHILE Expr DO Stat;
Stat: REPEAT statList UNTIL Expr;
Stat: VAL '(' PARAMSTR ')' Expr ')' ',' ID ')';
Stat: ID '=' Expr | ;
Stat: WRITELN (writelnPList | );

writelnPList: '(' (Expr | STRING) commaExprOrStringList ')';
commaExprOrStringList: commaExprOrStringList ',' (Expr | STRING) | ;

Expr: Expr (OP1 | OP2 | OP3 | OP4) Expr;
Expr: (OP3 | NOT) Expr;
Expr: '(' Expr ')';
Expr: NUMBER | NUMBER;
Expr: ID (paramList | );

paramList: '(' Expr commaExprList ')';
commaExprList: commaExprList ',' Expr | ;

%%
#include <stdio.h>

int main(){
	yyparse();

}
