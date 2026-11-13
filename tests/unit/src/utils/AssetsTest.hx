package utils;

#if sys
import haxe.io.Bytes;
import lime.app.Future;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.AssetType;
import lime.utils.Assets;
import lime.utils.Log;
import sys.FileSystem;
import sys.io.File;
#if lime_cffi
import lime.text.Font;
#end
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	The application's own assets, from `<assets path="assets" rename="assets" />`,
	are in the default library, which Assets looks in for IDs without a library
	name. Other libraries are registered, found, loaded and unloaded by name.
**/
class AssetsTest extends Test
{
	#if sys
	private static inline var LICENSE = "assets/mono-OFL.txt";
	private static inline var README = "assets/variable-README.md";
	private static inline var MONO = "assets/mono.ttf";
	private static inline var VARIABLE = "assets/variable.ttf";
	private static inline var TONE = "assets/tone.wav";
	private static inline var VIDEO = "assets/video.mp4";
	private static inline var MISSING = "assets/missing.txt";
	private static inline var NAME = "assetstest";

	private var defaultError:Dynamic;
	private var files:AssetTestFiles;
	#end

	public function new()
	{
		super();
	}

	#if sys
	public function setupClass(async:Async):Void
	{
		files = new AssetTestFiles("assets");
		async.setTimeout(10000);

		// The tests run before the application's preloader has loaded its library
		Assets.loadLibrary("default").onComplete(function(_) async.done()).onError(function(error)
		{
			defaultError = error;
			async.done();
		});
	}

	public function teardownClass():Void
	{
		files.remove();
	}

	public function teardown():Void
	{
		Log.throwErrors = true;
		Assets.cache.enabled = true;

		if (Assets.hasLibrary(NAME)) Assets.unloadLibrary(NAME);
	}

	public function testTheDefaultLibraryLoads():Void
	{
		Assert.isNull(defaultError, "Assets.loadLibrary(\"default\") failed: " + defaultError);
		Assert.isTrue(Assets.hasLibrary("default"));
		Assert.notNull(Assets.getLibrary("default"));
	}

	public function testAnEmptyLibraryNameIsTheDefaultLibrary():Void
	{
		// As registerLibrary() takes null or "" for the default library
		var library = Assets.getLibrary("default");
		Assert.equals(library, Assets.getLibrary(""));
		Assert.equals(library, Assets.getLibrary(null));
		Assert.isTrue(Assets.hasLibrary(""));
	}

	public function testShippedAssetsExist():Void
	{
		Assert.isTrue(Assets.exists(LICENSE));
		Assert.isTrue(Assets.exists(LICENSE, TEXT));
		Assert.isTrue(Assets.exists(MONO));
		Assert.isTrue(Assets.exists(MONO, FONT));
		Assert.isTrue(Assets.exists(TONE, SOUND));
		Assert.isTrue(Assets.exists(VIDEO, BINARY));
	}

	public function testExistsMatchesTheType():Void
	{
		Assert.isFalse(Assets.exists(LICENSE, FONT), "a text asset exists as a font");
		Assert.isFalse(Assets.exists(LICENSE, IMAGE), "a text asset exists as an image");
		Assert.isFalse(Assets.exists(MONO, IMAGE), "a font exists as an image");
		Assert.isFalse(Assets.exists(MONO, SOUND), "a font exists as a sound");
		Assert.isFalse(Assets.exists(VIDEO, FONT), "a binary asset exists as a font");
	}

	@Ignored("Waiting on #2158")
	public function testUnknownIdsDoNotExist():Void
	{
		Assert.isFalse(Assets.exists(MISSING));
		Assert.isFalse(Assets.exists(MISSING, TEXT));
		Assert.isFalse(Assets.exists("default:" + MISSING));
		Assert.isFalse(Assets.isLocal(MISSING));
	}

	public function testTextAssetsReadAsShipped():Void
	{
		Assert.equals(File.getContent(LICENSE), Assets.getText(LICENSE));
		Assert.equals(File.getContent(README), Assets.getText(README));
	}

	public function testBytesAreTheShippedFile():Void
	{
		Assert.isTrue(AssetTestFiles.sameBytes(File.getBytes(LICENSE), Assets.getBytes(LICENSE)), "getBytes() gave other bytes for a text asset");
		Assert.isTrue(AssetTestFiles.sameBytes(File.getBytes(VIDEO), Assets.getBytes(VIDEO)), "getBytes() gave other bytes for a binary asset");
	}

