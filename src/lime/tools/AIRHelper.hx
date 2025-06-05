package lime.tools;

import hxp.*;
import sys.FileSystem;

class AIRHelper
{
	public static function build(project:HXProject, workingDirectory:String, targetPlatform:Platform, targetPath:String, applicationXML:String,
			files:Array<String>, fileDirectory:String = null):String
	{
		// var airTarget = "air";
		// var extension = ".air";
		var airTarget = "bundle";
		var extension = "";

		switch (targetPlatform)
		{
			case MAC:

				if (airTarget == "bundle")
				{
					extension = ".app";
				}

			case IOS:
				if (project.targetFlags.exists("simulator"))
				{
					if (project.debug)
					{
						airTarget = "ipa-debug-interpreter-simulator";
					}
					else
					{
						airTarget = "ipa-test-interpreter-simulator";
					}
				}
				else
				{
					var supportedExportMethods = ["adhoc", "appstore"];
					var exportMethod:String = null;
					for (m in supportedExportMethods)
					{
						if (project.targetFlags.exists(m))
						{
							if (exportMethod != null)
							{
								Log.error("Must not specify multiple export methods. Found: " + exportMethod + " and " + m);
							}
							exportMethod = m;
						}
					}
					if (exportMethod == null && project.targetFlags.exists("final")) {
						exportMethod = "appstore";
					}

					if (project.debug)
					{
						if (exportMethod != null)
						{
							Log.error("Must not specify export method for a debug build. Found: " + exportMethod);
						}
						airTarget = "ipa-debug";
					}
					else
					{
						switch (exportMethod)
						{
							case "appstore":
								airTarget = "ipa-app-store";
							case "adhoc":
								airTarget = "ipa-ad-hoc";
							default:
								airTarget = "ipa-test";
						}
					}
				}

			// extension = ".ipa";

			case ANDROID:
				if (project.debug)
				{
					airTarget = "apk-debug";
				}
				else
				{
					airTarget = "apk";
				}

			// extension = ".apk";

			default:
		}

		var signingOptions = [];

		if (project.keystore != null)
		{
			var keystoreType = project.keystore.type != null ? project.keystore.type : "pkcs12";
			signingOptions.push("-storetype");
			signingOptions.push(keystoreType);

			if (project.keystore.path != null)
			{
				var keystore = Path.tryFullPath(project.keystore.path);
				signingOptions.push("-keystore");
				signingOptions.push(keystore);
			}

			if (project.keystore.alias != null)
			{
				signingOptions.push("-alias");
				signingOptions.push(project.keystore.alias);
			}

			if (project.keystore.password != null)
			{
				signingOptions.push("-storepass");
				signingOptions.push(project.keystore.password);
			}

			if (project.keystore.aliasPassword != null)
			{
				signingOptions.push("-keypass");
				signingOptions.push(project.keystore.aliasPassword);
			}
		}
		else
		{
			signingOptions.push("-storetype");
			signingOptions.push("pkcs12");
			signingOptions.push("-keystore");
			signingOptions.push(System.findTemplate(project.templatePaths, "air/debug.pfx"));
			signingOptions.push("-storepass");
			signingOptions.push("samplePassword");
		}

		if (project.config.exists("air.tsa"))
		{
			signingOptions.push("-tsa");
			signingOptions.push(project.config.getString("air.tsa"));
		}

		var args = ["-package"];

		// TODO: Is this an old workaround fixed in newer AIR SDK?

		if (airTarget == "air" || airTarget == "bundle")
		{
			args = args.concat(signingOptions);
			args.push("-target");
			args.push(airTarget);
		}
		else
		{
			args.push("-target");
			args.push(airTarget);

			if (project.debug)
			{
				if (project.config.exists("air.connect"))
				{
					args.push("-connect");
					args.push(project.config.getString("air.connect"));
				}
				else if (project.config.exists("air.listen"))
				{
					args.push("-listen");
					args.push(project.config.getString("air.listen"));
				}
				else
				{
					args.push("-connect");
				}
			}

			args = args.concat(signingOptions);
		}

		if (targetPlatform == IOS)
		{
			var provisioningProfile = IOSHelper.getProvisioningFile(project);

			if (provisioningProfile != "")
			{
				args.push("-provisioning-profile");
				args.push(provisioningProfile);
			}
		}

		args = args.concat([targetPath + extension, applicationXML]);

		if (targetPlatform == IOS && System.hostPlatform == MAC && project.targetFlags.exists("simulator"))
		{
			args.push("-platformsdk");
			args.push(IOSHelper.getSDKDirectory(project));
		}

		if (fileDirectory != null && fileDirectory != "")
		{
			args.push("-C");
			args.push(fileDirectory);
		}

		args = args.concat(files);

		var extDirs:Array<String> = getExtDirs(project);

		if (extDirs.length > 0)
		{
			args.push("-extdir");

			for (extDir in extDirs)
			{
				args.push(extDir);
			}
		}

		if (targetPlatform == ANDROID)
		{
			Sys.putEnv("AIR_NOANDROIDFLAIR", "true");
		}

		if (targetPlatform == IOS && System.hostPlatform == MAC)
		{
			var simulatorName = XCodeHelper.getSimulatorName(project);
			if (simulatorName == null)
			{
				Log.warn("Skipping AIR_IOS_SIMULATOR_DEVICE environment variable because default simulator not found");
			}
			else
			{
				Sys.putEnv("AIR_IOS_SIMULATOR_DEVICE", simulatorName);
			}
		}

		System.runCommand(workingDirectory, project.defines.get("AIR_SDK") + "/bin/adt", args);

		return targetPath + extension;
	}

