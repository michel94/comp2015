
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
	printf2("%s%s = %s %s %s\n", 
		global ? "@" : "%",
		var_name, 
		global ? "global" : "alloca",
		type2llvm(type),
		global ? type == REAL_T ? "0.000000e+00" : "0" : "");
}

void writeln_init(){
	printf("declare i32 @printf(i8*, ...)\n");
	printf("@.newline = private unnamed_addr constant [2 x i8] c\"\\0A\\00\"\n");
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

	writeln_init();
}

void function_gen(Node* p){
	element_t** it;

	int f_id = fetch_func(p->op[0]->value);
	hashtable_t* h = symbol_tables[f_id];

	type_t type = h->next[0]->type;
	printf2("define %s @%s(", type2llvm(type), p->op[0]->value);
	for(it = h->next+1; it != h->last; ++it){
		if((*it)->flag == VARPARAM_F){
			if(it != h->next+1) printf(", ");
			printf("%s* %%%s", type2llvm((*it)->type), (*it)->name);
		}else if((*it)->flag == PARAM_F){
			if(it != h->next+1) printf(", ");
			printf("%s %%%s", type2llvm((*it)->type), (*it)->name);
		}else
			break;

	}

	printf2(") {\n");

	code_gen(p->op[3]);
	
	// TODO: LATER CHANGE RETURN VALUE TO ITS OWN VARIABLE
	printf("ret %s 1\n}\n", type2llvm(type));
}

void ifelse_gen(Node *p){

}

void writeln_gen(Node *p){
	if(!p->n_op)
		printf2("\tcall i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([2 x i8]* @.newline, i32 0, i32 0))\n");
	else {
		
	}
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
	}else if(!strcmp(p->type, "IfElse")){
		ifelse_gen(p);
	}else if(!strcmp(p->type, "WriteLn")){
		writeln_gen(p);
	}else{
		for(i = 0; i < p->n_op; i++)
			code_gen(p->op[i]);
	}

}