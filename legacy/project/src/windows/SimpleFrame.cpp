#include <Graphics.h>
#include <Display.h>
#include <Surface.h>
#include <windows.h>
#include <KeyCodes.h>
#include <map>

#include <gl/GL.h>

namespace nme
{

// --- DIB   ------------------------------------------------------------------------

typedef std::map<HWND,class WindowsFrame *> FrameMap;
static FrameMap sgFrameMap;

class DIBSurface : public SimpleSurface
{
public:
   DIBSurface(int inW,int inH) : SimpleSurface( (inW+3) & ~3 ,inH,pfXRGB,4)
   {
      memset(&mInfo,0,sizeof(mInfo));
      BITMAPINFOHEADER &h = mInfo.bmiHeader;
      h.biSize = sizeof(BITMAPINFOHEADER);
      h.biWidth = mWidth;
      h.biHeight = -mHeight;
      h.biPlanes = 1;
      h.biBitCount = 32;
      h.biCompression = BI_RGB;

      memset(mBase, 0, mWidth*mHeight*4);
   }

   void RenderTo(HDC inDC)
   {
       SetDIBitsToDevice(inDC,0,0,mWidth,mHeight,
                        0,0, 0,mHeight, mBase, &mInfo, DIB_RGB_COLORS);
   }

   BITMAPINFO mInfo;

private:
   ~DIBSurface() { }
};


// --- Stage ------------------------------------------------------------------------


//typedef std::vector<Stage *> StageList;
Stage *sgStage = 0;

class WindowsStage : public Stage
{
public:
   WindowsStage(HWND inHWND,uint32 inFlags)
   {
      mHWND = inHWND;
      mDC = GetDC(mHWND);
      SetICMMode(mDC,ICM_OFF);
      mFlags = inFlags;
      mBMP = 0;
      mHardwareContext = 0;
      mHardwareSurface = 0;
      mOGLCtx = 0;
      mCursor = curPointer;

      mIsHardware = inFlags & wfHardware;
      HintColourOrder(mIsHardware);

		sgStage = this;

      if (mIsHardware)
      {
         if (!CreateHardware())
            mIsHardware = false;
      }
      if (!mIsHardware)
         CreateBMP();
   }

   void PollNow()
   {
      Event evt(etPoll);
      HandleEvent(evt);
   }

   ~WindowsStage()
   {
      if (mBMP)
         mBMP->DecRef();
      if (mHardwareContext)
         mHardwareContext->DecRef();
      if (mHardwareSurface)
         mHardwareSurface->DecRef();
      if (mOGLCtx)
         wglDeleteContext( mOGLCtx );
   }

   bool CreateHardware()
   {
      PIXELFORMATDESCRIPTOR pfd;
      ZeroMemory( &pfd, sizeof( pfd ) );
      pfd.nSize = sizeof( pfd );
      pfd.nVersion = 1;
      pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL |
                    PFD_DOUBLEBUFFER;
      pfd.iPixelType = PFD_TYPE_RGBA;
      pfd.cColorBits = 24;
      pfd.cDepthBits = 16;
      pfd.iLayerType = PFD_MAIN_PLANE;
      int fmt = ChoosePixelFormat( mDC, &pfd );
      if (!fmt)
         return false;
      if (!SetPixelFormat( mDC, fmt, &pfd ))
         return false;

      mOGLCtx = wglCreateContext( mDC );
      if (!mOGLCtx)
         return false;

      mHardwareContext = HardwareContext::CreateOpenGL(mDC,mOGLCtx);
      mHardwareContext->IncRef();
      mHardwareSurface = new HardwareSurface(mHardwareContext);
      mHardwareSurface->IncRef();
      UpdateHardware();
      return true;
   }

   void ApplyCursor()
   {
      static HCURSOR pointer = LoadCursor(0,IDC_ARROW);
      static HCURSOR text = LoadCursor(0,IDC_IBEAM);
      static HCURSOR hand = LoadCursor(0,IDC_CROSS); // For now
      static HCURSOR none = 0;
      if (none==0)
      {
         unsigned char and_mask[32*32/4];
         unsigned char xor_mask[32*32/4];
         memset(and_mask,255,sizeof(and_mask));
         memset(xor_mask,0,sizeof(and_mask));
         none = CreateCursor(0, 0,0, 32, 32, and_mask, xor_mask );
      }

      switch(mCursor)
      {
         case curNone : ::SetCursor(none); break;
         case curHand : ::SetCursor(hand); break;
			// TODO:
         case curTextSelect0 :
         case curTextSelect90:
         case curTextSelect180:
         case curTextSelect270:
					::SetCursor(text); break;
         default:
            ::SetCursor(pointer);
      }
   }

