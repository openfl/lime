package;

import hxp.ArrayTools;
import hxp.Haxelib;
import hxp.HXML;
import hxp.Log;
import hxp.Path;
import hxp.System;
import lime.tools.AndroidHelper;
import lime.tools.Architecture;
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.CPPHelper;
import lime.tools.DeploymentHelper;
import lime.tools.HXProject;
import lime.tools.Icon;
import lime.tools.IconHelper;
import lime.tools.PlatformTarget;
import lime.tools.ProjectHelper;
import sys.io.File;
import sys.FileSystem;

class AndroidPlatform extends PlatformTarget
{
	private var deviceID:String;

	public function new(command:String, _project:HXProject, targetFlags:Map<String, String>)
	{
		super(command, _project, targetFlags);

		if (command != "display" && command != "clean")
		{
			// project = project.clone ();

			if (!project.environment.exists("ANDROID_SETUP"))
			{
				Log.error("You need to run \"lime setup android\" before you can use the Android target");
			}

			AndroidHelper.initialize(project);

			if (deviceID == null && project.targetFlags.exists("device"))
			{
				deviceID = project.targetFlags.get("device") + ":5555";
			}
		}

		targetDirectory = Path.combine(project.app.path, project.config.getString("android.output-directory", "android"));
	}

	public override function build():Void
	{
		var destination = targetDirectory + "/bin";
		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";
		var sourceSet = destination + "/app/src/main";

		var hasARMV5 = (ArrayTools.containsValue(project.architectures, Architecture.ARMV5)
			|| ArrayTools.containsValue(project.architectures, Architecture.ARMV6));
		var hasARMV7 = ArrayTools.containsValue(project.architectures, Architecture.ARMV7);
		var hasARM64 = ArrayTools.containsValue(project.architectures, Architecture.ARM64);
		var hasX86 = ArrayTools.containsValue(project.architectures, Architecture.X86);
		var hasX64 = ArrayTools.containsValue(project.architectures, Architecture.X64);

		var architectures = [];

		if (hasARMV5) architectures.push(Architecture.ARMV5);
		if (hasARMV7 || (!hasARMV5 && !hasX86)) architectures.push(Architecture.ARMV7);
		if (hasARM64) architectures.push(Architecture.ARM64);
		if (hasX86) architectures.push(Architecture.X86);
		if (hasX64) architectures.push(Architecture.X64);

		for (architecture in architectures)
		{
			var haxeParams = [hxml, "-D", "android", "-D", "PLATFORM=android-16"];
			var cppParams = ["-Dandroid", "-DPLATFORM=android-16"];
			var path = sourceSet + "/jniLibs/armeabi";
			var suffix = ".so";

			if (architecture == Architecture.ARMV7)
			{
				haxeParams.push("-D");
				haxeParams.push("HXCPP_ARMV7");
				cppParams.push("-DHXCPP_ARMV7");
				path = sourceSet + "/jniLibs/armeabi-v7a";
				suffix = "-v7.so";
			}
			else if (architecture == Architecture.ARM64)
			{
				haxeParams = [hxml, "-D", "android", "-D", "PLATFORM=android-21"];
				cppParams = ["-Dandroid", "-DPLATFORM=android-21"];

				haxeParams.push("-D");
				haxeParams.push("HXCPP_ARM64");
				cppParams.push("-DHXCPP_ARM64");
				path = sourceSet + "/jniLibs/arm64-v8a";
				suffix = "-64.so";
			}
			else if (architecture == Architecture.X86)
			{
				haxeParams.push("-D");
				haxeParams.push("HXCPP_X86");
				cppParams.push("-DHXCPP_X86");
				path = sourceSet + "/jniLibs/x86";
				suffix = "-x86.so";
			}
			else if (architecture == Architecture.X64)
			{
				haxeParams = [hxml, "-D", "android", "-D", "PLATFORM=android-21"];
				cppParams = ["-Dandroid", "-DPLATFORM=android-21"];

				haxeParams.push("-D");
				haxeParams.push("HXCPP_X86_64");
				cppParams.push("-DHXCPP_X86_64");
				path = sourceSet + "/jniLibs/x86_64";
				suffix = "-x86_64.so";
			}

			for (ndll in project.ndlls)
			{
				ProjectHelper.copyLibrary(project, ndll, "Android", "lib", suffix, path, project.debug, ".so");
			}

			System.runCommand("", "haxe", haxeParams);

			if (noOutput) return;

			CPPHelper.compile(project, targetDirectory + "/obj", cppParams);

			System.copyIfNewer(targetDirectory + "/obj/libApplicationMain" + (project.debug ? "-debug" : "") + suffix, path + "/libApplicationMain.so");
		}

		if (!hasARMV5)
		{
			if (FileSystem.exists(sourceSet + "/jniLibs/armeabi"))
			{
				System.removeDirectory(sourceSet + "/jniLibs/armeabi");
			}
		}

		if (!hasARMV7)
		{
			if (FileSystem.exists(sourceSet + "/jniLibs/armeabi-v7a"))
			{
				System.removeDirectory(sourceSet + "/jniLibs/armeabi-v7a");
			}
		}

		if (!hasARM64)
		{
			if (FileSystem.exists(sourceSet + "/jniLibs/arm64-v8a"))
			{
				System.removeDirectory(sourceSet + "/jniLibs/arm64-v8a");
			}
		}

		if (!hasX86)
		{
			if (FileSystem.exists(sourceSet + "/jniLibs/x86"))
			{
				System.removeDirectory(sourceSet + "/jniLibs/x86");
			}
		}

		if (!hasX64)
		{
			if (FileSystem.exists(sourceSet + "/jniLibs/x86_64"))
			{
				System.removeDirectory(sourceSet + "/jniLibs/x86_64");
			}
		}

		if (noOutput) return;

		AndroidHelper.build(project, destination);
	}

