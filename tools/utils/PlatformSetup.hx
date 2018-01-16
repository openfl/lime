package utils;


import haxe.Http;
import haxe.io.Eof;
import haxe.io.Path;
import haxe.zip.Reader;
import lime.project.Haxelib;
import lime.project.HXProject;
import lime.project.Platform;
import lime.project.Version;
import lime.tools.helpers.BlackBerryHelper;
import lime.tools.helpers.CLIHelper;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.HaxelibHelper;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.ProcessHelper;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


class PlatformSetup {
	
	
	private static var airMacPath = "http://airdownload.adobe.com/air/mac/download/latest/AdobeAIRSDK.tbz2";
	private static var airWindowsPath = "http://airdownload.adobe.com/air/win/download/latest/AdobeAIRSDK.zip";
	private static var androidLinuxNDKPath = "http://dl.google.com/android/repository/android-ndk-r11c-linux-x86_64.zip";
	private static var androidLinuxSDKPath = "http://dl.google.com/android/android-sdk_r22.0.5-linux.tgz";
	private static var androidMacNDKPath = "http://dl.google.com/android/repository/android-ndk-r11c-darwin-x86_64.zip";
	private static var androidMacSDKPath = "http://dl.google.com/android/android-sdk_r22.0.5-macosx.zip";
	private static var androidWindowsNDKPath = "http://dl.google.com/android/repository/android-ndk-r11c-windows-x86_64.zip";
	private static var androidWindowsSDKPath = "http://dl.google.com/android/android-sdk_r22.0.5-windows.zip";
	private static var apacheCordovaPath = "http://www.apache.org/dist/incubator/cordova/cordova-2.1.0-incubating-src.zip";
	private static var appleXcodeURL = "https://developer.apple.com/xcode/download/";
	private static var blackBerryCodeSigningURL = "https://www.blackberry.com/SignedKeys/";
	private static var blackBerryLinuxNativeSDKPath = "http://developer.blackberry.com/native/downloads/fetch/installer-bbndk-2.1.0-linux-1032-201209271809-201209280007.bin";
	private static var blackBerryMacNativeSDKPath = "http://developer.blackberry.com/native/downloads/fetch/installer-bbndk-2.1.0-macosx-1032-201209271809-201209280007.dmg";
	private static var blackBerryMacWebWorksSDKPath = "https://developer.blackberry.com/html5/downloads/fetch/BB10-WebWorks-SDK_1.0.4.7.zip";
	private static var blackBerryWindowsNativeSDKPath = "http://developer.blackberry.com/native/downloads/fetch/installer-bbndk-2.1.0-win32-1032-201209271809-201209280007.exe";
	private static var blackBerryWindowsWebWorksSDKPath = "https://developer.blackberry.com/html5/downloads/fetch/BB10-WebWorks-SDK_1.0.4.7.exe";
	private static var codeSourceryWindowsPath = "http://sourcery.mentor.com/public/gnu_toolchain/arm-none-linux-gnueabi/arm-2009q1-203-arm-none-linux-gnueabi.exe";
	private static var emscriptenSDKURL = "https://github.com/kripken/emscripten/wiki/Emscripten-SDK";
	private static var javaJDKURL = "http://www.oracle.com/technetwork/java/javase/downloads/jdk6u37-downloads-1859587.html";
	private static var linuxAptPackages = "gcc-multilib g++-multilib";
	private static var linuxUbuntuSaucyPackages = "gcc-multilib g++-multilib libxext-dev";
	private static var linuxYumPackages = "gcc gcc-c++";
	private static var linuxDnfPackages = "gcc gcc-c++";
	private static var linuxEquoPackages = "media-libs/mesa sys-devel/gcc";
	private static var linuxEmergePackages = "media-libs/mesa sys-devel/gcc";
	private static var linuxPacman32Packages = "multilib-devel mesa mesa-libgl glu";
	private static var linuxPacman64Packages = "multilib-devel lib32-mesa lib32-mesa-libgl lib32-glu";
	private static var tizenSDKURL = "https://developer.tizen.org/downloads/tizen-sdk";
	private static var webOSLinuxX64NovacomPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/palm-novacom_1.0.80_amd64.deb";
	private static var webOSLinuxX86NovacomPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/palm-novacom_1.0.80_i386.deb";
	private static var webOSLinuxSDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/palm-sdk_3.0.5-svn528736-pho676_i386.deb";
	private static var webOSMacSDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/Palm_webOS_SDK.3.0.5.676.dmg";
	private static var webOSWindowsX64SDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/HP_webOS_SDK-Win-3.0.5-676-x64.exe";
	private static var webOSWindowsX86SDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/HP_webOS_SDK-Win-3.0.5-676-x86.exe";
	private static var windowsVisualStudioCPPPath = "http://download.microsoft.com/download/1/D/9/1D9A6C0E-FC89-43EE-9658-B9F0E3A76983/vc_web.exe";
	
