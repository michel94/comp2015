
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <inttypes.h>

int ENABLE_HASH_REGRESSIONS = 0;

typedef enum {INTEGER_T, STRING_T, REAL_T} type_t;
//typedef 

typedef struct {
	char name[64];
	type_t type;
} element_t;

typedef struct{
	char name[64];
	element_t *elements;
	int size;
} hashtable_t;

hashtable_t* new_hashtable(int size, char* str){
	hashtable_t* h;
	h = (hashtable_t*) malloc(sizeof(hashtable_t));
	h->elements = (element_t*) malloc(sizeof(element_t) * size);
	memset(h->elements, 0, sizeof(element_t) * size);
	h->size = size;
	strcpy(h->name, str);

	return h;
}

uint64_t hash_fnv1a(char s[]){
	const uint64_t prime = 0x100000001b3;
	uint64_t hash = 0xcbf29ce484222325;
	int i, len = strlen(s);

	for(i = 0; i < len; i++){
		hash ^= s[i] & 0xff;
		hash *= prime;
	}

	return hash;
}

int store(hashtable_t* hashtable, char *s, type_t type){
	int size = hashtable->size;
	element_t* table = hashtable->elements;
	uint64_t ind = hash_fnv1a(s) % size;
	element_t *it, *el = &table[ind];
	
	if(strlen(el->name) <= 0){
		strcpy(el->name, s);
		el->type = type;

		return (el-table) + 1; /* RETURN INDEX IN HASHTABLE PLUS 1 */
	}

	register int i;
	for(i=(ind+1)%size; i!=ind; i=(i+1)%size){
		it = table + i;
		if(strlen(it->name) <= 0){
			strcpy(it->name, s);
			it->type = type;

			return (it-table) + 1; /* RETURN INDEX IN HASHTABLE PLUS 1 */
		}
	}
	
	return 0;
}

element_t *fetch(hashtable_t* hashtable, char *s){
	int size = hashtable->size;
	element_t* table = hashtable->elements;
	uint64_t ind = hash_fnv1a(s) % size;
	element_t *it, *el = &table[ind];

	if(strlen(el->name) == 0){
		return el;
	}

	register int i;
	for(i=(ind+1)%size; i!=ind; i=(i+1)%size){
		it = table + i;
		if(strlen(it->name) == 0)
			return it;
	}

}
