package platforms;


import haxe.io.Path;
import haxe.Json;
import haxe.Template;
import helpers.CompatibilityHelper;
import helpers.FileHelper;
import helpers.FlashHelper;
import helpers.PathHelper;
import helpers.PlatformHelper;
import helpers.ProcessHelper;
import project.AssetType;
import project.Haxelib;
import project.HXProject;
import project.Platform;
import project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class FlashPlatform extends PlatformTarget {
	
	
	private var embedded:Bool;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String>) {
		
		super (command, _project, targetFlags);
		
	}
	
	
	public override function build ():Void {
		
		var destination = project.app.path + "/flash/bin";
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		if (embedded) {
			
			var hxml = File.getContent (project.app.path + "/flash/haxe/" + type + ".hxml");
			hxml = StringTools.replace (hxml, "\r\n", "\n");
			
			var lines = hxml.split ("\n");
			hxml = "";
			
			for (line in lines) {
				
				if (!StringTools.startsWith (line, "#")) {
					
					if (hxml.length > 0) hxml += " ";
					hxml += line;
					
				}
				
			}
			
			hxml = StringTools.trim (hxml);
			
			var args = new EReg ("\\s+", "g").split (hxml);
			var strip;
			
			while ((strip = args.indexOf ("-swf-header")) > -1) {
				
				args.splice (strip, 2);
				
			}
			
			var index = 2;
			
			while (index < args.length) {
				
				if (!StringTools.startsWith (args[index - 1], "-") && !StringTools.startsWith (args[index], "-")) {
					
					args[index - 1] += " " + args[index];
					args.splice (index, 1);
					
				} else {
					
					index++;
					
				}
				
			}
			
			if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
				
				for (i in 0...args.length) {
					
					if (args[i].indexOf ("(") > -1) {
						
						args[i] = "'" + args[i] + "'";
						
					}
					
				}
				
			}
			
			ProcessHelper.runCommand ("", "haxe", args);
			
		} else {
			
			var hxml = project.app.path + "/flash/haxe/" + type + ".hxml";
			ProcessHelper.runCommand ("", "haxe", [ hxml ] );
			
		}
		
		/*var usesOpenFL = false;
		
		for (haxelib in project.haxelibs) {
			
			if (haxelib.name == "nme" || haxelib.name == "openfl") {
				
				usesOpenFL = true;
				
			}
			
		}
		
		if (usesOpenFL) {
			
			FlashHelper.embedAssets (destination + "/" + project.app.file + ".swf", project.assets);
			
		}*/
		
	}
	
	
	public override function clean ():Void {
		
		var targetPath = project.app.path + "/flash";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public override function display ():Void {
		
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
	
	
	private function generateContext ():Dynamic {
		
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
				
				case MUSIC : asset.flashClass = "flash.media.Sound";
				case SOUND : asset.flashClass = "flash.media.Sound";
				case IMAGE : asset.flashClass = "flash.display.BitmapData";
				case FONT : asset.flashClass = "flash.text.Font";
				default: asset.flashClass = "flash.utils.ByteArray";
				
			}
			
		}
		
		return context;
		
	}
	
	
	public override function run ():Void {
		
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
	
	
	public override function update ():Void {
		
		var destination = project.app.path + "/flash/bin/";
		PathHelper.mkdir (destination);
		
		embedded = FlashHelper.embedAssets (project);
		
		var context = generateContext ();
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", project.app.path + "/flash/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "flash/hxml", project.app.path + "/flash/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "flash/haxe", project.app.path + "/flash/haxe", context, true, false);
		
		//SWFHelper.generateSWFClasses (project, project.app.path + "/flash/haxe");
		
		var usesNME = false;
		
		for (haxelib in project.haxelibs) {
			
			if (haxelib.name == "nme" || haxelib.name == "openfl") {
				
				usesNME = true;
				
			}
			
			if (haxelib.name == "openfl") {
				
				CompatibilityHelper.patchAssetLibrary (project, haxelib, project.app.path + "/flash/haxe/DefaultAssetLibrary.hx", context);
				
			}
			
		}
		
		if (project.targetFlags.exists ("web") || project.app.url != "") {
			
			PathHelper.mkdir (destination);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "flash/templates/web", destination, generateContext ());
			
		}
		
		for (asset in project.assets) {
			
			if (asset.type == AssetType.TEMPLATE || asset.embed == false || !usesNME) {
				
				var path = PathHelper.combine (destination, asset.targetPath);
				
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path, context);
				
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
	
	
	@ignore public override function install ():Void {}
	@ignore public override function rebuild ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
}
