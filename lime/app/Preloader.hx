package lime.app;


import lime.Assets;

#if js
import js.html.Image;
import js.Browser;
import lime.net.URLLoader;
import lime.net.URLRequest;
#elseif flash
import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.Lib;
#end


class Preloader #if flash extends Sprite #end {
	
	
	public var complete:Bool;
	public var onComplete:Dynamic;
	
	#if js
	public static var images = new Map<String, Image> ();
	public static var loaders = new Map<String, URLLoader> ();
	private var loaded = 0;
	private var total = 0;
	#end
	
	
	public function new () {
		
		#if flash
		super ();
		#end
		
	}
	
	
	public function create (config:Config):Void {
		
		#if flash
		Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		
		Lib.current.addChild (this);
		
		Lib.current.loaderInfo.addEventListener (Event.COMPLETE, loaderInfo_onComplete);
		Lib.current.loaderInfo.addEventListener (Event.INIT, loaderInfo_onInit);
		Lib.current.loaderInfo.addEventListener (ProgressEvent.PROGRESS, loaderInfo_onProgress);
		Lib.current.addEventListener (Event.ENTER_FRAME, current_onEnter);
		#end
		
		#if (!flash && !js)
		start ();
		#end
		
	}
	
	
	public function load (urls:Array<String>, types:Array<AssetType>):Void {
		
		#if js
		
		var url = null;
		
		for (i in 0...urls.length) {
			
			url = urls[i];
			
			switch (types[i]) {
				
				case IMAGE:
					
					var image = new Image ();
					images.set (url, image);
					image.onload = image_onLoad;
					image.src = url;
					total++;
				
				case BINARY:
					
					var loader = new URLLoader ();
					loader.dataFormat = BINARY;
					loaders.set (url, loader);
					total++;
				
				case TEXT:
					
					var loader = new URLLoader ();
					loaders.set (url, loader);
					total++;
				
				case FONT:
					
					total++;
					loadFont (url);
				
				default:
				
			}
			
		}
		
		for (url in loaders.keys ()) {
			
			var loader = loaders.get (url);
			loader.onComplete.add (loader_onComplete);
			loader.load (new URLRequest (url));
			
		}
		
		if (total == 0) {
			
			start ();
			
		}
		
		#end
		
	}
	
	
	#if js
	private function loadFont (font:String):Void {
		
		var node = Browser.document.createElement ("span");
		node.innerHTML = "giItT1WQy@!-/#";
		var style = node.style;
		style.position = "absolute";
		style.left = "-10000px";
		style.top = "-10000px";
		style.fontSize = "300px";
		style.fontFamily = "sans-serif";
		style.fontVariant = "normal";
		style.fontStyle = "normal";
		style.fontWeight = "normal";
		style.letterSpacing = "0";
		Browser.document.body.appendChild (node);
		
		var width = node.offsetWidth;
		style.fontFamily = "'" + font + "'";
		
		var interval:Null<Int> = null;
		var found = false;
		
		var checkFont = function () {
			
			if (node.offsetWidth != width) {
				
				// Test font was still not available yet, try waiting one more interval?
				if (!found) {
					
					found = true;
					return false;
					
				}
				
				loaded ++;
				
				if (interval != null) {
					
					Browser.window.clearInterval (interval);
					
				}
				
				node.parentNode.removeChild (node);
				node = null;
				
				update (loaded, total);
				
				if (loaded == total) {
					
					start ();
					
				}
				
				return true;
				
			}
			
			return false;
			
		}
		
		if (!checkFont ()) {
			
			interval = Browser.window.setInterval (checkFont, 50);
			
		}
		
	}
	#end
	
	
	private function start ():Void {
		
		#if flash
		if (Lib.current.contains (this)) {
			
			Lib.current.removeChild (this);
			
		}
		#end
		
		if (onComplete != null) {
			
			onComplete ();
			
		}
		
	}
	
	
	private function update (loaded:Int, total:Int):Void {
		
		
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	#if js
	private function image_onLoad (_):Void {
		
		loaded++;
		
		update (loaded, total);
		
		if (loaded == total) {
			
			start ();
			
		}
		
	}
	
	
	private function loader_onComplete (loader:URLLoader):Void {
		
		loaded++;
		
		update (loaded, total);
		
		if (loaded == total) {
			
			start ();
			
		}
		
	}
	#end
	
	
	#if flash
	private function current_onEnter (event:Event):Void {
		
		if (complete) {
			
			Lib.current.removeEventListener (Event.ENTER_FRAME, current_onEnter);
			Lib.current.loaderInfo.removeEventListener (Event.COMPLETE, loaderInfo_onComplete);
			Lib.current.loaderInfo.removeEventListener (Event.INIT, loaderInfo_onInit);
			Lib.current.loaderInfo.removeEventListener (ProgressEvent.PROGRESS, loaderInfo_onProgress);
			
			start ();
			
		}
		
	}
	
	
	private function loaderInfo_onComplete (event:flash.events.Event):Void {
		
		complete = true;
		update (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
		
	}
	
	
	private function loaderInfo_onInit (event:flash.events.Event):Void {
		
		update (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
		
	}
	
	
	private function loaderInfo_onProgress (event:flash.events.ProgressEvent):Void {
		
		update (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
		
	}
	#end
	
	
}