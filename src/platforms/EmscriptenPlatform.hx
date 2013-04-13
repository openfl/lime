package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.FileHelper;
import helpers.HTML5Helper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import project.AssetType;
import project.NMEProject;
import sys.io.File;
import sys.FileSystem;


class EmscriptenPlatform implements IPlatformTool {
	
	
	private var outputDirectory:String;
	private var outputFile:String;
	
	
	public function build (project:NMEProject):Void {
		
		initialize (project);
		
		if (project.app.main != null) {
			
			var hxml = outputDirectory + "/haxe/" + (project.debug ? "debug" : "release") + ".hxml";
			ProcessHelper.runCommand ("", "haxe", [ hxml ] );
			
		}
		
		ProcessHelper.runCommand ("", "emcc", [ outputDirectory + "/obj/Main.cpp", "-o", outputDirectory + "/obj/Main.o" ]);
		
		var paths = [ outputDirectory + "/obj/Main.o" ];
		ProcessHelper.runCommand ("", "emar", [ "r", outputDirectory + "/obj/ApplicationMain.a" ].concat (paths));
		var paths = [ outputDirectory + "/obj/Main.o" ];
		
		for (ndll in project.ndlls) {
			
			var path = PathHelper.getLibraryPath (ndll, "Emscripten", "", ".a", project.debug);
			paths.push (path);
			
		}
		
		//var args = [ "r", outputDirectory + "/obj/ApplicationMain.a" ].concat (paths);
		//Sys.println ("emar " + args.join (" "));
		//ProcessHelper.runCommand ("", "emar", args);
		
		
		
		
		var args = [ outputDirectory + "/obj/ApplicationMain.a" ].concat (paths);
		args.push ("-o");
		args.push (outputDirectory + "/obj/ApplicationMain.js");
		
		Sys.println ("emcc " + args.join (" "));
		ProcessHelper.runCommand ("", "emcc", args);
		
		
		//if (project.targetFlags.exists ("webgl")) {
			
			FileHelper.copyFile (outputDirectory + "/obj/ApplicationMain.js", outputFile);
			
		//}
		
		if (project.targetFlags.exists ("minify")) {
			
			HTML5Helper.minify (project, outputDirectory + "/bin/" + project.app.file + ".js");
			
		}
		
	}
	
	
	public function clean (project:NMEProject):Void {
		
		var targetPath = project.app.path + "/emscripten";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public function display (project:NMEProject):Void {
		
		initialize (project);
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "emscripten/hxml/" + (project.debug ? "debug" : "release") + ".hxml");
		
		var context = project.templateContext;
		context.OUTPUT_DIR = outputDirectory;
		context.OUTPUT_FILE = outputFile;
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	private function initialize (project:NMEProject):Void {
		
		outputDirectory = project.app.path + "/emscripten";
		outputFile = outputDirectory + "/bin/" + project.app.file + ".js";
		
	}
	
	
	public function run (project:NMEProject, arguments:Array < String > ):Void {
		
		initialize (project);
		
		if (project.app.url != "") {
			
			ProcessHelper.openURL (project.app.url);
			
		} else {
			
			ProcessHelper.openFile (project.app.path + "/emscripten/bin", "index.html");
			
		}
		
	}
	
	
	public function update (project:NMEProject):Void {
		
		initialize (project);
		
		project = project.clone ();
		
		var destination = outputDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		for (asset in project.assets) {
			
			if (asset.type == AssetType.FONT) {
				
				project.haxeflags.push (HTML5Helper.generateFontData (project, asset));
				
			}
			
		}
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + project.app.path + "/emscripten/types.xml");
			
		}
		
		var context = project.templateContext;
		
		context.WIN_FLASHBACKGROUND = StringTools.hex (project.window.background, 6);
		context.OUTPUT_DIR = outputDirectory;
		context.OUTPUT_FILE = outputFile;
		
		//if (project.targetFlags.exists ("webgl")) {
			
			context.CPP_DIR = project.app.path + "/emscripten/obj";
			
		//}
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			if (asset.type != AssetType.TEMPLATE) {
				
				if (asset.type != AssetType.FONT) {
					
					PathHelper.mkdir (Path.directory (path));
					FileHelper.copyAssetIfNewer (asset, path);
					
				}
				
			}
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "emscripten/template", destination, context);
		
		if (project.app.main != null) {
			
			FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", outputDirectory + "/haxe", context);
			
			//if (!project.targetFlags.exists ("webgl")) {
				//
				//FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/haxe", outputDirectory + "/haxe", context);
				//FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/hxml", outputDirectory + "/haxe", context);
				//
			//} else {
				
				FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", outputDirectory + "/haxe", context);
				FileHelper.recursiveCopyTemplate (project.templatePaths, "emscripten/hxml", outputDirectory + "/haxe", context);
				FileHelper.recursiveCopyTemplate (project.templatePaths, "emscripten/cpp", outputDirectory + "/obj", context);
				//FileHelper.recursiveCopyTemplate (project.templatePaths, "webgl/hxml", outputDirectory + "/haxe", context);
				
			//}
			
		}
		
		//for (ndll in project.ndlls) {
			//
			//FileHelper.copyLibrary (ndll, "Emscripten", "", ".js", destination, project.debug);
			//
		//}
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			if (asset.type == AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path, context);
				
			}
			
		}
		
	}
	
	
	public function new () {}
	@ignore public function install (project:NMEProject):Void {}
	@ignore public function trace (project:NMEProject):Void {}
	@ignore public function uninstall (project:NMEProject):Void {}
	
	
}