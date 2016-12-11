package lime.utils;


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

@:access(lime.utils.AssetLibrary)


class Assets {
	
	
	public static var cache:AssetCache = new AssetCache ();
	public static var libraries (default, null) = new Map<String, AssetLibrary> ();
	public static var onChange = new Event<Void->Void> ();
	
	
	public static function exists (id:String, type:AssetType = null):Bool {
		
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
					
					Log.info ("Audio asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				Log.info ("There is no audio asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			Log.info ("There is no asset library named \"" + libraryName + "\"");
			
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
		
		#if (tools && !display)
		
		var libraryName = id.substring (0, id.indexOf(":"));
		var symbolName = id.substr (id.indexOf(":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.BINARY)) {
				
				if (library.isLocal (symbolName, cast AssetType.BINARY)) {
					
					return library.getBytes (symbolName);
					
				} else {
					
					Log.info ("String or Bytes asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				Log.info ("There is no String or Bytes asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			Log.info ("There is no asset library named \"" + libraryName + "\"");
			
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
					
					Log.info ("Font asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				Log.info ("There is no Font asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			Log.info ("There is no asset library named \"" + libraryName + "\"");
			
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
					
					Log.info ("Image asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				Log.info ("There is no Image asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			Log.info ("There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public static function getLibrary (name:String):AssetLibrary {
		
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
		
		var libraryName = id.substring (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, null)) {
				
				return library.getPath (symbolName);
				
			} else {
				
				Log.info ("There is no asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			Log.info ("There is no asset library named \"" + libraryName + "\"");
			
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
		
		#if (tools && !display)
		
		var libraryName = id.substring (0, id.indexOf(":"));
		var symbolName = id.substr (id.indexOf(":") + 1);
		var library = getLibrary (libraryName);
		
		if (library != null) {
			
			if (library.exists (symbolName, cast AssetType.TEXT)) {
				
				if (library.isLocal (symbolName, cast AssetType.TEXT)) {
					
					return library.getText (symbolName);
					
				} else {
					
					Log.info ("String asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				Log.info ("There is no String asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			Log.info ("There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public static function isLocal (id:String, type:AssetType = null, useCache:Bool = true):Bool {
		
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
	
	
	public static function loadAudioBuffer (id:String, useCache:Bool = true):Future<AudioBuffer> {
		
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