package;


//import openfl.text.Font;
//import openfl.utils.ByteArray;
//import openfl.utils.CompressionAlgorithm;
import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.io.Path;
import haxe.rtti.Meta;
import lime.tools.helpers.*;
import lime.system.System;
import lime.tools.platforms.*;
import lime.project.*;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;
import utils.publish.*;
import utils.CreateTemplate;
import utils.JavaExternGenerator;
import utils.PlatformSetup;
	
	
class CommandLineTools {
	
	
	public static var commandName = "lime";
	public static var defaultLibrary = "lime";
	public static var defaultLibraryName = "Lime";
	
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
		
		PathHelper.haxelibOverrides.set ("lime-tools", PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "tools"));
		
		processArguments ();
		version = getVersion ();
		
		if (targetFlags.exists ("openfl")) {
			
			LogHelper.accentColor = "\x1b[36;1m";
			commandName = "openfl";
			defaultLibrary = "openfl";
			defaultLibraryName = "OpenFL";
			
		}
		
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
				
			case "install", "remove", "upgrade":
				
				updateLibrary ();
			
			case "clean", "update", "display", "build", "run", "rerun", /*"install",*/ "uninstall", "trace", "test":
				
				if (words.length < 1 || words.length > 2) {
					
					LogHelper.error ("Incorrect number of arguments for command '" + command + "'");
					return;
					
				}
				
				var project = initializeProject ();
				buildProject (project);
			
			case "rebuild":
				
				if (words.length < 1 || words.length > 2) {
					
					LogHelper.error ("Incorrect number of arguments for command '" + command + "'");
					return;
					
				}
				
				if (words.length < 2) {
					
					words.unshift ("lime");
					
				}
				
				var targets = words[1].split (",");
				
				var haxelib = null;
				var path = null;
				var project = null;
				
				if (!FileSystem.exists (words[0])) {
					
					if (FileSystem.exists (PathHelper.tryFullPath (words[0]))) {
						
						path = PathHelper.combine (PathHelper.tryFullPath (words[0]), "project");
						
					} else {
						
						haxelib = new Haxelib (words[0]);
						
					}
					
				} else {
					
					if (FileSystem.isDirectory (words[0])) {
						
						if (FileSystem.exists (PathHelper.combine (words[0], "Build.xml"))) {
							
							path = words[0];
							
						} else {
							
							path = PathHelper.combine (words[0], "project");
							
						}
						
					} else {
						
						path = words[0];
						
					}
					
					var haxelibPath = PathHelper.getHaxelib (new Haxelib (words[0]));
					
					if (!FileSystem.exists (path) && haxelibPath != null) {
						
						haxelib = new Haxelib (words[0]);
						
					}
					
				}
				
				if (haxelib != null) {
					
					PathHelper.getHaxelib (haxelib, true);
					
				}
				
				for (targetName in targets) {
					
					var target = null;
					
					switch (targetName) {
						
						case "cpp":
							
							target = PlatformHelper.hostPlatform;
							targetFlags.set ("cpp", "");
							
						case "neko":
							
							target = PlatformHelper.hostPlatform;
							targetFlags.set ("neko", "");
						
						case "nodejs":
							
							target = PlatformHelper.hostPlatform;
							targetFlags.set ("nodejs", "");
							
						case "iphone", "iphoneos":
							
							target = Platform.IOS;
							
						case "iphonesim":
							
							target = Platform.IOS;
							targetFlags.set ("simulator", "");
						
						case "firefox", "firefoxos":
							
							target = Platform.FIREFOX;
							overrides.haxedefs.set ("firefoxos", "");
						
						default:
							
							target = cast targetName.toLowerCase ();
						
					}
					
					HXProject._command = command;
					HXProject._debug = debug;
					HXProject._target = target;
					HXProject._targetFlags = targetFlags;
					
					var project = null;
					
					if (haxelib != null) {
						
						userDefines.set ("rebuild", 1);
						project = HXProject.fromHaxelib (haxelib, userDefines);
						
						if (project == null) {
							
							project = new HXProject ();
							project.config.set ("project.rebuild.path", PathHelper.combine (PathHelper.getHaxelib (haxelib), "project"));
							
						}
						
					} else {
						
						//project = HXProject.fromPath (path);
						
						if (project == null) {
							
							project = new HXProject ();
							
							if (FileSystem.isDirectory (path)) {
								
								project.config.set ("project.rebuild.path", path);
								
							} else {
								
								project.config.set ("project.rebuild.path", Path.directory (path));
								project.config.set ("project.rebuild.file", Path.withoutDirectory (path));
								
							}
							
						}
						
					}
					
					// this needs to be improved
					
					var rebuildPath = project.config.get ("project.rebuild.path");
					var rebuildFile = project.config.get ("project.rebuild.file");
					
					project.merge (overrides);
					
					for (haxelib in overrides.haxelibs) {
						
						var includeProject = HXProject.fromHaxelib (haxelib, project.defines);
						
						if (includeProject != null) {
							
							for (ndll in includeProject.ndlls) {
								
								if (ndll.haxelib == null) {
									
									ndll.haxelib = haxelib;
									
								}
								
							}
							
							project.merge (includeProject);
							
						}
						
					}
					
					project.config.set ("project.rebuild.path", rebuildPath);
					project.config.set ("project.rebuild.file", rebuildFile);
					
					initializeProject (project, targetName);
					buildProject (project);
					
					if (LogHelper.verbose) {
						
						LogHelper.println ("");
						
					}
					
				}
			
			case "publish":
				
				if (words.length < 1 || words.length > 2) {
					
					LogHelper.error ("Incorrect number of arguments for command '" + command + "'");
					return;
					
				}
				
				publishProject ();
			
			case "installer", "copy-if-newer":
				
				// deprecated?
			
			default:
				
				LogHelper.error ("'" + command + "' is not a valid command");
			
		}
		
	}
	
	
	#if (neko && (haxe_210 || haxe3))
	public static function __init__ ():Void {
		
		var args = Sys.args ();
		
		if (args.length > 0 && args[0].toLowerCase () == "rebuild") {
			
			System.disableCFFI = true;
			
		}
		
		for (arg in args) {
			
			if (arg == "-nocffi") {
				
				System.disableCFFI = true;
				
			}
			
		}
		
		var process = new Process ("haxelib", [ "path", "lime" ]);
		var path = "";
		var lines = new Array <String> ();
		
		try {
			
			while (true) {
				
				var length = lines.length;
				var line = process.stdout.readLine ();
				
				if (length > 0 && StringTools.trim (line) == "-D lime") {
					
					path = StringTools.trim (lines[length - 1]);
					
				}
				
				lines.push (line);
				
			}
			
		} catch (e:Dynamic) {
			
		}
		
		if (path == "") {
			
			for (line in lines) {
				
				if (line != "" && line.substr (0, 1) != "-") {
					
					try {
						
						if (FileSystem.exists (line)) {
							
							path = line;
							
						}
						
					} catch (e:Dynamic) {}
					
				}
				
			}
			
		}
		
		process.close ();
		path += "/ndll/";
		
		switch (PlatformHelper.hostPlatform) {
			
			case WINDOWS:
				
				untyped $loader.path = $array (path + "Windows/", $loader.path);
				
			case MAC:
				
				//if (PlatformHelper.hostArchitecture == Architecture.X64) {
					
					untyped $loader.path = $array (path + "Mac64/", $loader.path);
					
				//} else {
					
				//	untyped $loader.path = $array (path + "Mac/", $loader.path);
					
				//}
				
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
	
	
	private function buildProject (project:HXProject, command:String = "") {
		
		if (command == "") {
			
			command = project.command.toLowerCase ();
			
		}
		
		if (project.targetHandlers.exists (Std.string (project.target))) {
			
			LogHelper.info ("", LogHelper.accentColor + "Using target platform: " + Std.string (project.target).toUpperCase () + "\x1b[0m");
			
			var handler = project.targetHandlers.get (Std.string (project.target));
			var projectData = Serializer.run (project);
			var temporaryFile = PathHelper.getTemporaryFile ();
			File.saveContent (temporaryFile, projectData);
			
			var args = [ "run", handler, command, temporaryFile ];
			
			if (LogHelper.verbose) args.push ("-verbose");
			if (!LogHelper.enableColor) args.push ("-nocolor");
			if (!traceEnabled) args.push ("-notrace");
			
			if (additionalArguments.length > 0) {
				
				args.push ("-args");
				args = args.concat (additionalArguments);
				
			}
			
			ProcessHelper.runCommand ("", "haxelib", args);
			
			try {
				
				FileSystem.deleteFile (temporaryFile);
				
			} catch (e:Dynamic) {}
			
		} else {
			
			var platform:PlatformTarget = null;
			
			switch (project.target) {
				
				case ANDROID:
					
					platform = new AndroidPlatform (command, project, targetFlags);
					
				case BLACKBERRY:
					
					platform = new BlackBerryPlatform (command, project, targetFlags);
				
				case IOS:
					
					platform = new IOSPlatform (command, project, targetFlags);
				
				case TIZEN:
					
					platform = new TizenPlatform (command, project, targetFlags);
				
				case WEBOS:
					
					platform = new WebOSPlatform (command, project, targetFlags);
				
				case WINDOWS:
					
					platform = new WindowsPlatform (command, project, targetFlags);
				
				case MAC:
					
					platform = new MacPlatform (command, project, targetFlags);
				
				case LINUX:
					
					platform = new LinuxPlatform (command, project, targetFlags);
				
				case FLASH:
					
					platform = new FlashPlatform (command, project, targetFlags);
				
				case HTML5:
					
					platform = new HTML5Platform (command, project, targetFlags);
				
				case FIREFOX:
					
					platform = new FirefoxPlatform (command, project, targetFlags);
				
				case EMSCRIPTEN:
					
					platform = new EmscriptenPlatform (command, project, targetFlags);
				
				default:
				
			}
			
			if (platform != null) {
				
				platform.execute (additionalArguments);
				
			} else {
				
				LogHelper.error ("\"" + Std.string (project.target) + "\" is an unknown target");
				
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
		
		LogHelper.info ("", LogHelper.accentColor + "Running command: CREATE\x1b[0m");
		
		if (words.length > 0) {
			
			var colonIndex = words[0].indexOf (":");
			
			var projectName = null;
			var sampleName = null;
			
			if (colonIndex == -1) {
				
				projectName = words[0];
				
				if (words.length > 1) {
					
					sampleName = words[1];
					
				}
				
			} else {
				
				projectName = words[0].substring (0, colonIndex);
				sampleName = words[0].substr (colonIndex + 1);
				
			}
			
			if (projectName == "project" || sampleName == "project") {
				
				CreateTemplate.createProject (words, userDefines);
				
			} else if (projectName == "extension") {
				
				CreateTemplate.createExtension (words, userDefines);
				
			} else {
				
				if (sampleName == null) {
					
					var sampleExists = false;
					var defines = new Map <String, Dynamic> ();
					defines.set ("create", 1);
					var project = HXProject.fromHaxelib (new Haxelib (defaultLibrary), defines);
					
					for (samplePath in project.samplePaths) {
						
						if (FileSystem.exists (PathHelper.combine (samplePath, projectName))) {
							
							sampleExists = true;
							
						}
						
					}
					
					if (sampleExists) {
						
						CreateTemplate.createSample (words, userDefines);
						
					} else if (PathHelper.getHaxelib (new Haxelib (projectName)) != "") {
						
						CreateTemplate.listSamples (projectName, userDefines);
						
					} else if (projectName == "" || projectName == null) {
						
						CreateTemplate.listSamples (defaultLibrary, userDefines);
						
					} else {
						
						CreateTemplate.listSamples (null, userDefines);
						
					}
					
				} else {
					
					CreateTemplate.createSample (words, userDefines);
					
				}
				
			}
			
		} else {
			
			CreateTemplate.listSamples (defaultLibrary, userDefines);
			
		}
		
	}
	
	
	private function displayHelp ():Void {
		
		displayInfo ();
		
		LogHelper.println ("");
		LogHelper.println (" " + LogHelper.accentColor + "Usage:\x1b[0m \x1b[1m" + commandName + "\x1b[0m setup \x1b[3;37m(target)\x1b[0m");
		LogHelper.println (" " + LogHelper.accentColor + "Usage:\x1b[0m \x1b[1m" + commandName + "\x1b[0m clean|update|build|run|test|display \x1b[3;37m<project>\x1b[0m (target) \x1b[3;37m[options]\x1b[0m");
		LogHelper.println (" " + LogHelper.accentColor + "Usage:\x1b[0m \x1b[1m" + commandName + "\x1b[0m create <library> (template) \x1b[3;37m(directory)\x1b[0m");
		LogHelper.println (" " + LogHelper.accentColor + "Usage:\x1b[0m \x1b[1m" + commandName + "\x1b[0m rebuild <library> (target)\x1b[3;37m,(target),...\x1b[0m");
		LogHelper.println (" " + LogHelper.accentColor + "Usage:\x1b[0m \x1b[1m" + commandName + "\x1b[0m install|remove|upgrade <library>");
		LogHelper.println (" " + LogHelper.accentColor + "Usage:\x1b[0m \x1b[1m" + commandName + "\x1b[0m help");
		LogHelper.println ("");
		LogHelper.println (" " + LogHelper.accentColor + "Commands:" + LogHelper.resetColor);
		LogHelper.println ("");
		LogHelper.println ("  \x1b[1msetup\x1b[0m -- Setup " + defaultLibraryName + " or a specific platform");
		LogHelper.println ("  \x1b[1mclean\x1b[0m -- Remove the target build directory if it exists");
		LogHelper.println ("  \x1b[1mupdate\x1b[0m -- Copy assets for the specified project/target");
		LogHelper.println ("  \x1b[1mbuild\x1b[0m -- Compile and package for the specified project/target");
		LogHelper.println ("  \x1b[1mrun\x1b[0m -- Install and run for the specified project/target");
		LogHelper.println ("  \x1b[1mtest\x1b[0m -- Update, build and run in one command");
		LogHelper.println ("  \x1b[1mdisplay\x1b[0m -- Display information for the specified project/target");
		LogHelper.println ("  \x1b[1mcreate\x1b[0m -- Create a new project or extension using templates");
		LogHelper.println ("  \x1b[1mrebuild\x1b[0m -- Recompile native binaries for libraries");
		LogHelper.println ("  \x1b[1minstall\x1b[0m -- Install a library from haxelib, plus dependencies");
		LogHelper.println ("  \x1b[1mremove\x1b[0m -- Remove a library from haxelib");
		LogHelper.println ("  \x1b[1mupgrade\x1b[0m -- Upgrade a library from haxelib");
		LogHelper.println ("  \x1b[1mhelp\x1b[0m -- Show this information");
		LogHelper.println ("");
		LogHelper.println (" " + LogHelper.accentColor + "Targets:" + LogHelper.resetColor);
		LogHelper.println ("");
		LogHelper.println ("  \x1b[1mandroid\x1b[0m -- Create an Android application");
		LogHelper.println ("  \x1b[1mblackberry\x1b[0m -- Create a BlackBerry application");
		LogHelper.println ("  \x1b[1memscripten\x1b[0m -- Create an Emscripten application");
		LogHelper.println ("  \x1b[1mflash\x1b[0m -- Create a Flash SWF application");
		LogHelper.println ("  \x1b[1mhtml5\x1b[0m -- Create an HTML5 canvas application");
		LogHelper.println ("  \x1b[1mios\x1b[0m -- Create an iOS application");
		LogHelper.println ("  \x1b[1mlinux\x1b[0m -- Create a Linux application");
		LogHelper.println ("  \x1b[1mmac\x1b[0m -- Create a Mac OS X application");
		LogHelper.println ("  \x1b[1mtizen\x1b[0m -- Create a Tizen application");
		LogHelper.println ("  \x1b[1mwebos\x1b[0m -- Create a webOS application");
		LogHelper.println ("  \x1b[1mwindows\x1b[0m -- Create a Windows application");
		LogHelper.println ("");
		LogHelper.println (" " + LogHelper.accentColor + "Options:" + LogHelper.resetColor);
		LogHelper.println ("");
		LogHelper.println ("  \x1b[1m-D\x1b[0;3mvalue\x1b[0m -- Specify a define to use when processing other commands");
		LogHelper.println ("  \x1b[1m-debug\x1b[0m -- Use debug configuration instead of release");
		LogHelper.println ("  \x1b[1m-verbose\x1b[0m -- Print additional information (when available)");
		LogHelper.println ("  \x1b[1m-clean\x1b[0m -- Add a \"clean\" action before running the current command");
		LogHelper.println ("  \x1b[1m-nocolor\x1b[0m -- Disable ANSI format codes in output");
		LogHelper.println ("  \x1b[1m-xml\x1b[0m -- Generate XML type information, useful for documentation");
		LogHelper.println ("  \x1b[1m-args\x1b[0m ... -- Add additional arguments when using \"run\" or \"test\"");
		LogHelper.println ("  \x1b[3m(windows|mac|linux)\x1b[0m \x1b[1m-neko\x1b[0m -- Build with Neko instead of C++");
		LogHelper.println ("  \x1b[3m(mac|linux)\x1b[0m \x1b[1m-32\x1b[0m -- Compile for 32-bit instead of the OS default");
		LogHelper.println ("  \x1b[3m(mac|linux)\x1b[0m \x1b[1m-64\x1b[0m -- Compile for 64-bit instead of the OS default");
		LogHelper.println ("  \x1b[3m(ios|blackberry|tizen|webos)\x1b[0m \x1b[1m-simulator\x1b[0m -- Target the device simulator");
		LogHelper.println ("  \x1b[3m(ios)\x1b[0m \x1b[1m-simulator -ipad\x1b[0m -- Build/test for the iPad Simulator");
		LogHelper.println ("  \x1b[3m(android)\x1b[0m \x1b[1m-emulator\x1b[0m -- Target the device emulator");
		LogHelper.println ("  \x1b[3m(html5)\x1b[0m \x1b[1m-minify\x1b[0m -- Minify output using the Google Closure compiler");
		LogHelper.println ("  \x1b[3m(html5)\x1b[0m \x1b[1m-minify -yui\x1b[0m -- Minify output using the YUI compressor");
		LogHelper.println ("");
		LogHelper.println (" " + LogHelper.accentColor + "Project Overrides:" + LogHelper.resetColor);
		LogHelper.println ("");
		LogHelper.println ("  \x1b[1m--app-\x1b[0;3moption=value\x1b[0m -- Override a project <app/> setting");
		LogHelper.println ("  \x1b[1m--meta-\x1b[0;3moption=value\x1b[0m -- Override a project <meta/> setting");
		LogHelper.println ("  \x1b[1m--window-\x1b[0;3moption=value\x1b[0m -- Override a project <window/> setting");
		LogHelper.println ("  \x1b[1m--dependency\x1b[0;3m=value\x1b[0m -- Add an additional <dependency/> value");
		LogHelper.println ("  \x1b[1m--haxedef\x1b[0;3m=value\x1b[0m -- Add an additional <haxedef/> value");
		LogHelper.println ("  \x1b[1m--haxeflag\x1b[0;3m=value\x1b[0m -- Add an additional <haxeflag/> value");
		LogHelper.println ("  \x1b[1m--haxelib\x1b[0;3m=value\x1b[0m -- Add an additional <haxelib/> value");
		LogHelper.println ("  \x1b[1m--haxelib-\x1b[0;3mname=value\x1b[0m -- Override the path to a haxelib");
		LogHelper.println ("  \x1b[1m--source\x1b[0;3m=value\x1b[0m -- Add an additional <source/> value");
		LogHelper.println ("  \x1b[1m--certificate-\x1b[0;3moption=value\x1b[0m -- Override a project <certificate/> setting");
		
	}
	
	
	private function displayInfo (showHint:Bool = false):Void {
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			LogHelper.println ("");
			
		}
		
		if (targetFlags.exists ("openfl")) {
			
			LogHelper.println ("\x1b[37m .d88 88b.                             \x1b[0m\x1b[1;36m888888b 888 \x1b[0m");
			LogHelper.println ("\x1b[37md88P\" \"Y88b                            \x1b[0m\x1b[1;36m888     888 \x1b[0m");
			LogHelper.println ("\x1b[37m888     888                            \x1b[0m\x1b[1;36m888     888 \x1b[0m");
			LogHelper.println ("\x1b[37m888     888 88888b.   .d88b.  88888b.  \x1b[0m\x1b[1;36m8888888 888 \x1b[0m");
			LogHelper.println ("\x1b[37m888     888 888 \"88b d8P  Y8b 888 \"88b \x1b[0m\x1b[1;36m888     888 \x1b[0m");
			LogHelper.println ("\x1b[37m888     888 888  888 88888888 888  888 \x1b[0m\x1b[1;36m888     888 \x1b[0m");
			LogHelper.println ("\x1b[37mY88b. .d88P 888 d88P Y8b.     888  888 \x1b[0m\x1b[1;36m888     888 \x1b[0m");
			LogHelper.println ("\x1b[37m \"Y88 88P\"  88888P\"   \"Y8888  888  888 \x1b[0m\x1b[1;36m888     \"Y888P \x1b[0m");
			LogHelper.println ("\x1b[37m            888                                   ");
			LogHelper.println ("\x1b[37m            888                                   \x1b[0m");
			
			LogHelper.println ("");
			LogHelper.println ("\x1b[1mOpenFL Command-Line Tools\x1b[0;1m (" + getVersion (new Haxelib ("openfl")) + "-L" + StringHelper.generateUUID (5, null, StringHelper.generateHashCode (version)) + ")\x1b[0m");
			
		} else {
			
			LogHelper.println ("\x1b[32;1m ___     \x1b[0m");
			LogHelper.println ("\x1b[32m/\x1b[1m\\_ \\    __                       \x1b[0m");
			LogHelper.println ("\x1b[32m\\//\x1b[1m\\ \\  \x1b[0m\x1b[32m/\x1b[1m\\\x1b[0m\x1b[32m_\x1b[1m\\    ___ ___      __   \x1b[0m");
			LogHelper.println ("\x1b[32m  \\ \x1b[1m\\ \\ \x1b[0m\x1b[32m\\/\x1b[1m\\ \\ /' __` __`\\  /'__`\\ \x1b[0m");
			LogHelper.println ("\x1b[32m   \\\x1b[1m_\\ \\_\x1b[0m\x1b[32m\\ \x1b[1m\\ \\\x1b[0m\x1b[32m/\x1b[1m\\ \\\x1b[0m\x1b[32m/\x1b[1m\\ \\\x1b[0m\x1b[32m/\x1b[1m\\ \\\x1b[0m\x1b[32m/\x1b[1m\\  __/ \x1b[0m");
			LogHelper.println ("\x1b[32m   /\x1b[1m\\____\\\x1b[0m\x1b[32m\\ \x1b[1m\\_\\ \\_\\ \\_\\ \\_\\ \\____\\\x1b[0m");
			LogHelper.println ("\x1b[32m   \\/____/ \\/_/\\/_/\\/_/\\/_/\\/____/\x1b[0m");
			
			LogHelper.println ("");
			LogHelper.println ("\x1b[1mLime Command-Line Tools\x1b[0;1m (" + version + ")\x1b[0m");
			
		}
		
		if (showHint) {
			
			LogHelper.println ("Use \x1b[3m" + commandName + " setup\x1b[0m to configure platforms or \x1b[3m" + commandName + " help\x1b[0m for more commands");
			
		}
		
	}
	
	
	private function document ():Void {
		
		
		
	}
	
	
	private function findProjectFile (path:String):String {
		
		if (FileSystem.exists (PathHelper.combine (path, "project.hxp"))) {
			
			return PathHelper.combine (path, "project.hxp");
			
		} else if (FileSystem.exists (PathHelper.combine (path, "project.lime"))) {
			
			return PathHelper.combine (path, "project.lime");
			
		} else if (FileSystem.exists (PathHelper.combine (path, "project.nmml"))) {
			
			return PathHelper.combine (path, "project.nmml");
			
		} else if (FileSystem.exists (PathHelper.combine (path, "project.xml"))) {
			
			return PathHelper.combine (path, "project.xml");
			
		} else {
			
			var files = FileSystem.readDirectory (path);
			var matches = new Map <String, Array <String>> ();
			matches.set ("hxp", []);
			matches.set ("lime", []);
			matches.set ("nmml", []);
			matches.set ("xml", []);
			
			for (file in files) {
				
				var path = PathHelper.combine (path, file);
				
				if (FileSystem.exists (path) && !FileSystem.isDirectory (path)) {
					
					var extension = Path.extension (file);
					
					if ((extension == "lime" && file != "include.lime") || (extension == "nmml" && file != "include.nmml") || (extension == "xml" && file != "include.xml") || extension == "hxp") {
						
						matches.get (extension).push (path);
						
					}
					
				}
				
			}
			
			if (matches.get ("hxp").length > 0) {
				
				return matches.get ("hxp")[0];
				
			}
			
			if (matches.get ("lime").length > 0) {
				
				return matches.get ("lime")[0];
				
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
			
			ProcessHelper.runCommand (Path.directory (sourcePath), "neko", [ PathHelper.getHaxelib (new Haxelib ("lime")) + "/templates/bin/hxswfml.n", "ttf2hash2", Path.withoutDirectory (sourcePath), Path.withoutDirectory (sourcePath) + ".hash", "-glyphs", glyphs ]);
			
		} else if (targetFlags.exists ("font-details")) {
			
			//var sourcePath = words[0];
			
			//var details = Font.load (sourcePath);
			//var json = Json.stringify (details);
			//Sys.print (json);
			
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
			
			try {
				
				if (FileSystem.exists (versionFile)) {
					
					var previousVersion = Std.parseInt (File.getBytes (versionFile).toString ());
					
					if (previousVersion != null) {
						
						version = previousVersion;
						
						if (increment) {
							
							version ++;
							
						}
						
					}
					
				}
				
			} catch (e:Dynamic) {}
			
			project.meta.buildNumber = Std.string (version);
			
			if (increment) {
				
				try {
					
					PathHelper.mkdir (project.app.path);
					
					var output = File.write (versionFile, false);
					output.writeString (Std.string (version));
					output.close ();
					
				} catch (e:Dynamic) {}
				
			}
			
			
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
			
			LogHelper.info ("", LogHelper.accentColor + "Reading HXCPP config: " + config + LogHelper.resetColor);
			
			return new ProjectXMLParser (config);
			
		} else {
			
			LogHelper.warn ("", "Could not read HXCPP config: " + config);
			
		}
		
		return null;
		
	}
	
	
	private function getVersion (haxelib:Haxelib = null):String {
		
		if (haxelib == null) {
			
			haxelib = new Haxelib ("lime");
			
		}
		
		var json = Json.parse (File.getContent (PathHelper.getHaxelib (haxelib, true) + "/haxelib.json"));
		return json.version;
		
	}
	
	
	private function initializeProject (project:HXProject = null, targetName:String = ""):HXProject {
		
		LogHelper.info ("", LogHelper.accentColor + "Initializing project..." + LogHelper.resetColor);
		
		var projectFile = "";
		
		if (project == null) {
			
			if (words.length == 2) {
				
				if (FileSystem.exists (words[0])) {
					
					if (FileSystem.isDirectory (words[0])) {
						
						projectFile = findProjectFile (words[0]);
						
					} else {
						
						projectFile = words[0];
						
					}
					
				}
				
				if (targetName == "") {
					
					targetName = words[1].toLowerCase ();
					
				}
				
			} else {
				
				projectFile = findProjectFile (Sys.getCwd ());
				
				if (targetName == "") {
					
					targetName = words[0].toLowerCase ();
					
				}
				
			}
			
			if (projectFile == "") {
				
				LogHelper.error ("You must have a \"project.xml\" file or specify another valid project file when using the '" + command + "' command");
				return null;
				
			} else {
				
				LogHelper.info ("", LogHelper.accentColor + "Using project file: " + projectFile + LogHelper.resetColor);
				
			}
			
		}
		
		var target = null;
		
		switch (targetName) {
			
			case "cpp":
				
				target = PlatformHelper.hostPlatform;
				targetFlags.set ("cpp", "");
				
			case "neko":
				
				target = PlatformHelper.hostPlatform;
				targetFlags.set ("neko", "");
			
			case "java":
				
				target = PlatformHelper.hostPlatform;
				targetFlags.set ("java", "");
			
			case "nodejs":
				
				target = PlatformHelper.hostPlatform;
				targetFlags.set ("nodejs", "");
			
			case "iphone", "iphoneos":
				
				target = Platform.IOS;
				
			case "iphonesim":
				
				target = Platform.IOS;
				targetFlags.set ("simulator", "");
			
			case "firefox", "firefoxos":
				
				target = Platform.FIREFOX;
				overrides.haxedefs.set ("firefoxos", "");
			
			default:
				
				target = cast targetName.toLowerCase ();
			
		}
		
		var config = getHXCPPConfig ();
		
		if (config != null) {
			
			for (define in config.defines.keys ()) {
				
				if (define == define.toUpperCase ()) {
					
					var value = config.defines.get (define);
					
					switch (define) {
						
						case "ANT_HOME":
							
							if (value == "/usr") {
								
								value = "/usr/share/ant";
								
							}
							
							if (FileSystem.exists (value)) {
								
								Sys.putEnv (define, value);
								
							}
							
						case "JAVA_HOME":
							
							if (FileSystem.exists (value)) {
								
								Sys.putEnv (define, value);
								
							}
						
						default:
							
							Sys.putEnv (define, value);
						
					}
					
				}
				
			}
			
		}
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			if (Sys.getEnv ("JAVA_HOME") != null) {
				
				var javaPath = PathHelper.combine (Sys.getEnv ("JAVA_HOME"), "bin");
				
				if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
					
					Sys.putEnv ("PATH", javaPath + ";" + Sys.getEnv ("PATH"));
					
				} else {
					
					Sys.putEnv ("PATH", javaPath + ":" + Sys.getEnv ("PATH"));
					
				}
				
			}
			
		}
		
		if (project == null) {
			
			HXProject._command = command;
			HXProject._debug = debug;
			HXProject._target = target;
			HXProject._targetFlags = targetFlags;
			
			try { Sys.setCwd (Path.directory (projectFile)); } catch (e:Dynamic) {}
			
			if (Path.extension (projectFile) == "lime" || Path.extension (projectFile) == "nmml" || Path.extension (projectFile) == "xml") {
				
				project = new ProjectXMLParser (Path.withoutDirectory (projectFile), userDefines, includePaths);
				
			} else if (Path.extension (projectFile) == "hxp") {
				
				project = HXProject.fromFile (projectFile, userDefines, includePaths);
				
				if (project != null) {
					
					project.command = command;
					project.debug = debug;
					project.target = target;
					project.targetFlags = targetFlags;
					
				} else {
					
					LogHelper.error ("Could not process \"" + projectFile + "\"");
					return null;
					
				}
				
			}
			
		}
		
		if (project == null) {
			
			LogHelper.error ("You must have a \"project.xml\" file or specify another valid project file when using the '" + command + "' command");
			return null;
			
		}
		
		project.merge (config);
		
		project.haxedefs.set ("tools", version);
		
		/*if (userDefines.exists ("nme")) {
			
			project.haxedefs.set ("nme_install_tool", 1);
			project.haxedefs.set ("nme_ver", version);
			project.haxedefs.set ("nme" + version.split (".")[0], 1);
			
			project.config.cpp.buildLibrary = "hxcpp";
			project.config.cpp.requireBuild = false;
			
		}*/
		
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
				
				getBuildNumber (project, (project.command == "build" || project.command == "test"));
				
			default:
			
		}
		
		return project;
		
	}
	
	
	public static function main ():Void {
		
		new CommandLineTools ();
		
	}
	
	
	private function platformSetup ():Void {
		
		LogHelper.info ("", LogHelper.accentColor + "Running command: SETUP" + LogHelper.resetColor);
		
		if (words.length == 0) {
			
			PlatformSetup.run ("", userDefines, targetFlags);
			
		} else if (words.length == 1) {
			
			PlatformSetup.run (words[0], userDefines, targetFlags);
			
		} else {
			
			LogHelper.error ("Incorrect number of arguments for command 'setup'");
			return;
			
		}
		
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
						
						var i = 0;
						
						overrides.haxelibs.push (new Haxelib (name, version));
						
					} else if (StringTools.startsWith (field, "haxelib-")) {
						
						var name = field.substr (8);
						PathHelper.haxelibOverrides.set (name, PathHelper.tryFullPath (argValue));
						
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
						
					} else if (field == "build-library") {
						
						overrides.config.set ("cpp.buildLibrary", argValue);
						
					} else if (field == "device") {
						
						targetFlags.set ("device", argValue);
						
					} else {
						
						projectDefines.set (field, argValue);
						
					}
					
				} else {
					
					userDefines.set (argument.substr (0, equals), argValue);
					
				}
				
			} else if (argument.substr (0, 2) == "-D") {
				
				userDefines.set (argument.substr (2), "");
				
			} else if (argument.substr (0, 2) == "-I") {
				
				includePaths.push (argument.substr (2));
				
			} else if (argument == "-args") {
				
				catchArguments = true;
				
			} else if (argument.substr (0, 1) == "-") {
				
				if (argument.substr (1, 1) == "-") {
					
					overrides.haxeflags.push (argument);
					
					if (argument == "--remap" || argument == "--connect") {
						
						catchHaxeFlag = true;
						
					}
					
				} else {
					
					if (argument.substr (0, 4) == "-arm") {
						
						var name = argument.substr (1).toUpperCase ();
						var value = Type.createEnum (Architecture, name);
						
						if (value != null) {
							
							overrides.architectures.push (value);
							
						}
						
					} else if (argument == "-64") {
						
						overrides.architectures.push (Architecture.X64);
						
					} else if (argument == "-32") {
						
						overrides.architectures.push (Architecture.X86);
						
					} else if (argument == "-v" || argument == "-verbose") {
						
						argument = "-verbose";
						LogHelper.verbose = true;
						
					} else if (argument == "-dryrun") {
						
						ProcessHelper.dryRun = true;
						
					} else if (argument == "-notrace") {
						
						traceEnabled = false;
						
					} else if (argument == "-debug") {
						
						debug = true;
						
					} else if (argument == "-nocolor") {
						
						LogHelper.enableColor = false;
						
					}
					
					targetFlags.set (argument.substr (1), "");
					
				}
				
			} else if (command.length == 0) {
				
				command = argument;
				
			} else {
				
				words.push (argument);
				
			}
			
		}
		
	}
	
	
	private function publishProject () {
		
		switch (words[words.length - 1]) {
			
			case "firefox":
				
				var project = initializeProject (null, "firefox");
				
				LogHelper.info ("", LogHelper.accentColor + "Using publishing target: FIREFOX MARKETPLACE" + LogHelper.resetColor);
				
				if (FirefoxMarketplace.isValid (project)) {
					
					buildProject (project, "build");
					
					LogHelper.info ("", "\n" + LogHelper.accentColor + "Running command: PUBLISH" + LogHelper.resetColor);
					
					FirefoxMarketplace.publish (project);
					
				}
			
		}
		
	}
	
	
	private function updateLibrary ():Void {
		
		if ((words.length < 1 && command != "upgrade") || words.length > 1) {
			
			LogHelper.error ("Incorrect number of arguments for command '" + command + "'");
			return;
			
		}
		
		LogHelper.info ("", LogHelper.accentColor + "Running command: " + command.toUpperCase () + LogHelper.resetColor);
		
		var name = defaultLibrary;
		
		if (words.length > 0) {
			
			name = words[0];
			
		}
		
		var haxelib = new Haxelib (name);
		var path = PathHelper.getHaxelib (haxelib);
		
		switch (command) {
			
			case "install":
				
				if (path == null || path == "") {
					
					PlatformSetup.installHaxelib (haxelib);
					
				} else {
					
					PlatformSetup.updateHaxelib (haxelib);
					
				}
				
				PlatformSetup.setupHaxelib (haxelib);
			
			case "remove":
				
				if (path != null && path != "") {
					
					ProcessHelper.runCommand ("", "haxelib", [ "remove", name ]);
					
				}
			
			case "upgrade":
				
				if (path != null && path != "") {
					
					PlatformSetup.updateHaxelib (haxelib);
					PlatformSetup.setupHaxelib (haxelib);
					
				} else {
					
					LogHelper.warn ("\"" + haxelib.name + "\" is not a valid haxelib, or has not been installed");
					
				}
			
		}
		
	}
	
	
}
