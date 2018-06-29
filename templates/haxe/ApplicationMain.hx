package;


@:access(lime.app.Application)
@:access(lime.system.System)


@:dox(hide) class ApplicationMain {
	
	
	public static function main () {
		
		var projectName = "::APP_FILE::";
		
		var config = {
			
			build: "::meta.buildNumber::",
			company: "::meta.company::",
			file: "::APP_FILE::",
			name: "::meta.title::",
			orientation: "::WIN_ORIENTATION::",
			packageName: "::meta.packageName::",
			version: "::meta.version::",
			windows: [
				::foreach windows::
				{
					allowHighDPI: ::allowHighDPI::,
					alwaysOnTop: ::alwaysOnTop::,
					antialiasing: ::antialiasing::,
					background: ::background::,
					borderless: ::borderless::,
					colorDepth: ::colorDepth::,
					depthBuffer: ::depthBuffer::,
					display: ::display::,
					fps: ::fps::,
					fullscreen: ::fullscreen::,
					hardware: ::hardware::,
					height: ::height::,
					hidden: #if munit true #else ::hidden:: #end,
					maximized: ::maximized::,
					minimized: ::minimized::,
					parameters: ::parameters::,
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
		
		lime.system.System.__registerEntryPoint (projectName, create, config);
		
		#if sys
		lime.system.System.__parseArguments (config);
		#end
		
		#if (!html5 || munit)
		create (config);
		#end
		
	}
	
	
	public static function create (config:lime.app.Config):Void {
		
		ManifestResources.init (config);
		
		var preloader = new ::if (PRELOADER_NAME != "")::::PRELOADER_NAME::::else::lime.utils.Preloader::end:: ();
		
		#if !munit
		var app = new ::APP_MAIN:: ();
		app.setPreloader (preloader);
		app.create (config);
		#end
		
		preloader.create (config);
		
		for (library in ManifestResources.preloadLibraries) {
			
			preloader.addLibrary (library);
			
		}
		
		for (name in ManifestResources.preloadLibraryNames) {
			
			preloader.addLibraryName (name);
			
		}
		
		preloader.load ();
		
		#if !munit
		start (app);
		#end
		
	}
	
	
	public static function start (app:lime.app.Application = null):Void {
		
		#if !munit
		
		var result = app.exec ();
		
		#if (sys && !ios && !nodejs && !emscripten)
		lime.system.System.exit (result);
		#end
		
		#else
		
		new ::APP_MAIN:: ();
		
		#end
		
	}
	
	
	@:noCompletion @:dox(hide) public static function __init__ () {
		
		var init = lime.app.Application;
		
		#if neko
		// Copy from https://github.com/HaxeFoundation/haxe/blob/development/std/neko/_std/Sys.hx#L164
		// since Sys.programPath () isn't available in __init__
		var sys_program_path = {
			var m = neko.vm.Module.local().name;
			try {
				sys.FileSystem.fullPath(m);
			} catch (e:Dynamic) {
				// maybe the neko module name was supplied without .n extension...
				if (!StringTools.endsWith(m, ".n")) {
					try {
						sys.FileSystem.fullPath(m + ".n");
					} catch (e:Dynamic) {
						m;
					}
				} else {
					m;
				}
			}
		};
		
		var loader = new neko.vm.Loader (untyped $loader);
		loader.addPath (haxe.io.Path.directory (#if (haxe_ver >= 3.3) sys_program_path #else Sys.executablePath () #end));
		loader.addPath ("./");
		loader.addPath ("@executable_path/");
		#end
		
	}
	
	
}