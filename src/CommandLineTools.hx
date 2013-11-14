package;


import flash.text.Font;
import flash.utils.ByteArray;
import flash.utils.CompressionAlgorithm;
import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.io.Path;
import haxe.rtti.Meta;
import helpers.*;
import platforms.*;
import project.*;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;
import utils.CreateTemplate;
import utils.JavaExternGenerator;
import utils.PlatformSetup;
	
	
class CommandLineTools {
	
	
	private var additionalArguments:Array <String>;
	private var command:String;
	private var debug:Bool;
	private var includePaths:Array <String>;
	private var overrides:HXProject;
	private var project:HXProject;
	private var projectDefines:Map <String, String>;
	private var targetFlags:Map <String, String>;
	private var traceEnabled:Bool;
	private var userDefines:Map <String, Dynamic>;
	private var version:String;
	private var words:Array <String>;
	
	
	public function new () {
		
		additionalArguments = new Array <String> ();
		command = "";
		debug = false;
		includePaths = new Array <String> ();
		projectDefines = new Map <String, String> ();
		targetFlags = new Map <String, String> ();
		traceEnabled = true;
		userDefines = new Map <String, Dynamic> ();
		words = new Array <String> ();
		
		overrides = new HXProject ();
		overrides.architectures = [];
		
		processArguments ();
		version = getVersion ();
		
		if (LogHelper.verbose && command != "") {
			
			displayInfo ();
			Sys.println ("");
			
		}
		
		switch (command) {
			
			case "":
				
				displayInfo (true);
			
			case "help":
				
				displayHelp ();
			
			case "setup":
				
				platformSetup ();
			
			case "document":
				
				document ();
			
			case "generate":
				
				generate ();
			
			case "compress":
				
				compress ();
			
			case "create":
				
				createTemplate ();
			
			case "clean", "update", "display", "build", "run", "rerun", "install", "uninstall", "trace", "test":
				
				if (words.length < 1 || words.length > 2) {
					
					LogHelper.error ("Incorrect number of arguments for command '" + command + "'");
					return;
					
				}
				
				buildProject ();
			
			case "installer", "copy-if-newer":
				
				// deprecated?
			
			default:
				
				LogHelper.error ("'" + command + "' is not a valid command");
			
		}
		
	}
	
	
	private function buildProject () {
		
		var project = initializeProject ();
		var platform:IPlatformTool = null;
		
		LogHelper.info ("", "Using target platform: " + project.target);
		
		switch (project.target) {
			
			case ANDROID:
				
				platform = new AndroidPlatform ();
				
			case BLACKBERRY:
				
				platform = new BlackBerryPlatform ();
			
			case IOS:
				
				platform = new IOSPlatform ();
			
			case TIZEN:
				
				platform = new TizenPlatform ();
			
			case WEBOS:
				
				platform = new WebOSPlatform ();
			
			case WINDOWS:
				
				platform = new WindowsPlatform ();
			
			case MAC:
				
				platform = new MacPlatform ();
			
			case LINUX:
				
				platform = new LinuxPlatform ();
			
			case FLASH:
				
				platform = new FlashPlatform ();
			
			case HTML5:
				
				platform = new HTML5Platform ();
			
			case EMSCRIPTEN:
				
				platform = new EmscriptenPlatform ();
			
		}
		
		var metaFields = Meta.getFields (Type.getClass (platform));
		
		if (platform != null) {
			
			var command = project.command.toLowerCase ();
			
			if (!Reflect.hasField (metaFields.display, "ignore") && (command == "display")) {
				
				platform.display (project);
				
			}
			
			if (!Reflect.hasField (metaFields.clean, "ignore") && (command == "clean" || targetFlags.exists ("clean"))) {
				
				LogHelper.info ("", "\nRunning command: CLEAN");
				platform.clean (project);
				
			}
			
			if (!Reflect.hasField (metaFields.update, "ignore") && (command == "update" || command == "build" || command == "test")) {
				
				LogHelper.info ("", "\nRunning command: UPDATE");
				AssetHelper.processLibraries (project);
				platform.update (project);
				
			}
			
			if (!Reflect.hasField (metaFields.build, "ignore") && (command == "build" || command == "test")) {
				
				LogHelper.info ("", "\nRunning command: BUILD");
				platform.build (project);
				
			}
			
			if (!Reflect.hasField (metaFields.install, "ignore") && (command == "install" || command == "run" || command == "test")) {
				
				LogHelper.info ("", "\nRunning command: INSTALL");
				platform.install (project);
				
			}
		
			if (!Reflect.hasField (metaFields.run, "ignore") && (command == "run" || command == "rerun" || command == "test")) {
				
				LogHelper.info ("", "\nRunning command: RUN");
				platform.run (project, additionalArguments);
				
			}
		
			if (!Reflect.hasField (metaFields.trace, "ignore") && (command == "test" || command == "trace")) {
				
				if (traceEnabled || command == "trace") {
					
					LogHelper.info ("", "\nRunning command: TRACE");
					platform.trace (project);
					
				}
				
			}
			
		}
		
	}
	
	
	private function compress () { 
		
		if (words.length > 0) {
			
			//var bytes = new ByteArray ();
			//bytes.writeUTFBytes (words[0]);
			//bytes.compress (CompressionAlgorithm.LZMA);
			//Sys.print (bytes.toString ());
			//File.saveBytes (words[0] + ".compress", bytes);
			
		}
		
	}
	
	
	private function createTemplate () {
		
		LogHelper.info ("", "Running command: CREATE");
		
		if (words.length > 0) {
			
			if (words[0] == "project") {
				
				CreateTemplate.createProject (words, userDefines);
				
			} else if (words[0] == "extension") {
				
				CreateTemplate.createExtension (words, userDefines);
				
			} else {
				
				CreateTemplate.createSample (words, userDefines);
				
			}
			
		} else {
			
			CreateTemplate.listSamples (userDefines);
			
		}
		
	}
	
	
	private function document ():Void {
	
	
	}
	
	
	private function displayHelp ():Void {
		
		displayInfo ();
		
		var alias = "openfl";
		var name = "OpenFL";
		
		if (userDefines.exists ("nme")) {
			
			alias = "nme";
			name = "NME";
			
		}
		
		Sys.println ("");
		Sys.println (" Usage: " + alias + " setup (target)");
		Sys.println (" Usage: " + alias + " help");
		Sys.println (" Usage: " + alias + " [clean|update|build|run|test|display] <project> (target) [options]");
		Sys.println (" Usage: " + alias + " create project <package> [options]");
		Sys.println (" Usage: " + alias + " create extension <name>");
		Sys.println (" Usage: " + alias + " create <sample>");
		Sys.println (" Usage: " + alias + " rebuild <extension> (targets)");
		//Sys.println (" Usage : nme document <project> (target)");
		//Sys.println (" Usage : nme generate <args> [options]");
		//Sys.println (" Usage : nme new file.nmml name1=value1 name2=value2 ...");
		Sys.println ("");
		Sys.println (" Commands: ");
		Sys.println ("");
		Sys.println ("  setup -- Setup " + name + " or a specific target");
		Sys.println ("  help -- Show this information");
		Sys.println ("  clean -- Remove the target build directory if it exists");
		Sys.println ("  update -- Copy assets for the specified project/target");
		Sys.println ("  build -- Compile and package for the specified project/target");
		Sys.println ("  run -- Install and run for the specified project/target");
		Sys.println ("  test -- Update, build and run in one command");
		Sys.println ("  display -- Display information for the specified project/target");
		Sys.println ("  create -- Create a new project or extension using templates");
		Sys.println ("  rebuild -- Recompile native binaries for extensions");
		//Sys.println ("  document : Generate documentation using haxedoc");
		//Sys.println ("  generate : Tools to help create source code automatically");
		Sys.println ("");
		Sys.println (" Targets: ");
		Sys.println ("");
		Sys.println ("  android -- Create an Android application");
		Sys.println ("  blackberry -- Create a BlackBerry application");
		//Sys.println ("  emscripten : Create Emscripten applications");
		//Sys.println ("  cpp : Create application for the system you are compiling on");
		
		if (!userDefines.exists ("nme")) {
			
			Sys.println ("  flash -- Create a Flash SWF application");
			Sys.println ("  html5 -- Create an HTML5 canvas application");
			
		}
		
		Sys.println ("  ios -- Create an iOS application");
		Sys.println ("  linux -- Create a Linux application");
		Sys.println ("  mac -- Create a Mac OS X application");
		Sys.println ("  tizen -- Create a Tizen application");
		//Sys.println ("  webos : Create HP webOS applications");
		Sys.println ("  windows -- Create a Windows application");
		Sys.println ("");
		Sys.println (" Options: ");
		Sys.println ("");
		Sys.println ("  -D[value] -- Specify a define to use when processing other commands");
		Sys.println ("  -debug -- Use debug configuration instead of release");
		Sys.println ("  -verbose -- Print additional information (when available)");
		Sys.println ("  -clean -- Add a \"clean\" action before running the current command");
		Sys.println ("  -xml -- Generate XML type information, useful for documentation");
		Sys.println ("  (windows|mac|linux) -neko -- Build with Neko instead of C++");
		Sys.println ("  (mac|linux) -32 -- Compile for 32-bit instead of the OS default");
		Sys.println ("  (mac|linux) -64 -- Compile for 64-bit instead of the OS default");
		Sys.println ("  (ios|blackberry) -simulator -- Build/test for the device simulator");
		Sys.println ("  (ios) -simulator -ipad -- Build/test for the iPad Simulator");
		Sys.println ("  (android) -emulator -- Build/test for the device emulator");
		
		if (!userDefines.exists ("nme")) {
			
			Sys.println ("  (html5) -minify -- Minify output using the Google Closure compiler");
			Sys.println ("  (html5) -minify -yui -- Minify output using the YUI compressor");
			
		}
		
		
		//Sys.println ("  [android] -arm7 : Compile for arm-7a and arm5");
		//Sys.println ("  [android] -arm7-only : Compile for arm-7a for testing");
		
		//Sys.println ("  [flash] -web : Generate web template files");
		//Sys.println ("  [flash] -chrome : Generate Google Chrome app template files");
		//Sys.println ("  [flash] -opera : Generate an Opera Widget");
		//Sys.println ("  (display) -hxml -- Print HXML information for the project");
		//Sys.println ("  (display) -nmml -- Print NMML information for the project");
		//Sys.println ("  (generate) -java-externs : Generate Haxe classes from compiled Java");
		
		if (userDefines.exists ("nme")) {
			
			Sys.println ("  (run|test) -args a0 a1... -- Pass remaining arguments to executable");
			
		}
		
		Sys.println ("");
		Sys.println (" Project Overrides: ");
		Sys.println ("");
		Sys.println ("  --app-[option]=[value] -- Override a project <app /> setting");
		Sys.println ("  --meta-[option]=[value] -- Override a project <meta /> setting");
		Sys.println ("  --window-[option]=[value] -- Override a project <window /> setting");
		Sys.println ("  --dependency=[value] -- Add an additional <dependency /> value");
		Sys.println ("  --haxedef=[value] -- Add an additional <haxedef /> value");
		Sys.println ("  --haxeflag=[value] -- Add an additional <haxeflag /> value");
		Sys.println ("  --haxelib=[value] -- Add an additional <haxelib /> value");
		Sys.println ("  --source=[value] -- Add an additional <source /> value");
		Sys.println ("  --certificate-[option]=[value] -- Override a project <certificate /> setting");
		
	}
	
	
	private function displayInfo (showHint:Bool = false):Void {
		
		var alias = "openfl";
		var name = "OpenFL";
		
		if (userDefines.exists ("nme")) {
			
			Sys.println (" _____________");
			Sys.println ("|             |");
			Sys.println ("|__  _  __  __|");
			Sys.println ("|  \\| \\/  ||__|");
			Sys.println ("|\\  \\  \\ /||__|");
			Sys.println ("|_|\\_|\\/|_||__|");
			Sys.println ("|             |");
			Sys.println ("|_____________|");
			Sys.println ("");
			
			alias = "nme";
			name = "NME";
			
		} else {
			
			//Sys.println ("   ___                   _____ _     ");
			//Sys.println ("  / _ \\ _ __   ___ _ __ |  ___| |    ");
			//Sys.println (" | | | | '_ \\ / _ \\ '_ \\| |_  | |    ");
			//Sys.println (" | |_| | |_) |  __/ | | |  _| | |__ ");
			//Sys.println ("  \\___/| .__/ \\___|_| |_|_|   |____|");
			//Sys.println ("       |_|                           ");
			//Sys.println ("");
			
			Sys.println ("   ____                   ______ _ ");
			Sys.println ("  / __ \\____  ___  ____  / ____/ / ");
			Sys.println (" / / / / __ \\/ _ \\/ __ \\/ /__ / /  ");
			Sys.println ("/ /_/ / /_/ /  __/ / / / ___// /___");
			Sys.println ("\\____/  ___/\\___/_/ /_/_/   /_____/");
			Sys.println ("    /_/");
			Sys.println ("");
			
		}
		
		Sys.println (name + " Command-Line Tools (" + version + ")");
		
		if (showHint) {
			
			Sys.println ("Use \"" + alias + " setup\" to configure " + name + " or \"" + alias + " help\" for more commands");
			
		}
		
	}
	
	
	private function findProjectFile (path:String):String {
		
		if (FileSystem.exists (PathHelper.combine (path, "project.hxp"))) {
			
			return PathHelper.combine (path, "project.hxp");
			
		} else if (FileSystem.exists (PathHelper.combine (path, "project.nmml"))) {
			
			return PathHelper.combine (path, "project.nmml");
			
		} else if (FileSystem.exists (PathHelper.combine (path, "project.xml"))) {
			
			return PathHelper.combine (path, "project.xml");
			
		} else {
			
			var files = FileSystem.readDirectory (path);
			var matches = new Map <String, Array <String>> ();
			matches.set ("hxp", []);
			matches.set ("nmml", []);
			matches.set ("xml", []);
			
			for (file in files) {
				
				var path = PathHelper.combine (path, file);
				
				if (FileSystem.exists (path) && !FileSystem.isDirectory (path)) {
					
					var extension = Path.extension (file);
					
					if ((extension == "nmml" && file != "include.nmml") || (extension == "xml" && file != "include.xml") || extension == "hxp") {
						
						matches.get (extension).push (path);
						
					}
					
				}
				
			}
			
			if (matches.get ("hxp").length > 0) {
				
				return matches.get ("hxp")[0];
				
			}
			
			if (matches.get ("nmml").length > 0) {
				
				return matches.get ("nmml")[0];
				
			}
			
			if (matches.get ("xml").length > 0) {
				
				return matches.get ("xml")[0];
				
			}
			
		}
		
		return "";
		
	}
	
	
	private function generate ():Void {
		
		if (targetFlags.exists ("font-hash")) {
			
			var sourcePath = words[0];
			var glyphs = "32-255";
			
			ProcessHelper.runCommand (Path.directory (sourcePath), "neko", [ PathHelper.getHaxelib (new Haxelib ("hxtools")) + "/templates/bin/hxswfml.n", "ttf2hash2", Path.withoutDirectory (sourcePath), Path.withoutDirectory (sourcePath) + ".hash", "-glyphs", glyphs ]);
			
		} else if (targetFlags.exists ("font-details")) {
			
			var sourcePath = words[0];
			
			var details = Font.load (sourcePath);
			var json = Json.stringify (details);
			Sys.print (json);
			
		} else if (targetFlags.exists ("java-externs")) {
			
			var config = getHXCPPConfig ();
			var sourcePath = words[0];
			var targetPath = words[1];
			
			new JavaExternGenerator (config, sourcePath, targetPath);
			
		}
		
	}
	
	
	private function getBuildNumber (project:HXProject, increment:Bool = true):Void {
		
		if (project.meta.buildNumber == "1") {
			
			var versionFile = PathHelper.combine (project.app.path, ".build");
			var version = 1;
			
			PathHelper.mkdir (project.app.path);
			
			if (FileSystem.exists (versionFile)) {
				
				var previousVersion = Std.parseInt (File.getBytes (versionFile).toString ());
				
				if (previousVersion != null) {
					
					version = previousVersion;
					
					if (increment) {
						
						version ++;
						
					}
					
				}
				
			}
			
			project.meta.buildNumber = Std.string (version);
			
			try {
				
			   var output = File.write (versionFile, false);
			   output.writeString (Std.string (version));
			   output.close ();
				
			} catch (e:Dynamic) {}
			
		}
		
	}
	
	
	public static function getHXCPPConfig ():HXProject {
		
		var environment = Sys.environment ();
		var config = "";
		
		if (environment.exists ("HXCPP_CONFIG")) {
			
			config = environment.get ("HXCPP_CONFIG");
			
		} else {
			
			var home = "";
			
			if (environment.exists ("HOME")) {
				
				home = environment.get ("HOME");
				
			} else if (environment.exists ("USERPROFILE")) {
				
				home = environment.get ("USERPROFILE");
				
			} else {
				
				LogHelper.warn ("HXCPP config might be missing (Environment has no \"HOME\" variable)");
				
				return null;
				
			}
			
			config = home + "/.hxcpp_config.xml";
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				config = config.split ("/").join ("\\");
				
			}
			
		}
		
