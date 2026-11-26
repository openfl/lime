package utils;

import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.utils.AssetCache;
import lime.utils.AssetType;
#if sys
import lime.utils.Assets;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	The cache keeps images, sounds and fonts by ID, each kind in a map of its
	own. `Assets` fills it with the ID an asset was asked for, which for
	libraries other than the default starts with the library's name and a
	colon, and `Assets.unloadLibrary()` clears the IDs with that prefix. While
	`enabled` is false, `Assets` neither reads nor fills it.
**/
class AssetCacheTest extends Test
{
	#if sys
	private static inline var PICTURE = "assets/image-rgba.png";
	private static inline var TONE = "assets/tone.wav";

	private var defaultError:Dynamic;
	private var shared:AssetCache;
	#end

	public function new()
	{
		super();
	}

	#if sys
	public function setupClass(async:Async):Void
	{
		shared = Assets.cache;
		async.setTimeout(10000);

		// The tests can run before the application's preloader has loaded its library
		Assets.loadLibrary("default").onComplete(function(_) async.done()).onError(function(error)
		{
			defaultError = error;
			async.done();
		});
	}

	public function teardown():Void
	{
		Assets.cache = shared;
		Assets.cache.enabled = true;
	}

	/**
		Finishes on the next tick. utest 1.13 doesn't go on to the next class when setupClass finished
		asynchronously and every test in the class ran synchronously: its checkSetup drops the result of
		runFixtures, which only goes on by itself when teardownClass is asynchronous. setupClass finishes
		asynchronously whenever this class runs before the preloader has loaded the default library, and
		the order the classes run in changes as classes are added.
	**/
	public function teardownClass(async:Async):Void
	{
		haxe.Timer.delay(function() async.done(), 0);
	}
	#end

	public function testANewCacheIsEnabledAndEmpty():Void
	{
		var cache = new AssetCache();

		Assert.isTrue(cache.enabled);
		Assert.equals(0, count(cache.image));
		Assert.equals(0, count(cache.audio));
		Assert.equals(0, count(cache.font));
		Assert.isFalse(cache.exists("missing"));
	}

	public function testImagesAreKeptInTheImageMap():Void
	{
		var cache = new AssetCache();
		var image = picture();
		cache.set("picture", IMAGE, image);

		Assert.equals(image, cache.image.get("picture"));
		Assert.equals(1, count(cache.image));
		Assert.equals(0, count(cache.audio));
		Assert.equals(0, count(cache.font));
	}

	public function testSoundsAndMusicAreKeptInTheAudioMap():Void
	{
		var cache = new AssetCache();
		var sound = new AudioBuffer();
		var music = new AudioBuffer();
		cache.set("sound", SOUND, sound);
		cache.set("music", MUSIC, music);

		Assert.equals(sound, cache.audio.get("sound"));
		Assert.equals(music, cache.audio.get("music"));
		Assert.equals(2, count(cache.audio));
		Assert.equals(0, count(cache.image));
		Assert.equals(0, count(cache.font));
	}

	public function testFontsAreKeptInTheFontMap():Void
	{
		var cache = new AssetCache();
		var font = {name: "font"};
		cache.set("font", FONT, font);

		Assert.isTrue(cache.font.get("font") == font);
		Assert.equals(1, count(cache.font));
		Assert.equals(0, count(cache.image));
		Assert.equals(0, count(cache.audio));
	}

	public function testExistsLooksInTheMapOfTheTypeAskedFor():Void
	{
		var cache = new AssetCache();
		cache.set("picture", IMAGE, picture());
		cache.set("sound", SOUND, new AudioBuffer());
		cache.set("font", FONT, {name: "font"});

		Assert.isTrue(cache.exists("picture", IMAGE));
		Assert.isFalse(cache.exists("picture", SOUND), "an image exists as a sound");
		Assert.isFalse(cache.exists("picture", MUSIC), "an image exists as music");
		Assert.isFalse(cache.exists("picture", FONT), "an image exists as a font");

		Assert.isTrue(cache.exists("sound", SOUND));
		Assert.isFalse(cache.exists("sound", IMAGE), "a sound exists as an image");
		Assert.isFalse(cache.exists("sound", FONT), "a sound exists as a font");

		Assert.isTrue(cache.exists("font", FONT));
		Assert.isFalse(cache.exists("font", IMAGE), "a font exists as an image");
		Assert.isFalse(cache.exists("font", SOUND), "a font exists as a sound");
	}

	public function testSoundsAndMusicAreFoundAsEitherType():Void
	{
		var cache = new AssetCache();
		cache.set("sound", SOUND, new AudioBuffer());
		cache.set("music", MUSIC, new AudioBuffer());

		Assert.isTrue(cache.exists("sound", MUSIC));
		Assert.isTrue(cache.exists("music", SOUND));
	}

