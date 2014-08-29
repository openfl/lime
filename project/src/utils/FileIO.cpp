#include <utils/FileIO.h>

#ifdef HX_MACOS
#include <CoreFoundation/CoreFoundation.h>
#endif


namespace lime {
	
	
	int fclose (FILE *stream) {
		
		return ::fclose (stream);
		
	}
	
	
	FILE *fdopen (int fd, const char *mode) {
		
		return ::fdopen (fd, mode);
		
	}
	
	
	FILE* fopen (const char *filename, const char *mode) {
		
		#ifdef HX_MACOS
		FILE *result = ::fopen (filename, "rb");
		if (!result) {
			CFStringRef str = CFStringCreateWithCString (NULL, filename, kCFStringEncodingUTF8);
			CFURLRef path = CFBundleCopyResourceURL (CFBundleGetMainBundle (), str, NULL, NULL);
			CFRelease (str);
			if (path) {
				str = CFURLCopyPath (path);
				CFIndex maxSize = CFStringGetMaximumSizeForEncoding (CFStringGetLength (str), kCFStringEncodingUTF8);
				char *buffer = (char *)malloc (maxSize);
				if (CFStringGetCString (str, buffer, maxSize, kCFStringEncodingUTF8)) {
					result = ::fopen (buffer,"rb");
					free (buffer);
				}
				CFRelease (str);
				CFRelease (path);
			}
		}
		return result;
		#else
		return ::fopen (filename, mode);
		#endif
		
	}
	
	
	size_t fread (void *ptr, size_t size, size_t count, FILE *stream) {
		
		return ::fread (ptr, size, count, stream);
		
	}
	
	
	int fseek (FILE *stream, long int offset, int origin) {
		
		return ::fseek (stream, offset, origin);
		
	}
	
	
	long int ftell (FILE *stream) {
		
		return ::ftell (stream);
		
	}
	
	
	size_t fwrite (const void *ptr, size_t size, size_t count, FILE *stream) {
		
		return ::fwrite (ptr, size, count, stream);
		
	}
	
	
}