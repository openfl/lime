#include <Display.h>
#include <Utils.h>
#include <SDL.h>
#include "renderer/common/Surface.h"
#include "renderer/common/HardwareSurface.h"
#include "renderer/common/HardwareContext.h"
#include <ExternalInterface.h>
#include <KeyCodes.h>
#include <map>

#ifdef BLACKBERRY
#include <SDL_syswm.h>
#include <bps/sensor.h>
#include <bps/virtualkeyboard.h>
#endif

#ifdef WEBOS
#include "PDL.h"
#include <syslog.h>
#endif

#ifdef RASPBERRYPI
#include <SDL_syswm.h>
#include "../opengl/Egl.h"
#endif

#ifdef EMSCRIPTEN
#include <emscripten.h>
#endif

#ifdef LIME_MIXER
#include <SDL_mixer.h>
#endif

#ifdef SDL_IMAGE
#include <SDL_image.h>
#endif

#ifdef HX_WINDOWS
#include <windows.h>
#include <SDL_syswm.h>

HICON icon;
struct zWMcursor { void* curs; };
HWND hwnd;
SDL_SysWMinfo wminfo;

void init_win32()
{
	SDL_Cursor *cursor = SDL_GetCursor();

	HINSTANCE handle = GetModuleHandle(NULL);
	//((struct zWMcursor *)cursor->wm_cursor)->curs = (void *)LoadCursorA(NULL, IDC_ARROW);
	((struct zWMcursor *)cursor->wm_cursor)->curs = (void *)LoadCursor(NULL, IDC_ARROW);
	SDL_SetCursor(cursor);

	icon = LoadIcon(handle, (char *)101);
	SDL_GetWMInfo(&wminfo);
	hwnd = wminfo.window;
	SetClassLong(hwnd, GCL_HICON, (LONG)icon);

	SDL_putenv("SDL_VIDEO_WINDOW_POS=center");
	SDL_putenv("SDL_VIDEO_CENTERED=center");
}

void done_win32()
{
	DestroyIcon(icon);
}
#endif