	public function testExistsWithoutATypeLooksInEveryMap():Void
	{
		var cache = new AssetCache();
		cache.set("picture", IMAGE, picture());
		cache.set("sound", SOUND, new AudioBuffer());
		cache.set("font", FONT, {name: "font"});

		Assert.isTrue(cache.exists("picture"));
		Assert.isTrue(cache.exists("sound"));
		Assert.isTrue(cache.exists("font"));
		Assert.isFalse(cache.exists("missing"));
	}

	public function testTypesTheCacheDoesNotKeepNeverExist():Void
	{
		var cache = new AssetCache();
		cache.set("asset", IMAGE, picture());
		cache.set("asset", SOUND, new AudioBuffer());
		cache.set("asset", FONT, {name: "font"});

		Assert.isFalse(cache.exists("asset", TEXT));
		Assert.isFalse(cache.exists("asset", BINARY));
	}

	public function testAnIdCanBeCachedOnceForEachKind():Void
	{
		var cache = new AssetCache();
		var image = picture();
		var sound = new AudioBuffer();
		cache.set("asset", IMAGE, image);
		cache.set("asset", SOUND, sound);

		Assert.equals(image, cache.image.get("asset"));
		Assert.equals(sound, cache.audio.get("asset"));
	}

	public function testSettingAnIdAgainReplacesItsAsset():Void
	{
		var cache = new AssetCache();
		var first = picture();
		var second = picture();
		cache.set("picture", IMAGE, first);
		cache.set("picture", IMAGE, second);

		Assert.equals(second, cache.image.get("picture"));
		Assert.equals(1, count(cache.image));
	}

	public function testAnAssetOfAnotherKindIsRefused():Void
	{
		var cache = new AssetCache();

		Assert.raises(function() cache.set("sound", IMAGE, new AudioBuffer()));
		Assert.raises(function() cache.set("picture", SOUND, picture()));
		Assert.raises(function() cache.set("picture", MUSIC, picture()));

		Assert.isFalse(cache.exists("sound"), "a sound refused as an image was kept");
		Assert.isFalse(cache.exists("picture"), "an image refused as a sound was kept");
	}

	public function testAnEntryRemovedFromItsMapNoLongerExists():Void
	{
		var cache = new AssetCache();
		cache.set("picture", IMAGE, picture());
		cache.set("sound", SOUND, new AudioBuffer());
		cache.set("font", FONT, {name: "font"});

		Assert.isTrue(cache.image.remove("picture"));
		Assert.isTrue(cache.audio.remove("sound"));
		Assert.isTrue(cache.font.remove("font"));

		Assert.isFalse(cache.exists("picture"));
		Assert.isFalse(cache.exists("sound"));
		Assert.isFalse(cache.exists("font"));
	}

	public function testClearEmptiesEveryMap():Void
	{
		var cache = new AssetCache();
		cache.set("picture", IMAGE, picture());
		cache.set("sound", SOUND, new AudioBuffer());
		cache.set("font", FONT, {name: "font"});

		cache.clear();

		Assert.equals(0, count(cache.image));
		Assert.equals(0, count(cache.audio));
		Assert.equals(0, count(cache.font));
		Assert.isFalse(cache.exists("picture"));
		Assert.isFalse(cache.exists("sound"));
		Assert.isFalse(cache.exists("font"));
	}

	public function testClearingAPrefixClearsItInEveryMap():Void
	{
		var cache = new AssetCache();
		cache.set("one:picture", IMAGE, picture());
		cache.set("one:sound", SOUND, new AudioBuffer());
		cache.set("one:music", MUSIC, new AudioBuffer());
		cache.set("one:font", FONT, {name: "font"});

		cache.clear("one:");

		Assert.isFalse(cache.exists("one:picture"));
		Assert.isFalse(cache.exists("one:sound"));
		Assert.isFalse(cache.exists("one:music"));
		Assert.isFalse(cache.exists("one:font"));
	}

	public function testClearingALibrarysPrefixLeavesOtherLibrariesCached():Void
	{
		var cache = new AssetCache();

		// As Assets caches them: the default library's without a prefix, the others' with their name
		var kept = ["picture", "two:picture", "onetwo:picture", "two:one:picture", "ONE:picture"];
		for (id in kept)
		{
			cache.set(id, IMAGE, picture());
			cache.set(id, SOUND, new AudioBuffer());
			cache.set(id, FONT, {name: id});
		}

		cache.set("one:picture", IMAGE, picture());
		cache.set("one:sound", SOUND, new AudioBuffer());
		cache.set("one:font", FONT, {name: "font"});

		cache.clear("one:");

		for (id in kept)
		{
			Assert.isTrue(cache.exists(id, IMAGE), "the image \"" + id + "\" was cleared with the prefix \"one:\"");
			Assert.isTrue(cache.exists(id, SOUND), "the sound \"" + id + "\" was cleared with the prefix \"one:\"");
			Assert.isTrue(cache.exists(id, FONT), "the font \"" + id + "\" was cleared with the prefix \"one:\"");
		}

		Assert.equals(kept.length, count(cache.image));
		Assert.equals(kept.length, count(cache.audio));
		Assert.equals(kept.length, count(cache.font));
	}

