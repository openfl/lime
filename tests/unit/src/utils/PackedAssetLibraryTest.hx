package utils;

#if sys
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import lime.app.Future;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.AssetType;
import lime.utils.Assets;
import lime.utils.Bytes as LimeBytes;
import lime.utils.CompressionAlgorithm;
import lime.utils.PackedAssetLibrary;
#if lime_cffi
import lime.graphics.Image;
import lime.graphics.ImageFileFormat;
#end
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	A packed library keeps its assets in one file, which the command-line tools
	write as "lime-asset-pack" followed by each asset, compressed one by one for
	the deflate and gzip types. Its manifest names lime.utils.PackedAssetLibrary,
	with the pack's path and type as arguments, and gives each asset's position
	and length in the pack.
**/
class PackedAssetLibraryTest extends Test
{
	#if sys
	private static inline var NAME = "packedtest";

	private var binary:Bytes;
	private var files:AssetTestFiles;
	#if lime_cffi
	private var png:Bytes;
	#end
	#end

	public function new()
	{
		super();
	}

	#if sys
	public function setupClass():Void
	{
		files = new AssetTestFiles("packed");

		binary = Bytes.alloc(3000);
		for (i in 0...binary.length)
		{
			binary.set(i, (i * 13) & 0xFF);
		}

		#if lime_cffi
		png = new Image(null, 0, 0, 4, 5, 0x00FF00FF).encode(PNG);
		#end
	}

	public function teardownClass():Void
	{
		files.remove();
	}

	public function teardown():Void
	{
		if (Assets.hasLibrary(NAME)) Assets.unloadLibrary(NAME);
	}

	public function testPackedManifestsMakePackedLibraries():Void
	{
		Assert.isOfType(AssetLibrary.fromManifest(pack("made.pak", "pak")), PackedAssetLibrary);
		Assert.isOfType(PackedAssetLibrary.fromManifest(pack("made.pak", "pak")), PackedAssetLibrary);
	}

	@:timeout(5000)
	public function testUncompressedPacksRead(async:Async):Void
	{
		assertReads(pack("plain.pak", "pak"), async);
	}

	@:timeout(5000)
	public function testPackTypePacksRead(async:Async):Void
	{
		assertReads(pack("plain.pack", "pack"), async);
	}

	@:timeout(5000)
	public function testDeflatePacksRead(async:Async):Void
	{
		assertReads(pack("deflate.pak", "deflate"), async);
	}

	@:timeout(5000)
	public function testGzipPacksRead(async:Async):Void
	{
		assertReads(pack("gzip.pak", "gzip"), async);
	}

	// The tools write "zip" libraries as "deflate", and the library reads "zip" as "deflate" too
	@:timeout(5000)
	@Ignored("Waiting on #2159")
	public function testZipPacksRead(async:Async):Void
	{
		assertReads(pack("zip.pak", "zip"), async);
	}

	@:timeout(5000)
	public function testATrailingSlashOnTheRootPathIsAllowed(async:Async):Void
	{
		var manifest = pack("slash.pak", "pak");
		manifest.rootPath += "/";
		assertReads(manifest, async);
	}

	@:timeout(5000)
	public function testPackedLibrariesReportLoadProgress(async:Async):Void
	{
		var library = AssetLibrary.fromManifest(pack("progress.pak", "pak"));
		var progress = [];

		library.load().onProgress(function(loaded, total) progress.push({loaded: loaded, total: total})).onComplete(function(_)
		{
			Assert.isTrue(progress.length > 0, "load() reported no progress");

			if (progress.length > 0)
			{
				var last = progress[progress.length - 1];
				Assert.isTrue(last.total > 0, "load() reported progress out of " + last.total);
				Assert.equals(last.total, last.loaded, "load() completed at " + last.loaded + "/" + last.total);
			}

			async.done();
		}).onError(function(error)
		{
			Assert.fail("load() failed: " + error);
			async.done();
		});
	}

