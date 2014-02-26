#ifdef TIZEN

#include <FGraphicsOpengl2.h>
using namespace Tizen::Graphics::Opengl;

#else

#include <EGL/egl.h>
#include <GLES/gl.h>
#include <X11/Xlib.h>

#endif

#include <stdio.h>
#include "renderer/opengl/Egl.h"

// Seems this does not work on raspberry pi....
//#define X11_EGL

#ifdef RASPBERRYPI
#ifndef X11_EGL
#include "bcm_host.h"
static EGL_DISPMANX_WINDOW_T gNativewindow;
#endif
#endif

EGLDisplay g_eglDisplay = 0;
EGLConfig  g_eglConfig = 0;
EGLContext g_eglContext = 0;
EGLSurface g_eglSurface = 0;
#ifdef X11_EGL
Display   *g_x11Display = NULL;
#endif
void      *g_Window = 0;
int        g_eglVersion = 1;

#ifdef TIZEN
#include <FBase.h>
#endif


void limeEGLDestroy()
{
   if (g_eglContext)
   {
      eglSwapBuffers(g_eglDisplay, g_eglSurface);
      // here we free up the context and display we made earlier
      eglMakeCurrent(g_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT );
      eglDestroySurface( g_eglDisplay, g_eglSurface );
      eglDestroyContext( g_eglDisplay, g_eglContext );
      g_eglContext = 0;
      g_eglSurface = 0;
   }
}

void limeEGLSwapBuffers()
{
   eglSwapBuffers(g_eglDisplay, g_eglSurface);
}

bool limeEGLResize(void *inWindow, int &ioWidth, int &ioHeight)
{
   limeEGLDestroy();

   //printf("eglCreateWindowSurface %p %p %p\n", g_eglDisplay, g_eglConfig, inX11Window);
 
   // create an EGL window surface
   uint32_t width = ioWidth;
   uint32_t height = ioHeight;
   
   #if defined(X11_EGL) || defined(TIZEN)
   g_eglSurface = eglCreateWindowSurface(g_eglDisplay,
          g_eglConfig, (EGLNativeWindowType)inWindow, 0);
   #else
   
   DISPMANX_ELEMENT_HANDLE_T dispman_element;
   DISPMANX_DISPLAY_HANDLE_T dispman_display;
   DISPMANX_UPDATE_HANDLE_T dispman_update;
   VC_RECT_T dst_rect;
   VC_RECT_T src_rect;
  
   #if 0
   int success = graphics_get_display_size(0 /* LCD */, &width, &height);
   if (success<0)
   {
      printf("Could not get graphics size.\n");
      return false;
   }
   #endif

   dst_rect.x = 0;
   dst_rect.y = 0;
   dst_rect.width = width;
   dst_rect.height = height;
      
   src_rect.x = 0;
   src_rect.y = 0;
   src_rect.width = width << 16;
   src_rect.height = height << 16;        

   dispman_display = vc_dispmanx_display_open( 0 /* LCD */);
   dispman_update = vc_dispmanx_update_start( 0 );
         
   dispman_element = vc_dispmanx_element_add ( dispman_update, dispman_display,
      0/*layer*/, &dst_rect, 0/*src*/,
      &src_rect, DISPMANX_PROTECTION_NONE, 0 /*alpha*/, 0/*clamp*/,
          (DISPMANX_TRANSFORM_T)0/*transform*/);
      
   gNativewindow.element = dispman_element;
   gNativewindow.width = width;
   gNativewindow.height = height;
   vc_dispmanx_update_submit_sync( dispman_update );
   
   // printf("Create surface %dx%d...\n", width, height );
   g_eglSurface = eglCreateWindowSurface( g_eglDisplay, g_eglConfig, &gNativewindow, 0 );

   ioWidth = width;
   ioHeight = height;

   #endif

   if ( g_eglSurface == EGL_NO_SURFACE)
   {
      printf("Unable to create EGL surface!\n");
      return false;
   }
 
   // Bind GLES and create the context
   eglBindAPI(EGL_OPENGL_ES_API);

     // Use GLES version 1.x
   EGLint contextParams[] = {EGL_CONTEXT_CLIENT_VERSION, g_eglVersion, EGL_NONE};
   g_eglContext = eglCreateContext(g_eglDisplay, g_eglConfig, EGL_NO_CONTEXT, contextParams);
   if (g_eglContext == EGL_NO_CONTEXT)
   {
      printf("Unable to create GLES context!\n");
      return false;
   }
 
   if (eglMakeCurrent(g_eglDisplay,  g_eglSurface,  g_eglSurface, g_eglContext) == EGL_FALSE)
   {
      printf("Unable to make GLES context current\n");
      return false;
   }

   printf("Created opengl context %dx%d.\n", width, height);
   return true;
}


bool limeEGLCreate(void *inWindow, int &ioWidth, int &ioHeight,
                int inOGLESVersion,
                int inDepthBits,
                int inStencilBits,
                int inAlphaBits
                )
{
   #ifdef X11_EGL
   // use EGL to initialise GLES
   g_x11Display = XOpenDisplay(NULL);
 
   if (!g_x11Display)
   {
      fprintf(stderr, "ERROR: unable to get display!\n");
      return 0;
   }
 
   g_eglDisplay = eglGetDisplay((EGLNativeDisplayType)g_x11Display);
   if (g_eglDisplay == EGL_NO_DISPLAY)
   {
      printf("Unable to get EGL display(%p).\n", g_x11Display);
      return false;
   }

   #else
   
   #ifdef RASPBERRYPI
   bcm_host_init();
   #endif

   g_eglDisplay = eglGetDisplay(EGL_DEFAULT_DISPLAY);

   #endif

   // Initialise egl
   if (!eglInitialize(g_eglDisplay, NULL, NULL) || eglGetError() != EGL_SUCCESS)
   {
      printf("Unable to initialise EGL display.\n");
      return false;
   }
 
   // Find a matching config
   
   int renderType = (inOGLESVersion > 1 ? EGL_OPENGL_ES2_BIT : EGL_OPENGL_ES_BIT);

   EGLint attribs[] ={
      #ifdef RASPBERRYPI
      EGL_RED_SIZE,             5,
      EGL_GREEN_SIZE,           6,
      EGL_BLUE_SIZE,            5,
      #else
      EGL_RED_SIZE,             8,
      EGL_GREEN_SIZE,           8,
      EGL_BLUE_SIZE,            8,
      EGL_ALPHA_SIZE,            8,
      #endif
      EGL_DEPTH_SIZE,           inDepthBits,
      EGL_SURFACE_TYPE,         EGL_WINDOW_BIT,
      EGL_RENDERABLE_TYPE,      renderType,
      EGL_BIND_TO_TEXTURE_RGBA, EGL_TRUE,
      EGL_NONE
      };
   
   EGLint numConfigsOut = 0;
   if (eglChooseConfig(g_eglDisplay, attribs, &g_eglConfig, 1, &numConfigsOut) != EGL_TRUE || numConfigsOut == 0 || eglGetError() != EGL_SUCCESS)
   {
      printf("Unable to find appropriate EGL config.\n");
      return false;
   }

   g_eglVersion = inOGLESVersion;

   return limeEGLResize(inWindow, ioWidth, ioHeight);
}
