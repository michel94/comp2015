%{

	#include <stdio.h>
	#include <stdarg.h>
	#include <stdlib.h>
	#include <string.h>
	typedef struct node {
		char* type;
		char* value;
		int n_op;
		int to_use;

		struct node **op;
	} Node;

	Node* merge_nodes[1000000];

	extern int yylineno, col, yyleng;
	extern char* yytext;
	int tree=0;

	Node* new_node(){
		return (Node *) malloc(sizeof(Node));
	}

	Node *make_node(char* node_type, int to_use, int node_operands, ...){
		Node *p, **tmp;
		va_list args;
		int i;

		p = new_node();
		p->to_use = to_use;
		//tmp = p->op = 
		tmp = merge_nodes;

		p->type = node_type;
		p->n_op = node_operands;

		int node_count=0;


		va_start(args, node_operands);
		while(node_operands--){
			Node *t = va_arg(args, Node *);
			if(!t->to_use){
				if(strcmp(node_type, "Program") == 0){
					printf("prog_arg: %s %d\n", t->type, t->n_op);
				}
				for(i=0; i<t->n_op; i++){
					if(strcmp(node_type, "Program") == 0){
						printf("prog_arg: %s\n", t->op[i]->type);
					}
					node_count++;
					*tmp++ = t->op[i];
					
				}
			}else{
				node_count++;
				*tmp++ = t;
			}
		}

		va_end(args);

		p->op = (Node **) malloc(node_count * sizeof(Node *));
		memcpy(p->op, merge_nodes, node_count * sizeof(Node *));
		p->n_op = node_count;

		return p;
	}

	Node *terminal(char* node_type, char* value){
		Node* p = new_node();
		p->type = node_type;
		p->value = value;
		p->n_op = 0;
		p->to_use = 1;

		return p;
	}

	void printData(Node* p){
		if(strcmp(p->type, "Id") == 0)
			printf("Id(%s)\n", p->value);
		else
			printf("%s\n", p->type);
	}

	void printNode(Node* p, int d){
		int i, o;
		for(o=0; o<d; o++) putchar('\t');
		printData(p);
		for(i=0; i<p->n_op; i++){
			printNode(p->op[i], d+1);
		}
	}

	void print_ast(int syntax_error){
		if(syntax_error)
			return;
		

	}

%}

%union{
	int val;
	char *str;
	struct node *node;
}

%token <val> INTLIT
%token <str> ID STRING REALLIT

%token NOT AND OR MOD DIV
%token ASSIGN NEQ LEQ GEQ
%token IF THEN ELSE BEG END
%token DO REPEAT UNTIL WHILE
%token VAR VAL FORWARD FUNCTION OUTPUT PARAMSTR PROGRAM WRITELN

%right THEN
%right ELSE

%right ASSIGN
%left NEQ LEQ GEQ '<' '>' '='
%left  OR '+' '-'
%left '*' '/' MOD DIV AND
%left NOT

%type <node> Prog ProgHeading ProgBlock VarPart VarDeclarationList VarDeclaration FuncPart StatPart IdList IdListLoop ID_


%%

Prog: ProgHeading ';' ProgBlock '.' {$$ = make_node("Program", 1, 2, $1, $3); if(tree) printNode($$, 0); };
ProgHeading: PROGRAM ID_ '(' OUTPUT ')' {$$ = make_node("ProgHeading", 0, 1, $2); };
ProgBlock: VarPart FuncPart StatPart {$$ = make_node("ProgBlock", 0, 3, $1, $2, $3); };
VarPart: VAR VarDeclaration ';' VarDeclarationList {$$ = make_node("VarPart", 1, 2, $2, $4);}
	 	| %empty 										{$$ = make_node("VarPart", 0, 0);}
;
VarDeclarationList: VarDeclarationList VarDeclaration ';' {$$ = make_node("VarDeclarationList", 0, 2, $1, $2);} 
		| %empty										{$$ = make_node("VarDeclarationList", 0, 0);}
;
VarDeclaration: IdList ':' ID_							{$$ = make_node("VarDecl", 1, 2, $1, $3); } ;
IdList: ID_ IdListLoop									{$$ = make_node("IdList", 0, 2, $1, $2);};
IdListLoop: IdListLoop ',' ID_ 							{$$ = make_node("IdListLoop", 0, 2, $1, $3);};
		| %empty										{$$ = make_node("IdListLoop", 0, 0);};

ID_ : ID 												{$$ = terminal("Id", $1); };

FuncPart: FuncDeclarationList 							{$$ = make_node("FuncPart", 1, 0); };
FuncDeclarationList: FuncDeclarationList FuncDeclaration ';' | %empty;
FuncDeclaration: FuncHeading ';' FORWARD
	| FuncIdent ';' FuncBlock
	| FuncHeading ';' FuncBlock;
FuncHeading: FUNCTION ID_ NullFormalParam ':' ID_;
FuncIdent: FUNCTION ID_;

FormalParamList: '(' FormalParams FormalParamsListLoop ')';
FormalParams: NullVar IdList ':' ID_;
FuncBlock: VarPart StatPart;
NullVar: VAR | %empty;

FormalParamsListLoop: FormalParamsListLoop ';' FormalParams | %empty;
NullFormalParam: FormalParamList | %empty;

StatPart: CompStat 										{$$ = make_node("StatPart", 1, 0); };
CompStat: BEG StatList END;
StatList: Stat StatListLoop;
StatListLoop: StatListLoop ';' Stat | %empty;
Stat: CompStat
	| IF Expr THEN Stat
	| IF Expr THEN Stat ELSE Stat
	| WHILE Expr DO Stat
	| REPEAT StatList UNTIL Expr
	| VAL '(' PARAMSTR '(' Expr ')' ',' ID_ ')'
	| WRITELN WriteList | WRITELN
	| ID_ ASSIGN Expr
	| %empty;

WriteList: '(' ExprString ExprStringList ')';
ExprStringList: ExprStringList ',' ExprString | %empty;
ExprString: Expr | STRING ;

Expr: Expr AND Expr
	| Expr OR Expr
	| Expr '<' Expr
	| Expr '>' Expr
	| Expr '=' Expr
	| Expr NEQ Expr
	| Expr LEQ Expr
	| Expr GEQ Expr
	| Expr '+' Expr
	| Expr '-' Expr
	| Expr '*' Expr
	| Expr '/' Expr
	| Expr DIV Expr
	| Expr MOD Expr
	| '+' Expr
	| '-' Expr
	| NOT Expr
	| '(' Expr ')'
	| INTLIT | REALLIT
	| ID_ ParamList | ID_;

ParamList: '(' Expr ExprList ')';

ExprList: ExprList ',' Expr | %empty;

%%

int main(int argc, char **argv){

	// SIMPLER THIS WAY
	// if(!tmp)

	while(argc--)
		if(!strcmp(*argv++, "-t")){
			tree = 1;
			//print_ast(tmp);
		}

	int tmp = yyparse();

	return 0;
}

int yyerror(char *s){
	printf("Line %d, col %d: %s: %s\n", yylineno, col - (int)yyleng, s, yytext);
}

