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
import sys.io.File;
import sys.FileSystem;

class AndroidPlatform implements IPlatformTool {
	
	
	private var deviceID:String;
	
	
	public function build (project:HXProject):Void {
		
		initialize (project);
		
		var destination = project.app.path + "/android/bin";
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = project.app.path + "/android/haxe/" + type + ".hxml";
		
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
			var path = project.app.path + "/android/bin/libs/armeabi/libApplicationMain.so";
			var suffix = "";
			
			if (architecture == Architecture.ARMV7) {
				
				haxeParams.push ("-D");
				haxeParams.push ("HXCPP_ARMV7");
				cppParams.push ("-DHXCPP_ARMV7");
				
				if (hasARMV5) {
					
					path = project.app.path + "/android/bin/libs/armeabi-v7/libApplicationMain.so";
					
				}
				
				suffix = "-v7";
				
			} else if (architecture == Architecture.X86) {
				
				haxeParams.push ("-D");
				haxeParams.push ("HXCPP_X86");
				cppParams.push ("-DHXCPP_X86");
				path = project.app.path + "/android/bin/libs/x86/libApplicationMain.so";
				suffix = "-x86";
				
			}
			
			ProcessHelper.runCommand ("", "haxe", haxeParams);
			CPPHelper.compile (project, project.app.path + "/android/obj", cppParams);
			
			FileHelper.copyIfNewer (project.app.path + "/android/obj/libApplicationMain" + (project.debug ? "-debug" : "") + suffix + ".so", path);
			
		}
		
		if (!ArrayHelper.containsValue (project.architectures, Architecture.ARMV7) || !hasARMV5) {
			
			if (FileSystem.exists (project.app.path + "/android/bin/libs/armeabi-v7")) {
				
				PathHelper.removeDirectory (project.app.path + "/android/bin/libs/armeabi-v7");
				
			}
			
		}
		
		if (!hasX86) {
			
			if (FileSystem.exists (project.app.path + "/android/bin/libs/x86")) {
				
				PathHelper.removeDirectory (project.app.path + "/android/bin/libs/x86");
				
			}
			
		}
		
		AndroidHelper.build (project, destination);
		
	}
	
	
	public function clean (project:HXProject):Void {
		
		var targetPath = project.app.path + "/android";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public function display (project:HXProject):Void {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "android/hxml/" + (project.debug ? "debug" : "release") + ".hxml");
		
		var context = project.templateContext;
		context.CPP_DIR = project.app.path + "/android/obj";
		
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (context));
		
	}
	
	
	public function install (project:HXProject):Void {
		
		initialize (project);
		
		var build = "debug";
		
		if (project.certificate != null) {
			
			build = "release";
			
		}
		
		deviceID = AndroidHelper.install (project, FileSystem.fullPath (project.app.path) + "/android/bin/bin/" + project.app.file + "-" + build + ".apk", deviceID);
		
   }
	
	
	private function initialize (project:HXProject):Void {
		
		if (!project.environment.exists ("ANDROID_SETUP")) {
			
			LogHelper.error ("You need to run \"lime setup android\" before you can use the Android target");
			
		}
		
		AndroidHelper.initialize (project);
		
		if (deviceID == null && project.targetFlags.exists ("device")) {
			
			deviceID = project.targetFlags.get ("device") + ":5555";
			
		}
		
	}
	
	
	public function run (project:HXProject, arguments:Array <String>):Void {
		
		initialize (project);
		
		AndroidHelper.run (project.meta.packageName + "/" + project.meta.packageName + ".MainActivity", deviceID);
		
	}
	
	
	public function trace (project:HXProject):Void {
		
		initialize (project);
		
		AndroidHelper.trace (project, project.debug, deviceID);
		
	}
	
	
	public function uninstall (project:HXProject):Void {
		
		initialize (project);
		
		AndroidHelper.uninstall (project.meta.packageName, deviceID);
		
	}
	
	
	public function update (project:HXProject):Void {
		
		project = project.clone ();
		
		initialize (project);
		
		var destination = project.app.path + "/android/bin/";
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
						targetPath = destination + "/assets/" + asset.resourceName;
						
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
			
			project.haxeflags.push ("-xml " + project.app.path + "/android/types.xml");
			
		}
		
		var context = project.templateContext;
		
		context.CPP_DIR = project.app.path + "/android/obj";
		context.ANDROID_INSTALL_LOCATION = project.config.android.installLocation;
		context.ANDROID_MINIMUM_SDK_VERSION = project.config.android.minimumSDKVersion;
		context.ANDROID_TARGET_SDK_VERSION = project.config.android.targetSDKVersion;
		context.ANDROID_EXTENSIONS = project.config.android.extensions;
		context.ANDROID_PERMISSIONS = project.config.android.permissions;
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
		
		var iconTypes = [ "ldpi", "mdpi", "hdpi", "xhdpi" ];
		var iconSizes = [ 36, 48, 72, 96 ];
		
		for (i in 0...iconTypes.length) {
			
			if (IconHelper.createIcon (project.icons, iconSizes[i], iconSizes[i], destination + "/res/drawable-" + iconTypes[i] + "/icon.png")) {
				
				context.HAS_ICON = true;
				
			}
			
		}
		
		IconHelper.createIcon (project.icons, 732, 412, destination + "/res/drawable-xhdpi/ouya_icon.png");
		
		var packageDirectory = project.meta.packageName;
		packageDirectory = destination + "/src/" + packageDirectory.split (".").join ("/");
		PathHelper.mkdir (packageDirectory);
		
		//SWFHelper.generateSWFClasses (project, project.app.path + "/android/haxe");
		
		var armv5 = ArrayHelper.containsValue (project.architectures, Architecture.ARMV5) || ArrayHelper.containsValue (project.architectures, Architecture.ARMV6);
		var armv7 = ArrayHelper.containsValue (project.architectures, Architecture.ARMV7);
		
		for (ndll in project.ndlls) {
			
			if (armv5) {
				
				FileHelper.copyLibrary (project, ndll, "Android", "lib", ".so", destination + "/libs/armeabi", project.debug);
				
			}
			
			if (armv7) {
				
				if (armv5) {
					
					FileHelper.copyLibrary (project, ndll, "Android", "lib", "-v7.so", destination + "/libs/armeabi-v7a", project.debug, ".so");
					
				} else {
					
					FileHelper.copyLibrary (project, ndll, "Android", "lib", "-v7.so", destination + "/libs/armeabi", project.debug, ".so");
					
				}
				
			}
			
		}
		
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
		FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", project.app.path + "/android/haxe", context);
		FileHelper.recursiveCopyTemplate (project.templatePaths, "android/hxml", project.app.path + "/android/haxe", context);
		
		for (asset in project.assets) {
			
			if (asset.type == AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (destination + asset.targetPath));
				FileHelper.copyAsset (asset, destination + asset.targetPath, context);
				
			}
			
		}
		
		AssetHelper.createManifest (project, destination + "/assets/manifest");
		
	}
	
	
	public function new () {}
	
	
}