namespace lime
{

static int sgDesktopWidth = 0;
static int sgDesktopHeight = 0;

static bool sgInitCalled = false;
static bool sgJoystickEnabled = false;
static int  sgShaderFlags = 0;
static bool sgIsOGL2 = false;

enum { NO_TOUCH = -1 };

//To guard against multiple calls
int initSDL () {
	
	if (sgInitCalled)
		return 0;
	
	sgInitCalled = true;
	
	#ifdef WEBOS
	   if (PDL_GetPDKVersion () >= 100)
		  PDL_Init(0);
	#endif
	
	int err = SDL_Init (SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER);
	
	#if HX_WINDOWS
		init_win32();
	#endif
	
	if (err == 0 && SDL_InitSubSystem (SDL_INIT_JOYSTICK) == 0) {
		
		sgJoystickEnabled = true;
		
	}
	
	#ifdef BLACKBERRY
	if (err == 0) {
		
		SDL_EventState(SDL_SYSWMEVENT, SDL_ENABLE);
		
	}
	#endif
	
	return err;
	
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

   int Width() const  { return mSurf->w; }
   int Height() const  { return mSurf->h; }
   PixelFormat Format()  const
   {
      #ifdef EMSCRIPTEN
      uint8 swap = 0;
      #else
      uint8 swap = mSurf->format->Bshift; // is 0 on argb
      #endif
      if (mSurf->flags & SDL_SRCALPHA)
         return swap ? pfARGBSwap : pfARGB;
      return swap ? pfXRGBSwap : pfXRGB;
   }
   AlphaMode GetAlphaMode() const { return amStraight; }
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

SDL_Surface *SurfaceToSDL(Surface *inSurface)
{
   int swap =  (gC0IsRed!=(bool)(inSurface->Format()&pfSwapRB)) ? 0xff00ff : 0;
   return SDL_CreateRGBSurfaceFrom((void *)inSurface->Row(0),
             inSurface->Width(), inSurface->Height(),
             32, inSurface->Width()*4,
             0x00ff0000^swap, 0x0000ff00,
             0x000000ff^swap, 0xff000000 );
}


#ifdef SDL_IMAGE
Surface *Surface::Load(const OSChar *inFilename)
{
   #ifdef HX_WINDOWS
   char *filename = new char [wcslen(inFilename) + 1];
   wcstombs(filename, inFilename, wcslen(inFilename));
   SDL_Surface *img = IMG_Load(filename);
   #else
   SDL_Surface *img = IMG_Load(inFilename);
   #endif
   
   if (img != NULL)
   {
	  Surface *result = new SDLSurf(img, true);
      result->IncRef();
      return result;
   }
   
   return 0;
}

Surface *Surface::LoadFromBytes(const uint8 *inBytes,int inLen)
{
   return 0;
}

bool Surface::Encode( ByteArray *outBytes,bool inPNG,double inQuality)
{
   return 0;
}
#endif


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
   SDLStage(SDL_Surface *inSurface,uint32 inFlags,bool inIsOpenGL,
       int inWidth, int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;

      mIsOpenGL = inIsOpenGL;
      mSDLSurface = inSurface;
      mFlags = inFlags;
      mShowCursor = true;
      mLockCursor = false;
      mCurrentCursor = curPointer;      

      mIsFullscreen =  (mFlags & SDL_FULLSCREEN);
      if (mIsFullscreen)
         displayState = sdsFullscreenInteractive;

      if (mIsOpenGL)
      {
         mOpenGLContext = HardwareContext::CreateOpenGL(0, 0, sgIsOGL2);
         mOpenGLContext->IncRef();
         mOpenGLContext->SetWindowSize(inSurface->w, inSurface->h);
         mPrimarySurface = new HardwareSurface(mOpenGLContext);
      }
      else
      {
         mOpenGLContext = 0;
         mPrimarySurface = new SDLSurf(inSurface,inIsOpenGL);
      }
      mPrimarySurface->IncRef();
	  
	  #if defined(WEBOS) || defined(BLACKBERRY)
	  mMultiTouch = true;
	  #else
	  mMultiTouch = false;
	  #endif
	  mSingleTouchID = NO_TOUCH;
      mDX = 0;
      mDY = 0;

      // Click detection
      mDownX = 0;
      mDownY = 0;
   }

   ~SDLStage()
   {
      if (!mIsOpenGL)
         SDL_FreeSurface(mSDLSurface);
      else
         mOpenGLContext->DecRef();
      mPrimarySurface->DecRef();
   }

   void Resize(int inWidth, int inHeight, bool resizeWindow = false)
   {
      #ifdef HX_WINDOWS
      if (mIsOpenGL && !resizeWindow)
      {
         // Little hack to help windows
         mSDLSurface->w = inWidth;
         mSDLSurface->h = inHeight;
         mOpenGLContext->SetWindowSize(inWidth,inHeight);
      }
      else
      #endif
      {
         // Calling this recreates the gl context and we loose all our textures and
         // display lists. So Work around it.
         gTextureContextVersion++;
         
         if (mIsOpenGL)
         {
            Event contextLost(etRenderContextLost);
            ProcessEvent(contextLost);
         }
 
         mSDLSurface = SDL_SetVideoMode(inWidth, inHeight, 32, mFlags);
  
         if (mIsOpenGL)
         {
            #ifdef RASPBERRYPI
            SDL_SysWMinfo sysInfo;
            SDL_VERSION(&sysInfo.version);
            if(SDL_GetWMInfo(&sysInfo)>0)
            {
               void *window = (void *)(size_t)sysInfo.info.x11.window;
               limeEGLResize(window, inWidth, inHeight);
            }
            #endif
            
            //lime_resize_id ++;
            mOpenGLContext->DecRef();
            mOpenGLContext = HardwareContext::CreateOpenGL(0, 0, sgIsOGL2);
            mOpenGLContext->SetWindowSize(inWidth, inHeight);
            mOpenGLContext->IncRef();
            mPrimarySurface->DecRef();
            mPrimarySurface = new HardwareSurface(mOpenGLContext);
            
            Event contextRestored(etRenderContextRestored);
            ProcessEvent(contextRestored);
         }
         else
         {
            mPrimarySurface->DecRef();
            mPrimarySurface = new SDLSurf(mSDLSurface,mIsOpenGL);
         }
         mPrimarySurface->IncRef();
      }
   }
   
   void ResizeWindow(int inWidth, int inHeight)
   {
      Resize(inWidth, inHeight, true);
      Event resize(etResize, mSDLSurface->w, mSDLSurface->h);
      ProcessEvent(resize);
   }

   void SetFullscreen(bool inFullscreen)
   {
      #if RASPBERRYPI
      if (mIsOpenGL)
         return;
      #endif
      if (inFullscreen != mIsFullscreen)
      {
         mIsFullscreen = inFullscreen;
         //printf("SetFullscreen %d\n",inFullscreen);

         // Calling this recreates the gl context and we loose all our textures and
         // display lists. So Work around it.
         gTextureContextVersion++;
         
         if (mIsOpenGL)
         {
            Event contextLost(etRenderContextLost);
            ProcessEvent(contextLost);
         }

         int w = mIsFullscreen ? sgDesktopWidth : mWidth;
         int h = mIsFullscreen ? sgDesktopHeight : mHeight;
         if (mIsFullscreen)
            mFlags |= SDL_FULLSCREEN;
         else
            mFlags &= ~SDL_FULLSCREEN;

         //printf("Set %dx%d %d\n", w,h,mFlags & SDL_FULLSCREEN);
         mSDLSurface = SDL_SetVideoMode(w, h, 32, mFlags);
         if (!mSDLSurface && (mFlags & SDL_FULLSCREEN) )
         {
            // printf("Failed to set fullscreen, returning to windowed....\n");
            mSDLSurface = SDL_SetVideoMode(w, h, 32, (mFlags & ~SDL_FULLSCREEN) );
         }


         w = mSDLSurface->w;
         h = mSDLSurface->h;
         if (mIsOpenGL)
         {
            //lime_resize_id ++;
            mOpenGLContext->DecRef();
            mOpenGLContext = HardwareContext::CreateOpenGL(0, 0, sgIsOGL2);
            mOpenGLContext->SetWindowSize(w, h);
            mOpenGLContext->IncRef();
            mPrimarySurface->DecRef();
            mPrimarySurface = new HardwareSurface(mOpenGLContext);
            
            Event contextRestored(etRenderContextRestored);
            ProcessEvent(contextRestored);
         }
         else
         {
            mPrimarySurface->DecRef();
            mPrimarySurface = new SDLSurf(mSDLSurface,mIsOpenGL);
         }
         mPrimarySurface->IncRef();


         Event resize(etResize,w,h);
         ProcessEvent(resize);
      }
   }



   bool isOpenGL() const { return mOpenGLContext; }

   void ProcessEvent(Event &inEvent)
   {
	   
	   #ifdef HX_MACOS
	   
	   if (inEvent.type == etKeyUp && (inEvent.flags & efCommandDown))
	   {
		   switch (inEvent.code)
		   {
			   case SDLK_q:
			   case SDLK_w: 
				   inEvent.type = etQuit;
				   break;
			   case SDLK_m:
				   SDL_WM_IconifyWindow();
				   return;
		   }
	   }
	   
	   #endif
	   
      #if defined(HX_WINDOWS) || defined(HX_LINUX)
      
      if (inEvent.type == etKeyUp && (inEvent.flags & efAltDown) && inEvent.value == keyF4)
      {
          inEvent.type = etQuit;
      }
      
      #endif
	   
	  #if defined(WEBOS) || defined(BLACKBERRY)
	   
	   if (inEvent.type == etMouseMove || inEvent.type == etMouseDown || inEvent.type == etMouseUp) {
		   
		   if (mSingleTouchID == NO_TOUCH || inEvent.value == mSingleTouchID || !mMultiTouch)
			inEvent.flags |= efPrimaryTouch;
			
			if (mMultiTouch) {
				
				switch(inEvent.type)
               {
                  case  etMouseDown: inEvent.type = etTouchBegin; break;
				  case  etMouseUp: inEvent.type = etTouchEnd; break;
				  case  etMouseMove: inEvent.type = etTouchMove; break;
               }
			   
			   if (inEvent.type == etTouchBegin) {
					
					mDownX = inEvent.x;
					mDownY = inEvent.y;
					
				}
				
				if (inEvent.type == etTouchEnd) {
					
					if (mSingleTouchID==inEvent.value)
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
         limeEGLSwapBuffers();
         #else
         SDL_GL_SwapBuffers();
         #endif
      }
      else
      {
         SDL_Flip( mSDLSurface );
      }
   }
   void GetMouse()
   {
   }

   void SetCursor(Cursor inCursor)
   {
	  #if defined(WEBOS) || defined(BLACKBERRY) || defined(EMSCRIPTEN)
	  SDL_ShowCursor(false);
	  return;
	  #endif
	  
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
         SetCursor( mCurrentCursor );
      }
   }

   void ConstrainCursorToWindowFrame(bool inLock) {
      if (inLock != mLockCursor) {
         mLockCursor = inLock;
         SDL_WM_GrabInput( inLock ? SDL_GRAB_ON : SDL_GRAB_OFF );
      }
   }
   
      //Note that this fires a mouse event, see the SDL_WarpMouse docs
   void SetCursorPositionInWindow(int inX, int inY) {
      SDL_WarpMouse( inX, inY );
   }
   
   void EnablePopupKeyboard (bool enabled) {
      
      #ifdef WEBOS
      
      if (PDL_GetPDKVersion () >= 300) {
         
         if (enabled) {
            
            PDL_SetKeyboardState (PDL_TRUE);
            
         } else {
            
            PDL_SetKeyboardState (PDL_FALSE);
            
         }
      	
      }
      
      #endif
	  
	  #ifdef BLACKBERRY
      
      if (enabled) {
         
         virtualkeyboard_show();
         
      } else {
         
         virtualkeyboard_hide();
         
      }
	  
      #endif
      
   }
   
   
   bool getMultitouchSupported() { 
	   #if defined(WEBOS) || defined(BLACKBERRY)
	   return true;
	   #else
	   return false;
	   #endif
   }
   void setMultitouchActive(bool inActive) { mMultiTouch = inActive; }
   bool getMultitouchActive() {
	   #if defined(WEBOS) || defined(BLACKBERRY)
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

   Surface *GetPrimarySurface()
   {
      return mPrimarySurface;
   }

   HardwareContext *mOpenGLContext;
   SDL_Surface *mSDLSurface;
   Surface     *mPrimarySurface;
   double       mFrameRate;
   bool         mIsOpenGL;
   Cursor       mCurrentCursor;
   bool         mShowCursor;
   bool         mLockCursor;
   bool         mIsFullscreen;
   unsigned int mFlags;
   int          mWidth;
   int          mHeight;
};


class SDLFrame : public Frame
{
public:
   SDLFrame(SDL_Surface *inSurface, uint32 inFlags, bool inIsOpenGL,int inW,int inH)
   {
      mFlags = inFlags;
      mIsOpenGL = inIsOpenGL;
      mStage = new SDLStage(inSurface,mFlags,inIsOpenGL,inW,inH);
      mStage->IncRef();
      // SetTimer(mHandle,timerFrame, 10,0);
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
      mStage->Resize(inWidth,inHeight);
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
   bool   mIsOpenGL;
   uint32 mFlags;
   
   double mAccX;
   double mAccY;
   double mAccZ;
};


// --- When using the simple window class -----------------------------------------------

extern "C" void MacBoot( /*void (*)()*/ );


SDLFrame *sgSDLFrame = 0;
#ifndef EMSCRIPTEN
SDL_Joystick *sgJoystick = 0;
#endif


void AddModStates(int &ioFlags,int inState = -1)
{
   int state = inState==-1 ? SDL_GetModState() : inState;
   if (state & KMOD_SHIFT) ioFlags |= efShiftDown;
   if (state & KMOD_CTRL) ioFlags |= efCtrlDown;
   if (state & KMOD_ALT) ioFlags |= efAltDown;
   if (state & KMOD_META) ioFlags |= efCommandDown;
	
 
	int m = SDL_GetMouseState(0,0);
	if ( m & SDL_BUTTON(1) ) ioFlags |= efLeftDown;
	if ( m & SDL_BUTTON(2) ) ioFlags |= efMiddleDown;
	if ( m & SDL_BUTTON(3) ) ioFlags |= efRightDown;
		

	ioFlags |= efPrimaryTouch;
   ioFlags |= efNoNativeClick;
}

#define SDL_TRANS(x) case SDLK_##x: return key##x;

int SDLKeyToFlash(int inKey,bool &outRight)
{
   outRight = (inKey==SDLK_RSHIFT || inKey==SDLK_RCTRL ||
               inKey==SDLK_RALT || inKey==SDLK_RMETA || inKey==SDLK_RSUPER);
   if (inKey>=keyA && inKey<=keyZ)
      return inKey;
   if (inKey>=SDLK_0 && inKey<=SDLK_9)
      return inKey - SDLK_0 + keyNUMBER_0;
   if (inKey>=SDLK_KP0 && inKey<=SDLK_KP9)
      return inKey - SDLK_KP0 + keyNUMPAD_0;

   if (inKey>=SDLK_F1 && inKey<=SDLK_F15)
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
      case SDLK_LMETA:
      case SDLK_RMETA:
         return keyCOMMAND;

      case SDLK_CAPSLOCK: return keyCAPS_LOCK;
      case SDLK_PAGEDOWN: return keyPAGE_DOWN;
      case SDLK_PAGEUP: return keyPAGE_UP;
      case SDLK_EQUALS: return keyEQUAL;
      case SDLK_RETURN:
      case SDLK_KP_ENTER:
         return keyENTER;

      SDL_TRANS(BACKQUOTE)
      SDL_TRANS(BACKSLASH)
      SDL_TRANS(BACKSPACE)
      SDL_TRANS(COMMA)
      SDL_TRANS(DELETE)
      SDL_TRANS(DOWN)
      SDL_TRANS(END)
      SDL_TRANS(ESCAPE)
      SDL_TRANS(HOME)
      SDL_TRANS(INSERT)
      SDL_TRANS(LEFT)
      SDL_TRANS(LEFTBRACKET)
      SDL_TRANS(MINUS)
      SDL_TRANS(PERIOD)
      SDL_TRANS(QUOTE)
      SDL_TRANS(RIGHT)
      SDL_TRANS(RIGHTBRACKET)
      SDL_TRANS(SEMICOLON)
      SDL_TRANS(SLASH)
      SDL_TRANS(SPACE)
      SDL_TRANS(TAB)
      SDL_TRANS(UP)
   }

   return inKey;
}

std::map<int,wchar_t> sLastUnicode;



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
	   case SDL_ACTIVEEVENT:
      {
         if (inEvent.active.state & SDL_APPINPUTFOCUS)
         {
            Event activate( inEvent.active.gain ? etGotInputFocus : etLostInputFocus );
            sgSDLFrame->ProcessEvent(activate);
         }
	
         if (inEvent.active.state & SDL_APPACTIVE)
         {
            Event activate( inEvent.active.gain ? etActivate : etDeactivate );
            sgSDLFrame->ProcessEvent(activate);
         }
		   break;
	   }
      case SDL_MOUSEMOTION:
      {
         Event mouse(etMouseMove,inEvent.motion.x,inEvent.motion.y);
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
         Event mouse(etMouseDown,inEvent.button.x,inEvent.button.y,inEvent.button.button-1);
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
         Event mouse(etMouseUp,inEvent.button.x,inEvent.button.y,inEvent.button.button-1);
		 #if defined(WEBOS) || defined(BLACKBERRY)
		 mouse.value = inEvent.motion.which;
		 #else
		 AddModStates(mouse.flags);
		 #endif
         sgSDLFrame->ProcessEvent(mouse);
         break;
      }

      case SDL_KEYDOWN:
      case SDL_KEYUP:
      {
         Event key(inEvent.type==SDL_KEYDOWN ? etKeyDown : etKeyUp );
         bool right;
         key.value = SDLKeyToFlash(inEvent.key.keysym.sym,right);
         if (inEvent.type==SDL_KEYDOWN)
         {
            key.code = key.value==keyBACKSPACE ? keyBACKSPACE : inEvent.key.keysym.unicode;
            sLastUnicode[inEvent.key.keysym.scancode] = key.code;
         }
         else
            // SDL does not provide unicode on key up, so remember it,
            //  keyed by scancode
            key.code = sLastUnicode[inEvent.key.keysym.scancode];

         AddModStates(key.flags,inEvent.key.keysym.mod);
         if (right)
            key.flags |= efLocationRight;
         sgSDLFrame->ProcessEvent(key);
         break;
      }

	  case SDL_VIDEOEXPOSE:
	  {
			Event poll(etPoll);
			sgSDLFrame->ProcessEvent(poll);
         break;
	  }
      case SDL_VIDEORESIZE:
      {
         Event resize(etResize,inEvent.resize.w,inEvent.resize.h);
         sgSDLFrame->Resize(inEvent.resize.w,inEvent.resize.h);
         sgSDLFrame->ProcessEvent(resize);
         break;
      }
	  
	  case SDL_JOYAXISMOTION:
	  {
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
         sgSDLFrame->ProcessEvent(joystick);
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
	  
	  #ifdef BLACKBERRY
	  case SDL_SYSWMEVENT:
	  {
         Event syswm(etSysWM);
		 syswm.value = (int)inEvent.syswm.msg->event;
		 sgSDLFrame->ProcessEvent(syswm);
	  }
	  #endif
	  
   }
}


#ifdef EMSCRIPTEN
void loop () {
	
	SDL_Event event;
	while (SDL_PollEvent(&event)) {
		ProcessEvent (event);
	   // if (sgDead) break;
		event.type = -1;
	 }
	 
	 Event poll(etPoll);
	 sgSDLFrame->ProcessEvent(poll);
	
	
}
#endif





void CreateMainFrame(FrameCreationCallback inOnFrame,int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, Surface *inIcon )
{

#ifdef HX_MACOS
   MacBoot();
#endif
#ifdef WEBOS
   openlog (gPackage.c_str(), 0, LOG_USER);
#endif
#ifdef HX_WINDOWS
	//ShowWindow (GetConsoleWindow (), SW_MINIMIZE);
#endif
	
   unsigned int sdl_flags = 0;
   bool fullscreen = (inFlags & wfFullScreen) != 0;
   bool opengl = (inFlags & wfHardware) != 0;
   bool resizable = (inFlags & wfResizable) != 0;
   bool borderless = (inFlags & wfBorderless) != 0;
   sgShaderFlags = (inFlags & (wfAllowShaders|wfRequireShaders) );

   Rect r(100,100,inWidth,inHeight);

   int err = initSDL ();// SDL_Init( init_flags );
   
   if ( err == -1 )
   {
      fprintf(stderr,"Could not initialize SDL : %s\n", SDL_GetError());
      inOnFrame(0);
      // SDL_GetError()
      return;
   }
   
   #ifdef BLACKBERRY
   virtualkeyboard_request_events(0);
   #endif

   SDL_EnableUNICODE(1);
   SDL_EnableKeyRepeat(500,30);

   gSDLIsInit = true;

   #ifdef LIME_MIXER
   
   #ifdef WEBOS
   int chunksize = 256;
   if (PDL_GetPDKVersion () == 100 || PDL_GetHardwareID () < 300)
   {
      // use a larger chunksize for older devices
      chunksize = 1024;
   }
   #elif BLACKBERRY
   int chunksize = 512;
   #elif HX_WINDOWS
   int chunksize = 2048;
   #else
   int chunksize = 4096;
   #endif
   
   int frequency = 44100;
   //int frequency = MIX_DEFAULT_FREQUENCY //22050
   
   // The default frequency would have less latency, but is incompatible with the average MP3 file
   
   if ( Mix_OpenAudio(frequency, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS, chunksize)!= 0 )
   {
      fprintf(stderr,"Could not open sound: %s\n", Mix_GetError());
      gSDLIsInit = false;
   }
   #endif


   const SDL_VideoInfo *info  = SDL_GetVideoInfo();
   sgDesktopWidth = info->current_w;
   sgDesktopHeight = info->current_h;


   #ifdef RASPBERRYPI
   sdl_flags = SDL_SWSURFACE;
   if (opengl)
      fullscreen = true;
   #else
   sdl_flags = SDL_HWSURFACE;
   #endif

   if ( resizable )
      sdl_flags |= SDL_RESIZABLE;
	
   if ( borderless )
      sdl_flags |= SDL_NOFRAME;

   if ( fullscreen )
   {
      sdl_flags |= SDL_FULLSCREEN;
   }


   int use_w = fullscreen ? 0 : inWidth;
   int use_h = fullscreen ? 0 : inHeight;

#if defined(IPHONE) || defined(BLACKBERRY) || defined(EMSCRIPTEN)
   sdl_flags |= SDL_NOFRAME;
#else
   if (inIcon)
   {
      SDL_Surface *sdl = SurfaceToSDL(inIcon);
      SDL_WM_SetIcon( sdl, NULL );
   }
#endif


   #if defined (HX_WINDOWS) || defined (HX_LINUX)
   SDL_WM_SetCaption( inTitle, 0 );
   #endif

   SDL_Surface* screen = 0;
   bool is_opengl = false;
   sgIsOGL2 = false;

   #ifdef RASPBERRYPI
   bool limeEgl = true;
   #else
   bool limeEgl = false;
   #endif

   if (opengl && !limeEgl)
   {
      int  aa_tries = (inFlags & wfHW_AA) ? ( (inFlags & wfHW_AA_HIRES) ? 2 : 1 ) : 0;
   
      //int bpp = info->vfmt->BitsPerPixel;
      int startingPass = 0;

      // Try for 24:8  depth:stencil
      if (inFlags & wfStencilBuffer)
         startingPass = 1;
 
	   #if defined (WEBOS) || defined (BLACKBERRY) || defined(EMSCRIPTEN)
      // Start at 16 bits...
	   startingPass = 2;
	   #endif

      // No need to loop over depth
      if (!(inFlags & wfDepthBuffer))
         startingPass = 2;

      int oglLevelPasses = 1;

      #if !defined(LIME_FORCE_GLES1) && (defined(WEBOS) || defined(BLACKBERRY) || defined(EMSCRIPTEN))
      // Try 2 then 1 ?
      if ( (inFlags & wfAllowShaders) && !(inFlags & wfRequireShaders) )
         oglLevelPasses = 2;
      #endif

      // Find config...

      for(int oglPass = 0; oglPass< oglLevelPasses && !is_opengl; oglPass++)
      {
         #ifdef LIME_FORCE_GLES1
         int level = 1;
         #else
         int level = (inFlags & wfRequireShaders) ? 2 : (inFlags & wfAllowShaders) ? 2-oglPass : 1;
         #endif
        
   
         for(int depthPass=startingPass;depthPass<3 && !is_opengl;depthPass++)
         {
            /* Initialize the display */
            for(int aa_pass = aa_tries; aa_pass>=0 && !is_opengl; --aa_pass)
            {
               SDL_GL_SetAttribute(SDL_GL_RED_SIZE,  8 );
               SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE,8 );
               SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8 );
   
               #if defined(WEBOS) || defined(BLACKBERRY) || defined(EMSCRIPTEN)
               SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, level);
               #endif
               // try 32 24 or 16 bit depth...
               if (inFlags & wfDepthBuffer)
                  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE,  32 - depthPass*8 );
   
               if (inFlags & wfStencilBuffer)
                  SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8 );
   
               SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
   			
               if (aa_tries > 0)
               {
                  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, aa_pass>0);
                  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES,  1<<aa_pass );
               }
               
               #ifndef EMSCRIPTEN
               if ( inFlags & wfVSync )
               {
                  SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, 1);
               }
               #endif
   
               sdl_flags |= SDL_OPENGL;
   			
               if (!(screen = SDL_SetVideoMode( use_w, use_h, 32, sdl_flags)))
               {
                  if (depthPass==2 && aa_pass==0 && oglPass==oglLevelPasses-1)
                  {
                     sdl_flags &= ~SDL_OPENGL;
                     fprintf(stderr, "Couldn't set OpenGL mode32: %s\n", SDL_GetError());
                  }
               }
               else
               {
                  is_opengl = true;
                  #if defined(WEBOS) || defined(BLACKBERRY) || defined(EMSCRIPTEN)
                  sgIsOGL2 = level==2;
                  #else
                  // TODO: check extensions support
                  sgIsOGL2 = (inFlags & (wfAllowShaders | wfRequireShaders) );
                  #endif
                  break;
               }
            }
         }
      }
   }
 
   if (!screen)
   {
      if (!opengl || !limeEgl)
         sdl_flags |= SDL_DOUBLEBUF;

      screen = SDL_SetVideoMode( use_w, use_h, 32, sdl_flags );
      if (!screen)
      {
         fprintf(stderr, "Couldn't set video mode: %s\n", SDL_GetError());
         inOnFrame(0);
         gSDLIsInit = false;
         return;
      }
   }

   #ifdef RASPBERRYPI
   if (opengl)
   {
      sgIsOGL2 = (inFlags & (wfAllowShaders | wfRequireShaders) );
         
      use_w = screen->w;
      use_h = screen->h;
      bool ok = limeEGLCreate( 0, use_w, use_h,
                        sgIsOGL2,
                        (inFlags & wfDepthBuffer) ? 16 : 0,
                        (inFlags & wfStencilBuffer) ? 8 : 0,
                        0 );
      if (ok)
         is_opengl = true;
   }
   #endif




   HintColourOrder( is_opengl || screen->format->Rmask==0xff );

   #ifdef WEBOS
   PDL_ScreenTimeoutEnable(PDL_TRUE);
   #endif
   
   #ifndef EMSCRIPTEN
   int numJoysticks = SDL_NumJoysticks();
   
   if (sgJoystickEnabled && numJoysticks > 0) {
	   
	   for (int i = 0; i < numJoysticks; i++) {
		   
		   sgJoystick = SDL_JoystickOpen(i);
		   
	   }
	   
	   #ifndef WEBOS
	   SDL_JoystickEventState(SDL_TRUE);
	   #endif
	   
   }
   #endif

   sgSDLFrame = new SDLFrame( screen, sdl_flags, is_opengl, inWidth, inHeight );

   inOnFrame(sgSDLFrame);
   
   #ifdef EMSCRIPTEN
   emscripten_set_main_loop (loop, 0, true);
   #else
   StartAnimation();
   #endif
}

