package lime.utils;

import haxe.io.Bytes;
import haxe.io.Path;
import lime.app.Event;
import lime.app.Future;
import lime.app.Promise;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.net.HTTPRequest;
import lime.text.Font;
import lime.utils.AssetType;
import lime.utils.Bytes;
#if flash
import flash.display.BitmapData;
import flash.media.Sound;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:keep class PackedAssetLibrary extends AssetLibrary
{
	@:noCompletion private var id:String;
	@:noCompletion private var lengths = new Map<String, Int>();
	@:noCompletion private var packedData:Bytes;
	@:noCompletion private var positions = new Map<String, Int>();
	@:noCompletion private var type:String;
	@:noCompletion private var rootPath:String;

	public function new(id:String, type:String)
	{
		super();

		this.id = id;
		this.type = type;
	}

	public static function fromBytes(bytes:Bytes, rootPath:String = null):PackedAssetLibrary
	{
		return cast fromManifest(AssetManifest.fromBytes(bytes, rootPath));
	}

	public static function fromFile(path:String, rootPath:String = null):PackedAssetLibrary
	{
		return cast fromManifest(AssetManifest.fromFile(path, rootPath));
	}

	public static function fromManifest(manifest:AssetManifest):PackedAssetLibrary
	{
		return cast AssetLibrary.fromManifest(manifest);
	}

	public override function getAudioBuffer(id:String):AudioBuffer
	{
		#if (js && html5)
		return super.getAudioBuffer(id);
		#else
		if (cachedAudioBuffers.exists(id))
		{
			return cachedAudioBuffers.get(id);
		}
		else
		{
			// TODO: More efficient method
			var bytes = Bytes.alloc(lengths[id]);
			bytes.blit(0, packedData, positions[id], lengths[id]);
			if (type == "gzip") bytes = bytes.decompress(GZIP);
			else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
			return AudioBuffer.fromBytes(bytes);
		}
		#end
	}

	public override function getBytes(id:String):Bytes
	{
		if (cachedBytes.exists(id))
		{
			return cachedBytes.get(id);
		}
		else if (cachedText.exists(id))
		{
			var bytes = Bytes.ofString(cachedText.get(id));
			cachedBytes.set(id, bytes);
			return bytes;
		}
		else
		{
			var bytes = Bytes.alloc(lengths[id]);
			bytes.blit(0, packedData, positions[id], lengths[id]);
			if (type == "gzip") bytes = bytes.decompress(GZIP);
			else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
			return bytes;
		}
	}

	public override function getFont(id:String):Font
	{
		#if (js && html5)
		return super.getFont(id);
		#else
		if (cachedFonts.exists(id))
		{
			return cachedFonts.get(id);
		}
		else
		{
			// TODO: More efficient method
			var bytes = Bytes.alloc(lengths[id]);
			bytes.blit(0, packedData, positions[id], lengths[id]);
			if (type == "gzip") bytes = bytes.decompress(GZIP);
			else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
			return Font.fromBytes(bytes);
		}
		#end
	}

	public override function getImage(id:String):Image
	{
		if (cachedImages.exists(id))
		{
			return cachedImages.get(id);
		}
		else
		{
			// TODO: More efficient method
			var bytes = Bytes.alloc(lengths[id]);
			bytes.blit(0, packedData, positions[id], lengths[id]);
			if (type == "gzip") bytes = bytes.decompress(GZIP);
			else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
			return Image.fromBytes(bytes);
		}
	}

	public override function getText(id:String):String
	{
		if (cachedText.exists(id))
		{
			return cachedText.get(id);
		}
		else if (type == "gzip" || type == "zip" || type == "deflate")
		{
			var bytes = Bytes.alloc(lengths[id]);
			bytes.blit(0, packedData, positions[id], lengths[id]);
			if (type == "gzip") bytes = bytes.decompress(GZIP);
			else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
			return bytes.getString(0, bytes.length);
		}
		else
		{
			return packedData.getString(positions[id], lengths[id]);
		}
	}

	public override function isLocal(id:String, type:String):Bool
	{
		return true;
	}

	public override function load():Future<AssetLibrary>
	{
		if (loaded)
		{
			return Future.withValue(cast this);
		}

		if (promise == null)
		{
			promise = new Promise<AssetLibrary>();

			// TODO: Handle `preload` for individual assets
			// TODO: Do not preload bytes on native, if we can read from it instead (all non-Android targets?)

			var packedData_onComplete = function(data:Bytes)
			{
				cachedBytes.set(id, data);
				packedData = data;

				assetsLoaded = 0;
				assetsTotal = 1;

				for (id in preload.keys())
				{
					if (!preload.get(id)) continue;

					Log.verbose("Preloading asset: " + id + " [" + types.get(id) + "]");

					switch (types.get(id))
					{
						case BINARY:
							assetsTotal++;

							var future = loadBytes(id);
							// future.onProgress (load_onProgress.bind (id));
							future.onError(load_onError.bind(id));
							future.onComplete(loadBytes_onComplete.bind(id));

						case FONT:
							assetsTotal++;

							var future = loadFont(id);
							// future.onProgress (load_onProgress.bind (id));
							future.onError(load_onError.bind(id));
							future.onComplete(loadFont_onComplete.bind(id));

						case IMAGE:
							assetsTotal++;

							var future = loadImage(id);
							// future.onProgress (load_onProgress.bind (id));
							future.onError(load_onError.bind(id));
							future.onComplete(loadImage_onComplete.bind(id));

						case MUSIC, SOUND:
							assetsTotal++;

							var future = loadAudioBuffer(id);
							// future.onProgress (load_onProgress.bind (id));
							future.onError(load_onError.bind(id));
							future.onComplete(loadAudioBuffer_onComplete.bind(id));

						case TEXT:
							assetsTotal++;

							var future = loadText(id);
							// future.onProgress (load_onProgress.bind (id));
							future.onError(load_onError.bind(id));
							future.onComplete(loadText_onComplete.bind(id));

						default:
					}
				}

				__assetLoaded(null);
			};

			if (cachedBytes.exists(id))
			{
				packedData_onComplete(cachedBytes.get(id));
			}
			else
			{
				var basePath = rootPath == null || rootPath == "" ?  "" : Path.addTrailingSlash(rootPath);
				var libPath = paths.exists(id) ? paths.get(id) : id;

				var path = Path.join([basePath, libPath]);
				path = __cacheBreak(path);

				Bytes.loadFromFile(path).onError(promise.error).onComplete(packedData_onComplete);
			}
		}

		return promise.future;
	}

	public override function loadAudioBuffer(id:String):Future<AudioBuffer>
	{
		#if (js && html5)
		return super.loadAudioBuffer(id);
		#else
		if (cachedAudioBuffers.exists(id))
		{
			return Future.withValue(cachedAudioBuffers.get(id));
		}
		else
		{
			// TODO: More efficient method, use `loadFromBytes` method
			var bytes = Bytes.alloc(lengths[id]);
			bytes.blit(0, packedData, positions[id], lengths[id]);
			if (type == "gzip") bytes = bytes.decompress(GZIP);
			else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
			return Future.withValue(AudioBuffer.fromBytes(bytes));
		}
		#end
	}

	public override function loadBytes(id:String):Future<Bytes>
	{
		if (cachedBytes.exists(id))
		{
			return Future.withValue(cachedBytes.get(id));
		}
		else
		{
			// TODO: More efficient method
			var bytes = Bytes.alloc(lengths[id]);
			bytes.blit(0, packedData, positions[id], lengths[id]);
			if (type == "gzip") bytes = bytes.decompress(GZIP);
			else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
			return Future.withValue(bytes);
		}
	}

	public override function loadFont(id:String):Future<Font>
	{
		#if (js && html5)
		return super.loadFont(id);
		#else
		if (cachedFonts.exists(id))
		{
			return Future.withValue(cachedFonts.get(id));
		}
		else
		{
			// TODO: More efficient method
			var bytes = Bytes.alloc(lengths[id]);
			bytes.blit(0, packedData, positions[id], lengths[id]);
			if (type == "gzip") bytes = bytes.decompress(GZIP);
			else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
			return Font.loadFromBytes(bytes);
		}
		#end
	}

	public static function loadFromBytes(bytes:Bytes, rootPath:String = null):Future<PackedAssetLibrary>
	{
		return AssetLibrary.loadFromBytes(bytes, rootPath).then(function(library)
		{
			var assetLibrary:PackedAssetLibrary = cast library;
			return Future.withValue(assetLibrary);
		});
	}

	public static function loadFromFile(path:String, rootPath:String = null):Future<PackedAssetLibrary>
	{
		return AssetLibrary.loadFromFile(path, rootPath).then(function(library)
		{
			var assetLibrary:PackedAssetLibrary = cast library;
			return Future.withValue(assetLibrary);
		});
	}

	public static function loadFromManifest(manifest:AssetManifest):Future<PackedAssetLibrary>
	{
		return AssetLibrary.loadFromManifest(manifest).then(function(library)
		{
			var assetLibrary:PackedAssetLibrary = cast library;
			return Future.withValue(assetLibrary);
		});
	}

	public override function loadImage(id:String):Future<Image>
	{
		if (cachedImages.exists(id))
		{
			return Future.withValue(cachedImages.get(id));
		}
		else
		{
			// TODO: More efficient method
			var bytes = Bytes.alloc(lengths[id]);
			bytes.blit(0, packedData, positions[id], lengths[id]);
			if (type == "gzip") bytes = bytes.decompress(GZIP);
			else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
			return Image.loadFromBytes(bytes);
		}
	}

	public override function loadText(id:String):Future<String>
	{
		if (cachedText.exists(id))
		{
			return Future.withValue(cachedText.get(id));
		}
		else if (cachedBytes.exists(id))
		{
			var bytes = getBytes(id);

			if (bytes == null)
			{
				return cast Future.withValue(null);
			}
			else
			{
				var text = bytes.getString(0, bytes.length);
				cachedText.set(id, text);
				return Future.withValue(text);
			}
		}
		else if (type == "gzip" || type == "deflate")
		{
			var bytes = Bytes.alloc(lengths[id]);
			bytes.blit(0, packedData, positions[id], lengths[id]);
			if (type == "gzip") bytes = bytes.decompress(GZIP);
			else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
			return Future.withValue(bytes.getString(0, bytes.length));
		}
		else
		{
			return Future.withValue(packedData.getString(positions[id], lengths[id]));
		}
	}

	public override function unload():Void {}

	@:noCompletion private override function __fromManifest(manifest:AssetManifest):Void
	{
		rootPath = manifest.rootPath;

		super.__fromManifest(manifest);

		for (asset in manifest.assets)
		{
			if (Reflect.hasField(asset, "position"))
			{
				positions.set(asset.id, Reflect.field(asset, "position"));
			}

			if (Reflect.hasField(asset, "length"))
			{
				lengths.set(asset.id, Reflect.field(asset, "length"));
			}
		}
	}

	@:noCompletion private override function __assetLoaded(id:String):Void
	{
		assetsLoaded++;

		if (id != null)
		{
			Log.verbose("Loaded asset: " + id + " [" + types.get(id) + "] (" + (assetsLoaded - 1) + "/" + (assetsTotal - 1) + ")");
		}

		// if (id != null) {

		// 	var size = sizes.get (id);

		// 	if (!bytesLoadedCache.exists (id)) {

		// 		bytesLoaded += size;

		// 	} else {

		// 		var cache = bytesLoadedCache.get (id);

		// 		if (cache < size) {

		// 			bytesLoaded += (size - cache);

		// 		}

		// 	}

		// 	bytesLoadedCache.set (id, size);

		// }

		if (assetsLoaded < assetsTotal)
		{
			// promise.progress (bytesLoaded, bytesTotal);
		}
		else
		{
			loaded = true;
			// promise.progress (bytesTotal, bytesTotal);
			promise.complete(this);
		}
	}
}
