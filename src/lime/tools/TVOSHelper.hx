package lime.tools;

import hxp.*;
import lime.tools.HXProject;
import sys.io.Process;
import sys.FileSystem;

class TVOSHelper
{
	private static var initialized = false;

	public static function build(project:HXProject, workingDirectory:String, additionalArguments:Array<String> = null):Void
	{
		initialize(project);

		var commands = getXCodeArgs(project);

		if (project.targetFlags.exists("archive"))
		{
			var configuration = project.environment.get("CONFIGURATION");
			var platformName = project.environment.get("PLATFORM_NAME");

			commands.push("archive");
			commands.push("-scheme");
			commands.push(project.app.file);
			commands.push("-archivePath");
			commands.push(Path.combine("build", Path.combine(configuration + "-" + platformName, project.app.file)));
		}

		if (additionalArguments != null)
		{
			commands = commands.concat(additionalArguments);
		}

		System.runCommand(workingDirectory, "xcodebuild", commands);
	}

	public static function deploy(project:HXProject, workingDirectory:String):Void
	{
		initialize(project);

		var commands = getXCodeArgs(project);
		var archiveCommands = commands.concat([]);

		// generate xcarchive
		var configuration = project.environment.get("CONFIGURATION");
		var platformName = project.environment.get("PLATFORM_NAME");

		archiveCommands.push("archive");
		archiveCommands.push("-scheme");
		archiveCommands.push(project.app.file);
		archiveCommands.push("-archivePath");
		archiveCommands.push(Path.combine("build", Path.combine(configuration + "-" + platformName, project.app.file)));

		System.runCommand(workingDirectory, "xcodebuild", archiveCommands);

		// generate IPA from xcarchive
		var exportCommands = commands.concat([]);

		var exportMethod = project.targetFlags.exists("adhoc") ? "adhoc" : project.targetFlags.exists("development") ? "development" : project.targetFlags.exists("enterprise") ? "enterprise" : "appstore";

		exportCommands.push("-exportArchive");
		exportCommands.push("-archivePath");
		exportCommands.push(Path.combine("build", Path.combine(configuration + "-" + platformName, project.app.file + ".xcarchive")));
		exportCommands.push("-exportOptionsPlist");
		exportCommands.push(Path.combine(project.app.file, "exportOptions-" + exportMethod + ".plist"));
		exportCommands.push("-exportPath");
		exportCommands.push(Path.combine("dist", exportMethod));

		System.runCommand(workingDirectory, "xcodebuild", exportCommands);
	}

	private static function getXCodeArgs(project:HXProject):Array<String>
	{
		var platformName = "appletvos";

		if (project.targetFlags.exists("simulator"))
		{
			platformName = "appletvsimulator";
		}

		var configuration = "Release";

		if (project.debug)
		{
			configuration = "Debug";
		}

		var iphoneVersion = project.environment.get("TVOS_VER");
		var commands = [
			"-configuration",
			configuration,
			"PLATFORM_NAME=" + platformName,
			"SDKROOT=" + platformName + iphoneVersion
		];

		if (project.targetFlags.exists("simulator"))
		{
			commands.push("-arch");
			commands.push("x86_64");
		}

		project.setenv("PLATFORM_NAME", platformName);
		project.setenv("CONFIGURATION", configuration);

		// setting CONFIGURATION and PLATFORM_NAME in project.environment doesn't set them for xcodebuild so also pass via command line
		var commands = [
			"-configuration",
			configuration,
			"PLATFORM_NAME=" + platformName,
			"SDKROOT=" + platformName + iphoneVersion
		];

		if (project.targetFlags.exists("simulator"))
		{
			commands.push("-arch");
			commands.push("x86_64");
		}

		commands.push("-project");
		commands.push(project.app.file + ".xcodeproj");

		var xcodeVersions = getXcodeVersion().split(".").map(function(i:String)
		{
			var ver = Std.parseInt(i);
			return ver != null ? ver : 0;
		});

		if (xcodeVersions[0] >= 9)
		{
			if (project.config.getBool('ios.allow-provisioning-updates', true))
			{
				commands.push("-allowProvisioningUpdates");
			}
			if (project.config.getBool('ios.allow-provisioning-device-registration', true))
			{
				commands.push("-allowProvisioningDeviceRegistration");
			}
		}

		return commands;
	}

