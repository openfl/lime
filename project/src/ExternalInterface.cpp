#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif


#include <hx/CFFI.h>
#include <app/Application.h>
#include <app/Renderer.h>
#include <app/RenderEvent.h>
#include <app/UpdateEvent.h>
#include <app/Window.h>
#include <ui/KeyEvent.h>
#include <ui/MouseEvent.h>
#include <ui/TouchEvent.h>
#include <ui/WindowEvent.h>


namespace lime {
	
	
	value lime_application_create (value callback) {
		
		Application* app = CreateApplication ();
		Application::callback = new AutoGCRoot (callback);
		return alloc_int ((intptr_t)app);
		
	}
	
	
	value lime_application_exec (value application) {
		
		Application* app = (Application*)(intptr_t)val_int (application);
		return alloc_int (app->Exec ());
		
	}
	
	
	value lime_application_get_ticks (value application) {
		
		return alloc_float (Application::GetTicks ());
		
	}
	
	
	value lime_key_event_manager_register (value callback, value eventObject) {
		
		KeyEvent::callback = new AutoGCRoot (callback);
		KeyEvent::eventObject = new AutoGCRoot (eventObject);
		return alloc_null ();
		
	}
	
	
	value lime_lzma_decode (value input_value) {
		
		/*buffer input_buffer = val_to_buffer(input_value);
		buffer output_buffer = alloc_buffer_len(0);
		
		Lzma::Decode (input_buffer, output_buffer);
		
		return buffer_val (output_buffer);*/
		return alloc_null ();
		
	}
	
	
	value lime_lzma_encode (value input_value) {
		
		/*buffer input_buffer = val_to_buffer(input_value);
		buffer output_buffer = alloc_buffer_len(0);
		
		Lzma::Encode (input_buffer, output_buffer);
		
		return buffer_val (output_buffer);*/
		return alloc_null ();
		
	}
	
	
	value lime_mouse_event_manager_register (value callback, value eventObject) {
		
		MouseEvent::callback = new AutoGCRoot (callback);
		MouseEvent::eventObject = new AutoGCRoot (eventObject);
		return alloc_null ();
		
	}
	
	
	value lime_render_event_manager_register (value callback, value eventObject) {
		
		RenderEvent::callback = new AutoGCRoot (callback);
		RenderEvent::eventObject = new AutoGCRoot (eventObject);
		return alloc_null ();
		
	}
	
	
	value lime_renderer_create (value window) {
		
		Renderer* renderer = CreateRenderer ((Window*)(intptr_t)val_int (window));
		return alloc_int ((intptr_t)renderer);
		
	}
	
	
	value lime_renderer_flip (value renderer) {
		
		((Renderer*)(intptr_t)val_int (renderer))->Flip ();
		return alloc_null (); 
		
	}
	
	
	value lime_touch_event_manager_register (value callback, value eventObject) {
		
		TouchEvent::callback = new AutoGCRoot (callback);
		TouchEvent::eventObject = new AutoGCRoot (eventObject);
		return alloc_null ();
		
	}
	
	
	value lime_update_event_manager_register (value callback, value eventObject) {
		
		UpdateEvent::callback = new AutoGCRoot (callback);
		UpdateEvent::eventObject = new AutoGCRoot (eventObject);
		return alloc_null ();
		
	}
	
	
	value lime_window_create (value application) {
		
		Window* window = CreateWindow ((Application*)(intptr_t)val_int (application));
		return alloc_int ((intptr_t)window);
		
	}
	
	
	value lime_window_event_manager_register (value callback, value eventObject) {
		
		WindowEvent::callback = new AutoGCRoot (callback);
		WindowEvent::eventObject = new AutoGCRoot (eventObject);
		return alloc_null ();
		
	}
	
	
	DEFINE_PRIM (lime_application_create, 1);
	DEFINE_PRIM (lime_application_exec, 1);
	DEFINE_PRIM (lime_application_get_ticks, 0);
	DEFINE_PRIM (lime_key_event_manager_register, 2);
	DEFINE_PRIM (lime_lzma_encode, 1);
	DEFINE_PRIM (lime_lzma_decode, 1);
	DEFINE_PRIM (lime_mouse_event_manager_register, 2);
	DEFINE_PRIM (lime_renderer_create, 1);
	DEFINE_PRIM (lime_renderer_flip, 1);
	DEFINE_PRIM (lime_render_event_manager_register, 2);
	DEFINE_PRIM (lime_touch_event_manager_register, 2);
	DEFINE_PRIM (lime_update_event_manager_register, 2);
	DEFINE_PRIM (lime_window_create, 1);
	DEFINE_PRIM (lime_window_event_manager_register, 2);
	
	
}


extern "C" int lime_register_prims () {
	
	return 0;
	
}