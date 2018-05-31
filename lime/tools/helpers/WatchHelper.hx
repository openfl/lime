package lime.tools.helpers;


import lime.project.Architecture;
import lime.project.Haxelib;
import lime.project.HXProject;
import lime.project.Platform;
import sys.FileSystem;


class WatchHelper {
	
	
	public static function getCurrentCommand ():String {
		
		var args = Sys.args ();
		args.remove ("-watch");
		
		if (HaxelibHelper.pathOverrides.exists ("lime-tools")) {
			
			var tools = HaxelibHelper.pathOverrides.get ("lime-tools");
			
			return "neko " + tools + "/tools.n " + args.join (" ");
			
		} else {
			
			args.pop ();
			
			return "lime " + args.join (" ");
			
		}
		
	}
	
	
	public static function processHXML (project:HXProject, hxml:String):Array<String> {
		
		var directories = [];
		var outputPath = PathHelper.tryFullPath (project.app.path);
		var dir, fullPath = null;
		
		for (line in hxml.split ("\n")) {
			
			if (StringTools.startsWith (line, "-cp ")) {
				
				dir = StringTools.trim (line.substr (4));
				
				if (FileSystem.exists (dir)) {
					
					fullPath = PathHelper.tryFullPath (dir);
					
					if (!StringTools.startsWith (fullPath, outputPath)) {
						
						// directories.push (fullPath);
						directories.push (dir);
						
					}
					
				}
				
			}
			
		}
		
		return directories;
		
	}
	
	
	public static function watch (project:HXProject, command:String, directories:Array<String>):Void {
		
		var suffix = switch (PlatformHelper.hostPlatform) {
			
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
		var bin = PathHelper.findTemplate (templatePaths, "bin/node/watch/cli-custom.js");
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			Sys.command ("chmod", [ "+x", node ]);
			
		}
		
		var args = [ bin, command ];
		args = args.concat (directories);
		
		args.push ("--exit");
		args.push ("--ignoreDotFiles");
		args.push ("--ignoreUnreadable");
		
		ProcessHelper.runCommand ("", node, args);
		
	}
	
	
}