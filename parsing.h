
#include "types.h"

#define OUTER_ST 0
int PROGRAM_ST;

hashtable_t* symbol_tables[TABLE_SIZE];
int st_pointer, st_size=0;

int type_is_valid(char* ret_type){
	element_t* t = fetch(symbol_tables[OUTER_ST], ret_type);
	if(t == NULL || t->type != TYPE_T)
		return 0;
	return 1;
}

void parse_funchead(char* name, int n_args, Node** args, char* ret_type){
	
	st_pointer = st_size++;
	
	symbol_tables[st_pointer] = new_hashtable(TABLE_SIZE, "Function");
	strcpy(symbol_tables[st_pointer]->func, name);
	if(!type_is_valid(ret_type))
		printf("Cannot write values of type <%s>\n", ret_type);
	else{
		element_t* el = store(symbol_tables[st_pointer], name, vartype(ret_type) );
		el->flag = RETURN_F;
		store(symbol_tables[PROGRAM_ST], name, FUNCTION_T);
	}

}

