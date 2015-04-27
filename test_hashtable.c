#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "hashtable.h"

#define DEBUG_FILL 1
#define DEBUG_DISTRIBUTION 0

int fill_regression(){
	int words = pow(26, 2)+1;

	int dist[words+1];

	hashtable_t* table = new_hashtable(words, "");
	memset(dist,  0, sizeof dist);

	for(char i = 'a'; i <= 'z'; i++){
		for(char j = 'a'; j <= 'z'; j++){
			char str[] = {i, j, 0};
			
			int pos = store(table, str, STRING_T);
			dist[pos]++;

			if(dist[pos] > 1 || pos > words || pos < 0){
				printf("Error: %d\n", pos);
				return -1;
			}
		}
	}

#if DEBUG_FILL
	for(int i = 0; i <= words; ++i)
		printf("%d - %d\n", i, dist[i]);
#endif

	return dist[0];
}
/*
int distribution_regression(){

	if(!ENABLE_HASH_REGRESSIONS)
		return -1;

	double var, desv, mean;
	int sum = 0, words = 128;

	int dist[words+1];
	element_t table[words];

	memset(table, 0, sizeof table);
	memset(dist,  0, sizeof dist);

	for(char i = 'a'; i <= 'z'; i++){
		for(char j = 'a'; j <= 'z'; j++){
			for(char k = 'a'; k <= 'z'; k++){
				char str[] = {i, j, k, 0};
				dist[store(table, words, str, STRING_T)]++;
			}
		}
	}

#if DEBUG_DISTRIBUTION
	for(int i = 0; i <= words; ++i)
		printf("%d - %d\n", i, dist[i]);
#endif

	for(int i = 0; i <= words; ++i)
		sum += dist[i];

#if DEBUG_DISTRIBUTION
	mean = sum / (words*1.0f);
	printf("\nMedia - %.2lf\n", mean);
#endif

	for(int i = 1; i <= words; ++i)
		var += (dist[i] - mean) * (dist[i] - mean);
	var = var / words;

#if DEBUG_DISTRIBUTION
	printf("Variancia - %.2lf\n", var);
	desv = sqrt(var);
	printf("Desvio %.2lf\n\n", desv);
#endif

	return desv > 10;
}*/

int main(){
	if(fill_regression())
		printf("Store needs fix\n");
	else
		printf("Fill regression.. OK\n");

	/*
	int v = distribution_regression();
	if(v == 1)
		printf("fnv1a needs fix\n");
	else if(v == 0)
		printf("Distribution regression.. OK\n");
	else
		printf("Error: Set ENABLE_TEST_REGRESSIONS in hashtable.h\n");
	*/
}
