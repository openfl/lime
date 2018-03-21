package lime.tools.platforms;


import haxe.io.Path;
import haxe.Template;
import lime.tools.helpers.CPPHelper;
import lime.tools.helpers.CSHelper;
import lime.tools.helpers.DeploymentHelper;
import lime.tools.helpers.GUID;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.HaxelibHelper;
import lime.tools.helpers.IconHelper;
import lime.tools.helpers.JavaHelper;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.NekoHelper;
import lime.tools.helpers.NodeJSHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.ProcessHelper;
import lime.tools.helpers.WatchHelper;
import lime.project.AssetType;
import lime.project.Architecture;
import lime.project.Haxelib;
import lime.project.HXProject;
import lime.project.Icon;
import lime.project.Platform;
import lime.project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class MacPlatform extends PlatformTarget {
	
	
	private var applicationDirectory:String;
	private var contentDirectory:String;
	private var executableDirectory:String;
	private var executablePath:String;
	private var is64:Bool;
	private var targetType:String;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map<String, String> ) {
		
		super (command, _project, targetFlags);
		
		for (architecture in project.architectures) {
			
			if (architecture == Architecture.X64) {
				
				is64 = true;
				
			}
			
		}
		
		if (project.targetFlags.exists ("neko") || project.target != PlatformHelper.hostPlatform) {
			
			targetType = "neko";
			
		} else if (project.targetFlags.exists ("java")) {
			
			targetType = "java";
			
		} else if (project.targetFlags.exists ("nodejs")) {
			
			targetType = "nodejs";
			
		} else if (project.targetFlags.exists ("cs")) {
			
			targetType = "cs";
			
		} else {
			
			targetType = "cpp";
			
		}
		
		targetDirectory = PathHelper.combine (project.app.path, project.config.getString ("mac.output-directory", targetType == "cpp" ? "macos" : targetType));
		targetDirectory = StringTools.replace (targetDirectory, "arch64", is64 ? "64" : "");
		applicationDirectory = targetDirectory + "/bin/" + project.app.file + ".app";
		contentDirectory = applicationDirectory + "/Contents/Resources";
		executableDirectory = applicationDirectory + "/Contents/MacOS";
		executablePath = executableDirectory + "/" + project.app.file;
		
	}
	
	
	public override function build ():Void {
		
		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";
		
		PathHelper.mkdir (targetDirectory);
		
		if (!project.targetFlags.exists ("static") || targetType != "cpp") {
			
			for (ndll in project.ndlls) {
				
				FileHelper.copyLibrary (project, ndll, "Mac" + (is64 ? "64" : ""), "", (ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dylib" : ".ndll", executableDirectory, project.debug);
				
			}
			
		}
		
		if (targetType == "neko") {
			
			ProcessHelper.runCommand ("", "haxe", [ hxml ]);
			
			if (noOutput) return;
			
			NekoHelper.createExecutable (project.templatePaths, "mac" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries (project.templatePaths, "mac" + (is64 ? "64" : ""), executableDirectory);
			
		} else if (targetType == "java") {
			
			var libPath = PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates/java/lib/");
			
			ProcessHelper.runCommand ("", "haxe", [ hxml, "-java-lib", libPath + "disruptor.jar", "-java-lib", libPath + "lwjgl.jar" ]);
			
			if (noOutput) return;
			
			HaxelibHelper.runCommand (targetDirectory + "/obj", [ "run", "hxjava", "hxjava_build.txt", "--haxe-version", "3103" ]);
			FileHelper.recursiveCopy (targetDirectory + "/obj/lib", PathHelper.combine (executableDirectory, "lib"));
			FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-Debug" : "") + ".jar", PathHelper.combine (executableDirectory, project.app.file + ".jar"));
			JavaHelper.copyLibraries (project.templatePaths, "Mac" + (is64 ? "64" : ""), executableDirectory);
			
		} else if (targetType == "nodejs") {
			
			ProcessHelper.runCommand ("", "haxe", [ hxml ]);
			
			if (noOutput) return;
			
			//NekoHelper.createExecutable (project.templatePaths, "Mac" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
			NekoHelper.copyLibraries (project.templatePaths, "Mac" + (is64 ? "64" : ""), executableDirectory);
			
		} else if (targetType == "cs") {
			
			ProcessHelper.runCommand ("", "haxe", [ hxml ]);
			
			if (noOutput) return;
			
			CSHelper.copySourceFiles (project.templatePaths, targetDirectory + "/obj/src");
			var txtPath = targetDirectory + "/obj/hxcs_build.txt";
			CSHelper.addSourceFiles (txtPath, CSHelper.ndllSourceFiles);
			CSHelper.addGUID (txtPath, GUID.uuid ());
			CSHelper.compile (project, targetDirectory + "/obj", targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), "x64", "desktop");
			FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath + ".exe");
			File.saveContent (executablePath, "#!/bin/sh\nmono ${PWD}/" + project.app.file + ".exe");
			
		} else {
			
			var haxeArgs = [ hxml, "-D", "HXCPP_CLANG" ];
			var flags = [ "-DHXCPP_CLANG" ];
			
			if (is64) {
				
				haxeArgs.push ("-D");
				haxeArgs.push ("HXCPP_M64");
				flags.push ("-DHXCPP_M64");
				
			}
			
			if (!project.targetFlags.exists ("static")) {
				
				ProcessHelper.runCommand ("", "haxe", haxeArgs);
				
				if (noOutput) return;
				
				CPPHelper.compile (project, targetDirectory + "/obj", flags);
				
				FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), executablePath);
				
			} else {
				
				ProcessHelper.runCommand ("", "haxe", haxeArgs.concat ([ "-D", "static_link" ]));
				
				if (noOutput) return;
				
				CPPHelper.compile (project, targetDirectory + "/obj", flags.concat ([ "-Dstatic_link" ]));
				CPPHelper.compile (project, targetDirectory + "/obj", flags, "BuildMain.xml");
				
				FileHelper.copyFile (targetDirectory + "/obj/Main" + (project.debug ? "-debug" : ""), executablePath);
				
			}
			
		}
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS && targetType != "nodejs" && targetType != "java") {
			
			ProcessHelper.runCommand ("", "chmod", [ "755", executablePath ]);
			
		}
		
	}
	
	
	public override function clean ():Void {
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function deploy ():Void {
		
		DeploymentHelper.deploy (project, targetFlags, targetDirectory, "Mac");
		
	}
	
	
	public override function display ():Void {
		
		Sys.println (getDisplayHXML ());
		
	}
	
	
	private function generateContext ():Dynamic {
		
		var context = project.templateContext;
		context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
		context.NODE_FILE = executableDirectory + "/ApplicationMain.js";
		context.CPP_DIR = targetDirectory + "/obj/";
		context.BUILD_DIR = project.app.path + "/mac" + (is64 ? "64" : "");
		
		return context;
		
	}
	
	
	private function getDisplayHXML ():String {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, targetType + "/hxml/" + buildType + ".hxml");
		var template = new Template (File.getContent (hxml));
		
		var context = generateContext ();
		context.OUTPUT_DIR = targetDirectory;
		
		return template.execute (context) + "\n-D display";
		
	}
	
	
	public override function rebuild ():Void {
		
		var commands = [];
		
		if (!targetFlags.exists ("32") && (command == "rebuild" || PlatformHelper.hostArchitecture == Architecture.X64)) {
			
			commands.push ([ "-Dmac", "-DHXCPP_CLANG", "-DHXCPP_M64" ]);
			
		}
		
		if (!targetFlags.exists ("64") && (command == "rebuild" || PlatformHelper.hostArchitecture == Architecture.X86)) {
			
			commands.push ([ "-Dmac", "-DHXCPP_CLANG", "-DHXCPP_M32" ]);
			
		}
		
		CPPHelper.rebuild (project, commands);
		
	}
	
	
	public override function run ():Void {
		
		var arguments = additionalArguments.copy ();
		
		if (LogHelper.verbose) {
			
			arguments.push ("-verbose");
			
		}
		
		if (targetType == "nodejs") {
			
			NodeJSHelper.run (project, executableDirectory + "/ApplicationMain.js", arguments);
			
		} else if (targetType == "java") {
			
			ProcessHelper.runCommand (executableDirectory, "java", [ "-jar", project.app.file + ".jar" ].concat (arguments));
			
		} else if (project.target == PlatformHelper.hostPlatform) {
			
			arguments = arguments.concat ([ "-livereload" ]);
			ProcessHelper.runCommand (executableDirectory, "./" + Path.withoutDirectory (executablePath), arguments);
			
		}
		
	}
	
	
	public override function update ():Void {
		
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
			
			for (i in 0...project.ndlls.length) {
				
				var ndll = project.ndlls[i];
				
				if (ndll.path == null || ndll.path == "") {
					
					context.ndlls[i].path = PathHelper.getLibraryPath (ndll, "Mac" + (is64 ? "64" : ""), "lib", ".a", project.debug);
					
				}
				
			}
			
		}
		
		PathHelper.mkdir (targetDirectory);
		PathHelper.mkdir (targetDirectory + "/obj");
		PathHelper.mkdir (targetDirectory + "/haxe");
		PathHelper.mkdir (applicationDirectory);
		PathHelper.mkdir (contentDirectory);
		
		//SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
		FileHelper.recursiveSmartCopyTemplate (project, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveSmartCopyTemplate (project, targetType + "/hxml", targetDirectory + "/haxe", context);
		
		if (targetType == "cpp" && project.targetFlags.exists ("static")) {
			
			FileHelper.recursiveSmartCopyTemplate (project, "cpp/static", targetDirectory + "/obj", context);
			
		}
		
		FileHelper.copyFileTemplate (project.templatePaths, "mac/Info.plist", targetDirectory + "/bin/" + project.app.file + ".app/Contents/Info.plist", context);
		FileHelper.copyFileTemplate (project.templatePaths, "mac/Entitlements.plist", targetDirectory + "/bin/" + project.app.file + ".app/Contents/Entitlements.plist", context);
		
		var icons = project.icons;
		
		if (icons.length == 0) {
			
			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];
			
		}
		
		context.HAS_ICON = IconHelper.createMacIcon (icons, PathHelper.combine (contentDirectory, "icon.icns"));
		
		for (asset in project.assets) {
			
			if (asset.embed != true) {
			
				if (asset.type != AssetType.TEMPLATE) {
					
					PathHelper.mkdir (Path.directory (PathHelper.combine (contentDirectory, asset.targetPath)));
					FileHelper.copyAssetIfNewer (asset, PathHelper.combine (contentDirectory, asset.targetPath));
					
				} else {
					
					PathHelper.mkdir (Path.directory (PathHelper.combine (targetDirectory, asset.targetPath)));
					FileHelper.copyAsset (asset, PathHelper.combine (targetDirectory, asset.targetPath), context);
					
				}
				
			}
			
		}
		
	}
	
	
	public override function watch ():Void {
		
		var dirs = WatchHelper.processHXML (project, getDisplayHXML ());
		var command = WatchHelper.getCurrentCommand ();
		WatchHelper.watch (project, command, dirs);
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}