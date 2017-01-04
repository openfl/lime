package lime.tools.helpers;


import haxe.Json;
import lime.project.Haxelib;
import sys.io.File;
import sys.FileSystem;


class HaxelibHelper {
	
	
	public static function getVersion (haxelib:Haxelib = null):String {
		
		if (haxelib == null) {
			
			haxelib = new Haxelib ("lime");
			
		}
		
		if (haxelib.version != "") {
			
			return haxelib.version;
			
		}
		
		var path = PathHelper.getHaxelib (haxelib, true) + "/haxelib.json";
		
		if (FileSystem.exists (path)) {
			
			var json = Json.parse (File.getContent (path));
			return json.version;
			
		}
		
		return "";
		
	}
	
	
}