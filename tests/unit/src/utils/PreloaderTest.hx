package utils;

import lime.app.Future;
import lime.app.Promise;
import lime.utils.AssetLibrary;
import lime.utils.Assets;
import lime.utils.Log;
import lime.utils.Preloader;
import utest.Assert;
import utest.Test;

/**
	The preloader loads the libraries it was given and then the libraries it
	was given by name, reporting how much of them is loaded with `onProgress`,
	as Flash reports `bytesLoaded` and `bytesTotal`, and that all of them are
	loaded with `onComplete`, once.

	On Flash the preloader also waits for the SWF itself and counts its bytes,
	so these are left to the other targets.
**/
class PreloaderTest extends Test
{
	#if !flash
	private static inline var NAME = "preloadertest";
	private static inline var OTHER = "preloadertest-other";
	#end

	public function new()
	{
		super();
	}

	#if !flash
	public function teardown():Void
	{
		Log.throwErrors = true;

		// Leaves the libraries as they are, as they were never loaded
		if (Assets.hasLibrary(NAME)) Assets.removeLibrary(NAME, false);
		if (Assets.hasLibrary(OTHER)) Assets.removeLibrary(OTHER, false);
	}

	public function testNothingIsCompleteBeforeLoading():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		preloader.addLibrary(new StubLibrary(100));

