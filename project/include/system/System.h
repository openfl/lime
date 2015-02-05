#ifndef LIME_SYSTEM_SYSTEM_H
#define LIME_SYSTEM_SYSTEM_H

#include <stdio.h>


namespace lime {
	
	
	class System {
		
		
		public:
			
			static double GetTimer ();
		
		
	};
	
	
	struct FILE_HANDLE {
		
		void *handle;
		
		FILE_HANDLE (void* handle) : handle (handle) {}
		
		FILE* getFile ();
		int getLength ();
		bool isFile ();
		
	};
	
	
	extern int fclose (FILE_HANDLE *stream);
	extern FILE_HANDLE *fdopen (int fd, const char *mode);
	extern FILE_HANDLE *fopen (const char *filename, const char *mode);
	//extern FILE* freopen (const char *filename, const char *mode, FILE *stream);
	extern size_t fread (void *ptr, size_t size, size_t count, FILE_HANDLE *stream);
	extern int fseek (FILE_HANDLE *stream, long int offset, int origin);
	extern long int ftell (FILE_HANDLE *stream);
	extern size_t fwrite (const void *ptr, size_t size, size_t count, FILE_HANDLE *stream);
	
	
}


#endif