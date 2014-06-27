#import <UIKit/UIKit.h>
#import <string>

namespace lime
{

FILE *OpenRead(const char *inName)
{
	FILE *result = 0;

	if (inName[0]=='/')
	{
		result = fopen(inName,"rb");
	}
	else
	{
		NSString *assetPath = [@"assets" stringByAppendingPathComponent:[NSString stringWithFormat:@"%s", inName]];

		NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
		NSString *path = [resourcePath stringByAppendingPathComponent:assetPath];

		// search in documents if not in the resource bundle
		if ( ! [[NSFileManager defaultManager] fileExistsAtPath:path])
		{
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documentDir = [paths objectAtIndex:0];
			path = [documentDir stringByAppendingPathComponent:assetPath];
		}

		result = fopen([path UTF8String],"rb");
	}

	return result;
}


FILE *OpenOverwrite(const char *inName)
{
	NSString *str = [@"assets" stringByAppendingPathComponent:[NSString stringWithFormat:@"%s", inName]];

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDir = [paths objectAtIndex:0];
	NSString *path = [documentDir stringByAppendingPathComponent:str];

	// create any directories if they don't exist
	[[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES  attributes:nil error:NULL];

	FILE * result = fopen([path UTF8String],"w");
	return result;
}

}
