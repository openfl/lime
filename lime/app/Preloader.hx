package lime.app;


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


class Preloader #if flash extends Sprite #end {
	
	
	public var complete (default, null):Bool;
	public var onComplete = new Event<Void->Void> ();
	public var onProgress = new Event<Int->Int->Void> ();
	
	private var bytesLoaded:Int;
	private var bytesLoadedCache = new Map<AssetLibrary, Int> ();
	private var bytesLoadedCache2 = new Map<String, Int> ();
	private var bytesTotal:Int;
	private var bytesTotalCache = new Map<String, Int> ();
	private var initLibraryNames:Bool;
	private var libraries:Array<AssetLibrary>;
	private var libraryNames:Array<String>;
	private var loadedLibraries:Int;
	private var loadedStage:Bool;
	private var preloadStarted:Bool;
	private var simulateProgress:Bool;
	
	
	public function new () {
		
		#if flash
		super ();
		#end
		
		bytesLoaded = 0;
		bytesTotal = 0;
		libraries = new Array<AssetLibrary> ();
		libraryNames = new Array<String> ();
		
		onProgress.add (update);
		
		#if simulate_preloader
		var preloadTime = Std.parseInt (Compiler.getDefine ("simulate_preloader"));
		
		if (preloadTime == 1) {
			
			preloadTime = 3000;
			
		}
		
		var startTime = System.getTimer ();
		var currentTime = 0;
		var timeStep = Std.int (1000 / 60);
		var timer = new Timer (timeStep);
		
		simulateProgress = true;
		
		timer.run = function () {
			
			currentTime = System.getTimer () - startTime;
			if (currentTime > preloadTime) currentTime = preloadTime;
			onProgress.dispatch (currentTime, preloadTime);
			
			if (currentTime >= preloadTime) {
				
				timer.stop ();
				
				simulateProgress = false;
				start ();
				
			}
			
		};
		#end
		
	}
	
	
	public function addLibrary (library:AssetLibrary):Void {
		
		libraries.push (library);
		
	}
	
	
	public function addLibraryName (name:String):Void {
		
		if (libraryNames.indexOf (name) == -1) {
			
			libraryNames.push (name);
			
		}
		
	}
	
	
	public function create (config:Config):Void {
		
		#if flash
		Lib.current.addChild (this);
		
		Lib.current.loaderInfo.addEventListener (flash.events.Event.COMPLETE, loaderInfo_onComplete);
		Lib.current.loaderInfo.addEventListener (flash.events.Event.INIT, loaderInfo_onInit);
		Lib.current.loaderInfo.addEventListener (ProgressEvent.PROGRESS, loaderInfo_onProgress);
		Lib.current.addEventListener (flash.events.Event.ENTER_FRAME, current_onEnter);
		#end
		
	}
	
	
	public function load ():Void {
		
		for (library in libraries) {
			
			bytesTotal += library.bytesTotal;
			
		}
		
		loadedLibraries = -1;
		preloadStarted = false;
		
		for (library in libraries) {
			
			Log.verbose ("Preloading asset library");
			
			library.load ().onProgress (function (loaded, total) {
				
				if (!bytesLoadedCache.exists (library)) {
					
					bytesLoaded += loaded;
					
				} else {
					
					bytesLoaded += loaded - bytesLoadedCache.get (library);
					
				}
				
				bytesLoadedCache.set (library, loaded);
				
				if (!simulateProgress) {
					
					onProgress.dispatch (bytesLoaded, bytesTotal);
					
				}
				
			}).onComplete (function (_) {
				
				if (!bytesLoadedCache.exists (library)) {
					
					bytesLoaded += library.bytesTotal;
					
				} else {
					
					bytesLoaded += library.bytesTotal - bytesLoadedCache.get (library);
					
				}
				
				loadedAssetLibrary ();
				
			}).onError (function (e) {
				
				Log.error (e);
				
			});
			
		}
		
		// TODO: Handle bytes total better
		
		for (name in libraryNames) {
			
			bytesTotal += 200;
			
		}
		
		loadedLibraries++;
		preloadStarted = true;
		updateProgress ();
		
	}
	
	
	private function loadedAssetLibrary (name:String = null):Void {
		
		loadedLibraries++;
		
		var current = loadedLibraries;
		if (!preloadStarted) current++;
		
		var totalLibraries = libraries.length + libraryNames.length;
		
		if (name != null) {
			
			Log.verbose ("Loaded asset library: " + name + " [" + current + "/" + totalLibraries + "]");
			
		} else {
			
			Log.verbose ("Loaded asset library [" + current + "/" + totalLibraries + "]");
			
		}
		
		updateProgress ();
		
	}
	
	
	private function start ():Void {
		
		if (complete) return;
		
		complete = true;
		
		#if flash
		if (Lib.current.contains (this)) {
			
			Lib.current.removeChild (this);
			
		}
		#end
		
		onComplete.dispatch ();
		
	}
	
	
	private function update (loaded:Int, total:Int):Void {
		
		
		
	}
	
	
	private function updateProgress ():Void {
		
		if (!simulateProgress) {
			
			onProgress.dispatch (bytesLoaded, bytesTotal);
			
		}
		
		if (#if flash loadedStage && #end loadedLibraries == libraries.length && !initLibraryNames) {
			
			initLibraryNames = true;
			
			for (name in libraryNames) {
				
				Log.verbose ("Preloading asset library: " + name);
				
				Assets.loadLibrary (name).onProgress (function (loaded, total) {
					
					if (total > 0) {
						
						if (!bytesTotalCache.exists (name)) {
							
							bytesTotalCache.set (name, total);
							bytesTotal += (total - 200);
							
						}
						
						if (loaded > total) loaded = total;
						
						if (!bytesLoadedCache2.exists (name)) {
							
							bytesLoaded += loaded;
							
						} else {
							
							bytesLoaded += loaded - bytesLoadedCache2.get (name);
							
						}
						
						bytesLoadedCache2.set (name, loaded);
						
						if (!simulateProgress) {
							
							onProgress.dispatch (bytesLoaded, bytesTotal);
							
						}
						
					}
					
				}).onComplete (function (library) {
					
					var total = 200;
					
					if (bytesTotalCache.exists (name)) {
						
						total = bytesTotalCache.get (name);
						
					}
					
					if (!bytesLoadedCache2.exists (name)) {
						
						bytesLoaded += total;
						
					} else {
						
						bytesLoaded += total - bytesLoadedCache2.get (name);
						
					}
					
					loadedAssetLibrary (name);
					
				}).onError (function (e) {
					
					Log.error (e);
					
				});
				
			}	
			
		}
		
		if (!simulateProgress && #if flash loadedStage && #end loadedLibraries == (libraries.length + libraryNames.length)) {
			
			Log.verbose ("Preload complete");
			
			start ();
			
		}
		
	}
	
	
	#if flash
	private function current_onEnter (event:flash.events.Event):Void {
		
		if (!loadedStage && Lib.current.loaderInfo.bytesLoaded == Lib.current.loaderInfo.bytesTotal) {
			
			loadedStage = true;
			
			if (bytesTotalCache["_root"] > 0) {
				
				var loaded = Lib.current.loaderInfo.bytesLoaded;
				bytesLoaded += loaded - bytesLoadedCache2["_root"];
				bytesLoadedCache2["_root"] = loaded;
				
				updateProgress ();
				
			}
			
		}
		
		if (loadedStage) {
			
			Lib.current.removeEventListener (flash.events.Event.ENTER_FRAME, current_onEnter);
			Lib.current.loaderInfo.removeEventListener (flash.events.Event.COMPLETE, loaderInfo_onComplete);
			Lib.current.loaderInfo.removeEventListener (flash.events.Event.INIT, loaderInfo_onInit);
			Lib.current.loaderInfo.removeEventListener (ProgressEvent.PROGRESS, loaderInfo_onProgress);
			
			updateProgress ();
			
		}
		
	}
	
	
	private function loaderInfo_onComplete (event:flash.events.Event):Void {
		
		//loadedStage = true;
		
		if (bytesTotalCache["_root"] > 0) {
			
			var loaded = Lib.current.loaderInfo.bytesLoaded;
			bytesLoaded += loaded - bytesLoadedCache2["_root"];
			bytesLoadedCache2["_root"] = loaded;
			
			updateProgress ();
			
		}
		
	}
	
	
	private function loaderInfo_onInit (event:flash.events.Event):Void {
		
		bytesTotal += Lib.current.loaderInfo.bytesTotal;
		bytesTotalCache["_root"] = Lib.current.loaderInfo.bytesTotal;
		
		if (bytesTotalCache["_root"] > 0) {
			
			var loaded = Lib.current.loaderInfo.bytesLoaded;
			bytesLoaded += loaded;
			bytesLoadedCache2["_root"] = loaded;
			
			updateProgress ();
			
		}
		
	}
	
	
	private function loaderInfo_onProgress (event:flash.events.ProgressEvent):Void {
		
		if (bytesTotalCache["_root"] > 0) {
			
			var loaded = Lib.current.loaderInfo.bytesLoaded;
			bytesLoaded += loaded - bytesLoadedCache2["_root"];
			bytesLoadedCache2["_root"] = loaded;
			
			updateProgress ();
			
		}
		
	}
	#end
	
	
}