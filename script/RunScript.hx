package;


import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;


class RunScript {
	

	public static function runCommand (path:String, command:String, args:Array<String>, throwErrors:Bool = true):Int {
		
		var oldPath:String = "";
		
		if (path != null && path != "") {
			
			oldPath = Sys.getCwd ();
			
			try {
				
				Sys.setCwd (path);
				
			} catch (e:Dynamic) {
				
				//Sys.stderr ().write (Bytes.ofString ("Cannot set current working directory to \"" + path + "\""));
				//Sys.exit (1);
				//error ("Cannot set current working directory to \"" + path + "\"");
				
			}
			
		}
		
		var result:Dynamic = Sys.command (command, args);
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
		if (throwErrors && result != 0) {
			
			Sys.exit (1);
			
		}
		
		return result;
		
	}
	
	
	public static function main () {
		
		var args = Sys.args ();
		var command = args[0];
		
		if (command == "rebuild") {
			
			// When the command-line tools are called from haxelib, 
			// the last argument is the project directory and the
			// path to Lime is the current working directory 
			
			var ignoreLength = 0;
			var lastArgument = new Path (args[args.length - 1]).toString ();
			
			if (((StringTools.endsWith (lastArgument, "/") && lastArgument != "/") || StringTools.endsWith (lastArgument, "\\")) && !StringTools.endsWith (lastArgument, ":\\")) {
				
				lastArgument = lastArgument.substr (0, lastArgument.length - 1);
				
			}
			
			if (FileSystem.exists (lastArgument) && FileSystem.isDirectory (lastArgument)) {
				
				Sys.setCwd (lastArgument);
				//args.pop ();
				ignoreLength++;
				
			}
			
			for (arg in args) {
				
				if (StringTools.startsWith (arg, "-D")) {
					
					ignoreLength++;
					
				} else if (StringTools.startsWith (arg, "--") && arg.indexOf ("=") > -1) {
					
					ignoreLength++;
					
				} else if (StringTools.startsWith (arg, "-")) {
					
					ignoreLength++;
					
				}
				
			}
			
			if (args.length == 2 + ignoreLength) {
				
				args.insert (1, "lime");
				
			}
			
		}
		
		var workingDirectory = args.pop ();
		var args = [ "run", "aether" ].concat (args);
		
		Sys.exit (runCommand (workingDirectory, "haxelib", args));
		
	}
	
	
}