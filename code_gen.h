#define print_code 0

void code_gen(Node* p);

int tabs = 0;
int r_count = 1;
int l_count = 1;

FILE* out_file;

void printf2(char* str, ...){
	int i;
	for(i=0; i<tabs; i++)
		putchar('\t');

	va_list vl;
	va_start(vl, str);
	vfprintf(out_file, str, vl);
	if(print_code){
		va_start(vl, str);
		vprintf(str, vl);
	}

	va_end(vl);
}

void print_decl(char* var_name, type_t type, int global){

	if(!global)
		printf2("%%_%s = alloca %s\n", var_name, type2llvm(type));
	else
		printf2("@_%s = global %s %s\n", var_name, type2llvm(type), type == REAL_T ? "0.000000e+00" : "0");
}

void program_gen(Node* p){

	Node* var_decl = p->op[1];
	int decl, i;

	printf2("@_false = global i1 0\n");
	printf2("@_true = global i1 1\n");

	for(decl = 0; decl < p->op[1]->n_op; decl++){
		var_decl = p->op[1]->op[decl];
		type_t type = vartype(var_decl->op[var_decl->n_op-1]->value);
		for(i = 0; i < var_decl->n_op-1; i++){
			print_decl(var_decl->op[i]->value, type, 1);
		}
	}

	printf2("@argc_ = global i32 0\n");
	printf2("@argv_ = global i8** null\n");

	code_gen(p->op[2]);

	r_count = 1;
	printf2("define %s @main(i32 %%argc, i8** %%argv) {\n", type2llvm(INTEGER_T));
	printf2("%%1 = alloca i32\n");
	printf2("%%2 = alloca i8**\n");
	printf2("store i32 %%argc, i32* %%1\n");
	printf2("store i8** %%argv, i8*** %%2\n");
	printf2("%%3 = load i32* %%1\n");
	printf2("store i32 %%3, i32* @argc_\n");
	printf2("%%4 = load i8*** %%2\n");
	printf2("store i8** %%4, i8*** @argv_\n\n");
	r_count = 5;

	st_pointer = PROGRAM_ST;
	code_gen(p->op[3]);
	
	printf2("ret i32 0\n}\n");
}

void function_gen(Node* p){
	r_count = 1;
	element_t** it;

	int f_id = fetch_func(p->op[0]->value);
	hashtable_t* h = symbol_tables[f_id];

	type_t type = h->next[0]->type;
	printf2("define %s @%s(", type2llvm(type), p->op[0]->value);
	for(it = h->next+1; it != h->last; ++it){
		if((*it)->flag == VARPARAM_F){
			if(it != h->next+1) printf2(", ");
			printf2("%s* dereferenceable(8) %%_%s", type2llvm((*it)->type), (*it)->name);
		}else if((*it)->flag == PARAM_F){
			if(it != h->next+1) printf2(", ");
			printf2("%s %%__%s", type2llvm((*it)->type), (*it)->name);
		}else
			break;

	}
	printf2(") {\n");

	print_decl( p->op[0]->value, fetch(h, p->op[0]->value)->type, 0);

	for(it = h->next+1; it != h->last; ++it){
		if((*it)->flag == VARPARAM_F){
			printf2("%%%d = alloca %s*\n", r_count, type2llvm((*it)->type) );
			printf2("store %s* %%_%s, %s** %%%d\n", type2llvm((*it)->type), (*it)->name, type2llvm((*it)->type), r_count++);
		}else if((*it)->flag == PARAM_F){
			printf2("%%_%s = alloca %s\n", (*it)->name, type2llvm((*it)->type));
			printf2("store %s %%__%s, %s* %%_%s\n", type2llvm((*it)->type), (*it)->name, type2llvm((*it)->type), (*it)->name);
		}else
			break;
	}

	code_gen(p->op[p->n_op-2]);
	code_gen(p->op[p->n_op-1]);
	
	code_gen(p->op[0]);
	printf2("ret %s %%%d\n", type2llvm(type), p->op[0]->reg);

	printf2("}\n");
}

char* const_strings[256] = {"\\0A", " ", "%.12F", "%d", "%s", "TRUE", "FALSE"};
int s_const_strings[256] = {1, 1, 5, 2, 2, 4, 5};
int n_const_strings = 7;

