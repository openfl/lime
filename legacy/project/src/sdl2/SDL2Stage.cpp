#include <Display.h>
#include <Utils.h>
#include <SDL.h>
#include <Surface.h>
#include <nme/NmeCffi.h>
#include <KeyCodes.h>
#include <map>
#include <Sound.h>
#include <utf8.h>

#ifdef NME_MIXER
#include <SDL_mixer.h>
#endif

#ifdef HX_WINDOWS
#include <SDL_syswm.h>
#include <Windows.h>
#endif


namespace nme
{
   

static int sgDesktopWidth = 0;
static int sgDesktopHeight = 0;
static Rect sgWindowRect = Rect(0, 0, 0, 0);
static bool sgInitCalled = false;
static bool sgJoystickEnabled = false;
static int  sgShaderFlags = 0;
static bool sgIsOGL2 = false;
const int sgJoystickDeadZone = 1000;

enum { NO_TOUCH = -1 };


int InitSDL()
{   
   if (sgInitCalled)
      return 0;
      
   sgInitCalled = true;
   
   #ifdef NME_MIXER
   int audioFlag = SDL_INIT_AUDIO;
   #else
   int audioFlag = 0;
   #endif
   int err = SDL_Init(SDL_INIT_VIDEO | audioFlag | SDL_INIT_TIMER);
   
   if (err == 0 && SDL_InitSubSystem (SDL_INIT_JOYSTICK) == 0)
   {
      sgJoystickEnabled = true;
   }
   
   return err;
}

static void openAudio()
{
   #ifdef NME_MIXER
   gSDLAudioState = sdaOpen;

   #ifdef HX_WINDOWS
   int chunksize = 2048;
   #else
   int chunksize = 4096;
   #endif
   
   int frequency = 44100;
   //int frequency = MIX_DEFAULT_FREQUENCY //22050
   //The default frequency would have less latency, but is incompatible with the average MP3 file
   
   if (Mix_OpenAudio(frequency, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS, chunksize) != 0)
   {
      fprintf(stderr,"Could not open sound: %s\n", Mix_GetError());
      gSDLAudioState = sdaError;
   }
   #endif
}

void InitSDLAudio()
{
   SDL_Init(SDL_INIT_AUDIO);
   openAudio();
}



class SDLSurf : public Surface
{
public:
   SDLSurf(SDL_Surface *inSurf,bool inDelete) : mSurf(inSurf)
   {
      mDelete = inDelete;
      mLockedForHitTest = false;
   }
   ~SDLSurf()
   {
      if (mDelete)
         SDL_FreeSurface(mSurf);
   }
   
   int Width() const { return mSurf->w; }
   int Height() const { return mSurf->h; }
   PixelFormat Format() const
   {
      if (mSurf->format->Amask)
         return pfARGB;
      return pfXRGB;
   }
   const uint8 *GetBase() const { return (const uint8 *)mSurf->pixels; }
   int GetStride() const { return mSurf->pitch; }

   void Clear(uint32 inColour,const Rect *inRect)
   {
      SDL_Rect r;
      SDL_Rect *rect_ptr = 0;
      if (inRect)
      {
         rect_ptr = &r;
         r.x = inRect->x;
         r.y = inRect->y;
         r.w = inRect->w;
         r.h = inRect->h;
      }
      
      SDL_FillRect(mSurf,rect_ptr,SDL_MapRGBA(mSurf->format,
            inColour>>16, inColour>>8, inColour, inColour>>24 )  );
   }

   uint8 *Edit(const Rect *inRect)
   {
      if (SDL_MUSTLOCK(mSurf))
         SDL_LockSurface(mSurf);

      return (uint8 *)mSurf->pixels;
   }
   void Commit()
   {
      if (SDL_MUSTLOCK(mSurf))
         SDL_UnlockSurface(mSurf);
   }

   RenderTarget BeginRender(const Rect &inRect,bool inForHitTest)
   {
      mLockedForHitTest = inForHitTest;
      if (SDL_MUSTLOCK(mSurf) && !mLockedForHitTest)
         SDL_LockSurface(mSurf);
      return RenderTarget(Rect(Width(),Height()), Format(),
         (uint8 *)mSurf->pixels, mSurf->pitch);
   }
   void EndRender()
   {
      if (SDL_MUSTLOCK(mSurf) && !mLockedForHitTest)
         SDL_UnlockSurface(mSurf);
   }

   void BlitTo(const RenderTarget &outTarget,
               const Rect &inSrcRect,int inPosX, int inPosY,
               BlendMode inBlend, const BitmapCache *inMask,
               uint32 inTint=0xffffff ) const
   {
   }
   void BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
                            int inPosX, int inPosY,
                            int inSrcChannel, int inDestChannel ) const
   {
   }

   void StretchTo(const RenderTarget &outTarget,
          const Rect &inSrcRect, const DRect &inDestRect) const
   {
   }

   SDL_Surface *mSurf;
   bool  mDelete;
   bool  mLockedForHitTest;
};


/*
SDL_Surface *SurfaceToSDL(Surface *inSurface)
{
   int swap =  (gC0IsRed!=(bool)(inSurface->Format()&pfSwapRB)) ? 0xff00ff : 0;
   return SDL_CreateRGBSurfaceFrom((void *)inSurface->Row(0),
             inSurface->Width(), inSurface->Height(),
             32, inSurface->Width()*4,
             0x00ff0000^swap, 0x0000ff00,
             0x000000ff^swap, 0xff000000 );
}
*/

SDL_Cursor *CreateCursor(const char *image[],int inHotX,int inHotY)
{
   int i, row, col;
   Uint8 data[4*32];
   Uint8 mask[4*32];

   i = -1;
   for ( row=0; row<32; ++row ) {
      for ( col=0; col<32; ++col ) {
         if ( col % 8 ) {
            data[i] <<= 1;
            mask[i] <<= 1;
         } else {
            ++i;
            data[i] = mask[i] = 0;
         }
         switch (image[row][col]) {
            case 'X':
               data[i] |= 0x01;
               mask[i] |= 0x01;
               break;
            case '.':
               mask[i] |= 0x01;
               break;
            case ' ':
               break;
         }
      }
   }
   return SDL_CreateCursor(data, mask, 32, 32, inHotX, inHotY);
}

SDL_Cursor *sDefaultCursor = 0;
SDL_Cursor *sTextCursor = 0;
SDL_Cursor *sHandCursor = 0;


