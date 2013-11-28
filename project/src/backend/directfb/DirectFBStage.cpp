#include <directfb.h>
#include <Display.h>
#include "renderer/common/Surface.h"
#include "renderer/common/HardwareSurface.h"
#include "renderer/common/HardwareContext.h"
#include <KeyCodes.h>


namespace lime
{


class DirectFBFrame;
DirectFBFrame *sgDirectFBFrame;
IDirectFBEventBuffer *sgEventBuffer;
static IDirectFB *dfb = NULL;

// So as not to clutter this file ...
#include "DirectFBKeyInputEventConvert.cpp"


/*class DFBSurface : public Surface
{
public:
   DFBSurface(IDirectFBSurface *inSurface, bool inDelete) : mSurface(inSurface)
   {
      mDelete = inDelete;
      mLockedForHitTest = false;
   }
   
   ~DFBSurface()
   {
      //if (mDelete)
         //SDL_FreeSurface(mSurf);
   }
   
   int Width() const
   {
      int w;
      mSurface->GetSize(mSurface, &w, NULL);
      return w;
   }
   
   int Height() const
   {
      int h;
      mSurface->GetSize(mSurface, NULL, &h);
      return h;
   }
   
   PixelFormat Format() const
   {
      //uint8 swap = mSurf->format->Bshift; // is 0 on argb
      //if (mSurf->flags & SDL_SRCALPHA)
         //return swap ? pfARGBSwap : pfARGB;
      //return swap ? pfXRGBSwap : pfXRGB;
   }
   
   const uint8 *GetBase() const
   {
      return 0;
      //return (const uint8 *)mSurf->pixels;
   }
   
   int GetStride() const
   {
      return 0;
      //return mSurf->pitch;
   }
   
   void Clear(uint32 inColour, const Rect *inRect)
   {
      if (inRect)
      {
         mSurface->SetColor(mSurface, inColour>>16, inColour>>8, inColour, inColour>>24);
         mSurface->FillRectangle(mSurface, inRect->x, inRect->y, inRect->w, inRect->h);
      }
      else
      {
         mSurface->Clear(mSurface, inColour>>16, inColour>>8, inColour, inColour>>24);
      }
   }
   
   RenderTarget BeginRender(const Rect &inRect,bool inForHitTest)
   {
      mLockedForHitTest = inForHitTest;
      //if (SDL_MUSTLOCK(mSurf) && !mLockedForHitTest)
         //SDL_LockSurface(mSurf);
      //return RenderTarget(Rect(Width(), Height()), Format(), (uint8 *)mSurf->pixels, mSurf->pitch);
      return RenderTarget(Rect(Width(), Height()), Format(), 0, 0);
   }
   
   void EndRender()
   {
      //if (SDL_MUSTLOCK(mSurf) && !mLockedForHitTest)
         //SDL_UnlockSurface(mSurf);
   }
   
   void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect, int inPosX, int inPosY, BlendMode inBlend, const BitmapCache *inMask, uint32 inTint = 0xffffff) const
   {
       
   }
   
   void BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect, int inPosX, int inPosY, int inSrcChannel, int inDestChannel) const
   {
      
   }
   
   void StretchTo(const RenderTarget &outTarget, const Rect &inSrcRect, const DRect &inDestRect) const
   {
      
   }
   
   IDirectFBSurface *mSurface;
   bool  mDelete;
   bool  mLockedForHitTest;
   
};*/


class DirectFBStage : public Stage
{
public:
   DirectFBStage(IDirectFBSurface *inWindow, int inWidth, int inHeight) : mPrimarySurface(0)
   {
      mWindow = inWindow;
      
      mHardwareContext = HardwareContext::CreateDirectFB(dfb, inWindow);
      mHardwareContext->SetWindowSize(inWidth, inHeight);
      mHardwareContext->IncRef();
      mPrimarySurface = new HardwareSurface(mHardwareContext);
      mPrimarySurface->IncRef();
   }
   
   ~DirectFBStage()
   {
      mHardwareContext->DecRef();
      mPrimarySurface->DecRef();
   }
   
   void SetCursor(Cursor inCursor)
   {
      switch (inCursor)
      {
         case curNone:
            break;
         case curPointer:
            break;
         case curHand:
            break;
      }
   }
   
   void GetMouse()
   {
      
   }
   
   Surface *GetPrimarySurface()
   {
      return mPrimarySurface;
   }
   
   bool isOpenGL() const { return false; }
   
   void Flip()
   {
      
   }
   
   void Resize(const int inWidth, const int inHeight)
   {
      
   }
   
