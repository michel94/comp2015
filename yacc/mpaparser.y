%{

#include<stdio.h>
%}

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

prog: progHeading ';' progBlock '.'
progHeading: PROGRAM ID '(' OUTPUT ')'
progBlock: varPart statPart
varPart: VAR varDeclaration

statPart: compStat
compStat: BEG END

varDeclaration: ID ':' ID ';'
			|	ID ':' ID varDeclaration ';'

%%
int main(){
	yyparse();

}