class SDLStage : public Stage
{
public:
   SDLStage(SDL_Window *inWindow, SDL_Renderer *inRenderer, uint32 inWindowFlags, bool inIsOpenGL, int inWidth, int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      
      mIsOpenGL = inIsOpenGL;
      mSDLWindow = inWindow;
      mSDLRenderer = inRenderer;
      mWindowFlags = inWindowFlags;
      
      mShowCursor = true;
      mCurrentCursor = curPointer;
      
      mIsFullscreen = (mWindowFlags & SDL_WINDOW_FULLSCREEN || mWindowFlags & SDL_WINDOW_FULLSCREEN_DESKTOP);
      if (mIsFullscreen)
         displayState = sdsFullscreenInteractive;
      
      if (mIsOpenGL)
      {
         mOpenGLContext = HardwareRenderer::CreateOpenGL(0, 0, sgIsOGL2);
         mOpenGLContext->IncRef();
         //mOpenGLContext->SetWindowSize(inSurface->w, inSurface->h);
         mOpenGLContext->SetWindowSize(mWidth, mHeight);
         mPrimarySurface = new HardwareSurface(mOpenGLContext);
      }
      else
      {
         mOpenGLContext = 0;
         mSoftwareSurface = SDL_CreateRGBSurface(0, mWidth, mHeight, 32, 0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
         if (!mSoftwareSurface)
         {
            fprintf(stderr, "Could not create SDL surface : %s\n", SDL_GetError());
         }
         mSoftwareTexture = SDL_CreateTexture(mSDLRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, mWidth, mHeight);
         mPrimarySurface = new SDLSurf(mSoftwareSurface, inIsOpenGL);
      }
      mPrimarySurface->IncRef();
     
      #if defined(WEBOS) || defined(BLACKBERRY) || defined(HX_LINUX) || defined(HX_WINDOWS)
      mMultiTouch = true;
      #else
      mMultiTouch = false;
      #endif
      mSingleTouchID = NO_TOUCH;
      mDX = 0;
      mDY = 0;
      
      mDownX = 0;
      mDownY = 0;
   }
   
   
   ~SDLStage()
   {
      SDL_SetWindowFullscreen(mSDLWindow, 0);
      if (!mIsOpenGL)
      {
         SDL_FreeSurface(mSoftwareSurface);
         SDL_DestroyTexture(mSoftwareTexture);
      }
      else
      {
         mOpenGLContext->DecRef();
      }
      mPrimarySurface->DecRef();
      SDL_DestroyRenderer(mSDLRenderer);
      SDL_DestroyWindow(mSDLWindow);
   }
   
   
   void Resize(int inWidth, int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      
      if (mIsOpenGL)
      {
         mOpenGLContext->SetWindowSize(inWidth, inHeight);
      }
      else
      {
         SDL_FreeSurface(mSoftwareSurface);
         SDL_DestroyTexture(mSoftwareTexture);
         
         mSoftwareSurface = SDL_CreateRGBSurface(0, mWidth, mHeight, 32, 0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
         if (!mSoftwareSurface)
         {
            fprintf(stderr, "Could not create SDL surface : %s\n", SDL_GetError());
         }
         mSoftwareTexture = SDL_CreateTexture(mSDLRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, mWidth, mHeight);
         ((SDLSurf*)mPrimarySurface)->mSurf = mSoftwareSurface;
      }
   }
   
   
   void ResizeWindow(int inWidth, int inHeight)
   {
      if (mIsFullscreen)
      {
         SDL_DisplayMode mode;
         SDL_GetCurrentDisplayMode(0, &mode);
         
         mode.w = inWidth;
         mode.h = inHeight;
         
         SDL_SetWindowDisplayMode(mSDLWindow, &mode);
      }
      else
      {
         SDL_SetWindowSize(mSDLWindow, inWidth, inHeight);
      }
   }
   
   
   void SetFullscreen(bool inFullscreen)
   {
      if (inFullscreen != mIsFullscreen)
      {
         mIsFullscreen = inFullscreen;
         
         if (mIsFullscreen)
         {
            SDL_GetWindowPosition(mSDLWindow, &sgWindowRect.x, &sgWindowRect.y);
            SDL_GetWindowSize(mSDLWindow, &sgWindowRect.w, &sgWindowRect.h);
            
            //SDL_SetWindowSize(mSDLWindow, sgDesktopWidth, sgDesktopHeight);
            
            SDL_DisplayMode mode;
            SDL_GetCurrentDisplayMode(0, &mode);
            mode.w = sgDesktopWidth;
            mode.h = sgDesktopHeight;
            SDL_SetWindowDisplayMode(mSDLWindow, &mode);
            
            SDL_SetWindowFullscreen(mSDLWindow, SDL_WINDOW_FULLSCREEN_DESKTOP /*SDL_WINDOW_FULLSCREEN_DESKTOP*/);
         }
         else
         {
            SDL_SetWindowFullscreen(mSDLWindow, 0);
            if (sgWindowRect.w && sgWindowRect.h)
            {
               SDL_SetWindowSize(mSDLWindow, sgWindowRect.w, sgWindowRect.h);
            }
            #ifndef HX_LINUX
            SDL_SetWindowPosition(mSDLWindow, sgWindowRect.x, sgWindowRect.y);
            #endif
         }
         
         SDL_ShowCursor(mShowCursor);
      }
   }


   void SetResolution(int inWidth, int inHeight)
   {
      fprintf(stderr, "SetResolution %i %i\n", inWidth, inHeight);
      SDL_DisplayMode mode;
      SDL_GetCurrentDisplayMode(0, &mode);
      fprintf(stderr, "Current %i %i\n", mode.w, mode.h);
      mode.w = inWidth;
      mode.h = inHeight;
      SDL_SetWindowFullscreen(mSDLWindow, 0);
      SDL_SetWindowDisplayMode(mSDLWindow, &mode);
      SDL_SetWindowFullscreen(mSDLWindow, SDL_WINDOW_FULLSCREEN_DESKTOP);
   }
   

   void SetScreenMode(ScreenMode m)
   {
      if (m.width <= 1 || m.height <= 1)
      {
         //fprintf(stderr, "Stop calling me\n");
         return;
      }
      SDL_DisplayMode mode;
      mode.w = m.width;
      mode.h = m.height;
      mode.refresh_rate = m.refreshRate;
      switch (m.format) {
      case PIXELFORMAT_UNKNOWN:
         mode.format = SDL_PIXELFORMAT_UNKNOWN;
         break;
      case PIXELFORMAT_INDEX1LSB:
         mode.format = SDL_PIXELFORMAT_INDEX1LSB;
         break;
      case PIXELFORMAT_INDEX1MSB:
         mode.format = SDL_PIXELFORMAT_INDEX1MSB;
         break;
      case PIXELFORMAT_INDEX4LSB:
         mode.format = SDL_PIXELFORMAT_INDEX4LSB;
         break;
      case PIXELFORMAT_INDEX4MSB:
         mode.format = SDL_PIXELFORMAT_INDEX4MSB;
         break;
      case PIXELFORMAT_INDEX8:
         mode.format = SDL_PIXELFORMAT_INDEX8;
         break;
      case PIXELFORMAT_RGB332:
         mode.format = SDL_PIXELFORMAT_RGB332;
         break;
      case PIXELFORMAT_RGB444:
         mode.format = SDL_PIXELFORMAT_RGB444;
         break;
      case PIXELFORMAT_RGB555:
         mode.format = SDL_PIXELFORMAT_RGB555;
         break;
      case PIXELFORMAT_BGR555:
         mode.format = SDL_PIXELFORMAT_BGR555;
         break;
      case PIXELFORMAT_ARGB4444:
         mode.format = SDL_PIXELFORMAT_ARGB4444;
         break;
      case PIXELFORMAT_RGBA4444:
         mode.format = SDL_PIXELFORMAT_RGBA4444;
         break;
      case PIXELFORMAT_ABGR4444:
         mode.format = SDL_PIXELFORMAT_ABGR4444;
         break;
      case PIXELFORMAT_BGRA4444:
         mode.format = SDL_PIXELFORMAT_BGRA4444;
         break;
      case PIXELFORMAT_ARGB1555:
         mode.format = SDL_PIXELFORMAT_ARGB1555;
         break;
      case PIXELFORMAT_RGBA5551:
         mode.format = SDL_PIXELFORMAT_RGBA5551;
         break;
      case PIXELFORMAT_ABGR1555:
         mode.format = SDL_PIXELFORMAT_ABGR1555;
         break;
      case PIXELFORMAT_BGRA5551:
         mode.format = SDL_PIXELFORMAT_BGRA5551;
         break;
      case PIXELFORMAT_RGB565:
         mode.format = SDL_PIXELFORMAT_RGB565;
         break;
      case PIXELFORMAT_BGR565:
         mode.format = SDL_PIXELFORMAT_BGR565;
         break;
      case PIXELFORMAT_RGB24:
         mode.format = SDL_PIXELFORMAT_RGB24;
         break;
      case PIXELFORMAT_BGR24:
         mode.format = SDL_PIXELFORMAT_BGR24;
         break;
      case PIXELFORMAT_RGB888:
         mode.format = SDL_PIXELFORMAT_RGB888;
         break;
      case PIXELFORMAT_RGBX8888:
         mode.format = SDL_PIXELFORMAT_RGBX8888;
         break;
      case PIXELFORMAT_BGR888:
         mode.format = SDL_PIXELFORMAT_BGR888;
         break;
      case PIXELFORMAT_BGRX8888:
         mode.format = SDL_PIXELFORMAT_BGRX8888;
         break;
      case PIXELFORMAT_ARGB8888:
         mode.format = SDL_PIXELFORMAT_ARGB8888;
         break;
      case PIXELFORMAT_RGBA8888:
         mode.format = SDL_PIXELFORMAT_RGBA8888;
         break;
      case PIXELFORMAT_ABGR8888:
         mode.format = SDL_PIXELFORMAT_ABGR8888;
         break;
      case PIXELFORMAT_BGRA8888:
         mode.format = SDL_PIXELFORMAT_BGRA8888;
         break;
      case PIXELFORMAT_ARGB2101010:
         mode.format = SDL_PIXELFORMAT_ARGB2101010;
         break;
      case PIXELFORMAT_YV12:
         mode.format = SDL_PIXELFORMAT_YV12;
         break;
      case PIXELFORMAT_IYUV:
         mode.format = SDL_PIXELFORMAT_IYUV;
         break;
      case PIXELFORMAT_YUY2:
         mode.format = SDL_PIXELFORMAT_YUY2;
         break;
      case PIXELFORMAT_UYVY:
         mode.format = SDL_PIXELFORMAT_UYVY;
         break;
      case PIXELFORMAT_YVYU:
         mode.format = SDL_PIXELFORMAT_YVYU;
         break;
      }
      SDL_SetWindowFullscreen(mSDLWindow, 0);
      SDL_SetWindowDisplayMode(mSDLWindow, &mode);
      SDL_SetWindowFullscreen(mSDLWindow, SDL_WINDOW_FULLSCREEN_DESKTOP);
   }
    
   
   bool isOpenGL() const { return mOpenGLContext; }
   
   
   void ProcessEvent(Event &inEvent)
   {
      #if defined(HX_WINDOWS) || defined(HX_LINUX)
      if (inEvent.type == etKeyUp && (inEvent.flags & efAltDown) && inEvent.value == keyF4)
      {
         inEvent.type = etQuit;
      }
      #endif

      #if defined(WEBOS) || defined(BLACKBERRY)
      if (inEvent.type == etMouseMove || inEvent.type == etMouseDown || inEvent.type == etMouseUp)
      {
         if (mSingleTouchID == NO_TOUCH || inEvent.value == mSingleTouchID || !mMultiTouch)
         inEvent.flags |= efPrimaryTouch;
         
         if (mMultiTouch)
         {
            switch(inEvent.type)
            {
               case etMouseDown: inEvent.type = etTouchBegin; break;
               case etMouseUp: inEvent.type = etTouchEnd; break;
               case etMouseMove: inEvent.type = etTouchMove; break;
            }
            
            if (inEvent.type == etTouchBegin)
            {   
               mDownX = inEvent.x;
               mDownY = inEvent.y;   
            }
            
            if (inEvent.type == etTouchEnd)
            {   
               if (mSingleTouchID == inEvent.value)
                  mSingleTouchID = NO_TOUCH;
            }
         }
      }
      #endif
      
      HandleEvent(inEvent);
   }
   
   
   void Flip()
   {
      if (mIsOpenGL)
      {
         #ifdef RASPBERRYPI
         nmeEGLSwapBuffers();
         #else
         SDL_RenderPresent(mSDLRenderer);
         #endif
      }
      else
      {
         SDL_UpdateTexture(mSoftwareTexture, NULL, mSoftwareSurface->pixels, mSoftwareSurface->pitch);
         //SDL_RenderClear(mSDLRenderer);
         SDL_RenderCopy(mSDLRenderer, mSoftwareTexture, NULL, NULL);
         SDL_RenderPresent(mSDLRenderer);
      }
   }
   
   
   void GetMouse()
   {
      
   }
   
   
   void SetCursor(Cursor inCursor)
   {
      if (sDefaultCursor==0)
         sDefaultCursor = SDL_GetCursor();
      
      mCurrentCursor = inCursor;
      
      if (inCursor==curNone || !mShowCursor)
         SDL_ShowCursor(false);
      else
      {
         SDL_ShowCursor(true);
         
         if (inCursor==curPointer)
            SDL_SetCursor(sDefaultCursor);
         else if (inCursor==curHand)
         {
            if (!sHandCursor)
               sHandCursor = CreateCursor(sHandCursorData,13,1);
            SDL_SetCursor(sHandCursor);
         }
         else
         {
         // TODO: Rotated
         if (sTextCursor==0)
            sTextCursor = CreateCursor(sTextCursorData,2,13);
         SDL_SetCursor(sTextCursor);
         }
      }
   }
   
   
   void ShowCursor(bool inShow)
   {
      if (inShow!=mShowCursor)
      {
         mShowCursor = inShow;
         this->SetCursor(mCurrentCursor);
      }
   }

    void ConstrainCursorToWindowFrame(bool inLock) 
    {
        if (inLock != mLockCursor) 
        {
           mLockCursor = inLock;
           SDL_SetRelativeMouseMode( inLock ? SDL_TRUE : SDL_FALSE );
        }
    }
   
      //Note that this fires a mouse event, see the SDL_WarpMouseInWindow docs
    void SetCursorPositionInWindow(int inX, int inY) 
    {
      SDL_WarpMouseInWindow( mSDLWindow, inX, inY );
    }   
   
      //Note that this fires a mouse event, see the SDL_WarpMouseInWindow docs
    void SetStageWindowPosition(int inX, int inY) 
    {
      SDL_SetWindowPosition( mSDLWindow, inX, inY );
    }   
 
   int GetWindowX() 
   {
      int x = 0;
      int y = 0;
      SDL_GetWindowPosition(mSDLWindow, &x, &y);
      return x;
   }   
 
  
   int GetWindowY() 
   {
      int x = 0;
      int y = 0;
      SDL_GetWindowPosition(mSDLWindow, &x, &y);
      return y;
   }   

   
   bool textInputEnabled;
   void EnablePopupKeyboard(bool enabled)
   {
      #if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
      //fprintf(stderr, enabled ? "popup keyboard enabled true\n" : "popup keyboard enabled false\n");
      if (!textInputEnabled && enabled)
      {
         SDL_StartTextInput();
      }
      else if (textInputEnabled && !enabled)
      {
         SDL_StopTextInput();
      }
      textInputEnabled = enabled;
      #endif
   }
   
   
   bool getMultitouchSupported()
   {
      #if defined(WEBOS) || defined(BLACKBERRY) || defined(HX_LINUX) || defined(HX_WINDOWS)
      return true;
      #else
      return false;
      #endif
   }
   
   
   void setMultitouchActive(bool inActive) { mMultiTouch = inActive; }
   
   
   bool getMultitouchActive()
   {
      #if defined(WEBOS) || defined(BLACKBERRY) || defined(HX_LINUX) || defined(HX_WINDOWS)
      return mMultiTouch;
      #else
      return false;
      #endif
   }
   
   
   bool mMultiTouch;
   int  mSingleTouchID;
  
   double mDX;
   double mDY;

   double mDownX;
   double mDownY;
   
   const char *getJoystickName(int id) {
      return SDL_JoystickNameForIndex(id);
   }
   
   
   Surface *GetPrimarySurface()
   {
      return mPrimarySurface;
   }
   
   
   HardwareRenderer *mOpenGLContext;
   SDL_Window *mSDLWindow;
   SDL_Renderer *mSDLRenderer;
   Surface     *mPrimarySurface;
   SDL_Surface *mSoftwareSurface;
   SDL_Texture *mSoftwareTexture;
   double       mFrameRate;
   bool         mIsOpenGL;
   Cursor       mCurrentCursor;
   bool         mShowCursor;
   bool            mLockCursor;   
   bool         mIsFullscreen;
   unsigned int mWindowFlags;
   int          mWidth;
   int          mHeight;
};


class SDLFrame : public Frame
{
public:
   SDLFrame(SDL_Window *inWindow, SDL_Renderer *inRenderer, uint32 inWindowFlags, bool inIsOpenGL, int inWidth, int inHeight)
   {
      mWindowFlags = inWindowFlags;
      mIsOpenGL = inIsOpenGL;
      mStage = new SDLStage(inWindow, inRenderer, mWindowFlags, inIsOpenGL, inWidth, inHeight);
      mStage->IncRef();
   }
   
   
   ~SDLFrame()
   {
      mStage->DecRef();
   }
   
   
   void ProcessEvent(Event &inEvent)
   {
      mStage->ProcessEvent(inEvent);
   }
   
   
   void Resize(int inWidth, int inHeight)
   {
      mStage->Resize(inWidth, inHeight);
   }
   
   
   // --- Frame Interface ----------------------------------------------------
   
   
   void SetTitle()
   {
      
   }
   
   
   void SetIcon()
   {
      
   }
   
   
   Stage *GetStage()
   {
      return mStage;
   }
   
   
   SDLStage *mStage;
   bool mIsOpenGL;
   uint32 mWindowFlags;
   
   double mAccX;
   double mAccY;
   double mAccZ;
};


// --- When using the simple window class -----------------------------------------------


extern "C" void MacBoot( /*void (*)()*/ );


SDLFrame *sgSDLFrame = 0;
#ifndef EMSCRIPTEN
SDL_Joystick *sgJoystick;
QuickVec<SDL_Joystick *> sgJoysticks;
QuickVec<int> sgJoysticksId;
QuickVec<int> sgJoysticksIndex;
std::map<int, std::map<int, int> > sgJoysticksAxisMap;
#endif


void AddModStates(int &ioFlags,int inState = -1)
{
   int state = inState==-1 ? SDL_GetModState() : inState;
   if (state & KMOD_SHIFT) ioFlags |= efShiftDown;
   if (state & KMOD_CTRL) ioFlags |= efCtrlDown;
   if (state & KMOD_ALT) ioFlags |= efAltDown;
   if (state & KMOD_GUI) ioFlags |= efCommandDown;
   
   int m = SDL_GetMouseState(0,0);
   if ( m & SDL_BUTTON(1) ) ioFlags |= efLeftDown;
   if ( m & SDL_BUTTON(2) ) ioFlags |= efMiddleDown;
   if ( m & SDL_BUTTON(3) ) ioFlags |= efRightDown;
   
   ioFlags |= efPrimaryTouch;
   ioFlags |= efNoNativeClick;
}


#define SDL_TRANS(x) case SDLK_##x: return key##x;
#define SDL_TRANS_TO(x, y) case SDLK_##x: return key##y;


int SDLKeyToFlash(int inKey,bool &outRight)
{
   outRight = (inKey==SDLK_RSHIFT || inKey==SDLK_RCTRL ||
               inKey==SDLK_RALT || inKey==SDLK_RGUI);
   if (inKey>=keyA && inKey<=keyZ){
      return inKey;
   }
   if (inKey>=keyA+32 && inKey<=keyZ+32){
      return inKey - 32;
   }
   if (inKey>=SDLK_0 && inKey<=SDLK_9)
      return inKey - SDLK_0 + keyNUMBER_0;
   
   if (inKey>=SDLK_F1 && inKey<=SDLK_F12)
      return inKey - SDLK_F1 + keyF1;
   
   switch(inKey)
   {
      case SDLK_RALT:
      case SDLK_LALT:
         return keyALTERNATE;
      case SDLK_RSHIFT:
      case SDLK_LSHIFT:
         return keySHIFT;
      case SDLK_RCTRL:
      case SDLK_LCTRL:
         return keyCONTROL;
      case SDLK_LGUI:
      case SDLK_RGUI:
         return keyCOMMAND;
      
      case SDLK_CAPSLOCK: return keyCAPS_LOCK;
      case SDLK_PAGEDOWN: return keyPAGE_DOWN;
      case SDLK_PAGEUP: return keyPAGE_UP;
      case SDLK_EQUALS: return keyEQUAL;
      case SDLK_RETURN:
      case SDLK_KP_ENTER:
         return keyENTER;
      
      SDL_TRANS(AMPERSAND)
      SDL_TRANS(APPLICATION)
      SDL_TRANS(ASTERISK)
      SDL_TRANS(AT)
      SDL_TRANS(BACKQUOTE)
      SDL_TRANS(BACKSLASH)
      SDL_TRANS(BACKSPACE)
      SDL_TRANS(CARET)
      SDL_TRANS(COLON)
      SDL_TRANS(COMMA)
      SDL_TRANS(DELETE)
      SDL_TRANS(DOLLAR)
      SDL_TRANS(DOWN)
      SDL_TRANS(END)
      SDL_TRANS(ESCAPE)
      SDL_TRANS(EXCLAIM)
      SDL_TRANS(GREATER)
      SDL_TRANS(HASH)
      SDL_TRANS(HOME)
      SDL_TRANS(INSERT)
      SDL_TRANS(LEFT)
      SDL_TRANS(LEFTBRACKET)
      SDL_TRANS(LEFTPAREN)
      SDL_TRANS(LESS)
      SDL_TRANS(MINUS)
      SDL_TRANS(NUMLOCKCLEAR)
      SDL_TRANS(PAUSE)
      SDL_TRANS(PERCENT)
      SDL_TRANS(PERIOD)
      SDL_TRANS(PRINTSCREEN)
      SDL_TRANS(QUESTION)
      SDL_TRANS(QUOTE)
      SDL_TRANS(RIGHT)
      SDL_TRANS(RIGHTBRACKET)
      SDL_TRANS(RIGHTPAREN)
      SDL_TRANS(SCROLLLOCK)
      SDL_TRANS(SEMICOLON)
      SDL_TRANS(SLASH)
      SDL_TRANS(SPACE)
      SDL_TRANS(TAB)
      SDL_TRANS(UNDERSCORE)
      SDL_TRANS(UP)
      SDL_TRANS(F13)
      SDL_TRANS(F14)
      SDL_TRANS(F15)
      SDL_TRANS_TO(KP_0, NUMPAD_0)
      SDL_TRANS_TO(KP_1, NUMPAD_1)
      SDL_TRANS_TO(KP_2, NUMPAD_2)
      SDL_TRANS_TO(KP_3, NUMPAD_3)
      SDL_TRANS_TO(KP_4, NUMPAD_4)
      SDL_TRANS_TO(KP_5, NUMPAD_5)
      SDL_TRANS_TO(KP_6, NUMPAD_6)
      SDL_TRANS_TO(KP_7, NUMPAD_7)
      SDL_TRANS_TO(KP_8, NUMPAD_8)
      SDL_TRANS_TO(KP_9, NUMPAD_9)
      SDL_TRANS_TO(KP_PLUS, NUMPAD_ADD)
      SDL_TRANS_TO(KP_DECIMAL, NUMPAD_DECIMAL)
      SDL_TRANS_TO(KP_PERIOD, NUMPAD_DECIMAL)
      SDL_TRANS_TO(KP_DIVIDE, NUMPAD_DIVIDE)
      //SDL_TRANS_TO(KP_ENTER, NUMPAD_ENTER)
      SDL_TRANS_TO(KP_MULTIPLY, NUMPAD_MULTIPLY)
      SDL_TRANS_TO(KP_MINUS, NUMPAD_SUBTRACT)
   }

   return inKey;
}


void AddCharCode(Event &key)
{
   bool shift = (key.flags & efShiftDown);
   bool foundCode = true;
   
   if (!shift)
   {
      switch (key.value)
      {
         case 8:
         case 9:
         case 13:
         case 27:
         case 32:
            key.code = key.value;
            break;
         case 186:
            key.code = 59;
            break;
         case 187:
            key.code = 61;
            break;
         case 188:
         case 189:
         case 190:
         case 191:
            key.code = key.value - 144;
            break;
         case 192:
            key.code = 96;
            break;
         case 219:
         case 220:
         case 221:
            key.code = key.value - 128;
            break;
         case 222:
            key.code = 39;
            break;
         default:
            foundCode = false;
            break;
      }
      
      if (!foundCode)
      {
         if (key.value >= 48 && key.value <= 57)
         {
            key.code = key.value;
            foundCode = true;
         }
         else if (key.value >= 65 && key.value <= 90)
         {
            key.code = key.value + 32;
            foundCode = true;
         }
      }
   }
   else
   {
      switch (key.value)
      {
         case 48:
            key.code = 41;
            break;
         case 49:
            key.code = 33;
            break;
         case 50:
            key.code = 64;
            break;
         case 51:
         case 52:
         case 53:
            key.code = key.value - 16;
            break;
         case 54:
            key.code = 94;
            break;
         case 55:
            key.code = 38;
            break;
         case 56:
            key.code = 42;
            break;
         case 57:
            key.code = 40;
            break;
         case 186:
            key.code = 58;
            break;
         case 187:
            key.code = 43;
            break;
         case 188:
            key.code = 60;
            break;
         case 189:
            key.code = 95;
            break;
         case 190:
            key.code = 62;
            break;
         case 191:
            key.code = 63;
            break;
         case 192:
            key.code = 126;
            break;
         case 219:
         case 220:
         case 221:
            key.code = key.value - 96;
            break;
         case 222:
            key.code = 34;
            break;
         default:
            foundCode = false;
            break;
      }
      
      if (!foundCode)
      {
         if (key.value >= 65 && key.value <= 90)
         {
            key.code = key.value;
            foundCode = true;
         }
      }
   }
   
   if (!foundCode)
   {
      if (key.value >= 96 && key.value <= 105)
      {
         key.code = key.value - 48;
      }
      else if (key.value >= 106 && key.value <= 111)
      {
         key.code = key.value - 64;
      }
      else if (key.value == 46)
      {
         key.code = 127;
      }
      else if (key.value == 13)
      {
         key.code = 13;
      }
      else if (key.value == 8)
      {
         key.code = keyBACKSPACE;
      }
      else
      {
         key.code = 0;
      }
   }
}


std::map<int,wchar_t> sLastUnicode;
Event textInputEvent;

void ProcessEvent(SDL_Event &inEvent)
{
   switch(inEvent.type)
   {
      case SDL_QUIT:
      {
         Event close(etQuit);
         sgSDLFrame->ProcessEvent(close);
         break;
      }
      case SDL_WINDOWEVENT:
      {
         switch (inEvent.window.event)
         {
            case SDL_WINDOWEVENT_SHOWN:
            {
               Event activate(etActivate);
               sgSDLFrame->ProcessEvent(activate);
               break;
            }
            case SDL_WINDOWEVENT_HIDDEN:
            {
               Event deactivate(etDeactivate);
               sgSDLFrame->ProcessEvent(deactivate);
               break;
            }
            case SDL_WINDOWEVENT_EXPOSED:
            {
               Event poll(etPoll);
               sgSDLFrame->ProcessEvent(poll);
               break;
            }
            //case SDL_WINDOWEVENT_MOVED: break;
            //case SDL_WINDOWEVENT_RESIZED: break;
            case SDL_WINDOWEVENT_SIZE_CHANGED:
            {
               Event resize(etResize, inEvent.window.data1, inEvent.window.data2);
               sgSDLFrame->Resize(inEvent.window.data1, inEvent.window.data2);
               sgSDLFrame->ProcessEvent(resize);
               break;
            }
            case SDL_WINDOWEVENT_MINIMIZED:
            {
               Event deactivate(etDeactivate);
               sgSDLFrame->ProcessEvent(deactivate);
               break;
            }
            //case SDL_WINDOWEVENT_MAXIMIZED: break;
            case SDL_WINDOWEVENT_RESTORED:
            {
               Event activate(etActivate);
               sgSDLFrame->ProcessEvent(activate);
               break;
            }
            //case SDL_WINDOWEVENT_ENTER: break;
            //case SDL_WINDOWEVENT_LEAVE: break;
            case SDL_WINDOWEVENT_FOCUS_GAINED:
            {
               Event inputFocus(etGotInputFocus);
               sgSDLFrame->ProcessEvent(inputFocus);
               break;
            }
            case SDL_WINDOWEVENT_FOCUS_LOST:
            {
               Event inputFocus(etLostInputFocus);
               sgSDLFrame->ProcessEvent(inputFocus);
               break;
            }
            case SDL_WINDOWEVENT_CLOSE:
            {
               //Event deactivate(etDeactivate);
               //sgSDLFrame->ProcessEvent(deactivate);
               
               //Event kill(etDestroyHandler);
               //sgSDLFrame->ProcessEvent(kill);
               break;
            }
            default: break;
         }
         
         break;
         
      }
      case SDL_MOUSEMOTION:
      {  
            //default to 0
         int deltaX = 0;
         int deltaY = 0;

            //but if we are locking the cursor,
            //pass the delta in as well through as deltaX
         if(SDL_GetRelativeMouseMode()) {
            SDL_GetRelativeMouseState( &deltaX, &deltaY );
         }

            //int inValue=0, int inID=0, int inFlags=0, float inScaleX=1,float inScaleY=1, int inDeltaX=0,int inDeltaY=0
         Event mouse(etMouseMove, inEvent.motion.x, inEvent.motion.y, 0, 0, 0, 1.0f, 1.0f, deltaX, deltaY);
         #if defined(WEBOS) || defined(BLACKBERRY)
         mouse.value = inEvent.motion.which;
         mouse.flags |= efLeftDown;
         #else
         AddModStates(mouse.flags);
         #endif
         sgSDLFrame->ProcessEvent(mouse);
         break;
      }
      case SDL_MOUSEBUTTONDOWN:
      {
         Event mouse(etMouseDown, inEvent.button.x, inEvent.button.y, inEvent.button.button - 1);
         #if defined(WEBOS) || defined(BLACKBERRY)
         mouse.value = inEvent.motion.which;
         mouse.flags |= efLeftDown;
         #else
         AddModStates(mouse.flags);
         #endif
         sgSDLFrame->ProcessEvent(mouse);
         break;
      }
      case SDL_MOUSEBUTTONUP:
      {
         Event mouse(etMouseUp, inEvent.button.x, inEvent.button.y, inEvent.button.button - 1);
         #if defined(WEBOS) || defined(BLACKBERRY)
         mouse.value = inEvent.motion.which;
         #else
         AddModStates(mouse.flags);
         #endif
         sgSDLFrame->ProcessEvent(mouse);
         break;
      }
      case SDL_MOUSEWHEEL: 
      {   
            //previous behavior in nme was 3 for down, 4 for up
         int event_dir = (inEvent.wheel.y > 0) ? 3 : 4;
            //space to get the current mouse position, to make sure the values are sane
         int _x = 0; 
         int _y = 0;
            //fetch the mouse position
         SDL_GetMouseState(&_x,&_y);
            //create the event
         Event mouse(etMouseUp, _x, _y, event_dir);
            //add flags for modifier keys
         AddModStates(mouse.flags);
            //and done.
         sgSDLFrame->ProcessEvent(mouse);
         break;
      }

      #if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
      case SDL_TEXTINPUT:
      {
         int cp = utf8::peek_next(inEvent.text.text, inEvent.text.text+32);
         textInputEvent.code = cp;
         sgSDLFrame->ProcessEvent(textInputEvent);
		 break;
	   }
      #endif
      case SDL_FINGERMOTION:
      {
         SDL_TouchFingerEvent inFingerEvent = inEvent.tfinger;
         Event finger(etTouchMove, inFingerEvent.x, inFingerEvent.y, 0, 0, 0, 1.0f, 1.0f, inFingerEvent.dx, inFingerEvent.dy);
         finger.value = inFingerEvent.fingerId;
         sgSDLFrame->ProcessEvent(finger);
         break;
      }
      case SDL_FINGERDOWN:
      {
         SDL_TouchFingerEvent inFingerEvent = inEvent.tfinger;
         Event finger(etTouchBegin, inFingerEvent.x, inFingerEvent.y);
         finger.value = inFingerEvent.fingerId;
         sgSDLFrame->ProcessEvent(finger);
         break;
      }
      case SDL_FINGERUP:
      {
         SDL_TouchFingerEvent inFingerEvent = inEvent.tfinger;
         Event finger(etTouchEnd, inFingerEvent.x, inFingerEvent.y);
         finger.value = inFingerEvent.fingerId;
         sgSDLFrame->ProcessEvent(finger);
         break;
      }
      case SDL_KEYDOWN:
      case SDL_KEYUP:
      {
         Event key(inEvent.type == SDL_KEYDOWN ? etKeyDown : etKeyUp );
         bool right;
         key.value = SDLKeyToFlash(inEvent.key.keysym.sym, right);
         AddModStates(key.flags, inEvent.key.keysym.mod);
         if (right)
            key.flags |= efLocationRight;
         
         AddCharCode(key);
         #if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
         if (inEvent.type == SDL_KEYDOWN && sgSDLFrame->mStage->textInputEnabled && !iscntrl(key.code))
         {
            // Wait for text input event for correct keyboard layout handling
            textInputEvent = key;
         }
         else
         {
            sgSDLFrame->ProcessEvent(key);
         }
         #else
         sgSDLFrame->ProcessEvent(key);
         #endif
         break;
      }
      case SDL_JOYAXISMOTION:
      {
         if (sgJoysticksAxisMap[inEvent.jaxis.which].empty())
         {
            sgJoysticksAxisMap[inEvent.jaxis.which][inEvent.jaxis.axis] = inEvent.jaxis.value;
         }
         else if (sgJoysticksAxisMap[inEvent.jaxis.which][inEvent.jaxis.axis] == inEvent.jaxis.value)
         {
            break;
         }
         if (inEvent.jaxis.value > -sgJoystickDeadZone && inEvent.jaxis.value < sgJoystickDeadZone)
         {
            if (sgJoysticksAxisMap[inEvent.jaxis.which][inEvent.jaxis.axis] != 0)
            {
               sgJoysticksAxisMap[inEvent.jaxis.which][inEvent.jaxis.axis] = 0;
               Event joystick(etJoyAxisMove);
               joystick.id = inEvent.jaxis.which;
               joystick.code = inEvent.jaxis.axis;
               joystick.value = 0;
               sgSDLFrame->ProcessEvent(joystick);
            }
            break;
         }
         sgJoysticksAxisMap[inEvent.jaxis.which][inEvent.jaxis.axis] = inEvent.jaxis.value;
         Event joystick(etJoyAxisMove);
         joystick.id = inEvent.jaxis.which;
         joystick.code = inEvent.jaxis.axis;
         joystick.value = inEvent.jaxis.value;
         sgSDLFrame->ProcessEvent(joystick);
         break;
      }
      case SDL_JOYBALLMOTION:
      {
         Event joystick(etJoyBallMove, inEvent.jball.xrel, inEvent.jball.yrel);
         joystick.id = inEvent.jball.which;
         joystick.code = inEvent.jball.ball;
         sgSDLFrame->ProcessEvent(joystick);
         break;
      }
      case SDL_JOYBUTTONDOWN:
      {
         Event joystick(etJoyButtonDown);
         joystick.id = inEvent.jbutton.which;
         joystick.code = inEvent.jbutton.button;
         sgSDLFrame->ProcessEvent(joystick);
         break;
      }
      case SDL_JOYBUTTONUP:
      {
         Event joystick(etJoyButtonUp);
         joystick.id = inEvent.jbutton.which;
         joystick.code = inEvent.jbutton.button;
         for (int i = 0; i < sgJoysticksId.size(); i++) { //if SDL_JOYDEVICEREMOVED is triggered, up is fired on all buttons, so we need to counter the effect
            if (sgJoysticksId[i] == joystick.id) {
               sgSDLFrame->ProcessEvent(joystick);
               break;
            }
          }
         break;
      }
      case SDL_JOYHATMOTION:
      {
         Event joystick(etJoyHatMove);
         joystick.id = inEvent.jhat.which;
         joystick.code = inEvent.jhat.hat;
         joystick.value = inEvent.jhat.value;
         sgSDLFrame->ProcessEvent(joystick);
         break;
      }
      case SDL_JOYDEVICEADDED:
      {
         int joyId = -1;
         for (int i = 0; i < sgJoysticksId.size(); i++)
         {
            if (sgJoysticksIndex[i] == inEvent.jdevice.which)
            {
               joyId = inEvent.jdevice.which;
               break;
            }
         }
         if (joyId == -1)
         {
            Event joystick(etJoyDeviceAdded);
            sgJoystick = SDL_JoystickOpen(inEvent.jdevice.which); //which: joystick device index
            joystick.id = SDL_JoystickInstanceID(sgJoystick);
            //get string id
            const char * gamepadstring = SDL_JoystickName(sgJoystick);
            if (strcmp (gamepadstring, "PLAYSTATION(R)3 Controller") == 0)  //PS3 controller
            {
                joystick.x = 1;
            }
            else if (strcmp (gamepadstring, "Wireless Controller") == 0)    //PS4 controller
            {
                joystick.x = 2;
            }
            else if (strcmp (gamepadstring, "OUYA Game Controller") == 0)   //OUYA controller
            {
                joystick.x = 3;
            }
            else if (strcmp (gamepadstring, "Mayflash WIIMote PC Adapter") == 0)   //MayFlash WIIMote PC Adapter
            {
                joystick.x = 4;
            }
            else if (strcmp (gamepadstring, "Nintendo RVL-CNT-01-TR") == 0)   //Nintendo WIIMote MotionPlus, used directly
            {
                joystick.x = 5;
            }
            else if (strcmp (gamepadstring, "Nintendo RVL-CNT-01") == 0)      //Nintendo WIIMote w/o MotionPlus attachment, used directly
            {
                joystick.x = 6;
            }
            else    //default (XBox 360, basically)
            {
                joystick.x = 0;
            }
            sgJoysticks.push_back(sgJoystick);
            sgJoysticksId.push_back(joystick.id);
            sgJoysticksIndex.push_back(inEvent.jdevice.which);
            sgSDLFrame->ProcessEvent(joystick);
         }
         break;
      }
      case SDL_JOYDEVICEREMOVED:
      {
         Event joystick(etJoyDeviceRemoved);
         joystick.id = inEvent.jdevice.which; //which: instance id
         int j = 0;
         for (int i = 0; i < sgJoysticksId.size(); i++)
         {
            if (sgJoysticksId[i] == joystick.id)
            {
               SDL_JoystickClose(sgJoysticks[i]);
               break;   
            }
            j++;
         }
         sgJoysticksId.erase(j,1);
         sgJoysticks.erase(j,1);
         sgJoysticksIndex.erase(j,1);
         sgSDLFrame->ProcessEvent(joystick);
         break;
      }
   }
};


void CreateMainFrame(FrameCreationCallback inOnFrame, int inWidth, int inHeight, unsigned int inFlags, const char *inTitle, Surface *inIcon)
{
   #ifdef HX_MACOS
   MacBoot();
   #endif
   
   bool fullscreen = (inFlags & wfFullScreen) != 0;
   bool opengl = (inFlags & wfHardware) != 0;
   bool resizable = (inFlags & wfResizable) != 0;
   bool borderless = (inFlags & wfBorderless) != 0;
   bool vsync = (inFlags & wfVSync) != 0;

   #ifdef HX_LINUX
   if (opengl)
   {
      if (!InitOGLFunctions())
        opengl = false;
   }
   #endif


   
   sgShaderFlags = (inFlags & (wfAllowShaders|wfRequireShaders) );

   //Rect r(100,100,inWidth,inHeight);
   
   int err = InitSDL();
   if (err == -1)
   {
      fprintf(stderr,"Could not initialize SDL : %s\n", SDL_GetError());
      inOnFrame(0);
   }
   
   //SDL_EnableUNICODE(1);
   //SDL_EnableKeyRepeat(500,30);

   #ifdef NME_MIXER
   openAudio();
   #endif
   
   if (SDL_GetNumVideoDisplays() > 0)
   {
      SDL_DisplayMode currentMode;
      SDL_GetDesktopDisplayMode(0, &currentMode);
      sgDesktopWidth = currentMode.w;
      sgDesktopHeight = currentMode.h;
   }
   
   int windowFlags, requestWindowFlags = 0;
   
   if (opengl) requestWindowFlags |= SDL_WINDOW_OPENGL;
   if (resizable) requestWindowFlags |= SDL_WINDOW_RESIZABLE;
   if (borderless) requestWindowFlags |= SDL_WINDOW_BORDERLESS;
   if (fullscreen) requestWindowFlags |= SDL_WINDOW_FULLSCREEN_DESKTOP; //SDL_WINDOW_FULLSCREEN_DESKTOP;
   
   if (opengl)
   {
      SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
      SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
      SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
      
      if (inFlags & wfDepthBuffer)
         SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 32 - (inFlags & wfStencilBuffer) ? 8 : 0);
      
      if (inFlags & wfStencilBuffer)
         SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
      
      SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
      
      if (inFlags & wfHW_AA_HIRES)
      {
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, true);
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
      }
      else if (inFlags & wfHW_AA)
      {
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, true);
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 2);
      }

      //requestWindowFlags |= SDL_WINDOW_ALLOW_HIGHDPI;
   }
   
   #ifdef HX_LINUX
   int setWidth = inWidth;
   int setHeight = inHeight;
   #else
   int setWidth = fullscreen ? sgDesktopWidth : inWidth;
   int setHeight = fullscreen ? sgDesktopHeight : inHeight;
   #endif
   
   SDL_Window *window = NULL;
   SDL_Renderer *renderer = NULL;

   while (!window || !renderer) 
   {
      // if there's an old window around from a failed attempt, destroy it
      if (window) 
      {
         SDL_DestroyWindow(window);
         window = NULL;
      }

      window = SDL_CreateWindow(inTitle, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, setWidth, setHeight, requestWindowFlags);
      
      #ifdef HX_WINDOWS
      HINSTANCE handle = ::GetModuleHandle(0);
      HICON icon = ::LoadIcon(handle, MAKEINTRESOURCE (1));
      
      if (icon)
      {
         SDL_SysWMinfo wminfo;
         SDL_VERSION (&wminfo.version);
         
         if (SDL_GetWindowWMInfo(window, &wminfo) == 1)
         {
            HWND hwnd = wminfo.info.win.window;
            ::SetClassLong(hwnd, GCL_HICON, reinterpret_cast<LONG>(icon));
         }
      }
      #endif
     
      // retrieve the actual window flags (as opposed to the requested ones)
      windowFlags = SDL_GetWindowFlags (window);
      if (fullscreen) sgWindowRect = Rect(SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, inWidth, inHeight);

      int renderFlags = 0;
      if (opengl) renderFlags |= SDL_RENDERER_ACCELERATED;
      if (opengl && vsync) renderFlags |= SDL_RENDERER_PRESENTVSYNC;

      renderer = SDL_CreateRenderer (window, -1, renderFlags);
      
      if (opengl)
      {
         sgIsOGL2 = (inFlags & (wfAllowShaders | wfRequireShaders));
      }
      else
      {
         sgIsOGL2 = false;
      }
      
      if (!renderer && (inFlags & wfHW_AA_HIRES || inFlags & wfHW_AA)) {
         // if no window was created and AA was enabled, disable AA and try again
         fprintf(stderr, "Multisampling is not available. Retrying without. (%s)\n", SDL_GetError());
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, false);
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 0);
         inFlags &= ~wfHW_AA_HIRES;
         inFlags &= ~wfHW_AA;
      }
      else if (!renderer && opengl) 
      {
         // if opengl is enabled and no window was created, disable it and try again
         fprintf(stderr, "OpenGL is not available. Retrying without. (%s)\n", SDL_GetError());
         opengl = false;
         requestWindowFlags &= ~SDL_WINDOW_OPENGL;
      }
      else 
      {
         // no more things to try, break out of the loop
         break;
      }
   }

   if (!window)
   {
      fprintf(stderr, "Failed to create SDL window: %s\n", SDL_GetError());
      return;
   }  
   
   if (!renderer)
   {
      fprintf(stderr, "Failed to create SDL renderer: %s\n", SDL_GetError());
      return;
   }
   
   int width, height;
   if (windowFlags & SDL_WINDOW_FULLSCREEN || windowFlags & SDL_WINDOW_FULLSCREEN_DESKTOP)
   {
      //SDL_DisplayMode mode;
      //SDL_GetCurrentDisplayMode(0, &mode);
      //width = mode.w;
      //height = mode.h;
      width = sgDesktopWidth;
      height = sgDesktopHeight;
   }
   else
   {
      SDL_GetWindowSize(window, &width, &height);
   }
   
   sgSDLFrame = new SDLFrame(window, renderer, windowFlags, opengl, width, height);
   inOnFrame(sgSDLFrame);
   
   int numJoysticks = SDL_NumJoysticks();
   SDL_JoystickEventState(SDL_TRUE);
   
   StartAnimation();
}