	private static var backedUpConfig:Bool = false;
	private static var nme:String;
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
	
	
	public static function getDefines (names:Array<String> = null, descriptions:Array<String> = null, ignored:Array<String> = null):Map<String, String> {
		
		var config = CommandLineTools.getLimeConfig ();
		
		var defines = null;
		var env = Sys.environment ();
		var path = "";
		
		if (config != null) {
			
			defines = config.environment;
			
			for (key in defines.keys ()) {
				
				if (defines.get (key) == env.get (key)) {
					
					defines.remove (key);
					
				}
				
			}
			
		} else {
			
			defines = new Map<String, String> ();
			
		}
		
		if (!defines.exists ("LIME_CONFIG")) {
			
			var home = "";
			
			if (env.exists ("HOME")) {
				
				home = env.get ("HOME");
				
			} else if (env.exists ("USERPROFILE")) {
				
				home = env.get ("USERPROFILE");
				
			} else {
				
				LogHelper.println ("Warning : No 'HOME' variable set - ~/.lime/config.xml might be missing.");
				
				return null;
				
			}
			
			defines.set ("LIME_CONFIG", home + "/.lime/config.xml");
			
		}
		
		if (names == null) {
			
			return defines;
			
		}
		
		var values = new Array<String> ();
		
		for (i in 0...names.length) {
			
			var name = names[i];
			var description = descriptions[i];
			
			var ignore = "";
			
			if (ignored != null && ignored.length > i) {
				
				ignore = ignored[i];
				
			}
			
			var value = "";
			
			if (defines.exists (name) && defines.get (name) != ignore) {
				
				value = defines.get (name);
				
			} else if (env.exists (name)) {
				
				value = Sys.getEnv (name);
				
			}
			
			value = unescapePath (CLIHelper.param ("\x1b[1m" + description + "\x1b[0m \x1b[37;3m[" + value + "]\x1b[0m"));
			
			if (value != "") {
				
				defines.set (name, value);
				
			} else if (value == Sys.getEnv (name)) {
				
				defines.remove (name);
				
			}
			
		}
		
		return defines;
		
	}
	
	
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
			
			switch (target) {
				
				//case "air":
					
					//setupAIR ();
				
				case "android":
					
					setupAndroid ();
				
				case "blackberry":
					
					setupBlackBerry ();
				
				case "emscripten":
					
					setupEmscripten ();
				
				//case "html5":
					
					//setupHTML5 ();
				
				case "ios":
					
					if (PlatformHelper.hostPlatform == Platform.MAC) {
						
						setupMac ();
						
					}
				
				case "linux":
					
					if (PlatformHelper.hostPlatform == Platform.LINUX) {
						
						setupLinux ();
						
					}
				
				case "mac":
					
					if (PlatformHelper.hostPlatform == Platform.MAC) {
						
						setupMac ();
						
					}
				
				case "tizen":
					
					setupTizen ();
				
				case "webos":
					
					setupWebOS ();
				
				case "windows":
					
					if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
						
						setupWindows ();
						
					}
				
				case "lime":
					
					setupLime ();
				
				case "openfl":
					
					setupOpenFL ();
				
				case "tvos":
					
					if (PlatformHelper.hostPlatform == Platform.MAC) {
						
						setupMac ();
						
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
		
		var setAIRSDK = false;
		var defines = getDefines ();
		var answer = CLIHelper.ask ("Download and install the Adobe AIR SDK?");
		
		if (answer == YES || answer == ALWAYS) {
			
			var downloadPath = "";
			var defaultInstallPath = "";
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				downloadPath = airWindowsPath;
				defaultInstallPath = "C:\\Development\\Android SDK";
				
			} else if (PlatformHelper.hostPlatform == Platform.MAC) {
				
				downloadPath = airMacPath;
				defaultInstallPath = "/opt/air-sdk";
				
			}
			
			downloadFile (downloadPath);
			
			var path = unescapePath (CLIHelper.param ("Output directory [" + defaultInstallPath + "]"));
			path = createPath (path, defaultInstallPath);
			
			extractFile (Path.withoutDirectory (downloadPath), path, "");
			
			setAIRSDK = true;
			defines.set ("AIR_SDK", path);
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			LogHelper.println ("");
			
		}
		
		var requiredVariables = new Array<String> ();
		var requiredVariableDescriptions = new Array<String> ();
		
		if (!setAIRSDK) {
			
			requiredVariables.push ("AIR_SDK");
			requiredVariableDescriptions.push ("Path to AIR SDK");
			
		}
		
		if (!setAIRSDK) {
			
			LogHelper.println ("");
			
		}
		
		var defines = getDefines (requiredVariables, requiredVariableDescriptions, null);
		
		if (defines != null) {
			
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			
		}
		
