#ifdef HX_LINUX

// Improve compatibility with old glibc

#define __fdelt_chk __fdelt_chk_local
#include <sys/select.h>
#undef __fdelt_chk

long int __fdelt_chk (long int d) {
	
	if (d >= FD_SETSIZE) {
		
		//printf("Select - bad fd.\n");
		return 0;
		
	}
	
	return d / __NFDBITS;
	
}

#endif