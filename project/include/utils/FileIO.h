#ifndef LIME_UTILS_FILEIO_H
#define LIME_UTILS_FILEIO_H


extern "C" {
	
	#include <stdio.h>
	
}


namespace lime {
	
	
	extern int fclose (FILE *stream);
	extern FILE *fdopen (int fd, const char *mode);
	extern FILE* fopen (const char *filename, const char *mode);
	//extern FILE* freopen (const char *filename, const char *mode, FILE *stream);
	extern size_t fread (void *ptr, size_t size, size_t count, FILE *stream);
	extern int fseek (FILE *stream, long int offset, int origin);
	extern long int ftell (FILE *stream);
	extern size_t fwrite (const void *ptr, size_t size, size_t count, FILE *stream);
	
	
}


#endif