	private static function getIOSVersion(project:HXProject):Void
	{
		if (!project.environment.exists("TVOS_VER"))
		{
			if (!project.environment.exists("DEVELOPER_DIR"))
			{
				var proc = new Process("xcode-select", ["--print-path"]);
				var developer_dir = proc.stdout.readLine();
				proc.close();
				project.environment.set("DEVELOPER_DIR", developer_dir);
			}

			var dev_path = project.environment.get("DEVELOPER_DIR") + "/Platforms/AppleTVOS.platform/Developer/SDKs";

			if (FileSystem.exists(dev_path))
			{
				var best = "";
				var files = FileSystem.readDirectory(dev_path);
				var extract_version = ~/^AppleTVOS(.*).sdk$/;

				for (file in files)
				{
					if (extract_version.match(file))
					{
						var ver = extract_version.matched(1);

						if (ver > best)
						{
							best = ver;
						}
					}
				}

				if (best != "")
				{
					project.environment.set("TVOS_VER", best);
				}
			}
		}
	}

	private static function getOSXVersion():String
	{
		var output = System.runProcess("", "sw_vers", ["-productVersion"]);
		return StringTools.trim(output);
	}

	public static function getProvisioningFile():String
	{
		var path = Path.expand("~/Library/MobileDevice/Provisioning Profiles");
		var files = FileSystem.readDirectory(path);

		for (file in files)
		{
			if (Path.extension(file) == "mobileprovision")
			{
				return path + "/" + file;
			}
		}

		return "";
	}

	public static function getSDKDirectory(project:HXProject):String
	{
		initialize(project);

		var platformName = "AppleTVOS";

		if (project.targetFlags.exists("simulator"))
		{
			platformName = "AppleTVSimulator";
		}

		var process = new Process("xcode-select", ["--print-path"]);
		var directory = process.stdout.readLine();
		process.close();

		if (directory == "" || directory.indexOf("Run xcode-select") > -1)
		{
			directory = "/Applications/Xcode.app/Contents/Developer";
		}

		directory += "/Platforms/" + platformName + ".platform/Developer/SDKs/" + platformName + project.environment.get("TVOS_VER") + ".sdk";
		Log.info(directory);
		return directory;
	}

	private static function getXcodeVersion():String
	{
		var output = System.runProcess("", "xcodebuild", ["-version"]);
		var firstLine = output.split("\n").shift();

		return StringTools.trim(firstLine.substring("Xcode".length, firstLine.length));
	}

	private static function initialize(project:HXProject):Void
	{
		if (!initialized)
		{
			getIOSVersion(project);

			initialized = true;
		}
	}