const int PRINT_REAL = 2;
const int PRINT_INT = 3;
const int PRINT_STR = 4;
const int PRINT_TRUE = 5;

void printf_call(int str_id, Node* p){
	printf2("%%%d = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([%d x i8]* @.str_%d, i32 0, i32 0)", r_count, s_const_strings[str_id]+1, str_id);
	if(p != NULL){
		printf2(", %s %%%d", type2llvm(p->op_type), p->reg);
	}
	printf2(")\n");
	r_count++;
}

void add_const_string(char * s){
	char s2[64];
	strcpy(s2, s+1);
	int l = strlen(s2);
	s2[l-1] = '\0';
	
	const_strings[n_const_strings] = strdup(s2);
	s_const_strings[n_const_strings] = strlen(s2);
	n_const_strings++;
}

void writeln_gen(Node* p){
	int i;
	for(i=0; i<p->n_op; i++){
		code_gen(p->op[i]);
		if(p->op[i]->op_type == REAL_T){
			printf_call(PRINT_REAL, p->op[i]);
		}else if(p->op[i]->op_type == INTEGER_T){
			printf_call(PRINT_INT, p->op[i]);
		}else if(p->op[i]->op_type == BOOLEAN_T){
			printf2("call void @print_boolean(i1 %%%d)\n", p->op[i]->reg);
		}else{
			add_const_string(p->op[i]->value2);
			printf_call(n_const_strings-1, NULL);
		}
	}
	printf_call(0, NULL);
}

char *get_var(Node* p){
	char s[64];
	if(is_global(p)){
		sprintf(s, "@_%s", p->value);
	}else{
		sprintf(s, "%%_%s", p->value);
	}
	return strdup(s);
}

void print_consts(){

	int i;
	for(i=0; i<n_const_strings; i++){
		printf2("@.str_%d = private unnamed_addr constant [%d x i8] c\"%s\\00\"\n", i, s_const_strings[i]+1, const_strings[i]);
	}
	printf2("\n");

	printf2("declare i32 @atoi(i8*)\n");
	printf2("declare i32 @printf(i8*, ...)\n");

	printf2("define i32 @valparam(i32 %%pos){\n%%1 = alloca i32\nstore i32 %%pos, i32* %%1\n%%2 = load i32* %%1\n%%3 = sext i32 %%2 to i64\n%%4 = load i8*** @argv_\n%%5 = getelementptr inbounds i8** %%4, i64 %%3\n%%6 = load i8** %%5\n%%7 = call i32 @atoi(i8* %%6)\nret i32 %%7\n}\n");
	printf2("define void @print_boolean(i1 %%_b){\nbr i1 %%_b, label %%if_bool, label %%else_bool\nif_bool:\n call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([5 x i8]* @.str_5, i32 0, i32 0))\n br label %%end_bool\nelse_bool:\n call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([6 x i8]* @.str_6, i32 0, i32 0))\n br label %%end_bool\nend_bool: ret void\n}\n");
	
	if(!fetch(symbol_tables[PROGRAM_ST], "paramcount"))
		printf2("define i32 @paramcount(){\n %%1 = load i32* @argc_\nret i32 %%1\n}\n");
}

void ifelse_gen(Node *p){
	int if_label, else_label, ret_label;
	code_gen(p->op[0]);

	if_label   = l_count++;
	else_label = l_count++;
	ret_label  = l_count++;
	printf2("br i1 %%%d, label %%label_%d, label %%label_%d\n\n", p->op[0]->reg, if_label, else_label);

	printf2("label_%d:\n", if_label);
	code_gen(p->op[1]);
	printf2("br label %%label_%d\n", ret_label);
	
	printf2("\nlabel_%d:\n", else_label);
	code_gen(p->op[2]);
	printf2("br label %%label_%d\n", ret_label);

	printf2("\nlabel_%d:\n", ret_label);	
}

int real_cast(Node* p){
	printf2("%%%d = sitofp %s %%%d to double\n", r_count, type2llvm(p->op_type), p->reg );
	return r_count++;
}

