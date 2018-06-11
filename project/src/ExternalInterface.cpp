#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif

#include <system/CFFI.h>

#include <app/Application.h>
#include <app/ApplicationEvent.h>
#include <graphics/format/JPEG.h>
#include <graphics/format/PNG.h>
#include <graphics/utils/ImageDataUtil.h>
#include <graphics/Image.h>
#include <graphics/ImageBuffer.h>
#include <graphics/Renderer.h>
#include <graphics/RenderEvent.h>
#include <media/containers/OGG.h>
#include <media/containers/WAV.h>
#include <media/AudioBuffer.h>
#include <system/CFFIPointer.h>
#include <system/Clipboard.h>
#include <system/ClipboardEvent.h>
#include <system/Endian.h>
#include <system/FileWatcher.h>
#include <system/JNI.h>
#include <system/Locale.h>
#include <system/SensorEvent.h>
#include <system/System.h>
#include <text/Font.h>
#include <text/TextLayout.h>
#include <ui/DropEvent.h>
#include <ui/FileDialog.h>
#include <ui/Gamepad.h>
#include <ui/GamepadEvent.h>
#include <ui/Haptic.h>
#include <ui/Joystick.h>
#include <ui/JoystickEvent.h>
#include <ui/KeyCode.h>
#include <ui/KeyEvent.h>
#include <ui/Mouse.h>
#include <ui/MouseCursor.h>
#include <ui/MouseEvent.h>
#include <ui/TextEvent.h>
#include <ui/TouchEvent.h>
#include <ui/Window.h>
#include <ui/WindowEvent.h>
#include <utils/compress/LZMA.h>
#include <utils/compress/Zlib.h>
#include <utils/String.h>
#include <vm/NekoVM.h>

DEFINE_KIND (k_finalizer);


