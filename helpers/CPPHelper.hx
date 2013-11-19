package helpers;


import helpers.ProcessHelper;
import project.HXProject;
import sys.io.File;
import sys.FileSystem;


class CPPHelper {
	
	
	public static function compile (project:HXProject, path:String, flags:Array<String> = null, buildFile:String = "Build.xml"):Void {
		
		if (project.config.cpp.requireBuild) {
			
			var args = [ "run", project.config.cpp.buildLibrary, buildFile ];
			var foundOptions = false;
			
			try {
				
				var options = PathHelper.combine (path, "Options.txt");
				
				if (FileSystem.exists (options)) {
					
					var input = File.read (options, false);
					var text = input.readLine ();
					input.close ();
					
					var list = text.split (" ");
					
					for (option in list) {
						
						if (option != "" && !StringTools.startsWith (option, "-Dno_compilation") && !StringTools.startsWith (option, "-Dno-compilation")) {
							
							args.push (option);
							
						}
						
					}
					
					foundOptions = true;
					
				}
				
			} catch (e:Dynamic) {}
			
			if (flags != null) {
				
				args = args.concat (flags);
				
			}
			
			if (!foundOptions) {
				
				for (key in project.haxedefs.keys ()) {
					
					var value = project.haxedefs.get (key);
					
					if (value == null || value == "") {
						
						args.push ("-D" + key);
						
					} else {
						
						args.push ("-D" + key + "=" + value);
						
					}
					
				}
				
			}
			
			if (project.debug) {
				
				args.push ("-Ddebug");
				
			}
			
			ProcessHelper.runCommand (path, "haxelib", args);
			
		}
		
	}
	
	
}