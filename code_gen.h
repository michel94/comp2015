#define print_code 0

void code_gen(Node* p);

int tabs = 0;
int r_count = 1;

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

void print_function(type_t type, char* name, hashtable_t* h){
	printf2("define %s @%s(", type2llvm(type), name);
	
	printf2(") {\n");

}

void print_decl(char* var_name, type_t type, int global){
	if(!global)
		printf2("%%_%s = alloca %s\n", var_name, type2llvm(type));
	else
		printf2("@_%s = common global %s %s\n", var_name, type2llvm(type), type == REAL_T ? "0.0" : "0");
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
	r_count = 1;
	st_pointer = PROGRAM_ST;
	code_gen(p->op[3]);
	
	printf2("ret i32 0\n}\n");

}
void function_gen(Node* p){
	r_count = 1;
	int f_id = fetch_func(p->op[0]->value);
	hashtable_t* h = symbol_tables[f_id];

	type_t type = (*h->next)->type;
	printf2("define %s @%s(", type2llvm(type), p->op[0]->value);
	for(element_t** it = h->next+1; it != h->last; ++it){

		if((*it)->flag == VARPARAM_F){
			if(it != h->next+1) printf2(", ");
			printf2("%s* %s", (*it)->name, type2llvm((*it)->type));
		}else if((*it)->flag == PARAM_F){
			if(it != h->next+1) printf2(", ");
			printf2("%s %s", (*it)->name, type2llvm((*it)->type));
		}else
			break;

	}
	printf2(") {\n");

	print_decl( p->op[0]->value, fetch(h, p->op[0]->value)->type, 0);

	code_gen(p->op[p->n_op-2]);
	code_gen(p->op[p->n_op-1]);

	code_gen(p->op[0]);
	printf2("ret %s %%%d\n", type2llvm(type), p->op[0]->reg);

	printf2("}\n");
}

const char OUTPUT_REAL[] = 		"@.prreal = private unnamed_addr constant [3 x i8] c\"%lf\"";
const char OUTPUT_STRING[] = 	"@.prstr = private unnamed_addr constant [3 x i8] c\"%s\\00\"";
const char OUTPUT_INT[] = 		"@.print = private unnamed_addr constant [3 x i8] c\"%d\\00\"";

char* const_strings[256] = {"\\0A\\00", " \\00"};
int s_const_strings[256] = {2, 2};
int n_const_strings = 2;


void print_real(Node* p){
	printf2("%%%d = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([3 x i8]* @.prreal, i32 0, i32 0), double %%%d)\n", r_count, p->reg );
	r_count++;
}

void print_int(Node* p){
	printf2("%%%d = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([3 x i8]* @.print, i32 0, i32 0), i32 %%%d)\n", r_count, p->reg );
	r_count++;
}

void print_str(int str_id){
	printf2("%%%d = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([%d x i8]* @.str_%d, i32 0, i32 0))\n", r_count, s_const_strings[str_id], str_id);
	r_count++;
}

void add_const_string(char * s){
	const_strings[n_const_strings] = strdup(s+1);
	const_strings[n_const_strings][strlen(const_strings[n_const_strings])-1] = 0;
	s_const_strings[n_const_strings] = strlen(const_strings[n_const_strings]);
	n_const_strings++;
}

void writeln_gen(Node* p){
	int i;
	for(i=0; i<p->n_op; i++){
		code_gen(p->op[i]);

		if(p->op[i]->op_type == REAL_T){
			print_real(p->op[i]);
		}else if(p->op[i]->op_type == INTEGER_T){
			print_int(p->op[i]);
		}else{
			add_const_string(p->op[i]->value);
			print_str(n_const_strings-1);
		}
	}
	print_str(0);
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
	printf2("%s\n", OUTPUT_INT);
	printf2("%s\n", OUTPUT_STRING);
	printf2("%s\n", OUTPUT_REAL);
	printf2("\n");

	int i;
	for(i=0; i<n_const_strings; i++){
		printf2("@.str_%d = private unnamed_addr constant [%d x i8] c\"%s\"\n", i, s_const_strings[i], const_strings[i]);
	}
	printf2("\n");

	printf2("declare i32 @printf(i8*, ...)\n");
}

void code_gen(Node* p){
	int i;
	if(p == NULL)
		return;

	if(strcmp(p->type, "Program") == 0){
		program_gen(p);
		print_consts();
	}else if(strcmp(p->type, "VarDecl") == 0){
		type_t type = vartype(p->op[p->n_op-1]->value);
		for(i = 0; i < p->n_op-1; i++){
			print_decl(p->op[i]->value, type, 0);
		}
	}else if(strcmp(p->type, "FuncDef") == 0){
		//print_function()
		st_pointer = fetch_func(p->op[0]->value);
		function_gen(p);
	}else if(!strcmp(p->type, "Add") || !strcmp(p->type, "Sub") || !strcmp(p->type, "Mul") ){
		code_gen(p->op[0]);
		code_gen(p->op[1]);
		printf2("%%%d = %s %s %%%d, %%%d\n", r_count, "add", type2llvm(p->op_type), p->op[0]->reg, p->op[1]->reg);
		p->reg = r_count++;
	}else if(!strcmp(p->type, "Id")){
		printf2("%%%d = load %s* %s\n", r_count, type2llvm(p->op_type), get_var(p) );
		
		p->reg = r_count++;
	}else if(!strcmp(p->type, "IntLit")){
		printf2("%%%d = add i32 %s, 0\n", r_count, p->value);
		p->reg = r_count++;
	}else if(!strcmp(p->type, "RealLit")){
		printf2("%%%d = add double %s, 0.0\n", r_count, p->value);
		p->reg = r_count++;
	}else if(!strcmp(p->type, "WriteLn")){
		writeln_gen(p);
	}else if(!strcmp(p->type, "Assign")){
		code_gen(p->op[1]);
		printf2("store %s %%%d, %s* %s\n", type2llvm(p->op[1]->op_type), p->op[1]->reg, type2llvm(p->op[0]->op_type), get_var(p->op[0]));
	}else{
		for(i = 0; i < p->n_op; i++)
			code_gen(p->op[i]);
	}

}