bool sgDead = false;


void SetIcon(const OSChar *path)
{
   Surface *surface = Surface::Load(path);
   
   if (surface)
   {
      SDL_Surface *sdlSurface = SDL_CreateRGBSurfaceFrom ((void *)surface->GetBase(), surface->Width(), surface->Height(), 32, surface->GetStride(), 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);
      
      SDL_SetWindowIcon(sgSDLFrame->mStage->mSDLWindow, sdlSurface);
      
      surface->DecRef();
      SDL_FreeSurface (sdlSurface);
   }
}


QuickVec<int>* CapabilitiesGetScreenResolutions()
{   
   InitSDL();
   QuickVec<int> *out = new QuickVec<int>();
   
   int numModes = SDL_GetNumDisplayModes(0);
   SDL_DisplayMode mode;
   
   for (int i = 0; i < numModes; i++)
   {
      SDL_GetDisplayMode(0, i, &mode);
      out->push_back(mode.w);
      out->push_back(mode.h);
   }
   
   return out;
}


QuickVec<ScreenMode>* CapabilitiesGetScreenModes()
{
   InitSDL();
   QuickVec<ScreenMode> *out = new QuickVec<ScreenMode>();

   int numModes = SDL_GetNumDisplayModes(0);
   SDL_DisplayMode mode;

   for (int i = 0; i < numModes; i++)
   {
      SDL_GetDisplayMode(0, i, &mode);
      ScreenMode screenMode;
      screenMode.width = mode.w;
      screenMode.height = mode.h;
      switch (mode.format) {
      case SDL_PIXELFORMAT_UNKNOWN:
         screenMode.format = PIXELFORMAT_UNKNOWN;
         break;
      case SDL_PIXELFORMAT_INDEX1LSB:
         screenMode.format = PIXELFORMAT_INDEX1LSB;
         break;
      case SDL_PIXELFORMAT_INDEX1MSB:
         screenMode.format = PIXELFORMAT_INDEX1MSB;
         break;
      case SDL_PIXELFORMAT_INDEX4LSB:
         screenMode.format = PIXELFORMAT_INDEX4LSB;
         break;
      case SDL_PIXELFORMAT_INDEX4MSB:
         screenMode.format = PIXELFORMAT_INDEX4MSB;
         break;
      case SDL_PIXELFORMAT_INDEX8:
         screenMode.format = PIXELFORMAT_INDEX8;
         break;
      case SDL_PIXELFORMAT_RGB332:
         screenMode.format = PIXELFORMAT_RGB332;
         break;
      case SDL_PIXELFORMAT_RGB444:
         screenMode.format = PIXELFORMAT_RGB444;
         break;
      case SDL_PIXELFORMAT_RGB555:
         screenMode.format = PIXELFORMAT_RGB555;
         break;
      case SDL_PIXELFORMAT_BGR555:
         screenMode.format = PIXELFORMAT_BGR555;
         break;
      case SDL_PIXELFORMAT_ARGB4444:
         screenMode.format = PIXELFORMAT_ARGB4444;
         break;
      case SDL_PIXELFORMAT_RGBA4444:
         screenMode.format = PIXELFORMAT_RGBA4444;
         break;
      case SDL_PIXELFORMAT_ABGR4444:
         screenMode.format = PIXELFORMAT_ABGR4444;
         break;
      case SDL_PIXELFORMAT_BGRA4444:
         screenMode.format = PIXELFORMAT_BGRA4444;
         break;
      case SDL_PIXELFORMAT_ARGB1555:
         screenMode.format = PIXELFORMAT_ARGB1555;
         break;
      case SDL_PIXELFORMAT_RGBA5551:
         screenMode.format = PIXELFORMAT_RGBA5551;
         break;
      case SDL_PIXELFORMAT_ABGR1555:
         screenMode.format = PIXELFORMAT_ABGR1555;
         break;
      case SDL_PIXELFORMAT_BGRA5551:
         screenMode.format = PIXELFORMAT_BGRA5551;
         break;
      case SDL_PIXELFORMAT_RGB565:
         screenMode.format = PIXELFORMAT_RGB565;
         break;
      case SDL_PIXELFORMAT_BGR565:
         screenMode.format = PIXELFORMAT_BGR565;
         break;
      case SDL_PIXELFORMAT_RGB24:
         screenMode.format = PIXELFORMAT_RGB24;
         break;
      case SDL_PIXELFORMAT_BGR24:
         screenMode.format = PIXELFORMAT_BGR24;
         break;
      case SDL_PIXELFORMAT_RGB888:
         screenMode.format = PIXELFORMAT_RGB888;
         break;
      case SDL_PIXELFORMAT_RGBX8888:
         screenMode.format = PIXELFORMAT_RGBX8888;
         break;
      case SDL_PIXELFORMAT_BGR888:
         screenMode.format = PIXELFORMAT_BGR888;
         break;
      case SDL_PIXELFORMAT_BGRX8888:
         screenMode.format = PIXELFORMAT_BGRX8888;
         break;
      case SDL_PIXELFORMAT_ARGB8888:
         screenMode.format = PIXELFORMAT_ARGB8888;
         break;
      case SDL_PIXELFORMAT_RGBA8888:
         screenMode.format = PIXELFORMAT_RGBA8888;
         break;
      case SDL_PIXELFORMAT_ABGR8888:
         screenMode.format = PIXELFORMAT_ABGR8888;
         break;
      case SDL_PIXELFORMAT_BGRA8888:
         screenMode.format = PIXELFORMAT_BGRA8888;
         break;
      case SDL_PIXELFORMAT_ARGB2101010:
         screenMode.format = PIXELFORMAT_ARGB2101010;
         break;
      case SDL_PIXELFORMAT_YV12:
         screenMode.format = PIXELFORMAT_YV12;
         break;
      case SDL_PIXELFORMAT_IYUV:
         screenMode.format = PIXELFORMAT_IYUV;
         break;
      case SDL_PIXELFORMAT_YUY2:
         screenMode.format = PIXELFORMAT_YUY2;
         break;
      case SDL_PIXELFORMAT_UYVY:
         screenMode.format = PIXELFORMAT_UYVY;
         break;
      case SDL_PIXELFORMAT_YVYU:
         screenMode.format = PIXELFORMAT_YVYU;
         break;
      }
      screenMode.refreshRate = mode.refresh_rate;
      out->push_back(screenMode);
   }

   return out;
 }


