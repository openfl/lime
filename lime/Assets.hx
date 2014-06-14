package lime;


import haxe.Unserializer;
import lime.graphics.ImageData;
import lime.graphics.JPG;
import lime.graphics.PNG;
import lime.utils.ByteArray;


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
class Assets {
	
	
	private static var initialized = false;
	private static var path (default, null) = new Map <String, String> ();
	private static var type (default, null) = new Map <String, AssetType> ();
	
	
	public static function exists (id:String, type:AssetType = null):Bool {
		
		initialize ();
		
		#if (tools && !display)
		
		var assetType = Assets.type.get (id);
		
		if (assetType != null) {
			
			if (assetType == type || ((type == SOUND || type == MUSIC) && (assetType == MUSIC || assetType == SOUND))) {
				
				return true;
				
			}
			
			#if flash
			
			if ((assetType == BINARY || assetType == TEXT) && type == BINARY) {
				
				return true;
				
			} else if (path.exists (id)) {
				
				return true;
				
			}
			
			#else
			
			if (type == BINARY || type == null) {
				
				return true;
				
			}
			
			#end
			
		}
		
		return false;
		
		#end
		
		return false;
		
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
		
		#if (flash)
		
		//return cast (Type.createInstance (className.get (id), []), ByteArray);

		#elseif js
		
		var bytes:ByteArray = null;
		/*var data = ApplicationMain.urlLoaders.get (path.get (id)).data;
		
		if (Std.is (data, String)) {
			
			bytes = new ByteArray ();
			bytes.writeUTFBytes (data);
			
		} else if (Std.is (data, ByteArray)) {
			
			bytes = cast data;
			
		} else {
			
			bytes = null;
			
		}*/

		if (bytes != null) {
			
			bytes.position = 0;
			return bytes;
			
		} else {
			
			return null;
		}
		
		#else
		
		//if (className.exists(id)) return cast (Type.createInstance (className.get (id), []), ByteArray);
		/*else*/ return ByteArray.readFile (path.get (id));
		
		#end
		
		#end
		
		return null;
		
	}
	
	
	public static function getImageData (id:String):ImageData {
		
		initialize ();
		
		#if (tools && !display)
		
		#if (flash)
		
		//return cast (Type.createInstance (className.get (id), []), ByteArray);

		#elseif js
		
		return null;
		
		#else
		
		var bytes = getBytes (id);
		
		if (bytes != null) {
			
			if (JPG.isFormat (bytes)) {
				
				return JPG.decode (bytes);
				
			} else if (PNG.isFormat (bytes)) {
				
				return PNG.decode (bytes);
				
			}
			
			return null;
			
		}
		
		#end
		
		#end
		
		return null;
		
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
		
		#if ios
		
		return SystemPath.applicationDirectory + "/assets/" + path.get (id);
		
		#else
		
		return path.get (id);
		
		#end
		
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
		
		#if js
		
		var bytes:ByteArray = null;
		/*var data = ApplicationMain.urlLoaders.get (path.get (id)).data;
		
		if (Std.is (data, String)) {
			
			return cast data;
			
		} else if (Std.is (data, ByteArray)) {
			
			bytes = cast data;
			
		} else {
			
			bytes = null;
			
		}*/
		
		if (bytes != null) {
			
			bytes.position = 0;
			return bytes.readUTFBytes (bytes.length);
			
		} else {
			
			return null;
		}
		
		#else
		
		var bytes = getBytes (id);
		
		if (bytes == null) {
			
			return null;
			
		} else {
			
			return bytes.readUTFBytes (bytes.length);
			
		}
		
		#end
		
		#end
		
		return null;
		
	}
	
	
	private static function initialize ():Void {
		
		if (!initialized) {
			
			#if (tools && !display)
			
			#if (!js && !flash)
			loadManifest ();
			#end
			
			#end
			
			initialized = true;
			
		}
		
	}
	
	
	public static function isLocal (id:String, type:AssetType = null, useCache:Bool = true):Bool {
		
		initialize ();
		
		#if (tools && !display)
		
		#if flash
		
		if (type != AssetType.MUSIC && type != AssetType.SOUND) {
			
			//return className.exists (id);
			
		}
		
		#end
		
		return true;
		
		#end
		
		return false;
		
	}
	
	
	public static function list (type:AssetType = null):Array<String> {
		
		initialize ();
		
		var items = [];
		
		for (id in Assets.type.keys ()) {
			
			if (type == null || exists (id, type)) {
				
				items.push (id);
				
			}
			
		}
		
		return items;
		
	}
	
	
	public static function loadBytes (id:String, handler:ByteArray -> Void):Void {
		
		initialize ();
		
		#if (tools && !display)
		
		#if (flash || js)
		
		if (path.exists (id)) {
			
			/*var loader = new URLLoader ();
			loader.addEventListener (Event.COMPLETE, function (event:Event) {
				
				var bytes = new ByteArray ();
				bytes.writeUTFBytes (event.currentTarget.data);
				bytes.position = 0;
				
				handler (bytes);
				
			});
			loader.load (new URLRequest (path.get (id)));*/
			
			handler (null);
			
		} else {
			
			handler (getBytes (id));
			
		}
		
		#else
		
		handler (getBytes (id));
		
		#end
		
		#end
		
		handler (null);
		
	}
	
	
	#if !flash
	private static function loadManifest ():Void {
		
		try {
			
			#if blackberry
			var bytes = ByteArray.readFile ("app/native/manifest");
			#elseif tizen
			var bytes = ByteArray.readFile ("../res/manifest");
			#elseif emscripten
			var bytes = ByteArray.readFile ("assets/manifest");
			#else
			var bytes = ByteArray.readFile ("manifest");
			#end
			
			if (bytes != null) {
				
				bytes.position = 0;
				
				if (bytes.length > 0) {
					
					var data = bytes.readUTFBytes (bytes.length);
					
					if (data != null && data.length > 0) {
						
						var manifest:Array<Dynamic> = Unserializer.run (data);
						
						for (asset in manifest) {
							
							//if (!className.exists (asset.id)) {
								
								path.set (asset.id, asset.path);
								type.set (asset.id, Type.createEnum (AssetType, asset.type));
								
							//}
							
						}
						
					}
					
				}
				
			} else {
				
				trace ("Warning: Could not load asset manifest (bytes was null)");
				
			}
		
		} catch (e:Dynamic) {
			
			trace ('Warning: Could not load asset manifest (${e})');
			
		}
		
	}
	#end
	
	
	public static function loadText (id:String, handler:String -> Void):Void {
		
		initialize ();
		
		#if (tools && !display)
		
		#if js
		
		if (path.exists (id)) {
			
			/*var loader = new URLLoader ();
			loader.addEventListener (Event.COMPLETE, function (event:Event) {
				
				handler (event.currentTarget.data);
				
			});
			loader.load (new URLRequest (path.get (id)));*/
			
			handler (null);
			
		} else {
			
			handler (getText (id));
			
		}
		
		#else
		
		var callback = function (bytes:ByteArray):Void {
			
			if (bytes == null) {
				
				handler (null);
				
			} else {
				
				handler (bytes.readUTFBytes (bytes.length));
				
			}
			
		}
		
		loadBytes (id, callback);
		
		#end
		
		#end
		
		handler (null);
		
	}
	
	
	private static function resolveClass (name:String):Class <Dynamic> {
		
		return Type.resolveClass (name);
		
	}
	
	
	private static function resolveEnum (name:String):Enum <Dynamic> {
		
		var value = Type.resolveEnum (name);
		
		#if flash
		
		if (value == null) {
			
			return cast Type.resolveClass (name);
			
		}
		
		#end
		
		return value;
		
	}
	
	
}


enum AssetType {
	
	BINARY;
	FONT;
	IMAGE;
	MOVIE_CLIP;
	MUSIC;
	SOUND;
	TEMPLATE;
	TEXT;
	
}