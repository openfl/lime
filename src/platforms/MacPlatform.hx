package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.AssetHelper;
import helpers.FileHelper;
import helpers.IconHelper;
import helpers.NekoHelper;
import helpers.PathHelper;
import helpers.PlatformHelper;
import helpers.ProcessHelper;
import project.Architecture;
import project.AssetType;
import project.OpenFLProject;
import project.Platform;
import sys.io.File;
import sys.FileSystem;


class MacPlatform implements IPlatformTool {
	
	
	private var applicationDirectory:String;
	private var contentDirectory:String;
	private var executableDirectory:String;
	private var executablePath:String;
	private var is64:Bool;
	private var targetDirectory:String;
	private var useNeko:Bool;
	
	
	public function build (project:OpenFLProject):Void {
		
		initialize (project);
		
		var hxml = targetDirectory + "/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
		
		PathHelper.mkdir (targetDirectory);
		ProcessHelper.runCommand ("", "haxe", [ hxml ]);
		
		if (useNeko) {
			
			NekoHelper.createExecutable (project.templatePaths, "Mac" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries (project.templatePaths, "Mac" + (is64 ? "64" : ""), executableDirectory);
			
		} else {
			
			FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), executablePath);
			
		}
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			ProcessHelper.runCommand ("", "chmod", [ "755", executablePath ]);
			
		}
		
	}
	
	
	public function clean (project:OpenFLProject):Void {
		
		initialize (project);
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public function display (project:OpenFLProject):Void {
		
		initialize (project);
		
		var hxml = PathHelper.findTemplate (project.templatePaths, (useNeko ? "neko" : "cpp") + "/hxml/" + (project.debug ? "debug" : "release") + ".hxml");
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (generateContext (project)));
		
	}
	
	
	private function generateContext (project:OpenFLProject):Dynamic {
		
		var context = project.templateContext;
		context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
		context.CPP_DIR = targetDirectory + "/obj/";
		context.BUILD_DIR = project.app.path + "/mac" + (is64 ? "64" : "");
		
		return context;
		
	}
	
	
	private function initialize (project:OpenFLProject):Void {
		
		if (project.targetFlags.exists ("neko") || project.target != PlatformHelper.hostPlatform) {
			
			useNeko = true;
			
		}
		
		if (!useNeko) {
			
			for (architecture in project.architectures) {
				
				if (architecture == Architecture.X64) {
					
					is64 = true;
					
				}
				
			}
			
			targetDirectory = project.app.path + "/mac" + (is64 ? "64" : "") + "/cpp";
			
		} else {
			
			targetDirectory = project.app.path + "/mac" + (is64 ? "64" : "") + "/neko";
			
		}
		
		applicationDirectory = targetDirectory + "/bin/" + project.app.file + ".app";
		contentDirectory = applicationDirectory + "/Contents/Resources";
		executableDirectory = applicationDirectory + "/Contents/MacOS";
		executablePath = executableDirectory + "/" + project.app.file;
		
	}
	
	
	public function run (project:OpenFLProject, arguments:Array <String>):Void {
		
		if (project.target == PlatformHelper.hostPlatform) {
			
			initialize (project);
			ProcessHelper.runCommand (executableDirectory, "./" + Path.withoutDirectory (executablePath), arguments);
			
		}
		
	}
	
	
	public function update (project:OpenFLProject):Void {
		
		initialize (project);
		
		project = project.clone ();
		
		if (is64) {
			
			project.haxedefs.set ("HXCPP_M64", 1);
			
		}

		if (!useNeko) {

			project.haxedefs.set ("HXCPP_CLANG", "1");

		}

		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		var context = generateContext (project);
		
		PathHelper.mkdir (targetDirectory);
		PathHelper.mkdir (targetDirectory + "/obj");
		PathHelper.mkdir (targetDirectory + "/haxe");
		PathHelper.mkdir (applicationDirectory);
		PathHelper.mkdir (contentDirectory);
		
		//SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, (useNeko ? "neko" : "cpp") + "/hxml", targetDirectory + "/haxe", context);
		FileHelper.copyFileTemplate (project.templatePaths, "mac/Info.plist", targetDirectory + "/bin/" + project.app.file + ".app/Contents/Info.plist", context);
		
		for (ndll in project.ndlls) {
			
			FileHelper.copyLibrary (ndll, "Mac" + (is64 ? "64" : ""), "", (ndll.haxelib != null && ndll.haxelib.name == "hxcpp") ? ".dylib" : ".ndll", executableDirectory, project.debug);
			
		}
		
		context.HAS_ICON = IconHelper.createMacIcon (project.icons, PathHelper.combine (contentDirectory,"icon.icns"));
		
		for (asset in project.assets) {
			
			if (asset.type != AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (PathHelper.combine (contentDirectory, asset.targetPath)));
				FileHelper.copyAssetIfNewer (asset, PathHelper.combine (contentDirectory, asset.targetPath));
				
			} else {
				
				PathHelper.mkdir (Path.directory (PathHelper.combine (targetDirectory, asset.targetPath)));
				FileHelper.copyAsset (asset, PathHelper.combine (targetDirectory, asset.targetPath), context);
				
			}
			
			
		}
		
		AssetHelper.createManifest (project, PathHelper.combine (contentDirectory, "manifest"));
		
	}
	
	
	public function new () {}
	@ignore public function install (project:OpenFLProject):Void {}
	@ignore public function trace (project:OpenFLProject):Void {}
	@ignore public function uninstall (project:OpenFLProject):Void {}
	
	
}