void op_gen(Node* p){
	code_gen(p->op[0]);
	code_gen(p->op[1]);
	int reg0 = p->op[0]->reg;
	int reg1 = p->op[1]->reg;
	
	if(p->op_type == REAL_T){
		if(p->op[0]->op_type == INTEGER_T)
			reg0 = real_cast(p->op[0]);
		if(p->op[1]->op_type == INTEGER_T)
			reg1 = real_cast(p->op[1]);
		printf2("%%%d = %s %s %%%d, %%%d\n", r_count, op2llvm(p->type, REAL_T), type2llvm(REAL_T), reg0, reg1);
	}else if(p->op_type == BOOLEAN_T){
		type_t type;

		if(p->op[0]->op_type == REAL_T || p->op[1]->op_type == REAL_T){
			if(p->op[0]->op_type == INTEGER_T)
				reg0 = real_cast(p->op[0]);
			if(p->op[1]->op_type == INTEGER_T)
				reg1 = real_cast(p->op[1]);
			type = REAL_T;
		}else if(p->op[0]->op_type == BOOLEAN_T)
			type = BOOLEAN_T;
		else
			type = INTEGER_T;
		
		printf2("%%%d = %s %s %%%d, %%%d\n", r_count, op2llvm(p->type, type), type2llvm(type), reg0, reg1);
	}else{
		printf2("%%%d = %s %s %%%d, %%%d\n", r_count, op2llvm(p->type, INTEGER_T), type2llvm(p->op_type), reg0, reg1);
	}
	p->reg = r_count++;
}

void unary_gen(Node* p){
	code_gen(p->op[0]);
	int reg0 = p->op[0]->reg;
	if(p->op_type == BOOLEAN_T){
		printf2("%%%d = add i1 %%%d, 1\n", r_count, reg0);
		p->reg = r_count++;
	}else if(!strcmp(p->type, "Minus")){
		printf2("%%%d = %s, %%%d\n", r_count, p->op[0]->op_type == REAL_T ? "fsub double 0.0" : "sub i32 0", reg0);
		p->reg = r_count++;
	}else{
		p->reg = reg0;
	}
}

void vardecl_gen(Node* p){
	int i;
	type_t type = vartype(p->op[p->n_op-1]->value);
	for(i = 0; i < p->n_op-1; i++){
		print_decl(p->op[i]->value, type, 0);
	}
}

void while_gen(Node *p){
	int cmp_label, inside_label, ret_label;

	cmp_label    = l_count++;
	inside_label = l_count++;
	ret_label    = l_count++;
	printf2("br label %%label_%d\n", cmp_label);
	printf2("\nlabel_%d:\n", cmp_label);
	
	code_gen(p->op[0]);
	printf2("br i1 %%%d, label %%label_%d, label %%label_%d\n", p->op[0]->reg, inside_label, ret_label);

	printf2("\nlabel_%d:\n", inside_label);
	code_gen(p->op[1]);
	printf2("br label %%label_%d\n", cmp_label);

	printf2("\nlabel_%d:\n", ret_label);
}

void repeat_gen(Node *p){
	int inside_label, cmp_label, ret_label;

	inside_label = l_count++;
	cmp_label    = l_count++;
	ret_label    = l_count++;
	printf2("br label %%label_%d\n", inside_label);
	printf2("\nlabel_%d:\n", inside_label);
	
	code_gen(p->op[0]);
	printf2("br label %%label_%d\n", cmp_label);

	printf2("\nlabel_%d:\n", cmp_label);
	code_gen(p->op[1]);
	printf2("br i1 %%%d, label %%label_%d, label %%label_%d\n", p->op[1]->reg, inside_label, ret_label);

	printf2("\nlabel_%d:\n", ret_label);
}

void valparam_gen(Node *p){
	code_gen(p->op[0]);
	code_gen(p->op[1]);

	printf2("%%%d = call i32 @valparam(i32 %%%d)\n", r_count, p->op[0]->reg);
	printf2("store i32 %%%d, i32* %s\n", r_count++, get_var(p->op[1]));
}

