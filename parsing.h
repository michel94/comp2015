
#include "types.h"

#define OUTER_ST 0
int PROGRAM_ST;

hashtable_t* symbol_tables[TABLE_SIZE];
int st_pointer, st_size=0;

int parse_tree(Node* p);

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
	for(i=OUTER_ST+1; i<st_size; i++){
		if(strcmp(symbol_tables[i]->func, s) == 0){
			return i;
		}
	}
	return -1;
}

int parse_funchead(char* name, int n_args, Node** args, char* ret_type){
	int i;
	st_pointer = st_size++;
	
	symbol_tables[st_pointer] = new_hashtable(TABLE_SIZE, "Function");
	strcpy(symbol_tables[st_pointer]->func, name);
	if(!type_is_valid(ret_type)){
		printf("Cannot write values of type %s\n", ret_type);
		return 1;
	}
	else{
		element_t* el = store(symbol_tables[st_pointer], name, vartype(ret_type) );
		el->flag = RETURN_F;
		store(symbol_tables[PROGRAM_ST], name, FUNCTION_T);
		for(i = 0; i < n_args; i++)
			if(parse_tree(args[i])) return 1;
	}

	return 0;

}

int is_int(Node* p){
	return p->op_type == INTEGER_T;
}

int is_boolean(Node* p){
	return p->op_type == BOOLEAN_T;
}

int is_real(Node* p){
	return p->op_type == REAL_T;
}

void print_op_error(Node *p){
	printf("Line %d, col %d: Operator %s cannot be applied to types %s, %s\n", 
		p->loc.first_line, p->loc.first_column, p->type, type2string(p->op[0]->op_type), type2string(p->op[1]->op_type) );
}

void print_assign_error(Node *p){
	printf("Line %d, col %d: Incompatible type in assignment to %s (got %s, expected %s)\n", 
		p->loc.first_line, p->loc.first_column, p->op[0]->value2, type2string(p->op[1]->op_type), type2string(p->op[0]->op_type));
}

void print_unary_error(Node *p){
	printf("Line %d, col %d: Operator %s cannot be applied to type %s\n", 
		p->loc.first_line, p->loc.first_column, p->type, type2string(p->op[0]->op_type));
}

void print_stat_error(Node* p, type_t type1, type_t type2){
	if(!strcmp(p->type, "IfElse"))
		printf("Line %d, col %d: Incompatible type in if-else statement",
			p->loc.first_line, p->loc.first_column);
	else if(!strcmp(p->type, "While"))
		printf("Line %d, col %d: Incompatible type in while statement",
			p->loc.first_line, p->loc.first_column);
	else
		printf("Line %d, col %d: Incompatible type in repeat-until statement",
			p->loc.first_line, p->loc.first_column);
	
	printf(" (got %s, expected %s)\n", type2string(type1), type2string(type2));
}

void print_already_def_error(Node* p){
	printf("Line %d, col %d: Symbol %s already defined\n", p->loc.first_line, p->loc.first_column, p->value2);
}

int parse_op(Node* p){ // +,-,*
	if(parse_tree(p->op[0])) return 1;
	if(parse_tree(p->op[1])) return 1;
	
	if(is_boolean(p->op[0]) || is_boolean(p->op[1]) ){
		print_op_error(p);
		return 1;
	}else if(is_int(p->op[0]) && is_int(p->op[1]) ){
		p->op_type = INTEGER_T;
	}else{
		p->op_type = REAL_T;
	}
	return 0;

}

int parse_assign(Node* p){
	if(parse_tree(p->op[0])) return 1;
	if(parse_tree(p->op[1])) return 1;
	
	if(is_int(p->op[0]) && !is_int(p->op[1]) || is_real(p->op[0]) && is_boolean(p->op[1]) || is_boolean(p->op[0]) && !is_boolean(p->op[1]) ){
		print_assign_error(p);
		return 1;
	}
	return 0;
}

int parse_boolop(Node* p){ // or,and
	if(parse_tree(p->op[0])) return 1;
	if(parse_tree(p->op[1])) return 1;
	
	if(!is_boolean(p->op[0]) || !is_boolean(p->op[1])){
		print_op_error(p);
		return 1;
	}else{
		p->op_type = BOOLEAN_T;
	}
	return 0;

}

