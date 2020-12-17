package;

import ::APP_MAIN::;

@:access(lime.app.Application)
@:access(lime.system.System)

@:dox(hide) class ApplicationMain
{
	public static function main()
	{
		lime.system.System.__registerEntryPoint("::APP_FILE::", create);

		#if (!html5 || munit)
		create(null);
		#end
	}

	public static function create(config:Dynamic):Void
	{
		ManifestResources.init(config);

		#if !munit
		var app = new ::APP_MAIN::();
		app.meta.set("build", "::meta.buildNumber::");
		app.meta.set("company", "::meta.company::");
		app.meta.set("file", "::APP_FILE::");
		app.meta.set("name", "::meta.title::");
		app.meta.set("packageName", "::meta.packageName::");
		app.meta.set("version", "::meta.version::");

		#if !flash
		::foreach windows::
		var attributes:lime.ui.WindowAttributes =
			{
				allowHighDPI: ::allowHighDPI::,
				alwaysOnTop: ::alwaysOnTop::,
				borderless: ::borderless::,
				// display: ::display::,
				element: null,
				frameRate: ::fps::,
				#if !web fullscreen: ::fullscreen::, #end
				height: ::height::,
				hidden: #if munit true #else ::hidden:: #end,
				maximized: ::maximized::,
				minimized: ::minimized::,
				parameters: ::parameters::,
				resizable: ::resizable::,
				title: "::title::",
				width: ::width::,
				x: ::x::,
				y: ::y::,
			};

		attributes.context =
			{
				antialiasing: ::antialiasing::,
				background: ::background::,
				colorDepth: ::colorDepth::,
				depth: ::depthBuffer::,
				hardware: ::hardware::,
				stencil: ::stencilBuffer::,
				type: null,
				vsync: ::vsync::
			};

		if (app.window == null)
		{
			if (config != null)
			{
				for (field in Reflect.fields(config))
				{
					if (Reflect.hasField(attributes, field))
					{
						Reflect.setField(attributes, field, Reflect.field(config, field));
					}
					else if (Reflect.hasField(attributes.context, field))
					{
						Reflect.setField(attributes.context, field, Reflect.field(config, field));
					}
				}
			}

			#if sys
			lime.system.System.__parseArguments(attributes);
			#end
		}

		app.createWindow(attributes);
		::end::
		#elseif !air

		app.window.context.attributes.background = ::WIN_BACKGROUND::;
		app.window.frameRate = ::WIN_FPS::;

		#end
		#end

		// preloader.create ();

		for (library in ManifestResources.preloadLibraries)
		{
			app.preloader.addLibrary(library);
		}

		for (name in ManifestResources.preloadLibraryNames)
		{
			app.preloader.addLibraryName(name);
		}

		app.preloader.load();

		#if !munit
		start(app);
		#end
	}

	public static function start(app:lime.app.Application = null):Void
	{
		#if !munit

		var result = app.exec();

		#if (sys && !ios && !nodejs && !emscripten)
		lime.system.System.exit(result);
		#end

		#else

		new ::APP_MAIN::();

		#end
	}

	@:noCompletion @:dox(hide) public static function __init__()
	{
		var init = lime.app.Application;

		#if neko
		// Copy from https://github.com/HaxeFoundation/haxe/blob/development/std/neko/_std/Sys.hx#L164
		// since Sys.programPath () isn't available in __init__
		var sys_program_path =
			{
				var m = neko.vm.Module.local().name;
				try
				{
					sys.FileSystem.fullPath(m);
				}
				catch (e:Dynamic)
				{
					// maybe the neko module name was supplied without .n extension...
					if (!StringTools.endsWith(m, ".n"))
					{
						try
						{
							sys.FileSystem.fullPath(m + ".n");
						}
						catch (e:Dynamic)
						{
							m;
						}
					}
					else
					{
						m;
					}
				}
			};

		var loader = new neko.vm.Loader(untyped $loader);
		loader.addPath(haxe.io.Path.directory(#if (haxe_ver >= 3.3) sys_program_path #else Sys.executablePath() #end));
		loader.addPath("./");
		loader.addPath("@executable_path/");
		#end
	}
}