	public override function clean():Void
	{
		if (FileSystem.exists(targetDirectory))
		{
			System.removeDirectory(targetDirectory);
		}
	}

	public override function deploy():Void
	{
		DeploymentHelper.deploy(project, targetFlags, targetDirectory, "Android");
	}

	public override function display():Void
	{
		if (project.targetFlags.exists("output-file"))
		{
			var build = "-debug";
			if (project.keystore != null)
			{
				build = "-release";
			}

			var outputDirectory = null;
			if (project.config.exists("android.gradle-build-directory"))
			{
				outputDirectory = Path.combine(project.config.getString("android.gradle-build-directory"), project.app.file + "/app/outputs/apk");
			}
			else
			{
				outputDirectory = Path.combine(FileSystem.fullPath(targetDirectory), "bin/app/build/outputs/apk");
			}

			Sys.println(Path.combine(outputDirectory, project.app.file + build + ".apk"));
		}
		else
		{
			Sys.println(getDisplayHXML().toString());
		}
	}

	private function getDisplayHXML():HXML
	{
		var path = targetDirectory + "/haxe/" + buildType + ".hxml";

		if (FileSystem.exists(path))
		{
			return File.getContent(path);
		}
		else
		{
			var context = project.templateContext;
			var hxml = HXML.fromString(context.HAXE_FLAGS);
			hxml.addClassName(context.APP_MAIN);
			hxml.cpp = "_";
			hxml.noOutput = true;
			return hxml;
		}
	}

	public override function install():Void
	{
		var build = "debug";

		if (project.keystore != null)
		{
			build = "release";
		}

		if (project.environment.exists("ANDROID_GRADLE_TASK"))
		{
			var task = project.environment.get("ANDROID_GRADLE_TASK");
			if (task == "assembleDebug")
			{
				build = "debug";
			}
			else
			{
				build = "release";
			}
		}

		var outputDirectory = null;

		if (project.config.exists("android.gradle-build-directory"))
		{
			outputDirectory = Path.combine(project.config.getString("android.gradle-build-directory"), project.app.file + "/app/outputs/apk/" + build);
		}
		else
		{
			outputDirectory = Path.combine(FileSystem.fullPath(targetDirectory), "bin/app/build/outputs/apk/" + build);
		}

		var apkPath = Path.combine(outputDirectory, project.app.file + "-" + build + ".apk");

		deviceID = AndroidHelper.install(project, apkPath, deviceID);
	}

	public override function rebuild():Void
	{
		var armv5 = (command == "rebuild"
			|| ArrayTools.containsValue(project.architectures, Architecture.ARMV5)
			|| ArrayTools.containsValue(project.architectures, Architecture.ARMV6));
		var armv7 = (command == "rebuild" || ArrayTools.containsValue(project.architectures, Architecture.ARMV7));
		var arm64 = (command == "rebuild" || ArrayTools.containsValue(project.architectures, Architecture.ARM64));
		var x86 = (command == "rebuild" || ArrayTools.containsValue(project.architectures, Architecture.X86));
		var x64 = (/*command == "rebuild" ||*/ ArrayTools.containsValue(project.architectures, Architecture.X64));

		var commands = [];

		if (armv5) commands.push(["-Dandroid", "-DPLATFORM=android-16"]);
		if (armv7) commands.push(["-Dandroid", "-DHXCPP_ARMV7", "-DHXCPP_ARM7", "-DPLATFORM=android-16"]);
		if (arm64) commands.push(["-Dandroid", "-DHXCPP_ARM64", "-DPLATFORM=android-21"]);
		if (x86) commands.push(["-Dandroid", "-DHXCPP_X86", "-DPLATFORM=android-16"]);
		if (x64) commands.push(["-Dandroid", "-DHXCPP_X86_64", "-DPLATFORM=android-21"]);

		CPPHelper.rebuild(project, commands);
	}

