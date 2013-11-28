#include <Display.h>
#include <Graphics.h>
#include "renderer/common/Surface.h"
#include "renderer/common/HardwareContext.h"
#include "renderer/common/Texture.h"


namespace lime
{


class EmptyHardwareContext : public HardwareContext
{
public:
   int mWidth;
   int mHeight;


   EmptyHardwareContext()
   {
      mWidth = mHeight = 0;
   }

   void SetWindowSize(int inWidth,int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
   }

   void SetQuality(StageQuality inQuality)
   {
   }

   void BeginRender(const Rect &inRect,bool inForHitTest)
   {
   }

   void EndRender()
   {
   }


   void SetViewport(const Rect &inRect)
   {
   }

   void Clear(uint32 inColour,const Rect *inRect=0)
   {
   }

   void Flip()
   {
   }

   void DestroyNativeTexture(void *)
   {
      // TODO
   }

   int Width() const { return mWidth; }

   int Height() const { return mHeight; } 

   class Texture *CreateTexture(class Surface *inSurface, unsigned int inFlags);

   void Render(const RenderState &inState, const HardwareCalls &inCalls )
   {
   }

   void BeginBitmapRender(Surface *inSurface,uint32 inTint,bool inRepeat,bool inSmooth)
   {
   }

   void RenderBitmap(const Rect &inSrc, int inX, int inY)
   {
   }

   void EndBitmapRender()
   {
   }
};




class EmptyTexture : public Texture
{
public:
   unsigned int flags;
   int          width;
   int          height;

   EmptyTexture(EmptyHardwareContext *inContext,Surface *inSurface, unsigned int inFlags)
   {
   }

   ~EmptyTexture()
   {
   }

   void Bind(class Surface *inSurface,int inSlot)
   {
   }

   void BindFlags(bool inRepeat,bool inSmooth)
   {
      // TODO:
   }
   UserPoint PixelToTex(const UserPoint &inPixels)
   {
      return UserPoint(inPixels.x/width, inPixels.y/height);
   }
   UserPoint TexToPaddedTex(const UserPoint &inPixels)
   {
      return inPixels;
   }

};



class Texture *EmptyHardwareContext::CreateTexture(class Surface *inSurface, unsigned int inFlags)
{
   return new EmptyTexture(this, inSurface, inFlags);
}






HardwareContext *HardwareContext::current = 0;

HardwareContext *HardwareContext::CreateOpenGL(void *inWindow, void *inGLCtx, bool shaders)
{
   return new EmptyHardwareContext();
}

} // end namespace lime
