package platforms;


//import openfl.display.BitmapData;
import haxe.io.Path;
import haxe.Template;
import helpers.ArrayHelper;
import helpers.AssetHelper;
import helpers.CPPHelper;
import helpers.FileHelper;
import helpers.IconHelper;
import helpers.IOSHelper;
import helpers.LogHelper;
import helpers.PathHelper;
import helpers.PlatformHelper;
import helpers.ProcessHelper;
import helpers.StringHelper;
import lime.graphics.Image;
import project.Architecture;
import project.Asset;
import project.AssetType;
import project.Haxelib;
import project.HXProject;
import project.Keystore;
import project.NDLL;
import project.Platform;
import project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class IOSPlatform extends PlatformTarget {
	
	public var iPadSupported:Bool = false;
	public var iPhoneSupported:Bool = false;


	public function new (command:String, _project:HXProject, targetFlags:Map <String, String> ) {
		
		super (command, _project, targetFlags);
		
		var device = project.config.getString ("ios.device", null);
		iPhoneSupported = (device == null || device == "iphone");
		iPadSupported = (device == null || device == "ipad");
	}
	
	
	public override function build ():Void {
		
		var targetDirectory = PathHelper.combine (project.app.path, "ios");
		
		IOSHelper.build (project, project.app.path + "/ios");
		
		if (!project.targetFlags.exists ("simulator")) {
			
			var entitlements = targetDirectory + "/" + project.app.file + "/" + project.app.file + "-Entitlements.plist";
			IOSHelper.sign (project, targetDirectory + "/bin", entitlements);
			
		}
		
	}
	
	
	public override function clean ():Void {
		
		var targetPath = project.app.path + "/ios";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public override function display ():Void {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "iphone/PROJ/haxe/Build.hxml");
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (generateContext ()));
		
	}
	
	
	private function generateContext ():Dynamic {
		
		project = project.clone ();
		
		project.sources.unshift ("");
		project.sources = PathHelper.relocatePaths (project.sources, PathHelper.combine (project.app.path, "ios/" + project.app.file + "/haxe"));
		//project.dependencies.push ("stdc++");
		
		if (project.certificate == null || project.certificate.identity == null) {
			
			project.certificate = new Keystore ();
			project.certificate.identity = "iPhone Developer";
			
		}
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + project.app.path + "/ios/types.xml");
			
		}
		
		if (project.targetFlags.exists ("final")) {
			
			project.haxedefs.set ("final", "");
			
		}
		
		var context = project.templateContext;
		
		context.HAS_ICON = false;
		context.HAS_LAUNCH_IMAGE = false;
		context.LAUNCH_IMAGES = [];

		context.OBJC_ARC = false;
		
		context.linkedLibraries = [];
		
		for (dependency in project.dependencies) {
			
			if (!StringTools.endsWith (dependency.name, ".framework") && !StringTools.endsWith (dependency.path, ".framework")) {
				
				if (dependency.path != "") {
					
					var name = Path.withoutDirectory (Path.withoutExtension (dependency.path));
					
					project.config.push ("ios.linker-flags", "-force_load $SRCROOT/$PRODUCT_NAME/lib/$ARCHS/" + Path.withoutDirectory (dependency.path));
					//project.config.ios.linkerFlags.push ("-force_load $SRCROOT/$PRODUCT_NAME/lib/$ARCHS/" + Path.withoutDirectory (dependency.path));
					
					if (StringTools.startsWith (name, "lib")) {
						
						name = name.substring (3, name.length);
						
					}
					
					context.linkedLibraries.push (name);
					
				} else if (dependency.name != "") {
					
					context.linkedLibraries.push (dependency.name);
					
				}
				
			}
			
		}
		
		/*var deployment = Std.parseFloat (iosDeployment);
		var binaries = iosBinaries;
		var devices = iosDevices;
		
		if (binaries != "fat" && binaries != "armv7" && binaries != "armv6") {
			
			InstallerBase.error ("iOS binaries must be one of: \"fat\", \"armv6\", \"armv7\"");
			
		}
		
		if (devices != "iphone" && devices != "ipad" && devices != "universal") {
			
			InstallerBase.error ("iOS devices must be one of: \"universal\", \"iphone\", \"ipad\"");
			
		}
		
		var iphone = (devices == "universal" || devices == "iphone");
		var ipad = (devices == "universal" || devices == "ipad");
		
		armv6 = ((iphone && deployment < 5.0 && Std.parseInt (defines.get ("IPHONE_VER")) < 6) || binaries == "armv7");
		armv7 = (binaries != "armv6" || !armv6 || ipad);
		
		var valid_archs = new Array <String> ();
		
		if (armv6) {
			
			valid_archs.push("armv6");
			
		}
		
		if (armv7) {
			
			valid_archs.push("armv7");
			
		}
		
		if (iosCompiler == "llvm" || iosCompiler == "clang") {
			
			context.OBJC_ARC = true;
			
		}*/
		
		var valid_archs = new Array <String> ();
		var armv6 = false;
		var armv7 = false;
		var architectures = project.architectures;
		
		if (architectures == null || architectures.length == 0) {
			
			architectures = [ Architecture.ARMV7 ];
			
		}
		
		if (iPhoneSupported) {
			
			if (project.config.getInt ("ios.deployment", 5) < 5) {
				
				ArrayHelper.addUnique (architectures, Architecture.ARMV6);
				
			}
			
		}
		
		for (architecture in project.architectures) {
			
			switch (architecture) {
				
				case ARMV6: valid_archs.push ("armv6"); armv6 = true;
				case ARMV7: valid_archs.push ("armv7"); armv7 = true;
				default:
				
			}
			
		}
		
		context.CURRENT_ARCHS = "( " + valid_archs.join(",") + ") ";
		
		valid_archs.push ("i386");
		
		context.VALID_ARCHS = valid_archs.join(" ");
		context.THUMB_SUPPORT = armv6 ? "GCC_THUMB_SUPPORT = NO;" : "";
		
		var requiredCapabilities = [];
		
		if (armv7 && !armv6) {
			
			requiredCapabilities.push( { name: "armv7", value: true } );
			
		}
		
		context.REQUIRED_CAPABILITY = requiredCapabilities;
		context.ARMV6 = armv6;
		context.ARMV7 = armv7;
		context.TARGET_DEVICES = switch (project.config.getString ("ios.device", "universal")) { case "iphone": "1"; case "ipad": "2"; default: "1,2";  }
		context.DEPLOYMENT = project.config.getInt ("ios.deployment", 5);
		
		if (project.config.getString ("ios.compiler") == "llvm" || project.config.getString ("ios.compiler", "clang") == "clang") {
			
			context.OBJC_ARC = true;
			
		}
		
		context.IOS_COMPILER = project.config.getString ("ios.compiler", "clang");
		context.CPP_BUILD_LIBRARY = project.config.getString ("cpp.buildLibrary", "hxcpp");
		context.IOS_LINKER_FLAGS = ["-stdlib=libc++"].concat (project.config.getArrayString ("ios.linker-flags"));
		
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
			
			if (Path.extension (dependency.name) == "framework") {
				
				name = dependency.name;
				path = "/System/Library/Frameworks/" + dependency.name;
				
			} else if (Path.extension (dependency.path) == "framework") {
				
				name = Path.withoutDirectory (dependency.path);
				path = PathHelper.tryFullPath (dependency.path);
				
			}
			
			if (name != null) {
				
				var frameworkID = "11C0000000000018" + StringHelper.getUniqueID ();
				var fileID = "11C0000000000018" + StringHelper.getUniqueID ();
				
				ArrayHelper.addUnique (context.frameworkSearchPaths, Path.directory (path));
				
				context.ADDL_PBX_BUILD_FILE += "		" + frameworkID + " /* " + name + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + fileID + " /* " + name + " */; };\n";
				context.ADDL_PBX_FILE_REFERENCE += "		" + fileID + " /* " + name + " */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = \"" + name + "\"; path = \"" + path + "\"; sourceTree = SDKROOT; };\n";
				context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE += "				" + frameworkID + " /* " + name + " in Frameworks */,\n";
				context.ADDL_PBX_FRAMEWORK_GROUP += "				" + fileID + " /* " + name + " */,\n";
				
			}
			
		}
		
		context.HXML_PATH = PathHelper.findTemplate (project.templatePaths, "iphone/PROJ/haxe/Build.hxml");
		context.PRERENDERED_ICON = project.config.getBool ("ios.prerenderedIcon", false);
		
		/*var assets = new Array <Asset> ();
		
		for (asset in project.assets) {
			
			var newAsset = asset.clone ();
			
			assets.push ();
			
		}*/
		
		//updateIcon ();
		//updateLaunchImage ();
		
		return context;
		
	}
	
	
	public override function rebuild ():Void {
		
		var armv6 = (command == "rebuild" || (project.architectures.indexOf (Architecture.ARMV6) > -1 && !project.targetFlags.exists ("simulator")));
		var armv7 = (command == "rebuild" || (project.architectures.indexOf (Architecture.ARMV7) > -1 && !project.targetFlags.exists ("simulator")));
		var simulator = (command == "rebuild" || project.targetFlags.exists ("simulator"));
		
		var commands = [];
		
		if (armv6) commands.push ([ "-Diphoneos", "-DHXCPP_CPP11" ]);
		if (armv7) commands.push ([ "-Diphoneos", "-DHXCPP_CPP11", "-DHXCPP_ARMV7" ]);
		if (simulator) commands.push ([ "-Diphonesim", "-DHXCPP_CPP11" ]);
		
		CPPHelper.rebuild (project, commands);
		
	}
	
	
	public override function run ():Void {
		
		IOSHelper.launch (project, PathHelper.combine (project.app.path, "ios"));
		
	}
	
	
	public override function update ():Void {
		
		project = project.clone ();
		
		var manifest = new Asset ();
		manifest.id = "__manifest__";
		manifest.data = AssetHelper.createManifest (project);
		manifest.resourceName = manifest.flatName = manifest.targetPath = "manifest";
		manifest.type = AssetType.TEXT;
		project.assets.push (manifest);
		
		var context = generateContext ();
		
		var targetDirectory = PathHelper.combine (project.app.path, "ios");
		var projectDirectory = targetDirectory + "/" + project.app.file + "/";
		
		PathHelper.mkdir (targetDirectory);
		PathHelper.mkdir (projectDirectory);
		PathHelper.mkdir (projectDirectory + "/haxe");
		PathHelper.mkdir (projectDirectory + "/haxe/lime/installer");
		
		var iconNames = [ "Icon.png", "Icon@2x.png", "Icon-60.png", "Icon-60@2x.png", "Icon-72.png", "Icon-72@2x.png", "Icon-76.png", "Icon-76@2x.png" ];
		var iconSizes = [ 57, 114, 60, 120, 72, 144, 76, 152 ];
		
		context.HAS_ICON = true;
		
		for (i in 0...iconNames.length) {
			
			if (!IconHelper.createIcon (project.icons, iconSizes[i], iconSizes[i], PathHelper.combine (projectDirectory, iconNames[i]))) {
				
				context.HAS_ICON = false;
				
			}
			
		}
		
		var splashScreenNames = [];
		var splashScreenWidth = [];
		var splashScreenHeight = [];
		
		var portraitSupported = ! (project.window.orientation == LANDSCAPE);
		var landscapeSupported = ! (project.window.orientation == PORTRAIT);

		if (iPhoneSupported) {
			
			splashScreenNames = splashScreenNames.concat(["Default.png", "Default@2x.png", "Default-568h@2x.png"]);
			splashScreenWidth = splashScreenWidth.concat([320, 640, 640]);
			splashScreenHeight = splashScreenHeight.concat([480, 960, 1136]);
		
		}

		if (iPadSupported) {
			
			if (portraitSupported) { 

				splashScreenNames = splashScreenNames.concat(["Default-Portrait.png", "Default-Portrait@2x.png"]); 
				splashScreenWidth = splashScreenWidth.concat([768, 1536]);
				splashScreenHeight = splashScreenHeight.concat([1024, 2048]);
			
			}

			if (landscapeSupported) { 

				splashScreenNames = splashScreenNames.concat(["Default-Landscape.png", "Default-Landscape@2x.png"]); 
				splashScreenHeight = splashScreenHeight.concat([768, 1536]);
				splashScreenWidth = splashScreenWidth.concat([1024, 2048]);
			
			}
		
		}

		for (i in 0...splashScreenNames.length) {
			
			var width = splashScreenWidth[i];
			var height = splashScreenHeight[i];
			var match = false;

			for (splashScreen in project.splashScreens) {
				if (splashScreen.width == width && splashScreen.height == height && Path.extension (splashScreen.path) == "png") {
					var uniqueID = StringHelper.getUniqueID();
					var buildFileUDID = "1EF0A83A0000001D" + uniqueID;					
					var fileRefUDID =   "1EF0A83A0000001E" + uniqueID;					
					FileHelper.copyFile (splashScreen.path, PathHelper.combine (projectDirectory, splashScreenNames[i]));
					context.LAUNCH_IMAGES.push( { "name": splashScreenNames[i], "build_file_udid" : buildFileUDID, "file_ref_udid" : fileRefUDID } );	
					match = true;
				}
				
			}

		}

		context.HAS_LAUNCH_IMAGE = true;
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "iphone/PROJ/haxe", projectDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", projectDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "iphone/PROJ/Classes", projectDirectory + "/Classes", context);
		FileHelper.copyFileTemplate (project.templatePaths, "iphone/PROJ/PROJ-Entitlements.plist", projectDirectory + "/" + project.app.file + "-Entitlements.plist", context);
		FileHelper.copyFileTemplate (project.templatePaths, "iphone/PROJ/PROJ-Info.plist", projectDirectory + "/" + project.app.file + "-Info.plist", context);
		FileHelper.copyFileTemplate (project.templatePaths, "iphone/PROJ/PROJ-Prefix.pch", projectDirectory + "/" + project.app.file + "-Prefix.pch", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "iphone/PROJ.xcodeproj", targetDirectory + "/" + project.app.file + ".xcodeproj", context);
		
		//SWFHelper.generateSWFClasses (project, projectDirectory + "/haxe");
		
		PathHelper.mkdir (projectDirectory + "/lib");
		
		for (archID in 0...3) {
			
			var arch = [ "armv6", "armv7", "i386" ][archID];
			
			if (arch == "armv6" && !context.ARMV6)
				continue;
			
			if (arch == "armv7" && !context.ARMV7)
				continue;
			
			var libExt = [ ".iphoneos.a", ".iphoneos-v7.a", ".iphonesim.a" ][archID];
			
			PathHelper.mkdir (projectDirectory + "/lib/" + arch);
			PathHelper.mkdir (projectDirectory + "/lib/" + arch + "-debug");
			
			for (ndll in project.ndlls) {
				
				//if (ndll.haxelib != null) {
					
					var releaseLib = PathHelper.getLibraryPath (ndll, "iPhone", "lib", libExt);
					var debugLib = PathHelper.getLibraryPath (ndll, "iPhone", "lib", libExt, true);
					var releaseDest = projectDirectory + "/lib/" + arch + "/lib" + ndll.name + ".a";
					var debugDest = projectDirectory + "/lib/" + arch + "-debug/lib" + ndll.name + ".a";
					
					if (!FileSystem.exists (releaseLib)) {
						
						releaseLib = PathHelper.getLibraryPath (ndll, "IPhone", "lib", ".iphoneos.a");
						debugLib = PathHelper.getLibraryPath (ndll, "IPhone", "lib", ".iphoneos.a", true);
						
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
				
				var targetPath = projectDirectory + "/assets/" + asset.resourceName;
				//var sourceAssetPath:String = projectDirectory + "haxe/" + asset.sourcePath;
				
				PathHelper.mkdir (Path.directory (targetPath));
				FileHelper.copyAssetIfNewer (asset, targetPath);
				
				//PathHelper.mkdir (Path.directory (sourceAssetPath));
				//FileHelper.linkFile (flatAssetPath, sourceAssetPath, true, true);
				
			} else {
				
				PathHelper.mkdir (Path.directory (projectDirectory + "/" + asset.targetPath));
				FileHelper.copyAsset (asset, projectDirectory + "/" + asset.targetPath, context);
				
			}
			
		}
		
		if (project.command == "update" && PlatformHelper.hostPlatform == Platform.MAC) {
			
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
	
	
	@ignore public override function install ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}