		Assert.isFalse(preloader.complete == true);
		Assert.equals(0, record.completed);
	}

	public function testWithNothingToLoadItCompletesAtOnce():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		preloader.load();

		Assert.isTrue(preloader.complete);
		Assert.equals(1, record.completed);
		Assert.isTrue(record.neverPastTheTotal());
	}

	public function testItWaitsForItsLibrary():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		var library = new StubLibrary(100);
		preloader.addLibrary(library);
		preloader.load();

		Assert.equals(1, library.loads);
		Assert.isFalse(preloader.complete == true);
		Assert.equals(0, record.completed);

		library.finish();

		Assert.isTrue(preloader.complete);
		Assert.equals(1, record.completed);
	}

	public function testALibraryThatIsAlreadyLoadedCompletesIt():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		var library = new StubLibrary(100);
		library.finish();
		preloader.addLibrary(library);
		preloader.load();

		Assert.isTrue(preloader.complete);
		Assert.equals(1, record.completed);
		Assert.equals("100/100", record.last());
	}

	public function testItWaitsForEveryLibrary():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		var libraries = [new StubLibrary(100), new StubLibrary(200), new StubLibrary(300)];
		for (library in libraries) preloader.addLibrary(library);
		preloader.load();

		// Not in the order they were added
		libraries[1].finish();
		Assert.isFalse(preloader.complete == true);
		libraries[2].finish();
		Assert.isFalse(preloader.complete == true);
		Assert.equals(0, record.completed);
		libraries[0].finish();

		Assert.isTrue(preloader.complete);
		Assert.equals(1, record.completed);
	}

	public function testTheTotalIsTheSizeOfEveryLibrary():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		var libraries = [new StubLibrary(100), new StubLibrary(200), new StubLibrary(300)];
		for (library in libraries) preloader.addLibrary(library);
		preloader.load();

		Assert.equals("0/600", record.last());

		libraries[0].finish();
		Assert.equals("100/600", record.last());
		libraries[2].finish();
		Assert.equals("400/600", record.last());
		libraries[1].finish();
		Assert.equals("600/600", record.last());
	}

	public function testALibrarysProgressIsReportedAsItLoads():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		var library = new StubLibrary(1000);
		preloader.addLibrary(library);
		preloader.load();

		library.report(250);
		Assert.equals("250/1000", record.last());
		library.report(750);
		Assert.equals("750/1000", record.last());
		library.finish();
		Assert.equals("1000/1000", record.last());
		Assert.isTrue(record.neverBackwards());
	}

	public function testProgressOfSeveralLibrariesIsAddedUp():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		var first = new StubLibrary(1000);
		var second = new StubLibrary(500);
		preloader.addLibrary(first);
		preloader.addLibrary(second);
		preloader.load();

		first.report(400);
		Assert.equals("400/1500", record.last());
		second.report(100);
		Assert.equals("500/1500", record.last());

		// A library reports all that it has loaded so far, not what it loaded since
		first.report(400);
		Assert.equals("500/1500", record.last());
		first.report(900);
		Assert.equals("1000/1500", record.last());

		second.finish();
		Assert.equals("1400/1500", record.last());
		first.finish();
		Assert.equals("1500/1500", record.last());

		Assert.isTrue(preloader.complete);
		Assert.isTrue(record.neverBackwards());
		Assert.isTrue(record.neverPastTheTotal());
	}

	public function testEverythingIsReportedLoadedBeforeItCompletes():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		var library = new StubLibrary(64);
		preloader.addLibrary(library);
		preloader.load();
		library.report(10);
		library.finish();

		Assert.equals("64/64", record.atCompletion);
	}

	public function testProgressAfterCompletionDoesNotCompleteItAgain():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		var library = new StubLibrary(100);
		preloader.addLibrary(library);
		preloader.load();
		library.finish();
		library.report(100);

		Assert.equals(1, record.completed);
	}

	public function testALibraryThatFailsDoesNotCompleteIt():Void
	{
		var preloader = new Preloader();
		var record = new Record(preloader);
		var failing = new StubLibrary(100);
		var loading = new StubLibrary(100);
		preloader.addLibrary(failing);
		preloader.addLibrary(loading);
		preloader.load();

		// The preloader logs the error, which is otherwise thrown
		Log.throwErrors = false;
		failing.fail("the library is missing");
		Log.throwErrors = true;
		loading.finish();

		Assert.isFalse(preloader.complete == true, "the preloader completed without one of its libraries");
		Assert.equals(0, record.completed);
		Assert.isTrue(record.neverPastTheTotal());
	}

	public function testLibrariesGivenByNameAreLoadedAfterTheOthers():Void
	{
		var named = new StubLibrary(300);
		Assets.registerLibrary(NAME, named);

		var preloader = new Preloader();
		var record = new Record(preloader);
		var library = new StubLibrary(100);
		preloader.addLibrary(library);
		preloader.addLibraryName(NAME);
		preloader.load();

		Assert.equals(0, named.loads);
		library.finish();
		Assert.equals(1, named.loads);
		Assert.isFalse(preloader.complete == true);

		named.finish();
		Assert.isTrue(preloader.complete);
		Assert.equals(1, record.completed);
	}

	public function testANameGivenTwiceIsLoadedOnce():Void
	{
		var named = new StubLibrary(300);
		Assets.registerLibrary(NAME, named);

		var preloader = new Preloader();
		var record = new Record(preloader);
		preloader.addLibraryName(NAME);
		preloader.addLibraryName(NAME);
		preloader.load();

		Assert.equals(1, named.loads);
		named.finish();
		Assert.isTrue(preloader.complete);
		Assert.equals(1, record.completed);
	}

	public function testItWaitsForEveryLibraryGivenByName():Void
	{
		var first = new StubLibrary(300);
		var second = new StubLibrary(300);
		Assets.registerLibrary(NAME, first);
		Assets.registerLibrary(OTHER, second);

		var preloader = new Preloader();
		var record = new Record(preloader);
		preloader.addLibraryName(NAME);
		preloader.addLibraryName(OTHER);
		preloader.load();

		second.finish();
		Assert.isFalse(preloader.complete == true);
		Assert.equals(0, record.completed);
		first.finish();
		Assert.isTrue(preloader.complete);
		Assert.equals(1, record.completed);
	}

	public function testTheTotalTakesTheSizeANamedLibraryReports():Void
	{
		var named = new StubLibrary(4000);
		Assets.registerLibrary(NAME, named);

		var preloader = new Preloader();
		var record = new Record(preloader);
		var library = new StubLibrary(1000);
		preloader.addLibrary(library);
		preloader.addLibraryName(NAME);
		preloader.load();
		library.finish();

		// Its size is not known until it says
		named.report(1000);
		Assert.equals("2000/5000", record.last());
		named.report(3000);
		Assert.equals("4000/5000", record.last());
		named.finish();
		Assert.equals("5000/5000", record.last());

		Assert.equals("5000/5000", record.atCompletion);
		Assert.isTrue(record.neverBackwards());
		Assert.isTrue(record.neverPastTheTotal());
	}

	public function testANamedLibraryThatReportsNoProgressIsStillCountedLoaded():Void
	{
		var named = new StubLibrary(4000);
		Assets.registerLibrary(NAME, named);

		var preloader = new Preloader();
		var record = new Record(preloader);
		preloader.addLibraryName(NAME);
		preloader.load();

		var before = record.last();
		named.finish();
		var after = record.last();

		Assert.notEquals(before, after, "nothing was reported as the library finished loading");
		Assert.equals(after, record.atCompletion);
		Assert.equals(record.lastTotal, record.lastLoaded);
		Assert.isTrue(record.lastTotal > 0);
		Assert.isTrue(record.neverPastTheTotal());
	}

	public function testANamedLibraryThatFailsDoesNotCompleteIt():Void
	{
		var named = new StubLibrary(300);
		Assets.registerLibrary(NAME, named);

		var preloader = new Preloader();
		var record = new Record(preloader);
		preloader.addLibraryName(NAME);
		preloader.load();

		Log.throwErrors = false;
		named.fail("the library is missing");
		Log.throwErrors = true;

		Assert.isFalse(preloader.complete == true, "the preloader completed without its library");
		Assert.equals(0, record.completed);
	}

	public function testTheApplicationIsToldOfItsPreloadersProgress():Void
	{
		var application = new PreloadingModule();
		var library = new StubLibrary(100);
		application.preloader.addLibrary(library);
		application.preloader.load();
		library.report(40);
		library.finish();

		Assert.equals("40/100", application.progress[application.progress.length - 2]);
		Assert.equals("100/100", application.progress[application.progress.length - 1]);
		Assert.equals(1, application.completed);
	}
	#end
}

