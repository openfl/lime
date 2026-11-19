package utils;

#if sys
import haxe.io.Bytes;
import lime.app.Future;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.AssetType;
import lime.utils.Log;
import lime.utils.PackedAssetLibrary;
import sys.FileSystem;
import sys.io.File;
#if lime_cffi
import lime.graphics.Image;
import lime.graphics.ImageFileFormat;
#end
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	A library made from a manifest has an asset for each the manifest lists, read
	from the file its path names under the manifest's root path. `load()` loads the
	assets marked to preload, and completes with the library.
**/
class AssetLibraryTest extends Test
{
	#if sys
	private static inline var TEXT_SIZE = 5;

	private var binary:Bytes;
	private var files:AssetTestFiles;
	#end

	public function new()
	{
		super();
	}

	#if sys
	public function setupClass():Void
	{
		files = new AssetTestFiles("library");
		files.writeText("a.txt", "alpha");

		binary = Bytes.alloc(256);
		for (i in 0...binary.length)
		{
			binary.set(i, i);
		}
		files.write("data.bin", binary);

		#if lime_cffi
		files.write("image.png", new Image(null, 0, 0, 2, 3, 0xFF0000FF).encode(PNG));
		files.copy("assets/mono.ttf", "mono.ttf");
		files.copy("assets/tone.wav", "tone.wav");
		#end
	}

	public function teardownClass():Void
	{
		files.remove();
	}

	public function teardown():Void
	{
		Log.throwErrors = true;
	}

	public function testManifestLibrariesHaveEachAssetAsItsType():Void
	{
		var library = everyType();

		Assert.isTrue(library.exists("text", AssetType.TEXT));
		Assert.isTrue(library.exists("binary", AssetType.BINARY));
		Assert.isTrue(library.exists("text", null));
		Assert.isTrue(library.exists("binary", null));
		Assert.isFalse(library.exists("missing", null));
		Assert.isFalse(library.exists("missing", AssetType.TEXT));

		#if lime_cffi
		Assert.isTrue(library.exists("image", AssetType.IMAGE));
		Assert.isTrue(library.exists("font", AssetType.FONT));
		Assert.isTrue(library.exists("sound", AssetType.SOUND));
		#end
	}

	public function testExistsMatchesTheType():Void
	{
		var library = everyType();

		Assert.isFalse(library.exists("text", AssetType.FONT), "a text asset exists as a font");
		Assert.isFalse(library.exists("text", AssetType.IMAGE), "a text asset exists as an image");
		Assert.isFalse(library.exists("binary", AssetType.SOUND), "a binary asset exists as a sound");

		#if lime_cffi
		Assert.isFalse(library.exists("image", AssetType.FONT), "an image exists as a font");
		Assert.isFalse(library.exists("font", AssetType.IMAGE), "a font exists as an image");
		#end
	}

	public function testTextAndBinaryAssetsRead():Void
	{
		var library = everyType();

		Assert.equals("alpha", library.getText("text"));
		Assert.isTrue(AssetTestFiles.sameBytes(binary, library.getBytes("binary")), "getBytes() gave other bytes");
		Assert.isTrue(AssetTestFiles.sameBytes(Bytes.ofString("alpha"), library.getBytes("text")), "a text asset gave other bytes");
	}

	#if lime_cffi
	public function testImageFontAndSoundAssetsRead():Void
	{
		var library = everyType();

		var image = library.getImage("image");
		Assert.notNull(image);
		if (image != null)
		{
			Assert.equals(2, image.width);
			Assert.equals(3, image.height);
		}

		var font = library.getFont("font");
		Assert.notNull(font);
		if (font != null) Assert.isTrue(font.unitsPerEM > 0);

		var sound = library.getAudioBuffer("sound");
		Assert.notNull(sound);
		if (sound != null) Assert.notNull(sound.data);
	}
	#end

