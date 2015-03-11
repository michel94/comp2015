%option caseless

num									[0-9]+
letter								[a-zA-Z]+
whitespace							[\n\t ]

%%

({num}"."{num})|({num}e[+-]?{num}) 			{printf("REALLIT(%s)\n", yytext); } 
{num}										{printf("INTLIT(%s)\n", yytext); }

'([^'\n]|'')+'								{yytext[strlen(yytext)-1]=0; printf("STRING('%s')\n", yytext+1); }
'([^'\n]|'')+								{printf("Line 33, col 33: unterminated string\n"); }
(\{|"(*")[^("}"|"*)")]*(\}|"*)")			{; /*comments are ignored*/ }
(\{|"(*")[^("}"|"*)")]						{printf("Line 33, col 33: unterminated comment %s\n", yytext); }

":="										{printf("ASSIGN\n");}
begin										{printf("BEGIN\n");}
":"											{printf("COLON\n");}
","				 							{printf("COMMA\n");}
do											{printf("DO\n"); }
"."											{printf("DOT\n");}
else										{printf("ELSE\n");}
end											{printf("END\n");}
forward										{printf("FORWARD\n");}
function									{printf("FUNCTION\n");}
if											{printf("IF\n");}
"("				 							{printf("LBRAC\n");}
not											{printf("NOT\n");}
output										{printf("OUTPUT\n");}
paramstr									{printf("PARAMSTR\n");}
program										{printf("PROGRAM\n");}
")"				 							{printf("RBRAC\n");}
repeat										{printf("REPEAT\n");}
";"				 							{printf("SEMIC\n");}
then										{printf("THEN\n");}
until										{printf("UNTIL\n");}
val											{printf("VAL\n");}	
var											{printf("VAR\n");}
while										{printf("WHILE\n");}
writeln										{printf("WRITELN\n");}
and											{printf("OP1(%s)\n", yytext);}
or											{printf("OP1(%s)\n", yytext);}
"<"|">"|"="|"<>"|"<="|">="					{printf("OP2(%s)\n", yytext);}
"+"|"-"				 						{printf("OP3(%s)\n", yytext);}
"*"|"/"										{printf("OP4(%s)\n", yytext);}
mod											{printf("OP4(%s)\n", yytext);}
div											{printf("OP4(%s)\n", yytext);}
	
[a-zA-Z][0-9a-zA-Z]*						{printf("ID(%s)\n", yytext);}

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
