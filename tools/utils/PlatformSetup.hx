package utils;


import haxe.Http;
import haxe.io.Eof;
import haxe.io.Path;
import haxe.zip.Reader;
#if (hxp > "1.0.0")
import hxp.CLIHelper;
import hxp.ConfigHelper;
import hxp.FileHelper;
import hxp.Haxelib;
import hxp.HaxelibHelper;
import hxp.LogHelper;
import hxp.PathHelper;
import hxp.Platform;
import hxp.PlatformHelper;
import hxp.ProcessHelper;
import hxp.Project;
import hxp.Version;
#else
import hxp.helpers.CLIHelper;
import hxp.helpers.ConfigHelper;
import hxp.helpers.FileHelper;
import hxp.helpers.HaxelibHelper;
import hxp.helpers.LogHelper;
import hxp.helpers.PathHelper;
import hxp.helpers.PlatformHelper;
import hxp.helpers.ProcessHelper;
import hxp.project.Haxelib;
import hxp.project.HXProject in Project;
import hxp.project.Platform;
import hxp.project.Version;
#end
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


class PlatformSetup {


	private static var appleXcodeURL = "https://developer.apple.com/xcode/download/";
	private static var linuxAptPackages = "gcc-multilib g++-multilib";
	private static var linuxUbuntuSaucyPackages = "gcc-multilib g++-multilib libxext-dev";
	private static var linuxYumPackages = "gcc gcc-c++";
	private static var linuxDnfPackages = "gcc gcc-c++";
	private static var linuxEquoPackages = "media-libs/mesa sys-devel/gcc";
	private static var linuxEmergePackages = "media-libs/mesa sys-devel/gcc";
	private static var linuxPacman32Packages = "multilib-devel mesa mesa-libgl glu";
	private static var linuxPacman64Packages = "multilib-devel lib32-mesa lib32-mesa-libgl lib32-glu";
	private static var visualStudioURL = "https://www.visualstudio.com/downloads/";

	private static var triedSudo:Bool = false;
	private static var userDefines:Map<String, Dynamic>;
	private static var targetFlags:Map<String, Dynamic>;
	private static var setupHaxelibs = new Map<String, Bool> ();


	private static function createPath (path:String, defaultPath:String = ""):String {

		try {

			if (path == "") {

				PathHelper.mkdir (defaultPath);
				return defaultPath;

			} else {

				PathHelper.mkdir (path);
				return path;

			}

		} catch (e:Dynamic) {

			throwPermissionsError ();
			return "";

		}

	}


	private static function downloadFile (remotePath:String, localPath:String = "", followingLocation:Bool = false):Void {

		if (localPath == "") {

			localPath = Path.withoutDirectory (remotePath);

		}

		if (!followingLocation && FileSystem.exists (localPath)) {

			var answer = CLIHelper.ask ("File found. Install existing file?");

			if (answer != NO) {

				return;

			}

		}

		var out = File.write (localPath, true);
		var progress = new Progress (out);
		var h = new Http (remotePath);

		h.cnxTimeout = 30;

		h.onError = function (e) {
			progress.close();
			FileSystem.deleteFile (localPath);
			throw e;
		};

		if (!followingLocation) {

			LogHelper.println ("Downloading " + localPath + "...");

		}

		h.customRequest (false, progress);

		if (h.responseHeaders != null && h.responseHeaders.exists ("Location")) {

			var location = h.responseHeaders.get ("Location");

			if (location != remotePath) {

				downloadFile (location, localPath, true);

			}

		}

	}


	private static function extractFile (sourceZIP:String, targetPath:String, ignoreRootFolder:String = ""):Void {

		var extension = Path.extension (sourceZIP);

		if (extension != "zip") {

			var arguments = "xvzf";

			if (extension == "bz2" || extension == "tbz2") {

				arguments = "xvjf";

			}

			if (ignoreRootFolder != "") {

				if (ignoreRootFolder == "*") {

					for (file in FileSystem.readDirectory (targetPath)) {

						if (FileSystem.isDirectory (targetPath + "/" + file)) {

							ignoreRootFolder = file;

						}

					}

				}

				ProcessHelper.runCommand ("", "tar", [ arguments, sourceZIP ], false);
				ProcessHelper.runCommand ("", "cp", [ "-R", ignoreRootFolder + "/.", targetPath ], false);
				Sys.command ("rm", [ "-r", ignoreRootFolder ]);

			} else {

				ProcessHelper.runCommand ("", "tar", [ arguments, sourceZIP, "-C", targetPath ], false);

				//InstallTool.runCommand (targetPath, "tar", [ arguments, FileSystem.fullPath (sourceZIP) ]);

			}

			Sys.command ("chmod", [ "-R", "755", targetPath ]);

		} else {

			var file = File.read (sourceZIP, true);
			var entries = Reader.readZip (file);
			file.close ();

			for (entry in entries) {

				var fileName = entry.fileName;

				if (fileName.charAt (0) != "/" && fileName.charAt (0) != "\\" && fileName.split ("..").length <= 1) {

					var dirs = ~/[\/\\]/g.split(fileName);

					if ((ignoreRootFolder != "" && dirs.length > 1) || ignoreRootFolder == "") {

						if (ignoreRootFolder != "") {

							dirs.shift ();

						}

						var path = "";
						var file = dirs.pop ();

						for (d in dirs) {

							path += d;
							PathHelper.mkdir (targetPath + "/" + path);
							path += "/";

						}

						if (file == "") {

							if (path != "") LogHelper.println ("  Created " + path);
							continue; // was just a directory

						}

						path += file;
						LogHelper.println ("  Install " + path);

						var data = Reader.unzip (entry);
						var f = File.write (targetPath + "/" + path, true);
						f.write (data);
						f.close ();

					}

				}

			}

		}

		LogHelper.println ("Done");

	}


