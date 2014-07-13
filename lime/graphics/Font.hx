package lime.graphics;

import lime.utils.UInt8Array;
import lime.system.System;

typedef GlyphData = {
	var image:Image;
	var glyphs:Array<Dynamic>;
};

class Font {

	#if (cpp || neko)
	public var handle:Dynamic;
	#end

	public function new (fontFace:String) {

		#if (cpp || neko)
		handle = lime_font_load (fontFace);
		#end

	}

	public function createImage (size:Int, glyphs:String="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^`'\"/\\&*()[]{}<>|:;_-+=?,. "):GlyphData {

		#if (cpp || neko)

		var data = lime_font_load_glyphs (handle, size, glyphs);

		if (data == null) {

			return null;

		} else {

			return {
				glyphs: data.glyphs,
				image: new Image (new UInt8Array (data.image.data), data.image.width, data.image.height, data.image.bpp)
			};

		}

		#end

		return null;

	}

	#if (cpp || neko)
	private static var lime_font_load = System.load ("lime", "lime_font_load", 1);
	private static var lime_font_load_glyphs = System.load ("lime", "lime_font_load_glyphs", 3);
	#end

}
