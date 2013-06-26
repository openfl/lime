#if (!lime && !flambe)


import ::APP_MAIN_PACKAGE::::APP_MAIN_CLASS::;
import nme.display.Bitmap;
import nme.display.Loader;
import nme.events.Event;
import nme.media.Sound;
import nme.net.URLLoader;
import nme.net.URLRequest;
import nme.net.URLLoaderDataFormat;
import nme.Assets;
import nme.Lib;


class ApplicationMain {
	
	
	private static var completed:Int;
	private static var preloader:NMEPreloader;
	private static var total:Int;
	
	public static var loaders:Hash <Loader>;
	public static var urlLoaders:Hash <URLLoader>;
	
	
	public static function main () {
		
		completed = 0;
		loaders = new Hash <Loader> ();
		urlLoaders = new Hash <URLLoader> ();
		total = 0;
		
		::if (WIN_WIDTH == "0")::::if (WIN_HEIGHT == "0")::
		browser.Lib.preventDefaultTouchMove ();
		::end::::end::
		
		::if (PRELOADER_NAME!="")::
		preloader = new ::PRELOADER_NAME:: ();
		::else::
		preloader = new NMEPreloader ();
		::end::
		Lib.current.addChild (preloader);
		preloader.onInit ();
		
		::foreach assets::
		::if (type=="image")::
		var loader:Loader = new Loader ();
		loaders.set ("::resourceName::", loader);
		total ++;
		::elseif (type == "binary")::
		var urlLoader:URLLoader = new URLLoader ();
		urlLoader.dataFormat = BINARY;
		urlLoaders.set ("::resourceName::", urlLoader);
		total ++;
		::elseif (type == "text")::
		var urlLoader:URLLoader = new URLLoader ();
		urlLoader.dataFormat = TEXT;
		urlLoaders.set ("::resourceName::", urlLoader);
		total ++;
		::end::::end::
		
		if (total == 0) {
			
			begin ();
			
		} else {
			
			for (path in loaders.keys ()) {
				
				var loader:Loader = loaders.get (path);
				loader.contentLoaderInfo.addEventListener ("complete", loader_onComplete);
				loader.load (new URLRequest (path));
				
			}
			
			for (path in urlLoaders.keys ()) {
				
				var urlLoader:URLLoader = urlLoaders.get (path);
				urlLoader.addEventListener ("complete", loader_onComplete);
				urlLoader.load (new URLRequest (path));
				
			}
			
		}
		
	}
	
	
	private static function begin ():Void {
		
		preloader.addEventListener (Event.COMPLETE, preloader_onComplete);
		preloader.onLoaded ();
		
	}
	

   public static function getAsset(inName:String):Dynamic {
	   
		::foreach assets::
		if (inName=="::id::") {
			::if (type == "image")::
			return Assets.getBitmapData ("::id::");
			::elseif (type=="sound")::
			return Assets.getSound ("::id::");
			::elseif (type=="music")::
			return Assets.getSound ("::id::");
			::elseif (type== "font")::
			return Assets.getFont ("::id::");
			::elseif (type== "text")::
			return Assets.getText ("::id::");
			::else::
			return Assets.getBytes ("::id::");
			::end::
		}
		::end::
		return null;
		
   }
   
   
   
   
   // Event Handlers
   
   
   
   
	private static function loader_onComplete (event:Event):Void {
		
		completed ++;
		
		preloader.onUpdate (completed, total);
		
		if (completed == total) {
			
			begin ();
			
		}
	   
	}
	
	
	private static function preloader_onComplete (event:Event):Void {
		
		preloader.removeEventListener (Event.COMPLETE, preloader_onComplete);
		
		Lib.current.removeChild(preloader);
		preloader = null;
		
		if (Reflect.field(::APP_MAIN::, "main") == null)
		{
			var mainDisplayObj = new ::APP_MAIN::();
			if (Std.is(mainDisplayObj, browser.display.DisplayObject))
				nme.Lib.current.addChild(cast mainDisplayObj);
		}
		else
		{
			Reflect.callMethod (::APP_MAIN::, Reflect.field (::APP_MAIN::, "main"), []);
		}
		
	}
   
   
}


::foreach assets::
	::if (type=="font")::
		class NME_::flatName:: extends nme.text.Font { }
	::end::
::end::


#else


import ::APP_MAIN_PACKAGE::::APP_MAIN_CLASS::;
import lime.LiME;

class ApplicationMain {
	
	public static function main () {
		
			//Create the game class, give it the runtime			
		var _main_ = Type.createInstance (::APP_MAIN::, []);
			//Create an instance of lime
		var _lime = new LiME();

			//Create the config from the project.nmml info
		var config = {
			width : ::WIN_WIDTH::, 
			height : ::WIN_HEIGHT::, 
			title : "::APP_TITLE::"
		};

			//Start up
		_lime.init( _main_, config );			
		
	} //main
} //ApplicationMain


#end