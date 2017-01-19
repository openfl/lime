package lime.project;


import haxe.io.Path;
import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import lime.tools.helpers.ArrayHelper;
import lime.tools.helpers.CompatibilityHelper;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.ObjectHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.StringHelper;
import lime.tools.helpers.StringMapHelper;
import lime.project.AssetType;
import sys.FileSystem;
import sys.io.File;

#if (lime && !lime_legacy)
import haxe.xml.Fast;
import haxe.ds.ArraySort;
import lime.text.Font;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.ProcessHelper;
import sys.io.Process;
@:access(lime.text.Font)
#end


class HXProject {
	
	
	public var app:ApplicationData;
	public var architectures:Array <Architecture>;
	public var assets:Array <Asset>;
	public var certificate:Keystore;
	public var command:String;
	public var config:ConfigData;
	public var debug:Bool;
	public var defines:Map <String, Dynamic>;
	public var dependencies:Array <Dependency>;
	public var environment:Map <String, String>;
	public var haxedefs:Map <String, Dynamic>;
	public var haxeflags:Array <String>;
	public var haxelibs:Array <Haxelib>;
	public var host (get_host, null):Platform;
	public var icons:Array <Icon>;
	public var javaPaths:Array <String>;
	public var libraries:Array <Library>;
	public var libraryHandlers:Map <String, String>;
	public var meta:MetaData;
	public var ndlls:Array <NDLL>;
	public var platformType:PlatformType;
	public var samplePaths:Array <String>;
	public var sources:Array <String>;
	public var splashScreens:Array <SplashScreen>;
	public var target:Platform;
	public var targetFlags:Map <String, String>;
	public var targetHandlers:Map <String, String>;
	public var templateContext (get_templateContext, null):Dynamic;
	public var templatePaths:Array <String>;
	@:isVar public var window (get, set):WindowData;
	public var windows:Array <WindowData>;
	
	private var defaultApp:ApplicationData;
	private var defaultMeta:MetaData;
	private var defaultWindow:WindowData;
	
	public static var _command:String;
	public static var _debug:Bool;
	public static var _target:Platform;
	public static var _targetFlags:Map <String, String>;
	public static var _templatePaths:Array <String>;
	