	public static function getDefineValue (name:String, description:String):Void {

		var value = ConfigHelper.getConfigValue (name);

		if (value == null && Sys.getEnv (name) != null) {

			value = Sys.getEnv (name);

		}

		var inputValue = unescapePath (CLIHelper.param (LogHelper.accentColor + description + "\x1b[0m \x1b[37;3m[" + (value != null ? value : "") + "]\x1b[0m"));

		if (inputValue != "" && inputValue != value) {

			ConfigHelper.writeConfigValue (name, inputValue);

		} else if (inputValue == Sys.getEnv (inputValue)) {

			ConfigHelper.removeConfigValue (name);

		}

	}


	// public static function getDefines (names:Array<String> = null, descriptions:Array<String> = null, ignored:Array<String> = null):Map<String, String> {

		// var config = CommandLineTools.getLimeConfig ();

		// var defines = null;
		// var env = Sys.environment ();
		// var path = "";

		// if (config != null) {

		// 	defines = config.environment;

		// 	for (key in defines.keys ()) {

		// 		if (defines.get (key) == env.get (key)) {

		// 			defines.remove (key);

		// 		}

		// 	}

		// } else {

		// 	defines = new Map<String, String> ();

		// }

		// if (!defines.exists ("LIME_CONFIG")) {

		// 	var home = "";

		// 	if (env.exists ("HOME")) {

		// 		home = env.get ("HOME");

		// 	} else if (env.exists ("USERPROFILE")) {

		// 		home = env.get ("USERPROFILE");

		// 	} else {

		// 		LogHelper.println ("Warning : No 'HOME' variable set - ~/.lime/config.xml might be missing.");

		// 		return null;

		// 	}

		// 	defines.set ("LIME_CONFIG", home + "/.lime/config.xml");

		// }

		// if (names == null) {

		// 	return defines;

		// }

		// var values = new Array<String> ();

		// for (i in 0...names.length) {

		// 	var name = names[i];
		// 	var description = descriptions[i];

		// 	var ignore = "";

		// 	if (ignored != null && ignored.length > i) {

		// 		ignore = ignored[i];

		// 	}

		// 	var value = "";

		// 	if (defines.exists (name) && defines.get (name) != ignore) {

		// 		value = defines.get (name);

		// 	} else if (env.exists (name)) {

		// 		value = Sys.getEnv (name);

		// 	}

		// 	value = unescapePath (CLIHelper.param ("\x1b[1m" + description + "\x1b[0m \x1b[37;3m[" + value + "]\x1b[0m"));

		// 	if (value != "") {

		// 		defines.set (name, value);

		// 	} else if (value == Sys.getEnv (name)) {

		// 		defines.remove (name);

		// 	}

		// }

		// return defines;

	// }


	public static function installHaxelib (haxelib:Haxelib):Void {

		var name = haxelib.name;
		var version = haxelib.version;

		if (version != null && version.indexOf ("*") > -1) {

			var regexp = new EReg ("^.+[0-9]+-[0-9]+-[0-9]+ +[0-9]+:[0-9]+:[0-9]+ +([a-z0-9.-]+) +", "gi");
			var output = HaxelibHelper.runProcess ("", [ "info", haxelib.name ]);
			var lines = output.split ("\n");

			var versions = new Array<Version> ();
			var ver:Version;

			for (line in lines) {

				if (regexp.match (line)) {

					try {

						ver = regexp.matched (1);
						versions.push (ver);

					} catch (e:Dynamic) {}

				}

			}

			var match = HaxelibHelper.findMatch (haxelib, versions);

			if (match != null) {

				version = match;

			} else {

				LogHelper.error ("Could not find version \"" + haxelib.version + "\" for haxelib \"" + haxelib.name + "\"");

			}

		}

		var args = [ "install", name ];

		if (version != null && version != "" && version.indexOf ("*") == -1) {

			args.push (version);

		}

		HaxelibHelper.runCommand ("", args);

	}