int parse_compop(Node* p){ // <,=,>,<=,>=
	if(parse_tree(p->op[0])) return 1;
	if(parse_tree(p->op[1])) return 1;

	if(is_boolean(p->op[0]) || is_boolean(p->op[1]) ){
		print_op_error(p);
		return 1;
	}else
		p->op_type = BOOLEAN_T;
	return 0;
}

int parse_unary(Node* p){
	if(parse_tree(p->op[0])) return 1;

	if(!strcmp(p->type, "Not") ){
		if(!is_boolean(p->op[0])){
			print_unary_error(p);
			return 1;
		}else
			p->op_type = BOOLEAN_T;
	}else{
		if(is_boolean(p->op[0])){
			print_unary_error(p);
			return 1;
		}else
			p->op_type = p->op[0]->op_type;
	}
	return 0;

}

int parse_id(Node* p){
	element_t * t = fetch(symbol_tables[st_pointer], p->value);
	if(t != NULL){
		p->op_type = t->type;
		return 0;
	}
	t = fetch(symbol_tables[PROGRAM_ST], p->value);
	if(t != NULL){
		p->op_type = t->type;
		return 0;
	}
	t = fetch(symbol_tables[OUTER_ST], p->value);
	if(t != NULL){
		p->op_type = t->type;
		return 0;
	}

	printf("Line %d, col %d: Symbol %s not defined\n", p->loc.first_line, p->loc.first_column, p->value);
	return 1;

}

int parse_intop(Node* p){
	if(parse_tree(p->op[0])) return 1;
	if(parse_tree(p->op[1])) return 1;
	
	if(!is_int(p->op[0]) || !is_int(p->op[1])){
		print_op_error(p);
		return 1;
	}else
		p->op_type = INTEGER_T;

	return 0;
}

int parse_realop(Node* p){ // USED ONCE
	if(parse_tree(p->op[0])) return 1;
	if(parse_tree(p->op[1])) return 1;
	
	if(is_boolean(p->op[0]) || is_boolean(p->op[1])){
		print_op_error(p);
		return 1;
	}else
		p->op_type = REAL_T;

	return 0;
}

int parse_var(Node *p, type_t type, flag_t flag){

	element_t *t = fetch(symbol_tables[st_pointer], p->value);
	if(t != NULL){
		print_already_def_error(p);
		return 1;
	}
	t = store(symbol_tables[st_pointer], p->value, type);
	t->flag = flag;

	return 0;
}

int parse_if_while(Node* p){
	if(parse_tree(p->op[0])) return 1;
	if(parse_tree(p->op[1])) return 1;
	if(parse_tree(p->op[2])) return 1;

	if(!is_boolean(p->op[0])){
		print_stat_error(p, p->op[0]->op_type, BOOLEAN_T);
		return 1;
	}

	return 0;

}

int parse_repeat(Node* p){
	if(parse_tree(p->op[0])) return 1;
	if(parse_tree(p->op[1])) return 1;
	if(parse_tree(p->op[2])) return 1;

	if(!is_boolean(p->op[1])){
		print_stat_error(p, p->op[1]->op_type, BOOLEAN_T);
		return 1;
	}

	return 0;
}

int parse_decl(Node* p, flag_t flag){
	if(!type_is_valid(p->op[p->n_op-1]->value)){
		printf("Line %d, col %d: Type identifier expected\n", p->loc.first_line, p->loc.first_column);
		return 1;
	}
	type_t type = vartype(p->op[p->n_op-1]->value);

	int i;
	for(i = 0; i < p->n_op-1; i++){
		if(parse_var(p->op[i], type, flag)) return 1;
	}

	return 0;
}

