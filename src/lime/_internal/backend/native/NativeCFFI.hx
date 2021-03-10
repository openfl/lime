package lime._internal.backend.native;

import haxe.io.Bytes;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLRenderbuffer;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GLTexture;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.math.Rectangle;
import lime.media.openal.ALAuxiliaryEffectSlot;
import lime.utils.DataPointer;
#if hl
import lime._internal.backend.native.NativeApplication;
import lime.graphics.cairo.CairoGlyph;
import lime.graphics.opengl.GL;
import lime.math.Matrix3;
import lime.math.Vector2;
import lime.media.openal.ALContext;
import lime.media.openal.ALDevice;
import lime.media.AudioBuffer;
import lime.system.DisplayMode;
import lime.utils.ArrayBufferView;
#end
#if (!lime_doc_gen || lime_cffi)
import lime.system.CFFI;
import lime.system.CFFIPointer;
#end
#if (cpp && !cppia)
import cpp.Float32;
#else
typedef Float32 = Float;
#end
#if (lime_doc_gen && !lime_cffi)
typedef CFFI = Dynamic;
typedef CFFIPointer = Dynamic;
#end

// #if hl
// typedef TNative_Application = hl.Abstract<"Application">;
// #end
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
#if (!macro && !lime_doc_gen)
#if (disable_cffi || haxe_ver < "3.4.0")
@:build(lime.system.CFFI.build())
#end
#end
class NativeCFFI
{
	#if (lime_cffi && !macro)
	#if (cpp && !cppia)
	#if (disable_cffi || haxe_ver < "3.4.0")
	@:cffi private static function lime_application_create():Dynamic;

	@:cffi private static function lime_application_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_application_exec(handle:Dynamic):Int;

	@:cffi private static function lime_application_init(handle:Dynamic):Void;

	@:cffi private static function lime_application_quit(handle:Dynamic):Int;

	@:cffi private static function lime_application_set_frame_rate(handle:Dynamic, value:Float):Void;

	@:cffi private static function lime_application_update(handle:Dynamic):Bool;

	@:cffi private static function lime_audio_load(data:Dynamic, buffer:Dynamic):Dynamic;

	@:cffi private static function lime_audio_load_bytes(data:Dynamic, buffer:Dynamic):Dynamic;

	@:cffi private static function lime_audio_load_file(path:Dynamic, buffer:Dynamic):Dynamic;

	@:cffi private static function lime_bytes_from_data_pointer(data:Float, length:Int, bytes:Dynamic):Dynamic;

	@:cffi private static function lime_bytes_get_data_pointer(data:Dynamic):Float;

	@:cffi private static function lime_bytes_get_data_pointer_offset(data:Dynamic, offset:Int):Float;

	@:cffi private static function lime_bytes_read_file(path:String, bytes:Dynamic):Dynamic;

	@:cffi private static function lime_cffi_get_native_pointer(ptr:Dynamic):Float;

	@:cffi private static function lime_clipboard_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_clipboard_get_text():Dynamic;

	@:cffi private static function lime_clipboard_set_text(text:String):Void;

	@:cffi private static function lime_data_pointer_offset(dataPointer:DataPointer, offset:Int):Float;

	@:cffi private static function lime_deflate_compress(data:Dynamic, bytes:Dynamic):Dynamic;

	@:cffi private static function lime_deflate_decompress(data:Dynamic, bytes:Dynamic):Dynamic;

	@:cffi private static function lime_drop_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_file_dialog_open_directory(title:String, filter:String, defaultPath:String):Dynamic;

	@:cffi private static function lime_file_dialog_open_file(title:String, filter:String, defaultPath:String):Dynamic;

	@:cffi private static function lime_file_dialog_open_files(title:String, filter:String, defaultPath:String):Dynamic;

	@:cffi private static function lime_file_dialog_save_file(title:String, filter:String, defaultPath:String):Dynamic;

	@:cffi private static function lime_file_watcher_create(callback:Dynamic):CFFIPointer;

	@:cffi private static function lime_file_watcher_add_directory(handle:CFFIPointer, path:Dynamic, recursive:Bool):Dynamic;

	@:cffi private static function lime_file_watcher_remove_directory(handle:CFFIPointer, watchID:Dynamic):Void;

	@:cffi private static function lime_file_watcher_update(handle:CFFIPointer):Void;

	@:cffi private static function lime_font_get_ascender(handle:Dynamic):Int;

	@:cffi private static function lime_font_get_descender(handle:Dynamic):Int;

	@:cffi private static function lime_font_get_family_name(handle:Dynamic):Dynamic;

	@:cffi private static function lime_font_get_glyph_index(handle:Dynamic, character:String):Int;

	@:cffi private static function lime_font_get_glyph_indices(handle:Dynamic, characters:String):Dynamic;

	@:cffi private static function lime_font_get_glyph_metrics(handle:Dynamic, index:Int):Dynamic;

	@:cffi private static function lime_font_get_height(handle:Dynamic):Int;

	@:cffi private static function lime_font_get_num_glyphs(handle:Dynamic):Int;

	@:cffi private static function lime_font_get_underline_position(handle:Dynamic):Int;

	@:cffi private static function lime_font_get_underline_thickness(handle:Dynamic):Int;

	@:cffi private static function lime_font_get_units_per_em(handle:Dynamic):Int;

	@:cffi private static function lime_font_load(data:Dynamic):Dynamic;

	@:cffi private static function lime_font_load_bytes(data:Dynamic):Dynamic;

	@:cffi private static function lime_font_load_file(path:Dynamic):Dynamic;

	@:cffi private static function lime_font_outline_decompose(handle:Dynamic, size:Int):Dynamic;

	@:cffi private static function lime_font_render_glyph(handle:Dynamic, index:Int, data:Dynamic):Dynamic;

	@:cffi private static function lime_font_render_glyphs(handle:Dynamic, indices:Dynamic, data:Dynamic):Dynamic;

	@:cffi private static function lime_font_set_size(handle:Dynamic, size:Int):Void;

	@:cffi private static function lime_gamepad_add_mappings(mappings:Dynamic):Void;

	@:cffi private static function lime_gamepad_get_device_guid(id:Int):Dynamic;

	@:cffi private static function lime_gamepad_get_device_name(id:Int):Dynamic;

	@:cffi private static function lime_gamepad_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_gzip_compress(data:Dynamic, bytes:Dynamic):Dynamic;

	@:cffi private static function lime_gzip_decompress(data:Dynamic, bytes:Dynamic):Dynamic;

	@:cffi private static function lime_haptic_vibrate(period:Int, duration:Int):Void;

	@:cffi private static function lime_image_encode(data:Dynamic, type:Int, quality:Int, bytes:Dynamic):Dynamic;

	@:cffi private static function lime_image_load(data:Dynamic, buffer:Dynamic):Dynamic;

	@:cffi private static function lime_image_load_bytes(data:Dynamic, buffer:Dynamic):Dynamic;

	@:cffi private static function lime_image_load_file(path:Dynamic, buffer:Dynamic):Dynamic;

	@:cffi private static function lime_image_data_util_color_transform(image:Dynamic, rect:Dynamic, colorMatrix:Dynamic):Void;

	@:cffi private static function lime_image_data_util_copy_channel(image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic,
		srcChannel:Int, destChannel:Int):Void;

	@:cffi private static function lime_image_data_util_copy_pixels(image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic,
		alphaImage:Dynamic, alphaPoint:Dynamic, mergeAlpha:Bool):Void;

	@:cffi private static function lime_image_data_util_fill_rect(image:Dynamic, rect:Dynamic, rg:Int, ba:Int):Void;

	@:cffi private static function lime_image_data_util_flood_fill(image:Dynamic, x:Int, y:Int, rg:Int, ba:Int):Void;

	@:cffi private static function lime_image_data_util_get_pixels(image:Dynamic, rect:Dynamic, format:Int, bytes:Dynamic):Void;

	@:cffi private static function lime_image_data_util_merge(image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic, redMultiplier:Int,
		greenMultiplier:Int, blueMultiplier:Int, alphaMultiplier:Int):Void;

	@:cffi private static function lime_image_data_util_multiply_alpha(image:Dynamic):Void;

	@:cffi private static function lime_image_data_util_resize(image:Dynamic, buffer:Dynamic, width:Int, height:Int):Void;

	@:cffi private static function lime_image_data_util_set_format(image:Dynamic, format:Int):Void;

	@:cffi private static function lime_image_data_util_set_pixels(image:Dynamic, rect:Dynamic, bytes:Dynamic, offset:Int, format:Int, endian:Int):Void;

	@:cffi private static function lime_image_data_util_threshold(image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic, operation:Int,
		thresholdRG:Int, thresholdBA:Int, colorRG:Int, colorBA:Int, maskRG:Int, maskBA:Int, copySource:Bool):Int;

	@:cffi private static function lime_image_data_util_unmultiply_alpha(image:Dynamic):Void;

	@:cffi private static function lime_joystick_get_device_guid(id:Int):Dynamic;

	@:cffi private static function lime_joystick_get_device_name(id:Int):Dynamic;

	@:cffi private static function lime_joystick_get_num_axes(id:Int):Int;

	@:cffi private static function lime_joystick_get_num_buttons(id:Int):Int;

	@:cffi private static function lime_joystick_get_num_hats(id:Int):Int;

	@:cffi private static function lime_joystick_get_num_trackballs(id:Int):Int;

	@:cffi private static function lime_joystick_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_jpeg_decode_bytes(data:Dynamic, decodeData:Bool, buffer:Dynamic):Dynamic;

	@:cffi private static function lime_jpeg_decode_file(path:String, decodeData:Bool, buffer:Dynamic):Dynamic;

	@:cffi private static function lime_key_code_from_scan_code(scanCode:Float32):Float32;

	@:cffi private static function lime_key_code_to_scan_code(keyCode:Float32):Float32;

	@:cffi private static function lime_key_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_lzma_compress(data:Dynamic, bytes:Dynamic):Dynamic;

	@:cffi private static function lime_lzma_decompress(data:Dynamic, bytes:Dynamic):Dynamic;

	@:cffi private static function lime_mouse_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_neko_execute(module:String):Void;

	@:cffi private static function lime_png_decode_bytes(data:Dynamic, decodeData:Bool, buffer:Dynamic):Dynamic;

	@:cffi private static function lime_png_decode_file(path:String, decodeData:Bool, buffer:Dynamic):Dynamic;

	@:cffi private static function lime_render_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_sensor_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_system_get_allow_screen_timeout():Bool;

	@:cffi private static function lime_system_set_allow_screen_timeout(value:Bool):Bool;

	@:cffi private static function lime_system_get_device_model():Dynamic;

	@:cffi private static function lime_system_get_device_vendor():Dynamic;

	@:cffi private static function lime_system_get_directory(type:Int, company:String, title:String):Dynamic;

	@:cffi private static function lime_system_get_display(index:Int):Dynamic;

	@:cffi private static function lime_system_get_ios_tablet():Bool;

	@:cffi private static function lime_system_get_num_displays():Int;

	@:cffi private static function lime_system_get_platform_label():Dynamic;

	@:cffi private static function lime_system_get_platform_name():Dynamic;

	@:cffi private static function lime_system_get_platform_version():Dynamic;

	@:cffi private static function lime_system_get_timer():Float;

	@:cffi private static function lime_system_open_file(path:String):Void;

	@:cffi private static function lime_system_open_url(url:String, target:String):Void;

	@:cffi private static function lime_text_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_touch_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_window_alert(handle:Dynamic, message:String, title:String):Void;

	@:cffi private static function lime_window_close(handle:Dynamic):Void;

	@:cffi private static function lime_window_context_flip(handle:Dynamic):Void;

	@:cffi private static function lime_window_context_lock(handle:Dynamic):Dynamic;

	@:cffi private static function lime_window_context_make_current(handle:Dynamic):Void;

	@:cffi private static function lime_window_context_unlock(handle:Dynamic):Void;

	@:cffi private static function lime_window_create(application:Dynamic, width:Int, height:Int, flags:Int, title:String):Dynamic;

	@:cffi private static function lime_window_focus(handle:Dynamic):Void;

	@:cffi private static function lime_window_get_context(handle:Dynamic):Float;

	@:cffi private static function lime_window_get_context_type(handle:Dynamic):Dynamic;

	@:cffi private static function lime_window_get_display(handle:Dynamic):Int;

	@:cffi private static function lime_window_get_display_mode(handle:Dynamic):Dynamic;

	@:cffi private static function lime_window_get_height(handle:Dynamic):Int;

	@:cffi private static function lime_window_get_id(handle:Dynamic):Int;

	@:cffi private static function lime_window_get_mouse_lock(handle:Dynamic):Bool;

	@:cffi private static function lime_window_get_scale(handle:Dynamic):Float;

	@:cffi private static function lime_window_get_text_input_enabled(handle:Dynamic):Bool;

	@:cffi private static function lime_window_get_width(handle:Dynamic):Int;

	@:cffi private static function lime_window_get_x(handle:Dynamic):Int;

	@:cffi private static function lime_window_get_y(handle:Dynamic):Int;

	@:cffi private static function lime_window_move(handle:Dynamic, x:Int, y:Int):Void;

	@:cffi private static function lime_window_read_pixels(handle:Dynamic, rect:Dynamic, imageBuffer:Dynamic):Dynamic;

	@:cffi private static function lime_window_resize(handle:Dynamic, width:Int, height:Int):Void;

	@:cffi private static function lime_window_set_borderless(handle:Dynamic, borderless:Bool):Bool;

	@:cffi private static function lime_window_set_cursor(handle:Dynamic, cursor:Int):Void;

	@:cffi private static function lime_window_set_display_mode(handle:Dynamic, displayMode:Dynamic):Dynamic;

	@:cffi private static function lime_window_set_fullscreen(handle:Dynamic, fullscreen:Bool):Bool;

	@:cffi private static function lime_window_set_icon(handle:Dynamic, buffer:Dynamic):Void;

	@:cffi private static function lime_window_set_maximized(handle:Dynamic, maximized:Bool):Bool;

	@:cffi private static function lime_window_set_minimized(handle:Dynamic, minimized:Bool):Bool;

	@:cffi private static function lime_window_set_mouse_lock(handle:Dynamic, mouseLock:Bool):Void;

	@:cffi private static function lime_window_set_resizable(handle:Dynamic, resizable:Bool):Bool;

	@:cffi private static function lime_window_set_text_input_enabled(handle:Dynamic, enabled:Bool):Void;

	@:cffi private static function lime_window_set_title(handle:Dynamic, title:String):Dynamic;

	@:cffi private static function lime_window_warp_mouse(handle:Dynamic, x:Int, y:Int):Void;

	@:cffi private static function lime_window_event_manager_register(callback:Dynamic, eventObject:Dynamic):Void;

	@:cffi private static function lime_zlib_compress(data:Dynamic, bytes:Dynamic):Dynamic;

	@:cffi private static function lime_zlib_decompress(data:Dynamic, bytes:Dynamic):Dynamic;
	#else
	private static var lime_application_create = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_application_create", "o", false));
	private static var lime_application_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_application_event_manager_register", "oov", false));
	private static var lime_application_exec = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_application_exec", "oi", false));
	private static var lime_application_init = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_application_init", "ov", false));
	private static var lime_application_quit = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_application_quit", "oi", false));
	private static var lime_application_set_frame_rate = new cpp.Callable<cpp.Object->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_application_set_frame_rate", "odv", false));
	private static var lime_application_update = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_application_update", "ob", false));
	private static var lime_audio_load = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_audio_load", "ooo", false));
	private static var lime_audio_load_bytes = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_audio_load_bytes",
		"ooo", false));
	private static var lime_audio_load_file = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_audio_load_file", "ooo",
		false));
	private static var lime_bytes_from_data_pointer = new cpp.Callable<Float->Int->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_bytes_from_data_pointer", "dioo", false));
	private static var lime_bytes_get_data_pointer = new cpp.Callable<cpp.Object->Float>(cpp.Prime._loadPrime("lime", "lime_bytes_get_data_pointer", "od",
		false));
	private static var lime_bytes_get_data_pointer_offset = new cpp.Callable<cpp.Object->Int->Float>(cpp.Prime._loadPrime("lime",
		"lime_bytes_get_data_pointer_offset", "oid", false));
	private static var lime_bytes_read_file = new cpp.Callable<String->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_bytes_read_file", "soo",
		false));
	private static var lime_cffi_get_native_pointer = new cpp.Callable<cpp.Object->Float>(cpp.Prime._loadPrime("lime", "lime_cffi_get_native_pointer", "od",
		false));
	private static var lime_clipboard_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_clipboard_event_manager_register", "oov", false));
	private static var lime_clipboard_get_text = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_clipboard_get_text", "o", false));
	private static var lime_clipboard_set_text = new cpp.Callable<String->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_clipboard_set_text", "sv", false));
	private static var lime_data_pointer_offset = new cpp.Callable<lime.utils.DataPointer->Int->Float>(cpp.Prime._loadPrime("lime",
		"lime_data_pointer_offset", "did", false));
	private static var lime_deflate_compress = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_deflate_compress",
		"ooo", false));
	private static var lime_deflate_decompress = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_deflate_decompress",
		"ooo", false));
	private static var lime_drop_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_drop_event_manager_register", "oov", false));
	private static var lime_file_dialog_open_directory = new cpp.Callable<String->String->String->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_file_dialog_open_directory", "ssso", false));
	private static var lime_file_dialog_open_file = new cpp.Callable<String->String->String->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_file_dialog_open_file", "ssso", false));
	private static var lime_file_dialog_open_files = new cpp.Callable<String->String->String->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_file_dialog_open_files", "ssso", false));
	private static var lime_file_dialog_save_file = new cpp.Callable<String->String->String->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_file_dialog_save_file", "ssso", false));
	private static var lime_file_watcher_create = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_file_watcher_create", "oo",
		false));
	private static var lime_file_watcher_add_directory = new cpp.Callable<cpp.Object->cpp.Object->Bool->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_file_watcher_add_directory", "oobo", false));
	private static var lime_file_watcher_remove_directory = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_file_watcher_remove_directory", "oov", false));
	private static var lime_file_watcher_update = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_file_watcher_update", "ov",
		false));
	private static var lime_font_get_ascender = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_font_get_ascender", "oi", false));
	private static var lime_font_get_descender = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_font_get_descender", "oi", false));
	private static var lime_font_get_family_name = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_font_get_family_name", "oo",
		false));
	private static var lime_font_get_glyph_index = new cpp.Callable<cpp.Object->String->Int>(cpp.Prime._loadPrime("lime", "lime_font_get_glyph_index", "osi",
		false));
	private static var lime_font_get_glyph_indices = new cpp.Callable<cpp.Object->String->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_font_get_glyph_indices", "oso", false));
	private static var lime_font_get_glyph_metrics = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_font_get_glyph_metrics",
		"oio", false));
	private static var lime_font_get_height = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_font_get_height", "oi", false));
	private static var lime_font_get_num_glyphs = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_font_get_num_glyphs", "oi", false));
	private static var lime_font_get_underline_position = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_font_get_underline_position",
		"oi", false));
	private static var lime_font_get_underline_thickness = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_font_get_underline_thickness",
		"oi", false));
	private static var lime_font_get_units_per_em = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_font_get_units_per_em", "oi", false));
	private static var lime_font_load = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_font_load", "oo", false));
	private static var lime_font_load_bytes = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_font_load_bytes", "oo", false));
	private static var lime_font_load_file = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_font_load_file", "oo", false));
	private static var lime_font_outline_decompose = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_font_outline_decompose",
		"oio", false));
	private static var lime_font_render_glyph = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_font_render_glyph", "oioo", false));
	private static var lime_font_render_glyphs = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_font_render_glyphs", "oooo", false));
	private static var lime_font_set_size = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_font_set_size", "oiv", false));
	private static var lime_gamepad_add_mappings = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gamepad_add_mappings", "ov",
		false));
	private static var lime_gamepad_get_device_guid = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gamepad_get_device_guid", "io",
		false));
	private static var lime_gamepad_get_device_name = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gamepad_get_device_name", "io",
		false));
	private static var lime_gamepad_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gamepad_event_manager_register", "oov", false));
	private static var lime_gzip_compress = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gzip_compress", "ooo",
		false));
	private static var lime_gzip_decompress = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gzip_decompress", "ooo",
		false));
	private static var lime_haptic_vibrate = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_haptic_vibrate", "iiv", false));
	private static var lime_image_encode = new cpp.Callable<cpp.Object->Int->Int->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_image_encode",
		"oiioo", false));
	private static var lime_image_load = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_image_load", "ooo", false));
	private static var lime_image_load_bytes = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_image_load_bytes",
		"ooo", false));
	private static var lime_image_load_file = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_image_load_file", "ooo",
		false));
	private static var lime_image_data_util_color_transform = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_image_data_util_color_transform", "ooov", false));
	private static var lime_image_data_util_copy_channel = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->cpp.Object->Int->Int->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_image_data_util_copy_channel", "ooooiiv", false));
	private static var lime_image_data_util_copy_pixels = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->cpp.Object->cpp.Object->cpp.Object->Bool->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_image_data_util_copy_pixels", "oooooobv", false));
	private static var lime_image_data_util_fill_rect = new cpp.Callable<cpp.Object->cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_image_data_util_fill_rect", "ooiiv", false));
	private static var lime_image_data_util_flood_fill = new cpp.Callable<cpp.Object->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_image_data_util_flood_fill", "oiiiiv", false));
	private static var lime_image_data_util_get_pixels = new cpp.Callable<cpp.Object->cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_image_data_util_get_pixels", "ooiov", false));
	private static var lime_image_data_util_merge = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->cpp.Object->Int->Int->Int->Int->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_image_data_util_merge", "ooooiiiiv", false));
	private static var lime_image_data_util_multiply_alpha = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_image_data_util_multiply_alpha", "ov", false));
	private static var lime_image_data_util_resize = new cpp.Callable<cpp.Object->cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_image_data_util_resize", "ooiiv", false));
	private static var lime_image_data_util_set_format = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_image_data_util_set_format", "oiv", false));
	private static var lime_image_data_util_set_pixels = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->Int->Int->Int->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_image_data_util_set_pixels", "oooiiiv", false));
	private static var lime_image_data_util_threshold = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->cpp.Object->Int->Int->Int->Int->Int->Int->Int->
		Bool->Int>(cpp.Prime._loadPrime("lime", "lime_image_data_util_threshold", "ooooiiiiiiibi", false));
	private static var lime_image_data_util_unmultiply_alpha = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_image_data_util_unmultiply_alpha", "ov", false));
	private static var lime_joystick_get_device_guid = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_joystick_get_device_guid", "io",
		false));
	private static var lime_joystick_get_device_name = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_joystick_get_device_name", "io",
		false));
	private static var lime_joystick_get_num_axes = new cpp.Callable<Int->Int>(cpp.Prime._loadPrime("lime", "lime_joystick_get_num_axes", "ii", false));
	private static var lime_joystick_get_num_buttons = new cpp.Callable<Int->Int>(cpp.Prime._loadPrime("lime", "lime_joystick_get_num_buttons", "ii", false));
	private static var lime_joystick_get_num_hats = new cpp.Callable<Int->Int>(cpp.Prime._loadPrime("lime", "lime_joystick_get_num_hats", "ii", false));
	private static var lime_joystick_get_num_trackballs = new cpp.Callable<Int->Int>(cpp.Prime._loadPrime("lime", "lime_joystick_get_num_trackballs", "ii",
		false));
	private static var lime_joystick_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_joystick_event_manager_register", "oov", false));
	private static var lime_jpeg_decode_bytes = new cpp.Callable<cpp.Object->Bool->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_jpeg_decode_bytes", "oboo", false));
	private static var lime_jpeg_decode_file = new cpp.Callable<String->Bool->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_jpeg_decode_file",
		"sboo", false));
	private static var lime_key_code_from_scan_code = new cpp.Callable<cpp.Float32->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_key_code_from_scan_code",
		"ff", false));
	private static var lime_key_code_to_scan_code = new cpp.Callable<cpp.Float32->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_key_code_to_scan_code",
		"ff", false));
	private static var lime_key_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_key_event_manager_register", "oov", false));
	private static var lime_lzma_compress = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_lzma_compress", "ooo",
		false));
	private static var lime_lzma_decompress = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_lzma_decompress", "ooo",
		false));
	private static var lime_mouse_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_mouse_event_manager_register", "oov", false));
	private static var lime_neko_execute = new cpp.Callable<String->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_neko_execute", "sv", false));
	private static var lime_png_decode_bytes = new cpp.Callable<cpp.Object->Bool->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_png_decode_bytes", "oboo", false));
	private static var lime_png_decode_file = new cpp.Callable<String->Bool->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_png_decode_file",
		"sboo", false));
	private static var lime_render_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_render_event_manager_register", "oov", false));
	private static var lime_sensor_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_sensor_event_manager_register", "oov", false));
	private static var lime_system_get_allow_screen_timeout = new cpp.Callable<Void->Bool>(cpp.Prime._loadPrime("lime",
		"lime_system_get_allow_screen_timeout", "b", false));
	private static var lime_system_set_allow_screen_timeout = new cpp.Callable<Bool->Bool>(cpp.Prime._loadPrime("lime",
		"lime_system_set_allow_screen_timeout", "bb", false));
	private static var lime_system_get_device_model = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_system_get_device_model", "o",
		false));
	private static var lime_system_get_device_vendor = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_system_get_device_vendor", "o",
		false));
	private static var lime_system_get_directory = new cpp.Callable<Int->String->String->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_system_get_directory",
		"isso", false));
	private static var lime_system_get_display = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_system_get_display", "io", false));
	private static var lime_system_get_ios_tablet = new cpp.Callable<Void->Bool>(cpp.Prime._loadPrime("lime", "lime_system_get_ios_tablet", "b", false));
	private static var lime_system_get_num_displays = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_system_get_num_displays", "i", false));
	private static var lime_system_get_platform_label = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_system_get_platform_label", "o",
		false));
	private static var lime_system_get_platform_name = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_system_get_platform_name", "o",
		false));
	private static var lime_system_get_platform_version = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_system_get_platform_version",
		"o", false));
	private static var lime_system_get_timer = new cpp.Callable<Void->Float>(cpp.Prime._loadPrime("lime", "lime_system_get_timer", "d", false));
	private static var lime_system_open_file = new cpp.Callable<String->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_system_open_file", "sv", false));
	private static var lime_system_open_url = new cpp.Callable<String->String->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_system_open_url", "ssv", false));
	private static var lime_text_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_text_event_manager_register", "oov", false));
	private static var lime_touch_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_touch_event_manager_register", "oov", false));
	private static var lime_window_alert = new cpp.Callable<cpp.Object->String->String->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_window_alert", "ossv",
		false));
	private static var lime_window_close = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_window_close", "ov", false));
	private static var lime_window_context_flip = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_window_context_flip", "ov",
		false));
	private static var lime_window_context_lock = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_window_context_lock", "oo",
		false));
	private static var lime_window_context_make_current = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_window_context_make_current", "ov", false));
	private static var lime_window_context_unlock = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_window_context_unlock", "ov",
		false));
	private static var lime_window_create = new cpp.Callable<cpp.Object->Int->Int->Int->String->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_window_create",
		"oiiiso", false));
	private static var lime_window_focus = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_window_focus", "ov", false));
	private static var lime_window_get_context = new cpp.Callable<cpp.Object->Float>(cpp.Prime._loadPrime("lime", "lime_window_get_context", "od", false));
	private static var lime_window_get_context_type = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_window_get_context_type",
		"oo", false));
	private static var lime_window_get_display = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_window_get_display", "oi", false));
	private static var lime_window_get_display_mode = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_window_get_display_mode",
		"oo", false));
	private static var lime_window_get_height = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_window_get_height", "oi", false));
	private static var lime_window_get_id = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_window_get_id", "oi", false));
	private static var lime_window_get_mouse_lock = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_window_get_mouse_lock", "ob",
		false));
	private static var lime_window_get_scale = new cpp.Callable<cpp.Object->Float>(cpp.Prime._loadPrime("lime", "lime_window_get_scale", "od", false));
	private static var lime_window_get_text_input_enabled = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime",
		"lime_window_get_text_input_enabled", "ob", false));
	private static var lime_window_get_width = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_window_get_width", "oi", false));
	private static var lime_window_get_x = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_window_get_x", "oi", false));
	private static var lime_window_get_y = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_window_get_y", "oi", false));
	private static var lime_window_move = new cpp.Callable<cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_window_move", "oiiv", false));
	private static var lime_window_read_pixels = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_window_read_pixels", "oooo", false));
	private static var lime_window_resize = new cpp.Callable<cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_window_resize", "oiiv",
		false));
	private static var lime_window_set_borderless = new cpp.Callable<cpp.Object->Bool->Bool>(cpp.Prime._loadPrime("lime", "lime_window_set_borderless", "obb",
		false));
	private static var lime_window_set_cursor = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_window_set_cursor", "oiv",
		false));
	private static var lime_window_set_display_mode = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_window_set_display_mode", "ooo", false));
	private static var lime_window_set_fullscreen = new cpp.Callable<cpp.Object->Bool->Bool>(cpp.Prime._loadPrime("lime", "lime_window_set_fullscreen", "obb",
		false));
	private static var lime_window_set_icon = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_window_set_icon", "oov",
		false));
	private static var lime_window_set_maximized = new cpp.Callable<cpp.Object->Bool->Bool>(cpp.Prime._loadPrime("lime", "lime_window_set_maximized", "obb",
		false));
	private static var lime_window_set_minimized = new cpp.Callable<cpp.Object->Bool->Bool>(cpp.Prime._loadPrime("lime", "lime_window_set_minimized", "obb",
		false));
	private static var lime_window_set_mouse_lock = new cpp.Callable<cpp.Object->Bool->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_window_set_mouse_lock",
		"obv", false));
	private static var lime_window_set_resizable = new cpp.Callable<cpp.Object->Bool->Bool>(cpp.Prime._loadPrime("lime", "lime_window_set_resizable", "obb",
		false));
	private static var lime_window_set_text_input_enabled = new cpp.Callable<cpp.Object->Bool->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_window_set_text_input_enabled", "obv", false));
	private static var lime_window_set_title = new cpp.Callable<cpp.Object->String->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_window_set_title", "oso",
		false));
	private static var lime_window_warp_mouse = new cpp.Callable<cpp.Object->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_window_warp_mouse",
		"oiiv", false));
	private static var lime_window_event_manager_register = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_window_event_manager_register", "oov", false));
	private static var lime_zlib_compress = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_zlib_compress", "ooo",
		false));
	private static var lime_zlib_decompress = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_zlib_decompress", "ooo",
		false));
	#end
	#end
	#if (neko || cppia)
	private static var lime_application_create = CFFI.load("lime", "lime_application_create", 0);
	private static var lime_application_event_manager_register = CFFI.load("lime", "lime_application_event_manager_register", 2);
	private static var lime_application_exec = CFFI.load("lime", "lime_application_exec", 1);
	private static var lime_application_init = CFFI.load("lime", "lime_application_init", 1);
	private static var lime_application_quit = CFFI.load("lime", "lime_application_quit", 1);
	private static var lime_application_set_frame_rate = CFFI.load("lime", "lime_application_set_frame_rate", 2);
	private static var lime_application_update = CFFI.load("lime", "lime_application_update", 1);
	private static var lime_audio_load = CFFI.load("lime", "lime_audio_load", 2);
	private static var lime_audio_load_bytes = CFFI.load("lime", "lime_audio_load_bytes", 2);
	private static var lime_audio_load_file = CFFI.load("lime", "lime_audio_load_file", 2);
	private static var lime_bytes_from_data_pointer = CFFI.load("lime", "lime_bytes_from_data_pointer", 3);
	private static var lime_bytes_get_data_pointer = CFFI.load("lime", "lime_bytes_get_data_pointer", 1);
	private static var lime_bytes_get_data_pointer_offset = CFFI.load("lime", "lime_bytes_get_data_pointer_offset", 2);
	private static var lime_bytes_read_file = CFFI.load("lime", "lime_bytes_read_file", 2);
	private static var lime_cffi_get_native_pointer = CFFI.load("lime", "lime_cffi_get_native_pointer", 1);
	private static var lime_clipboard_event_manager_register = CFFI.load("lime", "lime_clipboard_event_manager_register", 2);
	private static var lime_clipboard_get_text = CFFI.load("lime", "lime_clipboard_get_text", 0);
	private static var lime_clipboard_set_text = CFFI.load("lime", "lime_clipboard_set_text", 1);
	private static var lime_data_pointer_offset = CFFI.load("lime", "lime_data_pointer_offset", 2);
	private static var lime_deflate_compress = CFFI.load("lime", "lime_deflate_compress", 2);
	private static var lime_deflate_decompress = CFFI.load("lime", "lime_deflate_decompress", 2);
	private static var lime_drop_event_manager_register = CFFI.load("lime", "lime_drop_event_manager_register", 2);
	private static var lime_file_dialog_open_directory = CFFI.load("lime", "lime_file_dialog_open_directory", 3);
	private static var lime_file_dialog_open_file = CFFI.load("lime", "lime_file_dialog_open_file", 3);
	private static var lime_file_dialog_open_files = CFFI.load("lime", "lime_file_dialog_open_files", 3);
	private static var lime_file_dialog_save_file = CFFI.load("lime", "lime_file_dialog_save_file", 3);
	private static var lime_file_watcher_create = CFFI.load("lime", "lime_file_watcher_create", 1);
	private static var lime_file_watcher_add_directory = CFFI.load("lime", "lime_file_watcher_add_directory", 3);
	private static var lime_file_watcher_remove_directory = CFFI.load("lime", "lime_file_watcher_remove_directory", 2);
	private static var lime_file_watcher_update = CFFI.load("lime", "lime_file_watcher_update", 1);
	private static var lime_font_get_ascender = CFFI.load("lime", "lime_font_get_ascender", 1);
	private static var lime_font_get_descender = CFFI.load("lime", "lime_font_get_descender", 1);
	private static var lime_font_get_family_name = CFFI.load("lime", "lime_font_get_family_name", 1);
	private static var lime_font_get_glyph_index = CFFI.load("lime", "lime_font_get_glyph_index", 2);
	private static var lime_font_get_glyph_indices = CFFI.load("lime", "lime_font_get_glyph_indices", 2);
	private static var lime_font_get_glyph_metrics = CFFI.load("lime", "lime_font_get_glyph_metrics", 2);
	private static var lime_font_get_height = CFFI.load("lime", "lime_font_get_height", 1);
	private static var lime_font_get_num_glyphs = CFFI.load("lime", "lime_font_get_num_glyphs", 1);
	private static var lime_font_get_underline_position = CFFI.load("lime", "lime_font_get_underline_position", 1);
	private static var lime_font_get_underline_thickness = CFFI.load("lime", "lime_font_get_underline_thickness", 1);
	private static var lime_font_get_units_per_em = CFFI.load("lime", "lime_font_get_units_per_em", 1);
	private static var lime_font_load = CFFI.load("lime", "lime_font_load", 1);
	private static var lime_font_load_bytes = CFFI.load("lime", "lime_font_load_bytes", 1);
	private static var lime_font_load_file = CFFI.load("lime", "lime_font_load_file", 1);
	private static var lime_font_outline_decompose = CFFI.load("lime", "lime_font_outline_decompose", 2);
	private static var lime_font_render_glyph = CFFI.load("lime", "lime_font_render_glyph", 3);
	private static var lime_font_render_glyphs = CFFI.load("lime", "lime_font_render_glyphs", 3);
	private static var lime_font_set_size = CFFI.load("lime", "lime_font_set_size", 2);
	private static var lime_gamepad_add_mappings = CFFI.load("lime", "lime_gamepad_add_mappings", 1);
	private static var lime_gamepad_get_device_guid = CFFI.load("lime", "lime_gamepad_get_device_guid", 1);
	private static var lime_gamepad_get_device_name = CFFI.load("lime", "lime_gamepad_get_device_name", 1);
	private static var lime_gamepad_event_manager_register = CFFI.load("lime", "lime_gamepad_event_manager_register", 2);
	private static var lime_gzip_compress = CFFI.load("lime", "lime_gzip_compress", 2);
	private static var lime_gzip_decompress = CFFI.load("lime", "lime_gzip_decompress", 2);
	private static var lime_haptic_vibrate = CFFI.load("lime", "lime_haptic_vibrate", 2);
	private static var lime_image_encode = CFFI.load("lime", "lime_image_encode", 4);
	private static var lime_image_load = CFFI.load("lime", "lime_image_load", 2);
	private static var lime_image_load_bytes = CFFI.load("lime", "lime_image_load_bytes", 2);
	private static var lime_image_load_file = CFFI.load("lime", "lime_image_load_file", 2);
	private static var lime_image_data_util_color_transform = CFFI.load("lime", "lime_image_data_util_color_transform", 3);
	private static var lime_image_data_util_copy_channel = CFFI.load("lime", "lime_image_data_util_copy_channel", -1);
	private static var lime_image_data_util_copy_pixels = CFFI.load("lime", "lime_image_data_util_copy_pixels", -1);
	private static var lime_image_data_util_fill_rect = CFFI.load("lime", "lime_image_data_util_fill_rect", 4);
	private static var lime_image_data_util_flood_fill = CFFI.load("lime", "lime_image_data_util_flood_fill", 5);
	private static var lime_image_data_util_get_pixels = CFFI.load("lime", "lime_image_data_util_get_pixels", 4);
	private static var lime_image_data_util_merge = CFFI.load("lime", "lime_image_data_util_merge", -1);
	private static var lime_image_data_util_multiply_alpha = CFFI.load("lime", "lime_image_data_util_multiply_alpha", 1);
	private static var lime_image_data_util_resize = CFFI.load("lime", "lime_image_data_util_resize", 4);
	private static var lime_image_data_util_set_format = CFFI.load("lime", "lime_image_data_util_set_format", 2);
	private static var lime_image_data_util_set_pixels = CFFI.load("lime", "lime_image_data_util_set_pixels", -1);
	private static var lime_image_data_util_threshold = CFFI.load("lime", "lime_image_data_util_threshold", -1);
	private static var lime_image_data_util_unmultiply_alpha = CFFI.load("lime", "lime_image_data_util_unmultiply_alpha", 1);
	private static var lime_joystick_get_device_guid = CFFI.load("lime", "lime_joystick_get_device_guid", 1);
	private static var lime_joystick_get_device_name = CFFI.load("lime", "lime_joystick_get_device_name", 1);
	private static var lime_joystick_get_num_axes = CFFI.load("lime", "lime_joystick_get_num_axes", 1);
	private static var lime_joystick_get_num_buttons = CFFI.load("lime", "lime_joystick_get_num_buttons", 1);
	private static var lime_joystick_get_num_hats = CFFI.load("lime", "lime_joystick_get_num_hats", 1);
	private static var lime_joystick_get_num_trackballs = CFFI.load("lime", "lime_joystick_get_num_trackballs", 1);
	private static var lime_joystick_event_manager_register = CFFI.load("lime", "lime_joystick_event_manager_register", 2);
	private static var lime_jpeg_decode_bytes = CFFI.load("lime", "lime_jpeg_decode_bytes", 3);
	private static var lime_jpeg_decode_file = CFFI.load("lime", "lime_jpeg_decode_file", 3);
	private static var lime_key_code_from_scan_code = CFFI.load("lime", "lime_key_code_from_scan_code", 1);
	private static var lime_key_code_to_scan_code = CFFI.load("lime", "lime_key_code_to_scan_code", 1);
	private static var lime_key_event_manager_register = CFFI.load("lime", "lime_key_event_manager_register", 2);
	private static var lime_lzma_compress = CFFI.load("lime", "lime_lzma_compress", 2);
	private static var lime_lzma_decompress = CFFI.load("lime", "lime_lzma_decompress", 2);
	private static var lime_mouse_event_manager_register = CFFI.load("lime", "lime_mouse_event_manager_register", 2);
	private static var lime_neko_execute = CFFI.load("lime", "lime_neko_execute", 1);
	private static var lime_png_decode_bytes = CFFI.load("lime", "lime_png_decode_bytes", 3);
	private static var lime_png_decode_file = CFFI.load("lime", "lime_png_decode_file", 3);
	private static var lime_render_event_manager_register = CFFI.load("lime", "lime_render_event_manager_register", 2);
	private static var lime_sensor_event_manager_register = CFFI.load("lime", "lime_sensor_event_manager_register", 2);
	private static var lime_system_get_allow_screen_timeout = CFFI.load("lime", "lime_system_get_allow_screen_timeout", 0);
	private static var lime_system_set_allow_screen_timeout = CFFI.load("lime", "lime_system_set_allow_screen_timeout", 1);
	private static var lime_system_get_device_model = CFFI.load("lime", "lime_system_get_device_model", 0);
	private static var lime_system_get_device_vendor = CFFI.load("lime", "lime_system_get_device_vendor", 0);
	private static var lime_system_get_directory = CFFI.load("lime", "lime_system_get_directory", 3);
	private static var lime_system_get_display = CFFI.load("lime", "lime_system_get_display", 1);
	private static var lime_system_get_ios_tablet = CFFI.load("lime", "lime_system_get_ios_tablet", 0);
	private static var lime_system_get_num_displays = CFFI.load("lime", "lime_system_get_num_displays", 0);
	private static var lime_system_get_platform_label = CFFI.load("lime", "lime_system_get_platform_label", 0);
	private static var lime_system_get_platform_name = CFFI.load("lime", "lime_system_get_platform_name", 0);
	private static var lime_system_get_platform_version = CFFI.load("lime", "lime_system_get_platform_version", 0);
	private static var lime_system_get_timer = CFFI.load("lime", "lime_system_get_timer", 0);
	private static var lime_system_open_file = CFFI.load("lime", "lime_system_open_file", 1);
	private static var lime_system_open_url = CFFI.load("lime", "lime_system_open_url", 2);
	private static var lime_text_event_manager_register = CFFI.load("lime", "lime_text_event_manager_register", 2);
	private static var lime_touch_event_manager_register = CFFI.load("lime", "lime_touch_event_manager_register", 2);
	private static var lime_window_alert = CFFI.load("lime", "lime_window_alert", 3);
	private static var lime_window_close = CFFI.load("lime", "lime_window_close", 1);
	private static var lime_window_context_flip = CFFI.load("lime", "lime_window_context_flip", 1);
	private static var lime_window_context_lock = CFFI.load("lime", "lime_window_context_lock", 1);
	private static var lime_window_context_make_current = CFFI.load("lime", "lime_window_context_make_current", 1);
	private static var lime_window_context_unlock = CFFI.load("lime", "lime_window_context_unlock", 1);
	private static var lime_window_create = CFFI.load("lime", "lime_window_create", 5);
	private static var lime_window_focus = CFFI.load("lime", "lime_window_focus", 1);
	private static var lime_window_get_context = CFFI.load("lime", "lime_window_get_context", 1);
	private static var lime_window_get_context_type = CFFI.load("lime", "lime_window_get_context_type", 1);
	private static var lime_window_get_display = CFFI.load("lime", "lime_window_get_display", 1);
	private static var lime_window_get_display_mode = CFFI.load("lime", "lime_window_get_display_mode", 1);
	private static var lime_window_get_height = CFFI.load("lime", "lime_window_get_height", 1);
	private static var lime_window_get_id = CFFI.load("lime", "lime_window_get_id", 1);
	private static var lime_window_get_mouse_lock = CFFI.load("lime", "lime_window_get_mouse_lock", 1);
	private static var lime_window_get_scale = CFFI.load("lime", "lime_window_get_scale", 1);
	private static var lime_window_get_text_input_enabled = CFFI.load("lime", "lime_window_get_text_input_enabled", 1);
	private static var lime_window_get_width = CFFI.load("lime", "lime_window_get_width", 1);
	private static var lime_window_get_x = CFFI.load("lime", "lime_window_get_x", 1);
	private static var lime_window_get_y = CFFI.load("lime", "lime_window_get_y", 1);
	private static var lime_window_move = CFFI.load("lime", "lime_window_move", 3);
	private static var lime_window_read_pixels = CFFI.load("lime", "lime_window_read_pixels", 3);
	private static var lime_window_resize = CFFI.load("lime", "lime_window_resize", 3);
	private static var lime_window_set_borderless = CFFI.load("lime", "lime_window_set_borderless", 2);
	private static var lime_window_set_cursor = CFFI.load("lime", "lime_window_set_cursor", 2);
	private static var lime_window_set_display_mode = CFFI.load("lime", "lime_window_set_display_mode", 2);
	private static var lime_window_set_fullscreen = CFFI.load("lime", "lime_window_set_fullscreen", 2);
	private static var lime_window_set_icon = CFFI.load("lime", "lime_window_set_icon", 2);
	private static var lime_window_set_maximized = CFFI.load("lime", "lime_window_set_maximized", 2);
	private static var lime_window_set_minimized = CFFI.load("lime", "lime_window_set_minimized", 2);
	private static var lime_window_set_mouse_lock = CFFI.load("lime", "lime_window_set_mouse_lock", 2);
	private static var lime_window_set_resizable = CFFI.load("lime", "lime_window_set_resizable", 2);
	private static var lime_window_set_text_input_enabled = CFFI.load("lime", "lime_window_set_text_input_enabled", 2);
	private static var lime_window_set_title = CFFI.load("lime", "lime_window_set_title", 2);
	private static var lime_window_warp_mouse = CFFI.load("lime", "lime_window_warp_mouse", 3);
	private static var lime_window_event_manager_register = CFFI.load("lime", "lime_window_event_manager_register", 2);
	private static var lime_zlib_compress = CFFI.load("lime", "lime_zlib_compress", 2);
	private static var lime_zlib_decompress = CFFI.load("lime", "lime_zlib_decompress", 2);
	#end

	#if hl
	@:hlNative("lime", "lime_application_create") private static function lime_application_create():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_application_event_manager_register") private static function lime_application_event_manager_register(callback:Void->Void,
		eventObject:ApplicationEventInfo):Void {}

	@:hlNative("lime", "lime_application_exec") private static function lime_application_exec(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_application_init") private static function lime_application_init(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_application_quit") private static function lime_application_quit(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_application_set_frame_rate") private static function lime_application_set_frame_rate(handle:CFFIPointer, value:Float):Void {}

	@:hlNative("lime", "lime_application_update") private static function lime_application_update(handle:CFFIPointer):Bool
	{
		return false;
	}

	// @:cffi private static function lime_audio_load (data:Dynamic, buffer:Dynamic):Dynamic;
	@:hlNative("lime", "lime_audio_load_bytes") private static function lime_audio_load_bytes(data:Bytes, buffer:AudioBuffer):AudioBuffer
	{
		return null;
	}

	@:hlNative("lime", "lime_audio_load_file") private static function lime_audio_load_file(path:String, buffer:AudioBuffer):AudioBuffer
	{
		return null;
	}

	@:hlNative("lime", "lime_bytes_from_data_pointer") private static function lime_bytes_from_data_pointer(data:Float, length:Int, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_bytes_get_data_pointer") private static function lime_bytes_get_data_pointer(data:Bytes):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_bytes_get_data_pointer_offset") private static function lime_bytes_get_data_pointer_offset(data:Bytes, offset:Int):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_bytes_read_file") private static function lime_bytes_read_file(path:String, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_cffi_get_native_pointer") private static function lime_cffi_get_native_pointer(ptr:CFFIPointer):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_clipboard_event_manager_register") private static function lime_clipboard_event_manager_register(callback:Void->Void,
		eventObject:ClipboardEventInfo):Void {}

	@:hlNative("lime", "lime_clipboard_get_text") private static function lime_clipboard_get_text():hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_clipboard_set_text") private static function lime_clipboard_set_text(text:String):Void {}

	@:hlNative("lime", "lime_data_pointer_offset") private static function lime_data_pointer_offset(dataPointer:DataPointer, offset:Int):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_deflate_compress") private static function lime_deflate_compress(data:Bytes, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_deflate_decompress") private static function lime_deflate_decompress(data:Bytes, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_drop_event_manager_register") private static function lime_drop_event_manager_register(callback:Void->Void,
		eventObject:DropEventInfo):Void {}

	@:hlNative("lime", "lime_file_dialog_open_directory") private static function lime_file_dialog_open_directory(title:String, filter:String,
			defaultPath:String):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_file_dialog_open_file") private static function lime_file_dialog_open_file(title:String, filter:String,
			defaultPath:String):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_file_dialog_open_files") private static function lime_file_dialog_open_files(title:String, filter:String,
			defaultPath:String):hl.NativeArray<hl.Bytes>
	{
		return null;
	}

	@:hlNative("lime", "lime_file_dialog_save_file") private static function lime_file_dialog_save_file(title:String, filter:String,
			defaultPath:String):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_file_watcher_create") private static function lime_file_watcher_create(callback:Dynamic):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_file_watcher_add_directory") private static function lime_file_watcher_add_directory(handle:CFFIPointer, path:String,
			recursive:Bool):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_file_watcher_remove_directory") private static function lime_file_watcher_remove_directory(handle:CFFIPointer,
		watchID:Int):Void {}

	@:hlNative("lime", "lime_file_watcher_update") private static function lime_file_watcher_update(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_font_get_ascender") private static function lime_font_get_ascender(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_font_get_descender") private static function lime_font_get_descender(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_font_get_family_name") private static function lime_font_get_family_name(handle:CFFIPointer):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_font_get_glyph_index") private static function lime_font_get_glyph_index(handle:CFFIPointer, character:String):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_font_get_glyph_indices") private static function lime_font_get_glyph_indices(handle:CFFIPointer,
			characters:String):hl.NativeArray<Int>
	{
		return null;
	}

	@:hlNative("lime", "lime_font_get_glyph_metrics") private static function lime_font_get_glyph_metrics(handle:CFFIPointer, index:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_font_get_height") private static function lime_font_get_height(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_font_get_num_glyphs") private static function lime_font_get_num_glyphs(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_font_get_underline_position") private static function lime_font_get_underline_position(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_font_get_underline_thickness") private static function lime_font_get_underline_thickness(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_font_get_units_per_em") private static function lime_font_get_units_per_em(handle:CFFIPointer):Int
	{
		return 0;
	}

	// @:hlNative("lime", "") private static function lime_font_load (data:Dynamic):Dynamic { return null; }
	@:hlNative("lime", "lime_font_load_bytes") private static function lime_font_load_bytes(data:Bytes):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_font_load_file") private static function lime_font_load_file(path:String):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_font_outline_decompose") private static function lime_font_outline_decompose(handle:CFFIPointer, size:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_font_render_glyph") private static function lime_font_render_glyph(handle:CFFIPointer, index:Int, data:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_font_render_glyphs") private static function lime_font_render_glyphs(handle:CFFIPointer, indices:hl.NativeArray<Int>,
			data:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_font_set_size") private static function lime_font_set_size(handle:CFFIPointer, size:Int):Void {}

	@:hlNative("lime", "lime_gamepad_add_mappings") private static function lime_gamepad_add_mappings(mappings:hl.NativeArray<String>):Void {}

	@:hlNative("lime", "lime_gamepad_get_device_guid") private static function lime_gamepad_get_device_guid(id:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_gamepad_get_device_name") private static function lime_gamepad_get_device_name(id:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_gamepad_event_manager_register") private static function lime_gamepad_event_manager_register(callback:Void->Void,
		eventObject:GamepadEventInfo):Void {}

	@:hlNative("lime", "lime_gzip_compress") private static function lime_gzip_compress(data:Bytes, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_gzip_decompress") private static function lime_gzip_decompress(data:Bytes, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_haptic_vibrate") private static function lime_haptic_vibrate(period:Int, duration:Int):Void {}

	@:hlNative("lime", "lime_image_encode") private static function lime_image_encode(data:ImageBuffer, type:Int, quality:Int, bytes:Bytes):Bytes
	{
		return null;
	}

	// @:cffi private static function lime_image_load (data:Dynamic, buffer:Dynamic):Dynamic;
	@:hlNative("lime", "lime_image_load_bytes") private static function lime_image_load_bytes(data:Bytes, buffer:ImageBuffer):ImageBuffer
	{
		return null;
	}

	@:hlNative("lime", "lime_image_load_file") private static function lime_image_load_file(path:String, buffer:ImageBuffer):ImageBuffer
	{
		return null;
	}

	@:hlNative("lime", "lime_image_data_util_color_transform") private static function lime_image_data_util_color_transform(image:Image, rect:Rectangle,
		colorMatrix:ArrayBufferView):Void {}

	// @:cffi private static function lime_image_data_util_copy_channel (image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic, srcChannel:Int, destChannel:Int):Void;
	@:hlNative("lime", "lime_image_data_util_copy_channel") private static function lime_image_data_util_copy_channel(image:Image, sourceImage:Image,
		sourceRect:Rectangle, destPoint:Vector2, srcChannel:Int, destChannel:Int):Void {}

	// @:cffi private static function lime_image_data_util_copy_pixels (image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic, alphaImage:Dynamic, alphaPoint:Dynamic, mergeAlpha:Bool):Void;
	@:hlNative("lime", "lime_image_data_util_copy_pixels") private static function lime_image_data_util_copy_pixels(image:Image, sourceImage:Image,
		sourceRect:Rectangle, destPoint:Vector2, alphaImage:Image, alphaPoint:Vector2, mergeAlpha:Bool):Void {}

	@:hlNative("lime", "lime_image_data_util_fill_rect") private static function lime_image_data_util_fill_rect(image:Image, rect:Rectangle, rg:Int,
		ba:Int):Void {}

	@:hlNative("lime", "lime_image_data_util_flood_fill") private static function lime_image_data_util_flood_fill(image:Image, x:Int, y:Int, rg:Int,
		ba:Int):Void {}

	@:hlNative("lime", "lime_image_data_util_get_pixels") private static function lime_image_data_util_get_pixels(image:Image, rect:Rectangle, format:Int,
		bytes:Bytes):Void {}

	// @:cffi private static function lime_image_data_util_merge (image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic, redMultiplier:Int, greenMultiplier:Int, blueMultiplier:Int, alphaMultiplier:Int):Void;
	@:hlNative("lime", "lime_image_data_util_merge") private static function lime_image_data_util_merge(image:Image, sourceImage:Image, sourceRect:Rectangle,
		destPoint:Vector2, redMultiplier:Int, greenMultiplier:Int, blueMultiplier:Int, alphaMultiplier:Int):Void {}

	@:hlNative("lime", "lime_image_data_util_multiply_alpha") private static function lime_image_data_util_multiply_alpha(image:Image):Void {}

	@:hlNative("lime", "lime_image_data_util_resize") private static function lime_image_data_util_resize(image:Image, buffer:ImageBuffer, width:Int,
		height:Int):Void {}

	@:hlNative("lime", "lime_image_data_util_set_format") private static function lime_image_data_util_set_format(image:Image, format:Int):Void {}

	// @:cffi private static function lime_image_data_util_set_pixels (image:Dynamic, rect:Dynamic, bytes:Dynamic, offset:Int, format:Int, endian:Int):Void;
	@:hlNative("lime", "lime_image_data_util_set_pixels") private static function lime_image_data_util_set_pixels(image:Image, rect:Rectangle, bytes:Bytes,
		offset:Int, format:Int, endian:Int):Void {}

	// @:cffi private static function lime_image_data_util_threshold (image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic, operation:Int, thresholdRG:Int, thresholdBA:Int, colorRG:Int, colorBA:Int, maskRG:Int, maskBA:Int, copySource:Bool):Int;
	@:hlNative("lime", "lime_image_data_util_threshold") private static function lime_image_data_util_threshold(image:Image, sourceImage:Image,
			sourceRect:Rectangle, destPoint:Vector2, operation:Int, thresholdRG:Int, thresholdBA:Int, colorRG:Int, colorBA:Int, maskRG:Int, maskBA:Int,
			copySource:Bool):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_image_data_util_unmultiply_alpha") private static function lime_image_data_util_unmultiply_alpha(image:Image):Void {}

	@:hlNative("lime", "lime_joystick_get_device_guid") private static function lime_joystick_get_device_guid(id:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_joystick_get_device_name") private static function lime_joystick_get_device_name(id:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_joystick_get_num_axes") private static function lime_joystick_get_num_axes(id:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_joystick_get_num_buttons") private static function lime_joystick_get_num_buttons(id:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_joystick_get_num_hats") private static function lime_joystick_get_num_hats(id:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_joystick_get_num_trackballs") private static function lime_joystick_get_num_trackballs(id:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_joystick_event_manager_register") private static function lime_joystick_event_manager_register(callback:Void->Void,
		eventObject:JoystickEventInfo):Void {}

	@:hlNative("lime", "lime_jpeg_decode_bytes") private static function lime_jpeg_decode_bytes(data:Bytes, decodeData:Bool, buffer:ImageBuffer):ImageBuffer
	{
		return null;
	}

	@:hlNative("lime", "lime_jpeg_decode_file") private static function lime_jpeg_decode_file(path:String, decodeData:Bool, buffer:ImageBuffer):ImageBuffer
	{
		return null;
	}

	@:hlNative("lime", "lime_key_code_from_scan_code") private static function lime_key_code_from_scan_code(scanCode:hl.F32):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_key_code_to_scan_code") private static function lime_key_code_to_scan_code(keyCode:hl.F32):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_key_event_manager_register") private static function lime_key_event_manager_register(callback:Void->Void,
		eventObject:KeyEventInfo):Void {}

	@:hlNative("lime", "lime_lzma_compress") private static function lime_lzma_compress(data:Bytes, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_lzma_decompress") private static function lime_lzma_decompress(data:Bytes, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_mouse_event_manager_register") private static function lime_mouse_event_manager_register(callback:Void->Void,
		eventObject:MouseEventInfo):Void {}

	// @:cffi private static function lime_neko_execute (module:String):Void;
	@:hlNative("lime", "lime_png_decode_bytes") private static function lime_png_decode_bytes(data:Bytes, decodeData:Bool, buffer:ImageBuffer):ImageBuffer
	{
		return null;
	}

	@:hlNative("lime", "lime_png_decode_file") private static function lime_png_decode_file(path:String, decodeData:Bool, buffer:ImageBuffer):ImageBuffer
	{
		return null;
	}

	@:hlNative("lime", "lime_render_event_manager_register") private static function lime_render_event_manager_register(callback:Void->Void,
		eventObject:RenderEventInfo):Void {}

	@:hlNative("lime", "lime_sensor_event_manager_register") private static function lime_sensor_event_manager_register(callback:Void->Void,
		eventObject:SensorEventInfo):Void {}

	@:hlNative("lime", "lime_system_get_allow_screen_timeout") private static function lime_system_get_allow_screen_timeout():Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_system_set_allow_screen_timeout") private static function lime_system_set_allow_screen_timeout(value:Bool):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_system_get_device_model") private static function lime_system_get_device_model():hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_system_get_device_vendor") private static function lime_system_get_device_vendor():hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_system_get_directory") private static function lime_system_get_directory(type:Int, company:String, title:String):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_system_get_display") private static function lime_system_get_display(index:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_system_get_ios_tablet") private static function lime_system_get_ios_tablet():Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_system_get_num_displays") private static function lime_system_get_num_displays():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_system_get_platform_label") private static function lime_system_get_platform_label():hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_system_get_platform_name") private static function lime_system_get_platform_name():hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_system_get_platform_version") private static function lime_system_get_platform_version():hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_system_get_timer") private static function lime_system_get_timer():Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_system_open_file") private static function lime_system_open_file(path:String):Void {}

	@:hlNative("lime", "lime_system_open_url") private static function lime_system_open_url(url:String, target:String):Void {}

	@:hlNative("lime", "lime_text_event_manager_register") private static function lime_text_event_manager_register(callback:Void->Void,
		eventObject:TextEventInfo):Void {}

	@:hlNative("lime", "lime_touch_event_manager_register") private static function lime_touch_event_manager_register(callback:Void->Void,
		eventObject:TouchEventInfo):Void {}

	@:hlNative("lime", "lime_window_alert") private static function lime_window_alert(handle:CFFIPointer, message:String, title:String):Void {}

	@:hlNative("lime", "lime_window_close") private static function lime_window_close(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_window_context_flip") private static function lime_window_context_flip(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_window_context_lock") private static function lime_window_context_lock(handle:CFFIPointer):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_window_context_make_current") private static function lime_window_context_make_current(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_window_context_unlock") private static function lime_window_context_unlock(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_window_create") private static function lime_window_create(application:CFFIPointer, width:Int, height:Int, flags:Int,
			title:String):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_window_focus") private static function lime_window_focus(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_window_get_context") private static function lime_window_get_context(handle:CFFIPointer):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_window_get_context_type") private static function lime_window_get_context_type(handle:CFFIPointer):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_window_get_display") private static function lime_window_get_display(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_window_get_display_mode") private static function lime_window_get_display_mode(handle:CFFIPointer, result:DisplayMode):Void {}

	@:hlNative("lime", "lime_window_get_height") private static function lime_window_get_height(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_window_get_id") private static function lime_window_get_id(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_window_get_mouse_lock") private static function lime_window_get_mouse_lock(handle:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_window_get_scale") private static function lime_window_get_scale(handle:CFFIPointer):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_window_get_text_input_enabled") private static function lime_window_get_text_input_enabled(handle:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_window_get_width") private static function lime_window_get_width(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_window_get_x") private static function lime_window_get_x(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_window_get_y") private static function lime_window_get_y(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_window_move") private static function lime_window_move(handle:CFFIPointer, x:Int, y:Int):Void {}

	@:hlNative("lime", "lime_window_read_pixels") private static function lime_window_read_pixels(handle:CFFIPointer, rect:Rectangle,
			imageBuffer:ImageBuffer):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_window_resize") private static function lime_window_resize(handle:CFFIPointer, width:Int, height:Int):Void {}

	@:hlNative("lime", "lime_window_set_borderless") private static function lime_window_set_borderless(handle:CFFIPointer, borderless:Bool):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_window_set_cursor") private static function lime_window_set_cursor(handle:CFFIPointer, cursor:Int):Void {}

	@:hlNative("lime", "lime_window_set_display_mode") private static function lime_window_set_display_mode(handle:CFFIPointer, displayMode:DisplayMode,
		result:DisplayMode):Void {}

	@:hlNative("lime", "lime_window_set_fullscreen") private static function lime_window_set_fullscreen(handle:CFFIPointer, fullscreen:Bool):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_window_set_icon") private static function lime_window_set_icon(handle:CFFIPointer, buffer:ImageBuffer):Void {}

	@:hlNative("lime", "lime_window_set_maximized") private static function lime_window_set_maximized(handle:CFFIPointer, maximized:Bool):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_window_set_minimized") private static function lime_window_set_minimized(handle:CFFIPointer, minimized:Bool):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_window_set_mouse_lock") private static function lime_window_set_mouse_lock(handle:CFFIPointer, mouseLock:Bool):Void {}

	@:hlNative("lime", "lime_window_set_resizable") private static function lime_window_set_resizable(handle:CFFIPointer, resizable:Bool):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_window_set_text_input_enabled") private static function lime_window_set_text_input_enabled(handle:CFFIPointer,
		enabled:Bool):Void {}

	@:hlNative("lime", "lime_window_set_title") private static function lime_window_set_title(handle:CFFIPointer, title:String):String
	{
		return null;
	}

	@:hlNative("lime", "lime_window_warp_mouse") private static function lime_window_warp_mouse(handle:CFFIPointer, x:Int, y:Int):Void {}

	@:hlNative("lime", "lime_window_event_manager_register") private static function lime_window_event_manager_register(callback:Void->Void,
		eventObject:WindowEventInfo):Void {}

	@:hlNative("lime", "lime_zlib_compress") private static function lime_zlib_compress(data:Bytes, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_zlib_decompress") private static function lime_zlib_decompress(data:Bytes, bytes:Bytes):Bytes
	{
		return null;
	}
	#end
	#end
	#if (lime_cffi && !macro && android)
	#if (cpp && !cppia)
	#if (disable_cffi || haxe_ver < "3.4.0")
	@:cffi private static function lime_jni_call_member(jniMethod:Dynamic, jniObject:Dynamic, args:Dynamic):Dynamic;

	@:cffi private static function lime_jni_call_static(jniMethod:Dynamic, args:Dynamic):Dynamic;

	@:cffi private static function lime_jni_create_field(className:String, field:String, signature:String, isStatic:Bool):Dynamic;

	@:cffi private static function lime_jni_create_method(className:String, method:String, signature:String, isStatic:Bool, quiet:Bool):Dynamic;

	@:cffi private static function lime_jni_get_env():Float;

	@:cffi private static function lime_jni_get_member(jniField:Dynamic, jniObject:Dynamic):Dynamic;

	@:cffi private static function lime_jni_get_static(jniField:Dynamic):Dynamic;

	@:cffi private static function lime_jni_post_ui_callback(callback:Dynamic):Void;

	@:cffi private static function lime_jni_set_member(jniField:Dynamic, jniObject:Dynamic, value:Dynamic):Void;

	@:cffi private static function lime_jni_set_static(jniField:Dynamic, value:Dynamic):Void;
	#else
	private static var lime_jni_call_member = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_jni_call_member", "oooo", false));
	private static var lime_jni_call_static = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_jni_call_static", "ooo",
		false));
	private static var lime_jni_create_field = new cpp.Callable<String->String->String->Bool->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_jni_create_field", "sssbo", false));
	private static var lime_jni_create_method = new cpp.Callable<String->String->String->Bool->Bool->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_jni_create_method", "sssbbo", false));
	private static var lime_jni_get_env = new cpp.Callable<Void->Float>(cpp.Prime._loadPrime("lime", "lime_jni_get_env", "d", false));
	private static var lime_jni_get_member = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_jni_get_member", "ooo",
		false));
	private static var lime_jni_get_static = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_jni_get_static", "oo", false));
	private static var lime_jni_post_ui_callback = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_jni_post_ui_callback", "ov",
		false));
	private static var lime_jni_set_member = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_jni_set_member", "ooov", false));
	private static var lime_jni_set_static = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_jni_set_static", "oov",
		false));
	#end
	#end
	#if !cpp
	@:cffi private static function lime_jni_call_member(jniMethod:Dynamic, jniObject:Dynamic, args:Dynamic):Dynamic;

	@:cffi private static function lime_jni_call_static(jniMethod:Dynamic, args:Dynamic):Dynamic;

	@:cffi private static function lime_jni_create_field(className:String, field:String, signature:String, isStatic:Bool):Dynamic;

	@:cffi private static function lime_jni_create_method(className:String, method:String, signature:String, isStatic:Bool, quiet:Bool):Dynamic;

	@:cffi private static function lime_jni_get_env():Float;

	@:cffi private static function lime_jni_get_member(jniField:Dynamic, jniObject:Dynamic):Dynamic;

	@:cffi private static function lime_jni_get_static(jniField:Dynamic):Dynamic;

	@:cffi private static function lime_jni_post_ui_callback(callback:Dynamic):Void;

	@:cffi private static function lime_jni_set_member(jniField:Dynamic, jniObject:Dynamic, value:Dynamic):Void;

	@:cffi private static function lime_jni_set_static(jniField:Dynamic, value:Dynamic):Void;
	#end
	#end
	#if (lime_cffi && !macro && lime_openal)
	#if (cpp && !cppia)
	#if (disable_cffi || haxe_ver < "3.4.0")
	@:cffi private static function lime_al_buffer_data(buffer:CFFIPointer, format:Int, data:Dynamic, size:Int, freq:Int):Void;

	@:cffi private static function lime_al_buffer3f(buffer:CFFIPointer, param:Int, value1:Float32, value2:Float32, value3:Float32):Void;

	@:cffi private static function lime_al_buffer3i(buffer:CFFIPointer, param:Int, value1:Int, value2:Int, value3:Int):Void;

	@:cffi private static function lime_al_bufferf(buffer:CFFIPointer, param:Int, value:Float32):Void;

	@:cffi private static function lime_al_bufferfv(buffer:CFFIPointer, param:Int, values:Dynamic):Void;

	@:cffi private static function lime_al_bufferi(buffer:CFFIPointer, param:Int, value:Int):Void;

	@:cffi private static function lime_al_bufferiv(buffer:CFFIPointer, param:Int, values:Dynamic):Void;

	@:cffi private static function lime_al_cleanup():Void;

	@:cffi private static function lime_al_delete_buffer(buffer:CFFIPointer):Void;

	@:cffi private static function lime_al_delete_buffers(n:Int, buffers:Dynamic):Void;

	@:cffi private static function lime_al_delete_source(source:CFFIPointer):Void;

	@:cffi private static function lime_al_delete_sources(n:Int, sources:Dynamic):Void;

	@:cffi private static function lime_al_disable(capability:Int):Void;

	@:cffi private static function lime_al_distance_model(distanceModel:Int):Void;

	@:cffi private static function lime_al_doppler_factor(value:Float32):Void;

	@:cffi private static function lime_al_doppler_velocity(value:Float32):Void;

	@:cffi private static function lime_al_enable(capability:Int):Void;

	@:cffi private static function lime_al_gen_source():CFFIPointer;

	@:cffi private static function lime_al_gen_sources(n:Int):Array<CFFIPointer>;

	@:cffi private static function lime_al_get_boolean(param:Int):Bool;

	@:cffi private static function lime_al_get_booleanv(param:Int, count:Int):Array<Bool>;

	@:cffi private static function lime_al_gen_buffer():CFFIPointer;

	@:cffi private static function lime_al_gen_buffers(n:Int):Array<CFFIPointer>;

	@:cffi private static function lime_al_get_buffer3f(buffer:CFFIPointer, param:Int):Array<Float>;

	@:cffi private static function lime_al_get_buffer3i(buffer:CFFIPointer, param:Int):Array<Int>;

	@:cffi private static function lime_al_get_bufferf(buffer:CFFIPointer, param:Int):Float32;

	@:cffi private static function lime_al_get_bufferfv(buffer:CFFIPointer, param:Int, count:Int):Array<Float>;

	@:cffi private static function lime_al_get_bufferi(buffer:CFFIPointer, param:Int):Int;

	@:cffi private static function lime_al_get_bufferiv(buffer:CFFIPointer, param:Int, count:Int):Array<Int>;

	@:cffi private static function lime_al_get_double(param:Int):Float;

	@:cffi private static function lime_al_get_doublev(param:Int, count:Int):Array<Float>;

	@:cffi private static function lime_al_get_enum_value(ename:String):Int;

	@:cffi private static function lime_al_get_error():Int;

	@:cffi private static function lime_al_get_float(param:Int):Float32;

	@:cffi private static function lime_al_get_floatv(param:Int, count:Int):Array<Float>;

	@:cffi private static function lime_al_get_integer(param:Int):Int;

	@:cffi private static function lime_al_get_integerv(param:Int, count:Int):Array<Int>;

	@:cffi private static function lime_al_get_listener3f(param:Int):Array<Float>;

	@:cffi private static function lime_al_get_listener3i(param:Int):Array<Int>;

	@:cffi private static function lime_al_get_listenerf(param:Int):Float32;

	@:cffi private static function lime_al_get_listenerfv(param:Int, count:Int):Array<Float>;

	@:cffi private static function lime_al_get_listeneri(param:Int):Int;

	@:cffi private static function lime_al_get_listeneriv(param:Int, count:Int):Array<Int>;

	@:cffi private static function lime_al_get_proc_address(fname:String):Float;

	@:cffi private static function lime_al_get_source3f(source:CFFIPointer, param:Int):Array<Float>;

	@:cffi private static function lime_al_get_source3i(source:CFFIPointer, param:Int):Array<Int>;

	@:cffi private static function lime_al_get_sourcef(source:CFFIPointer, param:Int):Float32;

	@:cffi private static function lime_al_get_sourcefv(source:CFFIPointer, param:Int, count:Int):Array<Float>;

	@:cffi private static function lime_al_get_sourcei(source:CFFIPointer, param:Int):Dynamic;

	@:cffi private static function lime_al_get_sourceiv(source:CFFIPointer, param:Int, count:Int):Array<Int>;

	@:cffi private static function lime_al_get_string(param:Int):Dynamic;

	@:cffi private static function lime_al_is_buffer(buffer:CFFIPointer):Bool;

	@:cffi private static function lime_al_is_enabled(capability:Int):Bool;

	@:cffi private static function lime_al_is_extension_present(extname:String):Bool;

	@:cffi private static function lime_al_is_source(source:CFFIPointer):Bool;

	@:cffi private static function lime_al_listener3f(param:Int, value1:Float32, value2:Float32, value3:Float32):Void;

	@:cffi private static function lime_al_listener3i(param:Int, value1:Int, value2:Int, value3:Int):Void;

	@:cffi private static function lime_al_listenerf(param:Int, value1:Float32):Void;

	@:cffi private static function lime_al_listenerfv(param:Int, values:Dynamic):Void;

	@:cffi private static function lime_al_listeneri(param:Int, value1:Int):Void;

	@:cffi private static function lime_al_listeneriv(param:Int, values:Dynamic):Void;

	@:cffi private static function lime_al_source_pause(source:CFFIPointer):Void;

	@:cffi private static function lime_al_source_pausev(n:Int, sources:Dynamic):Void;

	@:cffi private static function lime_al_source_play(source:CFFIPointer):Void;

	@:cffi private static function lime_al_source_playv(n:Int, sources:Dynamic):Void;

	@:cffi private static function lime_al_source_queue_buffers(source:CFFIPointer, nb:Int, buffers:Dynamic):Void;

	@:cffi private static function lime_al_source_rewind(source:CFFIPointer):Void;

	@:cffi private static function lime_al_source_rewindv(n:Int, sources:Dynamic):Void;

	@:cffi private static function lime_al_source_stop(source:CFFIPointer):Void;

	@:cffi private static function lime_al_source_stopv(n:Int, sources:Dynamic):Void;

	@:cffi private static function lime_al_source_unqueue_buffers(source:CFFIPointer, nb:Int):Dynamic;

	@:cffi private static function lime_al_source3f(source:CFFIPointer, param:Int, value1:Float32, value2:Float32, value3:Float32):Void;

	@:cffi private static function lime_al_source3i(source:CFFIPointer, param:Int, value1:Dynamic, value2:Int, value3:Int):Void;

	@:cffi private static function lime_al_sourcef(source:CFFIPointer, param:Int, value:Float32):Void;

	@:cffi private static function lime_al_sourcefv(source:CFFIPointer, param:Int, values:Dynamic):Void;

	@:cffi private static function lime_al_sourcei(source:CFFIPointer, param:Int, value:Dynamic):Void;

	@:cffi private static function lime_al_sourceiv(source:CFFIPointer, param:Int, values:Dynamic):Void;

	@:cffi private static function lime_al_speed_of_sound(speed:Float32):Void;

	@:cffi private static function lime_alc_close_device(device:CFFIPointer):Bool;

	@:cffi private static function lime_alc_create_context(device:CFFIPointer, attrlist:Dynamic):CFFIPointer;

	@:cffi private static function lime_alc_destroy_context(context:CFFIPointer):Void;

	@:cffi private static function lime_alc_get_contexts_device(context:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_alc_get_current_context():CFFIPointer;

	@:cffi private static function lime_alc_get_error(device:CFFIPointer):Int;

	@:cffi private static function lime_alc_get_integerv(device:CFFIPointer, param:Int, size:Int):Dynamic;

	@:cffi private static function lime_alc_get_string(device:CFFIPointer, param:Int):Dynamic;

	@:cffi private static function lime_alc_make_context_current(context:CFFIPointer):Bool;

	@:cffi private static function lime_alc_open_device(devicename:String):CFFIPointer;

	@:cffi private static function lime_alc_pause_device(device:CFFIPointer):Void;

	@:cffi private static function lime_alc_process_context(context:CFFIPointer):Void;

	@:cffi private static function lime_alc_resume_device(device:CFFIPointer):Void;

	@:cffi private static function lime_alc_suspend_context(context:CFFIPointer):Void;

	@:cffi private static function lime_al_gen_filter():CFFIPointer;

	@:cffi private static function lime_al_filteri(filter:CFFIPointer, param:Int, value:Dynamic):Void;

	@:cffi private static function lime_al_filterf(filter:CFFIPointer, param:Int, value:Float32):Void;

	@:cffi private static function lime_al_remove_direct_filter(source:CFFIPointer):Void;

	@:cffi private static function lime_al_is_filter(filter:CFFIPointer):Bool;

	@:cffi private static function lime_al_get_filteri(filter:CFFIPointer, param:Int):Int;

	@:cffi private static function lime_al_gen_effect():CFFIPointer;

	@:cffi private static function lime_al_effectf(effect:CFFIPointer, param:Int, value:Float32):Void;

	@:cffi private static function lime_al_effectfv(effect:CFFIPointer, param:Int, values:Array<Float>):Void;

	@:cffi private static function lime_al_effecti(effect:CFFIPointer, param:Int, value:Int):Void;

	@:cffi private static function lime_al_effectiv(effect:CFFIPointer, param:Int, values:Array<Int>):Void;

	@:cffi private static function lime_al_is_effect(effect:CFFIPointer):Bool;

	@:cffi private static function lime_al_gen_aux():CFFIPointer;

	@:cffi private static function lime_al_auxf(aux:CFFIPointer, param:Int, value:Float32):Void;

	@:cffi private static function lime_al_auxfv(aux:CFFIPointer, param:Int, values:Array<Float>):Void;

	@:cffi private static function lime_al_auxi(aux:CFFIPointer, param:Int, value:Dynamic):Void;

	@:cffi private static function lime_al_auxiv(aux:CFFIPointer, param:Int, values:Array<Int>):Void;

	@:cffi private static function lime_al_is_aux(aux:CFFIPointer):Bool;

	@:cffi private static function lime_al_remove_send(source:CFFIPointer, index:Int):Void;
	#else
	private static var lime_al_buffer_data = new cpp.Callable<cpp.Object->Int->cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_al_buffer_data", "oioiiv", false));
	private static var lime_al_buffer3f = new cpp.Callable<cpp.Object->Int->cpp.Float32->cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_al_buffer3f", "oifffv", false));
	private static var lime_al_buffer3i = new cpp.Callable<cpp.Object->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_buffer3i",
		"oiiiiv", false));
	private static var lime_al_bufferf = new cpp.Callable<cpp.Object->Int->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_bufferf", "oifv",
		false));
	private static var lime_al_bufferfv = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_bufferfv", "oiov",
		false));
	private static var lime_al_bufferi = new cpp.Callable<cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_bufferi", "oiiv", false));
	private static var lime_al_bufferiv = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_bufferiv", "oiov",
		false));
	private static var lime_al_cleanup = new cpp.Callable<Void->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_cleanup", "v", false));
	private static var lime_al_delete_buffer = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_delete_buffer", "ov", false));
	private static var lime_al_delete_buffers = new cpp.Callable<Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_delete_buffers", "iov",
		false));
	private static var lime_al_delete_source = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_delete_source", "ov", false));
	private static var lime_al_delete_sources = new cpp.Callable<Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_delete_sources", "iov",
		false));
	private static var lime_al_disable = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_disable", "iv", false));
	private static var lime_al_distance_model = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_distance_model", "iv", false));
	private static var lime_al_doppler_factor = new cpp.Callable<cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_doppler_factor", "fv", false));
	private static var lime_al_doppler_velocity = new cpp.Callable<cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_doppler_velocity", "fv",
		false));
	private static var lime_al_enable = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_enable", "iv", false));
	private static var lime_al_gen_source = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_gen_source", "o", false));
	private static var lime_al_gen_sources = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_gen_sources", "io", false));
	private static var lime_al_get_boolean = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_al_get_boolean", "ib", false));
	private static var lime_al_get_booleanv = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_booleanv", "iio", false));
	private static var lime_al_gen_buffer = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_gen_buffer", "o", false));
	private static var lime_al_gen_buffers = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_gen_buffers", "io", false));
	private static var lime_al_get_buffer3f = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_buffer3f", "oio",
		false));
	private static var lime_al_get_buffer3i = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_buffer3i", "oio",
		false));
	private static var lime_al_get_bufferf = new cpp.Callable<cpp.Object->Int->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_al_get_bufferf", "oif", false));
	private static var lime_al_get_bufferfv = new cpp.Callable<cpp.Object->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_bufferfv", "oiio",
		false));
	private static var lime_al_get_bufferi = new cpp.Callable<cpp.Object->Int->Int>(cpp.Prime._loadPrime("lime", "lime_al_get_bufferi", "oii", false));
	private static var lime_al_get_bufferiv = new cpp.Callable<cpp.Object->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_bufferiv", "oiio",
		false));
	private static var lime_al_get_double = new cpp.Callable<Int->Float>(cpp.Prime._loadPrime("lime", "lime_al_get_double", "id", false));
	private static var lime_al_get_doublev = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_doublev", "iio", false));
	private static var lime_al_get_enum_value = new cpp.Callable<String->Int>(cpp.Prime._loadPrime("lime", "lime_al_get_enum_value", "si", false));
	private static var lime_al_get_error = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_al_get_error", "i", false));
	private static var lime_al_get_float = new cpp.Callable<Int->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_al_get_float", "if", false));
	private static var lime_al_get_floatv = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_floatv", "iio", false));
	private static var lime_al_get_integer = new cpp.Callable<Int->Int>(cpp.Prime._loadPrime("lime", "lime_al_get_integer", "ii", false));
	private static var lime_al_get_integerv = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_integerv", "iio", false));
	private static var lime_al_get_listener3f = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_listener3f", "io", false));
	private static var lime_al_get_listener3i = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_listener3i", "io", false));
	private static var lime_al_get_listenerf = new cpp.Callable<Int->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_al_get_listenerf", "if", false));
	private static var lime_al_get_listenerfv = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_listenerfv", "iio", false));
	private static var lime_al_get_listeneri = new cpp.Callable<Int->Int>(cpp.Prime._loadPrime("lime", "lime_al_get_listeneri", "ii", false));
	private static var lime_al_get_listeneriv = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_listeneriv", "iio", false));
	private static var lime_al_get_proc_address = new cpp.Callable<String->Float>(cpp.Prime._loadPrime("lime", "lime_al_get_proc_address", "sd", false));
	private static var lime_al_get_source3f = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_source3f", "oio",
		false));
	private static var lime_al_get_source3i = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_source3i", "oio",
		false));
	private static var lime_al_get_sourcef = new cpp.Callable<cpp.Object->Int->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_al_get_sourcef", "oif", false));
	private static var lime_al_get_sourcefv = new cpp.Callable<cpp.Object->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_sourcefv", "oiio",
		false));
	private static var lime_al_get_sourcei = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_sourcei", "oio", false));
	private static var lime_al_get_sourceiv = new cpp.Callable<cpp.Object->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_sourceiv", "oiio",
		false));
	private static var lime_al_get_string = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_get_string", "io", false));
	private static var lime_al_is_buffer = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_al_is_buffer", "ob", false));
	private static var lime_al_is_enabled = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_al_is_enabled", "ib", false));
	private static var lime_al_is_extension_present = new cpp.Callable<String->Bool>(cpp.Prime._loadPrime("lime", "lime_al_is_extension_present", "sb",
		false));
	private static var lime_al_is_source = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_al_is_source", "ob", false));
	private static var lime_al_listener3f = new cpp.Callable<Int->cpp.Float32->cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_al_listener3f", "ifffv", false));
	private static var lime_al_listener3i = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_listener3i", "iiiiv", false));
	private static var lime_al_listenerf = new cpp.Callable<Int->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_listenerf", "ifv", false));
	private static var lime_al_listenerfv = new cpp.Callable<Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_listenerfv", "iov", false));
	private static var lime_al_listeneri = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_listeneri", "iiv", false));
	private static var lime_al_listeneriv = new cpp.Callable<Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_listeneriv", "iov", false));
	private static var lime_al_source_pause = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_source_pause", "ov", false));
	private static var lime_al_source_pausev = new cpp.Callable<Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_source_pausev", "iov",
		false));
	private static var lime_al_source_play = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_source_play", "ov", false));
	private static var lime_al_source_playv = new cpp.Callable<Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_source_playv", "iov", false));
	private static var lime_al_source_queue_buffers = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_al_source_queue_buffers", "oiov", false));
	private static var lime_al_source_rewind = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_source_rewind", "ov", false));
	private static var lime_al_source_rewindv = new cpp.Callable<Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_source_rewindv", "iov",
		false));
	private static var lime_al_source_stop = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_source_stop", "ov", false));
	private static var lime_al_source_stopv = new cpp.Callable<Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_source_stopv", "iov", false));
	private static var lime_al_source_unqueue_buffers = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_al_source_unqueue_buffers", "oio", false));
	private static var lime_al_source3f = new cpp.Callable<cpp.Object->Int->cpp.Float32->cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_al_source3f", "oifffv", false));
	private static var lime_al_source3i = new cpp.Callable<cpp.Object->Int->cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_source3i",
		"oioiiv", false));
	private static var lime_al_sourcef = new cpp.Callable<cpp.Object->Int->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_sourcef", "oifv",
		false));
	private static var lime_al_sourcefv = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_sourcefv", "oiov",
		false));
	private static var lime_al_sourcei = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_sourcei", "oiov",
		false));
	private static var lime_al_sourceiv = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_sourceiv", "oiov",
		false));
	private static var lime_al_speed_of_sound = new cpp.Callable<cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_speed_of_sound", "fv", false));
	private static var lime_alc_close_device = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_alc_close_device", "ob", false));
	private static var lime_alc_create_context = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_alc_create_context",
		"ooo", false));
	private static var lime_alc_destroy_context = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_alc_destroy_context", "ov",
		false));
	private static var lime_alc_get_contexts_device = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_alc_get_contexts_device",
		"oo", false));
	private static var lime_alc_get_current_context = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_alc_get_current_context", "o",
		false));
	private static var lime_alc_get_error = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_alc_get_error", "oi", false));
	private static var lime_alc_get_integerv = new cpp.Callable<cpp.Object->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_alc_get_integerv",
		"oiio", false));
	private static var lime_alc_get_string = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_alc_get_string", "oio", false));
	private static var lime_alc_make_context_current = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_alc_make_context_current", "ob",
		false));
	private static var lime_alc_open_device = new cpp.Callable<String->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_alc_open_device", "so", false));
	private static var lime_alc_pause_device = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_alc_pause_device", "ov", false));
	private static var lime_alc_process_context = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_alc_process_context", "ov",
		false));
	private static var lime_alc_resume_device = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_alc_resume_device", "ov", false));
	private static var lime_alc_suspend_context = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_alc_suspend_context", "ov",
		false));
	private static var lime_al_gen_filter = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_gen_filter", "o", false));
	private static var lime_al_filteri = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_filteri", "oiov",
		false));
	private static var lime_al_filterf = new cpp.Callable<cpp.Object->Int->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_filterf", "oifv",
		false));
	private static var lime_al_remove_direct_filter = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_remove_direct_filter",
		"ov", false));
	private static var lime_al_is_filter = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_al_is_filter", "ob", false));
	private static var lime_al_get_filteri = new cpp.Callable<cpp.Object->Int->Int>(cpp.Prime._loadPrime("lime", "lime_al_get_filteri", "oii", false));
	private static var lime_al_gen_effect = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_gen_effect", "o", false));
	private static var lime_al_effectf = new cpp.Callable<cpp.Object->Int->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_effectf", "oifv",
		false));
	private static var lime_al_effectfv = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_effectfv", "oiov",
		false));
	private static var lime_al_effecti = new cpp.Callable<cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_effecti", "oiiv", false));
	private static var lime_al_effectiv = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_effectiv", "oiov",
		false));
	private static var lime_al_is_effect = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_al_is_effect", "ob", false));
	private static var lime_al_gen_aux = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_al_gen_aux", "o", false));
	private static var lime_al_auxf = new cpp.Callable<cpp.Object->Int->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_auxf", "oifv", false));
	private static var lime_al_auxfv = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_auxfv", "oiov", false));
	private static var lime_al_auxi = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_auxi", "oiov", false));
	private static var lime_al_auxiv = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_auxiv", "oiov", false));
	private static var lime_al_is_aux = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_al_is_aux", "ob", false));
	private static var lime_al_remove_send = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_al_remove_send", "oiv", false));
	#end
	#end
	#if (neko || cppia)
	private static var lime_al_buffer_data = CFFI.load("lime", "lime_al_buffer_data", 5);
	private static var lime_al_buffer3f = CFFI.load("lime", "lime_al_buffer3f", 5);
	private static var lime_al_buffer3i = CFFI.load("lime", "lime_al_buffer3i", 5);
	private static var lime_al_bufferf = CFFI.load("lime", "lime_al_bufferf", 3);
	private static var lime_al_bufferfv = CFFI.load("lime", "lime_al_bufferfv", 3);
	private static var lime_al_bufferi = CFFI.load("lime", "lime_al_bufferi", 3);
	private static var lime_al_bufferiv = CFFI.load("lime", "lime_al_bufferiv", 3);
	private static var lime_al_cleanup = CFFI.load("lime", "lime_al_cleanup", 0);
	private static var lime_al_delete_buffer = CFFI.load("lime", "lime_al_delete_buffer", 1);
	private static var lime_al_delete_buffers = CFFI.load("lime", "lime_al_delete_buffers", 2);
	private static var lime_al_delete_source = CFFI.load("lime", "lime_al_delete_source", 1);
	private static var lime_al_delete_sources = CFFI.load("lime", "lime_al_delete_sources", 2);
	private static var lime_al_disable = CFFI.load("lime", "lime_al_disable", 1);
	private static var lime_al_distance_model = CFFI.load("lime", "lime_al_distance_model", 1);
	private static var lime_al_doppler_factor = CFFI.load("lime", "lime_al_doppler_factor", 1);
	private static var lime_al_doppler_velocity = CFFI.load("lime", "lime_al_doppler_velocity", 1);
	private static var lime_al_enable = CFFI.load("lime", "lime_al_enable", 1);
	private static var lime_al_gen_source = CFFI.load("lime", "lime_al_gen_source", 0);
	private static var lime_al_gen_sources = CFFI.load("lime", "lime_al_gen_sources", 1);
	private static var lime_al_get_boolean = CFFI.load("lime", "lime_al_get_boolean", 1);
	private static var lime_al_get_booleanv = CFFI.load("lime", "lime_al_get_booleanv", 2);
	private static var lime_al_gen_buffer = CFFI.load("lime", "lime_al_gen_buffer", 0);
	private static var lime_al_gen_buffers = CFFI.load("lime", "lime_al_gen_buffers", 1);
	private static var lime_al_get_buffer3f = CFFI.load("lime", "lime_al_get_buffer3f", 2);
	private static var lime_al_get_buffer3i = CFFI.load("lime", "lime_al_get_buffer3i", 2);
	private static var lime_al_get_bufferf = CFFI.load("lime", "lime_al_get_bufferf", 2);
	private static var lime_al_get_bufferfv = CFFI.load("lime", "lime_al_get_bufferfv", 3);
	private static var lime_al_get_bufferi = CFFI.load("lime", "lime_al_get_bufferi", 2);
	private static var lime_al_get_bufferiv = CFFI.load("lime", "lime_al_get_bufferiv", 3);
	private static var lime_al_get_double = CFFI.load("lime", "lime_al_get_double", 1);
	private static var lime_al_get_doublev = CFFI.load("lime", "lime_al_get_doublev", 2);
	private static var lime_al_get_enum_value = CFFI.load("lime", "lime_al_get_enum_value", 1);
	private static var lime_al_get_error = CFFI.load("lime", "lime_al_get_error", 0);
	private static var lime_al_get_float = CFFI.load("lime", "lime_al_get_float", 1);
	private static var lime_al_get_floatv = CFFI.load("lime", "lime_al_get_floatv", 2);
	private static var lime_al_get_integer = CFFI.load("lime", "lime_al_get_integer", 1);
	private static var lime_al_get_integerv = CFFI.load("lime", "lime_al_get_integerv", 2);
	private static var lime_al_get_listener3f = CFFI.load("lime", "lime_al_get_listener3f", 1);
	private static var lime_al_get_listener3i = CFFI.load("lime", "lime_al_get_listener3i", 1);
	private static var lime_al_get_listenerf = CFFI.load("lime", "lime_al_get_listenerf", 1);
	private static var lime_al_get_listenerfv = CFFI.load("lime", "lime_al_get_listenerfv", 2);
	private static var lime_al_get_listeneri = CFFI.load("lime", "lime_al_get_listeneri", 1);
	private static var lime_al_get_listeneriv = CFFI.load("lime", "lime_al_get_listeneriv", 2);
	private static var lime_al_get_proc_address = CFFI.load("lime", "lime_al_get_proc_address", 1);
	private static var lime_al_get_source3f = CFFI.load("lime", "lime_al_get_source3f", 2);
	private static var lime_al_get_source3i = CFFI.load("lime", "lime_al_get_source3i", 2);
	private static var lime_al_get_sourcef = CFFI.load("lime", "lime_al_get_sourcef", 2);
	private static var lime_al_get_sourcefv = CFFI.load("lime", "lime_al_get_sourcefv", 3);
	private static var lime_al_get_sourcei = CFFI.load("lime", "lime_al_get_sourcei", 2);
	private static var lime_al_get_sourceiv = CFFI.load("lime", "lime_al_get_sourceiv", 3);
	private static var lime_al_get_string = CFFI.load("lime", "lime_al_get_string", 1);
	private static var lime_al_is_buffer = CFFI.load("lime", "lime_al_is_buffer", 1);
	private static var lime_al_is_enabled = CFFI.load("lime", "lime_al_is_enabled", 1);
	private static var lime_al_is_extension_present = CFFI.load("lime", "lime_al_is_extension_present", 1);
	private static var lime_al_is_source = CFFI.load("lime", "lime_al_is_source", 1);
	private static var lime_al_listener3f = CFFI.load("lime", "lime_al_listener3f", 4);
	private static var lime_al_listener3i = CFFI.load("lime", "lime_al_listener3i", 4);
	private static var lime_al_listenerf = CFFI.load("lime", "lime_al_listenerf", 2);
	private static var lime_al_listenerfv = CFFI.load("lime", "lime_al_listenerfv", 2);
	private static var lime_al_listeneri = CFFI.load("lime", "lime_al_listeneri", 2);
	private static var lime_al_listeneriv = CFFI.load("lime", "lime_al_listeneriv", 2);
	private static var lime_al_source_pause = CFFI.load("lime", "lime_al_source_pause", 1);
	private static var lime_al_source_pausev = CFFI.load("lime", "lime_al_source_pausev", 2);
	private static var lime_al_source_play = CFFI.load("lime", "lime_al_source_play", 1);
	private static var lime_al_source_playv = CFFI.load("lime", "lime_al_source_playv", 2);
	private static var lime_al_source_queue_buffers = CFFI.load("lime", "lime_al_source_queue_buffers", 3);
	private static var lime_al_source_rewind = CFFI.load("lime", "lime_al_source_rewind", 1);
	private static var lime_al_source_rewindv = CFFI.load("lime", "lime_al_source_rewindv", 2);
	private static var lime_al_source_stop = CFFI.load("lime", "lime_al_source_stop", 1);
	private static var lime_al_source_stopv = CFFI.load("lime", "lime_al_source_stopv", 2);
	private static var lime_al_source_unqueue_buffers = CFFI.load("lime", "lime_al_source_unqueue_buffers", 2);
	private static var lime_al_source3f = CFFI.load("lime", "lime_al_source3f", 5);
	private static var lime_al_source3i = CFFI.load("lime", "lime_al_source3i", 5);
	private static var lime_al_sourcef = CFFI.load("lime", "lime_al_sourcef", 3);
	private static var lime_al_sourcefv = CFFI.load("lime", "lime_al_sourcefv", 3);
	private static var lime_al_sourcei = CFFI.load("lime", "lime_al_sourcei", 3);
	private static var lime_al_sourceiv = CFFI.load("lime", "lime_al_sourceiv", 3);
	private static var lime_al_speed_of_sound = CFFI.load("lime", "lime_al_speed_of_sound", 1);
	private static var lime_alc_close_device = CFFI.load("lime", "lime_alc_close_device", 1);
	private static var lime_alc_create_context = CFFI.load("lime", "lime_alc_create_context", 2);
	private static var lime_alc_destroy_context = CFFI.load("lime", "lime_alc_destroy_context", 1);
	private static var lime_alc_get_contexts_device = CFFI.load("lime", "lime_alc_get_contexts_device", 1);
	private static var lime_alc_get_current_context = CFFI.load("lime", "lime_alc_get_current_context", 0);
	private static var lime_alc_get_error = CFFI.load("lime", "lime_alc_get_error", 1);
	private static var lime_alc_get_integerv = CFFI.load("lime", "lime_alc_get_integerv", 3);
	private static var lime_alc_get_string = CFFI.load("lime", "lime_alc_get_string", 2);
	private static var lime_alc_make_context_current = CFFI.load("lime", "lime_alc_make_context_current", 1);
	private static var lime_alc_open_device = CFFI.load("lime", "lime_alc_open_device", 1);
	private static var lime_alc_pause_device = CFFI.load("lime", "lime_alc_pause_device", 1);
	private static var lime_alc_process_context = CFFI.load("lime", "lime_alc_process_context", 1);
	private static var lime_alc_resume_device = CFFI.load("lime", "lime_alc_resume_device", 1);
	private static var lime_alc_suspend_context = CFFI.load("lime", "lime_alc_suspend_context", 1);
	private static var lime_al_gen_filter = CFFI.load("lime", "lime_al_gen_filter", 0);
	private static var lime_al_filteri = CFFI.load("lime", "lime_al_filteri", 3);
	private static var lime_al_filterf = CFFI.load("lime", "lime_al_filterf", 3);
	private static var lime_al_remove_direct_filter = CFFI.load("lime", "lime_al_remove_direct_filter", 1);
	private static var lime_al_is_filter = CFFI.load("lime", "lime_al_is_filter", 1);
	private static var lime_al_get_filteri = CFFI.load("lime", "lime_al_get_filteri", 2);
	private static var lime_al_gen_effect = CFFI.load("lime", "lime_al_gen_effect", 0);
	private static var lime_al_effectf = CFFI.load("lime", "lime_al_effectf", 3);
	private static var lime_al_effectfv = CFFI.load("lime", "lime_al_effectfv", 3);
	private static var lime_al_effecti = CFFI.load("lime", "lime_al_effecti", 3);
	private static var lime_al_effectiv = CFFI.load("lime", "lime_al_effectiv", 3);
	private static var lime_al_is_effect = CFFI.load("lime", "lime_al_is_effect", 1);
	private static var lime_al_gen_aux = CFFI.load("lime", "lime_al_gen_aux", 0);
	private static var lime_al_auxf = CFFI.load("lime", "lime_al_auxf", 3);
	private static var lime_al_auxfv = CFFI.load("lime", "lime_al_auxfv", 3);
	private static var lime_al_auxi = CFFI.load("lime", "lime_al_auxi", 3);
	private static var lime_al_auxiv = CFFI.load("lime", "lime_al_auxiv", 3);
	private static var lime_al_is_aux = CFFI.load("lime", "lime_al_is_aux", 1);
	private static var lime_al_remove_send = CFFI.load("lime", "lime_al_remove_send", 2);
	#end

	#if hl
	@:hlNative("lime", "lime_al_buffer_data") private static function lime_al_buffer_data(buffer:CFFIPointer, format:Int, data:ArrayBufferView, size:Int,
		freq:Int):Void {}

	@:hlNative("lime", "lime_al_buffer3f") private static function lime_al_buffer3f(buffer:CFFIPointer, param:Int, value1:hl.F32, value2:hl.F32,
		value3:hl.F32):Void {}

	@:hlNative("lime", "lime_al_buffer3i") private static function lime_al_buffer3i(buffer:CFFIPointer, param:Int, value1:Int, value2:Int, value3:Int):Void {}

	@:hlNative("lime", "lime_al_bufferf") private static function lime_al_bufferf(buffer:CFFIPointer, param:Int, value:hl.F32):Void {}

	@:hlNative("lime", "lime_al_bufferfv") private static function lime_al_bufferfv(buffer:CFFIPointer, param:Int, values:hl.NativeArray<hl.F32>):Void {}

	@:hlNative("lime", "lime_al_bufferi") private static function lime_al_bufferi(buffer:CFFIPointer, param:Int, value:Int):Void {}

	@:hlNative("lime", "lime_al_bufferiv") private static function lime_al_bufferiv(buffer:CFFIPointer, param:Int, values:hl.NativeArray<Int>):Void {}

	@:hlNative("lime", "lime_al_cleanup") private static function lime_al_cleanup():Void {}

	@:hlNative("lime", "lime_al_delete_buffer") private static function lime_al_delete_buffer(buffer:CFFIPointer):Void {}

	@:hlNative("lime", "lime_al_delete_buffers") private static function lime_al_delete_buffers(n:Int, buffers:hl.NativeArray<CFFIPointer>):Void {}

	@:hlNative("lime", "lime_al_delete_source") private static function lime_al_delete_source(source:CFFIPointer):Void {}

	@:hlNative("lime", "lime_al_delete_sources") private static function lime_al_delete_sources(n:Int, sources:hl.NativeArray<CFFIPointer>):Void {}

	@:hlNative("lime", "lime_al_disable") private static function lime_al_disable(capability:Int):Void {}

	@:hlNative("lime", "lime_al_distance_model") private static function lime_al_distance_model(distanceModel:Int):Void {}

	@:hlNative("lime", "lime_al_doppler_factor") private static function lime_al_doppler_factor(value:hl.F32):Void {}

	@:hlNative("lime", "lime_al_doppler_velocity") private static function lime_al_doppler_velocity(value:hl.F32):Void {}

	@:hlNative("lime", "lime_al_enable") private static function lime_al_enable(capability:Int):Void {}

	@:hlNative("lime", "lime_al_gen_source") private static function lime_al_gen_source():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_al_gen_sources") private static function lime_al_gen_sources(n:Int):hl.NativeArray<CFFIPointer>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_boolean") private static function lime_al_get_boolean(param:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_al_get_booleanv") private static function lime_al_get_booleanv(param:Int, count:Int):hl.NativeArray<Bool>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_gen_buffer") private static function lime_al_gen_buffer():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_al_gen_buffers") private static function lime_al_gen_buffers(n:Int):hl.NativeArray<CFFIPointer>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_buffer3f") private static function lime_al_get_buffer3f(buffer:CFFIPointer, param:Int):hl.NativeArray<hl.F32>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_buffer3i") private static function lime_al_get_buffer3i(buffer:CFFIPointer, param:Int):hl.NativeArray<Int>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_bufferf") private static function lime_al_get_bufferf(buffer:CFFIPointer, param:Int):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_bufferfv") private static function lime_al_get_bufferfv(buffer:CFFIPointer, param:Int, count:Int):hl.NativeArray<hl.F32>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_bufferi") private static function lime_al_get_bufferi(buffer:CFFIPointer, param:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_bufferiv") private static function lime_al_get_bufferiv(buffer:CFFIPointer, param:Int, count:Int):hl.NativeArray<Int>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_double") private static function lime_al_get_double(param:Int):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_doublev") private static function lime_al_get_doublev(param:Int, count:Int):hl.NativeArray<Float>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_enum_value") private static function lime_al_get_enum_value(ename:String):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_error") private static function lime_al_get_error():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_float") private static function lime_al_get_float(param:Int):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_floatv") private static function lime_al_get_floatv(param:Int, count:Int):hl.NativeArray<hl.F32>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_integer") private static function lime_al_get_integer(param:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_integerv") private static function lime_al_get_integerv(param:Int, count:Int):hl.NativeArray<Int>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_listener3f") private static function lime_al_get_listener3f(param:Int):hl.NativeArray<hl.F32>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_listener3i") private static function lime_al_get_listener3i(param:Int):hl.NativeArray<Int>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_listenerf") private static function lime_al_get_listenerf(param:Int):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_listenerfv") private static function lime_al_get_listenerfv(param:Int, count:Int):hl.NativeArray<hl.F32>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_listeneri") private static function lime_al_get_listeneri(param:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_listeneriv") private static function lime_al_get_listeneriv(param:Int, count:Int):hl.NativeArray<Int>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_proc_address") private static function lime_al_get_proc_address(fname:String):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_source3f") private static function lime_al_get_source3f(source:CFFIPointer, param:Int):hl.NativeArray<hl.F32>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_source3i") private static function lime_al_get_source3i(source:CFFIPointer, param:Int):hl.NativeArray<Int>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_sourcef") private static function lime_al_get_sourcef(source:CFFIPointer, param:Int):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_get_sourcefv") private static function lime_al_get_sourcefv(source:CFFIPointer, param:Int, count:Int):hl.NativeArray<hl.F32>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_sourcei") private static function lime_al_get_sourcei(source:CFFIPointer, param:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_sourceiv") private static function lime_al_get_sourceiv(source:CFFIPointer, param:Int, count:Int):hl.NativeArray<Int>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_get_string") private static function lime_al_get_string(param:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_al_is_buffer") private static function lime_al_is_buffer(buffer:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_al_is_enabled") private static function lime_al_is_enabled(capability:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_al_is_extension_present") private static function lime_al_is_extension_present(extname:String):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_al_is_source") private static function lime_al_is_source(source:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_al_listener3f") private static function lime_al_listener3f(param:Int, value1:hl.F32, value2:hl.F32, value3:hl.F32):Void {}

	@:hlNative("lime", "lime_al_listener3i") private static function lime_al_listener3i(param:Int, value1:Int, value2:Int, value3:Int):Void {}

	@:hlNative("lime", "lime_al_listenerf") private static function lime_al_listenerf(param:Int, value1:hl.F32):Void {}

	@:hlNative("lime", "lime_al_listenerfv") private static function lime_al_listenerfv(param:Int, values:hl.NativeArray<hl.F32>):Void {}

	@:hlNative("lime", "lime_al_listeneri") private static function lime_al_listeneri(param:Int, value1:Int):Void {}

	@:hlNative("lime", "lime_al_listeneriv") private static function lime_al_listeneriv(param:Int, values:hl.NativeArray<Int>):Void {}

	@:hlNative("lime", "lime_al_source_pause") private static function lime_al_source_pause(source:CFFIPointer):Void {}

	@:hlNative("lime", "lime_al_source_pausev") private static function lime_al_source_pausev(n:Int, sources:hl.NativeArray<CFFIPointer>):Void {}

	@:hlNative("lime", "lime_al_source_play") private static function lime_al_source_play(source:CFFIPointer):Void {}

	@:hlNative("lime", "lime_al_source_playv") private static function lime_al_source_playv(n:Int, sources:hl.NativeArray<CFFIPointer>):Void {}

	@:hlNative("lime", "lime_al_source_queue_buffers") private static function lime_al_source_queue_buffers(source:CFFIPointer, nb:Int,
		buffers:hl.NativeArray<CFFIPointer>):Void {}

	@:hlNative("lime", "lime_al_source_rewind") private static function lime_al_source_rewind(source:CFFIPointer):Void {}

	@:hlNative("lime", "lime_al_source_rewindv") private static function lime_al_source_rewindv(n:Int, sources:hl.NativeArray<CFFIPointer>):Void {}

	@:hlNative("lime", "lime_al_source_stop") private static function lime_al_source_stop(source:CFFIPointer):Void {}

	@:hlNative("lime", "lime_al_source_stopv") private static function lime_al_source_stopv(n:Int, sources:hl.NativeArray<CFFIPointer>):Void {}

	@:hlNative("lime", "lime_al_source_unqueue_buffers") private static function lime_al_source_unqueue_buffers(source:CFFIPointer,
			nb:Int):hl.NativeArray<CFFIPointer>
	{
		return null;
	}

	@:hlNative("lime", "lime_al_source3f") private static function lime_al_source3f(source:CFFIPointer, param:Int, value1:hl.F32, value2:hl.F32,
		value3:hl.F32):Void {}

	@:hlNative("lime", "lime_al_source3i") private static function lime_al_source3i(source:CFFIPointer, param:Int, value1:Dynamic, value2:Int,
		value3:Int):Void {}

	@:hlNative("lime", "lime_al_sourcef") private static function lime_al_sourcef(source:CFFIPointer, param:Int, value:hl.F32):Void {}

	@:hlNative("lime", "lime_al_sourcefv") private static function lime_al_sourcefv(source:CFFIPointer, param:Int, values:hl.NativeArray<hl.F32>):Void {}

	@:hlNative("lime", "lime_al_sourcei") private static function lime_al_sourcei(source:CFFIPointer, param:Int, value:Dynamic):Void {}

	@:hlNative("lime", "lime_al_sourceiv") private static function lime_al_sourceiv(source:CFFIPointer, param:Int, values:hl.NativeArray<Int>):Void {}

	@:hlNative("lime", "lime_al_speed_of_sound") private static function lime_al_speed_of_sound(speed:hl.F32):Void {}

	@:hlNative("lime", "lime_alc_close_device") private static function lime_alc_close_device(device:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_alc_create_context") private static function lime_alc_create_context(device:CFFIPointer, attrlist:hl.NativeArray<Int>):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_alc_destroy_context") private static function lime_alc_destroy_context(context:CFFIPointer):Void {}

	@:hlNative("lime", "lime_alc_get_contexts_device") private static function lime_alc_get_contexts_device(context:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_alc_get_current_context") private static function lime_alc_get_current_context():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_alc_get_error") private static function lime_alc_get_error(device:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_alc_get_integerv") private static function lime_alc_get_integerv(device:CFFIPointer, param:Int, size:Int):hl.NativeArray<Int>
	{
		return null;
	}

	@:hlNative("lime", "lime_alc_get_string") private static function lime_alc_get_string(device:CFFIPointer, param:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_alc_make_context_current") private static function lime_alc_make_context_current(context:ALContext):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_alc_open_device") private static function lime_alc_open_device(devicename:String):CFFIPointer
	{
		return null;
	};

	@:hlNative("lime", "lime_alc_pause_device") private static function lime_alc_pause_device(device:ALDevice):Void {}

	@:hlNative("lime", "lime_alc_process_context") private static function lime_alc_process_context(context:ALContext):Void {}

	@:hlNative("lime", "lime_alc_resume_device") private static function lime_alc_resume_device(device:ALDevice):Void {}

	@:hlNative("lime", "lime_alc_suspend_context") private static function lime_alc_suspend_context(context:ALContext):Void {}

	@:hlNative("lime", "lime_al_gen_filter") private static function lime_al_gen_filter():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_al_filteri") private static function lime_al_filteri(filter:CFFIPointer, param:Int, value:Dynamic):Void {}

	@:hlNative("lime", "lime_al_filterf") private static function lime_al_filterf(filter:CFFIPointer, param:Int, value:hl.F32):Void {}

	@:hlNative("lime", "lime_al_remove_direct_filter") private static function lime_al_remove_direct_filter(source:CFFIPointer):Void {}

	@:hlNative("lime", "lime_al_is_filter") private static function lime_al_is_filter(filter:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_al_get_filteri") private static function lime_al_get_filteri(filter:CFFIPointer, param:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_al_gen_effect") private static function lime_al_gen_effect():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_al_effectf") private static function lime_al_effectf(effect:CFFIPointer, param:Int, value:hl.F32):Void {}

	@:hlNative("lime", "lime_al_effectfv") private static function lime_al_effectfv(effect:CFFIPointer, param:Int, values:hl.NativeArray<hl.F32>):Void {}

	@:hlNative("lime", "lime_al_effecti") private static function lime_al_effecti(effect:CFFIPointer, param:Int, value:Int):Void {}

	@:hlNative("lime", "lime_al_effectiv") private static function lime_al_effectiv(effect:CFFIPointer, param:Int, values:hl.NativeArray<Int>):Void {}

	@:hlNative("lime", "lime_al_is_effect") private static function lime_al_is_effect(effect:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_al_gen_aux") private static function lime_al_gen_aux():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_al_auxf") private static function lime_al_auxf(aux:CFFIPointer, param:Int, value:hl.F32):Void {}

	@:hlNative("lime", "lime_al_auxfv") private static function lime_al_auxfv(aux:CFFIPointer, param:Int, values:hl.NativeArray<hl.F32>):Void {}

	@:hlNative("lime", "lime_al_auxi") private static function lime_al_auxi(aux:CFFIPointer, param:Int, value:Dynamic):Void {}

	@:hlNative("lime", "lime_al_auxiv") private static function lime_al_auxiv(aux:CFFIPointer, param:Int, values:hl.NativeArray<Int>):Void {}

	@:hlNative("lime", "lime_al_is_aux") private static function lime_al_is_aux(aux:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_al_remove_send") private static function lime_al_remove_send(source:CFFIPointer, index:Int):Void {}
	#end
	#end
	#if (lime_cffi && !macro && lime_cairo)
	#if (cpp && !cppia)
	#if (disable_cffi || haxe_ver < "3.4.0")
	@:cffi private static function lime_cairo_arc(handle:CFFIPointer, xc:Float, yc:Float, radius:Float, angle1:Float, angle2:Float):Void;

	@:cffi private static function lime_cairo_arc_negative(handle:CFFIPointer, xc:Float, yc:Float, radius:Float, angle1:Float, angle2:Float):Void;

	@:cffi private static function lime_cairo_clip(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_clip_preserve(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_clip_extents(handle:CFFIPointer, x1:Float, y1:Float, x2:Float, y2:Float):Void;

	@:cffi private static function lime_cairo_close_path(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_copy_page(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_create(handle:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_cairo_curve_to(handle:CFFIPointer, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float):Void;

	@:cffi private static function lime_cairo_fill(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_fill_extents(handle:CFFIPointer, x1:Float, y1:Float, x2:Float, y2:Float):Void;

	@:cffi private static function lime_cairo_fill_preserve(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_get_antialias(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_get_current_point(handle:CFFIPointer):Dynamic;

	@:cffi private static function lime_cairo_get_dash(handle:CFFIPointer):Dynamic;

	@:cffi private static function lime_cairo_get_dash_count(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_get_fill_rule(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_get_font_face(handle:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_cairo_get_font_options(handle:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_cairo_get_group_target(handle:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_cairo_get_line_cap(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_get_line_join(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_get_line_width(handle:CFFIPointer):Float;

	@:cffi private static function lime_cairo_get_matrix(handle:CFFIPointer):Dynamic;

	@:cffi private static function lime_cairo_get_miter_limit(handle:CFFIPointer):Float;

	@:cffi private static function lime_cairo_get_operator(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_get_source(handle:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_cairo_get_target(handle:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_cairo_get_tolerance(handle:CFFIPointer):Float;

	@:cffi private static function lime_cairo_has_current_point(handle:CFFIPointer):Bool;

	@:cffi private static function lime_cairo_identity_matrix(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_in_clip(handle:CFFIPointer, x:Float, y:Float):Bool;

	@:cffi private static function lime_cairo_in_fill(handle:CFFIPointer, x:Float, y:Float):Bool;

	@:cffi private static function lime_cairo_in_stroke(handle:CFFIPointer, x:Float, y:Float):Bool;

	@:cffi private static function lime_cairo_line_to(handle:CFFIPointer, x:Float, y:Float):Void;

	@:cffi private static function lime_cairo_mask(handle:CFFIPointer, pattern:CFFIPointer):Void;

	@:cffi private static function lime_cairo_mask_surface(handle:CFFIPointer, surface:CFFIPointer, x:Float, y:Float):Void;

	@:cffi private static function lime_cairo_move_to(handle:CFFIPointer, x:Float, y:Float):Void;

	@:cffi private static function lime_cairo_new_path(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_paint(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_paint_with_alpha(handle:CFFIPointer, alpha:Float):Void;

	@:cffi private static function lime_cairo_pop_group(handle:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_cairo_pop_group_to_source(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_push_group(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_push_group_with_content(handle:CFFIPointer, content:Int):Void;

	@:cffi private static function lime_cairo_rectangle(handle:CFFIPointer, x:Float, y:Float, width:Float, height:Float):Void;

	@:cffi private static function lime_cairo_rel_curve_to(handle:CFFIPointer, dx1:Float, dy1:Float, dx2:Float, dy2:Float, dx3:Float, dy3:Float):Void;

	@:cffi private static function lime_cairo_rel_line_to(handle:CFFIPointer, dx:Float, dy:Float):Void;

	@:cffi private static function lime_cairo_rel_move_to(handle:CFFIPointer, dx:Float, dy:Float):Void;

	@:cffi private static function lime_cairo_reset_clip(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_restore(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_rotate(handle:CFFIPointer, amount:Float):Void;

	@:cffi private static function lime_cairo_save(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_scale(handle:CFFIPointer, x:Float, y:Float):Void;

	@:cffi private static function lime_cairo_set_antialias(handle:CFFIPointer, cap:Int):Void;

	@:cffi private static function lime_cairo_set_dash(handle:CFFIPointer, dash:Dynamic):Void;

	@:cffi private static function lime_cairo_set_fill_rule(handle:CFFIPointer, cap:Int):Void;

	@:cffi private static function lime_cairo_set_font_face(handle:CFFIPointer, face:CFFIPointer):Void;

	@:cffi private static function lime_cairo_set_font_options(handle:CFFIPointer, options:CFFIPointer):Void;

	@:cffi private static function lime_cairo_set_font_size(handle:CFFIPointer, size:Float):Void;

	@:cffi private static function lime_cairo_set_line_cap(handle:CFFIPointer, cap:Int):Void;

	@:cffi private static function lime_cairo_set_line_join(handle:CFFIPointer, join:Int):Void;

	@:cffi private static function lime_cairo_set_line_width(handle:CFFIPointer, width:Float):Void;

	@:cffi private static function lime_cairo_set_matrix(handle:CFFIPointer, a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Void;

	// @:cffi private static function lime_cairo_set_matrix (handle:CFFIPointer, matrix:Dynamic):Void;
	@:cffi private static function lime_cairo_set_miter_limit(handle:CFFIPointer, miterLimit:Float):Void;

	@:cffi private static function lime_cairo_set_operator(handle:CFFIPointer, op:Int):Void;

	@:cffi private static function lime_cairo_set_source(handle:CFFIPointer, pattern:CFFIPointer):Void;

	@:cffi private static function lime_cairo_set_source_rgb(handle:CFFIPointer, r:Float, g:Float, b:Float):Void;

	@:cffi private static function lime_cairo_set_source_rgba(handle:CFFIPointer, r:Float, g:Float, b:Float, a:Float):Void;

	@:cffi private static function lime_cairo_set_source_surface(handle:CFFIPointer, surface:CFFIPointer, x:Float, y:Float):Void;

	@:cffi private static function lime_cairo_set_tolerance(handle:CFFIPointer, tolerance:Float):Void;

	@:cffi private static function lime_cairo_show_glyphs(handle:CFFIPointer, glyphs:Dynamic):Void;

	@:cffi private static function lime_cairo_show_page(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_show_text(handle:CFFIPointer, text:String):Void;

	@:cffi private static function lime_cairo_status(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_stroke(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_stroke_extents(handle:CFFIPointer, x1:Float, y1:Float, x2:Float, y2:Float):Void;

	@:cffi private static function lime_cairo_stroke_preserve(handle:CFFIPointer):Void;

	@:cffi private static function lime_cairo_text_path(handle:CFFIPointer, text:String):Void;

	@:cffi private static function lime_cairo_transform(handle:CFFIPointer, matrix:Dynamic):Void;

	@:cffi private static function lime_cairo_translate(handle:CFFIPointer, x:Float, y:Float):Void;

	@:cffi private static function lime_cairo_version():Int;

	@:cffi private static function lime_cairo_version_string():String;

	@:cffi private static function lime_cairo_font_face_status(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_font_options_create():CFFIPointer;

	@:cffi private static function lime_cairo_font_options_get_antialias(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_font_options_get_hint_metrics(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_font_options_get_hint_style(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_font_options_get_subpixel_order(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_font_options_set_antialias(handle:CFFIPointer, v:Int):Void;

	@:cffi private static function lime_cairo_font_options_set_hint_metrics(handle:CFFIPointer, v:Int):Void;

	@:cffi private static function lime_cairo_font_options_set_hint_style(handle:CFFIPointer, v:Int):Void;

	@:cffi private static function lime_cairo_font_options_set_subpixel_order(handle:CFFIPointer, v:Int):Void;

	@:cffi private static function lime_cairo_ft_font_face_create(face:CFFIPointer, flags:Int):CFFIPointer;

	@:cffi private static function lime_cairo_image_surface_create(format:Int, width:Int, height:Int):CFFIPointer;

	@:cffi private static function lime_cairo_image_surface_create_for_data(data:DataPointer, format:Int, width:Int, height:Int, stride:Int):CFFIPointer;

	@:cffi private static function lime_cairo_image_surface_get_data(handle:CFFIPointer):DataPointer;

	@:cffi private static function lime_cairo_image_surface_get_format(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_image_surface_get_height(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_image_surface_get_stride(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_image_surface_get_width(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_pattern_add_color_stop_rgb(handle:CFFIPointer, offset:Float, red:Float, green:Float, blue:Float):Void;

	@:cffi private static function lime_cairo_pattern_add_color_stop_rgba(handle:CFFIPointer, offset:Float, red:Float, green:Float, blue:Float,
		alpha:Float):Void;

	@:cffi private static function lime_cairo_pattern_create_for_surface(surface:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_cairo_pattern_create_linear(x0:Float, y0:Float, x1:Float, y1:Float):CFFIPointer;

	@:cffi private static function lime_cairo_pattern_create_radial(cx0:Float, cy0:Float, radius0:Float, cx1:Float, cy1:Float, radius1:Float):CFFIPointer;

	@:cffi private static function lime_cairo_pattern_create_rgb(r:Float, g:Float, b:Float):CFFIPointer;

	@:cffi private static function lime_cairo_pattern_create_rgba(r:Float, g:Float, b:Float, a:Float):CFFIPointer;

	@:cffi private static function lime_cairo_pattern_get_color_stop_count(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_pattern_get_extend(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_pattern_get_filter(handle:CFFIPointer):Int;

	@:cffi private static function lime_cairo_pattern_get_matrix(handle:CFFIPointer):Dynamic;

	@:cffi private static function lime_cairo_pattern_set_extend(handle:CFFIPointer, extend:Int):Void;

	@:cffi private static function lime_cairo_pattern_set_filter(handle:CFFIPointer, filter:Int):Void;

	@:cffi private static function lime_cairo_pattern_set_matrix(handle:CFFIPointer, matrix:Dynamic):Void;

	@:cffi private static function lime_cairo_surface_flush(surface:CFFIPointer):Void;
	#else
	private static var lime_cairo_arc = new cpp.Callable<cpp.Object->Float->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_arc", "odddddv", false));
	private static var lime_cairo_arc_negative = new cpp.Callable<cpp.Object->Float->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_arc_negative", "odddddv", false));
	private static var lime_cairo_clip = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_clip", "ov", false));
	private static var lime_cairo_clip_preserve = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_clip_preserve", "ov",
		false));
	private static var lime_cairo_clip_extents = new cpp.Callable<cpp.Object->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_clip_extents", "oddddv", false));
	private static var lime_cairo_close_path = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_close_path", "ov", false));
	private static var lime_cairo_copy_page = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_copy_page", "ov", false));
	private static var lime_cairo_create = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_create", "oo", false));
	private static var lime_cairo_curve_to = new cpp.Callable<cpp.Object->Float->Float->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_curve_to", "oddddddv", false));
	private static var lime_cairo_fill = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_fill", "ov", false));
	private static var lime_cairo_fill_extents = new cpp.Callable<cpp.Object->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_fill_extents", "oddddv", false));
	private static var lime_cairo_fill_preserve = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_fill_preserve", "ov",
		false));
	private static var lime_cairo_get_antialias = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_get_antialias", "oi", false));
	private static var lime_cairo_get_current_point = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_get_current_point",
		"oo", false));
	private static var lime_cairo_get_dash = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_get_dash", "oo", false));
	private static var lime_cairo_get_dash_count = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_get_dash_count", "oi", false));
	private static var lime_cairo_get_fill_rule = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_get_fill_rule", "oi", false));
	private static var lime_cairo_get_font_face = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_get_font_face", "oo",
		false));
	private static var lime_cairo_get_font_options = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_get_font_options",
		"oo", false));
	private static var lime_cairo_get_group_target = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_get_group_target",
		"oo", false));
	private static var lime_cairo_get_line_cap = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_get_line_cap", "oi", false));
	private static var lime_cairo_get_line_join = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_get_line_join", "oi", false));
	private static var lime_cairo_get_line_width = new cpp.Callable<cpp.Object->Float>(cpp.Prime._loadPrime("lime", "lime_cairo_get_line_width", "od", false));
	private static var lime_cairo_get_matrix = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_get_matrix", "oo", false));
	private static var lime_cairo_get_miter_limit = new cpp.Callable<cpp.Object->Float>(cpp.Prime._loadPrime("lime", "lime_cairo_get_miter_limit", "od",
		false));
	private static var lime_cairo_get_operator = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_get_operator", "oi", false));
	private static var lime_cairo_get_source = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_get_source", "oo", false));
	private static var lime_cairo_get_target = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_get_target", "oo", false));
	private static var lime_cairo_get_tolerance = new cpp.Callable<cpp.Object->Float>(cpp.Prime._loadPrime("lime", "lime_cairo_get_tolerance", "od", false));
	private static var lime_cairo_has_current_point = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_cairo_has_current_point", "ob",
		false));
	private static var lime_cairo_identity_matrix = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_identity_matrix", "ov",
		false));
	private static var lime_cairo_in_clip = new cpp.Callable<cpp.Object->Float->Float->Bool>(cpp.Prime._loadPrime("lime", "lime_cairo_in_clip", "oddb",
		false));
	private static var lime_cairo_in_fill = new cpp.Callable<cpp.Object->Float->Float->Bool>(cpp.Prime._loadPrime("lime", "lime_cairo_in_fill", "oddb",
		false));
	private static var lime_cairo_in_stroke = new cpp.Callable<cpp.Object->Float->Float->Bool>(cpp.Prime._loadPrime("lime", "lime_cairo_in_stroke", "oddb",
		false));
	private static var lime_cairo_line_to = new cpp.Callable<cpp.Object->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_line_to", "oddv",
		false));
	private static var lime_cairo_mask = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_mask", "oov", false));
	private static var lime_cairo_mask_surface = new cpp.Callable<cpp.Object->cpp.Object->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_mask_surface", "ooddv", false));
	private static var lime_cairo_move_to = new cpp.Callable<cpp.Object->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_move_to", "oddv",
		false));
	private static var lime_cairo_new_path = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_new_path", "ov", false));
	private static var lime_cairo_paint = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_paint", "ov", false));
	private static var lime_cairo_paint_with_alpha = new cpp.Callable<cpp.Object->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_paint_with_alpha",
		"odv", false));
	private static var lime_cairo_pop_group = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_pop_group", "oo", false));
	private static var lime_cairo_pop_group_to_source = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_pop_group_to_source",
		"ov", false));
	private static var lime_cairo_push_group = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_push_group", "ov", false));
	private static var lime_cairo_push_group_with_content = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_push_group_with_content", "oiv", false));
	private static var lime_cairo_rectangle = new cpp.Callable<cpp.Object->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_rectangle", "oddddv", false));
	private static var lime_cairo_rel_curve_to = new cpp.Callable<cpp.Object->Float->Float->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_rel_curve_to", "oddddddv", false));
	private static var lime_cairo_rel_line_to = new cpp.Callable<cpp.Object->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_rel_line_to",
		"oddv", false));
	private static var lime_cairo_rel_move_to = new cpp.Callable<cpp.Object->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_rel_move_to",
		"oddv", false));
	private static var lime_cairo_reset_clip = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_reset_clip", "ov", false));
	private static var lime_cairo_restore = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_restore", "ov", false));
	private static var lime_cairo_rotate = new cpp.Callable<cpp.Object->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_rotate", "odv", false));
	private static var lime_cairo_save = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_save", "ov", false));
	private static var lime_cairo_scale = new cpp.Callable<cpp.Object->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_scale", "oddv",
		false));
	private static var lime_cairo_set_antialias = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_antialias", "oiv",
		false));
	private static var lime_cairo_set_dash = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_dash", "oov",
		false));
	private static var lime_cairo_set_fill_rule = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_fill_rule", "oiv",
		false));
	private static var lime_cairo_set_font_face = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_font_face",
		"oov", false));
	private static var lime_cairo_set_font_options = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_set_font_options", "oov", false));
	private static var lime_cairo_set_font_size = new cpp.Callable<cpp.Object->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_font_size",
		"odv", false));
	private static var lime_cairo_set_line_cap = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_line_cap", "oiv",
		false));
	private static var lime_cairo_set_line_join = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_line_join", "oiv",
		false));
	private static var lime_cairo_set_line_width = new cpp.Callable<cpp.Object->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_line_width",
		"odv", false));
	private static var lime_cairo_set_matrix = new cpp.Callable<cpp.Object->Float->Float->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_set_matrix", "oddddddv", false));
	private static var lime_cairo_set_miter_limit = new cpp.Callable<cpp.Object->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_miter_limit",
		"odv", false));
	private static var lime_cairo_set_operator = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_operator", "oiv",
		false));
	private static var lime_cairo_set_source = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_source", "oov",
		false));
	private static var lime_cairo_set_source_rgb = new cpp.Callable<cpp.Object->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_set_source_rgb", "odddv", false));
	private static var lime_cairo_set_source_rgba = new cpp.Callable<cpp.Object->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_set_source_rgba", "oddddv", false));
	private static var lime_cairo_set_source_surface = new cpp.Callable<cpp.Object->cpp.Object->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_set_source_surface", "ooddv", false));
	private static var lime_cairo_set_tolerance = new cpp.Callable<cpp.Object->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_set_tolerance",
		"odv", false));
	private static var lime_cairo_show_glyphs = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_show_glyphs",
		"oov", false));
	private static var lime_cairo_show_page = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_show_page", "ov", false));
	private static var lime_cairo_show_text = new cpp.Callable<cpp.Object->String->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_show_text", "osv",
		false));
	private static var lime_cairo_status = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_status", "oi", false));
	private static var lime_cairo_stroke = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_stroke", "ov", false));
	private static var lime_cairo_stroke_extents = new cpp.Callable<cpp.Object->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_stroke_extents", "oddddv", false));
	private static var lime_cairo_stroke_preserve = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_stroke_preserve", "ov",
		false));
	private static var lime_cairo_text_path = new cpp.Callable<cpp.Object->String->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_text_path", "osv",
		false));
	private static var lime_cairo_transform = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_transform", "oov",
		false));
	private static var lime_cairo_translate = new cpp.Callable<cpp.Object->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_translate",
		"oddv", false));
	private static var lime_cairo_version = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_version", "i", false));
	private static var lime_cairo_version_string = new cpp.Callable<Void->String>(cpp.Prime._loadPrime("lime", "lime_cairo_version_string", "s", false));
	private static var lime_cairo_font_face_status = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_font_face_status", "oi",
		false));
	private static var lime_cairo_font_options_create = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_font_options_create", "o",
		false));
	private static var lime_cairo_font_options_get_antialias = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_cairo_font_options_get_antialias", "oi", false));
	private static var lime_cairo_font_options_get_hint_metrics = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_cairo_font_options_get_hint_metrics", "oi", false));
	private static var lime_cairo_font_options_get_hint_style = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_cairo_font_options_get_hint_style", "oi", false));
	private static var lime_cairo_font_options_get_subpixel_order = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_cairo_font_options_get_subpixel_order", "oi", false));
	private static var lime_cairo_font_options_set_antialias = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_font_options_set_antialias", "oiv", false));
	private static var lime_cairo_font_options_set_hint_metrics = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_font_options_set_hint_metrics", "oiv", false));
	private static var lime_cairo_font_options_set_hint_style = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_font_options_set_hint_style", "oiv", false));
	private static var lime_cairo_font_options_set_subpixel_order = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_font_options_set_subpixel_order", "oiv", false));
	private static var lime_cairo_ft_font_face_create = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_cairo_ft_font_face_create", "oio", false));
	private static var lime_cairo_image_surface_create = new cpp.Callable<Int->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_cairo_image_surface_create", "iiio", false));
	private static var lime_cairo_image_surface_create_for_data = new cpp.Callable<lime.utils.DataPointer->Int->Int->Int->Int->
		cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_image_surface_create_for_data", "diiiio", false));
	private static var lime_cairo_image_surface_get_data = new cpp.Callable<cpp.Object->lime.utils.DataPointer>(cpp.Prime._loadPrime("lime",
		"lime_cairo_image_surface_get_data", "od", false));
	private static var lime_cairo_image_surface_get_format = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_cairo_image_surface_get_format", "oi", false));
	private static var lime_cairo_image_surface_get_height = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_cairo_image_surface_get_height", "oi", false));
	private static var lime_cairo_image_surface_get_stride = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_cairo_image_surface_get_stride", "oi", false));
	private static var lime_cairo_image_surface_get_width = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_cairo_image_surface_get_width", "oi", false));
	private static var lime_cairo_pattern_add_color_stop_rgb = new cpp.Callable<cpp.Object->Float->Float->Float->Float->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_pattern_add_color_stop_rgb", "oddddv", false));
	private static var lime_cairo_pattern_add_color_stop_rgba = new cpp.Callable<cpp.Object->Float->Float->Float->Float->Float->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_pattern_add_color_stop_rgba", "odddddv", false));
	private static var lime_cairo_pattern_create_for_surface = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_cairo_pattern_create_for_surface", "oo", false));
	private static var lime_cairo_pattern_create_linear = new cpp.Callable<Float->Float->Float->Float->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_cairo_pattern_create_linear", "ddddo", false));
	private static var lime_cairo_pattern_create_radial = new cpp.Callable<Float->Float->Float->Float->Float->Float->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_cairo_pattern_create_radial", "ddddddo", false));
	private static var lime_cairo_pattern_create_rgb = new cpp.Callable<Float->Float->Float->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_cairo_pattern_create_rgb", "dddo", false));
	private static var lime_cairo_pattern_create_rgba = new cpp.Callable<Float->Float->Float->Float->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_cairo_pattern_create_rgba", "ddddo", false));
	private static var lime_cairo_pattern_get_color_stop_count = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_cairo_pattern_get_color_stop_count", "oi", false));
	private static var lime_cairo_pattern_get_extend = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_pattern_get_extend", "oi",
		false));
	private static var lime_cairo_pattern_get_filter = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_cairo_pattern_get_filter", "oi",
		false));
	private static var lime_cairo_pattern_get_matrix = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_cairo_pattern_get_matrix",
		"oo", false));
	private static var lime_cairo_pattern_set_extend = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_pattern_set_extend", "oiv", false));
	private static var lime_cairo_pattern_set_filter = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_pattern_set_filter", "oiv", false));
	private static var lime_cairo_pattern_set_matrix = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_cairo_pattern_set_matrix", "oov", false));
	private static var lime_cairo_surface_flush = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_cairo_surface_flush", "ov",
		false));
	#end
	#end
	#if (neko || cppia)
	private static var lime_cairo_arc = CFFI.load("lime", "lime_cairo_arc", -1);
	private static var lime_cairo_arc_negative = CFFI.load("lime", "lime_cairo_arc_negative", -1);
	private static var lime_cairo_clip = CFFI.load("lime", "lime_cairo_clip", 1);
	private static var lime_cairo_clip_preserve = CFFI.load("lime", "lime_cairo_clip_preserve", 1);
	private static var lime_cairo_clip_extents = CFFI.load("lime", "lime_cairo_clip_extents", 5);
	private static var lime_cairo_close_path = CFFI.load("lime", "lime_cairo_close_path", 1);
	private static var lime_cairo_copy_page = CFFI.load("lime", "lime_cairo_copy_page", 1);
	private static var lime_cairo_create = CFFI.load("lime", "lime_cairo_create", 1);
	private static var lime_cairo_curve_to = CFFI.load("lime", "lime_cairo_curve_to", -1);
	private static var lime_cairo_fill = CFFI.load("lime", "lime_cairo_fill", 1);
	private static var lime_cairo_fill_extents = CFFI.load("lime", "lime_cairo_fill_extents", 5);
	private static var lime_cairo_fill_preserve = CFFI.load("lime", "lime_cairo_fill_preserve", 1);
	private static var lime_cairo_get_antialias = CFFI.load("lime", "lime_cairo_get_antialias", 1);
	private static var lime_cairo_get_current_point = CFFI.load("lime", "lime_cairo_get_current_point", 1);
	private static var lime_cairo_get_dash = CFFI.load("lime", "lime_cairo_get_dash", 1);
	private static var lime_cairo_get_dash_count = CFFI.load("lime", "lime_cairo_get_dash_count", 1);
	private static var lime_cairo_get_fill_rule = CFFI.load("lime", "lime_cairo_get_fill_rule", 1);
	private static var lime_cairo_get_font_face = CFFI.load("lime", "lime_cairo_get_font_face", 1);
	private static var lime_cairo_get_font_options = CFFI.load("lime", "lime_cairo_get_font_options", 1);
	private static var lime_cairo_get_group_target = CFFI.load("lime", "lime_cairo_get_group_target", 1);
	private static var lime_cairo_get_line_cap = CFFI.load("lime", "lime_cairo_get_line_cap", 1);
	private static var lime_cairo_get_line_join = CFFI.load("lime", "lime_cairo_get_line_join", 1);
	private static var lime_cairo_get_line_width = CFFI.load("lime", "lime_cairo_get_line_width", 1);
	private static var lime_cairo_get_matrix = CFFI.load("lime", "lime_cairo_get_matrix", 1);
	private static var lime_cairo_get_miter_limit = CFFI.load("lime", "lime_cairo_get_miter_limit", 1);
	private static var lime_cairo_get_operator = CFFI.load("lime", "lime_cairo_get_operator", 1);
	private static var lime_cairo_get_source = CFFI.load("lime", "lime_cairo_get_source", 1);
	private static var lime_cairo_get_target = CFFI.load("lime", "lime_cairo_get_target", 1);
	private static var lime_cairo_get_tolerance = CFFI.load("lime", "lime_cairo_get_tolerance", 1);
	private static var lime_cairo_has_current_point = CFFI.load("lime", "lime_cairo_has_current_point", 1);
	private static var lime_cairo_identity_matrix = CFFI.load("lime", "lime_cairo_identity_matrix", 1);
	private static var lime_cairo_in_clip = CFFI.load("lime", "lime_cairo_in_clip", 3);
	private static var lime_cairo_in_fill = CFFI.load("lime", "lime_cairo_in_fill", 3);
	private static var lime_cairo_in_stroke = CFFI.load("lime", "lime_cairo_in_stroke", 3);
	private static var lime_cairo_line_to = CFFI.load("lime", "lime_cairo_line_to", 3);
	private static var lime_cairo_mask = CFFI.load("lime", "lime_cairo_mask", 2);
	private static var lime_cairo_mask_surface = CFFI.load("lime", "lime_cairo_mask_surface", 4);
	private static var lime_cairo_move_to = CFFI.load("lime", "lime_cairo_move_to", 3);
	private static var lime_cairo_new_path = CFFI.load("lime", "lime_cairo_new_path", 1);
	private static var lime_cairo_paint = CFFI.load("lime", "lime_cairo_paint", 1);
	private static var lime_cairo_paint_with_alpha = CFFI.load("lime", "lime_cairo_paint_with_alpha", 2);
	private static var lime_cairo_pop_group = CFFI.load("lime", "lime_cairo_pop_group", 1);
	private static var lime_cairo_pop_group_to_source = CFFI.load("lime", "lime_cairo_pop_group_to_source", 1);
	private static var lime_cairo_push_group = CFFI.load("lime", "lime_cairo_push_group", 1);
	private static var lime_cairo_push_group_with_content = CFFI.load("lime", "lime_cairo_push_group_with_content", 2);
	private static var lime_cairo_rectangle = CFFI.load("lime", "lime_cairo_rectangle", 5);
	private static var lime_cairo_rel_curve_to = CFFI.load("lime", "lime_cairo_rel_curve_to", -1);
	private static var lime_cairo_rel_line_to = CFFI.load("lime", "lime_cairo_rel_line_to", 3);
	private static var lime_cairo_rel_move_to = CFFI.load("lime", "lime_cairo_rel_move_to", 3);
	private static var lime_cairo_reset_clip = CFFI.load("lime", "lime_cairo_reset_clip", 1);
	private static var lime_cairo_restore = CFFI.load("lime", "lime_cairo_restore", 1);
	private static var lime_cairo_rotate = CFFI.load("lime", "lime_cairo_rotate", 2);
	private static var lime_cairo_save = CFFI.load("lime", "lime_cairo_save", 1);
	private static var lime_cairo_scale = CFFI.load("lime", "lime_cairo_scale", 3);
	private static var lime_cairo_set_antialias = CFFI.load("lime", "lime_cairo_set_antialias", 2);
	private static var lime_cairo_set_dash = CFFI.load("lime", "lime_cairo_set_dash", 2);
	private static var lime_cairo_set_fill_rule = CFFI.load("lime", "lime_cairo_set_fill_rule", 2);
	private static var lime_cairo_set_font_face = CFFI.load("lime", "lime_cairo_set_font_face", 2);
	private static var lime_cairo_set_font_options = CFFI.load("lime", "lime_cairo_set_font_options", 2);
	private static var lime_cairo_set_font_size = CFFI.load("lime", "lime_cairo_set_font_size", 2);
	private static var lime_cairo_set_line_cap = CFFI.load("lime", "lime_cairo_set_line_cap", 2);
	private static var lime_cairo_set_line_join = CFFI.load("lime", "lime_cairo_set_line_join", 2);
	private static var lime_cairo_set_line_width = CFFI.load("lime", "lime_cairo_set_line_width", 2);
	private static var lime_cairo_set_matrix = CFFI.load("lime", "lime_cairo_set_matrix", -1);
	private static var lime_cairo_set_miter_limit = CFFI.load("lime", "lime_cairo_set_miter_limit", 2);
	private static var lime_cairo_set_operator = CFFI.load("lime", "lime_cairo_set_operator", 2);
	private static var lime_cairo_set_source = CFFI.load("lime", "lime_cairo_set_source", 2);
	private static var lime_cairo_set_source_rgb = CFFI.load("lime", "lime_cairo_set_source_rgb", 4);
	private static var lime_cairo_set_source_rgba = CFFI.load("lime", "lime_cairo_set_source_rgba", 5);
	private static var lime_cairo_set_source_surface = CFFI.load("lime", "lime_cairo_set_source_surface", 4);
	private static var lime_cairo_set_tolerance = CFFI.load("lime", "lime_cairo_set_tolerance", 2);
	private static var lime_cairo_show_glyphs = CFFI.load("lime", "lime_cairo_show_glyphs", 2);
	private static var lime_cairo_show_page = CFFI.load("lime", "lime_cairo_show_page", 1);
	private static var lime_cairo_show_text = CFFI.load("lime", "lime_cairo_show_text", 2);
	private static var lime_cairo_status = CFFI.load("lime", "lime_cairo_status", 1);
	private static var lime_cairo_stroke = CFFI.load("lime", "lime_cairo_stroke", 1);
	private static var lime_cairo_stroke_extents = CFFI.load("lime", "lime_cairo_stroke_extents", 5);
	private static var lime_cairo_stroke_preserve = CFFI.load("lime", "lime_cairo_stroke_preserve", 1);
	private static var lime_cairo_text_path = CFFI.load("lime", "lime_cairo_text_path", 2);
	private static var lime_cairo_transform = CFFI.load("lime", "lime_cairo_transform", 2);
	private static var lime_cairo_translate = CFFI.load("lime", "lime_cairo_translate", 3);
	private static var lime_cairo_version = CFFI.load("lime", "lime_cairo_version", 0);
	private static var lime_cairo_version_string = CFFI.load("lime", "lime_cairo_version_string", 0);
	private static var lime_cairo_font_face_status = CFFI.load("lime", "lime_cairo_font_face_status", 1);
	private static var lime_cairo_font_options_create = CFFI.load("lime", "lime_cairo_font_options_create", 0);
	private static var lime_cairo_font_options_get_antialias = CFFI.load("lime", "lime_cairo_font_options_get_antialias", 1);
	private static var lime_cairo_font_options_get_hint_metrics = CFFI.load("lime", "lime_cairo_font_options_get_hint_metrics", 1);
	private static var lime_cairo_font_options_get_hint_style = CFFI.load("lime", "lime_cairo_font_options_get_hint_style", 1);
	private static var lime_cairo_font_options_get_subpixel_order = CFFI.load("lime", "lime_cairo_font_options_get_subpixel_order", 1);
	private static var lime_cairo_font_options_set_antialias = CFFI.load("lime", "lime_cairo_font_options_set_antialias", 2);
	private static var lime_cairo_font_options_set_hint_metrics = CFFI.load("lime", "lime_cairo_font_options_set_hint_metrics", 2);
	private static var lime_cairo_font_options_set_hint_style = CFFI.load("lime", "lime_cairo_font_options_set_hint_style", 2);
	private static var lime_cairo_font_options_set_subpixel_order = CFFI.load("lime", "lime_cairo_font_options_set_subpixel_order", 2);
	private static var lime_cairo_ft_font_face_create = CFFI.load("lime", "lime_cairo_ft_font_face_create", 2);
	private static var lime_cairo_image_surface_create = CFFI.load("lime", "lime_cairo_image_surface_create", 3);
	private static var lime_cairo_image_surface_create_for_data = CFFI.load("lime", "lime_cairo_image_surface_create_for_data", 5);
	private static var lime_cairo_image_surface_get_data = CFFI.load("lime", "lime_cairo_image_surface_get_data", 1);
	private static var lime_cairo_image_surface_get_format = CFFI.load("lime", "lime_cairo_image_surface_get_format", 1);
	private static var lime_cairo_image_surface_get_height = CFFI.load("lime", "lime_cairo_image_surface_get_height", 1);
	private static var lime_cairo_image_surface_get_stride = CFFI.load("lime", "lime_cairo_image_surface_get_stride", 1);
	private static var lime_cairo_image_surface_get_width = CFFI.load("lime", "lime_cairo_image_surface_get_width", 1);
	private static var lime_cairo_pattern_add_color_stop_rgb = CFFI.load("lime", "lime_cairo_pattern_add_color_stop_rgb", 5);
	private static var lime_cairo_pattern_add_color_stop_rgba = CFFI.load("lime", "lime_cairo_pattern_add_color_stop_rgba", -1);
	private static var lime_cairo_pattern_create_for_surface = CFFI.load("lime", "lime_cairo_pattern_create_for_surface", 1);
	private static var lime_cairo_pattern_create_linear = CFFI.load("lime", "lime_cairo_pattern_create_linear", 4);
	private static var lime_cairo_pattern_create_radial = CFFI.load("lime", "lime_cairo_pattern_create_radial", -1);
	private static var lime_cairo_pattern_create_rgb = CFFI.load("lime", "lime_cairo_pattern_create_rgb", 3);
	private static var lime_cairo_pattern_create_rgba = CFFI.load("lime", "lime_cairo_pattern_create_rgba", 4);
	private static var lime_cairo_pattern_get_color_stop_count = CFFI.load("lime", "lime_cairo_pattern_get_color_stop_count", 1);
	private static var lime_cairo_pattern_get_extend = CFFI.load("lime", "lime_cairo_pattern_get_extend", 1);
	private static var lime_cairo_pattern_get_filter = CFFI.load("lime", "lime_cairo_pattern_get_filter", 1);
	private static var lime_cairo_pattern_get_matrix = CFFI.load("lime", "lime_cairo_pattern_get_matrix", 1);
	private static var lime_cairo_pattern_set_extend = CFFI.load("lime", "lime_cairo_pattern_set_extend", 2);
	private static var lime_cairo_pattern_set_filter = CFFI.load("lime", "lime_cairo_pattern_set_filter", 2);
	private static var lime_cairo_pattern_set_matrix = CFFI.load("lime", "lime_cairo_pattern_set_matrix", 2);
	private static var lime_cairo_surface_flush = CFFI.load("lime", "lime_cairo_surface_flush", 1);
	#end

	#if hl
	@:hlNative("lime", "lime_cairo_arc") private static function lime_cairo_arc(handle:CFFIPointer, xc:Float, yc:Float, radius:Float, angle1:Float,
		angle2:Float):Void {}

	@:hlNative("lime", "lime_cairo_arc_negative") private static function lime_cairo_arc_negative(handle:CFFIPointer, xc:Float, yc:Float, radius:Float,
		angle1:Float, angle2:Float):Void {}

	@:hlNative("lime", "lime_cairo_clip") private static function lime_cairo_clip(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_clip_preserve") private static function lime_cairo_clip_preserve(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_clip_extents") private static function lime_cairo_clip_extents(handle:CFFIPointer, x1:Float, y1:Float, x2:Float,
		y2:Float):Void {}

	@:hlNative("lime", "lime_cairo_close_path") private static function lime_cairo_close_path(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_copy_page") private static function lime_cairo_copy_page(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_create") private static function lime_cairo_create(handle:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_curve_to") private static function lime_cairo_curve_to(handle:CFFIPointer, x1:Float, y1:Float, x2:Float, y2:Float,
		x3:Float, y3:Float):Void {}

	@:hlNative("lime", "lime_cairo_fill") private static function lime_cairo_fill(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_fill_extents") private static function lime_cairo_fill_extents(handle:CFFIPointer, x1:Float, y1:Float, x2:Float,
		y2:Float):Void {}

	@:hlNative("lime", "lime_cairo_fill_preserve") private static function lime_cairo_fill_preserve(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_get_antialias") private static function lime_cairo_get_antialias(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_get_current_point") private static function lime_cairo_get_current_point(handle:CFFIPointer, out:Vector2):Vector2
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_get_dash") private static function lime_cairo_get_dash(handle:CFFIPointer):hl.NativeArray<Float>
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_get_dash_count") private static function lime_cairo_get_dash_count(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_get_fill_rule") private static function lime_cairo_get_fill_rule(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_get_font_face") private static function lime_cairo_get_font_face(handle:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_get_font_options") private static function lime_cairo_get_font_options(handle:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_get_group_target") private static function lime_cairo_get_group_target(handle:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_get_line_cap") private static function lime_cairo_get_line_cap(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_get_line_join") private static function lime_cairo_get_line_join(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_get_line_width") private static function lime_cairo_get_line_width(handle:CFFIPointer):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_get_matrix") private static function lime_cairo_get_matrix(handle:CFFIPointer, out:Matrix3):Matrix3
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_get_miter_limit") private static function lime_cairo_get_miter_limit(handle:CFFIPointer):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_get_operator") private static function lime_cairo_get_operator(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_get_source") private static function lime_cairo_get_source(handle:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_get_target") private static function lime_cairo_get_target(handle:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_get_tolerance") private static function lime_cairo_get_tolerance(handle:CFFIPointer):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_has_current_point") private static function lime_cairo_has_current_point(handle:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_cairo_identity_matrix") private static function lime_cairo_identity_matrix(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_in_clip") private static function lime_cairo_in_clip(handle:CFFIPointer, x:Float, y:Float):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_cairo_in_fill") private static function lime_cairo_in_fill(handle:CFFIPointer, x:Float, y:Float):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_cairo_in_stroke") private static function lime_cairo_in_stroke(handle:CFFIPointer, x:Float, y:Float):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_cairo_line_to") private static function lime_cairo_line_to(handle:CFFIPointer, x:Float, y:Float):Void {}

	@:hlNative("lime", "lime_cairo_mask") private static function lime_cairo_mask(handle:CFFIPointer, pattern:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_mask_surface") private static function lime_cairo_mask_surface(handle:CFFIPointer, surface:CFFIPointer, x:Float,
		y:Float):Void {}

	@:hlNative("lime", "lime_cairo_move_to") private static function lime_cairo_move_to(handle:CFFIPointer, x:Float, y:Float):Void {}

	@:hlNative("lime", "lime_cairo_new_path") private static function lime_cairo_new_path(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_paint") private static function lime_cairo_paint(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_paint_with_alpha") private static function lime_cairo_paint_with_alpha(handle:CFFIPointer, alpha:Float):Void {}

	@:hlNative("lime", "lime_cairo_pop_group") private static function lime_cairo_pop_group(handle:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_pop_group_to_source") private static function lime_cairo_pop_group_to_source(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_push_group") private static function lime_cairo_push_group(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_push_group_with_content") private static function lime_cairo_push_group_with_content(handle:CFFIPointer,
		content:Int):Void {}

	@:hlNative("lime", "lime_cairo_rectangle") private static function lime_cairo_rectangle(handle:CFFIPointer, x:Float, y:Float, width:Float,
		height:Float):Void {}

	@:hlNative("lime", "lime_cairo_rel_curve_to") private static function lime_cairo_rel_curve_to(handle:CFFIPointer, dx1:Float, dy1:Float, dx2:Float,
		dy2:Float, dx3:Float, dy3:Float):Void {}

	@:hlNative("lime", "lime_cairo_rel_line_to") private static function lime_cairo_rel_line_to(handle:CFFIPointer, dx:Float, dy:Float):Void {}

	@:hlNative("lime", "lime_cairo_rel_move_to") private static function lime_cairo_rel_move_to(handle:CFFIPointer, dx:Float, dy:Float):Void {}

	@:hlNative("lime", "lime_cairo_reset_clip") private static function lime_cairo_reset_clip(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_restore") private static function lime_cairo_restore(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_rotate") private static function lime_cairo_rotate(handle:CFFIPointer, amount:Float):Void {}

	@:hlNative("lime", "lime_cairo_save") private static function lime_cairo_save(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_scale") private static function lime_cairo_scale(handle:CFFIPointer, x:Float, y:Float):Void {}

	@:hlNative("lime", "lime_cairo_set_antialias") private static function lime_cairo_set_antialias(handle:CFFIPointer, cap:Int):Void {}

	@:hlNative("lime", "lime_cairo_set_dash") private static function lime_cairo_set_dash(handle:CFFIPointer, dash:hl.NativeArray<Float>):Void {}

	@:hlNative("lime", "lime_cairo_set_fill_rule") private static function lime_cairo_set_fill_rule(handle:CFFIPointer, cap:Int):Void {}

	@:hlNative("lime", "lime_cairo_set_font_face") private static function lime_cairo_set_font_face(handle:CFFIPointer, face:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_set_font_options") private static function lime_cairo_set_font_options(handle:CFFIPointer, options:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_set_font_size") private static function lime_cairo_set_font_size(handle:CFFIPointer, size:Float):Void {}

	@:hlNative("lime", "lime_cairo_set_line_cap") private static function lime_cairo_set_line_cap(handle:CFFIPointer, cap:Int):Void {}

	@:hlNative("lime", "lime_cairo_set_line_join") private static function lime_cairo_set_line_join(handle:CFFIPointer, join:Int):Void {}

	@:hlNative("lime", "lime_cairo_set_line_width") private static function lime_cairo_set_line_width(handle:CFFIPointer, width:Float):Void {}

	@:hlNative("lime", "lime_cairo_set_matrix") private static function lime_cairo_set_matrix(handle:CFFIPointer, matrix:Matrix3):Void {}

	@:hlNative("lime", "lime_cairo_set_miter_limit") private static function lime_cairo_set_miter_limit(handle:CFFIPointer, miterLimit:Float):Void {}

	@:hlNative("lime", "lime_cairo_set_operator") private static function lime_cairo_set_operator(handle:CFFIPointer, op:Int):Void {}

	@:hlNative("lime", "lime_cairo_set_source") private static function lime_cairo_set_source(handle:CFFIPointer, pattern:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_set_source_rgb") private static function lime_cairo_set_source_rgb(handle:CFFIPointer, r:Float, g:Float, b:Float):Void {}

	@:hlNative("lime", "lime_cairo_set_source_rgba") private static function lime_cairo_set_source_rgba(handle:CFFIPointer, r:Float, g:Float, b:Float,
		a:Float):Void {}

	@:hlNative("lime", "lime_cairo_set_source_surface") private static function lime_cairo_set_source_surface(handle:CFFIPointer, surface:CFFIPointer,
		x:Float, y:Float):Void {}

	@:hlNative("lime", "lime_cairo_set_tolerance") private static function lime_cairo_set_tolerance(handle:CFFIPointer, tolerance:Float):Void {}

	@:hlNative("lime", "lime_cairo_show_glyphs") private static function lime_cairo_show_glyphs(handle:CFFIPointer, glyphs:hl.NativeArray<CairoGlyph>):Void {}

	@:hlNative("lime", "lime_cairo_show_page") private static function lime_cairo_show_page(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_show_text") private static function lime_cairo_show_text(handle:CFFIPointer, text:String):Void {}

	@:hlNative("lime", "lime_cairo_status") private static function lime_cairo_status(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_stroke") private static function lime_cairo_stroke(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_stroke_extents") private static function lime_cairo_stroke_extents(handle:CFFIPointer, x1:Float, y1:Float, x2:Float,
		y2:Float):Void {}

	@:hlNative("lime", "lime_cairo_stroke_preserve") private static function lime_cairo_stroke_preserve(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_cairo_text_path") private static function lime_cairo_text_path(handle:CFFIPointer, text:String):Void {}

	@:hlNative("lime", "lime_cairo_transform") private static function lime_cairo_transform(handle:CFFIPointer, matrix:Matrix3):Void {}

	@:hlNative("lime", "lime_cairo_translate") private static function lime_cairo_translate(handle:CFFIPointer, x:Float, y:Float):Void {}

	@:hlNative("lime", "lime_cairo_version") private static function lime_cairo_version():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_version_string") private static function lime_cairo_version_string():hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_font_face_status") private static function lime_cairo_font_face_status(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_font_options_create") private static function lime_cairo_font_options_create():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_font_options_get_antialias") private static function lime_cairo_font_options_get_antialias(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_font_options_get_hint_metrics") private static function lime_cairo_font_options_get_hint_metrics(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_font_options_get_hint_style") private static function lime_cairo_font_options_get_hint_style(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_font_options_get_subpixel_order") private static function lime_cairo_font_options_get_subpixel_order(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_font_options_set_antialias") private static function lime_cairo_font_options_set_antialias(handle:CFFIPointer,
		v:Int):Void {}

	@:hlNative("lime", "lime_cairo_font_options_set_hint_metrics") private static function lime_cairo_font_options_set_hint_metrics(handle:CFFIPointer,
		v:Int):Void {}

	@:hlNative("lime", "lime_cairo_font_options_set_hint_style") private static function lime_cairo_font_options_set_hint_style(handle:CFFIPointer,
		v:Int):Void {}

	@:hlNative("lime", "lime_cairo_font_options_set_subpixel_order") private static function lime_cairo_font_options_set_subpixel_order(handle:CFFIPointer,
		v:Int):Void {}

	@:hlNative("lime", "lime_cairo_ft_font_face_create") private static function lime_cairo_ft_font_face_create(face:CFFIPointer, flags:Int):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_image_surface_create") private static function lime_cairo_image_surface_create(format:Int, width:Int,
			height:Int):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_image_surface_create_for_data") private static function lime_cairo_image_surface_create_for_data(data:Float, format:Int,
			width:Int, height:Int, stride:Int):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_image_surface_get_data") private static function lime_cairo_image_surface_get_data(handle:CFFIPointer):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_image_surface_get_format") private static function lime_cairo_image_surface_get_format(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_image_surface_get_height") private static function lime_cairo_image_surface_get_height(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_image_surface_get_stride") private static function lime_cairo_image_surface_get_stride(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_image_surface_get_width") private static function lime_cairo_image_surface_get_width(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_pattern_add_color_stop_rgb") private static function lime_cairo_pattern_add_color_stop_rgb(handle:CFFIPointer,
		offset:Float, red:Float, green:Float, blue:Float):Void {}

	@:hlNative("lime", "lime_cairo_pattern_add_color_stop_rgba") private static function lime_cairo_pattern_add_color_stop_rgba(handle:CFFIPointer,
		offset:Float, red:Float, green:Float, blue:Float, alpha:Float):Void {}

	@:hlNative("lime", "lime_cairo_pattern_create_for_surface") private static function lime_cairo_pattern_create_for_surface(surface:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_pattern_create_linear") private static function lime_cairo_pattern_create_linear(x0:Float, y0:Float, x1:Float,
			y1:Float):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_pattern_create_radial") private static function lime_cairo_pattern_create_radial(cx0:Float, cy0:Float, radius0:Float,
			cx1:Float, cy1:Float, radius1:Float):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_pattern_create_rgb") private static function lime_cairo_pattern_create_rgb(r:Float, g:Float, b:Float):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_pattern_create_rgba") private static function lime_cairo_pattern_create_rgba(r:Float, g:Float, b:Float, a:Float):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_pattern_get_color_stop_count") private static function lime_cairo_pattern_get_color_stop_count(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_pattern_get_extend") private static function lime_cairo_pattern_get_extend(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_pattern_get_filter") private static function lime_cairo_pattern_get_filter(handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_cairo_pattern_get_matrix") private static function lime_cairo_pattern_get_matrix(handle:CFFIPointer, out:Matrix3):Matrix3
	{
		return null;
	}

	@:hlNative("lime", "lime_cairo_pattern_set_extend") private static function lime_cairo_pattern_set_extend(handle:CFFIPointer, extend:Int):Void {}

	@:hlNative("lime", "lime_cairo_pattern_set_filter") private static function lime_cairo_pattern_set_filter(handle:CFFIPointer, filter:Int):Void {}

	@:hlNative("lime", "lime_cairo_pattern_set_matrix") private static function lime_cairo_pattern_set_matrix(handle:CFFIPointer, matrix:Matrix3):Void {}

	@:hlNative("lime", "lime_cairo_surface_flush") private static function lime_cairo_surface_flush(surface:CFFIPointer):Void {}
	#end
	#end
	#if (lime_cffi && !macro && lime_curl)
	#if (cpp && !cppia)
	#if (disable_cffi || haxe_ver < "3.4.0")
	@:cffi private static function lime_curl_getdate(date:String, now:Float):Float;

	@:cffi private static function lime_curl_global_cleanup():Void;

	@:cffi private static function lime_curl_global_init(flags:Int):Int;

	@:cffi private static function lime_curl_version():Dynamic;

	@:cffi private static function lime_curl_version_info(type:Int):Dynamic;

	@:cffi private static function lime_curl_easy_cleanup(handle:CFFIPointer):Void;

	@:cffi private static function lime_curl_easy_duphandle(handle:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_curl_easy_escape(curl:CFFIPointer, url:String, length:Int):Dynamic;

	@:cffi private static function lime_curl_easy_flush(curl:CFFIPointer):Void;

	@:cffi private static function lime_curl_easy_getinfo(curl:CFFIPointer, info:Int):Dynamic;

	@:cffi private static function lime_curl_easy_init():CFFIPointer;

	@:cffi private static function lime_curl_easy_pause(handle:CFFIPointer, bitmask:Int):Int;

	@:cffi private static function lime_curl_easy_perform(easy_handle:CFFIPointer):Int;

	@:cffi private static function lime_curl_easy_recv(curl:CFFIPointer, buffer:Dynamic, buflen:Int, n:Int):Int;

	@:cffi private static function lime_curl_easy_reset(curl:CFFIPointer):Void;

	@:cffi private static function lime_curl_easy_send(curl:CFFIPointer, buffer:Dynamic, buflen:Int, n:Int):Int;

	@:cffi private static function lime_curl_easy_setopt(handle:CFFIPointer, option:Int, parameter:Dynamic, writeBytes:Dynamic):Int;

	@:cffi private static function lime_curl_easy_strerror(errornum:Int):Dynamic;

	@:cffi private static function lime_curl_easy_unescape(curl:CFFIPointer, url:String, inlength:Int, outlength:Int):Dynamic;

	@:cffi private static function lime_curl_multi_init():CFFIPointer;

	@:cffi private static function lime_curl_multi_add_handle(multi_handle:CFFIPointer, curl_object:Dynamic, curl_handle:CFFIPointer):Int;

	@:cffi private static function lime_curl_multi_get_running_handles(multi_handle:CFFIPointer):Int;

	@:cffi private static function lime_curl_multi_info_read(multi_handle:CFFIPointer):Dynamic;

	@:cffi private static function lime_curl_multi_perform(multi_handle:CFFIPointer):Int;

	@:cffi private static function lime_curl_multi_remove_handle(multi_handle:CFFIPointer, curl_handle:CFFIPointer):Int;

	@:cffi private static function lime_curl_multi_setopt(multi_handle:CFFIPointer, option:Int, parameter:Dynamic):Int;

	@:cffi private static function lime_curl_multi_wait(multi_handle:CFFIPointer, timeout_ms:Int):Int;
	#else
	private static var lime_curl_getdate = new cpp.Callable<String->Float->Float>(cpp.Prime._loadPrime("lime", "lime_curl_getdate", "sdd", false));
	private static var lime_curl_global_cleanup = new cpp.Callable<Void->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_curl_global_cleanup", "v", false));
	private static var lime_curl_global_init = new cpp.Callable<Int->Int>(cpp.Prime._loadPrime("lime", "lime_curl_global_init", "ii", false));
	private static var lime_curl_version = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_curl_version", "o", false));
	private static var lime_curl_version_info = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_curl_version_info", "io", false));
	private static var lime_curl_easy_cleanup = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_curl_easy_cleanup", "ov", false));
	private static var lime_curl_easy_duphandle = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_curl_easy_duphandle", "oo",
		false));
	private static var lime_curl_easy_escape = new cpp.Callable<cpp.Object->String->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_curl_easy_escape",
		"osio", false));
	private static var lime_curl_easy_flush = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_curl_easy_flush", "ov", false));
	private static var lime_curl_easy_getinfo = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_curl_easy_getinfo", "oio",
		false));
	private static var lime_curl_easy_init = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_curl_easy_init", "o", false));
	private static var lime_curl_easy_pause = new cpp.Callable<cpp.Object->Int->Int>(cpp.Prime._loadPrime("lime", "lime_curl_easy_pause", "oii", false));
	private static var lime_curl_easy_perform = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_curl_easy_perform", "oi", false));
	private static var lime_curl_easy_recv = new cpp.Callable<cpp.Object->cpp.Object->Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_curl_easy_recv",
		"ooiii", false));
	private static var lime_curl_easy_reset = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_curl_easy_reset", "ov", false));
	private static var lime_curl_easy_send = new cpp.Callable<cpp.Object->cpp.Object->Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_curl_easy_send",
		"ooiii", false));
	private static var lime_curl_easy_setopt = new cpp.Callable<cpp.Object->Int->cpp.Object->cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_curl_easy_setopt", "oiooi", false));
	private static var lime_curl_easy_strerror = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_curl_easy_strerror", "io", false));
	private static var lime_curl_easy_unescape = new cpp.Callable<cpp.Object->String->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_curl_easy_unescape", "osiio", false));
	private static var lime_curl_multi_init = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_curl_multi_init", "o", false));
	private static var lime_curl_multi_add_handle = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_curl_multi_add_handle", "oooi", false));
	private static var lime_curl_multi_get_running_handles = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_curl_multi_get_running_handles", "oi", false));
	private static var lime_curl_multi_info_read = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_curl_multi_info_read", "oo",
		false));
	private static var lime_curl_multi_perform = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_curl_multi_perform", "oi", false));
	private static var lime_curl_multi_remove_handle = new cpp.Callable<cpp.Object->cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_curl_multi_remove_handle", "ooi", false));
	private static var lime_curl_multi_setopt = new cpp.Callable<cpp.Object->Int->cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_curl_multi_setopt",
		"oioi", false));
	private static var lime_curl_multi_wait = new cpp.Callable<cpp.Object->Int->Int>(cpp.Prime._loadPrime("lime", "lime_curl_multi_wait", "oii", false));
	#end
	#end
	#if (neko || cppia)
	private static var lime_curl_getdate = CFFI.load("lime", "lime_curl_getdate", 2);
	private static var lime_curl_global_cleanup = CFFI.load("lime", "lime_curl_global_cleanup", 0);
	private static var lime_curl_global_init = CFFI.load("lime", "lime_curl_global_init", 1);
	private static var lime_curl_version = CFFI.load("lime", "lime_curl_version", 0);
	private static var lime_curl_version_info = CFFI.load("lime", "lime_curl_version_info", 1);
	private static var lime_curl_easy_cleanup = CFFI.load("lime", "lime_curl_easy_cleanup", 1);
	private static var lime_curl_easy_duphandle = CFFI.load("lime", "lime_curl_easy_duphandle", 1);
	private static var lime_curl_easy_escape = CFFI.load("lime", "lime_curl_easy_escape", 3);
	private static var lime_curl_easy_flush = CFFI.load("lime", "lime_curl_easy_flush", 1);
	private static var lime_curl_easy_getinfo = CFFI.load("lime", "lime_curl_easy_getinfo", 2);
	private static var lime_curl_easy_init = CFFI.load("lime", "lime_curl_easy_init", 0);
	private static var lime_curl_easy_pause = CFFI.load("lime", "lime_curl_easy_pause", 2);
	private static var lime_curl_easy_perform = CFFI.load("lime", "lime_curl_easy_perform", 1);
	private static var lime_curl_easy_recv = CFFI.load("lime", "lime_curl_easy_recv", 4);
	private static var lime_curl_easy_reset = CFFI.load("lime", "lime_curl_easy_reset", 1);
	private static var lime_curl_easy_send = CFFI.load("lime", "lime_curl_easy_send", 4);
	private static var lime_curl_easy_setopt = CFFI.load("lime", "lime_curl_easy_setopt", 4);
	private static var lime_curl_easy_strerror = CFFI.load("lime", "lime_curl_easy_strerror", 1);
	private static var lime_curl_easy_unescape = CFFI.load("lime", "lime_curl_easy_unescape", 4);
	private static var lime_curl_multi_init = CFFI.load("lime", "lime_curl_multi_init", 0);
	private static var lime_curl_multi_add_handle = CFFI.load("lime", "lime_curl_multi_add_handle", 3);
	private static var lime_curl_multi_get_running_handles = CFFI.load("lime", "lime_curl_multi_get_running_handles", 1);
	private static var lime_curl_multi_info_read = CFFI.load("lime", "lime_curl_multi_info_read", 1);
	private static var lime_curl_multi_perform = CFFI.load("lime", "lime_curl_multi_perform", 1);
	private static var lime_curl_multi_remove_handle = CFFI.load("lime", "lime_curl_multi_remove_handle", 2);
	private static var lime_curl_multi_setopt = CFFI.load("lime", "lime_curl_multi_setopt", 3);
	private static var lime_curl_multi_wait = CFFI.load("lime", "lime_curl_multi_wait", 2);
	#end

	#if hl
	@:hlNative("lime", "lime_curl_getdate") private static function lime_curl_getdate(date:String, now:Float):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_global_cleanup") private static function lime_curl_global_cleanup():Void {}

	@:hlNative("lime", "lime_curl_global_init") private static function lime_curl_global_init(flags:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_version") private static function lime_curl_version():hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_curl_version_info") private static function lime_curl_version_info(type:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_curl_easy_cleanup") private static function lime_curl_easy_cleanup(handle:CFFIPointer):Void {}

	@:hlNative("lime", "lime_curl_easy_duphandle") private static function lime_curl_easy_duphandle(handle:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_curl_easy_escape") private static function lime_curl_easy_escape(curl:CFFIPointer, url:String, length:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_curl_easy_flush") private static function lime_curl_easy_flush(curl:CFFIPointer):Void {}

	@:hlNative("lime", "lime_curl_easy_getinfo") private static function lime_curl_easy_getinfo(curl:CFFIPointer, info:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_curl_easy_init") private static function lime_curl_easy_init():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_curl_easy_pause") private static function lime_curl_easy_pause(handle:CFFIPointer, bitmask:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_easy_perform") private static function lime_curl_easy_perform(easy_handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_easy_recv") private static function lime_curl_easy_recv(curl:CFFIPointer, buffer:Float, buflen:Int, n:Int):Int
	{
		return 0;
	};

	@:hlNative("lime", "lime_curl_easy_reset") private static function lime_curl_easy_reset(curl:CFFIPointer):Void {}

	@:hlNative("lime", "lime_curl_easy_send") private static function lime_curl_easy_send(curl:CFFIPointer, buffer:Float, buflen:Int, n:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_easy_setopt") private static function lime_curl_easy_setopt(handle:CFFIPointer, option:Int, parameter:Dynamic,
			writeBytes:Bytes):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_easy_strerror") private static function lime_curl_easy_strerror(errornum:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_curl_easy_unescape") private static function lime_curl_easy_unescape(curl:CFFIPointer, url:String, inlength:Int,
			outlength:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_curl_multi_init") private static function lime_curl_multi_init():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_curl_multi_add_handle") private static function lime_curl_multi_add_handle(multi_handle:CFFIPointer, curl_object:Dynamic,
			curl_handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_multi_get_running_handles") private static function lime_curl_multi_get_running_handles(multi_handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_multi_info_read") private static function lime_curl_multi_info_read(multi_handle:CFFIPointer, object:Dynamic):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_curl_multi_perform") private static function lime_curl_multi_perform(multi_handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_multi_remove_handle") private static function lime_curl_multi_remove_handle(multi_handle:CFFIPointer,
			curl_handle:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_multi_setopt") private static function lime_curl_multi_setopt(multi_handle:CFFIPointer, option:Int, parameter:Dynamic):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_curl_multi_wait") private static function lime_curl_multi_wait(multi_handle:CFFIPointer, timeout_ms:Int):Int
	{
		return 0;
	}
	#end
	#end
	#if (lime_cffi && !macro && (lime_opengl || lime_opengles))
	#if (cpp && !cppia)
	#if (disable_cffi || haxe_ver < "3.4.0")
	@:cffi private static function lime_gl_active_texture(texture:Int):Void;

	@:cffi private static function lime_gl_attach_shader(program:Int, shader:Int):Void;

	@:cffi private static function lime_gl_begin_query(target:Int, query:Int):Void;

	@:cffi private static function lime_gl_begin_transform_feedback(primitiveNode:Int):Void;

	@:cffi private static function lime_gl_bind_attrib_location(program:Int, index:Int, name:String):Void;

	@:cffi private static function lime_gl_bind_buffer(target:Int, buffer:Int):Void;

	@:cffi private static function lime_gl_bind_buffer_base(target:Int, index:Int, buffer:Int):Void;

	@:cffi private static function lime_gl_bind_buffer_range(target:Int, index:Int, buffer:Int, offset:DataPointer, size:Int):Void;

	@:cffi private static function lime_gl_bind_framebuffer(target:Int, framebuffer:Int):Void;

	@:cffi private static function lime_gl_bind_renderbuffer(target:Int, renderbuffer:Int):Void;

	@:cffi private static function lime_gl_bind_sampler(target:Int, sampler:Int):Void;

	@:cffi private static function lime_gl_bind_texture(target:Int, texture:Int):Void;

	@:cffi private static function lime_gl_bind_transform_feedback(target:Int, transformFeedback:Int):Void;

	@:cffi private static function lime_gl_bind_vertex_array(vertexArray:Int):Void;

	@:cffi private static function lime_gl_blend_color(red:Float32, green:Float32, blue:Float32, alpha:Float32):Void;

	@:cffi private static function lime_gl_blend_equation(mode:Int):Void;

	@:cffi private static function lime_gl_blend_equation_separate(modeRGB:Int, modeAlpha:Int):Void;

	@:cffi private static function lime_gl_blend_func(sfactor:Int, dfactor:Int):Void;

	@:cffi private static function lime_gl_blend_func_separate(srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void;

	@:cffi private static function lime_gl_blit_framebuffer(srcX0:Int, srcY0:Int, srcX1:Int, srcY1:Int, dstX0:Int, dstY0:Int, dstX1:Int, dstY1:Int, mask:Int,
		filter:Int):Void;

	@:cffi private static function lime_gl_buffer_data(target:Int, size:Int, srcData:DataPointer, usage:Int):Void;

	@:cffi private static function lime_gl_buffer_sub_data(target:Int, offset:Int, size:Int, srcData:DataPointer):Void;

	@:cffi private static function lime_gl_check_framebuffer_status(target:Int):Int;

	@:cffi private static function lime_gl_clear(mask:Int):Void;

	@:cffi private static function lime_gl_clear_bufferfi(buffer:Int, drawBuffer:Int, depth:Float32, stencil:Int):Void;

	@:cffi private static function lime_gl_clear_bufferfv(buffer:Int, drawBuffer:Int, data:DataPointer):Void;

	@:cffi private static function lime_gl_clear_bufferiv(buffer:Int, drawBuffer:Int, data:DataPointer):Void;

	@:cffi private static function lime_gl_clear_bufferuiv(buffer:Int, drawBuffer:Int, data:DataPointer):Void;

	@:cffi private static function lime_gl_client_wait_sync(sync:CFFIPointer, flags:Int, timeoutA:Int, timeoutB:Int):Int;

	@:cffi private static function lime_gl_clear_color(red:Float32, green:Float32, blue:Float32, alpha:Float32):Void;

	@:cffi private static function lime_gl_clear_depthf(depth:Float32):Void;

	@:cffi private static function lime_gl_clear_stencil(s:Int):Void;

	@:cffi private static function lime_gl_color_mask(red:Bool, green:Bool, blue:Bool, alpha:Bool):Void;

	@:cffi private static function lime_gl_compile_shader(shader:Int):Void;

	@:cffi private static function lime_gl_compressed_tex_image_2d(target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int,
		imageSize:Int, data:DataPointer):Void;

	@:cffi private static function lime_gl_compressed_tex_image_3d(target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int,
		imageSize:Int, data:DataPointer):Void;

	@:cffi private static function lime_gl_compressed_tex_sub_image_2d(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int,
		imageSize:Int, data:DataPointer):Void;

	@:cffi private static function lime_gl_compressed_tex_sub_image_3d(target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int,
		depth:Int, format:Int, imageSize:Int, data:DataPointer):Void;

	@:cffi private static function lime_gl_copy_buffer_sub_data(readTarget:Int, writeTarget:Int, readOffset:DataPointer, writeOffset:DataPointer,
		size:Int):Void;

	@:cffi private static function lime_gl_copy_tex_image_2d(target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void;

	@:cffi private static function lime_gl_copy_tex_sub_image_2d(target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void;

	@:cffi private static function lime_gl_copy_tex_sub_image_3d(target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, x:Int, y:Int, width:Int,
		height:Int):Void;

	@:cffi private static function lime_gl_create_buffer():Int;

	@:cffi private static function lime_gl_create_framebuffer():Int;

	@:cffi private static function lime_gl_create_program():Int;

	@:cffi private static function lime_gl_create_query():Int;

	@:cffi private static function lime_gl_create_renderbuffer():Int;

	@:cffi private static function lime_gl_create_sampler():Int;

	@:cffi private static function lime_gl_create_shader(type:Int):Int;

	@:cffi private static function lime_gl_create_texture():Int;

	@:cffi private static function lime_gl_create_transform_feedback():Int;

	@:cffi private static function lime_gl_create_vertex_array():Int;

	@:cffi private static function lime_gl_cull_face(mode:Int):Void;

	@:cffi private static function lime_gl_delete_buffer(buffer:Int):Void;

	@:cffi private static function lime_gl_delete_framebuffer(framebuffer:Int):Void;

	@:cffi private static function lime_gl_delete_program(program:Int):Void;

	@:cffi private static function lime_gl_delete_query(query:Int):Void;

	@:cffi private static function lime_gl_delete_renderbuffer(renderbuffer:Int):Void;

	@:cffi private static function lime_gl_delete_sampler(sampler:Int):Void;

	@:cffi private static function lime_gl_delete_shader(shader:Int):Void;

	@:cffi private static function lime_gl_delete_sync(sync:CFFIPointer):Void;

	@:cffi private static function lime_gl_delete_texture(texture:Int):Void;

	@:cffi private static function lime_gl_delete_transform_feedback(transformFeedback:Int):Void;

	@:cffi private static function lime_gl_delete_vertex_array(vertexArray:Int):Void;

	@:cffi private static function lime_gl_depth_func(func:Int):Void;

	@:cffi private static function lime_gl_depth_mask(flag:Bool):Void;

	@:cffi private static function lime_gl_depth_rangef(zNear:Float32, zFar:Float32):Void;

	@:cffi private static function lime_gl_detach_shader(program:Int, shader:Int):Void;

	@:cffi private static function lime_gl_disable(cap:Int):Void;

	@:cffi private static function lime_gl_disable_vertex_attrib_array(index:Int):Void;

	@:cffi private static function lime_gl_draw_arrays(mode:Int, first:Int, count:Int):Void;

	@:cffi private static function lime_gl_draw_arrays_instanced(mode:Int, first:Int, count:Int, instanceCount:Int):Void;

	@:cffi private static function lime_gl_draw_buffers(buffers:Dynamic):Void;

	@:cffi private static function lime_gl_draw_elements(mode:Int, count:Int, type:Int, offset:DataPointer):Void;

	@:cffi private static function lime_gl_draw_elements_instanced(mode:Int, count:Int, type:Int, offset:DataPointer, instanceCount:Int):Void;

	@:cffi private static function lime_gl_draw_range_elements(mode:Int, start:Int, end:Int, count:Int, type:Int, offset:DataPointer):Void;

	@:cffi private static function lime_gl_enable(cap:Int):Void;

	@:cffi private static function lime_gl_enable_vertex_attrib_array(index:Int):Void;

	@:cffi private static function lime_gl_end_query(target:Int):Void;

	@:cffi private static function lime_gl_end_transform_feedback():Void;

	@:cffi private static function lime_gl_fence_sync(condition:Int, flags:Int):CFFIPointer;

	@:cffi private static function lime_gl_finish():Void;

	@:cffi private static function lime_gl_flush():Void;

	@:cffi private static function lime_gl_framebuffer_renderbuffer(target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:Int):Void;

	@:cffi private static function lime_gl_framebuffer_texture2D(target:Int, attachment:Int, textarget:Int, texture:Int, level:Int):Void;

	@:cffi private static function lime_gl_framebuffer_texture_layer(target:Int, attachment:Int, texture:Int, level:Int, layer:Int):Void;

	@:cffi private static function lime_gl_front_face(mode:Int):Void;

	@:cffi private static function lime_gl_generate_mipmap(target:Int):Void;

	@:cffi private static function lime_gl_get_active_attrib(program:Int, index:Int):Dynamic;

	@:cffi private static function lime_gl_get_active_uniform(program:Int, index:Int):Dynamic;

	@:cffi private static function lime_gl_get_active_uniform_blocki(program:Int, uniformBlockIndex:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_active_uniform_blockiv(program:Int, uniformBlockIndex:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_active_uniform_block_name(program:Int, uniformBlockIndex:Int):Dynamic;

	@:cffi private static function lime_gl_get_active_uniformsiv(program:Int, uniformIndices:Dynamic, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_attached_shaders(program:Int):Dynamic;

	@:cffi private static function lime_gl_get_attrib_location(program:Int, name:String):Int;

	@:cffi private static function lime_gl_get_boolean(pname:Int):Bool;

	@:cffi private static function lime_gl_get_booleanv(pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_buffer_parameteri(target:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_buffer_parameteri64v(target:Int, index:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_buffer_parameteriv(target:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_buffer_pointerv(target:Int, pname:Int):DataPointer;

	@:cffi private static function lime_gl_get_buffer_sub_data(target:Int, offset:DataPointer, size:Int, data:DataPointer):Void;

	@:cffi private static function lime_gl_get_context_attributes():Dynamic;

	@:cffi private static function lime_gl_get_error():Int;

	@:cffi private static function lime_gl_get_extension(name:String):Dynamic;

	@:cffi private static function lime_gl_get_float(pname:Int):Float32;

	@:cffi private static function lime_gl_get_floatv(pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_frag_data_location(program:Int, name:String):Int;

	@:cffi private static function lime_gl_get_framebuffer_attachment_parameteri(target:Int, attachment:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_framebuffer_attachment_parameteriv(target:Int, attachment:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_integer(pname:Int):Int;

	@:cffi private static function lime_gl_get_integer64v(pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_integer64i_v(pname:Int, index:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_integerv(pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_integeri_v(pname:Int, index:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_internalformativ(target:Int, internalformat:Int, pname:Int, bufSize:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_program_binary(program:Int, binaryFormat:Int, bytes:Dynamic):Void;

	@:cffi private static function lime_gl_get_program_info_log(program:Int):Dynamic;

	@:cffi private static function lime_gl_get_programi(program:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_programiv(program:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_queryi(target:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_queryiv(target:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_query_objectui(target:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_query_objectuiv(target:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_renderbuffer_parameteri(target:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_renderbuffer_parameteriv(target:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_sampler_parameterf(target:Int, pname:Int):Float32;

	@:cffi private static function lime_gl_get_sampler_parameterfv(target:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_sampler_parameteri(target:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_sampler_parameteriv(target:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_shader_info_log(shader:Int):Dynamic;

	@:cffi private static function lime_gl_get_shaderi(shader:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_shaderiv(shader:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_shader_precision_format(shadertype:Int, precisiontype:Int):Dynamic;

	@:cffi private static function lime_gl_get_shader_source(shader:Int):Dynamic;

	@:cffi private static function lime_gl_get_string(pname:Int):Dynamic;

	@:cffi private static function lime_gl_get_stringi(pname:Int, index:Int):Dynamic;

	@:cffi private static function lime_gl_get_sync_parameteri(sync:CFFIPointer, pname:Int):Int;

	@:cffi private static function lime_gl_get_sync_parameteriv(sync:CFFIPointer, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_tex_parameterf(target:Int, pname:Int):Float32;

	@:cffi private static function lime_gl_get_tex_parameterfv(target:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_tex_parameteri(target:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_tex_parameteriv(target:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_transform_feedback_varying(program:Int, index:Int):Dynamic;

	@:cffi private static function lime_gl_get_uniformf(program:Int, location:Int):Float32;

	@:cffi private static function lime_gl_get_uniformfv(program:Int, location:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_uniformi(program:Int, location:Int):Int;

	@:cffi private static function lime_gl_get_uniformiv(program:Int, location:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_uniformui(program:Int, location:Int):Int;

	@:cffi private static function lime_gl_get_uniformuiv(program:Int, location:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_uniform_block_index(program:Int, uniformBlockName:String):Int;

	@:cffi private static function lime_gl_get_uniform_location(program:Int, name:String):Int;

	@:cffi private static function lime_gl_get_vertex_attribf(index:Int, pname:Int):Float32;

	@:cffi private static function lime_gl_get_vertex_attribfv(index:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_vertex_attribi(index:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_vertex_attribiv(index:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_vertex_attribii(index:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_vertex_attribiiv(index:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_vertex_attribiui(index:Int, pname:Int):Int;

	@:cffi private static function lime_gl_get_vertex_attribiuiv(index:Int, pname:Int, params:DataPointer):Void;

	@:cffi private static function lime_gl_get_vertex_attrib_pointerv(index:Int, pname:Int):DataPointer;

	@:cffi private static function lime_gl_hint(target:Int, mode:Int):Void;

	@:cffi private static function lime_gl_invalidate_framebuffer(target:Int, attachments:Dynamic):Void;

	@:cffi private static function lime_gl_invalidate_sub_framebuffer(target:Int, attachments:Dynamic, x:Int, y:Int, width:Int, height:Int):Void;

	@:cffi private static function lime_gl_is_buffer(buffer:Int):Bool;

	@:cffi private static function lime_gl_is_enabled(cap:Int):Bool;

	@:cffi private static function lime_gl_is_framebuffer(framebuffer:Int):Bool;

	@:cffi private static function lime_gl_is_program(program:Int):Bool;

	@:cffi private static function lime_gl_is_query(query:Int):Bool;

	@:cffi private static function lime_gl_is_renderbuffer(renderbuffer:Int):Bool;

	@:cffi private static function lime_gl_is_sampler(sampler:Int):Bool;

	@:cffi private static function lime_gl_is_shader(shader:Int):Bool;

	@:cffi private static function lime_gl_is_sync(sync:CFFIPointer):Bool;

	@:cffi private static function lime_gl_is_texture(texture:Int):Bool;

	@:cffi private static function lime_gl_is_transform_feedback(transformFeedback:Int):Bool;

	@:cffi private static function lime_gl_is_vertex_array(vertexArray:Int):Bool;

	@:cffi private static function lime_gl_line_width(width:Float32):Void;

	@:cffi private static function lime_gl_link_program(program:Int):Void;

	@:cffi private static function lime_gl_map_buffer_range(target:Int, offset:DataPointer, length:Int, access:Int):DataPointer;

	@:cffi private static function lime_gl_object_deregister(object:Dynamic):Void;

	@:cffi private static function lime_gl_object_from_id(id:Int, type:Int):Dynamic;

	@:cffi private static function lime_gl_object_register(id:Int, type:Int, object:Dynamic):Dynamic;

	@:cffi private static function lime_gl_pause_transform_feedback():Void;

	@:cffi private static function lime_gl_pixel_storei(pname:Int, param:Int):Void;

	@:cffi private static function lime_gl_polygon_offset(factor:Float32, units:Float32):Void;

	@:cffi private static function lime_gl_program_binary(program:Int, binaryFormat:Int, binary:DataPointer, length:Int):Void;

	@:cffi private static function lime_gl_program_parameteri(program:Int, pname:Int, value:Int):Void;

	@:cffi private static function lime_gl_read_buffer(src:Int):Void;

	@:cffi private static function lime_gl_read_pixels(x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:DataPointer):Void;

	@:cffi private static function lime_gl_release_shader_compiler():Void;

	@:cffi private static function lime_gl_renderbuffer_storage(target:Int, internalformat:Int, width:Int, height:Int):Void;

	@:cffi private static function lime_gl_renderbuffer_storage_multisample(target:Int, samples:Int, internalformat:Int, width:Int, height:Int):Void;

	@:cffi private static function lime_gl_resume_transform_feedback():Void;

	@:cffi private static function lime_gl_sample_coverage(value:Float32, invert:Bool):Void;

	@:cffi private static function lime_gl_sampler_parameterf(sampler:Int, pname:Int, param:Float32):Void;

	@:cffi private static function lime_gl_sampler_parameteri(sampler:Int, pname:Int, param:Int):Void;

	@:cffi private static function lime_gl_scissor(x:Int, y:Int, width:Int, height:Int):Void;

	@:cffi private static function lime_gl_shader_binary(shaders:Dynamic, binaryformat:Int, binary:DataPointer, length:Int):Void;

	@:cffi private static function lime_gl_shader_source(shader:Int, source:String):Void;

	@:cffi private static function lime_gl_stencil_func(func:Int, ref:Int, mask:Int):Void;

	@:cffi private static function lime_gl_stencil_func_separate(face:Int, func:Int, ref:Int, mask:Int):Void;

	@:cffi private static function lime_gl_stencil_mask(mask:Int):Void;

	@:cffi private static function lime_gl_stencil_mask_separate(face:Int, mask:Int):Void;

	@:cffi private static function lime_gl_stencil_op(fail:Int, zfail:Int, zpass:Int):Void;

	@:cffi private static function lime_gl_stencil_op_separate(face:Int, fail:Int, zfail:Int, zpass:Int):Void;

	@:cffi private static function lime_gl_tex_image_2d(target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int,
		data:DataPointer):Void;

	@:cffi private static function lime_gl_tex_image_3d(target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int,
		type:Int, data:DataPointer):Void;

	@:cffi private static function lime_gl_tex_parameterf(target:Int, pname:Int, param:Float32):Void;

	@:cffi private static function lime_gl_tex_parameteri(target:Int, pname:Int, param:Int):Void;

	@:cffi private static function lime_gl_tex_storage_2d(target:Int, level:Int, internalformat:Int, width:Int, height:Int):Void;

	@:cffi private static function lime_gl_tex_storage_3d(target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int):Void;

	@:cffi private static function lime_gl_tex_sub_image_2d(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int,
		data:DataPointer):Void;

	@:cffi private static function lime_gl_tex_sub_image_3d(target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int,
		format:Int, type:Int, data:DataPointer):Void;

	@:cffi private static function lime_gl_transform_feedback_varyings(program:Int, varyings:Dynamic, bufferMode:Int):Void;

	@:cffi private static function lime_gl_uniform1f(location:Int, v0:Float32):Void;

	@:cffi private static function lime_gl_uniform1fv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform1i(location:Int, v0:Int):Void;

	@:cffi private static function lime_gl_uniform1iv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform1ui(location:Int, v0:Int):Void;

	@:cffi private static function lime_gl_uniform1uiv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform2f(location:Int, v0:Float32, v1:Float32):Void;

	@:cffi private static function lime_gl_uniform2fv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform2i(location:Int, v0:Int, v1:Int):Void;

	@:cffi private static function lime_gl_uniform2iv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform2ui(location:Int, v0:Int, v1:Int):Void;

	@:cffi private static function lime_gl_uniform2uiv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform3f(location:Int, v0:Float32, v1:Float32, v2:Float32):Void;

	@:cffi private static function lime_gl_uniform3fv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform3i(location:Int, v0:Int, v1:Int, v2:Int):Void;

	@:cffi private static function lime_gl_uniform3iv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform3ui(location:Int, v0:Int, v1:Int, v2:Int):Void;

	@:cffi private static function lime_gl_uniform3uiv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform4f(location:Int, v0:Float32, v1:Float32, v2:Float32, v3:Float32):Void;

	@:cffi private static function lime_gl_uniform4fv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform4i(location:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void;

	@:cffi private static function lime_gl_uniform4iv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform4ui(location:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void;

	@:cffi private static function lime_gl_uniform4uiv(location:Int, count:Int, v:DataPointer):Void;

	@:cffi private static function lime_gl_uniform_block_binding(program:Int, uniformBlockIndex:Int, uniformBlockBinding:Int):Void;

	@:cffi private static function lime_gl_uniform_matrix2fv(location:Int, count:Int, transpose:Bool, value:DataPointer):Void;

	@:cffi private static function lime_gl_uniform_matrix2x3fv(location:Int, count:Int, transpose:Bool, value:DataPointer):Void;

	@:cffi private static function lime_gl_uniform_matrix2x4fv(location:Int, count:Int, transpose:Bool, value:DataPointer):Void;

	@:cffi private static function lime_gl_uniform_matrix3fv(location:Int, count:Int, transpose:Bool, value:DataPointer):Void;

	@:cffi private static function lime_gl_uniform_matrix3x2fv(location:Int, count:Int, transpose:Bool, value:DataPointer):Void;

	@:cffi private static function lime_gl_uniform_matrix3x4fv(location:Int, count:Int, transpose:Bool, value:DataPointer):Void;

	@:cffi private static function lime_gl_uniform_matrix4fv(location:Int, count:Int, transpose:Bool, value:DataPointer):Void;

	@:cffi private static function lime_gl_uniform_matrix4x2fv(location:Int, count:Int, transpose:Bool, value:DataPointer):Void;

	@:cffi private static function lime_gl_uniform_matrix4x3fv(location:Int, count:Int, transpose:Bool, value:DataPointer):Void;

	@:cffi private static function lime_gl_unmap_buffer(target:Int):Bool;

	@:cffi private static function lime_gl_use_program(program:Int):Void;

	@:cffi private static function lime_gl_validate_program(program:Int):Void;

	@:cffi private static function lime_gl_vertex_attrib1f(indx:Int, v0:Float32):Void;

	@:cffi private static function lime_gl_vertex_attrib1fv(indx:Int, values:DataPointer):Void;

	@:cffi private static function lime_gl_vertex_attrib2f(indx:Int, v0:Float32, v1:Float32):Void;

	@:cffi private static function lime_gl_vertex_attrib2fv(indx:Int, values:DataPointer):Void;

	@:cffi private static function lime_gl_vertex_attrib3f(indx:Int, v0:Float32, v1:Float32, v2:Float32):Void;

	@:cffi private static function lime_gl_vertex_attrib3fv(indx:Int, values:DataPointer):Void;

	@:cffi private static function lime_gl_vertex_attrib4f(indx:Int, v0:Float32, v1:Float32, v2:Float32, v3:Float32):Void;

	@:cffi private static function lime_gl_vertex_attrib4fv(indx:Int, values:DataPointer):Void;

	@:cffi private static function lime_gl_vertex_attribi4i(indx:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void;

	@:cffi private static function lime_gl_vertex_attribi4iv(indx:Int, values:DataPointer):Void;

	@:cffi private static function lime_gl_vertex_attribi4ui(indx:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void;

	@:cffi private static function lime_gl_vertex_attribi4uiv(indx:Int, values:DataPointer):Void;

	@:cffi private static function lime_gl_vertex_attrib_divisor(indx:Int, divisor:Int):Void;

	@:cffi private static function lime_gl_vertex_attrib_ipointer(indx:Int, size:Int, type:Int, stride:Int, offset:DataPointer):Void;

	@:cffi private static function lime_gl_vertex_attrib_pointer(indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:DataPointer):Void;

	@:cffi private static function lime_gl_viewport(x:Int, y:Int, width:Int, height:Int):Void;

	@:cffi private static function lime_gl_wait_sync(sync:CFFIPointer, flags:Int, timeoutA:Int, timeoutB:Int):Void;
	#else
	private static var lime_gl_active_texture = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_active_texture", "iv", false));
	private static var lime_gl_attach_shader = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_attach_shader", "iiv", false));
	private static var lime_gl_begin_query = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_begin_query", "iiv", false));
	private static var lime_gl_begin_transform_feedback = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_begin_transform_feedback",
		"iv", false));
	private static var lime_gl_bind_attrib_location = new cpp.Callable<Int->Int->String->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_bind_attrib_location", "iisv", false));
	private static var lime_gl_bind_buffer = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_bind_buffer", "iiv", false));
	private static var lime_gl_bind_buffer_base = new cpp.Callable<Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_bind_buffer_base", "iiiv",
		false));
	private static var lime_gl_bind_buffer_range = new cpp.Callable<Int->Int->Int->lime.utils.DataPointer->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_bind_buffer_range", "iiidiv", false));
	private static var lime_gl_bind_framebuffer = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_bind_framebuffer", "iiv", false));
	private static var lime_gl_bind_renderbuffer = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_bind_renderbuffer", "iiv",
		false));
	private static var lime_gl_bind_sampler = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_bind_sampler", "iiv", false));
	private static var lime_gl_bind_texture = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_bind_texture", "iiv", false));
	private static var lime_gl_bind_transform_feedback = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_bind_transform_feedback",
		"iiv", false));
	private static var lime_gl_bind_vertex_array = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_bind_vertex_array", "iv", false));
	private static var lime_gl_blend_color = new cpp.Callable<cpp.Float32->cpp.Float32->cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_blend_color", "ffffv", false));
	private static var lime_gl_blend_equation = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_blend_equation", "iv", false));
	private static var lime_gl_blend_equation_separate = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_blend_equation_separate",
		"iiv", false));
	private static var lime_gl_blend_func = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_blend_func", "iiv", false));
	private static var lime_gl_blend_func_separate = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_blend_func_separate", "iiiiv", false));
	private static var lime_gl_blit_framebuffer = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_blit_framebuffer", "iiiiiiiiiiv", false));
	private static var lime_gl_buffer_data = new cpp.Callable<Int->Int->lime.utils.DataPointer->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_buffer_data", "iidiv", false));
	private static var lime_gl_buffer_sub_data = new cpp.Callable<Int->Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_buffer_sub_data", "iiidv", false));
	private static var lime_gl_check_framebuffer_status = new cpp.Callable<Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_check_framebuffer_status", "ii",
		false));
	private static var lime_gl_clear = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_clear", "iv", false));
	private static var lime_gl_clear_bufferfi = new cpp.Callable<Int->Int->cpp.Float32->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_clear_bufferfi",
		"iifiv", false));
	private static var lime_gl_clear_bufferfv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_clear_bufferfv", "iidv", false));
	private static var lime_gl_clear_bufferiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_clear_bufferiv", "iidv", false));
	private static var lime_gl_clear_bufferuiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_clear_bufferuiv", "iidv", false));
	private static var lime_gl_client_wait_sync = new cpp.Callable<cpp.Object->Int->Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_client_wait_sync",
		"oiiii", false));
	private static var lime_gl_clear_color = new cpp.Callable<cpp.Float32->cpp.Float32->cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_clear_color", "ffffv", false));
	private static var lime_gl_clear_depthf = new cpp.Callable<cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_clear_depthf", "fv", false));
	private static var lime_gl_clear_stencil = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_clear_stencil", "iv", false));
	private static var lime_gl_color_mask = new cpp.Callable<Bool->Bool->Bool->Bool->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_color_mask", "bbbbv",
		false));
	private static var lime_gl_compile_shader = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_compile_shader", "iv", false));
	private static var lime_gl_compressed_tex_image_2d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_compressed_tex_image_2d", "iiiiiiidv", false));
	private static var lime_gl_compressed_tex_image_3d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_compressed_tex_image_3d", "iiiiiiiidv", false));
	private static var lime_gl_compressed_tex_sub_image_2d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_compressed_tex_sub_image_2d", "iiiiiiiidv", false));
	private static var lime_gl_compressed_tex_sub_image_3d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->Int->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_compressed_tex_sub_image_3d", "iiiiiiiiiidv", false));
	private static var lime_gl_copy_buffer_sub_data = new cpp.Callable<Int->Int->lime.utils.DataPointer->lime.utils.DataPointer->Int->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_copy_buffer_sub_data", "iiddiv", false));
	private static var lime_gl_copy_tex_image_2d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_copy_tex_image_2d", "iiiiiiiiv", false));
	private static var lime_gl_copy_tex_sub_image_2d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_copy_tex_sub_image_2d", "iiiiiiiiv", false));
	private static var lime_gl_copy_tex_sub_image_3d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_copy_tex_sub_image_3d", "iiiiiiiiiv", false));
	private static var lime_gl_create_buffer = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_gl_create_buffer", "i", false));
	private static var lime_gl_create_framebuffer = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_gl_create_framebuffer", "i", false));
	private static var lime_gl_create_program = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_gl_create_program", "i", false));
	private static var lime_gl_create_query = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_gl_create_query", "i", false));
	private static var lime_gl_create_renderbuffer = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_gl_create_renderbuffer", "i", false));
	private static var lime_gl_create_sampler = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_gl_create_sampler", "i", false));
	private static var lime_gl_create_shader = new cpp.Callable<Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_create_shader", "ii", false));
	private static var lime_gl_create_texture = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_gl_create_texture", "i", false));
	private static var lime_gl_create_transform_feedback = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_gl_create_transform_feedback", "i",
		false));
	private static var lime_gl_create_vertex_array = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_gl_create_vertex_array", "i", false));
	private static var lime_gl_cull_face = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_cull_face", "iv", false));
	private static var lime_gl_delete_buffer = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_buffer", "iv", false));
	private static var lime_gl_delete_framebuffer = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_framebuffer", "iv", false));
	private static var lime_gl_delete_program = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_program", "iv", false));
	private static var lime_gl_delete_query = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_query", "iv", false));
	private static var lime_gl_delete_renderbuffer = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_renderbuffer", "iv", false));
	private static var lime_gl_delete_sampler = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_sampler", "iv", false));
	private static var lime_gl_delete_shader = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_shader", "iv", false));
	private static var lime_gl_delete_sync = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_sync", "ov", false));
	private static var lime_gl_delete_texture = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_texture", "iv", false));
	private static var lime_gl_delete_transform_feedback = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_transform_feedback",
		"iv", false));
	private static var lime_gl_delete_vertex_array = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_delete_vertex_array", "iv", false));
	private static var lime_gl_depth_func = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_depth_func", "iv", false));
	private static var lime_gl_depth_mask = new cpp.Callable<Bool->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_depth_mask", "bv", false));
	private static var lime_gl_depth_rangef = new cpp.Callable<cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_depth_rangef", "ffv",
		false));
	private static var lime_gl_detach_shader = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_detach_shader", "iiv", false));
	private static var lime_gl_disable = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_disable", "iv", false));
	private static var lime_gl_disable_vertex_attrib_array = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_disable_vertex_attrib_array", "iv", false));
	private static var lime_gl_draw_arrays = new cpp.Callable<Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_draw_arrays", "iiiv", false));
	private static var lime_gl_draw_arrays_instanced = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_draw_arrays_instanced", "iiiiv", false));
	private static var lime_gl_draw_buffers = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_draw_buffers", "ov", false));
	private static var lime_gl_draw_elements = new cpp.Callable<Int->Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_draw_elements", "iiidv", false));
	private static var lime_gl_draw_elements_instanced = new cpp.Callable<Int->Int->Int->lime.utils.DataPointer->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_draw_elements_instanced", "iiidiv", false));
	private static var lime_gl_draw_range_elements = new cpp.Callable<Int->Int->Int->Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_draw_range_elements", "iiiiidv", false));
	private static var lime_gl_enable = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_enable", "iv", false));
	private static var lime_gl_enable_vertex_attrib_array = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_enable_vertex_attrib_array",
		"iv", false));
	private static var lime_gl_end_query = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_end_query", "iv", false));
	private static var lime_gl_end_transform_feedback = new cpp.Callable<Void->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_end_transform_feedback", "v",
		false));
	private static var lime_gl_fence_sync = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_fence_sync", "iio", false));
	private static var lime_gl_finish = new cpp.Callable<Void->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_finish", "v", false));
	private static var lime_gl_flush = new cpp.Callable<Void->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_flush", "v", false));
	private static var lime_gl_framebuffer_renderbuffer = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_framebuffer_renderbuffer", "iiiiv", false));
	private static var lime_gl_framebuffer_texture2D = new cpp.Callable<Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_framebuffer_texture2D", "iiiiiv", false));
	private static var lime_gl_framebuffer_texture_layer = new cpp.Callable<Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_framebuffer_texture_layer", "iiiiiv", false));
	private static var lime_gl_front_face = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_front_face", "iv", false));
	private static var lime_gl_generate_mipmap = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_generate_mipmap", "iv", false));
	private static var lime_gl_get_active_attrib = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_get_active_attrib", "iio",
		false));
	private static var lime_gl_get_active_uniform = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_get_active_uniform", "iio",
		false));
	private static var lime_gl_get_active_uniform_blocki = new cpp.Callable<Int->Int->Int->Int>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_active_uniform_blocki", "iiii", false));
	private static var lime_gl_get_active_uniform_blockiv = new cpp.Callable<Int->Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_active_uniform_blockiv", "iiidv", false));
	private static var lime_gl_get_active_uniform_block_name = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_active_uniform_block_name", "iio", false));
	private static var lime_gl_get_active_uniformsiv = new cpp.Callable<Int->cpp.Object->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_active_uniformsiv", "ioidv", false));
	private static var lime_gl_get_attached_shaders = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_get_attached_shaders", "io",
		false));
	private static var lime_gl_get_attrib_location = new cpp.Callable<Int->String->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_attrib_location", "isi",
		false));
	private static var lime_gl_get_boolean = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_get_boolean", "ib", false));
	private static var lime_gl_get_booleanv = new cpp.Callable<Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_get_booleanv",
		"idv", false));
	private static var lime_gl_get_buffer_parameteri = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_buffer_parameteri", "iii",
		false));
	private static var lime_gl_get_buffer_parameteri64v = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_buffer_parameteri64v", "iidv", false));
	private static var lime_gl_get_buffer_parameteriv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_buffer_parameteriv", "iidv", false));
	private static var lime_gl_get_buffer_pointerv = new cpp.Callable<Int->Int->lime.utils.DataPointer>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_buffer_pointerv", "iid", false));
	private static var lime_gl_get_buffer_sub_data = new cpp.Callable<Int->lime.utils.DataPointer->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_get_buffer_sub_data", "ididv", false));
	private static var lime_gl_get_context_attributes = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_get_context_attributes", "o",
		false));
	private static var lime_gl_get_error = new cpp.Callable<Void->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_error", "i", false));
	private static var lime_gl_get_extension = new cpp.Callable<String->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_get_extension", "so", false));
	private static var lime_gl_get_float = new cpp.Callable<Int->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_gl_get_float", "if", false));
	private static var lime_gl_get_floatv = new cpp.Callable<Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_get_floatv", "idv",
		false));
	private static var lime_gl_get_frag_data_location = new cpp.Callable<Int->String->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_frag_data_location",
		"isi", false));
	private static var lime_gl_get_framebuffer_attachment_parameteri = new cpp.Callable<Int->Int->Int->Int>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_framebuffer_attachment_parameteri", "iiii", false));
	private static var lime_gl_get_framebuffer_attachment_parameteriv = new cpp.Callable<Int->Int->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_get_framebuffer_attachment_parameteriv", "iiidv", false));
	private static var lime_gl_get_integer = new cpp.Callable<Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_integer", "ii", false));
	private static var lime_gl_get_integer64v = new cpp.Callable<Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_get_integer64v",
		"idv", false));
	private static var lime_gl_get_integer64i_v = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_integer64i_v", "iidv", false));
	private static var lime_gl_get_integerv = new cpp.Callable<Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_get_integerv",
		"idv", false));
	private static var lime_gl_get_integeri_v = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_integeri_v", "iidv", false));
	private static var lime_gl_get_internalformativ = new cpp.Callable<Int->Int->Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_internalformativ", "iiiidv", false));
	private static var lime_gl_get_program_binary = new cpp.Callable<Int->Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_program_binary", "iiov", false));
	private static var lime_gl_get_program_info_log = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_get_program_info_log", "io",
		false));
	private static var lime_gl_get_programi = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_programi", "iii", false));
	private static var lime_gl_get_programiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_programiv", "iidv", false));
	private static var lime_gl_get_queryi = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_queryi", "iii", false));
	private static var lime_gl_get_queryiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_get_queryiv",
		"iidv", false));
	private static var lime_gl_get_query_objectui = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_query_objectui", "iii", false));
	private static var lime_gl_get_query_objectuiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_query_objectuiv", "iidv", false));
	private static var lime_gl_get_renderbuffer_parameteri = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_renderbuffer_parameteri", "iii", false));
	private static var lime_gl_get_renderbuffer_parameteriv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_renderbuffer_parameteriv", "iidv", false));
	private static var lime_gl_get_sampler_parameterf = new cpp.Callable<Int->Int->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_gl_get_sampler_parameterf",
		"iif", false));
	private static var lime_gl_get_sampler_parameterfv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_sampler_parameterfv", "iidv", false));
	private static var lime_gl_get_sampler_parameteri = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_sampler_parameteri", "iii",
		false));
	private static var lime_gl_get_sampler_parameteriv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_sampler_parameteriv", "iidv", false));
	private static var lime_gl_get_shader_info_log = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_get_shader_info_log", "io",
		false));
	private static var lime_gl_get_shaderi = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_shaderi", "iii", false));
	private static var lime_gl_get_shaderiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_shaderiv", "iidv", false));
	private static var lime_gl_get_shader_precision_format = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_shader_precision_format", "iio", false));
	private static var lime_gl_get_shader_source = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_get_shader_source", "io", false));
	private static var lime_gl_get_string = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_get_string", "io", false));
	private static var lime_gl_get_stringi = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_get_stringi", "iio", false));
	private static var lime_gl_get_sync_parameteri = new cpp.Callable<cpp.Object->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_sync_parameteri", "oii",
		false));
	private static var lime_gl_get_sync_parameteriv = new cpp.Callable<cpp.Object->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_sync_parameteriv", "oidv", false));
	private static var lime_gl_get_tex_parameterf = new cpp.Callable<Int->Int->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_gl_get_tex_parameterf", "iif",
		false));
	private static var lime_gl_get_tex_parameterfv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_tex_parameterfv", "iidv", false));
	private static var lime_gl_get_tex_parameteri = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_tex_parameteri", "iii", false));
	private static var lime_gl_get_tex_parameteriv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_tex_parameteriv", "iidv", false));
	private static var lime_gl_get_transform_feedback_varying = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_transform_feedback_varying", "iio", false));
	private static var lime_gl_get_uniformf = new cpp.Callable<Int->Int->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_gl_get_uniformf", "iif", false));
	private static var lime_gl_get_uniformfv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_uniformfv", "iidv", false));
	private static var lime_gl_get_uniformi = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_uniformi", "iii", false));
	private static var lime_gl_get_uniformiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_uniformiv", "iidv", false));
	private static var lime_gl_get_uniformui = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_uniformui", "iii", false));
	private static var lime_gl_get_uniformuiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_uniformuiv", "iidv", false));
	private static var lime_gl_get_uniform_block_index = new cpp.Callable<Int->String->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_uniform_block_index",
		"isi", false));
	private static var lime_gl_get_uniform_location = new cpp.Callable<Int->String->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_uniform_location", "isi",
		false));
	private static var lime_gl_get_vertex_attribf = new cpp.Callable<Int->Int->cpp.Float32>(cpp.Prime._loadPrime("lime", "lime_gl_get_vertex_attribf", "iif",
		false));
	private static var lime_gl_get_vertex_attribfv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_vertex_attribfv", "iidv", false));
	private static var lime_gl_get_vertex_attribi = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_vertex_attribi", "iii", false));
	private static var lime_gl_get_vertex_attribiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_vertex_attribiv", "iidv", false));
	private static var lime_gl_get_vertex_attribii = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_vertex_attribii", "iii",
		false));
	private static var lime_gl_get_vertex_attribiiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_vertex_attribiiv", "iidv", false));
	private static var lime_gl_get_vertex_attribiui = new cpp.Callable<Int->Int->Int>(cpp.Prime._loadPrime("lime", "lime_gl_get_vertex_attribiui", "iii",
		false));
	private static var lime_gl_get_vertex_attribiuiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_vertex_attribiuiv", "iidv", false));
	private static var lime_gl_get_vertex_attrib_pointerv = new cpp.Callable<Int->Int->lime.utils.DataPointer>(cpp.Prime._loadPrime("lime",
		"lime_gl_get_vertex_attrib_pointerv", "iid", false));
	private static var lime_gl_hint = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_hint", "iiv", false));
	private static var lime_gl_invalidate_framebuffer = new cpp.Callable<Int->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_invalidate_framebuffer", "iov", false));
	private static var lime_gl_invalidate_sub_framebuffer = new cpp.Callable<Int->cpp.Object->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_invalidate_sub_framebuffer", "ioiiiiv", false));
	private static var lime_gl_is_buffer = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_buffer", "ib", false));
	private static var lime_gl_is_enabled = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_enabled", "ib", false));
	private static var lime_gl_is_framebuffer = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_framebuffer", "ib", false));
	private static var lime_gl_is_program = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_program", "ib", false));
	private static var lime_gl_is_query = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_query", "ib", false));
	private static var lime_gl_is_renderbuffer = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_renderbuffer", "ib", false));
	private static var lime_gl_is_sampler = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_sampler", "ib", false));
	private static var lime_gl_is_shader = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_shader", "ib", false));
	private static var lime_gl_is_sync = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_sync", "ob", false));
	private static var lime_gl_is_texture = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_texture", "ib", false));
	private static var lime_gl_is_transform_feedback = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_transform_feedback", "ib", false));
	private static var lime_gl_is_vertex_array = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_is_vertex_array", "ib", false));
	private static var lime_gl_line_width = new cpp.Callable<cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_line_width", "fv", false));
	private static var lime_gl_link_program = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_link_program", "iv", false));
	private static var lime_gl_map_buffer_range = new cpp.Callable<Int->lime.utils.DataPointer->Int->Int->lime.utils.DataPointer>(cpp.Prime._loadPrime("lime",
		"lime_gl_map_buffer_range", "idiid", false));
	private static var lime_gl_object_deregister = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_object_deregister", "ov",
		false));
	private static var lime_gl_object_from_id = new cpp.Callable<Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_object_from_id", "iio", false));
	private static var lime_gl_object_register = new cpp.Callable<Int->Int->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_gl_object_register",
		"iioo", false));
	private static var lime_gl_pause_transform_feedback = new cpp.Callable<Void->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_pause_transform_feedback",
		"v", false));
	private static var lime_gl_pixel_storei = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_pixel_storei", "iiv", false));
	private static var lime_gl_polygon_offset = new cpp.Callable<cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_polygon_offset",
		"ffv", false));
	private static var lime_gl_program_binary = new cpp.Callable<Int->Int->lime.utils.DataPointer->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_program_binary", "iidiv", false));
	private static var lime_gl_program_parameteri = new cpp.Callable<Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_program_parameteri",
		"iiiv", false));
	private static var lime_gl_read_buffer = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_read_buffer", "iv", false));
	private static var lime_gl_read_pixels = new cpp.Callable<Int->Int->Int->Int->Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_read_pixels", "iiiiiidv", false));
	private static var lime_gl_release_shader_compiler = new cpp.Callable<Void->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_release_shader_compiler", "v",
		false));
	private static var lime_gl_renderbuffer_storage = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_renderbuffer_storage", "iiiiv", false));
	private static var lime_gl_renderbuffer_storage_multisample = new cpp.Callable<Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_renderbuffer_storage_multisample", "iiiiiv", false));
	private static var lime_gl_resume_transform_feedback = new cpp.Callable<Void->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_resume_transform_feedback",
		"v", false));
	private static var lime_gl_sample_coverage = new cpp.Callable<cpp.Float32->Bool->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_sample_coverage", "fbv",
		false));
	private static var lime_gl_sampler_parameterf = new cpp.Callable<Int->Int->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_sampler_parameterf", "iifv", false));
	private static var lime_gl_sampler_parameteri = new cpp.Callable<Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_sampler_parameteri",
		"iiiv", false));
	private static var lime_gl_scissor = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_scissor", "iiiiv", false));
	private static var lime_gl_shader_binary = new cpp.Callable<cpp.Object->Int->lime.utils.DataPointer->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_shader_binary", "oidiv", false));
	private static var lime_gl_shader_source = new cpp.Callable<Int->String->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_shader_source", "isv", false));
	private static var lime_gl_stencil_func = new cpp.Callable<Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_stencil_func", "iiiv", false));
	private static var lime_gl_stencil_func_separate = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_stencil_func_separate", "iiiiv", false));
	private static var lime_gl_stencil_mask = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_stencil_mask", "iv", false));
	private static var lime_gl_stencil_mask_separate = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_stencil_mask_separate",
		"iiv", false));
	private static var lime_gl_stencil_op = new cpp.Callable<Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_stencil_op", "iiiv", false));
	private static var lime_gl_stencil_op_separate = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_stencil_op_separate", "iiiiv", false));
	private static var lime_gl_tex_image_2d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_tex_image_2d", "iiiiiiiidv", false));
	private static var lime_gl_tex_image_3d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_tex_image_3d", "iiiiiiiiidv", false));
	private static var lime_gl_tex_parameterf = new cpp.Callable<Int->Int->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_tex_parameterf",
		"iifv", false));
	private static var lime_gl_tex_parameteri = new cpp.Callable<Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_tex_parameteri", "iiiv",
		false));
	private static var lime_gl_tex_storage_2d = new cpp.Callable<Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_tex_storage_2d",
		"iiiiiv", false));
	private static var lime_gl_tex_storage_3d = new cpp.Callable<Int->Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_tex_storage_3d", "iiiiiiv", false));
	private static var lime_gl_tex_sub_image_2d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_tex_sub_image_2d", "iiiiiiiidv", false));
	private static var lime_gl_tex_sub_image_3d = new cpp.Callable<Int->Int->Int->Int->Int->Int->Int->Int->Int->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_tex_sub_image_3d", "iiiiiiiiiidv", false));
	private static var lime_gl_transform_feedback_varyings = new cpp.Callable<Int->cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_transform_feedback_varyings", "ioiv", false));
	private static var lime_gl_uniform1f = new cpp.Callable<Int->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform1f", "ifv", false));
	private static var lime_gl_uniform1fv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform1fv",
		"iidv", false));
	private static var lime_gl_uniform1i = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform1i", "iiv", false));
	private static var lime_gl_uniform1iv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform1iv",
		"iidv", false));
	private static var lime_gl_uniform1ui = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform1ui", "iiv", false));
	private static var lime_gl_uniform1uiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform1uiv",
		"iidv", false));
	private static var lime_gl_uniform2f = new cpp.Callable<Int->cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform2f", "iffv",
		false));
	private static var lime_gl_uniform2fv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform2fv",
		"iidv", false));
	private static var lime_gl_uniform2i = new cpp.Callable<Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform2i", "iiiv", false));
	private static var lime_gl_uniform2iv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform2iv",
		"iidv", false));
	private static var lime_gl_uniform2ui = new cpp.Callable<Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform2ui", "iiiv", false));
	private static var lime_gl_uniform2uiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform2uiv",
		"iidv", false));
	private static var lime_gl_uniform3f = new cpp.Callable<Int->cpp.Float32->cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform3f", "ifffv", false));
	private static var lime_gl_uniform3fv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform3fv",
		"iidv", false));
	private static var lime_gl_uniform3i = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform3i", "iiiiv", false));
	private static var lime_gl_uniform3iv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform3iv",
		"iidv", false));
	private static var lime_gl_uniform3ui = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform3ui", "iiiiv", false));
	private static var lime_gl_uniform3uiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform3uiv",
		"iidv", false));
	private static var lime_gl_uniform4f = new cpp.Callable<Int->cpp.Float32->cpp.Float32->cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform4f", "iffffv", false));
	private static var lime_gl_uniform4fv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform4fv",
		"iidv", false));
	private static var lime_gl_uniform4i = new cpp.Callable<Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform4i", "iiiiiv",
		false));
	private static var lime_gl_uniform4iv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform4iv",
		"iidv", false));
	private static var lime_gl_uniform4ui = new cpp.Callable<Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform4ui", "iiiiiv",
		false));
	private static var lime_gl_uniform4uiv = new cpp.Callable<Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform4uiv",
		"iidv", false));
	private static var lime_gl_uniform_block_binding = new cpp.Callable<Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_uniform_block_binding",
		"iiiv", false));
	private static var lime_gl_uniform_matrix2fv = new cpp.Callable<Int->Int->Bool->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform_matrix2fv", "iibdv", false));
	private static var lime_gl_uniform_matrix2x3fv = new cpp.Callable<Int->Int->Bool->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform_matrix2x3fv", "iibdv", false));
	private static var lime_gl_uniform_matrix2x4fv = new cpp.Callable<Int->Int->Bool->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform_matrix2x4fv", "iibdv", false));
	private static var lime_gl_uniform_matrix3fv = new cpp.Callable<Int->Int->Bool->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform_matrix3fv", "iibdv", false));
	private static var lime_gl_uniform_matrix3x2fv = new cpp.Callable<Int->Int->Bool->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform_matrix3x2fv", "iibdv", false));
	private static var lime_gl_uniform_matrix3x4fv = new cpp.Callable<Int->Int->Bool->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform_matrix3x4fv", "iibdv", false));
	private static var lime_gl_uniform_matrix4fv = new cpp.Callable<Int->Int->Bool->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform_matrix4fv", "iibdv", false));
	private static var lime_gl_uniform_matrix4x2fv = new cpp.Callable<Int->Int->Bool->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform_matrix4x2fv", "iibdv", false));
	private static var lime_gl_uniform_matrix4x3fv = new cpp.Callable<Int->Int->Bool->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_uniform_matrix4x3fv", "iibdv", false));
	private static var lime_gl_unmap_buffer = new cpp.Callable<Int->Bool>(cpp.Prime._loadPrime("lime", "lime_gl_unmap_buffer", "ib", false));
	private static var lime_gl_use_program = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_use_program", "iv", false));
	private static var lime_gl_validate_program = new cpp.Callable<Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_validate_program", "iv", false));
	private static var lime_gl_vertex_attrib1f = new cpp.Callable<Int->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_vertex_attrib1f", "ifv",
		false));
	private static var lime_gl_vertex_attrib1fv = new cpp.Callable<Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_vertex_attrib1fv", "idv", false));
	private static var lime_gl_vertex_attrib2f = new cpp.Callable<Int->cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_vertex_attrib2f", "iffv", false));
	private static var lime_gl_vertex_attrib2fv = new cpp.Callable<Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_vertex_attrib2fv", "idv", false));
	private static var lime_gl_vertex_attrib3f = new cpp.Callable<Int->cpp.Float32->cpp.Float32->cpp.Float32->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_vertex_attrib3f", "ifffv", false));
	private static var lime_gl_vertex_attrib3fv = new cpp.Callable<Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_vertex_attrib3fv", "idv", false));
	private static var lime_gl_vertex_attrib4f = new cpp.Callable<Int->cpp.Float32->cpp.Float32->cpp.Float32->cpp.Float32->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_vertex_attrib4f", "iffffv", false));
	private static var lime_gl_vertex_attrib4fv = new cpp.Callable<Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_vertex_attrib4fv", "idv", false));
	private static var lime_gl_vertex_attribi4i = new cpp.Callable<Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_vertex_attribi4i",
		"iiiiiv", false));
	private static var lime_gl_vertex_attribi4iv = new cpp.Callable<Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_vertex_attribi4iv", "idv", false));
	private static var lime_gl_vertex_attribi4ui = new cpp.Callable<Int->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_vertex_attribi4ui", "iiiiiv", false));
	private static var lime_gl_vertex_attribi4uiv = new cpp.Callable<Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_vertex_attribi4uiv", "idv", false));
	private static var lime_gl_vertex_attrib_divisor = new cpp.Callable<Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_vertex_attrib_divisor",
		"iiv", false));
	private static var lime_gl_vertex_attrib_ipointer = new cpp.Callable<Int->Int->Int->Int->lime.utils.DataPointer->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_gl_vertex_attrib_ipointer", "iiiidv", false));
	private static var lime_gl_vertex_attrib_pointer = new cpp.Callable<Int->Int->Int->Bool->Int->lime.utils.DataPointer->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_vertex_attrib_pointer", "iiibidv", false));
	private static var lime_gl_viewport = new cpp.Callable<Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_viewport", "iiiiv", false));
	private static var lime_gl_wait_sync = new cpp.Callable<cpp.Object->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_gl_wait_sync", "oiiiv",
		false));
	#end
	#end
	#if (neko || cppia)
	private static var lime_gl_active_texture = CFFI.load("lime", "lime_gl_active_texture", 1);
	private static var lime_gl_attach_shader = CFFI.load("lime", "lime_gl_attach_shader", 2);
	private static var lime_gl_begin_query = CFFI.load("lime", "lime_gl_begin_query", 2);
	private static var lime_gl_begin_transform_feedback = CFFI.load("lime", "lime_gl_begin_transform_feedback", 1);
	private static var lime_gl_bind_attrib_location = CFFI.load("lime", "lime_gl_bind_attrib_location", 3);
	private static var lime_gl_bind_buffer = CFFI.load("lime", "lime_gl_bind_buffer", 2);
	private static var lime_gl_bind_buffer_base = CFFI.load("lime", "lime_gl_bind_buffer_base", 3);
	private static var lime_gl_bind_buffer_range = CFFI.load("lime", "lime_gl_bind_buffer_range", 5);
	private static var lime_gl_bind_framebuffer = CFFI.load("lime", "lime_gl_bind_framebuffer", 2);
	private static var lime_gl_bind_renderbuffer = CFFI.load("lime", "lime_gl_bind_renderbuffer", 2);
	private static var lime_gl_bind_sampler = CFFI.load("lime", "lime_gl_bind_sampler", 2);
	private static var lime_gl_bind_texture = CFFI.load("lime", "lime_gl_bind_texture", 2);
	private static var lime_gl_bind_transform_feedback = CFFI.load("lime", "lime_gl_bind_transform_feedback", 2);
	private static var lime_gl_bind_vertex_array = CFFI.load("lime", "lime_gl_bind_vertex_array", 1);
	private static var lime_gl_blend_color = CFFI.load("lime", "lime_gl_blend_color", 4);
	private static var lime_gl_blend_equation = CFFI.load("lime", "lime_gl_blend_equation", 1);
	private static var lime_gl_blend_equation_separate = CFFI.load("lime", "lime_gl_blend_equation_separate", 2);
	private static var lime_gl_blend_func = CFFI.load("lime", "lime_gl_blend_func", 2);
	private static var lime_gl_blend_func_separate = CFFI.load("lime", "lime_gl_blend_func_separate", 4);
	private static var lime_gl_blit_framebuffer = CFFI.load("lime", "lime_gl_blit_framebuffer", -1);
	private static var lime_gl_buffer_data = CFFI.load("lime", "lime_gl_buffer_data", 4);
	private static var lime_gl_buffer_sub_data = CFFI.load("lime", "lime_gl_buffer_sub_data", 4);
	private static var lime_gl_check_framebuffer_status = CFFI.load("lime", "lime_gl_check_framebuffer_status", 1);
	private static var lime_gl_clear = CFFI.load("lime", "lime_gl_clear", 1);
	private static var lime_gl_clear_bufferfi = CFFI.load("lime", "lime_gl_clear_bufferfi", 4);
	private static var lime_gl_clear_bufferfv = CFFI.load("lime", "lime_gl_clear_bufferfv", 3);
	private static var lime_gl_clear_bufferiv = CFFI.load("lime", "lime_gl_clear_bufferiv", 3);
	private static var lime_gl_clear_bufferuiv = CFFI.load("lime", "lime_gl_clear_bufferuiv", 3);
	private static var lime_gl_client_wait_sync = CFFI.load("lime", "lime_gl_client_wait_sync", 4);
	private static var lime_gl_clear_color = CFFI.load("lime", "lime_gl_clear_color", 4);
	private static var lime_gl_clear_depthf = CFFI.load("lime", "lime_gl_clear_depthf", 1);
	private static var lime_gl_clear_stencil = CFFI.load("lime", "lime_gl_clear_stencil", 1);
	private static var lime_gl_color_mask = CFFI.load("lime", "lime_gl_color_mask", 4);
	private static var lime_gl_compile_shader = CFFI.load("lime", "lime_gl_compile_shader", 1);
	private static var lime_gl_compressed_tex_image_2d = CFFI.load("lime", "lime_gl_compressed_tex_image_2d", -1);
	private static var lime_gl_compressed_tex_image_3d = CFFI.load("lime", "lime_gl_compressed_tex_image_3d", -1);
	private static var lime_gl_compressed_tex_sub_image_2d = CFFI.load("lime", "lime_gl_compressed_tex_sub_image_2d", -1);
	private static var lime_gl_compressed_tex_sub_image_3d = CFFI.load("lime", "lime_gl_compressed_tex_sub_image_3d", -1);
	private static var lime_gl_copy_buffer_sub_data = CFFI.load("lime", "lime_gl_copy_buffer_sub_data", 5);
	private static var lime_gl_copy_tex_image_2d = CFFI.load("lime", "lime_gl_copy_tex_image_2d", -1);
	private static var lime_gl_copy_tex_sub_image_2d = CFFI.load("lime", "lime_gl_copy_tex_sub_image_2d", -1);
	private static var lime_gl_copy_tex_sub_image_3d = CFFI.load("lime", "lime_gl_copy_tex_sub_image_3d", -1);
	private static var lime_gl_create_buffer = CFFI.load("lime", "lime_gl_create_buffer", 0);
	private static var lime_gl_create_framebuffer = CFFI.load("lime", "lime_gl_create_framebuffer", 0);
	private static var lime_gl_create_program = CFFI.load("lime", "lime_gl_create_program", 0);
	private static var lime_gl_create_query = CFFI.load("lime", "lime_gl_create_query", 0);
	private static var lime_gl_create_renderbuffer = CFFI.load("lime", "lime_gl_create_renderbuffer", 0);
	private static var lime_gl_create_sampler = CFFI.load("lime", "lime_gl_create_sampler", 0);
	private static var lime_gl_create_shader = CFFI.load("lime", "lime_gl_create_shader", 1);
	private static var lime_gl_create_texture = CFFI.load("lime", "lime_gl_create_texture", 0);
	private static var lime_gl_create_transform_feedback = CFFI.load("lime", "lime_gl_create_transform_feedback", 0);
	private static var lime_gl_create_vertex_array = CFFI.load("lime", "lime_gl_create_vertex_array", 0);
	private static var lime_gl_cull_face = CFFI.load("lime", "lime_gl_cull_face", 1);
	private static var lime_gl_delete_buffer = CFFI.load("lime", "lime_gl_delete_buffer", 1);
	private static var lime_gl_delete_framebuffer = CFFI.load("lime", "lime_gl_delete_framebuffer", 1);
	private static var lime_gl_delete_program = CFFI.load("lime", "lime_gl_delete_program", 1);
	private static var lime_gl_delete_query = CFFI.load("lime", "lime_gl_delete_query", 1);
	private static var lime_gl_delete_renderbuffer = CFFI.load("lime", "lime_gl_delete_renderbuffer", 1);
	private static var lime_gl_delete_sampler = CFFI.load("lime", "lime_gl_delete_sampler", 1);
	private static var lime_gl_delete_shader = CFFI.load("lime", "lime_gl_delete_shader", 1);
	private static var lime_gl_delete_sync = CFFI.load("lime", "lime_gl_delete_sync", 1);
	private static var lime_gl_delete_texture = CFFI.load("lime", "lime_gl_delete_texture", 1);
	private static var lime_gl_delete_transform_feedback = CFFI.load("lime", "lime_gl_delete_transform_feedback", 1);
	private static var lime_gl_delete_vertex_array = CFFI.load("lime", "lime_gl_delete_vertex_array", 1);
	private static var lime_gl_depth_func = CFFI.load("lime", "lime_gl_depth_func", 1);
	private static var lime_gl_depth_mask = CFFI.load("lime", "lime_gl_depth_mask", 1);
	private static var lime_gl_depth_rangef = CFFI.load("lime", "lime_gl_depth_rangef", 2);
	private static var lime_gl_detach_shader = CFFI.load("lime", "lime_gl_detach_shader", 2);
	private static var lime_gl_disable = CFFI.load("lime", "lime_gl_disable", 1);
	private static var lime_gl_disable_vertex_attrib_array = CFFI.load("lime", "lime_gl_disable_vertex_attrib_array", 1);
	private static var lime_gl_draw_arrays = CFFI.load("lime", "lime_gl_draw_arrays", 3);
	private static var lime_gl_draw_arrays_instanced = CFFI.load("lime", "lime_gl_draw_arrays_instanced", 4);
	private static var lime_gl_draw_buffers = CFFI.load("lime", "lime_gl_draw_buffers", 1);
	private static var lime_gl_draw_elements = CFFI.load("lime", "lime_gl_draw_elements", 4);
	private static var lime_gl_draw_elements_instanced = CFFI.load("lime", "lime_gl_draw_elements_instanced", 5);
	private static var lime_gl_draw_range_elements = CFFI.load("lime", "lime_gl_draw_range_elements", -1);
	private static var lime_gl_enable = CFFI.load("lime", "lime_gl_enable", 1);
	private static var lime_gl_enable_vertex_attrib_array = CFFI.load("lime", "lime_gl_enable_vertex_attrib_array", 1);
	private static var lime_gl_end_query = CFFI.load("lime", "lime_gl_end_query", 1);
	private static var lime_gl_end_transform_feedback = CFFI.load("lime", "lime_gl_end_transform_feedback", 0);
	private static var lime_gl_fence_sync = CFFI.load("lime", "lime_gl_fence_sync", 2);
	private static var lime_gl_finish = CFFI.load("lime", "lime_gl_finish", 0);
	private static var lime_gl_flush = CFFI.load("lime", "lime_gl_flush", 0);
	private static var lime_gl_framebuffer_renderbuffer = CFFI.load("lime", "lime_gl_framebuffer_renderbuffer", 4);
	private static var lime_gl_framebuffer_texture2D = CFFI.load("lime", "lime_gl_framebuffer_texture2D", 5);
	private static var lime_gl_framebuffer_texture_layer = CFFI.load("lime", "lime_gl_framebuffer_texture_layer", 5);
	private static var lime_gl_front_face = CFFI.load("lime", "lime_gl_front_face", 1);
	private static var lime_gl_generate_mipmap = CFFI.load("lime", "lime_gl_generate_mipmap", 1);
	private static var lime_gl_get_active_attrib = CFFI.load("lime", "lime_gl_get_active_attrib", 2);
	private static var lime_gl_get_active_uniform = CFFI.load("lime", "lime_gl_get_active_uniform", 2);
	private static var lime_gl_get_active_uniform_blocki = CFFI.load("lime", "lime_gl_get_active_uniform_blocki", 3);
	private static var lime_gl_get_active_uniform_blockiv = CFFI.load("lime", "lime_gl_get_active_uniform_blockiv", 4);
	private static var lime_gl_get_active_uniform_block_name = CFFI.load("lime", "lime_gl_get_active_uniform_block_name", 2);
	private static var lime_gl_get_active_uniformsiv = CFFI.load("lime", "lime_gl_get_active_uniformsiv", 4);
	private static var lime_gl_get_attached_shaders = CFFI.load("lime", "lime_gl_get_attached_shaders", 1);
	private static var lime_gl_get_attrib_location = CFFI.load("lime", "lime_gl_get_attrib_location", 2);
	private static var lime_gl_get_boolean = CFFI.load("lime", "lime_gl_get_boolean", 1);
	private static var lime_gl_get_booleanv = CFFI.load("lime", "lime_gl_get_booleanv", 2);
	private static var lime_gl_get_buffer_parameteri = CFFI.load("lime", "lime_gl_get_buffer_parameteri", 2);
	private static var lime_gl_get_buffer_parameteri64v = CFFI.load("lime", "lime_gl_get_buffer_parameteri64v", 3);
	private static var lime_gl_get_buffer_parameteriv = CFFI.load("lime", "lime_gl_get_buffer_parameteriv", 3);
	private static var lime_gl_get_buffer_pointerv = CFFI.load("lime", "lime_gl_get_buffer_pointerv", 2);
	private static var lime_gl_get_buffer_sub_data = CFFI.load("lime", "lime_gl_get_buffer_sub_data", 4);
	private static var lime_gl_get_context_attributes = CFFI.load("lime", "lime_gl_get_context_attributes", 0);
	private static var lime_gl_get_error = CFFI.load("lime", "lime_gl_get_error", 0);
	private static var lime_gl_get_extension = CFFI.load("lime", "lime_gl_get_extension", 1);
	private static var lime_gl_get_float = CFFI.load("lime", "lime_gl_get_float", 1);
	private static var lime_gl_get_floatv = CFFI.load("lime", "lime_gl_get_floatv", 2);
	private static var lime_gl_get_frag_data_location = CFFI.load("lime", "lime_gl_get_frag_data_location", 2);
	private static var lime_gl_get_framebuffer_attachment_parameteri = CFFI.load("lime", "lime_gl_get_framebuffer_attachment_parameteri", 3);
	private static var lime_gl_get_framebuffer_attachment_parameteriv = CFFI.load("lime", "lime_gl_get_framebuffer_attachment_parameteriv", 4);
	private static var lime_gl_get_integer = CFFI.load("lime", "lime_gl_get_integer", 1);
	private static var lime_gl_get_integer64v = CFFI.load("lime", "lime_gl_get_integer64v", 2);
	private static var lime_gl_get_integer64i_v = CFFI.load("lime", "lime_gl_get_integer64i_v", 3);
	private static var lime_gl_get_integerv = CFFI.load("lime", "lime_gl_get_integerv", 2);
	private static var lime_gl_get_integeri_v = CFFI.load("lime", "lime_gl_get_integeri_v", 3);
	private static var lime_gl_get_internalformativ = CFFI.load("lime", "lime_gl_get_internalformativ", 5);
	private static var lime_gl_get_program_binary = CFFI.load("lime", "lime_gl_get_program_binary", 3);
	private static var lime_gl_get_program_info_log = CFFI.load("lime", "lime_gl_get_program_info_log", 1);
	private static var lime_gl_get_programi = CFFI.load("lime", "lime_gl_get_programi", 2);
	private static var lime_gl_get_programiv = CFFI.load("lime", "lime_gl_get_programiv", 3);
	private static var lime_gl_get_queryi = CFFI.load("lime", "lime_gl_get_queryi", 2);
	private static var lime_gl_get_queryiv = CFFI.load("lime", "lime_gl_get_queryiv", 3);
	private static var lime_gl_get_query_objectui = CFFI.load("lime", "lime_gl_get_query_objectui", 2);
	private static var lime_gl_get_query_objectuiv = CFFI.load("lime", "lime_gl_get_query_objectuiv", 3);
	private static var lime_gl_get_renderbuffer_parameteri = CFFI.load("lime", "lime_gl_get_renderbuffer_parameteri", 2);
	private static var lime_gl_get_renderbuffer_parameteriv = CFFI.load("lime", "lime_gl_get_renderbuffer_parameteriv", 3);
	private static var lime_gl_get_sampler_parameterf = CFFI.load("lime", "lime_gl_get_sampler_parameterf", 2);
	private static var lime_gl_get_sampler_parameterfv = CFFI.load("lime", "lime_gl_get_sampler_parameterfv", 3);
	private static var lime_gl_get_sampler_parameteri = CFFI.load("lime", "lime_gl_get_sampler_parameteri", 2);
	private static var lime_gl_get_sampler_parameteriv = CFFI.load("lime", "lime_gl_get_sampler_parameteriv", 3);
	private static var lime_gl_get_shader_info_log = CFFI.load("lime", "lime_gl_get_shader_info_log", 1);
	private static var lime_gl_get_shaderi = CFFI.load("lime", "lime_gl_get_shaderi", 2);
	private static var lime_gl_get_shaderiv = CFFI.load("lime", "lime_gl_get_shaderiv", 3);
	private static var lime_gl_get_shader_precision_format = CFFI.load("lime", "lime_gl_get_shader_precision_format", 2);
	private static var lime_gl_get_shader_source = CFFI.load("lime", "lime_gl_get_shader_source", 1);
	private static var lime_gl_get_string = CFFI.load("lime", "lime_gl_get_string", 1);
	private static var lime_gl_get_stringi = CFFI.load("lime", "lime_gl_get_stringi", 2);
	private static var lime_gl_get_sync_parameteri = CFFI.load("lime", "lime_gl_get_sync_parameteri", 2);
	private static var lime_gl_get_sync_parameteriv = CFFI.load("lime", "lime_gl_get_sync_parameteriv", 3);
	private static var lime_gl_get_tex_parameterf = CFFI.load("lime", "lime_gl_get_tex_parameterf", 2);
	private static var lime_gl_get_tex_parameterfv = CFFI.load("lime", "lime_gl_get_tex_parameterfv", 3);
	private static var lime_gl_get_tex_parameteri = CFFI.load("lime", "lime_gl_get_tex_parameteri", 2);
	private static var lime_gl_get_tex_parameteriv = CFFI.load("lime", "lime_gl_get_tex_parameteriv", 3);
	private static var lime_gl_get_transform_feedback_varying = CFFI.load("lime", "lime_gl_get_transform_feedback_varying", 2);
	private static var lime_gl_get_uniformf = CFFI.load("lime", "lime_gl_get_uniformf", 2);
	private static var lime_gl_get_uniformfv = CFFI.load("lime", "lime_gl_get_uniformfv", 3);
	private static var lime_gl_get_uniformi = CFFI.load("lime", "lime_gl_get_uniformi", 2);
	private static var lime_gl_get_uniformiv = CFFI.load("lime", "lime_gl_get_uniformiv", 3);
	private static var lime_gl_get_uniformui = CFFI.load("lime", "lime_gl_get_uniformui", 2);
	private static var lime_gl_get_uniformuiv = CFFI.load("lime", "lime_gl_get_uniformuiv", 3);
	private static var lime_gl_get_uniform_block_index = CFFI.load("lime", "lime_gl_get_uniform_block_index", 2);
	private static var lime_gl_get_uniform_location = CFFI.load("lime", "lime_gl_get_uniform_location", 2);
	private static var lime_gl_get_vertex_attribf = CFFI.load("lime", "lime_gl_get_vertex_attribf", 2);
	private static var lime_gl_get_vertex_attribfv = CFFI.load("lime", "lime_gl_get_vertex_attribfv", 3);
	private static var lime_gl_get_vertex_attribi = CFFI.load("lime", "lime_gl_get_vertex_attribi", 2);
	private static var lime_gl_get_vertex_attribiv = CFFI.load("lime", "lime_gl_get_vertex_attribiv", 3);
	private static var lime_gl_get_vertex_attribii = CFFI.load("lime", "lime_gl_get_vertex_attribii", 2);
	private static var lime_gl_get_vertex_attribiiv = CFFI.load("lime", "lime_gl_get_vertex_attribiiv", 3);
	private static var lime_gl_get_vertex_attribiui = CFFI.load("lime", "lime_gl_get_vertex_attribiui", 2);
	private static var lime_gl_get_vertex_attribiuiv = CFFI.load("lime", "lime_gl_get_vertex_attribiuiv", 3);
	private static var lime_gl_get_vertex_attrib_pointerv = CFFI.load("lime", "lime_gl_get_vertex_attrib_pointerv", 2);
	private static var lime_gl_hint = CFFI.load("lime", "lime_gl_hint", 2);
	private static var lime_gl_invalidate_framebuffer = CFFI.load("lime", "lime_gl_invalidate_framebuffer", 2);
	private static var lime_gl_invalidate_sub_framebuffer = CFFI.load("lime", "lime_gl_invalidate_sub_framebuffer", -1);
	private static var lime_gl_is_buffer = CFFI.load("lime", "lime_gl_is_buffer", 1);
	private static var lime_gl_is_enabled = CFFI.load("lime", "lime_gl_is_enabled", 1);
	private static var lime_gl_is_framebuffer = CFFI.load("lime", "lime_gl_is_framebuffer", 1);
	private static var lime_gl_is_program = CFFI.load("lime", "lime_gl_is_program", 1);
	private static var lime_gl_is_query = CFFI.load("lime", "lime_gl_is_query", 1);
	private static var lime_gl_is_renderbuffer = CFFI.load("lime", "lime_gl_is_renderbuffer", 1);
	private static var lime_gl_is_sampler = CFFI.load("lime", "lime_gl_is_sampler", 1);
	private static var lime_gl_is_shader = CFFI.load("lime", "lime_gl_is_shader", 1);
	private static var lime_gl_is_sync = CFFI.load("lime", "lime_gl_is_sync", 1);
	private static var lime_gl_is_texture = CFFI.load("lime", "lime_gl_is_texture", 1);
	private static var lime_gl_is_transform_feedback = CFFI.load("lime", "lime_gl_is_transform_feedback", 1);
	private static var lime_gl_is_vertex_array = CFFI.load("lime", "lime_gl_is_vertex_array", 1);
	private static var lime_gl_line_width = CFFI.load("lime", "lime_gl_line_width", 1);
	private static var lime_gl_link_program = CFFI.load("lime", "lime_gl_link_program", 1);
	private static var lime_gl_map_buffer_range = CFFI.load("lime", "lime_gl_map_buffer_range", 4);
	private static var lime_gl_object_deregister:Dynamic->Void = CFFI.load("lime", "lime_gl_object_deregister", 1);
	private static var lime_gl_object_from_id = CFFI.load("lime", "lime_gl_object_from_id", 2);
	private static var lime_gl_object_register = CFFI.load("lime", "lime_gl_object_register", 3);
	private static var lime_gl_pause_transform_feedback = CFFI.load("lime", "lime_gl_pause_transform_feedback", 0);
	private static var lime_gl_pixel_storei = CFFI.load("lime", "lime_gl_pixel_storei", 2);
	private static var lime_gl_polygon_offset = CFFI.load("lime", "lime_gl_polygon_offset", 2);
	private static var lime_gl_program_binary = CFFI.load("lime", "lime_gl_program_binary", 4);
	private static var lime_gl_program_parameteri = CFFI.load("lime", "lime_gl_program_parameteri", 3);
	private static var lime_gl_read_buffer = CFFI.load("lime", "lime_gl_read_buffer", 1);
	private static var lime_gl_read_pixels = CFFI.load("lime", "lime_gl_read_pixels", -1);
	private static var lime_gl_release_shader_compiler = CFFI.load("lime", "lime_gl_release_shader_compiler", 0);
	private static var lime_gl_renderbuffer_storage = CFFI.load("lime", "lime_gl_renderbuffer_storage", 4);
	private static var lime_gl_renderbuffer_storage_multisample = CFFI.load("lime", "lime_gl_renderbuffer_storage_multisample", 5);
	private static var lime_gl_resume_transform_feedback = CFFI.load("lime", "lime_gl_resume_transform_feedback", 0);
	private static var lime_gl_sample_coverage = CFFI.load("lime", "lime_gl_sample_coverage", 2);
	private static var lime_gl_sampler_parameterf = CFFI.load("lime", "lime_gl_sampler_parameterf", 3);
	private static var lime_gl_sampler_parameteri = CFFI.load("lime", "lime_gl_sampler_parameteri", 3);
	private static var lime_gl_scissor = CFFI.load("lime", "lime_gl_scissor", 4);
	private static var lime_gl_shader_binary = CFFI.load("lime", "lime_gl_shader_binary", 4);
	private static var lime_gl_shader_source = CFFI.load("lime", "lime_gl_shader_source", 2);
	private static var lime_gl_stencil_func = CFFI.load("lime", "lime_gl_stencil_func", 3);
	private static var lime_gl_stencil_func_separate = CFFI.load("lime", "lime_gl_stencil_func_separate", 4);
	private static var lime_gl_stencil_mask = CFFI.load("lime", "lime_gl_stencil_mask", 1);
	private static var lime_gl_stencil_mask_separate = CFFI.load("lime", "lime_gl_stencil_mask_separate", 2);
	private static var lime_gl_stencil_op = CFFI.load("lime", "lime_gl_stencil_op", 3);
	private static var lime_gl_stencil_op_separate = CFFI.load("lime", "lime_gl_stencil_op_separate", 4);
	private static var lime_gl_tex_image_2d = CFFI.load("lime", "lime_gl_tex_image_2d", -1);
	private static var lime_gl_tex_image_3d = CFFI.load("lime", "lime_gl_tex_image_3d", -1);
	private static var lime_gl_tex_parameterf = CFFI.load("lime", "lime_gl_tex_parameterf", 3);
	private static var lime_gl_tex_parameteri = CFFI.load("lime", "lime_gl_tex_parameteri", 3);
	private static var lime_gl_tex_storage_2d = CFFI.load("lime", "lime_gl_tex_storage_2d", 5);
	private static var lime_gl_tex_storage_3d = CFFI.load("lime", "lime_gl_tex_storage_3d", -1);
	private static var lime_gl_tex_sub_image_2d = CFFI.load("lime", "lime_gl_tex_sub_image_2d", -1);
	private static var lime_gl_tex_sub_image_3d = CFFI.load("lime", "lime_gl_tex_sub_image_3d", -1);
	private static var lime_gl_transform_feedback_varyings = CFFI.load("lime", "lime_gl_transform_feedback_varyings", 3);
	private static var lime_gl_uniform1f = CFFI.load("lime", "lime_gl_uniform1f", 2);
	private static var lime_gl_uniform1fv = CFFI.load("lime", "lime_gl_uniform1fv", 3);
	private static var lime_gl_uniform1i = CFFI.load("lime", "lime_gl_uniform1i", 2);
	private static var lime_gl_uniform1iv = CFFI.load("lime", "lime_gl_uniform1iv", 3);
	private static var lime_gl_uniform1ui = CFFI.load("lime", "lime_gl_uniform1ui", 2);
	private static var lime_gl_uniform1uiv = CFFI.load("lime", "lime_gl_uniform1uiv", 3);
	private static var lime_gl_uniform2f = CFFI.load("lime", "lime_gl_uniform2f", 3);
	private static var lime_gl_uniform2fv = CFFI.load("lime", "lime_gl_uniform2fv", 3);
	private static var lime_gl_uniform2i = CFFI.load("lime", "lime_gl_uniform2i", 3);
	private static var lime_gl_uniform2iv = CFFI.load("lime", "lime_gl_uniform2iv", 3);
	private static var lime_gl_uniform2ui = CFFI.load("lime", "lime_gl_uniform2ui", 3);
	private static var lime_gl_uniform2uiv = CFFI.load("lime", "lime_gl_uniform2uiv", 3);
	private static var lime_gl_uniform3f = CFFI.load("lime", "lime_gl_uniform3f", 4);
	private static var lime_gl_uniform3fv = CFFI.load("lime", "lime_gl_uniform3fv", 3);
	private static var lime_gl_uniform3i = CFFI.load("lime", "lime_gl_uniform3i", 4);
	private static var lime_gl_uniform3iv = CFFI.load("lime", "lime_gl_uniform3iv", 3);
	private static var lime_gl_uniform3ui = CFFI.load("lime", "lime_gl_uniform3ui", 4);
	private static var lime_gl_uniform3uiv = CFFI.load("lime", "lime_gl_uniform3uiv", 3);
	private static var lime_gl_uniform4f = CFFI.load("lime", "lime_gl_uniform4f", 5);
	private static var lime_gl_uniform4fv = CFFI.load("lime", "lime_gl_uniform4fv", 3);
	private static var lime_gl_uniform4i = CFFI.load("lime", "lime_gl_uniform4i", 5);
	private static var lime_gl_uniform4iv = CFFI.load("lime", "lime_gl_uniform4iv", 3);
	private static var lime_gl_uniform4ui = CFFI.load("lime", "lime_gl_uniform4ui", 5);
	private static var lime_gl_uniform4uiv = CFFI.load("lime", "lime_gl_uniform4uiv", 3);
	private static var lime_gl_uniform_block_binding = CFFI.load("lime", "lime_gl_uniform_block_binding", 3);
	private static var lime_gl_uniform_matrix2fv = CFFI.load("lime", "lime_gl_uniform_matrix2fv", 4);
	private static var lime_gl_uniform_matrix2x3fv = CFFI.load("lime", "lime_gl_uniform_matrix2x3fv", 4);
	private static var lime_gl_uniform_matrix2x4fv = CFFI.load("lime", "lime_gl_uniform_matrix2x4fv", 4);
	private static var lime_gl_uniform_matrix3fv = CFFI.load("lime", "lime_gl_uniform_matrix3fv", 4);
	private static var lime_gl_uniform_matrix3x2fv = CFFI.load("lime", "lime_gl_uniform_matrix3x2fv", 4);
	private static var lime_gl_uniform_matrix3x4fv = CFFI.load("lime", "lime_gl_uniform_matrix3x4fv", 4);
	private static var lime_gl_uniform_matrix4fv = CFFI.load("lime", "lime_gl_uniform_matrix4fv", 4);
	private static var lime_gl_uniform_matrix4x2fv = CFFI.load("lime", "lime_gl_uniform_matrix4x2fv", 4);
	private static var lime_gl_uniform_matrix4x3fv = CFFI.load("lime", "lime_gl_uniform_matrix4x3fv", 4);
	private static var lime_gl_unmap_buffer = CFFI.load("lime", "lime_gl_unmap_buffer", 1);
	private static var lime_gl_use_program = CFFI.load("lime", "lime_gl_use_program", 1);
	private static var lime_gl_validate_program = CFFI.load("lime", "lime_gl_validate_program", 1);
	private static var lime_gl_vertex_attrib1f = CFFI.load("lime", "lime_gl_vertex_attrib1f", 2);
	private static var lime_gl_vertex_attrib1fv = CFFI.load("lime", "lime_gl_vertex_attrib1fv", 2);
	private static var lime_gl_vertex_attrib2f = CFFI.load("lime", "lime_gl_vertex_attrib2f", 3);
	private static var lime_gl_vertex_attrib2fv = CFFI.load("lime", "lime_gl_vertex_attrib2fv", 2);
	private static var lime_gl_vertex_attrib3f = CFFI.load("lime", "lime_gl_vertex_attrib3f", 4);
	private static var lime_gl_vertex_attrib3fv = CFFI.load("lime", "lime_gl_vertex_attrib3fv", 2);
	private static var lime_gl_vertex_attrib4f = CFFI.load("lime", "lime_gl_vertex_attrib4f", 5);
	private static var lime_gl_vertex_attrib4fv = CFFI.load("lime", "lime_gl_vertex_attrib4fv", 2);
	private static var lime_gl_vertex_attribi4i = CFFI.load("lime", "lime_gl_vertex_attribi4i", 5);
	private static var lime_gl_vertex_attribi4iv = CFFI.load("lime", "lime_gl_vertex_attribi4iv", 2);
	private static var lime_gl_vertex_attribi4ui = CFFI.load("lime", "lime_gl_vertex_attribi4ui", 5);
	private static var lime_gl_vertex_attribi4uiv = CFFI.load("lime", "lime_gl_vertex_attribi4uiv", 2);
	private static var lime_gl_vertex_attrib_divisor = CFFI.load("lime", "lime_gl_vertex_attrib_divisor", 2);
	private static var lime_gl_vertex_attrib_ipointer = CFFI.load("lime", "lime_gl_vertex_attrib_ipointer", 5);
	private static var lime_gl_vertex_attrib_pointer = CFFI.load("lime", "lime_gl_vertex_attrib_pointer", -1);
	private static var lime_gl_viewport = CFFI.load("lime", "lime_gl_viewport", 4);
	private static var lime_gl_wait_sync = CFFI.load("lime", "lime_gl_wait_sync", 4);
	#end

	#if hl
	@:hlNative("lime", "lime_gl_active_texture") private static function lime_gl_active_texture(texture:Int):Void {}

	@:hlNative("lime", "lime_gl_attach_shader") private static function lime_gl_attach_shader(program:Int, shader:Int):Void {}

	@:hlNative("lime", "lime_gl_begin_query") private static function lime_gl_begin_query(target:Int, query:Int):Void {}

	@:hlNative("lime", "lime_gl_begin_transform_feedback") private static function lime_gl_begin_transform_feedback(primitiveNode:Int):Void {}

	@:hlNative("lime", "lime_gl_bind_attrib_location") private static function lime_gl_bind_attrib_location(program:Int, index:Int, name:String):Void {}

	@:hlNative("lime", "lime_gl_bind_buffer") private static function lime_gl_bind_buffer(target:Int, buffer:Int):Void {}

	@:hlNative("lime", "lime_gl_bind_buffer_base") private static function lime_gl_bind_buffer_base(target:Int, index:Int, buffer:Int):Void {}

	@:hlNative("lime", "lime_gl_bind_buffer_range") private static function lime_gl_bind_buffer_range(target:Int, index:Int, buffer:Int, offset:DataPointer,
		size:Int):Void {}

	@:hlNative("lime", "lime_gl_bind_framebuffer") private static function lime_gl_bind_framebuffer(target:Int, framebuffer:Int):Void {}

	@:hlNative("lime", "lime_gl_bind_renderbuffer") private static function lime_gl_bind_renderbuffer(target:Int, renderbuffer:Int):Void {}

	@:hlNative("lime", "lime_gl_bind_sampler") private static function lime_gl_bind_sampler(target:Int, sampler:Int):Void {}

	@:hlNative("lime", "lime_gl_bind_texture") private static function lime_gl_bind_texture(target:Int, texture:Int):Void {}

	@:hlNative("lime", "lime_gl_bind_transform_feedback") private static function lime_gl_bind_transform_feedback(target:Int, transformFeedback:Int):Void {}

	@:hlNative("lime", "lime_gl_bind_vertex_array") private static function lime_gl_bind_vertex_array(vertexArray:Int):Void {}

	@:hlNative("lime", "lime_gl_blend_color") private static function lime_gl_blend_color(red:hl.F32, green:hl.F32, blue:hl.F32, alpha:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_blend_equation") private static function lime_gl_blend_equation(mode:Int):Void {}

	@:hlNative("lime", "lime_gl_blend_equation_separate") private static function lime_gl_blend_equation_separate(modeRGB:Int, modeAlpha:Int):Void {}

	@:hlNative("lime", "lime_gl_blend_func") private static function lime_gl_blend_func(sfactor:Int, dfactor:Int):Void {}

	@:hlNative("lime", "lime_gl_blend_func_separate") private static function lime_gl_blend_func_separate(srcRGB:Int, dstRGB:Int, srcAlpha:Int,
		dstAlpha:Int):Void {}

	@:hlNative("lime", "lime_gl_blit_framebuffer") private static function lime_gl_blit_framebuffer(srcX0:Int, srcY0:Int, srcX1:Int, srcY1:Int, dstX0:Int,
		dstY0:Int, dstX1:Int, dstY1:Int, mask:Int, filter:Int):Void {}

	@:hlNative("lime", "lime_gl_buffer_data") private static function lime_gl_buffer_data(target:Int, size:Int, srcData:DataPointer, usage:Int):Void {}

	@:hlNative("lime", "lime_gl_buffer_sub_data") private static function lime_gl_buffer_sub_data(target:Int, offset:Int, size:Int,
		srcData:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_check_framebuffer_status") private static function lime_gl_check_framebuffer_status(target:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_clear") private static function lime_gl_clear(mask:Int):Void {}

	@:hlNative("lime", "lime_gl_clear_bufferfi") private static function lime_gl_clear_bufferfi(buffer:Int, drawBuffer:Int, depth:hl.F32, stencil:Int):Void {}

	@:hlNative("lime", "lime_gl_clear_bufferfv") private static function lime_gl_clear_bufferfv(buffer:Int, drawBuffer:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_clear_bufferiv") private static function lime_gl_clear_bufferiv(buffer:Int, drawBuffer:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_clear_bufferuiv") private static function lime_gl_clear_bufferuiv(buffer:Int, drawBuffer:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_client_wait_sync") private static function lime_gl_client_wait_sync(sync:CFFIPointer, flags:Int, timeoutA:Int,
			timeoutB:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_clear_color") private static function lime_gl_clear_color(red:hl.F32, green:hl.F32, blue:hl.F32, alpha:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_clear_depthf") private static function lime_gl_clear_depthf(depth:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_clear_stencil") private static function lime_gl_clear_stencil(s:Int):Void {}

	@:hlNative("lime", "lime_gl_color_mask") private static function lime_gl_color_mask(red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {}

	@:hlNative("lime", "lime_gl_compile_shader") private static function lime_gl_compile_shader(shader:Int):Void {}

	@:hlNative("lime", "lime_gl_compressed_tex_image_2d") private static function lime_gl_compressed_tex_image_2d(target:Int, level:Int, internalformat:Int,
		width:Int, height:Int, border:Int, imageSize:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_compressed_tex_image_3d") private static function lime_gl_compressed_tex_image_3d(target:Int, level:Int, internalformat:Int,
		width:Int, height:Int, depth:Int, border:Int, imageSize:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_compressed_tex_sub_image_2d") private static function lime_gl_compressed_tex_sub_image_2d(target:Int, level:Int, xoffset:Int,
		yoffset:Int, width:Int, height:Int, format:Int, imageSize:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_compressed_tex_sub_image_3d") private static function lime_gl_compressed_tex_sub_image_3d(target:Int, level:Int, xoffset:Int,
		yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, imageSize:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_copy_buffer_sub_data") private static function lime_gl_copy_buffer_sub_data(readTarget:Int, writeTarget:Int,
		readOffset:DataPointer, writeOffset:DataPointer, size:Int):Void {}

	@:hlNative("lime", "lime_gl_copy_tex_image_2d") private static function lime_gl_copy_tex_image_2d(target:Int, level:Int, internalformat:Int, x:Int, y:Int,
		width:Int, height:Int, border:Int):Void {}

	@:hlNative("lime", "lime_gl_copy_tex_sub_image_2d") private static function lime_gl_copy_tex_sub_image_2d(target:Int, level:Int, xoffset:Int, yoffset:Int,
		x:Int, y:Int, width:Int, height:Int):Void {}

	@:hlNative("lime", "lime_gl_copy_tex_sub_image_3d") private static function lime_gl_copy_tex_sub_image_3d(target:Int, level:Int, xoffset:Int, yoffset:Int,
		zoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {}

	@:hlNative("lime", "lime_gl_create_buffer") private static function lime_gl_create_buffer():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_create_framebuffer") private static function lime_gl_create_framebuffer():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_create_program") private static function lime_gl_create_program():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_create_query") private static function lime_gl_create_query():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_create_renderbuffer") private static function lime_gl_create_renderbuffer():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_create_sampler") private static function lime_gl_create_sampler():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_create_shader") private static function lime_gl_create_shader(type:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_create_texture") private static function lime_gl_create_texture():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_create_transform_feedback") private static function lime_gl_create_transform_feedback():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_create_vertex_array") private static function lime_gl_create_vertex_array():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_cull_face") private static function lime_gl_cull_face(mode:Int):Void {}

	@:hlNative("lime", "lime_gl_delete_buffer") private static function lime_gl_delete_buffer(buffer:Int):Void {}

	@:hlNative("lime", "lime_gl_delete_framebuffer") private static function lime_gl_delete_framebuffer(framebuffer:Int):Void {}

	@:hlNative("lime", "lime_gl_delete_program") private static function lime_gl_delete_program(program:Int):Void {}

	@:hlNative("lime", "lime_gl_delete_query") private static function lime_gl_delete_query(query:Int):Void {}

	@:hlNative("lime", "lime_gl_delete_renderbuffer") private static function lime_gl_delete_renderbuffer(renderbuffer:Int):Void {}

	@:hlNative("lime", "lime_gl_delete_sampler") private static function lime_gl_delete_sampler(sampler:Int):Void {}

	@:hlNative("lime", "lime_gl_delete_shader") private static function lime_gl_delete_shader(shader:Int):Void {}

	@:hlNative("lime", "lime_gl_delete_sync") private static function lime_gl_delete_sync(sync:CFFIPointer):Void {}

	@:hlNative("lime", "lime_gl_delete_texture") private static function lime_gl_delete_texture(texture:Int):Void {}

	@:hlNative("lime", "lime_gl_delete_transform_feedback") private static function lime_gl_delete_transform_feedback(transformFeedback:Int):Void {}

	@:hlNative("lime", "lime_gl_delete_vertex_array") private static function lime_gl_delete_vertex_array(vertexArray:Int):Void {}

	@:hlNative("lime", "lime_gl_depth_func") private static function lime_gl_depth_func(func:Int):Void {}

	@:hlNative("lime", "lime_gl_depth_mask") private static function lime_gl_depth_mask(flag:Bool):Void {}

	@:hlNative("lime", "lime_gl_depth_rangef") private static function lime_gl_depth_rangef(zNear:hl.F32, zFar:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_detach_shader") private static function lime_gl_detach_shader(program:Int, shader:Int):Void {}

	@:hlNative("lime", "lime_gl_disable") private static function lime_gl_disable(cap:Int):Void {}

	@:hlNative("lime", "lime_gl_disable_vertex_attrib_array") private static function lime_gl_disable_vertex_attrib_array(index:Int):Void {}

	@:hlNative("lime", "lime_gl_draw_arrays") private static function lime_gl_draw_arrays(mode:Int, first:Int, count:Int):Void {}

	@:hlNative("lime", "lime_gl_draw_arrays_instanced") private static function lime_gl_draw_arrays_instanced(mode:Int, first:Int, count:Int,
		instanceCount:Int):Void {}

	@:hlNative("lime", "lime_gl_draw_buffers") private static function lime_gl_draw_buffers(buffers:hl.NativeArray<Int>):Void {}

	@:hlNative("lime", "lime_gl_draw_elements") private static function lime_gl_draw_elements(mode:Int, count:Int, type:Int, offset:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_draw_elements_instanced") private static function lime_gl_draw_elements_instanced(mode:Int, count:Int, type:Int,
		offset:DataPointer, instanceCount:Int):Void {}

	@:hlNative("lime", "lime_gl_draw_range_elements") private static function lime_gl_draw_range_elements(mode:Int, start:Int, end:Int, count:Int, type:Int,
		offset:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_enable") private static function lime_gl_enable(cap:Int):Void {}

	@:hlNative("lime", "lime_gl_enable_vertex_attrib_array") private static function lime_gl_enable_vertex_attrib_array(index:Int):Void {}

	@:hlNative("lime", "lime_gl_end_query") private static function lime_gl_end_query(target:Int):Void {}

	@:hlNative("lime", "lime_gl_end_transform_feedback") private static function lime_gl_end_transform_feedback():Void {}

	@:hlNative("lime", "lime_gl_fence_sync") private static function lime_gl_fence_sync(condition:Int, flags:Int):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_finish") private static function lime_gl_finish():Void {}

	@:hlNative("lime", "lime_gl_flush") private static function lime_gl_flush():Void {}

	@:hlNative("lime", "lime_gl_framebuffer_renderbuffer") private static function lime_gl_framebuffer_renderbuffer(target:Int, attachment:Int,
		renderbuffertarget:Int, renderbuffer:Int):Void {}

	@:hlNative("lime", "lime_gl_framebuffer_texture2D") private static function lime_gl_framebuffer_texture2D(target:Int, attachment:Int, textarget:Int,
		texture:Int, level:Int):Void {}

	@:hlNative("lime", "lime_gl_framebuffer_texture_layer") private static function lime_gl_framebuffer_texture_layer(target:Int, attachment:Int, texture:Int,
		level:Int, layer:Int):Void {}

	@:hlNative("lime", "lime_gl_front_face") private static function lime_gl_front_face(mode:Int):Void {}

	@:hlNative("lime", "lime_gl_generate_mipmap") private static function lime_gl_generate_mipmap(target:Int):Void {}

	@:hlNative("lime", "lime_gl_get_active_attrib") private static function lime_gl_get_active_attrib(program:Int, index:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_active_uniform") private static function lime_gl_get_active_uniform(program:Int, index:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_active_uniform_blocki") private static function lime_gl_get_active_uniform_blocki(program:Int, uniformBlockIndex:Int,
			pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_active_uniform_blockiv") private static function lime_gl_get_active_uniform_blockiv(program:Int, uniformBlockIndex:Int,
		pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_active_uniform_block_name") private static function lime_gl_get_active_uniform_block_name(program:Int,
			uniformBlockIndex:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_active_uniformsiv") private static function lime_gl_get_active_uniformsiv(program:Int, uniformIndices:hl.NativeArray<Int>,
		pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_attached_shaders") private static function lime_gl_get_attached_shaders(program:Int):hl.NativeArray<Int>
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_attrib_location") private static function lime_gl_get_attrib_location(program:Int, name:String):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_boolean") private static function lime_gl_get_boolean(pname:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_get_booleanv") private static function lime_gl_get_booleanv(pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_buffer_parameteri") private static function lime_gl_get_buffer_parameteri(target:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_buffer_parameteri64v") private static function lime_gl_get_buffer_parameteri64v(target:Int, index:Int,
		params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_buffer_parameteriv") private static function lime_gl_get_buffer_parameteriv(target:Int, pname:Int,
		params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_buffer_pointerv") private static function lime_gl_get_buffer_pointerv(target:Int, pname:Int):DataPointer
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_buffer_sub_data") private static function lime_gl_get_buffer_sub_data(target:Int, offset:DataPointer, size:Int,
		data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_context_attributes") private static function lime_gl_get_context_attributes():Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_error") private static function lime_gl_get_error():Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_extension") private static function lime_gl_get_extension(name:String):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_float") private static function lime_gl_get_float(pname:Int):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_floatv") private static function lime_gl_get_floatv(pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_frag_data_location") private static function lime_gl_get_frag_data_location(program:Int, name:String):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_framebuffer_attachment_parameteri") private static function lime_gl_get_framebuffer_attachment_parameteri(target:Int,
			attachment:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_framebuffer_attachment_parameteriv") private static function lime_gl_get_framebuffer_attachment_parameteriv(target:Int,
		attachment:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_integer") private static function lime_gl_get_integer(pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_integer64v") private static function lime_gl_get_integer64v(pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_integer64i_v") private static function lime_gl_get_integer64i_v(pname:Int, index:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_integerv") private static function lime_gl_get_integerv(pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_integeri_v") private static function lime_gl_get_integeri_v(pname:Int, index:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_internalformativ") private static function lime_gl_get_internalformativ(target:Int, internalformat:Int, pname:Int,
		bufSize:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_program_binary") private static function lime_gl_get_program_binary(program:Int, binaryFormat:Int, bytes:Bytes):Void {}

	@:hlNative("lime", "lime_gl_get_program_info_log") private static function lime_gl_get_program_info_log(program:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_programi") private static function lime_gl_get_programi(program:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_programiv") private static function lime_gl_get_programiv(program:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_queryi") private static function lime_gl_get_queryi(target:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_queryiv") private static function lime_gl_get_queryiv(target:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_query_objectui") private static function lime_gl_get_query_objectui(target:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_query_objectuiv") private static function lime_gl_get_query_objectuiv(target:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_renderbuffer_parameteri") private static function lime_gl_get_renderbuffer_parameteri(target:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_renderbuffer_parameteriv") private static function lime_gl_get_renderbuffer_parameteriv(target:Int, pname:Int,
		params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_sampler_parameterf") private static function lime_gl_get_sampler_parameterf(target:Int, pname:Int):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_sampler_parameterfv") private static function lime_gl_get_sampler_parameterfv(target:Int, pname:Int,
		params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_sampler_parameteri") private static function lime_gl_get_sampler_parameteri(target:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_sampler_parameteriv") private static function lime_gl_get_sampler_parameteriv(target:Int, pname:Int,
		params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_shader_info_log") private static function lime_gl_get_shader_info_log(shader:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_shaderi") private static function lime_gl_get_shaderi(shader:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_shaderiv") private static function lime_gl_get_shaderiv(shader:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_shader_precision_format") private static function lime_gl_get_shader_precision_format(shadertype:Int,
			precisiontype:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_shader_source") private static function lime_gl_get_shader_source(shader:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_string") private static function lime_gl_get_string(pname:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_stringi") private static function lime_gl_get_stringi(pname:Int, index:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_sync_parameteri") private static function lime_gl_get_sync_parameteri(sync:CFFIPointer, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_sync_parameteriv") private static function lime_gl_get_sync_parameteriv(sync:CFFIPointer, pname:Int,
		params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_tex_parameterf") private static function lime_gl_get_tex_parameterf(target:Int, pname:Int):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_tex_parameterfv") private static function lime_gl_get_tex_parameterfv(target:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_tex_parameteri") private static function lime_gl_get_tex_parameteri(target:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_tex_parameteriv") private static function lime_gl_get_tex_parameteriv(target:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_transform_feedback_varying") private static function lime_gl_get_transform_feedback_varying(program:Int, index:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_get_uniformf") private static function lime_gl_get_uniformf(program:Int, location:Int):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_uniformfv") private static function lime_gl_get_uniformfv(program:Int, location:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_uniformi") private static function lime_gl_get_uniformi(program:Int, location:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_uniformiv") private static function lime_gl_get_uniformiv(program:Int, location:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_uniformui") private static function lime_gl_get_uniformui(program:Int, location:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_uniformuiv") private static function lime_gl_get_uniformuiv(program:Int, location:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_uniform_block_index") private static function lime_gl_get_uniform_block_index(program:Int, uniformBlockName:String):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_uniform_location") private static function lime_gl_get_uniform_location(program:Int, name:String):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_vertex_attribf") private static function lime_gl_get_vertex_attribf(index:Int, pname:Int):hl.F32
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_vertex_attribfv") private static function lime_gl_get_vertex_attribfv(index:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_vertex_attribi") private static function lime_gl_get_vertex_attribi(index:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_vertex_attribiv") private static function lime_gl_get_vertex_attribiv(index:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_vertex_attribii") private static function lime_gl_get_vertex_attribii(index:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_vertex_attribiiv") private static function lime_gl_get_vertex_attribiiv(index:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_vertex_attribiui") private static function lime_gl_get_vertex_attribiui(index:Int, pname:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_get_vertex_attribiuiv") private static function lime_gl_get_vertex_attribiuiv(index:Int, pname:Int, params:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_get_vertex_attrib_pointerv") private static function lime_gl_get_vertex_attrib_pointerv(index:Int, pname:Int):DataPointer
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_hint") private static function lime_gl_hint(target:Int, mode:Int):Void {}

	@:hlNative("lime", "lime_gl_invalidate_framebuffer") private static function lime_gl_invalidate_framebuffer(target:Int,
		attachments:hl.NativeArray<Int>):Void {}

	@:hlNative("lime", "lime_gl_invalidate_sub_framebuffer") private static function lime_gl_invalidate_sub_framebuffer(target:Int,
		attachments:hl.NativeArray<Int>, x:Int, y:Int, width:Int, height:Int):Void {}

	@:hlNative("lime", "lime_gl_is_buffer") private static function lime_gl_is_buffer(buffer:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_enabled") private static function lime_gl_is_enabled(cap:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_framebuffer") private static function lime_gl_is_framebuffer(framebuffer:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_program") private static function lime_gl_is_program(program:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_query") private static function lime_gl_is_query(query:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_renderbuffer") private static function lime_gl_is_renderbuffer(renderbuffer:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_sampler") private static function lime_gl_is_sampler(sampler:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_shader") private static function lime_gl_is_shader(shader:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_sync") private static function lime_gl_is_sync(sync:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_texture") private static function lime_gl_is_texture(texture:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_transform_feedback") private static function lime_gl_is_transform_feedback(transformFeedback:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_is_vertex_array") private static function lime_gl_is_vertex_array(vertexArray:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_line_width") private static function lime_gl_line_width(width:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_link_program") private static function lime_gl_link_program(program:Int):Void {}

	@:hlNative("lime", "lime_gl_map_buffer_range") private static function lime_gl_map_buffer_range(target:Int, offset:DataPointer, length:Int,
			access:Int):DataPointer
	{
		return 0;
	}

	@:hlNative("lime", "lime_gl_object_deregister") private static function lime_gl_object_deregister(object:GLObject):Void {}

	@:hlNative("lime", "lime_gl_object_from_id") private static function lime_gl_object_from_id(id:Int, type:Int):GLObject
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_object_register") private static function lime_gl_object_register(id:Int, type:Int, object:GLObject):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_gl_pause_transform_feedback") private static function lime_gl_pause_transform_feedback():Void {}

	@:hlNative("lime", "lime_gl_pixel_storei") private static function lime_gl_pixel_storei(pname:Int, param:Int):Void {}

	@:hlNative("lime", "lime_gl_polygon_offset") private static function lime_gl_polygon_offset(factor:hl.F32, units:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_program_binary") private static function lime_gl_program_binary(program:Int, binaryFormat:Int, binary:DataPointer,
		length:Int):Void {}

	@:hlNative("lime", "lime_gl_program_parameteri") private static function lime_gl_program_parameteri(program:Int, pname:Int, value:Int):Void {}

	@:hlNative("lime", "lime_gl_read_buffer") private static function lime_gl_read_buffer(src:Int):Void {}

	@:hlNative("lime", "lime_gl_read_pixels") private static function lime_gl_read_pixels(x:Int, y:Int, width:Int, height:Int, format:Int, type:Int,
		pixels:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_release_shader_compiler") private static function lime_gl_release_shader_compiler():Void {}

	@:hlNative("lime", "lime_gl_renderbuffer_storage") private static function lime_gl_renderbuffer_storage(target:Int, internalformat:Int, width:Int,
		height:Int):Void {}

	@:hlNative("lime", "lime_gl_renderbuffer_storage_multisample") private static function lime_gl_renderbuffer_storage_multisample(target:Int, samples:Int,
		internalformat:Int, width:Int, height:Int):Void {}

	@:hlNative("lime", "lime_gl_resume_transform_feedback") private static function lime_gl_resume_transform_feedback():Void {}

	@:hlNative("lime", "lime_gl_sample_coverage") private static function lime_gl_sample_coverage(value:hl.F32, invert:Bool):Void {}

	@:hlNative("lime", "lime_gl_sampler_parameterf") private static function lime_gl_sampler_parameterf(sampler:Int, pname:Int, param:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_sampler_parameteri") private static function lime_gl_sampler_parameteri(sampler:Int, pname:Int, param:Int):Void {}

	@:hlNative("lime", "lime_gl_scissor") private static function lime_gl_scissor(x:Int, y:Int, width:Int, height:Int):Void {}

	@:hlNative("lime", "lime_gl_shader_binary") private static function lime_gl_shader_binary(shaders:hl.NativeArray<Int>, binaryformat:Int,
		binary:DataPointer, length:Int):Void {}

	@:hlNative("lime", "lime_gl_shader_source") private static function lime_gl_shader_source(shader:Int, source:String):Void {}

	@:hlNative("lime", "lime_gl_stencil_func") private static function lime_gl_stencil_func(func:Int, ref:Int, mask:Int):Void {}

	@:hlNative("lime", "lime_gl_stencil_func_separate") private static function lime_gl_stencil_func_separate(face:Int, func:Int, ref:Int, mask:Int):Void {}

	@:hlNative("lime", "lime_gl_stencil_mask") private static function lime_gl_stencil_mask(mask:Int):Void {}

	@:hlNative("lime", "lime_gl_stencil_mask_separate") private static function lime_gl_stencil_mask_separate(face:Int, mask:Int):Void {}

	@:hlNative("lime", "lime_gl_stencil_op") private static function lime_gl_stencil_op(fail:Int, zfail:Int, zpass:Int):Void {}

	@:hlNative("lime", "lime_gl_stencil_op_separate") private static function lime_gl_stencil_op_separate(face:Int, fail:Int, zfail:Int, zpass:Int):Void {}

	@:hlNative("lime", "lime_gl_tex_image_2d") private static function lime_gl_tex_image_2d(target:Int, level:Int, internalformat:Int, width:Int, height:Int,
		border:Int, format:Int, type:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_tex_image_3d") private static function lime_gl_tex_image_3d(target:Int, level:Int, internalformat:Int, width:Int, height:Int,
		depth:Int, border:Int, format:Int, type:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_tex_parameterf") private static function lime_gl_tex_parameterf(target:Int, pname:Int, param:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_tex_parameteri") private static function lime_gl_tex_parameteri(target:Int, pname:Int, param:Int):Void {}

	@:hlNative("lime", "lime_gl_tex_storage_2d") private static function lime_gl_tex_storage_2d(target:Int, level:Int, internalformat:Int, width:Int,
		height:Int):Void {}

	@:hlNative("lime", "lime_gl_tex_storage_3d") private static function lime_gl_tex_storage_3d(target:Int, level:Int, internalformat:Int, width:Int,
		height:Int, depth:Int):Void {}

	@:hlNative("lime", "lime_gl_tex_sub_image_2d") private static function lime_gl_tex_sub_image_2d(target:Int, level:Int, xoffset:Int, yoffset:Int,
		width:Int, height:Int, format:Int, type:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_tex_sub_image_3d") private static function lime_gl_tex_sub_image_3d(target:Int, level:Int, xoffset:Int, yoffset:Int,
		zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, data:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_transform_feedback_varyings") private static function lime_gl_transform_feedback_varyings(program:Int,
		varyings:hl.NativeArray<Int>, bufferMode:Int):Void {}

	@:hlNative("lime", "lime_gl_uniform1f") private static function lime_gl_uniform1f(location:Int, v0:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_uniform1fv") private static function lime_gl_uniform1fv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform1i") private static function lime_gl_uniform1i(location:Int, v0:Int):Void {}

	@:hlNative("lime", "lime_gl_uniform1iv") private static function lime_gl_uniform1iv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform1ui") private static function lime_gl_uniform1ui(location:Int, v0:Int):Void {}

	@:hlNative("lime", "lime_gl_uniform1uiv") private static function lime_gl_uniform1uiv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform2f") private static function lime_gl_uniform2f(location:Int, v0:hl.F32, v1:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_uniform2fv") private static function lime_gl_uniform2fv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform2i") private static function lime_gl_uniform2i(location:Int, v0:Int, v1:Int):Void {}

	@:hlNative("lime", "lime_gl_uniform2iv") private static function lime_gl_uniform2iv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform2ui") private static function lime_gl_uniform2ui(location:Int, v0:Int, v1:Int):Void {}

	@:hlNative("lime", "lime_gl_uniform2uiv") private static function lime_gl_uniform2uiv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform3f") private static function lime_gl_uniform3f(location:Int, v0:hl.F32, v1:hl.F32, v2:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_uniform3fv") private static function lime_gl_uniform3fv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform3i") private static function lime_gl_uniform3i(location:Int, v0:Int, v1:Int, v2:Int):Void {}

	@:hlNative("lime", "lime_gl_uniform3iv") private static function lime_gl_uniform3iv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform3ui") private static function lime_gl_uniform3ui(location:Int, v0:Int, v1:Int, v2:Int):Void {}

	@:hlNative("lime", "lime_gl_uniform3uiv") private static function lime_gl_uniform3uiv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform4f") private static function lime_gl_uniform4f(location:Int, v0:hl.F32, v1:hl.F32, v2:hl.F32, v3:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_uniform4fv") private static function lime_gl_uniform4fv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform4i") private static function lime_gl_uniform4i(location:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void {}

	@:hlNative("lime", "lime_gl_uniform4iv") private static function lime_gl_uniform4iv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform4ui") private static function lime_gl_uniform4ui(location:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void {}

	@:hlNative("lime", "lime_gl_uniform4uiv") private static function lime_gl_uniform4uiv(location:Int, count:Int, v:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform_block_binding") private static function lime_gl_uniform_block_binding(program:Int, uniformBlockIndex:Int,
		uniformBlockBinding:Int):Void {}

	@:hlNative("lime", "lime_gl_uniform_matrix2fv") private static function lime_gl_uniform_matrix2fv(location:Int, count:Int, transpose:Bool,
		value:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform_matrix2x3fv") private static function lime_gl_uniform_matrix2x3fv(location:Int, count:Int, transpose:Bool,
		value:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform_matrix2x4fv") private static function lime_gl_uniform_matrix2x4fv(location:Int, count:Int, transpose:Bool,
		value:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform_matrix3fv") private static function lime_gl_uniform_matrix3fv(location:Int, count:Int, transpose:Bool,
		value:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform_matrix3x2fv") private static function lime_gl_uniform_matrix3x2fv(location:Int, count:Int, transpose:Bool,
		value:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform_matrix3x4fv") private static function lime_gl_uniform_matrix3x4fv(location:Int, count:Int, transpose:Bool,
		value:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform_matrix4fv") private static function lime_gl_uniform_matrix4fv(location:Int, count:Int, transpose:Bool,
		value:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform_matrix4x2fv") private static function lime_gl_uniform_matrix4x2fv(location:Int, count:Int, transpose:Bool,
		value:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_uniform_matrix4x3fv") private static function lime_gl_uniform_matrix4x3fv(location:Int, count:Int, transpose:Bool,
		value:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_unmap_buffer") private static function lime_gl_unmap_buffer(target:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_gl_use_program") private static function lime_gl_use_program(program:Int):Void {}

	@:hlNative("lime", "lime_gl_validate_program") private static function lime_gl_validate_program(program:Int):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib1f") private static function lime_gl_vertex_attrib1f(indx:Int, v0:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib1fv") private static function lime_gl_vertex_attrib1fv(indx:Int, values:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib2f") private static function lime_gl_vertex_attrib2f(indx:Int, v0:hl.F32, v1:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib2fv") private static function lime_gl_vertex_attrib2fv(indx:Int, values:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib3f") private static function lime_gl_vertex_attrib3f(indx:Int, v0:hl.F32, v1:hl.F32, v2:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib3fv") private static function lime_gl_vertex_attrib3fv(indx:Int, values:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib4f") private static function lime_gl_vertex_attrib4f(indx:Int, v0:hl.F32, v1:hl.F32, v2:hl.F32, v3:hl.F32):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib4fv") private static function lime_gl_vertex_attrib4fv(indx:Int, values:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_vertex_attribi4i") private static function lime_gl_vertex_attribi4i(indx:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void {}

	@:hlNative("lime", "lime_gl_vertex_attribi4iv") private static function lime_gl_vertex_attribi4iv(indx:Int, values:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_vertex_attribi4ui") private static function lime_gl_vertex_attribi4ui(indx:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void {}

	@:hlNative("lime", "lime_gl_vertex_attribi4uiv") private static function lime_gl_vertex_attribi4uiv(indx:Int, values:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib_divisor") private static function lime_gl_vertex_attrib_divisor(indx:Int, divisor:Int):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib_ipointer") private static function lime_gl_vertex_attrib_ipointer(indx:Int, size:Int, type:Int, stride:Int,
		offset:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_vertex_attrib_pointer") private static function lime_gl_vertex_attrib_pointer(indx:Int, size:Int, type:Int, normalized:Bool,
		stride:Int, offset:DataPointer):Void {}

	@:hlNative("lime", "lime_gl_viewport") private static function lime_gl_viewport(x:Int, y:Int, width:Int, height:Int):Void {}

	@:hlNative("lime", "lime_gl_wait_sync") private static function lime_gl_wait_sync(sync:CFFIPointer, flags:Int, timeoutA:Int, timeoutB:Int):Void {}
	#end
	#end
	#if (lime_cffi && !macro && lime_harfbuzz)
	#if (cpp && !cppia)
	#if (disable_cffi || haxe_ver < "3.4.0")
	@:cffi private static function lime_hb_blob_create(data:DataPointer, length:Int, memoryMode:Int):CFFIPointer;

	@:cffi private static function lime_hb_blob_create_sub_blob(parent:CFFIPointer, offset:Int, length:Int):CFFIPointer;

	@:cffi private static function lime_hb_blob_get_data(blob:CFFIPointer):Float;

	@:cffi private static function lime_hb_blob_get_data_writable(blob:CFFIPointer):Float;

	@:cffi private static function lime_hb_blob_get_empty():CFFIPointer;

	@:cffi private static function lime_hb_blob_get_length(blob:CFFIPointer):Int;

	@:cffi private static function lime_hb_blob_is_immutable(blob:CFFIPointer):Bool;

	@:cffi private static function lime_hb_blob_make_immutable(blob:CFFIPointer):Void;

	@:cffi private static function lime_hb_buffer_add(buffer:CFFIPointer, codepoint:Int, cluster:Int):Void;

	@:cffi private static function lime_hb_buffer_add_codepoints(buffer:CFFIPointer, text:DataPointer, textLength:Int, itemOffset:Int, itemLength:Int):Void;

	@:cffi private static function lime_hb_buffer_add_utf8(buffer:CFFIPointer, text:String, itemOffset:Int, itemLength:Int):Void;

	@:cffi private static function lime_hb_buffer_add_utf16(buffer:CFFIPointer, text:DataPointer, textLength:Int, itemOffset:Int, itemLength:Int):Void;

	@:cffi private static function lime_hb_buffer_add_utf32(buffer:CFFIPointer, text:DataPointer, textLength:Int, itemOffset:Int, itemLength:Int):Void;

	@:cffi private static function lime_hb_buffer_allocation_successful(buffer:CFFIPointer):Bool;

	@:cffi private static function lime_hb_buffer_clear_contents(buffer:CFFIPointer):Void;

	@:cffi private static function lime_hb_buffer_create():CFFIPointer;

	@:cffi private static function lime_hb_buffer_get_cluster_level(buffer:CFFIPointer):Int;

	@:cffi private static function lime_hb_buffer_get_content_type(buffer:CFFIPointer):Int;

	@:cffi private static function lime_hb_buffer_get_direction(buffer:CFFIPointer):Int;

	@:cffi private static function lime_hb_buffer_get_empty():CFFIPointer;

	@:cffi private static function lime_hb_buffer_get_flags(buffer:CFFIPointer):Int;

	@:cffi private static function lime_hb_buffer_get_glyph_infos(buffer:CFFIPointer, bytes:Bytes):Bytes;

	@:cffi private static function lime_hb_buffer_get_glyph_positions(buffer:CFFIPointer, bytes:Bytes):Bytes;

	@:cffi private static function lime_hb_buffer_get_language(buffer:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_buffer_get_length(buffer:CFFIPointer):Int;

	@:cffi private static function lime_hb_buffer_get_replacement_codepoint(buffer:CFFIPointer):Int;

	@:cffi private static function lime_hb_buffer_get_script(buffer:CFFIPointer):Int;

	@:cffi private static function lime_hb_buffer_get_segment_properties(buffer:CFFIPointer, props:CFFIPointer):Void;

	@:cffi private static function lime_hb_buffer_guess_segment_properties(buffer:CFFIPointer):Void;

	@:cffi private static function lime_hb_buffer_normalize_glyphs(buffer:CFFIPointer):Void;

	@:cffi private static function lime_hb_buffer_preallocate(buffer:CFFIPointer, size:Int):Bool;

	@:cffi private static function lime_hb_buffer_reset(buffer:CFFIPointer):Void;

	@:cffi private static function lime_hb_buffer_reverse(buffer:CFFIPointer):Void;

	@:cffi private static function lime_hb_buffer_reverse_clusters(buffer:CFFIPointer):Void;

	@:cffi private static function lime_hb_buffer_serialize_format_from_string(str:String):Int;

	@:cffi private static function lime_hb_buffer_serialize_format_to_string(format:Int):CFFIPointer;

	@:cffi private static function lime_hb_buffer_serialize_list_formats():CFFIPointer;

	@:cffi private static function lime_hb_buffer_set_cluster_level(buffer:CFFIPointer, clusterLevel:Int):Void;

	@:cffi private static function lime_hb_buffer_set_content_type(buffer:CFFIPointer, contentType:Int):Void;

	@:cffi private static function lime_hb_buffer_set_direction(buffer:CFFIPointer, direction:Int):Void;

	@:cffi private static function lime_hb_buffer_set_flags(buffer:CFFIPointer, flags:Int):Void;

	@:cffi private static function lime_hb_buffer_set_language(buffer:CFFIPointer, language:CFFIPointer):Void;

	@:cffi private static function lime_hb_buffer_set_length(buffer:CFFIPointer, length:Int):Bool;

	@:cffi private static function lime_hb_buffer_set_replacement_codepoint(buffer:CFFIPointer, replacement:Int):Void;

	@:cffi private static function lime_hb_buffer_set_script(buffer:CFFIPointer, script:Int):Void;

	@:cffi private static function lime_hb_buffer_set_segment_properties(buffer:CFFIPointer, props:CFFIPointer):Void;

	@:cffi private static function lime_hb_face_create(blob:CFFIPointer, index:Int):CFFIPointer;

	@:cffi private static function lime_hb_face_get_empty():CFFIPointer;

	@:cffi private static function lime_hb_face_get_glyph_count(face:CFFIPointer):Int;

	@:cffi private static function lime_hb_face_get_index(face:CFFIPointer):Int;

	@:cffi private static function lime_hb_face_get_upem(face:CFFIPointer):Int;

	@:cffi private static function lime_hb_face_is_immutable(face:CFFIPointer):Bool;

	@:cffi private static function lime_hb_face_make_immutable(face:CFFIPointer):Void;

	@:cffi private static function lime_hb_face_reference_blob(face:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_face_reference_table(face:CFFIPointer, tag:Int):CFFIPointer;

	@:cffi private static function lime_hb_face_set_glyph_count(face:CFFIPointer, glyphCount:Int):Void;

	@:cffi private static function lime_hb_face_set_index(face:CFFIPointer, index:Int):Void;

	@:cffi private static function lime_hb_face_set_upem(face:CFFIPointer, upem:Int):Void;

	@:cffi private static function lime_hb_feature_from_string(str:String):CFFIPointer;

	@:cffi private static function lime_hb_feature_to_string(feature:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_font_add_glyph_origin_for_direction(font:CFFIPointer, glyph:Int, direction:Int, x:Int, y:Int):Void;

	@:cffi private static function lime_hb_font_create(face:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_font_create_sub_font(parent:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_font_get_empty():CFFIPointer;

	@:cffi private static function lime_hb_font_get_face(font:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_font_get_glyph_advance_for_direction(font:CFFIPointer, glyph:Int, direction:Int):Dynamic;

	@:cffi private static function lime_hb_font_get_glyph_kerning_for_direction(font:CFFIPointer, firstGlyph:Int, secondGlyph:Int, direction:Int):Dynamic;

	@:cffi private static function lime_hb_font_get_glyph_origin_for_direction(font:CFFIPointer, glyph:Int, direction:Int):Dynamic;

	@:cffi private static function lime_hb_font_get_parent(font:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_font_get_ppem(font:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_font_get_scale(font:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_font_glyph_from_string(font:CFFIPointer, s:String):Int;

	@:cffi private static function lime_hb_font_glyph_to_string(font:CFFIPointer, codepoint:Int):CFFIPointer;

	@:cffi private static function lime_hb_font_is_immutable(font:CFFIPointer):Bool;

	@:cffi private static function lime_hb_font_make_immutable(font:CFFIPointer):Void;

	@:cffi private static function lime_hb_font_set_ppem(font:CFFIPointer, xppem:Int, yppem:Int):Void;

	@:cffi private static function lime_hb_font_set_scale(font:CFFIPointer, xScale:Int, yScale:Int):Void;

	@:cffi private static function lime_hb_font_subtract_glyph_origin_for_direction(font:CFFIPointer, glyph:Int, direction:Int, x:Int, y:Int):Void;

	@:cffi private static function lime_hb_ft_font_create(font:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_ft_font_create_referenced(font:CFFIPointer):CFFIPointer;

	@:cffi private static function lime_hb_ft_font_get_load_flags(font:CFFIPointer):Int;

	@:cffi private static function lime_hb_ft_font_set_load_flags(font:CFFIPointer, loadFlags:Int):Void;

	@:cffi private static function lime_hb_language_from_string(str:String):CFFIPointer;

	@:cffi private static function lime_hb_language_get_default():CFFIPointer;

	@:cffi private static function lime_hb_language_to_string(language:CFFIPointer):Dynamic;

	@:cffi private static function lime_hb_segment_properties_equal(a:CFFIPointer, b:CFFIPointer):Bool;

	@:cffi private static function lime_hb_segment_properties_hash(p:CFFIPointer):Int;

	@:cffi private static function lime_hb_set_add(set:CFFIPointer, codepoint:Int):Void;

	@:cffi private static function lime_hb_set_add_range(set:CFFIPointer, first:Int, last:Int):Void;

	@:cffi private static function lime_hb_set_allocation_successful(set:CFFIPointer):Bool;

	@:cffi private static function lime_hb_set_clear(set:CFFIPointer):Void;

	@:cffi private static function lime_hb_set_create():CFFIPointer;

	@:cffi private static function lime_hb_set_del(set:CFFIPointer, codepoint:Int):Void;

	@:cffi private static function lime_hb_set_del_range(set:CFFIPointer, first:Int, last:Int):Void;

	@:cffi private static function lime_hb_set_get_empty():CFFIPointer;

	@:cffi private static function lime_hb_set_get_max(set:CFFIPointer):Int;

	@:cffi private static function lime_hb_set_get_min(set:CFFIPointer):Int;

	@:cffi private static function lime_hb_set_get_population(set:CFFIPointer):Int;

	@:cffi private static function lime_hb_set_has(set:CFFIPointer, codepoint:Int):Bool;

	@:cffi private static function lime_hb_set_intersect(set:CFFIPointer, other:CFFIPointer):Void;

	@:cffi private static function lime_hb_set_invert(set:CFFIPointer):Void;

	@:cffi private static function lime_hb_set_is_empty(set:CFFIPointer):Bool;

	@:cffi private static function lime_hb_set_is_equal(set:CFFIPointer, other:CFFIPointer):Bool;

	@:cffi private static function lime_hb_set_next(set:CFFIPointer):Int;

	@:cffi private static function lime_hb_set_next_range(set:CFFIPointer):Dynamic;

	@:cffi private static function lime_hb_set_set(set:CFFIPointer, other:CFFIPointer):Void;

	@:cffi private static function lime_hb_set_subtract(set:CFFIPointer, other:CFFIPointer):Void;

	@:cffi private static function lime_hb_set_symmetric_difference(set:CFFIPointer, other:CFFIPointer):Void;

	@:cffi private static function lime_hb_set_union(set:CFFIPointer, other:CFFIPointer):Void;

	@:cffi private static function lime_hb_shape(font:CFFIPointer, buffer:CFFIPointer, features:Dynamic):Void;
	#else
	private static var lime_hb_blob_create = new cpp.Callable<lime.utils.DataPointer->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_blob_create", "diio", false));
	private static var lime_hb_blob_create_sub_blob = new cpp.Callable<cpp.Object->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_blob_create_sub_blob", "oiio", false));
	private static var lime_hb_blob_get_data = new cpp.Callable<cpp.Object->Float>(cpp.Prime._loadPrime("lime", "lime_hb_blob_get_data", "od", false));
	private static var lime_hb_blob_get_data_writable = new cpp.Callable<cpp.Object->Float>(cpp.Prime._loadPrime("lime", "lime_hb_blob_get_data_writable",
		"od", false));
	private static var lime_hb_blob_get_empty = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_blob_get_empty", "o", false));
	private static var lime_hb_blob_get_length = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_blob_get_length", "oi", false));
	private static var lime_hb_blob_is_immutable = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_hb_blob_is_immutable", "ob", false));
	private static var lime_hb_blob_make_immutable = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_blob_make_immutable", "ov",
		false));
	private static var lime_hb_buffer_add = new cpp.Callable<cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_add", "oiiv",
		false));
	private static var lime_hb_buffer_add_codepoints = new cpp.Callable<cpp.Object->lime.utils.DataPointer->Int->Int->Int->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_add_codepoints", "odiiiv", false));
	private static var lime_hb_buffer_add_utf8 = new cpp.Callable<cpp.Object->String->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_add_utf8", "osiiv", false));
	private static var lime_hb_buffer_add_utf16 = new cpp.Callable<cpp.Object->lime.utils.DataPointer->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_add_utf16", "odiiiv", false));
	private static var lime_hb_buffer_add_utf32 = new cpp.Callable<cpp.Object->lime.utils.DataPointer->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_add_utf32", "odiiiv", false));
	private static var lime_hb_buffer_allocation_successful = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_allocation_successful", "ob", false));
	private static var lime_hb_buffer_clear_contents = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_clear_contents",
		"ov", false));
	private static var lime_hb_buffer_create = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_create", "o", false));
	private static var lime_hb_buffer_get_cluster_level = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_get_cluster_level",
		"oi", false));
	private static var lime_hb_buffer_get_content_type = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_get_content_type",
		"oi", false));
	private static var lime_hb_buffer_get_direction = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_get_direction", "oi",
		false));
	private static var lime_hb_buffer_get_empty = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_get_empty", "o", false));
	private static var lime_hb_buffer_get_flags = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_get_flags", "oi", false));
	private static var lime_hb_buffer_get_glyph_infos = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_get_glyph_infos", "ooo", false));
	private static var lime_hb_buffer_get_glyph_positions = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_get_glyph_positions", "ooo", false));
	private static var lime_hb_buffer_get_language = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_get_language",
		"oo", false));
	private static var lime_hb_buffer_get_length = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_get_length", "oi", false));
	private static var lime_hb_buffer_get_replacement_codepoint = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_get_replacement_codepoint", "oi", false));
	private static var lime_hb_buffer_get_script = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_get_script", "oi", false));
	private static var lime_hb_buffer_get_segment_properties = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_get_segment_properties", "oov", false));
	private static var lime_hb_buffer_guess_segment_properties = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_guess_segment_properties", "ov", false));
	private static var lime_hb_buffer_normalize_glyphs = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_normalize_glyphs", "ov", false));
	private static var lime_hb_buffer_preallocate = new cpp.Callable<cpp.Object->Int->Bool>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_preallocate", "oib",
		false));
	private static var lime_hb_buffer_reset = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_reset", "ov", false));
	private static var lime_hb_buffer_reverse = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_reverse", "ov", false));
	private static var lime_hb_buffer_reverse_clusters = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_reverse_clusters", "ov", false));
	private static var lime_hb_buffer_serialize_format_from_string = new cpp.Callable<String->Int>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_serialize_format_from_string", "si", false));
	private static var lime_hb_buffer_serialize_format_to_string = new cpp.Callable<Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_serialize_format_to_string", "io", false));
	private static var lime_hb_buffer_serialize_list_formats = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_serialize_list_formats", "o", false));
	private static var lime_hb_buffer_set_cluster_level = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_set_cluster_level", "oiv", false));
	private static var lime_hb_buffer_set_content_type = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_set_content_type", "oiv", false));
	private static var lime_hb_buffer_set_direction = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_set_direction",
		"oiv", false));
	private static var lime_hb_buffer_set_flags = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_set_flags", "oiv",
		false));
	private static var lime_hb_buffer_set_language = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_set_language", "oov", false));
	private static var lime_hb_buffer_set_length = new cpp.Callable<cpp.Object->Int->Bool>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_set_length", "oib",
		false));
	private static var lime_hb_buffer_set_replacement_codepoint = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_set_replacement_codepoint", "oiv", false));
	private static var lime_hb_buffer_set_script = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_buffer_set_script",
		"oiv", false));
	private static var lime_hb_buffer_set_segment_properties = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_buffer_set_segment_properties", "oov", false));
	private static var lime_hb_face_create = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_face_create", "oio", false));
	private static var lime_hb_face_get_empty = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_face_get_empty", "o", false));
	private static var lime_hb_face_get_glyph_count = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_face_get_glyph_count", "oi",
		false));
	private static var lime_hb_face_get_index = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_face_get_index", "oi", false));
	private static var lime_hb_face_get_upem = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_face_get_upem", "oi", false));
	private static var lime_hb_face_is_immutable = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_hb_face_is_immutable", "ob", false));
	private static var lime_hb_face_make_immutable = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_face_make_immutable", "ov",
		false));
	private static var lime_hb_face_reference_blob = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_face_reference_blob",
		"oo", false));
	private static var lime_hb_face_reference_table = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_face_reference_table", "oio", false));
	private static var lime_hb_face_set_glyph_count = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_face_set_glyph_count",
		"oiv", false));
	private static var lime_hb_face_set_index = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_face_set_index", "oiv",
		false));
	private static var lime_hb_face_set_upem = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_face_set_upem", "oiv",
		false));
	private static var lime_hb_feature_from_string = new cpp.Callable<String->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_feature_from_string", "so",
		false));
	private static var lime_hb_feature_to_string = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_feature_to_string", "oo",
		false));
	private static var lime_hb_font_add_glyph_origin_for_direction = new cpp.Callable<cpp.Object->Int->Int->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_font_add_glyph_origin_for_direction", "oiiiiv", false));
	private static var lime_hb_font_create = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_font_create", "oo", false));
	private static var lime_hb_font_create_sub_font = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_font_create_sub_font",
		"oo", false));
	private static var lime_hb_font_get_empty = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_font_get_empty", "o", false));
	private static var lime_hb_font_get_face = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_font_get_face", "oo", false));
	private static var lime_hb_font_get_glyph_advance_for_direction = new cpp.Callable<cpp.Object->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_font_get_glyph_advance_for_direction", "oiio", false));
	private static var lime_hb_font_get_glyph_kerning_for_direction = new cpp.Callable<cpp.Object->Int->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_font_get_glyph_kerning_for_direction", "oiiio", false));
	private static var lime_hb_font_get_glyph_origin_for_direction = new cpp.Callable<cpp.Object->Int->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_font_get_glyph_origin_for_direction", "oiio", false));
	private static var lime_hb_font_get_parent = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_font_get_parent", "oo",
		false));
	private static var lime_hb_font_get_ppem = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_font_get_ppem", "oo", false));
	private static var lime_hb_font_get_scale = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_font_get_scale", "oo", false));
	private static var lime_hb_font_glyph_from_string = new cpp.Callable<cpp.Object->String->Int>(cpp.Prime._loadPrime("lime",
		"lime_hb_font_glyph_from_string", "osi", false));
	private static var lime_hb_font_glyph_to_string = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_font_glyph_to_string", "oio", false));
	private static var lime_hb_font_is_immutable = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_hb_font_is_immutable", "ob", false));
	private static var lime_hb_font_make_immutable = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_font_make_immutable", "ov",
		false));
	private static var lime_hb_font_set_ppem = new cpp.Callable<cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_font_set_ppem", "oiiv",
		false));
	private static var lime_hb_font_set_scale = new cpp.Callable<cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_font_set_scale",
		"oiiv", false));
	private static var lime_hb_font_subtract_glyph_origin_for_direction = new cpp.Callable<cpp.Object->Int->Int->Int->Int->
		cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_font_subtract_glyph_origin_for_direction", "oiiiiv", false));
	private static var lime_hb_ft_font_create = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_ft_font_create", "oo", false));
	private static var lime_hb_ft_font_create_referenced = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_hb_ft_font_create_referenced", "oo", false));
	private static var lime_hb_ft_font_get_load_flags = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_ft_font_get_load_flags", "oi",
		false));
	private static var lime_hb_ft_font_set_load_flags = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_ft_font_set_load_flags", "oiv", false));
	private static var lime_hb_language_from_string = new cpp.Callable<String->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_language_from_string", "so",
		false));
	private static var lime_hb_language_get_default = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_language_get_default", "o",
		false));
	private static var lime_hb_language_to_string = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_language_to_string", "oo",
		false));
	private static var lime_hb_segment_properties_equal = new cpp.Callable<cpp.Object->cpp.Object->Bool>(cpp.Prime._loadPrime("lime",
		"lime_hb_segment_properties_equal", "oob", false));
	private static var lime_hb_segment_properties_hash = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_segment_properties_hash",
		"oi", false));
	private static var lime_hb_set_add = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_set_add", "oiv", false));
	private static var lime_hb_set_add_range = new cpp.Callable<cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_set_add_range", "oiiv",
		false));
	private static var lime_hb_set_allocation_successful = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime",
		"lime_hb_set_allocation_successful", "ob", false));
	private static var lime_hb_set_clear = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_set_clear", "ov", false));
	private static var lime_hb_set_create = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_set_create", "o", false));
	private static var lime_hb_set_del = new cpp.Callable<cpp.Object->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_set_del", "oiv", false));
	private static var lime_hb_set_del_range = new cpp.Callable<cpp.Object->Int->Int->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_set_del_range", "oiiv",
		false));
	private static var lime_hb_set_get_empty = new cpp.Callable<Void->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_set_get_empty", "o", false));
	private static var lime_hb_set_get_max = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_set_get_max", "oi", false));
	private static var lime_hb_set_get_min = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_set_get_min", "oi", false));
	private static var lime_hb_set_get_population = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_set_get_population", "oi", false));
	private static var lime_hb_set_has = new cpp.Callable<cpp.Object->Int->Bool>(cpp.Prime._loadPrime("lime", "lime_hb_set_has", "oib", false));
	private static var lime_hb_set_intersect = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_set_intersect", "oov",
		false));
	private static var lime_hb_set_invert = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_set_invert", "ov", false));
	private static var lime_hb_set_is_empty = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_hb_set_is_empty", "ob", false));
	private static var lime_hb_set_is_equal = new cpp.Callable<cpp.Object->cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_hb_set_is_equal", "oob",
		false));
	private static var lime_hb_set_next = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_hb_set_next", "oi", false));
	private static var lime_hb_set_next_range = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_hb_set_next_range", "oo", false));
	private static var lime_hb_set_set = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_set_set", "oov", false));
	private static var lime_hb_set_subtract = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_set_subtract", "oov",
		false));
	private static var lime_hb_set_symmetric_difference = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime",
		"lime_hb_set_symmetric_difference", "oov", false));
	private static var lime_hb_set_union = new cpp.Callable<cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_set_union", "oov", false));
	private static var lime_hb_shape = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_hb_shape", "ooov",
		false));
	#end
	#end
	#if (neko || cppia)
	private static var lime_hb_blob_create:lime.utils.DataPointer->Int->Int->Dynamic = CFFI.load("lime", "lime_hb_blob_create", 3);
	private static var lime_hb_blob_create_sub_blob:Dynamic->Int->Int->Dynamic = CFFI.load("lime", "lime_hb_blob_create_sub_blob", 3);
	private static var lime_hb_blob_get_data:Dynamic->Float = CFFI.load("lime", "lime_hb_blob_get_data", 1);
	private static var lime_hb_blob_get_data_writable:Dynamic->Float = CFFI.load("lime", "lime_hb_blob_get_data_writable", 1);
	private static var lime_hb_blob_get_empty:Void->Dynamic = CFFI.load("lime", "lime_hb_blob_get_empty", 0);
	private static var lime_hb_blob_get_length:Dynamic->Int = CFFI.load("lime", "lime_hb_blob_get_length", 1);
	private static var lime_hb_blob_is_immutable:Dynamic->Bool = CFFI.load("lime", "lime_hb_blob_is_immutable", 1);
	private static var lime_hb_blob_make_immutable:Dynamic->Void = CFFI.load("lime", "lime_hb_blob_make_immutable", 1);
	private static var lime_hb_buffer_add:Dynamic->Int->Int->Void = CFFI.load("lime", "lime_hb_buffer_add", 3);
	private static var lime_hb_buffer_add_codepoints:Dynamic->lime.utils.DataPointer->Int->Int->Int->Void = CFFI.load("lime", "lime_hb_buffer_add_codepoints",
		5);
	private static var lime_hb_buffer_add_utf8:Dynamic->String->Int->Int->Void = CFFI.load("lime", "lime_hb_buffer_add_utf8", 4);
	private static var lime_hb_buffer_add_utf16:Dynamic->lime.utils.DataPointer->Int->Int->Int->Void = CFFI.load("lime", "lime_hb_buffer_add_utf16", 5);
	private static var lime_hb_buffer_add_utf32:Dynamic->lime.utils.DataPointer->Int->Int->Int->Void = CFFI.load("lime", "lime_hb_buffer_add_utf32", 5);
	private static var lime_hb_buffer_allocation_successful:Dynamic->Bool = CFFI.load("lime", "lime_hb_buffer_allocation_successful", 1);
	private static var lime_hb_buffer_clear_contents:Dynamic->Void = CFFI.load("lime", "lime_hb_buffer_clear_contents", 1);
	private static var lime_hb_buffer_create:Void->Dynamic = CFFI.load("lime", "lime_hb_buffer_create", 0);
	private static var lime_hb_buffer_get_cluster_level:Dynamic->Int = CFFI.load("lime", "lime_hb_buffer_get_cluster_level", 1);
	private static var lime_hb_buffer_get_content_type:Dynamic->Int = CFFI.load("lime", "lime_hb_buffer_get_content_type", 1);
	private static var lime_hb_buffer_get_direction:Dynamic->Int = CFFI.load("lime", "lime_hb_buffer_get_direction", 1);
	private static var lime_hb_buffer_get_empty:Void->Dynamic = CFFI.load("lime", "lime_hb_buffer_get_empty", 0);
	private static var lime_hb_buffer_get_flags:Dynamic->Int = CFFI.load("lime", "lime_hb_buffer_get_flags", 1);
	private static var lime_hb_buffer_get_glyph_infos:Dynamic->Dynamic->Dynamic = CFFI.load("lime", "lime_hb_buffer_get_glyph_infos", 2);
	private static var lime_hb_buffer_get_glyph_positions:Dynamic->Dynamic->Dynamic = CFFI.load("lime", "lime_hb_buffer_get_glyph_positions", 2);
	private static var lime_hb_buffer_get_language:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_buffer_get_language", 1);
	private static var lime_hb_buffer_get_length:Dynamic->Int = CFFI.load("lime", "lime_hb_buffer_get_length", 1);
	private static var lime_hb_buffer_get_replacement_codepoint:Dynamic->Int = CFFI.load("lime", "lime_hb_buffer_get_replacement_codepoint", 1);
	private static var lime_hb_buffer_get_script:Dynamic->Int = CFFI.load("lime", "lime_hb_buffer_get_script", 1);
	private static var lime_hb_buffer_get_segment_properties:Dynamic->Dynamic->Void = CFFI.load("lime", "lime_hb_buffer_get_segment_properties", 2);
	private static var lime_hb_buffer_guess_segment_properties:Dynamic->Void = CFFI.load("lime", "lime_hb_buffer_guess_segment_properties", 1);
	private static var lime_hb_buffer_normalize_glyphs:Dynamic->Void = CFFI.load("lime", "lime_hb_buffer_normalize_glyphs", 1);
	private static var lime_hb_buffer_preallocate:Dynamic->Int->Bool = CFFI.load("lime", "lime_hb_buffer_preallocate", 2);
	private static var lime_hb_buffer_reset:Dynamic->Void = CFFI.load("lime", "lime_hb_buffer_reset", 1);
	private static var lime_hb_buffer_reverse:Dynamic->Void = CFFI.load("lime", "lime_hb_buffer_reverse", 1);
	private static var lime_hb_buffer_reverse_clusters:Dynamic->Void = CFFI.load("lime", "lime_hb_buffer_reverse_clusters", 1);
	private static var lime_hb_buffer_serialize_format_from_string:String->Int = CFFI.load("lime", "lime_hb_buffer_serialize_format_from_string", 1);
	private static var lime_hb_buffer_serialize_format_to_string:Int->Dynamic = CFFI.load("lime", "lime_hb_buffer_serialize_format_to_string", 1);
	private static var lime_hb_buffer_serialize_list_formats:Void->Dynamic = CFFI.load("lime", "lime_hb_buffer_serialize_list_formats", 0);
	private static var lime_hb_buffer_set_cluster_level:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_buffer_set_cluster_level", 2);
	private static var lime_hb_buffer_set_content_type:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_buffer_set_content_type", 2);
	private static var lime_hb_buffer_set_direction:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_buffer_set_direction", 2);
	private static var lime_hb_buffer_set_flags:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_buffer_set_flags", 2);
	private static var lime_hb_buffer_set_language:Dynamic->Dynamic->Void = CFFI.load("lime", "lime_hb_buffer_set_language", 2);
	private static var lime_hb_buffer_set_length:Dynamic->Int->Bool = CFFI.load("lime", "lime_hb_buffer_set_length", 2);
	private static var lime_hb_buffer_set_replacement_codepoint:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_buffer_set_replacement_codepoint", 2);
	private static var lime_hb_buffer_set_script:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_buffer_set_script", 2);
	private static var lime_hb_buffer_set_segment_properties:Dynamic->Dynamic->Void = CFFI.load("lime", "lime_hb_buffer_set_segment_properties", 2);
	private static var lime_hb_face_create:Dynamic->Int->Dynamic = CFFI.load("lime", "lime_hb_face_create", 2);
	private static var lime_hb_face_get_empty:Void->Dynamic = CFFI.load("lime", "lime_hb_face_get_empty", 0);
	private static var lime_hb_face_get_glyph_count:Dynamic->Int = CFFI.load("lime", "lime_hb_face_get_glyph_count", 1);
	private static var lime_hb_face_get_index:Dynamic->Int = CFFI.load("lime", "lime_hb_face_get_index", 1);
	private static var lime_hb_face_get_upem:Dynamic->Int = CFFI.load("lime", "lime_hb_face_get_upem", 1);
	private static var lime_hb_face_is_immutable:Dynamic->Bool = CFFI.load("lime", "lime_hb_face_is_immutable", 1);
	private static var lime_hb_face_make_immutable:Dynamic->Void = CFFI.load("lime", "lime_hb_face_make_immutable", 1);
	private static var lime_hb_face_reference_blob:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_face_reference_blob", 1);
	private static var lime_hb_face_reference_table:Dynamic->Int->Dynamic = CFFI.load("lime", "lime_hb_face_reference_table", 2);
	private static var lime_hb_face_set_glyph_count:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_face_set_glyph_count", 2);
	private static var lime_hb_face_set_index:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_face_set_index", 2);
	private static var lime_hb_face_set_upem:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_face_set_upem", 2);
	private static var lime_hb_feature_from_string:String->Dynamic = CFFI.load("lime", "lime_hb_feature_from_string", 1);
	private static var lime_hb_feature_to_string:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_feature_to_string", 1);
	private static var lime_hb_font_add_glyph_origin_for_direction:Dynamic->Int->Int->Int->Int->Void = CFFI.load("lime",
		"lime_hb_font_add_glyph_origin_for_direction", 5);
	private static var lime_hb_font_create:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_font_create", 1);
	private static var lime_hb_font_create_sub_font:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_font_create_sub_font", 1);
	private static var lime_hb_font_get_empty:Void->Dynamic = CFFI.load("lime", "lime_hb_font_get_empty", 0);
	private static var lime_hb_font_get_face:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_font_get_face", 1);
	private static var lime_hb_font_get_glyph_advance_for_direction:Dynamic->Int->Int->Dynamic = CFFI.load("lime",
		"lime_hb_font_get_glyph_advance_for_direction", 3);
	private static var lime_hb_font_get_glyph_kerning_for_direction:Dynamic->Int->Int->Int->Dynamic = CFFI.load("lime",
		"lime_hb_font_get_glyph_kerning_for_direction", 4);
	private static var lime_hb_font_get_glyph_origin_for_direction:Dynamic->Int->Int->Dynamic = CFFI.load("lime",
		"lime_hb_font_get_glyph_origin_for_direction", 3);
	private static var lime_hb_font_get_parent:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_font_get_parent", 1);
	private static var lime_hb_font_get_ppem:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_font_get_ppem", 1);
	private static var lime_hb_font_get_scale:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_font_get_scale", 1);
	private static var lime_hb_font_glyph_from_string:Dynamic->String->Int = CFFI.load("lime", "lime_hb_font_glyph_from_string", 2);
	private static var lime_hb_font_glyph_to_string:Dynamic->Int->Dynamic = CFFI.load("lime", "lime_hb_font_glyph_to_string", 2);
	private static var lime_hb_font_is_immutable:Dynamic->Bool = CFFI.load("lime", "lime_hb_font_is_immutable", 1);
	private static var lime_hb_font_make_immutable:Dynamic->Void = CFFI.load("lime", "lime_hb_font_make_immutable", 1);
	private static var lime_hb_font_set_ppem:Dynamic->Int->Int->Void = CFFI.load("lime", "lime_hb_font_set_ppem", 3);
	private static var lime_hb_font_set_scale:Dynamic->Int->Int->Void = CFFI.load("lime", "lime_hb_font_set_scale", 3);
	private static var lime_hb_font_subtract_glyph_origin_for_direction:Dynamic->Int->Int->Int->Int->Void = CFFI.load("lime",
		"lime_hb_font_subtract_glyph_origin_for_direction", 5);
	private static var lime_hb_ft_font_create:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_ft_font_create", 1);
	private static var lime_hb_ft_font_create_referenced:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_ft_font_create_referenced", 1);
	private static var lime_hb_ft_font_get_load_flags:Dynamic->Int = CFFI.load("lime", "lime_hb_ft_font_get_load_flags", 1);
	private static var lime_hb_ft_font_set_load_flags:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_ft_font_set_load_flags", 2);
	private static var lime_hb_language_from_string:String->Dynamic = CFFI.load("lime", "lime_hb_language_from_string", 1);
	private static var lime_hb_language_get_default:Void->Dynamic = CFFI.load("lime", "lime_hb_language_get_default", 0);
	private static var lime_hb_language_to_string:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_language_to_string", 1);
	private static var lime_hb_segment_properties_equal:Dynamic->Dynamic->Bool = CFFI.load("lime", "lime_hb_segment_properties_equal", 2);
	private static var lime_hb_segment_properties_hash:Dynamic->Int = CFFI.load("lime", "lime_hb_segment_properties_hash", 1);
	private static var lime_hb_set_add:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_set_add", 2);
	private static var lime_hb_set_add_range:Dynamic->Int->Int->Void = CFFI.load("lime", "lime_hb_set_add_range", 3);
	private static var lime_hb_set_allocation_successful:Dynamic->Bool = CFFI.load("lime", "lime_hb_set_allocation_successful", 1);
	private static var lime_hb_set_clear:Dynamic->Void = CFFI.load("lime", "lime_hb_set_clear", 1);
	private static var lime_hb_set_create:Void->Dynamic = CFFI.load("lime", "lime_hb_set_create", 0);
	private static var lime_hb_set_del:Dynamic->Int->Void = CFFI.load("lime", "lime_hb_set_del", 2);
	private static var lime_hb_set_del_range:Dynamic->Int->Int->Void = CFFI.load("lime", "lime_hb_set_del_range", 3);
	private static var lime_hb_set_get_empty:Void->Dynamic = CFFI.load("lime", "lime_hb_set_get_empty", 0);
	private static var lime_hb_set_get_max:Dynamic->Int = CFFI.load("lime", "lime_hb_set_get_max", 1);
	private static var lime_hb_set_get_min:Dynamic->Int = CFFI.load("lime", "lime_hb_set_get_min", 1);
	private static var lime_hb_set_get_population:Dynamic->Int = CFFI.load("lime", "lime_hb_set_get_population", 1);
	private static var lime_hb_set_has:Dynamic->Int->Bool = CFFI.load("lime", "lime_hb_set_has", 2);
	private static var lime_hb_set_intersect:Dynamic->Dynamic->Void = CFFI.load("lime", "lime_hb_set_intersect", 2);
	private static var lime_hb_set_invert:Dynamic->Void = CFFI.load("lime", "lime_hb_set_invert", 1);
	private static var lime_hb_set_is_empty:Dynamic->Bool = CFFI.load("lime", "lime_hb_set_is_empty", 1);
	private static var lime_hb_set_is_equal:Dynamic->Dynamic->Bool = CFFI.load("lime", "lime_hb_set_is_equal", 2);
	private static var lime_hb_set_next:Dynamic->Int = CFFI.load("lime", "lime_hb_set_next", 1);
	private static var lime_hb_set_next_range:Dynamic->Dynamic = CFFI.load("lime", "lime_hb_set_next_range", 1);
	private static var lime_hb_set_set:Dynamic->Dynamic->Void = CFFI.load("lime", "lime_hb_set_set", 2);
	private static var lime_hb_set_subtract:Dynamic->Dynamic->Void = CFFI.load("lime", "lime_hb_set_subtract", 2);
	private static var lime_hb_set_symmetric_difference:Dynamic->Dynamic->Void = CFFI.load("lime", "lime_hb_set_symmetric_difference", 2);
	private static var lime_hb_set_union:Dynamic->Dynamic->Void = CFFI.load("lime", "lime_hb_set_union", 2);
	private static var lime_hb_shape:Dynamic->Dynamic->Dynamic->Void = CFFI.load("lime", "lime_hb_shape", 3);
	#end

	#if hl
	@:hlNative("lime", "lime_hb_blob_create") private static function lime_hb_blob_create(data:DataPointer, length:Int, memoryMode:Int):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_blob_create_sub_blob") private static function lime_hb_blob_create_sub_blob(parent:CFFIPointer, offset:Int,
			length:Int):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_blob_get_data") private static function lime_hb_blob_get_data(blob:CFFIPointer):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_blob_get_data_writable") private static function lime_hb_blob_get_data_writable(blob:CFFIPointer):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_blob_get_empty") private static function lime_hb_blob_get_empty():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_blob_get_length") private static function lime_hb_blob_get_length(blob:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_blob_is_immutable") private static function lime_hb_blob_is_immutable(blob:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_blob_make_immutable") private static function lime_hb_blob_make_immutable(blob:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_buffer_add") private static function lime_hb_buffer_add(buffer:CFFIPointer, codepoint:Int, cluster:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_add_codepoints") private static function lime_hb_buffer_add_codepoints(buffer:CFFIPointer, text:DataPointer,
		textLength:Int, itemOffset:Int, itemLength:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_add_utf8") private static function lime_hb_buffer_add_utf8(buffer:CFFIPointer, text:String, itemOffset:Int,
		itemLength:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_add_utf16") private static function lime_hb_buffer_add_utf16(buffer:CFFIPointer, text:DataPointer, textLength:Int,
		itemOffset:Int, itemLength:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_add_utf32") private static function lime_hb_buffer_add_utf32(buffer:CFFIPointer, text:DataPointer, textLength:Int,
		itemOffset:Int, itemLength:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_allocation_successful") private static function lime_hb_buffer_allocation_successful(buffer:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_buffer_clear_contents") private static function lime_hb_buffer_clear_contents(buffer:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_buffer_create") private static function lime_hb_buffer_create():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_buffer_get_cluster_level") private static function lime_hb_buffer_get_cluster_level(buffer:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_buffer_get_content_type") private static function lime_hb_buffer_get_content_type(buffer:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_buffer_get_direction") private static function lime_hb_buffer_get_direction(buffer:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_buffer_get_empty") private static function lime_hb_buffer_get_empty():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_buffer_get_flags") private static function lime_hb_buffer_get_flags(buffer:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_buffer_get_glyph_infos") private static function lime_hb_buffer_get_glyph_infos(buffer:CFFIPointer, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_buffer_get_glyph_positions") private static function lime_hb_buffer_get_glyph_positions(buffer:CFFIPointer, bytes:Bytes):Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_buffer_get_language") private static function lime_hb_buffer_get_language(buffer:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_buffer_get_length") private static function lime_hb_buffer_get_length(buffer:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_buffer_get_replacement_codepoint") private static function lime_hb_buffer_get_replacement_codepoint(buffer:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_buffer_get_script") private static function lime_hb_buffer_get_script(buffer:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_buffer_get_segment_properties") private static function lime_hb_buffer_get_segment_properties(buffer:CFFIPointer,
		props:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_buffer_guess_segment_properties") private static function lime_hb_buffer_guess_segment_properties(buffer:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_buffer_normalize_glyphs") private static function lime_hb_buffer_normalize_glyphs(buffer:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_buffer_preallocate") private static function lime_hb_buffer_preallocate(buffer:CFFIPointer, size:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_buffer_reset") private static function lime_hb_buffer_reset(buffer:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_buffer_reverse") private static function lime_hb_buffer_reverse(buffer:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_buffer_reverse_clusters") private static function lime_hb_buffer_reverse_clusters(buffer:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_buffer_serialize_format_from_string") private static function lime_hb_buffer_serialize_format_from_string(str:String):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_buffer_serialize_format_to_string") private static function lime_hb_buffer_serialize_format_to_string(format:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_buffer_serialize_list_formats") private static function lime_hb_buffer_serialize_list_formats():hl.NativeArray<hl.Bytes>
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_buffer_set_cluster_level") private static function lime_hb_buffer_set_cluster_level(buffer:CFFIPointer,
		clusterLevel:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_set_content_type") private static function lime_hb_buffer_set_content_type(buffer:CFFIPointer, contentType:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_set_direction") private static function lime_hb_buffer_set_direction(buffer:CFFIPointer, direction:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_set_flags") private static function lime_hb_buffer_set_flags(buffer:CFFIPointer, flags:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_set_language") private static function lime_hb_buffer_set_language(buffer:CFFIPointer, language:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_buffer_set_length") private static function lime_hb_buffer_set_length(buffer:CFFIPointer, length:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_buffer_set_replacement_codepoint") private static function lime_hb_buffer_set_replacement_codepoint(buffer:CFFIPointer,
		replacement:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_set_script") private static function lime_hb_buffer_set_script(buffer:CFFIPointer, script:Int):Void {}

	@:hlNative("lime", "lime_hb_buffer_set_segment_properties") private static function lime_hb_buffer_set_segment_properties(buffer:CFFIPointer,
		props:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_face_create") private static function lime_hb_face_create(blob:CFFIPointer, index:Int):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_face_get_empty") private static function lime_hb_face_get_empty():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_face_get_glyph_count") private static function lime_hb_face_get_glyph_count(face:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_face_get_index") private static function lime_hb_face_get_index(face:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_face_get_upem") private static function lime_hb_face_get_upem(face:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_face_is_immutable") private static function lime_hb_face_is_immutable(face:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_face_make_immutable") private static function lime_hb_face_make_immutable(face:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_face_reference_blob") private static function lime_hb_face_reference_blob(face:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_face_reference_table") private static function lime_hb_face_reference_table(face:CFFIPointer, tag:Int):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_face_set_glyph_count") private static function lime_hb_face_set_glyph_count(face:CFFIPointer, glyphCount:Int):Void {}

	@:hlNative("lime", "lime_hb_face_set_index") private static function lime_hb_face_set_index(face:CFFIPointer, index:Int):Void {}

	@:hlNative("lime", "lime_hb_face_set_upem") private static function lime_hb_face_set_upem(face:CFFIPointer, upem:Int):Void {}

	@:hlNative("lime", "lime_hb_feature_from_string") private static function lime_hb_feature_from_string(str:String):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_feature_to_string") private static function lime_hb_feature_to_string(feature:CFFIPointer):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_add_glyph_origin_for_direction") private static function lime_hb_font_add_glyph_origin_for_direction(font:CFFIPointer,
		glyph:Int, direction:Int, x:Int, y:Int):Void {}

	@:hlNative("lime", "lime_hb_font_create") private static function lime_hb_font_create(face:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_create_sub_font") private static function lime_hb_font_create_sub_font(parent:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_get_empty") private static function lime_hb_font_get_empty():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_get_face") private static function lime_hb_font_get_face(font:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_get_glyph_advance_for_direction") private static function lime_hb_font_get_glyph_advance_for_direction(font:CFFIPointer,
			glyph:Int, direction:Int, out:Vector2):Vector2
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_get_glyph_kerning_for_direction") private static function lime_hb_font_get_glyph_kerning_for_direction(font:CFFIPointer,
			firstGlyph:Int, secondGlyph:Int, direction:Int, out:Vector2):Vector2
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_get_glyph_origin_for_direction") private static function lime_hb_font_get_glyph_origin_for_direction(font:CFFIPointer,
			glyph:Int, direction:Int, out:Vector2):Vector2
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_get_parent") private static function lime_hb_font_get_parent(font:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_get_ppem") private static function lime_hb_font_get_ppem(font:CFFIPointer, out:Vector2):Vector2
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_get_scale") private static function lime_hb_font_get_scale(font:CFFIPointer, out:Vector2):Vector2
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_glyph_from_string") private static function lime_hb_font_glyph_from_string(font:CFFIPointer, s:String):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_font_glyph_to_string") private static function lime_hb_font_glyph_to_string(font:CFFIPointer, codepoint:Int):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_font_is_immutable") private static function lime_hb_font_is_immutable(font:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_font_make_immutable") private static function lime_hb_font_make_immutable(font:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_font_set_ppem") private static function lime_hb_font_set_ppem(font:CFFIPointer, xppem:Int, yppem:Int):Void {}

	@:hlNative("lime", "lime_hb_font_set_scale") private static function lime_hb_font_set_scale(font:CFFIPointer, xScale:Int, yScale:Int):Void {}

	@:hlNative("lime",
		"lime_hb_font_subtract_glyph_origin_for_direction") private static function lime_hb_font_subtract_glyph_origin_for_direction(font:CFFIPointer,
		glyph:Int, direction:Int, x:Int, y:Int):Void {}

	@:hlNative("lime", "lime_hb_ft_font_create") private static function lime_hb_ft_font_create(font:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_ft_font_create_referenced") private static function lime_hb_ft_font_create_referenced(font:CFFIPointer):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_ft_font_get_load_flags") private static function lime_hb_ft_font_get_load_flags(font:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_ft_font_set_load_flags") private static function lime_hb_ft_font_set_load_flags(font:CFFIPointer, loadFlags:Int):Void {}

	@:hlNative("lime", "lime_hb_language_from_string") private static function lime_hb_language_from_string(str:String):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_language_get_default") private static function lime_hb_language_get_default():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_language_to_string") private static function lime_hb_language_to_string(language:CFFIPointer):hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_segment_properties_equal") private static function lime_hb_segment_properties_equal(a:CFFIPointer, b:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_segment_properties_hash") private static function lime_hb_segment_properties_hash(p:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_set_add") private static function lime_hb_set_add(set:CFFIPointer, codepoint:Int):Void {}

	@:hlNative("lime", "lime_hb_set_add_range") private static function lime_hb_set_add_range(set:CFFIPointer, first:Int, last:Int):Void {}

	@:hlNative("lime", "lime_hb_set_allocation_successful") private static function lime_hb_set_allocation_successful(set:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_set_clear") private static function lime_hb_set_clear(set:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_set_create") private static function lime_hb_set_create():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_set_del") private static function lime_hb_set_del(set:CFFIPointer, codepoint:Int):Void {}

	@:hlNative("lime", "lime_hb_set_del_range") private static function lime_hb_set_del_range(set:CFFIPointer, first:Int, last:Int):Void {}

	@:hlNative("lime", "lime_hb_set_get_empty") private static function lime_hb_set_get_empty():CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_set_get_max") private static function lime_hb_set_get_max(set:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_set_get_min") private static function lime_hb_set_get_min(set:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_set_get_population") private static function lime_hb_set_get_population(set:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_set_has") private static function lime_hb_set_has(set:CFFIPointer, codepoint:Int):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_set_intersect") private static function lime_hb_set_intersect(set:CFFIPointer, other:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_set_invert") private static function lime_hb_set_invert(set:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_set_is_empty") private static function lime_hb_set_is_empty(set:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_set_is_equal") private static function lime_hb_set_is_equal(set:CFFIPointer, other:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_hb_set_next") private static function lime_hb_set_next(set:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_hb_set_next_range") private static function lime_hb_set_next_range(set:CFFIPointer, out:Vector2):Vector2
	{
		return null;
	}

	@:hlNative("lime", "lime_hb_set_set") private static function lime_hb_set_set(set:CFFIPointer, other:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_set_subtract") private static function lime_hb_set_subtract(set:CFFIPointer, other:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_set_symmetric_difference") private static function lime_hb_set_symmetric_difference(set:CFFIPointer, other:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_set_union") private static function lime_hb_set_union(set:CFFIPointer, other:CFFIPointer):Void {}

	@:hlNative("lime", "lime_hb_shape") private static function lime_hb_shape(font:CFFIPointer, buffer:CFFIPointer,
		features:hl.NativeArray<CFFIPointer>):Void {}
	#end
	#end
	#if (lime_cffi && !macro && lime_vorbis)
	#if (cpp && !cppia)
	#if (disable_cffi || haxe_ver < "3.4.0")
	@:cffi private static function lime_vorbis_file_bitrate(vorbisFile:Dynamic, bitstream:Int):Int;

	@:cffi private static function lime_vorbis_file_bitrate_instant(vorbisFile:Dynamic):Int;

	@:cffi private static function lime_vorbis_file_clear(vorbisFile:Dynamic):Void;

	@:cffi private static function lime_vorbis_file_comment(vorbisFile:Dynamic, bitstream:Int):Dynamic;

	@:cffi private static function lime_vorbis_file_crosslap(vorbisFile:Dynamic, otherVorbisFile:Dynamic):Dynamic;

	@:cffi private static function lime_vorbis_file_from_bytes(bytes:Dynamic):Dynamic;

	@:cffi private static function lime_vorbis_file_from_file(path:String):Dynamic;

	@:cffi private static function lime_vorbis_file_info(vorbisFile:Dynamic, bitstream:Int):Dynamic;

	@:cffi private static function lime_vorbis_file_pcm_seek(vorbisFile:Dynamic, posLow:Dynamic, posHigh:Dynamic):Int;

	@:cffi private static function lime_vorbis_file_pcm_seek_lap(vorbisFile:Dynamic, posLow:Dynamic, posHigh:Dynamic):Int;

	@:cffi private static function lime_vorbis_file_pcm_seek_page(vorbisFile:Dynamic, posLow:Dynamic, posHigh:Dynamic):Int;

	@:cffi private static function lime_vorbis_file_pcm_seek_page_lap(vorbisFile:Dynamic, posLow:Dynamic, posHigh:Dynamic):Int;

	@:cffi private static function lime_vorbis_file_raw_seek(vorbisFile:Dynamic, posLow:Dynamic, posHigh:Dynamic):Int;

	@:cffi private static function lime_vorbis_file_raw_seek_lap(vorbisFile:Dynamic, posLow:Dynamic, posHigh:Dynamic):Int;

	@:cffi private static function lime_vorbis_file_pcm_tell(vorbisFile:Dynamic):Dynamic;

	@:cffi private static function lime_vorbis_file_pcm_total(vorbisFile:Dynamic, bitstream:Int):Dynamic;

	@:cffi private static function lime_vorbis_file_raw_tell(vorbisFile:Dynamic):Dynamic;

	@:cffi private static function lime_vorbis_file_raw_total(vorbisFile:Dynamic, bitstream:Int):Dynamic;

	@:cffi private static function lime_vorbis_file_read(vorbisFile:Dynamic, buffer:Dynamic, position:Int, length:Int, bigendianp:Bool, word:Int,
		signed:Bool):Dynamic;

	@:cffi private static function lime_vorbis_file_read_float(vorbisFile:Dynamic, pcmChannels:Dynamic, samples:Int):Dynamic;

	@:cffi private static function lime_vorbis_file_seekable(vorbisFile:Dynamic):Bool;

	@:cffi private static function lime_vorbis_file_serial_number(vorbisFile:Dynamic, bitstream:Int):Int;

	@:cffi private static function lime_vorbis_file_streams(vorbisFile:Dynamic):Int;

	@:cffi private static function lime_vorbis_file_time_seek(vorbisFile:Dynamic, s:Float):Int;

	@:cffi private static function lime_vorbis_file_time_seek_lap(vorbisFile:Dynamic, s:Float):Int;

	@:cffi private static function lime_vorbis_file_time_seek_page(vorbisFile:Dynamic, s:Float):Int;

	@:cffi private static function lime_vorbis_file_time_seek_page_lap(vorbisFile:Dynamic, s:Float):Int;

	@:cffi private static function lime_vorbis_file_time_tell(vorbisFile:Dynamic):Float;

	@:cffi private static function lime_vorbis_file_time_total(vorbisFile:Dynamic, bitstream:Int):Float;
	#else
	private static var lime_vorbis_file_bitrate = new cpp.Callable<cpp.Object->Int->Int>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_bitrate", "oii",
		false));
	private static var lime_vorbis_file_bitrate_instant = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_bitrate_instant",
		"oi", false));
	private static var lime_vorbis_file_clear = new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_clear", "ov", false));
	private static var lime_vorbis_file_comment = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_comment",
		"oio", false));
	private static var lime_vorbis_file_crosslap = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_crosslap", "ooo", false));
	private static var lime_vorbis_file_from_bytes = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_from_bytes",
		"oo", false));
	private static var lime_vorbis_file_from_file = new cpp.Callable<String->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_from_file", "so",
		false));
	private static var lime_vorbis_file_info = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_info", "oio",
		false));
	private static var lime_vorbis_file_pcm_seek = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_pcm_seek", "oooi", false));
	private static var lime_vorbis_file_pcm_seek_lap = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_pcm_seek_lap", "oooi", false));
	private static var lime_vorbis_file_pcm_seek_page = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_pcm_seek_page", "oooi", false));
	private static var lime_vorbis_file_pcm_seek_page_lap = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_pcm_seek_page_lap", "oooi", false));
	private static var lime_vorbis_file_raw_seek = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_raw_seek", "oooi", false));
	private static var lime_vorbis_file_raw_seek_lap = new cpp.Callable<cpp.Object->cpp.Object->cpp.Object->Int>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_raw_seek_lap", "oooi", false));
	private static var lime_vorbis_file_pcm_tell = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_pcm_tell", "oo",
		false));
	private static var lime_vorbis_file_pcm_total = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_pcm_total",
		"oio", false));
	private static var lime_vorbis_file_raw_tell = new cpp.Callable<cpp.Object->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_raw_tell", "oo",
		false));
	private static var lime_vorbis_file_raw_total = new cpp.Callable<cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_raw_total",
		"oio", false));
	private static var lime_vorbis_file_read = new cpp.Callable<cpp.Object->cpp.Object->Int->Int->Bool->Int->Bool->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_read", "ooiibibo", false));
	private static var lime_vorbis_file_read_float = new cpp.Callable<cpp.Object->cpp.Object->Int->cpp.Object>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_read_float", "ooio", false));
	private static var lime_vorbis_file_seekable = new cpp.Callable<cpp.Object->Bool>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_seekable", "ob", false));
	private static var lime_vorbis_file_serial_number = new cpp.Callable<cpp.Object->Int->Int>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_serial_number",
		"oii", false));
	private static var lime_vorbis_file_streams = new cpp.Callable<cpp.Object->Int>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_streams", "oi", false));
	private static var lime_vorbis_file_time_seek = new cpp.Callable<cpp.Object->Float->Int>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_time_seek", "odi",
		false));
	private static var lime_vorbis_file_time_seek_lap = new cpp.Callable<cpp.Object->Float->Int>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_time_seek_lap", "odi", false));
	private static var lime_vorbis_file_time_seek_page = new cpp.Callable<cpp.Object->Float->Int>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_time_seek_page", "odi", false));
	private static var lime_vorbis_file_time_seek_page_lap = new cpp.Callable<cpp.Object->Float->Int>(cpp.Prime._loadPrime("lime",
		"lime_vorbis_file_time_seek_page_lap", "odi", false));
	private static var lime_vorbis_file_time_tell = new cpp.Callable<cpp.Object->Float>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_time_tell", "od",
		false));
	private static var lime_vorbis_file_time_total = new cpp.Callable<cpp.Object->Int->Float>(cpp.Prime._loadPrime("lime", "lime_vorbis_file_time_total",
		"oid", false));
	#end
	#end
	#if (neko || cppia)
	private static var lime_vorbis_file_bitrate = CFFI.load("lime", "lime_vorbis_file_bitrate", 2);
	private static var lime_vorbis_file_bitrate_instant = CFFI.load("lime", "lime_vorbis_file_bitrate_instant", 1);
	private static var lime_vorbis_file_clear = CFFI.load("lime", "lime_vorbis_file_clear", 1);
	private static var lime_vorbis_file_comment = CFFI.load("lime", "lime_vorbis_file_comment", 2);
	private static var lime_vorbis_file_crosslap = CFFI.load("lime", "lime_vorbis_file_crosslap", 2);
	private static var lime_vorbis_file_from_bytes = CFFI.load("lime", "lime_vorbis_file_from_bytes", 1);
	private static var lime_vorbis_file_from_file = CFFI.load("lime", "lime_vorbis_file_from_file", 1);
	private static var lime_vorbis_file_info = CFFI.load("lime", "lime_vorbis_file_info", 2);
	private static var lime_vorbis_file_pcm_seek = CFFI.load("lime", "lime_vorbis_file_pcm_seek", 3);
	private static var lime_vorbis_file_pcm_seek_lap = CFFI.load("lime", "lime_vorbis_file_pcm_seek_lap", 3);
	private static var lime_vorbis_file_pcm_seek_page = CFFI.load("lime", "lime_vorbis_file_pcm_seek_page", 3);
	private static var lime_vorbis_file_pcm_seek_page_lap = CFFI.load("lime", "lime_vorbis_file_pcm_seek_page_lap", 3);
	private static var lime_vorbis_file_raw_seek = CFFI.load("lime", "lime_vorbis_file_raw_seek", 3);
	private static var lime_vorbis_file_raw_seek_lap = CFFI.load("lime", "lime_vorbis_file_raw_seek_lap", 3);
	private static var lime_vorbis_file_pcm_tell = CFFI.load("lime", "lime_vorbis_file_pcm_tell", 1);
	private static var lime_vorbis_file_pcm_total = CFFI.load("lime", "lime_vorbis_file_pcm_total", 2);
	private static var lime_vorbis_file_raw_tell = CFFI.load("lime", "lime_vorbis_file_raw_tell", 1);
	private static var lime_vorbis_file_raw_total = CFFI.load("lime", "lime_vorbis_file_raw_total", 2);
	private static var lime_vorbis_file_read = CFFI.load("lime", "lime_vorbis_file_read", -1);
	private static var lime_vorbis_file_read_float = CFFI.load("lime", "lime_vorbis_file_read_float", 3);
	private static var lime_vorbis_file_seekable = CFFI.load("lime", "lime_vorbis_file_seekable", 1);
	private static var lime_vorbis_file_serial_number = CFFI.load("lime", "lime_vorbis_file_serial_number", 2);
	private static var lime_vorbis_file_streams = CFFI.load("lime", "lime_vorbis_file_streams", 1);
	private static var lime_vorbis_file_time_seek = CFFI.load("lime", "lime_vorbis_file_time_seek", 2);
	private static var lime_vorbis_file_time_seek_lap = CFFI.load("lime", "lime_vorbis_file_time_seek_lap", 2);
	private static var lime_vorbis_file_time_seek_page = CFFI.load("lime", "lime_vorbis_file_time_seek_page", 2);
	private static var lime_vorbis_file_time_seek_page_lap = CFFI.load("lime", "lime_vorbis_file_time_seek_page_lap", 2);
	private static var lime_vorbis_file_time_tell = CFFI.load("lime", "lime_vorbis_file_time_tell", 1);
	private static var lime_vorbis_file_time_total = CFFI.load("lime", "lime_vorbis_file_time_total", 2);
	#end

	#if hl
	@:hlNative("lime", "lime_vorbis_file_bitrate") private static function lime_vorbis_file_bitrate(vorbisFile:CFFIPointer, bitstream:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_bitrate_instant") private static function lime_vorbis_file_bitrate_instant(vorbisFile:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_clear") private static function lime_vorbis_file_clear(vorbisFile:CFFIPointer):Void {}

	@:hlNative("lime", "lime_vorbis_file_comment") private static function lime_vorbis_file_comment(vorbisFile:CFFIPointer, bitstream:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_vorbis_file_crosslap") private static function lime_vorbis_file_crosslap(vorbisFile:CFFIPointer, otherVorbisFile:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_from_bytes") private static function lime_vorbis_file_from_bytes(bytes:Bytes):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_vorbis_file_from_file") private static function lime_vorbis_file_from_file(path:String):CFFIPointer
	{
		return null;
	}

	@:hlNative("lime", "lime_vorbis_file_info") private static function lime_vorbis_file_info(vorbisFile:CFFIPointer, bitstream:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_vorbis_file_pcm_seek") private static function lime_vorbis_file_pcm_seek(vorbisFile:CFFIPointer, posLow:Int, posHigh:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_pcm_seek_lap") private static function lime_vorbis_file_pcm_seek_lap(vorbisFile:CFFIPointer, posLow:Int,
			posHigh:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_pcm_seek_page") private static function lime_vorbis_file_pcm_seek_page(vorbisFile:CFFIPointer, posLow:Int,
			posHigh:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_pcm_seek_page_lap") private static function lime_vorbis_file_pcm_seek_page_lap(vorbisFile:CFFIPointer, posLow:Int,
			posHigh:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_raw_seek") private static function lime_vorbis_file_raw_seek(vorbisFile:CFFIPointer, posLow:Int, posHigh:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_raw_seek_lap") private static function lime_vorbis_file_raw_seek_lap(vorbisFile:CFFIPointer, posLow:Int,
			posHigh:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_pcm_tell") private static function lime_vorbis_file_pcm_tell(vorbisFile:CFFIPointer):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_vorbis_file_pcm_total") private static function lime_vorbis_file_pcm_total(vorbisFile:CFFIPointer, bitstream:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_vorbis_file_raw_tell") private static function lime_vorbis_file_raw_tell(vorbisFile:CFFIPointer):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_vorbis_file_raw_total") private static function lime_vorbis_file_raw_total(vorbisFile:CFFIPointer, bitstream:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_vorbis_file_read") private static function lime_vorbis_file_read(vorbisFile:CFFIPointer, buffer:Bytes, position:Int, length:Int,
			bigendianp:Bool, word:Int, signed:Bool):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_vorbis_file_read_float") private static function lime_vorbis_file_read_float(vorbisFile:CFFIPointer, pcmChannels:Bytes,
			samples:Int):Dynamic
	{
		return null;
	}

	@:hlNative("lime", "lime_vorbis_file_seekable") private static function lime_vorbis_file_seekable(vorbisFile:CFFIPointer):Bool
	{
		return false;
	}

	@:hlNative("lime", "lime_vorbis_file_serial_number") private static function lime_vorbis_file_serial_number(vorbisFile:CFFIPointer, bitstream:Int):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_streams") private static function lime_vorbis_file_streams(vorbisFile:CFFIPointer):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_time_seek") private static function lime_vorbis_file_time_seek(vorbisFile:CFFIPointer, s:Float):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_time_seek_lap") private static function lime_vorbis_file_time_seek_lap(vorbisFile:CFFIPointer, s:Float):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_time_seek_page") private static function lime_vorbis_file_time_seek_page(vorbisFile:CFFIPointer, s:Float):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_time_seek_page_lap") private static function lime_vorbis_file_time_seek_page_lap(vorbisFile:CFFIPointer, s:Float):Int
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_time_tell") private static function lime_vorbis_file_time_tell(vorbisFile:CFFIPointer):Float
	{
		return 0;
	}

	@:hlNative("lime", "lime_vorbis_file_time_total") private static function lime_vorbis_file_time_total(vorbisFile:CFFIPointer, bitstream:Int):Float
	{
		return 0;
	}
	#end
	#end
}