void code_gen(Node* p){
	int i;
	if(p == NULL)
		return;

	if(strcmp(p->type, "Program") == 0){
		program_gen(p);
		print_consts();
	}else if(strcmp(p->type, "VarDecl") == 0){
		vardecl_gen(p);
	}else if(strcmp(p->type, "FuncDef") == 0 || strcmp(p->type, "FuncDef2") == 0){
		st_pointer = fetch_func(p->op[0]->value);
		function_gen(p);
	}else if(!strcmp(p->type, "Add") || !strcmp(p->type, "Sub") || !strcmp(p->type, "Mul") || !strcmp(p->type, "Or") || !strcmp(p->type, "And")
		|| !strcmp(p->type, "Lt") || !strcmp(p->type, "Gt") || !strcmp(p->type, "Leq") || !strcmp(p->type, "Geq") || !strcmp(p->type, "Eq") || !strcmp(p->type, "Neq") 
		|| !strcmp(p->type, "RealDiv") || !strcmp(p->type, "Div") || !strcmp(p->type, "Mod") ){
		op_gen(p);
	}else if(!strcmp(p->type, "Minus") || !strcmp(p->type, "Plus") || !strcmp(p->type, "Not")){
		unary_gen(p);
	}else if(!strcmp(p->type, "Id")){
		printf2("%%%d = load %s* %s\n", r_count, type2llvm(p->op_type), get_var(p));
		p->reg = r_count++;
	}else if(!strcmp(p->type, "IntLit")){
		printf2("%%%d = add i32 %s, 0\n", r_count, p->value);
		p->reg = r_count++;
	}else if(!strcmp(p->type, "RealLit")){
		printf2("%%%d = fadd double ", r_count);

		char intp[20], *s, g[20], c;
		int t = sscanf(p->value, "%[^.].%c", intp, &c);
		sscanf(p->value, "%c", intp, c);
		s = p->value;
		if(t < 2){
			sscanf(p->value, "%d%s", &t, g);
			printf2("%d.0", t);
			s = g;
		}
		printf2("%s, 0.0\n", s);

		p->reg = r_count++;
	}else if(!strcmp(p->type, "WriteLn")){
		writeln_gen(p);
	}else if(!strcmp(p->type, "Assign")){
		code_gen(p->op[1]);
		int reg1 = p->op[1]->reg;
		if(p->op[0]->op_type == REAL_T && p->op[1]->op_type == INTEGER_T)
			reg1 = real_cast(p->op[1]);

		printf2("store %s %%%d, %s* %s\n", type2llvm(p->op[0]->op_type), reg1, type2llvm(p->op[0]->op_type), get_var(p->op[0]));
	}else if(!strcmp(p->type, "IfElse")){
		ifelse_gen(p);
	}else if(!strcmp(p->type, "Call")){
		for(i=1; i<p->n_op; i++)
			code_gen(p->op[i]);

		int f_id = fetch_func(p->op[0]->value);
		hashtable_t* h = symbol_tables[f_id];
		element_t** it;


		for(it = h->next+1, i=1; it != h->last; ++it, ++i){
			if((*it)->flag == VARPARAM_F){
			}else if((*it)->flag == PARAM_F){
				if(p->op[i]->op_type == INTEGER_T && (*it)->type == REAL_T )
					p->op[i]->reg = real_cast(p->op[i]);
			}else
				break;
		}

		printf2("%%%d = call %s @%s(", r_count, type2llvm(p->op_type), p->op[0]->value);
		for(it = h->next+1, i=1; it != h->last; ++it, ++i){
			if((*it)->flag == VARPARAM_F){
				if(it != h->next+1) printf2(", ");
				printf2("%s* dereferenceable(8) %s", type2llvm(p->op[i]->op_type), get_var(p->op[i]));
			}else if((*it)->flag == PARAM_F){
				if(it != h->next+1) printf2(", ");
				printf2("%s %%%d", type2llvm((*it)->type), p->op[i]->reg);
			}else
				break;
		}
		
		printf2(")\n");
		p->reg = r_count++;
	}else if(!strcmp(p->type, "While")){
		while_gen(p);
	}else if(!strcmp(p->type, "Repeat")){
		repeat_gen(p);
	}else if(!strcmp(p->type, "ValParam")){
		valparam_gen(p);
	}else if(!strcmp(p->type, "FuncDecl")){
		;
	}else{
		for(i = 0; i < p->n_op; i++)
			code_gen(p->op[i]);
	}

}