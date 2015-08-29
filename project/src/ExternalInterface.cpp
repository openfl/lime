#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif


#include <hx/CFFIPrime.h>
#include <app/Application.h>
#include <app/ApplicationEvent.h>
#include <audio/format/OGG.h>
#include <audio/format/WAV.h>
#include <audio/AudioBuffer.h>
#include <graphics/format/JPEG.h>
#include <graphics/format/PNG.h>
#include <graphics/utils/ImageDataUtil.h>
#include <graphics/Image.h>
#include <graphics/ImageBuffer.h>
#include <graphics/Renderer.h>
#include <graphics/RenderEvent.h>
#include <system/Clipboard.h>
#include <system/JNI.h>
#include <system/System.h>
#include <text/Font.h>
#include <text/TextLayout.h>
#include <ui/FileDialog.h>
#include <ui/Gamepad.h>
#include <ui/GamepadEvent.h>
#include <ui/KeyEvent.h>
#include <ui/Mouse.h>
#include <ui/MouseCursor.h>
#include <ui/MouseEvent.h>
#include <ui/TextEvent.h>
#include <ui/TouchEvent.h>
#include <ui/Window.h>
#include <ui/WindowEvent.h>
#include <utils/LZMA.h>
#include <vm/NekoVM.h>


namespace lime {
	
	
	intptr_t lime_application_create (value callback) {
		
		Application* app = CreateApplication ();
		Application::callback = new AutoGCRoot (callback);
		return (intptr_t)app;
		
	}
	
	
	void lime_application_event_manager_register (value callback, value eventObject) {
		
		ApplicationEvent::callback = new AutoGCRoot (callback);
		ApplicationEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	int lime_application_exec (intptr_t application) {
		
		Application* app = (Application*)application;
		return app->Exec ();
		
	}
	
	
	void lime_application_init (intptr_t application) {
		
		Application* app = (Application*)application;
		app->Init ();
		
	}
	
	
	int lime_application_quit (intptr_t application) {
		
		Application* app = (Application*)application;
		return app->Quit ();
		
	}
	
	
	void lime_application_set_frame_rate (intptr_t application, double frameRate) {
		
		Application* app = (Application*)(intptr_t)application;
		app->SetFrameRate (frameRate);
		
	}
	
	
	bool lime_application_update (intptr_t application) {
		
		Application* app = (Application*)application;
		return app->Update ();
		
	}
	
	
	value lime_audio_load (value data) {
		
		AudioBuffer audioBuffer;
		Resource resource;
		
		if (val_is_string (data)) {
			
			resource = Resource (val_string (data));
			
		} else {
			
			Bytes bytes (data);
			resource = Resource (&bytes);
			
		}
		
		if (WAV::Decode (&resource, &audioBuffer)) {
			
			return audioBuffer.Value ();
			
		}
		
		#ifdef LIME_OGG
		if (OGG::Decode (&resource, &audioBuffer)) {
			
			return audioBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	value lime_bytes_from_data_pointer (value data, int length) {
		
		intptr_t ptr = (intptr_t)val_float (data);
		Bytes bytes = Bytes (length);
		
		if (ptr) {
			
			memcpy (bytes.Data (), (const void*)ptr, length);
			
		}
		
		return bytes.Value ();
		
	}
	
	
	intptr_t lime_bytes_get_data_pointer (value bytes) {
		
		Bytes data = Bytes (bytes);
		return (intptr_t)data.Data ();
		
	}
	
	
	value lime_bytes_read_file (const char* path) {
		
		Bytes data = Bytes (path);
		return data.Value ();
		
	}
	
	
	HxString lime_clipboard_get_text () {
		
		if (Clipboard::HasText ()) {
			
			return HxString (Clipboard::GetText ());
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	void lime_clipboard_set_text (const char* text) {
		
		Clipboard::SetText (text);
		
	}
	
	
	HxString lime_file_dialog_open_file (const char* filter, const char* defaultPath) {
		
		#ifdef LIME_NFD
		const char* path = FileDialog::OpenFile (filter, defaultPath);
		return HxString (path);
		#endif
		
		return 0;
		
	}
	
	
	value lime_file_dialog_open_files (const char* filter, const char* defaultPath) {
		
		#ifdef LIME_NFD
		std::vector<const char*> files;
		
		FileDialog::OpenFiles (&files, filter, defaultPath);
		value result = alloc_array (files.size ());
		
		for (int i = 0; i < files.size (); i++) {
			
			val_array_set_i (result, i, alloc_string (files[i]));
			
		}
		#else
		value result = alloc_array (0);
		#endif
		
		return result;
		
	}
	
	
	HxString lime_file_dialog_save_file (const char* filter, const char* defaultPath) {
		
		#ifdef LIME_NFD
		const char* path = FileDialog::SaveFile (filter, defaultPath);
		return HxString (path);
		#endif
		
		return 0;
		
	}
	
	
	void lime_font_destroy (value handle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)val_float (handle);
		delete font;
		#endif
		
	}
	
	
	int lime_font_get_ascender (double fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->GetAscender ();
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_descender (double fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->GetDescender ();
		#else
		return 0;
		#endif
		
	}
	
	
	HxString lime_font_get_family_name (double fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return HxString ((const char*)font->GetFamilyName ());
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_glyph_index (double fontHandle, const char* character) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->GetGlyphIndex ((char*)character);
		#else
		return -1;
		#endif
		
	}
	
	
	value lime_font_get_glyph_indices (double fontHandle, const char* characters) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->GetGlyphIndices ((char*)characters);
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	value lime_font_get_glyph_metrics (double fontHandle, int index) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->GetGlyphMetrics (index);
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	int lime_font_get_height (double fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->GetHeight ();
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_num_glyphs (double fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->GetNumGlyphs ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	int lime_font_get_underline_position (double fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->GetUnderlinePosition ();
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_underline_thickness (double fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->GetUnderlineThickness ();
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_units_per_em (double fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->GetUnitsPerEM ();
		#else
		return 0;
		#endif
		
	}
	
	
	value lime_font_load (value data) {
		
		#ifdef LIME_FREETYPE
		Resource resource;
		
		if (val_is_string (data)) {
			
			resource = Resource (val_string (data));
			
		} else {
			
			Bytes bytes (data);
			resource = Resource (&bytes);
			
		}
		
		Font *font = new Font (&resource, 0);
		
		if (font) {
			
			if (font->face) {
				
				value v = alloc_float ((intptr_t)font);
				val_gc (v, lime_font_destroy);
				return v;
				
			} else {
				
				delete font;
				
			}
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	value lime_font_outline_decompose (double fontHandle, int size) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		return font->Decompose (size);
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	bool lime_font_render_glyph (double fontHandle, int index, value data) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		Bytes bytes = Bytes (data);
		return font->RenderGlyph (index, &bytes);
		#else
		return false;
		#endif
		
	}
	
	
	bool lime_font_render_glyphs (double fontHandle, value indices, value data) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		Bytes bytes = Bytes (data);
		return font->RenderGlyphs (indices, &bytes);
		#else
		return false;
		#endif
		
	}
	
	
	void lime_font_set_size (double fontHandle, int fontSize) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)fontHandle;
		font->SetSize (fontSize);
		#endif
		
	}
	
	
	void lime_gamepad_add_mappings (value mappings) {
		
		int length = val_array_size (mappings);
		
		for (int i = 0; i < length; i++) {
			
			Gamepad::AddMapping (val_string (val_array_i (mappings, i)));
			
		}
		
	}
	
	
	void lime_gamepad_event_manager_register (value callback, value eventObject) {
		
		GamepadEvent::callback = new AutoGCRoot (callback);
		GamepadEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	HxString lime_gamepad_get_device_guid (int id) {
		
		return HxString (Gamepad::GetDeviceGUID (id));
		
	}
	
	
	HxString lime_gamepad_get_device_name (int id) {
		
		return HxString (Gamepad::GetDeviceName (id));
		
	}
	
	
	value lime_image_encode (value buffer, int type, int quality) {
		
		ImageBuffer imageBuffer = ImageBuffer (buffer);
		Bytes data;
		
		switch (type) {
			
			case 0: 
				
				#ifdef LIME_PNG
				if (PNG::Encode (&imageBuffer, &data)) {
					
					//delete imageBuffer.data;
					return data.Value ();
					
				}
				#endif
				break;
			
			case 1:
				
				#ifdef LIME_JPEG
				if (JPEG::Encode (&imageBuffer, &data, quality)) {
					
					//delete imageBuffer.data;
					return data.Value ();
					
				}
				#endif
				break;
			
			default: break;
			
		}
		
		//delete imageBuffer.data;
		return alloc_null ();
		
	}
	
	
	value lime_image_load (value data) {
		
		ImageBuffer buffer;
		Resource resource;
		
		if (val_is_string (data)) {
			
			resource = Resource (val_string (data));
			
		} else {
			
			Bytes bytes (data);
			resource = Resource (&bytes);
			
		}
		
		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &buffer)) {
			
			return buffer.Value ();
			
		}
		#endif
		
		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &buffer)) {
			
			return buffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	void lime_image_data_util_color_transform (value image, value rect, value colorMatrix) {
		
		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		ColorMatrix _colorMatrix = ColorMatrix (colorMatrix);
		ImageDataUtil::ColorTransform (&_image, &_rect, &_colorMatrix);
		
	}
	
	
	void lime_image_data_util_copy_channel (value image, value sourceImage, value sourceRect, value destPoint, int srcChannel, int destChannel) {
		
		Image _image = Image (image);
		Image _sourceImage = Image (sourceImage);
		Rectangle _sourceRect = Rectangle (sourceRect);
		Vector2 _destPoint = Vector2 (destPoint);
		ImageDataUtil::CopyChannel (&_image, &_sourceImage, &_sourceRect, &_destPoint, srcChannel, destChannel);
		
	}
	
	
	void lime_image_data_util_copy_pixels (value image, value sourceImage, value sourceRect, value destPoint, value alphaImage, value alphaPoint, bool mergeAlpha) {
		
		Image _image = Image (image);
		Image _sourceImage = Image (sourceImage);
		Rectangle _sourceRect = Rectangle (sourceRect);
		Vector2 _destPoint = Vector2 (destPoint);
		
		if (val_is_null (alphaImage)) {
			
			ImageDataUtil::CopyPixels (&_image, &_sourceImage, &_sourceRect, &_destPoint, 0, 0, mergeAlpha);
			
		} else {
			
			Image _alphaImage = Image (alphaImage);
			Vector2 _alphaPoint = Vector2 (alphaPoint);
			
			ImageDataUtil::CopyPixels (&_image, &_sourceImage, &_sourceRect, &_destPoint, &_alphaImage, &_alphaPoint, mergeAlpha);
			
		}
		
	}
	
	
	void lime_image_data_util_fill_rect (value image, value rect, int rg, int ba) {
		
		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		int32_t color = (rg << 16) | ba;
		ImageDataUtil::FillRect (&_image, &_rect, color);
		
	}
	
	
	void lime_image_data_util_flood_fill (value image, int x, int y, int rg, int ba) {
		
		Image _image = Image (image);
		int32_t color = (rg << 16) | ba;
		ImageDataUtil::FloodFill (&_image, x, y, color);
		
	}
	
	
	void lime_image_data_util_get_pixels (value image, value rect, int format, value bytes) {
		
		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		PixelFormat _format = (PixelFormat)format;
		Bytes pixels = Bytes (bytes);
		ImageDataUtil::GetPixels (&_image, &_rect, _format, &pixels);
		
	}
	
	
	void lime_image_data_util_merge (value image, value sourceImage, value sourceRect, value destPoint, int redMultiplier, int greenMultiplier, int blueMultiplier, int alphaMultiplier) {
		
		Image _image = Image (image);
		Image _sourceImage = Image (sourceImage);
		Rectangle _sourceRect = Rectangle (sourceRect);
		Vector2 _destPoint = Vector2 (destPoint);
		ImageDataUtil::Merge (&_image, &_sourceImage, &_sourceRect, &_destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);
		
	}
	
	
	void lime_image_data_util_multiply_alpha (value image) {
		
		Image _image = Image (image);
		ImageDataUtil::MultiplyAlpha (&_image);
		
	}
	
	
	void lime_image_data_util_resize (value image, value buffer, int width, int height) {
		
		Image _image = Image (image);
		ImageBuffer _buffer = ImageBuffer (buffer);
		ImageDataUtil::Resize (&_image, &_buffer, width, height);
		
	}
	
	
	void lime_image_data_util_set_format (value image, int format) {
		
		Image _image = Image (image);
		PixelFormat _format = (PixelFormat)format;
		ImageDataUtil::SetFormat (&_image, _format);
		
	}
	
	
	void lime_image_data_util_set_pixels (value image, value rect, value bytes, int format) {
		
		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		Bytes _bytes = Bytes (bytes);
		PixelFormat _format = (PixelFormat)format;
		ImageDataUtil::SetPixels (&_image, &_rect, &_bytes, _format);
		
	}
	
	
	void lime_image_data_util_unmultiply_alpha (value image) {
		
		Image _image = Image (image);
		ImageDataUtil::UnmultiplyAlpha (&_image);
		
	}
	
	
	intptr_t lime_jni_getenv () {
		
		#ifdef ANDROID
		return (intptr_t)JNI::GetEnv ();
		#else
		return 0;
		#endif
		
	}
	
	
	value lime_jpeg_decode_bytes (value data, bool decodeData) {
		
		ImageBuffer imageBuffer;
		
		Bytes bytes (data);
		Resource resource = Resource (&bytes);
		
		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &imageBuffer, decodeData)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	value lime_jpeg_decode_file (const char* path, bool decodeData) {
		
		ImageBuffer imageBuffer;
		Resource resource = Resource (path);
		
		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &imageBuffer, decodeData)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	void lime_key_event_manager_register (value callback, value eventObject) {
		
		KeyEvent::callback = new AutoGCRoot (callback);
		KeyEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	value lime_lzma_decode (value buffer) {
		
		#ifdef LIME_LZMA
		Bytes data = Bytes (buffer);
		Bytes result;
		
		LZMA::Decode (&data, &result);
		
		return result.Value ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	value lime_lzma_encode (value buffer) {
		
		#ifdef LIME_LZMA
		Bytes data = Bytes (buffer);
		Bytes result;
		
		LZMA::Encode (&data, &result);
		
		return result.Value ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	void lime_mouse_event_manager_register (value callback, value eventObject) {
		
		MouseEvent::callback = new AutoGCRoot (callback);
		MouseEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	void lime_mouse_hide () {
		
		Mouse::Hide ();
		
	}
	
	
	void lime_mouse_set_cursor (int cursor) {
		
		Mouse::SetCursor ((MouseCursor)cursor);
		
	}
	
	
	void lime_mouse_set_lock (bool lock) {
		
		Mouse::SetLock (lock);
		
	}
	
	
	void lime_mouse_show () {
		
		Mouse::Show ();
		
	}
	
	
	void lime_mouse_warp (int x, int y, intptr_t window) {
		
		Window* windowRef = 0;
		
		if (window) {
			
			windowRef = (Window*)window;
			
		}
		
		Mouse::Warp (x, y, windowRef);
		
	}
	
	
	void lime_neko_execute (const char* module) {
		
		#ifdef LIME_NEKO
		NekoVM::Execute (module);
		#endif
		
	}
	
	
	value lime_png_decode_bytes (value data, bool decodeData) {
		
		ImageBuffer imageBuffer;
		
		Bytes bytes (data);
		Resource resource = Resource (&bytes);
		
		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &imageBuffer, decodeData)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	value lime_png_decode_file (const char* path, bool decodeData) {
		
		ImageBuffer imageBuffer;
		Resource resource = Resource (path);
		
		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &imageBuffer, decodeData)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	void lime_render_event_manager_register (value callback, value eventObject) {
		
		RenderEvent::callback = new AutoGCRoot (callback);
		RenderEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	intptr_t lime_renderer_create (intptr_t window) {
		
		Renderer* renderer = CreateRenderer ((Window*)window);
		return (intptr_t)renderer;
		
	}
	
	
	void lime_renderer_flip (intptr_t renderer) {
		
		((Renderer*)renderer)->Flip ();
		
	}
	
	
	intptr_t lime_renderer_get_context (intptr_t renderer) {
		
		Renderer* targetRenderer = (Renderer*)renderer;
		return (intptr_t)targetRenderer->GetContext ();
		
	}
	
	
	HxString lime_renderer_get_type (intptr_t renderer) {
		
		Renderer* targetRenderer = (Renderer*)renderer;
		return HxString (targetRenderer->Type ());
		
	}
	
	
	value lime_renderer_lock (intptr_t renderer) {
		
		return ((Renderer*)renderer)->Lock ();
		
	}
	
	
	void lime_renderer_make_current (intptr_t renderer) {
		
		((Renderer*)renderer)->MakeCurrent ();
		
	}
	
	
	void lime_renderer_unlock (intptr_t renderer) {
		
		((Renderer*)renderer)->Unlock ();
		
	}
	
	
	HxString lime_system_get_directory (int type, const char* company, const char* title) {
		
		return HxString (System::GetDirectory ((SystemDirectory)type, company, title));
		
	}
	
	
	value lime_system_get_display (int id) {
		
		return System::GetDisplay (id);
		
	}
	
	
	int lime_system_get_num_displays () {
		
		return System::GetNumDisplays ();
		
	}
	
	
	double lime_system_get_timer () {
		
		return System::GetTimer ();
		
	}
	
	
	void lime_text_event_manager_register (value callback, value eventObject) {
		
		TextEvent::callback = new AutoGCRoot (callback);
		TextEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	void lime_text_layout_destroy (value textHandle) {
		
		#ifdef LIME_HARFBUZZ
		TextLayout *text = (TextLayout*)(intptr_t)val_float (textHandle);
		delete text;
		text = 0;
		#endif
		
	}
	
	
	value lime_text_layout_create (int direction, const char* script, const char* language) {
		
		#if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		
		TextLayout *text = new TextLayout (direction, script, language);
		value v = alloc_float ((intptr_t)text);
		val_gc (v, lime_text_layout_destroy);
		return v;
		
		#else
		
		return alloc_null ();
		
		#endif
		
	}
	
	
	value lime_text_layout_position (double textHandle, double fontHandle, int size, const char* textString, value data) {
		
		#if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		
		TextLayout *text = (TextLayout*)(intptr_t)textHandle;
		Font *font = (Font*)(intptr_t)fontHandle;
		Bytes bytes = Bytes (data);
		text->Position (font, size, textString, &bytes);
		return bytes.Value ();
		
		#endif
		
		return alloc_null ();
		
	}
	
	
	void lime_text_layout_set_direction (double textHandle, int direction) {
		
		#if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)(intptr_t)textHandle;
		text->SetDirection (direction);
		#endif
		
	}
	
	
	void lime_text_layout_set_language (double textHandle, const char* language) {
		
		#if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)(intptr_t)textHandle;
		text->SetLanguage (language);
		#endif
		
	}
	
	
	void lime_text_layout_set_script (double textHandle, const char* script) {
		
		#if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)(intptr_t)textHandle;
		text->SetScript (script);
		#endif
		
	}
	
	
	void lime_touch_event_manager_register (value callback, value eventObject) {
		
		TouchEvent::callback = new AutoGCRoot (callback);
		TouchEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	void lime_window_close (intptr_t window) {
		
		Window* targetWindow = (Window*)window;
		targetWindow->Close ();
		
	}
	
	
	intptr_t lime_window_create (intptr_t application, int width, int height, int flags, const char* title) {
		
		Window* window = CreateWindow ((Application*)application, width, height, flags, title);
		return (intptr_t)window;
		
	}
	
	
	void lime_window_event_manager_register (value callback, value eventObject) {
		
		WindowEvent::callback = new AutoGCRoot (callback);
		WindowEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	void lime_window_focus (intptr_t window) {
		
		Window* targetWindow = (Window*)window;
		targetWindow->Focus ();
		
	}
	
	
	bool lime_window_get_enable_text_events (intptr_t window) {
		
		Window* targetWindow = (Window*)window;
		return targetWindow->GetEnableTextEvents ();
		
	}
	
	
	int lime_window_get_height (intptr_t window) {
		
		Window* targetWindow = (Window*)window;
		return targetWindow->GetHeight ();
		
	}
	
	
	int32_t lime_window_get_id (intptr_t window) {
		
		Window* targetWindow = (Window*)window;
		return (int32_t)targetWindow->GetID ();
		
	}
	
	
	int lime_window_get_width (intptr_t window) {
		
		Window* targetWindow = (Window*)window;
		return targetWindow->GetWidth ();
		
	}
	
	
	int lime_window_get_x (intptr_t window) {
		
		Window* targetWindow = (Window*)window;
		return targetWindow->GetX ();
		
	}
	
	
	int lime_window_get_y (intptr_t window) {
		
		Window* targetWindow = (Window*)window;
		return targetWindow->GetY ();
		
	}
	
	
	void lime_window_move (intptr_t window, int x, int y) {
		
		Window* targetWindow = (Window*)window;
		targetWindow->Move (x, y);
		
	}
	
	
	void lime_window_resize (intptr_t window, int width, int height) {
		
		Window* targetWindow = (Window*)window;
		targetWindow->Resize (width, height);
		
	}
	
	
	void lime_window_set_enable_text_events (intptr_t window, bool enabled) {
		
		Window* targetWindow = (Window*)window;
		targetWindow->SetEnableTextEvents (enabled);
		
	}
	
	
	bool lime_window_set_fullscreen (intptr_t window, bool fullscreen) {
		
		Window* targetWindow = (Window*)window;
		return targetWindow->SetFullscreen (fullscreen);
		
	}
	
	
	void lime_window_set_icon (intptr_t window, value buffer) {
		
		Window* targetWindow = (Window*)window;
		ImageBuffer imageBuffer = ImageBuffer (buffer);
		targetWindow->SetIcon (&imageBuffer);
		
	}
	
	
	bool lime_window_set_minimized (intptr_t window, bool fullscreen) {
		
		Window* targetWindow = (Window*)window;
		return targetWindow->SetMinimized (fullscreen);
		
	}
	
	
	HxString lime_window_set_title (intptr_t window, const char* title) {
		
		Window* targetWindow = (Window*)window;
		return HxString (targetWindow->SetTitle (title));
		
	}
	
	
	DEFINE_PRIME1 (lime_application_create);
	DEFINE_PRIME2v (lime_application_event_manager_register);
	DEFINE_PRIME1 (lime_application_exec);
	DEFINE_PRIME1v (lime_application_init);
	DEFINE_PRIME1 (lime_application_quit);
	DEFINE_PRIME2v (lime_application_set_frame_rate);
	DEFINE_PRIME1 (lime_application_update);
	DEFINE_PRIME1 (lime_audio_load);
	DEFINE_PRIME2 (lime_bytes_from_data_pointer);
	DEFINE_PRIME1 (lime_bytes_get_data_pointer);
	DEFINE_PRIME1 (lime_bytes_read_file);
	DEFINE_PRIME0 (lime_clipboard_get_text);
	DEFINE_PRIME1v (lime_clipboard_set_text);
	DEFINE_PRIME2 (lime_file_dialog_open_file);
	DEFINE_PRIME2 (lime_file_dialog_open_files);
	DEFINE_PRIME2 (lime_file_dialog_save_file);
	DEFINE_PRIME1 (lime_font_get_ascender);
	DEFINE_PRIME1 (lime_font_get_descender);
	DEFINE_PRIME1 (lime_font_get_family_name);
	DEFINE_PRIME2 (lime_font_get_glyph_index);
	DEFINE_PRIME2 (lime_font_get_glyph_indices);
	DEFINE_PRIME2 (lime_font_get_glyph_metrics);
	DEFINE_PRIME1 (lime_font_get_height);
	DEFINE_PRIME1 (lime_font_get_num_glyphs);
	DEFINE_PRIME1 (lime_font_get_underline_position);
	DEFINE_PRIME1 (lime_font_get_underline_thickness);
	DEFINE_PRIME1 (lime_font_get_units_per_em);
	DEFINE_PRIME1 (lime_font_load);
	DEFINE_PRIME2 (lime_font_outline_decompose);
	DEFINE_PRIME3 (lime_font_render_glyph);
	DEFINE_PRIME3 (lime_font_render_glyphs);
	DEFINE_PRIME2v (lime_font_set_size);
	DEFINE_PRIME1v (lime_gamepad_add_mappings);
	DEFINE_PRIME2v (lime_gamepad_event_manager_register);
	DEFINE_PRIME1 (lime_gamepad_get_device_guid);
	DEFINE_PRIME1 (lime_gamepad_get_device_name);
	DEFINE_PRIME3v (lime_image_data_util_color_transform);
	DEFINE_PRIME6v (lime_image_data_util_copy_channel);
	DEFINE_PRIME7v (lime_image_data_util_copy_pixels);
	DEFINE_PRIME4v (lime_image_data_util_fill_rect);
	DEFINE_PRIME5v (lime_image_data_util_flood_fill);
	DEFINE_PRIME4v (lime_image_data_util_get_pixels);
	DEFINE_PRIME8v (lime_image_data_util_merge);
	DEFINE_PRIME1v (lime_image_data_util_multiply_alpha);
	DEFINE_PRIME4v (lime_image_data_util_resize);
	DEFINE_PRIME2v (lime_image_data_util_set_format);
	DEFINE_PRIME4v (lime_image_data_util_set_pixels);
	DEFINE_PRIME1v (lime_image_data_util_unmultiply_alpha);
	DEFINE_PRIME3 (lime_image_encode);
	DEFINE_PRIME1 (lime_image_load);
	DEFINE_PRIME0 (lime_jni_getenv);
	DEFINE_PRIME2 (lime_jpeg_decode_bytes);
	DEFINE_PRIME2 (lime_jpeg_decode_file);
	DEFINE_PRIME2v (lime_key_event_manager_register);
	DEFINE_PRIME1 (lime_lzma_decode);
	DEFINE_PRIME1 (lime_lzma_encode);
	DEFINE_PRIME2v (lime_mouse_event_manager_register);
	DEFINE_PRIME0v (lime_mouse_hide);
	DEFINE_PRIME1v (lime_mouse_set_cursor);
	DEFINE_PRIME1v (lime_mouse_set_lock);
	DEFINE_PRIME0v (lime_mouse_show);
	DEFINE_PRIME3v (lime_mouse_warp);
	DEFINE_PRIME1v (lime_neko_execute);
	DEFINE_PRIME2 (lime_png_decode_bytes);
	DEFINE_PRIME2 (lime_png_decode_file);
	DEFINE_PRIME1 (lime_renderer_create);
	DEFINE_PRIME1v (lime_renderer_flip);
	DEFINE_PRIME1 (lime_renderer_get_context);
	DEFINE_PRIME1 (lime_renderer_get_type);
	DEFINE_PRIME1 (lime_renderer_lock);
	DEFINE_PRIME1v (lime_renderer_make_current);
	DEFINE_PRIME1v (lime_renderer_unlock);
	DEFINE_PRIME2v (lime_render_event_manager_register);
	DEFINE_PRIME3 (lime_system_get_directory);
	DEFINE_PRIME1 (lime_system_get_display);
	DEFINE_PRIME0 (lime_system_get_num_displays);
	DEFINE_PRIME0 (lime_system_get_timer);
	DEFINE_PRIME2v (lime_text_event_manager_register);
	DEFINE_PRIME3 (lime_text_layout_create);
	DEFINE_PRIME5 (lime_text_layout_position);
	DEFINE_PRIME2v (lime_text_layout_set_direction);
	DEFINE_PRIME2v (lime_text_layout_set_language);
	DEFINE_PRIME2v (lime_text_layout_set_script);
	DEFINE_PRIME2v (lime_touch_event_manager_register);
	DEFINE_PRIME1v (lime_window_close);
	DEFINE_PRIME5 (lime_window_create);
	DEFINE_PRIME2v (lime_window_event_manager_register);
	DEFINE_PRIME1v (lime_window_focus);
	DEFINE_PRIME1 (lime_window_get_enable_text_events);
	DEFINE_PRIME1 (lime_window_get_height);
	DEFINE_PRIME1 (lime_window_get_id);
	DEFINE_PRIME1 (lime_window_get_width);
	DEFINE_PRIME1 (lime_window_get_x);
	DEFINE_PRIME1 (lime_window_get_y);
	DEFINE_PRIME3v (lime_window_move);
	DEFINE_PRIME3v (lime_window_resize);
	DEFINE_PRIME2v (lime_window_set_enable_text_events);
	DEFINE_PRIME2 (lime_window_set_fullscreen);
	DEFINE_PRIME2v (lime_window_set_icon);
	DEFINE_PRIME2 (lime_window_set_minimized);
	DEFINE_PRIME2 (lime_window_set_title);
	
	
}


extern "C" int lime_register_prims () {
	
	return 0;
	
}