namespace lime {
	
	
	void gc_application (value handle) {
		
		Application* application = (Application*)val_data (handle);
		delete application;
		
	}
	
	
	void hl_gc_application (HL_CFFIPointer* handle) {
		
		Application* application = (Application*)handle->ptr;
		delete application;
		
	}
	
	
	void gc_file_watcher (value handle) {
		
		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)val_data (handle);
		delete watcher;
		#endif
		
	}
	
	
	void hl_gc_file_watcher (HL_CFFIPointer* handle) {
		
		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)handle->ptr;
		delete watcher;
		#endif
		
	}
	
	
	void gc_font (value handle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (handle);
		delete font;
		#endif
		
	}
	
	
	void hl_gc_font (HL_CFFIPointer* handle) {
		
		#ifdef LIME_FREETYPE
		Font* font = (Font*)handle->ptr;
		delete font;
		#endif
		
	}
	
	
	void gc_renderer (value handle) {
		
		Renderer* renderer = (Renderer*)val_data (handle);
		delete renderer;
		
	}
	
	
	void hl_gc_renderer (HL_CFFIPointer* handle) {
		
		Renderer* renderer = (Renderer*)handle->ptr;
		delete renderer;
		
	}
	
	
	void gc_text_layout (value handle) {
		
		#ifdef LIME_HARFBUZZ
		TextLayout *text = (TextLayout*)val_data (handle);
		delete text;
		#endif
		
	}
	
	
	void hl_gc_text_layout (HL_CFFIPointer* handle) {
		
		#ifdef LIME_HARFBUZZ
		TextLayout* text = (TextLayout*)handle->ptr;
		delete text;
		#endif
		
	}
	
	
	void gc_window (value handle) {
		
		Window* window = (Window*)val_data (handle);
		delete window;
		
	}
	
	
	void hl_gc_window (HL_CFFIPointer* handle) {
		
		Window* window = (Window*)handle->ptr;
		delete window;
		
	}
	
	
	std::wstring* hxstring_to_wstring (HxString val) {
		
		if (val.c_str ()) {
			
			std::string _val = std::string (val.c_str ());
			return new std::wstring (_val.begin (), _val.end ());
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	value lime_application_create () {
		
		Application* application = CreateApplication ();
		return CFFIPointer (application, gc_application);
		
	}
	
	
	HL_PRIM HL_CFFIPointer* hl_lime_application_create () {
		
		Application* application = CreateApplication ();
		return HLCFFIPointer (application, (hl_finalizer)hl_gc_application);
		
	}
	
	
	void lime_application_event_manager_register (value callback, value eventObject) {
		
		ApplicationEvent::callback = new ValuePointer (callback);
		ApplicationEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_application_event_manager_register (vclosure* callback, HL_ApplicationEvent* eventObject) {
		
		ApplicationEvent::callback = new ValuePointer (callback);
		ApplicationEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	int lime_application_exec (value application) {
		
		Application* app = (Application*)val_data (application);
		return app->Exec ();
		
	}
	
	
	HL_PRIM int hl_lime_application_exec (HL_CFFIPointer* application) {
		
		Application* app = (Application*)application->ptr;
		return app->Exec ();
		
	}
	
	
	void lime_application_init (value application) {
		
		Application* app = (Application*)val_data (application);
		app->Init ();
		
	}
	
	
	HL_PRIM void hl_lime_application_init (HL_CFFIPointer* application) {
		
		Application* app = (Application*)application->ptr;
		app->Init ();
		
	}
	
	
	int lime_application_quit (value application) {
		
		Application* app = (Application*)val_data (application);
		return app->Quit ();
		
	}
	
	
	HL_PRIM int hl_lime_application_quit (HL_CFFIPointer* application) {
		
		Application* app = (Application*)application->ptr;
		return app->Quit ();
		
	}
	
	
	void lime_application_set_frame_rate (value application, double frameRate) {
		
		Application* app = (Application*)val_data (application);
		app->SetFrameRate (frameRate);
		
	}
	
	
	HL_PRIM void hl_lime_application_set_frame_rate (HL_CFFIPointer* application, double frameRate) {
		
		Application* app = (Application*)application->ptr;
		app->SetFrameRate (frameRate);
		
	}
	
	
	bool lime_application_update (value application) {
		
		Application* app = (Application*)val_data (application);
		return app->Update ();
		
	}
	
	
	HL_PRIM bool hl_lime_application_update (HL_CFFIPointer* application) {
		
		Application* app = (Application*)application->ptr;
		return app->Update ();
		
	}
	
	
	value lime_audio_load_bytes (value data, value buffer) {
		
		Resource resource;
		Bytes bytes;
		
		AudioBuffer audioBuffer = AudioBuffer (buffer);
		
		bytes.Set (data);
		resource = Resource (&bytes);
		
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
	
	
	HL_PRIM vdynamic* hl_lime_audio_load_bytes (HL_Bytes* data, HL_AudioBuffer* buffer) {
		
		// Resource resource;
		// Bytes bytes;
		
		// AudioBuffer audioBuffer = AudioBuffer (buffer);
		
		// bytes.Set (data);
		// resource = Resource (&bytes);
		
		// if (WAV::Decode (&resource, &audioBuffer)) {
			
		// 	return audioBuffer.Value ();
			
		// }
		
		// #ifdef LIME_OGG
		// if (OGG::Decode (&resource, &audioBuffer)) {
			
		// 	return audioBuffer.Value ();
			
		// }
		// #endif
		
		return 0;
		
	}
	
	
	value lime_audio_load_file (value data, value buffer) {
		
		Resource resource;
		Bytes bytes;
		
		AudioBuffer audioBuffer = AudioBuffer (buffer);
		
		resource = Resource (val_string (data));
		
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
	
	
	HL_PRIM vdynamic* hl_lime_audio_load_file (vbyte* data, HL_AudioBuffer* buffer) {
		
		// Resource resource;
		// Bytes bytes;
		
		// AudioBuffer audioBuffer = AudioBuffer (buffer);
		
		// resource = Resource (val_string (data));
		
		// if (WAV::Decode (&resource, &audioBuffer)) {
			
		// 	return audioBuffer.Value ();
			
		// }
		
		// #ifdef LIME_OGG
		// if (OGG::Decode (&resource, &audioBuffer)) {
			
		// 	return audioBuffer.Value ();
			
		// }
		// #endif
		
		return 0;
		
	}
	
	
	value lime_audio_load (value data, value buffer) {
		
		if (val_is_string (data)) {
			
			return lime_audio_load_file (data, buffer);
			
		} else {
			
			return lime_audio_load_bytes (data, buffer);
			
		}
		
	}
	
	
	value lime_bytes_from_data_pointer (double data, int length) {
		
		uintptr_t ptr = (uintptr_t)data;
		Bytes bytes (length);
		
		if (ptr) {
			
			memcpy (bytes.Data (), (const void*)ptr, length);
			
		}
		
		return bytes.Value ();
		
	}
	
	
	double lime_bytes_get_data_pointer (value bytes) {
		
		Bytes data = Bytes (bytes);
		return (uintptr_t)data.Data ();
		
	}
	
	
	HL_PRIM double hl_lime_bytes_get_data_pointer (HL_Bytes* bytes) {
		
		return bytes ? (uintptr_t)bytes->b : 0;
		
	}
	
	
	double lime_bytes_get_data_pointer_offset (value bytes, int offset) {
		
		Bytes data = Bytes (bytes);
		return (uintptr_t)data.Data () + offset;
		
	}
	
	
	value lime_bytes_read_file (HxString path, value bytes) {
		
		Bytes data (bytes);
		data.ReadFile (path.c_str ());
		return data.Value ();
		
	}
	
	
	double lime_cffi_get_native_pointer (value handle) {
		
		return (uintptr_t)val_data (handle);
		
	}
	
	
	void lime_cffi_finalizer (value abstract) {
		
		val_call0 ((value)val_data (abstract));
		
	}
	
	
	value lime_cffi_set_finalizer (value callback) {
		
		value abstract = alloc_abstract (k_finalizer, callback);
		val_gc (abstract, lime_cffi_finalizer);
		return abstract;
		
	}
	
	
	void lime_clipboard_event_manager_register (value callback, value eventObject) {
		
		ClipboardEvent::callback = new ValuePointer (callback);
		ClipboardEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_clipboard_event_manager_register (vclosure* callback, HL_ClipboardEvent* eventObject) {
		
		ClipboardEvent::callback = new ValuePointer (callback);
		ClipboardEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
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
	
	
	HL_PRIM vbyte* hl_lime_clipboard_get_text () {
		
		if (Clipboard::HasText ()) {
			
			const char* text = Clipboard::GetText ();
			// char* _text = malloc (strlen (text) + 1);
			// strpy (text, _text);
			
			// // TODO: Should we free for all backends? (SDL requires it)
			
			// free ((char*)text);
			return (vbyte*)text;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	void lime_clipboard_set_text (HxString text) {
		
		Clipboard::SetText (text.c_str ());
		
	}
	
	
	HL_PRIM void hl_lime_clipboard_set_text (vbyte* text) {
		
		Clipboard::SetText ((const char*)text);
		
	}
	
	
	double lime_data_pointer_offset (double pointer, int offset) {
		
		return (uintptr_t)pointer + offset;
		
	}
	
	
	value lime_deflate_compress (value buffer, value bytes) {
		
		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);
		
		Zlib::Compress (DEFLATE, &data, &result);
		
		return result.Value ();
		#else
		return alloc_null();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_deflate_compress (HL_Bytes* buffer, HL_Bytes* bytes) {
		
		// #ifdef LIME_ZLIB
		// Bytes data (buffer);
		// Bytes result (bytes);
		
		// Zlib::Compress (DEFLATE, &data, &result);
		
		// return result.Value ();
		// #else
		// return alloc_null();
		// #endif
		return 0;
		
	}
	
	
	value lime_deflate_decompress (value buffer, value bytes) {
		
		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);
		
		Zlib::Decompress (DEFLATE, &data, &result);
		
		return result.Value ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_deflate_decompress (HL_Bytes* buffer, HL_Bytes* bytes) {
		
		// #ifdef LIME_ZLIB
		// Bytes data (buffer);
		// Bytes result (bytes);
		
		// Zlib::Decompress (DEFLATE, &data, &result);
		
		// return result.Value ();
		// #else
		// return alloc_null ();
		// #endif
		return 0;
		
	}
	
	
	void lime_drop_event_manager_register (value callback, value eventObject) {
		
		DropEvent::callback = new ValuePointer (callback);
		DropEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_drop_event_manager_register (vclosure* callback, HL_DropEvent* eventObject) {
		
		DropEvent::callback = new ValuePointer (callback);
		DropEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	value lime_file_dialog_open_directory (HxString title, HxString filter, HxString defaultPath) {
		
		#ifdef LIME_TINYFILEDIALOGS
		
		std::wstring* _title = hxstring_to_wstring (title);
		std::wstring* _filter = hxstring_to_wstring (filter);
		std::wstring* _defaultPath = hxstring_to_wstring (defaultPath);
		
		std::wstring* path = FileDialog::OpenDirectory (_title, _filter, _defaultPath);
		
		if (_title) delete _title;
		if (_filter) delete _filter;
		if (_defaultPath) delete _defaultPath;
		
		if (path) {
			
			value _path = alloc_wstring (path->c_str ());
			delete path;
			return _path;
			
		} else {
			
			delete path;
			return alloc_null ();
			
		}
		
		#endif
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vbyte* hl_lime_file_dialog_open_directory (vbyte* title, vbyte* filter, vbyte* defaultPath) {
		
		// #ifdef LIME_TINYFILEDIALOGS
		
		// std::wstring* _title = hxstring_to_wstring (title);
		// std::wstring* _filter = hxstring_to_wstring (filter);
		// std::wstring* _defaultPath = hxstring_to_wstring (defaultPath);
		
		// std::wstring* path = FileDialog::OpenDirectory (_title, _filter, _defaultPath);
		
		// if (_title) delete _title;
		// if (_filter) delete _filter;
		// if (_defaultPath) delete _defaultPath;
		
		// if (path) {
			
		// 	value _path = alloc_wstring (path->c_str ());
		// 	delete path;
		// 	return _path;
			
		// } else {
			
		// 	delete path;
		// 	return alloc_null ();
			
		// }
		
		// #endif
		
		return 0;
		
	}
	
	
	value lime_file_dialog_open_file (HxString title, HxString filter, HxString defaultPath) {
		
		#ifdef LIME_TINYFILEDIALOGS
		
		std::wstring* _title = hxstring_to_wstring (title);
		std::wstring* _filter = hxstring_to_wstring (filter);
		std::wstring* _defaultPath = hxstring_to_wstring (defaultPath);
		
		std::wstring* path = FileDialog::OpenFile (_title, _filter, _defaultPath);
		
		if (_title) delete _title;
		if (_filter) delete _filter;
		if (_defaultPath) delete _defaultPath;
		
		if (path) {
			
			value _path = alloc_wstring (path->c_str ());
			delete path;
			return _path;
			
		} else {
			
			delete path;
			return alloc_null ();
			
		}
		
		#endif
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vbyte* hl_lime_file_dialog_open_file (vbyte* title, vbyte* filter, vbyte* defaultPath) {
		
		// #ifdef LIME_TINYFILEDIALOGS
		
		// std::wstring* _title = hxstring_to_wstring (title);
		// std::wstring* _filter = hxstring_to_wstring (filter);
		// std::wstring* _defaultPath = hxstring_to_wstring (defaultPath);
		
		// std::wstring* path = FileDialog::OpenFile (_title, _filter, _defaultPath);
		
		// if (_title) delete _title;
		// if (_filter) delete _filter;
		// if (_defaultPath) delete _defaultPath;
		
		// if (path) {
			
		// 	value _path = alloc_wstring (path->c_str ());
		// 	delete path;
		// 	return _path;
			
		// } else {
			
		// 	delete path;
		// 	return alloc_null ();
			
		// }
		
		// #endif
		
		return 0;
		
	}
	
	
	value lime_file_dialog_open_files (HxString title, HxString filter, HxString defaultPath) {
		
		#ifdef LIME_TINYFILEDIALOGS
		
		std::wstring* _title = hxstring_to_wstring (title);
		std::wstring* _filter = hxstring_to_wstring (filter);
		std::wstring* _defaultPath = hxstring_to_wstring (defaultPath);
		
		std::vector<std::wstring*> files;
		
		FileDialog::OpenFiles (&files, _title, _filter, _defaultPath);
		value result = alloc_array (files.size ());
		
		if (_title) delete _title;
		if (_filter) delete _filter;
		if (_defaultPath) delete _defaultPath;
		
		for (int i = 0; i < files.size (); i++) {
			
			val_array_set_i (result, i, alloc_wstring (files[i]->c_str ()));
			delete files[i];
			
		}
		
		#else
		value result = alloc_array (0);
		#endif
		
		return result;
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_file_dialog_open_files (vbyte* title, vbyte* filter, vbyte* defaultPath) {
		
		// #ifdef LIME_TINYFILEDIALOGS
		
		// std::wstring* _title = hxstring_to_wstring (title);
		// std::wstring* _filter = hxstring_to_wstring (filter);
		// std::wstring* _defaultPath = hxstring_to_wstring (defaultPath);
		
		// std::vector<std::wstring*> files;
		
		// FileDialog::OpenFiles (&files, _title, _filter, _defaultPath);
		// value result = alloc_array (files.size ());
		
		// if (_title) delete _title;
		// if (_filter) delete _filter;
		// if (_defaultPath) delete _defaultPath;
		
		// for (int i = 0; i < files.size (); i++) {
			
		// 	val_array_set_i (result, i, alloc_wstring (files[i]->c_str ()));
		// 	delete files[i];
			
		// }
		
		// #else
		// value result = alloc_array (0);
		// #endif
		
		return 0;
		
	}
	
	
	value lime_file_dialog_save_file (HxString title, HxString filter, HxString defaultPath) {
		
		#ifdef LIME_TINYFILEDIALOGS
		
		std::wstring* _title = hxstring_to_wstring (title);
		std::wstring* _filter = hxstring_to_wstring (filter);
		std::wstring* _defaultPath = hxstring_to_wstring (defaultPath);
		
		std::wstring* path = FileDialog::SaveFile (_title, _filter, _defaultPath);
		
		if (_title) delete _title;
		if (_filter) delete _filter;
		if (_defaultPath) delete _defaultPath;
		
		if (path) {
			
			value _path = alloc_wstring (path->c_str ());
			delete path;
			return _path;
			
		} else {
			
			delete path;
			return alloc_null ();
			
		}
		
		#endif
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vbyte* hl_lime_file_dialog_save_file (vbyte* title, vbyte* filter, vbyte* defaultPath) {
		
		// #ifdef LIME_TINYFILEDIALOGS
		
		// std::wstring* _title = hxstring_to_wstring (title);
		// std::wstring* _filter = hxstring_to_wstring (filter);
		// std::wstring* _defaultPath = hxstring_to_wstring (defaultPath);
		
		// std::wstring* path = FileDialog::SaveFile (_title, _filter, _defaultPath);
		
		// if (_title) delete _title;
		// if (_filter) delete _filter;
		// if (_defaultPath) delete _defaultPath;
		
		// if (path) {
			
		// 	value _path = alloc_wstring (path->c_str ());
		// 	delete path;
		// 	return _path;
			
		// } else {
			
		// 	delete path;
		// 	return alloc_null ();
			
		// }
		
		// #endif
		
		return 0;
		
	}
	
	
	value lime_file_watcher_create (value callback) {
		
		#ifdef LIME_EFSW
		FileWatcher* watcher = new FileWatcher (callback);
		return CFFIPointer (watcher, gc_file_watcher);
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM HL_CFFIPointer* hl_lime_file_watcher_create (vclosure* callback) {
		
		// #ifdef LIME_EFSW
		// FileWatcher* watcher = new FileWatcher (callback);
		// return CFFIPointer (watcher, gc_file_watcher);
		// #else
		// return alloc_null ();
		// #endif
		return 0;
		
	}
	
	
	value lime_file_watcher_add_directory (value handle, value path, bool recursive) {
		
		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)val_data (handle);
		return alloc_int (watcher->AddDirectory (val_string (path), recursive));
		#else
		return alloc_int (0);
		#endif
		
	}
	
	
	HL_PRIM int hl_lime_file_watcher_add_directory (HL_CFFIPointer* handle, vbyte* path, bool recursive) {
		
		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)handle->ptr;
		return watcher->AddDirectory ((const char*)path, recursive);
		#else
		return 0;
		#endif
		
	}
	
	
	void lime_file_watcher_remove_directory (value handle, value watchID) {
		
		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)val_data (handle);
		watcher->RemoveDirectory (val_int (watchID));
		#endif
		
	}
	
	
	HL_PRIM void hl_lime_file_watcher_remove_directory (HL_CFFIPointer* handle, int watchID) {
		
		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)handle->ptr;
		watcher->RemoveDirectory (watchID);
		#endif
		
	}
	
	
	void lime_file_watcher_update (value handle) {
		
		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)val_data (handle);
		watcher->Update ();
		#endif
		
	}
	
	
	HL_PRIM void hl_lime_file_watcher_update (HL_CFFIPointer* handle) {
		
		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)handle->ptr;
		watcher->Update ();
		#endif
		
	}
	
	
	int lime_font_get_ascender (value fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetAscender ();
		#else
		return 0;
		#endif
		
	}
	
	
	HL_PRIM int hl_lime_font_get_ascender (HL_CFFIPointer* fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
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
	
	
	HL_PRIM int hl_lime_font_get_descender (HL_CFFIPointer* fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
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
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vbyte* hl_lime_font_get_family_name (HL_CFFIPointer* fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		wchar_t *name = font->GetFamilyName ();
		return (vbyte*)name;
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_font_get_glyph_index (value fontHandle, HxString character) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetGlyphIndex ((char*)character.c_str ());
		#else
		return -1;
		#endif
		
	}
	
	
	HL_PRIM int hl_lime_font_get_glyph_index (HL_CFFIPointer* fontHandle, vbyte* character) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetGlyphIndex ((char*)character);
		#else
		return -1;
		#endif
		
	}
	
	
	value lime_font_get_glyph_indices (value fontHandle, HxString characters) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetGlyphIndices ((char*)characters.c_str ());
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_font_get_glyph_indices (HL_CFFIPointer* fontHandle, vbyte* characters) {
		
		// #ifdef LIME_FREETYPE
		// Font *font = (Font*)fontHandle->ptr;
		// return font->GetGlyphIndices ((char*)characters);
		// #else
		return 0;
		// #endif
		
	}
	
	
	value lime_font_get_glyph_metrics (value fontHandle, int index) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetGlyphMetrics (index);
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_font_get_glyph_metrics (HL_CFFIPointer* fontHandle, int index) {
		
		// #ifdef LIME_FREETYPE
		// Font *font = (Font*)fontHandle->ptr;
		// return font->GetGlyphMetrics (index);
		// #else
		return 0;
		// #endif
		
	}
	
	
	int lime_font_get_height (value fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetHeight ();
		#else
		return 0;
		#endif
		
	}
	
	
	HL_PRIM int hl_lime_font_get_height (HL_CFFIPointer* fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
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
		return 0;
		#endif
		
	}
	
	
	HL_PRIM int hl_lime_font_get_num_glyphs (HL_CFFIPointer* fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetNumGlyphs ();
		#else
		return 0;
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
	
	
	HL_PRIM int hl_lime_font_get_underline_position (HL_CFFIPointer* fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
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
	
	
	HL_PRIM int hl_lime_font_get_underline_thickness (HL_CFFIPointer* fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
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
	
	
	HL_PRIM int hl_lime_font_get_units_per_em (HL_CFFIPointer* fontHandle) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetUnitsPerEM ();
		#else
		return 0;
		#endif
		
	}
	
	
	value lime_font_load_bytes (value data) {
		
		#ifdef LIME_FREETYPE
		Resource resource;
		Bytes bytes;
		
		bytes.Set (data);
		resource = Resource (&bytes);
		
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
	
	
	HL_PRIM HL_CFFIPointer* hl_lime_font_load_bytes (HL_Bytes* data) {
		
		// #ifdef LIME_FREETYPE
		// Resource resource;
		// Bytes bytes;
		
		// bytes.Set (data);
		// resource = Resource (&bytes);
		
		// Font *font = new Font (&resource, 0);
		
		// if (font) {
			
		// 	if (font->face) {
				
		// 		return CFFIPointer (font, gc_font);
				
		// 	} else {
				
		// 		delete font;
				
		// 	}
			
		// }
		// #endif
		
		return 0;
		
	}
	
	
	value lime_font_load_file (value data) {
		
		#ifdef LIME_FREETYPE
		Resource resource;
		Bytes bytes;
		
		resource = Resource (val_string (data));
		
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
	
	
	HL_PRIM HL_CFFIPointer* hl_lime_font_load_file (vbyte* data) {
		
		// #ifdef LIME_FREETYPE
		// Resource resource;
		// Bytes bytes;
		
		// resource = Resource (val_string (data));
		
		// Font *font = new Font (&resource, 0);
		
		// if (font) {
			
		// 	if (font->face) {
				
		// 		return CFFIPointer (font, gc_font);
				
		// 	} else {
				
		// 		delete font;
				
		// 	}
			
		// }
		// #endif
		
		return 0;
		
	}
	
	
	value lime_font_load (value data) {
		
		if (val_is_string (data)) {
			
			return lime_font_load_file (data);
			
		} else {
			
			return lime_font_load_bytes (data);
			
		}
		
	}
	
	
	value lime_font_outline_decompose (value fontHandle, int size) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->Decompose (size);
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_font_outline_decompose (HL_CFFIPointer* fontHandle, int size) {
		
		// #ifdef LIME_FREETYPE
		// Font *font = (Font*)fontHandle->ptr;
		// return font->Decompose (size);
		// #else
		return 0;
		// #endif
		
	}
	
	
	bool lime_font_render_glyph (value fontHandle, int index, value data) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		Bytes bytes (data);
		return font->RenderGlyph (index, &bytes);
		#else
		return false;
		#endif
		
	}
	
	
	HL_PRIM bool hl_lime_font_render_glyph (HL_CFFIPointer* fontHandle, int index, HL_Bytes* data) {
		
		// #ifdef LIME_FREETYPE
		// Font *font = (Font*)val_data (fontHandle);
		// Bytes bytes (data);
		// return font->RenderGlyph (index, &bytes);
		// #else
		return false;
		// #endif
		
	}
	
	
	bool lime_font_render_glyphs (value fontHandle, value indices, value data) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		Bytes bytes (data);
		return font->RenderGlyphs (indices, &bytes);
		#else
		return false;
		#endif
		
	}
	
	
	HL_PRIM bool hl_lime_font_render_glyphs (HL_CFFIPointer* fontHandle, vdynamic* indices, HL_Bytes* data) {
		
		// #ifdef LIME_FREETYPE
		// Font *font = (Font*)val_data (fontHandle);
		// Bytes bytes (data);
		// return font->RenderGlyphs (indices, &bytes);
		// #else
		return false;
		// #endif
		
	}
	
	
	void lime_font_set_size (value fontHandle, int fontSize) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		font->SetSize (fontSize);
		#endif
		
	}
	
	
	HL_PRIM void hl_lime_font_set_size (HL_CFFIPointer* fontHandle, int fontSize) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		font->SetSize (fontSize);
		#endif
		
	}
	
	
	void lime_gamepad_add_mappings (value mappings) {
		
		int length = val_array_size (mappings);
		
		for (int i = 0; i < length; i++) {
			
			Gamepad::AddMapping (val_string (val_array_i (mappings, i)));
			
		}
		
	}
	
	
	HL_PRIM void hl_lime_gamepad_add_mappings (vdynamic* mappings) {
		
		// int length = val_array_size (mappings);
		
		// for (int i = 0; i < length; i++) {
			
		// 	Gamepad::AddMapping (val_string (val_array_i (mappings, i)));
			
		// }
		
	}
	
	
	void lime_gamepad_event_manager_register (value callback, value eventObject) {
		
		GamepadEvent::callback = new ValuePointer (callback);
		GamepadEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_gamepad_event_manager_register (vclosure* callback, HL_GamepadEvent* eventObject) {
		
		GamepadEvent::callback = new ValuePointer (callback);
		GamepadEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	value lime_gamepad_get_device_guid (int id) {
		
		const char* guid = Gamepad::GetDeviceGUID (id);
		
		if (guid) {
			
			value result = alloc_string (guid);
			delete guid;
			return result;
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	HL_PRIM vbyte* hl_lime_gamepad_get_device_guid (int id) {
		
		const char* guid = Gamepad::GetDeviceGUID (id);
		
		if (guid) {
			
			// value result = alloc_string (guid);
			// delete guid;
			// return result;
			return (vbyte*)guid;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	value lime_gamepad_get_device_name (int id) {
		
		const char* name = Gamepad::GetDeviceName (id);
		return name ? alloc_string (name) : alloc_null ();
		
	}
	
	
	HL_PRIM vbyte* hl_lime_gamepad_get_device_name (int id) {
		
		return (vbyte*)Gamepad::GetDeviceName (id);
		
	}
	
	
	value lime_gzip_compress (value buffer, value bytes) {
		
		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);
		
		Zlib::Compress (GZIP, &data, &result);
		
		return result.Value ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_gzip_compress (HL_Bytes* buffer, HL_Bytes* bytes) {
		
		// #ifdef LIME_ZLIB
		// Bytes data (buffer);
		// Bytes result (bytes);
		
		// Zlib::Compress (GZIP, &data, &result);
		
		// return result.Value ();
		// #else
		return 0;
		// #endif
		
	}
	
	
	value lime_gzip_decompress (value buffer, value bytes) {
		
		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);
		
		Zlib::Decompress (GZIP, &data, &result);
		
		return result.Value ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_gzip_decompress (HL_Bytes* buffer, HL_Bytes* bytes) {
		
		// #ifdef LIME_ZLIB
		// Bytes data (buffer);
		// Bytes result (bytes);
		
		// Zlib::Decompress (GZIP, &data, &result);
		
		// return result.Value ();
		// #else
		return 0;
		// #endif
		
	}
	
	
	void lime_haptic_vibrate (int period, int duration) {
		
		#ifdef IPHONE
		Haptic::Vibrate (period, duration);
		#endif
		
	}
	
	
	HL_PRIM void hl_lime_haptic_vibrate (int period, int duration) {
		
		#ifdef IPHONE
		Haptic::Vibrate (period, duration);
		#endif
		
	}
	
	
	value lime_image_encode (value buffer, int type, int quality, value bytes) {
		
		ImageBuffer imageBuffer = ImageBuffer (buffer);
		Bytes data = Bytes (bytes);
		
		switch (type) {
			
			case 0: 
				
				#ifdef LIME_PNG
				if (PNG::Encode (&imageBuffer, &data)) {
					
					return data.Value ();
					
				}
				#endif
				break;
			
			case 1:
				
				#ifdef LIME_JPEG
				if (JPEG::Encode (&imageBuffer, &data, quality)) {
					
					return data.Value ();
					
				}
				#endif
				break;
			
			default: break;
			
		}
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_image_encode (HL_ImageBuffer* buffer, int type, int quality, HL_Bytes* bytes) {
		
		// ImageBuffer imageBuffer = ImageBuffer (buffer);
		// Bytes data = Bytes (bytes);
		
		// switch (type) {
			
		// 	case 0: 
				
		// 		#ifdef LIME_PNG
		// 		if (PNG::Encode (&imageBuffer, &data)) {
					
		// 			return data.Value ();
					
		// 		}
		// 		#endif
		// 		break;
			
		// 	case 1:
				
		// 		#ifdef LIME_JPEG
		// 		if (JPEG::Encode (&imageBuffer, &data, quality)) {
					
		// 			return data.Value ();
					
		// 		}
		// 		#endif
		// 		break;
			
		// 	default: break;
			
		// }
		
		return 0;
		
	}
	
	
	value lime_image_load_bytes (value data, value buffer) {
		
		Resource resource;
		Bytes bytes;
		
		ImageBuffer imageBuffer = ImageBuffer (buffer);
		
		bytes.Set (data);
		resource = Resource (&bytes);
		
		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &imageBuffer)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &imageBuffer)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_image_load_bytes (HL_Bytes* data, HL_ImageBuffer* buffer) {
		
		// Resource resource;
		// Bytes bytes;
		
		// ImageBuffer imageBuffer = ImageBuffer (buffer);
		
		// bytes.Set (data);
		// resource = Resource (&bytes);
		
		// #ifdef LIME_PNG
		// if (PNG::Decode (&resource, &imageBuffer)) {
			
		// 	return imageBuffer.Value ();
			
		// }
		// #endif
		
		// #ifdef LIME_JPEG
		// if (JPEG::Decode (&resource, &imageBuffer)) {
			
		// 	return imageBuffer.Value ();
			
		// }
		// #endif
		
		return 0;
		
	}
	
	
	value lime_image_load_file (value data, value buffer) {
		
		Resource resource;
		Bytes bytes;
		
		ImageBuffer imageBuffer = ImageBuffer (buffer);
		
		resource = Resource (val_string (data));
		
		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &imageBuffer)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &imageBuffer)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_image_load_file (vbyte* data, HL_ImageBuffer* buffer) {
		
		// Resource resource;
		// Bytes bytes;
		
		// ImageBuffer imageBuffer = ImageBuffer (buffer);
		
		// resource = Resource (val_string (data));
		
		// #ifdef LIME_PNG
		// if (PNG::Decode (&resource, &imageBuffer)) {
			
		// 	return imageBuffer.Value ();
			
		// }
		// #endif
		
		// #ifdef LIME_JPEG
		// if (JPEG::Decode (&resource, &imageBuffer)) {
			
		// 	return imageBuffer.Value ();
			
		// }
		// #endif
		
		return 0;
		
	}
	
	
	value lime_image_load (value data, value buffer) {
		
		if (val_is_string (data)) {
			
			return lime_image_load_file (data, buffer);
			
		} else {
			
			return lime_image_load_bytes (data, buffer);
			
		}
		
	}
	
	
	void lime_image_data_util_color_transform (value image, value rect, value colorMatrix) {
		
		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		ColorMatrix _colorMatrix = ColorMatrix (colorMatrix);
		ImageDataUtil::ColorTransform (&_image, &_rect, &_colorMatrix);
		
	}
	
	
	HL_PRIM void hl_lime_image_data_util_color_transform (HL_Image* image, HL_Rectangle* rect, HL_ArrayBufferView* colorMatrix) {
		
		// Image _image = Image (image);
		// Rectangle _rect = Rectangle (rect);
		// ColorMatrix _colorMatrix = ColorMatrix (colorMatrix);
		// ImageDataUtil::ColorTransform (&_image, &_rect, &_colorMatrix);
		
	}
	
	
	void lime_image_data_util_copy_channel (value image, value sourceImage, value sourceRect, value destPoint, int srcChannel, int destChannel) {
		
		Image _image = Image (image);
		Image _sourceImage = Image (sourceImage);
		Rectangle _sourceRect = Rectangle (sourceRect);
		Vector2 _destPoint = Vector2 (destPoint);
		ImageDataUtil::CopyChannel (&_image, &_sourceImage, &_sourceRect, &_destPoint, srcChannel, destChannel);
		
	}
	
	
	HL_PRIM void hl_lime_image_data_util_copy_channel (HL_Image* image, HL_Image* sourceImage, HL_Rectangle* sourceRect, HL_Vector2* destPoint, int srcChannel, int destChannel) {
		
		// Image _image = Image (image);
		// Image _sourceImage = Image (sourceImage);
		// Rectangle _sourceRect = Rectangle (sourceRect);
		// Vector2 _destPoint = Vector2 (destPoint);
		// ImageDataUtil::CopyChannel (&_image, &_sourceImage, &_sourceRect, &_destPoint, srcChannel, destChannel);
		
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
	
	
	HL_PRIM void hl_lime_image_data_util_copy_pixels (HL_Image* image, HL_Image* sourceImage, HL_Rectangle* sourceRect, HL_Vector2* destPoint, HL_Image* alphaImage, HL_Vector2* alphaPoint, bool mergeAlpha) {
		
		// Image _image = Image (image);
		// Image _sourceImage = Image (sourceImage);
		// Rectangle _sourceRect = Rectangle (sourceRect);
		// Vector2 _destPoint = Vector2 (destPoint);
		
		// if (val_is_null (alphaImage)) {
			
		// 	ImageDataUtil::CopyPixels (&_image, &_sourceImage, &_sourceRect, &_destPoint, 0, 0, mergeAlpha);
			
		// } else {
			
		// 	Image _alphaImage = Image (alphaImage);
		// 	Vector2 _alphaPoint = Vector2 (alphaPoint);
			
		// 	ImageDataUtil::CopyPixels (&_image, &_sourceImage, &_sourceRect, &_destPoint, &_alphaImage, &_alphaPoint, mergeAlpha);
			
		// }
		
	}
	
	
	void lime_image_data_util_fill_rect (value image, value rect, int rg, int ba) {
		
		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		int32_t color = (rg << 16) | ba;
		ImageDataUtil::FillRect (&_image, &_rect, color);
		
	}
	
	
	HL_PRIM void hl_lime_image_data_util_fill_rect (HL_Image* image, HL_Rectangle* rect, int rg, int ba) {
		
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
	
	
	HL_PRIM void hl_lime_image_data_util_flood_fill (HL_Image* image, int x, int y, int rg, int ba) {
		
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
	
	
	HL_PRIM void hl_lime_image_data_util_get_pixels (HL_Image* image, HL_Rectangle* rect, int format, HL_Bytes* bytes) {
		
		// Image _image = Image (image);
		// Rectangle _rect = Rectangle (rect);
		// PixelFormat _format = (PixelFormat)format;
		// Bytes pixels = Bytes (bytes);
		// ImageDataUtil::GetPixels (&_image, &_rect, _format, &pixels);
		
	}
	
	
	void lime_image_data_util_merge (value image, value sourceImage, value sourceRect, value destPoint, int redMultiplier, int greenMultiplier, int blueMultiplier, int alphaMultiplier) {
		
		Image _image = Image (image);
		Image _sourceImage = Image (sourceImage);
		Rectangle _sourceRect = Rectangle (sourceRect);
		Vector2 _destPoint = Vector2 (destPoint);
		ImageDataUtil::Merge (&_image, &_sourceImage, &_sourceRect, &_destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);
		
	}
	
	
	HL_PRIM void hl_lime_image_data_util_merge (HL_Image* image, HL_Image* sourceImage, HL_Rectangle* sourceRect, HL_Vector2* destPoint, int redMultiplier, int greenMultiplier, int blueMultiplier, int alphaMultiplier) {
		
		// Image _image = Image (image);
		// Image _sourceImage = Image (sourceImage);
		// Rectangle _sourceRect = Rectangle (sourceRect);
		// Vector2 _destPoint = Vector2 (destPoint);
		// ImageDataUtil::Merge (&_image, &_sourceImage, &_sourceRect, &_destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);
		
	}
	
	
	void lime_image_data_util_multiply_alpha (value image) {
		
		Image _image = Image (image);
		ImageDataUtil::MultiplyAlpha (&_image);
		
	}
	
	
	HL_PRIM void hl_lime_image_data_util_multiply_alpha (HL_Image* image) {
		
		Image _image = Image (image);
		ImageDataUtil::MultiplyAlpha (&_image);
		
	}
	
	
	void lime_image_data_util_resize (value image, value buffer, int width, int height) {
		
		Image _image = Image (image);
		ImageBuffer _buffer = ImageBuffer (buffer);
		ImageDataUtil::Resize (&_image, &_buffer, width, height);
		
	}
	
	
	HL_PRIM void hl_lime_image_data_util_resize (HL_Image* image, HL_ImageBuffer* buffer, int width, int height) {
		
		Image _image = Image (image);
		ImageBuffer _buffer = ImageBuffer (buffer);
		ImageDataUtil::Resize (&_image, &_buffer, width, height);
		
	}
	
	
	void lime_image_data_util_set_format (value image, int format) {
		
		Image _image = Image (image);
		PixelFormat _format = (PixelFormat)format;
		ImageDataUtil::SetFormat (&_image, _format);
		
	}
	
	
	HL_PRIM void hl_lime_image_data_util_set_format (HL_Image* image, int format) {
		
		Image _image = Image (image);
		PixelFormat _format = (PixelFormat)format;
		ImageDataUtil::SetFormat (&_image, _format);
		
	}
	
	
	void lime_image_data_util_set_pixels (value image, value rect, value bytes, int offset, int format, int endian) {
		
		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		Bytes _bytes (bytes);
		PixelFormat _format = (PixelFormat)format;
		Endian _endian = (Endian)endian;
		ImageDataUtil::SetPixels (&_image, &_rect, &_bytes, offset, _format, _endian);
		
	}
	
	
	HL_PRIM void hl_lime_image_data_util_set_pixels (HL_Image* image, HL_Rectangle* rect, HL_Bytes* bytes, int offset, int format, int endian) {
		
		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		Bytes _bytes (bytes);
		PixelFormat _format = (PixelFormat)format;
		Endian _endian = (Endian)endian;
		ImageDataUtil::SetPixels (&_image, &_rect, &_bytes, offset, _format, _endian);
		
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
	
	
	HL_PRIM int hl_lime_image_data_util_threshold (HL_Image* image, HL_Image* sourceImage, HL_Rectangle* sourceRect, HL_Vector2* destPoint, int operation, int thresholdRG, int thresholdBA, int colorRG, int colorBA, int maskRG, int maskBA, bool copySource) {
		
		// Image _image = Image (image);
		// Image _sourceImage = Image (sourceImage);
		// Rectangle _sourceRect = Rectangle (sourceRect);
		// Vector2 _destPoint = Vector2 (destPoint);
		// int32_t threshold = (thresholdRG << 16) | thresholdBA;
		// int32_t color = (colorRG << 16) | colorBA;
		// int32_t mask = (maskRG << 16) | maskBA;
		// return ImageDataUtil::Threshold (&_image, &_sourceImage, &_sourceRect, &_destPoint, operation, threshold, color, mask, copySource);
		return 0;
		
	}
	
	
	void lime_image_data_util_unmultiply_alpha (value image) {
		
		Image _image = Image (image);
		ImageDataUtil::UnmultiplyAlpha (&_image);
		
	}
	
	
	HL_PRIM void hl_lime_image_data_util_unmultiply_alpha (HL_Image* image) {
		
		Image _image = Image (image);
		ImageDataUtil::UnmultiplyAlpha (&_image);
		
	}
	
	
	double lime_jni_getenv () {
		
		#ifdef ANDROID
		return (uintptr_t)JNI::GetEnv ();
		#else
		return 0;
		#endif
		
	}
	
	
	HL_PRIM double hl_lime_jni_getenv () {
		
		#ifdef ANDROID
		return (uintptr_t)JNI::GetEnv ();
		#else
		return 0;
		#endif
		
	}
	
	
	void lime_joystick_event_manager_register (value callback, value eventObject) {
		
		JoystickEvent::callback = new ValuePointer (callback);
		JoystickEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_joystick_event_manager_register (vclosure* callback, HL_JoystickEvent* eventObject) {
		
		JoystickEvent::callback = new ValuePointer (callback);
		JoystickEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	value lime_joystick_get_device_guid (int id) {
		
		const char* guid = Joystick::GetDeviceGUID (id);
		return guid ? alloc_string (guid) : alloc_null ();
		
	}
	
	
	HL_PRIM vbyte* hl_lime_joystick_get_device_guid (int id) {
		
		return (vbyte*)Joystick::GetDeviceGUID (id);
		
	}
	
	
	value lime_joystick_get_device_name (int id) {
		
		const char* name = Joystick::GetDeviceName (id);
		return name ? alloc_string (name) : alloc_null ();
		
	}
	
	
	HL_PRIM vbyte* hl_lime_joystick_get_device_name (int id) {
		
		return (vbyte*)Joystick::GetDeviceName (id);
		
	}
	
	
	int lime_joystick_get_num_axes (int id) {
		
		return Joystick::GetNumAxes (id);
		
	}
	
	
	HL_PRIM int hl_lime_joystick_get_num_axes (int id) {
		
		return Joystick::GetNumAxes (id);
		
	}
	
	
	int lime_joystick_get_num_buttons (int id) {
		
		return Joystick::GetNumButtons (id);
		
	}
	
	
	HL_PRIM int hl_lime_joystick_get_num_buttons (int id) {
		
		return Joystick::GetNumButtons (id);
		
	}
	
	
	int lime_joystick_get_num_hats (int id) {
		
		return Joystick::GetNumHats (id);
		
	}
	
	
	HL_PRIM int hl_lime_joystick_get_num_hats (int id) {
		
		return Joystick::GetNumHats (id);
		
	}
	
	
	int lime_joystick_get_num_trackballs (int id) {
		
		return Joystick::GetNumTrackballs (id);
		
	}
	
	
	HL_PRIM int hl_lime_joystick_get_num_trackballs (int id) {
		
		return Joystick::GetNumTrackballs (id);
		
	}
	
	
	value lime_jpeg_decode_bytes (value data, bool decodeData, value buffer) {
		
		ImageBuffer imageBuffer (buffer);
		
		Bytes bytes (data);
		Resource resource = Resource (&bytes);
		
		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &imageBuffer, decodeData)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_jpeg_decode_bytes (HL_Bytes* data, bool decodeData, HL_ImageBuffer* buffer) {
		
		// ImageBuffer imageBuffer (buffer);
		
		// Bytes bytes (data);
		// Resource resource = Resource (&bytes);
		
		// #ifdef LIME_JPEG
		// if (JPEG::Decode (&resource, &imageBuffer, decodeData)) {
			
		// 	return imageBuffer.Value ();
			
		// }
		// #endif
		
		return 0;
		
	}
	
	
	value lime_jpeg_decode_file (HxString path, bool decodeData, value buffer) {
		
		ImageBuffer imageBuffer (buffer);
		Resource resource = Resource (path.c_str ());
		
		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &imageBuffer, decodeData)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_jpeg_decode_file (vbyte* path, bool decodeData, HL_ImageBuffer* buffer) {
		
		// ImageBuffer imageBuffer (buffer);
		// Resource resource = Resource (path.c_str ());
		
		// #ifdef LIME_JPEG
		// if (JPEG::Decode (&resource, &imageBuffer, decodeData)) {
			
		// 	return imageBuffer.Value ();
			
		// }
		// #endif
		
		return 0;
		
	}
	
	
	float lime_key_code_from_scan_code (float scanCode) {
		
		return KeyCode::FromScanCode (scanCode);
		
	}
	
	
	HL_PRIM float hl_lime_key_code_from_scan_code (float scanCode) {
		
		return KeyCode::FromScanCode (scanCode);
		
	}
	
	
	float lime_key_code_to_scan_code (float keyCode) {
		
		return KeyCode::ToScanCode (keyCode);
		
	}
	
	
	HL_PRIM float hl_lime_key_code_to_scan_code (float keyCode) {
		
		return KeyCode::ToScanCode (keyCode);
		
	}
	
	
	void lime_key_event_manager_register (value callback, value eventObject) {
		
		KeyEvent::callback = new ValuePointer (callback);
		KeyEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_key_event_manager_register (vclosure* callback, HL_KeyEvent* eventObject) {
		
		KeyEvent::callback = new ValuePointer (callback);
		KeyEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	value lime_locale_get_system_locale () {
		
		std::string* locale = Locale::GetSystemLocale ();
		
		if (!locale) {
			
			return alloc_null ();
			
		} else {
			
			value result = alloc_string (locale->c_str ());
			delete locale;
			return result;
			
		}
		
	}
	
	
	HL_PRIM vbyte* hl_lime_locale_get_system_locale () {
		
		std::string* locale = Locale::GetSystemLocale ();
		
		if (!locale) {
			
			return 0;
			
		} else {
			
			// value result = alloc_string (locale->c_str ());
			// delete locale;
			
			// TODO: Copy string
			
			return (vbyte*)locale->c_str ();
			
		}
		
	}
	
	
	value lime_lzma_compress (value buffer, value bytes) {
		
		#ifdef LIME_LZMA
		Bytes data (buffer);
		Bytes result (bytes);
		
		LZMA::Compress (&data, &result);
		
		return result.Value ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_lzma_compress (HL_Bytes* buffer, HL_Bytes* bytes) {
		
		// #ifdef LIME_LZMA
		// Bytes data (buffer);
		// Bytes result (bytes);
		
		// LZMA::Compress (&data, &result);
		
		// return result.Value ();
		// #else
		return 0;
		// #endif
		
	}
	
	
	value lime_lzma_decompress (value buffer, value bytes) {
		
		#ifdef LIME_LZMA
		Bytes data (buffer);
		Bytes result (bytes);
		
		LZMA::Decompress (&data, &result);
		
		return result.Value ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_lzma_decompress (HL_Bytes* buffer, HL_Bytes* bytes) {
		
		// #ifdef LIME_LZMA
		// Bytes data (buffer);
		// Bytes result (bytes);
		
		// LZMA::Decompress (&data, &result);
		
		// return result.Value ();
		// #else
		return 0;
		// #endif
		
	}
	
	
	void lime_mouse_event_manager_register (value callback, value eventObject) {
		
		MouseEvent::callback = new ValuePointer (callback);
		MouseEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_mouse_event_manager_register (vclosure* callback, HL_MouseEvent* eventObject) {
		
		MouseEvent::callback = new ValuePointer (callback);
		MouseEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	void lime_mouse_hide () {
		
		Mouse::Hide ();
		
	}
	
	
	HL_PRIM void hl_lime_mouse_hide () {
		
		Mouse::Hide ();
		
	}
	
	
	void lime_mouse_set_cursor (int cursor) {
		
		Mouse::SetCursor ((MouseCursor)cursor);
		
	}
	
	
	HL_PRIM void hl_lime_mouse_set_cursor (int cursor) {
		
		Mouse::SetCursor ((MouseCursor)cursor);
		
	}
	
	
	void lime_mouse_set_lock (bool lock) {
		
		Mouse::SetLock (lock);
		
	}
	
	
	HL_PRIM void hl_lime_mouse_set_lock (bool lock) {
		
		Mouse::SetLock (lock);
		
	}
	
	
	void lime_mouse_show () {
		
		Mouse::Show ();
		
	}
	
	
	HL_PRIM void hl_lime_mouse_show () {
		
		Mouse::Show ();
		
	}
	
	
	void lime_mouse_warp (int x, int y, value window) {
		
		Window* windowRef = 0;
		
		if (window) {
			
			windowRef = (Window*)val_data (window);
			
		}
		
		Mouse::Warp (x, y, windowRef);
		
	}
	
	
	HL_PRIM void hl_lime_mouse_warp (int x, int y, HL_CFFIPointer* window) {
		
		Window* windowRef = 0;
		
		if (window) {
			
			windowRef = (Window*)window->ptr;
			
		}
		
		Mouse::Warp (x, y, windowRef);
		
	}
	
	
	void lime_neko_execute (HxString module) {
		
		#ifdef LIME_NEKO
		NekoVM::Execute (module.c_str ());
		#endif
		
	}
	
	
	value lime_png_decode_bytes (value data, bool decodeData, value buffer) {
		
		ImageBuffer imageBuffer (buffer);
		Bytes bytes (data);
		Resource resource = Resource (&bytes);
		
		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &imageBuffer, decodeData)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_png_decode_bytes (HL_Bytes* data, bool decodeData, HL_ImageBuffer* buffer) {
		
		// ImageBuffer imageBuffer (buffer);
		// Bytes bytes (data);
		// Resource resource = Resource (&bytes);
		
		// #ifdef LIME_PNG
		// if (PNG::Decode (&resource, &imageBuffer, decodeData)) {
			
		// 	return imageBuffer.Value ();
			
		// }
		// #endif
		
		return 0;
		
	}
	
	
	value lime_png_decode_file (HxString path, bool decodeData, value buffer) {
		
		ImageBuffer imageBuffer (buffer);
		Resource resource = Resource (path.c_str ());
		
		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &imageBuffer, decodeData)) {
			
			return imageBuffer.Value ();
			
		}
		#endif
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_png_decode_file (vbyte* path, bool decodeData, HL_Bytes* buffer) {
		
		// ImageBuffer imageBuffer (buffer);
		// Resource resource = Resource (path.c_str ());
		
		// #ifdef LIME_PNG
		// if (PNG::Decode (&resource, &imageBuffer, decodeData)) {
			
		// 	return imageBuffer.Value ();
			
		// }
		// #endif
		
		return 0;
		
	}
	
	
	void lime_render_event_manager_register (value callback, value eventObject) {
		
		RenderEvent::callback = new ValuePointer (callback);
		RenderEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_render_event_manager_register (vclosure* callback, HL_RenderEvent* eventObject) {
		
		RenderEvent::callback = new ValuePointer (callback);
		RenderEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	value lime_renderer_create (value window) {
		
		Renderer* renderer = CreateRenderer ((Window*)val_data (window));
		return CFFIPointer (renderer, gc_renderer);
		
	}
	
	
	HL_PRIM HL_CFFIPointer* hl_lime_renderer_create (HL_CFFIPointer* window) {
		
		Renderer* renderer = CreateRenderer ((Window*)window->ptr);
		return HLCFFIPointer (renderer, (hl_finalizer)hl_gc_renderer);
		
	}
	
	
	void lime_renderer_flip (value renderer) {
		
		((Renderer*)val_data (renderer))->Flip ();
		
	}
	
	
	HL_PRIM void hl_lime_renderer_flip (HL_CFFIPointer* renderer) {
		
		((Renderer*)renderer->ptr)->Flip ();
		
	}
	
	
	double lime_renderer_get_context (value renderer) {
		
		Renderer* targetRenderer = (Renderer*)val_data (renderer);
		return (uintptr_t)targetRenderer->GetContext ();
		
	}
	
	
	HL_PRIM double hl_lime_renderer_get_context (HL_CFFIPointer* renderer) {
		
		Renderer* targetRenderer = (Renderer*)renderer->ptr;
		return (uintptr_t)targetRenderer->GetContext ();
		
	}
	
	
	double lime_renderer_get_scale (value renderer) {
		
		Renderer* targetRenderer = (Renderer*)val_data (renderer);
		return targetRenderer->GetScale ();
		
	}
	
	
	HL_PRIM double hl_lime_renderer_get_scale (HL_CFFIPointer* renderer) {
		
		Renderer* targetRenderer = (Renderer*)renderer->ptr;
		return targetRenderer->GetScale ();
		
	}
	
	
	value lime_renderer_get_type (value renderer) {
		
		Renderer* targetRenderer = (Renderer*)val_data (renderer);
		const char* type = targetRenderer->Type ();
		return type ? alloc_string (type) : alloc_null ();
		
	}
	
	
	HL_PRIM vbyte* hl_lime_renderer_get_type (HL_CFFIPointer* renderer) {
		
		Renderer* targetRenderer = (Renderer*)renderer->ptr;
		return (vbyte*)targetRenderer->Type ();
		
	}
	
	
	value lime_renderer_lock (value renderer) {
		
		return (value)((Renderer*)val_data (renderer))->Lock (true);
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_renderer_lock (HL_CFFIPointer* renderer) {
		
		return (vdynamic*)((Renderer*)renderer->ptr)->Lock (false);
		
	}
	
	
	void lime_renderer_make_current (value renderer) {
		
		((Renderer*)val_data (renderer))->MakeCurrent ();
		
	}
	
	
	HL_PRIM void hl_lime_renderer_make_current (HL_CFFIPointer* renderer) {
		
		((Renderer*)renderer->ptr)->MakeCurrent ();
		
	}
	
	
	value lime_renderer_read_pixels (value renderer, value rect, value imageBuffer) {
		
		Renderer* targetRenderer = (Renderer*)val_data (renderer);
		ImageBuffer buffer (imageBuffer);
		
		if (!val_is_null (rect)) {
			
			Rectangle _rect = Rectangle (rect);
			targetRenderer->ReadPixels (&buffer, &_rect);
			
		} else {
			
			targetRenderer->ReadPixels (&buffer, NULL);
			
		}
		
		return buffer.Value ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_renderer_read_pixels (HL_CFFIPointer* renderer, HL_Rectangle* rect, HL_ImageBuffer* imageBuffer) {
		
		// Renderer* targetRenderer = (Renderer*)renderer->ptr;
		// ImageBuffer buffer (imageBuffer);
		
		// if (rect) {
			
		// 	Rectangle _rect = Rectangle (rect);
		// 	targetRenderer->ReadPixels (&buffer, &_rect);
			
		// } else {
			
		// 	targetRenderer->ReadPixels (&buffer, NULL);
			
		// }
		
		// return buffer.Value ();
		return 0;
		
	}
	
	
	void lime_renderer_unlock (value renderer) {
		
		((Renderer*)val_data (renderer))->Unlock ();
		
	}
	
	
	HL_PRIM void hl_lime_renderer_unlock (HL_CFFIPointer* renderer) {
		
		((Renderer*)renderer->ptr)->Unlock ();
		
	}
	
	
	void lime_sensor_event_manager_register (value callback, value eventObject) {
		
		SensorEvent::callback = new ValuePointer (callback);
		SensorEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_sensor_event_manager_register (vclosure* callback, HL_SensorEvent* eventObject) {
		
		SensorEvent::callback = new ValuePointer (callback);
		SensorEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	bool lime_system_get_allow_screen_timeout () {
		
		return System::GetAllowScreenTimeout ();
		
	}
	
	
	HL_PRIM bool hl_lime_system_get_allow_screen_timeout () {
		
		return System::GetAllowScreenTimeout ();
		
	}
	
	
	value lime_system_get_device_model () {
		
		std::wstring* model = System::GetDeviceModel ();
		
		if (model) {
			
			value result = alloc_wstring (model->c_str ());
			delete model;
			return result;
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	HL_PRIM vbyte* hl_lime_system_get_device_model () {
		
		std::wstring* model = System::GetDeviceModel ();
		
		if (model) {
			
			// TODO: Copy string
			return (vbyte*)model->c_str ();
			
			// value result = alloc_wstring (model->c_str ());
			// delete model;
			// return result;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	value lime_system_get_device_vendor () {
		
		std::wstring* vendor = System::GetDeviceVendor ();
		
		if (vendor) {
			
			value result = alloc_wstring (vendor->c_str ());
			delete vendor;
			return result;
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	HL_PRIM vbyte* hl_lime_system_get_device_vendor () {
		
		std::wstring* vendor = System::GetDeviceVendor ();
		
		if (vendor) {
			
			// TODO: Copy string
			return (vbyte*)vendor->c_str ();
			
			// value result = alloc_wstring (vendor->c_str ());
			// delete vendor;
			// return result;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	value lime_system_get_directory (int type, HxString company, HxString title) {
		
		std::wstring* path = System::GetDirectory ((SystemDirectory)type, company.c_str (), title.c_str ());
		
		if (path) {
			
			value result = alloc_wstring (path->c_str ());
			delete path;
			return result;
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	HL_PRIM vbyte* hl_lime_system_get_directory (int type, vbyte* company, vbyte* title) {
		
		std::wstring* path = System::GetDirectory ((SystemDirectory)type, (char*)company, (char*)title);
		
		if (path) {
			
			// TODO: Copy string
			return (vbyte*)path->c_str ();
			
			// value result = alloc_wstring (path->c_str ());
			// delete path;
			// return result;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	value lime_system_get_display (int id) {
		
		return System::GetDisplay (id);
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_system_get_display (int id) {
		
		// return System::GetDisplay (id);
		return 0;
		
	}
	
	
	bool lime_system_get_ios_tablet () {
		
		#ifdef IPHONE
		return System::GetIOSTablet ();
		#else
		return false;
		#endif
		
	}
	
	
	HL_PRIM bool hl_lime_system_get_ios_tablet () {
		
		#ifdef IPHONE
		return System::GetIOSTablet ();
		#else
		return false;
		#endif
		
	}
	
	
	int lime_system_get_num_displays () {
		
		return System::GetNumDisplays ();
		
	}
	
	
	HL_PRIM int hl_lime_system_get_num_displays () {
		
		return System::GetNumDisplays ();
		
	}
	
	
	value lime_system_get_platform_label () {
		
		std::wstring* label = System::GetPlatformLabel ();
		
		if (label) {
			
			value result = alloc_wstring (label->c_str ());
			delete label;
			return result;
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	HL_PRIM vbyte* hl_lime_system_get_platform_label () {
		
		std::wstring* label = System::GetPlatformLabel ();
		
		if (label) {
			
			// TODO: Copy string
			return (vbyte*)label->c_str ();
			
			// value result = alloc_wstring (label->c_str ());
			// delete label;
			// return result;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	value lime_system_get_platform_name () {
		
		std::wstring* name = System::GetPlatformName ();
		
		if (name) {
			
			value result = alloc_wstring (name->c_str ());
			delete name;
			return result;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	HL_PRIM vbyte* hl_lime_system_get_platform_name () {
		
		std::wstring* name = System::GetPlatformName ();
		
		if (name) {
			
			// TODO: Copy string
			return (vbyte*)name->c_str ();
			
			// value result = alloc_wstring (name->c_str ());
			// delete name;
			// return result;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	value lime_system_get_platform_version () {
		
		std::wstring* version = System::GetPlatformVersion ();
		
		if (version) {
			
			value result = alloc_wstring (version->c_str ());
			delete version;
			return result;
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	HL_PRIM vbyte* hl_lime_system_get_platform_version () {
		
		std::wstring* version = System::GetPlatformVersion ();
		
		if (version) {
			
			// TODO: Copy string
			return (vbyte*)version->c_str ();
			
			// value result = alloc_wstring (version->c_str ());
			// delete version;
			// return result;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	double lime_system_get_timer () {
		
		return System::GetTimer ();
		
	}
	
	
	HL_PRIM double hl_lime_system_get_timer () {
		
		return System::GetTimer ();
		
	}
	
	
	int lime_system_get_windows_console_mode (int handleType) {
		
		#ifdef HX_WINDOWS
		return System::GetWindowsConsoleMode (handleType);
		#else
		return 0;
		#endif
		
	}
	
	
	HL_PRIM int hl_lime_system_get_windows_console_mode (int handleType) {
		
		#ifdef HX_WINDOWS
		return System::GetWindowsConsoleMode (handleType);
		#else
		return 0;
		#endif
		
	}
	
	
	void lime_system_open_file (HxString path) {
		
		#ifdef IPHONE
		System::OpenFile (path.c_str ());
		#endif
		
	}
	
	
	HL_PRIM void hl_lime_system_open_file (vbyte* path) {
		
		#ifdef IPHONE
		System::OpenFile ((char*)path);
		#endif
		
	}
	
	
	void lime_system_open_url (HxString url, HxString target) {
		
		#ifdef IPHONE
		System::OpenURL (url.c_str (), target.c_str ());
		#endif
		
	}
	
	
	HL_PRIM void hl_lime_system_open_url (vbyte* url, vbyte* target) {
		
		#ifdef IPHONE
		System::OpenURL ((char*)url, (char*)target);
		#endif
		
	}
	
	
	bool lime_system_set_allow_screen_timeout (bool allow) {
		
		return System::SetAllowScreenTimeout (allow);
		
	}
	
	
	HL_PRIM bool hl_lime_system_set_allow_screen_timeout (bool allow) {
		
		return System::SetAllowScreenTimeout (allow);
		
	}
	
	
	bool lime_system_set_windows_console_mode (int handleType, int mode) {
		
		#ifdef HX_WINDOWS
		return System::SetWindowsConsoleMode (handleType, mode);
		#else
		return false;
		#endif
		
	}
	
	
	HL_PRIM bool hl_lime_system_set_windows_console_mode (int handleType, int mode) {
		
		#ifdef HX_WINDOWS
		return System::SetWindowsConsoleMode (handleType, mode);
		#else
		return false;
		#endif
		
	}
	
	
	void lime_text_event_manager_register (value callback, value eventObject) {
		
		TextEvent::callback = new ValuePointer (callback);
		TextEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_text_event_manager_register (vclosure* callback, HL_TextEvent* eventObject) {
		
		TextEvent::callback = new ValuePointer (callback);
		TextEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	value lime_text_layout_create (int direction, HxString script, HxString language) {
		
		#if defined (LIME_FREETYPE) && defined (LIME_HARFBUZZ)
		
		TextLayout *text = new TextLayout (direction, script.c_str (), language.c_str ());
		return CFFIPointer (text, gc_text_layout);
		
		#else
		
		return alloc_null ();
		
		#endif
		
	}
	
	
	HL_PRIM HL_CFFIPointer* hl_lime_text_layout_create (int direction, vbyte* script, vbyte* language) {
		
		#if defined (LIME_FREETYPE) && defined (LIME_HARFBUZZ)
		
		TextLayout *text = new TextLayout (direction, (char*)script, (char*)language);
		return HLCFFIPointer (text, (hl_finalizer)hl_gc_text_layout);
		
		#else
		
		return 0;
		
		#endif
		
	}
	
	
	value lime_text_layout_position (value textHandle, value fontHandle, int size, HxString textString, value data) {
		
		#if defined (LIME_FREETYPE) && defined (LIME_HARFBUZZ)
		
		TextLayout *text = (TextLayout*)val_data (textHandle);
		Font *font = (Font*)val_data (fontHandle);
		Bytes bytes (data);
		text->Position (font, size, textString.c_str (), &bytes);
		return bytes.Value ();
		
		#endif
		
		return alloc_null ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_text_layout_position (HL_CFFIPointer* textHandle, HL_CFFIPointer* fontHandle, int size, vbyte* textString, HL_Bytes* data) {
		
		// #if defined(LIME_FREETYPE) && defined(LIME_HARFBUZZ)
		
		// TextLayout *text = (TextLayout*)val_data (textHandle);
		// Font *font = (Font*)val_data (fontHandle);
		// Bytes bytes (data);
		// text->Position (font, size, textString.c_str (), &bytes);
		// return bytes.Value ();
		
		// #endif
		
		return 0;
		
	}
	
	
	void lime_text_layout_set_direction (value textHandle, int direction) {
		
		#if defined (LIME_FREETYPE) && defined (LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)val_data (textHandle);
		text->SetDirection (direction);
		#endif
		
	}
	
	
	HL_PRIM void hl_lime_text_layout_set_direction (HL_CFFIPointer* textHandle, int direction) {
		
		#if defined (LIME_FREETYPE) && defined (LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)textHandle->ptr;
		text->SetDirection (direction);
		#endif
		
	}
	
	
	void lime_text_layout_set_language (value textHandle, HxString language) {
		
		#if defined (LIME_FREETYPE) && defined (LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)val_data (textHandle);
		text->SetLanguage (language.c_str ());
		#endif
		
	}
	
	
	HL_PRIM void hl_lime_text_layout_set_language (HL_CFFIPointer* textHandle, vbyte* language) {
		
		#if defined (LIME_FREETYPE) && defined (LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)textHandle->ptr;
		text->SetLanguage ((char*)language);
		#endif
		
	}
	
	
	void lime_text_layout_set_script (value textHandle, HxString script) {
		
		#if defined (LIME_FREETYPE) && defined (LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)val_data (textHandle);
		text->SetScript (script.c_str ());
		#endif
		
	}
	
	
	HL_PRIM void hl_lime_text_layout_set_script (HL_CFFIPointer* textHandle, vbyte* script) {
		
		#if defined (LIME_FREETYPE) && defined (LIME_HARFBUZZ)
		TextLayout *text = (TextLayout*)textHandle->ptr;
		text->SetScript ((char*)script);
		#endif
		
	}
	
	
	void lime_touch_event_manager_register (value callback, value eventObject) {
		
		TouchEvent::callback = new ValuePointer (callback);
		TouchEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_touch_event_manager_register (vclosure* callback, HL_TouchEvent* eventObject) {
		
		TouchEvent::callback = new ValuePointer (callback);
		TouchEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	void lime_window_alert (value window, HxString message, HxString title) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Alert (message.c_str (), title.c_str ());
		
	}
	
	
	HL_PRIM void hl_lime_window_alert (HL_CFFIPointer* window, vbyte* message, vbyte* title) {
		
		Window* targetWindow = (Window*)window->ptr;
		targetWindow->Alert ((const char*)message, (const char*)title);
		
	}
	
	
	void lime_window_close (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Close ();
		
	}
	
	
	HL_PRIM void hl_lime_window_close (HL_CFFIPointer* window) {
		
		Window* targetWindow = (Window*)window->ptr;
		targetWindow->Close ();
		
	}
	
	
	value lime_window_create (value application, int width, int height, int flags, HxString title) {
		
		Window* window = CreateWindow ((Application*)val_data (application), width, height, flags, title.c_str ());
		return CFFIPointer (window, gc_window);
		
	}
	
	
	HL_PRIM HL_CFFIPointer* hl_lime_window_create (HL_CFFIPointer* application, int width, int height, int flags, HL_String* title) {
		
		Window* window = CreateWindow ((Application*)application->ptr, width, height, flags, (const char*)hl_to_utf8 ((const uchar*)title->bytes));
		return HLCFFIPointer (window, (hl_finalizer)hl_gc_window);
		
	}
	
	
	void lime_window_event_manager_register (value callback, value eventObject) {
		
		WindowEvent::callback = new ValuePointer (callback);
		WindowEvent::eventObject = new ValuePointer (eventObject);
		
	}
	
	
	HL_PRIM void hl_lime_window_event_manager_register (vclosure* callback, HL_WindowEvent* eventObject) {
		
		WindowEvent::callback = new ValuePointer (callback);
		WindowEvent::eventObject = new ValuePointer ((vobj*)eventObject);
		
	}
	
	
	void lime_window_focus (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Focus ();
		
	}
	
	
	HL_PRIM void hl_lime_window_focus (HL_CFFIPointer* window) {
		
		Window* targetWindow = (Window*)window->ptr;
		targetWindow->Focus ();
		
	}
	
	
	int lime_window_get_display (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetDisplay ();
		
	}
	
	
	HL_PRIM int hl_lime_window_get_display (HL_CFFIPointer* window) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetDisplay ();
		
	}
	
	
	value lime_window_get_display_mode (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		DisplayMode displayMode;
		targetWindow->GetDisplayMode (&displayMode);
		return displayMode.Value ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_window_get_display_mode (HL_CFFIPointer* window) {
		
		// Window* targetWindow = (Window*)window->ptr;
		// DisplayMode displayMode;
		// targetWindow->GetDisplayMode (&displayMode);
		// return displayMode.Value ();
		return 0;
		
	}
	
	
	bool lime_window_get_enable_text_events (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetEnableTextEvents ();
		
	}
	
	
	HL_PRIM bool hl_lime_window_get_enable_text_events (HL_CFFIPointer* window) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetEnableTextEvents ();
		
	}
	
	
	int lime_window_get_height (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetHeight ();
		
	}
	
	
	HL_PRIM int hl_lime_window_get_height (HL_CFFIPointer* window) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetHeight ();
		
	}
	
	
	int32_t lime_window_get_id (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return (int32_t)targetWindow->GetID ();
		
	}
	
	
	HL_PRIM int32_t hl_lime_window_get_id (HL_CFFIPointer* window) {
		
		Window* targetWindow = (Window*)window->ptr;
		return (int32_t)targetWindow->GetID ();
		
	}
	
	
	int lime_window_get_width (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetWidth ();
		
	}
	
	
	HL_PRIM int hl_lime_window_get_width (HL_CFFIPointer* window) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetWidth ();
		
	}
	
	
	int lime_window_get_x (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetX ();
		
	}
	
	
	HL_PRIM int hl_lime_window_get_x (HL_CFFIPointer* window) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetX ();
		
	}
	
	
	int lime_window_get_y (value window) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetY ();
		
	}
	
	
	HL_PRIM int hl_lime_window_get_y (HL_CFFIPointer* window) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetY ();
		
	}
	
	
	void lime_window_move (value window, int x, int y) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Move (x, y);
		
	}
	
	
	HL_PRIM void hl_lime_window_move (HL_CFFIPointer* window, int x, int y) {
		
		Window* targetWindow = (Window*)window->ptr;
		targetWindow->Move (x, y);
		
	}
	
	
	void lime_window_resize (value window, int width, int height) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Resize (width, height);
		
	}
	
	
	HL_PRIM void hl_lime_window_resize (HL_CFFIPointer* window, int width, int height) {
		
		Window* targetWindow = (Window*)window->ptr;
		targetWindow->Resize (width, height);
		
	}
	
	
	bool lime_window_set_borderless (value window, bool borderless) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetBorderless (borderless);
		
	}
	
	
	HL_PRIM bool hl_lime_window_set_borderless (HL_CFFIPointer* window, bool borderless) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetBorderless (borderless);
		
	}
	
	
	value lime_window_set_display_mode (value window, value displayMode) {
		
		Window* targetWindow = (Window*)val_data (window);
		DisplayMode _displayMode (displayMode);
		targetWindow->SetDisplayMode (&_displayMode);
		targetWindow->GetDisplayMode (&_displayMode);
		return _displayMode.Value ();
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_window_set_display_mode (HL_CFFIPointer* window, vdynamic* displayMode) {
		
		// Window* targetWindow = (Window*)val_data (window);
		// DisplayMode _displayMode (displayMode);
		// targetWindow->SetDisplayMode (&_displayMode);
		// targetWindow->GetDisplayMode (&_displayMode);
		// return _displayMode.Value ();
		return 0;
		
	}
	
	
	void lime_window_set_enable_text_events (value window, bool enabled) {
		
		Window* targetWindow = (Window*)val_data (window);
		targetWindow->SetEnableTextEvents (enabled);
		
	}
	
	
	HL_PRIM void hl_lime_window_set_enable_text_events (HL_CFFIPointer* window, bool enabled) {
		
		Window* targetWindow = (Window*)window->ptr;
		targetWindow->SetEnableTextEvents (enabled);
		
	}
	
	
	bool lime_window_set_fullscreen (value window, bool fullscreen) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetFullscreen (fullscreen);
		
	}
	
	
	HL_PRIM bool hl_lime_window_set_fullscreen (HL_CFFIPointer* window, bool fullscreen) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetFullscreen (fullscreen);
		
	}
	
	
	void lime_window_set_icon (value window, value buffer) {
		
		Window* targetWindow = (Window*)val_data (window);
		ImageBuffer imageBuffer = ImageBuffer (buffer);
		targetWindow->SetIcon (&imageBuffer);
		
	}
	
	
	HL_PRIM void hl_lime_window_set_icon (HL_CFFIPointer* window, HL_ImageBuffer* buffer) {
		
		Window* targetWindow = (Window*)window->ptr;
		ImageBuffer imageBuffer = ImageBuffer (buffer);
		targetWindow->SetIcon (&imageBuffer);
		
	}
	
	
	bool lime_window_set_maximized (value window, bool maximized) {
		
		Window* targetWindow = (Window*)val_data(window);
		return targetWindow->SetMaximized (maximized);
		
	}
	
	
	HL_PRIM bool hl_lime_window_set_maximized (HL_CFFIPointer* window, bool maximized) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetMaximized (maximized);
		
	}
	
	
	bool lime_window_set_minimized (value window, bool minimized) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetMinimized (minimized);
		
	}
	
	
	HL_PRIM bool hl_lime_window_set_minimized (HL_CFFIPointer* window, bool minimized) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetMinimized (minimized);
		
	}
	
	
	bool lime_window_set_resizable (value window, bool resizable) {
		
		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetResizable (resizable);
		
	}
	
	
	HL_PRIM bool hl_lime_window_set_resizable (HL_CFFIPointer* window, bool resizable) {
		
		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetResizable (resizable);
		
	}
	
	
	value lime_window_set_title (value window, HxString title) {
		
		Window* targetWindow = (Window*)val_data (window);
		const char* result = targetWindow->SetTitle (title.c_str ());
		
		if (result) {
			
			value _result = alloc_string (result);
			
			if (result != title.c_str ()) {
				
				free ((char*) result);
				
			}
			
			return _result;
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	HL_PRIM HL_String* hl_lime_window_set_title (HL_CFFIPointer* window, HL_String* title) {
		
		Window* targetWindow = (Window*)window->ptr;
		const char* result = targetWindow->SetTitle ((char*)hl_to_utf8 ((const uchar*)title->bytes));
		
		if (result) {
			
			// value _result = alloc_string (result);
			
			// if (result != title.c_str ()) {
				
			// 	free ((char*) result);
				
			// }
			
			// return _result;
			//return (vbyte*)result;
			return title;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	value lime_zlib_compress (value buffer, value bytes) {
		
		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);
		
		Zlib::Compress (ZLIB, &data, &result);
		
		return result.Value ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_zlib_compress (HL_Bytes* buffer, HL_Bytes* bytes) {
		
		// #ifdef LIME_ZLIB
		// Bytes data (buffer);
		// Bytes result (bytes);
		
		// Zlib::Compress (ZLIB, &data, &result);
		
		// return result.Value ();
		// #else
		return 0;
		// #endif
		
	}
	
	
	value lime_zlib_decompress (value buffer, value bytes) {
		
		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);
		
		Zlib::Decompress (ZLIB, &data, &result);
		
		return result.Value ();
		#else
		return alloc_null ();
		#endif
		
	}
	
	
	HL_PRIM vdynamic* hl_lime_zlib_decompress (HL_Bytes* buffer, HL_Bytes* bytes) {
		
		// #ifdef LIME_ZLIB
		// Bytes data (buffer);
		// Bytes result (bytes);
		
		// Zlib::Decompress (ZLIB, &data, &result);
		
		// return result.Value ();
		// #else
		return 0;
		// #endif
		
	}
	
	
	DEFINE_PRIME0 (lime_application_create);
	DEFINE_PRIME2v (lime_application_event_manager_register);
	DEFINE_PRIME1 (lime_application_exec);
	DEFINE_PRIME1v (lime_application_init);
	DEFINE_PRIME1 (lime_application_quit);
	DEFINE_PRIME2v (lime_application_set_frame_rate);
	DEFINE_PRIME1 (lime_application_update);
	DEFINE_PRIME2 (lime_audio_load);
	DEFINE_PRIME2 (lime_bytes_from_data_pointer);
	DEFINE_PRIME1 (lime_bytes_get_data_pointer);
	DEFINE_PRIME2 (lime_bytes_get_data_pointer_offset);
	DEFINE_PRIME2 (lime_bytes_read_file);
	DEFINE_PRIME1 (lime_cffi_get_native_pointer);
	DEFINE_PRIME1 (lime_cffi_set_finalizer);
	DEFINE_PRIME2v (lime_clipboard_event_manager_register);
	DEFINE_PRIME0 (lime_clipboard_get_text);
	DEFINE_PRIME1v (lime_clipboard_set_text);
	DEFINE_PRIME2 (lime_data_pointer_offset);
	DEFINE_PRIME2 (lime_deflate_compress);
	DEFINE_PRIME2 (lime_deflate_decompress);
	DEFINE_PRIME2v (lime_drop_event_manager_register);
	DEFINE_PRIME3 (lime_file_dialog_open_directory);
	DEFINE_PRIME3 (lime_file_dialog_open_file);
	DEFINE_PRIME3 (lime_file_dialog_open_files);
	DEFINE_PRIME3 (lime_file_dialog_save_file);
	DEFINE_PRIME1 (lime_file_watcher_create);
	DEFINE_PRIME3 (lime_file_watcher_add_directory);
	DEFINE_PRIME2v (lime_file_watcher_remove_directory);
	DEFINE_PRIME1v (lime_file_watcher_update);
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
	DEFINE_PRIME2 (lime_gzip_compress);
	DEFINE_PRIME2 (lime_gzip_decompress);
	DEFINE_PRIME2v (lime_haptic_vibrate);
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
	DEFINE_PRIME6v (lime_image_data_util_set_pixels);
	DEFINE_PRIME12 (lime_image_data_util_threshold);
	DEFINE_PRIME1v (lime_image_data_util_unmultiply_alpha);
	DEFINE_PRIME4 (lime_image_encode);
	DEFINE_PRIME2 (lime_image_load);
	DEFINE_PRIME0 (lime_jni_getenv);
	DEFINE_PRIME2v (lime_joystick_event_manager_register);
	DEFINE_PRIME1 (lime_joystick_get_device_guid);
	DEFINE_PRIME1 (lime_joystick_get_device_name);
	DEFINE_PRIME1 (lime_joystick_get_num_axes);
	DEFINE_PRIME1 (lime_joystick_get_num_buttons);
	DEFINE_PRIME1 (lime_joystick_get_num_hats);
	DEFINE_PRIME1 (lime_joystick_get_num_trackballs);
	DEFINE_PRIME3 (lime_jpeg_decode_bytes);
	DEFINE_PRIME3 (lime_jpeg_decode_file);
	DEFINE_PRIME1 (lime_key_code_from_scan_code);
	DEFINE_PRIME1 (lime_key_code_to_scan_code);
	DEFINE_PRIME2v (lime_key_event_manager_register);
	DEFINE_PRIME0 (lime_locale_get_system_locale);
	DEFINE_PRIME2 (lime_lzma_compress);
	DEFINE_PRIME2 (lime_lzma_decompress);
	DEFINE_PRIME2v (lime_mouse_event_manager_register);
	DEFINE_PRIME0v (lime_mouse_hide);
	DEFINE_PRIME1v (lime_mouse_set_cursor);
	DEFINE_PRIME1v (lime_mouse_set_lock);
	DEFINE_PRIME0v (lime_mouse_show);
	DEFINE_PRIME3v (lime_mouse_warp);
	DEFINE_PRIME1v (lime_neko_execute);
	DEFINE_PRIME3 (lime_png_decode_bytes);
	DEFINE_PRIME3 (lime_png_decode_file);
	DEFINE_PRIME1 (lime_renderer_create);
	DEFINE_PRIME1v (lime_renderer_flip);
	DEFINE_PRIME1 (lime_renderer_get_context);
	DEFINE_PRIME1 (lime_renderer_get_scale);
	DEFINE_PRIME1 (lime_renderer_get_type);
	DEFINE_PRIME1 (lime_renderer_lock);
	DEFINE_PRIME1v (lime_renderer_make_current);
	DEFINE_PRIME3 (lime_renderer_read_pixels);
	DEFINE_PRIME1v (lime_renderer_unlock);
	DEFINE_PRIME2v (lime_render_event_manager_register);
	DEFINE_PRIME2v (lime_sensor_event_manager_register);
	DEFINE_PRIME0 (lime_system_get_allow_screen_timeout);
	DEFINE_PRIME0 (lime_system_get_device_model);
	DEFINE_PRIME0 (lime_system_get_device_vendor);
	DEFINE_PRIME3 (lime_system_get_directory);
	DEFINE_PRIME1 (lime_system_get_display);
	DEFINE_PRIME0 (lime_system_get_ios_tablet);
	DEFINE_PRIME0 (lime_system_get_num_displays);
	DEFINE_PRIME0 (lime_system_get_platform_label);
	DEFINE_PRIME0 (lime_system_get_platform_name);
	DEFINE_PRIME0 (lime_system_get_platform_version);
	DEFINE_PRIME0 (lime_system_get_timer);
	DEFINE_PRIME1 (lime_system_get_windows_console_mode);
	DEFINE_PRIME1v (lime_system_open_file);
	DEFINE_PRIME2v (lime_system_open_url);
	DEFINE_PRIME1 (lime_system_set_allow_screen_timeout);
	DEFINE_PRIME2 (lime_system_set_windows_console_mode);
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
	DEFINE_PRIME1 (lime_window_get_display_mode);
	DEFINE_PRIME1 (lime_window_get_enable_text_events);
	DEFINE_PRIME1 (lime_window_get_height);
	DEFINE_PRIME1 (lime_window_get_id);
	DEFINE_PRIME1 (lime_window_get_width);
	DEFINE_PRIME1 (lime_window_get_x);
	DEFINE_PRIME1 (lime_window_get_y);
	DEFINE_PRIME3v (lime_window_move);
	DEFINE_PRIME3v (lime_window_resize);
	DEFINE_PRIME2 (lime_window_set_borderless);
	DEFINE_PRIME2 (lime_window_set_display_mode);
	DEFINE_PRIME2v (lime_window_set_enable_text_events);
	DEFINE_PRIME2 (lime_window_set_fullscreen);
	DEFINE_PRIME2v (lime_window_set_icon);
	DEFINE_PRIME2 (lime_window_set_maximized);
	DEFINE_PRIME2 (lime_window_set_minimized);
	DEFINE_PRIME2 (lime_window_set_resizable);
	DEFINE_PRIME2 (lime_window_set_title);
	DEFINE_PRIME2 (lime_zlib_compress);
	DEFINE_PRIME2 (lime_zlib_decompress);
	
	
	#define _ENUM "?"
	// #define _TCFFIPOINTER _ABSTRACT (HL_CFFIPointer)
	#define _TAPPLICATION_EVENT _OBJ (_I32 _I32)
	#define _TARRAYBUFFER _TBYTES
	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN
	#define _TCLIPBOARD_EVENT _OBJ (_I32)
	#define _TDROP_EVENT _OBJ (_STRING _I32)
	#define _TGAMEPAD_EVENT _OBJ (_I32 _I32 _I32 _I32 _F64)
	#define _TJOYSTICK_EVENT _OBJ (_I32 _I32 _I32 _I32 _F64 _F64)
	#define _TKEY_EVENT _OBJ (_I32 _I32 _I32 _I32)
	#define _TMOUSE_EVENT _OBJ (_I32 _F64 _F64 _I32 _I32 _F64 _F64)
	#define _TRECTANGLE _OBJ (_F64 _F64 _F64 _F64)
	#define _TRENDER_EVENT _OBJ (_ENUM _I32)
	#define _TSENSOR_EVENT _OBJ (_I32 _F64 _F64 _F64 _I32)
	#define _TTEXT_EVENT _OBJ (_I32 _I32 _I32 _STRING _I32 _I32)
	#define _TTOUCH_EVENT _OBJ (_I32 _F64 _F64 _I32 _F64 _I32 _F64 _F64)
	#define _TWINDOW_EVENT _OBJ (_I32 _I32 _I32 _I32 _I32 _I32)
	
	#define _TARRAYBUFFERVIEW _OBJ (_I32 _TARRAYBUFFER _I32 _I32 _I32 _I32)
	#define _TIMAGEBUFFER _OBJ (_I32 _TARRAYBUFFERVIEW _I32 _I32 _BOOL _BOOL _I32 _DYN _DYN _DYN _DYN _DYN _DYN)
	#define _TIMAGE _OBJ (_TIMAGEBUFFER _BOOL _I32 _I32 _I32 _TRECTANGLE _ENUM _I32 _I32 _F64 _F64)
	
	
	DEFINE_HL_PRIM (_TCFFIPOINTER, lime_application_create, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, lime_application_event_manager_register, _FUN(_VOID, _NO_ARG) _TAPPLICATION_EVENT);
	DEFINE_HL_PRIM (_I32, lime_application_exec, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, lime_application_init, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, lime_application_quit, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, lime_application_set_frame_rate, _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_BOOL, lime_application_update, _TCFFIPOINTER);
	// DEFINE_PRIME2 (lime_audio_load);
	// DEFINE_PRIME2 (lime_bytes_from_data_pointer);
	DEFINE_HL_PRIM (_F64, lime_bytes_get_data_pointer, _BYTES);
	// DEFINE_PRIME2 (lime_bytes_get_data_pointer_offset);
	// DEFINE_PRIME2 (lime_bytes_read_file);
	// DEFINE_PRIME1 (lime_cffi_get_native_pointer);
	// DEFINE_PRIME1 (lime_cffi_set_finalizer);
	DEFINE_HL_PRIM (_VOID, lime_clipboard_event_manager_register, _FUN(_VOID, _NO_ARG) _TCLIPBOARD_EVENT);
	// DEFINE_PRIME0 (lime_clipboard_get_text);
	// DEFINE_PRIME1v (lime_clipboard_set_text);
	// DEFINE_PRIME2 (lime_data_pointer_offset);
	// DEFINE_PRIME2 (lime_deflate_compress);
	// DEFINE_PRIME2 (lime_deflate_decompress);
	DEFINE_HL_PRIM (_VOID, lime_drop_event_manager_register, _FUN(_VOID, _NO_ARG) _TDROP_EVENT);
	// DEFINE_PRIME3 (lime_file_dialog_open_directory);
	// DEFINE_PRIME3 (lime_file_dialog_open_file);
	// DEFINE_PRIME3 (lime_file_dialog_open_files);
	// DEFINE_PRIME3 (lime_file_dialog_save_file);
	// DEFINE_PRIME1 (lime_file_watcher_create);
	// DEFINE_PRIME3 (lime_file_watcher_add_directory);
	// DEFINE_PRIME2v (lime_file_watcher_remove_directory);
	// DEFINE_PRIME1v (lime_file_watcher_update);
	// DEFINE_PRIME1 (lime_font_get_ascender);
	// DEFINE_PRIME1 (lime_font_get_descender);
	// DEFINE_PRIME1 (lime_font_get_family_name);
	// DEFINE_PRIME2 (lime_font_get_glyph_index);
	// DEFINE_PRIME2 (lime_font_get_glyph_indices);
	// DEFINE_PRIME2 (lime_font_get_glyph_metrics);
	// DEFINE_PRIME1 (lime_font_get_height);
	// DEFINE_PRIME1 (lime_font_get_num_glyphs);
	// DEFINE_PRIME1 (lime_font_get_underline_position);
	// DEFINE_PRIME1 (lime_font_get_underline_thickness);
	// DEFINE_PRIME1 (lime_font_get_units_per_em);
	// DEFINE_PRIME1 (lime_font_load);
	// DEFINE_PRIME2 (lime_font_outline_decompose);
	// DEFINE_PRIME3 (lime_font_render_glyph);
	// DEFINE_PRIME3 (lime_font_render_glyphs);
	// DEFINE_PRIME2v (lime_font_set_size);
	DEFINE_HL_PRIM (_VOID, lime_gamepad_add_mappings, _DYN);
	DEFINE_HL_PRIM (_VOID, lime_gamepad_event_manager_register, _FUN(_VOID, _NO_ARG) _TGAMEPAD_EVENT);
	// DEFINE_PRIME1 (lime_gamepad_get_device_guid);
	// DEFINE_PRIME1 (lime_gamepad_get_device_name);
	// DEFINE_PRIME2 (lime_gzip_compress);
	// DEFINE_PRIME2 (lime_gzip_decompress);
	// DEFINE_PRIME2v (lime_haptic_vibrate);
	// DEFINE_PRIME3v (lime_image_data_util_color_transform);
	// DEFINE_PRIME6v (lime_image_data_util_copy_channel);
	// DEFINE_PRIME7v (lime_image_data_util_copy_pixels);
	DEFINE_HL_PRIM (_VOID, lime_image_data_util_fill_rect, _TIMAGE _TRECTANGLE _I32 _I32);
	// DEFINE_PRIME5v (lime_image_data_util_flood_fill);
	// DEFINE_PRIME4v (lime_image_data_util_get_pixels);
	// DEFINE_PRIME8v (lime_image_data_util_merge);
	// DEFINE_PRIME1v (lime_image_data_util_multiply_alpha);
	// DEFINE_PRIME4v (lime_image_data_util_resize);
	// DEFINE_PRIME2v (lime_image_data_util_set_format);
	// DEFINE_PRIME6v (lime_image_data_util_set_pixels);
	// DEFINE_PRIME12 (lime_image_data_util_threshold);
	// DEFINE_PRIME1v (lime_image_data_util_unmultiply_alpha);
	// DEFINE_PRIME4 (lime_image_encode);
	// DEFINE_PRIME2 (lime_image_load);
	// DEFINE_PRIME0 (lime_jni_getenv);
	DEFINE_HL_PRIM (_VOID, lime_joystick_event_manager_register, _FUN(_VOID, _NO_ARG) _TJOYSTICK_EVENT);
	// DEFINE_PRIME1 (lime_joystick_get_device_guid);
	// DEFINE_PRIME1 (lime_joystick_get_device_name);
	// DEFINE_PRIME1 (lime_joystick_get_num_axes);
	// DEFINE_PRIME1 (lime_joystick_get_num_buttons);
	// DEFINE_PRIME1 (lime_joystick_get_num_hats);
	// DEFINE_PRIME1 (lime_joystick_get_num_trackballs);
	// DEFINE_PRIME3 (lime_jpeg_decode_bytes);
	// DEFINE_PRIME3 (lime_jpeg_decode_file);
	// DEFINE_PRIME1 (lime_key_code_from_scan_code);
	// DEFINE_PRIME1 (lime_key_code_to_scan_code);
	DEFINE_HL_PRIM (_VOID, lime_key_event_manager_register, _FUN (_VOID, _NO_ARG) _TKEY_EVENT);
	// DEFINE_PRIME0 (lime_locale_get_system_locale);
	// DEFINE_PRIME2 (lime_lzma_compress);
	// DEFINE_PRIME2 (lime_lzma_decompress);
	DEFINE_HL_PRIM (_VOID, lime_mouse_event_manager_register, _FUN (_VOID, _NO_ARG) _TMOUSE_EVENT);
	// DEFINE_PRIME0v (lime_mouse_hide);
	// DEFINE_PRIME1v (lime_mouse_set_cursor);
	// DEFINE_PRIME1v (lime_mouse_set_lock);
	// DEFINE_PRIME0v (lime_mouse_show);
	// DEFINE_PRIME3v (lime_mouse_warp);
	// DEFINE_PRIME1v (lime_neko_execute);
	// DEFINE_PRIME3 (lime_png_decode_bytes);
	// DEFINE_PRIME3 (lime_png_decode_file);
	DEFINE_HL_PRIM (_TCFFIPOINTER, lime_renderer_create, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, lime_renderer_flip, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_F64, lime_renderer_get_context, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_F64, lime_renderer_get_scale, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BYTES, lime_renderer_get_type, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN, lime_renderer_lock, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, lime_renderer_make_current, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN, lime_renderer_read_pixels, _TCFFIPOINTER _TRECTANGLE _TIMAGEBUFFER);
	DEFINE_HL_PRIM (_VOID, lime_renderer_unlock, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, lime_render_event_manager_register, _FUN (_VOID, _NO_ARG) _TRENDER_EVENT);
	DEFINE_HL_PRIM (_VOID, lime_sensor_event_manager_register, _FUN (_VOID, _NO_ARG) _TSENSOR_EVENT);
	// DEFINE_PRIME2v (lime_render_event_manager_register);
	// DEFINE_PRIME2v (lime_sensor_event_manager_register);
	// DEFINE_PRIME0 (lime_system_get_allow_screen_timeout);
	// DEFINE_PRIME0 (lime_system_get_device_model);
	// DEFINE_PRIME0 (lime_system_get_device_vendor);
	// DEFINE_PRIME3 (lime_system_get_directory);
	// DEFINE_PRIME1 (lime_system_get_display);
	// DEFINE_PRIME0 (lime_system_get_ios_tablet);
	// DEFINE_PRIME0 (lime_system_get_num_displays);
	// DEFINE_PRIME0 (lime_system_get_platform_label);
	// DEFINE_PRIME0 (lime_system_get_platform_name);
	// DEFINE_PRIME0 (lime_system_get_platform_version);
	DEFINE_HL_PRIM (_F64, lime_system_get_timer, _NO_ARG);
	// DEFINE_PRIME1 (lime_system_get_windows_console_mode);
	// DEFINE_PRIME1v (lime_system_open_file);
	// DEFINE_PRIME2v (lime_system_open_url);
	// DEFINE_PRIME1 (lime_system_set_allow_screen_timeout);
	// DEFINE_PRIME2 (lime_system_set_windows_console_mode);
	DEFINE_HL_PRIM (_VOID, lime_text_event_manager_register, _FUN (_VOID, _NO_ARG) _TTEXT_EVENT);
	// DEFINE_PRIME3 (lime_text_layout_create);
	// DEFINE_PRIME5 (lime_text_layout_position);
	// DEFINE_PRIME2v (lime_text_layout_set_direction);
	// DEFINE_PRIME2v (lime_text_layout_set_language);
	// DEFINE_PRIME2v (lime_text_layout_set_script);
	DEFINE_HL_PRIM (_VOID, lime_touch_event_manager_register, _FUN (_VOID, _NO_ARG) _TTOUCH_EVENT);
	DEFINE_HL_PRIM (_VOID, lime_window_alert, _TCFFIPOINTER _BYTES _BYTES);
	DEFINE_HL_PRIM (_VOID, lime_window_close, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, lime_window_create, _TCFFIPOINTER _I32 _I32 _I32 _STRING);
	DEFINE_HL_PRIM (_VOID, lime_window_event_manager_register, _FUN (_VOID, _NO_ARG) _TWINDOW_EVENT);
	DEFINE_HL_PRIM (_VOID, lime_window_focus, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, lime_window_get_display, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN, lime_window_get_display_mode, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, lime_window_get_enable_text_events, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, lime_window_get_height, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, lime_window_get_id, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, lime_window_get_width, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, lime_window_get_x, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, lime_window_get_y, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, lime_window_move, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, lime_window_resize, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_BOOL, lime_window_set_borderless, _TCFFIPOINTER _BOOL);
	// DEFINE_PRIME2 (lime_window_set_display_mode, _TCFFIPOINTER );
	DEFINE_HL_PRIM (_VOID, lime_window_set_enable_text_events, _TCFFIPOINTER _BOOL);
	// DEFINE_PRIME2 (lime_window_set_fullscreen);
	// DEFINE_PRIME2v (lime_window_set_icon);
	// DEFINE_PRIME2 (lime_window_set_maximized);
	// DEFINE_PRIME2 (lime_window_set_minimized);
	// DEFINE_PRIME2 (lime_window_set_resizable);
	DEFINE_HL_PRIM (_STRING, lime_window_set_title, _TCFFIPOINTER _STRING);
	// DEFINE_PRIME2 (lime_zlib_compress);
	// DEFINE_PRIME2 (lime_zlib_decompress);
	
	
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

#ifdef LIME_VORBIS
extern "C" int lime_vorbis_register_prims ();
#else
extern "C" int lime_vorbis_register_prims () { return 0; }
#endif


extern "C" int lime_register_prims () {
	
	lime_cairo_register_prims ();
	lime_curl_register_prims ();
	lime_openal_register_prims ();
	lime_opengl_register_prims ();
	lime_vorbis_register_prims ();
	
	return 0;
	
}
