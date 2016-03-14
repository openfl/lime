#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif


#include <hx/CFFIPrimePatch.h>
//#include <hx/CFFIPrime.h>
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
#include <system/CFFIPointer.h>
#include <system/Clipboard.h>
#include <system/JNI.h>
#include <system/SensorEvent.h>
#include <system/System.h>
#include <text/Font.h>
#include <text/TextLayout.h>
#include <ui/DropEvent.h>
#include <ui/FileDialog.h>
#include <ui/Gamepad.h>
#include <ui/GamepadEvent.h>
#include <ui/Joystick.h>
#include <ui/JoystickEvent.h>
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

DEFINE_KIND (k_finalizer);


namespace lime {
	
	
	void gc_application (value handle) {
		
		Application* application = (Application*)val_data (handle);
		delete application;
		
	}
	
	
	void gc_font (value handle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (handle);
		delete font;
		#endif
		
	}
	
	
	void gc_renderer (value handle) {
		
		Renderer* renderer = (Renderer*)val_data (handle);
		delete renderer;
		
	}
	
	
	void gc_text_layout (value handle) {
		
		#ifdef LIME_HARFBUZZ
		TextLayout *text = (TextLayout*)val_data (handle);
		delete text;
		#endif
		
	}
	
	
	void gc_window (value handle) {
		
		Window* window = (Window*)val_data (handle);
		delete window;
		
	}
	
	
	value lime_application_create (value callback) {
		
		Application* application = CreateApplication ();
		Application::callback = new AutoGCRoot (callback);
		return CFFIPointer (application, gc_application);
		
	}
	
	
	void lime_application_event_manager_register (value callback, value eventObject) {
		
		ApplicationEvent::callback = new AutoGCRoot (callback);
		ApplicationEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	int lime_application_exec (value application) {
		
		Application* app = (Application*)val_data (application);
		return app->Exec ();
		
	}
	
	
	void lime_application_init (value application) {
		
		Application* app = (Application*)val_data (application);
		app->Init ();
		
	}
	
	
	int lime_application_quit (value application) {
		
		Application* app = (Application*)val_data (application);
		return app->Quit ();
		
	}
	
	
	void lime_application_set_frame_rate (value application, double frameRate) {
		
		Application* app = (Application*)val_data (application);
		app->SetFrameRate (frameRate);
		
	}
	
	
	bool lime_application_update (value application) {
		
		Application* app = (Application*)val_data (application);
		return app->Update ();
		
	}
	
	
	value lime_audio_load (value data) {
		
		AudioBuffer audioBuffer;
		Resource resource;
		Bytes bytes;
		
		if (val_is_string (data)) {
			
			resource = Resource (val_string (data));
			
		} else {
			
			bytes = Bytes (data);
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
	
	
	value lime_bytes_from_data_pointer (double data, int length) {
		
		intptr_t ptr = (intptr_t)data;
		Bytes bytes = Bytes (length);
		
		if (ptr) {
			
			memcpy (bytes.Data (), (const void*)ptr, length);
			
		}
		
		return bytes.Value ();
		
	}
	
	
	double lime_bytes_get_data_pointer (value bytes) {
		
		Bytes data = Bytes (bytes);
		return (intptr_t)data.Data ();
		
	}
	
	
	value lime_bytes_read_file (HxString path) {
		
		Bytes data = Bytes (path.__s);
		return data.Value ();
		
	}
	
	
	double lime_cffi_get_native_pointer (value handle) {
		
		return (intptr_t)val_data (handle);
		
	}
	
	
	void lime_cffi_finalizer (value abstract) {
		
		val_call0 ((value)val_data (abstract));
		
	}
	
	
	value lime_cffi_set_finalizer (value callback) {
		
		value abstract = alloc_abstract (k_finalizer, callback);
		val_gc (abstract, lime_cffi_finalizer);
		return abstract;
		
	}
	
	
	value lime_clipboard_get_text () {
		
		if (Clipboard::HasText ()) {
			
			const char* text = Clipboard::GetText ();
			value _text = alloc_string (text);
			
			// TODO: Should we free for all backends? (SDL requires it)
			
			free ((char*)text);
			return _text;
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	void lime_clipboard_set_text (HxString text) {
		
		Clipboard::SetText (text.__s);
		
	}
	
	
	void lime_drop_event_manager_register (value callback, value eventObject) {
		
		DropEvent::callback = new AutoGCRoot (callback);
		DropEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	value lime_file_dialog_open_directory (HxString filter, HxString defaultPath) {
		
		#ifdef LIME_NFD
		const char* path = FileDialog::OpenDirectory (filter.__s, defaultPath.__s);
		
		if (path) {
			
			value _path = alloc_string (path);
			free ((char*) path);
			return _path;
			
		} else {
			
			return alloc_null ();
			
		}
		#endif
		
		return 0;
		
	}
	
	value lime_file_dialog_open_file (HxString filter, HxString defaultPath) {
		
		#ifdef LIME_NFD
		const char* path = FileDialog::OpenFile (filter.__s, defaultPath.__s);
		
		if (path) {
			
			value _path = alloc_string (path);
			free ((char*) path);
			return _path;
			
		} else {
			
			return alloc_null ();
			
		}
		#endif
		
		return 0;
		
	}
	
	
	value lime_file_dialog_open_files (HxString filter, HxString defaultPath) {
		
		#ifdef LIME_NFD
		std::vector<const char*> files;
		
		FileDialog::OpenFiles (&files, filter.__s, defaultPath.__s);
		value result = alloc_array (files.size ());
		
		for (int i = 0; i < files.size (); i++) {
			
			val_array_set_i (result, i, alloc_string (files[i]));
			free ((char*)files[i]);
			
		}
		#else
		value result = alloc_array (0);
		#endif
		
		return result;
		
	}
	
	
	value lime_file_dialog_save_file (HxString filter, HxString defaultPath) {
		
		#ifdef LIME_NFD
		const char* path = FileDialog::SaveFile (filter.__s, defaultPath.__s);
		
		if (path) {
			
			value _path = alloc_string (path);
			free ((char*) path);
			return _path;
			
		} else {
			
			return alloc_null ();
			
		}
		#endif
		
		return 0;
		
	}
	
	
	int lime_font_get_ascender (value fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetAscender ();
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_descender (value fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetDescender ();
		#else
		return 0;
		#endif
		
	}
	
	
	value lime_font_get_family_name (value fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		wchar_t *name = font->GetFamilyName ();
		value result = alloc_wstring (name);
		delete name;
		return result;
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_glyph_index (value fontHandle, HxString character) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetGlyphIndex ((char*)character.__s);
		#else
		return -1;
		#endif
		
	}
	
	
	value lime_font_get_glyph_indices (value fontHandle, HxString characters) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetGlyphIndices ((char*)characters.__s);
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	value lime_font_get_glyph_metrics (value fontHandle, int index) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetGlyphMetrics (index);
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	int lime_font_get_height (value fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetHeight ();
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_num_glyphs (value fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetNumGlyphs ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	int lime_font_get_underline_position (value fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetUnderlinePosition ();
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_underline_thickness (value fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetUnderlineThickness ();
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_units_per_em (value fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetUnitsPerEM ();
		#else
		return 0;
		#endif
		
	}
	
	
	value lime_font_load (value data) {
		
		#ifdef LIME_FREETYPE
		Resource resource;
		Bytes bytes;
		
		if (val_is_string (data)) {
			
			resource = Resource (val_string (data));
			
		} else {
			
			bytes.Set (data);
			resource = Resource (&bytes);
			
		}
		
		Font *font = new Font (&resource, 0);
		
		if (font) {
			
			if (font->face) {
				
				return CFFIPointer (font, gc_font);
				
			} else {
				
				delete font;
				
			}
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	value lime_font_outline_decompose (value fontHandle, int size) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->Decompose (size);
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	bool lime_font_render_glyph (value fontHandle, int index, value data) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		Bytes bytes = Bytes (data);
		return font->RenderGlyph (index, &bytes);
		#else
		return false;
		#endif
		
	}
	
	
	bool lime_font_render_glyphs (value fontHandle, value indices, value data) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		Bytes bytes = Bytes (data);
		return font->RenderGlyphs (indices, &bytes);
		#else
		return false;
		#endif
		
	}
	
	
	void lime_font_set_size (value fontHandle, int fontSize) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
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
	
	
	value lime_gamepad_get_device_guid (int id) {
		
		const char* guid = Gamepad::GetDeviceGUID (id);
		return guid ? alloc_string (guid) : alloc_null ();
		
	}
	
	
	value lime_gamepad_get_device_name (int id) {
		
		const char* name = Gamepad::GetDeviceName (id);
		return name ? alloc_string (name) : alloc_null ();
		
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
		Bytes bytes;
		
		if (val_is_string (data)) {
			
			resource = Resource (val_string (data));
			
		} else {
			
			bytes.Set (data);
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
	
	int lime_image_data_util_threshold (value image, value sourceImage, value sourceRect, value destPoint, int operation, int thresholdRG, int thresholdBA, int colorRG, int colorBA, int maskRG, int maskBA, bool copySource) {
		
		Image _image = Image (image);
		Image _sourceImage = Image (sourceImage);
		Rectangle _sourceRect = Rectangle (sourceRect);
		Vector2 _destPoint = Vector2 (destPoint);
		int32_t threshold = (thresholdRG << 16) | thresholdBA;
		int32_t color = (colorRG << 16) | colorBA;
		int32_t mask = (maskRG << 16) | maskBA;
		return ImageDataUtil::Threshold (&_image, &_sourceImage, &_sourceRect, &_destPoint, operation, threshold, color, mask, copySource);
		
	}
	
	void lime_image_data_util_unmultiply_alpha (value image) {
		
		Image _image = Image (image);
		ImageDataUtil::UnmultiplyAlpha (&_image);
		
	}
	
	
	double lime_jni_getenv () {
		
		#ifdef ANDROID
		return (intptr_t)JNI::GetEnv ();
		#else
		return 0;
		#endif
		
	}
	
	
	void lime_joystick_event_manager_register (value callback, value eventObject) {
		
		JoystickEvent::callback = new AutoGCRoot (callback);
		JoystickEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	value lime_joystick_get_device_guid (int id) {
		
		const char* guid = Joystick::GetDeviceGUID (id);
		return guid ? alloc_string (guid) : alloc_null ();
		
	}
	
	
	value lime_joystick_get_device_name (int id) {
		
		const char* name = Joystick::GetDeviceName (id);
		return name ? alloc_string (name) : alloc_null ();
		
	}
	
	
	int lime_joystick_get_num_axes (int id) {
		
		return Joystick::GetNumAxes (id);
		
	}
	
	
	int lime_joystick_get_num_buttons (int id) {
		
		return Joystick::GetNumButtons (id);
		
	}
	
	
	int lime_joystick_get_num_hats (int id) {
		
		return Joystick::GetNumHats (id);
		
	}
	
	
	int lime_joystick_get_num_trackballs (int id) {
		
		return Joystick::GetNumTrackballs (id);
		
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
	
	
	value lime_jpeg_decode_file (HxString path, bool decodeData) {
		
		ImageBuffer imageBuffer;
		Resource resource = Resource (path.__s);
		
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
	
	
	void lime_mouse_warp (int x, int y, value window) {
		
		Window* windowRef = 0;
		
		if (window) {
			
			windowRef = (Window*)val_data (window);
			
		}
		
		Mouse::Warp (x, y, windowRef);
		
	}
	
	
	void lime_neko_execute (HxString module) {
		
		#ifdef LIME_NEKO
		NekoVM::Execute (module.__s);
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
	
	
	value lime_png_decode_file (HxString path, bool decodeData) {
		
		ImageBuffer imageBuffer;
		Resource resource = Resource (path.__s);
		
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
	
	
	value lime_renderer_create (value window) {
		
		Renderer* renderer = CreateRenderer ((Window*)val_data (window));
		return CFFIPointer (renderer, gc_renderer);
		
	}
	
	
	void lime_renderer_flip (value renderer) {
		
		((Renderer*)val_data (renderer))->Flip ();
		
	}
	
	
	double lime_renderer_get_context (value renderer) {
		
		Renderer* targetRenderer = (Renderer*)val_data (renderer);
		return (intptr_t)targetRenderer->GetContext ();
		
	}
	
	
	double lime_renderer_get_scale (value renderer) {
		
		Renderer* targetRenderer = (Renderer*)val_data (renderer);
		return targetRenderer->GetScale ();
		
	}
	
	
	value lime_renderer_get_type (value renderer) {
		
		Renderer* targetRenderer = (Renderer*)val_data (renderer);
		const char* type = targetRenderer->Type ();
		return type ? alloc_string (type) : alloc_null ();
		
	}
	
	
	value lime_renderer_lock (value renderer) {
		
		return ((Renderer*)val_data (renderer))->Lock ();
		
	}
	
	
	void lime_renderer_make_current (value renderer) {
		
		((Renderer*)val_data (renderer))->MakeCurrent ();
		
	}
	
	
	value lime_renderer_read_pixels (value renderer, value rect) {
		
		Renderer* targetRenderer = (Renderer*)val_data (renderer);
		ImageBuffer buffer;
		
		if (!val_is_null (rect)) {
			
			Rectangle _rect = Rectangle (rect);
			targetRenderer->ReadPixels (&buffer, &_rect);
			
		} else {
			
			targetRenderer->ReadPixels (&buffer, NULL);
			
		}
		
		return buffer.Value ();
		
	}
	
	
	void lime_renderer_unlock (value renderer) {
		
		((Renderer*)val_data (renderer))->Unlock ();
		
	}
	
	
	void lime_sensor_event_manager_register (value callback, value eventObject) {
		
		SensorEvent::callback = new AutoGCRoot (callback);
		SensorEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	bool lime_system_get_allow_screen_timeout () {
		
		return System::GetAllowScreenTimeout ();
		
	}
	
	
	value lime_system_get_directory (int type, HxString company, HxString title) {
		
		const char* path = System::GetDirectory ((SystemDirectory)type, company.__s, title.__s);
		
		if (path) {
			
			value _path = alloc_string (path);
			free ((char*) path);
			return _path;
			
		} else {
			
			return alloc_null ();
			
		}
		
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
	
	
	bool lime_system_set_allow_screen_timeout (bool allow) {
		
		return System::SetAllowScreenTimeout (allow);
		
	}
	
	
	void lime_text_event_manager_register (value callback, value eventObject) {
		
		TextEvent::callback = new AutoGCRoot (callback);
		TextEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	value lime_text_layout_create (int direction, HxString script, HxString language) {
		
		#if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		
		TextLayout *text = new TextLayout (direction, script.__s, language.__s);
		return CFFIPointer (text, gc_text_layout);
		
		#else
		
		return alloc_null ();
		
		#endif
		
	}
	
	
	value lime_text_layout_position (value textHandle, value fontHandle, int size, HxString textString, value data) {
		
		#if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		
		TextLayout *text = (TextLayout*)val_data (textHandle);
		Font *font = (Font*)val_data (fontHandle);
		Bytes bytes = Bytes (data);
		text->Position (font, size, textString.__s, &bytes);
		return bytes.Value ();
		
		#endif
		
		return alloc_null ();
		
	}
	
	
	void lime_text_layout_set_direction (value textHandle, int direction) {
		
		#if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)val_data (textHandle);
		text->SetDirection (direction);
		#endif
		
	}
	
	
	void lime_text_layout_set_language (value textHandle, HxString language) {
		
		#if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)val_data (textHandle);
		text->SetLanguage (language.__s);
		#endif
		
	}
	
	
	void lime_text_layout_set_script (value textHandle, HxString script) {
		
		#if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)val_data (textHandle);
		text->SetScript (script.__s);
		#endif
		
	}
	
	
	void lime_touch_event_manager_register (value callback, value eventObject) {
		
		TouchEvent::callback = new AutoGCRoot (callback);
		TouchEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	void lime_window_alert (value window, HxString message, HxString title) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Alert (message.__s, title.__s);
		
	}
	
	
	void lime_window_close (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Close ();
		
	}
	
	
	value lime_window_create (value application, int width, int height, int flags, HxString title) {
		
		Window* window = CreateWindow ((Application*)val_data (application), width, height, flags, title.__s);
		return CFFIPointer (window, gc_window);
		
	}
	
	
	void lime_window_event_manager_register (value callback, value eventObject) {
		
		WindowEvent::callback = new AutoGCRoot (callback);
		WindowEvent::eventObject = new AutoGCRoot (eventObject);
		
	}
	
	
	void lime_window_focus (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Focus ();
		
	}
	
	
	int lime_window_get_display (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetDisplay ();
		
	}
	
	
	bool lime_window_get_enable_text_events (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetEnableTextEvents ();
		
	}
	
	
	int lime_window_get_height (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetHeight ();
		
	}
	
	
	int32_t lime_window_get_id (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return (int32_t)targetWindow->GetID ();
		
	}
	
	
	int lime_window_get_width (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetWidth ();
		
	}
	
	
	int lime_window_get_x (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetX ();
		
	}
	
	
	int lime_window_get_y (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetY ();
		
	}
	
	
	void lime_window_move (value window, int x, int y) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Move (x, y);
		
	}
	
	
	void lime_window_resize (value window, int width, int height) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Resize (width, height);
		
	}
	
	
	bool lime_window_set_borderless (value window, bool borderless) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetBorderless (borderless);
		
	}
	
	
	void lime_window_set_enable_text_events (value window, bool enabled) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->SetEnableTextEvents (enabled);
		
	}
	
	
	bool lime_window_set_fullscreen (value window, bool fullscreen) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetFullscreen (fullscreen);
		
	}
	
	
	void lime_window_set_icon (value window, value buffer) {
		
		Window* targetWindow = (Window*)val_data (window);
		ImageBuffer imageBuffer = ImageBuffer (buffer);
		targetWindow->SetIcon (&imageBuffer);
		
	}
	
	
	bool lime_window_set_maximized (value window, bool maximized) {
		
		Window* targetWindow = (Window*)val_data(window);
		return targetWindow->SetMaximized (maximized);
		
	}
	
	
	bool lime_window_set_minimized (value window, bool minimized) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetMinimized (minimized);
		
	}
	
	
	bool lime_window_set_resizable (value window, bool resizable) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetResizable (resizable);
		
	}
	
	
	value lime_window_set_title (value window, HxString title) {
		
		Window* targetWindow = (Window*)val_data (window);
		const char* result = targetWindow->SetTitle (title.__s);
		
		if (result) {
			
			value _result = alloc_string (result);
			free ((char*) result);
			return _result;
			
		} else {
			
			return alloc_null ();
			
		}
		
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
	DEFINE_PRIME1 (lime_cffi_get_native_pointer);
	DEFINE_PRIME1 (lime_cffi_set_finalizer);
	DEFINE_PRIME0 (lime_clipboard_get_text);
	DEFINE_PRIME1v (lime_clipboard_set_text);
	DEFINE_PRIME2v (lime_drop_event_manager_register);
	DEFINE_PRIME2 (lime_file_dialog_open_directory);
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
	DEFINE_PRIME12 (lime_image_data_util_threshold);
	DEFINE_PRIME1v (lime_image_data_util_unmultiply_alpha);
	DEFINE_PRIME3 (lime_image_encode);
	DEFINE_PRIME1 (lime_image_load);
	DEFINE_PRIME0 (lime_jni_getenv);
	DEFINE_PRIME2v (lime_joystick_event_manager_register);
	DEFINE_PRIME1 (lime_joystick_get_device_guid);
	DEFINE_PRIME1 (lime_joystick_get_device_name);
	DEFINE_PRIME1 (lime_joystick_get_num_axes);
	DEFINE_PRIME1 (lime_joystick_get_num_buttons);
	DEFINE_PRIME1 (lime_joystick_get_num_hats);
	DEFINE_PRIME1 (lime_joystick_get_num_trackballs);
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
	DEFINE_PRIME1 (lime_renderer_get_scale);
	DEFINE_PRIME1 (lime_renderer_get_type);
	DEFINE_PRIME1 (lime_renderer_lock);
	DEFINE_PRIME1v (lime_renderer_make_current);
	DEFINE_PRIME2 (lime_renderer_read_pixels);
	DEFINE_PRIME1v (lime_renderer_unlock);
	DEFINE_PRIME2v (lime_render_event_manager_register);
	DEFINE_PRIME2v (lime_sensor_event_manager_register);
	DEFINE_PRIME0 (lime_system_get_allow_screen_timeout);
	DEFINE_PRIME3 (lime_system_get_directory);
	DEFINE_PRIME1 (lime_system_get_display);
	DEFINE_PRIME0 (lime_system_get_num_displays);
	DEFINE_PRIME0 (lime_system_get_timer);
	DEFINE_PRIME1 (lime_system_set_allow_screen_timeout);
	DEFINE_PRIME2v (lime_text_event_manager_register);
	DEFINE_PRIME3 (lime_text_layout_create);
	DEFINE_PRIME5 (lime_text_layout_position);
	DEFINE_PRIME2v (lime_text_layout_set_direction);
	DEFINE_PRIME2v (lime_text_layout_set_language);
	DEFINE_PRIME2v (lime_text_layout_set_script);
	DEFINE_PRIME2v (lime_touch_event_manager_register);
	DEFINE_PRIME3v (lime_window_alert);
	DEFINE_PRIME1v (lime_window_close);
	DEFINE_PRIME5 (lime_window_create);
	DEFINE_PRIME2v (lime_window_event_manager_register);
	DEFINE_PRIME1v (lime_window_focus);
	DEFINE_PRIME1 (lime_window_get_display);
	DEFINE_PRIME1 (lime_window_get_enable_text_events);
	DEFINE_PRIME1 (lime_window_get_height);
	DEFINE_PRIME1 (lime_window_get_id);
	DEFINE_PRIME1 (lime_window_get_width);
	DEFINE_PRIME1 (lime_window_get_x);
	DEFINE_PRIME1 (lime_window_get_y);
	DEFINE_PRIME3v (lime_window_move);
	DEFINE_PRIME3v (lime_window_resize);
	DEFINE_PRIME2 (lime_window_set_borderless);
	DEFINE_PRIME2v (lime_window_set_enable_text_events);
	DEFINE_PRIME2 (lime_window_set_fullscreen);
	DEFINE_PRIME2v (lime_window_set_icon);
	DEFINE_PRIME2 (lime_window_set_maximized);
	DEFINE_PRIME2 (lime_window_set_minimized);
	DEFINE_PRIME2 (lime_window_set_resizable);
	DEFINE_PRIME2 (lime_window_set_title);
	
	
}


#ifdef LIME_CAIRO
extern "C" int lime_cairo_register_prims ();
#else
extern "C" int lime_cairo_register_prims () { return 0; }
#endif

#ifdef LIME_CURL
extern "C" int lime_curl_register_prims ();
#else
extern "C" int lime_curl_register_prims () { return 0; }
#endif

#ifdef LIME_OPENAL
extern "C" int lime_openal_register_prims ();
#else
extern "C" int lime_openal_register_prims () { return 0; }
#endif

#ifdef LIME_OPENGL
extern "C" int lime_opengl_register_prims ();
#else
extern "C" int lime_opengl_register_prims () { return 0; }
#endif


extern "C" int lime_register_prims () {
	
	lime_cairo_register_prims ();
	lime_curl_register_prims ();
	lime_openal_register_prims ();
	lime_opengl_register_prims ();
	
	return 0;
	
}
