package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.FileHelper;
import helpers.FlashHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import project.AssetType;
import project.HXProject;
import sys.io.File;
import sys.FileSystem;

class FlashPlatform implements IPlatformTool {
	
	
	public function build (project:HXProject):Void {
		
		var destination = project.app.path + "/flash/bin";
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = project.app.path + "/flash/haxe/" + type + ".hxml";
		
		ProcessHelper.runCommand ("", "haxe", [ hxml ] );
		
		var usesOpenFL = false;
		
		for (haxelib in project.haxelibs) {
			
			if (haxelib.name == "nme" || haxelib.name == "openfl") {
				
				usesOpenFL = true;
				
			}
			
		}
		
		if (usesOpenFL) {
			
			FlashHelper.embedAssets (destination + "/" + project.app.file + ".swf", project.assets);
			
		}
		
	}
	
	
	public function clean (project:HXProject):Void {
		
		var targetPath = project.app.path + "/flash";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public function display (project:HXProject):Void {
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "flash/hxml/" + type + ".hxml");
		
		var context = project.templateContext;
		context.WIN_FLASHBACKGROUND = StringTools.hex (project.window.background, 6);
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	private function generateContext (project:HXProject):Dynamic {
		
		project = project.clone ();
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + project.app.path + "/flash/types.xml");
			
		}
		
		var context = project.templateContext;
		context.WIN_FLASHBACKGROUND = StringTools.hex (project.window.background, 6);
		var assets:Array <Dynamic> = cast context.assets;
		
		for (asset in assets) {
			
			var assetType:AssetType = Reflect.field (AssetType, asset.type.toUpperCase ());
			
			switch (assetType) {
				
				case MUSIC : asset.flashClass = "openfl.media.Sound";
				case SOUND : asset.flashClass = "openfl.media.Sound";
				case IMAGE : asset.flashClass = "openfl.display.BitmapData";
				case FONT : asset.flashClass = "openfl.text.Font";
				default: asset.flashClass = "openfl.utils.ByteArray";
				
			}
			
		}
		
		return context;
		
	}
	
	
	public function run (project:HXProject, arguments:Array <String>):Void {
		
		if (project.app.url != null && project.app.url != "") {
			
			ProcessHelper.openURL (project.app.url);
			
		} else {
			
			var destination = project.app.path + "/flash/bin";
			var targetPath = project.app.file + ".swf";
			
			if (project.targetFlags.exists ("web")) {
				
				targetPath = "index.html";
				
			}
			
			FlashHelper.run (project, destination, targetPath);
			
		}
		
	}
	
	
	public function update (project:HXProject):Void {
		
		var destination = project.app.path + "/flash/bin/";
		PathHelper.mkdir (destination);
		
		var context = generateContext (project);
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", project.app.path + "/flash/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "flash/hxml", project.app.path + "/flash/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "flash/haxe", project.app.path + "/flash/haxe", context);
		
		//SWFHelper.generateSWFClasses (project, project.app.path + "/flash/haxe");
		
		var usesNME = false;
		
		for (haxelib in project.haxelibs) {
			
			if (haxelib.name == "nme" || haxelib.name == "openfl") {
				
				usesNME = true;
				
			}
			
		}

		if (project.targetFlags.exists ("web") || project.app.url != "") {
			
			PathHelper.mkdir (destination);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "flash/templates/web", destination, generateContext (project));

			for (asset in project.assets) {
				
				if (asset.type == AssetType.TEMPLATE || asset.embed == false || !usesNME) {
					
					var path = PathHelper.combine (destination, asset.targetPath);
					
					PathHelper.mkdir (Path.directory (path));
					FileHelper.copyAsset (asset, path, context);
					
				}
				
			}

		}
		
		
	}
	
	
	/*private function getIcon (size:Int, targetPath:String):Void {
		
		var icon = icons.findIcon (size, size);
		
		if (icon != "") {
			
			FileHelper.copyIfNewer (icon, targetPath);
			
		} else {
			
			icons.updateIcon (size, size, targetPath);
			
		}
		
	}*/
	
	
	public function new () {}
	@ignore public function install (project:HXProject):Void { }
	@ignore public function trace (project:HXProject):Void { }
	@ignore public function uninstall (project:HXProject):Void { }
	
	
	
}