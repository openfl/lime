#ifndef NME_SURFACE_H
#define NME_SURFACE_H

#include <Graphics.h>
#include <Utils.h>
#include <ByteArray.h>
#include <Filters.h>

#include "Hardware.h"
#include <nme/Texture.h>
#include <nme/ImageBuffer.h>

// ---- Surface API --------------

namespace nme
{


void HintColourOrder(bool inRedFirst);

extern int gTextureContextVersion;




class Surface : public ImageBuffer
{
public:
   // Non-PO2 will generate dodgy repeating anyhow...
   Surface() : mTexture(0), mVersion(0), mFlags(surfNotRepeatIfNonPO2), mAllowTrans(true) { };

   // Implementation depends on platform.
   static Surface *Load(const OSChar *inFilename);
   static Surface *LoadFromBytes(const uint8 *inBytes,int inLen);
   bool Encode( nme::ByteArray *outBytes,bool inPNG,double inQuality);

   Surface *IncRef() { mRefCount++; return this; }

   virtual unsigned int GetFlags() const { return mFlags; }
   virtual void SetFlags(unsigned int inFlags) { mFlags = inFlags; }
   virtual int         GPUFormat() const { return Format(); }
   virtual bool GetAllowTrans() const { return mAllowTrans; }
   virtual void SetAllowTrans(bool inAllowTrans) { mAllowTrans = inAllowTrans; }
   virtual void Clear(uint32 inColour,const Rect *inRect=0) = 0;

   virtual void Zero() { Clear(0); }
   virtual void createHardwareSurface() { }
   virtual void destroyHardwareSurface() { }
   virtual void dispose() { }
   virtual void MakeTextureOnly() { /*printf("Dumping bits from Surface\n");*/  }
   virtual void setGPUFormat( PixelFormat pf ) {}
   virtual void multiplyAlpha () {}
   virtual void unmultiplyAlpha() { }

   int BytesPP() const { return Format()==pfAlpha ? 1 : 4; }

   virtual RenderTarget BeginRender(const Rect &inRect,bool inForHitTest=false)=0;
   virtual void EndRender()=0;

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       BlendMode inBlend, const BitmapCache *inMask,
                       uint32 inTint=0xffffff ) const = 0;
   virtual void StretchTo(const RenderTarget &outTarget,
                          const Rect &inSrcRect, const DRect &inDestRect) const = 0;
   virtual void BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
                            int inPosX, int inPosY,
                            int inSrcChannel, int inDestChannel ) const = 0;

   Texture *GetTexture(HardwareContext *inHardware,int inPlane=0);

   virtual HardwareRenderer *GetHardwareRenderer() { return 0; }

   void Bind(HardwareContext &inHardware,int inSlot=0);

   virtual Surface *clone() { return 0; }
   virtual void getPixels(const Rect &inRect,uint32 *outPixels,bool inIgnoreOrder=false,bool inLittleEndian=false) { }
   virtual void setPixels(const Rect &inRect,const uint32 *intPixels,bool inIgnoreOrder=false,bool inLittleEndian=false) { }
   virtual void getColorBoundsRect(int inMask, int inCol, bool inFind, Rect &outRect)
   {
      outRect = Rect(0,0,Width(),Height());
   }
   virtual uint32 getPixel(int inX,int inY) { return 0; }
   virtual void setPixel(int inX,int inY,uint32 inRGBA,bool inAlphaToo=false) { }
   virtual void scroll(int inDX,int inDY) { }
   virtual void colorTransform(const Rect &inRect, ColorTransform &inTransform) { }
   virtual void applyFilter(Surface *inSrc, const Rect &inRect, ImagePoint inOffset, Filter *inFilter) { }

   virtual void noise(unsigned int randomSeed, unsigned int low, unsigned int high, int channelOptions, bool grayScale) { }

   void OnChanged() { mVersion++; }

   int Version() const  { return mVersion; }


protected:
   mutable int   mVersion;
   Texture       *mTexture;
   virtual       ~Surface();
   unsigned int  mFlags;
   bool          mAllowTrans;
};

// Helper class....
class AutoSurfaceRender
{
   Surface *mSurface;
   RenderTarget mTarget;
public:
   AutoSurfaceRender(Surface *inSurface) : mSurface(inSurface),
       mTarget(inSurface->BeginRender( Rect(inSurface->Width(),inSurface->Height()),false ) ) { }
   AutoSurfaceRender(Surface *inSurface,const Rect &inRect) : mSurface(inSurface),
       mTarget(inSurface->BeginRender(inRect,false)) { }
   ~AutoSurfaceRender() { mSurface->EndRender(); }
   const RenderTarget &Target() { return mTarget; }

};