	private static function link (dir:String, file:String, dest:String):Void {

		Sys.command ("rm -rf " + dest + "/" + file);
		Sys.command ("ln -s " + "/usr/lib" +"/" + dir + "/" + file + " " + dest + "/" + file);

	}


	private static function openURL (url:String):Void {

		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {

			Sys.command ("explorer", [ url ]);

		} else if (PlatformHelper.hostPlatform == Platform.LINUX) {

			ProcessHelper.runCommand ("", "xdg-open", [ url ], false);

		} else {

			ProcessHelper.runCommand ("", "open", [ url ], false);

		}

	}


	public static function run (target:String = "", userDefines:Map<String, Dynamic> = null, targetFlags:Map<String, Dynamic> = null) {

		PlatformSetup.userDefines = userDefines;
		PlatformSetup.targetFlags = targetFlags;

		try {

			if (target == "cpp") {

				switch (PlatformHelper.hostPlatform) {

					case WINDOWS: target = "windows";
					case MAC: target = "mac";
					case LINUX: target = "linux";
					default:

				}

			}

			switch (target) {

				case "air":

					setupAIR ();

				case "android":

					setupAndroid ();

				case "blackberry":

					// setupBlackBerry ();

				case "emscripten", "webassembly", "wasm":

					setupEmscripten ();

				case "html5":

					LogHelper.println ("\x1b[0;3mNo additional configuration is required.\x1b[0m");
					//setupHTML5 ();

				case "ios", "iphoneos", "iphonesim":

					if (PlatformHelper.hostPlatform == Platform.MAC) {

						setupIOS ();

					}

				case "linux":

					if (PlatformHelper.hostPlatform == Platform.LINUX) {

						setupLinux ();

					}

				case "mac", "macos":

					if (PlatformHelper.hostPlatform == Platform.MAC) {

						setupMac ();

					}

				case "tizen":

					// setupTizen ();

				case "webos":

					// setupWebOS ();

				case "electron":

					setupElectron ();

				case "windows", "winrt":

					if (PlatformHelper.hostPlatform == Platform.WINDOWS) {

						setupWindows ();

					}

				case "neko", "hl", "cs", "uwp", "winjs", "nodejs", "java":

					LogHelper.println ("\x1b[0;3mNo additional configuration is required.\x1b[0m");

				case "lime":

					setupLime ();

				case "openfl":

					setupOpenFL ();

				case "tvos", "tvsim":

					if (PlatformHelper.hostPlatform == Platform.MAC) {

						setupIOS ();

					}

				case "":

					switch (CommandLineTools.defaultLibrary) {

						case "lime": setupLime ();
						case "openfl": setupOpenFL ();
						default: setupHaxelib (new Haxelib (CommandLineTools.defaultLibrary));

					}

				default:

					setupHaxelib (new Haxelib (target));

			}

		} catch (e:Eof) {



		}

	}


	private static function runInstaller (path:String, message:String = "Waiting for process to complete..."):Void {

		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {

			try {

				LogHelper.println (message);
				ProcessHelper.runCommand ("", "call", [ path ], false);
				LogHelper.println ("Done");

			} catch (e:Dynamic) {}

		} else if (PlatformHelper.hostPlatform == Platform.LINUX) {

			if (Path.extension (path) == "deb") {

				ProcessHelper.runCommand ("", "sudo", [ "dpkg", "-i", "--force-architecture", path ], false);

			} else {

				LogHelper.println (message);
				Sys.command ("chmod", [ "755", path ]);

				if (path.substr (0, 1) == "/") {

					ProcessHelper.runCommand ("", path, [], false);

				} else {

					ProcessHelper.runCommand ("", "./" + path, [], false);

				}

				LogHelper.println ("Done");

			}

		} else {

			if (Path.extension (path) == "") {

				LogHelper.println (message);
				Sys.command ("chmod", [ "755", path ]);
				ProcessHelper.runCommand ("", path, [], false);
				LogHelper.println ("Done");

			} else if (Path.extension (path) == "dmg") {

				var process = new Process("hdiutil", [ "mount", path ]);
				var ret = process.stdout.readAll().toString();
				process.exitCode(); //you need this to wait till the process is closed!
				process.close();

				var volumePath = "";

				if (ret != null && ret != "") {

					volumePath = StringTools.trim (ret.substr (ret.indexOf ("/Volumes")));

				}

				if (volumePath != "" && FileSystem.exists (volumePath)) {

					var apps = [];
					var packages = [];
					var executables = [];

					var files:Array<String> = FileSystem.readDirectory (volumePath);

					for (file in files) {

						switch (Path.extension (file)) {

							case "app":

								apps.push (file);

							case "pkg", "mpkg":

								packages.push (file);

							case "bin":

								executables.push (file);

						}

					}

					var file = "";

					if (apps.length == 1) {

						file = apps[0];

					} else if (packages.length == 1) {

						file = packages[0];

					} else if (executables.length == 1) {

						file = executables[0];

					}

					if (file != "") {

						LogHelper.println (message);
						ProcessHelper.runCommand ("", "open", [ "-W", volumePath + "/" + file ], false);
						LogHelper.println ("Done");

					}

					try {

						var process = new Process("hdiutil", [ "unmount", path ]);
						process.exitCode(); //you need this to wait till the process is closed!
						process.close();

					} catch (e:Dynamic) {

					}

					if (file == "") {

						ProcessHelper.runCommand ("", "open", [ path ], false);

					}

				} else {

					ProcessHelper.runCommand ("", "open", [ path ], false);

				}

			} else {

				ProcessHelper.runCommand ("", "open", [ path ], false);

			}

		}

	}