#if !flash
/**
	A library that loads when the test says.
**/
private class StubLibrary extends AssetLibrary
{
	public var loads:Int = 0;

	private var loading:Promise<AssetLibrary>;

	public function new(size:Int)
	{
		super();

		bytesTotal = size;
		loading = new Promise<AssetLibrary>();
	}

	public override function load():Future<AssetLibrary>
	{
		loads++;
		return loading.future;
	}

	public function report(loaded:Int):Void
	{
		loading.progress(loaded, bytesTotal);
	}

	public function finish():Void
	{
		loading.complete(this);
	}

	public function fail(message:String):Void
	{
		loading.error(message);
	}
}

/**
	What a preloader reported, as "loaded/total".
**/
private class Record
{
	public var atCompletion:String;
	public var completed:Int = 0;
	public var lastLoaded:Int = 0;
	public var lastTotal:Int = 0;
	public var reports:Array<String> = [];

	private var backwards:Bool = false;
	private var pastTheTotal:Bool = false;

	public function new(preloader:Preloader)
	{
		preloader.onProgress.add(function(loaded:Int, total:Int)
		{
			if (loaded < lastLoaded) backwards = true;
			if (loaded > total) pastTheTotal = true;

			lastLoaded = loaded;
			lastTotal = total;
			reports.push(loaded + "/" + total);
		});

		preloader.onComplete.add(function()
		{
			completed++;
			atCompletion = last();
		});
	}

	public function last():String
	{
		return reports.length > 0 ? reports[reports.length - 1] : null;
	}

	public function neverBackwards():Bool
	{
		return !backwards;
	}

	public function neverPastTheTotal():Bool
	{
		return !pastTheTotal;
	}
}

/**
	Hears of a preloader as `Application` does, without being a second application.
**/
private class PreloadingModule
{
	public var completed:Int = 0;
	public var preloader:Preloader;
	public var progress:Array<String> = [];

	public function new()
	{
		preloader = new Preloader();
		preloader.onProgress.add(function(loaded:Int, total:Int) progress.push(loaded + "/" + total));
		preloader.onComplete.add(function() completed++);
	}
}
#end