	private static var initialized:Bool;
	
	
	public static function main () {
		
		var args = Sys.args ();
		
		if (args.length < 7) {
			
			return;
			
		}
		
		HXProject._command = args[0];
		HXProject._target = cast args[2];
		HXProject._debug = (args[3] == "true");
		HXProject._targetFlags = Unserializer.run (args[4]);
		HXProject._templatePaths = Unserializer.run (args[5]);
		
		initialize ();
		
		var classRef = Type.resolveClass (args[1]);
		var instance = Type.createInstance (classRef, []);
		
		var serializer = new Serializer ();
		serializer.useCache = true;
		serializer.serialize (instance);
		
		File.saveContent (args[6], serializer.toString ());
		
	}
	
	
	public function new () {
		
		initialize ();
		
		command = _command;
		config = new ConfigData ();
		debug = _debug;
		target = _target;
		targetFlags = StringMapHelper.copy (_targetFlags);
		templatePaths = _templatePaths.copy ();
		
		defaultMeta = { title: "MyApplication", description: "", packageName: "com.example.myapp", version: "1.0.0", company: "Example, Inc.", companyUrl: "", buildNumber: "1", companyId: "" }
		defaultApp = { main: "Main", file: "MyApplication", path: "bin", preloader: "", swfVersion: 11.2, url: "", init: null }
		defaultWindow = { width: 800, height: 600, parameters: "{}", background: 0xFFFFFF, fps: 30, hardware: true, display: 0, resizable: true, borderless: false, orientation: Orientation.AUTO, vsync: false, fullscreen: false, antialiasing: 0, allowShaders: true, requireShaders: false, depthBuffer: false, stencilBuffer: false }
		
		platformType = PlatformType.DESKTOP;
		architectures = [];
		
		switch (target) {
			
			case FLASH:
				
				platformType = PlatformType.WEB;
				architectures = [];
				
			case HTML5, FIREFOX, EMSCRIPTEN:
				
				platformType = PlatformType.WEB;
				architectures = [];
				
				defaultWindow.width = 0;
				defaultWindow.height = 0;
				defaultWindow.fps = 60;
				
			case ANDROID, BLACKBERRY, IOS, TIZEN, WEBOS, TVOS:
				
				platformType = PlatformType.MOBILE;
				
				if (target == Platform.IOS) {
					
					architectures = [ Architecture.ARMV7, Architecture.ARM64 ];
					
				} else if (target == Platform.ANDROID) {
					
					if (targetFlags.exists ("simulator") || targetFlags.exists ("emulator")) {
						
						architectures = [ Architecture.X86 ];
						
					} else {
						
						architectures = [ Architecture.ARMV7 ];
						
					}
					
				} else if (target == Platform.TVOS) {
					
					architectures = [ Architecture.ARM64 ];
					
				} else {
					
					architectures = [ Architecture.ARMV6 ];
					
				}
				
				defaultWindow.width = 0;
				defaultWindow.height = 0;
				defaultWindow.fullscreen = true;
				defaultWindow.requireShaders = true;
				
			case WINDOWS, MAC, LINUX:
				
				platformType = PlatformType.DESKTOP;
				
				if (target == Platform.LINUX || target == Platform.MAC) {
					
					architectures = [ PlatformHelper.hostArchitecture ];
					
				} else {
					
					architectures = [ Architecture.X86 ];
					
				}
			
			default:
				
				// TODO: Better handle platform type for pluggable targets
				
				platformType = PlatformType.CONSOLE;
			
		}
		
		meta = ObjectHelper.copyFields (defaultMeta, {});
		app = ObjectHelper.copyFields (defaultApp, {});
		window = ObjectHelper.copyFields (defaultWindow, {});
		windows = [ window ];
		assets = new Array <Asset> ();
		defines = new Map <String, Dynamic> ();
		dependencies = new Array <Dependency> ();
		environment = Sys.environment ();
		haxedefs = new Map <String, Dynamic> ();
		haxeflags = new Array <String> ();
		haxelibs = new Array <Haxelib> ();
		icons = new Array <Icon> ();
		javaPaths = new Array <String> ();
		libraries = new Array <Library> ();
		libraryHandlers = new Map <String, String> ();
		ndlls = new Array <NDLL> ();
		sources = new Array <String> ();
		samplePaths = new Array <String> ();
		splashScreens = new Array <SplashScreen> ();
		targetHandlers = new Map <String, String> ();
		
	}
	
	
	public function clone ():HXProject {
		
		var project = new HXProject ();
		
		ObjectHelper.copyFields (app, project.app);
		project.architectures = architectures.copy ();
		project.assets = assets.copy ();
		
		for (i in 0...assets.length) {
			
			project.assets[i] = assets[i].clone ();
			
		}
		
		if (certificate != null) {
			
			project.certificate = certificate.clone ();
			
		}
		
		project.command = command;
		project.config = config.clone ();
		project.debug = debug;
		
		for (key in defines.keys ()) {
			
			project.defines.set (key, defines.get (key));
			
		}
		
		for (dependency in dependencies) {
			
			project.dependencies.push (dependency.clone ());
			
		}
		
		for (key in environment.keys ()) {
			
			project.environment.set (key, environment.get (key));
			
		}
		
		for (key in haxedefs.keys ()) {
			
			project.haxedefs.set (key, haxedefs.get (key));
			
		}
		
		project.haxeflags = haxeflags.copy ();
		
		for (haxelib in haxelibs) {
			
			project.haxelibs.push (haxelib.clone ());
			
		}
		
		for (icon in icons) {
			
			project.icons.push (icon.clone ());
			
		}
		
		project.javaPaths = javaPaths.copy ();
		
		for (library in libraries) {
			
			project.libraries.push (library.clone ());
			
		}
		
		for (key in libraryHandlers.keys ()) {
			
			project.libraryHandlers.set (key, libraryHandlers.get (key));
			
		}
		
		ObjectHelper.copyFields (meta, project.meta);
		
		for (ndll in ndlls) {
			
			project.ndlls.push (ndll.clone ());
			
		}
		
		project.platformType = platformType;
		project.samplePaths = samplePaths.copy ();
		project.sources = sources.copy ();
		
		for (splashScreen in splashScreens) {
			
			project.splashScreens.push (splashScreen.clone ());
			
		}
		
		project.target = target;
		
		for (key in targetFlags.keys ()) {
			
			project.targetFlags.set (key, targetFlags.get (key));
			
		}
		
		for (key in targetHandlers.keys ()) {
			
			project.targetHandlers.set (key, targetHandlers.get (key));
			
		}
		
		project.templatePaths = templatePaths.copy ();
		
		for (i in 0...windows.length) {
			
			project.windows[i] = (ObjectHelper.copyFields (windows[i], {}));
			
		}
		
		return project;
		
	}
	
	
	private function filter (text:String, include:Array <String> = null, exclude:Array <String> = null):Bool {
		
		if (include == null) {
			
			include = [ "*" ];
			
		}
		
		if (exclude == null) {
			
			exclude = [];
			
		}
		
		for (filter in exclude) {
			
			if (filter != "") {
				
				filter = StringTools.replace (filter, ".", "\\.");
				filter = StringTools.replace (filter, "*", ".*");
				
				var regexp = new EReg ("^" + filter, "i");
				
				if (regexp.match (text)) {
					
					return false;
					
				}
				
			}
			
		}
		
		for (filter in include) {
			
			if (filter != "") {
				
				filter = StringTools.replace (filter, ".", "\\.");
				filter = StringTools.replace (filter, "*", ".*");
				
				var regexp = new EReg ("^" + filter, "i");
				
				if (regexp.match (text)) {
					
					return true;
					
				}
				
			}
			
		}
		
		return false;
		
	}
	
	
	#if (lime && !lime_legacy)
	
