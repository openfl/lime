package utils;

import haxe.Http;
import haxe.io.Eof;
import haxe.zip.Reader;
import hxp.*;
import lime.tools.CLIHelper;
import lime.tools.ConfigHelper;
import lime.tools.Platform;
import lime.tools.HXProject;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class PlatformSetup
{
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
	private static var hashlinkURL = "https://github.com/HaxeFoundation/hashlink/releases";
	private static var triedSudo:Bool = false;
	private static var userDefines:Map<String, Dynamic>;
	private static var targetFlags:Map<String, Dynamic>;
	private static var setupHaxelibs = new Map<String, Bool>();

	private static function createPath(path:String, defaultPath:String = ""):String
	{
		try
		{
			if (path == "")
			{
				System.mkdir(defaultPath);
				return defaultPath;
			}
			else
			{
				System.mkdir(path);
				return path;
			}
		}
		catch (e:Dynamic)
		{
			throwPermissionsError();
			return "";
		}
	}

	private static function downloadFile(remotePath:String, localPath:String = "", followingLocation:Bool = false):Void
	{
		if (localPath == "")
		{
			localPath = Path.withoutDirectory(remotePath);
		}

		if (!followingLocation && FileSystem.exists(localPath))
		{
			var answer = CLIHelper.ask("File found. Install existing file?");

			if (answer != NO)
			{
				return;
			}
		}

		var out = File.write(localPath, true);
		var progress = new Progress(out);
		var h = new Http(remotePath);

		h.cnxTimeout = 30;

		h.onError = function(e)
		{
			progress.close();
			FileSystem.deleteFile(localPath);
			throw e;
		};

		if (!followingLocation)
		{
			Log.println("Downloading " + localPath + "...");
		}

		h.customRequest(false, progress);

		if (h.responseHeaders != null && h.responseHeaders.exists("Location"))
		{
			var location = h.responseHeaders.get("Location");

			if (location != remotePath)
			{
				downloadFile(location, localPath, true);
			}
		}
	}

	private static function extractFile(sourceZIP:String, targetPath:String, ignoreRootFolder:String = ""):Void
	{
		var extension = Path.extension(sourceZIP);

		if (extension != "zip")
		{
			var arguments = "xvzf";

			if (extension == "bz2" || extension == "tbz2")
			{
				arguments = "xvjf";
			}

			if (ignoreRootFolder != "")
			{
				if (ignoreRootFolder == "*")
				{
					for (file in FileSystem.readDirectory(targetPath))
					{
						if (FileSystem.isDirectory(targetPath + "/" + file))
						{
							ignoreRootFolder = file;
						}
					}
				}

				System.runCommand("", "tar", [arguments, sourceZIP], false);
				System.runCommand("", "cp", ["-R", ignoreRootFolder + "/.", targetPath], false);
				Sys.command("rm", ["-r", ignoreRootFolder]);
			}
			else
			{
				System.runCommand("", "tar", [arguments, sourceZIP, "-C", targetPath], false);

				// InstallTool.runCommand (targetPath, "tar", [ arguments, FileSystem.fullPath (sourceZIP) ]);
			}

			Sys.command("chmod", ["-R", "755", targetPath]);
		}
		else
		{
			var file = File.read(sourceZIP, true);
			var entries = Reader.readZip(file);
			file.close();

			for (entry in entries)
			{
				var fileName = entry.fileName;

				if (fileName.charAt(0) != "/" && fileName.charAt(0) != "\\" && fileName.split("..").length <= 1)
				{
					var dirs = ~/[\/\\]/g.split(fileName);

					if ((ignoreRootFolder != "" && dirs.length > 1) || ignoreRootFolder == "")
					{
						if (ignoreRootFolder != "")
						{
							dirs.shift();
						}

						var path = "";
						var file = dirs.pop();

						for (d in dirs)
						{
							path += d;
							System.mkdir(targetPath + "/" + path);
							path += "/";
						}

						if (file == "")
						{
							if (path != "") Log.println("  Created " + path);
							continue; // was just a directory
						}

						path += file;
						Log.println("  Install " + path);

						var data = Reader.unzip(entry);
						var f = File.write(targetPath + "/" + path, true);
						f.write(data);
						f.close();
					}
				}
			}
		}

		Log.println("Done");
	}

	public static function getDefineValue(name:String, description:String):Void
	{
		var value = ConfigHelper.getConfigValue(name);

		if (value == null && Sys.getEnv(name) != null)
		{
			value = Sys.getEnv(name);
		}

		var inputValue = unescapePath(CLIHelper.param(Log.accentColor + description + "\x1b[0m \x1b[37;3m[" + (value != null ? value : "") + "]\x1b[0m"));

		if (inputValue != "" && inputValue != value)
		{
			ConfigHelper.writeConfigValue(name, inputValue);
		}
		else if (inputValue == Sys.getEnv(inputValue))
		{
			ConfigHelper.removeConfigValue(name);
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
	// 		Log.println ("Warning : No 'HOME' variable set - ~/.lime/config.xml might be missing.");
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
	public static function installHaxelib(haxelib:Haxelib):Void
	{
		var name = haxelib.name;
		var version = haxelib.version;

		if (version != null && version.indexOf("*") > -1)
		{
			var regexp = new EReg("^.+[0-9]+-[0-9]+-[0-9]+ +[0-9]+:[0-9]+:[0-9]+ +([a-z0-9.-]+) +", "gi");
			var output = Haxelib.runProcess("", ["info", haxelib.name]);
			var lines = output.split("\n");

			var versions = new Array<Version>();
			var ver:Version;

			for (line in lines)
			{
				if (regexp.match(line))
				{
					try
					{
						ver = regexp.matched(1);
						versions.push(ver);
					}
					catch (e:Dynamic) {}
				}
			}

			var match = Haxelib.findMatch(haxelib, versions);

			if (match != null)
			{
				version = match;
			}
			else
			{
				Log.error("Could not find version \"" + haxelib.version + "\" for haxelib \"" + haxelib.name + "\"");
			}
		}

		var args = ["install", name];

		if (version != null && version != "" && version.indexOf("*") == -1)
		{
			args.push(version);
		}

		Haxelib.runCommand("", args);
	}

	private static function link(dir:String, file:String, dest:String):Void
	{
		Sys.command("rm -rf " + dest + "/" + file);
		Sys.command("ln -s " + "/usr/lib" + "/" + dir + "/" + file + " " + dest + "/" + file);
	}

	private static function openURL(url:String):Void
	{
		if (System.hostPlatform == WINDOWS)
		{
			Sys.command("explorer", [url]);
		}
		else if (System.hostPlatform == LINUX)
		{
			System.runCommand("", "xdg-open", [url], false);
		}
		else
		{
			System.runCommand("", "open", [url], false);
		}
	}

	public static function run(target:String = "", userDefines:Map<String, Dynamic> = null, targetFlags:Map<String, Dynamic> = null)
	{
		PlatformSetup.userDefines = userDefines;
		PlatformSetup.targetFlags = targetFlags;

		try
		{
			if (target == "cpp")
			{
				switch (System.hostPlatform)
				{
					case WINDOWS:
						target = "windows";
					case MAC:
						target = "mac";
					case LINUX:
						target = "linux";
					default:
				}
			}

			switch (target)
			{
				case "air":
					setupAIR();

				case "android":
					setupAndroid();

				case "blackberry":

				// setupBlackBerry ();

				case "emscripten", "webassembly", "wasm":
					setupEmscripten();

				case "html5":
					Log.println("\x1b[0;3mNo additional configuration is required.\x1b[0m");
				// setupHTML5 ();

				case "ios", "iphoneos", "iphonesim":
					if (System.hostPlatform == MAC)
					{
						setupIOS();
					}

				case "linux":
					if (System.hostPlatform == LINUX)
					{
						setupLinux();
					}

				case "mac", "macos":
					if (System.hostPlatform == MAC)
					{
						setupMac();
					}

				case "tizen":

				// setupTizen ();

				case "webos":

				// setupWebOS ();

				case "electron":
					setupElectron();

				case "windows", "winrt":
					if (System.hostPlatform == WINDOWS)
					{
						setupWindows();
					}

				case "neko", "cs", "uwp", "winjs", "nodejs", "java":
					Log.println("\x1b[0;3mNo additional configuration is required.\x1b[0m");

				case "hl", "hashlink":
					setupHL();

				case "lime":
					setupLime();

				case "openfl":
					setupOpenFL();

				case "tvos", "tvsim":
					if (System.hostPlatform == MAC)
					{
						setupIOS();
					}

				case "":
					switch (CommandLineTools.defaultLibrary)
					{
						case "lime": setupLime();
						case "openfl": setupOpenFL();
						default: setupHaxelib(new Haxelib(CommandLineTools.defaultLibrary));
					}

				default:
					setupHaxelib(new Haxelib(target));
			}
		}
		catch (e:Eof) {}
	}

	private static function runInstaller(path:String, message:String = "Waiting for process to complete..."):Void
	{
		if (System.hostPlatform == WINDOWS)
		{
			try
			{
				Log.println(message);
				System.runCommand("", "call", [path], false);
				Log.println("Done");
			}
			catch (e:Dynamic) {}
		}
		else if (System.hostPlatform == LINUX)
		{
			if (Path.extension(path) == "deb")
			{
				System.runCommand("", "sudo", ["dpkg", "-i", "--force-architecture", path], false);
			}
			else
			{
				Log.println(message);
				Sys.command("chmod", ["755", path]);

				if (path.substr(0, 1) == "/")
				{
					System.runCommand("", path, [], false);
				}
				else
				{
					System.runCommand("", "./" + path, [], false);
				}

				Log.println("Done");
			}
		}
		else
		{
			if (Path.extension(path) == "")
			{
				Log.println(message);
				Sys.command("chmod", ["755", path]);
				System.runCommand("", path, [], false);
				Log.println("Done");
			}
			else if (Path.extension(path) == "dmg")
			{
				var process = new Process("hdiutil", ["mount", path]);
				var ret = process.stdout.readAll().toString();
				process.exitCode(); // you need this to wait till the process is closed!
				process.close();

				var volumePath = "";

				if (ret != null && ret != "")
				{
					volumePath = StringTools.trim(ret.substr(ret.indexOf("/Volumes")));
				}

				if (volumePath != "" && FileSystem.exists(volumePath))
				{
					var apps = [];
					var packages = [];
					var executables = [];

					var files:Array<String> = FileSystem.readDirectory(volumePath);

					for (file in files)
					{
						switch (Path.extension(file))
						{
							case "app":
								apps.push(file);

							case "pkg", "mpkg":
								packages.push(file);

							case "bin":
								executables.push(file);
						}
					}

					var file = "";

					if (apps.length == 1)
					{
						file = apps[0];
					}
					else if (packages.length == 1)
					{
						file = packages[0];
					}
					else if (executables.length == 1)
					{
						file = executables[0];
					}

					if (file != "")
					{
						Log.println(message);
						System.runCommand("", "open", ["-W", volumePath + "/" + file], false);
						Log.println("Done");
					}

					try
					{
						var process = new Process("hdiutil", ["unmount", path]);
						process.exitCode(); // you need this to wait till the process is closed!
						process.close();
					}
					catch (e:Dynamic) {}

					if (file == "")
					{
						System.runCommand("", "open", [path], false);
					}
				}
				else
				{
					System.runCommand("", "open", [path], false);
				}
			}
			else
			{
				System.runCommand("", "open", [path], false);
			}
		}
	}

	public static function setupAIR():Void
	{
		Log.println("\x1b[1mIn order to package SWF applications using Adobe AIR, you must");
		Log.println("download and extract the Adobe AIR SDK.");
		Log.println("");

		getDefineValue("AIR_SDK", "Path to AIR SDK");

		Log.println("");
		Log.println("Setup complete.");
	}

	public static function setupAndroid():Void
	{
		Log.println("\x1b[1mIn order to build applications for Android, you must have recent");
		Log.println("versions of the Android SDK, Android NDK and Java JDK installed.");
		Log.println("");
		Log.println("You must also install the Android SDK Platform-tools and API 19 using");
		Log.println("the SDK manager from Android Studio.\x1b[0m");
		Log.println("");

		getDefineValue("ANDROID_SDK", "Path to Android SDK");
		getDefineValue("ANDROID_NDK_ROOT", "Path to Android NDK");

		if (System.hostPlatform != MAC)
		{
			getDefineValue("JAVA_HOME", "Path to Java JDK");
		}

		if (ConfigHelper.getConfigValue("ANDROID_SETUP") == null)
		{
			ConfigHelper.writeConfigValue("ANDROID_SETUP", "true");
		}

		Log.println("");
		Log.println("Setup complete.");
	}

	public static function setupElectron():Void
	{
		Log.println("\x1b[1mIn order to run Electron applications, you must download");
		Log.println("and extract the Electron runtime on your system.");
		Log.println("");

		getDefineValue("ELECTRON_PATH", "Path to Electron runtime");

		Log.println("");
		Haxelib.runCommand("", ["install", "electron"], true, true);

		Log.println("");
		Log.println("Setup complete.");
	}

	public static function setupEmscripten():Void
	{
		Log.println("\x1b[1mIn order to build for WebAssembly or asm.js, you must download");
		Log.println("and install the Emscripten SDK.");
		Log.println("");

		getDefineValue("EMSCRIPTEN_SDK", "Path to Emscripten SDK");

		Log.println("");
		Log.println("Setup complete.");
	}

	public static function setupHaxelib(haxelib:Haxelib, dependency:Bool = false):Void
	{
		setupHaxelibs.set(haxelib.name, true);

		var defines = new Map<String, Dynamic>();
		defines.set("setup", 1);

		var basePath = Haxelib.runProcess("", ["config"]);
		if (basePath != null)
		{
			basePath = StringTools.trim(basePath.split("\n")[0]);
		}
		var lib = Haxelib.getPath(haxelib, false, true);
		if (lib != null && !StringTools.startsWith(Path.standardize(lib), Path.standardize(basePath)))
		{
			defines.set("dev", 1);
		}

		var project = HXProject.fromHaxelib(haxelib, defines, true);

		if (project != null && project.haxelibs.length > 0)
		{
			for (lib in project.haxelibs)
			{
				if (setupHaxelibs.exists(lib.name)) continue;

				var path = Haxelib.getPath(lib, false, true);

				if (path == null || path == "" || (lib.version != null && lib.version != ""))
				{
					if (defines.exists("dev"))
					{
						Log.error("Could not find dependency \"" + lib.name + "\" for library \"" + haxelib.name + "\"");
					}

					installHaxelib(lib);
				}
				else
					/*if (userDefines.exists ("upgrade"))*/
				{
					updateHaxelib(lib);
				}

				setupHaxelib(lib, true);
			}
		}
		else if (!dependency)
		{
			// Log.warn ("No setup is required for " + haxelib.name + ", or it is not a valid target");
		}
	}

	public static function setupHTML5():Void
	{
		// var setApacheCordova = false;

		// var defines = getDefines ();
		// var answer = CLIHelper.ask ("Download and install Apache Cordova?");

		// if (answer == YES || answer == ALWAYS) {

		// 	var downloadPath = "";
		// 	var defaultInstallPath = "";

		// 	if (System.hostPlatform == WINDOWS) {

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

		// 	if (System.hostPlatform != WINDOWS) {

		// 		System.runCommand ("", "chmod", [ "-R", "777", path ], false);

		// 	}

		// 	setApacheCordova = true;
		// 	defines.set ("CORDOVA_PATH", path);
		// 	writeConfig (defines.get ("LIME_CONFIG"), defines);
		// 	Log.println ("");

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
		// System.runCommand (defines.get ("CORDOVA_PATH") + "/lib/ios", "make", [ "install" ], true, true);
		// Sys.println ("Done.");*/

		// writeConfig (defines.get ("LIME_CONFIG"), defines);

		// Haxelib.runCommand ("", [ "install", "cordova" ], true, true);
	}

	public static function setupIOS():Void
	{
		Log.println("\x1b[1mIn order to build applications for iOS and tvOS, you must have");
		Log.println("Xcode installed. Xcode is available from Apple as a free download.\x1b[0m");
		Log.println("");
		Log.println("\x1b[0;3mNo additional configuration is required.\x1b[0m");
		Log.println("");

		var answer = CLIHelper.ask("Would you like to visit the download page now?");

		if (answer == YES || answer == ALWAYS)
		{
			System.openURL(appleXcodeURL);
		}
	}

	public static function setupLime():Void
	{
		if (!targetFlags.exists("alias") && !targetFlags.exists("cli"))
		{
			setupHaxelib(new Haxelib("lime"));
		}

		var haxePath = Sys.getEnv("HAXEPATH");

		if (System.hostPlatform == WINDOWS)
		{
			if (haxePath == null || haxePath == "")
			{
				haxePath = "C:\\HaxeToolkit\\haxe\\";
			}

			try
			{
				File.copy(Haxelib.getPath(new Haxelib("lime")) + "\\templates\\\\bin\\lime.exe", haxePath + "\\lime.exe");
			}
			catch (e:Dynamic) {}
			try
			{
				File.copy(Haxelib.getPath(new Haxelib("lime")) + "\\templates\\\\bin\\lime.sh", haxePath + "\\lime");
			}
			catch (e:Dynamic) {}
		}
		else
		{
			if (haxePath == null || haxePath == "")
			{
				haxePath = "/usr/lib/haxe";
			}

			var installedCommand = false;
			var answer = YES;

			if (targetFlags.exists("y"))
			{
				Sys.println("Do you want to install the \"lime\" command? [y/n/a] y");
			}
			else
			{
				answer = CLIHelper.ask("Do you want to install the \"lime\" command?");
			}

			if (answer == YES || answer == ALWAYS)
			{
				if (System.hostPlatform == MAC)
				{
					try
					{
						System.runCommand("", "cp", [
							"-f",
							Haxelib.getPath(new Haxelib("lime")) + "/templates/bin/lime.sh",
							"/usr/local/bin/lime"
						], false);
						System.runCommand("", "chmod", ["755", "/usr/local/bin/lime"], false);
						installedCommand = true;
					}
					catch (e:Dynamic) {}
				}
				else
				{
					try
					{
						System.runCommand("", "sudo", [
							"cp",
							"-f",
							Haxelib.getPath(new Haxelib("lime")) + "/templates/bin/lime.sh",
							"/usr/local/bin/lime"
						], false);
						System.runCommand("", "sudo", ["chmod", "755", "/usr/local/bin/lime"], false);
						installedCommand = true;
					}
					catch (e:Dynamic) {}
				}
			}

			if (!installedCommand)
			{
				Sys.println("");
				Sys.println("To finish setup, we recommend you either...");
				Sys.println("");
				Sys.println(" a) Manually add an alias called \"lime\" to run \"haxelib run lime\"");
				Sys.println(" b) Run the following commands:");
				Sys.println("");
				Sys.println("sudo cp \"" + Path.combine(Haxelib.getPath(new Haxelib("lime")), "templates/bin/lime.sh") + "\" /usr/local/bin/lime");
				Sys.println("sudo chmod 755 /usr/local/bin/lime");
				Sys.println("");
			}
		}

		if (System.hostPlatform == MAC)
		{
			ConfigHelper.writeConfigValue("MAC_USE_CURRENT_SDK", "1");
		}
	}

	public static function setupLinux():Void
	{
		var whichAptGet = System.runProcess("", "which", ["apt-get"], true, true, true);
		var hasApt = whichAptGet != null && whichAptGet != "";

		if (hasApt)
		{
			// check if this is ubuntu saucy 64bit, which uses different packages.
			var lsbId = System.runProcess("", "lsb_release", ["-si"], true, true, true);
			var lsbRelease = System.runProcess("", "lsb_release", ["-sr"], true, true, true);
			var arch = System.runProcess("", "uname", ["-m"], true, true, true);
			var isSaucy = lsbId == "Ubuntu\n" && lsbRelease >= "13.10\n" && arch == "x86_64\n";

			var packages = isSaucy ? linuxUbuntuSaucyPackages : linuxAptPackages;

			var parameters = ["apt-get", "install"].concat(packages.split(" "));
			System.runCommand("", "sudo", parameters, false);

			Log.println("");
			Log.println("Setup complete.");
			return;
		}

		var whichYum = System.runProcess("", "which", ["yum"], true, true, true);
		var hasYum = whichYum != null && whichYum != "";

		if (hasYum)
		{
			var parameters = ["yum", "install"].concat(linuxYumPackages.split(" "));
			System.runCommand("", "sudo", parameters, false);

			Log.println("");
			Log.println("Setup complete.");
			return;
		}

		var whichDnf = System.runProcess("", "which", ["dnf"], true, true, true);
		var hasDnf = whichDnf != null && whichDnf != "";

		if (hasDnf)
		{
			var parameters = ["dnf", "install"].concat(linuxDnfPackages.split(" "));
			System.runCommand("", "sudo", parameters, false);

			Log.println("");
			Log.println("Setup complete.");
			return;
		}

		var whichEquo = System.runProcess("", "which", ["equo"], true, true, true);
		var hasEquo = whichEquo != null && whichEquo != "";

		if (hasEquo)
		{
			// Sabayon docs recommend not using sudo with equo, and instead using a root login shell
			var parameters = ["-l", "-c", "equo", "i", "-av"].concat(linuxEquoPackages.split(" "));
			System.runCommand("", "su", parameters, false);

			Log.println("");
			Log.println("Setup complete.");
			return;
		}

		var whichEmerge = System.runProcess("", "which", ["emerge"], true, true, true);
		var hasEmerge = whichEmerge != null && whichEmerge != "";

		if (hasEmerge)
		{
			var parameters = ["emerge", "-av"].concat(linuxEmergePackages.split(" "));
			System.runCommand("", "sudo", parameters, false);

			Log.println("");
			Log.println("Setup complete.");
			return;
		}

		var whichPacman = System.runProcess("", "which", ["pacman"], true, true, true);
		var hasPacman = whichPacman != null && whichPacman != "";

		if (hasPacman)
		{
			var parameters = ["pacman", "-S", "--needed"];

			if (System.hostArchitecture == X64)
			{
				parameters = parameters.concat(linuxPacman64Packages.split(" "));
			}
			else
			{
				parameters = parameters.concat(linuxPacman32Packages.split(" "));
			}

			System.runCommand("", "sudo", parameters, false);

			Log.println("");
			Log.println("Setup complete.");
			return;
		}

		Log.println("Unable to find a supported package manager on your Linux distribution.");
		Log.println("Currently apt-get, yum, dnf, equo, emerge, and pacman are supported.");

		Sys.exit(1);
	}

	public static function setupMac():Void
	{
		Log.println("\x1b[1mIn order to build native executables for macOS, you must have");
		Log.println("Xcode installed. Xcode is available from Apple as a free download.\x1b[0m");
		Log.println("");
		Log.println("\x1b[0;3mNo additional configuration is required.\x1b[0m");
		Log.println("");

		var answer = CLIHelper.ask("Would you like to visit the download page now?");

		if (answer == YES || answer == ALWAYS)
		{
			System.openURL(appleXcodeURL);
		}
	}

	public static function setupOpenFL():Void
	{
		if (!targetFlags.exists("alias") && !targetFlags.exists("cli"))
		{
			setupHaxelib(new Haxelib("openfl"));
		}

		var haxePath = Sys.getEnv("HAXEPATH");
		var project = null;

		try
		{
			project = HXProject.fromHaxelib(new Haxelib("openfl"));
		}
		catch (e:Dynamic) {}

		if (System.hostPlatform == WINDOWS)
		{
			if (haxePath == null || haxePath == "")
			{
				haxePath = "C:\\HaxeToolkit\\haxe\\";
			}

			try
			{
				File.copy(Haxelib.getPath(new Haxelib("lime")) + "\\templates\\\\bin\\lime.exe", haxePath + "\\lime.exe");
			}
			catch (e:Dynamic) {}
			try
			{
				File.copy(Haxelib.getPath(new Haxelib("lime")) + "\\templates\\\\bin\\lime.sh", haxePath + "\\lime");
			}
			catch (e:Dynamic) {}

			try
			{
				System.copyFileTemplate(project.templatePaths, "bin/openfl.exe", haxePath + "\\openfl.exe");
				System.copyFileTemplate(project.templatePaths, "bin/openfl.sh", haxePath + "\\openfl");
			}
			catch (e:Dynamic) {}
		}
		else
		{
			if (haxePath == null || haxePath == "")
			{
				haxePath = "/usr/lib/haxe";
			}

			var installedCommand = false;
			var answer = YES;

			if (targetFlags.exists("y"))
			{
				Sys.println("Do you want to install the \"openfl\" command? [y/n/a] y");
			}
			else
			{
				answer = CLIHelper.ask("Do you want to install the \"openfl\" command?");
			}

			if (answer == YES || answer == ALWAYS)
			{
				if (System.hostPlatform == MAC)
				{
					try
					{
						System.runCommand("", "cp", [
							"-f",
							Haxelib.getPath(new Haxelib("lime")) + "/templates/bin/lime.sh",
							"/usr/local/bin/lime"
						], false);
						System.runCommand("", "chmod", ["755", "/usr/local/bin/lime"], false);
						System.runCommand("", "cp", [
							"-f",
							System.findTemplate(project.templatePaths, "bin/openfl.sh"),
							"/usr/local/bin/openfl"
						], false);
						System.runCommand("", "chmod", ["755", "/usr/local/bin/openfl"], false);
						installedCommand = true;
					}
					catch (e:Dynamic) {}
				}
				else
				{
					System.runCommand("", "sudo", [
						"cp",
						"-f",
						Haxelib.getPath(new Haxelib("lime")) + "/templates/bin/lime.sh",
						"/usr/local/bin/lime"
					], false);
					System.runCommand("", "sudo", ["chmod", "755", "/usr/local/bin/lime"], false);
					System.runCommand("", "sudo", [
						"cp",
						"-f",
						System.findTemplate(project.templatePaths, "bin/openfl.sh"),
						"/usr/local/bin/openfl"
					], false);
					System.runCommand("", "sudo", ["chmod", "755", "/usr/local/bin/openfl"], false);
					installedCommand = true;
				}
			}

			if (!installedCommand)
			{
				Sys.println("");
				Sys.println("To finish setup, we recommend you either...");
				Sys.println("");
				Sys.println(" a) Manually add an alias called \"openfl\" to run \"haxelib run openfl\"");
				Sys.println(" b) Run the following commands:");
				Sys.println("");
				Sys.println("sudo cp \"" + Path.combine(Haxelib.getPath(new Haxelib("lime")), "templates/bin/lime.sh") + "\" /usr/local/bin/lime");
				Sys.println("sudo chmod 755 /usr/local/bin/lime");
				Sys.println("sudo cp \"" + System.findTemplate(project.templatePaths, "bin/openfl.sh") + "\" /usr/local/bin/openfl");
				Sys.println("sudo chmod 755 /usr/local/bin/openfl");
				Sys.println("");
			}
		}

		if (System.hostPlatform == MAC)
		{
			ConfigHelper.writeConfigValue("MAC_USE_CURRENT_SDK", "1");
		}
	}

	public static function setupWindows():Void
	{
		Log.println("\x1b[1mIn order to build native executables for Windows, you must have a");
		Log.println("Visual Studio C++ compiler with \"Windows Desktop\" (Win32) support");
		Log.println("installed. We recommend using Visual Studio Community, which is");
		Log.println("available as a free download from Microsoft.\x1b[0m");
		Log.println("");
		Log.println("\x1b[0;3mNo additional configuration is required.\x1b[0m");
		Log.println("");

		var answer = CLIHelper.ask("Would you like to visit the download page now?");

		if (answer == YES || answer == ALWAYS)
		{
			System.openURL(visualStudioURL);
		}
	}

	public static function setupHL():Void
	{
		getDefineValue("HL_PATH", "Path to a custom version of Hashlink. Leave empty to use lime's default version.");
		if (System.hostPlatform == MAC)
		{
			Log.println("To use the hashlink debugger on macOS, the hl executable needs to be signed.");
			if (ConfigHelper.getConfigValue("HL_PATH") != null)
			{
				Log.println("When building HL from source, make sure to have run `make codesign_osx` before installing.");
			}
			else
			{
				var answer = CLIHelper.ask("Would you like to do this now? (Requires sudo.)");

				if (answer == YES || answer == ALWAYS)
				{
					var openSSLConf = System.getTemporaryFile("cnf");
					var key = System.getTemporaryFile("pem");
					var cert = System.getTemporaryFile("cer");
					var limePath = Haxelib.getPath(new Haxelib("lime"));
					var hlPath = limePath + "/templates/bin/hl/mac/hl";
					var entitlementsPath = sys.FileSystem.exists(limePath + "/project") ? (limePath +
						"/project/lib/hashlink/other/osx/entitlements.xml") : (limePath
						+ "/templates/bin/hl/entitlements.xml");
					System.runCommand("", "sudo", ["security", "delete-identity", "-c", "hl-cert"], true, true, true);
					sys.io.File.saveContent(openSSLConf, [
						"[req]",
						"distinguished_name=codesign_dn",
						"[codesign_dn]",
						"commonName=hl-cert",
						"[v3_req]",
						"keyUsage=critical,digitalSignature",
						"extendedKeyUsage=critical,codeSigning",
					].join("\n"));
					System.runCommand("", "openssl", [
						"req", "-x509", "-newkey", "rsa:4096", "-keyout", key, "-nodes", "-days", "365", "-subj", "/CN=hl-cert", "-outform", "der", "-out",
						cert, "-extensions", "v3_req", "-config", openSSLConf
					], true, false, true);
					System.runCommand("", "sudo", [
						"security",
						"add-trusted-cert",
						"-d",
						"-k /Library/Keychains/System.keychain",
						cert
					], true, false, true);
					System.runCommand("", "sudo", ["security", "import", key, "-k", "/Library/Keychains/System.keychain", "-A"], true, false, true);
					System.runCommand("", "codesign", ["--entitlements", entitlementsPath, "-fs", "hl-cert", hlPath], true, false, true);
					for (f in [key, cert, openSSLConf])
						sys.FileSystem.deleteFile(f);
					Log.println("\nIf you update lime, you will have to run this again to sign the new hl executable");
				}
			}
		}
	}

	private static function throwPermissionsError()
	{
		if (System.hostPlatform == WINDOWS)
		{
			Log.println("Unable to access directory. Perhaps you need to run \"setup\" with administrative privileges?");
		}
		else
		{
			Log.println("Unable to access directory. Perhaps you should run \"setup\" again using \"sudo\"");
		}

		Sys.exit(1);
	}

	private static function unescapePath(path:String):String
	{
		if (path == null)
		{
			path = "";
		}

		path = StringTools.replace(path, "\\ ", " ");

		if (System.hostPlatform != WINDOWS && StringTools.startsWith(path, "~/"))
		{
			path = Sys.getEnv("HOME") + "/" + path.substr(2);
		}

		return path;
	}

	public static function updateHaxelib(haxelib:Haxelib):Void
	{
		var basePath = Haxelib.runProcess("", ["config"]);

		if (basePath != null)
		{
			basePath = StringTools.trim(basePath.split("\n")[0]);
		}

		var lib = Haxelib.getPath(haxelib, false, true);

		if (StringTools.startsWith(Path.standardize(lib), Path.standardize(basePath)))
		{
			Haxelib.runCommand("", ["update", haxelib.name]);
		}
		else
		{
			var git = Path.combine(lib, ".git");

			if (FileSystem.exists(git))
			{
				Log.info(Log.accentColor + "Updating \"" + haxelib.name + "\"" + Log.resetColor);

				if (System.hostPlatform == WINDOWS)
				{
					var path = Sys.getEnv("PATH");

					if (path.indexOf("Git") == -1)
					{
						Sys.putEnv("PATH", "C:\\Program Files (x86)\\Git\\bin;" + path);
					}
				}

				System.runCommand(lib, "git", ["pull"]);
				System.runCommand(lib, "git", ["submodule", "init"]);
				System.runCommand(lib, "git", ["submodule", "update"]);
			}
		}
	}
}

class Progress extends haxe.io.Output
{
	var o:haxe.io.Output;
	var cur:Int;
	var max:Null<Int>;
	var start:Float;

	public function new(o)
	{
		this.o = o;
		cur = 0;
		start = haxe.Timer.stamp();
	}

	function bytes(n)
	{
		cur += n;
		if (max == null) Sys.print(cur + " bytes\r");
		else
			Sys.print(cur + "/" + max + " (" + Std.int((cur * 100.0) / max) + "%)\r");
	}

	public override function writeByte(c)
	{
		o.writeByte(c);
		bytes(1);
	}

	public override function writeBytes(s, p, l)
	{
		var r = o.writeBytes(s, p, l);
		bytes(r);
		return r;
	}

	public override function close()
	{
		super.close();
		o.close();
		var time = haxe.Timer.stamp() - start;
		var speed = (cur / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;

		// When the path is a redirect, we don't want to display that the download completed

		if (cur > 400)
		{
			Sys.print("Download complete : " + cur + " bytes in " + time + "s (" + speed + "KB/s)\n");
		}
	}

	public override function prepare(m:Int)
	{
		max = m;
	}
}
