#include "renderer/opengl/OGL.h"

#ifdef NEED_EXTENSIONS
#define DEFINE_EXTENSION
#include "renderer/opengl/OGLExtensions.h"
#undef DEFINE_EXTENSION
#endif

#include "renderer/opengl/OpenGLContext.h"
#include "renderer/opengl/OpenGL2Context.h"
#include "renderer/opengl/OpenGLTexture.h"

#ifdef TIZEN
#include <FBase.h>
#endif


namespace lime {
	
	
	HardwareContext* lime::HardwareContext::current = NULL;
	
	
	bool HasShaderSupport () {
		
		int glMajor = 1;
		int glMinor = 0;
		bool shaders = false;
		
		const char *version = (const char *)glGetString (GL_VERSION);
		
		//printf("GL_VERSION: %s\n", version);
		
		#if defined(LIME_GLES) && !defined(TIZEN)
		glMajor = version[10];
		glMinor = version[12];
		#else
		if (version) {
			
			sscanf (version, "%d.%d", &glMajor, &glMinor);
			
		}
		#endif
		
		if (glMajor == 1) {
			
			const char *ext = (const char *)glGetString (GL_EXTENSIONS);
			if (ext && strstr (ext, "GL_ARB_shading_language_100")) {
				
				shaders = true;
				
			}
			
		} else if (glMajor >= 2) {
			
			shaders = true;
			
		}
		
		#ifdef ANDROID
		ELOG ("VERSION %s (%c), pipeline = %s", version, version == 0 ? '?' : version[10], shaders ? "programmable" : "fixed");
		#endif
		
		return shaders;
		
	}
	
	
	void InitExtensions () {
		
		static bool extentions_init = false;
		
		if (!extentions_init) {
			
			extentions_init = true;
			
			#ifdef HX_WINDOWS
			#ifndef SDL_OGL
			#ifndef GLFW_OGL
			wglMakeCurrent ((WinDC)inWindow, (GLCtx)inGLCtx);
			#endif
			#endif
			
			#ifdef NEED_EXTENSIONS
			#define GET_EXTENSION
			#include "renderer/opengl/OGLExtensions.h"
			#undef DEFINE_EXTENSION
			#endif
			
			#endif
			
		}
		
	}
	
	
	void ResetHardwareContext () {
		
		//__android_log_print(ANDROID_LOG_ERROR, "lime", "ResetHardwareContext");
		gTextureContextVersion++;
		
	}
	
	
	#ifdef LIME_USE_VBO
	void ReleaseVertexBufferObject (unsigned int inVBO) {
		
		if (glDeleteBuffers)
			glDeleteBuffers (1, &inVBO);
		
	}
	#endif
	
	
	HardwareContext *HardwareContext::CreateOpenGL (void *inWindow, void *inGLCtx, bool shaders) {
		
		HardwareContext *ctx;
		
		#if defined (ANDROID) || defined (BLACKBERRY) || defined (IPHONE) || defined (WEBOS) || defined (TIZEN)
		#ifdef LIME_FORCE_GLES2
		//printf ("Force GLES2\n");
		shaders = true;
		#elif defined(LIME_FORCE_GLES1)
		//printf ("Force GLES1\n");
		shaders = false;
		#endif
		#endif
		
		if (shaders && HasShaderSupport ()) {
			
			//#ifdef TIZEN
			//AppLog ("Using OGL2\n");
			//#endif
			//printf("Using OGL2\n");
			ctx = new OpenGL2Context ((WinDC)inWindow, (GLCtx)inGLCtx);
			
		} else {
			
			//#ifdef TIZEN
			//AppLog ("Using OGL2\n");
			//#endif
			//printf("Using OGL1\n");
			ctx = new OpenGLContext ((WinDC)inWindow, (GLCtx)inGLCtx);
			
		}
		
		InitExtensions ();
		return ctx;
		
	}
	
	
	Texture *OGLCreateTexture (Surface *inSurface, unsigned int inFlags) {
		
		return new OpenGLTexture (inSurface, inFlags);
		
	}
	
	
}