	public function testListGivesTheIdsOfAType():Void
	{
		var library = everyType();

		// Binary assets can be read as text too, so exists() and list() give them for TEXT
		var text = library.list(AssetType.TEXT);
		Assert.contains("text", text);
		for (id in text)
		{
			Assert.isTrue(library.exists(id, AssetType.TEXT), "list() gave \"" + id + "\", which exists() doesn't find as text");
		}

		var all = library.list(null);
		Assert.contains("text", all);
		Assert.contains("binary", all);

		#if lime_cffi
		Assert.same(["image"], library.list(AssetType.IMAGE));
		Assert.same(["font"], library.list(AssetType.FONT));
		Assert.same(["sound"], library.list(AssetType.SOUND));
		Assert.equals(5, all.length);
		#end
	}

	public function testGetPathIsUnderTheRootPath():Void
	{
		var path = everyType().getPath("text");
		Assert.notNull(path);
		if (path != null) Assert.equals("alpha", File.getContent(path));
	}

	@:timeout(5000)
	public function testLoadersGiveWhatGettersGive(async:Async):Void
	{
		var library = everyType();
		var pending = 2;
		function finish():Void
		{
			if (--pending == 0) async.done();
		}
		function failed(what:String):Dynamic->Void
		{
			return function(error)
			{
				Assert.fail(what + " failed: " + error);
				finish();
			};
		}

		library.loadText("text").onComplete(function(text)
		{
			Assert.equals("alpha", text);
			finish();
		}).onError(failed("loadText()"));

		library.loadBytes("binary").onComplete(function(bytes)
		{
			Assert.isTrue(AssetTestFiles.sameBytes(binary, bytes), "loadBytes() gave other bytes");
			finish();
		}).onError(failed("loadBytes()"));

		#if lime_cffi
		pending += 3;

		library.loadImage("image").onComplete(function(image)
		{
			Assert.notNull(image);
			if (image != null) Assert.equals(3, image.height);
			finish();
		}).onError(failed("loadImage()"));

		library.loadFont("font").onComplete(function(font)
		{
			Assert.notNull(font);
			finish();
		}).onError(failed("loadFont()"));

		library.loadAudioBuffer("sound").onComplete(function(sound)
		{
			Assert.notNull(sound);
			if (sound != null) Assert.notNull(sound.data);
			finish();
		}).onError(failed("loadAudioBuffer()"));
		#end
	}