bool sgDead = false;

void SetIcon( const char *path ) {
   #ifndef EMSCRIPTEN
   initSDL();
   
   SDL_Surface *surf = SDL_LoadBMP(path);
   
   if ( surf != NULL )
      SDL_WM_SetIcon( surf, NULL);
   #endif
}

QuickVec<int>*  CapabilitiesGetScreenResolutions() {
	
	
	initSDL ();
	
	QuickVec<int> *out = new QuickVec<int>();
	
	// Get available fullscreen/hardware modes
	SDL_Rect** modes = SDL_ListModes(NULL, SDL_FULLSCREEN|SDL_HWSURFACE);
	
	// Check if there are any modes available
	if (modes == (SDL_Rect**)0) {
	    return out;
	}
	
	// Check if our resolution is unrestricted
	if (modes == (SDL_Rect**)-1) {
	    return out;
	}
	else{
	    // Print valid modes 
	    
	    for ( int i=0; modes[i]; ++i) {
	       out->push_back( modes[ i ]->w );
	       out->push_back( modes[ i ]->h );
	    }
	       
	}
		
	
	return out;
	
	
}

#ifndef BLACKBERRY

double CapabilitiesGetScreenResolutionX() {
	
	initSDL ();
	
	return sgDesktopWidth;
	
	/*SDL_Rect** modes = SDL_ListModes(NULL, SDL_FULLSCREEN);
	
	if (modes == (SDL_Rect**)0 || modes == (SDL_Rect**)-1) {
		
		const SDL_VideoInfo* videoInfo = SDL_GetVideoInfo();
		return videoInfo->current_w;
		
	}
	
	return modes[0]->w;*/
	
}

