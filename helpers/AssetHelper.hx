package helpers;


import haxe.io.Path;
import haxe.Serializer;
import haxe.Unserializer;
import openfl.Assets;
import project.OpenFLProject;
import sys.io.File;


class AssetHelper {
	
	
	public static function createManifest (project:OpenFLProject, targetPath:String = ""):String {
		
		var manifest = new Array <AssetData> ();
		
		for (asset in project.assets) {
			
			if (asset.type != AssetType.TEMPLATE) {
				
				var data = new AssetData ();
				data.id = asset.id;
				data.path = asset.resourceName;
				data.type = asset.type;
				manifest.push (data);
				
			}
			
		}
		
		var data = Serializer.run (manifest);
		
		if (targetPath != "") {
			
			File.saveContent (targetPath, data);
			
		}
		
		return data;
		
	}
	
	
	public static function processLibraries (project:OpenFLProject):Void {
		
		var handlers = new Array <String> ();
		
		for (library in project.libraries) {
			
			var type = library.type;
			
			if (type == null) {
				
				type = Path.extension (library.sourcePath).toLowerCase ();
				
			}
			
			if (project.libraryHandlers.exists (type)) {
				
				var handler = project.libraryHandlers.get (type);
				
				handlers.remove (handler);
				handlers.push (handler);
				
			}
			
		}
		
		if (handlers.length > 0) {
			
			var projectData = Serializer.run (project);
			
			for (handler in handlers) {
				
				var output = ProcessHelper.runProcess ("", "haxelib", [ "run", handler, "process", projectData ]);
				//var output = "";
				//ProcessHelper.runCommand ("", "haxelib", [ "run", handler, "process", projectData ]);
				//Sys.exit (0);
				
				if (output != null && output != "") {
					
					try {
						
						var data:OpenFLProject = Unserializer.run (output);
						project.merge (data);
						
					} catch (e:Dynamic) {
						
						LogHelper.error (e);
						
					}
					
				}
				
			}
			
		}
		
	}
	

}