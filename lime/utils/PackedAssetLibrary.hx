package lime.utils;


import haxe.io.Path;
import lime.app.Event;
import lime.app.Future;
import lime.app.Promise;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.net.HTTPRequest;
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


class PackedAssetLibrary extends AssetLibrary {
	
	
	private var id:String;
	private var lengths = new Map<String, Int> ();
	private var packedData:Bytes;
	private var positions = new Map<String, Int> ();
	
	
	public function new (id:String) {
		
		super ();
		
		this.id = id;
		
	}
	
	
	public static function fromBytes (bytes:Bytes, rootPath:String = null):PackedAssetLibrary {
		
		return cast fromManifest (AssetManifest.fromBytes (bytes, rootPath));
		
	}
	
	
	public static function fromFile (path:String, rootPath:String = null):PackedAssetLibrary {
		
		return cast fromManifest (AssetManifest.fromFile (path, rootPath));
		
	}
	
	
	public static function fromManifest (manifest:AssetManifest):PackedAssetLibrary {
		
		return cast AssetLibrary.fromManifest (manifest);
		
	}
	
	
	public override function getAudioBuffer (id:String):AudioBuffer {
		
		if (cachedAudioBuffers.exists (id)) {
			
			return cachedAudioBuffers.get (id);
			
		} else {
			
			// TODO: Return based on position/length values for bytes
			return null;
			
		}
		
	}
	
	
	public override function getBytes (id:String):Bytes {
		
		if (cachedBytes.exists (id)) {
			
			return cachedBytes.get (id);
			
		} else if (cachedText.exists (id)) {
			
			var bytes = Bytes.ofString (cachedText.get (id));
			cachedBytes.set (id, bytes);
			return bytes;
			
		} else {
			
			// TODO: Return based on position/length values for bytes
			return null;
			
		}
		
	}
	
	
	public override function getFont (id:String):Font {
		
		if (cachedFonts.exists (id)) {
			
			return cachedFonts.get (id);
			
		} else {
			
			// TODO: Return based on position/length values for bytes
			return null;
			
		}
		
	}
	
	
	public override function getImage (id:String):Image {
		
		if (cachedImages.exists (id)) {
			
			return cachedImages.get (id);
			
		} else {
			
			// TODO: More efficient method
			var bytes = Bytes.alloc (lengths[id]);
			bytes.blit (0, packedData, positions[id], lengths[id]);
			return Image.fromBytes (bytes);
			
		}
		
	}
	
	
	public override function getText (id:String):String {
		
		if (cachedText.exists (id)) {
			
			return cachedText.get (id);
			
		} else {
			
			// TODO: Return based on position/length values for bytes
			return null;
			
		}
		
	}
	
	
	public override function isLocal (id:String, type:String):Bool {
		
		return true;
		
	}
	
	
	public override function load ():Future<AssetLibrary> {
		
		if (loaded) {
			
			return Future.withValue (cast this);
			
		}
		
		if (promise == null) {
			
			promise = new Promise<AssetLibrary> ();
			
			// TODO: Handle `preload` for individual assets
			// TODO: Do not preload bytes on native, if we can read from it instead (all non-Android targets?)
			
			var onComplete = function (data:Bytes) {
				
				cachedBytes.set (id, data);
				packedData = data;
				
				promise.complete (this);
				
			};
			
			if (cachedBytes.exists (id)) {
				
				onComplete (cachedBytes.get (id));
				
			} else {
				
				var path = paths.exists (id) ? paths.get (id) : id;
				
				Bytes.loadFromFile (path).onError (promise.error).onComplete (onComplete);
				
			}
			
		}
		
		return promise.future;
		
	}
	
	
	public override function loadAudioBuffer (id:String):Future<AudioBuffer> {
		
		if (cachedAudioBuffers.exists (id)) {
			
			return Future.withValue (cachedAudioBuffers.get (id));
			
		} else {
			
			// TODO: Return based on position/length values for bytes
			return Future.withValue (null);
			
		}
		
	}
	
	
	public override function loadBytes (id:String):Future<Bytes> {
		
		if (cachedBytes.exists (id)) {
			
			return Future.withValue (cachedBytes.get (id));
			
		} else {
			
			// TODO: Return based on position/length values for bytes
			return Future.withValue (null);
			
		}
		
	}
	
	
	public override function loadFont (id:String):Future<Font> {
		
		if (cachedFonts.exists (id)) {
			
			return Future.withValue (cachedFonts.get (id));
			
		} else {
			
			// TODO: Return based on position/length values for bytes
			return Future.withValue (null);
			
		}
		
	}
	
	
	public static function loadFromBytes (bytes:Bytes, rootPath:String = null):Future<PackedAssetLibrary> {
		
		return AssetLibrary.loadFromBytes (bytes, rootPath).then (function (library) {
			
			var assetLibrary:PackedAssetLibrary = cast library;
			return Future.withValue (assetLibrary);
			
		});
		
	}
	
	
	public static function loadFromFile (path:String, rootPath:String = null):Future<PackedAssetLibrary> {
		
		return AssetLibrary.loadFromFile (path, rootPath).then (function (library) {
			
			var assetLibrary:PackedAssetLibrary = cast library;
			return Future.withValue (assetLibrary);
			
		});
		
	}
	
	
	public static function loadFromManifest (manifest:AssetManifest):Future<PackedAssetLibrary> {
		
		return AssetLibrary.loadFromManifest (manifest).then (function (library) {
			
			var assetLibrary:PackedAssetLibrary = cast library;
			return Future.withValue (assetLibrary);
			
		});
		
	}
	
	
	public override function loadImage (id:String):Future<Image> {
		
		if (cachedImages.exists (id)) {
			
			return Future.withValue (cachedImages.get (id));
			
		} else {
			
			trace ("SDLKFJDSLKFJ");
			trace (id);
			// TODO: Return based on position/length values for bytes
			return Future.withValue (null);
			
		}
		
	}
	
	
	public override function loadText (id:String):Future<String> {
		
		if (cachedText.exists (id)) {
			
			return Future.withValue (cachedText.get (id));
			
		} else if (cachedBytes.exists (id)) {
			
			var bytes = getBytes (id);
			
			if (bytes == null) {
				
				return cast Future.withValue (null);
				
			} else {
				
				var text = bytes.getString (0, bytes.length);
				cachedText.set (id, text);
				return Future.withValue (text);
				
			}
			
		} else {
			
			// TODO: Return based on position/length values for bytes
			return Future.withValue (null);
			
		}
		
	}
	
	
	public override function unload ():Void {
		
		
		
	}
	
	
	private override function __fromManifest (manifest:AssetManifest):Void {
		
		super.__fromManifest (manifest);
		
		for (asset in manifest.assets) {
			
			if (Reflect.hasField (asset, "position")) {
				
				positions.set (asset.id, Reflect.field (asset, "position"));
				
			}
			
			if (Reflect.hasField (asset, "length")) {
				
				lengths.set (asset.id, Reflect.field (asset, "length"));
				
			}
			
		}
		
	}
	
	
}