package;


import haxe.Timer;
import haxe.Unserializer;
import lime.app.Future;
import lime.app.Preloader;
import lime.app.Promise;
import lime.audio.AudioSource;
import lime.audio.openal.AL;
import lime.audio.AudioBuffer;
import lime.graphics.Image;
import lime.net.HTTPRequest;
import lime.system.CFFI;
import lime.text.Font;
import lime.utils.Bytes;
import lime.utils.Log;
import lime.utils.UInt8Array;
import lime.Assets;

#if sys
import haxe.io.Path;
import sys.FileSystem;
#end

#if flash
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.media.Sound;
import flash.net.URLLoader;
import flash.net.URLRequest;
#end


class DefaultAssetLibrary extends AssetLibrary {
	
	
	public var className (default, null) = new Map<String, Dynamic> ();
	public var path (default, null) = new Map<String, String> ();
	public var type (default, null) = new Map<String, AssetType> ();
	
	private var lastModified:Float;
	private var timer:Timer;
	
	#if (windows && !cs)
	private var rootPath = FileSystem.absolutePath (Path.directory (#if (haxe_ver >= 3.3) Sys.programPath () #else Sys.executablePath () #end)) + "/";
	#else
	private var rootPath = "";
	#end
	
	
	public function new () {
		
		super ();
		
		#if (openfl && !flash)
		::if (assets != null)::
		::foreach assets::::if (type == "font")::openfl.text.Font.registerFont (__ASSET__OPENFL__::flatName::);::end::
		::end::::end::
		#end
		
		#if flash
		
		::if (assets != null)::::foreach assets::::if (embed)::className.set ("::id::", __ASSET__::flatName::);::else::path.set ("::id::", "::resourceName::");::end::
		type.set ("::id::", AssetType.$$upper(::type::));
		::end::::end::
		
		#elseif html5
		
		::if (assets != null)::var id;
		::foreach assets::id = "::id::";
		::if (embed)::::if (type == "font")::className.set (id, __ASSET__::flatName::);::else::path.set (id, ::if (resourceName == id)::id::else::"::resourceName::"::end::);::end::
		::else::path.set (id, ::if (resourceName == id)::id::else::"::resourceName::"::end::);::end::
		type.set (id, AssetType.$$upper(::type::));
		::end::::end::
		
		var assetsPrefix = null;
		if (ApplicationMain.config != null && Reflect.hasField (ApplicationMain.config, "assetsPrefix")) {
			assetsPrefix = ApplicationMain.config.assetsPrefix;
		}
		if (assetsPrefix != null) {
			for (k in path.keys()) {
				path.set(k, assetsPrefix + path[k]);
			}
		}
		
		#else
		
		#if (windows || mac || linux)
		
		var useManifest = false;
		::if (assets != null)::::foreach assets::::if (type == "font")::
		className.set ("::id::", __ASSET__::flatName::);
		type.set ("::id::", AssetType.$$upper(::type::));
		::else::::if (embed)::
		className.set ("::id::", __ASSET__::flatName::);
		type.set ("::id::", AssetType.$$upper(::type::));
		::else::useManifest = true;
		::end::::end::::end::::end::
		
		if (useManifest) {
			
			loadManifest ();
			
			if (Sys.args ().indexOf ("-livereload") > -1) {
				
				var path = FileSystem.fullPath ("manifest");
				
				if (FileSystem.exists (path)) {
					
					lastModified = FileSystem.stat (path).mtime.getTime ();
					
					timer = new Timer (2000);
					timer.run = function () {
						
						var modified = FileSystem.stat (path).mtime.getTime ();
						
						if (modified > lastModified) {
							
							lastModified = modified;
							loadManifest ();
							
							onChange.dispatch ();
							
						}
						
					}
					
				}
				
			}
			
		}
		
		#else
		
		loadManifest ();
		
		#end
		#end
		
	}
	
	
	public override function exists (id:String, type:String):Bool {
		
		var requestedType = type != null ? cast (type, AssetType) : null;
		var assetType = this.type.get (id);
		
		if (assetType != null) {
			
			if (assetType == requestedType || ((requestedType == SOUND || requestedType == MUSIC) && (assetType == MUSIC || assetType == SOUND))) {
				
				return true;
				
			}
			
			#if flash
			
			if (requestedType == BINARY && (assetType == BINARY || assetType == TEXT || assetType == IMAGE)) {
				
				return true;
				
			} else if (requestedType == TEXT && assetType == BINARY) {
				
				return true;
				
			} else if (requestedType == null || path.exists (id)) {
				
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
	
	
	public override function getAudioBuffer (id:String):AudioBuffer {
		
		#if flash
		
		var buffer = new AudioBuffer ();
		buffer.src = cast (Type.createInstance (className.get (id), []), Sound);
		return buffer;
		
		#elseif html5
		
		return Preloader.audioBuffers.get (path.get (id));
		
		#else
		
		if (className.exists (id)) return AudioBuffer.fromBytes (cast (Type.createInstance (className.get (id), []), Bytes));
		else return AudioBuffer.fromFile (rootPath + path.get (id));
		
		#end
		
	}
	
	
	public override function getBytes (id:String):Bytes {
		
		#if flash
		
		switch (type.get (id)) {
			
			case TEXT, BINARY:
				
				return Bytes.ofData (cast (Type.createInstance (className.get (id), []), flash.utils.ByteArray));
			
			case IMAGE:
				
				var bitmapData = cast (Type.createInstance (className.get (id), []), BitmapData);
				return Bytes.ofData (bitmapData.getPixels (bitmapData.rect));
			
			default:
			
		}
		
		return null;
		
		#elseif html5
		
		switch (type.get (id)) {
			
			case TEXT:
				
				var loader = Preloader.textLoaders.get (path.get (id));
				
				if (loader != null && loader.responseData != null) {
					
					return Bytes.ofString (loader.responseData);
					
				}
				
			case BINARY:
				
				var loader = Preloader.loaders.get (path.get (id));
				
				if (loader != null) {
					
					return Bytes.fromBytes (loader.responseData);
					
				}
				
			default:
			
		}
		
		return null;
		
		#else
		
		if (className.exists(id)) return cast (Type.createInstance (className.get (id), []), Bytes);
		else return Bytes.readFile (rootPath + path.get (id));
		
		#end
		
	}
	
	
	public override function getFont (id:String):Font {
		
		#if flash
		
		var src = Type.createInstance (className.get (id), []);
		
		var font = new Font (src.fontName);
		font.src = src;
		return font;
		
		#elseif html5
		
		return cast (Type.createInstance (className.get (id), []), Font);
		
		#else
		
		if (className.exists (id)) {
			
			var fontClass = className.get (id);
			return cast (Type.createInstance (fontClass, []), Font);
			
		} else {
			
			return Font.fromFile (rootPath + path.get (id));
			
		}
		
		#end
		
	}
	
	
	public override function getImage (id:String):Image {
		
		#if flash
		
		return Image.fromBitmapData (cast (Type.createInstance (className.get (id), []), BitmapData));
		
		#elseif html5
		
		return Preloader.images.get (path.get (id));
		
		#else
		
		if (className.exists (id)) {
			
			var fontClass = className.get (id);
			return cast (Type.createInstance (fontClass, []), Image);
			
		} else {
			
			return Image.fromFile (rootPath + path.get (id));
			
		}
		
		#end
		
	}
	
	
	/*public override function getMusic (id:String):Dynamic {
		
		#if flash
		
		return cast (Type.createInstance (className.get (id), []), Sound);
		
		#elseif openfl_html5
		
		//var sound = new Sound ();
		//sound.__buffer = true;
		//sound.load (new URLRequest (path.get (id)));
		//return sound;
		return null;
		
		#elseif html5
		
		return null;
		//return new Sound (new URLRequest (path.get (id)));
		
		#else
		
		return null;
		//if (className.exists(id)) return cast (Type.createInstance (className.get (id), []), Sound);
		//else return new Sound (new URLRequest (path.get (id)), null, true);
		
		#end
		
	}*/
	
	
	public override function getPath (id:String):String {
		
		//#if ios
		
		//return SystemPath.applicationDirectory + "/assets/" + path.get (id);
		
		//#else
		
		return path.get (id);
		
		//#end
		
	}
	
	
	public override function getText (id:String):String {
		
		#if html5
		
		var loader = Preloader.textLoaders.get (path.get (id));
		
		if (loader != null) {
			
			return loader.responseData;
			
		}
		
		#end
		
		var bytes = getBytes (id);
		
		if (bytes == null) {
			
			return null;
			
		} else {
			
			return bytes.getString (0, bytes.length);
			
		}
		
	}
	
	
	public override function isLocal (id:String, type:String):Bool {
		
		#if flash
		
		return className.exists (id);
		
		#elseif html5
		
		var requestedType = type != null ? cast (type, AssetType) : null;
		
		var symbolPath = path.get (id);
		
		return switch (requestedType) {
			
			case FONT:
				
				className.exists (id);
			
			case IMAGE:
				
				Preloader.images.exists (symbolPath);
			
			case MUSIC, SOUND:
				
				Preloader.audioBuffers.exists (symbolPath);
			
			case TEXT:
				
				Preloader.textLoaders.exists (symbolPath);
			
			default:
				
				Preloader.loaders.exists (symbolPath) || Preloader.textLoaders.exists (symbolPath);
			
		}
		
		#else
		
		return true;
		
		#end
		
	}
	
	
	public override function list (type:String):Array<String> {
		
		var requestedType = type != null ? cast (type, AssetType) : null;
		var items = [];
		
		for (id in this.type.keys ()) {
			
			if (requestedType == null || exists (id, type)) {
				
				items.push (id);
				
			}
			
		}
		
		return items;
		
	}
	
	
	public override function loadAudioBuffer (id:String):Future<AudioBuffer> {
		
		var promise = new Promise<AudioBuffer> ();
		
		if (Assets.isLocal (id)) {
			
			promise.completeWith (new Future<AudioBuffer> (function () return getAudioBuffer (id), true));
			
		} else if (path.exists (id)) {
			
			promise.completeWith (AudioBuffer.loadFromFile (path.get (id)));
			
		} else {
			
			promise.error (null);
			
		}
		
		return promise.future;
		
	}
	
	
	public override function loadBytes (id:String):Future<Bytes> {
		
		var promise = new Promise<Bytes> ();
		
		#if flash
		
		if (path.exists (id)) {
			
			var loader = new URLLoader ();
			loader.dataFormat = flash.net.URLLoaderDataFormat.BINARY;
			loader.addEventListener (Event.COMPLETE, function (event:Event) {
				
				var bytes = Bytes.ofData (loader.data);
				promise.complete (bytes);
				
			});
			loader.addEventListener (ProgressEvent.PROGRESS, function (event) {
				
				promise.progress (event.bytesLoaded, event.bytesTotal);
				
			});
			loader.addEventListener (IOErrorEvent.IO_ERROR, promise.error);
			loader.load (new URLRequest (path.get (id)));
			
		} else {
			
			promise.complete (getBytes (id));
			
		}
		
		#elseif html5
		
		if (path.exists (id)) {
			
			var request = new HTTPRequest<Bytes> ();
			promise.completeWith (request.load (path.get (id) + "?" + Assets.cache.version));
			
		} else {
			
			promise.complete (getBytes (id));
			
		}
		
		#else
		
		promise.completeWith (new Future<Bytes> (function () return getBytes (id), true));
		
		#end
		
		return promise.future;
		
	}
	
	
	public override function loadImage (id:String):Future<Image> {
		
		var image = super.loadImage (id);
		
		#if html5
		
		if (path.exists (id)) {
			
			var uri = path.get (id);
			image.onError (function (e) trace(e));
			image.onComplete (function (img) Preloader.images.set (uri, img));
			
		}
		
		#end
		
		return image;
		
	}
	
	
	#if (!flash && !html5)
	private function loadManifest ():Void {
		
		try {
			
			#if blackberry
			var bytes = Bytes.readFile ("app/native/manifest");
			#elseif tizen
			var bytes = Bytes.readFile ("../res/manifest");
			#elseif emscripten
			var bytes = Bytes.readFile ("assets/manifest");
			#elseif (mac && java)
			var bytes = Bytes.readFile ("../Resources/manifest");
			#elseif (ios || tvos)
			var bytes = Bytes.readFile ("assets/manifest");
			#else
			var bytes = Bytes.readFile ("manifest");
			#end
			
			if (bytes != null) {
				
				if (bytes.length > 0) {
					
					var data = bytes.getString (0, bytes.length);
					
					if (data != null && data.length > 0) {
						
						var manifest:Array<Dynamic> = Unserializer.run (data);
						
						for (asset in manifest) {
							
							if (!className.exists (asset.id)) {
								
								#if (ios || tvos)
								path.set (asset.id, "assets/" + asset.path);
								#else
								path.set (asset.id, asset.path);
								#end
								type.set (asset.id, cast (asset.type, AssetType));
								
							}
							
						}
						
					}
					
				}
				
			} else {
				
				Log.warn ("Could not load asset manifest (bytes was null)");
				
			}
		
		} catch (e:Dynamic) {
			
			Log.warn ('Could not load asset manifest (${e})');
			
		}
		
	}
	#end
	
	
	public override function loadText (id:String):Future<String> {
		
		#if html5
		
		var promise = new Promise<String> ();
		
		if (path.exists (id)) {
			
			var path = path.get (id);
			var request;
			if (Preloader.textLoaders.exists (path)) {

				request = Preloader.textLoaders.get (path);

			} else {

				request = new HTTPRequest<String> ();
				Preloader.textLoaders.set (path, request);

			}
			
			promise.completeWith (request.load (path + "?" + Assets.cache.version));
			
		} else {
			
			promise.complete (getText (id));
			
		}
		
		return promise.future;
		
		#else
		
		return super.loadText (id);
		
		#end
		
	}
	
	
}


#if !display
#if flash

::foreach assets::::if (embed)::::if (type == "image")::@:keep @:bind #if display private #end class __ASSET__::flatName:: extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }::else::@:keep @:bind #if display private #end class __ASSET__::flatName:: extends ::flashClass:: { }::end::::end::
::end::

#elseif html5

::foreach assets::::if (type == "font")::@:keep #if display private #end class __ASSET__::flatName:: extends lime.text.Font { public function new () { super (); name = "::fontName::"; } } ::end::
::end::

#else

::if (assets != null)::::foreach assets::::if (!embed)::::if (type == "font")::@:keep #if display private #end class __ASSET__::flatName:: extends lime.text.Font { public function new () { __fontPath = #if (ios || tvos) "assets/" + #end "::targetPath::"; name = "::fontName::"; super (); }}
::end::::end::::end::::end::

#if (windows || mac || linux || cpp)

::if (assets != null)::
::foreach assets::::if (embed)::::if (type == "image")::@:image("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.graphics.Image {}
::elseif (type == "sound")::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.utils.Bytes {}
::elseif (type == "music")::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.utils.Bytes {}
::elseif (type == "font")::@:font("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.text.Font {}
::else::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.utils.Bytes {}
::end::::end::::end::
::end::

#end
#end

#if (openfl && !flash)
::if (assets != null)::::foreach assets::::if (type == "font")::@:keep #if display private #end class __ASSET__OPENFL__::flatName:: extends openfl.text.Font { public function new () { ::if (embed)::var font = new __ASSET__::flatName:: (); src = font.src; name = font.name;::else::__fontPath = #if (ios || tvos) "assets/" + #end "::targetPath::"; name = "::fontName::";::end:: super (); }}
::end::::end::::end::
#end

#end
