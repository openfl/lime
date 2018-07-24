package;


import haxe.io.Path;
import haxe.Template;
import hxp.project.Icon;
import hxp.helpers.CPPHelper;
import hxp.helpers.DeploymentHelper;
import hxp.helpers.FileHelper;
import hxp.helpers.HTML5Helper;
import hxp.helpers.IconHelper;
import hxp.helpers.JavaHelper;
import hxp.helpers.LogHelper;
import hxp.helpers.ModuleHelper;
import hxp.helpers.CSHelper;
import hxp.helpers.GUID;
import hxp.helpers.NekoHelper;
import hxp.helpers.NodeJSHelper;
import hxp.helpers.PathHelper;
import hxp.helpers.PlatformHelper;
import hxp.helpers.ProcessHelper;
import hxp.helpers.WatchHelper;
import hxp.project.Architecture;
import hxp.project.Asset;
import hxp.project.AssetType;
import hxp.project.Haxelib;
import hxp.project.HXProject;
import hxp.project.Platform;
import hxp.project.PlatformTarget;
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

		if (project.targetFlags.exists ("uwp") || project.targetFlags.exists ("winjs")) {

			targetType = "winjs";

		} else if (project.targetFlags.exists ("neko") || project.target != PlatformHelper.hostPlatform) {

			targetType = "neko";

		} else if (project.targetFlags.exists ("hl")) {

			targetType = "hl";

		} else if (project.targetFlags.exists ("nodejs")) {

			targetType = "nodejs";

		} else if (project.targetFlags.exists ("cs")) {

			targetType = "cs";

		} else if (project.targetFlags.exists ("java")) {

			targetType = "java";

		} else {

			targetType = "cpp";

		}

		targetDirectory = PathHelper.combine (project.app.path, project.config.getString ("windows.output-directory", targetType == "cpp" ? "windows" : targetType));
		targetDirectory = StringTools.replace (targetDirectory, "arch64", is64 ? "64" : "");

		if (targetType == "winjs") {

			outputFile = targetDirectory + "/source/js/" + project.app.file + ".js";

		} else {

			applicationDirectory = targetDirectory + "/bin/";
			executablePath = applicationDirectory + project.app.file + ".exe";

		}

	}


	public override function build ():Void {

		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";

		PathHelper.mkdir (targetDirectory);

		var icons = project.icons;

		if (icons.length == 0) {

			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];

		}

		if (targetType == "winjs") {

			ModuleHelper.buildModules (project, targetDirectory, targetDirectory);

			if (project.app.main != null) {

				ProcessHelper.runCommand ("", "haxe", [ hxml ]);

				var msBuildPath = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\MSBuild\\15.0\\Bin\\MSBuild.exe";
				var args = [ PathHelper.tryFullPath (targetDirectory + "/source/" + project.app.file + ".jsproj"), "/p:Configuration=Release" ];

				ProcessHelper.runCommand ("", msBuildPath, args);
				if (noOutput) return;

				if (project.targetFlags.exists ("webgl")) {

					FileHelper.copyFile (targetDirectory + "/source/ApplicationMain.js", outputFile);

				}

				if (project.modules.iterator ().hasNext ()) {

					ModuleHelper.patchFile (outputFile);

				}

				if (project.targetFlags.exists ("minify") || buildType == "final") {

					HTML5Helper.minify (project, targetDirectory + outputFile);

				}

			}

		} else {

			for (dependency in project.dependencies) {

				if (StringTools.endsWith (dependency.path, ".dll")) {

					var fileName = Path.withoutDirectory (dependency.path);
					FileHelper.copyIfNewer (dependency.path, applicationDirectory + "/" + fileName);

				}

			}

			if (!project.targetFlags.exists ("static") || targetType != "cpp") {

				var targetSuffix = (targetType == "hl") ? ".hdll" : null;

				for (ndll in project.ndlls) {

					FileHelper.copyLibrary (project, ndll, "Windows" + (is64 ? "64" : ""), "", (ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dll" : ".ndll", applicationDirectory, project.debug, targetSuffix);

				}

			}

			//IconHelper.createIcon (project.icons, 32, 32, PathHelper.combine (applicationDirectory, "icon.png"));

			if (targetType == "neko") {

				ProcessHelper.runCommand ("", "haxe", [ hxml ]);

				if (noOutput) return;

				var iconPath = PathHelper.combine (applicationDirectory, "icon.ico");

				if (!IconHelper.createWindowsIcon (icons, iconPath)) {

					iconPath = null;

				}

				NekoHelper.createWindowsExecutable (project.templatePaths, targetDirectory + "/obj/ApplicationMain.n", executablePath, iconPath);
				NekoHelper.copyLibraries (project.templatePaths, "windows" + (is64 ? "64" : ""), applicationDirectory);

			} else if (targetType == "hl") {

				ProcessHelper.runCommand ("", "haxe", [ hxml ]);

				if (noOutput) return;

				FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain.hl", PathHelper.combine (applicationDirectory, project.app.file + ".hl"));

			} else if (targetType == "nodejs") {

				ProcessHelper.runCommand ("", "haxe", [ hxml ]);

				if (noOutput) return;

				//NekoHelper.createExecutable (project.templatePaths, "windows" + (is64 ? "64" : ""), targetDirectory + "/obj/ApplicationMain.n", executablePath);
				//NekoHelper.copyLibraries (project.templatePaths, "windows" + (is64 ? "64" : ""), applicationDirectory);

			} else if (targetType == "cs") {

				ProcessHelper.runCommand ("", "haxe", [ hxml ]);

				if (noOutput) return;

				CSHelper.copySourceFiles (project.templatePaths, targetDirectory + "/obj/src");
				var txtPath = targetDirectory + "/obj/hxcs_build.txt";
				CSHelper.addSourceFiles (txtPath, CSHelper.ndllSourceFiles);
				CSHelper.addGUID (txtPath, GUID.uuid ());
				CSHelper.compile (project, targetDirectory + "/obj", applicationDirectory + project.app.file, "x86", "desktop");

			} else if (targetType == "java") {

				var libPath = PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates/java/lib/");

				ProcessHelper.runCommand ("", "haxe", [ hxml, "-java-lib", libPath + "disruptor.jar", "-java-lib", libPath + "lwjgl.jar" ]);
				//ProcessHelper.runCommand ("", "haxe", [ hxml ]);

				if (noOutput) return;

				var haxeVersion = project.environment.get ("haxe_ver");
				var haxeVersionString = "3404";

				if (haxeVersion.length > 4) {

					haxeVersionString = haxeVersion.charAt (0) + haxeVersion.charAt (2) + (haxeVersion.length == 5 ? "0" + haxeVersion.charAt (4) : haxeVersion.charAt (4) + haxeVersion.charAt (5));

				}

				ProcessHelper.runCommand (targetDirectory + "/obj", "haxelib", [ "run", "hxjava", "hxjava_build.txt", "--haxe-version", haxeVersionString ]);
				FileHelper.recursiveCopy (targetDirectory + "/obj/lib", PathHelper.combine (applicationDirectory, "lib"));
				FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-Debug" : "") + ".jar", PathHelper.combine (applicationDirectory, project.app.file + ".jar"));
				JavaHelper.copyLibraries (project.templatePaths, "Windows" + (is64 ? "64" : ""), applicationDirectory);

			} else {

				var haxeArgs = [ hxml ];
				var flags = [];

				if (is64) {

					haxeArgs.push ("-D");
					haxeArgs.push ("HXCPP_M64");
					flags.push ("-DHXCPP_M64");

				} else {

					flags.push ("-DHXCPP_M32");

				}

				if (!project.environment.exists ("SHOW_CONSOLE")) {

					haxeArgs.push ("-D");
					haxeArgs.push ("no_console");
					flags.push ("-Dno_console");

				}

				if (!project.targetFlags.exists ("static")) {

					ProcessHelper.runCommand ("", "haxe", haxeArgs);

					if (noOutput) return;

					CPPHelper.compile (project, targetDirectory + "/obj", flags);

					FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : "") + ".exe", executablePath);

				} else {

					ProcessHelper.runCommand ("", "haxe", haxeArgs.concat ([ "-D", "static_link" ]));

					if (noOutput) return;

					CPPHelper.compile (project, targetDirectory + "/obj", flags.concat ([ "-Dstatic_link" ]));
					CPPHelper.compile (project, targetDirectory + "/obj", flags, "BuildMain.xml");

					FileHelper.copyFile (targetDirectory + "/obj/Main" + (project.debug ? "-debug" : "") + ".exe", executablePath);

				}

				var iconPath = PathHelper.combine (applicationDirectory, "icon.ico");

				if (IconHelper.createWindowsIcon (icons, iconPath) && PlatformHelper.hostPlatform == Platform.WINDOWS) {

					var templates = [ PathHelper.getHaxelib (new Haxelib (#if lime "lime" #else "hxp" #end)) + "/templates" ].concat (project.templatePaths);
					ProcessHelper.runCommand ("", PathHelper.findTemplate (templates, "bin/ReplaceVistaIcon.exe"), [ executablePath, iconPath, "1" ], true, true);

				}

			}

		}

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

		Sys.println (getDisplayHXML ());

	}


	private function generateContext ():Dynamic {

		var context = project.templateContext;

		if (targetType == "winjs") {

			context.WIN_FLASHBACKGROUND = project.window.background != null ? StringTools.hex (project.window.background, 6) : "";
			context.OUTPUT_FILE = outputFile;

			if (project.targetFlags.exists ("webgl")) {

				context.CPP_DIR = targetDirectory;

			}

			var guid = GUID.seededUuid (project.meta.packageName);
			context.APP_GUID = guid;

			var guidNoBrackets = guid.split("{").join("").split("}").join("");
			context.APP_GUID_NOBRACKETS = guidNoBrackets;

			if (context.APP_DESCRIPTION == null || context.APP_DESCRIPTION == "") {

				context.APP_DESCRIPTION = project.meta.title;

			}

		} else {

			context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
			context.NODE_FILE = targetDirectory + "/bin/ApplicationMain.js";
			context.HL_FILE = targetDirectory + "/obj/ApplicationMain.hl";
			context.CPP_DIR = targetDirectory + "/obj";
			context.BUILD_DIR = project.app.path + "/windows" + (is64 ? "64" : "");

		}

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

		if (targetType != "winjs") {

			if (project.environment.exists ("VS110COMNTOOLS") && project.environment.exists ("VS100COMNTOOLS")) {

				project.environment.set ("HXCPP_MSVC", project.environment.get ("VS100COMNTOOLS"));
				Sys.putEnv ("HXCPP_MSVC", project.environment.get ("VS100COMNTOOLS"));

			}

			var commands = [];

			if (!targetFlags.exists ("32") && PlatformHelper.hostArchitecture == X64) {

				if (targetFlags.exists ("winrt")) {

					commands.push ([ "-Dwinrt", "-DHXCPP_M64" ]);

				} else {

					commands.push ([ "-Dwindows", "-DHXCPP_M64" ]);

				}

			}

			if (!targetFlags.exists ("64") && (command == "rebuild" || PlatformHelper.hostArchitecture == Architecture.X86)) {

				if (targetFlags.exists ("winrt")) {

					commands.push ([ "-Dwinrt", "-DHXCPP_M32" ]);

				} else {

					commands.push ([ "-Dwindows", "-DHXCPP_M32" ]);

				}

			}

			CPPHelper.rebuild (project, commands);

		}

	}


	public override function run ():Void {

		var arguments = additionalArguments.copy ();

		if (LogHelper.verbose) {

			arguments.push ("-verbose");

		}

		if (targetType == "hl") {

			ProcessHelper.runCommand (applicationDirectory, "hl", [ project.app.file + ".hl" ].concat (arguments));

		} else if (targetType == "nodejs") {

			NodeJSHelper.run (project, targetDirectory + "/bin/ApplicationMain.js", arguments);

		} else if (targetType == "winjs") {

			/*

			The 'test' target is problematic for UWP applications.  UWP applications are bundled in appx packages and
			require app certs to properly install.

			There are two options to trigger an appx install from the command line.

			A. Use the WinAppDeployCmd.exe utility to deploy to local and remote devices

			B. Execute the Add-AppDevPackage.ps1 powershell script that is an
				artifact of the UWP msbuild

			A: WinAppDeployCmd.exe
			https://docs.microsoft.com/en-us/windows/uwp/packaging/install-universal-windows-apps-with-the-winappdeploycmd-tool
			https://msdn.microsoft.com/en-us/windows/desktop/mt627714
			Windows 10 SDK: https://developer.microsoft.com/windows/downloads/windows-10-sdk

			I've never actually got this to work, but I feel like I was close.  The WinAppDeployCmd.exe is a part of the
			Windows 10 SDK and not a part of the Visual Studio 2017 community edition.  It will appear magically if you
			check enough boxes when installing various project templates for Visual Studio.  It appeared for me, and I
			have no clue how it got there.

			A developer must take a few steps in order for this command to work.
			1. Install Visual Studio 2017 Community Edition
			2. Install the Windows 10 SDK
			3. Modify Windows 10 Settings to enable side loading and device discovery
			3. Enabling device discovery generates a pin number that is displayed to the user
			4. Open the "Developer Command Promp for VS 2017" from the Start menu
			5. run:
				> WinAppDeployCmd devices
			6. Make sure your device shows up in the list (if it does not appear try step 3 again, toggling things on/off)
			7. run: (replase file, ip and pin with your values)
				> WinAppDeployCmd install -file "uwp-project_1.0.0.0_AnyCPU.appx" -ip 192.168.27.167 -pin 326185

			B: Add-AppDevPackage.ps1 + PowerShell_Set_Unrestricted.reg
			The UWP build generates a powershell script by default. This script is usually executed by the user
			by right clicking the file and choosing "run with powershell". Executing this script directly from the cmd
			prompt results in a security error: "Add-AppDevPackage.ps1 cannot be loaded because running scripts is
			disabled on this system."

			We must edit the registry if we want to run this script directly from a shell.
			See lime/templates/windows/template/PowerShell_Set_Unrestricted.reg

			1. run:
				> regedit /s PowerShell_Set_Unrestricted.reg
			2. run:
	 			> powershell "& ""./Add-AppDevPackage.ps1"""

	 		note: the nonsensical double quotes are required.

	 		*/

			// Using option B because obtaining the device pin programatically does not seem possible.
			//ProcessHelper.runCommand ("", "regedit", [ '/s', '"' + targetDirectory + '/bin/PowerShell_Set_Unrestricted.reg"' ]);
			//var test = '"& ""' + targetDirectory + '/bin/PowerShell_Set_Unrestricted.reg"""';
			//Sys.command ('powershell & ""' + targetDirectory + '/bin/source/AppPackages/' + project.app.file + '_1.0.0.0_AnyCPU_Test/Add-AppDevPackage.ps1""');
			var version = project.meta.version + "." + project.meta.buildNumber;
			ProcessHelper.openFile (targetDirectory + "/source/AppPackages/" + project.app.file + "_" + version + "_AnyCPU_Test", project.app.file + "_" + version + "_AnyCPU.appx");

			//source/AppPackages/uwp-project_1.0.0.0_AnyCPU_Test/Add-AppDevPackage.ps1

			//HTML5Helper.launch (project, targetDirectory + "/bin");

		} else if (targetType == "java") {

			ProcessHelper.runCommand (applicationDirectory, "java", [ "-jar", project.app.file + ".jar" ].concat (arguments));

		} else if (project.target == PlatformHelper.hostPlatform) {

			arguments = arguments.concat ([ "-livereload" ]);
			ProcessHelper.runCommand (applicationDirectory, Path.withoutDirectory (executablePath), arguments);

		}

	}


	public override function update ():Void {

		if (targetType == "winjs") {

			updateUWP ();
			return;

		}

		// project = project.clone ();

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

			var programFiles = project.environment.get ("ProgramFiles(x86)");
			var hasVSCommunity = (programFiles != null && FileSystem.exists (PathHelper.combine (programFiles, "Microsoft Visual Studio/Installer/vswhere.exe")));
			var hxcppMSVC = project.environment.get ("HXCPP_MSVC");
			var vs140 = project.environment.get ("VS140COMNTOOLS");

			var msvc19 = true;

			if ((!hasVSCommunity && vs140 == null) || (hxcppMSVC != null && hxcppMSVC != vs140)) {

				msvc19 = false;

			}

			var suffix = (msvc19 ? "-19.lib" : ".lib");

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

		FileHelper.recursiveSmartCopyTemplate (project, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveSmartCopyTemplate (project, targetType + "/hxml", targetDirectory + "/haxe", context);

		if (targetType == "cpp" && project.targetFlags.exists ("static")) {

			FileHelper.recursiveSmartCopyTemplate (project, "cpp/static", targetDirectory + "/obj", context);

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


	private function updateUWP ():Void {

		project = project.clone ();

		var destination = targetDirectory + "/source/";
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

					// project.haxeflags.push (HTML5Helper.generateFontData (project, asset));

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

		var context = generateContext ();
		context.OUTPUT_DIR = targetDirectory;

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

			if (StringTools.endsWith (dependency.name, ".js")) {

				context.linkedLibraries.push (dependency.name);

			} else if (StringTools.endsWith (dependency.path, ".js") && FileSystem.exists (dependency.path)) {

				var name = Path.withoutDirectory (dependency.path);

				context.linkedLibraries.push ("./js/lib/" + name);
				FileHelper.copyIfNewer (dependency.path, PathHelper.combine (destination, PathHelper.combine ("js/lib", name)));

			}

		}

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

		FileHelper.recursiveSmartCopyTemplate (project, "winjs/template", targetDirectory, context);

		var renamePaths = [ "uwp-project.sln", "source/uwp-project.jsproj", "source/uwp-project_TemporaryKey.pfx" ];
		var fullPath;

		for (path in renamePaths) {

			fullPath = targetDirectory + "/" + path;

			try {

				if (FileSystem.exists (fullPath)) {

					File.copy (fullPath, targetDirectory + "/" + StringTools.replace (path, "uwp-project", project.app.file));
					FileSystem.deleteFile (fullPath);

				}

			} catch (e:Dynamic) {}

		}

		if (project.app.main != null) {

			FileHelper.recursiveSmartCopyTemplate (project, "haxe", targetDirectory + "/haxe", context);
			FileHelper.recursiveSmartCopyTemplate (project, "winjs/haxe", targetDirectory + "/haxe", context, true, false);
			FileHelper.recursiveSmartCopyTemplate (project, "winjs/hxml", targetDirectory + "/haxe", context);

			if (project.targetFlags.exists ("webgl")) {

				FileHelper.recursiveSmartCopyTemplate (project, "webgl/hxml", targetDirectory + "/haxe", context, true, false);

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


	public override function watch ():Void {

		var dirs = WatchHelper.processHXML (project, getDisplayHXML ());
		var command = WatchHelper.getCurrentCommand ();
		WatchHelper.watch (project, command, dirs);

	}


	@ignore public override function install ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}


}
