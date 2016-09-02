#ifdef HX_MACOS
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

#include <system/Locale.h>


namespace lime {
	
	
	char* Locale::GetSystemLocale () {
		
		#ifndef OBJC_ARC
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		#endif
		
		NSString* locale = [[NSLocale currentLocale] localeIdentifier];
		char* result = 0;
		
		if (locale) {
			
			const char* ptr = [locale UTF8String];
			result = (char*)malloc ([locale length] + 1);
			strncpy (result, ptr, [locale length]);
			
		}
		
		#ifndef OBJC_ARC
		[locale release];
		[pool drain];
		#endif
		
		return result;
		
	}
	
	
}