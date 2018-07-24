package;


//import openfl.display.BitmapData;
import haxe.io.Path;
import haxe.Json;
import haxe.Template;
import hxp.helpers.ArrayHelper;
import hxp.helpers.CPPHelper;
import hxp.helpers.DeploymentHelper;
import hxp.helpers.FileHelper;
import hxp.helpers.IconHelper;
import hxp.helpers.TVOSHelper;
import hxp.helpers.LogHelper;
import hxp.helpers.PathHelper;
import hxp.helpers.PlatformHelper;
import hxp.helpers.ProcessHelper;
import hxp.helpers.StringHelper;
import hxp.helpers.WatchHelper;
#if lime
import lime.graphics.Image;
#end
import hxp.project.Architecture;
import hxp.project.Asset;
import hxp.project.AssetType;
import hxp.project.Haxelib;
import hxp.project.HXProject;
import hxp.project.Icon;
import hxp.project.Keystore;
import hxp.project.NDLL;
import hxp.project.Platform;
import hxp.project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class TVOSPlatform extends PlatformTarget {


	public function new (command:String, _project:HXProject, targetFlags:Map<String, String> ) {

		super (command, _project, targetFlags);

		targetDirectory = PathHelper.combine (project.app.path, project.config.getString ("tvos.output-directory", "tvos"));

	}


	public override function build ():Void {

		if (project.targetFlags.exists ("xcode") && PlatformHelper.hostPlatform == Platform.MAC) {

			ProcessHelper.runCommand ("", "open", [ targetDirectory + "/" + project.app.file + ".xcodeproj" ] );

		} else {

			TVOSHelper.build (project, targetDirectory);

			if (noOutput) return;

			if (!project.targetFlags.exists ("simulator")) {

				TVOSHelper.sign (project, targetDirectory + "/bin");

			}

		}

	}


	public override function clean ():Void {

		if (FileSystem.exists (targetDirectory)) {

			PathHelper.removeDirectory (targetDirectory);

		}

	}


	public override function deploy ():Void {

		TVOSHelper.deploy (project, targetDirectory);

	}


	public override function display ():Void {

		Sys.println (getDisplayHXML ());

	}


	private function generateContext ():Dynamic {

		// project = project.clone ();

		project.sources.unshift ("");
		project.sources = PathHelper.relocatePaths (project.sources, PathHelper.combine (targetDirectory, project.app.file + "/haxe"));
		//project.dependencies.push ("stdc++");

		if (project.targetFlags.exists ("xml")) {

			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");

		}

		if (project.targetFlags.exists ("final")) {

			project.haxedefs.set ("final", "");

		}

		if (!project.config.exists ("tvos.identity")) {

			project.config.set ("tvos.identity", "tvOS Developer");

		}

		var context = project.templateContext;

		context.HAS_ICON = false;
		context.HAS_LAUNCH_IMAGE = false;
		context.OBJC_ARC = false;
		context.KEY_STORE_IDENTITY = project.config.getString ("tvos.identity");

		context.linkedLibraries = [];

		for (dependency in project.dependencies) {

			if (!StringTools.endsWith (dependency.name, ".framework") && !StringTools.endsWith (dependency.name, ".tbd") && !StringTools.endsWith (dependency.path, ".framework")) {

				if (dependency.path != "") {

					var name = Path.withoutDirectory (Path.withoutExtension (dependency.path));

					project.config.push ("tvos.linker-flags", "-force_load $SRCROOT/$PRODUCT_NAME/lib/$CURRENT_ARCH/" + Path.withoutDirectory (dependency.path));

					if (StringTools.startsWith (name, "lib")) {

						name = name.substring (3, name.length);

					}

					context.linkedLibraries.push (name);

				} else if (dependency.name != "") {

					context.linkedLibraries.push (dependency.name);

				}

			}

		}

		var valid_archs = new Array<String> ();
		var arm64 = false;
		var architectures = project.architectures;

		if (architectures == null || architectures.length == 0) {

			architectures = [ Architecture.ARM64 ];

		}

		/*if (project.config.getString ("ios.device", "universal") == "universal" || project.config.getString ("ios.device") == "iphone") {

			if (project.config.getFloat ("ios.deployment", 5.1) < 5) {

				ArrayHelper.addUnique (architectures, Architecture.ARMV6);

			}

		}*/

		for (architecture in project.architectures) {

			switch (architecture) {

				case ARM64: valid_archs.push ("arm64"); arm64 = true;
				default:

			}

		}

		context.CURRENT_ARCHS = "( " + valid_archs.join(",") + ") ";

		valid_archs.push ("i386");

		context.VALID_ARCHS = valid_archs.join(" ");
		context.THUMB_SUPPORT = "";

		var requiredCapabilities = [];

		requiredCapabilities.push( { name: "arm64", value: true } );

		context.REQUIRED_CAPABILITY = requiredCapabilities;
		context.ARM64 = arm64;
		context.TARGET_DEVICES = switch (project.config.getString ("tvos.device", "appletv")) { case "appletv": "3"; default: "3";  }
		context.DEPLOYMENT = project.config.getString ("tvos.deployment", "9.0");

		if (project.config.getString ("tvos.compiler") == "llvm" || project.config.getString ("tvos.compiler", "clang") == "clang") {

			context.OBJC_ARC = true;

		}

		context.IOS_COMPILER = project.config.getString ("tvos.compiler", "clang");
		context.CPP_BUILD_LIBRARY = project.config.getString ("cpp.buildLibrary", "hxcpp");

		var json = Json.parse (File.getContent (PathHelper.getHaxelib (new Haxelib ("hxcpp"), true) + "/haxelib.json"));

		var version = Std.string (json.version);
		var versionSplit = version.split (".");

		while (versionSplit.length > 2) versionSplit.pop ();

		if (Std.parseFloat (versionSplit.join (".")) > 3.1) {

			context.CPP_LIBPREFIX = "lib";

		} else {

			context.CPP_LIBPREFIX = "";

		}

		context.IOS_LINKER_FLAGS = ["-stdlib=libc++"].concat (project.config.getArrayString ("tvos.linker-flags"));
		context.IOS_NON_EXEMPT_ENCRYPTION = project.config.getBool ("tvos.non-exempt-encryption", true);

		switch (project.window.orientation) {

			case PORTRAIT:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			case LANDSCAPE:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>";
			case ALL:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			//case "allButUpsideDown":
				//context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string></array>";
			default:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";

		}

		context.ADDL_PBX_BUILD_FILE = "";
		context.ADDL_PBX_FILE_REFERENCE = "";
		context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE = "";
		context.ADDL_PBX_FRAMEWORK_GROUP = "";

		context.frameworkSearchPaths = [];

		for (dependency in project.dependencies) {

			var name = null;
			var path = null;
			var fileType = null;

			if (Path.extension (dependency.name) == "framework") {

				name = dependency.name;
				path = "/System/Library/Frameworks/" + dependency.name;
				fileType = "wrapper.framework";

			} else if (Path.extension (dependency.name) == "tbd") {

				name = dependency.name;
				path = "usr/lib/" + dependency.name;
				fileType = "sourcecode.text-based-dylib-definition";

			} else if (Path.extension (dependency.path) == "framework") {

				name = Path.withoutDirectory (dependency.path);
				path = PathHelper.tryFullPath (dependency.path);
				fileType = "wrapper.framework";

			}

			if (name != null) {

				var frameworkID = "11C0000000000018" + StringHelper.getUniqueID ();
				var fileID = "11C0000000000018" + StringHelper.getUniqueID ();

				ArrayHelper.addUnique (context.frameworkSearchPaths, Path.directory (path));

				context.ADDL_PBX_BUILD_FILE += "		" + frameworkID + " /* " + name + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + fileID + " /* " + name + " */; };\n";
				context.ADDL_PBX_FILE_REFERENCE += "		" + fileID + " /* " + name + " */ = {isa = PBXFileReference; lastKnownFileType = \"" + fileType + "\"; name = \"" + name + "\"; path = \"" + path + "\"; sourceTree = SDKROOT; };\n";
				context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE += "				" + frameworkID + " /* " + name + " in Frameworks */,\n";
				context.ADDL_PBX_FRAMEWORK_GROUP += "				" + fileID + " /* " + name + " */,\n";

			}

		}

		context.HXML_PATH = PathHelper.findTemplate (project.templatePaths, "tvos/PROJ/haxe/Build.hxml");
		context.PRERENDERED_ICON = project.config.getBool ("tvos.prerenderedIcon", false);

		var haxelibPath = project.environment.get ("HAXELIB_PATH");

		if (haxelibPath != null) {

			context.HAXELIB_PATH = 'export HAXELIB_PATH=$haxelibPath;';

		} else {

			context.HAXELIB_PATH = '';

		}

		return context;

	}


	private function getDisplayHXML ():String {

		var hxml = PathHelper.findTemplate (project.templatePaths, "tvos/PROJ/haxe/Build.hxml");
		var template = new Template (File.getContent (hxml));

		var context = generateContext ();
		context.OUTPUT_DIR = targetDirectory;

		return template.execute (context) + "\n-D display";

	}


	public override function rebuild ():Void {

		var arm64 = (command == "rebuild" || (project.architectures.indexOf (Architecture.ARM64) > -1 && !project.targetFlags.exists ("simulator")));
		var i386 = (command == "rebuild" || project.targetFlags.exists ("simulator"));
		var x86_64 = (command == "rebuild" || project.targetFlags.exists ("simulator"));

		var commands = [];

		if (arm64) commands.push ([ "-Dtvos", "-Dappletvos", "-DHXCPP_CPP11", "-DHXCPP_ARM64", "-DOBJC_ARC", "-DENABLE_BITCODE" ]);
		if (i386) commands.push ([ "-Dtvos", "-Dappletvsim", "-Dsimulator", "-DHXCPP_CPP11", "-DOBJC_ARC", "-DENABLE_BITCODE" ]);
		if (x86_64) commands.push ([ "-Dtvos", "-Dappletvsim", "-Dsimulator", "-DHXCPP_M64", "-DHXCPP_CPP11", "-DOBJC_ARC", "-DENABLE_BITCODE" ]);

		CPPHelper.rebuild (project, commands);

	}


	public override function run ():Void {

		if (project.targetFlags.exists ("xcode")) return;

		TVOSHelper.launch (project, targetDirectory);

	}


	public override function update ():Void {

		// project = project.clone ();

		for (asset in project.assets) {

			if (asset.embed && asset.sourcePath == "") {

				var path = PathHelper.combine (targetDirectory + "/" + project.app.file + "/obj/tmp", asset.targetPath);
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path);
				asset.sourcePath = path;

			}

		}

		//var manifest = new Asset ();
		//manifest.id = "__manifest__";
		//manifest.data = AssetHelper.createManifest (project).serialize ();
		//manifest.resourceName = manifest.flatName = manifest.targetPath = "manifest";
		//manifest.type = AssetType.TEXT;
		//project.assets.push (manifest);

		var context = generateContext ();
		context.OUTPUT_DIR = targetDirectory;

		var projectDirectory = targetDirectory + "/" + project.app.file + "/";

		PathHelper.mkdir (targetDirectory);
		PathHelper.mkdir (projectDirectory);
		PathHelper.mkdir (projectDirectory + "/haxe");
		PathHelper.mkdir (projectDirectory + "/haxe/lime/installer");

		var iconSizes:Array<IconSize> = [
			{ name : "Icon-Small.png", size : 29 },
			{ name : "Icon-Small-40.png", size : 40 },
			{ name : "Icon-Small-50.png", size : 50 },
			{ name : "Icon.png", size : 57 },
			{ name : "Icon-Small@2x.png", size : 58 },
			{ name : "Icon-72.png", size : 72 },
			{ name : "Icon-76.png", size : 76 },
			{ name : "Icon-Small-40@2x.png", size : 80 },
			{ name : "Icon-Small-50@2x.png", size : 100 },
			{ name : "Icon@2x.png", size : 114 },
			{ name : "Icon-60@2x.png", size : 120 },
			{ name : "Icon-72@2x.png", size : 144 },
			{ name : "Icon-76@2x.png", size : 152 },
			{ name : "Icon-60@3x.png", size : 180 },
		];

		context.HAS_ICON = true;

		var iconPath = PathHelper.combine (projectDirectory, "Images.xcassets/AppIcon.appiconset");
		PathHelper.mkdir (iconPath);

		var icons = project.icons;

		if (icons.length == 0) {

			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];

		}

		for (iconSize in iconSizes) {

			if (!IconHelper.createIcon (icons, iconSize.size, iconSize.size, PathHelper.combine (iconPath, iconSize.name))) {

				context.HAS_ICON = false;

			}

		}

		var splashSizes:Array<SplashSize> = [
			{ name: "Default.png", w: 320, h: 480 }, // iPhone, portrait
			{ name: "Default@2x.png", w: 640, h: 960  }, // iPhone Retina, portrait
			{ name: "Default-568h@2x.png", w: 640, h: 1136 }, // iPhone 5, portrait
			{ name: "Default-Portrait.png", w: 768, h: 1024 }, // iPad, portrait
			{ name: "Default-Landscape.png", w: 1024, h: 768  }, // iPad, landscape
			{ name: "Default-Portrait@2x.png", w: 1536, h: 2048 }, // iPad Retina, portrait
			{ name: "Default-Landscape@2x.png", w: 2048, h: 1536 },	// iPad Retina, landscape
			{ name: "Default-667h@2x.png", w: 750, h: 1334 }, // iPhone 6, portrait
			{ name: "Default-736h@3x.png", w: 1242,	h: 2208 }, // iPhone 6 Plus, portrait
			{ name: "Default-736h-Landscape@3x.png", w: 2208, h: 1242 }, // iPhone 6 Plus, landscape
		];

		var splashScreenPath = PathHelper.combine (projectDirectory, "Images.xcassets/LaunchImage.launchimage");
		PathHelper.mkdir (splashScreenPath);

		for (size in splashSizes) {

			var match = false;

			for (splashScreen in project.splashScreens) {

				if (splashScreen.width == size.w && splashScreen.height == size.h && Path.extension (splashScreen.path) == "png") {

					FileHelper.copyFile (splashScreen.path, PathHelper.combine (splashScreenPath, size.name));
					match = true;

				}

			}

			if (!match) {

				var imagePath = PathHelper.combine (splashScreenPath, size.name);

				if (!FileSystem.exists (imagePath)) {

					#if lime
					LogHelper.info ("", " - \x1b[1mGenerating image:\x1b[0m " + imagePath);

					var image = new Image (null, 0, 0, size.w, size.h, (0xFF << 24) | (project.window.background & 0xFFFFFF));
					var bytes = image.encode (PNG);

					File.saveBytes (imagePath, bytes);
					#end

				}

			}

		}

		context.HAS_LAUNCH_IMAGE = true;

		PathHelper.mkdir (projectDirectory + "/resources");
		PathHelper.mkdir (projectDirectory + "/haxe/build");

		FileHelper.recursiveSmartCopyTemplate (project, "tvos/resources", projectDirectory + "/resources", context, true, false);
		FileHelper.recursiveSmartCopyTemplate (project, "tvos/PROJ/haxe", projectDirectory + "/haxe", context);
		FileHelper.recursiveSmartCopyTemplate (project, "haxe", projectDirectory + "/haxe", context);
		FileHelper.recursiveSmartCopyTemplate (project, "tvos/PROJ/Classes", projectDirectory + "/Classes", context);
		FileHelper.recursiveSmartCopyTemplate (project, "tvos/PROJ/Images.xcassets", projectDirectory + "/Images.xcassets", context);
		FileHelper.copyFileTemplate (project.templatePaths, "tvos/PROJ/PROJ-Entitlements.plist", projectDirectory + "/" + project.app.file + "-Entitlements.plist", context);
		FileHelper.copyFileTemplate (project.templatePaths, "tvos/PROJ/PROJ-Info.plist", projectDirectory + "/" + project.app.file + "-Info.plist", context);
		FileHelper.copyFileTemplate (project.templatePaths, "tvos/PROJ/PROJ-Prefix.pch", projectDirectory + "/" + project.app.file + "-Prefix.pch", context);
		FileHelper.recursiveSmartCopyTemplate (project, "tvos/PROJ.xcodeproj", targetDirectory + "/" + project.app.file + ".xcodeproj", context);

		//SWFHelper.generateSWFClasses (project, projectDirectory + "/haxe");

		PathHelper.mkdir (projectDirectory + "/lib");

		for (archID in 0...3) {

			var arch = [ "arm64", "i386", "x86_64" ][archID];

			if (arch == "arm64" && !context.ARM64)
				continue;

			var libExt = [ ".appletvos-64.a", ".appletvsim.a", ".appletvsim-64.a" ][archID];

			PathHelper.mkdir (projectDirectory + "/lib/" + arch);
			PathHelper.mkdir (projectDirectory + "/lib/" + arch + "-debug");

			for (ndll in project.ndlls) {

				//if (ndll.haxelib != null) {

					var releaseLib = PathHelper.getLibraryPath (ndll, "AppleTV", "lib", libExt);
					LogHelper.info("releaseLib: " + releaseLib);
					var debugLib = PathHelper.getLibraryPath (ndll, "AppleTV", "lib", libExt, true);
					var releaseDest = projectDirectory + "/lib/" + arch + "/lib" + ndll.name + ".a";
					LogHelper.info("releaseDest: " + releaseDest);
					var debugDest = projectDirectory + "/lib/" + arch + "-debug/lib" + ndll.name + ".a";

					if (!FileSystem.exists (releaseLib)) {

						releaseLib = PathHelper.getLibraryPath (ndll, "AppleTV", "lib", ".appletvos-64.a");
						LogHelper.info("alternative releaseLib: " + releaseLib);
						debugLib = PathHelper.getLibraryPath (ndll, "AppleTV", "lib", ".appletvos-64.a", true);

					}

					FileHelper.copyIfNewer (releaseLib, releaseDest);

					if (FileSystem.exists (debugLib) && debugLib != releaseLib) {

						FileHelper.copyIfNewer (debugLib, debugDest);

					} else if (FileSystem.exists (debugDest)) {

						FileSystem.deleteFile (debugDest);

					}

				//}

			}

			for (dependency in project.dependencies) {

				if (StringTools.endsWith (dependency.path, ".a")) {

					var fileName = Path.withoutDirectory (dependency.path);

					if (!StringTools.startsWith (fileName, "lib")) {

						fileName = "lib" + fileName;

					}

					FileHelper.copyIfNewer (dependency.path, projectDirectory + "/lib/" + arch + "/" + fileName);

				}

			}

		}

		PathHelper.mkdir (projectDirectory + "/assets");

		for (asset in project.assets) {

			if (asset.type != AssetType.TEMPLATE) {

				var targetPath = PathHelper.combine (projectDirectory + "/assets/", asset.resourceName);

				//var sourceAssetPath:String = projectDirectory + "haxe/" + asset.sourcePath;

				PathHelper.mkdir (Path.directory (targetPath));
				FileHelper.copyAssetIfNewer (asset, targetPath);

				//PathHelper.mkdir (Path.directory (sourceAssetPath));
				//FileHelper.linkFile (flatAssetPath, sourceAssetPath, true, true);

			} else {

				var targetPath = PathHelper.combine (projectDirectory, asset.targetPath);

				PathHelper.mkdir (Path.directory (targetPath));
				FileHelper.copyAsset (asset, targetPath, context);

			}

		}

		if (project.targetFlags.exists ("xcode") && PlatformHelper.hostPlatform == Platform.MAC && command == "update") {

			ProcessHelper.runCommand ("", "open", [ targetDirectory + "/" + project.app.file + ".xcodeproj" ] );

		}

	}


	/*private function updateLaunchImage () {

		var destination = buildDirectory + "/ios";
		PathHelper.mkdir (destination);

		var has_launch_image = false;
		if (launchImages.length > 0) has_launch_image = true;

		for (launchImage in launchImages) {

			var splitPath = launchImage.name.split ("/");
			var path = destination + "/" + splitPath[splitPath.length - 1];
			FileHelper.copyFile (launchImage.name, path, context, false);

		}

		context.HAS_LAUNCH_IMAGE = has_launch_image;

	}*/


	public override function watch ():Void {

		var dirs = WatchHelper.processHXML (project, getDisplayHXML ());
		var command = WatchHelper.getCurrentCommand ();
		WatchHelper.watch (project, command, dirs);

	}


	@ignore public override function install ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}


}


private typedef IconSize = {

	name:String,
	size:Int,

}


private typedef SplashSize = {

	name:String,
	w:Int,
	h:Int,

}