	public static function setupAIR ():Void {

		LogHelper.println ("\x1b[1mIn order to package SWF applications using Adobe AIR, you must");
		LogHelper.println ("download and extract the Adobe AIR SDK.");
		LogHelper.println ("");

		getDefineValue ("AIR_SDK", "Path to AIR SDK");

		LogHelper.println ("");
		LogHelper.println ("Setup complete.");

	}


	public static function setupAndroid ():Void {

		LogHelper.println ("\x1b[1mIn order to build applications for Android, you must have recent");
		LogHelper.println ("versions of the Android SDK, Android NDK and Java JDK installed.");
		LogHelper.println ("");
		LogHelper.println ("You must also install the Android SDK Platform-tools and API 19 using");
		LogHelper.println ("the SDK manager from Android Studio.\x1b[0m");
		LogHelper.println ("");

		getDefineValue ("ANDROID_SDK", "Path to Android SDK");
		getDefineValue ("ANDROID_NDK_ROOT", "Path to Android NDK");

		if (PlatformHelper.hostPlatform != Platform.MAC) {

			getDefineValue ("JAVA_HOME", "Path to Java JDK");

		}

		if (ConfigHelper.getConfigValue ("ANDROID_SETUP") == null) {

			ConfigHelper.writeConfigValue ("ANDROID_SETUP", "true");

		}

		LogHelper.println ("");
		LogHelper.println ("Setup complete.");

	}


	public static function setupElectron ():Void {

		LogHelper.println ("\x1b[1mIn order to run Electron applications, you must download");
		LogHelper.println ("and extract the Electron runtime on your system.");
		LogHelper.println ("");

		getDefineValue ("ELECTRON_PATH", "Path to Electron runtime");

		LogHelper.println ("");
		HaxelibHelper.runCommand ("", [ "install", "electron" ], true, true);

		LogHelper.println ("");
		LogHelper.println ("Setup complete.");

	}


	public static function setupEmscripten ():Void {

		LogHelper.println ("\x1b[1mIn order to build for WebAssembly or asm.js, you must download");
		LogHelper.println ("and install the Emscripten SDK.");
		LogHelper.println ("");

		getDefineValue ("EMSCRIPTEN_SDK", "Path to Emscripten SDK");

		LogHelper.println ("");
		LogHelper.println ("Setup complete.");

	}


	public static function setupHaxelib (haxelib:Haxelib, dependency:Bool = false):Void {

		setupHaxelibs.set (haxelib.name, true);

		var defines = new Map<String, Dynamic> ();
		defines.set ("setup", 1);

		var basePath = HaxelibHelper.runProcess ("", [ "config" ]);
		if (basePath != null) {

			basePath = StringTools.trim (basePath.split ("\n")[0]);

		}
		var lib = HaxelibHelper.getPath (haxelib, false, true);
		if (lib != null && !StringTools.startsWith (PathHelper.standardize (lib), PathHelper.standardize (basePath))) {

			defines.set ("dev", 1);

		}

		var project = Project.fromHaxelib (haxelib, defines, true);

		if (project != null && project.haxelibs.length > 0) {

			for (lib in project.haxelibs) {

				if (setupHaxelibs.exists (lib.name)) continue;

				var path = HaxelibHelper.getPath (lib, false, true);

				if (path == null || path == "" || (lib.version != null && lib.version != "")) {

					if (defines.exists ("dev")) {

						LogHelper.error ("Could not find dependency \"" + lib.name + "\" for library \"" + haxelib.name + "\"");

					}

					installHaxelib (lib);

				} else /*if (userDefines.exists ("upgrade"))*/ {

					updateHaxelib (lib);

				}

				setupHaxelib (lib, true);

			}

		} else if (!dependency) {

			//LogHelper.warn ("No setup is required for " + haxelib.name + ", or it is not a valid target");

		}

	}


