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
	
	/*
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