   void SetCursor(Cursor inCursor)
   {
      mCursor = inCursor;
      ApplyCursor();
   }


   void UpdateHardware()
   {
      WINDOWINFO info;
      info.cbSize = sizeof(WINDOWINFO);

      if (GetWindowInfo(mHWND,&info))
      {
         int w =  info.rcClient.right - info.rcClient.left;
         int h =  info.rcClient.bottom - info.rcClient.top;
         mHardwareContext->SetWindowSize(w,h);
      }
   }

   void CreateBMP()
   {
      if (mBMP)
      {
         mBMP->DecRef();
         mBMP = 0;
      }

      WINDOWINFO info;
      info.cbSize = sizeof(WINDOWINFO);

      if (GetWindowInfo(mHWND,&info))
      {
         int w =  info.rcClient.right - info.rcClient.left;
         int h =  info.rcClient.bottom - info.rcClient.top;
         mBMP = new DIBSurface(w,h);
         mBMP->IncRef();
      }
   }

   bool isOpenGL() const { return mHardwareContext; }

   void Flip()
   {
      if (mHardwareContext)
         mHardwareContext->Flip();
      else if (mBMP)
         mBMP->RenderTo(mDC);
   }
   void GetMouse()
   {
   }

   Surface *GetPrimarySurface()
   {
      if (mHardwareSurface)
         return mHardwareSurface;
      return mBMP;
   }

   void HandleEvent(Event &inEvent)
   {
      switch(inEvent.type)
      {
         case etRedraw:
            Flip();
            break;
         case etResize:
            if (mHardwareContext)
               UpdateHardware();
            else
               CreateBMP();
            break;
      }

      Stage::HandleEvent(inEvent);
   }


   // --- IRenderTarget Interface ------------------------------------------
   int Width()
   {
      WINDOWINFO info;
      info.cbSize = sizeof(WINDOWINFO);

      if (!GetWindowInfo(mHWND,&info))
         return 0;
      return info.rcClient.right - info.rcClient.left;
   }

   int Height()
   {
      WINDOWINFO info;
      info.cbSize = sizeof(WINDOWINFO);

      if (!GetWindowInfo(mHWND,&info))
         return 0;

      return info.rcClient.bottom - info.rcClient.top;
   }