	public static function fromFile (projectFile:String, userDefines:Map <String, Dynamic> = null, includePaths:Array <String> = null):HXProject {
		
		var project:HXProject = null;
		
		var path = FileSystem.fullPath (Path.withoutDirectory (projectFile));
		var name = Path.withoutDirectory (Path.withoutExtension (projectFile));
		name = name.substr (0, 1).toUpperCase () + name.substr (1);
		
		var tempDirectory = PathHelper.getTemporaryDirectory ();
		var classFile = PathHelper.combine (tempDirectory, name + ".hx");
		var nekoOutput = PathHelper.combine (tempDirectory, name + ".n");
		var temporaryFile = PathHelper.combine (tempDirectory, "output.dat");
		
		FileHelper.copyFile (path, classFile);
		
		ProcessHelper.runCommand ("", "haxe", [ name, "-main", "lime.project.HXProject", "-cp", tempDirectory, "-neko", nekoOutput, "-cp", PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "tools"), "-lib", "lime", "-D", "lime_curl" ]);
		ProcessHelper.runCommand ("", "neko", [ FileSystem.fullPath (nekoOutput), HXProject._command, name, Std.string (HXProject._target), Std.string (HXProject._debug), Serializer.run (HXProject._targetFlags), Serializer.run (HXProject._templatePaths), temporaryFile ]);
		
		try {
			
			var outputPath = PathHelper.combine (tempDirectory, "output.dat");
		
			if (FileSystem.exists (outputPath)) {
				
				var output = File.getContent (outputPath);
				var unserializer = new Unserializer (output);
				unserializer.setResolver (cast { resolveEnum: Type.resolveEnum, resolveClass: resolveClass });
				project = unserializer.unserialize ();
				
			}
			
		} catch (e:Dynamic) {}
		
		PathHelper.removeDirectory (tempDirectory);
		
		if (project != null) {
			
			var defines = StringMapHelper.copy (userDefines);
			StringMapHelper.copyKeys (project.defines, defines);
			
			processHaxelibs (project, defines);
			
		}
		
