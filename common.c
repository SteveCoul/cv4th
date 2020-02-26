
#include "common.h"

int cmp( const char* s1, int len1, const char* s2, int len2, int match_case ) {
	int rc = 0;
	char a;
	char b;
	while ( ( len1 > 0 ) && ( len2 > 0 ) ) {
		a = *s1++;
		b = *s2++;
		len1--;
		len2--;
		if ( match_case == 0 ) {
			if ( ( a >= 'a' ) && ( a <= 'z' ) ) a-=32;
			if ( ( b >= 'a' ) && ( b <= 'z' ) ) b-=32;
		}
		if ( a != b ) break;
	}
	if ( a > b ) {
		rc = 1;
	} else if ( a < b ) {
		rc = -1;
	} else if ( ( len1 == 0 ) && ( len2 == 0 ) ) {
		rc = 0;
	} else {
		rc = len1 < len2 ? -1 : 1;
	}
	return rc;
}

