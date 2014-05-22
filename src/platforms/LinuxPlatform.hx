package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.AssetHelper;
import helpers.CPPHelper;
import helpers.FileHelper;
import helpers.NekoHelper;
import helpers.PathHelper;
import helpers.PlatformHelper;
import helpers.ProcessHelper;
import project.AssetType;
import project.Architecture;
import project.HXProject;
import project.Platform;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


class LinuxPlatform implements IPlatformTool {
	
	
	private var applicationDirectory:String;
	private var executablePath:String;
	private var is64:Bool;
	private var isRaspberryPi:Bool;
	private var targetDirectory:String;
	private var useNeko:Bool;
	
	
	public function build (project:HXProject):Void {
		
		initialize (project);
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = targetDirectory + "/haxe/" + type + ".hxml";
		
		PathHelper.mkdir (targetDirectory);
		
		if (useNeko) {
			
			ProcessHelper.runCommand ("", "haxe", [ hxml ]);
			NekoHelper.createExecutable (project.templatePaths, "linux" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries (project.templatePaths, "linux" + (is64 ? "64" : ""), applicationDirectory);
			
		} else {
			
			var haxeArgs = [ hxml ];
			
			if (is64) {
				
				haxeArgs.push ("-D");
				haxeArgs.push ("HXCPP_M64");
				
			}
			
			ProcessHelper.runCommand ("", "haxe", haxeArgs);
			CPPHelper.compile (project, targetDirectory + "/obj", [ is64 ? "-DHXCPP_M64" : "" ]);
			FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), executablePath);
			
		}
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			ProcessHelper.runCommand ("", "chmod", [ "755", executablePath ]);
			
		}
		
	}
	
	
	public function clean (project:HXProject):Void {
		
		initialize (project);
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public function display (project:HXProject):Void {
		
		initialize (project);
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = PathHelper.findTemplate (project.templatePaths, (useNeko ? "neko" : "cpp") + "/hxml/" + type + ".hxml");
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (generateContext (project)));
		
	}
	
	
	private function generateContext (project:HXProject):Dynamic {
		
		var project = project.clone ();
		
		if (isRaspberryPi) {
			
			project.haxedefs.set ("rpi", 1);
			
		}
		
		var context = project.templateContext;
		
		context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
		context.CPP_DIR = targetDirectory + "/obj/";
		context.BUILD_DIR = project.app.path + "/linux" + (is64 ? "64" : "") + (isRaspberryPi ? "-rpi" : "");
		context.WIN_ALLOW_SHADERS = false;
		
		return context;
		
	}
	
	
	private function initialize (project:HXProject):Void {
		
		for (architecture in project.architectures) {
			
			if (architecture == Architecture.X64) {
				
				is64 = true;
				
			}
			
		}
		
		if (project.targetFlags.exists ("rpi")) {
			
			isRaspberryPi = true;
			is64 = true;
			
		} else if (PlatformHelper.hostPlatform == Platform.LINUX) {
			
			var process = new Process ("uname", [ "-a" ]);
			var output = process.stdout.readAll ().toString ();
			var error = process.stderr.readAll ().toString ();
			process.exitCode ();
			process.close ();
			
			if (output.toLowerCase ().indexOf ("raspberrypi") > -1) {
				
				isRaspberryPi = true;
				is64 = true;
				
			}
			
		}
		
		if (project.targetFlags.exists ("neko") || project.target != PlatformHelper.hostPlatform) {
			
			useNeko = true;
			
		}
		
		targetDirectory = project.app.path + "/linux" + (is64 ? "64" : "") + (isRaspberryPi ? "-rpi" : "") + "/" + (useNeko ? "neko" : "cpp");
		applicationDirectory = targetDirectory + "/bin/";
		executablePath = PathHelper.combine (applicationDirectory, project.app.file);
		
	}
	
	
	public function run (project:HXProject, arguments:Array <String>):Void {
		
		if (project.target == PlatformHelper.hostPlatform) {
			
			initialize (project);
			arguments = arguments.concat ([ "-livereload" ]);
			ProcessHelper.runCommand (applicationDirectory, "./" + Path.withoutDirectory (executablePath), arguments);
			
		}
		
	}
	
	
	public function update (project:HXProject):Void {
		
		project = project.clone ();
		initialize (project);
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		var context = generateContext (project);
		
		PathHelper.mkdir (targetDirectory);
		PathHelper.mkdir (targetDirectory + "/obj");
		PathHelper.mkdir (targetDirectory + "/haxe");
		PathHelper.mkdir (applicationDirectory);
		
		//SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, (useNeko ? "neko" : "cpp") + "/hxml", targetDirectory + "/haxe", context);
		
		for (ndll in project.ndlls) {
			
			if (isRaspberryPi) {
				
				FileHelper.copyLibrary (project, ndll, "RPi", "", (ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dso" : ".ndll", applicationDirectory, project.debug);
				
			} else {
				
				FileHelper.copyLibrary (project, ndll, "Linux" + (is64 ? "64" : ""), "", (ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dso" : ".ndll", applicationDirectory, project.debug);
				
			}
			
		}
		
		//context.HAS_ICON = IconHelper.createIcon (project.icons, 256, 256, PathHelper.combine (applicationDirectory, "icon.png"));
		for (asset in project.assets) {
			
			var path = PathHelper.combine (applicationDirectory, asset.targetPath);
			
			if (asset.embed != true) {
			
				if (asset.type != AssetType.TEMPLATE) {
				
					PathHelper.mkdir (Path.directory (path));
					FileHelper.copyAssetIfNewer (asset, path);
				
				} else {
				
					PathHelper.mkdir (Path.directory (path));
					FileHelper.copyAsset (asset, path, context);
				
				}
				
			}
			
		}
		
		AssetHelper.createManifest (project, PathHelper.combine (applicationDirectory, "manifest"));
	}
	
	
	public function new () {}
	@ignore public function install (project:HXProject):Void {}
	@ignore public function trace (project:HXProject):Void {}
	@ignore public function uninstall (project:HXProject):Void {}
	
	
}
