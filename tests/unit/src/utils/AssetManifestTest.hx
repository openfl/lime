package utils;

#if sys
import haxe.io.Bytes;
import haxe.io.Path;
import lime.app.Future;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import sys.FileSystem;
import sys.io.File;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	An asset manifest describes a library: its name, the class that reads it and
	that class's arguments, the root path its asset paths are under, and each
	asset. Manifests are written with `serialize()` and read back with `parse()`,
	`fromBytes()` or `fromFile()`.
**/
class AssetManifestTest extends Test
{
	#if sys
	private var files:AssetTestFiles;
	#end

	public function new()
	{
		super();
	}

	#if sys
	public function setupClass():Void
	{
		files = new AssetTestFiles("manifest");
		files.writeText("root/a.txt", "alpha");
		files.writeText("root/sub/b.txt", "beta");
	}

	public function teardownClass():Void
	{
		files.remove();
	}

	public function testManifestsSurviveSerialization():Void
	{
		var manifest = fullManifest();
		var parsed = AssetManifest.parse(manifest.serialize());

		Assert.notNull(parsed);
		if (parsed == null) return;

		Assert.equals(manifest.version, parsed.version);
		Assert.equals("spec library", parsed.name);
		Assert.equals("lime.utils.PackedAssetLibrary", parsed.libraryType);
		Assert.same(["lib/spec.pak", "pak"], parsed.libraryArgs);
		Assert.equals("root/dir", parsed.rootPath);
		Assert.same(fullManifest().assets, parsed.assets, true);
	}

	@Ignored("Waiting on #2157")
	public function testTheVersionSurvivesSerialization():Void
	{
		// Other than the version new manifests have
		var manifest = fullManifest();
		manifest.version = 1;
		var parsed = AssetManifest.parse(manifest.serialize());

		Assert.notNull(parsed);
		if (parsed == null) return;

		Assert.equals(1, parsed.version);
		Assert.same(fullManifest().assets, parsed.assets, true);
	}

	public function testEmptyManifestsSurviveSerialization():Void
	{
		var parsed = AssetManifest.parse(new AssetManifest().serialize());

		Assert.notNull(parsed);
		if (parsed == null) return;

		Assert.equals(new AssetManifest().version, parsed.version);
		Assert.isNull(parsed.name);
		Assert.isNull(parsed.libraryType);
		Assert.isNull(parsed.rootPath);
		Assert.notNull(parsed.assets);
		if (parsed.assets != null) Assert.equals(0, parsed.assets.length);
	}

	public function testUnusualIdsAndPathsSurviveSerialization():Void
	{
		var manifest = new AssetManifest();
		manifest.name = "naïve \"library\"";
		manifest.assets = [
			{id: "dir/with space/ünïcödé ☃.txt", path: "dir/with space/ünïcödé ☃.txt", size: 1, type: "TEXT"},
			{id: "100% sure&x=y?z#w", path: "100%25 sure.txt", size: 2, type: "BINARY"},
			{id: "lib:colon", path: "C:/absolute/path.txt", size: 3, type: "TEXT"}
		];

		var parsed = AssetManifest.parse(manifest.serialize());
		Assert.notNull(parsed);
		if (parsed == null) return;

		Assert.equals(manifest.name, parsed.name);
		Assert.same(manifest.assets, parsed.assets, true);
	}

	public function testFromBytesReadsASerializedManifest():Void
	{
		var parsed = AssetManifest.fromBytes(Bytes.ofString(fullManifest().serialize()));

		Assert.notNull(parsed);
		if (parsed == null) return;

		Assert.equals("spec library", parsed.name);
		Assert.equals("root/dir", parsed.rootPath);
		Assert.same(fullManifest().assets, parsed.assets, true);
	}

	public function testFromFileReadsASerializedManifest():Void
	{
		var path = files.writeText("full.json", fullManifest().serialize());
		var parsed = AssetManifest.fromFile(path);

		Assert.notNull(parsed);
		if (parsed == null) return;

		Assert.equals("spec library", parsed.name);
		Assert.equals("lime.utils.PackedAssetLibrary", parsed.libraryType);
		Assert.same(["lib/spec.pak", "pak"], parsed.libraryArgs);
		Assert.same(fullManifest().assets, parsed.assets, true);
	}

	public function testFromFileGivesNullForAMissingFile():Void
	{
		Assert.isNull(AssetManifest.fromFile(files.path("missing.json")));
	}

