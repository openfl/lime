package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.AssetHelper;
import helpers.CPPHelper;
import helpers.FileHelper;
import helpers.IconHelper;
import helpers.NekoHelper;
import helpers.PathHelper;
import helpers.PlatformHelper;
import helpers.ProcessHelper;
import project.AssetType;
import project.Haxelib;
import project.HXProject;
import sys.io.File;
import sys.FileSystem;


class WindowsPlatform implements IPlatformTool {
	
	
	private var applicationDirectory:String;
	private var executablePath:String;
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
			NekoHelper.createExecutable (project.templatePaths, "windows", targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries (project.templatePaths, "windows", applicationDirectory);
			
		} else {
			
			var haxeArgs = [ hxml ];
			var flags = [];
			
			if (!project.environment.exists ("SHOW_CONSOLE")) {
				
				haxeArgs.push ("-D");
				haxeArgs.push ("no_console");
				flags.push ("-Dno_console");
				
			}
			
			ProcessHelper.runCommand ("", "haxe", haxeArgs);
			CPPHelper.compile (project, targetDirectory + "/obj", flags);
			
			FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath);
			
			var iconPath = PathHelper.combine (applicationDirectory, "icon.ico");
			
			if (IconHelper.createWindowsIcon (project.icons, iconPath)) {
				
				var templates = [ PathHelper.getHaxelib (new Haxelib ("lime-tools")) + "/templates" ].concat (project.templatePaths);
				ProcessHelper.runCommand ("", PathHelper.findTemplate (templates, "bin/ReplaceVistaIcon.exe"), [ executablePath, iconPath ], true, true);
				
			}
			
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
		
		var context = project.templateContext;
		
		context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
		context.CPP_DIR = targetDirectory + "/obj";
		context.BUILD_DIR = project.app.path + "/windows";
		
		return context;
		
	}
	
	
	private function initialize (project:HXProject):Void {
		
		targetDirectory = project.app.path + "/windows/cpp";
		
		if (project.targetFlags.exists ("neko") || project.target != PlatformHelper.hostPlatform) {
			
			targetDirectory = project.app.path + "/windows/neko";
			useNeko = true;
			
		}
		
		applicationDirectory = targetDirectory + "/bin/";
		executablePath = applicationDirectory + "/" + project.app.file + ".exe";
		
	}
	
	
	public function run (project:HXProject, arguments:Array <String>):Void {
		
		if (project.target == PlatformHelper.hostPlatform) {
			
			initialize (project);
			arguments = arguments.concat ([ "-livereload" ]);
			ProcessHelper.runCommand (applicationDirectory, Path.withoutDirectory (executablePath), arguments);
			
		}
		
	}
	
	
	public function update (project:HXProject):Void {
		
		project = project.clone ();
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		initialize (project);
		
		var context = generateContext (project);
		
		PathHelper.mkdir (targetDirectory);
		PathHelper.mkdir (targetDirectory + "/obj");
		PathHelper.mkdir (targetDirectory + "/haxe");
		PathHelper.mkdir (applicationDirectory);
		
		//SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, (useNeko ? "neko" : "cpp") + "/hxml", targetDirectory + "/haxe", context);
		
		for (dependency in project.dependencies) {
			
			if (StringTools.endsWith (dependency.path, ".dll")) {
				
				var fileName = Path.withoutDirectory (dependency.path);
				FileHelper.copyIfNewer (dependency.path, applicationDirectory + "/" + fileName);
				
			}
			
		}
		
		for (ndll in project.ndlls) {
			
			FileHelper.copyLibrary (project, ndll, "Windows", "", (ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dll" : ".ndll", applicationDirectory, project.debug);
			
		}
		
		/*if (IconHelper.createIcon (project.icons, 32, 32, PathHelper.combine (applicationDirectory, "icon.png"))) {
			
			context.HAS_ICON = true;
			context.WIN_ICON = "icon.png";
			
		}*/
		
		for (asset in project.assets) {
			
			if (asset.embed != true) {
			
				var path = PathHelper.combine (applicationDirectory, asset.targetPath);
			
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
