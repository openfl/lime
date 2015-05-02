package lime.text;


import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.math.Vector2;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;
import lime.system.System;

#if (js && html5)
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
#end

@:access(lime.text.Glyph)

#if (!display && !nodejs)
@:autoBuild(lime.Assets.embedFont())
#end


class Font {
	
	
	public var ascender (get, null):Int;
	public var descender (get, null):Int;
	public var height (get, null):Int;
	public var name (default, null):String;
	public var numGlyphs (get, null):Int;
	public var src:Dynamic;
	public var underlinePosition (get, null):Int;
	public var underlineThickness (get, null):Int;
	public var unitsPerEM (get, null):Int;
	
	@:noCompletion private var __fontPath:String;
	
	
	public function new (name:String = null) {
		
		this.name = name;
		
		if (__fontPath != null) {
			
			__fromFile (__fontPath);
			
		}
		
	}
	
	
	public function decompose ():NativeFontData {
		
		#if (cpp || neko || nodejs)
		
		if (src == null) throw "Uninitialized font handle.";
		return lime_font_outline_decompose (src, 1024 * 20);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function fromBytes (bytes:ByteArray):Font {
		
		var font = new Font ();
		font.__fromBytes (bytes);
		
		#if (cpp || neko || nodejs)
		return (font.src != null) ? font : null;
		#else
		return font;
		#end
		
	}
	
	
	public static function fromFile (path:String):Font {
		
		var font = new Font ();
		font.__fromFile (path);
		
		#if (cpp || neko || nodejs)
		return (font.src != null) ? font : null;
		#else
		return font;
		#end
		
	}
	
	
	public function getGlyph (character:String):Glyph {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_glyph_index (src, character);
		#else
		return -1;
		#end
		
	}
	
	
	public function getGlyphs (characters:String = #if (display && haxe_ver < "3.2") "" #else "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^`'\"/\\&*()[]{}<>|:;_-+=?,. " #end):Array<Glyph> {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_glyph_indices (src, characters);
		#else
		return null;
		#end
		
	}
	
	
	public function getGlyphMetrics (glyph:Glyph):GlyphMetrics {
		
		#if (cpp || neko || nodejs)
		var value = lime_font_get_glyph_metrics (src, glyph);
		var metrics = new GlyphMetrics ();
		
		metrics.advance = new Vector2 (value.horizontalAdvance, value.verticalAdvance);
		metrics.height = value.height;
		metrics.horizontalBearing = new Vector2 (value.horizontalBearingX, value.horizontalBearingY);
		metrics.verticalBearing = new Vector2 (value.verticalBearingX, value.verticalBearingY);
		
		return metrics;
		#else
		return null;
		#end
		
	}
	
	
	public function renderGlyph (glyph:Glyph, fontSize:Int):Image {
		
		#if (cpp || neko || nodejs)
		
		lime_font_set_size (src, fontSize);
		
		var bytes = new ByteArray ();
		bytes.endian = "littleEndian";
		var data:ByteArray = lime_font_render_glyph (src, glyph, bytes);
		
		if (data != null) {
			
			var width = bytes.readUnsignedInt ();
			var height = bytes.readUnsignedInt ();
			var x = bytes.readInt ();
			var y = bytes.readInt ();
			
			var buffer = new ImageBuffer (getUInt8ArrayFromByteArray (data), width, height, 1);
			var image = new Image (buffer, 0, 0, width, height);
			image.x = x;
			image.y = y;
			
			return image;
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public function renderGlyphs (glyphList:Array<Glyph>, fontSize:Int):Array<Image> {
		
		#if (cpp || neko || nodejs)
		
		lime_font_set_size (src, fontSize);
		
		var bytes = new ByteArray ();
		bytes.endian = "littleEndian";
		
		var rawImages:Array<ByteArray> = lime_font_render_glyphs (src, glyphList, bytes);
		
		if (rawImages != null) {
			
			var results:Array<Image> = [];
			for (i in 0 ... rawImages.length)
			{
				var width = bytes.readUnsignedInt ();
				var height = bytes.readUnsignedInt ();
				var x = bytes.readInt ();
				var y = bytes.readInt ();
				
				var rawImage:ByteArray = rawImages[i];
                var buffer, image = null;
                if (rawImage != null)
                {
                    
				    buffer = new ImageBuffer (getUInt8ArrayFromByteArray (rawImage), width, height, 1);
				    image = new Image (buffer, 0, 0, width, height);
				    image.x = x;
				    image.y = y;
                    
                }
                results.push (image);
			}
			
			return results;
			
		}
		
		#end
		
		return null;
		
	}
	
	
	@:noCompletion private function __fromBytes (bytes:ByteArray):Void {
		
		__fontPath = null;
		
		#if (cpp || neko || nodejs)
		
		src = lime_font_load (bytes);
		
		if (src != null && name == null) {
			
			name = lime_font_get_family_name (src);
			
		}
		
		#end
		
	}
	
	
	@:noCompletion private function __fromFile (path:String):Void {
		
		__fontPath = path;
		
		#if (cpp || neko || nodejs)
		
		src = lime_font_load (__fontPath);
		
		if (src != null && name == null) {
			
			name = lime_font_get_family_name (src);
			
		}
		
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_ascender ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_ascender (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_descender ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_descender (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_height ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_height (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_numGlyphs ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_num_glyphs (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_underlinePosition ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_underline_position (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_underlineThickness ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_underline_thickness (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_unitsPerEM ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_font_get_units_per_em (src);
		#else
		return 0;
		#end
		
	}
	
	private inline function getUInt8ArrayFromByteArray(ba:ByteArray)
	{
		#if nodejs
		return ba.byteView;
		#else
		return new UInt8Array(ba);
		#end
	}
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_font_get_ascender = System.load ("lime", "lime_font_get_ascender", 1);
	private static var lime_font_get_descender = System.load ("lime", "lime_font_get_descender", 1);
	private static var lime_font_get_family_name = System.load ("lime", "lime_font_get_family_name", 1);
	private static var lime_font_get_glyph_index = System.load ("lime", "lime_font_get_glyph_index", 2);
	private static var lime_font_get_glyph_indices = System.load ("lime", "lime_font_get_glyph_indices", 2);
	private static var lime_font_get_glyph_metrics = System.load ("lime", "lime_font_get_glyph_metrics", 2);
	private static var lime_font_get_height = System.load ("lime", "lime_font_get_height", 1);
	private static var lime_font_get_num_glyphs = System.load ("lime", "lime_font_get_num_glyphs", 1);
	private static var lime_font_get_underline_position = System.load ("lime", "lime_font_get_underline_position", 1);
	private static var lime_font_get_underline_thickness = System.load ("lime", "lime_font_get_underline_thickness", 1);
	private static var lime_font_get_units_per_em = System.load ("lime", "lime_font_get_units_per_em", 1);
	private static var lime_font_load:Dynamic = System.load ("lime", "lime_font_load", 1);
	private static var lime_font_outline_decompose = System.load ("lime", "lime_font_outline_decompose", 2);
	private static var lime_font_render_glyph = System.load ("lime", "lime_font_render_glyph", 3);
	private static var lime_font_render_glyphs = System.load ("lime", "lime_font_render_glyphs", 3);
	private static var lime_font_set_size = System.load ("lime", "lime_font_set_size", 2);
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
