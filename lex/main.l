%option caseless
%option yylineno

%X COMMENT

num									[0-9]+
whitespace							[\n\t ]

%%

({num}"."{num})|({num}e[+-]?{num})|({num}.{num}e[+-]?{num}) {printf("REALLIT(%s)\n", yytext);}
{num}														{printf("INTLIT(%s)\n", yytext);}

'([^'\n]|'')+'												{yytext[strlen(yytext)-1]=0; printf("STRING('%s')\n", yytext+1);}
'([^'\n]|'')+												{printf("Line %d, col 33: unterminated string\n", yylineno);}

"{"|"(*"													{BEGIN COMMENT; }
<COMMENT>"}"|"*)"											{BEGIN 0; }
<COMMENT>.|\n												{; }

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

abs|arctan|char|chr|cos|dispose|eof|eoln|exp|for|get|input|ln|maxint|new|odd|ord|output|pack|page|pred|put|read|readln|reset|rewrite|round|sin|sqr|sqrt|succ|text|to|trunc|unpack|write 										{printf("RESERVED(%s)\n", yytext);}
	
[a-zA-Z][0-9a-zA-Z]*										{printf("ID(%s)\n", yytext);}

{whitespace}												{;}
.															{printf("Line 33, col 33: illegal character ('%s')\n", yytext); /* Some illegal characters are parsed twice*/ }


%%
int main(){
	yylex();
	return 0;
}

int yywrap(){
	return 1;
}