    void ProcessEvent(DFBEvent &inEvent)
    {
        switch (inEvent.clazz) {
        case DFEC_INPUT:
            DFBInputEvent &inputEvent = (DFBInputEvent &) inEvent;
            switch(inputEvent.type) {
            case DIET_KEYPRESS:
                {
                    Event event(etKeyDown);
                    if (DirectFBKeyInputEventConvert(inputEvent, event)) {
                        this->HandleEvent(event);
                    }
                }
                break;
            case DIET_KEYRELEASE:
                {
                    Event event(etKeyUp);
                    if (DirectFBKeyInputEventConvert(inputEvent, event)) {
                        this->HandleEvent(event);
                    }
                }
                break;
            // Mouse button press currently not handled, just stubbed here
            case DIET_BUTTONPRESS:
                switch (inputEvent.button) {
                case DIBI_LEFT:
                    break;
                case DIBI_RIGHT: 
                    break;
                case DIBI_MIDDLE:
                    break;
                default:
                    break;
                }
                break;
            // Mouse button release currently not handled, just stubbed here
            case DIET_BUTTONRELEASE:
                switch (inputEvent.button) {
                case DIBI_LEFT:
                    break;
                case DIBI_RIGHT:
                    break;
                case DIBI_MIDDLE:
                    break;
                default:
                    break;
                }
                break;
            } 
        }
    }

   IDirectFBSurface *mWindow;
   
private:
   HardwareContext *mHardwareContext;
   Surface *mPrimarySurface;
   
};


class DirectFBFrame : public Frame
{
public:
   DirectFBFrame(IDirectFBSurface *inWindow, int inWidth, int inHeight)
   {
      mStage = new DirectFBStage(inWindow, inWidth,inHeight);
      mStage->IncRef();
   }
   
   ~DirectFBFrame()
   {
      mStage->DecRef();
   }
   
   void Resize(const int inWidth, const int inHeight)
   {
      mStage->Resize(inWidth, inHeight);
   }
   
   void SetTitle()
   {
      
   }
   
   void SetIcon()
   {
      
   }
   
   DirectFBStage *GetStage()
   {
      return mStage;
   }
   
   IDirectFBSurface *GetWindow()
   {
      return mStage->mWindow;
   }
   
private:
   DirectFBStage *mStage;
   
};


bool sgDead = false;


void StartAnimation()
{
   DirectFBStage *stage = sgDirectFBFrame->GetStage();
   
   while (!sgDead) {
       int waitMs = (stage->GetNextWake() - GetTimeStamp()) * 1000;
       if (waitMs < 0) {
           waitMs = 0;
       }
       sgEventBuffer->WaitForEventWithTimeout(sgEventBuffer, 0, waitMs);
      
      while (sgEventBuffer->HasEvent(sgEventBuffer) != DFB_BUFFEREMPTY) {
          DFBEvent event;
          sgEventBuffer->GetEvent(sgEventBuffer, DFB_EVENT(&event));
          stage->ProcessEvent(event);
          if (sgDead) {
              break;
          }
      }

      Event poll(etPoll);
      stage->HandleEvent(poll);
   }
   
   Event deactivate(etDeactivate);
   stage->HandleEvent(deactivate);
   
   Event kill(etDestroyHandler);
   stage->HandleEvent(kill);
}

void PauseAnimation()
{
   
}

void ResumeAnimation()
{
   
}

void StopAnimation()
{
   
}


DirectFBFrame *createWindowFrame(const char *inTitle, int inWidth, int inHeight, unsigned int inFlags)
{
   putenv ((char*)"DFBARGS=system=x11");
   
   DirectFBInit(0, NULL);
   DirectFBCreate(&dfb);
   
   bool fullscreen = (inFlags & wfFullScreen) != 0;
   if (fullscreen)
   {
      dfb->SetCooperativeLevel(dfb, DFSCL_FULLSCREEN);
   }
   else
   {
      //dfb->SetCooperativeLevel(dfb, DFSCL_NORMAL);
      dfb->SetCooperativeLevel(dfb, DFSCL_FULLSCREEN);
   }
   
   dfb->SetVideoMode(dfb, inWidth, inHeight, 32);
   dfb->CreateInputEventBuffer(dfb, (DFBInputDeviceCapabilities)(DICAPS_KEYS | DICAPS_BUTTONS), DFB_FALSE, &sgEventBuffer);
   
   DFBSurfaceDescription dsc;
   dsc.flags = DSDESC_CAPS;
   dsc.caps = (DFBSurfaceCapabilities)(DSCAPS_PRIMARY | DSCAPS_FLIPPING);
   dsc.width = inWidth;
   dsc.height = inHeight;
   
   IDirectFBSurface *surface = NULL;
   dfb->CreateSurface(dfb, &dsc, &surface);
   
   return new DirectFBFrame(surface, inWidth, inHeight);
}

void CreateMainFrame(FrameCreationCallback inOnFrame, int inWidth, int inHeight, unsigned int inFlags, const char *inTitle, Surface *inIcon)
{
   sgDirectFBFrame = createWindowFrame(inTitle, inWidth, inHeight, inFlags);
   inOnFrame(sgDirectFBFrame);
   StartAnimation();
}


void SetIcon(const char *path)
{
   
}


QuickVec<int>* CapabilitiesGetScreenResolutions()
{
   int count;
   QuickVec<int> *out = new QuickVec<int>();
   return out;
}

double CapabilitiesGetScreenResolutionX()
{
	return 0;
}

double CapabilitiesGetScreenResolutionY()
{
	return 0;
}


}
