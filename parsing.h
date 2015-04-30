
#include "types.h"

#define OUTER_ST 0
int PROGRAM_ST;

hashtable_t* symbol_tables[TABLE_SIZE];
int st_pointer, st_size=0;

void parse_tree(Node* p);

int type_is_valid(char* ret_type){
	element_t* t = fetch(symbol_tables[OUTER_ST], ret_type);
	if(t == NULL || t->type != TYPE_T)
		return 0;
	return 1;
}

int fetch_func(char* s){
	int i;
	if(fetch(symbol_tables[PROGRAM_ST], s) == NULL){
		return -1;
	}
	for(i=PROGRAM_ST+1; i<st_size; i++){
		if(strcmp(symbol_tables[i]->func, s) == 0){
			return i;
		}
	}
	return -1;
}

void parse_funchead(char* name, int n_args, Node** args, char* ret_type){
	int i;
	st_pointer = st_size++;
	
	symbol_tables[st_pointer] = new_hashtable(TABLE_SIZE, "Function");
	strcpy(symbol_tables[st_pointer]->func, name);
	if(!type_is_valid(ret_type))
		printf("Cannot write values of type <%s>\n", ret_type);
	else{
		element_t* el = store(symbol_tables[st_pointer], name, vartype(ret_type) );
		el->flag = RETURN_F;
		store(symbol_tables[PROGRAM_ST], name, FUNCTION_T);
		for(i = 0; i < n_args; i++)
			parse_tree(args[i]);
	}

}

int is_int(Node* p){
	return p->op_type == INTEGER_T;
}

int is_boolean(Node* p){
	return p->op_type == BOOLEAN_T;
}

void print_stat(char* stat, type_t type1, type_t type2){
	printf("Incompatible type in statement %s (got %s, expected %s)", stat, type2string(type1), type2string(type2) );
}

void parse_op(Node* p){ // +,-,/,*
	parse_tree(p->op[0]);
	parse_tree(p->op[1]);

	if(is_boolean(p->op[0]) || is_boolean(p->op[1]) ){
		if(is_boolean(p->op[0]))
			;//printf("Incompatible type in statement %s (got %s, expected real/int?)", p->type, p->op_type);
		if(is_boolean(p->op[1]))
			;//printf("Incompatible type in statement %s (got %s, expected real/int?)", p->type, p->op_type);
	}
	else if(is_int(p->op[0]) && is_int(p->op[1]) )
		p->op_type = INTEGER_T;
	else
		p->op_type = REAL_T;
}

void parse_boolop(Node* p){ // or,and
	parse_tree(p->op[0]);
	parse_tree(p->op[1]);

	if(!is_boolean(p->op[0]) || !is_boolean(p->op[1])){
		if(!is_boolean(p->op[0]))
			;//printf("Incompatible type in statement %s (got %s, expected boolean)", p->type, p->op_type); // Dar fix disto???
		if(!is_boolean(p->op[1]))
			;//printf("Incompatible type in statement %s (got %s, expected boolean)", p->type, p->op_type);
	}else{
		p->op_type = BOOLEAN_T;
	}


}

void parse_compop(Node* p){ // <,=,>,<=,>=
	parse_tree(p->op[0]);
	parse_tree(p->op[1]);

	if(is_boolean(p->op[0]) || is_boolean(p->op[1]) ){
		if(is_boolean(p->op[0]))
			;//printf("Incompatible type in statement %s (got %s, expected real/int?)\n", p->type, p->op_type);
		if(is_boolean(p->op[1]))
			;//printf("Incompatible type in statement %s (got %s, expected real/int?)\n", p->type, p->op_type);
	}
	else
		p->op_type = BOOLEAN_T;
}


void parse_unary(Node* p){
	parse_tree(p->op[0]);
	if(strcmp(p->type, "Not") ){
		if(!is_boolean(p->op[0]))
			;//printf("Incompatible type in statement %s (got %s, expected real/int?)\n", p->type, p->op_type);
		else
			p->op_type = BOOLEAN_T;
	}else{
		if(!is_boolean(p->op[0]))
			;//printf("Incompatible type in statement %s (got %s, expected real/int?)\n", p->type, p->op_type);
		else
			p->op_type = p->op[0]->op_type;
	}

}


void parse_tree(Node* p){
	int stp_backup, i;
	stp_backup = st_pointer;
	
	if(p == NULL)
		return;
	
	if(strcmp(p->type, "Program") == 0){
		st_pointer = st_size++;
		
		symbol_tables[st_pointer] = new_hashtable(TABLE_SIZE, "Program");
		PROGRAM_ST = st_pointer;
		for(i = 0; i < p->n_op; i++)
			parse_tree(p->op[i]);
		
	}else if(strcmp(p->type, "FuncDef") == 0){
		parse_funchead(p->op[0]->value, p->n_op-3, p->op+1, p->op[p->n_op-3]->value);
		
		parse_tree(p->op[p->n_op-2]);
		parse_tree(p->op[p->n_op-1]);

	}else if(strcmp(p->type, "FuncDef2") == 0){
		st_pointer = fetch_func(p->op[0]->value);
		if(st_pointer == -1)
			;//printf("Function identifier expected???");
		else
			for(i = 0; i < p->n_op; i++)
				parse_tree(p->op[i]);

	}else if(strcmp(p->type, "FuncDecl") == 0){

		parse_funchead(p->op[0]->value, p->n_op-1, p->op+1, p->op[p->n_op-1]->value);
		
	}else if(strcmp(p->type, "Params") == 0){
		for(i = 0; i < p->n_op-1; i++){
			element_t* el = store(symbol_tables[st_pointer], p->op[i]->value, vartype(p->op[p->n_op-1]->value) );
			el->flag = PARAM_F;
		}
	}else if(strcmp(p->type, "VarParams") == 0){
		for(i = 0; i < p->n_op-1; i++){
			element_t* el = store(symbol_tables[st_pointer], p->op[i]->value, vartype(p->op[p->n_op-1]->value) );
			el->flag = VARPARAM_F;
		}
	}else if(strcmp(p->type, "VarDecl") == 0){
		for(i = 0; i < p->n_op-1; i++){
			element_t *el = store(symbol_tables[st_pointer], p->op[i]->value, vartype(p->op[p->n_op-1]->value) );
			el->flag = NONE_F;
		}
	}else if(!strcmp(p->type, "Add") || !strcmp(p->type, "Sub") || !strcmp(p->type, "Mul") || !strcmp(p->type, "RealDiv")){ // Div supports reals??
		parse_op(p);
	}else if(!strcmp(p->type, "Or") || !strcmp(p->type, "And") ){
		parse_compop(p);
	}else if(!strcmp(p->type, "Lt") || !strcmp(p->type, "Gt") || !strcmp(p->type, "Eq") || !strcmp(p->type, "Leq") || !strcmp(p->type, "Geq") || !strcmp(p->type, "Neq") ){
		parse_unary(p);
	}else if(!strcmp(p->type, "IntLit")){
		p->op_type = INTEGER_T;
	}else if(!strcmp(p->type, "RealLit")){
		p->op_type = REAL_T;
	}else{
		for(i = 0; i < p->n_op; i++){
			parse_tree(p->op[i]);
		}
	}


	st_pointer = stp_backup;

}