	public override function run():Void
	{
		AndroidHelper.run(project.meta.packageName + "/" + project.meta.packageName + ".MainActivity", deviceID);
	}

	public override function trace():Void
	{
		AndroidHelper.trace(project, project.debug, deviceID);
	}

	public override function uninstall():Void
	{
		AndroidHelper.uninstall(project.meta.packageName, deviceID);
	}

	public override function update():Void
	{
		AssetHelper.processLibraries(project, targetDirectory);

		// project = project.clone ();

		for (asset in project.assets)
		{
			if (asset.embed && asset.sourcePath == "")
			{
				var path = Path.combine(targetDirectory + "/obj/tmp", asset.targetPath);
				System.mkdir(Path.directory(path));
				AssetHelper.copyAsset(asset, path);
				asset.sourcePath = path;
			}
		}

		// initialize (project);

		var destination = targetDirectory + "/bin";
		var sourceSet = destination + "/app/src/main";
		System.mkdir(sourceSet);
		System.mkdir(sourceSet + "/res/drawable-ldpi/");
		System.mkdir(sourceSet + "/res/drawable-mdpi/");
		System.mkdir(sourceSet + "/res/drawable-hdpi/");
		System.mkdir(sourceSet + "/res/drawable-xhdpi/");

		for (asset in project.assets)
		{
			if (asset.type != AssetType.TEMPLATE)
			{
				var targetPath = "";

				switch (asset.type)
				{
					default:
						// case SOUND, MUSIC:

						// var extension = Path.extension (asset.sourcePath);
						// asset.flatName += ((extension != "") ? "." + extension : "");

						// asset.resourceName = asset.flatName;
						targetPath = Path.combine(sourceSet + "/assets/", asset.resourceName);

						// asset.resourceName = asset.id;
						// targetPath = sourceSet + "/res/raw/" + asset.flatName + "." + Path.extension (asset.targetPath);

						// default:

						// asset.resourceName = asset.flatName;
						// targetPath = sourceSet + "/assets/" + asset.resourceName;
				}

				AssetHelper.copyAssetIfNewer(asset, targetPath);
			}
		}

		if (project.targetFlags.exists("xml"))
		{
			project.haxeflags.push("-xml " + targetDirectory + "/types.xml");
		}

		var context = project.templateContext;

		context.CPP_DIR = targetDirectory + "/obj";
		context.OUTPUT_DIR = targetDirectory;
		context.ANDROID_INSTALL_LOCATION = project.config.getString("android.install-location", "auto");
		context.ANDROID_MINIMUM_SDK_VERSION = project.config.getInt("android.minimum-sdk-version", 16);
		context.ANDROID_TARGET_SDK_VERSION = project.config.getInt("android.target-sdk-version", 28);
		context.ANDROID_EXTENSIONS = project.config.getArrayString("android.extension");
		context.ANDROID_PERMISSIONS = project.config.getArrayString("android.permission", [
			"android.permission.WAKE_LOCK",
			"android.permission.INTERNET",
			"android.permission.VIBRATE",
			"android.permission.ACCESS_NETWORK_STATE"
		]);
		context.ANDROID_GRADLE_VERSION = project.config.getString("android.gradle-version", "5.6.3");
		context.ANDROID_GRADLE_PLUGIN = project.config.getString("android.gradle-plugin", "3.5.1");

		context.ANDROID_LIBRARY_PROJECTS = [];

		if (!project.environment.exists("ANDROID_SDK") || !project.environment.exists("ANDROID_NDK_ROOT"))
		{
			var command = #if lime "lime" #else "hxp" #end;
			var toolsBase = Type.resolveClass("CommandLineTools");
			if (toolsBase != null) command = Reflect.field(toolsBase, "commandName");

			Log.error("You must define ANDROID_SDK and ANDROID_NDK_ROOT to target Android, please run '" + command + " setup android' first");
			Sys.exit(1);
		}

		if (project.config.exists("android.gradle-build-directory"))
		{
			context.ANDROID_GRADLE_BUILD_DIRECTORY = project.config.getString("android.gradle-build-directory");
		}

		if (project.config.exists("android.build-tools-version"))
		{
			context.ANDROID_BUILD_TOOLS_VERSION = project.config.getString("android.build-tools-version");
		}
		else
		{
			context.ANDROID_BUILD_TOOLS_VERSION = AndroidHelper.getBuildToolsVersion(project);
		}

		var escaped = ~/([ #!=\\:])/g;
		context.ANDROID_SDK_ESCAPED = escaped.replace(context.ENV_ANDROID_SDK, "\\$1");
		context.ANDROID_NDK_ROOT_ESCAPED = escaped.replace(context.ENV_ANDROID_NDK_ROOT, "\\$1");

		if (Reflect.hasField(context, "KEY_STORE")) context.KEY_STORE = StringTools.replace(context.KEY_STORE, "\\", "\\\\");
		if (Reflect.hasField(context, "KEY_STORE_ALIAS")) context.KEY_STORE_ALIAS = StringTools.replace(context.KEY_STORE_ALIAS, "\\", "\\\\");
		if (Reflect.hasField(context, "KEY_STORE_PASSWORD")) context.KEY_STORE_PASSWORD = StringTools.replace(context.KEY_STORE_PASSWORD, "\\", "\\\\");
		if (Reflect.hasField(context,
			"KEY_STORE_ALIAS_PASSWORD")) context.KEY_STORE_ALIAS_PASSWORD = StringTools.replace(context.KEY_STORE_ALIAS_PASSWORD, "\\", "\\\\");

		var index = 1;

		for (dependency in project.dependencies)
		{
			if (dependency.path != ""
				&& FileSystem.exists(dependency.path)
				&& FileSystem.isDirectory(dependency.path)
				&& (FileSystem.exists(Path.combine(dependency.path, "project.properties"))
					|| FileSystem.exists(Path.combine(dependency.path, "build.gradle"))))
			{
				var name = dependency.name;
				if (name == "") name = "project" + index;

				context.ANDROID_LIBRARY_PROJECTS.push(
					{
						name: name,
						index: index,
						path: "deps/" + name,
						source: dependency.path
					});
				index++;
			}
		}

		var iconTypes = ["ldpi", "mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"];
		var iconSizes = [36, 48, 72, 96, 144, 192];
		var icons = project.icons;

		if (icons.length == 0)
		{
			icons = [new Icon(System.findTemplate(project.templatePaths, "default/icon.svg"))];
		}

		for (i in 0...iconTypes.length)
		{
			if (IconHelper.createIcon(icons, iconSizes[i], iconSizes[i], sourceSet + "/res/drawable-" + iconTypes[i] + "/icon.png"))
			{
				context.HAS_ICON = true;
			}
		}

		IconHelper.createIcon(icons, 732, 412, sourceSet + "/res/drawable-xhdpi/ouya_icon.png");

		var packageDirectory = project.meta.packageName;
		packageDirectory = sourceSet + "/java/" + packageDirectory.split(".").join("/");
		System.mkdir(packageDirectory);

		for (javaPath in project.javaPaths)
		{
			try
			{
				if (FileSystem.isDirectory(javaPath))
				{
					System.recursiveCopy(javaPath, sourceSet + "/java", context, true);
				}
				else
				{
					if (Path.extension(javaPath) == "jar")
					{
						System.copyIfNewer(javaPath, destination + "/app/libs/" + Path.withoutDirectory(javaPath));
					}
					else
					{
						System.copyIfNewer(javaPath, sourceSet + "/java/" + Path.withoutDirectory(javaPath));
					}
				}
			}
			catch (e:Dynamic) {}

			//	throw"Could not find javaPath " + javaPath +" required by extension.";

			// }
		}

		for (library in cast(context.ANDROID_LIBRARY_PROJECTS, Array<Dynamic>))
		{
			System.recursiveCopy(library.source, destination + "/deps/" + library.name, context, true);
		}

		ProjectHelper.recursiveSmartCopyTemplate(project, "android/template", destination, context);
		System.copyFileTemplate(project.templatePaths, "android/MainActivity.java", packageDirectory + "/MainActivity.java", context);
		ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", targetDirectory + "/haxe", context);
		ProjectHelper.recursiveSmartCopyTemplate(project, "android/hxml", targetDirectory + "/haxe", context);

		for (asset in project.assets)
		{
			if (asset.type == AssetType.TEMPLATE)
			{
				var targetPath = Path.combine(destination, asset.targetPath);
				System.mkdir(Path.directory(targetPath));
				AssetHelper.copyAsset(asset, targetPath, context);
			}
		}
	}

	public override function watch():Void
	{
		var hxml = getDisplayHXML();
		var dirs = hxml.getClassPaths(true);

		var outputPath = Path.combine(Sys.getCwd(), project.app.path);
		dirs = dirs.filter(function(dir)
		{
			return (!Path.startsWith(dir, outputPath));
		});

		var command = ProjectHelper.getCurrentCommand();
		System.watch(command, dirs);
	}
}
