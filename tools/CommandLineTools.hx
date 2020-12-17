package;

// import openfl.text.Font;
// import openfl.utils.ByteArray;
// import openfl.utils.CompressionAlgorithm;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.rtti.Meta;
import hxp.*;
import lime.system.CFFI;
import lime.tools.HXProject;
import lime.tools.*;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;
import utils.publish.*;
import utils.CreateTemplate;
import utils.JavaExternGenerator;
import utils.PlatformSetup;

@:access(lime.tools.HXProject)
class CommandLineTools
{
	public static var commandName = "lime";
	public static var defaultLibrary = "lime";
	public static var defaultLibraryName = "Lime";

	private var additionalArguments:Array<String>;
	private var command:String;
	private var debug:Bool;
	private var environment:Map<String, String>;
	private var includePaths:Array<String>;
	private var overrides:HXProject;
	private var project:HXProject;
	private var projectDefines:Map<String, String>;
	private var runFromHaxelib:Bool;
	private var targetFlags:Map<String, String>;
	private var traceEnabled:Bool;
	private var userDefines:Map<String, Dynamic>;
	private var version:String;
	private var words:Array<String>;

	public function new()
	{
		additionalArguments = new Array<String>();
		command = "";
		debug = false;
		environment = Sys.environment();
		includePaths = new Array<String>();
		projectDefines = new Map<String, String>();
		targetFlags = new Map<String, String>();
		traceEnabled = true;
		userDefines = new Map<String, Dynamic>();
		words = new Array<String>();

		overrides = new HXProject();
		overrides.architectures = [];

		// Haxelib.setOverridePath (new Haxelib ("lime-tools"), Path.combine (Haxelib.getPath (new Haxelib ("lime")), "tools"));

		processArguments();
		version = Haxelib.getVersion();

		if (targetFlags.exists("openfl"))
		{
			Log.accentColor = "\x1b[36;1m";
			commandName = "openfl";
			defaultLibrary = "openfl";
			defaultLibraryName = "OpenFL";
		}

		if (command == "" && targetFlags.exists("help"))
		{
			command = "help";
		}

		if (Log.verbose && command != "help" && command != "")
		{
			displayInfo();
			Sys.println("");
		}

		switch (command)
		{
			case "":
				if (targetFlags.exists("version"))
				{
					Sys.println(getToolsVersion());
					return;
				}

				displayInfo(true);

			case "help":
				displayHelp();

			case "config":
				displayConfig();

			case "setup":
				platformSetup();

			case "document":
				document();

			case "generate":
				generate();

			case "compress":
				compress();

			case "create":
				createTemplate();

			case "install", "remove", "upgrade":
				updateLibrary();

			case "clean", "update", "display", "build", "run", "rerun", /*"install",*/ "uninstall", "trace", "test", "deploy":
				if (words.length < 1 || words.length > 2)
				{
					Log.error("Incorrect number of arguments for command '" + command + "'");
					return;
				}

				var project = initializeProject();
				buildProject(project);

			case "rebuild":
				if (words.length < 1 || words.length > 2)
				{
					Log.error("Incorrect number of arguments for command '" + command + "'");
					return;
				}

				if (words.length == 1)
				{
					var haxelibPath = Haxelib.getPath(new Haxelib(words[0]), false);

					if (haxelibPath != "" && haxelibPath != null)
					{
						words.push("tools");
					}
				}

				if (words.length < 2)
				{
					if (targetFlags.exists("openfl"))
					{
						words.unshift("openfl");
					}
					else
					{
						words.unshift("lime");
					}
				}

				var targets = words[1].split(",");

				var haxelib = null;
				var path = null;
				var hxmlPath = null;
				var project = null;

				if (!FileSystem.exists(words[0]))
				{
					var fullPath = Path.tryFullPath(words[0]);

					if (FileSystem.exists(fullPath))
					{
						path = Path.combine(fullPath, "project");
						hxmlPath = Path.combine(fullPath, "rebuild.hxml");
					}
					else
					{
						haxelib = new Haxelib(words[0]);
					}
				}
				else
				{
					if (FileSystem.isDirectory(words[0]))
					{
						if (FileSystem.exists(Path.combine(words[0], "Build.xml")))
						{
							path = words[0];
						}
						else
						{
							path = Path.combine(words[0], "project/Build.xml");
						}

						hxmlPath = Path.combine(words[0], "rebuild.hxml");
					}
					else
					{
						path = words[0];

						if (Path.extension(words[0]) == "hxml")
						{
							hxmlPath = words[0];
						}
					}

					var haxelibPath = Haxelib.getPath(new Haxelib(words[0]));

					if (!FileSystem.exists(path) && haxelibPath != null)
					{
						haxelib = new Haxelib(words[0]);
					}
				}

				if (haxelib != null)
				{
					var haxelibPath = Haxelib.getPath(haxelib, true);

					switch (haxelib.name)
					{
						case "hxcpp":
							hxmlPath = Path.combine(haxelibPath, "tools/hxcpp/compile.hxml");

						case "haxelib":
							hxmlPath = Path.combine(haxelibPath, "../client.hxml");

						default:
							hxmlPath = Path.combine(haxelibPath, "rebuild.hxml");
					}
				}

				for (targetName in targets)
				{
					var target:Platform = null;

					switch (targetName)
					{
						case "cpp":
							target = cast System.hostPlatform;
							targetFlags.set("cpp", "");

						case "neko":
							target = cast System.hostPlatform;
							targetFlags.set("neko", "");

						case "hl", "hashlink":
							target = cast System.hostPlatform;
							targetFlags.set("hl", "");

						case "cppia":
							target = cast System.hostPlatform;
							targetFlags.set("cppia", "");

						case "java":
							target = cast System.hostPlatform;
							targetFlags.set("java", "");

						case "nodejs":
							target = cast System.hostPlatform;
							targetFlags.set("nodejs", "");

						case "cs":
							target = cast System.hostPlatform;
							targetFlags.set("cs", "");

						case "iphone", "iphoneos":
							target = Platform.IOS;

						case "iphonesim":
							target = Platform.IOS;
							targetFlags.set("simulator", "");

						case "electron":
							target = Platform.HTML5;
							targetFlags.set("electron", "");

						case "firefox", "firefoxos":
							target = Platform.FIREFOX;
							overrides.haxedefs.set("firefoxos", "");

						case "appletv", "appletvos":
							target = Platform.TVOS;

						case "appletvsim":
							target = Platform.TVOS;
							targetFlags.set("simulator", "");

						case "mac", "macos":
							target = Platform.MAC;

						case "rpi", "raspberrypi":
							target = Platform.LINUX;
							targetFlags.set("rpi", "");

						case "webassembly", "wasm":
							target = Platform.EMSCRIPTEN;
							targetFlags.set("webassembly", "");

						default:
							target = cast targetName.toLowerCase();
					}

					if (target == cast "tools")
					{
						if (hxmlPath != null && FileSystem.exists(hxmlPath))
						{
							var cacheValue = Sys.getEnv("HAXELIB_PATH");
							Sys.putEnv("HAXELIB_PATH", Haxelib.getRepositoryPath());

							System.runCommand(Path.directory(hxmlPath), "haxe", [Path.withoutDirectory(hxmlPath)]);

							if (cacheValue != null)
							{
								Sys.putEnv("HAXELIB_PATH", cacheValue);
							}
						}
					}
					else
					{
						HXProject._command = command;
						HXProject._environment = environment;
						HXProject._debug = debug;
						HXProject._target = target;
						HXProject._targetFlags = targetFlags;
						HXProject._userDefines = userDefines;

						var project = null;

						if (haxelib != null)
						{
							userDefines.set("rebuild", 1);
							project = HXProject.fromHaxelib(haxelib, userDefines);

							if (project == null)
							{
								project = new HXProject();
								project.config.set("project.rebuild.path", Path.combine(Haxelib.getPath(haxelib), "project"));
							}
							else
							{
								project.config.set("project.rebuild.path", Path.combine(Haxelib.getPath(haxelib), project.config.get("project.rebuild.path")));
							}
						}
						else
						{
							// project =  HXProject.fromPath (path);

							if (project == null)
							{
								project = new HXProject();

								if (FileSystem.isDirectory(path))
								{
									project.config.set("project.rebuild.path", path);
								}
								else
								{
									project.config.set("project.rebuild.path", Path.directory(path));
									project.config.set("project.rebuild.file", Path.withoutDirectory(path));
								}
							}
						}

						// this needs to be improved

						var rebuildPath = project.config.get("project.rebuild.path");
						var rebuildFile = project.config.get("project.rebuild.file");

						project.merge(overrides);

						for (haxelib in overrides.haxelibs)
						{
							var includeProject = HXProject.fromHaxelib(haxelib, project.defines);

							if (includeProject != null)
							{
								for (ndll in includeProject.ndlls)
								{
									if (ndll.haxelib == null)
									{
										ndll.haxelib = haxelib;
									}
								}

								project.merge(includeProject);
							}
						}

						project.config.set("project.rebuild.path", rebuildPath);
						project.config.set("project.rebuild.file", rebuildFile);

						// TODO: Fix use of initialize without resetting reference?

						project = initializeProject(project, targetName);
						buildProject(project);

						if (Log.verbose)
						{
							Log.println("");
						}
					}
				}

			case "publish":
				if (words.length < 1 || words.length > 2)
				{
					Log.error("Incorrect number of arguments for command '" + command + "'");
					return;
				}

				publishProject();

			case "installer", "copy-if-newer":

			// deprecated?

			default:
				Log.error("'" + command + "' is not a valid command");
		}
	}

