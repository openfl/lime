package helpers;


import haxe.Json;
import project.Haxelib;
import project.HXProject;
import sys.io.File;


class CompatibilityHelper {
	
	
	public static function patchAssetLibrary (project:HXProject, haxelib:Haxelib, targetPath:String, context:Dynamic):Void {
		
		// Need to ensure that older OpenFL releases do not define the __ASSET__ classes for Flash, which are embedded
		// through -swf-lib now, rather than manually stuffing asset data into the SWF after compiling
		
		if (haxelib.name != "openfl") return;
		
		try {
			
			var json = Json.parse (File.getContent (PathHelper.getHaxelib (haxelib) + "/haxelib.json"));
			if (Std.parseInt (json.version.charAt (0)) < 3 && Std.parseInt (json.version.charAt (2)) < 1) {
				
				FileHelper.copyFile (PathHelper.getHaxelib (new Haxelib ("lime")) + "/templates/compatibility/DefaultAssetLibrary.hx", targetPath, context);
				
			}
			
		} catch (e:Dynamic) {}
		
	}
	
	
	public static function patchProject (project:HXProject, haxelib:Haxelib, version:String):Void {
		
		if (haxelib.name == "openfl" && Std.parseInt (version.charAt (0)) < 3 && Std.parseInt (version.charAt (2)) < 1) {
			
			if (project.app.preloader == "") project.app.preloader = "NMEPreloader";
			
		}
		
	}
	
	
}