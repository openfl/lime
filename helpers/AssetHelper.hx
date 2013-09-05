package helpers;


import haxe.Serializer;
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
	

}