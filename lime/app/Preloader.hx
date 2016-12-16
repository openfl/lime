package lime.app;


import haxe.io.Bytes;
import haxe.io.Path;
import lime.app.Event;
import lime.audio.AudioBuffer;
import lime.utils.AssetLibrary;
import lime.utils.Assets;
import lime.utils.AssetType;

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

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class Preloader #if flash extends Sprite #end {
	
	
	public var complete:Bool;
	public var onComplete = new Event<Void->Void> ();
	public var onProgress = new Event<Int->Int->Void> ();
	
	private var libraries:Array<AssetLibrary>;
	private var loadedLibraries:Int;
	private var loadedStage:Bool;
	
	
	public function new () {
		
		#if flash
		super ();
		#end
		
		libraries = new Array<AssetLibrary> ();
		
		onProgress.add (update);
		
	}
	
	
	public function addLibrary (library:AssetLibrary):Void {
		
		libraries.push (library);
		
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
		
		loadedLibraries = -1;
		
		for (library in libraries) {
			
			library.load ().onComplete (function (_) {
				
				loadedLibraries++;
				updateProgress ();
				
			});
			
		}
		
		loadedLibraries++;
		updateProgress ();
		
	}
	
	
	private function start ():Void {
		
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
		
		update (loadedLibraries, libraries.length);
		
		if (#if flash loadedStage && #end loadedLibraries == libraries.length) {
			
			start ();
			
		}
		
	}
	
	
	#if flash
	private function current_onEnter (event:flash.events.Event):Void {
		
		if (!loadedStage && Lib.current.loaderInfo.bytesLoaded == Lib.current.loaderInfo.bytesTotal) {
			
			loadedStage = true;
			onProgress.dispatch (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
			
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
		
		loadedStage = true;
		onProgress.dispatch (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
		
	}
	
	
	private function loaderInfo_onInit (event:flash.events.Event):Void {
		
		onProgress.dispatch (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
		
	}
	
	
	private function loaderInfo_onProgress (event:flash.events.ProgressEvent):Void {
		
		onProgress.dispatch (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
		
	}
	#end
	
	
}