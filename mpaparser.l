%option caseless
%option yylineno

%X COMMENT

num									[0-9]+
whitespace							[\t ]

%{
	#include "y.tab.h"
	#define YY_USER_ACTION col+=yyleng;
	
	int col=1, stcol, stline;
%}

%%

({num}"."{num})|({num}e[+-]?{num})|({num}.{num}e[+-]?{num}) {yylval.str=(char *) strdup(yytext); return REALLIT; }
{num}														{yylval.val=atoi(yytext); return INTLIT; }

'([^'\n]|'')+'												{yylval.str=(char *) strdup(yytext); return STRING; }
'([^'\n]|'')+												{printf("Line %d, col %d: unterminated string\n", yylineno, col - (int)yyleng);}

"{"|"(*"													{BEGIN COMMENT; stcol = col-yyleng; stline = yylineno; }
<COMMENT>"}"|"*)"											{BEGIN 0; }
<COMMENT>.													{; }
<COMMENT>\n 												{col = 1; }
<COMMENT><<eof>>	 										{col+=1; printf("Line %d, col %d: unterminated comment\n", stline, stcol); return 0; }

":="														{return ASSIGN; }
begin														{return BEG; }
do															{return DO; }
else														{return ELSE; }
end															{return END; }
forward														{return FORWARD; }
function													{return FUNCTION; }
if															{return IF; }
not															{return NOT; }
output														{return OUTPUT; }
paramstr													{return PARAMSTR; }
program														{return PROGRAM; }
repeat														{return REPEAT; }
then														{return THEN; }
until														{return UNTIL; }
val															{return VAL; }	
var															{return VAR; }
while														{return WHILE; }
writeln														{return WRITELN; }

and															{return AND; }
or															{return OR; }
"<>"														{return NEQ; }
"<="														{return LEQ; }
">="														{return GEQ; }
"<"|">"|"="|"+"|"-"|"*"|"/"|":"|","|"."|"("|")"|";"			{return yytext[0]; }
mod															{return MOD; }
div															{return DIV; }

abs|arctan|array|case|char|chr|const|cos|dispose|downto|eof|eoln|exp|file|for|get|goto|in|input|label|ln|maxint|new|nil|odd|of|ord|output|pack|packed|page|pred|procedure|put|record|read|readln|reset|rewrite|round|set|sin|sqr|sqrt|succ|text|type|to|trunc|unpack|with|write 	{return RESERVED;}

[a-zA-Z][0-9a-zA-Z]*										{yylval.str=(char *) strdup(yytext); return ID; }

{whitespace}												{;}
\n															{col=1;}
<<eof>>														{col+=1; return 0;}
.															{printf("Line %d, col %d: illegal character ('%s')\n", yylineno, col - (int)yyleng, yytext); /* Some illegal characters are parsed twice*/ }

%%

int yywrap(){
	return 1;
}