class SimpleSurface : public Surface
{
public:
   SimpleSurface(int inWidth,int inHeight,PixelFormat inPixelFormat,int inByteAlign=4,int inGPUPixelFormat=-1);

   PixelFormat Format() const  { return mPixelFormat; }

   int Width() const  { return mWidth; }
   int Height() const  { return mHeight; }
   const uint8 *GetBase() const { return mBase; }
   uint8       *Edit(const Rect *inRect);
   void        Commit() { };
   int GetStride() const { return mStride; }

   int         GPUFormat() const  { return mGPUPixelFormat; }
   void Clear(uint32 inColour,const Rect *inRect);
   void Zero();


   RenderTarget BeginRender(const Rect &inRect,bool inForHitTest);
   void EndRender();

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       BlendMode inBlend, const BitmapCache *inMask,
                       uint32 inTint=0xffffff ) const;

   virtual void StretchTo(const RenderTarget &outTarget,
                          const Rect &inSrcRect, const DRect &inDestRect) const;

   virtual void BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
                            int inPosX, int inPosY,
                            int inSrcChannel, int inDestChannel ) const;

   virtual void colorTransform(const Rect &inRect, ColorTransform &inTransform);
   virtual void setGPUFormat( PixelFormat pf ) { mGPUPixelFormat = pf; }
   void unmultiplyAlpha();
   
   Surface *clone();
   void getPixels(const Rect &inRect,uint32 *outPixels,bool inIgnoreOrder=false, bool inLittleEndian=false);
   void setPixels(const Rect &inRect,const uint32 *intPixels,bool inIgnoreOrder=false, bool inLittleEndian=false);
   void getColorBoundsRect(int inMask, int inCol, bool inFind, Rect &outRect);
   uint32 getPixel(int inX,int inY);
   void setPixel(int inX,int inY,uint32 inRGBA,bool inAlphaToo=false);
   void scroll(int inDX,int inDY);
   void applyFilter(Surface *inSrc, const Rect &inRect, ImagePoint inOffset, Filter *inFilter);
   void noise(unsigned int randomSeed, unsigned int low, unsigned int high, int channelOptions, bool grayScale);
   void createHardwareSurface();
   void destroyHardwareSurface();
   void dispose();
   
   void MakeTextureOnly();


protected:
   int           mWidth;
   int           mHeight;
   PixelFormat   mPixelFormat;
   int           mGPUPixelFormat;
   int           mStride;
   uint8         *mBase;
   ~SimpleSurface();

private:
   SimpleSurface(const SimpleSurface &inRHS);
   void operator=(const SimpleSurface &inRHS);
};

class HardwareSurface : public Surface
{
public:
   HardwareSurface(HardwareRenderer *inContext);

   PixelFormat Format()  const { return pfHardware; }

   int Width() const { return mHardware->Width(); }
   int Height() const { return mHardware->Height(); }
   const uint8 *GetBase() const { return 0; }
   uint8       *Edit(const Rect *inRect=0) { return 0; }
   void        Commit() { }
   int GetStride() const { return 0; }


   void Clear(uint32 inColour,const Rect *inRect=0) { mHardware->Clear(inColour,inRect); }
   RenderTarget BeginRender(const Rect &inRect,bool inForHitTest)
   {
      mHardware->BeginRender(inRect,inForHitTest);
      return RenderTarget(inRect,mHardware);
   }
   void EndRender()
   {
      mHardware->EndRender();
   }

   HardwareRenderer *GetHardwareRenderer() { return mHardware; }


   void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
               BlendMode inBlend, const BitmapCache *inMask,
               uint32 inTint ) const { }
   void StretchTo(const RenderTarget &outTarget,
               const Rect &inSrcRect, const DRect &inDestRect) const { }
   void BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
               int inPosX, int inPosY,
               int inSrcChannel, int inDestChannel ) const  { }

   Surface *clone();
   void getPixels(const Rect &inRect,uint32 *outPixels,bool inIgnoreOrder=false);
   void setPixels(const Rect &inRect,const uint32 *intPixels,bool inIgnoreOrder=false);

   protected:
      ~HardwareSurface();
   private:
      HardwareRenderer *mHardware;
};


} // end namespace nme


#endif