	#if neko
	public static function __init__():Void
	{
		var args = Sys.args();

		if (args.length > 0 && args[0].toLowerCase() == "rebuild")
		{
			CFFI.enabled = false;
		}

		for (arg in args)
		{
			// TODO: Allow -rebuild without locking native binary?

			if (arg == "-nocffi" || arg == "-rebuild")
			{
				CFFI.enabled = false;
			}
		}

		var path = "";

		if (FileSystem.exists("tools.n"))
		{
			path = Path.combine(Sys.getCwd(), "../ndll/");
		}
		else if (FileSystem.exists("run.n"))
		{
			path = Sys.getCwd() + "/ndll/";
		}

		if (path == "")
		{
			var process = new Process("haxelib", ["path", "lime"]);

			try
			{
				while (true)
				{
					var line = StringTools.trim(process.stdout.readLine());

					if (StringTools.startsWith(line, "-L "))
					{
						path = StringTools.trim(line.substr(2));
						break;
					}
				}
			}
			catch (e:Dynamic) {}

			process.close();
		}

		switch (System.hostPlatform)
		{
			case WINDOWS:
				// var is64 = neko.Lib.load("std", "sys_is64", 0)();
				untyped $loader.path = $array(path + "Windows/", $loader.path);
				if (CFFI.enabled)
				{
					try
					{
						neko.Lib.load("lime", "lime_application_create", 0);
					}
					catch (e:Dynamic)
					{
						untyped $loader.path = $array(path + "Windows64/", $loader.path);
					}
				}

			case MAC:
				// if (System.hostArchitecture == X64) {

				untyped $loader.path = $array(path + "Mac64/", $loader.path);

			// } else {

			//	untyped $loader.path = $array (path + "Mac/", $loader.path);

			// }

			case LINUX:
				var arguments = Sys.args();
				var raspberryPi = false;

				for (argument in arguments)
				{
					if (argument == "-rpi") raspberryPi = true;
				}

				if (raspberryPi || System.hostArchitecture == ARMV6 || System.hostArchitecture == ARMV7)
				{
					untyped $loader.path = $array(path + "RPi/", $loader.path);
				}
				else if (System.hostArchitecture == X64)
				{
					untyped $loader.path = $array(path + "Linux64/", $loader.path);
				}
				else
				{
					untyped $loader.path = $array(path + "Linux/", $loader.path);
				}

			default:
		}
	}
	#end

	private function buildProject(project:HXProject, command:String = "")
	{
		if (command == "")
		{
			command = project.command.toLowerCase();
		}

		if (project.targetHandlers.exists(Std.string(project.target)))
		{
			if (command == "build" || command == "test")
			{
				CommandHelper.executeCommands(project.preBuildCallbacks);
			}

			Log.info("", Log.accentColor + "Using target platform: " + Std.string(project.target).toUpperCase() + "\x1b[0m");

			var handler = project.targetHandlers.get(Std.string(project.target));
			var projectData = Serializer.run(project);
			var temporaryFile = System.getTemporaryFile();
			File.saveContent(temporaryFile, projectData);

			var targetDir = Haxelib.getPath(new Haxelib(handler));
			var exePath = Path.join([targetDir, "run.exe"]);
			var exeExists = FileSystem.exists(exePath);

			var args = [command, temporaryFile];

			if (Log.verbose) args.push("-verbose");
			if (!Log.enableColor) args.push("-nocolor");
			if (!traceEnabled) args.push("-notrace");

			if (additionalArguments.length > 0)
			{
				args.push("-args");
				args = args.concat(additionalArguments);
			}

			if (exeExists)
			{
				System.runCommand("", exePath, args);
			}
			else
			{
				Haxelib.runCommand("", ["run", handler].concat(args));
			}

			try
			{
				FileSystem.deleteFile(temporaryFile);
			}
			catch (e:Dynamic) {}

			if (command == "build" || command == "test")
			{
				CommandHelper.executeCommands(project.postBuildCallbacks);
			}
		}
		else
		{
			var platform:PlatformTarget = null;

			switch (project.target)
			{
				case ANDROID:
					platform = new AndroidPlatform(command, project, targetFlags);

				case BLACKBERRY:

				// platform = new BlackBerryPlatform (command, project, targetFlags);

				case IOS:
					platform = new IOSPlatform(command, project, targetFlags);

				case TIZEN:

				// platform = new TizenPlatform (command, project, targetFlags);

				case WEBOS:

				// platform = new WebOSPlatform (command, project, targetFlags);

				case WINDOWS:
					platform = new WindowsPlatform(command, project, targetFlags);

				case MAC:
					platform = new MacPlatform(command, project, targetFlags);

				case LINUX:
					platform = new LinuxPlatform(command, project, targetFlags);

				case FLASH:
					platform = new FlashPlatform(command, project, targetFlags);

				case HTML5:
					platform = new HTML5Platform(command, project, targetFlags);

				// case FIREFOX:

				// 	platform = new FirefoxPlatform (command, project, targetFlags);

				case EMSCRIPTEN:
					platform = new EmscriptenPlatform(command, project, targetFlags);

				case TVOS:
					platform = new TVOSPlatform(command, project, targetFlags);

				case AIR:
					platform = new AIRPlatform(command, project, targetFlags);

				default:
			}

			if (platform != null)
			{
				platform.traceEnabled = traceEnabled;
				platform.execute(additionalArguments);
			}
			else
			{
				Log.error("\"" + Std.string(project.target) + "\" is an unknown target");
			}
		}
	}

	private function compress()
	{
		if (words.length > 0)
		{
			// var bytes = new ByteArray ();
			// bytes.writeUTFBytes (words[0]);
			// bytes.compress (CompressionAlgorithm.LZMA);
			// Sys.print (bytes.toString ());
			// File.saveBytes (words[0] + ".compress", bytes);
		}
	}

	private function createTemplate()
	{
		Log.info("", Log.accentColor + "Running command: CREATE\x1b[0m");

		if (words.length > 0)
		{
			var colonIndex = words[0].indexOf(":");

			var projectName = null;
			var sampleName = null;

			if (colonIndex == -1)
			{
				projectName = words[0];

				if (words.length > 1)
				{
					sampleName = words[1];
				}
			}
			else
			{
				projectName = words[0].substring(0, colonIndex);
				sampleName = words[0].substr(colonIndex + 1);
			}

			if (projectName == "project" || sampleName == "project")
			{
				CreateTemplate.createProject(words, userDefines, overrides);
			}
			else if (projectName == "extension" || sampleName == "extension")
			{
				CreateTemplate.createExtension(words, userDefines);
			}
			else
			{
				if (sampleName == null)
				{
					var sampleExists = false;
					var defines = new Map<String, Dynamic>();
					defines.set("create", 1);
					var project = HXProject.fromHaxelib(new Haxelib(defaultLibrary), defines);

					for (samplePath in project.samplePaths)
					{
						if (FileSystem.exists(Path.combine(samplePath, projectName)))
						{
							sampleExists = true;
						}
					}

					if (sampleExists)
					{
						CreateTemplate.createSample(words, userDefines);
					}
					else if (Haxelib.getPath(new Haxelib(projectName)) != "")
					{
						CreateTemplate.listSamples(projectName, userDefines);
					}
					else if (projectName == "" || projectName == null)
					{
						CreateTemplate.listSamples(defaultLibrary, userDefines);
					}
					else
					{
						CreateTemplate.listSamples(null, userDefines);
					}
				}
				else
				{
					CreateTemplate.createSample(words, userDefines);
				}
			}
		}
		else
		{
			CreateTemplate.listSamples(defaultLibrary, userDefines);
		}
	}

	private function displayConfig():Void
	{
		if (words.length == 0)
		{
			Log.println(File.getContent(ConfigHelper.getConfigPath()));
		}
		else if (words.length == 1)
		{
			var value = ConfigHelper.getConfigValue(words[0]);

			if (value != null)
			{
				Log.println(value);
			}
			else
			{
				Log.error("\"" + words[0] + "\" is undefined");
			}
		}
		else
		{
			var name = words.shift();
			var value = words.join(" ");

			if (name == "remove")
			{
				ConfigHelper.removeConfigValue(value);
			}
			else
			{
				ConfigHelper.writeConfigValue(name, value);
			}
		}
	}

