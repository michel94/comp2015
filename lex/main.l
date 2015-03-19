%option caseless
%option yylineno

%X COMMENT

num									[0-9]+
whitespace							[\t ]

%{
	int col=1, stcol, stline;
	#define YY_USER_ACTION col+=yyleng;
%}

%%

({num}"."{num})|({num}e[+-]?{num})|({num}.{num}e[+-]?{num}) {printf("REALLIT(%s)\n", yytext);}
{num}														{printf("INTLIT(%s)\n", yytext);}

'([^'\n]|'')*'												{yytext[strlen(yytext)-1]=0; printf("STRING('%s')\n", yytext+1);}
'([^'\n]|'')*												{printf("Line %d, col %d: unterminated string\n", yylineno, col - (int)yyleng);}

"{"|"(*"													{BEGIN COMMENT; stcol = col-yyleng; stline = yylineno; }
<COMMENT>"}"|"*)"											{BEGIN 0; }
<COMMENT>.													{; }
<COMMENT>\n 												{col = 1; }
<COMMENT><<eof>>	 										{printf("Line %d, col %d: unterminated comment\n", stline, stcol); return 0; }

":="														{printf("ASSIGN\n");}
begin														{printf("BEGIN\n");}
":"															{printf("COLON\n");}
","				 											{printf("COMMA\n");}
do															{printf("DO\n"); }
"."															{printf("DOT\n");}
else														{printf("ELSE\n");}
end															{printf("END\n");}
forward														{printf("FORWARD\n");}
function													{printf("FUNCTION\n");}
if															{printf("IF\n");}
"("				 											{printf("LBRAC\n");}
not															{printf("NOT\n");}
output														{printf("OUTPUT\n");}
paramstr													{printf("PARAMSTR\n");}
program														{printf("PROGRAM\n");}
")"				 											{printf("RBRAC\n");}
repeat														{printf("REPEAT\n");}
";"				 											{printf("SEMIC\n");}
then														{printf("THEN\n");}
until														{printf("UNTIL\n");}
val															{printf("VAL\n");}	
var															{printf("VAR\n");}
while														{printf("WHILE\n");}
writeln														{printf("WRITELN\n");}
and|or														{printf("OP1(%s)\n", yytext);}
"<"|">"|"="|"<>"|"<="|">="									{printf("OP2(%s)\n", yytext);}
"+"|"-"				 										{printf("OP3(%s)\n", yytext);}
"*"|"/"|mod|div												{printf("OP4(%s)\n", yytext);}

abs|arctan|array|case|char|chr|const|cos|dispose|div|downto|eof|eoln|exp|file|for|function|get|goto|in|input|label|ln|maxint|new|nil|odd|of|ord|output|pack|packed|page|pred|procedure|put|record|read|readln|reset|rewrite|round|set|sin|sqr|sqrt|succ|text|type|to|trunc|unpack|until|var|with|write 																							{printf("RESERVED(%s)\n", yytext);}
	
[a-zA-Z][0-9a-zA-Z]*										{printf("ID(%s)\n", yytext);}

{whitespace}												{;}
\n															{col=1;}
.															{printf("Line %d, col %d: illegal character ('%s')\n", yylineno, col - (int)yyleng, yytext); /* Some illegal characters are parsed twice*/ }

%%
int main(){
	yylex();
	return 0;
}

int yywrap(){
	return 1;
}
