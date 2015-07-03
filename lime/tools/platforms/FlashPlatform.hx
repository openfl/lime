package lime.tools.platforms;


import haxe.io.Path;
import haxe.Json;
import haxe.Template;
import lime.tools.helpers.CompatibilityHelper;
import lime.tools.helpers.DeploymentHelper;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.FlashHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.ProcessHelper;
import lime.project.AssetType;
import lime.project.Haxelib;
import lime.project.HXProject;
import lime.project.Platform;
import lime.project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;

#if neko
import neko.vm.Thread;
#end


class FlashPlatform extends PlatformTarget {
	
	
	private var embedded:Bool;
	private var logLength:Int;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String>) {
		
		super (command, _project, targetFlags);
		
		targetDirectory = project.app.path + "/flash";
		
	}
	
	
	public override function build ():Void {
		
		var destination = targetDirectory + "/bin";
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		if (embedded) {
			
			var hxml = File.getContent (targetDirectory + "/haxe/" + type + ".hxml");
			var args = new Array<String> ();
			
			for (line in ~/[\r\n]+/g.split (hxml)) {
				
				line = StringTools.ltrim (line);
				
				if (StringTools.startsWith (line, "#") || line.indexOf ("-swf-header") > -1) {
					
					continue;
					
				}
				
				var space = line.indexOf (" ");
				
				if (space == -1) {
					
					args.push (StringTools.rtrim (line));
					
				} else {
					
					args.push (line.substr (0, space));
					
					args.push (StringTools.trim (line.substr (space + 1)));
					
				}
				
			}
				
			ProcessHelper.runCommand ("", "haxe", args);
			
		} else {
			
			var hxml = targetDirectory + "/haxe/" + type + ".hxml";
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
		
		var targetPath = targetDirectory + "";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public override function deploy ():Void {
		
		DeploymentHelper.deploy (project, targetFlags, targetDirectory, "Flash");
		
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
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
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
		
		if (traceEnabled) {
			
			FlashHelper.enableLogging ();
			logLength = FlashHelper.getLogLength ();
			
		}
		
		if (project.app.url != null && project.app.url != "") {
			
			ProcessHelper.openURL (project.app.url);
			
		} else {
			
			var destination = targetDirectory + "/bin";
			var targetPath = project.app.file + ".swf";
			
			if (project.targetFlags.exists ("web")) {
				
				targetPath = "index.html";
				
			}
			
			if (traceEnabled) {
				
				#if neko Thread.create (function () { #end
					
					FlashHelper.run (project, destination, targetPath);
					Sys.exit (0);
					
				#if neko }); #end
				
				Sys.sleep (0.1);
				
			} else {
				
				FlashHelper.run (project, destination, targetPath);
				
			}
			
		}
		
	}
	
	
	public override function update ():Void {
		
		var destination = targetDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		embedded = FlashHelper.embedAssets (project);
		
		var context = generateContext ();
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "flash/hxml", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "flash/haxe", targetDirectory + "/haxe", context, true, false);
		
		//SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
		var usesNME = false;
		
		for (haxelib in project.haxelibs) {
			
			if (haxelib.name == "nme" || haxelib.name == "openfl") {
				
				usesNME = true;
				
			}
			
			if (haxelib.name == "openfl") {
				
				CompatibilityHelper.patchAssetLibrary (project, haxelib, targetDirectory + "/haxe/DefaultAssetLibrary.hx", context);
				
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
	
	
	public override function trace ():Void {
		
		FlashHelper.tailLog (0);
		
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
	@ignore public override function uninstall ():Void {}
	
}