	public static function launch(project:HXProject, workingDirectory:String):Void
	{
		initialize(project);

		var configuration = "Release";

		if (project.debug)
		{
			configuration = "Debug";
		}

		if (project.targetFlags.exists("simulator"))
		{
			var applicationPath = "";

			if (Path.extension(workingDirectory) == "app" || Path.extension(workingDirectory) == "ipa")
			{
				applicationPath = workingDirectory;
			}
			else
			{
				applicationPath = workingDirectory + "/build/" + configuration + "-appletvsimulator/" + project.app.file + ".app";
			}

			var templatePaths = [
				Path.combine(Haxelib.getPath(new Haxelib(#if lime "lime" #else "hxp" #end)), #if lime "templates" #else "" #end)
			].concat(project.templatePaths);
			var launcher = System.findTemplate(templatePaths, "bin/ios-sim");
			Sys.command("chmod", ["+x", launcher]);

			// device config
			var defaultDevice = "apple-tv-1080p";
			var devices:Array<String> = ["apple-tv-1080p"];
			var oldDevices:Map<String, String> = ["appletv" => "apple-tv-1080p"];

			var deviceFlag:String = null;
			var deviceTypeID:String = null;

			// check if old device flag and convert to current
			for (key in oldDevices.keys())
			{
				if (project.targetFlags.exists(key))
				{
					deviceFlag = oldDevices[key];
					break;
				}
			}

			// check known device in command line args
			if (deviceFlag == null)
			{
				for (i in 0...devices.length)
				{
					if (project.targetFlags.exists(devices[i]))
					{
						deviceFlag = devices[i];
						break;
					}
				}
			}

			// default to iphone 6
			if (deviceFlag == null)
			{
				deviceFlag = defaultDevice;
			}

			// check if device is available
			// $ ios-sim showdevicetypes
			var devicesOutput:String = System.runProcess("", launcher, ["showdevicetypes"]);
			var deviceTypeList:Array<String> = devicesOutput.split("\n");

			for (i in 0...deviceTypeList.length)
			{
				var r = new EReg(deviceFlag + ",", "i");

				if (r.match(deviceTypeList[i]))
				{
					deviceTypeID = deviceTypeList[i];
					break;
				}
			}

			if (deviceTypeID == null)
			{
				Log.warn("Device \"" + deviceFlag + "\" was not found");
			}
			else
			{
				Log.info("Launch app on \"" + deviceTypeID + "\"");
			}

			// run command with --devicetypeid if exists
			if (deviceTypeID != null)
			{
				System.runCommand("", launcher, [
					"launch",
					FileSystem.fullPath(applicationPath),
					/*"--sdk", project.environment.get ("IPHONE_VER"),*/
					"--devicetypeid",
					deviceTypeID,
					"--timeout",
					"60"
				]);
			}
			else
			{
				System.runCommand("", launcher, [
					"launch",
					FileSystem.fullPath(applicationPath),
					/*"--sdk", project.environment.get ("IPHONE_VER"), "--devicetypeid", deviceTypeID,*/
					"--timeout",
					"60"
				]);
			}
		}
		else
		{
			var applicationPath = "";

			if (Path.extension(workingDirectory) == "app" || Path.extension(workingDirectory) == "ipa")
			{
				applicationPath = workingDirectory;
			}
			else
			{
				applicationPath = workingDirectory + "/build/" + configuration + "-appletvos/" + project.app.file + ".app";
			}

			var templatePaths = [
				Path.combine(Haxelib.getPath(new Haxelib(#if lime "lime" #else "hxp" #end)), #if lime "templates" #else "" #end)
			].concat(project.templatePaths);
			var launcher = System.findTemplate(templatePaths, "bin/ios-deploy");
			Sys.command("chmod", ["+x", launcher]);

			var xcodeVersion = getXcodeVersion();

			System.runCommand("", launcher, [
				"install",
				"--noninteractive",
				"--debug",
				"--timeout",
				"5",
				"--bundle",
				FileSystem.fullPath(applicationPath)
			]);
		}
	}

	public static function sign(project:HXProject, workingDirectory:String):Void
	{
		initialize(project);

		var configuration = "Release";

		if (project.debug)
		{
			configuration = "Debug";
		}

		var identity = project.config.getString("tvos.identity", "tvOS Developer");

		var commands = ["-s", identity, "CODE_SIGN_IDENTITY=" + identity];

		if (project.config.exists("tvos.provisioning-profile"))
		{
			commands.push("PROVISIONING_PROFILE=" + project.config.getString("tvos.provisioning-profile"));
		}

		var applicationPath = "build/" + configuration + "-appletvos/" + project.app.file + ".app";
		commands.push(applicationPath);

		System.runCommand(workingDirectory, "codesign", commands, true, true);
	}
}
