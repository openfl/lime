import ::APP_MAIN::;
import lime.Assets;


class ApplicationMain {
	
	
	public static var config:lime.app.Config;
	public static var preloader:lime.app.Preloader;
	
	private static var app:lime.app.Application;
	
	
	public static function create ():Void {
		
		#if !munit
		app = new ::APP_MAIN:: ();
		app.create (config);
		#end
		
		preloader = new ::if (PRELOADER_NAME != "")::::PRELOADER_NAME::::else::lime.app.Preloader::end:: ();
		preloader.onComplete = start;
		preloader.create (config);
		
		#if (js && html5)
		var urls = [];
		var types = [];
		
		::foreach assets::::if (embed)::
		urls.push ("::resourceName::");
		::if (type == "image")::types.push (AssetType.IMAGE);
		::elseif (type == "binary")::types.push (AssetType.BINARY);
		::elseif (type == "text")::types.push (AssetType.TEXT);
		::elseif (type == "font")::types.push (AssetType.FONT);
		::elseif (type == "sound")::types.push (AssetType.SOUND);
		::elseif (type == "music")::types.push (AssetType.MUSIC);
		::else::types.push (null);::end::
		::end::::end::
		
		if (config.assetsPrefix != null) {
			
			for (i in 0...urls.length) {
				
				if (types[i] != AssetType.FONT) {
					
					urls[i] = config.assetsPrefix + urls[i];
					
				}
				
			}
			
		}
		
		preloader.load (urls, types);
		#end
		
	}
	
	
	public static function main () {
		
		config = {
			
			antialiasing: Std.int (::WIN_ANTIALIASING::),
			background: Std.int (::WIN_BACKGROUND::),
			borderless: ::WIN_BORDERLESS::,
			company: "::META_COMPANY::",
			depthBuffer: ::WIN_DEPTH_BUFFER::,
			file: "::APP_FILE::",
			fps: Std.int (::WIN_FPS::),
			fullscreen: ::WIN_FULLSCREEN::,
			hardware: ::WIN_HARDWARE::,
			height: Std.int (::WIN_HEIGHT::),
			orientation: "::WIN_ORIENTATION::",
			packageName: "::META_PACKAGE_NAME::",
			resizable: ::WIN_RESIZABLE::,
			stencilBuffer: ::WIN_STENCIL_BUFFER::,
			title: "::APP_TITLE::",
			version: "::META_VERSION::",
			vsync: ::WIN_VSYNC::,
			width: Std.int (::WIN_WIDTH::),
			
		}
		
		#if (!html5 || munit)
		create ();
		#end
		
	}
	
	
	public static function start ():Void {
		
		#if !munit
		
		var result = app.exec ();
		
		#if (sys && !nodejs && !emscripten)
		Sys.exit (result);
		#end
		
		#else
		
		new ::APP_MAIN:: ();
		
		#end
		
	}
	
	
	#if neko
	@:noCompletion public static function __init__ () {
		
		var loader = new neko.vm.Loader (untyped $loader);
		loader.addPath (haxe.io.Path.directory (Sys.executablePath ()));
		loader.addPath ("./");
		loader.addPath ("@executable_path/");
		
	}
	#end
	
	
}
