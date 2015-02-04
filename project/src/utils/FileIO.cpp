#include <utils/FileIO.h>

#ifdef HX_MACOS
#include <CoreFoundation/CoreFoundation.h>
#endif


namespace lime {
	
	
	FILE* FILE_HANDLE::getFile () {
		
		return (FILE*)handle;
		
	}
	
	
	int FILE_HANDLE::getLength () {
		
		return 0;
		
	}
	
	
	bool FILE_HANDLE::isFile () {
		
		return true;
		
	}
	
	
	int fclose (FILE_HANDLE *stream) {
		
		if (stream) {
			
			int value = ::fclose ((FILE*)stream->handle);
			if (stream) delete stream;
			return value;
			
		}
		
		return 0;
		
	}
	
	
	FILE_HANDLE *fdopen (int fd, const char *mode) {
		
		FILE* result = ::fdopen (fd, mode);
		
		if (result) {
			
			return new FILE_HANDLE (result);
			
		}
		
		return NULL;
		
	}
	
	
	FILE_HANDLE *fopen (const char *filename, const char *mode) {
		
		FILE* result;
		#ifdef HX_MACOS
		result = ::fopen (filename, "rb");
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
		#else
		result = ::fopen (filename, mode);
		#endif
		
		if (result) {
			
			return new FILE_HANDLE (result);
			
		}
		
		return NULL;
		
	}
	
	
	size_t fread (void *ptr, size_t size, size_t count, FILE_HANDLE *stream) {
		
		return ::fread (ptr, size, count, stream ? (FILE*)stream->handle : NULL);
		
	}
	
	
	int fseek (FILE_HANDLE *stream, long int offset, int origin) {
		
		return ::fseek (stream ? (FILE*)stream->handle : NULL, offset, origin);
		
	}
	
	
	long int ftell (FILE_HANDLE *stream) {
		
		return ::ftell (stream ? (FILE*)stream->handle : NULL);
		
	}
	
	
	size_t fwrite (const void *ptr, size_t size, size_t count, FILE_HANDLE *stream) {
		
		return ::fwrite (ptr, size, count, (FILE*)stream->handle);
		
	}
	
	
}