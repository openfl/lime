package helpers;


import helpers.ProcessHelper;
import project.HXProject;


class CPPHelper {
	
	
	public static function compile (project:HXProject, path:String, flags:Array<String> = null, buildFile:String = "Build.xml"):Void {
		
		if (project.config.cpp.requireBuild) {
			
			var args = [ "run", project.config.cpp.buildLibrary, buildFile ];
			
			if (flags != null) {
				
				args = args.concat (flags);
				
			}
			
			for (key in project.haxedefs.keys ()) {
				
				var value = project.haxedefs.get (key);
				
				if (value == null || value == "") {
					
					args.push ("-D" + key);
					
				} else {
					
					args.push ("-D" + key + "=" + value);
					
				}
				
			}
			
			if (project.debug) {
				
				args.push ("-Ddebug");
				
			}
			
			ProcessHelper.runCommand (path, "haxelib", args);
			
		}
		
	}
	
	
}