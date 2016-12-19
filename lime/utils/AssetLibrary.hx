package lime.utils;


import lime.app.Event;
import lime.app.Future;
import lime.app.Promise;
import lime.audio.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.AssetType;

#if flash
import flash.display.BitmapData;
import flash.media.Sound;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class AssetLibrary {
	
	
	public var onChange = new Event<Void->Void> ();
	
	private var cachedAudioBuffers = new Map<String, AudioBuffer> ();
	private var cachedBytes = new Map<String, Bytes> ();
	private var cachedFonts = new Map<String, Font> ();
	private var cachedImages = new Map<String, Image> ();
	private var cachedText = new Map<String, String> ();
	private var classTypes = new Map<String, Class<Dynamic>> ();
	private var paths = new Map<String, String> ();
	private var preload = new Map<String, Bool> ();
	private var progressBytesLoadedCache:Map<String, Int>;
	private var progressBytesLoaded:Int;
	private var progressBytesTotal:Int;
	private var progressLoaded:Int;
	private var progressTotal:Int;
	private var promise:Promise<AssetLibrary>;
	private var types = new Map<String, AssetType> ();
	
	
	public function new () {
		
		
		
	}
	
	
	public function exists (id:String, type:String):Bool {
		
		var requestedType = type != null ? cast (type, AssetType) : null;
		var assetType = types.get (id);
		
		if (assetType != null) {
			
			if (assetType == requestedType || ((requestedType == SOUND || requestedType == MUSIC) && (assetType == MUSIC || assetType == SOUND))) {
				
				return true;
				
			}
			
			#if flash
			
			if (requestedType == BINARY && (assetType == BINARY || assetType == TEXT || assetType == IMAGE)) {
				
				return true;
				
			} else if (requestedType == TEXT && assetType == BINARY) {
				
				return true;
				
			} else if (requestedType == null || paths.exists (id)) {
				
				return true;
				
			}
			
			#else
			
			if (requestedType == BINARY || requestedType == null || (assetType == BINARY && requestedType == TEXT)) {
				
				return true;
				
			}
			
			#end
			
		}
		
		return false;
		
	}
	
	
	public static function fromManifest (manifest:AssetManifest):AssetLibrary {
		
		var library:AssetLibrary = null;
		
		if (manifest.version == 1) {
			
			if (manifest.libraryType == null) {
				
				library = new AssetLibrary ();
				
			} else {
				
				library = Type.createInstance (Type.resolveClass (manifest.libraryType), manifest.libraryArgs);
				
			}
			
			library.__fromManifest (manifest);
			
		}
		
		return library;
		
	}
	
	
	public function getAsset (id:String, type:String):Dynamic {
		
		return switch (type) {
			
			case BINARY:       getBytes       (id);
			case FONT:         getFont        (id);
			case IMAGE:        getImage       (id);
			case MUSIC, SOUND: getAudioBuffer (id);
			case TEXT:         getText        (id);
			
			case TEMPLATE:  throw "Not sure how to get template: " + id;
			default:		throw "Unknown asset type: " + type;
			
		}
		
	}
	
	
	public function getAudioBuffer (id:String):AudioBuffer {
		
		if (cachedAudioBuffers.exists (id)) {
			
			return cachedAudioBuffers.get (id);
			
		} else if (classTypes.exists (id)) {
			
			#if flash
			
			var buffer = new AudioBuffer ();
			buffer.src = cast (Type.createInstance (classTypes.get (id), []), Sound);
			return buffer;
			
			#else
			
			return AudioBuffer.fromBytes (cast (Type.createInstance (classTypes.get (id), []), Bytes));
			
			#end
			
		} else {
			
			return AudioBuffer.fromFile (paths.get (id));
			
		}
		
	}
	
	
	public function getBytes (id:String):Bytes {
		
		if (cachedBytes.exists (id)) {
			
			return cachedBytes.get (id);
			
		} else if (classTypes.exists (id)) {
			
			#if flash
			
			switch (types.get (id)) {
				
				case TEXT, BINARY:
					
					return Bytes.ofData (cast (Type.createInstance (classTypes.get (id), []), flash.utils.ByteArray));
				
				case IMAGE:
					
					var bitmapData = cast (Type.createInstance (classTypes.get (id), []), BitmapData);
					return Bytes.ofData (bitmapData.getPixels (bitmapData.rect));
				
				default:
					
					return null;
				
			}
			
			#else
			
			return cast (Type.createInstance (classTypes.get (id), []), Bytes);
			
			#end
			
		} else {
			
			return Bytes.fromFile (paths.get (id));
			
		}
		
	}
	
	
	public function getFont (id:String):Font {
		
		if (cachedFonts.exists (id)) {
			
			return cachedFonts.get (id);
			
		} else if (classTypes.exists (id)) {
			
			#if flash
			
			var src = Type.createInstance (classTypes.get (id), []);
			
			var font = new Font (src.fontName);
			font.src = src;
			return font;
			
			#else
			
			return cast (Type.createInstance (classTypes.get (id), []), Font);
			
			#end
			
		} else {
			
			return Font.fromFile (paths.get (id));
			
		}
		
	}
	
	
	public function getImage (id:String):Image {
		
		if (cachedImages.exists (id)) {
			
			return cachedImages.get (id);
			
		} else if (classTypes.exists (id)) {
			
			#if flash
			
			return Image.fromBitmapData (cast (Type.createInstance (classTypes.get (id), []), BitmapData));
			
			#else
			
			return cast (Type.createInstance (classTypes.get (id), []), Image);
			
			#end
			
		} else {
			
			return Image.fromFile (paths.get (id));
			
		}
		
	}
	
	
	public function getPath (id:String):String {
		
		return paths.get (id);
		
	}
	
	
	public function getText (id:String):String {
		
		if (cachedText.exists (id)) {
			
			return cachedText.get (id);
			
		} else {
			
			var bytes = getBytes (id);
			
			if (bytes == null) {
				
				return null;
				
			} else {
				
				return bytes.getString (0, bytes.length);
				
			}
			
		}
		
	}
	
	
	public function isLocal (id:String, type:String):Bool {
		
		#if sys
		
		return true;
		
		#else
		
		if (classTypes.exists (id)) {
			
			return true;
			
		}
		
		var requestedType = type != null ? cast (type, AssetType) : null;
		
		return switch (requestedType) {
			
			case IMAGE:
				
				cachedImages.exists (id);
			
			case MUSIC, SOUND:
				
				cachedAudioBuffers.exists (id);
			
			default:
				
				cachedBytes.exists (id) || cachedText.exists (id);
			
		}
		
		#end
		
	}
	
	
	public function list (type:String):Array<String> {
		
		var requestedType = type != null ? cast (type, AssetType) : null;
		var items = [];
		
		for (id in types.keys ()) {
			
			if (requestedType == null || exists (id, type)) {
				
				items.push (id);
				
			}
			
		}
		
		return items;
		
	}
	
	
	public function loadAsset (id:String, type:String):Future<Dynamic> {
		
		return switch (type) {
			
			case BINARY:       loadBytes       (id);
			case FONT:         loadFont        (id);
			case IMAGE:        loadImage       (id);
			case MUSIC, SOUND: loadAudioBuffer (id);
			case TEXT:         loadText        (id);
			
			case TEMPLATE:  throw "Not sure how to load template: " + id;
			default:		throw "Unknown asset type: " + type;
			
		}
		
	}
	
	
	public function load ():Future<AssetLibrary> {
		
		if (promise == null) {
			
			promise = new Promise<AssetLibrary> ();
			progressBytesLoadedCache = new Map ();
			
			progressLoaded = 0;
			progressTotal = 1;
			
			for (id in preload.keys ()) {
				
				switch (types.get (id)) {
					
					case BINARY:
						
						progressTotal++;
						
						var future = loadBytes (id);
						future.onProgress (load_onProgress.bind (id));
						future.onError (load_onError.bind (id));
						future.onComplete (loadBytes_onComplete.bind (id));
					
					case FONT:
						
						progressTotal++;
						
						var future = loadFont (id);
						future.onProgress (load_onProgress.bind (id));
						future.onError (load_onError.bind (id));
						future.onComplete (loadFont_onComplete.bind (id));
					
					case IMAGE:
						
						progressTotal++;
						
						var future = loadImage (id);
						future.onProgress (load_onProgress.bind (id));
						future.onError (load_onError.bind (id));
						future.onComplete (loadImage_onComplete.bind (id));
					
					case MUSIC, SOUND:
						
						progressTotal++;
						
						var future = loadAudioBuffer (id);
						future.onProgress (load_onProgress.bind (id));
						future.onError (load_onError.bind (id));
						future.onComplete (loadAudioBuffer_onComplete.bind (id));
					
					case TEXT:
						
						progressTotal++;
						
						var future = loadText (id);
						future.onProgress (load_onProgress.bind (id));
						future.onError (load_onError.bind (id));
						future.onComplete (loadText_onComplete.bind (id));
					
					default:
					
				}
				
			}
			
			updateProgressLoaded ();
			
		}
		
		return promise.future;
		
	}
	
	
	public function loadAudioBuffer (id:String):Future<AudioBuffer> {
		
		if (cachedAudioBuffers.exists (id)) {
			
			return Future.withValue (cachedAudioBuffers.get (id));
			
		} else if (classTypes.exists (id)) {
			
			return Future.withValue (Type.createInstance (classTypes.get (id), []));
			
		} else {
			
			return AudioBuffer.loadFromFile (paths.get (id));
			
		}
		
	}
	
	
	public function loadBytes (id:String):Future<Bytes> {
		
		if (cachedBytes.exists (id)) {
			
			return Future.withValue (cachedBytes.get (id));
			
		} else if (classTypes.exists (id)) {
			
			return Future.withValue (Type.createInstance (classTypes.get (id), []));
			
		} else {
			
			return Bytes.loadFromFile (paths.get (id));
			
		}
		
	}
	
	
	public function loadFont (id:String):Future<Font> {
		
		if (cachedFonts.exists (id)) {
			
			return Future.withValue (cachedFonts.get (id));
			
		} else if (classTypes.exists (id)) {
			
			var font:Font = Type.createInstance (classTypes.get (id), []);
			
			#if (js && html5)
			return Font.loadFromName (font.name);
			#else
			return Future.withValue (font);
			#end
			
		} else {
			
			#if (js && html5)
			return Font.loadFromName (paths.get (id));
			#else
			return Font.loadFromFile (paths.get (id));
			#end
			
		}
		
	}
	
	
	public function loadImage (id:String):Future<Image> {
		
		if (cachedImages.exists (id)) {
			
			return Future.withValue (cachedImages.get (id));
			
		} else if (classTypes.exists (id)) {
			
			return Future.withValue (Type.createInstance (classTypes.get (id), []));
			
		} else {
			
			return Image.loadFromFile (paths.get (id));
			
		}
		
	}
	
	
	public function loadText (id:String):Future<String> {
		
		if (cachedText.exists (id)) {
			
			return Future.withValue (cachedText.get (id));
			
		} else {
			
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
		
	}
	
	
	public function unload ():Void {
		
		
		
	}
	
	
	private function updateProgressLoaded ():Void {
		
		progressLoaded++;
		
		if (progressLoaded == progressTotal) {
			
			promise.complete (this);
			
		}
		
	}
	
	
	private function __fromManifest (manifest:AssetManifest):Void {
		
		if (manifest.version == 1) {
			
			for (asset in manifest.assets) {
				
				paths.set (asset.id, asset.path);
				types.set (asset.id, asset.type);
				
			}
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function loadAudioBuffer_onComplete (id:String, audioBuffer:AudioBuffer):Void {
		
		cachedAudioBuffers.set (id, audioBuffer);
		updateProgressLoaded ();
		
	}
	
	
	private function loadBytes_onComplete (id:String, bytes:Bytes):Void {
		
		cachedBytes.set (id, bytes);
		updateProgressLoaded ();
		
	}
	
	
	private function loadFont_onComplete (id:String, font:Font):Void {
		
		cachedFonts.set (id, font);
		updateProgressLoaded ();
		
	}
	
	
	private function loadImage_onComplete (id:String, image:Image):Void {
		
		cachedImages.set (id, image);
		updateProgressLoaded ();
		
	}
	
	
	private function loadText_onComplete (id:String, text:String):Void {
		
		cachedText.set (id, text);
		updateProgressLoaded ();
		
	}
	
	
	private function load_onError (id:String, message:Dynamic):Void {
		
		promise.error ("Error loading asset \"" + id + "\"");
		
	}
	
	
	private function load_onProgress (id:String, bytesLoaded:Int, bytesTotal:Int):Void {
		
		if (progressBytesLoadedCache.exists (id)) {
			
			var previous = progressBytesLoadedCache.get (id);
			progressBytesLoaded += (bytesLoaded - previous);
			progressBytesLoadedCache.set (id, bytesLoaded);
			
			promise.progress (progressBytesLoaded, progressBytesTotal);
			
		} else {
			
			if (bytesTotal > 0) {
				
				progressBytesLoadedCache.set (id, bytesLoaded);
				progressBytesLoaded += bytesLoaded;
				progressBytesTotal += bytesTotal;
				
			}
			
		}
		
	}
	
	
}