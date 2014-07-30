#ifndef LIME_GRAPHICS_OPENGL_OPENGL_BINDINGS_H
#define LIME_GRAPHICS_OPENGL_OPENGL_BINDINGS_H


namespace lime {
	
	
	class OpenGLBindings {
		
		public:
			
			static bool Init ();
			
			static void* handle;
			
		
		private:
			
			static bool initialized;
		
		
	};
	
	
}


#endif