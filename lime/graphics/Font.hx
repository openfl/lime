package lime.graphics;

import haxe.ds.StringMap;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.utils.UInt8Array;
import lime.system.System;
#if js
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
#end

typedef GlyphRect = {
	var x:Float;
	var y:Float;
	var advance:Int;
	var width:Float;
	var height:Float;
	var xOffset:Int;
	var yOffset:Int;
}

typedef GlyphData = {
	var image:Image;
	var glyphs:StringMap<GlyphRect>;
};

@:autoBuild(lime.Assets.embedFont())
class Font {

	#if js

	private static var __canvas:CanvasElement;
	private static var __context:CanvasRenderingContext2D;

	#elseif (cpp || neko)

	public var handle:GlyphRect;

	#end

	public var fontFace(default, null):String;

	public function new (fontFace:String) {

		this.fontFace = fontFace;

		#if (cpp || neko)

		handle = lime_font_load (fontFace);

		#end

	}

	public function createImage (size:Int, glyphs:String="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^`'\"/\\&*()[]{}<>|:;_-+=?,. "):GlyphData {

		var glyphRects = new StringMap<GlyphRect>();

		#if js

		if (__canvas == null) {

			__canvas = cast js.Browser.document.createElement ("canvas");
			__context = cast __canvas.getContext ("2d");

		}

		__canvas.width = __canvas.height = 128;
		__context.fillStyle = "#000000";
		__context.textBaseline = "top";
		__context.textAlign = "left";
		__context.font = size + "px " + fontFace;

		// canvas doesn't give the appropriate metrics so the values have to be padded...
		var padding = size / 4;

		var x = 0.0, y = 0.0, i = 0;

		var height = size + padding;

		while (i < glyphs.length) {

			var c = glyphs.charAt(i++);
			var metrics = __context.measureText (c);
			var width = metrics.width + 4; // fudge because of incorrect text metrics

			if (x + width > __canvas.width) {

				y += height + 1;
				x = 0;

			}

			if (y + height > __canvas.height) {

				if (__canvas.width < __canvas.height) {

					__canvas.width *= 2;

				} else {

					__canvas.height *= 2;

				}

				__context.clearRect (0, 0, __canvas.width, __canvas.height);
				__context.textBaseline = "top";
				__context.textAlign = "left";
				__context.fillStyle = "#000000";
				__context.font = size + "px " + fontFace;

				glyphRects = new StringMap<GlyphRect>();
				x = y = i = 0;
				continue;

			}

			__context.fillText (c, x + 2, y);
			glyphRects.set(c, {
				x: x,
				y: y,
				xOffset: 0,
				yOffset: 0,
				advance: Std.int(width),
				width: width,
				height: height
			});

			x += width;

		}

		var image = new js.html.Image ();
		image.src = __canvas.toDataURL();
		return {
			glyphs: glyphRects,
			image: Image.fromImage (image)
		}

		#elseif flash

		var bd = new flash.display.BitmapData(128, 128, true, 0);
		var tf = new flash.text.TextField ();
		var format = new flash.text.TextFormat ();
		format.size = size;
		format.font = fontFace;
		tf.defaultTextFormat = format;
		// tf.embedFonts = true;
		var mat = new flash.geom.Matrix ();

		var i = 0, x = 0.0, y = 0.0, maxHeight = 0.0;

		while (i < glyphs.length) {

			var c = glyphs.charAt(i++);
			tf.text = c;

			if (x + tf.textWidth > bd.width) {

				y += maxHeight + 1;
				x = maxHeight = 0;

			}

			if (y + tf.textHeight > bd.height) {

				if (bd.width < bd.height) {

					bd = new flash.display.BitmapData(bd.width * 2, bd.height, true, 0);

				} else {

					bd = new flash.display.BitmapData(bd.width, bd.height * 2, true, 0);

				}

				glyphRects = new StringMap<GlyphRect>();
				x = y = maxHeight = i = 0;
				continue;

			}

			mat.identity ();
			mat.translate (x, y);
			bd.draw (tf, mat);

			glyphRects.set(c, {
				x: x,
				y: y,
				xOffset: 0,
				yOffset: 0,
				advance: Std.int(tf.textWidth + 2),
				width: tf.textWidth + 2,
				height: tf.textHeight + 2
			});

			x += tf.textWidth + 4;

			if (tf.textHeight + 4 > maxHeight) {

				maxHeight = tf.textHeight + 4;

			}

		}
		
		return {
			glyphs: glyphRects,
			image: Image.fromBitmapData (bd)
		}

		#elseif (cpp || neko)

		var data = lime_font_load_glyphs (handle, size, glyphs);

		if (data == null) {

			return null;

		} else {

			for (glyph in cast (data.glyphs, Array<Dynamic>)) {

				glyphRects.set (glyph.char, {
					x: glyph.x,
					y: glyph.y,
					xOffset: glyph.xOffset,
					yOffset: glyph.yOffset,
					advance: glyph.advance,
					width: glyph.width,
					height: glyph.height,
				});

			}
			
			return {
				glyphs: glyphRects,
				image: new Image (new ImageBuffer (new UInt8Array (data.image.data), data.image.width, data.image.height, data.image.bpp))
			};

		}

		#end

	}

	#if (cpp || neko)
	private static var lime_font_load = System.load ("lime", "lime_font_load", 1);
	private static var lime_font_load_glyphs = System.load ("lime", "lime_font_load_glyphs", 3);
	#end

}
