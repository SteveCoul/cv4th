
#include "common.h"

int cmp( const char* s1, const char* s2, int len ) {
	int ret = 0;
	if ( len == 0 ) return 0;
	while ( len-- ) {
		char a = *s1++;
		char b = *s2++;
		if ( ( a >= 'a' ) && ( a <= 'z' ) ) a-=32;
		if ( ( b >= 'a' ) && ( b <= 'z' ) ) b-=32;
		if ( a != b ) { ret = a-b; break; }
	}
	return ret;
}

