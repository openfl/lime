package lime.system;

import haxe.Constraints;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Application;
import lime.graphics.RenderContextAttributes;
import lime.math.Rectangle;
import lime.ui.WindowAttributes;
import lime.utils.ArrayBuffer;
import lime.utils.UInt8Array;
import lime.utils.UInt16Array;
#if flash
import flash.net.URLRequest;
import flash.system.Capabilities;
import flash.Lib;
#end
#if air
import flash.desktop.NativeApplication;
#end
#if ((js && html5) || electron)
import js.html.Element;
import js.Browser;
#end
#if sys
import sys.io.Process;
#end

/**
	Access operating system level settings and operations.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.system.Display)
@:access(lime.system.DisplayMode)
#if (cpp && windows && !lime_disable_gpu_hint)
@:cppFileCode('
#if defined(HX_WINDOWS) && !defined(__MINGW32__)
extern "C" {
	_declspec(dllexport) unsigned long NvOptimusEnablement = 0x00000001;
	_declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;
}
#endif
')
#end
class System
{
	/**
		Determines if the screen saver is allowed to start or not.
	**/
	public static var allowScreenTimeout(get, set):Bool;

	/**
		The path to the directory where the application is installed, along with
		its supporting files. In many cases, this directory is read-only, and
		attempts to write to files, create new files, or delete files in this
		directory are likely fail.
	**/
	public static var applicationDirectory(get, never):String;

	/**
		The application's dedicated storage directory, which unique to each
		application and user. Useful for storing settings on a user-specific
		and application-specific basis.

		This directory may or may not be removed when the application is
		uninstalled, and it depends on the platform and installer technology
		that is used.
	**/
	public static var applicationStorageDirectory(get, never):String;

	/**
		The path to the directory containing the user's desktop.
	**/
	public static var desktopDirectory(get, never):String;

	public static var deviceModel(get, never):String;
	public static var deviceVendor(get, never):String;
	public static var disableCFFI:Bool;

	/**
		The path to the directory containing the user's documents.
	**/
	public static var documentsDirectory(get, never):String;

	/**
		The platform's default endianness for bytes.
	**/
	public static var endianness(get, never):Endian;

	/**
		The path to the directory where fonts are installed.
	**/
	public static var fontsDirectory(get, never):String;

	/**
		The number of available video displays.
	**/
	public static var numDisplays(get, never):Int;

	public static var platformLabel(get, never):String;
	public static var platformName(get, never):String;
	public static var platformVersion(get, never):String;

	/**
		The path to the user's home directory.
	**/
	public static var userDirectory(get, never):String;

	@:noCompletion private static var __applicationDirectory:String;
	@:noCompletion private static var __applicationEntryPoint:Map<String, Function>;
	@:noCompletion private static var __applicationStorageDirectory:String;
	@:noCompletion private static var __desktopDirectory:String;
	@:noCompletion private static var __deviceModel:String;
	@:noCompletion private static var __deviceVendor:String;
	@:noCompletion private static var __directories = new Map<SystemDirectory, String>();
	@:noCompletion private static var __documentsDirectory:String;
	@:noCompletion private static var __endianness:Endian;
	@:noCompletion private static var __fontsDirectory:String;
	@:noCompletion private static var __platformLabel:String;
	@:noCompletion private static var __platformName:String;
	@:noCompletion private static var __platformVersion:String;
	@:noCompletion private static var __userDirectory:String;

	#if (js && html5)
	@:keep @:expose("lime.embed")
	public static function embed(projectName:String, element:Dynamic, width:Null<Int> = null, height:Null<Int> = null, config:Dynamic = null):Void
	{
		if (__applicationEntryPoint == null) return;

		if (__applicationEntryPoint.exists(projectName))
		{
			var htmlElement:Element = null;

			if ((element is String))
			{
				htmlElement = cast Browser.document.getElementById(element);
			}
			else if (element == null)
			{
				htmlElement = cast Browser.document.createElement("div");
			}
			else
			{
				htmlElement = cast element;
			}

			if (htmlElement == null)
			{
				Browser.window.console.log("[lime.embed] ERROR: Cannot find target element: " + element);
				return;
			}

			if (width == null)
			{
				width = 0;
			}

			if (height == null)
			{
				height = 0;
			}

			if (config == null) config = {};

			if (Reflect.hasField(config, "background") && (config.background is String))
			{
				var background = StringTools.replace(Std.string(config.background), "#", "");

				if (background.indexOf("0x") > -1)
				{
					config.background = Std.parseInt(background);
				}
				else
				{
					config.background = Std.parseInt("0x" + background);
				}
			}

			config.element = htmlElement;
			config.width = width;
			config.height = height;

			__applicationEntryPoint[projectName](config);
		}
	}
	#end

	#if (!lime_doc_gen || sys)
	/**
		Attempts to exit the application. Dispatches `onExit`, and will not
		exit if the event is canceled. When exiting using this method, Lime will
		gracefully shut down a number of subsystems, including (but not limited
		to) audio, graphics, timers, and game controllers.

		To properly exit a Lime application, it's best to call Lime's
		`System.exit()` instead of calling Haxe's built-in `Sys.exit()`. When
		targeting native platforms especially, Lime's is built on C++ libraries
		that expose functions to clean up resources properly on exit. Haxe's
		`Sys.exit()` exits immediately without giving Lime a chance to clean
		things up. With that in mind, the proper and correct way to exit a Lime
		app is by calling `lime.system.System.exit()`, and to avoid using
		`Sys.exit()`.
	**/
	public static function exit(code:Int):Void
	{
		var currentApp = Application.current;
		#if ((sys || (js && html5) || air) && !macro)
		if (currentApp != null)
		{
			currentApp.onExit.dispatch(code);

			if (currentApp.onExit.canceled)
			{
				return;
			}
		}
		#end

		#if sys
		Sys.exit(code);
		#elseif (js && html5)
		if (currentApp != null && currentApp.window != null)
		{
			currentApp.window.close();
		}
		#elseif air
		NativeApplication.nativeApplication.exit(code);
		#end
	}
	#end

	/**
		Returns information about the video display with the specified ID.
	**/
	public static function getDisplay(id:Int):Display
	{
		#if (lime_cffi && !macro)
		var displayInfo:Dynamic = NativeCFFI.lime_system_get_display(id);

		if (displayInfo != null)
		{
			var display = new Display();
			display.id = id;
			display.name = CFFI.stringValue(displayInfo.name);
			display.bounds = new Rectangle(displayInfo.bounds.x, displayInfo.bounds.y, displayInfo.bounds.width, displayInfo.bounds.height);
			display.orientation = displayInfo.orientation;

			#if android
			var getDisplaySafeArea = JNI.createStaticMethod("org/haxe/lime/GameActivity", "getDisplaySafeAreaInsets", "()[I");
			var result = getDisplaySafeArea();
			display.safeArea = new Rectangle(
				display.bounds.x + result[0],
				display.bounds.y + result[1],
				display.bounds.width - result[0] - result[2],
				display.bounds.height - result[1] - result[3]);
			#else
			display.safeArea = new Rectangle(
				displayInfo.safeArea.x,
				displayInfo.safeArea.y,
				displayInfo.safeArea.width,
				displayInfo.safeArea.height);
			#end

			#if ios
			var tablet = NativeCFFI.lime_system_get_ios_tablet();
			var scale = Application.current.window.scale;
			if (!tablet && scale > 2.46)
			{
				display.dpi = 401; // workaround for iPhone Plus
			}
			else
			{
				display.dpi = (tablet ? 132 : 163) * scale;
			}
			#elseif android
			var getDisplayDPI = JNI.createStaticMethod("org/haxe/lime/GameActivity", "getDisplayXDPI", "()D");
			display.dpi = Math.round(getDisplayDPI());
			#else
			display.dpi = displayInfo.dpi;
			#end

			display.supportedModes = [];

			var displayMode;

			#if hl
			var supportedModes:hl.NativeArray<Dynamic> = displayInfo.supportedModes;
			#else
			var supportedModes:Array<Dynamic> = displayInfo.supportedModes;
			#end
			for (mode in supportedModes)
			{
				displayMode = new DisplayMode(mode.width, mode.height, mode.refreshRate, mode.pixelFormat);
				display.supportedModes.push(displayMode);
			}

			var mode = displayInfo.currentMode;
			var currentMode = new DisplayMode(mode.width, mode.height, mode.refreshRate, mode.pixelFormat);

			for (mode in display.supportedModes)
			{
				if (currentMode.pixelFormat == mode.pixelFormat
					&& currentMode.width == mode.width
					&& currentMode.height == mode.height
					&& currentMode.refreshRate == mode.refreshRate)
				{
					currentMode = mode;
					break;
				}
			}

			display.currentMode = currentMode;

			return display;
		}
		#elseif (flash || html5)
		if (id == 0)
		{
			var display = new Display();
			display.id = 0;
			display.name = "Generic Display";

			#if flash
			display.dpi = Capabilities.screenDPI;
			display.currentMode = new DisplayMode(Std.int(Capabilities.screenResolutionX), Std.int(Capabilities.screenResolutionY), 60, ARGB32);
			#if air
			switch (flash.Lib.current.stage.orientation) {
				case DEFAULT:
					display.orientation = PORTRAIT;
				case UPSIDE_DOWN:
					display.orientation = PORTRAIT_FLIPPED;
				case ROTATED_LEFT:
					display.orientation = LANDSCAPE_FLIPPED;
				case ROTATED_RIGHT:
					display.orientation = LANDSCAPE;
				default:
					display.orientation = UNKNOWN;
			}

			#else
			display.orientation = UNKNOWN;
			#end
			#elseif (js && html5)
			// var div = Browser.document.createElement ("div");
			// div.style.width = "1in";
			// Browser.document.body.appendChild (div);
			// var ppi = Browser.document.defaultView.getComputedStyle (div, null).getPropertyValue ("width");
			// Browser.document.body.removeChild (div);
			// display.dpi = Std.parseFloat (ppi);
			display.dpi = 96 * Browser.window.devicePixelRatio;
			display.currentMode = new DisplayMode(Browser.window.screen.width, Browser.window.screen.height, 60, ARGB32);
			if (Browser.window.screen.orientation != null)
			{
				switch (Browser.window.screen.orientation.type)
				{
					case PORTRAIT_PRIMARY:
						display.orientation = PORTRAIT;
					case PORTRAIT_SECONDARY:
						display.orientation = PORTRAIT_FLIPPED;
					case LANDSCAPE_PRIMARY:
						display.orientation = LANDSCAPE;
					case LANDSCAPE_SECONDARY:
						display.orientation = LANDSCAPE_FLIPPED;
					default:
						display.orientation = UNKNOWN;
				}
			}
			else
			{
				display.orientation = UNKNOWN;
			}
			#end

			display.supportedModes = [display.currentMode];
			display.bounds = new Rectangle(0, 0, display.currentMode.width, display.currentMode.height);
			display.safeArea = new Rectangle(0, 0, display.currentMode.width, display.currentMode.height);
			return display;
		}
		#end

		return null;
	}

	/**
		The number of milliseconds since the application was initialized.
	**/
	public static function getTimer():Int
	{
		#if flash
		return flash.Lib.getTimer();
		#elseif ((js && !nodejs) || electron)
		return Std.int(Browser.window.performance.now());
		#elseif (lime_cffi && !macro)
		return cast NativeCFFI.lime_system_get_timer();
		#elseif cpp
		return Std.int(untyped __global__.__time_stamp() * 1000);
		#elseif sys
		return Std.int(Sys.time() * 1000);
		#else
		return 0;
		#end
	}

	#if (!lime_doc_gen || lime_cffi)
	public static inline function load(library:String, method:String, args:Int = 0, lazy:Bool = false):Dynamic
	{
		#if !macro
		return CFFI.load(library, method, args, lazy);
		#else
		return null;
		#end
	}
	#end

	/**
		Opens a file with the system default application.

		In a web browser, opens a URL with target `_blank`.
	**/
	public static function openFile(path:String):Void
	{
		if (path != null)
		{
			#if (sys && windows)
			Sys.command("start", ["", path]);
			#elseif mac
			Sys.command("/usr/bin/open", [path]);
			#elseif linux
			Sys.command("/usr/bin/xdg-open", [path]);
			#elseif (js && html5)
			Browser.window.open(path, "_blank");
			#elseif flash
			Lib.getURL(new URLRequest(path), "_blank");
			#elseif android
			var openFile = JNI.createStaticMethod("org/haxe/lime/GameActivity", "openFile", "(Ljava/lang/String;)V");
			openFile(path);
			#elseif (lime_cffi && !macro)
			NativeCFFI.lime_system_open_file(path);
			#end
		}
	}

	/**
		Opens a URL with the specified target web browser window.
	**/
	public static function openURL(url:String, target:String = "_blank"):Void
	{
		if (url != null)
		{
			#if desktop
			openFile(url);
			#elseif (js && html5)
			Browser.window.open(url, target);
			#elseif flash
			Lib.getURL(new URLRequest(url), target);
			#elseif android
			var openURL = JNI.createStaticMethod("org/haxe/lime/GameActivity", "openURL", "(Ljava/lang/String;Ljava/lang/String;)V");
			openURL(url, target);
			#elseif (lime_cffi && !macro)
			NativeCFFI.lime_system_open_url(url, target);
			#end
		}
	}

	@:noCompletion private static function __copyMissingFields(target:Dynamic, source:Dynamic):Void
	{
		if (source == null || target == null) return;

		for (field in Reflect.fields(source))
		{
			if (!Reflect.hasField(target, field))
			{
				Reflect.setField(target, field, Reflect.field(source, field));
			}
		}
	}

	@:noCompletion private static function __getDirectory(type:SystemDirectory):String
	{
		#if (lime_cffi && !macro)
		if (__directories.exists(type))
		{
			return __directories.get(type);
		}
		else
		{
			var path:String;

			if (type == APPLICATION_STORAGE)
			{
				var company = "MyCompany";
				var file = "MyApplication";

				if (Application.current != null)
				{
					if (Application.current.meta.exists("company"))
					{
						company = Application.current.meta.get("company");
					}

					if (Application.current.meta.exists("file"))
					{
						file = Application.current.meta.get("file");
					}
				}

				path = CFFI.stringValue(NativeCFFI.lime_system_get_directory(type, company, file));
			}
			else
			{
				path = CFFI.stringValue(NativeCFFI.lime_system_get_directory(type, null, null));
			}

			#if windows
			var seperator = "\\";
			#else
			var seperator = "/";
			#end

			if (path != null && path.length > 0 && !StringTools.endsWith(path, seperator))
			{
				path += seperator;
			}

			__directories.set(type, path);
			return path;
		}
		#elseif flash
		if (type != FONTS && Capabilities.playerType == "Desktop")
		{
			var propertyName = switch (type)
			{
				case APPLICATION: "applicationDirectory";
				case APPLICATION_STORAGE: "applicationStorageDirectory";
				case DESKTOP: "desktopDirectory";
				case DOCUMENTS: "documentsDirectory";
				default: "userDirectory";
			}

			return Reflect.getProperty(Type.resolveClass("flash.filesystem.File"), propertyName).nativePath;
		}
		#end

		return null;
	}

	#if sys
	private static function __parseArguments(attributes:WindowAttributes):Void
	{
		// TODO: Handle default arguments, like --window-fps=60

		var arguments = Sys.args();
		var stripQuotes = ~/^['"](.*)['"]$/;
		var equals, argValue, parameters = null;
		var windowParamPrefix = "--window-";

		if (arguments != null)
		{
			for (argument in arguments)
			{
				equals = argument.indexOf("=");

				if (equals > 0)
				{
					argValue = argument.substr(equals + 1);

					if (stripQuotes.match(argValue))
					{
						argValue = stripQuotes.matched(1);
					}

					if (parameters == null) parameters = new Map<String, String>();
					parameters.set(argument.substr(0, equals), argValue);
				}
			}
		}

		if (parameters != null)
		{
			if (attributes.parameters == null) attributes.parameters = {};
			if (attributes.context == null) attributes.context = {};

			for (parameter in parameters.keys())
			{
				argValue = parameters.get(parameter);

				if (#if lime_disable_window_override false && #end StringTools.startsWith(parameter, windowParamPrefix))
				{
					switch (parameter.substr(windowParamPrefix.length))
					{
						case "allow-high-dpi":
							attributes.allowHighDPI = __parseBool(argValue);
						case "always-on-top":
							attributes.alwaysOnTop = __parseBool(argValue);
						case "antialiasing":
							attributes.context.antialiasing = Std.parseInt(argValue);
						case "background":
							attributes.context.background = (argValue == "" || argValue == "null") ? null : Std.parseInt(argValue);
						case "borderless":
							attributes.borderless = __parseBool(argValue);
						case "colorDepth":
							attributes.context.colorDepth = Std.parseInt(argValue);
						case "depth", "depth-buffer":
							attributes.context.depth = __parseBool(argValue);
						// case "display": windowConfig.display = Std.parseInt (argValue);
						case "fullscreen":
							attributes.fullscreen = __parseBool(argValue);
						case "hardware":
							attributes.context.hardware = __parseBool(argValue);
						case "height":
							attributes.height = Std.parseInt(argValue);
						case "hidden":
							attributes.hidden = __parseBool(argValue);
						case "maximized":
							attributes.maximized = __parseBool(argValue);
						case "minimized":
							attributes.minimized = __parseBool(argValue);
						case "render-type", "renderer":
							attributes.context.type = argValue;
						case "render-version", "renderer-version":
							attributes.context.version = argValue;
						case "resizable":
							attributes.resizable = __parseBool(argValue);
						case "stencil", "stencil-buffer":
							attributes.context.stencil = __parseBool(argValue);
						// case "title": windowConfig.title = argValue;
						case "vsync":
							attributes.context.vsync = __parseBool(argValue);
						case "width":
							attributes.width = Std.parseInt(argValue);
						case "x":
							attributes.x = Std.parseInt(argValue);
						case "y":
							attributes.y = Std.parseInt(argValue);
						default:
					}
				}
				else if (!Reflect.hasField(attributes.parameters, parameter))
				{
					Reflect.setField(attributes.parameters, parameter, argValue);
				}
			}
		}
	}
	#end

	@:noCompletion private static inline function __parseBool(value:String):Bool
	{
		return (value == "true");
	}

	@:noCompletion private static function __registerEntryPoint(projectName:String, entryPoint:Function):Void
	{
		if (__applicationEntryPoint == null)
		{
			__applicationEntryPoint = new Map();
		}

		__applicationEntryPoint[projectName] = entryPoint;
	}

	@:noCompletion private static function __runProcess(command:String, args:Array<String> = null):String
	{
		#if sys
		try
		{
			if (args == null) args = [];

			var process = new Process(command, args);
			var value = StringTools.trim(process.stdout.readLine().toString());
			process.close();
			return value;
		}
		catch (e:Dynamic) {}
		#end
		return null;
	}

	// Get & Set Methods
	private static function get_allowScreenTimeout():Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_system_get_allow_screen_timeout();
		#else
		return true;
		#end
	}

	private static function set_allowScreenTimeout(value:Bool):Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_system_set_allow_screen_timeout(value);
		#else
		return true;
		#end
	}

	private static function get_applicationDirectory():String
	{
		if (__applicationDirectory == null)
		{
			__applicationDirectory = __getDirectory(APPLICATION);
		}

		return __applicationDirectory;
	}

	private static function get_applicationStorageDirectory():String
	{
		if (__applicationStorageDirectory == null)
		{
			__applicationStorageDirectory = __getDirectory(APPLICATION_STORAGE);
		}

		return __applicationStorageDirectory;
	}

	private static function get_deviceModel():String
	{
		if (__deviceModel == null)
		{
			#if (lime_cffi && !macro && (windows || ios || tvos))
			__deviceModel = CFFI.stringValue(NativeCFFI.lime_system_get_device_model());
			#elseif android
			var manufacturer:String = JNI.createStaticField("android/os/Build", "MANUFACTURER", "Ljava/lang/String;").get();
			var model:String = JNI.createStaticField("android/os/Build", "MODEL", "Ljava/lang/String;").get();
			if (manufacturer != null && model != null)
			{
				if (StringTools.startsWith(model.toLowerCase(), manufacturer.toLowerCase()))
				{
					model = StringTools.trim(model.substr(manufacturer.length));
					while (StringTools.startsWith(model, "-"))
					{
						model = StringTools.trim(model.substr(1));
					}
				}
				__deviceModel = model;
			}
			#elseif mac
			__deviceModel = __runProcess("sysctl", ["-n", "hw.model"]);
			#elseif linux
			__deviceModel = __runProcess("cat", ["/sys/devices/virtual/dmi/id/sys_vendor"]);
			#end
		}

		return __deviceModel;
	}

	private static function get_deviceVendor():String
	{
		if (__deviceVendor == null)
		{
			#if (lime_cffi && !macro && windows && !html5)
			__deviceVendor = CFFI.stringValue(NativeCFFI.lime_system_get_device_vendor());
			#elseif android
			var vendor:String = JNI.createStaticField("android/os/Build", "MANUFACTURER", "Ljava/lang/String;").get();
			if (vendor != null)
			{
				__deviceVendor = vendor.charAt(0).toUpperCase() + vendor.substr(1);
			}
			#elseif (ios || mac || tvos)
			__deviceVendor = "Apple";
			#elseif linux
			__deviceVendor = __runProcess("cat", ["/sys/devices/virtual/dmi/id/product_name"]);
			#end
		}

		return __deviceVendor;
	}

	private static function get_desktopDirectory():String
	{
		if (__desktopDirectory == null)
		{
			__desktopDirectory = __getDirectory(DESKTOP);
		}

		return __desktopDirectory;
	}

	private static function get_documentsDirectory():String
	{
		if (__documentsDirectory == null)
		{
			__documentsDirectory = __getDirectory(DOCUMENTS);
		}

		return __documentsDirectory;
	}

	private static function get_endianness():Endian
	{
		if (__endianness == null)
		{
			#if (ps3 || wiiu || flash)
			__endianness = BIG_ENDIAN;
			#else
			var arrayBuffer = new ArrayBuffer(2);
			var uint8Array = new UInt8Array(arrayBuffer);
			var uint16array = new UInt16Array(arrayBuffer);
			uint8Array[0] = 0xAA;
			uint8Array[1] = 0xBB;
			if (uint16array[0] == 0xAABB) __endianness = BIG_ENDIAN;
			else
				__endianness = LITTLE_ENDIAN;
			#end
		}

		return __endianness;
	}

	private static function get_fontsDirectory():String
	{
		if (__fontsDirectory == null)
		{
			__fontsDirectory = __getDirectory(FONTS);
		}

		return __fontsDirectory;
	}

	private static function get_numDisplays():Int
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_system_get_num_displays();
		#else
		return 1;
		#end
	}

	private static function get_platformLabel():String
	{
		if (__platformLabel == null)
		{
			#if (lime_cffi && !macro && windows && !html5)
			var label:String = CFFI.stringValue(NativeCFFI.lime_system_get_platform_label());
			if (label != null) __platformLabel = StringTools.trim(label);
			#elseif linux
			__platformLabel = __runProcess("lsb_release", ["-ds"]);
			#else
			var name = System.platformName;
			var version = System.platformVersion;
			if (name != null && version != null) __platformLabel = name + " " + version;
			else if (name != null) __platformLabel = name;
			#end
		}

		return __platformLabel;
	}

	private static function get_platformName():String
	{
		if (__platformName == null)
		{
			#if windows
			__platformName = "Windows";
			#elseif mac
			__platformName = "macOS";
			#elseif linux
			__platformName = __runProcess("lsb_release", ["-is"]);
			#elseif ios
			__platformName = "iOS";
			#elseif android
			__platformName = "Android";
			#elseif air
			__platformName = "AIR";
			#elseif flash
			__platformName = "Flash Player";
			#elseif tvos
			__platformName = "tvOS";
			#elseif tizen
			__platformName = "Tizen";
			#elseif blackberry
			__platformName = "BlackBerry";
			#elseif firefox
			__platformName = "Firefox";
			#elseif webos
			__platformName = "webOS";
			#elseif nodejs
			__platformName = "Node.js";
			#elseif js
			__platformName = "HTML5";
			#end
		}

		return __platformName;
	}

	private static function get_platformVersion():String
	{
		if (__platformVersion == null)
		{
			#if (lime_cffi && !macro && windows && !html5)
			__platformVersion = CFFI.stringValue(NativeCFFI.lime_system_get_platform_version());
			#elseif android
			var release = JNI.createStaticField("android/os/Build$VERSION", "RELEASE", "Ljava/lang/String;").get();
			var api = JNI.createStaticField("android/os/Build$VERSION", "SDK_INT", "I").get();
			if (release != null && api != null) __platformVersion = release + " (API " + api + ")";
			#elseif (lime_cffi && !macro && (ios || tvos))
			__platformVersion = NativeCFFI.lime_system_get_platform_version();
			#elseif mac
			__platformVersion = __runProcess("sw_vers", ["-productVersion"]);
			#elseif linux
			__platformVersion = __runProcess("lsb_release", ["-rs"]);
			#elseif flash
			__platformVersion = Capabilities.version;
			#end
		}

		return __platformVersion;
	}

	private static function get_userDirectory():String
	{
		if (__userDirectory == null)
		{
			__userDirectory = __getDirectory(USER);
		}

		return __userDirectory;
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract SystemDirectory(Int) from Int to Int from UInt to UInt
{
	var APPLICATION = 0;
	var APPLICATION_STORAGE = 1;
	var DESKTOP = 2;
	var DOCUMENTS = 3;
	var FONTS = 4;
	var USER = 5;
}