   HWND         mHWND;
   HDC          mDC;
   HGLRC        mOGLCtx;
   uint32       mFlags;
   double       mFrameRate;
   DIBSurface   *mBMP;
   HardwareSurface *mHardwareSurface;
   HardwareContext *mHardwareContext;
   bool         mIsHardware;
   Cursor       mCursor;
};


// --- Frame ------------------------------------------------------------------------

#define VK_TRANS(x) case VK_##x: return key##x;

static HKL gKeyboardLayout = 0;

int WinKeyToFlash(int inKey,bool &outRight,int inChar)
{
   outRight = (inKey==VK_RSHIFT || inKey==VK_RCONTROL || inKey==VK_RMENU ||inKey==VK_RWIN);

   if (inKey>=keyA && inKey<=keyZ)
      return inKey;
   if (inKey>='0' && inKey<='9')
      return inKey;
   if (inKey>=VK_NUMPAD0 && inKey<=VK_NUMPAD9)
      return inKey - VK_NUMPAD0 + keyNUMPAD_0;

   if (inKey>=VK_F1 && inKey<=VK_F15)
      return inKey - VK_F1 + keyF1;


   switch(inKey)
   {
      case VK_RMENU:
      case VK_LMENU:
      case VK_MENU:
         return keyALTERNATE;
      case VK_RSHIFT:
      case VK_LSHIFT:
      case VK_SHIFT:
         return keySHIFT;
      case VK_RCONTROL:
      case VK_LCONTROL:
      case VK_CONTROL:
         return keyCONTROL;
      case VK_LWIN:
      case VK_RWIN:
         return keyCOMMAND;

      case VK_CAPITAL: return keyCAPS_LOCK;
      case VK_NEXT: return keyPAGE_DOWN;
      case VK_PRIOR: return keyPAGE_UP;
      case '=': return keyEQUAL;
      case VK_RETURN:
         return keyENTER;

      case '`' : return keyBACKQUOTE;
      //case '\\' : return keyBACKSLASH;
      case VK_OEM_COMMA : return keyCOMMA;
      case VK_BACK : return keyBACKSPACE;
      case VK_OEM_MINUS : return keyMINUS;
      case VK_OEM_PERIOD : return keyPERIOD;
      VK_TRANS(DELETE)
      VK_TRANS(DOWN)
      VK_TRANS(END)
      VK_TRANS(ESCAPE)
      VK_TRANS(HOME)
      VK_TRANS(INSERT)
      VK_TRANS(LEFT)
      // case '(' : return keyLEFTBRACKET;
      //VK_TRANS(QUOTE)
      VK_TRANS(RIGHT)
      //VK_TRANS(RIGHTBRACKET)
      //VK_TRANS(SEMICOLON)
      //VK_TRANS(SLASH)
      VK_TRANS(SPACE)
      VK_TRANS(TAB)
      VK_TRANS(UP)
   }

   return inChar;

}



class WindowsFrame : public Frame
{
public:
   WindowsFrame(HWND inHandle, uint32 inFlags)
   {
      mFlags = inFlags;
      mHandle = inHandle;
      sgFrameMap[mHandle] = this;
      mOldProc = (WNDPROC)SetWindowLongPtr(mHandle,GWL_WNDPROC,(LONG)StaticCallback);
      mStage = new WindowsStage(inHandle,mFlags);
      ShowWindow(mHandle,true);
   }
   ~WindowsFrame()
   {
      SetWindowLongPtr(mHandle,GWL_WNDPROC,(LONG)mOldProc);
      sgFrameMap.erase(mHandle);
   }

   void WParamToFlags(WPARAM wParam, Event &ioEvent)
   {
      if (wParam & MK_CONTROL) ioEvent.flags |= efCtrlDown;
      if (wParam & MK_LBUTTON) ioEvent.flags |= efLeftDown;
      if (wParam & MK_MBUTTON) ioEvent.flags |= efMiddleDown;
      if (wParam & MK_RBUTTON) ioEvent.flags |= efRightDown;
      if (wParam & MK_SHIFT)   ioEvent.flags |= efShiftDown;
   }

   LRESULT Callback(UINT uMsg, WPARAM wParam, LPARAM lParam)
   {
      switch (uMsg)
      {
         case WM_CLOSE:
            StopAnimation();
            break;
         case WM_PAINT:
            {
            PAINTSTRUCT ps;
            HDC dc;
            BeginPaint(mHandle,&ps);
            Event evt(etRedraw);
            mStage->HandleEvent(evt);
            EndPaint(mHandle,&ps);
            }
            break;
         case WM_SIZE:
            {
            Event evt(etResize, LOWORD(lParam), HIWORD(lParam));

            mStage->HandleEvent(evt);
            }
            break;
         case WM_MOUSEMOVE:
            {
            Event evt(etMouseMove, LOWORD(lParam), HIWORD(lParam));
            WParamToFlags(wParam,evt);
            mStage->HandleEvent(evt);
            }
            break;
         case WM_LBUTTONDOWN:
            {
            Event evt(etMouseDown, LOWORD(lParam), HIWORD(lParam));
            WParamToFlags(wParam,evt);
            mStage->HandleEvent(evt);
            }
            break;
         case WM_LBUTTONUP:
            {
            Event evt(etMouseUp, LOWORD(lParam), HIWORD(lParam));
            WParamToFlags(wParam,evt);
            mStage->HandleEvent(evt);
            // TODO: based on timer/motion?
            Event click(etMouseClick, LOWORD(lParam), HIWORD(lParam));
            mStage->HandleEvent(click);
            }
            break;
         // TODO : Create click event

         case WM_KEYUP:
         case WM_KEYDOWN:
            {
            Event key(uMsg==WM_KEYDOWN ? etKeyDown: etKeyUp);
            if (!gKeyboardLayout)
               gKeyboardLayout = GetKeyboardLayout(0);
            static uint8 key_buffer[256];
            GetKeyboardState(key_buffer);
            if (key_buffer[VK_SHIFT] & 0x80) key.flags|=efShiftDown;
            if (key_buffer[VK_CONTROL] & 0x80) key.flags|=efCtrlDown;
            if (key_buffer[VK_MENU] & 0x80) key.flags|=efAltDown;

            wchar_t codes[4] = {0,0,0,0};
            int converted = ToUnicodeEx( wParam, (lParam>>16)&0xff, key_buffer, codes, 4,
                                0, gKeyboardLayout );
            key.code = converted==1 ?  codes[0] : 0;
            bool right;
            key.value = WinKeyToFlash(wParam,right,key.code);
            if (right)
               key.flags |= efLocationRight;
            mStage->HandleEvent(key);
            break;
            }

         case WM_SETCURSOR:
            mStage->ApplyCursor();
            break;

         case WM_TIMER:
            {
            Event evt(etPoll);
            evt.id = wParam;
            mStage->HandleEvent(evt);
            }
            break;
      }

      return mOldProc(mHandle, uMsg, wParam, lParam);
   }

