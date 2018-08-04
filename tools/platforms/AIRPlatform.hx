package;


import haxe.io.Path;
import haxe.Template;
import lime.tools.AIRHelper;
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.DeploymentHelper;
import hxp.FileHelper;
import lime.tools.FlashHelper;
import lime.tools.Icon;
import lime.tools.IconHelper;
import hxp.Log;
import hxp.PathHelper;
import lime.tools.Platform;
import hxp.PlatformHelper;
import lime.tools.PlatformType;
import lime.tools.Project;
import lime.tools.ProjectHelper;
import hxp.ZipHelper;
import sys.io.File;
import sys.FileSystem;


class AIRPlatform extends FlashPlatform {


	private var iconData:Array<Dynamic>;
	private var splashScreenData:Array<Dynamic>;
	private var targetPlatform:Platform;
	private var targetPlatformType:PlatformType;


	public function new (command:String, _project:Project, targetFlags:Map<String, String>) {

		super (command, _project, targetFlags);

		targetDirectory = PathHelper.combine (project.app.path, project.config.getString ("air.output-directory", "air"));

		if (targetFlags.exists ("android")) {

			targetPlatform = Platform.ANDROID;
			targetPlatformType = MOBILE;

		} else if (targetFlags.exists ("ios")) {

			targetPlatform = Platform.IOS;
			targetPlatformType = MOBILE;

		} else if (targetFlags.exists ("windows")) {

			targetPlatform = Platform.WINDOWS;
			targetPlatformType = DESKTOP;

		} else if (targetFlags.exists ("mac")) {

			targetPlatform = Platform.MAC;
			targetPlatformType = DESKTOP;

		} else {

			targetPlatform = cast PlatformHelper.hostPlatform;
			targetPlatformType = DESKTOP;

		}

	}


	public override function build ():Void {

		super.build ();

		if (!project.defines.exists ("AIR_SDK")) {

			Log.error ("You must define AIR_SDK with the path to your AIR SDK");

		}

		// TODO: Should we package on desktop in "deploy" command instead?

		if (targetPlatformType != DESKTOP) {

			var files = [ project.app.file + ".swf" ];
			for (asset in project.assets) {

				if (asset.embed == false && asset.type != TEMPLATE) {

					files.push (asset.targetPath);

				}

			}

			for (icon in iconData) {

				files.push (icon.path);

			}

			for (splashScreen in splashScreenData) {

				files.push (splashScreen.path);

			}

			var targetPath = switch (targetPlatform) {

				case ANDROID: "bin/" + project.app.file + ".apk";
				case IOS: "bin/" + project.app.file + ".ipa";
				default: "bin/" + project.app.file + ".air";

			}

			AIRHelper.build (project, targetDirectory, targetPlatform, targetPath, "application.xml", files, "bin");

		}

	}


	public override function clean ():Void {

		if (FileSystem.exists (targetDirectory)) {

			PathHelper.removeDirectory (targetDirectory);

		}

	}


	public override function deploy ():Void {

		if (targetFlags.exists ("gdrive") || targetFlags.exists ("zip")) {

			DeploymentHelper.deploy (project, targetFlags, targetDirectory, "AIR");

		} else {

			var rootDirectory = targetDirectory + "/bin";
			var paths = PathHelper.readDirectory (rootDirectory, [ project.app.file + ".apk", project.app.file + ".ipa", project.app.file + ".air" ]);
			var files = [];

			for (path in paths) {

				files.push (path.substr (rootDirectory.length + 1));

			}

			var name = project.meta.title + " (" + project.meta.version + " build " + project.meta.buildNumber + ")";

			switch (targetPlatform) {

				case WINDOWS:

					name += " (Windows)";

				case MAC:

					name += " (macOS)";

				case IOS:

					name += " (iOS).ipa";

				case ANDROID:

					name += " (Android).apk";

				default:

			}

			var outputPath = "dist/" + name;

			PathHelper.mkdir (targetDirectory + "/dist");

			outputPath = AIRHelper.build (project, targetDirectory, targetPlatform, outputPath, "application.xml", files, "bin");

			if (targetPlatformType == DESKTOP) {

				ZipHelper.compress (PathHelper.combine (targetDirectory, outputPath), PathHelper.combine (targetDirectory, "dist/" + name + ".zip"));

			}

		}

	}


	private override function getDisplayHXML ():String {

		var hxml = PathHelper.findTemplate (project.templatePaths, "flash/hxml/" + buildType + ".hxml");

		var context = project.templateContext;
		context.WIN_FLASHBACKGROUND = StringTools.hex (project.window.background, 6);
		context.OUTPUT_DIR = targetDirectory;

		for (dependency in project.dependencies) {

			if (StringTools.endsWith (dependency.path, ".ane")) {

				context.HAXE_FLAGS += "\n-swf-lib " + dependency.path;

			}

		}

		var template = new Template (File.getContent (hxml));

		return template.execute (context) + "\n-D display";

	}