	public static function setupHTML5 ():Void {

		// var setApacheCordova = false;

		// var defines = getDefines ();
		// var answer = CLIHelper.ask ("Download and install Apache Cordova?");

		// if (answer == YES || answer == ALWAYS) {

		// 	var downloadPath = "";
		// 	var defaultInstallPath = "";

		// 	if (PlatformHelper.hostPlatform == Platform.WINDOWS) {

		// 		defaultInstallPath = "C:\\Development\\Apache Cordova";

		// 	} else {

		// 		defaultInstallPath = "/opt/cordova";

		// 	}

		// 	var path = unescapePath (CLIHelper.param ("Output directory [" + defaultInstallPath + "]"));
		// 	path = createPath (path, defaultInstallPath);

		// 	downloadFile (apacheCordovaPath);
		// 	extractFile (Path.withoutDirectory (apacheCordovaPath), path, "*");

		// 	var childArchives = [];

		// 	for (file in FileSystem.readDirectory (path)) {

		// 		if (Path.extension (file) == "zip") {

		// 			childArchives.push (file);

		// 		}

		// 	}

		// 	createPath (path + "/lib");
		// 	var libs = [ "android", "bada-wac", "bada", "blackberry", "ios", "mac", "qt", "tizen", "tvos", "webos", "wp7" ];

		// 	for (archive in childArchives) {

		// 		var name = Path.withoutExtension (archive);
		// 		name = StringTools.replace (name, "incubator-", "");
		// 		name = StringTools.replace (name, "cordova-", "");

		// 		if (name == "blackberry-webworks") {

		// 			name = "blackberry";

		// 		}

		// 		var basePath = path + "/";

		// 		for (lib in libs) {

		// 			if (name == lib) {

		// 				basePath += "lib/";

		// 			}

		// 		}

		// 		createPath (basePath + name);
		// 		extractFile (path + "/" + archive, basePath + name);

		// 	}

		// 	if (PlatformHelper.hostPlatform != Platform.WINDOWS) {

		// 		ProcessHelper.runCommand ("", "chmod", [ "-R", "777", path ], false);

		// 	}

		// 	setApacheCordova = true;
		// 	defines.set ("CORDOVA_PATH", path);
		// 	writeConfig (defines.get ("LIME_CONFIG"), defines);
		// 	LogHelper.println ("");

		// }

		// var requiredVariables = [];
		// var requiredVariableDescriptions = [];

		// if (!setApacheCordova) {

		// 	requiredVariables.push ("CORDOVA_PATH");
		// 	requiredVariableDescriptions.push ("Path to Apache Cordova");

		// }

		// requiredVariables = requiredVariables.concat ([ "WEBWORKS_SDK", "WEBWORKS_SDK_BBOS", "WEBWORKS_SDK_PLAYBOOK" ]);
		// requiredVariableDescriptions = requiredVariableDescriptions.concat ([ "Path to WebWorks SDK for BlackBerry 10", "Path to WebWorks SDK for BBOS", "Path to WebWorks SDK for PlayBook" ]);

		// defines = getDefines (requiredVariables, requiredVariableDescriptions);

		// defines.set ("CORDOVA_PATH", unescapePath (defines.get ("CORDOVA_PATH")));
		// defines.set ("WEBWORKS_SDK_BBOS", unescapePath (defines.get ("WEBWORKS_SDK_BBOS")));
		// defines.set ("WEBWORKS_SDK_PLAYBOOK", unescapePath (defines.get ("WEBWORKS_SDK_PLAYBOOK")));

		// // temporary hack

		// /*Sys.println ("");
		// Sys.println ("Setting Apache Cordova install path...");
		// ProcessHelper.runCommand (defines.get ("CORDOVA_PATH") + "/lib/ios", "make", [ "install" ], true, true);
		// Sys.println ("Done.");*/

		// writeConfig (defines.get ("LIME_CONFIG"), defines);

		// HaxelibHelper.runCommand ("", [ "install", "cordova" ], true, true);

	}


	public static function setupIOS ():Void {

		LogHelper.println ("\x1b[1mIn order to build applications for iOS and tvOS, you must have");
		LogHelper.println ("Xcode installed. Xcode is available from Apple as a free download.\x1b[0m");
		LogHelper.println ("");
		LogHelper.println ("\x1b[0;3mNo additional configuration is required.\x1b[0m");
		LogHelper.println ("");

		var answer = CLIHelper.ask ("Would you like to visit the download page now?");

		if (answer == YES || answer == ALWAYS) {

			ProcessHelper.openURL (appleXcodeURL);

		}

	}


