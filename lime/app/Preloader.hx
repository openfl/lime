package lime.app;


import lime.app.Event;
import lime.Assets;

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


class Preloader #if flash extends Sprite #end {
	
	
	public var complete:Bool;
	public var onComplete = new Event<Void->Void> ();
	public var onProgress = new Event<Int->Int->Void> ();
	public var onError = new Event<String->Void> ();

	#if (js && html5)
	public static var images = new Map<String, Image> ();
	public static var loaders = new Map<String, HTTPRequest> ();
	private var loaded = 0;
	private var total = 0;
	#end
	
	
	public function new () {
		
		#if flash
		super ();
		#end
		
		onProgress.add (update);
		
	}
	
	
	public function create (config:Config):Void {
		
		#if flash
		Lib.current.addChild (this);
		
		Lib.current.loaderInfo.addEventListener (flash.events.Event.COMPLETE, loaderInfo_onComplete);
		Lib.current.loaderInfo.addEventListener (flash.events.Event.INIT, loaderInfo_onInit);
		Lib.current.loaderInfo.addEventListener (ProgressEvent.PROGRESS, loaderInfo_onProgress);
		Lib.current.addEventListener (flash.events.Event.ENTER_FRAME, current_onEnter);
		#end
		
		#if (!flash && !html5)
		start ();
		#end
		
	}
	
	
	public function load (urls:Array<String>, types:Array<AssetType>):Void {
		
		#if (js && html5)
		
		var url = null;
		var cacheVersion = Assets.cache.version;
		
		for (i in 0...urls.length) {
			
			url = urls[i];
			
			switch (types[i]) {
				
				case IMAGE:
					
					if (!images.exists (url)) {
						
						var image = new Image ();
						images.set (url, image);
						image.crossOrigin = "Anonymous";
						image.onload = image_onLoad;
						image.onerror = image_onError;
						image.src = url + "?" + cacheVersion;
						total++;
						
					}
				
				case BINARY:
					
					if (!loaders.exists (url)) {
						
						var loader = new HTTPRequest ();
						loaders.set (url, loader);
						total++;
						
					}
				
				case TEXT:
					
					if (!loaders.exists (url)) {
						
						var loader = new HTTPRequest ();
						loaders.set (url, loader);
						total++;
						
					}
				
				case FONT:
					
					total++;
					loadFont (url);
				
				default:
				
			}
			
		}
		
		for (url in loaders.keys ()) {
			
			var loader = loaders.get (url);
			var future = loader.load (url + "?" + cacheVersion);
			future.onComplete (loader_onComplete).onError(loader_onError);

		}
		
		if (total == 0) {
			
			start ();
			
		}
		
		#end
		
	}
	
	
	#if (js && html5)
	private function loadFont (font:String):Void {
		
		if (untyped (Browser.document).fonts && untyped (Browser.document).fonts.load) {
			
			untyped (Browser.document).fonts.load ("1em '" + font + "'").then (function (_) {
				
				loaded ++;
				onProgress.dispatch (loaded, total);
				
				if (loaded == total) {
					
					start ();
					
				}
				
			});
			
		} else {
			var baseFont:String;
			if( font == "Arial" ){
				baseFont = "serif";
			} else {
				baseFont = "sans-serif";
			}
			var node:SpanElement = cast Browser.document.createElement ("span");
			node.innerHTML = "giItT1WQy@!-/#";
			var style = node.style;
			style.position = "absolute";
			style.left = "-10000px";
			style.top = "-10000px";
			style.fontSize = "300px";
			style.fontFamily = baseFont;
			style.fontVariant = "normal";
			style.fontStyle = "normal";
			style.fontWeight = "normal";
			style.letterSpacing = "0";
			Browser.document.body.appendChild (node);
			
			var width = node.offsetWidth;
			style.fontFamily = "'" + font + "', " + baseFont;

			var interval:Null<Int> = null;
			var found = false;
			var cycles = 0;

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
					
					onProgress.dispatch (loaded, total);
					
					if (loaded == total) {
						
						start ();
						
					}
					
					return true;

				} else {
					++cycles;

					if( cycles > 200 ){
						if (interval != null) {

							Browser.window.clearInterval (interval);

						}

						onError.dispatch( font );
					}
				}
				
				return false;
				
			}
			
			if (!checkFont ()) {
				
				interval = Browser.window.setInterval (checkFont, 50);
				
			}
			
		}
		
	}
	#end
	
	
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
	
	
	
	
	// Event Handlers
	
	
	
	
	#if (js && html5)
	private function image_onLoad (_):Void {
		
		loaded++;
		
		onProgress.dispatch (loaded, total);
		
		if (loaded == total) {
			
			start ();
			
		}
		
	}

	private function image_onError (event):Void {
		onError.dispatch( event.target.src );
	}


	private function loader_onComplete (_):Void {
		
		loaded++;
		
		onProgress.dispatch (loaded, total);
		
		if (loaded == total) {
			
			start ();
			
		}

	}

	private function loader_onError (event):Void {
		onError.dispatch( "unknown" );
	}
	#end
	
	
	#if flash
	private function current_onEnter (event:flash.events.Event):Void {
		
		if (!complete && Lib.current.loaderInfo.bytesLoaded == Lib.current.loaderInfo.bytesTotal) {
			
			complete = true;
			onProgress.dispatch (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
			
		}
		
		if (complete) {
			
			Lib.current.removeEventListener (flash.events.Event.ENTER_FRAME, current_onEnter);
			Lib.current.loaderInfo.removeEventListener (flash.events.Event.COMPLETE, loaderInfo_onComplete);
			Lib.current.loaderInfo.removeEventListener (flash.events.Event.INIT, loaderInfo_onInit);
			Lib.current.loaderInfo.removeEventListener (ProgressEvent.PROGRESS, loaderInfo_onProgress);
			
			start ();
			
		}
		
	}
	
	
	private function loaderInfo_onComplete (event:flash.events.Event):Void {
		
		complete = true;
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