double CapabilitiesGetScreenResolutionX()
{
   InitSDL();   
   return sgDesktopWidth;
}


double CapabilitiesGetScreenResolutionY()
{   
   InitSDL();   
   return sgDesktopHeight;
}


void PauseAnimation() {}
void ResumeAnimation() {}


void StopAnimation()
{
   #ifdef NME_MIXER
   if (gSDLAudioState==sdaOpen)
   {
      gSDLAudioState = sdaClosed;
      Mix_CloseAudio();
   }
   #else
   Sound::Shutdown();
   #endif
   sgDead = true;
}


static SDL_TimerID sgTimerID = 0;


#ifdef HX_LIME
bool sgTimerActive = false;

Uint32 OnTimer(Uint32 interval, void *)
{
   // Ping off an event - any event will force the frame check.
   SDL_Event event;
   SDL_UserEvent userevent;
   /* In this example, our callback pushes an SDL_USEREVENT event
   into the queue, and causes ourself to be called again at the
   same interval: */
   userevent.type = SDL_USEREVENT;
   userevent.code = 0;
   userevent.data1 = NULL;
   userevent.data2 = NULL;
   event.type = SDL_USEREVENT;
   event.user = userevent;
   sgTimerActive = false;
   sgTimerID = 0;
   SDL_PushEvent(&event);
   return 0;
}
#endif


