#ifndef NME_CAMERA
#define NME_CAMERA

#include <nme/Object.h>
#include <nme/NmeApi.h>
#include <nme/ImageBuffer.h>
#include <nme/NmeCffi.h>
#include <string>
#include <vector>

namespace nme
{

enum CameraStatus { camInit, camError, camStopped, camRunning };

struct FrameBuffer
{
   FrameBuffer() : width(0), height(0), stride(0), age(-1) { }
   unsigned char *row(int inY) { return &data[inY*stride]; }
   std::vector<unsigned char> data;

   int width;
   int height;
   int stride;
   int  age;
};

class Camera : public Object
{
public:
   Camera() : status(camInit), buffer(0), width(0), height(0) { }
   ~Camera() { if (buffer) buffer->DecRef(); }

   void onPoll(value inHandler);

   virtual void copyFrame(ImageBuffer *outBuffer, FrameBuffer *inFrame) = 0;
   virtual void lock( ) = 0;
   virtual void unlock( ) = 0;
   FrameBuffer  *getWriteBuffer();
   FrameBuffer  *getReadBuffer();

   bool setError(const std::string &inError);

   inline bool ok() { return status !=camError; }



   CameraStatus status;
   std::string  error;
   int          width;
   int          height;
   int          frameId;
   FrameBuffer  frameBuffers[3];
   ImageBuffer  *buffer;
};

Camera *CreateCamera(const char *inName);


} // end namespace nme

#endif
