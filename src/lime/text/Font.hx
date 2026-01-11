package lime.text;

import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Future;
import lime.app.Promise;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.math.Vector2;
import lime.net.HTTPRequest;
import lime.system.CFFI;
import lime.system.System;
import lime.utils.Assets;
import lime.utils.Log;
import lime.utils.UInt8Array;
#if (js && html5)
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.SpanElement;
import js.Browser;
#end
#if (lime_cffi && !macro)
import haxe.io.Path;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
#if (!display && !flash && !nodejs && !macro)
@:autoBuild(lime._internal.macros.AssetsMacro.embedFont())
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.text.Glyph)
class Font
{
	/**
     	* The ascender value of the font.
     	*/
	public var ascender:Int;

	 /**
     	* The descender value of the font.
     	*/
	public var descender:Int;

	/**
     	* The height of the font.
     	*/
	public var height:Int;

	/**
     	* The name of the font.
    	 */
	public var name(default, null):String;

	/**
     	* The number of glyphs in the font.
     	*/
	public var numGlyphs:Int;


	public var src:Dynamic;

	/**
    	* The underline position of the font.
    	*/
	public var underlinePosition:Int;

	/**
    	* The underline thickness of the font.
    	*/
	public var underlineThickness:Int;

	/**
    	* The underline position of the font.
    	*/
	public var strikethroughPosition:Int;

	/**
    	* The underline thickness of the font.
    	*/
	public var strikethroughThickness:Int;

	/**
     	* The units per EM of the font.
     	*/
	public var unitsPerEM:Int;

	@:noCompletion private var __fontID:String;
	@:noCompletion private var __fontPath:String;
	#if lime_cffi
	@:noCompletion private var __fontPathWithoutDirectory:String;
	#end
	@:noCompletion private var __init:Bool;

