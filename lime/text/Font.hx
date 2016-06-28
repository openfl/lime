package lime.text;


import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.math.Vector2;
import lime.system.System;
import lime.utils.UInt8Array;

#if ((cpp || neko || nodejs) && !macro)
import haxe.io.Path;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end

#if (!display && !nodejs && !macro)
@:autoBuild(lime.Assets.embedFont())
#end

@:access(lime.text.Glyph)


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
	#if (cpp || neko || nodejs)
	@:noCompletion private var __fontPathWithoutDirectory:String;
	#end
	
	public function new (name:String = null) {
		
		if (name != null) {
			
			this.name = name;
			
		}
		
		if (__fontPath != null) {
			
			__fromFile (__fontPath);
			
		}
		
	}
	
	
	public function decompose ():NativeFontData {
		
		#if ((cpp || neko || nodejs) && !macro)
		
		if (src == null) throw "Uninitialized font handle.";
		var data:Dynamic = lime_font_outline_decompose (src, 1024 * 20);
		return data;
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function fromBytes (bytes:Bytes):Font {
		
		var font = new Font ();
		font.__fromBytes (bytes);
		
		#if ((cpp || neko || nodejs) && !macro)
		return (font.src != null) ? font : null;
		#else
		return font;
		#end
		
	}
	
	
	public static function fromFile (path:String):Font {
		
		var font = new Font ();
		font.__fromFile (path);
		
		#if ((cpp || neko || nodejs) && !macro)
		return (font.src != null) ? font : null;
		#else
		return font;
		#end
		
	}
	
	
	public function getGlyph (character:String):Glyph {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_font_get_glyph_index (src, character);
		#else
		return -1;
		#end
		
	}
	
	
	public function getGlyphs (characters:String = #if (display && haxe_ver < "3.2") "" #else "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^`'\"/\\&*()[]{}<>|:;_-+=?,. " #end):Array<Glyph> {
		
		#if ((cpp || neko || nodejs) && !macro)
		var glyphs:Dynamic = lime_font_get_glyph_indices (src, characters);
		return glyphs;
		#else
		return null;
		#end
		
	}
	
	
	public function getGlyphMetrics (glyph:Glyph):GlyphMetrics {
		
		#if ((cpp || neko || nodejs) && !macro)
		var value:Dynamic = lime_font_get_glyph_metrics (src, glyph);
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
		
		#if ((cpp || neko || nodejs) && !macro)
		
		lime_font_set_size (src, fontSize);
		
		var bytes = Bytes.alloc (0);
		//bytes.endian = (System.endianness == BIG_ENDIAN ? "bigEndian" : "littleEndian");
		
		var dataPosition = 0;
		
		if (lime_font_render_glyph (src, glyph, bytes)) {
			
			var index = bytes.getInt32 (dataPosition); dataPosition += 4;
			var width = bytes.getInt32 (dataPosition); dataPosition += 4;
			var height = bytes.getInt32 (dataPosition); dataPosition += 4;
			var x = bytes.getInt32 (dataPosition); dataPosition += 4;
			var y = bytes.getInt32 (dataPosition); dataPosition += 4;
			
			var data = bytes.sub (dataPosition, width * height);
			dataPosition += (width * height);
			
			var buffer = new ImageBuffer (new UInt8Array (data), width, height, 1);
			var image = new Image (buffer, 0, 0, width, height);
			image.x = x;
			image.y = y;
			
			return image;
			
		}
		
		#end
		
		return null;
		
	}

	
	public function renderGlyphs (glyphs:Array<Glyph>, fontSize:Int):Map<Glyph, Image> {
		
		//#if ((cpp || neko || nodejs) && !macro)
		//
		//var uniqueGlyphs = new Map<Int, Bool> ();
		//
		//for (glyph in glyphs) {
			//
			//uniqueGlyphs.set (glyph, true);
			//
		//}
		//
		//var glyphList = [];
		//
		//for (key in uniqueGlyphs.keys ()) {
			//
			//glyphList.push (key);
			//
		//}
		//
		//lime_font_set_size (src, fontSize);
		//
		//var bytes = new ByteArray ();
		//bytes.endian = (System.endianness == BIG_ENDIAN ? "bigEndian" : "littleEndian");
		//
		//if (lime_font_render_glyphs (src, glyphList, bytes)) {
			//
			//bytes.position = 0;
			//
			//var count = bytes.readUnsignedInt ();
			//
			//var bufferWidth = 128;
			//var bufferHeight = 128;
			//var offsetX = 0;
			//var offsetY = 0;
			//var maxRows = 0;
			//
			//var width, height;
			//var i = 0;
			//
			//while (i < count) {
				//
				//bytes.position += 4;
				//width = bytes.readUnsignedInt ();
				//height = bytes.readUnsignedInt ();
				//bytes.position += (4 * 2) + width * height;
				//
				//if (offsetX + width > bufferWidth) {
					//
					//offsetY += maxRows + 1;
					//offsetX = 0;
					//maxRows = 0;
					//
				//}
				//
				//if (offsetY + height > bufferHeight) {
					//
					//if (bufferWidth < bufferHeight) {
						//
						//bufferWidth *= 2;
						//
					//} else {
						//
						//bufferHeight *= 2;
						//
					//}
					//
					//offsetX = 0;
					//offsetY = 0;
					//maxRows = 0;
					//
					//// TODO: make this better
					//
					//bytes.position = 4;
					//i = 0;
					//continue;
					//
				//}
				//
				//offsetX += width + 1;
				//
				//if (height > maxRows) {
					//
					//maxRows = height;
					//
				//}
				//
				//i++;
				//
			//}
			//
			//var map = new Map<Int, Image> ();
			//var buffer = new ImageBuffer (null, bufferWidth, bufferHeight, 8);
			//var data = new ByteArray (bufferWidth * bufferHeight);
			//
			//bytes.position = 4;
			//offsetX = 0;
			//offsetY = 0;
			//maxRows = 0;
			//
			//var index, x, y, image;
			//
			//for (i in 0...count) {
				//
				//index = bytes.readUnsignedInt ();
				//width = bytes.readUnsignedInt ();
				//height = bytes.readUnsignedInt ();
				//x = bytes.readUnsignedInt ();
				//y = bytes.readUnsignedInt ();
				//
				//if (offsetX + width > bufferWidth) {
					//
					//offsetY += maxRows + 1;
					//offsetX = 0;
					//maxRows = 0;
					//
				//}
				//
				//for (i in 0...height) {
					//
					//data.position = ((i + offsetY) * bufferWidth) + offsetX;
					////bytes.readBytes (data, 0, width);
					//
					//for (x in 0...width) {
						//
						//var byte = bytes.readUnsignedByte ();
						//data.writeByte (byte);
						//
					//}
					//
				//}
				//
				//image = new Image (buffer, offsetX, offsetY, width, height);
				//image.x = x;
				//image.y = y;
				//
				//map.set (index, image);
				//
				//offsetX += width + 1;
				//
				//if (height > maxRows) {
					//
					//maxRows = height;
					//
				//}
				//
			//}
			//
			//#if js
			//buffer.data = data.byteView;
			//#else
			//buffer.data = new UInt8Array (data);
			//#end
			//
			//return map;
			//
		//}
		//
		//#end
		
		return null;
		
	}
		
	@:noCompletion private function __fromBytes (bytes:Bytes):Void {
		
		__fontPath = null;
		
		#if ((cpp || neko || nodejs) && !macro)
		
		__fontPathWithoutDirectory = null;
		
		src = lime_font_load (bytes);
		
		if (src != null && name == null) {
			
			name = cast lime_font_get_family_name (src);
			
		}
		
		#end
		
	}
	
	
	@:noCompletion private function __fromFile (path:String):Void {
		
		__fontPath = path;
		
		#if ((cpp || neko || nodejs) && !macro)
		
		__fontPathWithoutDirectory = Path.withoutDirectory (__fontPath);
		
		src = lime_font_load (__fontPath);
		
		if (src != null && name == null) {
			
			name = cast lime_font_get_family_name (src);
			
		}
		
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_ascender ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_font_get_ascender (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_descender ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_font_get_descender (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_height ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_font_get_height (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_numGlyphs ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_font_get_num_glyphs (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_underlinePosition ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_font_get_underline_position (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_underlineThickness ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_font_get_underline_thickness (src);
		#else
		return 0;
		#end
		
	}
	
	
	private function get_unitsPerEM ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_font_get_units_per_em (src);
		#else
		return 0;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
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