	@:timeout(5000)
	public function testPreloadedAssetsLoadWithTheLibrary(async:Async):Void
	{
		files.writeText("preload/a.txt", "alpha");
		files.writeText("preload/b.txt", "beta");

		// b's size is large enough that progress counting it would show
		var library = AssetTestFiles.library(files.path("preload"), [
			{id: "a", path: "a.txt", size: TEXT_SIZE, type: "TEXT", preload: true},
			{id: "b", path: "b.txt", size: 1000000, type: "TEXT", preload: false}
		]);

		var progress = [];
		library.load().onProgress(function(loaded, total) progress.push({loaded: loaded, total: total})).onComplete(function(loaded)
		{
			Assert.equals(library, loaded, "load() completed with another library");

			// What was preloaded is kept, not read again
			files.delete("preload/a.txt");
			Assert.equals("alpha", library.getText("a"), "the preloaded asset wasn't kept");
			Assert.isTrue(library.isLocal("a", AssetType.TEXT));

			Assert.isTrue(progress.length > 0, "load() reported no progress");
			if (progress.length > 0)
			{
				var last = progress[progress.length - 1];
				Assert.equals(last.total, last.loaded, "load() completed at " + last.loaded + "/" + last.total);
				Assert.isTrue(last.total < 1000000, "the asset that isn't preloaded was counted: " + last.loaded + "/" + last.total);
			}

			async.done();
		}).onError(function(error)
		{
			Assert.fail("load() failed: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testLibrariesWithNothingToPreloadLoad(async:Async):Void
	{
		var library = everyType();

		library.load().onComplete(function(loaded)
		{
			Assert.equals(library, loaded);
			async.done();
		}).onError(function(error)
		{
			Assert.fail("load() failed: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testLoadingFailsForAMissingPreloadedAsset(async:Async):Void
	{
		var library = AssetTestFiles.library(files.directory, [
			{id: "text", path: "a.txt", size: TEXT_SIZE, type: "TEXT", preload: true},
			{id: "gone", path: "gone.txt", size: TEXT_SIZE, type: "TEXT", preload: true}
		]);

		library.load().onComplete(function(_)
		{
			Assert.fail("load() completed without a preloaded asset");
			async.done();
		}).onError(function(error)
		{
			var message = Std.string(error);
			Assert.isTrue(message.indexOf("gone") > -1, "the error doesn't name the asset: " + message);
			async.done();
		});
	}

	@:timeout(5000)
	public function testUnloadingDropsWhatWasPreloaded(async:Async):Void
	{
		files.writeText("unload/a.txt", "alpha");
		var library = AssetTestFiles.library(files.path("unload"), [{id: "a", path: "a.txt", size: TEXT_SIZE, type: "TEXT", preload: true}]);

		library.load().onComplete(function(_)
		{
			files.delete("unload/a.txt");
			library.unload();

			Log.throwErrors = false;
			var text = library.getText("a");
			Log.throwErrors = true;
			Assert.isNull(text, "the unloaded library still gave the preloaded text");
			async.done();
		}).onError(function(error)
		{
			Assert.fail("load() failed: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	@Ignored("Waiting on #2158")
	public function testLibrariesLoadAgainAfterUnloading(async:Async):Void
	{
		files.writeText("again/a.txt", "alpha");
		var library = AssetTestFiles.library(files.path("again"), [{id: "a", path: "a.txt", size: TEXT_SIZE, type: "TEXT", preload: true}]);

		library.load().onComplete(function(_)
		{
			library.unload();

			library.load().onComplete(function(_)
			{
				// What was preloaded again is kept, not read again
				files.delete("again/a.txt");

				Log.throwErrors = false;
				var text = library.getText("a");
				Log.throwErrors = true;
				Assert.equals("alpha", text, "load() after unload() didn't preload the asset again");
				async.done();
			}).onError(function(error)
			{
				Assert.fail("load() after unload() failed: " + error);
				async.done();
			});
		}).onError(function(error)
		{
			Assert.fail("load() failed: " + error);
			async.done();
		});
	}

	#if lime_cffi
	// The changelog: "Changed asset libraries to drop disposed AudioBuffer objects from their caches"
	@:timeout(5000)
	public function testDisposedPreloadedSoundsAreNotGivenAgain(async:Async):Void
	{
		var library = AssetTestFiles.library(files.directory, [
			{id: "sound", path: "tone.wav", size: FileSystem.stat(files.path("tone.wav")).size, type: "SOUND", preload: true}
		]);

		library.load().onComplete(function(_)
		{
			var sound = library.getAudioBuffer("sound");
			Assert.notNull(sound);

			if (sound != null)
			{
				Assert.equals(sound, library.getAudioBuffer("sound"), "the preloaded sound wasn't kept");
				sound.dispose();

				var fresh = library.getAudioBuffer("sound");
				Assert.notNull(fresh);
				Assert.notEquals(sound, fresh, "the library gave its disposed sound");
				if (fresh != null) Assert.notNull(fresh.data, "the sound given after disposing has no data");
			}

			async.done();
		}).onError(function(error)
		{
			Assert.fail("load() failed: " + error);
			async.done();
		});
	}
	#end

	public function testFromManifestMakesTheLibraryTypeNamed():Void
	{
		var manifest = AssetTestFiles.manifest(files.directory, []);
		manifest.libraryType = "lime.utils.PackedAssetLibrary";
		manifest.libraryArgs = ["lib/none.pak", "pak"];

		Assert.isOfType(AssetLibrary.fromManifest(manifest), PackedAssetLibrary);
	}

	public function testFromManifestGivesNullForAnUnknownLibraryType():Void
	{
		var manifest = AssetTestFiles.manifest(files.directory, []);
		manifest.libraryType = "no.such.AssetLibrary";

		Assert.isNull(AssetLibrary.fromManifest(manifest));
	}

	public function testFromManifestGivesNullForNoManifest():Void
	{
		Assert.isNull(AssetLibrary.fromManifest(null));
	}

	public function testFromFileReadsAManifestFile():Void
	{
		var path = files.writeText("file.json", textManifest(null).serialize());
		var library = AssetLibrary.fromFile(path);

		Assert.notNull(library);
		if (library != null) Assert.equals("alpha", library.getText("text"));
	}

	public function testFromFileGivesNullForAMissingFile():Void
	{
		Assert.isNull(AssetLibrary.fromFile(files.path("missing.json")));
	}

	public function testFromBytesReadsAManifest():Void
	{
		var library = AssetLibrary.fromBytes(Bytes.ofString(textManifest(null).serialize()), files.directory);

		Assert.notNull(library);
		if (library != null) Assert.equals("alpha", library.getText("text"));
	}

	@:timeout(5000)
	public function testLoadFromFileCompletesWithALoadedLibrary(async:Async):Void
	{
		var path = files.writeText("loaded.json", textManifest(null).serialize());

		AssetLibrary.loadFromFile(path).onComplete(function(library)
		{
			Assert.notNull(library);
			if (library != null) Assert.equals("alpha", library.getText("text"));
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadFromFile() failed: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testLoadFromManifestCompletesWithALoadedLibrary(async:Async):Void
	{
		AssetLibrary.loadFromManifest(textManifest(files.directory)).onComplete(function(library)
		{
			Assert.notNull(library);
			if (library != null) Assert.equals("alpha", library.getText("text"));
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadFromManifest() failed: " + error);
			async.done();
		});
	}

	// The changelog: "asset library load errors ... say which bundle or manifest failed to load, and why"
	@:timeout(5000)
	public function testLoadFromFileNamesAMissingManifest(async:Async):Void
	{
		var future:Future<AssetLibrary> = null;

		try
		{
			future = AssetLibrary.loadFromFile(files.path("missing.json"));
		}
		catch (e:Dynamic)
		{
			Assert.fail("loadFromFile() threw rather than failing its future: " + e);
			async.done();
			return;
		}

		future.onComplete(function(library)
		{
			Assert.fail("loadFromFile() completed for a missing manifest, with " + library);
			async.done();
		}).onError(function(error)
		{
			Assert.stringContains("missing.json", Std.string(error), "the error doesn't name the manifest: " + error);
			async.done();
		});
	}

	private function everyType():AssetLibrary
	{
		var assets:Array<Dynamic> = [
			{id: "text", path: "a.txt", size: TEXT_SIZE, type: "TEXT"},
			{id: "binary", path: "data.bin", size: binary.length, type: "BINARY"}
		];

		#if lime_cffi
		assets.push({id: "image", path: "image.png", size: FileSystem.stat(files.path("image.png")).size, type: "IMAGE"});
		assets.push({id: "font", path: "mono.ttf", size: FileSystem.stat(files.path("mono.ttf")).size, type: "FONT"});
		assets.push({id: "sound", path: "tone.wav", size: FileSystem.stat(files.path("tone.wav")).size, type: "SOUND"});
		#end

		return AssetTestFiles.library(files.directory, assets);
	}

	private function textManifest(rootPath:String):AssetManifest
	{
		return AssetTestFiles.manifest(rootPath, [{id: "text", path: "a.txt", size: TEXT_SIZE, type: "TEXT"}]);
	}
	#end
}