#ifndef SDL_NOEVENT
#define SDL_NOEVENT -1;
#endif


void StartAnimation()
{
#ifndef HX_LIME
   SDL_Event event;
   event.type = SDL_NOEVENT;

   double nextWake = GetTimeStamp();
   while(!sgDead)
   {
      // Process real events ...
      while(SDL_PollEvent(&event))
      {
         ProcessEvent(event);
         if (sgDead)
            break;
         nextWake = sgSDLFrame->GetStage()->GetNextWake();
      }
 

      // Poll if due
      double dWaitMs = (nextWake - GetTimeStamp())*1000.0 + 0.5;
      if (dWaitMs>1000000)
         dWaitMs = 1000000;
      int waitMs = (int)dWaitMs;
      if (waitMs<=0)
      {
         Event poll(etPoll);
         sgSDLFrame->ProcessEvent(poll);
         nextWake = sgSDLFrame->GetStage()->GetNextWake();
         if (sgDead)
            break;
      }
      // Kill some time
      else
      {
         if (sgSDLFrame->mStage->BuildCache())
         {
            Event redraw(etRedraw);
            sgSDLFrame->ProcessEvent(redraw);
         }
         else
         {
            // Windows will oversleep 10ms for any positive number here...
            #ifdef HX_WINDOWS
            if (waitMs>10)
               SDL_Delay(1);
            else
               SDL_Delay(0);
            #else
            // TODO - check this is ok for other targets...
            if (waitMs>10)
               SDL_Delay(10);
            else if (waitMs>1)
               SDL_Delay(waitMs-1);
            #endif
         }
      }
   }
#else
   SDL_Event event;
   bool firstTime = true;
   while(!sgDead)
   {
      event.type = SDL_NOEVENT;
      while (!sgDead && (firstTime || SDL_WaitEvent(&event)))
      {
         firstTime = false;
         if (sgTimerActive && sgTimerID)
         {
            SDL_RemoveTimer(sgTimerID);
            sgTimerActive = false;
            sgTimerID = 0;
         }
         
         ProcessEvent(event);
         if (sgDead) break;
         event.type = SDL_NOEVENT;
         
         while (SDL_PollEvent(&event))
         {
            ProcessEvent (event);
            if (sgDead) break;
            event.type = -1;
         }
         
         Event poll(etPoll);
         sgSDLFrame->ProcessEvent(poll);
         
         if (sgDead) break;
         
         double next = sgSDLFrame->GetStage()->GetNextWake() - GetTimeStamp();
         
         if (next > 0.001)
         {
            int snooze = next*1000.0;
            sgTimerActive = true;
            sgTimerID = SDL_AddTimer(snooze, OnTimer, 0);
         }
         else
         {
            OnTimer(0, 0);
         }
      }
   }
#endif
   Event deactivate(etDeactivate);
   sgSDLFrame->ProcessEvent(deactivate);
   
   Event kill(etDestroyHandler);
   sgSDLFrame->ProcessEvent(kill);
   SDL_Quit();
}


}
