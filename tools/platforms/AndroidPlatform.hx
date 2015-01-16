package platforms;


import haxe.io.Path;
import haxe.Template;
import helpers.AndroidHelper;
import helpers.ArrayHelper;
import helpers.AssetHelper;
import helpers.CPPHelper;
import helpers.FileHelper;
import helpers.IconHelper;
import helpers.LogHelper;
import helpers.PathHelper;
import helpers.ProcessHelper;
import project.Architecture;
import project.AssetType;
import project.HXProject;
import project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class AndroidPlatform extends PlatformTarget {
	
	
	private var deviceID:String;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String>) {
		
		super (command, _project, targetFlags);
		
		if (command != "display" && command != "clean") {
			
			project = project.clone ();
			
			if (!project.environment.exists ("ANDROID_SETUP")) {
				
				LogHelper.error ("You need to run \"lime setup android\" before you can use the Android target");
				
			}
			
			AndroidHelper.initialize (project);
			
			if (deviceID == null && project.targetFlags.exists ("device")) {
				
				deviceID = project.targetFlags.get ("device") + ":5555";
				
			}
			
		}
		
		targetDirectory = project.app.path + "/android";
		
	}
	
	
	public override function build ():Void {
		
		var destination = targetDirectory + "/bin";
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = targetDirectory + "/haxe/" + type + ".hxml";
		
		var hasARMV5 = (ArrayHelper.containsValue (project.architectures, Architecture.ARMV5) || ArrayHelper.containsValue (project.architectures, Architecture.ARMV6));
		var hasARMV7 = ArrayHelper.containsValue (project.architectures, Architecture.ARMV7);
		var hasX86 = ArrayHelper.containsValue (project.architectures, Architecture.X86);
		
		var architectures = [];
		
		if (hasARMV5) architectures.push (Architecture.ARMV5);
		if (hasARMV7 || (!hasARMV5 && !hasX86)) architectures.push (Architecture.ARMV7);
		if (hasX86) architectures.push (Architecture.X86);
		
		for (architecture in architectures) {
			
			var haxeParams = [ hxml, "-D", "android", "-D", "android-9" ];
			var cppParams = [ "-Dandroid", "-Dandroid-9" ];
			var path = targetDirectory + "/bin/libs/armeabi";
			var suffix = ".so";
			
			if (architecture == Architecture.ARMV7) {
				
				haxeParams.push ("-D");
				haxeParams.push ("HXCPP_ARMV7");
				cppParams.push ("-DHXCPP_ARMV7");
				
				if (hasARMV5) {
					
					path = targetDirectory + "/bin/libs/armeabi-v7";
					
				}
				
				suffix = "-v7.so";
				
			} else if (architecture == Architecture.X86) {
				
				haxeParams.push ("-D");
				haxeParams.push ("HXCPP_X86");
				cppParams.push ("-DHXCPP_X86");
				path = targetDirectory + "/bin/libs/x86";
				suffix = "-x86.so";
				
			}
			
			for (ndll in project.ndlls) {
				
				FileHelper.copyLibrary (project, ndll, "Android", "lib", suffix, path, project.debug, ".so");
				
			}
			
			ProcessHelper.runCommand ("", "haxe", haxeParams);
			CPPHelper.compile (project, targetDirectory + "/obj", cppParams);
			
			FileHelper.copyIfNewer (targetDirectory + "/obj/libApplicationMain" + (project.debug ? "-debug" : "") + suffix, path + "/libApplicationMain.so");
			
		}
		
		if (!ArrayHelper.containsValue (project.architectures, Architecture.ARMV7) || !hasARMV5) {
			
			if (FileSystem.exists (targetDirectory + "/bin/libs/armeabi-v7")) {
				
				PathHelper.removeDirectory (targetDirectory + "/bin/libs/armeabi-v7");
				
			}
			
		}
		
		if (!hasX86) {
			
			if (FileSystem.exists (targetDirectory + "/bin/libs/x86")) {
				
				PathHelper.removeDirectory (targetDirectory + "/bin/libs/x86");
				
			}
			
		}
		
		AndroidHelper.build (project, destination);
		
	}
	
	
	public override function clean ():Void {
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function display ():Void {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "android/hxml/" + (project.debug ? "debug" : "release") + ".hxml");
		
		var context = project.templateContext;
		context.CPP_DIR = targetDirectory + "/obj";
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	public override function install ():Void {
		
		var build = "debug";
		
		if (project.certificate != null) {
			
			build = "release";
			
		}
		
		deviceID = AndroidHelper.install (project, FileSystem.fullPath (targetDirectory) + "/bin/bin/" + project.app.file + "-" + build + ".apk", deviceID);
		
	}
	
	
	public override function rebuild ():Void {
		
		var armv5 = (command == "rebuild" || ArrayHelper.containsValue (project.architectures, Architecture.ARMV5) || ArrayHelper.containsValue (project.architectures, Architecture.ARMV6));
		var armv7 = (command == "rebuild" || ArrayHelper.containsValue (project.architectures, Architecture.ARMV7));
		var x86 = (command == "rebuild" || ArrayHelper.containsValue (project.architectures, Architecture.X86));
		
		var commands = [];
		
		if (armv5) commands.push ([ "-Dandroid", "-DPLATFORM=android-9" ]);
		if (armv7) commands.push ([ "-Dandroid", "-DHXCPP_ARMV7", "-DHXCPP_ARM7", "-DPLATFORM=android-9" ]);
		if (x86) commands.push ([ "-Dandroid", "-DHXCPP_X86", "-DPLATFORM=android-9" ]);
		
		CPPHelper.rebuild (project, commands);
		
	}
	
	
	public override function run ():Void {
		
		AndroidHelper.run (project.meta.packageName + "/" + project.meta.packageName + ".MainActivity", deviceID);
		
	}
	
	
	public override function trace ():Void {
		
		AndroidHelper.trace (project, project.debug, deviceID);
		
	}
	
	
	public override function uninstall ():Void {
		
		AndroidHelper.uninstall (project.meta.packageName, deviceID);
		
	}
	
	
	public override function update ():Void {
		
		//project = project.clone ();
		
		//initialize (project);
		
		var destination = targetDirectory + "/bin/";
		PathHelper.mkdir (destination);
		PathHelper.mkdir (destination + "/res/drawable-ldpi/");
		PathHelper.mkdir (destination + "/res/drawable-mdpi/");
		PathHelper.mkdir (destination + "/res/drawable-hdpi/");
		PathHelper.mkdir (destination + "/res/drawable-xhdpi/");
		
		for (asset in project.assets) {
			
			if (asset.type != AssetType.TEMPLATE) {
				
				var targetPath = "";
				
				switch (asset.type) {
					
					default:
					//case SOUND, MUSIC:
						
						//var extension = Path.extension (asset.sourcePath);
						//asset.flatName += ((extension != "") ? "." + extension : "");
						
						//asset.resourceName = asset.flatName;
						targetPath = PathHelper.combine (destination + "/assets/", asset.resourceName);
						
						//asset.resourceName = asset.id;
						//targetPath = destination + "/res/raw/" + asset.flatName + "." + Path.extension (asset.targetPath);
					
					//default:
						
						//asset.resourceName = asset.flatName;
						//targetPath = destination + "/assets/" + asset.resourceName;
					
				}
				
				FileHelper.copyAssetIfNewer (asset, targetPath);
				
			}
			
		}
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		var context = project.templateContext;
		
		context.CPP_DIR = targetDirectory + "/obj";
		context.ANDROID_INSTALL_LOCATION = project.config.getString ("android.install-location", "preferExternal");
		context.ANDROID_MINIMUM_SDK_VERSION = project.config.getInt ("android.minimum-sdk-version", 9);
		context.ANDROID_TARGET_SDK_VERSION = project.config.getInt ("android.target-sdk-version", 16);
		context.ANDROID_EXTENSIONS = project.config.getArrayString ("android.extension");
		context.ANDROID_PERMISSIONS = project.config.getArrayString ("android.permission", [ "android.permission.WAKE_LOCK", "android.permission.INTERNET", "android.permission.VIBRATE", "android.permission.ACCESS_NETWORK_STATE" ]);
		context.ANDROID_LIBRARY_PROJECTS = [];
		
		if (Reflect.hasField (context, "KEY_STORE")) context.KEY_STORE = StringTools.replace (context.KEY_STORE, "\\", "\\\\");
		if (Reflect.hasField (context, "KEY_STORE_ALIAS")) context.KEY_STORE_ALIAS = StringTools.replace (context.KEY_STORE_ALIAS, "\\", "\\\\");
		if (Reflect.hasField (context, "KEY_STORE_PASSWORD")) context.KEY_STORE_PASSWORD = StringTools.replace (context.KEY_STORE_PASSWORD, "\\", "\\\\");
		if (Reflect.hasField (context, "KEY_STORE_ALIAS_PASSWORD")) context.KEY_STORE_ALIAS_PASSWORD = StringTools.replace (context.KEY_STORE_ALIAS_PASSWORD, "\\", "\\\\");
		
		var index = 1;
		
		for (dependency in project.dependencies) {
			
			if (dependency.path != "" && FileSystem.isDirectory (dependency.path) && FileSystem.exists (PathHelper.combine (dependency.path, "project.properties"))) {
				
				var name = dependency.name;
				if (name == "") name = "project" + index;
				
				context.ANDROID_LIBRARY_PROJECTS.push ({ name: name, index: index, path: "deps/" + name, source: dependency.path });
				index++;
				
			}
			
		}
		
		var iconTypes = [ "ldpi", "mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi" ];
		var iconSizes = [ 36, 48, 72, 96, 144, 192 ];
		
		for (i in 0...iconTypes.length) {
			
			if (IconHelper.createIcon (project.icons, iconSizes[i], iconSizes[i], destination + "/res/drawable-" + iconTypes[i] + "/icon.png")) {
				
				context.HAS_ICON = true;
				
			}
			
		}
		
		IconHelper.createIcon (project.icons, 732, 412, destination + "/res/drawable-xhdpi/ouya_icon.png");
		
		var packageDirectory = project.meta.packageName;
		packageDirectory = destination + "/src/" + packageDirectory.split (".").join ("/");
		PathHelper.mkdir (packageDirectory);
		
		for (javaPath in project.javaPaths) {
			
			try {
				
				if (FileSystem.isDirectory (javaPath)) {
					
					FileHelper.recursiveCopy (javaPath, destination + "/src", context, true);
					
				} else {
					
					if (Path.extension (javaPath) == "jar") {
						
						FileHelper.copyIfNewer (javaPath, destination + "/libs/" + Path.withoutDirectory (javaPath));
						
					} else {
						
						FileHelper.copyIfNewer (javaPath, destination + "/src/" + Path.withoutDirectory (javaPath));
						
					}
					
				}
				
			} catch (e:Dynamic) {}
				
			//	throw"Could not find javaPath " + javaPath +" required by extension."; 
				
			//}
			
		}
		
		for (library in context.ANDROID_LIBRARY_PROJECTS) {
			
			FileHelper.recursiveCopy (library.source, destination + "/deps/" + library.name, context, true);
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "android/template", destination, context);
		FileHelper.copyFileTemplate (project.templatePaths, "android/MainActivity.java", packageDirectory + "/MainActivity.java", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "android/hxml", targetDirectory + "/haxe", context);
		
		for (asset in project.assets) {
			
			if (asset.type == AssetType.TEMPLATE) {
				
				var targetPath = PathHelper.combine (destination, asset.targetPath);
				PathHelper.mkdir (Path.directory (targetPath));
				FileHelper.copyAsset (asset, targetPath, context);
				
			}
			
		}
		
		AssetHelper.createManifest (project, destination + "/assets/manifest");
		
	}
	
	
}