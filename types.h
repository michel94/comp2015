#ifndef TYPES_H
#define TYPES_H

#define TABLE_SIZE 1024

typedef enum {INTEGER_T, BOOLEAN_T, REAL_T, TYPE_T, FUNCTION_T, PROGRAM_T} type_t;
typedef enum {CONSTANT_F, RETURN_F, PARAM_F, VARPARAM_F, NONE_F} flag_t;
typedef enum {BOOLEAN_V, INTEGER_V, REAL_V, FALSE_V, TRUE_V} value_t;

typedef struct node {
	int to_use;
	int n_op;
	
	char *value2;
	char *value;
	char *type;

	type_t op_type;

	struct node **op;
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
			return "integer";
		case(REAL_T):
			return "real";
		case(TYPE_T):
			return "type";
		case(PROGRAM_T):
			return "program";
		case(FUNCTION_T):
			return "function";
		case(BOOLEAN_T):
			return "boolean";
		default:
			return "undefined";
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
			return "boolean";
		case(INTEGER_V):
			return "integer";
		case(REAL_V):
			return "real";
		case(FALSE_V):
			return "false";
		case(TRUE_V):
			return "true";
		default:
			return "undefined";
	}
}


void to_lower(char *value){
	char *s;
	for(s = value; *s != '\0'; s++)
		*s = tolower(*s);
}

#endif