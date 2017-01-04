package lime.tools.helpers;


import haxe.io.Path;
import lime.tools.helpers.PlatformHelper;
import lime.project.Haxelib;
import lime.project.Platform;
import sys.FileSystem;
import sys.io.File;


class NekoHelper {
	
	
	public static function copyLibraries (templatePaths:Array<String>, platformName:String, targetPath:String) {
		
		//FileHelper.recursiveCopyTemplate (templatePaths, "neko/ndll/" + platformName, targetPath);
		
	}
	
	
	public static function createExecutable (templatePaths:Array<String>, platformName:String, source:String, target:String, iconPath:String = null):Void {
		
		/*var executablePath = PathHelper.findTemplate (templatePaths, "neko/bin/neko-" + platformName);
		var executable = File.getBytes (executablePath);
		var sourceContents = File.getBytes (source);
		
		var output = File.write (target, true);
		output.write (executable);
		output.write (sourceContents);
		output.writeString ("NEKO");
		output.writeInt32 (executable.length);
		output.close ();*/
		
		ProcessHelper.runCommand ("", "nekotools", [ "boot", PathHelper.tryFullPath (source) ]);
		
		var path = Path.withoutExtension (source);
		
		if (PlatformHelper.hostPlatform == WINDOWS) {
			
			path += ".exe";
			
		}
		
		FileHelper.copyFile (path, target);
		
	}
	
	
	public static function createWindowsExecutable (templatePaths:Array<String>, source:String, target:String, iconPath:String):Void {
		
		/*var executablePath = PathHelper.findTemplate (templatePaths, "neko/bin/neko-windows");
		var executable = File.getBytes (executablePath);
		var sourceContents = File.getBytes (source);
		
		var output = File.write (target, true);
		output.write (executable);
		output.close ();
		
		if (iconPath != null && PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			var templates = [ PathHelper.getHaxelib (new Haxelib ("lime")) + "/templates" ].concat (templatePaths);
			ProcessHelper.runCommand ("", PathHelper.findTemplate (templates, "bin/ReplaceVistaIcon.exe"), [ target, iconPath, "1" ], true, true);
			
		}
		
		var executable = File.getBytes (target);
		var output = File.write (target, true);
		output.write (executable);
		output.write (sourceContents);
		output.writeString ("NEKO");
		output.writeInt32 (executable.length);
		output.close ();*/
		
		createExecutable (templatePaths, null, source, target, iconPath);
		
	}
	
	
}
