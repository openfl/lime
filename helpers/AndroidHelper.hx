package helpers;


import helpers.LogHelper;
import helpers.ProcessHelper;
import project.HXProject;
import project.Platform;
import sys.FileSystem;


class AndroidHelper {
	
	
	private static var adbName:String;
	private static var adbPath:String;
	private static var androidName:String;
	private static var androidPath:String;
	private static var emulatorName:String;
	private static var emulatorPath:String;
	
	
	public static function build (project:HXProject, projectDirectory:String):Void {
		
		if (project.environment.exists ("ANDROID_SDK")) {
			
			Sys.putEnv ("ANDROID_SDK", project.environment.get ("ANDROID_SDK"));
			
		}
		
		var ant = project.environment.get ("ANT_HOME");
		
		if (ant == null || ant == "") {
			
			ant = "ant";
			
		} else {
			
			ant += "/bin/ant";
			
		}
		
		var build = "debug";
		
		if (project.certificate != null) {
			
			build = "release";
			
		}
		
		// Fix bug in Android build system, force compile
		
		var buildProperties = projectDirectory + "/bin/build.prop";
		
		if (FileSystem.exists (buildProperties)) {
			
			FileSystem.deleteFile (buildProperties);
			
		}
		
		ProcessHelper.runCommand (projectDirectory, ant, [ build ]);
		
	}
	
	
	public static function initialize (project:HXProject):Void {
		
		adbPath = project.environment.get ("ANDROID_SDK") + "/tools/";
		androidPath = project.environment.get ("ANDROID_SDK") + "/tools/";
		emulatorPath = project.environment.get ("ANDROID_SDK") + "/tools/";
		
		adbName = "adb";
		androidName = "android";
		emulatorName = "emulator";

		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {

			adbName += ".exe";
			androidName += ".bat";
			emulatorName += ".exe";

		}

		if (!FileSystem.exists (adbPath + adbName)) {

			adbPath = project.environment.get ("ANDROID_SDK") + "/platform-tools/";

		}

		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {

			adbName = "./" + adbName;
			androidName = "./" + androidName;
			emulatorName = "./" + emulatorName;

		}
		
		if (project.environment.exists ("JAVA_HOME")) {

			Sys.putEnv ("JAVA_HOME", project.environment.get ("JAVA_HOME"));

		}
		
	}
	
	
	public static function install (project:HXProject, targetPath:String):String {
		
		if (project.targetFlags.exists ("emulator") || project.targetFlags.exists ("simulator")) {
			
			LogHelper.info ("", "Searching for Android emulator");
			
			var devices = listDevices ();
			var emulator = null;
			
			for (device in devices) {
				
				if (device.indexOf ("emulator") > -1) {
					
					emulator = device;
					
				}
				
			}
			
			//TODO: Check emulator capabilities, if it is GPU enabled and if API LEVEL >15 (http://developer.android.com/tools/devices/emulator.html)
			
			if (emulator == null) {
				
				var avds = listAVDs ();
				
				if (avds.length == 0) {
					
					LogHelper.error ("Cannot find emulator, please use AVD manager to create one");
					
				}
				
				LogHelper.info ("Starting AVD: " + avds[0]);
				
				ProcessHelper.runProcess (emulatorPath, emulatorName, [ "-avd", avds[0], "-gpu", "on" ], false);
				
				while (emulator == null) {
					
					devices = listDevices ();
					
					for (device in devices) {
						
						if (device.indexOf ("emulator") > -1) {
							
							emulator = device;
							
						}
						
					}
					
					if (emulator == null) {
						
						Sys.sleep (3);
						Sys.print (".");
						
					} else {
						
						Sys.println ("");
						
					}
					
				}
				
			}
			
			//ProcessHelper.runCommand (adbPath, adbName, [ "-s", emulator, "install", "-r", "-d", targetPath ]);
			ProcessHelper.runCommand (adbPath, adbName, [ "-s", emulator, "install", "-r", targetPath ]);
			
			return emulator;
			
		} else {
			
			//ProcessHelper.runCommand (adbPath, adbName, [ "install", "-r", "-d", targetPath ]);
			ProcessHelper.runCommand (adbPath, adbName, [ "install", "-r", targetPath ]);
			
		}
		
		return null;
		
	}
	
	
	public static function listAVDs ():Array <String> {
		
		var avds = new Array <String> ();
		var output = ProcessHelper.runProcess (androidPath, androidName, [ "list", "avd" ]);
		
		if (output != null && output != "") {
			
			for (line in output.split ("\n")) {
				
				if (line.indexOf ("Name") > -1) {
					
					avds.push (StringTools.trim (line.substr (line.indexOf ("Name") + 6)));
					
				}
				
			}
			
		}
		
		return avds;
		
	}
	
	
	public static function listDevices ():Array <String> {
		
		var devices = new Array <String> ();
		var output = ProcessHelper.runProcess (adbPath, adbName, [ "devices" ]);
		
		if (output != null && output != "") {
			
			for (line in output.split ("\n")) {
				
				if (line.indexOf ("device") > -1 && line.indexOf ("attached") == -1) {
					
					devices.push (StringTools.trim (line.substr (0, line.indexOf ("device"))));
					
				}
				
			}
			
		}
		
		return devices;
		
	}
	
	
	public static function run (activityName:String, deviceID:String = null):Void {
		
		var args = [ "shell", "am", "start", "-a", "android.intent.action.MAIN", "-n", activityName ];
		
		if (deviceID != null && deviceID != "") {
			
			args.unshift (deviceID);
			args.unshift ("-s");
			
		}
		
		ProcessHelper.runCommand (adbPath, adbName, args);
		
	}
	
	
	public static function trace (project:HXProject, debug:Bool, deviceID:String = null):Void {
		
		// Use -DFULL_LOGCAT or  <set name="FULL_LOGCAT" /> if you do not want to filter log messages
		
		var args = [ "logcat" ];
		
		if (deviceID != null && deviceID != "") {
			
			args.unshift (deviceID);
			args.unshift ("-s");
			
		}
		
		if (project.environment.exists("FULL_LOGCAT") || LogHelper.verbose) {
			
			ProcessHelper.runCommand (adbPath, adbName, args.concat ([ "-c" ]));
			ProcessHelper.runCommand (adbPath, adbName, args);
			
		} else if (debug) {
			
			var filter = "*:E";
			var includeTags = [ "lime", "Main", "GameActivity", "GLThread", "trace" ];
			
			for (tag in includeTags) {
				
				filter += " " + tag + ":D";
				
			}
			
			Sys.println (filter);
			
			ProcessHelper.runCommand (adbPath, adbName, args.concat ([ filter ]));
			
		} else {
			
			ProcessHelper.runCommand (adbPath, adbName, args.concat ([ "*:S trace:I" ]));
			
		}
		
	}
	
	
	public static function uninstall (packageName:String, deviceID:String = null):Void {
		
		var args = [ "uninstall", packageName ];
		
		if (deviceID != null && deviceID != "") {
			
			args.unshift (deviceID);
			args.unshift ("-s");
			
		}
		
		ProcessHelper.runCommand (adbPath, adbName, args);
		
	}
	
	
}