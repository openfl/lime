package lime.utils;

import haxe.ds.ObjectMap;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.Timer;
import lime.app.Event;
import lime.media.AudioBuffer;
import lime.system.System;
import lime.utils.AssetLibrary;
import lime.utils.Assets;
import lime.utils.AssetType;
import lime.utils.Log;
#if (js && html5)
import js.html.Image;
import js.html.SpanElement;
import js.Browser;
import lime.net.HTTPRequest;
#elseif flash
import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.events.ProgressEvent;
import flash.Lib;
#end

@:access(lime.utils.AssetLibrary)
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Preloader #if flash extends Sprite #end
{
	public var complete(default, null):Bool;
	public var onComplete = new Event<Void->Void>();
	public var onProgress = new Event<Int->Int->Void>();

	@:noCompletion private var bytesLoaded:Int;
	@:noCompletion private var bytesLoadedCache = new ObjectMap<#if !disable_preloader_assets AssetLibrary #else Dynamic #end, Int>();
	@:noCompletion private var bytesLoadedCache2 = new Map<String, Int>();
	@:noCompletion private var bytesTotal:Int;
	@:noCompletion private var bytesTotalCache = new Map<String, Int>();
	@:noCompletion private var initLibraryNames:Bool;
	@:noCompletion private var libraries:Array<#if !disable_preloader_assets AssetLibrary #else Dynamic #end>;
	@:noCompletion private var libraryNames:Array<String>;
	@:noCompletion private var loadedLibraries:Int;
	@:noCompletion private var loadedStage:Bool;
	@:noCompletion private var preloadComplete:Bool;
	@:noCompletion private var preloadStarted:Bool;
	@:noCompletion private var simulateProgress:Bool;

	public function new()
	{
		// TODO: Split out core preloader support from generic Preloader type

		#if flash
		super();
		#end

		bytesLoaded = 0;
		bytesTotal = 0;

		libraries = new Array<#if !disable_preloader_assets AssetLibrary #else Dynamic #end>();
		libraryNames = new Array<String>();

		onProgress.add(update);

		#if simulate_preloader
		var preloadTime = Std.parseInt(Compiler.getDefine("simulate_preloader"));

		if (preloadTime == 1)
		{
			preloadTime = 3000;
		}

		var startTime = System.getTimer();
		var currentTime = 0;
		var timeStep = Std.int(1000 / 60);
		var timer = new Timer(timeStep);

		simulateProgress = true;

		timer.run = function()
		{
			currentTime = System.getTimer() - startTime;
			if (currentTime > preloadTime) currentTime = preloadTime;
			onProgress.dispatch(currentTime, preloadTime);

			if (currentTime >= preloadTime)
			{
				timer.stop();

				simulateProgress = false;
				start();
			}
		};
		#end

		#if flash
		Lib.current.addChild(this);

		Lib.current.loaderInfo.addEventListener(flash.events.Event.COMPLETE, loaderInfo_onComplete);
		Lib.current.loaderInfo.addEventListener(flash.events.Event.INIT, loaderInfo_onInit);
		Lib.current.loaderInfo.addEventListener(ProgressEvent.PROGRESS, loaderInfo_onProgress);
		Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, current_onEnter);
		#end
	}

	public function addLibrary(library:#if !disable_preloader_assets AssetLibrary #else Dynamic #end):Void
	{
		libraries.push(library);
	}

	public function addLibraryName(name:String):Void
	{
		if (libraryNames.indexOf(name) == -1)
		{
			libraryNames.push(name);
		}
	}

	public function load():Void
	{
		for (library in libraries)
		{
			bytesTotal += library.bytesTotal;
		}

		loadedLibraries = -1;
		preloadStarted = false;

		for (library in libraries)
		{
			Log.verbose("Preloading asset library");

			library.load()
				.onProgress(function(loaded, total)
				{
					if (!bytesLoadedCache.exists(library))
					{
						bytesLoaded += loaded;
					}
					else
					{
						bytesLoaded += loaded - bytesLoadedCache.get(library);
					}

					bytesLoadedCache.set(library, loaded);

					if (!simulateProgress)
					{
						onProgress.dispatch(bytesLoaded, bytesTotal);
					}
				})
				.onComplete(function(_)
				{
					if (!bytesLoadedCache.exists(library))
					{
						bytesLoaded += library.bytesTotal;
					}
					else
					{
						bytesLoaded += Std.int(library.bytesTotal) - bytesLoadedCache.get(library);
					}

					loadedAssetLibrary();
				})
				.onError(function(e)
				{
					Log.error(e);
				});
		}

		// TODO: Handle bytes total better

		for (name in libraryNames)
		{
			bytesTotal += 200;
		}

		loadedLibraries++;
		preloadStarted = true;
		updateProgress();
	}

	@:noCompletion private function loadedAssetLibrary(name:String = null):Void
	{
		loadedLibraries++;

		var current = loadedLibraries;
		if (!preloadStarted) current++;

		var totalLibraries = libraries.length + libraryNames.length;

		if (name != null)
		{
			Log.verbose("Loaded asset library: " + name + " [" + current + "/" + totalLibraries + "]");
		}
		else
		{
			Log.verbose("Loaded asset library [" + current + "/" + totalLibraries + "]");
		}

		updateProgress();
	}

	@:noCompletion private function start():Void
	{
		if (complete || simulateProgress || !preloadComplete) return;

		complete = true;

		#if flash
		if (Lib.current.contains(this))
		{
			Lib.current.removeChild(this);
		}
		#end

		onComplete.dispatch();
	}

	@:noCompletion private function update(loaded:Int, total:Int):Void {}

	@:noCompletion private function updateProgress():Void
	{
		if (!simulateProgress)
		{
			onProgress.dispatch(bytesLoaded, bytesTotal);
		}

		#if !disable_preloader_assets
		if (#if flash loadedStage && #end loadedLibraries == libraries.length && !initLibraryNames)
		{
			initLibraryNames = true;

			for (name in libraryNames)
			{
				Log.verbose("Preloading asset library: " + name);

				Assets.loadLibrary(name)
					.onProgress(function(loaded, total)
					{
						if (total > 0)
						{
							if (!bytesTotalCache.exists(name))
							{
								bytesTotalCache.set(name, total);
								bytesTotal += (total - 200);
							}

							if (loaded > total) loaded = total;

							if (!bytesLoadedCache2.exists(name))
							{
								bytesLoaded += loaded;
							}
							else
							{
								bytesLoaded += loaded - bytesLoadedCache2.get(name);
							}

							bytesLoadedCache2.set(name, loaded);

							if (!simulateProgress)
							{
								onProgress.dispatch(bytesLoaded, bytesTotal);
							}
						}
					})
					.onComplete(function(library)
					{
						var total = 200;

						if (bytesTotalCache.exists(name))
						{
							total = bytesTotalCache.get(name);
						}

						if (!bytesLoadedCache2.exists(name))
						{
							bytesLoaded += total;
						}
						else
						{
							bytesLoaded += total - bytesLoadedCache2.get(name);
						}

						loadedAssetLibrary(name);
					})
					.onError(function(e)
					{
						Log.error(e);
					});
			}
		}
		#end

		if (!simulateProgress #if flash && loadedStage #end
			&& loadedLibraries == (libraries.length + libraryNames.length))
		{
			if (!preloadComplete)
			{
				preloadComplete = true;

				Log.verbose("Preload complete");
			}

			start();
		}
	}

	#if flash
	@:noCompletion private function current_onEnter(event:flash.events.Event):Void
	{
		if (!loadedStage && Lib.current.loaderInfo.bytesLoaded == Lib.current.loaderInfo.bytesTotal)
		{
			loadedStage = true;

			if (bytesTotalCache["_root"] > 0)
			{
				var loaded = Lib.current.loaderInfo.bytesLoaded;
				bytesLoaded += loaded - bytesLoadedCache2["_root"];
				bytesLoadedCache2["_root"] = loaded;

				updateProgress();
			}
		}

		if (loadedStage)
		{
			Lib.current.removeEventListener(flash.events.Event.ENTER_FRAME, current_onEnter);
			Lib.current.loaderInfo.removeEventListener(flash.events.Event.COMPLETE, loaderInfo_onComplete);
			Lib.current.loaderInfo.removeEventListener(flash.events.Event.INIT, loaderInfo_onInit);
			Lib.current.loaderInfo.removeEventListener(ProgressEvent.PROGRESS, loaderInfo_onProgress);

			updateProgress();
		}
	}

	@:noCompletion private function loaderInfo_onComplete(event:flash.events.Event):Void
	{
		// loadedStage = true;

		if (bytesTotalCache["_root"] > 0)
		{
			var loaded = Lib.current.loaderInfo.bytesLoaded;
			bytesLoaded += loaded - bytesLoadedCache2["_root"];
			bytesLoadedCache2["_root"] = loaded;

			updateProgress();
		}
	}

	@:noCompletion private function loaderInfo_onInit(event:flash.events.Event):Void
	{
		bytesTotal += Lib.current.loaderInfo.bytesTotal;
		bytesTotalCache["_root"] = Lib.current.loaderInfo.bytesTotal;

		if (bytesTotalCache["_root"] > 0)
		{
			var loaded = Lib.current.loaderInfo.bytesLoaded;
			bytesLoaded += loaded;
			bytesLoadedCache2["_root"] = loaded;

			updateProgress();
		}
	}

	@:noCompletion private function loaderInfo_onProgress(event:flash.events.ProgressEvent):Void
	{
		if (bytesTotalCache["_root"] > 0)
		{
			var loaded = Lib.current.loaderInfo.bytesLoaded;
			bytesLoaded += loaded - bytesLoadedCache2["_root"];
			bytesLoadedCache2["_root"] = loaded;

			updateProgress();
		}
	}
	#end
}
