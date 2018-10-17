#ifdef HX_MACOS
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

#include <system/Locale.h>


namespace lime {


	float Display::GetDPI () {

		#ifndef OBJC_ARC
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		#endif

		NSString* locale = [[NSLocale currentLocale] localeIdentifier];
		std::string* result = 0;

		if (locale) {

			const char* ptr = [locale UTF8String];
			result = new std::string (ptr);

		}

		#ifndef OBJC_ARC
		[pool drain];
		#endif

		return result;

	}


}