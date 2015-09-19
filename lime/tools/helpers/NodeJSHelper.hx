package lime.tools.helpers;


import haxe.io.Path;
import lime.project.Architecture;
import lime.project.Haxelib;
import lime.project.HXProject;
import lime.project.Platform;


class NodeJSHelper {
	
	
	public static function run (project:HXProject, modulePath:String, args:Array<String> = null):Void {
		
		/*var suffix = switch (PlatformHelper.hostPlatform) {
			
			case Platform.WINDOWS: "-windows.exe";
			case Platform.MAC: "-mac";
			case Platform.LINUX: "-linux";
			default: return;
			
		}
		
		if (suffix == "-linux") {
			
			if (PlatformHelper.hostArchitecture == Architecture.X86) {
				
				suffix += "32";
				
			} else {
				
				suffix += "64";
				
			}
			
		}
		
		var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
		var node = PathHelper.findTemplate (templatePaths, "bin/node/node" + suffix);
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			Sys.command ("chmod", [ "+x", node ]);
			
		}
		
		if (args == null) {
			
			args = [];
			
		}*/
		
		args.unshift (Path.withoutDirectory (modulePath));
		
		ProcessHelper.runCommand (Path.directory (modulePath), "node", args);
		
	}
	
	
}