	private function displayHelp():Void
	{
		var commands = [

			         "config" => "Display or set command-line configuration values",    "create" => "Create a new project or extension using templates",
			                    "clean" => "Clean the specified project and target",     "update" => "Copy assets for the specified project and target",
			  "build" => "Compile and package for the specified project and target",    "run" => "Install and run for the specified project and target",
			                       "test" => "Update, build and run in one command",                                  "help" => "Show this information",
			          "trace" => "Trace output for the specifed project and target",                            "deploy" => "Archive and upload builds",
			"display" => "Display information for the specified project and target",             "rebuild" => "Recompile native binaries for libraries",
			       "install" => "Install a library from haxelib, plus dependencies",                        "remove" => "Remove a library from haxelib",
			                          "upgrade" => "Upgrade a library from haxelib", "setup" => "Setup " + defaultLibraryName + " or a specific platform"

		];

		var basicCommands = ["config", "create", "clean", "update", "build", "run", "test", "help"];
		var additionalCommands = ["trace", "deploy", "display", "rebuild", "install", "remove", "upgrade", "setup"];

		if (targetFlags.exists("openfl"))
		{
			commands.set("process", "Process a SWF asset for use with " + defaultLibraryName);
			additionalCommands.push("process");
		}

		var command = (words.length > 0 ? words[0] : "");
		var isProjectCommand = false, isBuildCommand = false;

		if (commands.exists(command))
		{
			Log.println("\x1b[1m" + commands.get(command) + "\x1b[0m");
			Log.println("");
		}

		switch (command)
		{
			case "setup":
				Log.println(" "
					+ Log.accentColor
					+ "Usage:\x1b[0m \x1b[1m"
					+ commandName
					+ " setup\x1b[0m \x1b[3;37m(target)\x1b[0m \x1b[3;37m[options]\x1b[0m");

			case "clean", "update", "build", "run", "test", "display", "deploy", "trace":
				Log.println(" "
					+ Log.accentColor
					+ "Usage:\x1b[0m \x1b[1m"
					+ commandName
					+ " "
					+ command
					+ "\x1b[0m \x1b[3;37m(project)\x1b[0m \x1b[1m<target>\x1b[0m \x1b[3;37m[options]\x1b[0m");
				isProjectCommand = true;
				isBuildCommand = true;

			case "create":
				Log.println(" "
					+ Log.accentColor
					+ "Usage:\x1b[0m \x1b[1m"
					+ commandName
					+ " create\x1b[0m \x1b[3;37m(library)\x1b[0m \x1b[1mproject\x1b[0m \x1b[3;37m(directory)\x1b[0m \x1b[3;37m[options]\x1b[0m");
				Log.println(" "
					+ Log.accentColor
					+ "Usage:\x1b[0m \x1b[1m"
					+ commandName
					+ " create\x1b[0m \x1b[3;37m(library)\x1b[0m \x1b[1mextension\x1b[0m \x1b[3;37m(directory)\x1b[0m \x1b[3;37m[options]\x1b[0m");
				Log.println(" "
					+ Log.accentColor
					+ "Usage:\x1b[0m \x1b[1m"
					+ commandName
					+ " create\x1b[0m \x1b[3;37m(library)\x1b[0m \x1b[1m<sample>\x1b[0m \x1b[3;37m(directory)\x1b[0m \x1b[3;37m[options]\x1b[0m");

			case "rebuild":
				Log.println(" "
					+ Log.accentColor
					+ "Usage:\x1b[0m \x1b[1m"
					+ commandName
					+ " rebuild\x1b[0m \x1b[3;37m(library)\x1b[0m \x1b[3;37m(target)\x1b[0m \x1b[3;37m[options]\x1b[0m");
				isBuildCommand = true;

			case "config":
				Log.println(" "
					+ Log.accentColor
					+ "Usage:\x1b[0m \x1b[1m"
					+ commandName
					+ " config\x1b[0m \x1b[3;37m(name)\x1b[0m \x1b[3;37m(value)\x1b[0m \x1b[3;37m[options]\x1b[0m");
				Log.println(" "
					+ Log.accentColor
					+ "Usage:\x1b[0m \x1b[1m"
					+ commandName
					+ " config remove <name>\x1b[0m \x1b[3;37m[options]\x1b[0m");

			case "install", "remove", "upgrade":
				Log.println(" "
					+ Log.accentColor
					+ "Usage:\x1b[0m \x1b[1m"
					+ commandName
					+ " "
					+ command
					+ "\x1b[0m \x1b[3;37m(library)\x1b[0m \x1b[3;37m[options]\x1b[0m");

			case "process":
				Log.println(" "
					+ Log.accentColor
					+ "Usage:\x1b[0m \x1b[1m"
					+ commandName
					+ " process <file>\x1b[0m \x1b[3;37m(directory)\x1b[0m \x1b[3;37m[options]\x1b[0m");

			default:
				displayInfo();

				Log.println("");
				Log.println(" " + Log.accentColor + "Usage:\x1b[0m \x1b[1m" + commandName + " <command>\x1b[0m \x1b[3;37m[arguments]\x1b[0m");
				Log.println("");
				Log.println(" " + Log.accentColor + "Basic Commands:" + Log.resetColor);
				Log.println("");

				for (command in basicCommands)
				{
					Log.println("  \x1b[1m" + command + "\x1b[0m -- " + commands.get(command));
				}

				Log.println("");
				Log.println(" " + Log.accentColor + "Additional Commands:" + Log.resetColor);
				Log.println("");

				for (command in additionalCommands)
				{
					Log.println("  \x1b[1m" + command + "\x1b[0m -- " + commands.get(command));
				}

				Log.println("");
				Log.println("For additional help, run \x1b[1m" + commandName + " help <command>\x1b[0m");

				return;
		}

		if (isBuildCommand || command == "setup")
		{
			Log.println("");
			Log.println(" " + Log.accentColor + "Targets:" + Log.resetColor);
			Log.println("");
			Log.println("  \x1b[1mair\x1b[0m -- Create an AIR application");
			Log.println("  \x1b[1mandroid\x1b[0m -- Create an Android application");
			// Log.println ("  \x1b[1mblackberry\x1b[0m -- Create a BlackBerry application");
			Log.println("  \x1b[1memscripten\x1b[0m -- Create an Emscripten application");
			Log.println("  \x1b[1mflash\x1b[0m -- Create a Flash SWF application");
			Log.println("  \x1b[1mhtml5\x1b[0m -- Create an HTML5 application");
			Log.println("  \x1b[1mios\x1b[0m -- Create an iOS application");
			Log.println("  \x1b[1mlinux\x1b[0m -- Create a Linux application");
			Log.println("  \x1b[1mmac\x1b[0m -- Create a macOS application");
			// Log.println ("  \x1b[1mtizen\x1b[0m -- Create a Tizen application");
			Log.println("  \x1b[1mtvos\x1b[0m -- Create a tvOS application");
			// Log.println ("  \x1b[1mwebos\x1b[0m -- Create a webOS application");
			Log.println("  \x1b[1mwindows\x1b[0m -- Create a Windows application");

			Log.println("");
			Log.println(" " + Log.accentColor + "Target Aliases:" + Log.resetColor);
			Log.println("");
			Log.println("  \x1b[1mcpp\x1b[0m -- Alias for host platform (using \x1b[1m-cpp\x1b[0m)");
			Log.println("  \x1b[1mneko\x1b[0m -- Alias for host platform (using \x1b[1m-neko\x1b[0m)");
			Log.println("  \x1b[1mmacos\x1b[0m -- Alias for \x1b[1mmac\x1b[0m");
			Log.println("  \x1b[1mnodejs\x1b[0m -- Alias for host platform (using \x1b[1m-nodejs\x1b[0m)");
			Log.println("  \x1b[1mjava\x1b[0m -- Alias for host platform (using \x1b[1m-java\x1b[0m)");
			Log.println("  \x1b[1mcs\x1b[0m -- Alias for host platform (using \x1b[1m-cs\x1b[0m)");
			Log.println("  \x1b[1mhl/hashlink\x1b[0m -- Alias for host platform (using \x1b[1m-hl\x1b[0m)");
			#if (lime >= "7.6.0")
			// Log.println("  \x1b[1mcppia\x1b[0m -- Alias for host platform (using \x1b[1m-cppia\x1b[0m)");
			#end
			Log.println("  \x1b[1muwp\x1b[0;3m/\x1b[0m\x1b[1mwinjs\x1b[0m -- Alias for \x1b[1mwindows -uwp\x1b[0m");
			// Log.println ("  \x1b[1miphone\x1b[0;3m/\x1b[0m\x1b[1miphoneos\x1b[0m -- \x1b[1mios\x1b[0m");
			// Log.println ("  \x1b[1miphonesim\x1b[0m -- Alias for \x1b[1mios -simulator\x1b[0m");
			// Log.println ("  \x1b[1mappletv\x1b[0;3m/\x1b[0m\x1b[1mappletvos\x1b[0m -- Alias for \x1b[1mtvos\x1b[0m");
			// Log.println ("  \x1b[1mappletvsim\x1b[0m -- Alias for \x1b[1mtvos -simulator\x1b[0m");
			Log.println("  \x1b[1mrpi\x1b[0;3m/\x1b[0m\x1b[1mraspberrypi\x1b[0m -- Alias for \x1b[1mlinux -rpi\x1b[0m");
			Log.println("  \x1b[1melectron\x1b[0m -- Alias for \x1b[1mhtml5 -electron\x1b[0m");
			Log.println("  \x1b[1mwebassembly\x1b[0;3m/\x1b[0m\x1b[1mwasm\x1b[0m -- Alias for \x1b[1memscripten -webassembly\x1b[0m");
		}

		Log.println("");
		Log.println(" " + Log.accentColor + "Options:" + Log.resetColor);
		Log.println("");

		if (isBuildCommand)
		{
			Log.println("  \x1b[1m-D\x1b[0;3mvalue\x1b[0m -- Specify a define to use when processing other commands");
			Log.println("  \x1b[1m-debug\x1b[0m -- Use debug configuration instead of release");
			Log.println("  \x1b[1m-final\x1b[0m -- Use final configuration instead of release");
		}

		Log.println("  \x1b[1m-v\x1b[0;3m/\x1b[0m\x1b[1m-verbose\x1b[0m -- Print additional information (when available)");

		if (isBuildCommand && command != "run" && command != "trace")
		{
			Log.println("  \x1b[1m-clean\x1b[0m -- Add a \"clean\" action before running the current command");
		}

		Log.println("  \x1b[1m-nocolor\x1b[0m -- Disable ANSI format codes in output");

		if (command == "run" || command == "test")
		{
			Log.println("  \x1b[1m-notrace\x1b[0m -- Disable trace output during run or test command");
		}

		Log.println("  \x1b[1m-dryrun\x1b[0m -- Execute the requested command without making changes");

		if (isProjectCommand && command != "run" && command != "trace")
		{
			Log.println("  \x1b[1m-xml\x1b[0m -- Generate XML type information, useful for documentation");
		}

		if (command == "run" || command == "test")
		{
			Log.println("  \x1b[1m--\x1b[0;3m/\x1b[0m\x1b[1m-args\x1b[0m ... -- Pass additional arguments at launch");
		}

		if (isProjectCommand)
		{
			Log.println("  \x1b[3m(windows|mac|linux)\x1b[0m \x1b[1m-cpp\x1b[0m -- Build with C++ (default behavior)");
			Log.println("  \x1b[3m(windows|mac|linux)\x1b[0m \x1b[1m-neko\x1b[0m -- Build with Neko instead of C++");
			Log.println("  \x1b[3m(windows|mac|ios|android)\x1b[0m \x1b[1m-air\x1b[0m -- Build with AIR instead of C++");
		}

		if (isBuildCommand)
		{
			Log.println("  \x1b[3m(windows|mac|linux|android)\x1b[0m \x1b[1m-static\x1b[0m -- Compile as a static C++ executable");
			Log.println("  \x1b[3m(windows|mac|linux)\x1b[0m \x1b[1m-32\x1b[0m -- Compile for 32-bit instead of the OS default");
			Log.println("  \x1b[3m(windows|mac|linux)\x1b[0m \x1b[1m-64\x1b[0m -- Compile for 64-bit instead of the OS default");
			Log.println("  \x1b[3m(ios|android)\x1b[0m \x1b[1m-armv6\x1b[0m -- Compile for ARMv6 instead of the OS defaults");
			Log.println("  \x1b[3m(ios|android)\x1b[0m \x1b[1m-armv7\x1b[0m -- Compile for ARMv7 instead of the OS defaults");
			Log.println("  \x1b[3m(ios|android)\x1b[0m \x1b[1m-armv7s\x1b[0m -- Compile for ARMv7s instead of the OS defaults");
			Log.println("  \x1b[3m(ios)\x1b[0m \x1b[1m-arm64\x1b[0m -- Compile for ARM64 instead of the OS defaults");
		}

		if (isProjectCommand)
		{
			Log.println("  \x1b[3m(ios)\x1b[0m \x1b[1m-archive\x1b[0m -- Generate iOS archive during build");
		}

		if (isProjectCommand)
		{
			if (command != "run" && command != "trace")
			{
				Log.println("  \x1b[3m(ios)\x1b[0m \x1b[1m-xcode\x1b[0m -- Launch the generated Xcode project");
			}

			// Log.println ("  \x1b[3m(ios|blackberry|tizen|tvos|webos)\x1b[0m \x1b[1m-simulator\x1b[0m -- Target the device simulator");
			Log.println("  \x1b[3m(ios|tvos)\x1b[0m \x1b[1m-simulator\x1b[0m -- Target the device simulator");
			Log.println("  \x1b[3m(ios)\x1b[0m \x1b[1m-simulator -ipad\x1b[0m -- Build/test for the iPad Simulator");
			Log.println("  \x1b[3m(android)\x1b[0m \x1b[1m-emulator\x1b[0m -- Target the device emulator");
			Log.println("  \x1b[3m(html5)\x1b[0m \x1b[1m-npm\x1b[0m -- Target HTML5 using an NPM project structure");
			Log.println("  \x1b[3m(flash)\x1b[0m \x1b[1m-web\x1b[0m -- Test Flash target using a web template");
			Log.println("  \x1b[3m(air)\x1b[0m \x1b[1m-ios\x1b[0m -- Target iOS instead of AIR desktop");
			Log.println("  \x1b[3m(air)\x1b[0m \x1b[1m-android\x1b[0m -- Target Android instead of AIR desktop");

			if (command != "run" && command != "trace")
			{
				Log.println("  \x1b[3m(emscripten)\x1b[0m \x1b[1m-webassembly\x1b[0m -- Compile for WebAssembly instead of asm.js");
				Log.println("  \x1b[3m(emscripten|html5)\x1b[0m \x1b[1m-minify\x1b[0m -- Minify application file");
			}

			if (command == "run" || command == "test")
			{
				Log.println("  \x1b[3m(emscripten|html5|flash)\x1b[0m \x1b[1m-nolaunch\x1b[0m -- Begin test server without launching");
				// Log.println ("  \x1b[3m(html5)\x1b[0m \x1b[1m-minify\x1b[0m -- Minify output using the Google Closure compiler");
				// Log.println ("  \x1b[3m(html5)\x1b[0m \x1b[1m-minify -yui\x1b[0m -- Minify output using the YUI compressor");
				Log.println("  \x1b[3m(emscripten|html5|flash)\x1b[0m \x1b[1m--port=\x1b[0;3mvalue\x1b[0m -- Set port for test server");
			}

			Log.println("");
			Log.println(" " + Log.accentColor + "Experimental Options:" + Log.resetColor);
			Log.println("");
			Log.println("  \x1b[1m-watch\x1b[0m -- Execute the current command when the source changes");
			Log.println("  \x1b[3m(linux)\x1b[0m \x1b[1m-rpi\x1b[0m -- Build for Raspberry Pi");
			Log.println("  \x1b[3m(windows|mac|linux)\x1b[0m \x1b[1m-java\x1b[0m -- Build for Java instead of C++");
			Log.println("  \x1b[3m(windows|mac|linux)\x1b[0m \x1b[1m-nodejs\x1b[0m -- Build for Node.js instead of C++");
			Log.println("  \x1b[3m(windows|mac|linux)\x1b[0m \x1b[1m-cs\x1b[0m -- Build for C# instead of C++");
			Log.println("  \x1b[3m(windows|mac|linux)\x1b[0m \x1b[1m-hl\x1b[0m -- Build for HashLink instead of C++");
			#if (lime >= "7.6.0")
			// Log.println("  \x1b[3m(windows|mac|linux)\x1b[0m \x1b[1m-cppia\x1b[0m -- Build for CPPIA instead of C++");
			#end
			Log.println("  \x1b[3m(windows)\x1b[0m \x1b[1m-winjs\x1b[0m -- Build for WinJS instead of C++ (implies UWP)");
			Log.println("  \x1b[3m(windows)\x1b[0m \x1b[1m-uwp\x1b[0m -- Build for Universal Windows Platform");
			Log.println("  \x1b[3m(html5)\x1b[0m \x1b[1m-electron\x1b[0m -- Target Electron instead of the browser");

			if (command != "run" && command != "trace")
			{
				Log.println("");
				Log.println(" " + Log.accentColor + "Project Overrides:" + Log.resetColor);
				Log.println("");
				Log.println("  \x1b[1m--app-\x1b[0;3moption=value\x1b[0m -- Override a project <app/> setting");
				Log.println("  \x1b[1m--meta-\x1b[0;3moption=value\x1b[0m -- Override a project <meta/> setting");
				Log.println("  \x1b[1m--window-\x1b[0;3moption=value\x1b[0m -- Override a project <window/> setting");
				Log.println("  \x1b[1m--dependency\x1b[0;3m=value\x1b[0m -- Add an additional <dependency/> value");
				Log.println("  \x1b[1m--haxedef\x1b[0;3m=value\x1b[0m -- Add an additional <haxedef/> value");
				Log.println("  \x1b[1m--haxeflag\x1b[0;3m=value\x1b[0m -- Add an additional <haxeflag/> value");
				Log.println("  \x1b[1m--haxelib\x1b[0;3m=value\x1b[0m -- Add an additional <haxelib/> value");
				Log.println("  \x1b[1m--haxelib-\x1b[0;3mname=value\x1b[0m -- Override the path to a haxelib");
				Log.println("  \x1b[1m--source\x1b[0;3m=value\x1b[0m -- Add an additional <source/> value");
				Log.println("  \x1b[1m--certificate-\x1b[0;3moption=value\x1b[0m -- Override a project <certificate/> setting");
			}

			if (command == "display")
			{
				Log.println("");
				Log.println(" " + Log.accentColor + "Display Options:" + Log.resetColor);
				Log.println("");
				Log.println("  \x1b[3m(no option)\x1b[0m -- Display HXML build arguments");
				Log.println("  \x1b[1m--output-file\x1b[0m -- Display the output file for the project");
			}
		}
	}