	public static function setupLime ():Void {

		if (!targetFlags.exists ("alias") && !targetFlags.exists ("cli")) {

			setupHaxelib (new Haxelib ("lime"));

		}

		var haxePath = Sys.getEnv ("HAXEPATH");

		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {

			if (haxePath == null || haxePath == "") {

				haxePath = "C:\\HaxeToolkit\\haxe\\";

			}

			try { File.copy (HaxelibHelper.getPath (new Haxelib ("lime")) + "\\templates\\\\bin\\lime.exe", haxePath + "\\lime.exe"); } catch (e:Dynamic) {}
			try { File.copy (HaxelibHelper.getPath (new Haxelib ("lime")) + "\\templates\\\\bin\\lime.sh", haxePath + "\\lime"); } catch (e:Dynamic) {}

		} else {

			if (haxePath == null || haxePath == "") {

				haxePath = "/usr/lib/haxe";

			}

			var installedCommand = false;
			var answer = YES;

			if (targetFlags.exists ("y")) {

				Sys.println ("Do you want to install the \"lime\" command? [y/n/a] y");

			} else {

				answer = CLIHelper.ask ("Do you want to install the \"lime\" command?");

			}

			if (answer == YES || answer == ALWAYS) {

				try {

					ProcessHelper.runCommand ("", "sudo", [ "cp", "-f", HaxelibHelper.getPath (new Haxelib ("lime")) + "/templates/bin/lime.sh", "/usr/local/bin/lime" ], false);
					ProcessHelper.runCommand ("", "sudo", [ "chmod", "755", "/usr/local/bin/lime" ], false);
					installedCommand = true;

				} catch (e:Dynamic) {}

			}

			if (!installedCommand) {

				Sys.println ("");
				Sys.println ("To finish setup, we recommend you either...");
				Sys.println ("");
				Sys.println (" a) Manually add an alias called \"lime\" to run \"haxelib run lime\"");
				Sys.println (" b) Run the following commands:");
				Sys.println ("");
				Sys.println ("sudo cp \"" + PathHelper.combine (HaxelibHelper.getPath (new Haxelib ("lime")), "templates/bin/lime.sh") + "\" /usr/local/bin/lime");
				Sys.println ("sudo chmod 755 /usr/local/bin/lime");
				Sys.println ("");

			}

		}

		if (PlatformHelper.hostPlatform == Platform.MAC) {

			ConfigHelper.writeConfigValue ("MAC_USE_CURRENT_SDK", "1");

		}

	}


	public static function setupLinux ():Void {

		var whichAptGet = ProcessHelper.runProcess ("", "which", ["apt-get"], true, true, true);
		var hasApt = whichAptGet != null && whichAptGet != "";

		if (hasApt) {

			// check if this is ubuntu saucy 64bit, which uses different packages.
			var lsbId = ProcessHelper.runProcess ("", "lsb_release", ["-si"], true, true, true);
			var lsbRelease = ProcessHelper.runProcess ("", "lsb_release", ["-sr"], true, true, true);
			var arch = ProcessHelper.runProcess ("", "uname", ["-m"], true, true, true);
			var isSaucy = lsbId == "Ubuntu\n" &&  lsbRelease >= "13.10\n" && arch == "x86_64\n";

			var packages = isSaucy ? linuxUbuntuSaucyPackages : linuxAptPackages;

			var parameters = [ "apt-get", "install" ].concat (packages.split (" "));
			ProcessHelper.runCommand ("", "sudo", parameters, false);

			LogHelper.println ("");
			LogHelper.println ("Setup complete.");
			return;

		}

		var whichYum = ProcessHelper.runProcess ("", "which", ["yum"], true, true, true);
		var hasYum = whichYum != null && whichYum != "";

		if (hasYum) {

			var parameters = [ "yum", "install" ].concat (linuxYumPackages.split (" "));
			ProcessHelper.runCommand ("", "sudo", parameters, false);

			LogHelper.println ("");
			LogHelper.println ("Setup complete.");
			return;

		}

		var whichDnf = ProcessHelper.runProcess ("", "which", ["dnf"], true, true, true);
		var hasDnf = whichDnf != null && whichDnf != "";

		if (hasDnf) {

			var parameters = [ "dnf", "install" ].concat (linuxDnfPackages.split (" "));
			ProcessHelper.runCommand ("", "sudo", parameters, false);

			LogHelper.println ("");
			LogHelper.println ("Setup complete.");
			return;

		}

		var whichEquo = ProcessHelper.runProcess ("", "which", ["equo"], true,true, true);
		var hasEquo = whichEquo != null && whichEquo != "";

		if (hasEquo) {

			// Sabayon docs recommend not using sudo with equo, and instead using a root login shell
			var parameters = [ "-l", "-c", "equo", "i", "-av" ].concat (linuxEquoPackages.split (" "));
			ProcessHelper.runCommand ("", "su", parameters, false);

			LogHelper.println ("");
			LogHelper.println ("Setup complete.");
			return;

		}

		var whichEmerge = ProcessHelper.runProcess ("", "which", ["emerge"], true,true, true);
		var hasEmerge = whichEmerge != null && whichEmerge != "";

		if (hasEmerge) {

			var parameters = [ "emerge", "-av" ].concat (linuxEmergePackages.split (" "));
			ProcessHelper.runCommand ("", "sudo", parameters, false);

			LogHelper.println ("");
			LogHelper.println ("Setup complete.");
			return;

		}

		var whichPacman = ProcessHelper.runProcess ("", "which", ["pacman"], true, true, true);
		var hasPacman = whichPacman != null && whichPacman != "";

		if (hasPacman) {

			var parameters = [ "pacman", "-S", "--needed" ];

			if (PlatformHelper.hostArchitecture == X64) {

				parameters = parameters.concat (linuxPacman64Packages.split (" "));

			} else {

				parameters = parameters.concat (linuxPacman32Packages.split (" "));

			}

			ProcessHelper.runCommand ("", "sudo", parameters, false);

			LogHelper.println ("");
			LogHelper.println ("Setup complete.");
			return;

		}

		LogHelper.println ("Unable to find a supported package manager on your Linux distribution.");
		LogHelper.println ("Currently apt-get, yum, dnf, equo, emerge, and pacman are supported.");

		Sys.exit (1);

	}