int parse_call(Node* p){
	int f_st = fetch_func(p->op[0]->value), i;

	if(f_st == -1){
		printf("Function identifier expected TODO\n");
		return 1;
	}
	for(i=1; i<p->n_op; i++){
		if(parse_tree(p->op[i])) return 1;
	}
	symbol_tables[f_st]->next[0];
	int n_args_def = 0;

	type_t types[TABLE_SIZE];
	element_t** el;
	for(el = symbol_tables[f_st]->next+1; el != symbol_tables[f_st]->last; ++el){
		flag_t flag = (*el)->flag;
		if(flag != VARPARAM_F && flag != PARAM_F)
			break;
		types[n_args_def] = (*el)->type;
		n_args_def++;
	}
	//printf("%d %d\n", p->n_op-1, n_args_def); // do not remove, useful for debug 
	if(p->n_op-1 != n_args_def){
		printf("Wrong number of arguments in call to function <token> (got <type>, expected <type>) TODO\n");
		return 1;
	}
	for(i=0; i<n_args_def; i++){
		type_t t1, t2;
		t1 = types[i];
		t2 = p->op[i+1]->op_type;
		if(t1 == INTEGER_T && t2 != INTEGER_T || t1 == BOOLEAN_T && t2 != BOOLEAN_T || t1 == REAL_T && t2 == BOOLEAN_T){
			printf("Wrong number of arguments in call to function <token> (got <type>, expected <type>) TODO\n");
			return 1;
		}
	}
	type_t func_type = symbol_tables[f_st]->next[0]->type;
	p->op_type = func_type;
	return 0;

}


int parse_tree(Node* p){
	int stp_backup, i;
	stp_backup = st_pointer;
	
	if(p == NULL)
		return 0;

	if(strcmp(p->type, "Program") == 0){
		st_pointer = st_size++;
		
		symbol_tables[st_pointer] = new_hashtable(TABLE_SIZE, "Program");
		PROGRAM_ST = st_pointer;
		for(i = 1; i < p->n_op; i++)
			if(parse_tree(p->op[i])) return 1;
		
	}else if(strcmp(p->type, "FuncDef") == 0){
		if(parse_funchead(p->op[0]->value, p->n_op-3, p->op+1, p->op[p->n_op-3]->value)) return 1;
		
		if(parse_tree(p->op[p->n_op-2])) return 1;
		if(parse_tree(p->op[p->n_op-1])) return 1;
	}else if(strcmp(p->type, "FuncDef2") == 0){
		st_pointer = fetch_func(p->op[0]->value);
		if(st_pointer == -1)
			printf("Function identifier expected???");
		else
			for(i = 0; i < p->n_op; i++)
				if(parse_tree(p->op[i])) return 1;
	}else if(strcmp(p->type, "FuncDecl") == 0){
		return parse_funchead(p->op[0]->value, p->n_op-1, p->op+1, p->op[p->n_op-1]->value);
		
	}else if(strcmp(p->type, "Params") == 0){
		return parse_decl(p, PARAM_F);
		
	}else if(strcmp(p->type, "VarParams") == 0){
		return parse_decl(p, VARPARAM_F);
		
	}else if(strcmp(p->type, "VarDecl") == 0){
		return parse_decl(p, NONE_F);

	}else if(!strcmp(p->type, "Add") || !strcmp(p->type, "Sub") || !strcmp(p->type, "Mul") ){
		return parse_op(p);
	}else if(!strcmp(p->type, "Or") || !strcmp(p->type, "And") ){
		return parse_boolop(p);
	}else if(!strcmp(p->type, "Lt") || !strcmp(p->type, "Gt") || !strcmp(p->type, "Eq") || !strcmp(p->type, "Leq") || !strcmp(p->type, "Geq") || !strcmp(p->type, "Neq") ){
		return parse_compop(p);
	}else if(!strcmp(p->type, "Minus") || !strcmp(p->type, "Plus") || !strcmp(p->type, "Not") ){
		return parse_unary(p);
	} else if(!strcmp(p->type, "RealDiv")){
		return parse_realop(p);
	}else if(!strcmp(p->type, "Div") || !strcmp(p->type, "Mod")){
		return parse_intop(p);
	}else if(!strcmp(p->type, "IntLit") ){
		p->op_type = INTEGER_T;
	}else if(!strcmp(p->type, "RealLit")){
		p->op_type = REAL_T;
	}else if(!strcmp(p->type, "Id")){
		return parse_id(p);
	}else if(!strcmp(p->type, "Assign")){
		return parse_assign(p);
	}else if(!strcmp(p->type, "IfElse") || !strcmp(p->type, "While")){
		return parse_if_while(p);
	}else if(!strcmp(p->type, "Repeat")){
		return parse_repeat(p);
	}else if(!strcmp(p->type, "Call")){
		return parse_call(p);
	}else{
		for(i = 0; i < p->n_op; i++){
			if(parse_tree(p->op[i])) return 1;
		}
	}

	st_pointer = stp_backup;

	return 0;
}