double CapabilitiesGetScreenResolutionY() {
	
	initSDL ();
	
	return sgDesktopHeight;
	
	/*SDL_Rect** modes = SDL_ListModes(NULL, SDL_FULLSCREEN);
	
	if (modes == (SDL_Rect**)0 || modes == (SDL_Rect**)-1) {
		
		const SDL_VideoInfo* videoInfo = SDL_GetVideoInfo();
		return videoInfo->current_h;
		
	}
	
	return modes[0]->h;*/
	
}

#endif

void PauseAnimation() {}
void ResumeAnimation() {}

void StopAnimation()
{
   #ifdef LIME_MIXER
   Mix_CloseAudio();
   #endif
   #ifdef WEBOS
   closelog();
   PDL_Quit();
   #endif
   sgDead = true;
}

static SDL_TimerID  sgTimerID = 0;
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






#ifdef WEBOS

bool GetAcceleration(double &outX, double &outY, double &outZ)
{
	outX = SDL_JoystickGetAxis(sgJoystick, 0) / 32768.0;
	outY = SDL_JoystickGetAxis(sgJoystick, 1) / 32768.0;
	outZ = SDL_JoystickGetAxis(sgJoystick, 2) / 32768.0;
	return true;
}

#endif

#ifndef SDL_NOEVENT
#define SDL_NOEVENT -1;
#endif


