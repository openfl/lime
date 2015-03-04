package lime.tools.helpers;


import haxe.io.Path;
import lime.project.Architecture;
import lime.project.Haxelib;
import lime.project.HXProject;
import lime.project.Platform;


class NodeJSHelper {
	
	
	public static function run (project:HXProject, modulePath:String, args:Array<String> = null):Void {

		if (args == null) {
			
			args = [];
			
		}
		
		args.unshift (Path.withoutDirectory (modulePath));
		
		ProcessHelper.runCommand (Path.directory (modulePath), "iojs", args);
		
	}
	
	
}