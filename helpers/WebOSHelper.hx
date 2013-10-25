package helpers;


import helpers.PlatformHelper;
import helpers.ProcessHelper;
import project.HXProject;
import project.Platform;


class WebOSHelper {
	
	
	public static function createPackage (project:HXProject, workingDirectory:String, targetPath:String):Void {
		
		runPalmCommand (project, workingDirectory, "package" , [ targetPath ]);
		
	}
	
	
	public static function install (project:HXProject, workingDirectory:String):Void {
		
		runPalmCommand (project, workingDirectory, "install", [ project.meta.packageName + "_" + project.meta.version + "_all.ipk" ]);
		
	}
	
	
	public static function launch (project:HXProject):Void {
		
		runPalmCommand (project, "", "launch", [ project.meta.packageName ]);
		
	}
	
	
	private static function runPalmCommand (project:HXProject, workingDirectory:String, command:String, args:Array<String>):Void {
		
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
	
	
	public static function trace (project:HXProject, follow:Bool = true):Void {
		
		var args = [];
		
		if (follow) {
			
			args.push ("-f");
			
		}
		
		args.push (project.meta.packageName);
		
		runPalmCommand (project, "", "log", args);
		
	}
		

}
