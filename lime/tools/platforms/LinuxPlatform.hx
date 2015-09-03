package lime.tools.platforms;


import haxe.io.Path;
import haxe.Template;
import lime.tools.helpers.AssetHelper;
import lime.tools.helpers.CPPHelper;
import lime.tools.helpers.DeploymentHelper;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.NekoHelper;
import lime.tools.helpers.NodeJSHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.ProcessHelper;
import lime.project.AssetType;
import lime.project.Architecture;
import lime.project.HXProject;
import lime.project.Platform;
import lime.project.PlatformTarget;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


class LinuxPlatform extends PlatformTarget {
	
	
	private var applicationDirectory:String;
	private var executablePath:String;
	private var is64:Bool;
	private var isRaspberryPi:Bool;
	private var targetType:String;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String> ) {
		
		super (command, _project, targetFlags);
		
		for (architecture in project.architectures) {
			
			if (architecture == Architecture.X64) {
				
				is64 = true;
				
			} else if (architecture == Architecture.ARMV7) {
				
				isRaspberryPi = true;
				
			}
			
		}
		
		if (project.targetFlags.exists ("rpi")) {
			
			isRaspberryPi = true;
			is64 = false;
			
		}
		
		if (project.targetFlags.exists ("neko") || project.target != PlatformHelper.hostPlatform) {
			
			targetType = "neko";
			
		} else if (project.targetFlags.exists ("nodejs")) {
			
			targetType = "nodejs";
			
		} else {
			
			targetType = "cpp";
			
		}
		
		targetDirectory = project.app.path + "/linux" + (is64 ? "64" : "") + (isRaspberryPi ? "-rpi" : "") + "/" + targetType;
		applicationDirectory = targetDirectory + "/bin/";
		executablePath = PathHelper.combine (applicationDirectory, project.app.file);
		
	}
	
	
	public override function build ():Void {
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = targetDirectory + "/haxe/" + type + ".hxml";
		
		PathHelper.mkdir (targetDirectory);
		
		if (!project.targetFlags.exists ("static") || targetType != "cpp") {
			
			for (ndll in project.ndlls) {
				
				if (isRaspberryPi) {
					
					FileHelper.copyLibrary (project, ndll, "RPi", "", (ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dso" : ".ndll", applicationDirectory, project.debug);
					
				} else {
					
					FileHelper.copyLibrary (project, ndll, "Linux" + (is64 ? "64" : ""), "", (ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dso" : ".ndll", applicationDirectory, project.debug);
					
				}
				
			}
			
		}
		
		if (targetType == "neko") {
			
			ProcessHelper.runCommand ("", "haxe", [ hxml ]);
			
			if (isRaspberryPi) {
				
				NekoHelper.createExecutable (project.templatePaths, "rpi", targetDirectory + "/obj/ApplicationMain.n", executablePath);
				NekoHelper.copyLibraries (project.templatePaths, "rpi", applicationDirectory);
				
			} else {
				
				NekoHelper.createExecutable (project.templatePaths, "linux" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
				NekoHelper.copyLibraries (project.templatePaths, "linux" + (is64 ? "64" : ""), applicationDirectory);
				
			}
			
		} else if (targetType == "nodejs") {
			
			ProcessHelper.runCommand ("", "haxe", [ hxml ]);
			//NekoHelper.createExecutable (project.templatePaths, "linux" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries (project.templatePaths, "linux" + (is64 ? "64" : ""), applicationDirectory);
			
		} else {
			
			var haxeArgs = [ hxml ];
			
			if (is64) {
				
				haxeArgs.push ("-D");
				haxeArgs.push ("HXCPP_M64");
				
			}
			
			var flags = [ is64 ? "-DHXCPP_M64" : "" ];
			
			if (!project.targetFlags.exists ("static")) {
				
				ProcessHelper.runCommand ("", "haxe", haxeArgs);
				CPPHelper.compile (project, targetDirectory + "/obj", flags);
				
				FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), executablePath);
				
			} else {
				
				ProcessHelper.runCommand ("", "haxe", haxeArgs.concat ([ "-D", "static_link" ]));
				CPPHelper.compile (project, targetDirectory + "/obj", flags.concat ([ "-Dstatic_link" ]));
				CPPHelper.compile (project, targetDirectory + "/obj", flags, "BuildMain.xml");
				
				FileHelper.copyFile (targetDirectory + "/obj/Main" + (project.debug ? "-debug" : ""), executablePath);
				
			}
			
		}
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS && targetType != "nodejs") {
			
			ProcessHelper.runCommand ("", "chmod", [ "755", executablePath ]);
			
		}
		
	}
	
	
	public override function clean ():Void {
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function deploy ():Void {
		
		DeploymentHelper.deploy (project, targetFlags, targetDirectory, "Linux " + (is64 ? "64" : "32") + "-bit");
		
	}
	
	
	public override function display ():Void {
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = PathHelper.findTemplate (project.templatePaths, targetType + "/hxml/" + type + ".hxml");
		var template = new Template (File.getContent (hxml));
		
		Sys.println (template.execute (generateContext ()));
		Sys.println ("-D display");
		
	}
	
	
	private function generateContext ():Dynamic {
		
		var project = project.clone ();
		
		if (isRaspberryPi) {
			
			project.haxedefs.set ("rpi", 1);
			
		}
		
		var context = project.templateContext;
		
		context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
		context.NODE_FILE = targetDirectory + "/bin/ApplicationMain.js";
		context.CPP_DIR = targetDirectory + "/obj/";
		context.BUILD_DIR = project.app.path + "/linux" + (is64 ? "64" : "") + (isRaspberryPi ? "-rpi" : "");
		context.WIN_ALLOW_SHADERS = false;
		
		return context;
		
	}
	
	
	public override function rebuild ():Void {
		
		var commands = [];
		
		if (targetFlags.exists ("rpi")) {
			
			commands.push ([ "-Dlinux", "-Drpi", "-Dtoolchain=linux", "-DBINDIR=RPi", "-DCXX=arm-linux-gnueabihf-g++", "-DHXCPP_M32", "-DHXCPP_STRIP=arm-linux-gnueabihf-strip", "-DHXCPP_AR=arm-linux-gnueabihf-ar", "-DHXCPP_RANLIB=arm-linux-gnueabihf-ranlib" ]);
			
		} else {
			
			if (!targetFlags.exists ("32") && PlatformHelper.hostArchitecture == X64) {
				
				commands.push ([ "-Dlinux", "-DHXCPP_M64" ]);
				
			}
			
			if (!targetFlags.exists ("64") && (command == "rebuild" || PlatformHelper.hostArchitecture == Architecture.X86)) {
				
				commands.push ([ "-Dlinux", "-DHXCPP_M32" ]);
				
			}
			
		}
		
		CPPHelper.rebuild (project, commands);
		
	}
	
	
	public override function run ():Void {
		
		var arguments = additionalArguments.copy ();
		
		if (LogHelper.verbose) {
			
			arguments.push ("-verbose");
			
		}
		
		if (targetType == "nodejs") {
			
			NodeJSHelper.run (project, targetDirectory + "/bin/ApplicationMain.js", arguments);
			
		} else if (project.target == PlatformHelper.hostPlatform) {
			
			arguments = arguments.concat ([ "-livereload" ]);
			ProcessHelper.runCommand (applicationDirectory, "./" + Path.withoutDirectory (executablePath), arguments);
			
		}
		
	}
	
	
	public override function update ():Void {
		
		project = project.clone ();
		//initialize (project);
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		var context = generateContext ();
		
		if (targetType == "cpp" && project.targetFlags.exists ("static")) {
			
			for (i in 0...project.ndlls.length) {
				
				var ndll = project.ndlls[i];
				
				if (ndll.path == null || ndll.path == "") {
					
					if (isRaspberryPi) {
						
						context.ndlls[i].path = PathHelper.getLibraryPath (ndll, "RPi", "lib", ".a", project.debug);
						
					} else {
						
						context.ndlls[i].path = PathHelper.getLibraryPath (ndll, "Linux" + (is64 ? "64" : ""), "lib", ".a", project.debug);
						
					}
					
				}
				
			}
			
		}
		
		PathHelper.mkdir (targetDirectory);
		PathHelper.mkdir (targetDirectory + "/obj");
		PathHelper.mkdir (targetDirectory + "/haxe");
		PathHelper.mkdir (applicationDirectory);
		
		//SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, targetType + "/hxml", targetDirectory + "/haxe", context);
		
		if (targetType == "cpp" && project.targetFlags.exists ("static")) {
			
			FileHelper.recursiveCopyTemplate (project.templatePaths, "cpp/static", targetDirectory + "/obj", context);
			
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
	
	
	@ignore public override function install ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}
