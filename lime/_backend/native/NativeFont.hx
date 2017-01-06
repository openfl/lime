package lime._backend.native;


#if !macro
@:build(lime.system.CFFI.build())
#end

class NativeFont {
	
	
	#if (lime_cffi && !macro)
	@:cffi private static function lime_font_get_ascender (handle:Dynamic):Int;
	@:cffi private static function lime_font_get_descender (handle:Dynamic):Int;
	@:cffi private static function lime_font_get_family_name (handle:Dynamic):Dynamic;
	@:cffi private static function lime_font_get_glyph_index (handle:Dynamic, character:String):Int;
	@:cffi private static function lime_font_get_glyph_indices (handle:Dynamic, characters:String):Dynamic;
	@:cffi private static function lime_font_get_glyph_metrics (handle:Dynamic, index:Int):Dynamic;
	@:cffi private static function lime_font_get_height (handle:Dynamic):Int;
	@:cffi private static function lime_font_get_num_glyphs (handle:Dynamic):Int;
	@:cffi private static function lime_font_get_underline_position (handle:Dynamic):Int;
	@:cffi private static function lime_font_get_underline_thickness (handle:Dynamic):Int;
	@:cffi private static function lime_font_get_units_per_em (handle:Dynamic):Int;
	@:cffi private static function lime_font_load (data:Dynamic):Dynamic;
	@:cffi private static function lime_font_outline_decompose (handle:Dynamic, size:Int):Dynamic;
	@:cffi private static function lime_font_render_glyph (handle:Dynamic, index:Int, data:Dynamic):Bool;
	@:cffi private static function lime_font_render_glyphs (handle:Dynamic, indices:Dynamic, data:Dynamic):Bool;
	@:cffi private static function lime_font_set_size (handle:Dynamic, size:Int):Void;
	#end
	
	
}