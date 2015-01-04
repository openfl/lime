#ifndef LIME_UI_WINDOW_H
#define LIME_UI_WINDOW_H


#ifdef CreateWindow
#undef CreateWindow
#endif

#include <app/Application.h>
#include <graphics/ImageBuffer.h>


namespace lime {
	
	
	class Window {
		
		
		public:
			
			virtual void Move (int x, int y) = 0;
			virtual void Resize (int width, int height) = 0;
			virtual void SetIcon (ImageBuffer *imageBuffer) = 0;
			
			Application* currentApplication;
			int flags;
		
		
	};
	
	
	Window* CreateWindow (Application* application, int width, int height, int flags, const char* title);
	
	
	enum WindowFlags {
		
		WINDOW_FLAG_FULLSCREEN = 0x00000001,
		WINDOW_FLAG_BORDERLESS = 0x00000002,
		WINDOW_FLAG_RESIZABLE = 0x00000004,
		WINDOW_FLAG_HARDWARE = 0x00000008,
		WINDOW_FLAG_VSYNC = 0x00000010,
		WINDOW_FLAG_HW_AA = 0x00000020,
		WINDOW_FLAG_HW_AA_HIRES = 0x00000060,
		WINDOW_FLAG_ALLOW_SHADERS = 0x00000080,
		WINDOW_FLAG_REQUIRE_SHADERS = 0x00000100,
		WINDOW_FLAG_DEPTH_BUFFER = 0x00000200,
		WINDOW_FLAG_STENCIL_BUFFER = 0x00000400
		
	};
	
}


#endif