	public function testGetPathGivesTheShippedFile():Void
	{
		var path = Assets.getPath(LICENSE);
		Assert.notNull(path);
		if (path == null) return;

		Assert.isTrue(FileSystem.exists(path), path + " doesn't exist");
		if (FileSystem.exists(path)) Assert.equals(File.getContent(LICENSE), File.getContent(path));
	}

	public function testTheDefaultLibraryNameReachesTheSameAssets():Void
	{
		Assert.isTrue(Assets.exists("default:" + LICENSE, TEXT));
		Assert.equals(Assets.getText(LICENSE), Assets.getText("default:" + LICENSE));
		Assert.equals(Assets.getPath(LICENSE), Assets.getPath("default:" + LICENSE));
		Assert.isTrue(AssetTestFiles.sameBytes(Assets.getBytes(LICENSE), Assets.getBytes("default:" + LICENSE)));
	}

	public function testIdsWithoutALibraryNameLookOnlyInTheDefaultLibrary():Void
	{
		files.writeText("other/license.txt", "other");
		Assets.registerLibrary(NAME, AssetTestFiles.library(files.path("other"), [{id: LICENSE, path: "license.txt", type: "TEXT", size: 5}]));

		Assert.equals(File.getContent(LICENSE), Assets.getText(LICENSE));
		Assert.equals("other", Assets.getText(NAME + ":" + LICENSE));
	}

	public function testShippedAssetsAreLocal():Void
	{
		// The application's own files can be read at once, without loading them first
		Assert.isTrue(Assets.isLocal(LICENSE), "a shipped text file isn't local");
		Assert.isTrue(Assets.isLocal(LICENSE, TEXT));
		Assert.isTrue(Assets.isLocal(LICENSE, TEXT, false));
		Assert.isTrue(Assets.isLocal(MONO, FONT), "a shipped font isn't local");
	}

	public function testListGivesTheAssetsOfAType():Void
	{
		var text = Assets.list(TEXT);
		Assert.contains(LICENSE, text);
		Assert.contains(README, text);
		Assert.notContains(MONO, text);

		var fonts = Assets.list(FONT);
		Assert.contains(MONO, fonts);
		Assert.contains(VARIABLE, fonts);
		Assert.notContains(LICENSE, fonts);

		var all = Assets.list();
		for (id in [LICENSE, MONO, TONE, VIDEO])
		{
			Assert.contains(id, all);
		}
	}

	@Ignored("Waiting on #2158")
	public function testListedIdsCanBeUsed():Void
	{
		files.writeText("listed/a.txt", "alpha");
		Assets.registerLibrary(NAME, AssetTestFiles.library(files.path("listed"), [{id: "a", path: "a.txt", type: "TEXT", size: 5}]));

		var text = Assets.list(TEXT);
		for (id in text)
		{
			Assert.isTrue(Assets.exists(id, TEXT), "Assets.list() gave \"" + id + "\", which Assets.exists() doesn't find");
		}

		Assert.contains(NAME + ":a", text, "the registered library's asset isn't listed by an ID Assets can use");
	}

	public function testUnknownIdsAreReportedByName():Void
	{
		assertReports(MISSING, function():Dynamic return Assets.getText(MISSING));
		assertReports(MISSING, function():Dynamic return Assets.getBytes(MISSING));
	}

	public function testUnknownIdsGiveNullWhenErrorsAreNotThrown():Void
	{
		Log.throwErrors = false;
		var text = Assets.getText(MISSING);
		var bytes = Assets.getBytes(MISSING);
		var path = Assets.getPath(MISSING);
		Log.throwErrors = true;

		Assert.isNull(text);
		Assert.isNull(bytes);
		Assert.isNull(path);
	}

	public function testUnknownLibrariesAreReportedByName():Void
	{
		Assert.isFalse(Assets.hasLibrary("nolibrary"));
		Assert.isNull(Assets.getLibrary("nolibrary"));
		Assert.isFalse(Assets.exists("nolibrary:" + LICENSE));
		assertReports("nolibrary", function():Dynamic return Assets.getText("nolibrary:" + LICENSE));

		Log.throwErrors = false;
		var text = Assets.getText("nolibrary:" + LICENSE);
		Log.throwErrors = true;
		Assert.isNull(text);
	}