	private function displayInfo(showHint:Bool = false):Void
	{
		// var out = "";
		// for (i in 0...80) out += "-";
		// Log.println (out);

		if (System.hostPlatform == WINDOWS)
		{
			Log.println("");
		}

		if (targetFlags.exists("openfl"))
		{
			Log.println("\x1b[37m .d88 88b.                             \x1b[0m\x1b[1;36m888888b 888 \x1b[0m");
			Log.println("\x1b[37md88P\" \"Y88b                            \x1b[0m\x1b[1;36m888     888 \x1b[0m");
			Log.println("\x1b[37m888     888                            \x1b[0m\x1b[1;36m888     888 \x1b[0m");
			Log.println("\x1b[37m888     888 88888b.   .d88b.  88888b.  \x1b[0m\x1b[1;36m8888888 888 \x1b[0m");
			Log.println("\x1b[37m888     888 888 \"88b d8P  Y8b 888 \"88b \x1b[0m\x1b[1;36m888     888 \x1b[0m");
			Log.println("\x1b[37m888     888 888  888 88888888 888  888 \x1b[0m\x1b[1;36m888     888 \x1b[0m");
			Log.println("\x1b[37mY88b. .d88P 888 d88P Y8b.     888  888 \x1b[0m\x1b[1;36m888     888 \x1b[0m");
			Log.println("\x1b[37m \"Y88 88P\"  88888P\"   \"Y8888  888  888 \x1b[0m\x1b[1;36m888     \"Y888P \x1b[0m");
			Log.println("\x1b[37m            888                                   ");
			Log.println("\x1b[37m            888                                   \x1b[0m");

			Log.println("");
			Log.println("\x1b[1mOpenFL Command-Line Tools\x1b[0;1m (" + getToolsVersion() + ")\x1b[0m");
		}
		else
		{
			Log.println("\x1b[32m_\x1b[1m/\\\\\\\\\\\\\x1b[0m\x1b[32m______________________________________________\x1b[0m");
			Log.println("\x1b[32m_\x1b[1m\\////\\\\\\\x1b[0m\x1b[32m______________________________________________\x1b[0m");
			Log.println("\x1b[32m_____\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m_____\x1b[1m/\\\\\\\x1b[0m\x1b[32m_____________________________________\x1b[0m");
			Log.println("\x1b[32m______\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m____\x1b[1m\\///\x1b[0m\x1b[32m_____\x1b[1m/\\\\\\\\\\\x1b[0m\x1b[32m__\x1b[1m/\\\\\\\\\\\x1b[0m\x1b[32m_______\x1b[1m/\\\\\\\\\\\\\\\\\x1b[0m\x1b[32m___\x1b[0m");
			Log.println("\x1b[32m_______\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m_____\x1b[1m/\\\\\\\x1b[0m\x1b[32m__\x1b[1m/\\\\\\///\\\\\\\\\\///\\\\\\\x1b[0m\x1b[32m___\x1b[1m/\\\\\\/////\\\\\\\x1b[0m\x1b[32m__\x1b[0m");
			Log.println("\x1b[32m________\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m____\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m_\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m_\x1b[1m\\//\\\\\\\x1b[0m\x1b[32m__\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m__\x1b[1m/\\\\\\\\\\\\\\\\\\\\\\\x1b[0m\x1b[32m___\x1b[0m");
			Log.println("\x1b[32m_________\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m____\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m_\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m__\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m__\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m_\x1b[1m\\//\\\\///////\x1b[0m\x1b[32m____\x1b[0m");
			Log.println("\x1b[32m________\x1b[1m/\\\\\\\\\\\\\\\\\\\x1b[0m\x1b[32m_\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m_\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m__\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m__\x1b[1m\\/\\\\\\\x1b[0m\x1b[32m__\x1b[1m\\//\\\\\\\\\\\\\\\\\\\\\x1b[0m\x1b[32m__\x1b[0m");
			Log.println("\x1b[32m________\x1b[1m\\/////////\x1b[0m\x1b[32m__\x1b[1m\\///\x1b[0m\x1b[32m__\x1b[1m\\///\x1b[0m\x1b[32m___\x1b[1m\\///\x1b[0m\x1b[32m___\x1b[1m\\///\x1b[0m\x1b[32m____\x1b[1m\\//////////\x1b[0m\x1b[32m___\x1b[0m");

			Log.println("");
			Log.println("\x1b[1mLime Command-Line Tools\x1b[0;1m (" + getToolsVersion() + ")\x1b[0m");
		}

		if (showHint)
		{
			Log.println("Use \x1b[3m"
				+ commandName
				+ " setup\x1b[0m to configure platforms or \x1b[3m"
				+ commandName
				+ " help\x1b[0m for more commands");
		}
	}

