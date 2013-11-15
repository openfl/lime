package helpers;


import haxe.io.Eof;
import helpers.PlatformHelper;
import helpers.ProcessHelper;
import project.HXProject;
import project.Platform;
import sys.FileSystem;


class TizenHelper {
	
	
	public static function createPackage (project:HXProject, workingDirectory:String, targetPath:String):Void {
		
		var password = null;
		
		if (project.certificate != null) {
			
			password = project.certificate.password;
			
			if (password == null) {
				
				password = prompt ("Keystore password", true);
				Sys.println ("");
				
			}
			
		}
		
		if (FileSystem.exists (PathHelper.combine (workingDirectory, project.meta.packageName + "-" + project.meta.version + "-arm.tpk"))) {
			
			try {
				
				FileSystem.deleteFile ((PathHelper.combine (workingDirectory, project.meta.packageName + "-" + project.meta.version + "-arm.tpk")));
				
			} catch (e:Dynamic) {}
			
		}
		
		runCommand (project, workingDirectory, "native-packaging" , [ "--sign-author-key", project.certificate.path, "--sign-author-pwd", password ]);
		
	}
	
	
	public static function install (project:HXProject, workingDirectory:String):Void {
		
		runCommand (project, "", "native-install", [ "--package", FileSystem.fullPath (workingDirectory + "/" + project.meta.packageName + "-" + project.meta.version + "-arm.tpk") ]);
		
	}
	
	
	public static function launch (project:HXProject):Void {
		
		runCommand (project, "", "native-run", [ "--package", project.meta.packageName ]);
		
	}
	
	
	private static function prompt (name:String, ?passwd:Bool):String {
		
		Sys.print (name + ": ");
		
		if (passwd) {
			var s = new StringBuf ();
			var c;
			while ((c = Sys.getChar(false)) != 13)
				s.addChar (c);
			return s.toString ();
		}
		
		try {
			
			return Sys.stdin ().readLine ();
			
		} catch (e:Eof) {
			
			return "";
			
		}
		
	}
	
	
	private static function runCommand (project:HXProject, workingDirectory:String, command:String, args:Array<String>):Void {
		
		var sdkDirectory = "";
		
		if (project.environment.exists ("TIZEN_SDK")) {
			
			sdkDirectory = project.environment.get ("TIZEN_SDK");
			
		} else {
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				sdkDirectory = "C:\\Development\\Tizen\\tizen-sdk";
				
			} else {
				
				sdkDirectory = "~/Development/Tizen/tizen-sdk";
				
			}
			
		}
		
		ProcessHelper.runCommand (workingDirectory, PathHelper.combine (sdkDirectory, "tools/ide/bin/" + command), args);
		
	}
	
	
	public static function trace (project:HXProject, follow:Bool = true):Void {
		
		/*var args = [];
		
		if (follow) {
			
			args.push ("-f");
			
		}
		
		args.push (project.meta.packageName);
		
		runPalmCommand (project, "", "log", args);*/
		
		var sdkDirectory = "";
		
		if (project.environment.exists ("TIZEN_SDK")) {
			
			sdkDirectory = project.environment.get ("TIZEN_SDK");
			
		} else {
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				sdkDirectory = "C:\\Development\\Tizen\\tizen-sdk";
				
			} else {
				
				sdkDirectory = "~/Development/Tizen/tizen-sdk";
				
			}
			
		}
		
		//var args = [ "--package", project.meta.packageName ];
		//var args = [ "dlog", project.meta.packageName + ":V", "*:E" ];
		var args = [ "dlog", project.app.file + ":V", "*:F" ];
		
		ProcessHelper.runCommand ("", PathHelper.combine (sdkDirectory, "tools/sdb"), [ "dlog", "-c" ]);
		ProcessHelper.runCommand ("", PathHelper.combine (sdkDirectory, "tools/sdb"), args);
		//runCommand (project, "", "native-debug", [ "-p", project.meta.packageName ]);
		
	}
	
	
}