	public static function getExtDirs(project:HXProject):Array<String>
	{
		var extDirs:Array<String> = [];

		for (dependency in project.dependencies)
		{
			var extDir:String = FileSystem.fullPath(Path.directory(dependency.path));

			if (StringTools.endsWith(dependency.path, ".ane") && extDirs.indexOf(extDir) == -1)
			{
				extDirs.push(extDir);
			}
		}

		return extDirs;
	}

	public static function run(project:HXProject, workingDirectory:String, targetPlatform:Platform, applicationXML:String, rootDirectory:String = null):Void
	{
		var runInAdl = true;
		if (targetPlatform == ANDROID && !project.targetFlags.exists("air-simulator"))
		{
			runInAdl = false;
			AndroidHelper.initialize(project);
			AndroidHelper.install(project,
				FileSystem.fullPath(workingDirectory)
				+ "/"
				+ (rootDirectory != null ? rootDirectory + "/" : "")
				+ project.app.file
				+ ".apk");
			AndroidHelper.run(project.meta.packageName + "/.AppEntry");
		}
		else if (targetPlatform == IOS && !project.targetFlags.exists("air-simulator"))
		{
			runInAdl = false;
			var args = ["-platform", "ios"];

			if (project.targetFlags.exists("simulator"))
			{
				args.push("-device");
				args.push("ios-simulator");
				args.push("-platformsdk");
				args.push(IOSHelper.getSDKDirectory(project));

				System.runCommand("", "killall", ["iPhone Simulator"], true, true);
			}

			System.runCommand(workingDirectory, project.defines.get("AIR_SDK") + "/bin/adt",
				["-uninstallApp"].concat(args).concat(["-appid", project.meta.packageName]), true, true);
			System.runCommand(workingDirectory, project.defines.get("AIR_SDK") + "/bin/adt", ["-installApp"].concat(args).concat(["-package",
				FileSystem.fullPath(workingDirectory)
				+ "/"
				+ (rootDirectory != null ? rootDirectory + "/" : "")
				+ project.app.file
				+ ".ipa"]));
			System.runCommand(workingDirectory, project.defines.get("AIR_SDK") + "/bin/adt",
				["-launchApp"].concat(args).concat(["-appid", project.meta.packageName]), true, true);

			if (project.targetFlags.exists("simulator"))
			{
				var simulatorAppPath:String = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app/";

				if (!FileSystem.exists(simulatorAppPath))
				{
					simulatorAppPath = "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/";
				}

				System.runCommand("", "open", [simulatorAppPath]);
			}
		}
		if (runInAdl)
		{
			var extDirs:Array<String> = getExtDirs(project);

			var profile:String;

			if (project.config.exists("air.profile"))
			{
				profile = project.config.getString("air.profile");
			}
			else if (targetPlatform == ANDROID)
			{
				profile = "mobileDevice";
			}
			else if (targetPlatform == IOS)
			{
				profile = "mobileDevice";
			}
			else
			{
				profile = extDirs.length > 0 ? "extendedDesktop" : "desktop";
			}

			var args = ["-profile", profile];

			if (targetPlatform == ANDROID || targetPlatform == IOS)
			{
				args.push("-XscreenDPI");
				if (project.config.exists("air.screenDPI"))
				{
					var screenDPI = project.config.getString("air.screenDPI");
					args.push(screenDPI);
				}
				else
				{
					args.push("252");
				}
				args.push("-screensize");
				if (project.config.exists("air.screensize"))
				{
					var screensize = project.config.getString("air.screensize");
					args.push(screensize);
				}
				else
				{
					// these are just generic default dimensions that are a bit
					// larger than AIR's defaults for the simulator
					args.push("480x762:480x800");
				}
			}
			if (targetPlatform == ANDROID)
			{
				args.push("-XversionPlatform");
				args.push("AND");
			}
			else if (targetPlatform == IOS)
			{
				args.push("-XversionPlatform");
				args.push("IOS");
			}

			if (!project.debug)
			{
				args.push("-nodebug");
			}

			if (extDirs.length > 0)
			{
				args.push("-extdir");

				for (extDir in extDirs)
				{
					if (!FileSystem.exists(extDir + "/adl"))
					{
						Log.error("Create " + extDir + "/adl directory, and extract your ANE files to .ane directories.");
					}

					args.push(extDir + "/adl");
				}
			}

			args.push(applicationXML);

			if (rootDirectory != null && rootDirectory != "")
			{
				args.push(rootDirectory);
			}

			System.runCommand(workingDirectory, project.defines.get("AIR_SDK") + "/bin/adl", args);
		}
	}

	public static function trace(project:HXProject, workingDirectory:String, targetPlatform:Platform, applicationXML:String, rootDirectory:String = null)
	{
		if (targetPlatform == ANDROID && !project.targetFlags.exists("air-simulator"))
		{
			AndroidHelper.initialize(project);
			var deviceID = null;
			var adbFilter = null;

			// if (!Log.verbose) {

			if (project.debug)
			{
				adbFilter = project.meta.packageName + ":I ActivityManager:I *:S";
			}
			else
			{
				adbFilter = project.meta.packageName + ":I *:S";
			}

			// }

			AndroidHelper.trace(project, project.debug, deviceID, adbFilter);
		}
	}

	public static function uninstall(project:HXProject, workingDirectory:String, targetPlatform:Platform, applicationXML:String, rootDirectory:String = null)
	{
		if (targetPlatform == ANDROID)
		{
			AndroidHelper.initialize(project);
			var deviceID = null;
			AndroidHelper.uninstall(project.meta.packageName, deviceID);
		}
	}
}
