
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <inttypes.h>

typedef enum {INTEGER_T, STRING_T, REAL_T} type_t;

typedef struct {
	char name[64];
	type_t type;
} element_t;

int64_t hash_fnv1a(char s[]){
	const uint64_t prime = 0xcbf29ce484222325;
	uint64_t hash = 0xcbf29ce484222325;
	int i;

	for(i = 0; i < strlen(s); i++){
		hash ^= (s[i] & 0xff);
		hash *= prime;
	}

	return hash;
}

int store(element_t table[], int size, char *s, type_t type){
	element_t *it, *el;
	uint64_t ind = hash_fnv1a(s);
	ind = ind % size;
	el = &table[ind];
	
	for(it = el; it != el-1 % size; it+=(it-el+1) % size){
		if(strlen(it->name) <= 0){
			strcpy(it->name, s);
			it->type = type;

			return 0;
		}
	}

	return 1;

}

element_t *fetch(element_t table[], int size, char *s){
	element_t *it, *el;
	int ind = hash_fnv1a(s);
	ind = ind % size;
	el = &table[ind];


	for(it = el; it != el-1 % size; it+=(it-el+1) % size){
		if(strcmp(it->name, s) == 0){
			return it;
		}
	}

	return NULL;
}

