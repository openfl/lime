package helpers;


import helpers.PlatformHelper;
import helpers.ProcessHelper;
import project.OpenFLProject;
import project.Platform;


class WebOSHelper {
	
	
	public static function createPackage (project:OpenFLProject, workingDirectory:String, targetPath:String):Void {
		
		runPalmCommand (project, workingDirectory, "package" , [ targetPath ]);
		
	}
	
	
	public static function install (project:OpenFLProject, workingDirectory:String):Void {
		
		runPalmCommand (project, workingDirectory, "install", [ project.meta.packageName + "_" + project.meta.version + "_all.ipk" ]);
		
	}
	
	
	public static function launch (project:OpenFLProject):Void {
		
		runPalmCommand (project, "", "launch", [ project.meta.packageName ]);
		
	}
	
	
	private static function runPalmCommand (project:OpenFLProject, workingDirectory:String, command:String, args:Array<String>):Void {
		
		var sdkDirectory = "";
		
		if (project.environment.exists ("PalmSDK")) {
			
			sdkDirectory = project.environment.get ("PalmSDK");
			
		} else {
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				sdkDirectory = "c:\\Program Files (x86)\\HP webOS\\SDK\\";
				
			} else {
				
				sdkDirectory = "/opt/PalmSDK/Current/";
				
			}
			
		}
		
		ProcessHelper.runCommand (workingDirectory, PathHelper.combine (sdkDirectory, "bin/palm-" + command), args);
		
	}
	
	
	public static function trace (project:OpenFLProject, follow:Bool = true):Void {
		
		var args = [];
		
		if (follow) {
			
			args.push ("-f");
			
		}
		
		args.push (project.meta.packageName);
		
		runPalmCommand (project, "", "log", args);
		
	}
		

}