	public static function setupMac ():Void {

		LogHelper.println ("\x1b[1mIn order to build native executables for macOS, you must have");
		LogHelper.println ("Xcode installed. Xcode is available from Apple as a free download.\x1b[0m");
		LogHelper.println ("");
		LogHelper.println ("\x1b[0;3mNo additional configuration is required.\x1b[0m");
		LogHelper.println ("");

		var answer = CLIHelper.ask ("Would you like to visit the download page now?");

		if (answer == YES || answer == ALWAYS) {

			ProcessHelper.openURL (appleXcodeURL);

		}

	}


	public static function setupOpenFL ():Void {

		if (!targetFlags.exists ("alias") && !targetFlags.exists ("cli")) {

			setupHaxelib (new Haxelib ("openfl"));

		}

		var haxePath = Sys.getEnv ("HAXEPATH");
		var project = null;

		try {

			project = Project.fromHaxelib (new Haxelib ("openfl"));

		} catch (e:Dynamic) {}

		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {

			if (haxePath == null || haxePath == "") {

				haxePath = "C:\\HaxeToolkit\\haxe\\";

			}

			try { File.copy (HaxelibHelper.getPath (new Haxelib ("lime")) + "\\templates\\\\bin\\lime.exe", haxePath + "\\lime.exe"); } catch (e:Dynamic) {}
			try { File.copy (HaxelibHelper.getPath (new Haxelib ("lime")) + "\\templates\\\\bin\\lime.sh", haxePath + "\\lime"); } catch (e:Dynamic) {}

			try {

				FileHelper.copyFileTemplate (project.templatePaths, "bin/openfl.exe", haxePath + "\\openfl.exe");
				FileHelper.copyFileTemplate (project.templatePaths, "bin/openfl.sh", haxePath + "\\openfl");

			} catch (e:Dynamic) {}

		} else {

			if (haxePath == null || haxePath == "") {

				haxePath = "/usr/lib/haxe";

			}

			var installedCommand = false;
			var answer = YES;

			if (targetFlags.exists ("y")) {

				Sys.println ("Do you want to install the \"openfl\" command? [y/n/a] y");

			} else {

				answer = CLIHelper.ask ("Do you want to install the \"openfl\" command?");

			}

			if (answer == YES || answer == ALWAYS) {

				try {

					ProcessHelper.runCommand ("", "sudo", [ "cp", "-f", HaxelibHelper.getPath (new Haxelib ("lime")) + "/templates/bin/lime.sh", "/usr/local/bin/lime" ], false);
					ProcessHelper.runCommand ("", "sudo", [ "chmod", "755", "/usr/local/bin/lime" ], false);
					ProcessHelper.runCommand ("", "sudo", [ "cp", "-f", PathHelper.findTemplate (project.templatePaths, "bin/openfl.sh"), "/usr/local/bin/openfl" ], false);
					ProcessHelper.runCommand ("", "sudo", [ "chmod", "755", "/usr/local/bin/openfl" ], false);
					installedCommand = true;

				} catch (e:Dynamic) {}

			}

			if (!installedCommand) {

				Sys.println ("");
				Sys.println ("To finish setup, we recommend you either...");
				Sys.println ("");
				Sys.println (" a) Manually add an alias called \"openfl\" to run \"haxelib run openfl\"");
				Sys.println (" b) Run the following commands:");
				Sys.println ("");
				Sys.println ("sudo cp \"" + PathHelper.combine (HaxelibHelper.getPath (new Haxelib ("lime")), "templates/bin/lime.sh") + "\" /usr/local/bin/lime");
				Sys.println ("sudo chmod 755 /usr/local/bin/lime");
				Sys.println ("sudo cp \"" + PathHelper.findTemplate (project.templatePaths, "bin/openfl.sh") + "\" /usr/local/bin/openfl");
				Sys.println ("sudo chmod 755 /usr/local/bin/openfl");
				Sys.println ("");

			}

		}

		if (PlatformHelper.hostPlatform == Platform.MAC) {

			ConfigHelper.writeConfigValue ("MAC_USE_CURRENT_SDK", "1");

		}

	}


