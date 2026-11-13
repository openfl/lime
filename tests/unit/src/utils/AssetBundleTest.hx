package utils;

#if sys
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.zip.Entry;
import haxe.zip.Writer;
import lime.app.Future;
import lime.utils.AssetBundle;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.AssetType;
import lime.utils.Assets;
import sys.FileSystem;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	An asset bundle is a zip file. With a library.json manifest in it, its files
	are the assets the manifest lists; without one, each file is an asset of its
	own path.
**/
class AssetBundleTest extends Test
{
	#if sys
	private static inline var NAME = "bundletest";

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
		files = new AssetTestFiles("bundle");

		binary = Bytes.alloc(1000);
		for (i in 0...binary.length)
		{
			binary.set(i, (i * 7) & 0xFF);
		}
	}

	public function teardownClass():Void
	{
		files.remove();
	}

	public function teardown():Void
	{
		@:privateAccess Assets.bundlePaths.remove(NAME);
		if (Assets.hasLibrary(NAME)) Assets.unloadLibrary(NAME);
	}

	public function testBundlesGiveTheirFilesByPath():Void
	{
		assertGivesItsFiles(false);
	}

	public function testCompressedBundlesGiveTheirFilesDecompressed():Void
	{
		assertGivesItsFiles(true);
	}

	public function testBundleLibrariesHaveTheAssetsTheirManifestLists():Void
	{
		for (compressed in [false, true])
		{
			var library = AssetLibrary.fromBundle(AssetBundle.fromBytes(withManifest(compressed)));
			Assert.notNull(library);
			if (library == null) continue;

			Assert.isTrue(library.exists("text", AssetType.TEXT));
			Assert.isTrue(library.exists("binary", AssetType.BINARY));
			Assert.isFalse(library.exists("text", AssetType.FONT));
			Assert.equals("alpha", library.getText("text"));
			Assert.isTrue(AssetTestFiles.sameBytes(binary, library.getBytes("binary")), "the bundle's asset gave other bytes");
			Assert.contains("text", library.list(AssetType.TEXT));
			Assert.contains("binary", library.list(AssetType.BINARY));
		}
	}

	public function testBundlesWithoutAManifestHaveEachFileAsAnAsset():Void
	{
		var library = AssetLibrary.fromBundle(AssetBundle.fromBytes(zip(["a.txt" => Bytes.ofString("alpha"), "dir/data.bin" => binary], false)));
		Assert.notNull(library);
		if (library == null) return;

		Assert.isTrue(library.exists("a.txt", null));
		Assert.isTrue(library.exists("dir/data.bin", null));
		Assert.isTrue(AssetTestFiles.sameBytes(Bytes.ofString("alpha"), library.getBytes("a.txt")));
		Assert.isTrue(AssetTestFiles.sameBytes(binary, library.getBytes("dir/data.bin")));
	}

	public function testBundlesReadFromFiles():Void
	{
		var path = files.write("file.zip", withManifest(true));
		var bundle = AssetBundle.fromFile(path);

		Assert.notNull(bundle);
		if (bundle == null) return;

		var library = AssetLibrary.fromBundle(bundle);
		Assert.notNull(library);
		if (library != null) Assert.equals("alpha", library.getText("text"));
	}

	@Ignored("Waiting on #2156")
	public function testReadingABundleFromAFileLetsGoOfTheFile():Void
	{
		var path = files.write("released.zip", withManifest(false));
		Assert.notNull(AssetBundle.fromFile(path));

		// Windows doesn't delete a file that is still open
		try
		{
			FileSystem.deleteFile(path);
		}
		catch (e:Dynamic) {}

		Assert.isFalse(FileSystem.exists(path), "the bundle's file is still open after fromFile()");
	}

	@:timeout(5000)
	public function testBundlesLoadFromFiles(async:Async):Void
	{
		var path = files.write("loaded.zip", withManifest(true));

		AssetBundle.loadFromFile(path).onComplete(function(bundle)
		{
			Assert.notNull(bundle);
			if (bundle != null) Assert.isTrue(AssetTestFiles.sameBytes(binary, bundle.data.get("data.bin")));
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadFromFile() failed: " + error);
			async.done();
		});
	}

	@Ignored("Waiting on #2155")
	public function testBytesThatAreNotAZipGiveNoBundle():Void
	{
		var bundle:AssetBundle = null;

		try
		{
			bundle = AssetBundle.fromBytes(Bytes.ofString("this is not a zip file"));
		}
		catch (e:Dynamic)
		{
			Assert.fail("fromBytes() threw: " + e);
			return;
		}

		Assert.isNull(bundle);
	}

	@Ignored("Waiting on #2156")
	public function testAMissingFileGivesNoBundle():Void
	{
		var bundle:AssetBundle = null;

		try
		{
			bundle = AssetBundle.fromFile(files.path("missing.zip"));
		}
		catch (e:Dynamic)
		{
			Assert.fail("fromFile() threw: " + e);
			return;
		}

		Assert.isNull(bundle);
	}

	@:timeout(5000)
	public function testLoadingAMissingFileFails(async:Async):Void
	{
		AssetBundle.loadFromFile(files.path("missing.zip")).onComplete(function(bundle)
		{
			Assert.fail("loadFromFile() completed for a missing file, with " + bundle);
			async.done();
		}).onError(function(error)
		{
			Assert.notNull(error);
			async.done();
		});
	}

	// ManifestResources registers a bundle that isn't embedded by its path, for Assets.loadLibrary()
	@:timeout(5000)
	public function testRegisteredBundlesLoadAsLibraries(async:Async):Void
	{
		@:privateAccess Assets.bundlePaths.set(NAME, files.write("registered.zip", withManifest(true)));

		Assets.loadLibrary(NAME).onComplete(function(library)
		{
			Assert.notNull(library);
			Assert.equals(library, Assets.getLibrary(NAME));
			Assert.equals("alpha", Assets.getText(NAME + ":text"));
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadLibrary() failed: " + error);
			async.done();
		});
	}

	// The changelog: "asset library load errors ... say which bundle or manifest failed to load, and why"
	@:timeout(5000)
	public function testAMissingBundleIsNamedWhenItsLibraryFails(async:Async):Void
	{
		var path = files.path("missing.zip");
		assertLibraryFails(path, "missing.zip", async);
	}

	@:timeout(5000)
	@Ignored("Waiting on #2155")
	public function testLoadingBytesThatAreNotAZipFails(async:Async):Void
	{
		var future:Future<AssetBundle> = null;

		try
		{
			future = AssetBundle.loadFromBytes(Bytes.ofString("this is not a zip file"));
		}
		catch (e:Dynamic)
		{
			Assert.fail("loadFromBytes() threw rather than failing its future: " + e);
			async.done();
			return;
		}

		future.onComplete(function(bundle)
		{
			Assert.fail("loadFromBytes() completed for bytes that aren't a zip, with " + bundle);
			async.done();
		}).onError(function(error)
		{
			Assert.notNull(error);
			async.done();
		});
	}

	@:timeout(5000)
	@Ignored("Waiting on #2155")
	public function testABrokenBundleIsNamedWhenItsLibraryFails(async:Async):Void
	{
		// loadFromFile() reads the bundle with loadFromBytes(), from the application's event loop,
		// where what it throws ends the application
		try
		{
			AssetBundle.loadFromBytes(Bytes.ofString("this is not a zip file"));
		}
		catch (e:Dynamic)
		{
			Assert.fail("a bundle that isn't a zip throws out of loadFromBytes(), so loading it from a file or as a library would end the application: " + e);
			async.done();
			return;
		}

		var path = files.writeText("broken.zip", "this is not a zip file");
		assertLibraryFails(path, "broken.zip", async);
	}

	private function assertLibraryFails(path:String, named:String, async:Async, ?pos:haxe.PosInfos):Void
	{
		@:privateAccess Assets.bundlePaths.set(NAME, path);

		// What the bundle fails with on its own
		var why:Dynamic = null;
		var cause = AssetBundle.loadFromFile(path);
		cause.onError(function(error) why = error);

		function check():Void
		{
			var future:Future<AssetLibrary> = null;

			try
			{
				future = Assets.loadLibrary(NAME);
			}
			catch (e:Dynamic)
			{
				Assert.fail("loadLibrary() threw rather than failing its future: " + e, pos);
				async.done();
				return;
			}

			future.onComplete(function(library)
			{
				Assert.fail("loadLibrary() completed for a bundle that can't load", pos);
				async.done();
			}).onError(function(error)
			{
				var message = Std.string(error);
				Assert.stringContains(named, message, "the error doesn't name the bundle: " + message, pos);
				Assert.isFalse(message.indexOf("There is no asset library") == 0, "the error blames the library's name: " + message, pos);

				if (why != null)
				{
					Assert.stringContains(Std.string(why), message, "the error doesn't say why (" + why + "): " + message, pos);
				}

				async.done();
			});
		}

		cause.onComplete(function(_) check()).onError(function(_) check());
	}

	private function assertGivesItsFiles(compressed:Bool, ?pos:haxe.PosInfos):Void
	{
		var bundle = AssetBundle.fromBytes(zip(["a.txt" => Bytes.ofString("alpha"), "dir/data.bin" => binary], compressed));
		Assert.notNull(bundle, pos);
		if (bundle == null) return;

		Assert.contains("a.txt", bundle.paths, pos);
		Assert.contains("dir/data.bin", bundle.paths, pos);
		Assert.isTrue(AssetTestFiles.sameBytes(Bytes.ofString("alpha"), bundle.data.get("a.txt")), "a.txt was given other bytes", pos);
		Assert.isTrue(AssetTestFiles.sameBytes(binary, bundle.data.get("dir/data.bin")), "dir/data.bin was given other bytes", pos);
	}

	private function withManifest(compressed:Bool):Bytes
	{
		var manifest = new AssetManifest();
		manifest.name = "bundle";
		manifest.assets = [
			{id: "text", path: "a.txt", size: 5, type: "TEXT"},
			{id: "binary", path: "data.bin", size: binary.length, type: "BINARY"}
		];

		return zip(["library.json" => Bytes.ofString(manifest.serialize()), "a.txt" => Bytes.ofString("alpha"), "data.bin" => binary], compressed);
	}

	private static function zip(contents:Map<String, Bytes>, compressed:Bool):Bytes
	{
		var entries = new List<Entry>();

		for (name in contents.keys())
		{
			var data = contents.get(name);
			var entry:Entry = {
				fileName: name,
				fileSize: data.length,
				fileTime: Date.now(),
				compressed: false,
				dataSize: data.length,
				data: data,
				crc32: Crc32.make(data)
			};

			if (compressed) haxe.zip.Tools.compress(entry, 9);
			entries.add(entry);
		}

		var output = new BytesOutput();
		new Writer(output).write(entries);
		return output.getBytes();
	}
	#end
}
