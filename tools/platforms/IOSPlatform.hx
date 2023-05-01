package;

import haxe.Json;
import hxp.ArrayTools;
import hxp.Haxelib;
import hxp.HXML;
import hxp.Log;
import hxp.NDLL;
import hxp.Path;
import hxp.StringTools;
import hxp.System;
#if lime
import lime.graphics.Image;
#end
import lime.tools.Architecture;
import lime.tools.Asset;
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.CPPHelper;
import lime.tools.DeploymentHelper;
import lime.tools.HXProject;
import lime.tools.Icon;
import lime.tools.IconHelper;
import lime.tools.ImageHelper;
import lime.tools.IOSHelper;
import lime.tools.Keystore;
import lime.tools.LaunchStoryboard;
import lime.tools.Orientation;
import lime.tools.Platform;
import lime.tools.PlatformTarget;
import lime.tools.ProjectHelper;
import sys.io.File;
import sys.FileSystem;

class IOSPlatform extends PlatformTarget
{
	public function new(command:String, _project:HXProject, targetFlags:Map<String, String>)
	{
		super(command, _project, targetFlags);

		var defaults = new HXProject();

		defaults.meta =
			{
				title: "MyApplication",
				description: "",
				packageName: "com.example.myapp",
				version: "1.0.0",
				company: "",
				companyUrl: "",
				buildNumber: null,
				companyId: ""
			};

		defaults.app =
			{
				main: "Main",
				file: "MyApplication",
				path: "bin",
				preloader: "",
				swfVersion: 17,
				url: "",
				init: null
			};

		defaults.window =
			{
				width: 800,
				height: 600,
				parameters: "{}",
				background: 0xFFFFFF,
				fps: 30,
				hardware: true,
				display: 0,
				resizable: true,
				borderless: false,
				orientation: Orientation.AUTO,
				vsync: false,
				fullscreen: false,
				allowHighDPI: true,
				alwaysOnTop: false,
				antialiasing: 0,
				allowShaders: true,
				requireShaders: false,
				depthBuffer: true,
				stencilBuffer: true,
				colorDepth: 32,
				maximized: false,
				minimized: false,
				hidden: false,
				title: ""
			};

		defaults.architectures = [Architecture.ARMV7, Architecture.ARM64];
		defaults.window.width = 0;
		defaults.window.height = 0;
		defaults.window.fullscreen = true;
		defaults.window.requireShaders = true;

		for (i in 1...project.windows.length)
		{
			defaults.windows.push(defaults.window);
		}

		defaults.merge(project);
		project = defaults;

		for (excludeArchitecture in project.excludeArchitectures)
		{
			project.architectures.remove(excludeArchitecture);
		}

		targetDirectory = Path.combine(project.app.path, project.config.getString("ios.output-directory", "ios"));
	}

	public override function build():Void
	{
		if (project.targetFlags.exists("xcode") && System.hostPlatform == MAC)
		{
			System.runCommand("", "open", [targetDirectory + "/" + project.app.file + ".xcodeproj"]);
		}
		else
		{
			IOSHelper.build(project, targetDirectory);

			if (noOutput) return;

			if (!project.targetFlags.exists("simulator"))
			{
				IOSHelper.sign(project, targetDirectory + "/bin");
			}
		}
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
		IOSHelper.deploy(project, targetDirectory);
	}

	public override function display():Void
	{
		if (project.targetFlags.exists("output-file"))
		{
			Sys.println(Path.combine(targetDirectory, project.app.file + ".xcodeproj"));
		}
		else
		{
			Sys.println(getDisplayHXML().toString());
		}
	}