	/**
     	* Creates a new instance of a Font object.
     	*
     	* @param name Optional name of the font.
     	*/
	public function new(name:String = null)
	{
		if (name != null)
		{
			this.name = name;
		}

		if (!__init)
		{
			#if js if (ascender == untyped #if haxe4 js.Syntax.code #else __js__ #end ("undefined")) #end ascender = 0;
			#if js
			if (descender == untyped #if haxe4 js.Syntax.code #else __js__ #end ("undefined"))
			#end
			descender = 0;
			#if js
			if (height == untyped #if haxe4 js.Syntax.code #else __js__ #end ("undefined"))
			#end
			height = 0;
			#if js
			if (numGlyphs == untyped #if haxe4 js.Syntax.code #else __js__ #end ("undefined"))
			#end
			numGlyphs = 0;
			#if js
			if (underlinePosition == untyped #if haxe4 js.Syntax.code #else __js__ #end ("undefined"))
			#end
			underlinePosition = 0;
			#if js
			if (underlineThickness == untyped #if haxe4 js.Syntax.code #else __js__ #end ("undefined"))
			#end
			underlineThickness = 0;
			#if js
			if (unitsPerEM == untyped #if haxe4 js.Syntax.code #else __js__ #end ("undefined"))
			#end
			unitsPerEM = 0;

			if (__fontID != null)
			{
				if (Assets.isLocal(__fontID))
				{
					__fromBytes(Assets.getBytes(__fontID));
				}
			}
			else if (__fontPath != null)
			{
				__fromFile(__fontPath);
			}
		}
	}

	/**
     	* Decomposes the font into outline data.
     	*
     	* @return An instance of `NativeFontData` that contains decomposed font outline information.
     	*/
	public function decompose():NativeFontData
	{
		#if (lime_cffi && !macro)
		if (src == null) throw "Uninitialized font handle.";
		var data:Dynamic = NativeCFFI.lime_font_outline_decompose(src, 1024 * 20);
		#if hl
		if (data != null)
		{
			data.family_name = @:privateAccess String.fromUCS2(data.family_name);
			data.style_name = @:privateAccess String.fromUTF8(data.style_name);
		}
		#end
		return data;
		#else
		return null;
		#end
	}

	/**
     	* Creates a Font instance from byte data.
     	*
     	* @param bytes The byte data containing the font.
     	* @return A `Font` instance.
     	*/
	public static function fromBytes(bytes:Bytes):Font
	{
		if (bytes == null) return null;

		var font = new Font();
		font.__fromBytes(bytes);

		#if (lime_cffi && !macro)
		return (font.src != null) ? font : null;
		#else
		return font;
		#end
	}

	/**
     	* Creates a Font instance from a file path.
     	*
     	* @param path The file path of the font.
     	* @return A `Font` instance.
     	*/
	public static function fromFile(path:String):Font
	{
		if (path == null) return null;

		var font = new Font();
		font.__fromFile(path);

		#if (lime_cffi && !macro)
		return (font.src != null) ? font : null;
		#else
		return font;
		#end
	}

	/**
     	* Loads a Font from byte data asynchronously.
     	*
     	* @param bytes The byte data containing the font.
     	* @return A `Future` containing a `Font` instance.
     	*/
	public static function loadFromBytes(bytes:Bytes):Future<Font>
	{
		return Future.withValue(fromBytes(bytes));
	}

	/**
     	* Loads a Font from a file path asynchronously.
     	*
     	* @param path The file path of the font.
     	* @return A `Future` containing a `Font` instance.
     	*/
	public static function loadFromFile(path:String):Future<Font>
	{
		var request = new HTTPRequest<Font>();
		return request.load(path).then(function(font)
		{
			if (font != null)
			{
				return Future.withValue(font);
			}
			else
			{
				return cast Future.withError("");
			}
		});
	}

	/**
     	* Loads a Font by its name asynchronously.
     	*
     	* @param path The name of the font.
     	* @return A `Future` containing a `Font` instance.
     	*/
	public static function loadFromName(path:String):Future<Font>
	{
		#if (js && html5)
		var font = new Font();
		return font.__loadFromName(path);
		#else
		return cast Future.withError("");
		#end
	}

	/**
     	* Retrieves a glyph from the font by a character.
     	*
     	* @param character The character whose glyph to retrieve.
     	* @return A `Glyph` instance representing the glyph of the character.
     	*/
	public function getGlyph(character:String):Glyph
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_font_get_glyph_index(src, character);
		#else
		return -1;
		#end
	}

	/**
     	* Retrieves an array of glyphs for a set of characters.
     	*
     	* @param characters The string containing characters to retrieve glyphs for.
     	* @return An array of `Glyph` instances representing the glyphs of the characters.
     	*/
	public function getGlyphs(characters:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^`'\"/\\&*()[]{}<>|:;_-+=?,. "):Array<Glyph>
	{
		#if (lime_cffi && !macro)
		#if hl
		return [for (index in NativeCFFI.lime_font_get_glyph_indices(src, characters)) new Glyph(index)];
		#else
		return NativeCFFI.lime_font_get_glyph_indices(src, characters);
		#end
		#else
		return null;
		#end
	}

	/**
     	* Retrieves metrics for a given glyph.
     	*
     	* @param glyph The glyph whose metrics to retrieve.
     	* @return A `GlyphMetrics` instance containing the metrics of the glyph.
     	*/
	public function getGlyphMetrics(glyph:Glyph):GlyphMetrics
	{
		#if (lime_cffi && !macro)
		var value:Dynamic = NativeCFFI.lime_font_get_glyph_metrics(src, glyph);
		var metrics = new GlyphMetrics();

		metrics.advance = new Vector2(value.horizontalAdvance, value.verticalAdvance);
		metrics.height = value.height;
		metrics.horizontalBearing = new Vector2(value.horizontalBearingX, value.horizontalBearingY);
		metrics.verticalBearing = new Vector2(value.verticalBearingX, value.verticalBearingY);

		return metrics;
		#else
		return null;
		#end
	}

	/**
     	* Renders a specific glyph to an image.
     	*
     	* @param glyph The glyph to render.
     	* @param fontSize The size to render the glyph at.
     	* @return An `Image` instance representing the rendered glyph.
     	*/
	public function renderGlyph(glyph:Glyph, fontSize:Int):Image
	{
		#if (lime_cffi && !macro)
		__setSize(fontSize, 96);

		// Allocate an estimated buffer size - adjust if necessary
		var bytes:Bytes = Bytes.alloc(0); // Allocate some reasonable initial size

		// Call native function to render glyph and get byte data
		bytes = NativeCFFI.lime_font_render_glyph(src, glyph, bytes);

		if (bytes != null && bytes.length > 0)
		{
			var dataPosition = 0;

			// Extract glyph information from the byte array
			var index:Int = bytes.getInt32(dataPosition);
			dataPosition += 4;

			var width:Int = bytes.getInt32(dataPosition);
			dataPosition += 4;

			var height:Int = bytes.getInt32(dataPosition);
			dataPosition += 4;

			var x:Int = bytes.getInt32(dataPosition);
			dataPosition += 4;

			var y:Int = bytes.getInt32(dataPosition);
			dataPosition += 4;

			// Check if width and height are valid before proceeding
			if (width <= 0 || height <= 0)
			{
				return null;
			}

			// Extract pixel data from the byte array, accounting for 32-bit RGBA data
			var pitch = width * 4; // 32-bit color data

			// Create a new Bytes array to store the extracted bitmap data without padding
			var dataBytes = Bytes.alloc(width * height * 4);

			// Extract row by row to handle RGBA data
			for (i in 0...height)
			{
				dataBytes.blit(i * width * 4, bytes, dataPosition + (i * pitch), width * 4);
			}

			// Create ImageBuffer and Image from the extracted data
			var buffer = new ImageBuffer(new UInt8Array(dataBytes), width, height, 32);
			var image = new Image(buffer, 0, 0, width, height);
			image.x = x;
			image.y = y;

			return image;
		}
		#end

		return null;
	}
	/**
     	* Renders a set of glyphs to images.
     	*
     	* @param glyphs The glyphs to render.
     	* @param fontSize The size to render the glyphs at.
     	* @return A `Map` containing glyphs mapped to their corresponding images.
     	*/
	public function renderGlyphs(glyphs:Array<Glyph>, fontSize:Int):Map<Glyph, Image>
	{
		#if (lime_cffi && !macro)
		var uniqueGlyphs = new Map<Int, Bool>();

		for (glyph in glyphs)
		{
			uniqueGlyphs.set(glyph, true);
		}

		var glyphList = [];

		for (key in uniqueGlyphs.keys())
		{
			glyphList.push(key);
		}

		#if hl
		var _glyphList = new hl.NativeArray<Glyph>(glyphList.length);

		for (i in 0...glyphList.length)
		{
			_glyphList[i] = glyphList[i];
		}

		var glyphList = _glyphList;
		#end

		__setSize(fontSize, 96);

		var bytes = Bytes.alloc(0);
		bytes = NativeCFFI.lime_font_render_glyphs(src, glyphList, bytes);

		if (bytes != null && bytes.length > 0)
		{
			var bytesPosition = 0;
			var count = bytes.getInt32(bytesPosition);
			bytesPosition += 4;

			var bufferWidth = 128;
			var bufferHeight = 128;
			var offsetX = 0;
			var offsetY = 0;
			var maxRows = 0;

			var width:Int;
			var height:Int;
			var i = 0;

			while (i < count)
			{
				bytesPosition += 4;
				width = bytes.getInt32(bytesPosition);
				bytesPosition += 4;
				height = bytes.getInt32(bytesPosition);
				bytesPosition += 4;

				bytesPosition += (4 * 2) + width * height;

				if (offsetX + width > bufferWidth)
				{
					offsetY += maxRows + 1;
					offsetX = 0;
					maxRows = 0;
				}

				if (offsetY + height > bufferHeight)
				{
					if (bufferWidth < bufferHeight)
					{
						bufferWidth *= 2;
					}
					else
					{
						bufferHeight *= 2;
					}

					offsetX = 0;
					offsetY = 0;
					maxRows = 0;

					// TODO: make this better

					bytesPosition = 4;
					i = 0;
					continue;
				}

				offsetX += width + 1;

				if (height > maxRows)
				{
					maxRows = height;
				}

				i++;
			}

			var map = new Map<Int, Image>();
			var buffer = new ImageBuffer(null, bufferWidth, bufferHeight, 8);
			var dataPosition = 0;
			var data = Bytes.alloc(bufferWidth * bufferHeight);

			bytesPosition = 4;
			offsetX = 0;
			offsetY = 0;
			maxRows = 0;

			var index:Int;
			var x:Int;
			var y:Int;
			var image:Image;

			for (i in 0...count)
			{
				index = bytes.getInt32(bytesPosition);
				bytesPosition += 4;
				width = bytes.getInt32(bytesPosition);
				bytesPosition += 4;
				height = bytes.getInt32(bytesPosition);
				bytesPosition += 4;
				x = bytes.getInt32(bytesPosition);
				bytesPosition += 4;
				y = bytes.getInt32(bytesPosition);
				bytesPosition += 4;

				if (offsetX + width > bufferWidth)
				{
					offsetY += maxRows + 1;
					offsetX = 0;
					maxRows = 0;
				}

				for (i in 0...height)
				{
					dataPosition = ((i + offsetY) * bufferWidth) + offsetX;
					data.blit(dataPosition, bytes, bytesPosition, width);
					bytesPosition += width;
				}

				image = new Image(buffer, offsetX, offsetY, width, height);
				image.x = x;
				image.y = y;

				map.set(index, image);

				offsetX += width + 1;

				if (height > maxRows)
				{
					maxRows = height;
				}
			}

			#if js
			buffer.data = data.byteView;
			#else
			buffer.data = new UInt8Array(data);
			#end

			return map;
		}
		#end

		return null;
	}

	@:noCompletion private function __copyFrom(other:Font):Void
	{
		if (other != null)
		{
			ascender = other.ascender;
			descender = other.descender;
			height = other.height;
			name = other.name;
			numGlyphs = other.numGlyphs;
			src = other.src;
			underlinePosition = other.underlinePosition;
			underlineThickness = other.underlineThickness;
			unitsPerEM = other.unitsPerEM;

			__fontID = other.__fontID;
			__fontPath = other.__fontPath;

			#if lime_cffi
			__fontPathWithoutDirectory = other.__fontPathWithoutDirectory;
			#end

			__init = true;
		}
	}

	@:noCompletion private function __fromBytes(bytes:Bytes):Void
	{
		__fontPath = null;

		#if (lime_cffi && !macro)
		__fontPathWithoutDirectory = null;

		src = NativeCFFI.lime_font_load_bytes(bytes);

		__initializeSource();
		#end
	}

	@:noCompletion private function __fromFile(path:String):Void
	{
		__fontPath = path;

		#if (lime_cffi && !macro)
		__fontPathWithoutDirectory = Path.withoutDirectory(__fontPath);

		src = NativeCFFI.lime_font_load_file(__fontPath);

		__initializeSource();
		#end
	}

	@:noCompletion private function __initializeSource():Void
	{
		#if (lime_cffi && !macro)
		if (src != null)
		{
			if (name == null)
			{
				name = CFFI.stringValue(cast NativeCFFI.lime_font_get_family_name(src));
			}

			ascender = NativeCFFI.lime_font_get_ascender(src);
			descender = NativeCFFI.lime_font_get_descender(src);
			height = NativeCFFI.lime_font_get_height(src);
			numGlyphs = NativeCFFI.lime_font_get_num_glyphs(src);
			underlinePosition = NativeCFFI.lime_font_get_underline_position(src);
			underlineThickness = NativeCFFI.lime_font_get_underline_thickness(src);
			strikethroughPosition = NativeCFFI.lime_font_get_strikethrough_position(src);
			strikethroughThickness = NativeCFFI.lime_font_get_strikethrough_thickness(src);
			unitsPerEM = NativeCFFI.lime_font_get_units_per_em(src);
		}
		#end

		__init = true;
	}

	@:noCompletion private function __loadFromName(name:String):Future<Font>
	{
		var promise = new Promise<Font>();

		#if (js && html5)
		this.name = name;

		var userAgent = Browser.navigator.userAgent.toLowerCase();
		var isSafari = (userAgent.indexOf(" safari/") >= 0 && userAgent.indexOf(" chrome/") < 0);
		var isUIWebView = ~/(iPhone|iPod|iPad).*AppleWebKit(?!.*Version)/i.match(userAgent);

		if (!isSafari && !isUIWebView && untyped (Browser.document).fonts && untyped (Browser.document).fonts.load)
		{
			untyped (Browser.document).fonts.load("1em '" + name + "'").then(function(_)
			{
				promise.complete(this);
			}, function(_)
			{
				Log.warn("Could not load web font \"" + name + "\"");
				promise.complete(this);
			});
		}
		else
		{
			var node1 = __measureFontNode("'" + name + "', sans-serif");
			var node2 = __measureFontNode("'" + name + "', serif");

			var width1 = node1.offsetWidth;
			var width2 = node2.offsetWidth;

			var interval = -1;
			var timeout = 3000;
			var intervalLength = 50;
			var intervalCount = 0;
			var loaded:Bool;
			var timeExpired:Bool;

			var checkFont = function()
			{
				intervalCount++;

				loaded = (node1.offsetWidth != width1 || node2.offsetWidth != width2);
				timeExpired = (intervalCount * intervalLength >= timeout);

				if (loaded || timeExpired)
				{
					Browser.window.clearInterval(interval);
					node1.parentNode.removeChild(node1);
					node2.parentNode.removeChild(node2);
					node1 = null;
					node2 = null;

					if (timeExpired)
					{
						Log.warn("Could not load web font \"" + name + "\"");
					}

					promise.complete(this);
				}
			}

			interval = Browser.window.setInterval(checkFont, intervalLength);
		}
		#else
		promise.error("");
		#end

		return promise.future;
	}

	#if (js && html5)
	private static function __measureFontNode(fontFamily:String):SpanElement
	{
		var node:SpanElement = cast Browser.document.createElement("span");
		node.setAttribute("aria-hidden", "true");
		var text = Browser.document.createTextNode("BESbswy");
		node.appendChild(text);
		var style = node.style;
		style.display = "block";
		style.position = "absolute";
		style.top = "-9999px";
		style.left = "-9999px";
		style.fontSize = "300px";
		style.width = "auto";
		style.height = "auto";
		style.lineHeight = "normal";
		style.margin = "0";
		style.padding = "0";
		style.fontVariant = "normal";
		style.whiteSpace = "nowrap";
		style.fontFamily = fontFamily;
		Browser.document.body.appendChild(node);
		return node;
	}
	#end

	@:noCompletion private function __setSize(size:Int, dpi:Int = 72):Void
	{
		#if (lime_cffi && !macro)
		NativeCFFI.lime_font_set_size(src, size, dpi);
		#end
	}
}

/**
* Represents decomposed font data, containing kerning information, glyphs, and other properties.
*/
typedef NativeFontData =
{
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

/**
* Represents data for an individual glyph, including dimensions and control points.
*/
typedef NativeGlyphData =
{
	var char_code:Int;
	var advance:Int;
	var min_x:Int;
	var max_x:Int;
	var min_y:Int;
	var max_y:Int;
	var points:Array<Int>;
}

/**
* Represents kerning information between two glyphs.
*/
typedef NativeKerningData =
{
	var left_glyph:Int;
	var right_glyph:Int;
	var x:Int;
	var y:Int;
}