	public override function install ():Void {

		// TODO: Make separate install step

	}


	public override function run ():Void {

		AIRHelper.run (project, targetDirectory, targetPlatform, "application.xml", "bin");

	}


	public override function trace ():Void {

		AIRHelper.trace (project, targetDirectory, targetPlatform, "application.xml", "bin");

	}


	public override function uninstall ():Void {

		AIRHelper.uninstall (project, targetDirectory, targetPlatform, "application.xml", "bin");

	}


	public override function update ():Void {

		AssetHelper.processLibraries (project, targetDirectory);

		var destination = targetDirectory + "/bin/";
		PathHelper.mkdir (destination);

		// project = project.clone ();

		embedded = FlashHelper.embedAssets (project, targetDirectory);

		var context = generateContext ();
		context.OUTPUT_DIR = targetDirectory;
		context.AIR_SDK_VERSION = project.config.getString ("air.sdk-version", "28.0");

		var buildNumber = Std.string (context.APP_BUILD_NUMBER);

		if (buildNumber.length <= 3) {

			context.APP_BUILD_NUMBER_SPLIT = buildNumber;

		} else {

			var major = null;

			var patch = buildNumber.substr (-3);
			buildNumber = buildNumber.substr (0, -3);

			var minor = buildNumber.substr (-Std.int (Math.min (buildNumber.length, 3)));
			buildNumber = buildNumber.substr (0, -minor.length);

			if (buildNumber.length > 0) {

				major = buildNumber.substr (-Std.int (Math.min (buildNumber.length, 3)));
				buildNumber = buildNumber.substr (0, -major.length);

			}

			var buildNumberSplit = minor + "." + patch;
			if (major != null) buildNumberSplit = major + "." + buildNumberSplit;

			context.APP_BUILD_NUMBER_SPLIT = buildNumberSplit;

			if (buildNumber.length > 0) {

				Log.warn ("Application build number " + buildNumber + buildNumberSplit + " exceeds 9 digits");

			}

		}

		var targetDevice = project.config.getString ("ios.device", "universal");
		var targetDevices = [];

		if (targetDevice != "ipad") targetDevices.push (1); // iphone
		if (targetDevice != "iphone") targetDevices.push (2); // ipad

		context.IOS_TARGET_DEVICES = targetDevices;

		var iconSizes = [ 16, 29, 32, 36, 40, 48, 50, 57, 58, 60, 72, 75, 76, 80, 87, 96, 100, 114, 120, 128, 144, 152, 167, 180, 192, 512, 1024 ];
		var icons = project.icons;
		iconData = [];

		if (icons.length == 0) {

			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];

		}

		for (size in iconSizes) {

			if (IconHelper.createIcon (icons, size, size, targetDirectory + "/bin/_res/icon-" + size + ".png")) {

				iconData.push ({ size: size, path: "_res/icon-" + size + ".png" });

			}

		}

		if (iconData.length > 0) context.icons = iconData;

		context.extensions = new Array<String>();

		for (dependency in project.dependencies) {

			if (StringTools.endsWith (dependency.path, ".ane")) {

				var extension:Dynamic = { name: dependency.name };
				context.extensions.push (extension);
				context.HAXE_FLAGS += "\n-swf-lib " + dependency.path;

			}

		}

		ProjectHelper.recursiveSmartCopyTemplate (project, "haxe", targetDirectory + "/haxe", context);
		ProjectHelper.recursiveSmartCopyTemplate (project, "air/hxml", targetDirectory + "/haxe", context);
		ProjectHelper.recursiveSmartCopyTemplate (project, "air/template", targetDirectory, context);

		if (embedded) {

			var files = [ "debug.hxml", "release.hxml", "final.hxml" ];
			var path, hxml, lines, output;

			for (file in files) {

				path = targetDirectory + "/haxe/" + file;
				hxml = File.getContent (path);

				if (hxml.indexOf ("-swf-header") > -1) {

					lines = ~/[\r\n]+/g.split (hxml);
					output = [];

					for (line in lines) {

						if (line.indexOf ("-swf-header") > -1) continue;
						output.push (line);

					}

					if (output.length < lines.length) {

						File.saveContent (path, output.join ("\n"));

					}

				}

			}

		}

		for (asset in project.assets) {

			if (asset.type == AssetType.TEMPLATE || asset.embed == false /*|| !usesLime*/) {

				var path = PathHelper.combine (destination, asset.targetPath);

				PathHelper.mkdir (Path.directory (path));
				AssetHelper.copyAsset (asset, path, context);

			}

		}

		splashScreenData = [];

		if (project.splashScreens != null) {

			for (splashScreen in project.splashScreens) {

				var path = Path.withoutDirectory (splashScreen.path);
				FileHelper.copyFile (splashScreen.path, PathHelper.combine (destination, path), context);
				splashScreenData.push ({ path: path });

			}

		}

	}


	@ignore public override function rebuild ():Void {}


}