	private function document():Void {}

	private function findProjectFile(path:String):String
	{
		if (FileSystem.exists(Path.combine(path, "project.hxp")))
		{
			return Path.combine(path, "project.hxp");
		}
		else if (FileSystem.exists(Path.combine(path, "project.lime")))
		{
			return Path.combine(path, "project.lime");
		}
		else if (FileSystem.exists(Path.combine(path, "project.xml")))
		{
			return Path.combine(path, "project.xml");
		}
		else if (FileSystem.exists(Path.combine(path, "project.nmml")))
		{
			return Path.combine(path, "project.nmml");
		}
		else
		{
			var files = FileSystem.readDirectory(path);
			var matches = new Map<String, Array<String>>();
			matches.set("hxp", []);
			matches.set("lime", []);
			matches.set("nmml", []);
			matches.set("xml", []);

			for (file in files)
			{
				var path = Path.combine(path, file);

				if (FileSystem.exists(path) && !FileSystem.isDirectory(path))
				{
					var extension = Path.extension(file);

					if ((extension == "lime" && file != "include.lime")
						|| (extension == "nmml" && file != "include.nmml")
						|| (extension == "xml" && file != "include.xml")
						|| extension == "hxp")
					{
						matches.get(extension).push(path);
					}
				}
			}

			if (matches.get("hxp").length > 0)
			{
				return matches.get("hxp")[0];
			}

			if (matches.get("lime").length > 0)
			{
				return matches.get("lime")[0];
			}

			if (matches.get("nmml").length > 0)
			{
				return matches.get("nmml")[0];
			}

			if (matches.get("xml").length > 0)
			{
				return matches.get("xml")[0];
			}
		}

		return "";
	}

	private function generate():Void
	{
		if (targetFlags.exists("font-hash"))
		{
			var sourcePath = words[0];
			var glyphs = "32-255";

			System.runCommand(Path.directory(sourcePath), "neko", [
				Haxelib.getPath(new Haxelib("lime")) + "/templates/bin/hxswfml.n",
				"ttf2hash2",
				Path.withoutDirectory(sourcePath),
				Path.withoutDirectory(sourcePath) + ".hash",
				"-glyphs",
				glyphs
			]);
		}
		else if (targetFlags.exists("font-details"))
		{
			// var sourcePath = words[0];

			// var details = Font.load (sourcePath);
			// var json = Json.stringify (details);
			// Sys.print (json);
		}
		else if (targetFlags.exists("java-externs"))
		{
			var config = ConfigHelper.getConfig();
			var sourcePath = words[0];
			var targetPath = words[1];

			new JavaExternGenerator(config, sourcePath, targetPath);
		}
	}

