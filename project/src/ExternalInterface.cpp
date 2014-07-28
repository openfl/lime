#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif


#include <hx/CFFI.h>
#include <app/Application.h>
#include <app/UpdateEvent.h>
#ifdef LIME_FREETYPE
#include <graphics/Font.h>
#endif
#include <graphics/Image.h>
#include <graphics/PNG.h>
#include <graphics/JPEG.h>
#include <graphics/Renderer.h>
#include <graphics/RenderEvent.h>
#include <system/System.h>
#include <ui/KeyEvent.h>
#include <ui/MouseEvent.h>
#include <ui/TouchEvent.h>
#include <ui/Window.h>
#include <ui/WindowEvent.h>
#include <vm/NekoVM.h>


namespace lime {
	
	
	value lime_application_create (value callback) {
		
		Application* app = CreateApplication ();
		Application::callback = new AutoGCRoot (callback);
		return alloc_float ((intptr_t)app);
		
	}
	
	
	value lime_application_exec (value application) {
		
		Application* app = (Application*)(intptr_t)val_float (application);
		return alloc_int (app->Exec ());
		
	}
	
	
	value lime_application_get_ticks (value application) {
		
		return alloc_float (Application::GetTicks ());
		
	}
	
	
	value lime_image_load (value path) {
		
		Image image;
		Resource resource (val_string (path));
		
		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &image)) {
			
			return image.Value ();
			
		}
		#endif
		
		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &image)) {
			
			return image.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	value lime_image_load_bytes (value bytes) {
		
		Image image;
		ByteArray data (bytes);
		Resource resource (&data);
		
		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &image)) {
			
			return image.Value ();
			
		}
		#endif
		
		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &image)) {
			
			return image.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	value lime_font_load (value fontFace) {
		
		#ifdef LIME_FREETYPE
		Font *font = new Font (val_string (fontFace));
		return alloc_float ((intptr_t)font);
		#else
		return alloc_null ();
		#endif

	}


	value lime_font_load_glyphs (value fontHandle, value size, value glyphs) {
		
		#ifdef LIME_FREETYPE
		Image image;
		Font *font = (Font*)(intptr_t)val_float (fontHandle);
		value data = alloc_empty_object ();
		alloc_field (data, val_id ("glyphs"), font->LoadGlyphs (val_int (size), val_string (glyphs), &image));
		alloc_field (data, val_id ("image"), image.Value ());
		return data;
		#else
		return alloc_null ();
		#endif
		
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
	
	
	value lime_neko_execute (value module) {
		
		#ifdef LIME_NEKO
		NekoVM::Execute (val_string (module));
		#endif
		return alloc_null ();
		
	}
	
	
	value lime_render_event_manager_register (value callback, value eventObject) {
		
		RenderEvent::callback = new AutoGCRoot (callback);
		RenderEvent::eventObject = new AutoGCRoot (eventObject);
		return alloc_null ();
		
	}
	
	
	value lime_renderer_create (value window) {
		
		Renderer* renderer = CreateRenderer ((Window*)(intptr_t)val_float (window));
		return alloc_float ((intptr_t)renderer);
		
	}
	
	
	value lime_renderer_flip (value renderer) {
		
		((Renderer*)(intptr_t)val_float (renderer))->Flip ();
		return alloc_null (); 
		
	}
	
	
	value lime_system_get_timestamp () {
		
		return alloc_float (System::GetTimestamp ());
		
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
	
	
	value lime_window_create (value application, value width, value height, value flags, value title) {
		
		Window* window = CreateWindow ((Application*)(intptr_t)val_float (application), val_int (width), val_int (height), val_int (flags), val_string (title));
		return alloc_float ((intptr_t)window);
		
	}
	
	
	value lime_window_event_manager_register (value callback, value eventObject) {
		
		WindowEvent::callback = new AutoGCRoot (callback);
		WindowEvent::eventObject = new AutoGCRoot (eventObject);
		return alloc_null ();
		
	}
	
	
	value lime_window_move (value window, value x, value y) {
		
		Window* targetWindow = (Window*)(intptr_t)val_float (window);
		targetWindow->Move (val_int (x), val_int (y));
		return alloc_null ();
		
	}
	
	
	value lime_window_resize (value window, value width, value height) {
		
		Window* targetWindow = (Window*)(intptr_t)val_float (window);
		targetWindow->Resize (val_int (width), val_int (height));
		return alloc_null ();
		
	}
	
	
	DEFINE_PRIM (lime_application_create, 1);
	DEFINE_PRIM (lime_application_exec, 1);
	DEFINE_PRIM (lime_application_get_ticks, 0);
	DEFINE_PRIM (lime_image_load, 1);
	DEFINE_PRIM (lime_image_load_bytes, 1);
	DEFINE_PRIM (lime_font_load, 1);
	DEFINE_PRIM (lime_font_load_glyphs, 3);
	DEFINE_PRIM (lime_key_event_manager_register, 2);
	DEFINE_PRIM (lime_lzma_encode, 1);
	DEFINE_PRIM (lime_lzma_decode, 1);
	DEFINE_PRIM (lime_mouse_event_manager_register, 2);
	DEFINE_PRIM (lime_neko_execute, 1);
	DEFINE_PRIM (lime_renderer_create, 1);
	DEFINE_PRIM (lime_renderer_flip, 1);
	DEFINE_PRIM (lime_render_event_manager_register, 2);
	DEFINE_PRIM (lime_system_get_timestamp, 0);
	DEFINE_PRIM (lime_touch_event_manager_register, 2);
	DEFINE_PRIM (lime_update_event_manager_register, 2);
	DEFINE_PRIM (lime_window_create, 5);
	DEFINE_PRIM (lime_window_event_manager_register, 2);
	DEFINE_PRIM (lime_window_move, 3);
	DEFINE_PRIM (lime_window_resize, 3);
	
	
}


extern "C" int lime_register_prims () {
	
	return 0;
	
}