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
			
			meta: {
				
				buildNumber: "::meta.buildNumber::",
				company: "::meta.company::",
				packageName: "::meta.packageName::",
				title: "::meta.title::",
				version: "::meta.version::"
				
			},
			
			windows: [
				::foreach windows::
				{
					
					width: ::width::,
					height: ::height::,
					x: ::x::,
					y: ::y::,
					background: ::background::,
					parameters: "::parameters::",
					fps: ::fps::,
					hardware: ::hardware::,
					display: ::display::,
					resizable: ::resizable::,
					borderless: ::borderless::,
					vsync: ::vsync::,
					fullscreen: ::fullscreen::,
					antialiasing: ::antialiasing::,
					orientation: ::orientation::,
					depthBuffer: ::depthBuffer::,
					stencilBuffer: ::stencilBuffer::,
					title: "::title::"
					
				},
				::end::
			],
			
			file: "::APP_FILE::"
			
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
	
	
	#if neko
	@:noCompletion public static function __init__ () {
		
		var loader = new neko.vm.Loader (untyped $loader);
		loader.addPath (haxe.io.Path.directory (Sys.executablePath ()));
		loader.addPath ("./");
		loader.addPath ("@executable_path/");
		
	}
	#end
	
	
}