	private function generateContext():Dynamic
	{
		// project = project.clone ();

		project.sources.unshift("");
		project.sources = Path.relocatePaths(project.sources, Path.combine(targetDirectory, project.app.file + "/haxe"));
		// project.dependencies.push ("stdc++");

		if (project.targetFlags.exists("xml"))
		{
			project.haxeflags.push("-xml " + targetDirectory + "/types.xml");
		}

		if (project.targetFlags.exists("final"))
		{
			project.haxedefs.set("final", "");
		}

		if (!project.config.exists("ios.identity"))
		{
			project.config.set("ios.identity", "iPhone Developer");
		}

		IOSHelper.getIOSVersion(project);
		project.haxedefs.set("IPHONE_VER", project.environment.get("IPHONE_VER"));

		project.haxedefs.set("HXCPP_CPP11", "1");

		if (project.config.getString("ios.compiler") == "llvm" || project.config.getString("ios.compiler", "clang") == "clang")
		{
			project.haxedefs.set("HXCPP_CLANG", "1");
			project.haxedefs.set("OBJC_ARC", "1");
		}

		var context = project.templateContext;

		context.HAS_ICON = false;
		context.HAS_LAUNCH_IMAGE = false;
		context.OBJC_ARC = false;
		context.KEY_STORE_IDENTITY = project.config.getString("ios.identity");

		if (project.config.exists("ios.provisioning-profile"))
		{
			context.IOS_PROVISIONING_PROFILE = Path.tryFullPath(project.config.getString("ios.provisioning-profile"));
		}

		if (project.config.exists("ios.team-id"))
		{
			context.DEVELOPMENT_TEAM_ID = project.config.getString("ios.team-id");
		}

		context.linkedLibraries = [];

		for (dependency in project.dependencies)
		{
			if (!StringTools.endsWith(dependency.name, ".framework")
				&& !StringTools.endsWith(dependency.name, ".tbd")
				&& !StringTools.endsWith(dependency.path, ".framework")
				&& !StringTools.endsWith(dependency.path, ".xcframework"))
			{
				if (dependency.path != "")
				{
					var name = Path.withoutDirectory(Path.withoutExtension(dependency.path));

					if (dependency.forceLoad)
					{
						project.config.push("ios.linker-flags",
							"-force_load $SRCROOT/$PRODUCT_NAME/lib/$CURRENT_ARCH/" + Path.withoutDirectory(dependency.path));
					}

					if (StringTools.startsWith(name, "lib"))
					{
						name = name.substring(3, name.length);
					}

					context.linkedLibraries.push(name);
				}
				else if (dependency.name != "")
				{
					context.linkedLibraries.push(dependency.name);
				}
			}
		}

		var valid_archs = new Array<String>();
		var armv6 = false;
		var armv7 = false;
		var armv7s = false;
		var arm64 = false;
		var architectures = project.architectures;

		if (architectures == null || architectures.length == 0)
		{
			architectures = [Architecture.ARMV7, Architecture.ARM64];
		}

		if (project.config.getString("ios.device", "universal") == "universal" || project.config.getString("ios.device") == "iphone")
		{
			if (project.config.getFloat("ios.deployment", 9) < 5)
			{
				ArrayTools.addUnique(architectures, Architecture.ARMV6);
			}
		}

		for (architecture in project.architectures)
		{
			switch (architecture)
			{
				case ARMV6:
					valid_archs.push("armv6");
					armv6 = true;
				case ARMV7:
					valid_archs.push("armv7");
					armv7 = true;
				case ARMV7S:
					valid_archs.push("armv7s");
					armv7s = true;
				case ARM64:
					valid_archs.push("arm64");
					arm64 = true;
				default:
			}
		}

		context.CURRENT_ARCHS = "( " + valid_archs.join(",") + ") ";

		valid_archs.push("x86_64");
		valid_archs.push("i386");

		context.VALID_ARCHS = valid_archs.join(" ");
		context.THUMB_SUPPORT = armv6 ? "GCC_THUMB_SUPPORT = NO;" : "";

		var requiredCapabilities = [];

		if (!armv6 && armv7)
		{
			requiredCapabilities.push({name: "armv7", value: true});
		}
		else if (!armv6 && !armv7 && armv7s)
		{
			requiredCapabilities.push({name: "armv7s", value: true});
		}
		else if (!armv6 && !armv7 && !armv7s && arm64)
		{
			requiredCapabilities.push({name: "arm64", value: true});
		}

		context.REQUIRED_CAPABILITY = requiredCapabilities;
		context.ARMV6 = armv6;
		context.ARMV7 = armv7;
		context.ARMV7S = armv7s;
		context.ARM64 = arm64;
		context.TARGET_DEVICES = switch (project.config.getString("ios.device", "universal"))
		{
			case "iphone": "1";
			case "ipad": "2";
			default: "1,2";
		}
		context.DEPLOYMENT = project.config.getString("ios.deployment", "9.0");

		if (project.config.getString("ios.compiler") == "llvm" || project.config.getString("ios.compiler", "clang") == "clang")
		{
			context.OBJC_ARC = true;
		}

		// context.ENABLE_BITCODE = (project.config.getFloat ("ios.deployment", 9) >= 6);
		context.ENABLE_BITCODE = project.config.getBool("ios.enable-bitcode", false);
		context.IOS_COMPILER = project.config.getString("ios.compiler", "clang");
		context.CPP_BUILD_LIBRARY = project.config.getString("cpp.buildLibrary", "hxcpp");

		var json = Json.parse(File.getContent(Haxelib.getPath(new Haxelib("hxcpp"), true) + "/haxelib.json"));

		var version = Std.string(json.version);
		var versionSplit = version.split(".");

		while (versionSplit.length > 2)
			versionSplit.pop();

		if (Std.parseFloat(versionSplit.join(".")) > 3.1)
		{
			context.CPP_LIBPREFIX = "lib";
		}
		else
		{
			context.CPP_LIBPREFIX = "";
		}

		context.IOS_LINKER_FLAGS = ["-stdlib=libc++"].concat(project.config.getArrayString("ios.linker-flags"));
		context.IOS_NON_EXEMPT_ENCRYPTION = project.config.getBool("ios.non-exempt-encryption", true);

		switch (project.window.orientation)
		{
			case PORTRAIT:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			case LANDSCAPE:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>";
			case ALL:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
			// case "allButUpsideDown":
			// context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string></array>";
			default:
				context.IOS_APP_ORIENTATION = "<array><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationPortraitUpsideDown</string></array>";
		}

		context.ADDL_PBX_BUILD_FILE = "";
		context.ADDL_PBX_FILE_REFERENCE = "";
		context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE = "";
		context.ADDL_PBX_FRAMEWORK_GROUP = "";

		context.frameworkSearchPaths = [];

		for (dependency in project.dependencies)
		{
			var name = null;
			var path = null;
			var fileType = null;

			if (Path.extension(dependency.name) == "framework")
			{
				name = dependency.name;
				path = "/System/Library/Frameworks/" + dependency.name;
				fileType = "wrapper.framework";
			}
			else if (Path.extension(dependency.name) == "tbd")
			{
				name = dependency.name;
				path = "/usr/lib/" + dependency.name;
				fileType = "sourcecode.text-based-dylib-definition";
			}
			else if (Path.extension(dependency.path) == "framework")
			{
				name = Path.withoutDirectory(dependency.path);
				path = Path.tryFullPath(dependency.path);
				fileType = "wrapper.framework";
			}
			else if (Path.extension(dependency.path) == "xcframework")
			{
				name = Path.withoutDirectory(dependency.path);
				path = Path.tryFullPath(dependency.path);
				fileType = "wrapper.xcframework";
			}

			if (name != null)
			{
				var frameworkID = "11C0000000000018" + StringTools.getUniqueID();
				var fileID = "11C0000000000018" + StringTools.getUniqueID();

				ArrayTools.addUnique(context.frameworkSearchPaths, Path.directory(path));

				context.ADDL_PBX_BUILD_FILE += "		" + frameworkID + " /* " + name + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + fileID + " /* "
					+ name + " */; };\n";
				context.ADDL_PBX_FILE_REFERENCE += "		" + fileID + " /* " + name + " */ = {isa = PBXFileReference; lastKnownFileType = \"" + fileType
					+ "\"; name = \"" + name + "\"; path = \"" + path + "\"; sourceTree = SDKROOT; };\n";
				context.ADDL_PBX_FRAMEWORKS_BUILD_PHASE += "				" + frameworkID + " /* " + name + " in Frameworks */,\n";
				context.ADDL_PBX_FRAMEWORK_GROUP += "				" + fileID + " /* " + name + " */,\n";
			}
		}

		context.HXML_PATH = System.findTemplate(project.templatePaths, "iphone/PROJ/haxe/Build.hxml", false);
		if (context.HXML_PATH == null) context.HXML_PATH = System.findTemplate(project.templatePaths, "ios/template/{{app.file}}/haxe/Build.hxml");
		context.PRERENDERED_ICON = project.config.getBool("ios.prerenderedIcon", false);

		var allowInsecureHTTP = project.config.getString("ios.allow-insecure-http", "*");

		if (allowInsecureHTTP != "*" && allowInsecureHTTP != "true")
		{
			var sites = [];

			if (allowInsecureHTTP != "false")
			{
				var domains = project.config.getArrayString("ios.allow-insecure-http");

				for (domain in domains)
				{
					sites.push({domain: domain});
				}
			}

			context.IOS_ALLOW_INSECURE_HTTP = sites;
		}

		var haxelibPath = project.environment.get("HAXELIB_PATH");

		if (haxelibPath != null)
		{
			context.HAXELIB_PATH = 'export HAXELIB_PATH="$haxelibPath";';
		}
		else
		{
			context.HAXELIB_PATH = '';
		}

		return context;
	}

