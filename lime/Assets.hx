package lime;


#if !macro


import haxe.CallStack;
import haxe.Json;
import haxe.Unserializer;
import lime.app.Event;
import lime.app.Promise;
import lime.app.Future;
import lime.audio.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;
import lime.utils.Log;


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
	public static var libraries (default, null) = new Map<String, AssetLibrary> ();
	public static var onChange = new Event<Void->Void> ();
	
	// See definition in this file in the macro section below
	public static macro function __with_library_and_symbolName (id:ExprOf<String>, expr:Expr):Expr;
	
	public static function exists (id:String, type:AssetType = null):Bool {
		
		#if (tools && !display)
		
		if (type == null) {
			
			type = BINARY;
			
		}
		
		__with_library_and_symbolName(id, if (library != null) {
			
			return library.exists (symbolName, cast type);
			
		});
		
		#end
		
		return false;
		
	}
	
	
	/**
	 * Gets an instance of a cached or embedded asset
	 * @usage		var sound = Assets.getAsset("sound.wav", SOUND);
	 * @param	id		The ID or asset path for the asset
	 * @return		An Asset object, or null.
	 */
	public static function getAsset (id:String, type:AssetType, useCache:Bool):Dynamic {
		
		#if (tools && !display)
		
		if (useCache && cache.enabled) {
			
			switch (type) {
				case BINARY, TEXT: // Not cached
					
					useCache = false;
				
				case FONT:
					var font = cache.font.get (id);
					
					if (font != null) {
						
						return font;
						
					}
				
				case IMAGE:
					var image = cache.image.get (id);
					
					if (isValidImage (image)) {
						
						return image;
						
					}
				
				case MUSIC, SOUND:
					var audio = cache.audio.get (id);
					
					if (isValidAudio (audio)) {
						
						return audio;
						
					}
				
				case TEMPLATE:  throw "Not sure how to get template: " + id;
			}
			
		}
		
		__with_library_and_symbolName(id, if (library != null) {
			
			if (library.exists (symbolName, cast type)) {
				
				if (library.isLocal (symbolName, cast type)) {
					
					var asset = library.getAsset (symbolName, cast type);
					
					if (useCache && cache.enabled) {
						
						cache.set (id, asset, type);
						
					}
					
					return asset;
					
				} else {
					
					Log.info (type + " asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				Log.info ("There is no " + type + " asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			Log.info ("There is no asset library named \"" + libraryName + "\"");
			
		});
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded sound
	 * @usage		var sound = Assets.getSound("sound.wav");
	 * @param	id		The ID or asset path for the sound
	 * @return		A new Sound object
	 */
	public static function getAudioBuffer (id:String, useCache:Bool = true):AudioBuffer {
		
		return cast getAsset (id, SOUND, useCache);
		
	}
	
	
	/**
	 * Gets an instance of an embedded binary asset
	 * @usage		var bytes = Assets.getBytes("file.zip");
	 * @param	id		The ID or asset path for the file
	 * @return		A new Bytes object
	 */
	public static function getBytes (id:String):Bytes {
		
		return cast getAsset (id, BINARY, false);
		
	}
	
	
	/**
	 * Gets an instance of an embedded font
	 * @usage		var fontName = Assets.getFont("font.ttf").fontName;
	 * @param	id		The ID or asset path for the font
	 * @return		A new Font object
	 */
	public static function getFont (id:String, useCache:Bool = true):Font {
		
		return getAsset(id, FONT, useCache);
		
	}
	
	
	/**
	 * Gets an instance of an embedded bitmap
	 * @usage		var bitmap = new Bitmap(Assets.getBitmapData("image.jpg"));
	 * @param	id		The ID or asset path for the bitmap
	 * @param	useCache		(Optional) Whether to use BitmapData from the cache(Default: true)
	 * @return		A new BitmapData object
	 */
	public static function getImage (id:String, useCache:Bool = true):Image {
		
		return getAsset(id, IMAGE, useCache);
		
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
		
		#if (tools && !display)
		
		__with_library_and_symbolName(id, if (library != null) {
			
			if (library.exists (symbolName, null)) {
				
				return library.getPath (symbolName);
				
			} else {
				
				Log.info ("There is no asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			Log.info ("There is no asset library named \"" + libraryName + "\"");
			
		});
		
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
		
		return getAsset(id, TEXT, false);
		
	}
	
	
	public static function isLocal (id:String, type:AssetType = null, useCache:Bool = true):Bool {
		
		#if (tools && !display)
		
		if (useCache && cache.enabled) {
			
			if (cache.exists(id, type)) return true;
			
		}
		
		__with_library_and_symbolName(id, if (library != null) {
			
			return library.isLocal (symbolName, cast type);
			
		});
		
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
		#if lime_cffi
		
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
		
		var items = [];
		
		for (library in libraries) {
			
			var libraryItems = library.list (cast type);
			
			if (libraryItems != null) {
				
				items = items.concat (libraryItems);
				
			}
			
		}
		
		return items;
		
	}
	
	
	public static function loadAsset (id:String, type:AssetType, useCache:Bool):Future<Dynamic> {
		
		#if (tools && !display)
		
		if (useCache && cache.enabled) {
			
			switch (type) {
				case BINARY, TEXT: // Not cached
					
					useCache = false;
				
				case FONT:
					var font = cache.font.get (id);
					
					if (font != null) {
						
						var promise = new Promise<Font> ();
						promise.complete (font);
						return promise.future;
						
					}
				
				case IMAGE:
					var image = cache.image.get (id);
					
					if (isValidImage (image)) {
						
						var promise = new Promise<Image> ();
						promise.complete (image);
						return promise.future;
						
					}
				
				case MUSIC, SOUND:
					var audio = cache.audio.get (id);
					
					if (isValidAudio (audio)) {
						
						var promise = new Promise<AudioBuffer> ();
						promise.complete(audio);
						return promise.future;
						
					}
				
				case TEMPLATE:  throw "Not sure how to get template: " + id;
			}
			
		}
		
		__with_library_and_symbolName(id, if (library != null) {
			
			if (library.exists (symbolName, cast type)) {
				
				var future = library.loadAsset (symbolName, cast type);
				
				if (useCache && cache.enabled) {
					
					future.onComplete (function (audio) cache.set (id, audio, type));
					
				}
				
				return future;
				
			} else {
				
				var promise = new Promise<Dynamic> ();
				promise.error ("[Assets] There is no " + type + " asset with an ID of \"" + id + "\"");
				return promise.future;
				
			}
			
		} else {
			
			var promise = new Promise<Dynamic> ();
			promise.error ("[Assets] There is no asset library named \"" + libraryName + "\"");
			return promise.future;
			
		});
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function loadAudioBuffer (id:String, useCache:Bool = true):Future<AudioBuffer> {
		
		return cast loadAsset (id, SOUND, useCache);
		
	}
	
	
	public static function loadBytes (id:String):Future<Bytes> {
		
		return cast loadAsset (id, BINARY, false);
		
	}
	
	
	public static function loadFont (id:String, useCache:Bool = true):Future<Font> {
		
		return cast loadAsset (id, FONT, useCache);
		
	}
	
	
	public static function loadImage (id:String, useCache:Bool = true):Future<Image> {
		
		return cast loadAsset (id, IMAGE, useCache);
		
	}
	
	
	public static function loadLibrary (name:String):Future<AssetLibrary> {
		
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
		
		var promise = new Promise<String> ();
		
		#if (tools && !display)
		
		__with_library_and_symbolName(id, if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.TEXT)) {
				
				promise.completeWith (library.loadText (symbolName));
				
			} else {
				
				promise.error ("[Assets] There is no String asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			promise.error ("[Assets] There is no asset library named \"" + libraryName + "\"");
			
		});
		
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
		
		return new Future<AudioBuffer> (function () return getAudioBuffer (id), true);
		
	}
	
	
	public function loadBytes (id:String):Future<Bytes> {
		
		return new Future<Bytes> (function () return getBytes (id), true);
		
	}
	
	
	public function loadFont (id:String):Future<Font> {
		
		return new Future<Font> (function () return getFont (id), true);
		
	}
	
	
	public function loadImage (id:String):Future<Image> {
		
		return new Future<Image> (function () return getImage (id), true);
		
	}
	
	
	public function loadText (id:String):Future<String> {
		
		return loadBytes (id).then (function (bytes) {
			
			return new Future<String> (function () {
				
				if (bytes == null) {
					
					return null;
					
				} else {
					
					return bytes.getString (0, bytes.length);
					
				}
				
			}, true);
			
		});
		
	}
	
	
	public function unload ():Void {
		
		
		
	}
	
	
	public function getAsset (id:String, type:String):Dynamic {
		
		var type : AssetType = cast type;
		return switch (type) {
			case BINARY:    getBytes(id);
			case FONT:      getFont(id);
			case IMAGE:     getImage(id);
			case MUSIC:     getAudioBuffer(id);
			case SOUND:     getAudioBuffer(id);
			case TEMPLATE:  throw "Not sure how to get template: " + id;
			case TEXT:      getText(id);
		}
		
	}
	
	
	public function loadAsset (id:String, type:String):Future<Dynamic> {
		
		var type : AssetType = cast type;
		return switch (type) {
			case BINARY:    loadBytes(id);
			case FONT:      loadFont(id);
			case IMAGE:     loadImage(id);
			case MUSIC:     loadAudioBuffer(id);
			case SOUND:     loadAudioBuffer(id);
			case TEMPLATE:  throw "Not sure how to load template: " + id;
			case TEXT:      loadText(id);
		}
		
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
		version = AssetCache.cacheVersion ();
		
	}
	
	
	private macro static function cacheVersion () {}
	
	
	public function exists (id:String, ?type:AssetType):Bool {
		
		if (type == AssetType.IMAGE || type == null) {
			
			if (image.exists (id)) return true;
			
		}
		
		if (type == AssetType.FONT || type == null) {
			
			if (font.exists (id)) return true;
			
		}
		
		if (type == AssetType.SOUND || type == AssetType.MUSIC || type == null) {
			
			if (audio.exists (id)) return true;
			
		}
		
		return false;
		
	}
	
	
	public function set (id:String, asset:Dynamic, type:AssetType):Void {
		
		switch (type) {
			
			case FONT:
				font.set(id, asset);
			
			case IMAGE:
				if (!Std.is(asset, Image))
					throw "Cannot cache non-Image asset: " + asset + " as Image";
				
				image.set(id, asset);
			
			case SOUND, MUSIC:
				if (!Std.is(asset, AudioBuffer))
					throw "Cannot cache non-AudioBuffer asset: " + asset + " as AudioBuffer";
				
				audio.set(id, asset);
				
			default:
				throw type + " assets are not cachable";
			
		}
		
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


#else // macro


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


	macro public static function __with_library_and_symbolName (id:ExprOf<String>, expr:Expr):Expr {

		return macro {
			var colonIndex  = ${id}.indexOf (":");
			var libraryName = ${id}.substring (0, colonIndex);
			var symbolName  = ${id}.substr (colonIndex + 1);
			var library     = getLibrary (libraryName);

			${expr};
		}

	}
	
	
	macro public static function embedBytes ():Array<Field> {
		
		var fields = embedData (":file");
		
		if (fields != null) {
			
			var constructor = macro {
				
				#if lime_console
				throw "not implemented";
				#else
				var bytes = haxe.Resource.getBytes (resourceName);
				super (bytes.length, bytes.b);
				#end
				
			};
			
			var args = [ { name: "length", opt: false, type: macro :Int }, { name: "bytesData", opt: false, type: macro :haxe.io.BytesData } ];
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos () });
			
		}
		
		return fields;
		
	}
	
	
	macro public static function embedByteArray ():Array<Field> {
		
		var fields = embedData (":file");
		
		if (fields != null) {
			
			var constructor = macro {
				
				super ();
				
				#if lime_console
				throw "not implemented";
				#else
				var bytes = haxe.Resource.getBytes (resourceName);
				__fromBytes (bytes);
				#end
				
			};
			
			var args = [ { name: "length", opt: true, type: macro :Int, value: macro 0 } ];
			fields.push ({ name: "new", access: [ APublic ], kind: FFun({ args: args, expr: constructor, params: [], ret: null }), pos: Context.currentPos () });
			
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
							
							#if lime_console
							
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
							
							#else
							
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
							
							#end
							
							return fields;
							
						default:
						
					}
					
				}
				
			}
			
		}
		
		return null;
		
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
			
			#if lime_console
			throw "not implemented";
			#end
			
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


class AssetCache {
	
	
	private static macro function cacheVersion () {
		
		return macro $v{ Std.int (Math.random () * 1000000) };
		
	}
	
	
}


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