	private function getBuildNumber(project:HXProject, increment:Bool = true):Void
	{
		var buildNumber = project.meta.buildNumber;

		if (buildNumber == null || StringTools.startsWith(buildNumber, "git"))
		{
			buildNumber = getBuildNumber_GIT(project, increment);
		}

		if (buildNumber == null || StringTools.startsWith(buildNumber, "svn"))
		{
			buildNumber = getBuildNumber_SVN(project, increment);
		}

		if (buildNumber == null || buildNumber == ".build")
		{
			var versionFile = Path.combine(project.app.path, ".build");
			var version = 1;

			try
			{
				if (FileSystem.exists(versionFile))
				{
					var previousVersion = Std.parseInt(File.getBytes(versionFile).toString());

					if (previousVersion != null)
					{
						version = previousVersion;

						if (increment)
						{
							version++;
						}
					}
				}
			}
			catch (e:Dynamic) {}

			project.meta.buildNumber = Std.string(version);

			if (increment)
			{
				try
				{
					System.mkdir(project.app.path);

					var output = File.write(versionFile, false);
					output.writeString(Std.string(version));
					output.close();
				}
				catch (e:Dynamic) {}
			}
		}
	}

	private function getBuildNumber_GIT(project:HXProject, increment:Bool = true):String
	{
		var cache = Log.mute;
		Log.mute = true;

		var output = System.runProcess("", "git", ["rev-list", "HEAD", "--count"], true, true, true);

		Log.mute = cache;

		if (output != null)
		{
			var value = Std.parseInt(output);

			if (value != null)
			{
				var buildNumber = project.meta.buildNumber;

				if (buildNumber != null && buildNumber.indexOf("+") > -1)
				{
					var modifier = Std.parseInt(buildNumber.substr(buildNumber.indexOf("+") + 1));

					if (modifier != null)
					{
						value += modifier;
					}
				}

				return project.meta.buildNumber = Std.string(value);
			}
		}

		return null;
	}

	private function getBuildNumber_SVN(project:HXProject, increment:Bool = true):String
	{
		var cache = Log.mute;
		Log.mute = true;

		var output = System.runProcess("", "svn", ["info"], true, true, true);

		Log.mute = cache;

		if (output != null)
		{
			var searchString = "Revision: ";
			var index = output.indexOf(searchString);

			if (index > -1)
			{
				var value = Std.parseInt(output.substring(index + searchString.length, output.indexOf("\n", index)));

				if (value != null)
				{
					var buildNumber = project.meta.buildNumber;

					if (buildNumber != null && buildNumber.indexOf("+") > -1)
					{
						var modifier = Std.parseInt(buildNumber.substr(buildNumber.indexOf("+") + 1));

						if (modifier != null)
						{
							value += modifier;
						}
					}

					return project.meta.buildNumber = Std.string(value);
				}
			}
		}

		return null;
	}

	private function getToolsVersion(version:String = null):String
	{
		if (version == null) version = this.version;

		if (targetFlags.exists("openfl"))
		{
			return Haxelib.getVersion(new Haxelib("openfl")) + "-L" + StringTools.generateUUID(5, null, StringTools.generateHashCode(version));
		}
		else
		{
			return version;
		}
	}

