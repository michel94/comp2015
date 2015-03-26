%{

#include<stdio.h>
%}
%token BEGIN
%token DOT
%token END
%token ID
%token OUTPUT
%token PROGRAM
%token VAR

%%

prog: progHeading ';' progBlock '.'
progHeading: PROGRAM ID '(' OUTPUT ')'
progBlock: varPart
varPart: VAR varDeclaration

varDeclaration: ID ':' ID ';'
			|	ID ':' ID varDeclaration ';'

%%
int main(){
	yyparse();

}