	public function testClearingAPrefixNothingHasLeavesTheCacheAsItWas():Void
	{
		var cache = new AssetCache();
		cache.set("one:picture", IMAGE, picture());

		cache.clear("two:");
		cache.clear("one:picture:");

		Assert.isTrue(cache.exists("one:picture", IMAGE));
	}

	#if sys
	public function testAssetsCachesEachKindInItsOwnMap():Void
	{
		if (!defaultLibraryLoaded()) return;

		var cache = new AssetCache();
		Assets.cache = cache;

		var image = Assets.getImage(PICTURE);
		var sound = Assets.getAudioBuffer(TONE);

		Assert.notNull(image);
		Assert.notNull(sound);
		Assert.equals(image, cache.image.get(PICTURE));
		Assert.equals(sound, cache.audio.get(TONE));
		Assert.isFalse(cache.audio.exists(PICTURE));
		Assert.isFalse(cache.image.exists(TONE));
		Assert.equals(0, count(cache.font));
	}

	public function testACachedImageIsGivenAgain():Void
	{
		if (!defaultLibraryLoaded()) return;

		Assets.cache = new AssetCache();

		var image = Assets.getImage(PICTURE);
		Assert.notNull(image);
		Assert.equals(image, Assets.getImage(PICTURE));
	}

	public function testAnImageSetInTheCacheIsGivenForItsId():Void
	{
		if (!defaultLibraryLoaded()) return;

		var cache = new AssetCache();
		Assets.cache = cache;

		var image = picture();
		cache.set(PICTURE, IMAGE, image);
		Assert.equals(image, Assets.getImage(PICTURE));
	}

	public function testImagesAreNotCachedWhileTheCacheIsDisabled():Void
	{
		if (!defaultLibraryLoaded()) return;

		var cache = new AssetCache();
		Assets.cache = cache;
		cache.enabled = false;

		var first = Assets.getImage(PICTURE);
		var second = Assets.getImage(PICTURE);

		Assert.notNull(first);
		Assert.notNull(second);
		Assert.isFalse(cache.exists(PICTURE), "the disabled cache kept the image");
		Assert.notEquals(first, second, "the disabled cache gave the same image twice");
	}

	public function testSoundsAreNotCachedWhileTheCacheIsDisabled():Void
	{
		if (!defaultLibraryLoaded()) return;

		var cache = new AssetCache();
		Assets.cache = cache;
		cache.enabled = false;

		var first = Assets.getAudioBuffer(TONE);
		var second = Assets.getAudioBuffer(TONE);

		Assert.notNull(first);
		Assert.notNull(second);
		Assert.isFalse(cache.exists(TONE), "the disabled cache kept the sound");
		Assert.notEquals(first, second, "the disabled cache gave the same sound twice");
	}

	public function testADisabledCacheIsNotReadFrom():Void
	{
		if (!defaultLibraryLoaded()) return;

		var cache = new AssetCache();
		Assets.cache = cache;

		var cached = picture();
		cache.set(PICTURE, IMAGE, cached);
		cache.enabled = false;

		var image = Assets.getImage(PICTURE);
		Assert.notNull(image);
		Assert.notEquals(cached, image, "the disabled cache gave the image it had");
		Assert.equals(cached, cache.image.get(PICTURE), "the disabled cache lost the image it had");
	}

	public function testEnablingTheCacheAgainGivesWhatItKept():Void
	{
		if (!defaultLibraryLoaded()) return;

		var cache = new AssetCache();
		Assets.cache = cache;

		var image = Assets.getImage(PICTURE);
		cache.enabled = false;
		Assets.getImage(PICTURE);
		cache.enabled = true;

		Assert.equals(image, Assets.getImage(PICTURE));
	}

	private function defaultLibraryLoaded():Bool
	{
		Assert.isNull(defaultError, "Assets.loadLibrary(\"default\") failed: " + defaultError);
		return defaultError == null;
	}
	#end

	private static function picture():Image
	{
		return new Image(null, 0, 0, 2, 2, 0xFF0000FF);
	}

	private static function count<T>(map:Map<String, T>):Int
	{
		var count = 0;
		for (key in map.keys()) count++;
		return count;
	}
}