   static LRESULT CALLBACK StaticCallback( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
   {
      FrameMap::iterator i = sgFrameMap.find(hwnd);
      if (i!=sgFrameMap.end())
         return i->second->Callback(uMsg,wParam,lParam);
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
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


   WindowsStage *mStage;

   uint32 mFlags;
   HWND mHandle;
   WNDPROC mOldProc;
};


// --- When using the simple window class -----------------------------------------------

void CreateMainFrame(FrameCreationCallback inOnCreate,int inWidth,int inHeight,unsigned int inFlags,
      const char *inTitle,Surface *inIcon)
{
   RECT r;
   r.left = 100;
   r.top= 100;
   r.right= 100+inWidth;
   r.bottom= 100+inHeight;

   WNDCLASSEX wc;
   memset(&wc,0,sizeof(wc));
   wc.cbSize = sizeof(wc);
   wc.style = CS_OWNDC | CS_DBLCLKS | CS_HREDRAW | CS_VREDRAW;
   wc.hCursor = LoadCursor(0,IDC_ARROW);
   wc.hbrBackground = 0; //(HBRUSH)GetStockObject(WHITE_BRUSH);
   wc.lpfnWndProc =  DefWindowProc;
   wc.lpszClassName = "NME";

   RegisterClassEx(&wc);

   DWORD ex_style = WS_EX_ACCEPTFILES;
   DWORD style = 0;
   if (inFlags & wfResizable)
      style |= WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_MAXIMIZEBOX;
   if (inFlags & wfBorderless)
      style |= WS_POPUP;
   else
      style |= WS_OVERLAPPEDWINDOW;

   AdjustWindowRect (& r, style, FALSE);

   HWND win = CreateWindowEx(ex_style, "NME", inTitle,
                              style,
                              r.left, r.top, r.right-r.left, r.bottom-r.top,
                              0,
                              0,
                              0,
                              0);

   Frame *frame = new WindowsFrame(win,inFlags);
   SetCursor(LoadCursor(0, IDC_ARROW));
   inOnCreate( frame );

	StartAnimation();
}


bool sgDead = false;

void StopAnimation()
{
   sgDead = true;
}

void StartAnimation()
{
   MSG msg;
   while( !sgDead )
   {
		// Process pending messages first...
      while(!sgDead && PeekMessage(&msg, NULL, 0, 0, PM_NOREMOVE))
      {
			if (GetMessage(&msg, NULL, 0, 0)<=0)
            break;
      	TranslateMessage(&msg);
      	DispatchMessage(&msg);
      }
		sgStage->PollNow();
		// Sleep if we have to...
		double next = sgStage->GetNextWake() - GetTimeStamp();
		if (next > 0.001)
		{
			int snooze = next*1000.0;
			MsgWaitForMultipleObjects(0,0, false, snooze,QS_ALLEVENTS);
		}
   }
}

} // end namespace nme