		if (FileSystem.exists (config)) {
			
			LogHelper.info ("", "Reading HXCPP config: " + config);
			
			return new ProjectXMLParser (config);
			
		} else {
			
			LogHelper.warn ("", "Could not read HXCPP config: " + config);
			
		}
		
		return null;
		
	}
	
	
	private function getVersion ():String {
		
		var json;
		
		if (userDefines.exists ("nme")) {
			
			json = Json.parse (File.getContent (PathHelper.getHaxelib (new Haxelib ("nme")) + "/haxelib.json"));
			
		} else {
			
			json = Json.parse (File.getContent (PathHelper.getHaxelib (new Haxelib ("hxtools")) + "/haxelib.json"));
			
		}
		
		return json.version;
		
	}
	
	
	#if (neko && (haxe_210 || haxe3))
	public static function __init__ () {
		
		var haxePath = Sys.getEnv ("HAXEPATH");
		var command = (haxePath != null && haxePath != "") ? haxePath + "/haxelib" : "haxelib";
		
		var process = new Process (command, [ "path", "hxtools" ]);
		var path = "";
		
		try {
			
			var lines = new Array <String> ();
			
			while (true) {
				
				var length = lines.length;
				var line = process.stdout.readLine ();
				
				if (length > 0 && StringTools.trim (line) == "-D hxtools") {
					
					path = StringTools.trim (lines[length - 1]);
					
				}
				
				lines.push (line);
         		
   			}
   			
		} catch (e:Dynamic) {
			
		}
		
		process.close ();
		path += "/ndll/";
		
		switch (PlatformHelper.hostPlatform) {
			
			case WINDOWS:
				
				untyped $loader.path = $array (path + "Windows/", $loader.path);
				
			case MAC:
				
				if (PlatformHelper.hostArchitecture == Architecture.X64) {
					
					untyped $loader.path = $array (path + "Mac64/", $loader.path);
					
				} else {
					
					untyped $loader.path = $array (path + "Mac/", $loader.path);
					
				}
				
			case LINUX:
				
				var arguments = Sys.args ();
				var raspberryPi = false;
				
				for (argument in arguments) {
					
					if (argument == "-rpi") raspberryPi = true;
					
				}
				
				if (raspberryPi) {
					
					untyped $loader.path = $array (path + "RPi/", $loader.path);
					
				} else if (PlatformHelper.hostArchitecture == Architecture.X64) {
					
					untyped $loader.path = $array (path + "Linux64/", $loader.path);
					
				} else {
					
					untyped $loader.path = $array (path + "Linux/", $loader.path);
					
				}
			
			default:
			
		}
		
	}
	#end
	
	
	private function initializeProject ():HXProject {
		
		LogHelper.info ("", "Initializing project...");
		
		var projectFile = "";
		var targetName = "";
		
		if (words.length == 2) {
			
			if (FileSystem.exists (words[0])) {
				
				if (FileSystem.isDirectory (words[0])) {
					
					projectFile = findProjectFile (words[0]);
					
				} else {
					
					projectFile = words[0];
					
				}
				
			}
			
			targetName = words[1].toLowerCase ();
			
		} else {
			
			projectFile = findProjectFile (Sys.getCwd ());
			targetName = words[0].toLowerCase ();
			
		}
		
		if (projectFile == "") {
			
			LogHelper.error ("You must have a \"project.xml\" file or specify another valid project file when using the '" + command + "' command");
			return null;
			
		} else {
			
			LogHelper.info ("", "Using project file: " + projectFile);
			
		}
		
		var target = null;
		
		switch (targetName) {
			
			case "cpp":
				
				target = PlatformHelper.hostPlatform;
				targetFlags.set ("cpp", "");
				
			case "neko":
				
				target = PlatformHelper.hostPlatform;
				targetFlags.set ("neko", "");
				
			case "iphone", "iphoneos":
				
				target = Platform.IOS;
				
			case "iphonesim":
				
				target = Platform.IOS;
				targetFlags.set ("simulator", "");
			
			default:
				
				try {
					
					target = Type.createEnum (Platform, targetName.toUpperCase ());
					
				} catch (e:Dynamic) {
					
					LogHelper.error ("\"" + targetName + "\" is an unknown target");
					
				}
			
		}
		
		var config = getHXCPPConfig ();
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			if (config != null && config.environment.exists ("JAVA_HOME")) {
				
				Sys.putEnv ("JAVA_HOME", config.environment.get ("JAVA_HOME"));
				
			}
			
			if (Sys.getEnv ("JAVA_HOME") != null) {
				
				var javaPath = PathHelper.combine (Sys.getEnv ("JAVA_HOME"), "bin");
				
				if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
					
					Sys.putEnv ("PATH", javaPath + ";" + Sys.getEnv ("PATH"));
					
				} else {
					
					Sys.putEnv ("PATH", javaPath + ":" + Sys.getEnv ("PATH"));
					
				}
				
			}
			
		}
		
		HXProject._command = command;
		HXProject._debug = debug;
		HXProject._target = target;
		HXProject._targetFlags = targetFlags;
		//HXProject._templatePaths = [ nme + "/templates/default", nme + "/tools/command-line" ];
		
		try { Sys.setCwd (Path.directory (projectFile)); } catch (e:Dynamic) {}
		
		var project:HXProject = null;
		
		if (Path.extension (projectFile) == "nmml" || Path.extension (projectFile) == "xml") {
			
			project = new ProjectXMLParser (Path.withoutDirectory (projectFile), userDefines, includePaths);
			
		} else if (Path.extension (projectFile) == "hxp") {
			
			project = HXProject.fromFile (projectFile, userDefines, includePaths);
			
			if (project != null) {
				
				project.command = command;
				project.debug = debug;
				project.target = target;
				project.targetFlags = targetFlags;
				//project.templatePaths = project.templatePaths.concat ([ nme + "/templates/default", nme + "/tools/command-line" ]);
				
			} else {
				
				LogHelper.error ("Could not process \"" + projectFile + "\"");
				return null;
				
			}
			
		}
		
		if (project == null) {
			
			LogHelper.error ("You must have a \"project.xml\" file or specify another valid project file when using the '" + command + "' command");
			return null;
			
		}
		
		project.merge (config);
		
		project.haxedefs.set ("tools", version);
		
		if (userDefines.exists ("nme")) {
			
			project.haxedefs.set ("nme_install_tool", 1);
			project.haxedefs.set ("nme_ver", version);
			project.haxedefs.set ("nme" + version.split (".")[0], 1);
			
			project.config.cpp.buildLibrary = "hxcpp";
			project.config.cpp.requireBuild = false;
			
		}
		
		project.merge (overrides);
		
		if (overrides.architectures.length > 0) {
			
			project.architectures = overrides.architectures;
			
		}
		
		for (key in projectDefines.keys ()) {
			
			var components = key.split ("-");
			var field = components.shift ().toLowerCase ();
			var attribute = "";
			
			if (components.length > 0) {
				
				for (i in 1...components.length) {
					
					components[i] = components[i].substr (0, 1).toUpperCase () + components[i].substr (1).toLowerCase ();
					
				}
				
				attribute = components.join ("");
				
			}
			
			if (field == "template" && attribute == "path") {
				
				project.templatePaths.push (projectDefines.get (key));
				
			} else {
				
				if (Reflect.hasField (project, field)) {
					
					var fieldValue = Reflect.field (project, field);
					
					if (Reflect.hasField (fieldValue, attribute)) {
						
						if (Std.is (Reflect.field (fieldValue, attribute), String)) {
							
							Reflect.setField (fieldValue, attribute, projectDefines.get (key));
							
						} else if (Std.is (Reflect.field (fieldValue, attribute), Float)) {
							
							Reflect.setField (fieldValue, attribute, Std.parseFloat (projectDefines.get (key)));
							
						} else if (Std.is (Reflect.field (fieldValue, attribute), Bool)) {
							
							Reflect.setField (fieldValue, attribute, (projectDefines.get (key).toLowerCase () == "true" || projectDefines.get (key) == "1"));
							
						}
						
					}
					
				}
				
			}
			
		}
		
		StringMapHelper.copyKeys (userDefines, project.haxedefs);
		
		// Better way to do this?
		
		switch (project.target) {
			
			case ANDROID, IOS, BLACKBERRY:
				
				getBuildNumber (project);
				
			default:
			
		}
		
		return project;
		
	}
	
	
	public static function main ():Void {
		
		new CommandLineTools ();
		
	}
	
	
	private function processArguments ():Void {
		
		var arguments = Sys.args ();
		
		if (arguments.length > 0) {
			
			// When the command-line tools are called from haxelib, 
			// the last argument is the project directory and the
			// path to NME is the current working directory 
			
			var lastArgument = "";
			
			for (i in 0...arguments.length) {
				
				lastArgument = arguments.pop ();
				if (lastArgument.length > 0) break;
				
			}
			
			lastArgument = new Path (lastArgument).toString ();
			
			if (((StringTools.endsWith (lastArgument, "/") && lastArgument != "/") || StringTools.endsWith (lastArgument, "\\")) && !StringTools.endsWith (lastArgument, ":\\")) {
				
				lastArgument = lastArgument.substr (0, lastArgument.length - 1);
				
			}
			
			if (FileSystem.exists (lastArgument) && FileSystem.isDirectory (lastArgument)) {
				
				Sys.setCwd (lastArgument);
				
			}
			
		}
		
		var catchArguments = false;
		var catchHaxeFlag = false;
		
		for (argument in arguments) {

			var equals = argument.indexOf ("=");
			
			if (catchHaxeFlag) {
				
				overrides.haxeflags.push (argument);
				catchHaxeFlag = false;
				
			} else if (catchArguments) {
				
				additionalArguments.push (argument);
				
			} else if (equals > 0) {

				var argValue = argument.substr (equals + 1);
				// if quotes remain on the argValue we need to strip them off
				// otherwise the compiler really dislikes the result!
				var r = ~/^['"](.*)['"]$/;
				if (r.match(argValue)) {
					argValue = r.matched(1);
				}
				
				if (argument.substr (0, 2) == "-D") {
					
					userDefines.set (argument.substr (2, equals - 2), argValue);
					
				} else if (argument.substr (0, 2) == "--") {
					
					// this won't work because it assumes there is only ever one of these.
					//projectDefines.set (argument.substr (2, equals - 2), argValue);
					
					var field = argument.substr (2, equals - 2);
					
					if (field == "haxedef") {
						
						overrides.haxedefs.set (argValue, 1);
						
					} else if (field == "haxeflag") {
						
						overrides.haxeflags.push (argValue);
						
					} else if (field == "haxelib") {
						
						var name = argValue;
						var version = "";
						
						if (name.indexOf (":") > -1) {
							
							version = name.substr (name.indexOf (":") + 1);
							name = name.substr (0, name.indexOf (":"));
							
						}
						
						overrides.haxelibs.push (new Haxelib (name, version));
						
					} else if (field == "source") {
						
						overrides.sources.push (argValue);
						
					} else if (field == "dependency") {
						
						overrides.dependencies.push (new Dependency (argValue, ""));
						
					} else if (StringTools.startsWith (field, "certificate-")) {
						
						if (overrides.certificate == null) {
							
							overrides.certificate = new Keystore ();
							
						}
						
						field = StringTools.replace (field, "certificate-", "");
						
						if (field == "alias-password") field = "aliasPassword";
						
						if (Reflect.hasField (overrides.certificate, field)) {
							
							Reflect.setField (overrides.certificate, field, argValue);
							
						}
							
					} else if (StringTools.startsWith (field, "app-") || StringTools.startsWith (field, "meta-") || StringTools.startsWith (field, "window-")) {
						
						var split = field.split ("-");
						
						var fieldName = split[0];
						var property = split[1];
						
						for (i in 2...split.length) {
							
							property += split[i].substr (0, 1).toUpperCase () + split[i].substr (1, split[i].length - 1);
							
						}
						
						var fieldReference = Reflect.field (overrides, fieldName);
						
						if (Reflect.hasField (fieldReference, property)) {
							
							var propertyReference = Reflect.field (fieldReference, property);
							
							if (Std.is (propertyReference, Bool)) {
								
								Reflect.setField (fieldReference, property, argValue == "true");
								
							} else if (Std.is (propertyReference, Int)) {
								
								Reflect.setField (fieldReference, property, Std.parseInt (argValue));
								
							} else if (Std.is (propertyReference, Float)) {
								
								Reflect.setField (fieldReference, property, Std.parseFloat (argValue));
								
							} else if (Std.is (propertyReference, String)) {
								
								Reflect.setField (fieldReference, property, argValue);
								
							}
							
						}
						
					} else {
						
						projectDefines.set (field, argValue);
						
					}
					
				} else {
					
					userDefines.set (argument.substr (0, equals), argValue);
					
				}
				
			} else if (argument.substr (0, 4) == "-arm") {
				
				var name = argument.substr (1).toUpperCase ();
				var value = Type.createEnum (Architecture, name);
				
				if (value != null) {
					
					overrides.architectures.push (value);
					
				}
				
			} else if (argument == "-64") {
				
				overrides.architectures.push (Architecture.X64);
				
			} else if (argument == "-32") {
				
				overrides.architectures.push (Architecture.X86);
				
			} else if (argument.substr (0, 2) == "-D") {
				
				userDefines.set (argument.substr (2), "");
				
			} else if (argument.substr (0, 2) == "-l") {
				
				includePaths.push (argument.substr (2));
				
			} else if (argument == "-v" || argument == "-verbose") {
				
				LogHelper.verbose = true;
				
			} else if (argument == "-args") {
				
				catchArguments = true;
				
			} else if (argument == "-notrace") {
				
				traceEnabled = false;
				
			} else if (argument == "-debug") {
				
				debug = true;
				
			} else if (command.length == 0) {
				
				command = argument;
				
			} else if (argument.substr (0, 1) == "-") {
				
				if (argument.substr (1, 1) == "-") {
					
					overrides.haxeflags.push (argument);
					
					if (argument == "--remap" || argument == "--connect") {
						
						catchHaxeFlag = true;
						
					}
					
				} else {
					
					targetFlags.set (argument.substr (1), "");
					
				}
				
			} else {
				
				words.push (argument);
				
			}
			
		}
		
	}
	
	
	private function platformSetup ():Void {
		
		LogHelper.info ("", "Running command: SETUP");
		
		if (words.length == 0) {
			
			PlatformSetup.run ("", userDefines);
			
		} else if (words.length == 1) {
			
			PlatformSetup.run (words[0], userDefines);
			
		} else {
			
			LogHelper.error ("Incorrect number of arguments for command 'setup'");
			return;
			
		}
		
	}
	
	
}
