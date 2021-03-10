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

			// extension = ".app";

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
					if (project.debug)
					{
						airTarget = "ipa-debug";
					}
					else
					{
						airTarget = "ipa-test";
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
			var keystore = Path.tryFullPath(project.keystore.path);
			var keystoreType = project.keystore.type != null ? project.keystore.type : "pkcs12";

			signingOptions.push("-storetype");
			signingOptions.push(keystoreType);
			signingOptions.push("-keystore");
			signingOptions.push(keystore);

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
				args.push("-connect");

				if (project.config.exists("air.connect"))
				{
					args.push(project.config.getString("air.connect"));
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

		if (targetPlatform == IOS)
		{
			Sys.putEnv("AIR_IOS_SIMULATOR_DEVICE", XCodeHelper.getSimulatorName(project));
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
		if (targetPlatform == ANDROID)
		{
			AndroidHelper.initialize(project);
			AndroidHelper.install(project,
				FileSystem.fullPath(workingDirectory)
				+ "/"
				+ (rootDirectory != null ? rootDirectory + "/" : "")
				+ project.app.file
				+ ".apk");
			AndroidHelper.run(project.meta.packageName + "/.AppEntry");
		}
		else if (targetPlatform == IOS)
		{
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
		else
		{
			var extDirs:Array<String> = getExtDirs(project);

			var profile:String = extDirs.length > 0 ? "extendedDesktop" : "desktop";

			var args = ["-profile", profile];

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
		if (targetPlatform == ANDROID)
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
