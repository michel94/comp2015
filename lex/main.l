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

({num}"."{num})|({num}e[+-]?{num})|({num}.{num}e[+-]?{num}) {printf("REALLIT(%s)\n", yytext); yylval = atoi(yytext); return NUMBER; }
{num}														{printf("INTLIT(%s)\n", yytext); yylval = atof(yytext); return NUMBER; }

'([^'\n]|'')*'												{yytext[strlen(yytext)-1]=0; printf("STRING('%s')\n", yytext+1); strcpy(yylstr, yytext); return STRING; }
'([^'\n]|'')*												{printf("Line %d, col %d: unterminated string\n", yylineno, col - (int)yyleng);}

"{"|"(*"													{BEGIN COMMENT; stcol = col-yyleng; stline = yylineno; }
<COMMENT>"}"|"*)"											{BEGIN 0; }
<COMMENT>.													{; }
<COMMENT>\n 												{col = 1; }
<COMMENT><<eof>>	 										{printf("Line %d, col %d: unterminated comment\n", stline, stcol); return 0; }

":="														{return ASSIGN; }
begin														{return BEGIN; }
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
"<="														{return LE; }
">="														{return GE; }
"<"|">"|"="|"+"|"-"|"*"|"/"|":"|","|"."|"("|")"|";"			{return yytext[0]; }
mod															{return MOD; }
div															{return DIV; }

abs|arctan|array|case|char|chr|const|cos|dispose|div|downto|eof|eoln|exp|file|for|get|goto|in|input|label|ln|maxint|new|nil|odd|of|ord|output|pack|packed|page|pred|procedure|put|record|read|readln|reset|rewrite|round|set|sin|sqr|sqrt|succ|text|type|to|trunc|unpack|with|write 	{printf("RESERVED(%s)\n", yytext);}

[a-zA-Z][0-9a-zA-Z]*										{printf("ID(%s)\n", yytext); strcpy(yylstr, yytext); return ID;}

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