	@:timeout(5000)
	public function testLoadedTextAndBytesMatchWhatGetGives(async:Async):Void
	{
		var pending = 2;
		function finish():Void
		{
			if (--pending == 0) async.done();
		}

		Assets.loadText(LICENSE).onComplete(function(text)
		{
			Assert.equals(Assets.getText(LICENSE), text);
			finish();
		}).onError(function(error)
		{
			Assert.fail("loadText() failed: " + error);
			finish();
		});

		Assets.loadBytes(LICENSE).onComplete(function(bytes)
		{
			Assert.isTrue(AssetTestFiles.sameBytes(Assets.getBytes(LICENSE), bytes), "loadBytes() gave other bytes than getBytes()");
			finish();
		}).onError(function(error)
		{
			Assert.fail("loadBytes() failed: " + error);
			finish();
		});
	}

	@:timeout(5000)
	public function testLoadingAnUnknownIdFailsItsFuture(async:Async):Void
	{
		var future:Future<String> = null;

		try
		{
			future = Assets.loadText(MISSING);
		}
		catch (e:Dynamic)
		{
			Assert.fail("loadText() threw rather than failing its future: " + e);
			async.done();
			return;
		}

		future.onComplete(function(text)
		{
			Assert.fail("loadText() completed with " + text);
			async.done();
		}).onError(function(error)
		{
			Assert.stringContains(MISSING, Std.string(error));
			async.done();
		});
	}

	public function testRegisteredLibrariesCanBeFoundUntilUnloaded():Void
	{
		files.writeText("registered/a.txt", "alpha");
		var library = AssetTestFiles.library(files.path("registered"), [{id: "a", path: "a.txt", type: "TEXT", size: 5}]);
		Assets.registerLibrary(NAME, library);

		Assert.isTrue(Assets.hasLibrary(NAME));
		Assert.equals(library, Assets.getLibrary(NAME));
		Assert.isTrue(Assets.exists(NAME + ":a", TEXT));
		Assert.equals("alpha", Assets.getText(NAME + ":a"));

		Assets.unloadLibrary(NAME);
		Assert.isFalse(Assets.hasLibrary(NAME));
		Assert.isNull(Assets.getLibrary(NAME));
		Assert.isFalse(Assets.exists(NAME + ":a"));
	}

	public function testRegisteringAnotherLibraryUnderANameReplacesIt():Void
	{
		files.writeText("first/a.txt", "first");
		files.writeText("second/a.txt", "second");
		Assets.registerLibrary(NAME, AssetTestFiles.library(files.path("first"), [{id: "a", path: "a.txt", type: "TEXT", size: 5}]));
		var second = AssetTestFiles.library(files.path("second"), [{id: "a", path: "a.txt", type: "TEXT", size: 6}]);
		Assets.registerLibrary(NAME, second);

		Assert.equals(second, Assets.getLibrary(NAME));
		Assert.equals("second", Assets.getText(NAME + ":a"));
	}

	public function testRemovingALibraryCanLeaveItLoaded():Void
	{
		files.writeText("removed/a.txt", "alpha");
		var library = AssetTestFiles.library(files.path("removed"), [{id: "a", path: "a.txt", type: "TEXT", size: 5}]);
		Assets.registerLibrary(NAME, library);

		Assets.removeLibrary(NAME, false);
		Assert.isFalse(Assets.hasLibrary(NAME));
		Assert.equals("alpha", library.getText("a"), "a library removed without unloading can't be used");
	}

	public function testLibraryChangesAreRelayedWhileRegistered():Void
	{
		var library = new AssetLibrary();
		var changes = 0;
		var listener = function():Void
		{
			changes++;
		};
		Assets.onChange.add(listener);

		Assets.registerLibrary(NAME, library);
		var registered = changes;
		library.onChange.dispatch();
		var changed = changes;

		Assets.unloadLibrary(NAME);
		var unloaded = changes;
		library.onChange.dispatch();
		var changedAfter = changes;
		Assets.onChange.remove(listener);

		Assert.equals(registered + 1, changed, "Assets.onChange missed a change to a registered library");
		Assert.equals(unloaded, changedAfter, "Assets.onChange relayed a change to a library that was unloaded");
	}

