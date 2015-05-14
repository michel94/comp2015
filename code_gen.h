
void code_gen(Node* p);

int tabs = 0;

void printf2(char* str, ...){
	int i;
	for(i=0; i<tabs; i++)
		putchar('\t');

	va_list vl;
	va_start(vl, str);
	vprintf(str, vl);
	va_end(vl);
}

void print_function(type_t type, char* name, hashtable_t* h){
	printf2("define %s @%s(", type2llvm(type), name);
	
	printf2(") {\n");

}

void print_decl(char* var_name, type_t type, int global){
	printf2("%s%s = alloca %s\n", global ? "@" : "%%", var_name, type2llvm(type));
}

void program_gen(Node* p){
	Node* var_decl = p->op[1];
	int decl, i;

	for(decl = 0; decl < p->op[1]->n_op; decl++){
		var_decl = p->op[1]->op[decl];
		type_t type = vartype(var_decl->op[var_decl->n_op-1]->value);
		for(i = 0; i < var_decl->n_op-1; i++){
			print_decl(var_decl->op[i]->value, type, 1);
		}
		
	}

	code_gen(p->op[2]);

	print_function(INTEGER_T, "main", NULL);
	code_gen(p->op[3]);
	
	printf2("\tret i32 0\n}\n");

}
void function_gen(Node* p){

	int f_id = fetch_func(p->op[0]->value);
	hashtable_t* h = symbol_tables[f_id];

	type_t type = (*h->next)->type;
	printf2("define %s @%s(", type2llvm(type), p->op[0]->value);
	for(element_t** it = h->next+1; it != h->last; ++it){

		if((*it)->flag == VARPARAM_F){
			if(it != h->next+1) printf(", ");
			printf("%s* %s", (*it)->name, type2llvm((*it)->type));
		}else if((*it)->flag == PARAM_F){
			if(it != h->next+1) printf(", ");
			printf("%s %s", (*it)->name, type2llvm((*it)->type));
		}else
			break;

	}

	printf2(") {\n");

	printf("}\n");
}

void code_gen(Node* p){
	int i;
	if(p == NULL)
		return;

	if(strcmp(p->type, "Program") == 0){
		program_gen(p);
	}else if(strcmp(p->type, "VarDecl") == 0){
		type_t type = vartype(p->op[p->n_op-1]->value);
		for(i = 0; i < p->n_op-1; i++){
			print_decl(p->op[i]->value, type, 0);
		}
	}else if(strcmp(p->type, "FuncDef") == 0){
		//print_function()
		function_gen(p);
	}else{
		for(i = 0; i < p->n_op; i++)
			code_gen(p->op[i]);
	}

}