	public static function setupWindows ():Void {

		LogHelper.println ("\x1b[1mIn order to build native executables for Windows, you must have a");
		LogHelper.println ("Visual Studio C++ compiler with \"Windows Desktop\" (Win32) support");
		LogHelper.println ("installed. We recommend using Visual Studio Community, which is");
		LogHelper.println ("available as a free download from Microsoft.\x1b[0m");
		LogHelper.println ("");
		LogHelper.println ("\x1b[0;3mNo additional configuration is required.\x1b[0m");
		LogHelper.println ("");

		var answer = CLIHelper.ask ("Would you like to visit the download page now?");

		if (answer == YES || answer == ALWAYS) {

			ProcessHelper.openURL (visualStudioURL);

		}

	}


	private static function throwPermissionsError () {

		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {

			LogHelper.println ("Unable to access directory. Perhaps you need to run \"setup\" with administrative privileges?");

		} else {

			LogHelper.println ("Unable to access directory. Perhaps you should run \"setup\" again using \"sudo\"");

		}

		Sys.exit (1);

	}


	private static function unescapePath (path:String):String {

		if (path == null) {

			path = "";

		}

		path = StringTools.replace (path, "\\ ", " ");

		if (PlatformHelper.hostPlatform != Platform.WINDOWS && StringTools.startsWith (path, "~/")) {

			path = Sys.getEnv ("HOME") + "/" + path.substr (2);

		}

		return path;

	}


	public static function updateHaxelib (haxelib:Haxelib):Void {

		var basePath = HaxelibHelper.runProcess ("", [ "config" ]);

		if (basePath != null) {

			basePath = StringTools.trim (basePath.split ("\n")[0]);

		}

		var lib = HaxelibHelper.getPath (haxelib, false, true);

		if (StringTools.startsWith (PathHelper.standardize (lib), PathHelper.standardize (basePath))) {

			HaxelibHelper.runCommand ("", [ "update", haxelib.name ]);

		} else {

			var git = PathHelper.combine (lib, ".git");

			if (FileSystem.exists (git)) {

				LogHelper.info (LogHelper.accentColor + "Updating \"" + haxelib.name + "\"" + LogHelper.resetColor);

				if (PlatformHelper.hostPlatform == Platform.WINDOWS) {

					var path = Sys.getEnv ("PATH");

					if (path.indexOf ("Git") == -1) {

						Sys.putEnv ("PATH", "C:\\Program Files (x86)\\Git\\bin;" + path);

					}

				}

				ProcessHelper.runCommand (lib, "git", [ "pull" ]);
				ProcessHelper.runCommand (lib, "git", [ "submodule", "init" ]);
				ProcessHelper.runCommand (lib, "git", [ "submodule", "update" ]);

			}

		}

	}


}


class Progress extends haxe.io.Output {

	var o : haxe.io.Output;
	var cur : Int;
	var max : Int;
	var start : Float;

	public function new(o) {
		this.o = o;
		cur = 0;
		start = haxe.Timer.stamp();
	}

	function bytes(n) {
		cur += n;
		if( max == null )
			Sys.print(cur+" bytes\r");
		else
			Sys.print(cur+"/"+max+" ("+Std.int((cur*100.0)/max)+"%)\r");
	}

	public override function writeByte(c) {
		o.writeByte(c);
		bytes(1);
	}

	public override function writeBytes(s,p,l) {
		var r = o.writeBytes(s,p,l);
		bytes(r);
		return r;
	}

	public override function close() {
		super.close();
		o.close();
		var time = haxe.Timer.stamp() - start;
		var speed = (cur / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;

		// When the path is a redirect, we don't want to display that the download completed

		if (cur > 400) {

			Sys.print("Download complete : " + cur + " bytes in " + time + "s (" + speed + "KB/s)\n");

		}

	}

	public override function prepare(m) {
		max = m;
	}

}
