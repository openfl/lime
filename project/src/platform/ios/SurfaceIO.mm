#include <Surface.h>
//#include <ApplicationServices/ApplicationServices.h>
#include <UIKit/UIImage.h>


namespace nme {

Surface *FromImage(UIImage *image)
{
   if (image == nil)
      return 0;

   CGSize size = image.size;
   int width = CGImageGetWidth(image.CGImage);
   int height = CGImageGetHeight(image.CGImage);
   //printf("Size %dx%d\n", width, height );

   bool has_alpha =   CGImageGetAlphaInfo(image.CGImage)!=kCGImageAlphaNone;
   Surface *result = new SimpleSurface(width,height,has_alpha?pfARGB:pfXRGB);
   result->IncRef();
   AutoSurfaceRender renderer(result);
   const RenderTarget &target = renderer.Target();


   CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
   CGContextRef context = CGBitmapContextCreate( target.Row(0),
       width, height, 8, target.mSoftStride, colorSpace,
       (has_alpha?kCGImageAlphaPremultipliedLast:kCGImageAlphaNoneSkipLast) |
            kCGBitmapByteOrderDefault );
   CGColorSpaceRelease( colorSpace );

   CGContextClearRect( context, CGRectMake( 0, 0, width, height ) );
   //CGContextTranslateCTM( context, 0, height - height );
   CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage );

   CGContextRelease(context);

   return result;
}


Surface *Surface::Load(const OSChar *inFilename)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    std::string asset = gAssetBase + inFilename;
    NSString *str = [[NSString alloc] initWithUTF8String:asset.c_str()];
    NSString *path = [[NSBundle mainBundle] pathForResource:str ofType:nil];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    Surface *result = FromImage(image);
    [str release];
    [image release];
    [pool drain];
    return result;
}


Surface *Surface::LoadFromBytes(const uint8 *inBytes,int inLen)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSData *data = [NSData dataWithBytes:(uint8 *)inBytes length:inLen];
    UIImage *image = [UIImage imageWithData:data];
    Surface *result = FromImage(image);
    [pool drain];
    return result;
}

bool Surface::Encode( ByteArray *outBytes,bool inPNG,double inQuality)
{
   // TODO:
   return false;
}



}
