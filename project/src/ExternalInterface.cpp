#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif


#include <hx/CFFI.h>
#include "Application.h"
#include "Window.h"
#include "Renderer.h"


namespace lime {
	
	
	value lime_application_create () {
		
		Application* app = CreateApplication ();
		return alloc_int ((intptr_t)app);
		
	}
	
	
	value lime_application_exec (value application) {
		
		Application* app = (Application*)(intptr_t)val_int (application);
		return alloc_int (app->Exec ());
		
	}
	
	
	value lime_renderer_create (value window) {
		
		Renderer* renderer = CreateRenderer ((Window*)(intptr_t)val_int (window));
		return alloc_int ((intptr_t)renderer);
		
	}
	
	
	value lime_window_create (value application) {
		
		Window* window = CreateWindow ((Application*)(intptr_t)val_int (application));
		return alloc_int ((intptr_t)window);
		
	}
	
	
	DEFINE_PRIM (lime_application_create, 0);
	DEFINE_PRIM (lime_application_exec, 1);
	DEFINE_PRIM (lime_renderer_create, 1);
	DEFINE_PRIM (lime_window_create, 1);
	
	
}


extern "C" int lime_register_prims () {
	
	return 0;
	
}