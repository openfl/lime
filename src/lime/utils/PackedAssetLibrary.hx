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
	@:noCompletion private var packWaiters:Array<Dynamic->Void>;
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
			var bytes = __unpack(id);
			return bytes == null ? null : AudioBuffer.fromBytes(bytes);
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
			return __unpack(id);
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
			var bytes = __unpack(id);
			return bytes == null ? null : Font.fromBytes(bytes);
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
			var bytes = __unpack(id);
			return bytes == null ? null : Image.fromBytes(bytes);
		}
	}

	public override function getText(id:String):String
	{
		if (cachedText.exists(id))
		{
			return cachedText.get(id);
		}
		else
		{
			var bytes = __unpack(id);
			return bytes == null ? null : bytes.getString(0, bytes.length);
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
			bytesLoadedCache = new Map();

			// TODO: Handle `preload` for individual assets
			// TODO: Do not preload bytes on native, if we can read from it instead (all non-Android targets?)

			assetsLoaded = 0;
			assetsTotal = 2; // for our initial __assetLoaded(null) call and __assetLoaded(this.id)

			for (id in preload.keys())
			{
				if (!preload.get(id)) continue;

				switch (types.get(id))
				{
					case BINARY, FONT, IMAGE, TEXT:
						assetsTotal++;

					case MUSIC, SOUND:
						Log.verbose("Preloading asset: " + id + " [" + types.get(id) + "]");
						assetsTotal++;

						var future = loadAudioBuffer(id);
						future.onProgress(load_onProgress.bind(id));
						future.onError(loadAudioBuffer_onError.bind(id));
						future.onComplete(loadAudioBuffer_onComplete.bind(id));

					default:
				}
			}

			var packedData_onComplete = function(data:Bytes)
			{
				cachedBytes.set(id, data);
				packedData = data;
				__packLoaded(null);

				__assetLoaded(this.id);

				for (id in preload.keys())
				{
					if (!preload.get(id)) continue;

					switch (types.get(id))
					{
						case BINARY:
							Log.verbose("Preloading asset: " + id + " [" + types.get(id) + "]");
							var future = loadBytes(id);
							// future.onProgress (load_onProgress.bind (id));
							future.onError(load_onError.bind(id));
							future.onComplete(loadBytes_onComplete.bind(id));

						case FONT:
							Log.verbose("Preloading asset: " + id + " [" + types.get(id) + "]");
							var future = loadFont(id);
							// future.onProgress (load_onProgress.bind (id));
							future.onError(load_onError.bind(id));
							future.onComplete(loadFont_onComplete.bind(id));

						case IMAGE:
							Log.verbose("Preloading asset: " + id + " [" + types.get(id) + "]");
							var future = loadImage(id);
							// future.onProgress (load_onProgress.bind (id));
							future.onError(load_onError.bind(id));
							future.onComplete(loadImage_onComplete.bind(id));

						case TEXT:
							Log.verbose("Preloading asset: " + id + " [" + types.get(id) + "]");
							var future = loadText(id);
							// future.onProgress (load_onProgress.bind (id));
							future.onError(load_onError.bind(id));
							future.onComplete(loadText_onComplete.bind(id));

						default:
					}
				}
			};

			__assetLoaded(null);

			if (cachedBytes.exists(id))
			{
				packedData_onComplete(cachedBytes.get(id));
			}
			else
			{
				var basePath = rootPath == null || rootPath == "" ? "" : Path.addTrailingSlash(rootPath);
				var libPath = getPath(id);
				if (libPath == null) libPath = id;

				var path = Path.join([basePath, libPath]);
				path = __cacheBreak(path);

				var packedData_onProgress = load_onProgress.bind(this.id);

				Bytes.loadFromFile(path)
					.onProgress(packedData_onProgress)
					.onError(function(error)
					{
						__packLoaded(error);
						promise.error(error);
					})
					.onComplete(packedData_onComplete);
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
			return __whenPacked(id, function(bytes) return Future.withValue(AudioBuffer.fromBytes(bytes)));
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
			return __whenPacked(id, function(bytes) return Future.withValue(bytes));
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
			return __whenPacked(id, Font.loadFromBytes);
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
			return __whenPacked(id, Image.loadFromBytes);
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
		else
		{
			// Decompressed for every compressed type, "zip" included, as getText() does
			return __whenPacked(id, function(bytes) return Future.withValue(bytes.getString(0, bytes.length)));
		}
	}

	public override function unload():Void
	{
		super.unload();

		// The pack is released too, and read again by the next load()
		__packLoaded("The library was unloaded");
		packedData = null;
		loaded = false;
		promise = null;
	}

	// Tells what waits on the pack that it has loaded, or why it failed to
	@:noCompletion private function __packLoaded(error:Dynamic):Void
	{
		var waiters = packWaiters;
		packWaiters = null;

		if (waiters != null)
		{
			for (waiter in waiters)
			{
				waiter(error);
			}
		}
	}

	// The asset's bytes from the pack, decompressed, or null while there is no
	// pack, before load() has read it or after unload()
	@:noCompletion private function __unpack(id:String):Bytes
	{
		if (packedData == null) return null;

		var bytes = Bytes.alloc(lengths[id]);
		bytes.blit(0, packedData, positions[id], lengths[id]);
		if (type == "gzip") bytes = bytes.decompress(GZIP);
		else if (type == "zip" || type == "deflate") bytes = bytes.decompress(DEFLATE);
		return bytes;
	}

	// Reads the asset once the pack has loaded. While load() is reading the pack
	// it waits for it, and before load() is called it fails rather than throwing.
	@:noCompletion private function __whenPacked<T>(id:String, read:Bytes->Future<T>):Future<T>
	{
		if (packedData != null)
		{
			return read(__unpack(id));
		}

		if (promise == null)
		{
			return cast Future.withError("Cannot load asset \"" + id + "\" before its library is loaded");
		}

		var result = new Promise<T>();
		if (packWaiters == null) packWaiters = [];

		packWaiters.push(function(error:Dynamic)
		{
			if (error != null)
			{
				result.error(error);
			}
			else
			{
				result.completeWith(read(__unpack(id)));
			}
		});

		return result.future;
	}

	@:noCompletion private override function __fromManifest(manifest:AssetManifest):Void
	{
		rootPath = manifest.rootPath;

		super.__fromManifest(manifest);

		var packedBytesTotal = 0;
		bytesTotal = 0;

		for (asset in manifest.assets)
		{
			var id = asset.id;

			if (Reflect.hasField(asset, "position"))
			{
				positions.set(id, Reflect.field(asset, "position"));
			}

			if (Reflect.hasField(asset, "length"))
			{
				var length = Reflect.field(asset, "length");
				lengths.set(id, length);

				// for individual packed assets, the size represents the work done unpacking them
				// since this is likely to be much faster than downloading, set it to something
				// small like the packed length / 10.
				sizes.set(id, Math.floor(length / 10));

				packedBytesTotal += length;
			}

			if (preload.exists(id) && preload.get(id) && sizes.exists(id))
			{
				bytesTotal += sizes.get(id);
			}
		}

		sizes.set(this.id, packedBytesTotal);
		bytesTotal += packedBytesTotal;
	}

	@:noCompletion private override function __assetLoaded(id:String):Void
	{
		assetsLoaded++;

		if (id != null)
		{
			Log.verbose("Loaded asset: " + id + " [" + types.get(id) + "] (" + (assetsLoaded - 1) + "/" + (assetsTotal - 1) + ")");
		}

		if (id != null)
		{
			var size = sizes.exists(id) ? sizes.get(id) : 0;

			if (!bytesLoadedCache.exists(id))
			{
				bytesLoaded += size;
			}
			else
			{
				var cache = bytesLoadedCache.get(id);

				if (cache < size)
				{
					bytesLoaded += (size - cache);
				}
			}

			bytesLoadedCache.set(id, size);
		}

		if (assetsLoaded < assetsTotal)
		{
			promise.progress(bytesLoaded, bytesTotal);
		}
		else
		{
			loaded = true;
			promise.progress(bytesTotal, bytesTotal);
			promise.complete(this);
		}
	}
}
