num				 [0-9]+
letter					[a-zA-Z]+
whitespace					[\n\t ]

%%

{num}"."{num}|{num}.{num}e[+-]?{num}|{num}e[-+]?{num} {printf("REALLIT(%s)\n", yytext); } 
{num}										{printf("INTLIT(%s)\n", yytext); }

'([^'\n]|'')+'								{yytext[strlen(yytext)-1]=0; printf("STRING(%s)\n", yytext+1); }
'([^'\n]|'')+								{printf("Line 33, col 33: unterminated string\n"); }
(\{|"(*")[^"}""\*\)"]*(\}|"*)")				{; /*comments are ignored*/ }
(\{|"(*")[^"}""\*\)"]*						{printf("Line 33, col 33: unterminated comment %s\n", yytext); }

":="										{printf("ASSIGN\n");}
[bB][eE][gG][iI][nN]						{printf("BEGIN\n");}
":"											{printf("COLON\n");}
","				 							{printf("COMMA\n");}
[dD][oO]									{printf("DO\n"); }
"."											{printf("DOT\n");}
[eE][lL][sS][eE]							{printf("ELSE\n");}
[eE][nN][dD]								{printf("END\n");}
[fF][oO][rR][wW][aA][rR][dD]				{printf("FORWARD\n");}
[fF][uU][nN][cC][tT][iI][oO][nN]			{printf("FUNCTION\n");}
[iI][fF]									{printf("IF\n");}
"("				 							{printf("LBRAC\n");}
[nN][oO][tT]								{printf("NOT\n");}
[oO][uU][tT][pP][uU][tT]					{printf("OUTPUT\n");}
[pP][aA][rR][aA][mM][sS][tT][rR]			{printf("PARAMSTR\n");}
[pP][rR][oO][gG][rR][aA][mM]				{printf("PROGRAM\n");}
")"				 							{printf("RBRAC\n");}
[rR][eE][pP][eE][aA][tT]					{printf("REPEAT\n");}
";"				 							{printf("SEMIC\n");}
[tT][hH][eE][nN]							{printf("THEN\n");}
[uU][nN][tT][iI][lL]						{printf("UNTIL\n");}
[vV][aA][lL]								{printf("VAL\n");}
[vV][aA][rR]								{printf("VAR\n");}
[wW][hH][iI][lL][eE]						{printf("WHILE\n");}
[wW][rR][iI][tT][eE][lL][nN]				{printf("WRITELN\n");}
[aA][nN][dD]								{printf("OP1(AND)\n", yytext);}
[oO][rR]									{printf("OP1(OR)\n", yytext);}
"<"|">"|"="|"<>"|"<="|">="					{printf("OP2(%s)\n", yytext);}
"+"|"-"				 						{printf("OP3(%s)\n", yytext);}
"*"|"/"										{printf("OP4(%s)\n", yytext);}
[mM][oO][dD]								{printf("OP4(MOD)\n", yytext);}
[dD][iI][vV]								{printf("OP4(DIV)\n", yytext);}

{letter}[{num}{letter}]*					{printf("ID(%s)\n", yytext);}
{whitespace}								{;}
.											{printf("Line 33, col 33: illegal character ('%s')\n", yytext); /* Some illegal characters are parsed twice*/ }


%%
int main(){
	yylex();
	return 0;
}

int yywrap(){
	return 1;
}