		HaxelibHelper.runCommand ("", [ "install", "air3" ], true, true);
		
	}
	
	
	public static function setupAndroid ():Void {
		
		var setAndroidSDK = false;
		var setAndroidNDK = false;
		var setJavaJDK = false;
		
		var defines = getDefines ();
		var answer = CLIHelper.ask ("Download and install the Android SDK?");
		
		if (answer == YES || answer == ALWAYS) {
			
			var downloadPath = "";
			var defaultInstallPath = "";
			var ignoreRootFolder = "android-sdk";
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				downloadPath = androidWindowsSDKPath;
				defaultInstallPath = "C:\\Development\\Android SDK";
			
			} else if (PlatformHelper.hostPlatform == Platform.LINUX) {
				
				downloadPath = androidLinuxSDKPath;
				defaultInstallPath = "/opt/android-sdk";
				ignoreRootFolder = "android-sdk-linux";
				
			} else if (PlatformHelper.hostPlatform == Platform.MAC) {
				
				downloadPath = androidMacSDKPath;
				defaultInstallPath = "/opt/android-sdk";
				ignoreRootFolder = "android-sdk-mac";
				
			}
			
			downloadFile (downloadPath);
			
			var path = unescapePath (CLIHelper.param ("Output directory [" + defaultInstallPath + "]"));
			path = createPath (path, defaultInstallPath);
			
			extractFile (Path.withoutDirectory (downloadPath), path, ignoreRootFolder);
			
			if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
				
				ProcessHelper.runCommand ("", "chmod", [ "-R", "777", path ], false);
				
			}
			
			LogHelper.println ("Launching the Android SDK Manager to install packages");
			LogHelper.println ("Please install Android API 16 and SDK Platform-tools");
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				runInstaller (path + "/SDK Manager.exe");
				
			} else {
				
				runInstaller (path + "/tools/android");
				
			}
			
			if (PlatformHelper.hostPlatform != Platform.WINDOWS && FileSystem.exists (Sys.getEnv ("HOME") + "/.android")) {
				
				ProcessHelper.runCommand ("", "chmod", [ "-R", "777", "~/.android" ], false);
				ProcessHelper.runCommand ("", "cp", [ HaxelibHelper.getPath (new Haxelib ("lime")) + "/templates/bin/debug.keystore", "~/.android/debug.keystore" ], false);
				
			}
			
			setAndroidSDK = true;
			defines.set ("ANDROID_SDK", path);
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			LogHelper.println ("");
			
		}
		
		if (answer == ALWAYS) {
			
			LogHelper.println ("Download and install the Android NDK? [y/n/a] a");
			
		} else {
			
			answer = CLIHelper.ask ("Download and install the Android NDK?");
			
		}
		
		if (answer == YES || answer == ALWAYS) {
			
			var downloadPath = "";
			var defaultInstallPath = "";
			var ignoreRootFolder = "android-ndk-r8b";
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				downloadPath = androidWindowsNDKPath;
				defaultInstallPath = "C:\\Development\\Android NDK";
				
			} else if (PlatformHelper.hostPlatform == Platform.LINUX) {
				
				downloadPath = androidLinuxNDKPath;
				defaultInstallPath = "/opt/android-ndk";
				
			} else {
				
				downloadPath = androidMacNDKPath;
				defaultInstallPath = "/opt/android-ndk";
				
			}
			
			downloadFile (downloadPath);
			
			var path = unescapePath (CLIHelper.param ("Output directory [" + defaultInstallPath + "]"));
			path = createPath (path, defaultInstallPath);
			
			extractFile (Path.withoutDirectory (downloadPath), path, ignoreRootFolder);
			
			setAndroidNDK = true;
			defines.set ("ANDROID_NDK_ROOT", path);
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			LogHelper.println ("");
			
		}
		
		if (PlatformHelper.hostPlatform != Platform.MAC) {
			
			if (answer == ALWAYS) {
				
				LogHelper.println ("Download and install the Java JDK? [y/n/a] a");
				
			} else {
				
				answer = CLIHelper.ask ("Download and install the Java JDK?");
				
			}
			
			if (answer == YES || answer == ALWAYS) {
				
				LogHelper.println ("You must visit the Oracle website to download the Java 6 JDK for your platform");
				var secondAnswer = CLIHelper.ask ("Would you like to go there now?");
				
				if (secondAnswer != NO) {
					
					openURL (javaJDKURL);
					
				}
				
				LogHelper.println ("");
				
			}
			
		}
		
		var requiredVariables = new Array<String> ();
		var requiredVariableDescriptions = new Array<String> ();
		var ignoreValues = new Array<String> ();
		
		if (!setAndroidSDK) {
			
			requiredVariables.push ("ANDROID_SDK");
			requiredVariableDescriptions.push ("Path to Android SDK");
			ignoreValues.push ("/SDKs//android-sdk");
			
		}
		
		if (!setAndroidNDK) {
			
			requiredVariables.push ("ANDROID_NDK_ROOT");
			requiredVariableDescriptions.push ("Path to Android NDK");
			ignoreValues.push ("/SDKs//android-ndk-r6");
			
		}
		
		if (PlatformHelper.hostPlatform != Platform.MAC && !setJavaJDK) {
			
			requiredVariables.push ("JAVA_HOME");
			requiredVariableDescriptions.push ("Path to Java JDK");
			ignoreValues.push ("/SDKs//java_jdk");
			
		}
		
		if (!setAndroidSDK && !setAndroidNDK) {
			
			LogHelper.println ("");
			
		}
		
		var defines = getDefines (requiredVariables, requiredVariableDescriptions, ignoreValues);
		
		if (defines != null) {
			
			defines.set ("ANDROID_SETUP", "true");
			
			if (PlatformHelper.hostPlatform == Platform.MAC) {
				
				defines.remove ("JAVA_HOME");
				
			}
			
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			
		}
		
	}
	
	
	public static function setupBlackBerry ():Void {
		
		var answer = CLIHelper.ask ("Download and install the BlackBerry Native SDK?");
		
		if (answer == YES || answer == ALWAYS) {
			
			var downloadPath = "";
			var defaultInstallPath = "";
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				downloadPath = blackBerryWindowsNativeSDKPath;
				//defaultInstallPath = "C:\\Development\\Android NDK";
				
			} else if (PlatformHelper.hostPlatform == Platform.LINUX) {
				
				downloadPath = blackBerryLinuxNativeSDKPath;
				//defaultInstallPath = "/opt/Android NDK";
				
			} else {
				
				downloadPath = blackBerryMacNativeSDKPath;
				//defaultInstallPath = "/opt/Android NDK";
				
			}
			
			downloadFile (downloadPath);
			runInstaller (Path.withoutDirectory (downloadPath));
			LogHelper.println ("");
			
			/*var path = unescapePath (CLIHelper.param ("Output directory [" + defaultInstallPath + "]"));
			path = createPath (path, defaultInstallPath);
			
			extractFile (Path.withoutDirectory (downloadPath), path, ignoreRootFolder);
			
			setAndroidNDK = true;
			defines.set ("ANDROID_NDK_ROOT", path);
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			LogHelper.println ("");*/
			
		}
		
		var defines = getDefines ([ "BLACKBERRY_NDK_ROOT" ], [ "Path to BlackBerry Native SDK" ]);
		
		if (defines != null) {
			
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			
		}
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			if (answer == ALWAYS) {
				
				LogHelper.println ("Download and install the BlackBerry WebWorks SDK? [y/n/a] a");
			
			} else {
				
				answer = CLIHelper.ask ("Download and install the BlackBerry WebWorks SDK?");
			
			}
			
			if (answer == ALWAYS || answer == YES) {
				
				var downloadPath = "";
				var defaultInstallPath = "";
				
				if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
					
					downloadPath = blackBerryWindowsWebWorksSDKPath;
					//defaultInstallPath = "C:\\Development\\Android NDK";
					
				} else if (PlatformHelper.hostPlatform == Platform.LINUX) {
					
					//downloadPath = blackBerryLinuxWebWorksSDKPath;
					//defaultInstallPath = "/opt/Android NDK";
					
				} else {
					
					downloadPath = blackBerryMacWebWorksSDKPath;
					//defaultInstallPath = "/opt/Android NDK";
					
				}
				
				downloadFile (downloadPath);
				runInstaller (Path.withoutDirectory (downloadPath));
				LogHelper.println ("");
				
				/*var path = unescapePath (CLIHelper.param ("Output directory [" + defaultInstallPath + "]"));
				path = createPath (path, defaultInstallPath);
				
				extractFile (Path.withoutDirectory (downloadPath), path, ignoreRootFolder);
				
				setAndroidNDK = true;
				defines.set ("ANDROID_NDK_ROOT", path);
				writeConfig (defines.get ("LIME_CONFIG"), defines);
				LogHelper.println ("");*/
				
			}
			
			var defines = getDefines ([ "BLACKBERRY_WEBWORKS_SDK" ], [ "Path to BlackBerry WebWorks SDK" ]);
			
			if (defines != null) {
				
				writeConfig (defines.get ("LIME_CONFIG"), defines);
				
			}
			
		}
		
		var binDirectory = "";
		
		try {
			
			if (defines.exists ("BLACKBERRY_NDK_ROOT") && (!defines.exists("QNX_HOST") || !defines.exists("QNX_TARGET"))) {
				
				var fileName = defines.get ("BLACKBERRY_NDK_ROOT");
				
				if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
					
					fileName += "\\bbndk-env.bat";
					
				} else {
					
					fileName += "/bbndk-env.sh";
					
				}
				
				var fin = File.read (fileName, false);
				
				try {
					
					while (true) {
					
						var str = fin.readLine();
						var split = str.split ("=");
						var name = StringTools.trim (split[0].substr (split[0].lastIndexOf (" ") + 1));
						
						switch (name) {
						
							case "QNX_HOST", "QNX_TARGET", "QNX_HOST_VERSION", "QNX_TARGET_VERSION":
								
								var value = split[1];
								
								if (StringTools.startsWith (value, "${") && split.length > 2) {
									
									value = split[2].substr (0, split[2].length - 1);
									
								}
								
								if (StringTools.startsWith(value, "\"")) {
								
									value = value.substr (1);
									
								}
								
								if (StringTools.endsWith(value, "\"")) {
								
									value = value.substr (0, value.length - 1);
									
								}
								
								if (name == "QNX_HOST_VERSION" || name == "QNX_TARGET_VERSION") {
									
									if (defines.get (name) != null) {
										
										continue;
									}
									
								} else {
									
									value = StringTools.replace (value, "$BASE_DIR", defines.get ("BLACKBERRY_NDK_ROOT"));
									value = StringTools.replace (value, "%BASE_DIR%", defines.get ("BLACKBERRY_NDK_ROOT"));
									value = StringTools.replace (value, "$TARGET", "qnx6");
									value = StringTools.replace (value, "%TARGET%", "qnx6");
									value = StringTools.replace (value, "$QNX_HOST_VERSION", defines.get ("QNX_HOST_VERSION"));
									value = StringTools.replace (value, "$QNX_TARGET_VERSION", defines.get ("QNX_TARGET_VERSION"));
									value = StringTools.replace (value, "%QNX_HOST_VERSION%", defines.get ("QNX_HOST_VERSION"));
									value = StringTools.replace (value, "%QNX_TARGET_VERSION%", defines.get ("QNX_TARGET_VERSION"));
									
								}
								
								defines.set (name, value);
								
						}
						
					}
					
				} catch (ex:Eof) {}
				
				fin.close();
				
			}
			
		} catch (e:Dynamic) {
			
			LogHelper.println ("Error: Path to BlackBerry Native SDK appears to be invalid");
			
		}
		
		binDirectory = defines.get ("QNX_HOST") + "/usr/bin/";
		
		if (answer == ALWAYS) {
			
			LogHelper.println ("Configure a BlackBerry device? [y/n/a] a");
			
		} else {
			
			answer = CLIHelper.ask ("Configure a BlackBerry device?");
			
		}
		
		var debugTokenPath:String = null;
		
		if (answer == YES || answer == ALWAYS) {
			
			var secondAnswer = CLIHelper.ask ("Do you have a valid debug token?");
			
			if (secondAnswer == NO) {
				
				secondAnswer = CLIHelper.ask ("Have you requested code signing keys?");
				
				if (secondAnswer == NO) {
					
					secondAnswer = CLIHelper.ask ("Would you like to request them now?");
					
					if (secondAnswer != NO) {
						
						openURL (blackBerryCodeSigningURL);
						
					}
					
					LogHelper.println ("");
					LogHelper.println ("It can take up to two hours for code signing keys to arrive");
					LogHelper.println ("Please run \"lime setup blackberry\" again at that time");
					Sys.exit (0);
					
				} else {
					
					secondAnswer = CLIHelper.ask ("Have you created a keystore file?");
					
					var cskPassword:String = null;
					var keystorePath:String = null;
					var keystorePassword:String = null;
					var outputPath:String = null;
					
					if (secondAnswer == NO) {
						
						var pbdtFile = unescapePath (CLIHelper.param ("Path to client-PBDT-*.csj file"));
						var rdkFile = unescapePath (CLIHelper.param ("Path to client-RDK-*.csj file"));
						var cskPIN = CLIHelper.param ("Code signing key PIN");
						cskPassword = CLIHelper.param ("Code signing key password", true);
						
						LogHelper.println ("Registering code signing keys...");
						
						try {
							
							ProcessHelper.runCommand ("", binDirectory + "blackberry-signer", [ "-csksetup", "-cskpass", cskPassword ], false);
							
						} catch (e:Dynamic) { }
						
						try {
							
							ProcessHelper.runCommand ("", binDirectory + "blackberry-signer", [ "-register", "-cskpass", cskPassword, "-csjpin", cskPIN, pbdtFile ], false);
							ProcessHelper.runCommand ("", binDirectory + "blackberry-signer", [ "-register", "-cskpass", cskPassword, "-csjpin", cskPIN, rdkFile ], false);
							
							LogHelper.println ("Done.");
							
						} catch (e:Dynamic) {}
						
						keystorePassword = CLIHelper.param ("Keystore password", true);
						var companyName = CLIHelper.param ("Company name");
						outputPath = unescapePath (CLIHelper.param ("Output directory"));
						keystorePath = outputPath + "/author.p12";
						
						LogHelper.println ("Creating keystore...");
						
						try {
							
							ProcessHelper.runCommand ("", binDirectory + "blackberry-keytool", [ "-genkeypair", "-keystore", keystorePath, "-storepass", keystorePassword, "-dname", "cn=(" + companyName + ")", "-alias", "author" ], false);
							
							LogHelper.println ("Done.");
							
						} catch (e:Dynamic) {
							
							Sys.exit (1);
							
						}
						
					}
					
					var names:Array<String> = [];
					var descriptions:Array<String> = [];
					
					if (cskPassword == null) {
						
						cskPassword = CLIHelper.param ("Code signing key password", true);
						
					}
					
					if (keystorePath == null) {
						
						keystorePath = unescapePath (CLIHelper.param ("Path to keystore (*.p12) file"));
						
					}
					
					if (keystorePassword == null) {
						
						keystorePassword = CLIHelper.param ("Keystore password", true);
						
					}
					
					var deviceIDs = [];
					var defines = getDefines ();
					
					var config = CommandLineTools.getLimeConfig ();
					
					BlackBerryHelper.initialize (config);
					var token = BlackBerryHelper.processDebugToken (config);
					
					if (token != null) {
						
						for (deviceID in token.deviceIDs) {
							
							if (CLIHelper.ask ("Would you like to add existing device PIN \"" + deviceID + "\"?") != NO) {
								
								deviceIDs.push ("0x" + deviceID);
								
							}
							
						}
						
					}
					
					if (deviceIDs.length == 0) {
						
						deviceIDs.push ("0x" + CLIHelper.param ("Device PIN"));
						
					}
					
					while (CLIHelper.ask ("Would you like to add another device PIN?") != NO) {
						
						var pin = CLIHelper.param ("Device PIN");
						
						if (pin != null && pin != "") {
							
							deviceIDs.push ("0x" + pin);
							
						}
						
					}
					
					if (outputPath == null) {
						
						outputPath = unescapePath (CLIHelper.param ("Output directory"));
						
					}
					
					debugTokenPath = outputPath + "/debugToken.bar";
					
					LogHelper.println ("Requesting debug token...");
					
					try {
						
						var params = [ "-cskpass", cskPassword, "-keystore", keystorePath, "-storepass", keystorePassword ];
						
						for (id in deviceIDs) {
							
							params.push ("-deviceId");
							params.push (id);
							
						}
						
						params.push (debugTokenPath);
						
						ProcessHelper.runCommand ("", binDirectory + "blackberry-debugtokenrequest", params, false);
						
						LogHelper.println ("Done.");
						
					} catch (e:Dynamic) {
						
						Sys.exit (1);
						
					}
					
					var defines = getDefines ();
					defines.set ("BLACKBERRY_DEBUG_TOKEN", debugTokenPath);
					writeConfig (defines.get ("LIME_CONFIG"), defines);
					
				}
				
			}
			
			if (answer == YES || answer == ALWAYS) {
				
				var names:Array<String> = [];
				var descriptions:Array<String> = [];
				
				if (debugTokenPath == null) {
					
					names.push ("BLACKBERRY_DEBUG_TOKEN");
					descriptions.push ("Path to debug token");
					
				}
				
				names = names.concat ([ "BLACKBERRY_DEVICE_IP", "BLACKBERRY_DEVICE_PASSWORD" ]);
				descriptions = descriptions.concat ([ "Device IP address", "Device password" ]);
				
				var defines = getDefines (names, descriptions);
				
				if (defines != null) {
					
					defines.set ("BLACKBERRY_SETUP", "true");
					writeConfig (defines.get ("LIME_CONFIG"), defines);
					
				}
				
				var secondAnswer = CLIHelper.ask ("Install debug token on device?");
				
				if (secondAnswer != NO) {
					
					LogHelper.println ("Installing debug token...");
					var done = false;
					
					while (!done) {
						
						try {
							
							ProcessHelper.runCommand ("", binDirectory + "blackberry-deploy", [ "-installDebugToken", defines.get ("BLACKBERRY_DEBUG_TOKEN"), "-device", defines.get ("BLACKBERRY_DEVICE_IP"), "-password", defines.get ("BLACKBERRY_DEVICE_PASSWORD") ], false);
							
							LogHelper.println ("Done.");
							done = true;
							
						} catch (e:Dynamic) {
							
							if (CLIHelper.ask ("Would you like to try again?") == NO) {
								
								Sys.exit (1);
								
							}
							
						}
						
					}
					
				}
				
			}
			
		}
		
		if (answer == ALWAYS) {
			
			LogHelper.println ("Configure the BlackBerry simulator? [y/n/a] a");
			
		} else {
			
			answer = CLIHelper.ask ("Configure the BlackBerry simulator?");
			
		}
		
		if (answer == YES || answer == ALWAYS) {
			
			var defines = getDefines ([ "BLACKBERRY_SIMULATOR_IP" ], [ "Simulator IP address" ]);
			
			if (defines != null) {
				
				writeConfig (defines.get ("LIME_CONFIG"), defines);
				
			}
			
		}
		
		var defines = getDefines ();
		defines.set ("BLACKBERRY_SETUP", "true");
		writeConfig (defines.get ("LIME_CONFIG"), defines);
		
	}
	
	
	public static function setupEmscripten ():Void {
		
		var answer = CLIHelper.ask ("Download and install Emscripten?");
		
		if (answer == YES || answer == ALWAYS) {
			
			LogHelper.println ("You may find instructions for installing Emscripten on the website.");
			var secondAnswer = CLIHelper.ask ("Would you like to open the wiki page now?");
			
			if (secondAnswer != NO) {
				
				ProcessHelper.openURL (emscriptenSDKURL);
				
			}
			
		}
		
		var defines = getDefines ([ "EMSCRIPTEN_SDK" ], [ "Path to Emscripten SDK" ]);
		
		if (defines != null) {
			
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			
		}
		
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
		
		var project = HXProject.fromHaxelib (haxelib, defines, true);
		
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
		
		var setApacheCordova = false;
		
		var defines = getDefines ();
		var answer = CLIHelper.ask ("Download and install Apache Cordova?");
		
		if (answer == YES || answer == ALWAYS) {
			
			var downloadPath = "";
			var defaultInstallPath = "";
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				defaultInstallPath = "C:\\Development\\Apache Cordova";
			
			} else {
				
				defaultInstallPath = "/opt/cordova";
				
			}
			
			var path = unescapePath (CLIHelper.param ("Output directory [" + defaultInstallPath + "]"));
			path = createPath (path, defaultInstallPath);
			
			downloadFile (apacheCordovaPath);
			extractFile (Path.withoutDirectory (apacheCordovaPath), path, "*");
			
			var childArchives = [];
			
			for (file in FileSystem.readDirectory (path)) {
				
				if (Path.extension (file) == "zip") {
					
					childArchives.push (file);
					
				}
				
			}
			
			createPath (path + "/lib");
			var libs = [ "android", "bada-wac", "bada", "blackberry", "ios", "mac", "qt", "tizen", "tvos", "webos", "wp7" ];
			
			for (archive in childArchives) {
				
				var name = Path.withoutExtension (archive);
				name = StringTools.replace (name, "incubator-", "");
				name = StringTools.replace (name, "cordova-", "");
				
				if (name == "blackberry-webworks") {
					
					name = "blackberry";
					
				}
				
				var basePath = path + "/";
				
				for (lib in libs) {
					
					if (name == lib) {
						
						basePath += "lib/";
						
					}
					
				}
				
				createPath (basePath + name);
				extractFile (path + "/" + archive, basePath + name);
				
			}
			
			if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
				
				ProcessHelper.runCommand ("", "chmod", [ "-R", "777", path ], false);
				
			}
			
			setApacheCordova = true;
			defines.set ("CORDOVA_PATH", path);
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			LogHelper.println ("");
			
		}
		
		var requiredVariables = [];
		var requiredVariableDescriptions = [];
		
		if (!setApacheCordova) {
			
			requiredVariables.push ("CORDOVA_PATH");
			requiredVariableDescriptions.push ("Path to Apache Cordova");
			
		}
		
		requiredVariables = requiredVariables.concat ([ "WEBWORKS_SDK", "WEBWORKS_SDK_BBOS", "WEBWORKS_SDK_PLAYBOOK" ]);
		requiredVariableDescriptions = requiredVariableDescriptions.concat ([ "Path to WebWorks SDK for BlackBerry 10", "Path to WebWorks SDK for BBOS", "Path to WebWorks SDK for PlayBook" ]);
		
		defines = getDefines (requiredVariables, requiredVariableDescriptions);
		
		defines.set ("CORDOVA_PATH", unescapePath (defines.get ("CORDOVA_PATH")));
		defines.set ("WEBWORKS_SDK_BBOS", unescapePath (defines.get ("WEBWORKS_SDK_BBOS")));
		defines.set ("WEBWORKS_SDK_PLAYBOOK", unescapePath (defines.get ("WEBWORKS_SDK_PLAYBOOK")));
		
		// temporary hack
		
		/*Sys.println ("");
		Sys.println ("Setting Apache Cordova install path...");
		ProcessHelper.runCommand (defines.get ("CORDOVA_PATH") + "/lib/ios", "make", [ "install" ], true, true);
		Sys.println ("Done.");*/
		
		writeConfig (defines.get ("LIME_CONFIG"), defines);
		
		HaxelibHelper.runCommand ("", [ "install", "cordova" ], true, true);
		
	}
	
	
	public static function setupLime ():Void {
		
		if (!targetFlags.exists ("cli")) {
			
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
			
			var defines = getDefines ();
			defines.set ("MAC_USE_CURRENT_SDK", "1");
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			
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
			return;
			
		}
		
		var whichYum = ProcessHelper.runProcess ("", "which", ["yum"], true, true, true);
		var hasYum = whichYum != null && whichYum != "";
		
		if (hasYum) {
			
			var parameters = [ "yum", "install" ].concat (linuxYumPackages.split (" "));
			ProcessHelper.runCommand ("", "sudo", parameters, false);
			return;
			
		}
		
		var whichDnf = ProcessHelper.runProcess ("", "which", ["dnf"], true, true, true);
		var hasDnf = whichDnf != null && whichDnf != "";
		
		if (hasDnf) {
			
			var parameters = [ "dnf", "install" ].concat (linuxDnfPackages.split (" "));
			ProcessHelper.runCommand ("", "sudo", parameters, false);
			return;
			
		}
		
		var whichEquo = ProcessHelper.runProcess ("", "which", ["equo"], true,true, true);
		var hasEquo = whichEquo != null && whichEquo != "";
		
		if (hasEquo) {
			
			// Sabayon docs recommend not using sudo with equo, and instead using a root login shell
			var parameters = [ "-l", "-c", "equo", "i", "-av" ].concat (linuxEquoPackages.split (" "));
			ProcessHelper.runCommand ("", "su", parameters, false);
			return;
			
		}
		
		var whichEmerge = ProcessHelper.runProcess ("", "which", ["emerge"], true,true, true);
		var hasEmerge = whichEmerge != null && whichEmerge != "";
		
		if (hasEmerge) {
			
			var parameters = [ "emerge", "-av" ].concat (linuxEmergePackages.split (" "));
			ProcessHelper.runCommand ("", "sudo", parameters, false);
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
			return;
			
		}
		
		LogHelper.println ("Unable to find a supported package manager on your Linux distribution.");
		LogHelper.println ("For now, only apt-get, yum, dnf, equo, emerge, and pacman are supported.");
		
		Sys.exit (1);
		
	}
	
	
	public static function setupMac ():Void {
		
		var answer = CLIHelper.ask ("Download and install Apple Xcode?");
		
		if (answer == YES || answer == ALWAYS) {
			
			LogHelper.println ("You must install Xcode from the Mac App Store or download from the Apple");
			LogHelper.println ("developer site.");
			var secondAnswer = CLIHelper.ask ("Would you like to open the download page?");
			
			if (secondAnswer != NO) {
				
				ProcessHelper.openURL (appleXcodeURL);
				
			}
			
		}
		
	}
	
	
	public static function setupOpenFL ():Void {
		
		if (!targetFlags.exists ("cli")) {
			
			setupHaxelib (new Haxelib ("openfl"));
			
		}
		
		var haxePath = Sys.getEnv ("HAXEPATH");
		var project = null;
		
		try {
			
			project = HXProject.fromHaxelib (new Haxelib ("openfl"));
			
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
			
			var defines = getDefines ();
			defines.set ("MAC_USE_CURRENT_SDK", "1");
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			
		}
		
	}
	
	
	public static function setupTizen ():Void {
		
		var answer = CLIHelper.ask ("Download and install the Tizen SDK?");
		
		if (answer == YES || answer == ALWAYS) {
			
			LogHelper.println ("You may download the Tizen SDK from the Tizen Developer portal.");
			var secondAnswer = CLIHelper.ask ("Would you like to open the download page?");
			
			if (secondAnswer != NO) {
				
				ProcessHelper.openURL (tizenSDKURL);
				
			}
			
		}
		
		var defines = getDefines ([ "TIZEN_SDK" ], [ "Path to Tizen SDK" ]);
		
		if (defines != null) {
			
			writeConfig (defines.get ("LIME_CONFIG"), defines);
			
		}
		
	}
	
	
	public static function setupWebOS ():Void {
		
		var answer = CLIHelper.ask ("Download and install the HP webOS SDK?");
		
		if (answer == YES || answer == ALWAYS) {
			
			var sdkPath = "";
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				if (Sys.environment ().exists ("PROCESSOR_ARCHITEW6432") && Sys.getEnv ("PROCESSOR_ARCHITEW6432").indexOf ("64") > -1) {
					
					sdkPath = webOSWindowsX64SDKPath;
					
				} else {
					
					sdkPath = webOSWindowsX86SDKPath;
					
				}
				
			} else if (PlatformHelper.hostPlatform == Platform.LINUX) {
				
				sdkPath = webOSLinuxSDKPath;
				
			} else {
				
				sdkPath = webOSMacSDKPath;
				
			}
			
			downloadFile (sdkPath);
			runInstaller (Path.withoutDirectory (sdkPath));
			LogHelper.println ("");
			
		}
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			if (answer == ALWAYS) {
				
				LogHelper.println ("Download and install the CodeSourcery C++ toolchain? [y/n/a] a");
				
			} else {
				
				answer = CLIHelper.ask ("Download and install the CodeSourcery C++ toolchain?");
				
			}
			
			if (answer != NO) {
				
				downloadFile (codeSourceryWindowsPath);
				runInstaller (Path.withoutDirectory (codeSourceryWindowsPath));
				
			}
			
		} else if (PlatformHelper.hostPlatform == Platform.LINUX) {
			
			if (answer == ALWAYS) {
				
				LogHelper.println ("Download and install Novacom? [y/n/a] a");
				
			} else {
				
				answer = CLIHelper.ask ("Download and install Novacom?");
				
			}
			
			if (answer != NO) {
				
				var process = new Process("uname", ["-m"]);
				var ret = process.stdout.readAll ().toString();
				var ret2 = process.stderr.readAll ().toString();
				process.exitCode (); //you need this to wait till the process is closed!
				process.close ();
				
				var novacomPath = webOSLinuxX86NovacomPath;
				
				if (ret.indexOf ("64") > -1) {
					
					novacomPath = webOSLinuxX64NovacomPath;
					
				}
				
				downloadFile (novacomPath);
				runInstaller (Path.withoutDirectory (novacomPath));
				
			}
			
		}
		
	}
	
	
	public static function setupWindows ():Void {
		
		var answer = CLIHelper.ask ("Download and install Visual Studio C++ Express?");
		
		if (answer == YES || answer == ALWAYS) {
			
			downloadFile (windowsVisualStudioCPPPath);
			runInstaller (Path.withoutDirectory (windowsVisualStudioCPPPath));
			
		}
		
	}
	
	
	private static function stripQuotes (path:String):String {
		
		if (path != null) {
			
			return path.split ("\"").join ("");
			
		}
		
		return path;
		
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
	
	
	public static function writeConfig (path:String, defines:Map<String, Dynamic>):Void {
		
		var newContent = "";
		var definesText = "";
		var env = Sys.environment ();
		
		for (key in defines.keys ()) {
			
			if (key != "LIME_CONFIG" && key != "LIME_CONFIG" && (!env.exists (key) || env.get (key) != defines.get (key))) {
				
				definesText += "\t\t<set name=\"" + key + "\" value=\"" + stripQuotes (Std.string (defines.get (key))) + "\" />\n";
				
			}
			
		}
		
		if (FileSystem.exists (path)) {
			
			var input = File.read (path, false);
			var bytes = input.readAll ();
			input.close ();
			
			if (!backedUpConfig) {
				
				try {
					
					var backup = File.write (path + ".bak", false);
					backup.writeBytes (bytes, 0, bytes.length);
					backup.close ();
					
				} catch (e:Dynamic) { }
				
				backedUpConfig = true;
				
			}
			
			var content = bytes.getString (0, bytes.length);
			
			var startIndex = content.indexOf ("<section id=\"defines\">");
			var endIndex = content.indexOf ("</section>", startIndex);
			
			newContent += content.substr (0, startIndex) + "<section id=\"defines\">\n\t\t\n";
			newContent += definesText;
			newContent += "\t\t\n\t" + content.substr (endIndex);
			
		} else {
			
			newContent += "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
			newContent += "<config>\n\t\n";
			newContent += "\t<section id=\"defines\">\n\t\t\n";
			newContent += definesText;
			newContent += "\t\t\n\t</section>\n\t\n</config>";
			
		}
		
		var output = File.write (path, false);
		output.writeString (newContent);
		output.close ();
		
		if (backedUpConfig) {
			
			try {
				
				FileSystem.deleteFile (path + ".bak");
				
			} catch (e:Dynamic) {}
			
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