	private function initializeProject(project:HXProject = null, targetName:String = ""):HXProject
	{
		Log.info("", Log.accentColor + "Initializing project..." + Log.resetColor);

		var projectFile = "";

		if (project == null)
		{
			if (words.length == 2)
			{
				if (FileSystem.exists(words[0]))
				{
					if (FileSystem.isDirectory(words[0]))
					{
						projectFile = findProjectFile(words[0]);
					}
					else
					{
						projectFile = words[0];
					}
				}

				if (targetName == "")
				{
					targetName = words[1].toLowerCase();
				}
			}
			else
			{
				projectFile = findProjectFile(Sys.getCwd());

				if (targetName == "")
				{
					targetName = words[0].toLowerCase();
				}
			}

			if (projectFile == "")
			{
				Log.error("You must have a \"project.xml\" file or specify another valid project file when using the '" + command + "' command");
				return null;
			}
			else
			{
				Log.info("", Log.accentColor + "Using project file: " + projectFile + Log.resetColor);
			}
		}

		if (runFromHaxelib && !targetFlags.exists("nolocalrepocheck"))
		{
			try
			{
				var forceGlobal = (overrides.haxeflags.indexOf("--global") > -1);
				var projectDirectory = Path.directory(projectFile);
				var localRepository = Path.combine(projectDirectory, ".haxelib");

				if (!forceGlobal && FileSystem.exists(localRepository) && FileSystem.isDirectory(localRepository))
				{
					var overrideExists = Haxelib.pathOverrides.exists("lime");
					var cacheOverride = Haxelib.pathOverrides.get("lime");
					Haxelib.pathOverrides.remove("lime");

					var workingDirectory = Sys.getCwd();
					Sys.setCwd(projectDirectory);

					var limePath = Haxelib.getPath(new Haxelib("lime"), true, true);
					var toolsPath = Haxelib.getPath(new Haxelib("lime-tools"));

					Sys.setCwd(workingDirectory);

					if (!StringTools.startsWith(toolsPath, limePath))
					{
						Log.info("", Log.accentColor + "Requesting alternate tools from .haxelib repository...\x1b[0m\n\n");

						var args = Sys.args();
						args.pop();

						Sys.setCwd(limePath);

						args = [Path.combine(limePath, "run.n")].concat(args);
						args.push("--haxelib-lime=" + limePath);
						args.push("-nolocalrepocheck");
						args.push(workingDirectory);

						Sys.exit(Sys.command("neko", args));
						return null;
					}

					if (overrideExists)
					{
						Haxelib.pathOverrides.set("lime", cacheOverride);
					}
				}
			}
			catch (e:Dynamic) {}
		}

		if (targetFlags.exists("air"))
		{
			switch (targetName)
			{
				case "android":
					targetName = "air";
					targetFlags.set("android", "");

				case "ios":
					targetName = "air";
					targetFlags.set("ios", "");

				case "windows":
					targetName = "air";
					targetFlags.set("windows", "");

				case "mac", "macos":
					targetName = "air";
					targetFlags.set("mac", "");
			}
		}

		var target:Platform = null;

		switch (targetName)
		{
			case "cpp":
				target = cast System.hostPlatform;
				targetFlags.set("cpp", "");

			case "neko":
				target = cast System.hostPlatform;
				targetFlags.set("neko", "");

			case "hl", "hashlink":
				target = cast System.hostPlatform;
				targetFlags.set("hl", "");

			case "cppia":
				target = cast System.hostPlatform;
				targetFlags.set("cppia", "");

			case "java":
				target = cast System.hostPlatform;
				targetFlags.set("java", "");

			case "nodejs":
				target = cast System.hostPlatform;
				targetFlags.set("nodejs", "");

			case "cs":
				target = cast System.hostPlatform;
				targetFlags.set("cs", "");

			case "iphone", "iphoneos":
				target = Platform.IOS;

			case "iphonesim":
				target = Platform.IOS;
				targetFlags.set("simulator", "");

			case "electron":
				target = Platform.HTML5;
				targetFlags.set("electron", "");

			case "firefox", "firefoxos":
				target = Platform.FIREFOX;
				overrides.haxedefs.set("firefoxos", "");

			case "mac", "macos":
				target = Platform.MAC;
				overrides.haxedefs.set("macos", "");

			case "rpi", "raspberrypi":
				target = Platform.LINUX;
				targetFlags.set("rpi", "");

			case "webassembly", "wasm":
				target = Platform.EMSCRIPTEN;
				targetFlags.set("webassembly", "");

			case "winjs", "uwp":
				target = Platform.WINDOWS;
				targetFlags.set("uwp", "");
				targetFlags.set("winjs", "");

			case "winrt":
				target = Platform.WINDOWS;
				targetFlags.set("winrt", "");

			default:
				target = cast targetName.toLowerCase();
		}

		HXProject._command = command;
		HXProject._debug = debug;
		HXProject._environment = environment;
		HXProject._target = target;
		HXProject._targetFlags = targetFlags;
		HXProject._userDefines = userDefines;

		var config = ConfigHelper.getConfig();

		if (config != null)
		{
			for (define in config.defines.keys())
			{
				if (define == define.toUpperCase())
				{
					var value = config.defines.get(define);

					switch (define)
					{
						case "ANT_HOME":
							if (value == "/usr")
							{
								value = "/usr/share/ant";
							}

							if (FileSystem.exists(value))
							{
								Sys.putEnv(define, value);
							}

						case "JAVA_HOME":
							if (FileSystem.exists(value))
							{
								Sys.putEnv(define, value);
							}

						default:
							Sys.putEnv(define, value);
					}
				}
			}
		}

		if (System.hostPlatform == WINDOWS)
		{
			if (environment.get("JAVA_HOME") != null)
			{
				var javaPath = Path.combine(environment.get("JAVA_HOME"), "bin");
				var value;

				if (System.hostPlatform == WINDOWS)
				{
					value = javaPath + ";" + Sys.getEnv("PATH");
				}
				else
				{
					value = javaPath + ":" + Sys.getEnv("PATH");
				}

				environment.set("PATH", value);
				Sys.putEnv("PATH", value);
			}
		}

		try
		{
			var process = new Process("haxe", ["-version"]);
			var haxeVersion = StringTools.trim(process.stderr.readAll().toString());

			if (haxeVersion == "")
			{
				haxeVersion = StringTools.trim(process.stdout.readAll().toString());
			}

			process.close();

			environment.set("haxe", haxeVersion);
			environment.set("haxe_ver", haxeVersion);

			environment.set("haxe" + haxeVersion.split(".")[0], "1");
		}
		catch (e:Dynamic) {}

		if (!environment.exists("HAXE_STD_PATH"))
		{
			if (System.hostPlatform == WINDOWS)
			{
				environment.set("HAXE_STD_PATH", "C:\\HaxeToolkit\\haxe\\std\\");
			}
			else
			{
				if (FileSystem.exists("/usr/lib/haxe"))
				{
					environment.set("HAXE_STD_PATH", "/usr/lib/haxe/std");
				}
				else if (FileSystem.exists("/usr/share/haxe"))
				{
					environment.set("HAXE_STD_PATH", "/usr/share/haxe/std");
				}
				else
				{
					environment.set("HAXE_STD_PATH", "/usr/local/lib/haxe/std");
				}
			}
		}

		if (project == null)
		{
			HXProject._command = command;
			HXProject._debug = debug;
			HXProject._environment = environment;
			HXProject._target = target;
			HXProject._targetFlags = targetFlags;
			HXProject._userDefines = userDefines;

			try
			{
				Sys.setCwd(Path.directory(projectFile));
			}
			catch (e:Dynamic) {}

			if (Path.extension(projectFile) == "lime" || Path.extension(projectFile) == "nmml" || Path.extension(projectFile) == "xml")
			{
				project = new ProjectXMLParser(Path.withoutDirectory(projectFile), userDefines, includePaths);
			}
			else if (Path.extension(projectFile) == "hxp")
			{
				project = HXProject.fromFile(projectFile, userDefines, includePaths);

				if (project != null)
				{
					project.command = command;
					project.debug = debug;
					project.target = target;
					project.targetFlags = targetFlags;
				}
				else
				{
					Log.error("Could not process \"" + projectFile + "\"");
					return null;
				}
			}
		}

		if (project != null && project.needRerun && !project.targetFlags.exists("norerun"))
		{
			Haxelib.pathOverrides.remove("lime");
			var workingDirectory = Sys.getCwd();
			var limePath = Haxelib.getPath(new Haxelib("lime"), true, true);
			Sys.setCwd(workingDirectory);

			Log.info("", Log.accentColor + "Requesting alternate tools from custom haxelib path...\x1b[0m\n\n");

			var args = Sys.args();
			args.pop();

			Sys.setCwd(limePath);

			args = [Path.combine(limePath, "run.n")].concat(args);
			args.push("--haxelib-lime=" + limePath);
			args.push("-norerun");
			args.push(workingDirectory);

			Sys.exit(Sys.command("neko", args));
			return null;
		}

		if (project == null || (command != "rebuild" && project.sources.length == 0 && !FileSystem.exists(project.app.main + ".hx")))
		{
			Log.error("You must have a \"project.xml\" file or specify another valid project file when using the '" + command + "' command");
			return null;
		}

		if (config != null)
		{
			config.merge(project);
			project = config;
		}

		project.haxedefs.set("tools", version);

		/*if (userDefines.exists ("nme")) {

			project.haxedefs.set ("nme_install_tool", 1);
			project.haxedefs.set ("nme_ver", version);
			project.haxedefs.set ("nme" + version.split (".")[0], 1);

			project.config.cpp.buildLibrary = "hxcpp";
			project.config.cpp.requireBuild = false;

		}*/

		project.merge(overrides);

		for (haxelib in project.haxelibs)
		{
			if (haxelib.name == "lime" && haxelib.version != null && haxelib.version != "" && haxelib.version != "dev" && !haxelib.versionMatches(version))
			{
				if (!project.targetFlags.exists("notoolscheck"))
				{
					if (targetFlags.exists("openfl"))
					{
						for (haxelib in project.haxelibs)
						{
							if (haxelib.name == "openfl")
							{
								Haxelib.setOverridePath(haxelib, Haxelib.getPath(haxelib));
							}
						}
					}

					Log.info("", Log.accentColor + "Requesting tools version " + getToolsVersion(haxelib.version) + "...\x1b[0m\n\n");

					Haxelib.pathOverrides.remove("lime");
					var path = Haxelib.getPath(haxelib);

					var args = Sys.args();
					var workingDirectory = args.pop();

					for (haxelib in project.haxelibs)
					{
						args.push("--haxelib-" + haxelib.name + "=" + Haxelib.getPath(haxelib));
					}

					args.push("-notoolscheck");

					Sys.setCwd(path);
					var args = [Path.combine(path, "run.n")].concat(args);
					args.push(workingDirectory);

					Sys.exit(Sys.command("neko", args));
					return null;

					// var args = [ "run", "lime:" + haxelib.version ].concat (args);
					// Sys.exit (Sys.command ("haxelib", args));
				}
				else
				{
					if (Std.string(version) != Std.string(Haxelib.getVersion(haxelib)))
					{
						Log.warn("", Log.accentColor + "Could not switch to requested tools version\x1b[0m");
					}
				}
			}
		}

		if (overrides.architectures.length > 0)
		{
			project.architectures = overrides.architectures;
		}

		for (key in projectDefines.keys())
		{
			var components = key.split("-");
			var field = components.shift().toLowerCase();
			var attribute = "";

			if (components.length > 0)
			{
				for (i in 1...components.length)
				{
					components[i] = components[i].substr(0, 1).toUpperCase() + components[i].substr(1).toLowerCase();
				}

				attribute = components.join("");
			}

			if (field == "template" && attribute == "path")
			{
				project.templatePaths.push(projectDefines.get(key));
			}
			else if (field == "config")
			{
				project.config.set(attribute, projectDefines.get(key));
			}
			else
			{
				if (Reflect.hasField(project, field))
				{
					var fieldValue = Reflect.field(project, field);

					if (Reflect.hasField(fieldValue, attribute))
					{
						if ((Reflect.field(fieldValue, attribute) is String))
						{
							Reflect.setField(fieldValue, attribute, projectDefines.get(key));
						}
						else if ((Reflect.field(fieldValue, attribute) is Float))
						{
							Reflect.setField(fieldValue, attribute, Std.parseFloat(projectDefines.get(key)));
						}
						else if ((Reflect.field(fieldValue, attribute) is Bool))
						{
							Reflect.setField(fieldValue, attribute, (projectDefines.get(key).toLowerCase() == "true"
								|| projectDefines.get(key) == "1"));
						}
					}
				}
				else
				{
					project.targetFlags.set(key, projectDefines.get(key));
					targetFlags.set(key, projectDefines.get(key));
				}
			}
		}

		MapTools.copyKeysDynamic(userDefines, project.haxedefs);

		getBuildNumber(project, (project.command == "build" || project.command == "test"));

		return project;
	}

	public static function main():Void
	{
		new CommandLineTools();
	}

	private function platformSetup():Void
	{
		Log.info("", Log.accentColor + "Running command: SETUP" + Log.resetColor);

		if (words.length == 0)
		{
			PlatformSetup.run("", userDefines, targetFlags);
		}
		else if (words.length == 1)
		{
			PlatformSetup.run(words[0], userDefines, targetFlags);
		}
		else
		{
			Log.error("Incorrect number of arguments for command 'setup'");
			return;
		}
	}

