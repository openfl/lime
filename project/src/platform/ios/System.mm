//#include <ApplicationServices/ApplicationServices.h>
#import <UIKit/UIKit.h>
#include <Utils.h>

namespace lime {

bool LaunchBrowser(const char *inUtf8URL)
{
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    #endif
	NSString *str = [[NSString alloc] initWithUTF8String:inUtf8URL];	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: str]];
	#ifndef OBJC_ARC
	[str release];
	[pool drain];
    #endif
	return true;
}

std::string CapabilitiesGetLanguage()
{
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    #endif
	NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
	std::string result(language?[language UTF8String]:"");
	#ifndef OBJC_ARC
	[language release];
	[pool drain];
    #endif
	return result;
}

std::string GetUserPreference(const char *inId)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    #endif
	NSString *strId = [[NSString alloc] initWithUTF8String:inId];
	NSString *pref = [userDefaults stringForKey:strId];
	std::string result(pref?[pref UTF8String]:"");
	#ifndef OBJC_ARC
	[strId release];
	[pool drain];
    #endif
	return result;
}
	
bool SetUserPreference(const char *inId, const char *inPreference)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    #endif
	NSString *strId = [[NSString alloc] initWithUTF8String:inId];
	NSString *strPref = [[NSString alloc] initWithUTF8String:inPreference];
	[userDefaults setObject:strPref forKey:strId];
	#ifndef OBJC_ARC
	[strId release];
	[strPref release];
	[pool drain];
    #endif
	return true;
}

bool ClearUserPreference(const char *inId)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    #endif
	NSString *strId = [[NSString alloc] initWithUTF8String:inId];
	[userDefaults setObject:@"" forKey:strId];
	#ifndef OBJC_ARC
	[strId release];
	[pool drain];
    #endif
	return true;
}

const std::string GetUniqueDeviceIdentifier()
{
	// @todo this is deprecated as of iOS 5. switch this out ASAP for UUID generation into user defaults.
  	//return [[[UIDevice currentDevice] uniqueIdentifier] cStringUsingEncoding:1];
  	return "";
}

const std::string &GetResourcePath()
{
   static bool tried = false;
   static std::string path;
   if (!tried)
   {
      tried = true;
	  #ifndef OBJC_ARC
	  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      #endif
      NSString *resourcePath = [ [NSBundle mainBundle]  resourcePath];
      path = [resourcePath cStringUsingEncoding:1];
	  #ifndef OBJC_ARC
      [pool release];
	  #endif
      path += "/";
   }

   return path;
}


	std::string FileDialogFolder( const std::string &title, const std::string &text ) { return ""; }
	std::string FileDialogOpen( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { return ""; }
	std::string FileDialogSave( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { return ""; }

}
