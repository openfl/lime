package lime.tools.helpers;


import haxe.io.Path;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.ProcessHelper;
import lime.project.Haxelib;
import lime.project.HXProject;
import sys.io.Process;
import sys.FileSystem;


class TVOSHelper {
	
	
	private static var initialized = false;
	
	
	public static function build (project:HXProject, workingDirectory:String, additionalArguments:Array<String> = null):Void {
		
		initialize (project);
		
		var platformName = "appletvos";
		
		if (project.targetFlags.exists ("simulator")) {
			
			platformName = "appletvsimulator";
			
		}
		
		var configuration = "Release";
		
		if (project.debug) {
			
			configuration = "Debug";
			
		}
			
		var iphoneVersion = project.environment.get ("TVOS_VER");
		var commands = [ "-configuration", configuration, "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion ];
			
		if (project.targetFlags.exists("simulator")) {
			
			commands.push ("-arch");
			commands.push ("x86_64");
			
		}
		
		if (additionalArguments != null) {
			
			commands = commands.concat (additionalArguments);
			
		}
		
		ProcessHelper.runCommand (workingDirectory, "xcodebuild", commands);
		
	}
	
	
	private static function getIOSVersion (project:HXProject):Void {
		
		if (!project.environment.exists("TVOS_VER")) {
			
			if (!project.environment.exists("DEVELOPER_DIR")) {
				
				var proc = new Process ("xcode-select", ["--print-path"]);
				var developer_dir = proc.stdout.readLine ();
				proc.close ();
				project.environment.set ("DEVELOPER_DIR", developer_dir);
				
			}
			
			var dev_path = project.environment.get ("DEVELOPER_DIR") + "/Platforms/AppleTVOS.platform/Developer/SDKs";
			
			if (FileSystem.exists (dev_path)) {
				
				var best = "";
				var files = FileSystem.readDirectory (dev_path);
				var extract_version = ~/^AppleTVOS(.*).sdk$/;
				
				for (file in files) {
					
					if (extract_version.match (file)) {
						
						var ver = extract_version.matched (1);
						
						if (ver > best) {
							
							best = ver;
							
						}
						
					}
					
				}
				
				if (best != "") {
					
					project.environment.set ("TVOS_VER", best);
					
				}
				
			}
			
		}
		
	}
	
	
	private static function getOSXVersion ():String {
		
		var output = ProcessHelper.runProcess ("", "sw_vers", [ "-productVersion" ]);
		return StringTools.trim (output);
		
	}
	
	
	public static function getProvisioningFile ():String {
		
		var path = PathHelper.expand ("~/Library/MobileDevice/Provisioning Profiles");
		var files = FileSystem.readDirectory (path);
		
		for (file in files) {
			
			if (Path.extension (file) == "mobileprovision") {
				
				return path + "/" + file;
				
			}
			
		}
		
		return "";
		
	}
	
	
	public static function getSDKDirectory (project:HXProject):String {
		
		initialize (project);
		
		var platformName = "AppleTVOS";
		
		if (project.targetFlags.exists ("simulator")) {
			
			platformName = "AppleTVSimulator";
			
		}
		
		var process = new Process ("xcode-select", [ "--print-path" ]);
		var directory = process.stdout.readLine ();
		process.close ();
		
		if (directory == "" || directory.indexOf ("Run xcode-select") > -1) {
			
			directory = "/Applications/Xcode.app/Contents/Developer";
			
		}
		
		directory += "/Platforms/" + platformName + ".platform/Developer/SDKs/" + platformName + project.environment.get ("TVOS_VER") + ".sdk";
		LogHelper.info(directory);
		return directory;
		
	}
	
	
	private static function getXcodeVersion ():String {
		
		var output = ProcessHelper.runProcess ("", "xcodebuild", [ "-version" ]);
		var firstLine = output.split ("\n").shift ();
		
		return StringTools.trim (firstLine.substring ("Xcode".length, firstLine.length));
		
	}
	
	
	private static function initialize (project:HXProject):Void {
		
		if (!initialized) {
			
			getIOSVersion (project);
			
			initialized = true;
			
		}
		
	}
	
	
	public static function launch (project:HXProject, workingDirectory:String):Void {
		
		initialize (project);
		
		var configuration = "Release";
			
		if (project.debug) {
			
			configuration = "Debug";
			
		}
		
		if (project.targetFlags.exists ("simulator")) {
			
			var applicationPath = "";
			
			if (Path.extension (workingDirectory) == "app" || Path.extension (workingDirectory) == "ipa") {
				
				applicationPath = workingDirectory;
				
			} else {
				
				applicationPath = workingDirectory + "/build/" + configuration + "-appletvsimulator/" + project.app.file + ".app";
				
			}
			
			var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
			var launcher = PathHelper.findTemplate (templatePaths, "bin/ios-sim");
			Sys.command ("chmod", [ "+x", launcher ]);
			
			// device config
			var defaultDevice = "apple-tv-1080p";
			var devices:Array<String> = ["apple-tv-1080p"];
			var oldDevices:Map<String, String> = ["appletv" => "apple-tv-1080p"];
			
			var deviceFlag:String = null;
			var deviceTypeID = null;
			
			// check if old device flag and convert to current
			for (key in oldDevices.keys ()) {
				
				if (project.targetFlags.exists (key)) {
					
					deviceFlag = oldDevices[key];
					break;
					
				}
				
			}
			
			// check known device in command line args
			if (deviceFlag == null) {
				
				for (i in 0...devices.length) {
					
					if (project.targetFlags.exists (devices[i])) {
						
						deviceFlag = devices[i];
						break;
						
					}
					
				}
				
			}
			
			// default to iphone 6
			if (deviceFlag == null) {
				
				deviceFlag = defaultDevice;
				
			}
			
			// check if device is available
			// $ ios-sim showdevicetypes
			var devicesOutput:String = ProcessHelper.runProcess ("", launcher, [ "showdevicetypes" ]);
			var deviceTypeList:Array<String> = devicesOutput.split ("\n");
			
			for (i in 0...deviceTypeList.length) {
				
				var r = new EReg (deviceFlag + ",", "i");
				
				if (r.match (deviceTypeList[i])) {
					
					deviceTypeID = deviceTypeList[i];
					break;
					
				}
				
			}
			
			if (deviceTypeID == null) {
				
				LogHelper.warn("Device \"" + deviceFlag + "\" was not found");
				
			} else {
				
				LogHelper.info("Launch app on \"" + deviceTypeID + "\"");
				
			}
			
			// run command with --devicetypeid if exists
			if (deviceTypeID != null) {
				
				ProcessHelper.runCommand ("", launcher, [ "launch", FileSystem.fullPath (applicationPath), /*"--sdk", project.environment.get ("IPHONE_VER"),*/ "--devicetypeid", deviceTypeID, "--timeout", "60" ]);
				
			} else {
				
				ProcessHelper.runCommand ("", launcher, [ "launch", FileSystem.fullPath (applicationPath), /*"--sdk", project.environment.get ("IPHONE_VER"), "--devicetypeid", deviceTypeID,*/ "--timeout", "60" ]);
				
			}
			
		} else {
			
			var applicationPath = "";
			
			if (Path.extension (workingDirectory) == "app" || Path.extension (workingDirectory) == "ipa") {
				
				applicationPath = workingDirectory;
				
			} else {
				
				applicationPath = workingDirectory + "/build/" + configuration + "-appletvos/" + project.app.file + ".app";
				
			}
			
			var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
			var launcher = PathHelper.findTemplate (templatePaths, "bin/ios-deploy");
			Sys.command ("chmod", [ "+x", launcher ]);
			
			var xcodeVersion = getXcodeVersion ();
			
			ProcessHelper.runCommand ("", launcher, [ "install", "--noninteractive", "--debug", "--timeout", "5", "--bundle", FileSystem.fullPath (applicationPath) ]);
			
		}
		
	}
	
	
	public static function sign (project:HXProject, workingDirectory:String, entitlementsPath:String):Void {
		
		initialize (project);
		
		var configuration = "Release";
		
		if (project.debug) {
			
			configuration = "Debug";
			
		}
		
		var identity = project.config.getString ("tvos.identity", "tvOS Developer");
		
		var commands = [ "-s", identity, "CODE_SIGN_IDENTITY=" + identity ];
		
		if (entitlementsPath != null) {
			
			commands.push ("--entitlements");
			commands.push (entitlementsPath);
			
		}
		
		if (project.config.exists ("tvos.provisioning-profile")) {
			
			commands.push ("PROVISIONING_PROFILE=" + project.config.getString ("ios.provisioning-profile"));
			
		}
		
		var applicationPath = "build/" + configuration + "-appletvos/" + project.app.file + ".app";
		commands.push (applicationPath);
		
		ProcessHelper.runCommand (workingDirectory, "codesign", commands, true, true);
		
	}
	
	
}