		return project;
		
	}
	
	
	public static function fromHaxelib (haxelib:Haxelib, userDefines:Map <String, Dynamic> = null, clearCache:Bool = false):HXProject {
		
		if (haxelib.name == null || haxelib.name == "") {
			
			return null;
			
		}
		
		var path = PathHelper.getHaxelib (haxelib, false, clearCache);
		
		if (path == null || path == "") {
			
			return null;
			
		}
		
		return HXProject.fromPath (path, userDefines);
		
	}
	
	
	public static function fromPath (path:String, userDefines:Map <String, Dynamic> = null):HXProject {
		
		if (!FileSystem.exists (path) || !FileSystem.isDirectory (path)) {
			
			return null;
			
		}
		
		var files = [ "include.lime", "include.nmml", "include.xml" ];
		var projectFile = null;
		
		for (file in files) {
			
			if (projectFile == null && FileSystem.exists (PathHelper.combine (path, file))) {
				
				projectFile = PathHelper.combine (path, file);
				
			}
			
		}
		
		if (projectFile != null) {
			
			var project = new ProjectXMLParser (projectFile, userDefines);
			
			if (project.config.get ("project.rebuild.path") == null) {
				
				project.config.set ("project.rebuild.path", PathHelper.combine (path, "project"));
				
			}
			
			return project;
			
		}
		
		return null;
		
	}
	
	#end
	
	
	private function getHaxelibVersion (haxelib:Haxelib):String {
		
		var version = haxelib.version;
		
		if (version == "" || version == null) {
			
			var haxelibPath = PathHelper.getHaxelib (haxelib);
			var jsonPath = PathHelper.combine (haxelibPath, "haxelib.json");
			
			try {
				
				if (FileSystem.exists (jsonPath)) {
					
					var json = Json.parse (File.getContent (jsonPath));
					version = json.version;
					
				}
				
			} catch (e:Dynamic) {}
			
		}
		
		return version;
		
	}
	
	
	public function include (path:String):Void {
		
		// extend project file somehow?
		
	}
	
	
	public function includeAssets (path:String, rename:String = null, include:Array <String> = null, exclude:Array <String> = null):Void {
		
		if (include == null) {
			
			include = [ "*" ];
			
		}
		
		if (exclude == null) {
			
			exclude = [];
			
		}
		
		exclude = exclude.concat ([ ".*", "cvs", "thumbs.db", "desktop.ini", "*.hash" ]);
			
		if (path == "") {
			
			return;
			
		}
		
		var targetPath = "";
		
		if (rename != null) {
			
			targetPath = rename;
			
		} else {
			
			targetPath = path;
			
		}
		
		if (!FileSystem.exists (path)) {
			
			LogHelper.error ("Could not find asset path \"" + path + "\"");
			return;
			
		}
		
		var files = FileSystem.readDirectory (path);
		
		if (targetPath != "") {
			
			targetPath += "/";
			
		}
		
		for (file in files) {
			
			if (FileSystem.isDirectory (path + "/" + file)) {
				
				if (filter (file, [ "*" ], exclude)) {
					
					includeAssets (path + "/" + file, targetPath + file, include, exclude);
					
				}
				
			} else {
				
				if (filter (file, include, exclude)) {
					
					assets.push (new Asset (path + "/" + file, targetPath + file));
					
				}
				
			}
			
		}
		
	}
	
	
	#if (lime && !lime_legacy)
	
	public function includeXML (xml:String):Void {
		
		var projectXML = new ProjectXMLParser ();
		@:privateAccess projectXML.parseXML (new Fast (Xml.parse (xml).firstElement ()), "");
		merge (projectXML);
		
	}
	
	#end
	
	
	private static function initialize ():Void {
		
		if (!initialized) {
			
			if (_target == null) {
				
				_target = PlatformHelper.hostPlatform;
				
			}
			
			if (_targetFlags == null) {
				
				_targetFlags = new Map <String, String> ();
				
			}
			
			if (_templatePaths == null) {
				
				_templatePaths = new Array <String> ();
				
			}
			
			initialized = true;
			
		}
		
	}
	
	
	public function merge (project:HXProject):Void {
		
		if (project != null) {
			
			ObjectHelper.copyUniqueFields (project.meta, meta, project.defaultMeta);
			ObjectHelper.copyUniqueFields (project.app, app, project.defaultApp);
			
			for (i in 0...project.windows.length) {
				
				if (i < windows.length) {
					
					ObjectHelper.copyUniqueFields (project.windows[i], windows[i], project.defaultWindow);
					
				} else {
					
					windows.push (ObjectHelper.copyFields (project.windows[i], {}));
					
				}
				
			}
			
			StringMapHelper.copyUniqueKeys (project.defines, defines);
			StringMapHelper.copyUniqueKeys (project.environment, environment);
			StringMapHelper.copyUniqueKeys (project.haxedefs, haxedefs);
			StringMapHelper.copyUniqueKeys (project.libraryHandlers, libraryHandlers);
			StringMapHelper.copyUniqueKeys (project.targetHandlers, targetHandlers);
			
			if (certificate == null) {
				
				certificate = project.certificate;
				
			} else {
				
				certificate.merge (project.certificate);
				
			}
			
			config.merge (project.config);
			
			assets = ArrayHelper.concatUnique (assets, project.assets);
			dependencies = ArrayHelper.concatUnique (dependencies, project.dependencies, true);
			haxeflags = ArrayHelper.concatUnique (haxeflags, project.haxeflags);
			haxelibs = ArrayHelper.concatUnique (haxelibs, project.haxelibs, true, "name");
			icons = ArrayHelper.concatUnique (icons, project.icons);
			javaPaths = ArrayHelper.concatUnique (javaPaths, project.javaPaths, true);
			libraries = ArrayHelper.concatUnique (libraries, project.libraries, true);
			ndlls = ArrayHelper.concatUnique (ndlls, project.ndlls);
			samplePaths = ArrayHelper.concatUnique (samplePaths, project.samplePaths, true);
			sources = ArrayHelper.concatUnique (sources, project.sources, true);
			splashScreens = ArrayHelper.concatUnique (splashScreens, project.splashScreens);
			templatePaths = ArrayHelper.concatUnique (templatePaths, project.templatePaths, true);
			
		}
		
	}
	
	
	public function path (value:String):Void {
		
		if (host == Platform.WINDOWS) {
			
			setenv ("PATH", value + ";" + Sys.getEnv ("PATH"));
			
		} else {
			
			setenv ("PATH", value + ":" + Sys.getEnv ("PATH"));
			
		}
		
	}
	
	
	#if (lime && !lime_legacy)
	
	@:noCompletion private static function processHaxelibs (project:HXProject, userDefines:Map <String, Dynamic>):Void {
		
		var haxelibs = project.haxelibs.copy ();
		project.haxelibs = [];
		
		for (haxelib in haxelibs) {
			
			project.haxelibs.push (haxelib);
			
			var includeProject = HXProject.fromHaxelib (haxelib, userDefines);
			
			if (includeProject != null) {
				
				for (ndll in includeProject.ndlls) {
					
					if (ndll.haxelib == null) {
						
						ndll.haxelib = haxelib;
						
					}
					
				}
				
				project.merge (includeProject);
				
			}
			
		}
		
	}
	
	
	@:noCompletion private static function resolveClass (name:String):Class <Dynamic> {
		
		var type = Type.resolveClass (name);
		
		if (type == null) {
			
			return HXProject;
			
		} else {
			
			return type;
			
		}
		
	}
	
	#end
	
	
	public function setenv (name:String, value:String):Void {
		
		Sys.putEnv (name, value);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_host ():Platform {
		
		return PlatformHelper.hostPlatform;
		
	}
	
	
	private function get_templateContext ():Dynamic {
		
		var context:Dynamic = {};
		
		if (app == null) app = { };
		if (meta == null) meta = { };
		
		if (window == null) {
			
			window = { };
			windows = [ window ];
			
		}
		
		ObjectHelper.copyMissingFields (defaultApp, app);
		ObjectHelper.copyMissingFields (defaultMeta, meta);
		
		for (item in windows) {
			
			ObjectHelper.copyMissingFields (defaultWindow, item);
			
		}
		
		//config.populate ();
		
		for (field in Reflect.fields (app)) {
			
			Reflect.setField (context, "APP_" + StringHelper.formatUppercaseVariable (field), Reflect.field (app, field));
			
		}
		
		context.BUILD_DIR = app.path;
		
		for (key in environment.keys ()) { 
			
			Reflect.setField (context, "ENV_" + key, environment.get (key));
			
		}
		
		context.meta = meta;
		
		for (field in Reflect.fields (meta)) {
			
			Reflect.setField (context, "APP_" + StringHelper.formatUppercaseVariable (field), Reflect.field (meta, field));
			Reflect.setField (context, "META_" + StringHelper.formatUppercaseVariable (field), Reflect.field (meta, field));
			
		}
		
		context.APP_PACKAGE = context.META_PACKAGE = meta.packageName;
		
		for (field in Reflect.fields (windows[0])) {
			
			Reflect.setField (context, "WIN_" + StringHelper.formatUppercaseVariable (field), Reflect.field (windows[0], field));
			Reflect.setField (context, "WINDOW_" + StringHelper.formatUppercaseVariable (field), Reflect.field (windows[0], field));
			
		}
		
		if (windows[0].orientation == Orientation.LANDSCAPE || windows[0].orientation == Orientation.PORTRAIT) {
			
			context.WIN_ORIENTATION = Std.string (windows[0].orientation).toLowerCase ();
			context.WINDOW_ORIENTATION = Std.string (windows[0].orientation).toLowerCase ();
			
		} else {
			
			context.WIN_ORIENTATION = "";
			context.WINDOW_ORIENTATION = "";
			
		}
		
		context.windows = windows;
		
		for (i in 0...windows.length) {
			
			for (field in Reflect.fields (windows[i])) {
				
				Reflect.setField (context, "WINDOW_" + StringHelper.formatUppercaseVariable (field) + "_" + i, Reflect.field (windows[i], field));
				
			}
			
			if (windows[i].orientation == Orientation.LANDSCAPE || windows[i].orientation == Orientation.PORTRAIT) {
				
				Reflect.setField (context, "WINDOW_ORIENTATION_" + i, Std.string (windows[i].orientation).toLowerCase ());
				
			} else {
				
				Reflect.setField (context, "WINDOW_ORIENTATION_" + i, "");
				
			}
			
			windows[i].title = meta.title;
			
		}
		
		for (haxeflag in haxeflags) {
			
			if (StringTools.startsWith (haxeflag, "-lib")) {
				
				Reflect.setField (context, "LIB_" + StringHelper.formatUppercaseVariable (haxeflag.substr (5)), "true");
				
			}
			
		}
		
		context.assets = new Array <Dynamic> ();
		var fontAssets = new Array <Dynamic> ();
		for (asset in assets) {
			
			if (asset.type != AssetType.TEMPLATE) {
				
				var embeddedAsset:Dynamic = { };
				ObjectHelper.copyFields (asset, embeddedAsset);
				
				embeddedAsset.sourcePath = PathHelper.standardize (asset.sourcePath);
				
				if (asset.embed == null) {
					
					embeddedAsset.embed = (platformType == PlatformType.WEB);
					
				}
				
				embeddedAsset.type = Std.string (asset.type).toLowerCase ();
				
				#if (lime && !lime_legacy)
				if (asset.type == FONT) {
					try {
						var font = Font.fromFile (asset.sourcePath);
						var assetHolder:Dynamic = {};
						assetHolder.embeddedAsset = embeddedAsset;
						assetHolder.font = font;
						fontAssets.push(assetHolder);
					} catch (e:Dynamic) {}
				}
				#end
				
				context.assets.push (embeddedAsset);
				
			}
			
		}


		#if (lime && !lime_legacy)
		// now sort all gathered font-assets

		ArraySort.sort(fontAssets, function (a:Dynamic, b:Dynamic): Int {
			if (a.font.name < b.font.name) return -1;
			if (a.font.name > b.font.name) return 1;
			return 0;
		});

		// now shorten the font names that are too long if necessary
		var i:Int = 0;
		for (assetHolder in fontAssets) {
		try {
				var maxLength:Int = 21;
				if (assetHolder.font.name.length <= maxLength)
				{
					assetHolder.embeddedAsset.fontName = assetHolder.font.name;	
				}
				else 
				{
					// replace fontname since IE11 can not handle FontFamilies 
					// that are longer than 31 characters!
					// during build process that max-length is getting even shorter (21)
					// prefixing with int-number to have unique name
					// add those fontfamily-names to the  fontaliases of the main class
					assetHolder.embeddedAsset.fontName = (i + '_' + StringTools.replace(assetHolder.font.name, ' ', '')).substr(0, maxLength);
					i++;
				}
				
				
			} catch (e:Dynamic) {}
		}
		
 		#end //(lime && !lime_legacy)



		context.libraries = new Array <Dynamic> ();
		
		for (library in libraries) {
			
			var embeddedLibrary:Dynamic = { };
			ObjectHelper.copyFields (library, embeddedLibrary);
			context.libraries.push (embeddedLibrary);
			
		}
		
		context.ndlls = new Array <Dynamic> ();
		
		for (ndll in ndlls) {
			
			var templateNDLL:Dynamic = { };
			ObjectHelper.copyFields (ndll, templateNDLL);
			templateNDLL.nameSafe = StringTools.replace (ndll.name, "-", "_");
			context.ndlls.push (templateNDLL);
			
		}
		
		//Reflect.setField (context, "ndlls", ndlls);
		//Reflect.setField (context, "sslCaCert", sslCaCert);
		context.sslCaCert = "";
		
		var compilerFlags = [];
		
		for (haxelib in haxelibs) {
			
			var name = haxelib.name;
			
			if (haxelib.version != "") {
				
				name += ":" + haxelib.version;
				
			}
			
			#if (lime && !lime_legacy)
			
			var cache = LogHelper.verbose;
			LogHelper.verbose = false;
			var output = "";
			
			try {
				
				output = ProcessHelper.runProcess ("", "haxelib", [ "path", name ], true, true, true);
				
			} catch (e:Dynamic) { }
			
			LogHelper.verbose = cache;
			
			var split = output.split ("\n");
			var haxelibName = null;
			
			for (arg in split) {
				
				arg = StringTools.trim (arg);
				
				if (arg != "") {
					
					if (!StringTools.startsWith (arg, "-")) {
						
						var path = PathHelper.standardize (arg);
						
						if (path != null && StringTools.trim (path) != "") {
							
							var param = "-cp " + path;
							compilerFlags.remove (param);
							compilerFlags.push (param);
							
						}
						
						var version = "0.0.0";
						var jsonPath = PathHelper.combine (path, "haxelib.json");
						
						try {
							
							if (FileSystem.exists (jsonPath)) {
								
								var json = Json.parse (File.getContent (jsonPath));
								haxelibName = json.name;
								compilerFlags = ArrayHelper.concatUnique (compilerFlags, [ "-D " + haxelibName + "=" + json.version ], true);
								
							}
							
						} catch (e:Dynamic) {}
						
					} else {
						
						if (StringTools.startsWith (arg, "-D ") && arg.indexOf ("=") == -1) {
							
							var name = arg.substr (3);
							
							if (name != haxelibName) {
								
								compilerFlags = ArrayHelper.concatUnique (compilerFlags, [ "-D " + name ], true);
								
							}
							
							/*var haxelib = new Haxelib (arg.substr (3));
							var path = PathHelper.getHaxelib (haxelib);
							var version = getHaxelibVersion (haxelib);
							
							if (path != null) {
								
								CompatibilityHelper.patchProject (this, haxelib, version);
								compilerFlags = ArrayHelper.concatUnique (compilerFlags, [ "-D " + haxelib.name + "=" + version ], true);
								
							}*/
							
						} else if (!StringTools.startsWith (arg, "-L")) {
							
							compilerFlags = ArrayHelper.concatUnique (compilerFlags, [ arg ], true);
							
						}
						
					}
					
				}
				
			}
			
			#else
			
			compilerFlags.push ("-lib " + name);
			
			#end
			
			Reflect.setField (context, "LIB_" + StringHelper.formatUppercaseVariable (haxelib.name), true);
			
			if (name == "nme") {
				
				context.EMBED_ASSETS = false;
				
			}
			
		}
		
		for (source in sources) {
			
			if (source != null && StringTools.trim (source) != "") {
				
				compilerFlags.push ("-cp " + source);
				
			}
			
		}
		
		for (key in defines.keys ()) {
			
			var value = defines.get (key);
			
			if (value == null || value == "") {
				
				Reflect.setField (context, "SET_" + StringHelper.formatUppercaseVariable (key), true);
				
			} else {
				
				Reflect.setField (context, "SET_" + StringHelper.formatUppercaseVariable (key), value);
				
			}
			
		}
		
		for (key in haxedefs.keys ()) {
			
			var value = haxedefs.get (key);
			
			if (value == null || value == "") {
				
				compilerFlags.push ("-D " + key);
				
				Reflect.setField (context, "DEFINE_" + StringHelper.formatUppercaseVariable (key), true);
				
			} else {
				
				compilerFlags.push ("-D " + key + "=" + value);
				
				Reflect.setField (context, "DEFINE_" + StringHelper.formatUppercaseVariable (key), value);
				
			}
			
		}
		
		if (target != Platform.FLASH) {
			
			compilerFlags.push ("-D " + Std.string (target).toLowerCase ());
			
		}
		
		compilerFlags.push ("-D " + Std.string (platformType).toLowerCase ());
		compilerFlags = compilerFlags.concat (haxeflags);
		
		if (compilerFlags.length == 0) {
			
			context.HAXE_FLAGS = "";
			
		} else {
			
			context.HAXE_FLAGS = "\n" + compilerFlags.join ("\n");
			
		}
		
		var main = app.main;
		
		if (main == null) {
			
			main = defaultApp.main;
			
		}
		
		var indexOfPeriod = main.lastIndexOf (".");
		
		context.APP_MAIN_PACKAGE = main.substr (0, indexOfPeriod + 1);
		context.APP_MAIN_CLASS = main.substr (indexOfPeriod + 1);
		
		var type = "release";
		
		if (debug) {
			
			type = "debug";
			
		} else if (targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = Std.string (target).toLowerCase () + "/hxml/" + type + ".hxml";
		
		for (templatePath in templatePaths) {
			
			var path = PathHelper.combine (templatePath, hxml);
			
			if (FileSystem.exists (path)) {
				
				context.HXML_PATH = path;
				
			}
			
		}
		
		context.RELEASE = (type == "release");
		context.DEBUG = debug;
		context.FINAL = (type == "final");
		context.SWF_VERSION = app.swfVersion;
		context.PRELOADER_NAME = app.preloader;
		
		if (certificate != null) {
			
			context.KEY_STORE = PathHelper.tryFullPath (certificate.path);
			
			if (certificate.password != null) {
				
				context.KEY_STORE_PASSWORD = certificate.password;
				
			}
			
			if (certificate.alias != null) {
				
				context.KEY_STORE_ALIAS = certificate.alias;
				
			} else if (certificate.path != null) {
				
				context.KEY_STORE_ALIAS = Path.withoutExtension (Path.withoutDirectory (certificate.path));
				
			}
			
			if (certificate.aliasPassword != null) {
				
				context.KEY_STORE_ALIAS_PASSWORD = certificate.aliasPassword;
				
			} else if (certificate.password != null) {
				
				context.KEY_STORE_ALIAS_PASSWORD = certificate.password;
				
			}
			
			if (certificate.identity != null) {
				
				context.KEY_STORE_IDENTITY = certificate.identity;
				
			}
			
		}
		
		context.config = config;
		
		return context;
		
	}
	
	
	private function get_window ():WindowData {
		
		if (windows != null) {
			
			return windows[0];
			
		} else {
			
			return window;
			
		}
		
	}
	
	
	private function set_window (value:WindowData):WindowData {
		
		if (windows != null) {
			
			return windows[0] = window = value;
			
		} else {
			
			return window = value;
			
		}
		
	}
	

}
