package lime.tools.platforms;


import haxe.io.Path;
import haxe.Template;
import lime.project.Icon;
import lime.tools.helpers.CPPHelper;
import lime.tools.helpers.DeploymentHelper;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.HTML5Helper;
import lime.tools.helpers.IconHelper;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.ModuleHelper;
import lime.tools.helpers.CSHelper;
import lime.tools.helpers.GUID;
import lime.tools.helpers.NekoHelper;
import lime.tools.helpers.NodeJSHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.ProcessHelper;
import lime.project.Architecture;
import lime.project.Asset;
import lime.project.AssetType;
import lime.project.Haxelib;
import lime.project.HXProject;
import lime.project.Platform;
import lime.project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;





class WindowsPlatform extends PlatformTarget {
	
	
	private var applicationDirectory:String;
	private var executablePath:String;
	private var is64:Bool;
	private var targetType:String;
	private var outputFile:String;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map<String, String> ) {
		
		super (command, _project, targetFlags);
		
		for (architecture in project.architectures) {
			
			if (architecture == Architecture.X64) {
				
				is64 = true;
				
			}
			
		}

		if (project.targetFlags.exists ("uwp")) {

			targetType = "html5";

		} else if (project.targetFlags.exists ("neko") || project.target != PlatformHelper.hostPlatform) {
			
			targetType = "neko";

		} else if (project.targetFlags.exists ("nodejs")) {
			
			targetType = "nodejs";

		} else if (project.targetFlags.exists ("cs")) {
			
			targetType = "cs";
		} else {
			
			targetType = "cpp";
			
		}

		targetDirectory = PathHelper.combine (project.app.path, project.config.getString ("windows.output-directory", "windows" + (is64 ? "64" : "") + "/" + targetType + "/" + buildType));


		if (project.targetFlags.exists ("uwp")) {
			targetDirectory = PathHelper.combine (project.app.path, "windows" + (is64 ? "64" : "") + "/" + targetType + "/" + buildType);
			outputFile = targetDirectory + "/bin/source/js/" + project.app.file + ".js";

		}

		targetDirectory = StringTools.replace (targetDirectory, "arch64", is64 ? "64" : "");

		applicationDirectory = targetDirectory + "/bin/";
		executablePath = applicationDirectory + project.app.file + ".exe";
		
	}	
	
	public override function build ():Void {

		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";
		
		PathHelper.mkdir (targetDirectory);
		
		

		// universal windows platform
		// for now build html5 	
		if (project.targetFlags.exists ("uwp")) {
			Sys.println ("Start UWP Build");
			ModuleHelper.buildModules (project, targetDirectory + "/obj", targetDirectory + "/bin");
		
			if (project.app.main != null) {

				ProcessHelper.runCommand ("", "haxe", [ hxml ] );
				ProcessHelper.runCommand("","MSBuild",[ targetDirectory + "/bin/source/uwp-project.jsproj",
					"/p:Configuration=Release", "/t:HelloWorld"]);
				//MSBuild temp/uwa/vws/vws.jsproj /p:Configuration=Release"
				
				if (noOutput) return;
				
				if (project.targetFlags.exists ("webgl")) {
					
					FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain.js", outputFile);
					
				}
				
				if (project.modules.iterator ().hasNext ()) {
					ModuleHelper.patchFile (outputFile);
					
				}
				
				if (project.targetFlags.exists ("minify") || buildType == "final") {
					
					HTML5Helper.minify (project, targetDirectory + "/bin/" + project.app.file + ".js");
					
				}
				
			}
			//return;
		}

		for (dependency in project.dependencies) {
			
			if (StringTools.endsWith (dependency.path, ".dll")) {
				
				var fileName = Path.withoutDirectory (dependency.path);
				FileHelper.copyIfNewer (dependency.path, applicationDirectory + "/" + fileName);
				
			}
			
		}

		
		if (!project.targetFlags.exists ("static") || targetType != "cpp") {
			
			for (ndll in project.ndlls) {
				
				FileHelper.copyLibrary (project, ndll, "Windows" + (is64 ? "64" : ""), "", (ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dll" : ".ndll", applicationDirectory, project.debug);
				
			}
			
		}
		
		var icons = project.icons;
		
		if (icons.length == 0) {
			
			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];
			
		}
		
//		//IconHelper.createIcon (project.icons, 32, 32, PathHelper.combine (applicationDirectory, "icon.png"));
//
//		if (targetType == "neko") {
//
//			ProcessHelper.runCommand ("", "haxe", [ hxml ]);
//
//			if (noOutput) return;
//
//			var iconPath = PathHelper.combine (applicationDirectory, "icon.ico");
//
//			if (!IconHelper.createWindowsIcon (icons, iconPath)) {
//
//				iconPath = null;
//
//			}
//
//			NekoHelper.createWindowsExecutable (project.templatePaths, targetDirectory + "/obj/ApplicationMain.n", executablePath, iconPath);
//			NekoHelper.copyLibraries (project.templatePaths, "windows" + (is64 ? "64" : ""), applicationDirectory);
//
//		} else if (targetType == "nodejs") {
//
//			ProcessHelper.runCommand ("", "haxe", [ hxml ]);
//
//			if (noOutput) return;
//
//			//NekoHelper.createExecutable (project.templatePaths, "windows" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
//			NekoHelper.copyLibraries (project.templatePaths, "windows" + (is64 ? "64" : ""), applicationDirectory);
//
//		} else if (targetType == "cs") {
//
//			ProcessHelper.runCommand ("", "haxe", [ hxml ]);
//
//			if (noOutput) return;
//
//			CSHelper.copySourceFiles (project.templatePaths, targetDirectory + "/obj/src");
//			var txtPath = targetDirectory + "/obj/hxcs_build.txt";
//			CSHelper.addSourceFiles (txtPath, CSHelper.ndllSourceFiles);
//			CSHelper.addGUID (txtPath, GUID.uuid ());
//			CSHelper.compile (project, targetDirectory + "/obj", applicationDirectory + project.app.file, "x86", "desktop");
//		} else {
//
//			var haxeArgs = [ hxml ];
//			var flags = [];
//
//			if (is64) {
//
//				haxeArgs.push ("-D");
//				haxeArgs.push ("HXCPP_M64");
//				flags.push ("-DHXCPP_M64");
//
//			} else {
//
//				flags.push ("-DHXCPP_M32");
//
//			}
//
//			if (!project.environment.exists ("SHOW_CONSOLE")) {
//
//				haxeArgs.push ("-D");
//				haxeArgs.push ("no_console");
//				flags.push ("-Dno_console");
//
//			}
//
//			if (!project.targetFlags.exists ("static")) {
//
//				ProcessHelper.runCommand ("", "haxe", haxeArgs);
//
//				if (noOutput) return;
//
//				CPPHelper.compile (project, targetDirectory + "/obj", flags);
//
//				FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath);
//
//			} else {
//
//				ProcessHelper.runCommand ("", "haxe", haxeArgs.concat ([ "-D", "static_link" ]));
//
//				if (noOutput) return;
//
//				CPPHelper.compile (project, targetDirectory + "/obj", flags.concat ([ "-Dstatic_link" ]));
//				CPPHelper.compile (project, targetDirectory + "/obj", flags, "BuildMain.xml");
//
//				FileHelper.copyFile (targetDirectory + "/obj/Main" + (project.debug ? "-debug" : "") + ".exe", executablePath);
//
//			}
//
//			var iconPath = PathHelper.combine (applicationDirectory, "icon.ico");
//
//			if (IconHelper.createWindowsIcon (icons, iconPath) && PlatformHelper.hostPlatform == Platform.WINDOWS) {
//
//				var templates = [ PathHelper.getHaxelib (new Haxelib ("lime")) + "/templates" ].concat (project.templatePaths);
//				ProcessHelper.runCommand ("", PathHelper.findTemplate (templates, "bin/ReplaceVistaIcon.exe"), [ executablePath, iconPath, "1" ], true, true);
//
//			}
//
//		}
		
	}

	public override function clean ():Void {
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function deploy ():Void {
		DeploymentHelper.deploy (project, targetFlags, targetDirectory, "Windows" + (is64 ? "64" : ""));
		
	}
	
	
	public override function display ():Void {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, targetType + "/hxml/" + buildType + ".hxml");
		var template = new Template (File.getContent (hxml));
		
		var context = generateContext ();
		context.OUTPUT_DIR = targetDirectory;
		
		Sys.println (template.execute (context));
		Sys.println ("-D display");
		
	}
	
	
	private function generateContext ():Dynamic {
		
		var context = project.templateContext;
		
		context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
		context.NODE_FILE = targetDirectory + "/bin/ApplicationMain.js";
		context.CPP_DIR = targetDirectory + "/obj";
		context.BUILD_DIR = project.app.path + "/windows" + (is64 ? "64" : "");
		
		return context;
		
	}
	
	
	public override function rebuild ():Void {
		
		if (project.environment.exists ("VS110COMNTOOLS") && project.environment.exists ("VS100COMNTOOLS")) {
			
			project.environment.set ("HXCPP_MSVC", project.environment.get ("VS100COMNTOOLS"));
			Sys.putEnv ("HXCPP_MSVC", project.environment.get ("VS100COMNTOOLS"));
			
		}
		
		var commands = [];
		
		if (targetFlags.exists ("64")) {
			
			commands.push ([ "-Dwindow", "-DHXCPP_M64" ]);
			
		} else {
			
			commands.push ([ "-Dwindow", "-DHXCPP_M32" ]);
			
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
		} else if (project.targetFlags.exists ("uwp")) {
			HTML5Helper.launch (project, targetDirectory + "/bin");
		} else if (project.target == PlatformHelper.hostPlatform) {
			arguments = arguments.concat ([ "-livereload" ]);
			ProcessHelper.runCommand (applicationDirectory, Path.withoutDirectory (executablePath), arguments);
			
		}
		
	}

	public function updateUwp ():Void {
		
		project = project.clone ();
		
		var destination = targetDirectory + "/bin/source/";
		PathHelper.mkdir (destination);
		
		var webfontDirectory = targetDirectory + "/obj/webfont";
		var useWebfonts = true;
		
		for (haxelib in project.haxelibs) {
			
			if (haxelib.name == "openfl-html5-dom" || haxelib.name == "openfl-bitfive") {
				
				useWebfonts = false;
				
			}
			
		}
		
		var fontPath;
		
		for (asset in project.assets) {
			
			if (asset.type == AssetType.FONT) {
				
				if (useWebfonts) {
					
					fontPath = PathHelper.combine (webfontDirectory, Path.withoutDirectory (asset.targetPath));
					
					if (!FileSystem.exists (fontPath)) {
						
						PathHelper.mkdir (webfontDirectory);
						FileHelper.copyFile (asset.sourcePath, fontPath);
						
						asset.sourcePath = fontPath;
						
						HTML5Helper.generateWebfonts (project, asset);
						
					}
					
					asset.sourcePath = fontPath;
					asset.targetPath = Path.withoutExtension (asset.targetPath);
					
				} else {
					
					project.haxeflags.push (HTML5Helper.generateFontData (project, asset));
					
				}
				
			}
			
		}
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		if (LogHelper.verbose) {
			
			project.haxedefs.set ("verbose", 1);
			
		}
		
		ModuleHelper.updateProject (project);
		
		var libraryNames = new Map<String, Bool> ();
		
		for (asset in project.assets) {
			
			if (asset.library != null && !libraryNames.exists (asset.library)) {
				
				libraryNames[asset.library] = true;
				
			}
			
		}
		
		//for (library in libraryNames.keys ()) {
			//
			//project.haxeflags.push ("-resource " + targetDirectory + "/obj/manifest/" + library + ".json@__ASSET_MANIFEST__" + library);
			//
		//}
		
		//project.haxeflags.push ("-resource " + targetDirectory + "/obj/manifest/default.json@__ASSET_MANIFEST__default");
		
		var context = project.templateContext;
		
		context.WIN_FLASHBACKGROUND = project.window.background != null ? StringTools.hex (project.window.background, 6) : "";
		context.OUTPUT_DIR = targetDirectory;
		context.OUTPUT_FILE = outputFile;
		
		if (project.targetFlags.exists ("webgl")) {
			
			context.CPP_DIR = targetDirectory + "/obj";
			
		}
		
		context.favicons = [];
		
		var icons = project.icons;
		
		if (icons.length == 0) {
			
			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];
			
		}
		
		//if (IconHelper.createWindowsIcon (icons, PathHelper.combine (destination, "favicon.ico"))) {
			//
			//context.favicons.push ({ rel: "icon", type: "image/x-icon", href: "./favicon.ico" });
			//
		//}
		
		if (IconHelper.createIcon (icons, 192, 192, PathHelper.combine (destination, "favicon.png"))) {
			
			context.favicons.push ({ rel: "shortcut icon", type: "image/png", href: "./favicon.png" });
			
		}
		
		context.linkedLibraries = [];
		
		for (dependency in project.dependencies) {

			Sys.println("found dependency: " + dependency.name + " path: " + dependency.path);

			
			if (StringTools.endsWith (dependency.name, ".js")) {
				
				context.linkedLibraries.push (dependency.name);
				
			} else if (StringTools.endsWith (dependency.path, ".js") && FileSystem.exists (dependency.path)) {
				
				var name = Path.withoutDirectory (dependency.path);
				
				context.linkedLibraries.push ("./js/lib/" + name);
				FileHelper.copyIfNewer (dependency.path, PathHelper.combine (destination, PathHelper.combine ("js/lib", name)));

			}
			
		}

		var seed = "unknown";
		if(project.defines.exists("APP_PACKAGE")) {
			seed = project.defines.get("APP_PACKAGE");
		} else if(project.defines.exists("APP_TITLE")) {
			seed = project.defines.get("APP_TITLE");
		}
		var guid = GUID.seededUuid(seed);
		context.APP_GUID = guid;
		var guidNoBrackets = guid.split("{").join("").split("}").join("");
		Sys.println("guid: " + guid);
		Sys.println("guidNoBrackets: " + guidNoBrackets);
		context.APP_GUID_NOBRACKETS = guidNoBrackets;


		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			if (asset.type != AssetType.TEMPLATE) {
				
				if (asset.type != AssetType.FONT) {
					
					PathHelper.mkdir (Path.directory (path));
					FileHelper.copyAssetIfNewer (asset, path);
					
				} else if (useWebfonts) {
					
					PathHelper.mkdir (Path.directory (path));
					var ext = "." + Path.extension (asset.sourcePath);
					var source = Path.withoutExtension (asset.sourcePath);
					
					for (extension in [ ext, ".eot", ".woff", ".svg" ]) {
						
						if (FileSystem.exists (source + extension)) {
							
							FileHelper.copyIfNewer (source + extension, path + extension);
							
						} else {
							
							LogHelper.warn ("Could not find generated font file \"" + source + extension + "\"");
							
						}
						
					}
					
				}
				
			}
			
		}
		
		//FileHelper.recursiveCopyTemplate (project.templatePaths, "windows/template", destination, context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "windows/template", targetDirectory + "/bin/", context);

		
		if (project.app.main != null) {
			
			FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "windows/haxe", targetDirectory + "/haxe", context, true, false);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "windows/hxml", targetDirectory + "/haxe", context);
			
			if (project.targetFlags.exists ("webgl")) {
				
				FileHelper.recursiveCopyTemplate (project.templatePaths, "webgl/hxml", targetDirectory + "/haxe", context, true, false);
				
			}
			
		}
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			if (asset.type == AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path, context);
				
			}
			
		}
		
	}

	public override function update ():Void {

		if(project.targetFlags.exists("uwp")) {
			updateUwp();
			return;
		}
		
		project = project.clone ();
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		for (asset in project.assets) {
			
			if (asset.embed && asset.sourcePath == "") {
				
				var path = PathHelper.combine (targetDirectory + "/obj/tmp", asset.targetPath);
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path);
				asset.sourcePath = path;
				
			}
			
		}
		
		var context = generateContext ();
		context.OUTPUT_DIR = targetDirectory;
		
		if (targetType == "cpp" && project.targetFlags.exists ("static")) {
			
			var suffix = ".lib";
			
			if (Sys.getEnv ("VS140COMNTOOLS") != null) {
				
				suffix = "-19.lib";
				
			}
			
			for (i in 0...project.ndlls.length) {
				
				var ndll = project.ndlls[i];
				
				if (ndll.path == null || ndll.path == "") {
					
					context.ndlls[i].path = PathHelper.getLibraryPath (ndll, "Windows" + (is64 ? "64" : ""), "lib", suffix, project.debug);
					
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
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}