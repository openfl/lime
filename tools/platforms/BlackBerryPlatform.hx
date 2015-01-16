package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.AssetHelper;
import helpers.BlackBerryHelper;
import helpers.CPPHelper;
import helpers.FileHelper;
import helpers.HTML5Helper;
import helpers.IconHelper;
import helpers.LogHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import project.AssetType;
import project.Haxelib;
import project.HXProject;
import project.NDLL;
import project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class BlackBerryPlatform extends PlatformTarget {
	
	
	private var outputFile:String;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String>) {
		
		super (command, _project, targetFlags);
		
		if (command != "display" && command != "clean") {
			
			project = project.clone ();
			
			if (!project.environment.exists ("BLACKBERRY_SETUP")) {
				
				LogHelper.error ("You need to run \"lime setup blackberry\" before you can use the BlackBerry target");
				
			}
			
			if (!project.targetFlags.exists ("html5")) {
				
				targetDirectory = project.app.path + "/blackberry/cpp";
				outputFile = targetDirectory + "/bin/" + PathHelper.safeFileName (project.app.file);
				
			} else {
				
				targetDirectory = project.app.path + "/blackberry/html5";
				outputFile = targetDirectory + "/src/" + project.app.file + ".js";
				
			}
			
			BlackBerryHelper.initialize (project);
			
		}
		
	}
	
	
	public override function build ():Void {
		
		if (project.app.main != null) {
			
			var type = "release";
			
			if (project.debug) {
				
				type = "debug";
				
			} else if (project.targetFlags.exists ("final")) {
				
				type = "final";
				
			}
			
			var hxml = targetDirectory + "/haxe/" + type + ".hxml";
			ProcessHelper.runCommand ("", "haxe", [ hxml, "-D", "blackberry" ] );
			
		}
		
		if (!project.targetFlags.exists ("html5")) {
			
			var destination = targetDirectory + "/bin/";
			var arch = "";
			
			if (project.targetFlags.exists ("simulator")) {
				
				arch = "-x86";
				
			}
			
			var haxelib = new Haxelib ("lime");
			var ndlls = project.ndlls.copy ();
			ndlls.push (new NDLL ("libTouchControlOverlay", haxelib));
			
			for (ndll in ndlls) {
				
				FileHelper.copyLibrary (project, ndll, "BlackBerry", "", arch + ".so", destination, project.debug, ".so");
				
			}
			
			var linkedLibraries = [ new NDLL ("libSDL", haxelib), new NDLL ("libOpenAL", haxelib) ];
			
			for (ndll in linkedLibraries) {
				
				var deviceLib = ndll.name + ".so";
				var simulatorLib = ndll.name + "-x86.so";
				
				if (project.targetFlags.exists ("simulator")) {
					
					if (FileSystem.exists (destination + deviceLib)) {
						
						FileSystem.deleteFile (destination + deviceLib);
						
					}
					
					FileHelper.copyIfNewer (PathHelper.getLibraryPath (ndll, "BlackBerry", "", "-x86.so"), destination + simulatorLib);
					
				} else {
					
					if (FileSystem.exists (destination + simulatorLib)) {
						
						FileSystem.deleteFile (destination + simulatorLib);
						
					}
					
					FileHelper.copyIfNewer (PathHelper.getLibraryPath (ndll, "BlackBerry", "", ".so"), destination + deviceLib);
					
				}
				
			}
			
			CPPHelper.compile (project, targetDirectory + "/obj", [ "-Dblackberry" ]);
			FileHelper.copyIfNewer (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), outputFile);
			BlackBerryHelper.createPackage (project, targetDirectory, "bin/bar-descriptor.xml", project.meta.packageName + "_" + project.meta.version + ".bar");
			
		} else {
			
			if (project.targetFlags.exists ("minify")) {
				
				HTML5Helper.minify (project, targetDirectory + "/src/" + project.app.file + ".js");
				
			}
			
			BlackBerryHelper.createWebWorksPackage (project, targetDirectory + "/src", targetDirectory + "/bin");
			
		}
		
	}
	
	
	public override function clean ():Void {
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function display ():Void {
		
		var hxml = "";
		var context = project.templateContext;
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		if (!project.targetFlags.exists ("html5")) {
			
			hxml = PathHelper.findTemplate (project.templatePaths, "blackberry/hxml/" + type + ".hxml");
			
			context.CPP_DIR = targetDirectory + "/obj";
			
		} else {
			
			hxml = PathHelper.findTemplate (project.templatePaths, "html5/hxml/" + type + ".hxml");
			
			context.OUTPUT_DIR = targetDirectory;
			context.OUTPUT_FILE = outputFile;
			
		}
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	public override function rebuild ():Void {
		
		var device = (command == "rebuild" || !targetFlags.exists ("simulator"));
		var simulator = (command == "rebuild" || targetFlags.exists ("simulator"));
		
		var commands = [];
		
		if (device) commands.push ([ "-Dblackberry" ]);
		if (simulator) commands.push ([ "-Dblackberry", "-Dsimulator" ]);
		
		CPPHelper.rebuild (project, commands);
		
	}
	
	
	public override function run ():Void {
		
		if (!project.targetFlags.exists ("html5")) {
			
			BlackBerryHelper.deploy (project, targetDirectory, project.meta.packageName + "_" + project.meta.version + ".bar");
			
		} else {
			
			BlackBerryHelper.deploy (project, targetDirectory + "/bin/" + (project.targetFlags.exists ("simulator") ? "simulator" : "device"), PathHelper.safeFileName (project.app.file) + ".bar");
			
		}
		
	}
	
	
	public override function trace ():Void {
		
		if (!project.targetFlags.exists ("html5")) {
			
			BlackBerryHelper.trace (project, targetDirectory, project.meta.packageName + "_" + project.meta.version + ".bar");
		
		} else {
			
			//BlackBerryHelper.trace (project, targetDirectory + "/bin/" + (project.targetFlags.exists ("simulator") ? "simulator" : "device"), PathHelper.safeFileName (project.app.file) + ".bar");
			
		}
		
	}
	
	
	public override function update ():Void {
		
		//project = project.clone ();
		//initialize (project);
		
		if (!project.targetFlags.exists ("html5")) {
			
			for (asset in project.assets) {
				
				asset.resourceName = "app/native/" + asset.resourceName;
				
			}
			
		} else {
			
			for (asset in project.assets) {
				
				if (asset.type == AssetType.FONT) {
					
					project.haxeflags.push (HTML5Helper.generateFontData (project, asset));
					
				}
				
			}
			
			project.haxedefs.set ("html5", 1);
			
		}
		
		if (project.targetFlags.exists ("simulator")) {
			
			project.haxedefs.set ("simulator", 1);
			
		}
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		var context = project.templateContext;
		var destination = targetDirectory + "/bin/";
		
		if (!project.targetFlags.exists ("html5")) {
			
			context.CPP_DIR = targetDirectory + "/obj";
			
		} else {
			
			destination = targetDirectory + "/src/";
			
			context.WIN_FLASHBACKGROUND = StringTools.hex (project.window.background, 6);
			context.OUTPUT_DIR = targetDirectory;
			context.OUTPUT_FILE = outputFile;
			
		}
		
		context.BLACKBERRY_AUTHOR_ID = BlackBerryHelper.processDebugToken (project, targetDirectory).authorID;
		context.APP_FILE_SAFE = PathHelper.safeFileName (project.app.file);
		
		PathHelper.mkdir (destination);
		
		context.ICONS = [];
		context.HAS_ICON = false;
		
		for (size in [ 114, 86 ]) {
			
			if (IconHelper.createIcon (project.icons, size, size, PathHelper.combine (destination, "icon-" + size + ".png"))) {
				
				context.ICONS.push ("icon-" + size + ".png");
				context.HAS_ICON = true;
				
			}
			
		}
		
		if (!project.targetFlags.exists ("html5")) {
			
			FileHelper.copyFileTemplate (project.templatePaths, "blackberry/template/bar-descriptor.xml", destination + "/bar-descriptor.xml", context);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "blackberry/hxml", targetDirectory + "/haxe", context);
			
		} else {
			
			FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/template", destination, context);
			FileHelper.copyFileTemplate (project.templatePaths, "blackberry/template/config.xml", destination + "/config.xml", context);
			
			if (project.app.main != null) {
				
				FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
				FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/haxe", targetDirectory + "/haxe", context);
				FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/hxml", targetDirectory + "/haxe", context);
				
			}
			
		}
		
		for (asset in project.assets) {
			
			var targetPath = PathHelper.combine (destination, asset.targetPath);
			PathHelper.mkdir (Path.directory (targetPath));
			
			if (asset.type != AssetType.TEMPLATE) {
				
				if (asset.type != AssetType.FONT || !project.targetFlags.exists ("html5")) {
					
					FileHelper.copyAssetIfNewer (asset, targetPath);
					
				}
				
			} else {
				
				FileHelper.copyAsset (asset, targetPath, context);
				
			}
			
		}
		
		AssetHelper.createManifest (project, PathHelper.combine (destination, "manifest"));
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}