	private function getDisplayHXML():HXML
	{
		var path = targetDirectory + "/" + project.app.file + "/haxe/Build.hxml";

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
			hxml.define("iphone");
			hxml.noOutput = true;
			return hxml;
		}
	}

	public override function rebuild():Void
	{
		var armv6 = (project.architectures.indexOf(Architecture.ARMV6) > -1 && !project.targetFlags.exists("simulator"));
		var armv7 = (command == "rebuild"
			|| (project.architectures.indexOf(Architecture.ARMV7) > -1 && !project.targetFlags.exists("simulator")));
		var armv7s = (project.architectures.indexOf(Architecture.ARMV7S) > -1 && !project.targetFlags.exists("simulator"));
		var arm64 = (command == "rebuild"
			|| (project.architectures.indexOf(Architecture.ARM64) > -1 && !project.targetFlags.exists("simulator")));
		var i386 = (command == "rebuild" || project.targetFlags.exists("simulator"));
		var x86_64 = (command == "rebuild" || project.targetFlags.exists("simulator"));

		var arc = (project.targetFlags.exists("arc"));

		var commands = [];

		if (armv6) commands.push(["-Dios", "-DHXCPP_CPP11"]);
		if (armv7) commands.push(["-Dios", "-DHXCPP_CPP11", "-DHXCPP_ARMV7"]);
		if (armv7s) commands.push(["-Dios", "-DHXCPP_CPP11", "-DHXCPP_ARMV7S"]);
		if (arm64) commands.push(["-Dios", "-DHXCPP_CPP11", "-DHXCPP_ARM64"]);
		if (i386) commands.push(["-Dios", "-Dsimulator", "-DHXCPP_CPP11"]);
		if (x86_64) commands.push(["-Dios", "-Dsimulator", "-DHXCPP_M64", "-DHXCPP_CPP11"]);

		if (arc)
		{
			for (command in commands)
			{
				command.push("-DOBJC_ARC");
			}
		}

		IOSHelper.getIOSVersion(project);
		var iphoneVer = project.environment.get("IPHONE_VER");

		for (command in commands)
		{
			command.push("-DIPHONE_VER=" + iphoneVer);
		}

		CPPHelper.rebuild(project, commands);
	}

	public override function run():Void
	{
		if (project.targetFlags.exists("xcode")) return;

		IOSHelper.launch(project, targetDirectory);
	}

	public override function update():Void
	{
		AssetHelper.processLibraries(project, targetDirectory);

		// project = project.clone ();

		for (asset in project.assets)
		{
			if (asset.embed && asset.sourcePath == "")
			{
				var path = Path.combine(targetDirectory + "/" + project.app.file + "/obj/tmp", asset.targetPath);
				System.mkdir(Path.directory(path));
				AssetHelper.copyAsset(asset, path);
				asset.sourcePath = path;
			}
		}

		// var manifest = new Asset ();
		// manifest.id = "__manifest__";
		// manifest.data = AssetHelper.createManifest (project).serialize ();
		// manifest.resourceName = manifest.flatName = manifest.targetPath = "manifest";
		// manifest.type = AssetType.TEXT;
		// project.assets.push (manifest);

		var context = generateContext();
		context.OUTPUT_DIR = targetDirectory;

		var projectDirectory = targetDirectory + "/" + project.app.file + "/";

		System.mkdir(targetDirectory);
		System.mkdir(projectDirectory);
		System.mkdir(projectDirectory + "/haxe");
		System.mkdir(projectDirectory + "/haxe/lime/installer");

		var iconSizes:Array<IconSize> = [
			{name: "Icon-20.png", size: 20},
			{name: "Icon-Small.png", size: 29},
			{name: "Icon-Small-40.png", size: 40},
			{name: "Icon-20@2x.png", size: 40},
			{name: "Icon-Small-50.png", size: 50},
			{name: "Icon.png", size: 57},
			{name: "Icon-Small@2x.png", size: 58},
			{name: "Icon-20@3x.png", size: 60},
			{name: "Icon-72.png", size: 72},
			{name: "Icon-76.png", size: 76},
			{name: "Icon-Small-40@2x.png", size: 80},
			{name: "Icon-Small@3x.png", size: 87},
			{name: "Icon-Small-50@2x.png", size: 100},
			{name: "Icon@2x.png", size: 114},
			{name: "Icon-60@2x.png", size: 120},
			{name: "Icon-Small-40@3x.png", size: 120},
			{name: "Icon-72@2x.png", size: 144},
			{name: "Icon-76@2x.png", size: 152},
			{name: "Icon-83.5@2x.png", size: 167},
			{name: "Icon-60@3x.png", size: 180},
			{name: "Icon-Marketing.png", size: 1024}
		];

		context.HAS_ICON = true;

		var iconPath = Path.combine(projectDirectory, "Images.xcassets/AppIcon.appiconset");
		System.mkdir(iconPath);

		var icons = project.icons;

		if (icons.length == 0)
		{
			icons = [new Icon(System.findTemplate(project.templatePaths, "default/icon.svg"))];
		}

		for (iconSize in iconSizes)
		{
			if (!IconHelper.createIcon(icons, iconSize.size, iconSize.size, Path.combine(iconPath, iconSize.name)))
			{
				context.HAS_ICON = false;
			}
		}

		if (project.launchStoryboard != null)
		{
			var sb = project.launchStoryboard;

			var assetsPath = sb.assetsPath;
			var imagesets = [];

			for (asset in sb.assets)
			{
				switch (asset.type)
				{
					case "imageset":
						var imageset = cast(asset, ImageSet);
						imagesets.push(imageset);

						var imagesetPath = Path.combine(projectDirectory, "Images.xcassets/" + imageset.name + ".imageset");
						System.mkdir(imagesetPath);

						var baseImageName = Path.withoutExtension(imageset.name);

						var imageScales = ["1x", "2x", "3x"];
						var images = [];
						for (scale in imageScales)
						{
							var filename = baseImageName + (scale == "1x" ? "" : "@" + scale) + ".png";
							if (FileSystem.exists(Path.combine(assetsPath, filename)))
							{
								images.push({idiom: "universal", filename: filename, scale: scale});
								System.copyFile(Path.combine(assetsPath, filename), Path.combine(imagesetPath, filename));

								if (imageset.width == 0 || imageset.height == 0)
								{
									var dim = ImageHelper.readPNGImageSize(Path.combine(assetsPath, filename));
									var scaleValue = Std.parseInt(scale.charAt(0));
									imageset.width = Std.int(dim.width / scaleValue);
									imageset.height = Std.int(dim.height / scaleValue);
								}
							}
						}

						var contents =
							{
								images: images,
								info:
									{
										version: "1",
										author: "xcode"
									}
							};

						File.saveContent(Path.combine(imagesetPath, "Contents.json"), Json.stringify(contents));

					default:
				}
			}

			if (sb.template != null)
			{
				sb.templateContext.imagesets = [];

				for (imageset in imagesets)
				{
					sb.templateContext.imagesets.push(
						{
							name: imageset.name,
							width: imageset.width,
							height: imageset.height,
						});
				}

				var deployment:String = context.DEPLOYMENT;
				var parts = deployment.split(".");
				var major = Std.parseInt(parts[0]);
				var minor = parts.length >= 2 ? Std.parseInt(parts[1]) : 0;
				var patch = parts.length >= 3 ? Std.parseInt(parts[2]) : 0;

				Reflect.setField(sb.templateContext, "deploymentVersion",
					{
						major: major,
						minor: minor,
						patch: patch,
						code: Std.parseInt("0x" + major + minor + patch)
					});

				System.copyFileTemplate(project.templatePaths, "ios/storyboards/" + sb.template, projectDirectory + sb.template, sb.templateContext, true,
					true);
				context.IOS_LAUNCH_STORYBOARD = Path.withoutExtension(sb.template);
			}
			else
			{
				System.copyFile(sb.path, projectDirectory + Path.withoutDirectory(sb.path));
				context.IOS_LAUNCH_STORYBOARD = Path.withoutDirectory(Path.withoutExtension(sb.path));
			}
		}
		else
		{
			var splashSizes:Array<SplashSize> = [
				{name: "Default.png", w: 320, h: 480}, // iPhone, portrait
				{name: "Default@2x.png", w: 640, h: 960}, // iPhone Retina, portrait
				{name: "Default-568h@2x.png", w: 640, h: 1136}, // iPhone 5, portrait
				{name: "Default-667h@2x.png", w: 750, h: 1334}, // iPhone 6, portrait
				{name: "Default-736h@3x.png", w: 1242, h: 2208}, // iPhone 6 Plus, portrait
				{name: "Default-Landscape.png", w: 1024, h: 768}, // iPad, landscape
				{name: "Default-Landscape@2x.png", w: 2048, h: 1536}, // iPad Retina, landscape
				{name: "Default-736h-Landscape@3x.png", w: 2208, h: 1242}, // iPhone 6 Plus, landscape
				{name: "Default-Portrait.png", w: 768, h: 1024}, // iPad, portrait
				{name: "Default-Portrait@2x.png", w: 1536, h: 2048}, // iPad Retina, portrait
				{name: "Default-812h@3x.png", w: 1125, h: 2436}, // iPhone X, portrait
				{name: "Default-Landscape-812h@3x.png", w: 2436, h: 1125} // iPhone X, landscape
			];

			var splashScreenPath = Path.combine(projectDirectory, "Images.xcassets/LaunchImage.launchimage");
			System.mkdir(splashScreenPath);

			for (size in splashSizes)
			{
				var match = false;

				for (splashScreen in project.splashScreens)
				{
					if (splashScreen.width == size.w && splashScreen.height == size.h && Path.extension(splashScreen.path) == "png")
					{
						System.copyFile(splashScreen.path, Path.combine(splashScreenPath, size.name));
						match = true;
					}
				}

				if (!match)
				{
					var imagePath = Path.combine(splashScreenPath, size.name);

					if (!FileSystem.exists(imagePath))
					{
						#if (lime && lime_cffi && !macro)
						Log.info("", " - \x1b[1mGenerating image:\x1b[0m " + imagePath);

						var background = project.window.background != null ? project.window.background & 0xFFFFFF : 0x000000;
						var image = new Image(null, 0, 0, size.w, size.h, (0xFF << 24) | background);
						var bytes = image.encode(PNG);

						File.saveBytes(imagePath, bytes);
						#end
					}
				}
			}

			context.HAS_LAUNCH_IMAGE = true;
		}

		System.mkdir(projectDirectory + "/resources");
		System.mkdir(projectDirectory + "/haxe/build");

		// Long deprecated template path

		ProjectHelper.recursiveSmartCopyTemplate(project, "iphone/resources", projectDirectory + "/resources", context, true, false);

		// New template path

		ProjectHelper.recursiveSmartCopyTemplate(project, "ios/template", targetDirectory, context);

		// Recently deprecated template paths

		ProjectHelper.recursiveSmartCopyTemplate(project, "iphone/PROJ/haxe", projectDirectory + "/haxe", context, true, false);
		ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", projectDirectory + "/haxe", context, true, false);
		ProjectHelper.recursiveSmartCopyTemplate(project, "iphone/PROJ/Classes", projectDirectory + "/Classes", context, true, false);
		ProjectHelper.recursiveSmartCopyTemplate(project, "iphone/PROJ/Images.xcassets", projectDirectory + "/Images.xcassets", context, true, false);
		System.copyFileTemplate(project.templatePaths, "iphone/PROJ/PROJ-Info.plist", projectDirectory + "/" + project.app.file + "-Info.plist", context,
			true, false);
		System.copyFileTemplate(project.templatePaths, "iphone/PROJ/PROJ-Prefix.pch", projectDirectory + "/" + project.app.file + "-Prefix.pch", context,
			true, false);
		ProjectHelper.recursiveSmartCopyTemplate(project, "iphone/PROJ.xcodeproj", targetDirectory + "/" + project.app.file + ".xcodeproj", context, true,
			false);

		// Merge plist files
		var plistFiles = System.readDirectory(projectDirectory).filter(function(fileName:String)
		{
			return fileName.substr(-11) == "-Info.plist" && fileName != projectDirectory + "/" + project.app.file + "-Info.plist";
		});
		for (plist in plistFiles)
		{
			System.runCommand(project.workingDirectory, "/usr/libexec/PlistBuddy", [
				"-x",
				"-c",
				"Merge '" + plist + "'",
				projectDirectory + "/" + project.app.file + "-Info.plist"
			]);
		}

		System.mkdir(projectDirectory + "/lib");

		for (archID in 0...6)
		{
			var arch = ["armv6", "armv7", "armv7s", "arm64", "i386", "x86_64"][archID];

			if (arch == "armv6" && !context.ARMV6) continue;

			if (arch == "armv7" && !context.ARMV7) continue;

			if (arch == "armv7s" && !context.ARMV7S) continue;

			if (arch == "arm64" && !context.ARM64) continue;

			var libExt = [
				".iphoneos.a",
				".iphoneos-v7.a",
				".iphoneos-v7s.a",
				".iphoneos-64.a",
				".iphonesim.a",
				".iphonesim-64.a"
			][archID];

			System.mkdir(projectDirectory + "/lib/" + arch);
			System.mkdir(projectDirectory + "/lib/" + arch + "-debug");

			for (ndll in project.ndlls)
			{
				// if (ndll.haxelib != null) {

				var releaseLib = NDLL.getLibraryPath(ndll, "iPhone", "lib", libExt);
				var debugLib = NDLL.getLibraryPath(ndll, "iPhone", "lib", libExt, true);
				var releaseDest = projectDirectory + "/lib/" + arch + "/lib" + ndll.name + ".a";
				var debugDest = projectDirectory + "/lib/" + arch + "-debug/lib" + ndll.name + ".a";

				if (!FileSystem.exists(releaseLib))
				{
					releaseLib = NDLL.getLibraryPath(ndll, "iPhone", "lib", ".iphoneos.a");
					debugLib = NDLL.getLibraryPath(ndll, "iPhone", "lib", ".iphoneos.a", true);
				}

				System.copyIfNewer(releaseLib, releaseDest);

				if (FileSystem.exists(debugLib) && debugLib != releaseLib)
				{
					System.copyIfNewer(debugLib, debugDest);
				}
				else if (FileSystem.exists(debugDest))
				{
					FileSystem.deleteFile(debugDest);
				}

				// }
			}

			for (dependency in project.dependencies)
			{
				if (StringTools.endsWith(dependency.path, ".a"))
				{
					var fileName = Path.withoutDirectory(dependency.path);

					if (!StringTools.startsWith(fileName, "lib"))
					{
						fileName = "lib" + fileName;
					}

					System.copyIfNewer(dependency.path, projectDirectory + "/lib/" + arch + "/" + fileName);
				}
			}
		}

		System.mkdir(projectDirectory + "/assets");

		for (asset in project.assets)
		{
			if (asset.type != AssetType.TEMPLATE)
			{
				var targetPath = Path.combine(projectDirectory + "/assets/", asset.resourceName);

				// var sourceAssetPath:String = projectDirectory + "haxe/" + asset.sourcePath;

				System.mkdir(Path.directory(targetPath));
				AssetHelper.copyAssetIfNewer(asset, targetPath);

				// System.mkdir (Path.directory (sourceAssetPath));
				// System.linkFile (flatAssetPath, sourceAssetPath, true, true);
			}
			else
			{
				var targetPath = Path.combine(projectDirectory, asset.targetPath);

				System.mkdir(Path.directory(targetPath));
				AssetHelper.copyAsset(asset, targetPath, context);
			}
		}

		if (project.targetFlags.exists("xcode") && System.hostPlatform == MAC && command == "update")
		{
			System.runCommand("", "open", [targetDirectory + "/" + project.app.file + ".xcodeproj"]);
		}
	}

	/*private function updateLaunchImage () {

		var destination = buildDirectory + "/ios";
		System.mkdir (destination);

		var has_launch_image = false;
		if (launchImages.length > 0) has_launch_image = true;

		for (launchImage in launchImages) {

			var splitPath = launchImage.name.split ("/");
			var path = destination + "/" + splitPath[splitPath.length - 1];
			System.copyFile (launchImage.name, path, context, false);

		}

		context.HAS_LAUNCH_IMAGE = has_launch_image;

	}*/
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

	@ignore public override function install():Void {}

	@ignore public override function trace():Void {}

	@ignore public override function uninstall():Void {}
}

private typedef IconSize =
{
	name:String,
	size:Int,
}

private typedef SplashSize =
{
	name:String,
	w:Int,
	h:Int,
}