	private function processArguments():Void
	{
		var arguments = Sys.args();

		if (arguments.length > 0)
		{
			// When the command-line tools are called from haxelib,
			// the last argument is the project directory and the
			// path to Lime is the current working directory

			var lastArgument = "";

			for (i in 0...arguments.length)
			{
				lastArgument = arguments.pop();
				if (lastArgument.length > 0) break;
			}

			lastArgument = new Path(lastArgument).toString();
			var isRootDirectory = false;

			if (System.hostPlatform == WINDOWS)
			{
				isRootDirectory = (lastArgument.length == 3
					&& lastArgument.charAt(1) == ":"
					&& (lastArgument.charAt(2) == "/" || lastArgument.charAt(2) == "\\"));
			}
			else
			{
				isRootDirectory = (lastArgument == "/");
			}

			if (FileSystem.exists(lastArgument) && FileSystem.isDirectory(lastArgument))
			{
				Haxelib.setOverridePath(new Haxelib("lime-tools"), Path.combine(Sys.getCwd(), "tools"));

				Sys.setCwd(lastArgument);
				runFromHaxelib = true;
			}
			else if (!isRootDirectory)
			{
				arguments.push(lastArgument);
			}

			Haxelib.workingDirectory = Sys.getCwd();
		}

		if (!runFromHaxelib)
		{
			var path = null;

			if (FileSystem.exists("tools.n"))
			{
				path = Path.combine(Sys.getCwd(), "../");
			}
			else if (FileSystem.exists("run.n"))
			{
				path = Sys.getCwd();
			}
			else
			{
				Log.error("Could not run Lime tools from this directory");
			}

			Haxelib.setOverridePath(new Haxelib("lime"), path);
			Haxelib.setOverridePath(new Haxelib("lime-tools"), Path.combine(path, "tools"));
		}

		var catchArguments = false;
		var catchHaxeFlag = false;
		var catchDefine = false;

		for (argument in arguments)
		{
			var equals = argument.indexOf("=");

			if (catchHaxeFlag)
			{
				overrides.haxeflags.push(argument);
				catchHaxeFlag = false;
			}
			else if (argument == "-args" || argument == "--")
			{
				catchArguments = true;
			}
			else if (catchArguments)
			{
				additionalArguments.push(argument);
			}
			else if (argument == "-D")
			{
				catchDefine = true;
			}
			else if (equals > 0)
			{
				var argValue = argument.substr(equals + 1);
				// if quotes remain on the argValue we need to strip them off
				// otherwise the compiler really dislikes the result!
				var r = ~/^['"](.*)['"]$/;
				if (r.match(argValue))
				{
					argValue = r.matched(1);
				}

				if (catchDefine)
				{
					userDefines.set(argument, argValue);
					catchDefine = false;
				}
				else if (argument.substr(0, 2) == "-D")
				{
					userDefines.set(argument.substr(2, equals - 2), argValue);
				}
				else if (argument.substr(0, 2) == "--")
				{
					// this won't work because it assumes there is only ever one of these.
					// projectDefines.set (argument.substr (2, equals - 2), argValue);

					var field = argument.substr(2, equals - 2);

					if (field == "haxedef")
					{
						overrides.haxedefs.set(argValue, 1);
					}
					else if (field == "haxeflag")
					{
						overrides.haxeflags.push(argValue);
					}
					else if (field == "haxelib")
					{
						var name = argValue;
						var version = "";

						if (name.indexOf(":") > -1)
						{
							version = name.substr(name.indexOf(":") + 1);
							name = name.substr(0, name.indexOf(":"));
						}

						var i = 0;

						overrides.haxelibs.push(new Haxelib(name, version));
					}
					else if (StringTools.startsWith(field, "haxelib-"))
					{
						var name = field.substr(8);
						Haxelib.setOverridePath(new Haxelib(name), Path.tryFullPath(argValue));
					}
					else if (field == "source")
					{
						overrides.sources.push(argValue);
					}
					else if (field == "dependency")
					{
						overrides.dependencies.push(new Dependency(argValue, ""));
					}
					else if (StringTools.startsWith(field, "certificate-"))
					{
						if (overrides.keystore == null)
						{
							overrides.keystore = new Keystore();
						}

						field = StringTools.replace(field, "certificate-", "");

						if (field == "alias-password") field = "aliasPassword";

						if (Reflect.hasField(overrides.keystore, field))
						{
							Reflect.setField(overrides.keystore, field, argValue);
						}

						if (field == "identity")
						{
							overrides.config.set("ios.identity", argValue);
							overrides.config.set("tvos.identity", argValue);
						}
						else if (field == "team-id")
						{
							overrides.config.set("ios.team-id", argValue);
							overrides.config.set("tvos.team-id", argValue);
						}
					}
					else if (StringTools.startsWith(field, "app-")
						|| StringTools.startsWith(field, "meta-")
						|| StringTools.startsWith(field, "window-"))
					{
						var split = field.split("-");

						var fieldName = split[0];
						var property = split[1];

						for (i in 2...split.length)
						{
							property += split[i].substr(0, 1).toUpperCase() + split[i].substr(1, split[i].length - 1);
						}

						if (field == "window-allow-high-dpi") property = "allowHighDPI";
						if (field == "window-color-depth") property = "colorDepth";
						if (field == "meta-build-number") property = "buildNumber";

						var fieldReference = Reflect.field(overrides, fieldName);

						if (Reflect.hasField(fieldReference, property))
						{
							var propertyReference = Reflect.field(fieldReference, property);

							if ((propertyReference is Bool))
							{
								Reflect.setField(fieldReference, property, argValue == "true");
							}
							else if ((propertyReference is Int))
							{
								Reflect.setField(fieldReference, property, Std.parseInt(argValue));
							}
							else if ((propertyReference is Float))
							{
								Reflect.setField(fieldReference, property, Std.parseFloat(argValue));
							}
							else if ((propertyReference is String))
							{
								Reflect.setField(fieldReference, property, argValue);
							}
							else
							{
								// TODO: Only certain properties?
								Reflect.setField(fieldReference, property, argValue);
							}
						}
					}
					else if (field == "build-library")
					{
						overrides.config.set("cpp.buildLibrary", argValue);
					}
					else if (field == "device")
					{
						targetFlags.set("device", argValue);
					}
					else
					{
						projectDefines.set(field, argValue);
					}
				}
				else
				{
					userDefines.set(argument.substr(0, equals), argValue);
				}
			}
			else if (catchDefine)
			{
				userDefines.set(argument, "");
				catchDefine = false;
			}
			else if (argument.substr(0, 2) == "-D")
			{
				userDefines.set(argument.substr(2), "");
			}
			else if (argument.substr(0, 2) == "-I")
			{
				includePaths.push(argument.substr(2));
			}
			else if (argument == "-haxelib-debug")
			{
				Haxelib.debug = true;
			}
			else if (argument == "--help" || argument == "-help" || argument == "-h")
			{
				targetFlags.set("help", "");
			}
			else if (argument == "--output-file")
			{
				targetFlags.set("output-file", "");
			}
			else if (argument.substr(0, 1) == "-")
			{
				if (argument == "-dce" || argument.substr(1, 1) == "-")
				{
					overrides.haxeflags.push(argument);

					if (argument == "--remap" || argument == "--connect" || argument == "-dce")
					{
						catchHaxeFlag = true;
					}
				}
				else
				{
					if (argument.substr(0, 4) == "-arm")
					{
						try
						{
							var name = argument.substr(1).toUpperCase();
							var value = Type.createEnum(Architecture, name);

							if (value != null)
							{
								overrides.architectures.push(value);
							}
						}
						catch (e:Dynamic) {}
					}
					else if (argument == "-64")
					{
						overrides.architectures.push(Architecture.X64);
					}
					else if (argument == "-32")
					{
						overrides.architectures.push(Architecture.X86);
					}
					else if (argument == "-v" || argument == "-verbose")
					{
						argument = "-verbose";

						if (command != "display")
						{
							Log.verbose = true;
						}
					}
					else if (argument == "-force-verbose")
					{
						Log.verbose = true;
					}
					else if (argument == "-dryrun")
					{
						System.dryRun = true;
					}
					else if (argument == "-notrace")
					{
						traceEnabled = false;
					}
					else if (argument == "-debug")
					{
						debug = true;
					}
					else if (argument == "-nocolor")
					{
						Log.enableColor = false;
					}

					targetFlags.set(argument.substr(1), "");
				}
			}
			else if (command.length == 0)
			{
				command = argument;
			}
			else
			{
				words.push(argument);
			}
		}
	}

	private function publishProject()
	{
		switch (words[words.length - 1])
		{
			case "firefox":
				var project = initializeProject(null, "firefox");

				Log.info("", Log.accentColor + "Using publishing target: FIREFOX MARKETPLACE" + Log.resetColor);

				// if (FirefoxMarketplace.isValid (project)) {
				//
				// buildProject (project, "build");
				//
				// Log.info ("", "\n" + Log.accentColor + "Running command: PUBLISH" + Log.resetColor);
				//
				// FirefoxMarketplace.publish (project);
				//
				// }
		}
	}

	private function updateLibrary():Void
	{
		if ((words.length < 1 && command != "upgrade") || words.length > 1)
		{
			Log.error("Incorrect number of arguments for command '" + command + "'");
			return;
		}

		Log.info("", Log.accentColor + "Running command: " + command.toUpperCase() + Log.resetColor);

		var name = defaultLibrary;

		if (words.length > 0)
		{
			name = words[0];
		}

		var haxelib = new Haxelib(name);
		var path = Haxelib.getPath(haxelib);

		switch (command)
		{
			case "install":
				if (path == null || path == "")
				{
					PlatformSetup.installHaxelib(haxelib);
				}
				else
				{
					PlatformSetup.updateHaxelib(haxelib);
				}

				PlatformSetup.setupHaxelib(haxelib);

			case "remove":
				if (path != null && path != "")
				{
					Haxelib.runCommand("", ["remove", name]);
				}

			case "upgrade":
				if (path != null && path != "")
				{
					PlatformSetup.updateHaxelib(haxelib);
					PlatformSetup.setupHaxelib(haxelib);
				}
				else
				{
					Log.warn("\"" + haxelib.name + "\" is not a valid haxelib, or has not been installed");
				}
		}
	}
}
