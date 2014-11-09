package lime;
#if !macro


import haxe.Json;
import haxe.Unserializer;
import lime.audio.AudioBuffer;
import lime.graphics.Font;
import lime.graphics.Image;
import lime.utils.ByteArray;

@:access(lime.AssetLibrary)


/**
 * <p>The Assets class provides a cross-platform interface to access 
 * embedded images, fonts, sounds and other resource files.</p>
 * 
 * <p>The contents are populated automatically when an application
 * is compiled using the OpenFL command-line tools, based on the
 * contents of the *.nmml project file.</p>
 * 
 * <p>For most platforms, the assets are included in the same directory
 * or package as the application, and the paths are handled
 * automatically. For web content, the assets are preloaded before
 * the start of the rest of the application. You can customize the 
 * preloader by extending the <code>NMEPreloader</code> class,
 * and specifying a custom preloader using <window preloader="" />
 * in the project file.</p>
 */
class Assets {
	
	
	public static var cache = new AssetCache ();
	public static var libraries (default, null) = new Map <String, AssetLibrary> ();
	
	private static var initialized = false;
	
	
	public static function exists (id:String, type:AssetType = null):Bool {
		
		initialize ();
		
		#if (tools && !display)
		
		if (type == null) {
			
			type = BINARY;
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			return library.exists (symbolName, cast type);
			
		}
		
		#end
		
		return false;
		
	}
	
	
	/**
	 * Gets an instance of an embedded sound
	 * @usage		var sound = Assets.getSound("sound.wav");
	 * @param	id		The ID or asset path for the sound
	 * @return		A new Sound object
	 */
	public static function getAudioBuffer (id:String, useCache:Bool = true):AudioBuffer {
		
		initialize ();
		
		#if (tools && !display)
		
		if (useCache && cache.enabled && cache.audio.exists (id)) {
			
			var audio = cache.audio.get (id);
			
			if (isValidAudio (audio)) {
				
				return audio;
				
			}
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.SOUND)) {
				
				if (library.isLocal (symbolName, cast AssetType.SOUND)) {
					
					var audio = library.getAudioBuffer (symbolName);
					
					if (useCache && cache.enabled) {
						
						cache.audio.set (id, audio);
						
					}
					
					return audio;
					
				} else {
					
					trace ("[Assets] Audio asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				trace ("[Assets] There is no audio asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded binary asset
	 * @usage		var bytes = Assets.getBytes("file.zip");
	 * @param	id		The ID or asset path for the file
	 * @return		A new ByteArray object
	 */
	public static function getBytes (id:String):ByteArray {
		
		initialize ();
		
		#if (tools && !display)
		
		var libraryName = id.substring (0, id.indexOf(":"));
		var symbolName = id.substr (id.indexOf(":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.BINARY)) {
				
				if (library.isLocal (symbolName, cast AssetType.BINARY)) {
					
					return library.getBytes (symbolName);
					
				} else {
					
					trace ("[Assets] String or ByteArray asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				trace ("[Assets] There is no String or ByteArray asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded font
	 * @usage		var fontName = Assets.getFont("font.ttf").fontName;
	 * @param	id		The ID or asset path for the font
	 * @return		A new Font object
	 */
	public static function getFont (id:String, useCache:Bool = true):Dynamic /*Font*/ {
		
		initialize ();
		
		#if (tools && !display)
		
		if (useCache && cache.enabled && cache.font.exists (id)) {
			
			return cache.font.get (id);
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.FONT)) {
				
				if (library.isLocal (symbolName, cast AssetType.FONT)) {
					
					var font = library.getFont (symbolName);
					
					if (useCache && cache.enabled) {
						
						cache.font.set (id, font);
						
					}
					
					return font;
					
				} else {
					
					trace ("[Assets] Font asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				trace ("[Assets] There is no Font asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded bitmap
	 * @usage		var bitmap = new Bitmap(Assets.getBitmapData("image.jpg"));
	 * @param	id		The ID or asset path for the bitmap
	 * @param	useCache		(Optional) Whether to use BitmapData from the cache(Default: true)
	 * @return		A new BitmapData object
	 */
	public static function getImage (id:String, useCache:Bool = true):Image {
		
		initialize ();
		
		#if (tools && !display)
		
		if (useCache && cache.enabled && cache.image.exists (id)) {
			
			var image = cache.image.get (id);
			
			if (isValidImage (image)) {
				
				return image;
				
			}
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.IMAGE)) {
				
				if (library.isLocal (symbolName, cast AssetType.IMAGE)) {
					
					var image = library.getImage (symbolName);
					
					if (useCache && cache.enabled) {
						
						cache.image.set (id, image);
						
					}
					
					return image;
					
				} else {
					
					trace ("[Assets] Image asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				trace ("[Assets] There is no Image asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	private static function getLibrary (name:String):AssetLibrary {
		
		if (name == null || name == "") {
			
			name = "default";
			
		}
		
		return libraries.get (name);
		
	}
	
	
	/**
	 * Gets an instance of an embedded streaming sound
	 * @usage		var sound = Assets.getMusic("sound.ogg");
	 * @param	id		The ID or asset path for the music track
	 * @return		A new Sound object
	 */
	/*public static function getMusic (id:String, useCache:Bool = true):Dynamic {
		
		initialize ();
		
		#if (tools && !display)
		
		if (useCache && cache.enabled && cache.sound.exists (id)) {
			
			var sound = cache.sound.get (id);
			
			if (isValidSound (sound)) {
				
				return sound;
				
			}
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.MUSIC)) {
				
				if (library.isLocal (symbolName, cast AssetType.MUSIC)) {
					
					var sound = library.getMusic (symbolName);
					
					if (useCache && cache.enabled) {
						
						cache.sound.set (id, sound);
						
					}
					
					return sound;
					
				} else {
					
					trace ("[Assets] Sound asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				trace ("[Assets] There is no Sound asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}*/
	
	
	/**
	 * Gets the file path (if available) for an asset
	 * @usage		var path = Assets.getPath("image.jpg");
	 * @param	id		The ID or asset path for the asset
	 * @return		The path to the asset (or null)
	 */
	public static function getPath (id:String):String {
		
		initialize ();
		
		#if (tools && !display)
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, null)) {
				
				return library.getPath (symbolName);
				
			} else {
				
				trace ("[Assets] There is no asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded text asset
	 * @usage		var text = Assets.getText("text.txt");
	 * @param	id		The ID or asset path for the file
	 * @return		A new String object
	 */
	public static function getText (id:String):String {
		
		initialize ();
		
		#if (tools && !display)
		
		var libraryName = id.substring (0, id.indexOf(":"));
		var symbolName = id.substr (id.indexOf(":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.TEXT)) {
				
				if (library.isLocal (symbolName, cast AssetType.TEXT)) {
					
					return library.getText (symbolName);
					
				} else {
					
					trace ("[Assets] String asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				trace ("[Assets] There is no String asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	private static function initialize ():Void {
		
		if (!initialized) {
			
			#if (tools && !display)
			
			registerLibrary ("default", new DefaultAssetLibrary ());
			
			#end
			
			initialized = true;
			
		}
		
	}
	
	
	public static function isLocal (id:String, type:AssetType = null, useCache:Bool = true):Bool {
		
		initialize ();
		
		#if (tools && !display)
		
		if (useCache && cache.enabled) {
			
			if (type == AssetType.IMAGE || type == null) {
				
				if (cache.image.exists (id)) return true;
				
			}
			
			if (type == AssetType.FONT || type == null) {
				
				if (cache.font.exists (id)) return true;
				
			}
			
			if (type == AssetType.SOUND || type == AssetType.MUSIC || type == null) {
				
				if (cache.audio.exists (id)) return true;
				
			}
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			return library.isLocal (symbolName, cast type);
			
		}
		
		#end
		
		return false;
		
	}
	
	
	private static function isValidAudio (buffer:AudioBuffer):Bool {
		
		#if (tools && !display)
		
		return (buffer != null);
		//return (sound.__handle != null && sound.__handle != 0);
		
		#end
		
		return true;
		
	}
	
	
	private static function isValidImage (buffer:Image):Bool {
		
		#if (tools && !display)
		#if (cpp || neko || nodejs)
		
		return (buffer != null);
		//return (bitmapData.__handle != null);
		
		#elseif flash
		
		/*try {
			
			image.bytes.width;
			
		} catch (e:Dynamic) {
			
			return false;
			
		}*/
		return (buffer != null);
		
		#end
		#end
		
		return true;
		
	}
	
	
	public static function list (type:AssetType = null):Array<String> {
		
		initialize ();
		
		var items = [];
		
		for (library in libraries) {
			
			var libraryItems = library.list (cast type);
			
			if (libraryItems != null) {
				
				items = items.concat (libraryItems);
				
			}
			
		}
		
		return items;
		
	}
	
	
	public static function loadAudioBuffer (id:String, handler:AudioBuffer -> Void, useCache:Bool = true):Void {
		
		initialize ();
		
		#if (tools && !display)
		
		if (useCache && cache.enabled && cache.audio.exists (id)) {
			
			var audio = cache.audio.get (id);
			
			if (isValidAudio (audio)) {
				
				handler (audio);
				return;
				
			}
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.SOUND)) {
				
				if (useCache && cache.enabled) {
					
					library.loadAudioBuffer (symbolName, function (audio:Dynamic):Void {
						
						cache.audio.set (id, audio);
						handler (audio);
						
					});
					
				} else {
					
					library.loadAudioBuffer (symbolName, handler);
					
				}
				
				return;
				
			} else {
				
				trace ("[Assets] There is no audio asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		handler (null);
		
	}
	
	
	public static function loadBytes (id:String, handler:ByteArray -> Void):Void {
		
		initialize ();
		
		#if (tools && !display)
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.BINARY)) {
				
				library.loadBytes (symbolName, handler);
				return;
				
			} else {
				
				trace ("[Assets] There is no String or ByteArray asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		handler (null);
		
	}
	
	
	public static function loadImage (id:String, handler:Image -> Void, useCache:Bool = true):Void {
		
		initialize ();
		
		#if (tools && !display)
		
		if (useCache && cache.enabled && cache.image.exists (id)) {
			
			var image = cache.image.get (id);
			
			if (isValidImage (image)) {
				
				handler (image);
				return;
				
			}
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.IMAGE)) {
				
				if (useCache && cache.enabled) {
					
					library.loadImage (symbolName, function (image:Image):Void {
						
						cache.image.set (id, image);
						handler (image);
						
					});
					
				} else {
					
					library.loadImage (symbolName, handler);
					
				}
				
				return;
				
			} else {
				
				trace ("[Assets] There is no Image asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		handler (null);
		
	}
	
	
	public static function loadLibrary (name:String, handler:AssetLibrary -> Void):Void {
		
		initialize();
		
		#if (tools && !display)
		
		var data = getText ("libraries/" + name + ".json");
		
		if (data != null && data != "") {
			
			var info = Json.parse (data);
			var library = Type.createInstance (Type.resolveClass (info.type), info.args);
			libraries.set (name, library);
			library.eventCallback = library_onEvent;
			library.load (handler);
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + name + "\"");
			
		}
		
		#end
		
	}
	
	
	/*public static function loadMusic (id:String, handler:Dynamic -> Void, useCache:Bool = true):Void {
		
		initialize ();
		
		#if (tools && !display)
		
		if (useCache && cache.enabled && cache.sound.exists (id)) {
			
			var sound = cache.sound.get (id);
			
			if (isValidSound (sound)) {
				
				handler (sound);
				return;
				
			}
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.MUSIC)) {
				
				if (useCache && cache.enabled) {
					
					library.loadMusic (symbolName, function (sound:Dynamic):Void {
						
						cache.sound.set (id, sound);
						handler (sound);
						
					});
					
				} else {
					
					library.loadMusic (symbolName, handler);
					
				}
				
				return;
				
			} else {
				
				trace ("[Assets] There is no Sound asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		handler (null);
		
	}*/
	
	
	public static function loadText (id:String, handler:String -> Void):Void {
		
		initialize ();
		
		#if (tools && !display)
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.TEXT)) {
				
				library.loadText (symbolName, handler);
				return;
				
			} else {
				
				trace ("[Assets] There is no String asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			trace ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		handler (null);
		
	}
	
	
	public static function registerLibrary (name:String, library:AssetLibrary):Void {
		
		if (libraries.exists (name)) {
			
			unloadLibrary (name);
			
		}
		
		if (library != null) {
			
			library.eventCallback = library_onEvent;
			
		}
		
		libraries.set (name, library);
		
	}
	
	
	public static function unloadLibrary (name:String):Void {
		
		initialize();
		
		#if (tools && !display)
		
		var library = libraries.get (name);
		
		if (library != null) {
			
			cache.clear (name + ":");
			library.eventCallback = null;
			
		}
		
		libraries.remove (name);
		
		#end
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private static function library_onEvent (library:AssetLibrary, type:String):Void {
		
		if (type == "change") {
			
			cache.clear ();
			//dispatchEvent (new Event (Event.CHANGE));
			
		}
		
	}
	
	
}


class AssetLibrary {
	
	
	public var eventCallback:Dynamic;
	
	
	public function new () {
		
		
		
	}
	
	
	public function exists (id:String, type:String):Bool {
		
		return false;
		
	}
	
	
	public function getAudioBuffer (id:String):AudioBuffer {
		
		return null;
		
	}
	
	
	public function getBytes (id:String):ByteArray {
		
		return null;
		
	}
	
	
	public function getFont (id:String):Dynamic /*Font*/ {
		
		return null;
		
	}
	
	
	public function getImage (id:String):Image {
		
		return null;
		
	}
	
	
	//public function getMusic (id:String):Dynamic /*Sound*/ {
		
	//	return getSound (id);
		
	//}
	
	
	public function getPath (id:String):String {
		
		return null;
		
	}
	
	
	public function getText (id:String):String {
		
		#if (tools && !display)
		
		var bytes = getBytes (id);
		
		if (bytes == null) {
			
			return null;
			
		} else {
			
			return bytes.readUTFBytes (bytes.length);
			
		}
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public function isLocal (id:String, type:String):Bool {
		
		return true;
		
	}
	
	
	public function list (type:String):Array<String> {
		
		return null;
		
	}
	
	
	private function load (handler:AssetLibrary -> Void):Void {
		
		handler (this);
		
	}
	
	
	public function loadAudioBuffer (id:String, handler:AudioBuffer -> Void):Void {
		
		handler (getAudioBuffer (id));
		
	}
	
	
	public function loadBytes (id:String, handler:ByteArray -> Void):Void {
		
		handler (getBytes (id));
		
	}
	
	
	public function loadFont (id:String, handler:Dynamic /*Font*/ -> Void):Void {
		
		handler (getFont (id));
		
	}
	
	
	public function loadImage (id:String, handler:Image -> Void):Void {
		
		handler (getImage (id));
		
	}
	
	
	//public function loadMusic (id:String, handler:Dynamic /*Sound*/ -> Void):Void {
		
	//	handler (getMusic (id));
		
	//}
	
	
	public function loadText (id:String, handler:String -> Void):Void {
		
		#if (tools && !display)
		
		var callback = function (bytes:ByteArray):Void {
			
			if (bytes == null) {
				
				handler (null);
				
			} else {
				
				handler (bytes.readUTFBytes (bytes.length));
				
			}
			
		}
		
		loadBytes (id, callback);
		
		#else
		
		handler (null);
		
		#end
		
	}
	
	
}


class AssetCache {
	
	
	public var audio:Map<String, AudioBuffer>;
	public var enabled:Bool = true;
	public var image:Map<String, Image>;
	public var font:Map<String, Dynamic /*Font*/>;
	
	
	public function new () {
		
		audio = new Map<String, AudioBuffer> ();
		font = new Map<String, Dynamic /*Font*/> ();
		image = new Map<String, Image> ();
		
	}
	
	
	public function clear (prefix:String = null):Void {
		
		if (prefix == null) {
			
			audio = new Map<String, AudioBuffer> ();
			font = new Map<String, Dynamic /*Font*/> ();
			image = new Map<String, Image> ();
			
		} else {
			
			var keys = audio.keys ();
			
			for (key in keys) {
				
				if (StringTools.startsWith (key, prefix)) {
					
					audio.remove (key);
					
				}
				
			}
			
			var keys = font.keys ();
			
			for (key in keys) {
				
				if (StringTools.startsWith (key, prefix)) {
					
					font.remove (key);
					
				}
				
			}
			
			var keys = image.keys ();
			
			for (key in keys) {
				
				if (StringTools.startsWith (key, prefix)) {
					
					image.remove (key);
					
				}
				
			}
			
		}
		
	}
	
	
}


@:enum abstract AssetType(String) {
	
	var BINARY = "BINARY";
	var FONT = "FONT";
	var IMAGE = "IMAGE";
	var MUSIC = "MUSIC";
	var SOUND = "SOUND";
	var TEMPLATE = "TEMPLATE";
	var TEXT = "TEXT";
	
}


#else


import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.Serializer;
import sys.io.File;


class Assets {
	
	
	private static var base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	private static var base64Encoder:BaseCode;
	
	
	private static function base64Encode (bytes:Bytes):String {
		
		var extension = switch (bytes.length % 3) {
			
			case 1: "==";
			case 2: "=";
			default: "";
			
		}
		
		if (base64Encoder == null) {
			
			base64Encoder = new BaseCode (Bytes.ofString (base64Chars));
			
		}
		
		return base64Encoder.encodeBytes (bytes).toString () + extension;
		
	}
	
	
	macro public static function embedBitmap ():Array<Field> {
		
		#if (html5 && !openfl_html5_dom)
		var fields = embedData (":bitmap", true);
		#else
		var fields = embedData (":bitmap");
		#end
		
		if (fields != null) {
			
			var constructor = macro { 
				
				#if html5
				#if openfl_html5_dom
				
				super (width, height, transparent, fillRGBA);
				
				var currentType = Type.getClass (this);
				
				if (preload != null) {
					
					___textureBuffer.width = Std.int (preload.width);
					___textureBuffer.height = Std.int (preload.height);
					rect = new openfl.geom.Rectangle (0, 0, preload.width, preload.height);
					setPixels(rect, preload.getPixels(rect));
					__buildLease();
					
				} else {
					
					var byteArray = openfl.utils.ByteArray.fromBytes (haxe.Resource.getBytes(resourceName));
					
					if (onload != null && !Std.is (onload, Bool)) {
						
						__loadFromBytes(byteArray, null, onload);
						
					} else {
						
						__loadFromBytes(byteArray);
						
					}
					
				}
				
				#else
				
				super (0, 0, transparent, fillRGBA);
				
				if (preload != null) {
					
					__sourceImage = preload;
					width = __sourceImage.width;
					height = __sourceImage.height;
					
				} else {
					
					__loadFromBase64 (haxe.Resource.getString(resourceName), resourceType, function (b) {
						
						if (preload == null) {
							
							preload = b.__sourceImage;
							
						}
						
						if (onload != null) {
							
							onload (b);
							
						}
						
					});
					
				}
				
				#end
				#else
				
				super (width, height, transparent, fillRGBA);
				
				var byteArray = openfl.utils.ByteArray.fromBytes (haxe.Resource.getBytes (resourceName));
				__loadFromBytes (byteArray);
				
				#end
				
			};
			
			var args = [ { name: "width", opt: false, type: macro :Int, value: null }, { name: "height", opt: false, type: macro :Int, value: null }, { name: "transparent", opt: true, type: macro :Bool, value: macro true }, { name: "fillRGBA", opt: true, type: macro :Int, value: macro 0xFFFFFFFF } ];
			
			#if html5
			args.push ({ name: "onload", opt: true, type: macro :Dynamic, value: null });
			#if openfl_html5_dom
			fields.push ({ kind: FVar(macro :openfl.display.BitmapData, null), name: "preload", doc: null, meta: [], access: [ APublic, AStatic ], pos: Context.currentPos() });
			#else
			fields.push ({ kind: FVar(macro :js.html.Image, null), name: "preload", doc: null, meta: [], access: [ APublic, AStatic ], pos: Context.currentPos() });
			#end
			#end
			
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos() });
			
		}
		
		return fields;
		
	}
	
	
	private static function embedData (metaName:String, encode:Bool = false):Array<Field> {
		
		var classType = Context.getLocalClass().get();
		var metaData = classType.meta.get();
		var position = Context.currentPos();
		var fields = Context.getBuildFields();
		
		for (meta in metaData) {
			
			if (meta.name == metaName) {
				
				if (meta.params.length > 0) {
					
					switch (meta.params[0].expr) {
						
						case EConst(CString(filePath)):
							
							var path = Context.resolvePath (filePath);
							var bytes = File.getBytes (path);
							var resourceName = "__ASSET__" + metaName + "_" + (classType.pack.length > 0 ? classType.pack.join ("_") + "_" : "") + classType.name;
							
							if (encode) {
								
								var resourceType = "image/png";
								
								if (bytes.get (0) == 0xFF && bytes.get (1) == 0xD8) {
									
									resourceType = "image/jpg";
									
								} else if (bytes.get (0) == 0x47 && bytes.get (1) == 0x49 && bytes.get (2) == 0x46) {
									
									resourceType = "image/gif";
									
								}
								
								var fieldValue = { pos: position, expr: EConst(CString(resourceType)) };
								fields.push ({ kind: FVar(macro :String, fieldValue), name: "resourceType", access: [ APrivate, AStatic ], pos: position });
								
								var base64 = base64Encode (bytes);
								Context.addResource (resourceName, Bytes.ofString (base64));
								
							} else {
								
								Context.addResource (resourceName, bytes);
								
							}
							
							var fieldValue = { pos: position, expr: EConst(CString(resourceName)) };
							fields.push ({ kind: FVar(macro :String, fieldValue), name: "resourceName", access: [ APrivate, AStatic ], pos: position });
							
							return fields;
							
						default:
						
					}
					
				}
				
			}
			
		}
		
		return null;
		
	}
	
	
	macro public static function embedFile ():Array<Field> {
		
		var fields = embedData (":file");
		
		if (fields != null) {
			
			var constructor = macro { 
				
				super();
				
				#if openfl_html5_dom
				nmeFromBytes (haxe.Resource.getBytes (resourceName));
				#else
				__fromBytes (haxe.Resource.getBytes (resourceName));
				#end
				
			};
			
			var args = [ { name: "size", opt: true, type: macro :Int, value: macro 0 } ];
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos() });
			
		}
		
		return fields;
		
	}
	
	
	macro public static function embedFont ():Array<Field> {
		
		var fields = null;
		
		var classType = Context.getLocalClass().get();
		var metaData = classType.meta.get();
		var position = Context.currentPos();
		var fields = Context.getBuildFields();
		
		var path = "";
		var glyphs = "32-255";
		
		for (meta in metaData) {
			
			if (meta.name == ":font") {
				
				if (meta.params.length > 0) {
					
					switch (meta.params[0].expr) {
						
						case EConst(CString(filePath)):
							
							path = Context.resolvePath (filePath);
							
						default:
						
					}
					
				}
				
			}
			
		}
		
		if (path != null && path != "") {
			
			#if html5
			Sys.command ("haxelib", [ "run", "openfl", "generate", "-font-hash", sys.FileSystem.fullPath(path) ]);
			path += ".hash";
			#end
			
			var bytes = File.getBytes (path);
			var resourceName = "LIME_font_" + (classType.pack.length > 0 ? classType.pack.join ("_") + "_" : "") + classType.name;
			
			Context.addResource (resourceName, bytes);
			
			var fieldValue = { pos: position, expr: EConst(CString(resourceName)) };
			fields.push ({ kind: FVar(macro :String, fieldValue), name: "resourceName", access: [ APublic, AStatic ], pos: position });
			
			var constructor = macro {
				
				super();
				
				fontName = resourceName;
				
			};
			
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: [], expr: constructor, params: [], ret: null }), pos: Context.currentPos() });
			
			return fields;
			
		}
		
		return fields;
		
	}
	
	
	macro public static function embedSound ():Array<Field> {
		
		var fields = embedData (":sound");
		
		if (fields != null) {
			
			#if (!html5) // CFFILoader.h(248) : NOT Implemented:api_buffer_data
			
			var constructor = macro { 
				
				super();
				
				var byteArray = openfl.utils.ByteArray.fromBytes (haxe.Resource.getBytes(resourceName));
				loadCompressedDataFromByteArray(byteArray, byteArray.length, forcePlayAsMusic);
				
			};
			
			var args = [ { name: "stream", opt: true, type: macro :openfl.net.URLRequest, value: null }, { name: "context", opt: true, type: macro :openfl.media.SoundLoaderContext, value: null }, { name: "forcePlayAsMusic", opt: true, type: macro :Bool, value: macro false } ];
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos() });
			
			#end
			
		}
		
		return fields;
		
	}
	
	
}


#end
