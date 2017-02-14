import ::APP_MAIN::;
import lime.Assets;


@:access(lime.app.Application)


class ApplicationMain {
	
	
	public static var config:lime.app.Config;
	public static var preloader:lime.app.Preloader;
	
	private static var app:lime.app.Application;
	
	
	public static function create ():Void {
		
		preloader = new ::if (PRELOADER_NAME != "")::::PRELOADER_NAME::::else::lime.app.Preloader::end:: ();
		
		#if !munit
		app = new ::APP_MAIN:: ();
		app.setPreloader (preloader);
		app.create (config);
		#end
		
		preloader.onComplete.add (start);
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
			
			build: "::meta.buildNumber::",
			company: "::meta.company::",
			file: "::APP_FILE::",
			fps: ::WIN_FPS::,
			name: "::meta.title::",
			orientation: "::WIN_ORIENTATION::",
			packageName: "::meta.packageName::",
			version: "::meta.version::",
			windows: [
				::foreach windows::
				{
					antialiasing: ::antialiasing::,
					background: ::background::,
					borderless: ::borderless::,
					depthBuffer: ::depthBuffer::,
					display: ::display::,
					fullscreen: ::fullscreen::,
					hardware: ::hardware::,
					height: ::height::,
					parameters: "::parameters::",
					resizable: ::resizable::,
					stencilBuffer: ::stencilBuffer::,
					title: "::title::",
					vsync: ::vsync::,
					width: ::width::,
					x: ::x::,
					y: ::y::
				},::end::
			]
			
		};
		
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
	
	public static function resize(object:Dynamic): Void {
	}
	
	#if neko
	@:noCompletion @:dox(hide) public static function __init__ () {
		
		var loader = new neko.vm.Loader (untyped $loader);
		loader.addPath (haxe.io.Path.directory (Sys.executablePath ()));
		loader.addPath ("./");
		loader.addPath ("@executable_path/");
		
	}
	#end
	
	
}
