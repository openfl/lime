package;


@:access(lime.app.Application)
@:access(lime.system.System)


@:dox(hide) class ApplicationMain {
	
	
	public static function main () {
		
		lime.system.System.__registerEntryPoint ("::APP_FILE::", create);
		
		#if (!html5 || munit)
		create (null);
		#end
		
	}
	
	
	public static function create (config:Dynamic):Void {
		
		ManifestResources.init (config);
		
		var preloader = new ::if (PRELOADER_NAME != "")::::PRELOADER_NAME::::else::lime.utils.Preloader::end:: ();
		
		#if !munit
		var app = new ::APP_MAIN:: ();
		app.setPreloader (preloader);
		
		app.meta.build = "::meta.buildNumber::";
		app.meta.company = "::meta.company::";
		app.meta.file = "::APP_FILE::";
		app.meta.name = "::meta.title::";
		app.meta.packageName = "::meta.packageName::";
		
		::foreach windows::
		var window = new lime.ui.Window ();
		::if (allowHighDPI)::window.allowHighDPI = ::allowHighDPI::;::end::
		::if (alwaysOnTop)::window.alwaysOnTop = ::alwaysOnTop::;::end::
		::if (borderless)::window.borderless = ::borderless::;::end::
		::if (fps)::window.frameRate = ::fps::;::end::
		::if (fullscreen)::#if !web window.fullscreen = ::fullscreen::; #end::end::
		::if (height)::window.height = ::height::;::end::
		::if (hidden)::window.hidden = #if munit true #else ::hidden:: #end;::end::
		::if (maximized)::window.maximized = ::maximized::;::end::
		::if (minimized)::window.minimized = ::minimized::;::end::
		::if (parameters)::window.parameters = ::parameters::;::end::
		::if (resizable)::window.resizable = ::resizable::;::end::
		::if (title)::window.title = "::title::";::end::
		::if (width)::window.width = ::width::;::end::
		::if (x)::window.x = ::x::;::end::
		::if (y)::window.y = ::y::;::end::
		
		var attributes = {
			
			antialiasing: ::antialiasing::,
			background: ::background::,
			colorDepth: ::colorDepth::,
			depth: ::depthBuffer::,
			element: null,
			hardware: ::hardware::,
			stencil: ::stencilBuffer::,
			type: null,
			vsync: ::vsync::
			
		};
		
		if (app.window == null) {
			
			if (config != null) {
				
				for (field in Reflect.fields (config)) {
					
					if (Reflect.hasField (window, field)) {
						
						Reflect.setField (window, field, Reflect.field (config, field));
						
					} else if (Reflect.hasField (attributes, field)) {
						
						Reflect.setField (attributes, field, Reflect.field (config, field));
						
					}
					
				}
				
			}
			
			#if sys
			lime.system.System.__parseArguments (window, attributes);
			#end
			
		}
		
		window.setContextAttributes (attributes);
		app.addWindow (window);
		::end::
		#end
		
		preloader.create ();
		
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