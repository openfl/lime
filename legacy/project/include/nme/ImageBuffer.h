#ifndef NME_IMAGE_BUFFER_H
#define NME_IMAGE_BUFFER_H

#include "Texture.h"
#include "Pixel.h"
#include "Object.h"

namespace nme
{


enum
{
   surfNotRepeatIfNonPO2    = 0x0001,
   surfUsePremultipliedAlpha = 0x0002,
   surfHasPremultipliedAlpha = 0x0004,
};


class ImageBuffer : public ApiObject
{
protected: // Use 'DecRef'
   virtual       ~ImageBuffer() { };
public:
   virtual unsigned int GetFlags() const = 0;
   virtual void SetFlags(unsigned int inFlags) = 0;

   virtual PixelFormat Format()  const = 0;
   virtual int  Version() const  = 0;
   virtual void OnChanged() = 0;

   virtual int                  Width() const =0;
   virtual int                  Height() const =0;
   virtual const unsigned char *GetBase() const = 0;
   virtual int                  GetStride() const = 0;
   virtual unsigned char        *Edit(const Rect *inRect=0) = 0;
   virtual void                 Commit() = 0;

   inline  unsigned char        *EditRect(int inX0, int inY0, int inW, int inH)
   {
      Rect rect(inX0, inY0, inW, inH);
      return Edit(&rect);
   }

   virtual Texture *GetTexture(class HardwareContext *inContext=0,int inPlane=0) = 0;
   virtual void  MakeTextureOnly() = 0;

   ImageBuffer *asImageBuffer() { return this; }


   inline const unsigned char *Row(int inY) const { return GetBase() + GetStride()*inY; }
};


} // end namespace nme

#endif
