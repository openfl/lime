#include <utils/FileIO.h>

#ifdef HX_MACOS
#include <CoreFoundation/CoreFoundation.h>
#endif

#include <SDL_rwops.h>


namespace lime {
	
	
	FILE* FILE_HANDLE::getFile () {
		
		if (((SDL_RWops*)handle)->type == SDL_RWOPS_STDFILE) {
			
			return ((SDL_RWops*)handle)->hidden.stdio.fp;
			
		} else if (((SDL_RWops*)handle)->type == SDL_RWOPS_JNIFILE) {
			
			#ifdef ANDROID
			FILE* file = ::fdopen (((SDL_RWops*)handle)->hidden.androidio.fd, "rb");
			::fseek (file, ((SDL_RWops*)handle)->hidden.androidio.offset, 0);
			return file;
			#endif
			
		}
		
		return NULL;
		
	}
	
	
	int FILE_HANDLE::getLength () {
		
		return SDL_RWsize (((SDL_RWops*)handle));
		
	}
	
	
	int fclose (FILE_HANDLE *stream) {
		
		if (stream) {
			
			return SDL_RWclose ((SDL_RWops*)stream->handle);
			
		}
		
		return 0;
		
	}
	
	
	FILE_HANDLE *fdopen (int fd, const char *mode) {
		
		FILE* fp = ::fdopen (fd, mode);
		SDL_RWops *result = SDL_RWFromFP (fp, SDL_TRUE);
		
		if (result) {
			
			return new FILE_HANDLE (result);
			
		}
		
		return NULL;
		
	}
	
	
	FILE_HANDLE *fopen (const char *filename, const char *mode) {
		
		SDL_RWops *result;
		#ifdef HX_MACOS
		result = SDL_RWFromFile (filename, "rb");
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
		result = SDL_RWFromFile (filename, mode);
		#endif
		
		if (result) {
			
			return new FILE_HANDLE (result);
			
		}
		
		return NULL;
		
	}
	
	
	size_t fread (void *ptr, size_t size, size_t count, FILE_HANDLE *stream) {
		
		return SDL_RWread (stream ? (SDL_RWops*)stream->handle : NULL, ptr, size, count);
		
	}
	
	
	int fseek (FILE_HANDLE *stream, long int offset, int origin) {
		
		return SDL_RWseek (stream ? (SDL_RWops*)stream->handle : NULL, offset, origin);
		
	}
	
	
	long int ftell (FILE_HANDLE *stream) {
		
		return SDL_RWtell (stream ? (SDL_RWops*)stream->handle : NULL);
		
	}
	
	
	size_t fwrite (const void *ptr, size_t size, size_t count, FILE_HANDLE *stream) {
		
		return SDL_RWwrite (stream ? (SDL_RWops*)stream->handle : NULL, ptr, size, count);
		
	}
	
	
}