	// Loading the pack first, or failing the future, but not throwing out of a loader
	@:timeout(5000)
	@Ignored("Waiting on #2159")
	public function testLoadingAnAssetBeforeItsPackDoesNotThrow(async:Async):Void
	{
		var library = AssetLibrary.fromManifest(pack("early.pak", "deflate"));
		var future:Future<String> = null;

		try
		{
			future = library.loadText("text");
		}
		catch (e:Dynamic)
		{
			Assert.fail("loadText() threw before the library was loaded: " + e);
			async.done();
			return;
		}

		future.onComplete(function(text)
		{
			Assert.equals("alpha", text);
			async.done();
		}).onError(function(error)
		{
			Assert.notNull(error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testPackedLibrariesLoadFromManifestBytes(async:Async):Void
	{
		var manifest = pack("bytes.pak", "deflate");
		var rootPath = manifest.rootPath;
		manifest.rootPath = null;

		var library = PackedAssetLibrary.fromBytes(Bytes.ofString(manifest.serialize()), rootPath);
		Assert.notNull(library);
		if (library == null)
		{
			async.done();
			return;
		}

		library.load().onComplete(function(_)
		{
			Assert.equals("alpha", library.getText("text"));
			async.done();
		}).onError(function(error)
		{
			Assert.fail("load() failed: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testPackedAssetsAreFoundThroughAssets(async:Async):Void
	{
		var library = AssetLibrary.fromManifest(pack("assets.pak", "pak"));
		Assets.registerLibrary(NAME, library);

		Assets.loadLibrary(NAME).onComplete(function(_)
		{
			Assert.isTrue(Assets.exists(NAME + ":text", TEXT));
			Assert.equals("alpha", Assets.getText(NAME + ":text"));
			Assert.isTrue(AssetTestFiles.sameBytes(binary, Assets.getBytes(NAME + ":binary")));
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadLibrary() failed: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testAMissingPackIsNamedWhenItFailsToLoad(async:Async):Void
	{
		var manifest = pack("present.pak", "pak");
		manifest.libraryArgs = ["lib/absent.pak", "pak"];

		AssetLibrary.fromManifest(manifest).load().onComplete(function(_)
		{
			Assert.fail("load() completed without its pack");
			async.done();
		}).onError(function(error)
		{
			Assert.stringContains("absent.pak", Std.string(error), "the error doesn't name the pack: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	@Ignored("Waiting on #2191")
	public function testUnloadReleasesTheCachedAssetsAndThePack(async:Async):Void
	{
		var manifest = pack("unload.pak", "pak");
		var packPath:String = manifest.libraryArgs[0];

		// Preloaded assets are cached as the library loads
		for (asset in manifest.assets)
		{
			Reflect.setField(asset, "preload", true);
		}

		var library = AssetLibrary.fromManifest(manifest);

		library.load().onComplete(function(_)
		{
			// Until it's unloaded, a getter gives what the library cached, and the pack is kept under its own path
			var bytes = library.getBytes("binary");
			var packed = library.getBytes(packPath);
			Assert.isTrue(bytes != null && bytes == library.getBytes("binary"), "the bytes were not cached as the library loaded");
			Assert.isTrue(packed != null && packed == library.getBytes(packPath), "the pack was not kept as the library loaded");
			#if lime_cffi
			var image = library.getImage("image");
			Assert.isTrue(image != null && image == library.getImage("image"), "the image was not cached as the library loaded");
			#end

			library.unload();

			// AssetLibrary.unload() clears its caches, so a getter may read an asset again, but not give what was cached
			var kept = [];
			if (getQuietly(function() return library.getBytes("binary")) == bytes) kept.push("the bytes");
			if (getQuietly(function() return library.getBytes(packPath)) == packed) kept.push("the pack");
			#if lime_cffi
			if (getQuietly(function() return library.getImage("image")) == image) kept.push("the image");
			#end

			Assert.equals("", kept.join(", "), "unload() kept " + kept.join(", "));
			async.done();
		}).onError(function(error)
		{
			Assert.fail("load() failed: " + error);
			async.done();
		});
	}

	private static function getQuietly(get:Void->Dynamic):Dynamic
	{
		try
		{
			return get();
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	private function assertReads(manifest:AssetManifest, async:Async, ?pos:haxe.PosInfos):Void
	{
		var library = AssetLibrary.fromManifest(manifest);
		Assert.notNull(library, pos);

		if (library == null)
		{
			async.done();
			return;
		}

		library.load().onComplete(function(loaded)
		{
			Assert.equals(library, loaded, "load() completed with another library", pos);
			Assert.isTrue(library.exists("text", AssetType.TEXT), pos);
			Assert.isTrue(library.exists("binary", AssetType.BINARY), pos);
			Assert.isFalse(library.exists("text", AssetType.IMAGE), pos);
			Assert.isFalse(library.exists("missing", null), pos);
			Assert.equals("alpha", library.getText("text"), pos);
			Assert.isTrue(AssetTestFiles.sameBytes(binary, library.getBytes("binary")), "the packed asset gave other bytes", pos);
			Assert.contains("text", library.list(AssetType.TEXT), pos);
			Assert.contains("binary", library.list(AssetType.BINARY), pos);

			#if lime_cffi
			var image = library.getImage("image");
			Assert.notNull(image, "the packed image can't be read", pos);
			if (image != null) Assert.equals(5, image.height, pos);
			#end

			// The loaders give what the getters give
			library.loadText("text").onComplete(function(text)
			{
				Assert.equals("alpha", text, "loadText() gave other text", pos);

				library.loadBytes("binary").onComplete(function(bytes)
				{
					Assert.isTrue(AssetTestFiles.sameBytes(binary, bytes), "loadBytes() gave other bytes", pos);
					async.done();
				}).onError(function(error)
				{
					Assert.fail("loadBytes() failed: " + error, pos);
					async.done();
				});
			}).onError(function(error)
			{
				Assert.fail("loadText() failed: " + error, pos);
				async.done();
			});
		}).onError(function(error)
		{
			Assert.fail("load() failed: " + error, pos);
			async.done();
		});
	}

	// Packs the assets as the command-line tools do (AssetHelper.processPackedLibraries)
	private function pack(name:String, type:String):AssetManifest
	{
		var contents:Array<{id:String, type:String, data:Bytes}> = [
			{id: "text", type: "TEXT", data: Bytes.ofString("alpha")},
			{id: "binary", type: "BINARY", data: binary}
		];

		#if lime_cffi
		contents.push({id: "image", type: "IMAGE", data: png});
		#end

		var output = new BytesOutput();
		output.writeString("lime-asset-pack");
		var assets:Array<Dynamic> = [];

		for (asset in contents)
		{
			var data:Bytes = switch (type)
			{
				case "deflate", "zip": (asset.data : LimeBytes).compress(DEFLATE);
				case "gzip": (asset.data : LimeBytes).compress(GZIP);
				default: asset.data;
			}

			var position = output.length;
			output.writeBytes(data, 0, data.length);
			assets.push({id: asset.id, size: 0, type: asset.type, position: position, length: data.length});
		}

		files.write("lib/" + name, output.getBytes());

		var manifest = new AssetManifest();
		manifest.libraryType = "lime.utils.PackedAssetLibrary";
		manifest.libraryArgs = ["lib/" + name, type];
		manifest.rootPath = files.directory;
		manifest.assets = assets;
		return manifest;
	}
	#end
}
