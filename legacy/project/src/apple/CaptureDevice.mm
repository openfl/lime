#import <AVFoundation/AVFoundation.h>
#include <Camera.h>
#include <pthread.h>

using namespace nme;

namespace nme { class AppleCamera; }


@interface FrameRelay : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{
   AppleCamera *mCamera;
}

- (id) initWithCamera:(AppleCamera*)camera;

- (void)captureOutput:(AVCaptureOutput *)captureOutput 
   didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
   fromConnection:(AVCaptureConnection *)connection;

@end



namespace nme
{


class AppleCamera : public Camera
{
   AVCaptureSession *mSession;
   pthread_mutex_t mMutex;


public:
   AppleCamera(const char *inName)
   {
      pthread_mutexattr_t mta;
      pthread_mutexattr_init(&mta);
      pthread_mutexattr_settype(&mta, PTHREAD_MUTEX_RECURSIVE);
      pthread_mutex_init(&mMutex,&mta);


    NSError *error = nil;

    // Create the session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];

    // Configure the session to produce lower resolution video frames, if your 
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
    session.sessionPreset = AVCaptureSessionPresetMedium;

    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice
                           defaultDeviceWithMediaType:AVMediaTypeVideo];

    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device 
                                                                    error:&error];
    if (!input)
    {
        NSLog(@"PANIC: no media input");
    }
    [session addInput:input];

    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [session addOutput:output];

    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    FrameRelay *relay = [[FrameRelay alloc] initWithCamera:this];
    [output setSampleBufferDelegate:relay queue:queue];
    dispatch_release(queue);

    // Specify the pixel format
    output.videoSettings = 
    [NSDictionary dictionaryWithObject:
    [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
                            forKey:(id)kCVPixelBufferPixelFormatTypeKey];


    // If you wish to cap the frame rate to a known value, such as 15 fps, set 
    // minFrameDuration.

    // Start the session running to start the flow of data
    [session startRunning];

    // Assign session to an ivar.
    // Add ref ?
    mSession = session;

  }

   ~AppleCamera()
   {
      pthread_mutex_destroy(&mMutex);
   }

   void lock()
   {
      pthread_mutex_lock(&mMutex); 
   }

   void unlock()
   {
      pthread_mutex_unlock(&mMutex); 
   }

   void copyFrame(ImageBuffer *outBuffer, FrameBuffer *inFrame)
   {
      int n = inFrame->width * inFrame->height;
      unsigned char *src = &inFrame->data[0];
      unsigned char *dest = outBuffer->Edit(0);
      memcpy(dest,src,n*4);
      outBuffer->Commit();
   }



   void onFrame(CMSampleBufferRef inSample)
   {
      // Get a CMSampleBuffer's Core Video image buffer for the media data
      CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(inSample); 
      // Lock the base address of the pixel buffer
      CVPixelBufferLockBaseAddress(imageBuffer, 0); 

      // Get the number of bytes per row for the pixel buffer
      void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 

      // Get the number of bytes per row for the pixel buffer
      size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
      // Get the pixel buffer width and height
      width = CVPixelBufferGetWidth(imageBuffer); 
      height = CVPixelBufferGetHeight(imageBuffer); 

      FrameBuffer *frameBuffer = getWriteBuffer();
      frameBuffer->data.resize(width*height*4);
      frameBuffer->width = width;
      frameBuffer->height = height;
      frameBuffer->stride = width*4;


      //printf("Got frame %d %d %lu\n", width, height, bytesPerRow);

      for(int y=0;y<height;y++)
         memcpy( frameBuffer->row(y), (char *)baseAddress + y*bytesPerRow, width*4 );
        
      frameBuffer->age = frameId++;


      CVPixelBufferUnlockBaseAddress(imageBuffer,0);

      if (width && height)
         status = camRunning;
   }

};


Camera *CreateCamera(const char *inName)
{
   return new AppleCamera(inName);
}


} // end namespace nme



@implementation FrameRelay

- (id) initWithCamera:(AppleCamera*)camera
{
  self = [super init];
  mCamera = camera;
  return self;
}


// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
   didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
   fromConnection:(AVCaptureConnection *)connection
{ 
    //NSLog(@"captureOutput: didOutputSampleBufferFromConnection");
    mCamera->onFrame( sampleBuffer );
}
@end



