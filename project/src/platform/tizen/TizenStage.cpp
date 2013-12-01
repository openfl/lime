#include "platform/tizen/TizenStage.h"
#include "platform/tizen/TizenFrame.h"
#include "renderer/common/HardwareSurface.h"
#include "renderer/opengl/Egl.h"
#include <FBase.h>


namespace lime {
	
	
	TizenStage::TizenStage (int inWidth, int inHeight) {
		
		//AppLog ("Hello from TizenStage");
		
		//mWidth = inWidth;
		//mHeight = inHeight;
		
		//mIsOpenGL = inIsOpenGL;
		//mSDLWindow = inWindow;
		//mSDLRenderer = inRenderer;
		//mWindowFlags = inWindowFlags;
		
		//mShowCursor = true;
		//mCurrentCursor = curPointer;
		
		//mIsFullscreen = (mWindowFlags & SDL_WINDOW_FULLSCREEN || mWindowFlags & SDL_WINDOW_FULLSCREEN_DESKTOP);
		//if (mIsFullscreen)
		//	displayState = sdsFullscreenInteractive;
		
		mOpenGLContext = HardwareContext::CreateOpenGL (0, 0, true);
		mOpenGLContext->IncRef ();
		mOpenGLContext->SetWindowSize (inWidth, inHeight);
		
		mPrimarySurface = new HardwareSurface (mOpenGLContext);
		mPrimarySurface->IncRef ();
		
		//mMultiTouch = true;
		//mSingleTouchID = NO_TOUCH;
		//mDX = 0;
		//mDY = 0;
		//mDownX = 0;
		//mDownY = 0;
		
	}
	
	
	TizenStage::~TizenStage () {
		
		mOpenGLContext->DecRef ();
		mPrimarySurface->DecRef ();
		
	}
	
	
	void TizenStage::Flip () {
		
		//AppLog ("Flip!");
		
		limeEGLSwapBuffers ();
		
	}
	
	
	void TizenStage::GetMouse () {}
	
	
	bool TizenStage::getMultitouchSupported () {
		
		return true;
	}
	
	
	bool TizenStage::getMultitouchActive () {
		
		//return mMultiTouch;
		return true;
		
	}
	
	
	void TizenStage::Resize (const int inWidth, const int inHeight) {
		
		AppLog ("Resize: %d x %d\n", inWidth, inHeight);
		
		/*// Calling this recreates the gl context and we loose all our textures and
		// display lists. So Work around it.
		if (mOpenGLContext) {
			
			gTextureContextVersion++;
			mOpenGLContext->DecRef ();
			
		}
		
		mOpenGLContext = HardwareContext::CreateOpenGL (0, 0, true);
		mOpenGLContext->SetWindowSize (inWidth, inHeight);
		mOpenGLContext->IncRef ();
		
		if (mPrimarySurface) {
			
			mPrimarySurface->DecRef ();
			
		}
		
		mPrimarySurface = new HardwareSurface (mOpenGLContext);
		mPrimarySurface->IncRef ();*/
		
	}
	
	
	void TizenStage::SetCursor (Cursor inCursor) {
		
		switch (inCursor) {
			
			case curNone:
				break;
			case curPointer:
				break;
			case curHand:
				break;
			
		}
		
	}
	
	
	void TizenStage::setMultitouchActive (bool inActive) {
		
		//mMultiTouch = inActive;
		
	}
	
	
	/*#define TIZEN_TRANS(x) case TIZEN_KEY_##x: return key##x;
	
	
	int TizenKeyToFlash(int inKey, bool &outRight) {
		
		outRight = (inKey == GLFW_KEY_RIGHT_SHIFT || inKey == GLFW_KEY_RIGHT_CONTROL ||
					inKey == GLFW_KEY_RIGHT_ALT || inKey == GLFW_KEY_RIGHT_SUPER);
		if (inKey >= keyA && inKey <= keyZ)
		  return inKey;
		if (inKey >= GLFW_KEY_0 && inKey <= GLFW_KEY_9)
		  return inKey - GLFW_KEY_0 + keyNUMBER_0;
		if (inKey >= GLFW_KEY_KP_0 && inKey <= GLFW_KEY_KP_9)
		  return inKey - GLFW_KEY_KP_0 + keyNUMPAD_0;

		if (inKey >= GLFW_KEY_F1 && inKey <= GLFW_KEY_F15)
		  return inKey - GLFW_KEY_F1 + keyF1;

		switch (inKey)
		{
		  case GLFW_KEY_RIGHT_ALT:
		  case GLFW_KEY_LEFT_ALT:
			 return keyALTERNATE;
		  case GLFW_KEY_RIGHT_SHIFT:
		  case GLFW_KEY_LEFT_SHIFT:
			 return keySHIFT;
		  case GLFW_KEY_RIGHT_CONTROL:
		  case GLFW_KEY_LEFT_CONTROL:
			 return keyCONTROL;
		  case GLFW_KEY_RIGHT_SUPER:
		  case GLFW_KEY_LEFT_SUPER:
			 return keyCOMMAND;

		  case GLFW_KEY_LEFT_BRACKET: return keyLEFTBRACKET;
		  case GLFW_KEY_RIGHT_BRACKET: return keyRIGHTBRACKET;
		  case GLFW_KEY_APOSTROPHE: return keyQUOTE;
		  case GLFW_KEY_GRAVE_ACCENT: return keyBACKQUOTE;

		  GLFW_TRANS(BACKSLASH)
		  GLFW_TRANS(BACKSPACE)
		  GLFW_TRANS(CAPS_LOCK)
		  GLFW_TRANS(COMMA)
		  GLFW_TRANS(DELETE)
		  GLFW_TRANS(DOWN)
		  GLFW_TRANS(END)
		  GLFW_TRANS(ENTER)
		  GLFW_TRANS(EQUAL)
		  GLFW_TRANS(ESCAPE)
		  GLFW_TRANS(HOME)
		  GLFW_TRANS(INSERT)
		  GLFW_TRANS(LEFT)
		  GLFW_TRANS(MINUS)
		  GLFW_TRANS(PAGE_UP)
		  GLFW_TRANS(PAGE_DOWN)
		  GLFW_TRANS(PERIOD)
		  GLFW_TRANS(RIGHT)
		  GLFW_TRANS(SEMICOLON)
		  GLFW_TRANS(SLASH)
		  GLFW_TRANS(SPACE)
		  GLFW_TRANS(TAB)
		  GLFW_TRANS(UP)

		  case GLFW_KEY_KP_ADD: return keyNUMPAD_ADD;
		  case GLFW_KEY_KP_DECIMAL: return keyNUMPAD_DECIMAL;
		  case GLFW_KEY_KP_DIVIDE: return keyNUMPAD_DIVIDE;
		  case GLFW_KEY_KP_ENTER: return keyNUMPAD_ENTER;
		  case GLFW_KEY_KP_MULTIPLY: return keyNUMPAD_MULTIPLY;
		  case GLFW_KEY_KP_SUBTRACT: return keyNUMPAD_SUBTRACT;
		}
		return inKey;
		
	}
	
	
	static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
	{
		Event event(action == GLFW_RELEASE ? etKeyUp : etKeyDown);
		bool right;
		event.value = GLFWKeyToFlash(key, right);
		if (right) event.flags |= efLocationRight;
		event.code = scancode;
		sgGLFWFrame->HandleEvent(event);
	}

	static void mouse_button_callback(GLFWwindow *window, int button, int action, int mods)
	{
		double xpos, ypos;
		glfwGetCursorPos(window, &xpos, &ypos);
		Event event(action == GLFW_RELEASE ? etMouseUp : etMouseDown, xpos, ypos, button);
		sgGLFWFrame->HandleEvent(event);
	}

	static void cursor_pos_callback(GLFWwindow *window, double xpos, double ypos)
	{
		Event event(etMouseMove, xpos, ypos);
		event.flags |= efPrimaryTouch;
		sgGLFWFrame->HandleEvent(event);
	}

	static void window_size_callback(GLFWwindow *window, int inWidth, int inHeight)
	{
		Event resize(etResize, inWidth, inHeight);
		sgGLFWFrame->Resize(inWidth, inHeight);
		sgGLFWFrame->HandleEvent(resize);
	}

	static void window_focus_callback(GLFWwindow *window, int inFocus)
	{
		Event activate( inFocus == GL_TRUE ? etGotInputFocus : etLostInputFocus );
		sgGLFWFrame->HandleEvent(activate);
	}

	static void window_close_callback(GLFWwindow *window)
	{
		Event close(etQuit);
		sgGLFWFrame->HandleEvent(close);
	}*/
	
	
	TizenFrame *createWindowFrame (const char *inTitle, int inWidth, int inHeight, unsigned int inFlags) {
		
		/*bool fullscreen = (inFlags & wfFullScreen) != 0;
		
		if (inFlags & wfResizable)
		  glfwWindowHint(GLFW_RESIZABLE, GL_TRUE);
		else
		  glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
		
		if (inFlags & wfBorderless)
		  glfwWindowHint(GLFW_DECORATED, GL_FALSE);
		
		glfwWindowHint(GLFW_DEPTH_BITS, (inFlags & wfDepthBuffer ? 24 : 0));
		glfwWindowHint(GLFW_STENCIL_BITS, (inFlags & wfStencilBuffer ? 8 : 0));
		
		if (inFlags & wfVSync)
		  glfwSwapInterval(1);
		
		GLFWwindow *window = glfwCreateWindow(inWidth, inHeight, inTitle, fullscreen ? glfwGetPrimaryMonitor() : NULL, NULL);
		if (!window)
		{
		  fprintf(stderr, "Failed to create GLFW window\n");
		  glfwTerminate();
		  return 0;
		}
		glfwMakeContextCurrent(window);
		
		glfwSetKeyCallback(window, key_callback);
		glfwSetMouseButtonCallback(window, mouse_button_callback);
		glfwSetCursorPosCallback(window, cursor_pos_callback);
		glfwSetWindowSizeCallback(window, window_size_callback);
		glfwSetWindowFocusCallback(window, window_focus_callback);
		// glfwSetWindowCloseCallback(window, window_close_callback);*/
		
		return new TizenFrame (/*window,*/ inWidth, inHeight);
		
	}
	
	
	void SetIcon (const char *path) {}
	
	
}