	@:timeout(5000)
	public function testLoadingARegisteredLibraryGivesIt(async:Async):Void
	{
		var library = new AssetLibrary();
		Assets.registerLibrary(NAME, library);

		Assets.loadLibrary(NAME).onComplete(function(loaded)
		{
			Assert.equals(library, loaded);
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadLibrary() failed for a registered library: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testLibrariesLoadFromAManifestPath(async:Async):Void
	{
		files.writeText("path/a.txt", "alpha");
		var path = files.writeText("path/library.json", AssetTestFiles.manifest(null, [{id: "a", path: "a.txt", type: "TEXT", size: 5}]).serialize());

		Assets.loadLibrary(path).onComplete(function(library)
		{
			Assert.notNull(library);
			Assert.equals(library, Assets.getLibrary(path), "the library isn't registered under the path it was loaded from");

			// Its assets are found beside the manifest
			if (library != null) Assert.equals("alpha", library.getText("a"));

			Assets.unloadLibrary(path);
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadLibrary() failed for a manifest path: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testLibrariesLoadFromABundleDirectory(async:Async):Void
	{
		files.writeText("lib.bundle/a.txt", "alpha");
		files.writeText("lib.bundle/library.json", AssetTestFiles.manifest(null, [{id: "a", path: "a.txt", type: "TEXT", size: 5}]).serialize());
		var path = files.path("lib.bundle");

		Assets.loadLibrary(path).onComplete(function(library)
		{
			Assert.notNull(library);
			if (library != null) Assert.equals("alpha", library.getText("a"));

			Assets.unloadLibrary(path);
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadLibrary() failed for a .bundle directory: " + error);
			async.done();
		});
	}

	// The changelog: "asset library load errors ... say which bundle or manifest failed to load, and why"
	@:timeout(5000)
	public function testAMissingManifestIsNamedWhenItsLibraryFails(async:Async):Void
	{
		var path = files.path("missing/library.json");
		assertLibraryFails(path, "missing/library.json", AssetManifest.loadFromFile(path), async);
	}

	@:timeout(5000)
	@Ignored("Waiting on #2155")
	public function testABrokenManifestIsNamedWhenItsLibraryFails(async:Async):Void
	{
		// loadFromFile() reads the manifest with fromBytes(), from the application's event loop,
		// where what it throws ends the application
		try
		{
			AssetManifest.loadFromBytes(Bytes.ofString("{ this is not a manifest"));
		}
		catch (e:Dynamic)
		{
			Assert.fail("a manifest that isn't JSON throws out of loadFromBytes(), so loading it from a file or as a library would end the application: " + e);
			async.done();
			return;
		}

		var path = files.writeText("broken/library.json", "{ this is not a manifest");
		assertLibraryFails(path, "broken/library.json", AssetManifest.loadFromFile(path), async);
	}

	@:timeout(5000)
	public function testAMissingBundleDirectoryIsNamedWhenItsLibraryFails(async:Async):Void
	{
		var path = files.path("missing.bundle");
		assertLibraryFails(path, "missing.bundle", AssetManifest.loadFromFile(path + "/library.json"), async);
	}

	@:timeout(5000)
	public function testAnUnknownLibraryNameIsNamedWhenItFails(async:Async):Void
	{
		assertLibraryFails("nolibrary", "nolibrary", null, async);
	}

	#if lime_cffi
	public function testFontsComeFromTheDefaultLibrary():Void
	{
		var font = Assets.getFont(MONO);
		Assert.notNull(font);
		if (font == null) return;

		Assert.notNull(font.name);
		Assert.isTrue(font.unitsPerEM > 0);
	}

	public function testUnknownFontsAreReportedByName():Void
	{
		assertReports(MISSING, function():Dynamic return Assets.getFont(MISSING));

		Log.throwErrors = false;
		var font = Assets.getFont(MISSING);
		Log.throwErrors = true;
		Assert.isNull(font);
	}

	@:timeout(5000)
	public function testLoadedFontsComeFromTheDefaultLibrary(async:Async):Void
	{
		Assets.loadFont(MONO).onComplete(function(font)
		{
			Assert.notNull(font);
			if (font != null) Assert.isTrue(font.unitsPerEM > 0);
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadFont() failed: " + error);
			async.done();
		});
	}

	public function testTheCacheGivesTheSameFontAgain():Void
	{
		Assets.cache.clear();
		Assert.isTrue(Assets.cache.enabled, "the cache starts disabled");

		var font = Assets.getFont(MONO);
		Assert.notNull(font);
		Assert.isTrue(Assets.cache.exists(MONO, FONT), "getFont() didn't cache the font");
		Assert.isTrue(Assets.cache.exists(MONO), "the cache doesn't find the font without its type");
		Assert.equals(font, Assets.getFont(MONO));
		Assert.isTrue(Assets.isLocal(MONO, FONT));
	}

	public function testClearingTheCacheGivesAFreshFont():Void
	{
		var font = Assets.getFont(MONO);
		Assets.cache.clear();

		Assert.isFalse(Assets.cache.exists(MONO, FONT));
		var fresh = Assets.getFont(MONO);
		Assert.notNull(fresh);
		Assert.notEquals(font, fresh, "the font was given again after the cache was cleared");
	}

	public function testClearingAPrefixLeavesTheRestCached():Void
	{
		Assets.cache.clear();
		Assets.getFont(MONO);
		var variable = Assets.getFont(VARIABLE);

		Assets.cache.clear("assets/mono");
		Assert.isFalse(Assets.cache.exists(MONO, FONT));
		Assert.isTrue(Assets.cache.exists(VARIABLE, FONT));
		Assert.equals(variable, Assets.getFont(VARIABLE));
	}

	public function testFontsAreNotCachedWhileTheCacheIsDisabled():Void
	{
		Assets.cache.clear();
		Assets.cache.enabled = false;
		var first = Assets.getFont(MONO);
		var second = Assets.getFont(MONO);
		var cached = Assets.cache.exists(MONO);
		Assets.cache.enabled = true;

		Assert.notNull(first);
		Assert.notEquals(first, second, "the disabled cache gave the same font twice");
		Assert.isFalse(cached, "the disabled cache kept the font");
	}

	public function testFontsAskedForWithoutTheCacheAreNew():Void
	{
		Assets.cache.clear();
		var cached = Assets.getFont(MONO);
		var uncached = Assets.getFont(MONO, false);

		Assert.notNull(uncached);
		Assert.notEquals(cached, uncached, "getFont(id, false) gave the cached font");
		Assert.equals(cached, Assets.getFont(MONO), "getFont(id, false) replaced the cached font");
	}

	public function testFontsSetInTheCacheAreGiven():Void
	{
		var font = new Font();
		Assets.cache.set(MONO, FONT, font);
		Assert.equals(font, Assets.getFont(MONO));
		Assets.cache.clear();
	}

	public function testUnloadingALibraryClearsItsCachedAssets():Void
	{
		files.copy(MONO, "unload/mono.ttf");
		Assets.registerLibrary(NAME, AssetTestFiles.library(files.path("unload"), [{id: "mono", path: "mono.ttf", type: "FONT", size: 20092}]));

		Assert.notNull(Assets.getFont(NAME + ":mono"));
		Assert.isTrue(Assets.cache.exists(NAME + ":mono", FONT));

		Assets.unloadLibrary(NAME);
		Assert.isFalse(Assets.cache.exists(NAME + ":mono", FONT), "the unloaded library's font is still cached");
	}

	// The changelog: "Changed asset libraries to drop disposed AudioBuffer objects from their caches"
	public function testDisposedSoundsAreNotGivenAgain():Void
	{
		var sound = Assets.getAudioBuffer(TONE);
		Assert.notNull(sound);
		if (sound == null) return;

		Assert.equals(sound, Assets.getAudioBuffer(TONE));
		sound.dispose();

		var fresh = Assets.getAudioBuffer(TONE);
		Assert.notNull(fresh);
		Assert.notEquals(sound, fresh, "a disposed sound was given from the cache");
		if (fresh != null) Assert.notNull(fresh.data, "the sound given after disposing has no data");
	}
	#end

	private static function assertReports(name:String, get:Void->Dynamic, ?pos:haxe.PosInfos):Void
	{
		Log.throwErrors = true;

		try
		{
			var value = get();
			Assert.fail("nothing was reported about \"" + name + "\", and it gave " + value, pos);
		}
		catch (e:Dynamic)
		{
			Assert.stringContains(name, Std.string(e), "the error doesn't name \"" + name + "\": " + e, pos);
		}
	}

	// Loads a library that can't load, then checks its error names the bundle or manifest, and
	// includes the error that `cause`, the same file loaded on its own, fails with
	private static function assertLibraryFails(id:String, named:String, cause:Future<Dynamic>, async:Async, ?pos:haxe.PosInfos):Void
	{
		function check(why:Dynamic):Void
		{
			var future:Future<AssetLibrary> = null;

			try
			{
				future = Assets.loadLibrary(id);
			}
			catch (e:Dynamic)
			{
				Assert.fail("loadLibrary() threw rather than failing its future: " + e, pos);
				async.done();
				return;
			}

			future.onComplete(function(library)
			{
				Assert.fail("loadLibrary(\"" + id + "\") completed", pos);
				Assets.unloadLibrary(id);
				async.done();
			}).onError(function(error)
			{
				var message = Std.string(error);
				Assert.stringContains(named, message, "the error doesn't name " + named + ": " + message, pos);

				if (why != null)
				{
					Assert.stringContains(Std.string(why), message, "the error doesn't say why (" + why + "): " + message, pos);
				}

				async.done();
			});
		}

		if (cause == null)
		{
			check(null);
		}
		else
		{
			cause.onComplete(function(_) check(null)).onError(check);
		}
	}
	#end
}
