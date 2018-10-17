#ifndef LIME_GRAPHICS_OPENGL_OPENGL_BINDINGS_H
#define LIME_GRAPHICS_OPENGL_OPENGL_BINDINGS_H


namespace lime {


	class OpenGLBindings {

		public:

			static bool Init ();

			static int defaultFramebuffer;
			static int defaultRenderbuffer;
			static void* handle;

			#ifdef NATIVE_TOOLKIT_SDL_ANGLE
			static void* eglHandle;
			#endif


		private:

			static bool initialized;


	};


	enum GLObjectType {

		TYPE_UNKNOWN,
		TYPE_PROGRAM,
		TYPE_SHADER,
		TYPE_BUFFER,
		TYPE_TEXTURE,
		TYPE_FRAMEBUFFER,
		TYPE_RENDERBUFFER,
		TYPE_VERTEX_ARRAY_OBJECT,
		TYPE_QUERY,
		TYPE_SAMPLER,
		TYPE_SYNC,
		TYPE_TRANSFORM_FEEDBACK

	};


}


#endif