	@:timeout(5000)
	public function testLoadFromFileCompletesWithTheManifest(async:Async):Void
	{
		var path = files.writeText("loaded.json", fullManifest().serialize());

		AssetManifest.loadFromFile(path).onComplete(function(parsed)
		{
			Assert.notNull(parsed);

			if (parsed != null)
			{
				Assert.equals("spec library", parsed.name);
				Assert.same(fullManifest().assets, parsed.assets, true);
			}

			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadFromFile() failed: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testLoadFromFileFailsForAMissingFile(async:Async):Void
	{
		AssetManifest.loadFromFile(files.path("missing.json")).onComplete(function(parsed)
		{
			Assert.fail("loadFromFile() completed for a missing file, with " + parsed);
			async.done();
		}).onError(function(error)
		{
			Assert.notNull(error);
			async.done();
		});
	}

	@Ignored("Waiting on #2155")
	public function testDataThatIsNotAManifestGivesNull():Void
	{
		// As for empty data, and as Assets.loadLibrary() expects of a manifest that can't be parsed
		Assert.isNull(AssetManifest.parse(""));

		var parsed:AssetManifest = null;

		try
		{
			parsed = AssetManifest.parse("{ this is not a manifest");
		}
		catch (e:Dynamic)
		{
			Assert.fail("parse() threw: " + e);
			return;
		}

		Assert.isNull(parsed);
	}

	// Failing, or completing with no manifest, as Assets.loadLibrary() handles either
	@:timeout(5000)
	@Ignored("Waiting on #2155")
	public function testLoadingBytesThatAreNotAManifestGivesNone(async:Async):Void
	{
		var future:Future<AssetManifest> = null;

		try
		{
			future = AssetManifest.loadFromBytes(Bytes.ofString("{ this is not a manifest"));
		}
		catch (e:Dynamic)
		{
			Assert.fail("loadFromBytes() threw rather than failing its future: " + e);
			async.done();
			return;
		}

		future.onComplete(function(parsed)
		{
			Assert.isNull(parsed, "loadFromBytes() completed with a manifest for data that isn't one");
			async.done();
		}).onError(function(error)
		{
			Assert.notNull(error);
			async.done();
		});
	}

	public function testPlainJsonManifestsParse():Void
	{
		// Manifests can list their assets as JSON, rather than serialized
		var parsed = AssetManifest.parse('{"name":"json","assets":[{"id":"a","path":"a.txt","size":5,"type":"TEXT"}]}');

		Assert.notNull(parsed);
		if (parsed == null) return;

		Assert.equals("json", parsed.name);
		Assert.notNull(parsed.assets);
		if (parsed.assets == null || parsed.assets.length != 1) return;

		Assert.equals("a", parsed.assets[0].id);
		Assert.equals("a.txt", parsed.assets[0].path);
	}

	public function testAssetsAreFoundUnderTheRootPath():Void
	{
		assertFinds(manifest(files.path("root")), "alpha", "beta");
	}

	public function testATrailingSlashOnTheRootPathIsNotDoubled():Void
	{
		assertFinds(manifest(files.path("root/")), "alpha", "beta");
	}

	public function testAnEmptyRootPathLeavesAssetPathsAsTheyAre():Void
	{
		var manifest = AssetTestFiles.manifest("", [{id: "a", path: files.path("root/a.txt"), size: 5, type: "TEXT"}]);
		assertFinds(manifest, "alpha");

		// A relative path is then the working directory's, where the application's own assets are
		manifest = AssetTestFiles.manifest("", [{id: "a", path: "assets/mono-OFL.txt", size: 4607, type: "TEXT"}]);
		assertFinds(manifest, File.getContent("assets/mono-OFL.txt"));
	}

	public function testANullRootPathLeavesAssetPathsAsTheyAre():Void
	{
		assertFinds(AssetTestFiles.manifest(null, [{id: "a", path: files.path("root/a.txt"), size: 5, type: "TEXT"}]), "alpha");
	}

	@Ignored("Waiting on #2157")
	public function testAbsoluteAssetPathsAreNotUnderTheRootPath():Void
	{
		var manifest = AssetTestFiles.manifest(files.path("elsewhere"), [{id: "a", path: files.path("root/a.txt"), size: 5, type: "TEXT"}]);
		assertFinds(manifest, "alpha");
	}

	public function testParseFindsAssetsUnderItsRootPath():Void
	{
		// As for a manifest embedded in the application, which has no root path of its own
		var parsed = AssetManifest.parse(manifest(null).serialize(), files.path("root"));
		assertFinds(parsed, "alpha", "beta");
	}

	public function testParseCombinesItsRootPathWithTheManifests():Void
	{
		// As for a manifest in manifest/, whose assets are in ../
		FileSystem.createDirectory(files.path("manifest"));
		var parsed = AssetManifest.parse(manifest("../root").serialize(), files.path("manifest"));
		assertFinds(parsed, "alpha", "beta");
	}

	@Ignored("Waiting on #2157")
	public function testRelativeRootPathsCanClimbAboveWhereTheyStart():Void
	{
		// manifest/../../<this directory> is this directory, where the application's own assets are
		var here = Path.withoutDirectory(Path.removeTrailingSlashes(Path.normalize(Sys.getCwd())));
		var manifest = AssetTestFiles.manifest("../../" + here, [{id: "a", path: "assets/mono-OFL.txt", size: 4607, type: "TEXT"}]);
		assertFinds(AssetManifest.parse(manifest.serialize(), "manifest"), File.getContent("assets/mono-OFL.txt"));
	}

	@Ignored("Waiting on #2157")
	public function testParseKeepsAnAbsoluteRootPath():Void
	{
		var parsed = AssetManifest.parse(manifest(files.path("root")).serialize(), files.path("elsewhere"));
		assertFinds(parsed, "alpha", "beta");
	}

	public function testManifestFilesFindAssetsBesideThem():Void
	{
		var path = files.writeText("root/library.json", manifest(null).serialize());
		assertFinds(AssetManifest.fromFile(path), "alpha", "beta");
	}

	public function testManifestFilesFindAssetsUnderTheirOwnRootPath():Void
	{
		var path = files.writeText("manifest/library.json", manifest("../root").serialize());
		assertFinds(AssetManifest.fromFile(path), "alpha", "beta");
	}

	public function testManifestFilesFindAssetsUnderARootPathGiven():Void
	{
		var path = files.writeText("other/library.json", manifest(null).serialize());
		assertFinds(AssetManifest.fromFile(path, files.path("root")), "alpha", "beta");
	}

	#if windows
	public function testWindowsRootPathsAreFound():Void
	{
		// As System.applicationDirectory gives them
		assertFinds(manifest(StringTools.replace(files.path("root"), "/", "\\") + "\\"), "alpha", "beta");
	}
	#end

	private static function fullManifest():AssetManifest
	{
		var manifest = new AssetManifest();
		manifest.name = "spec library";
		manifest.libraryType = "lime.utils.PackedAssetLibrary";
		manifest.libraryArgs = ["lib/spec.pak", "pak"];
		manifest.rootPath = "root/dir";
		manifest.assets = [
			{id: "text", path: "text.txt", size: 5, type: "TEXT", preload: true},
			{id: "font", className: "__ASSET__font", size: 10, type: "FONT"},
			{id: "packed", position: 15, length: 5, size: 5, type: "BINARY"},
			{id: "sound", pathGroup: ["sound.ogg", "sound.mp3"], size: 9, type: "SOUND", preload: false}
		];
		return manifest;
	}

	private static function manifest(rootPath:String):AssetManifest
	{
		return AssetTestFiles.manifest(rootPath, [
			{id: "a", path: "a.txt", size: 5, type: "TEXT"},
			{id: "b", path: "sub/b.txt", size: 4, type: "TEXT"}
		]);
	}

	// The manifest's first assets read as the text given, from files their paths name without doubled slashes
	private static function assertFinds(manifest:AssetManifest, first:String, ?second:String, ?pos:haxe.PosInfos):Void
	{
		Assert.notNull(manifest, "there is no manifest", pos);
		if (manifest == null) return;

		var library = AssetLibrary.fromManifest(manifest);
		Assert.notNull(library, "the manifest gave no library", pos);
		if (library == null) return;

		var expected = second == null ? [first] : [first, second];

		for (i in 0...expected.length)
		{
			var id:String = manifest.assets[i].id;
			var path = library.getPath(id);
			Assert.notNull(path, "\"" + id + "\" has no path", pos);

			if (path != null)
			{
				Assert.isTrue(FileSystem.exists(path), "\"" + id + "\" is at " + path + ", which doesn't exist", pos);
				Assert.isTrue(path.indexOf("//") == -1 && path.indexOf("\\\\") == -1, "\"" + id + "\" is at " + path + ", with a doubled slash", pos);
			}

			try
			{
				Assert.equals(expected[i], library.getText(id), "\"" + id + "\" read as other text, from " + path, pos);
			}
			catch (e:Dynamic)
			{
				Assert.fail("\"" + id + "\" can't be read from " + path + ": " + e, pos);
			}
		}
	}
	#end
}
