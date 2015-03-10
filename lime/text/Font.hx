package lime.text;


import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.math.Vector2;
import lime.text.Glyph;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;
import lime.system.System;

#if (js && html5)
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
#end

@:access(lime.text.Glyph)
@:autoBuild(lime.Assets.embedFont())


class Font {
	
	
	public var ascender (get, null):Int;
	public var descender (get, null):Int;
	public var height (get, null):Int;
	public var name (default, null):String;
	public var numGlyphs (get, null):Int;
	public var underlinePosition (get, null):Int;
	public var underlineThickness (get, null):Int;
	public var unitsPerEM (get, null):Int;
	
	@:noCompletion private var __fontPath:String;
	@:noCompletion private var __handle:Dynamic;
	
	
	public function new (name:String = null) {
		
		this.name = name;
		
	}
	
	
	public function decompose ():NativeFontData {
		
		#if (cpp || neko || nodejs)
		
		if (__handle == null) throw "Uninitialized font handle.";
		return lime_font_outline_decompose (__handle, 1024 * 20);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function fromBytes (bytes:ByteArray):Font {
		
		var font = new Font ();
		font.__fromBytes (bytes);
		return font;
		
	}
	
	
	public static function fromFile (path:String):Font {
		
		var font = new Font ();
		font.__fromFile (path);
		return font;
		
	}
	
	
	public function getGlyphMetrics (glyphs:GlyphSet = null):Map<Int, Glyph> {
		
		if (glyphs == null) {
			
			glyphs = new GlyphSet ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^`'\"/\\&*()[]{}<>|:;_-+=?,. ");
			
		}
		
		#if (cpp || neko || nodejs)
		var array:Array<Dynamic> = lime_font_get_glyph_metrics (__handle, glyphs);
		var map = new Map<Int, Glyph> ();
		
		for (value in array) {
			
			var glyph = new Glyph (value.charCode, value.glyphIndex);
			var metrics = new GlyphMetrics ();
			
			metrics.height = value.height;
			metrics.horizontalAdvance = value.horizontalAdvance;
			metrics.horizontalBearingX = value.horizontalBearingX;
			metrics.horizontalBearingY = value.horizontalBearingY;
			metrics.verticalAdvance = value.verticalAdvance;
			metrics.verticalBearingX = value.verticalBearingX;
			metrics.verticalBearingY = value.verticalBearingY;
			
			glyph.metrics = metrics;
			
			map.set (glyph.glyphIndex, glyph);
			
		}
		
		return map;
		#else
		return null;
		#end
		
	}
	
	
	public function renderGlyphs (fontSize:Int, glyphs:GlyphSet = null):Map<Int, Glyph> {
		
		if (glyphs == null) {
			
			glyphs = new GlyphSet ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^`'\"/\\&*()[]{}<>|:;_-+=?,. ");
			
		}
		
		#if (cpp || neko || nodejs)
		
		var data = lime_font_create_images (__handle, fontSize, glyphs);
		
		if (data == null) {
			
			return null;
			
		} else {
			
			var buffer = new ImageBuffer (new UInt8Array (data.image.data), data.image.width, data.image.height, data.image.bpp);
			var map = new Map<Int, Glyph> ();
			
			for (glyphData in cast (data.glyphs, Array<Dynamic>)) {
				
				if (glyphData != null) {
					
					var glyph = new Glyph (glyphData.charCode, glyphData.glyphIndex);
					glyph.image = new Image (buffer, glyphData.x, glyphData.y, glyphData.width, glyphData.height);
					glyph.x = glyphData.offset.x;
					glyph.y = glyphData.offset.y;
					map.set (glyph.glyphIndex, glyph);
					
				}
				
			}
			
			return map;
			
		}
		
		#end
		
		return null;
		
	}
	
	
	@:noCompletion private function __fromBytes (bytes:ByteArray):Void {
		
		__fontPath = null;
		
		#if (cpp || neko || nodejs)
		
		__handle = lime_font_load (bytes);
		
		if (__handle != null) {
			
			name = lime_font_get_family_name (__handle);
			
		}
		
		#end
		
	}
	
	
	@:noCompletion private function __fromFile (path:String):Void {
		
		__fontPath = path;
		
		#if (cpp || neko || nodejs)
		
		__handle = lime_font_load (__fontPath);
		
		if (__handle != null) {
			
			name = lime_font_get_family_name (__handle);
			
		}
		
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_ascender ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_ascender (__handle);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_descender ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_descender (__handle);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_height ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_height (__handle);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_numGlyphs ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_num_glyphs (__handle);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_underlinePosition ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_underline_position (__handle);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_underlineThickness ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_underline_thickness (__handle);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_unitsPerEM ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_units_per_em (__handle);
		#else
		return 0;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_font_get_ascender = System.load ("lime", "lime_font_get_ascender", 1);
	private static var lime_font_get_descender = System.load ("lime", "lime_font_get_descender", 1);
	private static var lime_font_get_family_name = System.load ("lime", "lime_font_get_family_name", 1);
	private static var lime_font_get_glyph_metrics = System.load ("lime", "lime_font_get_glyph_metrics", 2);
	private static var lime_font_get_height = System.load ("lime", "lime_font_get_height", 1);
	private static var lime_font_get_num_glyphs = System.load ("lime", "lime_font_get_num_glyphs", 1);
	private static var lime_font_get_underline_position = System.load ("lime", "lime_font_get_underline_position", 1);
	private static var lime_font_get_underline_thickness = System.load ("lime", "lime_font_get_underline_thickness", 1);
	private static var lime_font_get_units_per_em = System.load ("lime", "lime_font_get_units_per_em", 1);
	private static var lime_font_load:Dynamic = System.load ("lime", "lime_font_load", 1);
	private static var lime_font_create_images = System.load ("lime", "lime_font_create_images", 3);
	private static var lime_font_outline_decompose = System.load ("lime", "lime_font_outline_decompose", 2);
	#end
	
	
}


typedef NativeFontData = {
	
	var has_kerning:Bool;
	var is_fixed_width:Bool;
	var has_glyph_names:Bool;
	var is_italic:Bool;
	var is_bold:Bool;
	var num_glyphs:Int;
	var family_name:String;
	var style_name:String;
	var em_size:Int;
	var ascend:Int;
	var descend:Int;
	var height:Int;
	var glyphs:Array<NativeGlyphData>;
	var kerning:Array<NativeKerningData>;
	
}


typedef NativeGlyphData = {
	
	var char_code:Int;
	var advance:Int;
	var min_x:Int;
	var max_x:Int;
	var min_y:Int;
	var max_y:Int;
	var points:Array<Int>;
	
}


typedef NativeKerningData = {
	
	var left_glyph:Int;
	var right_glyph:Int;
	var x:Int;
	var y:Int;
	
}
