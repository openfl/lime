#include <system/Locale.h>

#if defined(HX_WINDOWS)
#include <windows.h>
#elif defined(HX_LINUX)
#include <stdlib.h>
#include <string.h>
#include <clocale>
#endif


namespace lime {
	
	
	char* Locale::GetSystemLocale () {
		
		#if defined(HX_WINDOWS)
		
		char locale[8];
		int length = GetLocaleInfo (GetSystemDefaultUILanguage (), LOCALE_SISO639LANGNAME, locale, sizeof (locale));
		char *result = (char*)malloc (length + 1);
		strcpy (result, locale);
		return result;
		
		#elif defined(HX_LINUX)
		
		const char* locale = getenv ("LANG");
		
		if (!locale) {
			
			locale = setlocale (LC_ALL, "");
			
		}
		
		if (locale) {
			
			char *result = (char*)malloc (sizeof (locale));
			strcpy (result, locale);
			
			return result;
			
		}
		
		return 0;
		
		#else
		
		return 0;
		
		#endif
		
	}
	
	
}