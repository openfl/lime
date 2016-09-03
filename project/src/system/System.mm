#ifdef IPHONE
#import <UIKit/UIKit.h>
#endif

#include <system/System.h>


namespace lime {
	
	
	std::wstring* System::GetIOSDirectory (SystemDirectory type) {
		
		#ifndef OBJC_ARC
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		#endif
		
		NSUInteger searchType = NSDocumentDirectory;
		
		switch (type) {
			
			case DESKTOP:
				
				searchType = NSDesktopDirectory;
				break;
			
			case USER:
				
				//searchType = NSUserDirectory;
				searchType = NSDocumentDirectory;
				break;
			
			default: break;
			
		}
		
		std::wstring* result = 0;
		
		NSArray* paths = NSSearchPathForDirectoriesInDomains (searchType, NSUserDomainMask, YES);
		
		if (paths && [paths count] > 0) {
			
			NSString* basePath = paths.firstObject;
			std::string path = std::string ([basePath UTF8String]);
			result = new std::wstring (path.begin (), path.end ());
			
		}
		
		#ifndef OBJC_ARC
		[pool drain];
		#endif
		
		return result;
		
	}
	
	
}