void StartAnimation()
{
   SDL_Event event;
   #ifndef EMSCRIPTEN
   bool firstTime = true;
   while(!sgDead)
   {
      event.type=SDL_NOEVENT;
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
   #endif
		 while (SDL_PollEvent(&event)) {
            ProcessEvent (event);
            if (sgDead) break;
            event.type = -1;
         }
         
         Event poll(etPoll);
         sgSDLFrame->ProcessEvent(poll);
   #ifndef EMSCRIPTEN
         if (sgDead) break;
         
         double next = sgSDLFrame->GetStage()->GetNextWake() - GetTimeStamp();
		 if (next > 0.001) {
			 int snooze = next*1000.0;
			 sgTimerActive = true;
			 sgTimerID = SDL_AddTimer(snooze, OnTimer, 0);
		 } else {
			 OnTimer(0, 0);
		 }
      }
   }
   
   Event deactivate( etDeactivate );
   sgSDLFrame->ProcessEvent(deactivate);
   
   Event kill(etDestroyHandler);
   sgSDLFrame->ProcessEvent(kill);
   SDL_Quit();
   #endif
   
   #if HX_WINDOWS
   done_win32();
   #endif
}


/*
Frame *CreateTopLevelWindow(int inWidth,int inHeight,unsigned int inFlags, wchar_t *inTitle, wchar_t *inIcon )
{
   return 0;
}

*/

} // end namespace lime


         #if 0
         if (event.type == SDL_JOYAXISMOTION)
         {
       alloc_field( evt, val_id( "type" ), alloc_int( et_jaxis ) );
       alloc_field( evt, val_id( "axis" ), alloc_int( event.jaxis.axis ) );
       alloc_field( evt, val_id( "value" ), alloc_int( event.jaxis.value ) );
       alloc_field( evt, val_id( "which" ), alloc_int( event.jaxis.which ) );
       return evt;
         }
         if (event.type == SDL_JOYBUTTONDOWN || event.type == SDL_JOYBUTTONUP)
         {
       alloc_field( evt, val_id( "type" ), alloc_int( et_jbutton ) );
       alloc_field( evt, val_id( "button" ), alloc_int( event.jbutton.button ) );
       alloc_field( evt, val_id( "state" ), alloc_int( event.jbutton.state ) );
       alloc_field( evt, val_id( "which" ), alloc_int( event.jbutton.which ) );
       return evt;
         }
         if (event.type == SDL_JOYHATMOTION)
         {
       alloc_field( evt, val_id( "type" ), alloc_int( et_jhat ) );
       alloc_field( evt, val_id( "button" ), alloc_int( event.jhat.hat ) );
       alloc_field( evt, val_id( "value" ), alloc_int( event.jhat.value ) );
       alloc_field( evt, val_id( "which" ), alloc_int( event.jhat.which ) );
       return evt;
         }
         if (event.type == SDL_JOYBALLMOTION)
         {
       alloc_field( evt, val_id( "type" ), alloc_int( et_jball ) );
       alloc_field( evt, val_id( "ball" ), alloc_int( event.jball.ball ) );
       alloc_field( evt, val_id( "xrel" ), alloc_int( event.jball.xrel ) );
       alloc_field( evt, val_id( "yrel" ), alloc_int( event.jball.yrel ) );
       alloc_field( evt, val_id( "which" ), alloc_int( event.jball.which ) );
       return evt;
         }

         if (event.type==SDL_VIDEORESIZE)
         {
       alloc_field( evt, val_id( "type" ), alloc_int( et_resize ) );
       alloc_field( evt, val_id( "width" ), alloc_int( event.resize.w ) );
       alloc_field( evt, val_id( "height" ), alloc_int( event.resize.h ) );
       return evt;
         }
         #endif


#if 0
/*
 */



value lime_get_mouse_position()
{
   int x,y;

   #ifdef SDL13
   SDL_GetMouseState(0,&x,&y);
   #else
   SDL_GetMouseState(&x,&y);
   #endif

   value pos = alloc_empty_object();
   alloc_field( pos, val_id( "x" ), alloc_int( x ) );
   alloc_field( pos, val_id( "y" ), alloc_int( y ) );
   return pos;
}


#endif
