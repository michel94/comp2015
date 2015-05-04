#ifndef TYPES_H
#define TYPES_H

#include "y.tab.h"
#define TABLE_SIZE 1024

typedef enum {INTEGER_T, BOOLEAN_T, REAL_T, TYPE_T, FUNCTION_T, PROGRAM_T, NONE_T} type_t;
typedef enum {CONSTANT_F, RETURN_F, PARAM_F, VARPARAM_F, NONE_F, FUNCDECL_F} flag_t;
typedef enum {BOOLEAN_V, INTEGER_V, REAL_V, FALSE_V, TRUE_V, NONE_V} value_t;

typedef struct node {
	int to_use;
	int n_op;

	char *value2;
	char *value;
	char *type;
	char *token;

	type_t op_type;

	struct node **op;

	YYLTYPE loc;
} Node;

int vartype(char* s){
	if(strcmp(s, "integer") == 0)
		return INTEGER_T;
	else if(strcmp(s, "real") == 0)
		return REAL_T;
	else if(strcmp(s, "boolean") == 0)
		return BOOLEAN_T;
}

char* type2string(type_t type){
	switch(type){
		case(INTEGER_T):
			return "_integer_";
		case(REAL_T):
			return "_real_";
		case(TYPE_T):
			return "_type_";
		case(PROGRAM_T):
			return "_program_";
		case(FUNCTION_T):
			return "_function_";
		case(BOOLEAN_T):
			return "_boolean_";
		default:
			return "_undefined_";
	}
}

char* flag2string(type_t type){
	switch(type){
		case(CONSTANT_F):
			return "constant";
		case(RETURN_F):
			return "return";
		case(PARAM_F):
			return "param";
		case(VARPARAM_F):
			return "varparam";
		case(NONE_F):
			return "";
		default:
			return "undefined";
	}
}

char* value2string(type_t type){
	switch(type){
		case(BOOLEAN_V):
			return "_boolean_";
		case(INTEGER_V):
			return "_integer_";
		case(REAL_V):
			return "_real_";
		case(FALSE_V):
			return "_false_";
		case(TRUE_V):
			return "_true_";
		default:
			return "undefined";
	}
}

void to_lower(char *value){
	char *s;
	for(s = value; *s != '\0'; s++)
		*s = tolower(*s);
}

int is_int(Node* p){ return p->op_type == INTEGER_T; }
int is_real(Node* p){ return p->op_type == REAL_T; }
int is_boolean(Node* p){ return p->op_type == BOOLEAN_T; }
int is_type(Node* p){ return p->op_type == TYPE_T; }
int is_string(Node* p){ return p->op_type == NONE_T; }
int is_real_or_int(Node* p){ return p->op_type == REAL_T || p->op_type == INTEGER_T; }

Node *new_node(){ return (Node *) malloc(sizeof(Node)); }

#endif
