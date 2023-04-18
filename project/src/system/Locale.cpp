#include <system/Locale.h>

#if defined(HX_WINDOWS)
#include <windows.h>
#elif defined(HX_LINUX)
#include <stdlib.h>
#include <string.h>
#include <clocale>
#endif


namespace lime {


	std::string* Locale::GetSystemLocale () {

		#if defined(HX_WINDOWS)

		char language[5] = {0};
		char country[5] = {0};

		GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_SISO639LANGNAME, language, sizeof (language) / sizeof (char));
		GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_SISO3166CTRYNAME, country, sizeof (country) / sizeof (char));

		std::string* locale = new std::string (std::string (language) + "_" + std::string (country));
		return locale;

		#elif defined(HX_LINUX)

		const char* locale = getenv ("LANG");

		if (!locale) {

			locale = setlocale (LC_ALL, "");

		}

		if (locale) {

			std::string* result = new std::string (locale);
			return result;

		}

		return 0;

		#else

		return 0;

		#endif

	}


}