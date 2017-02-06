package lime; #if (!lime_legacy || lime_hybrid)


#if !macro


import haxe.Json;
import haxe.Unserializer;
import lime.app.Event;
import lime.app.Promise;
import lime.app.Future;
import lime.audio.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;

/**
 * <p>The Assets class provides a cross-platform interface to access 
 * embedded images, fonts, sounds and other resource files.</p>
 * 
 * <p>The contents are populated automatically when an application
 * is compiled using the Lime command-line tools, based on the
 * contents of the *.xml project file.</p>
 * 
 * <p>For most platforms, the assets are included in the same directory
 * or package as the application, and the paths are handled
 * automatically. For web content, the assets are preloaded before
 * the start of the rest of the application. You can customize the 
 * preloader by extending the <code>NMEPreloader</code> class,
 * and specifying a custom preloader using <window preloader="" />
 * in the project file.</p>
 */

@:access(lime.AssetLibrary)


class Assets {
	
	
	public static var cache = new AssetCache ();
	public static var libraries (default, null) = new Map <String, AssetLibrary> ();
	public static var onChange = new Event<Void->Void> ();
	
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
	 * @return		A new Bytes object
	 */
	public static function getBytes (id:String):Bytes {
		
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
					
					trace ("[Assets] String or Bytes asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				trace ("[Assets] There is no String or Bytes asset with an ID of \"" + id + "\"");
				
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
	public static function getFont (id:String, useCache:Bool = true):Font {
		
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
		
		#else
		
		return true;
		
		#end
		
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
	
	
	public static function loadAudioBuffer (id:String, useCache:Bool = true):Future<AudioBuffer> {
		
		initialize ();
		
		var promise = new Promise<AudioBuffer> ();
		
		#if (tools && !display)
		
		if (useCache && cache.enabled && cache.audio.exists (id)) {
			
			var audio = cache.audio.get (id);
			
			if (isValidAudio (audio)) {
				
				promise.complete (audio);
				return promise.future;
				
			}
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.SOUND)) {
				
				var future = library.loadAudioBuffer (symbolName);
				
				if (useCache && cache.enabled) {
					
					future.onComplete (function (audio) cache.audio.set (id, audio));
					
				}
				
				promise.completeWith (future);
				
			} else {
				
				promise.error ("[Assets] There is no audio asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			promise.error ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return promise.future;
		
	}
	
	
	public static function loadBytes (id:String):Future<Bytes> {
		
		initialize ();
		
		var promise = new Promise<Bytes> ();
		
		#if (tools && !display)
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.BINARY)) {
				
				promise.completeWith (library.loadBytes (symbolName));
				
			} else {
				
				promise.error ("[Assets] There is no String or Bytes asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			promise.error ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return promise.future;
		
	}
	
	
	public static function loadFont (id:String):Future<Font> {
		
		initialize ();
		
		var promise = new Promise<Font> ();
		
		#if (tools && !display)
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.FONT)) {
				
				promise.completeWith (library.loadFont (symbolName));
				
			} else {
				
				promise.error ("[Assets] There is no Font asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			promise.error ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return promise.future;
		
	}
	
	
	public static function loadImage (id:String, useCache:Bool = true):Future<Image> {
		
		initialize ();
		
		var promise = new Promise<Image> ();
		
		#if (tools && !display)
		
		if (useCache && cache.enabled && cache.image.exists (id)) {
			
			var image = cache.image.get (id);
			
			if (isValidImage (image)) {
				
				promise.complete (image);
				return promise.future;
				
			}
			
		}
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.IMAGE)) {
				
				var future = library.loadImage (symbolName);
				
				if (useCache && cache.enabled) {
					
					future.onComplete (function (image) cache.image.set (id, image));
					
				}
				
				promise.completeWith (future);
				
			} else {
				
				promise.error ("[Assets] There is no Image asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			promise.error ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return promise.future;
		
	}
	
	
	public static function loadLibrary (name:String):Future<AssetLibrary> {
		
		initialize ();
		
		var promise = new Promise<AssetLibrary> ();
		
		#if (tools && !display)
		
		var data = getText ("libraries/" + name + ".json");
		
		if (data != null && data != "") {
			
			var info = Json.parse (data);
			var library = Type.createInstance (Type.resolveClass (info.type), info.args);
			libraries.set (name, library);
			library.onChange.add (onChange.dispatch);
			promise.completeWith (library.load ());
			
		} else {
			
			promise.error ("[Assets] There is no asset library named \"" + name + "\"");
			
		}
		
		#end
		
		return promise.future;
		
	}
	
	
	public static function loadText (id:String):Future<String> {
		
		initialize ();
		
		var promise = new Promise<String> ();
		
		#if (tools && !display)
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.TEXT)) {
				
				promise.completeWith (library.loadText (symbolName));
				
			} else {
				
				promise.error ("[Assets] There is no String asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			promise.error ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return promise.future;
		
	}
	
	
	public static function registerLibrary (name:String, library:AssetLibrary):Void {
		
		if (libraries.exists (name)) {
			
			if (libraries.get (name) == library) {
				
				return;
				
			} else {
				
				unloadLibrary (name);
				
			}
			
		}
		
		if (library != null) {
			
			library.onChange.add (library_onChange);
			
		}
		
		libraries.set (name, library);
		
	}
	
	
	public static function unloadLibrary (name:String):Void {
		
		initialize();
		
		#if (tools && !display)
		
		var library = libraries.get (name);
		
		if (library != null) {
			
			cache.clear (name + ":");
			library.onChange.remove (library_onChange);
			library.unload ();
			
		}
		
		libraries.remove (name);
		
		#end
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private static function library_onChange ():Void {
		
		cache.clear ();
		onChange.dispatch ();
		
	}
	
	
}


class AssetLibrary {
	
	
	public var onChange = new Event<Void->Void> ();
	
	
	public function new () {
		
		
		
	}
	
	
	public function exists (id:String, type:String):Bool {
		
		return false;
		
	}
	
	
	public function getAudioBuffer (id:String):AudioBuffer {
		
		return null;
		
	}
	
	
	public function getBytes (id:String):Bytes {
		
		return null;
		
	}
	
	
	public function getFont (id:String):Font {
		
		return null;
		
	}
	
	
	public function getImage (id:String):Image {
		
		return null;
		
	}
	
	
	public function getPath (id:String):String {
		
		return null;
		
	}
	
	
	public function getText (id:String):String {
		
		#if (tools && !display)
		
		var bytes = getBytes (id);
		
		if (bytes == null) {
			
			return null;
			
		} else {
			
			return bytes.getString (0, bytes.length);
			
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
	
	
	private function load ():Future<AssetLibrary> {
		
		return new Future<AssetLibrary> (function () return this);
		
	}
	
	
	public function loadAudioBuffer (id:String):Future<AudioBuffer> {
		
		return new Future<AudioBuffer> (function () return getAudioBuffer (id));
		
	}
	
	
	public function loadBytes (id:String):Future<Bytes> {
		
		return new Future<Bytes> (function () return getBytes (id));
		
	}
	
	
	public function loadFont (id:String):Future<Font> {
		
		return new Future<Font> (function () return getFont (id));
		
	}
	
	
	public function loadImage (id:String):Future<Image> {
		
		return new Future<Image> (function () return getImage (id));
		
	}
	
	
	public function loadText (id:String):Future<String> {
		
		return loadBytes (id).then (function (bytes) {
			
			return new Future<String> (function () {
				
				if (bytes == null) {
					
					return null;
					
				} else {
					
					return bytes.getString (0, bytes.length);
					
				}
				
			});
			
		});
		
	}
	
	
	public function unload ():Void {
		
		
		
	}
	
	
}


class AssetCache {
	
	
	public var audio:Map<String, AudioBuffer>;
	public var enabled:Bool = true;
	public var image:Map<String, Image>;
	public var font:Map<String, Dynamic /*Font*/>;
	public var version:Int;
	
	
	public function new () {
		
		audio = new Map<String, AudioBuffer> ();
		font = new Map<String, Dynamic /*Font*/> ();
		image = new Map<String, Image> ();
		version = Std.int (Math.random () * 1000000);
		
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


#else


import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.Serializer;
import lime.graphics.ImageBuffer;
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
	
	
	macro public static function embedBytes ():Array<Field> {
		
		var fields = embedData (":file");
		
		#if lime_console
		if (false) {
		#else
		if (fields != null) {
		#end
			
			var constructor = macro {
				
				var bytes = haxe.Resource.getBytes (resourceName);
				
				super (bytes.length, bytes.b);
				
			};
			
			var args = [ { name: "length", opt: false, type: macro :Int }, { name: "bytesData", opt: false, type: macro :haxe.io.BytesData } ];
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos () });
			
		}
		
		return fields;
		
	}
	
	
	macro public static function embedByteArray ():Array<Field> {
		
		var fields = embedData (":file");
		
		#if lime_console
		if (false) {
		#else
		if (fields != null) {
		#end
			
			var constructor = macro {
				
				super ();
				
				var bytes = haxe.Resource.getBytes (resourceName);
				__fromBytes (bytes);
				
			};
			
			var args = [ { name: "length", opt: true, type: macro :Int, value: macro 0 } ];
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos () });
			
		}
		
		return fields;
		
	}
	
	
	#if lime_console
	
	private static function embedData (metaName:String, encode:Bool = false):Array<Field> {
		
		var classType = Context.getLocalClass().get();
		var metaData = classType.meta.get();
		var position = Context.currentPos();
		var fields = Context.getBuildFields();
		
		for (meta in metaData) {
			
			if (meta.name != metaName || meta.params.length <= 0) {
				continue;
			}
				
			switch (meta.params[0].expr) {
				
				case EConst(CString(filePath)):
					
					var fieldValue = {
						pos: position,
						expr: EConst(CString(filePath))
					};
					fields.push ({
						kind: FVar(macro :String, fieldValue),
						name: "filePath",
						access: [ APrivate, AStatic ],
						pos: position
					});
					
					return fields;
					
				default:
				
			}
			
		}
		
		return null;
		
	}

	#else
	
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

							if( filePath == "" ){
								continue;
							}

							var path = filePath;
							if (!sys.FileSystem.exists(filePath)) {
								path = Context.resolvePath (filePath);
							}
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

	#end
	
	
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
							
							path = filePath;
							
							if (!sys.FileSystem.exists(filePath)) {
								
								path = Context.resolvePath (filePath);
								
							}
							
						default:
						
					}
					
				}
				
			}
			
		}
		
		if (path != null && path != "") {
			
			#if html5
			Sys.command ("haxelib", [ "run", "lime", "generate", "-font-hash", sys.FileSystem.fullPath(path) ]);
			path += ".hash";
			#end
			
			var bytes = File.getBytes (path);
			var resourceName = "LIME_font_" + (classType.pack.length > 0 ? classType.pack.join ("_") + "_" : "") + classType.name;
			
			Context.addResource (resourceName, bytes);
			
			for (field in fields) {
				
				if (field.name == "new") {
					
					fields.remove (field);
					break;
					
				}
				
			}
			
			var fieldValue = { pos: position, expr: EConst(CString(resourceName)) };
			fields.push ({ kind: FVar(macro :String, fieldValue), name: "resourceName", access: [ APublic, AStatic ], pos: position });
			
			var constructor = macro {
				
				super ();
				
				__fromBytes (haxe.Resource.getBytes (resourceName));
				
			};
			
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: [], expr: constructor, params: [], ret: null }), pos: Context.currentPos() });
			
			return fields;
			
		}
		
		return fields;
		
	}
	
	
	macro public static function embedImage ():Array<Field> {
		
		#if html5
		var fields = embedData (":image", true);
		#else
		var fields = embedData (":image");
		#end
		
		if (fields != null) {
			
			var constructor = macro { 
				
				#if html5
				
				super ();
				
				if (preload != null) {
					
					var buffer = new lime.graphics.ImageBuffer ();
					buffer.__srcImage = preload;
					buffer.width = preload.width;
					buffer.width = preload.height;
					
					__fromImageBuffer (buffer);
					
				} else {
					
					__fromBase64 (haxe.Resource.getString (resourceName), resourceType, function (image) {
						
						if (preload == null) {
							
							preload = image.buffer.__srcImage;
							
						}
						
						if (onload != null) {
							
							onload (image);
							
						}
						
					});
					
				}
				
				#else
				
				super ();
				
				#if lime_console
				throw "not implemented";
				#else
				__fromBytes (haxe.Resource.getBytes (resourceName), null);
				#end
				
				#end
				
			};
			
			var args = [ { name: "buffer", opt: true, type: macro :lime.graphics.ImageBuffer, value: null }, { name: "offsetX", opt: true, type: macro :Int, value: null }, { name: "offsetY", opt: true, type: macro :Int, value: null }, { name: "width", opt: true, type: macro :Int, value: null }, { name: "height", opt: true, type: macro :Int, value: null }, { name: "color", opt: true, type: macro :Null<Int>, value: null }, { name: "type", opt: true, type: macro :lime.graphics.ImageType, value: null } ];
			
			#if html5
			args.push ({ name: "onload", opt: true, type: macro :Dynamic, value: null });
			fields.push ({ kind: FVar(macro :js.html.Image, null), name: "preload", doc: null, meta: [], access: [ APublic, AStatic ], pos: Context.currentPos() });
			#end
			
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos() });
			
		}
		
		return fields;
		
	}
	
	
	macro public static function embedSound ():Array<Field> {
		
		var fields = embedData (":sound");
		
		if (fields != null) {
			
			#if (openfl && !html5) // CFFILoader.h(248) : NOT Implemented:api_buffer_data
			
			var constructor = macro { 
				
				super();
				
				#if lime_console
				throw "not implemented";
				#else
				var byteArray = openfl.utils.ByteArray.fromBytes (haxe.Resource.getBytes(resourceName));
				loadCompressedDataFromByteArray(byteArray, byteArray.length, forcePlayAsMusic);
				#end
				
			};
			
			var args = [ { name: "stream", opt: true, type: macro :openfl.net.URLRequest, value: null }, { name: "context", opt: true, type: macro :openfl.media.SoundLoaderContext, value: null }, { name: "forcePlayAsMusic", opt: true, type: macro :Bool, value: macro false } ];
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos() });
			
			#end
			
		}
		
		return fields;
		
	}
	
	
}


#end
#end


@:enum abstract AssetType(String) {
	
	var BINARY = "BINARY";
	var FONT = "FONT";
	var IMAGE = "IMAGE";
	var MUSIC = "MUSIC";
	var SOUND = "SOUND";
	var TEMPLATE = "TEMPLATE";
	var TEXT = "TEXT";
	
}
