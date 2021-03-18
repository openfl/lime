package lime.tools;

import hxp.*;
import sys.io.File;
import sys.FileSystem;

class AndroidHelper
{
	private static var adbName:String;
	private static var adbPath:String;
	private static var androidName:String;
	private static var androidPath:String;
	private static var emulatorName:String;
	private static var emulatorPath:String;

	public static function build(project:HXProject, projectDirectory:String):Void
	{
		if (project.environment.exists("ANDROID_SDK"))
		{
			Sys.putEnv("ANDROID_SDK", project.environment.get("ANDROID_SDK"));
		}

		var task = "assembleDebug";

		if (project.keystore != null)
		{
			task = "assembleRelease";
		}

		if (project.environment.exists("ANDROID_GRADLE_TASK"))
		{
			task = project.environment.get("ANDROID_GRADLE_TASK");
		}

		var args = task.split(" ");
		// args.push ("--stacktrace");
		// args.push ("--debug");

		if (Log.verbose)
		{
			args.push("--info");
		}

		if (System.hostPlatform != WINDOWS)
		{
			System.runCommand("", "chmod", ["755", Path.combine(projectDirectory, "gradlew")]);
			System.runCommand(projectDirectory, "./gradlew", args);
		}
		else
		{
			System.runCommand(projectDirectory, "gradlew", args);
		}
	}

	private static function connect(deviceID:String):Void
	{
		if (deviceID != null && deviceID != "" && deviceID.indexOf("emulator") == -1)
		{
			if (deviceID.indexOf(":") > 0)
			{
				deviceID = deviceID.substr(0, deviceID.indexOf(":"));
			}

			System.runCommand(adbPath, adbName, ["connect", deviceID]);
		}
	}

	public static function getBuildToolsVersion(project:HXProject):String
	{
		var buildToolsPath = Path.combine(project.environment.get("ANDROID_SDK"), "build-tools/");

		var version = ~/^(\d+)\.(\d+)\.(\d+)$/i;
		var current = {major: 0, minor: 0, micro: 0};

		if (!FileSystem.exists(buildToolsPath))
		{
			Log.error("Cannot find directory \"" + buildToolsPath + "\"");
		}

		for (buildTool in FileSystem.readDirectory(buildToolsPath))
		{
			// gradle only likes simple version numbers (x.y.z)

			if (!version.match(buildTool))
			{
				continue;
			}

			var newVersion =
				{
					major: Std.parseInt(version.matched(1)),
					minor: Std.parseInt(version.matched(2)),
					micro: Std.parseInt(version.matched(3))
				};

			if (newVersion.major != current.major)
			{
				if (newVersion.major > current.major)
				{
					current = newVersion;
				}
			}
			else if (newVersion.minor != current.minor)
			{
				if (newVersion.minor > current.minor)
				{
					current = newVersion;
				}
			}
			else
			{
				if (newVersion.micro > current.micro)
				{
					current = newVersion;
				}
			}
		}

		return '${current.major}.${current.minor}.${current.micro}';
	}

	public static function getDeviceSDKVersion(deviceID:String):Int
	{
		var devices = listDevices();

		if (devices.length > 0)
		{
			var tempFile = System.getTemporaryFile();

			var args = ["wait-for-device", "shell", "getprop", "ro.build.version.sdk", ">", tempFile];

			if (deviceID != null && deviceID != "")
			{
				args.unshift(deviceID);
				args.unshift("-s");

				// connect (deviceID);
			}

			if (System.hostPlatform == MAC)
			{
				System.runCommand(adbPath, "perl", ["-e", 'alarm shift @ARGV; exec @ARGV', "3", adbName].concat(args), true, true);
			}
			else
			{
				System.runCommand(adbPath, adbName, args, true, true);
			}

			if (FileSystem.exists(tempFile))
			{
				var output = File.getContent(tempFile);
				FileSystem.deleteFile(tempFile);
				return Std.parseInt(output);
			}
		}

		return 0;
	}

	public static function initialize(project:HXProject):Void
	{
		adbPath = project.environment.get("ANDROID_SDK") + "/tools/";
		androidPath = project.environment.get("ANDROID_SDK") + "/tools/";
		emulatorPath = project.environment.get("ANDROID_SDK") + "/tools/";

		adbName = "adb";
		androidName = "android";
		emulatorName = "emulator";

		if (System.hostPlatform == WINDOWS)
		{
			adbName += ".exe";
			androidName += ".bat";
			emulatorName += ".exe";
		}

		if (!FileSystem.exists(adbPath + adbName))
		{
			adbPath = project.environment.get("ANDROID_SDK") + "/platform-tools/";
		}

		if (System.hostPlatform != WINDOWS)
		{
			adbName = "./" + adbName;
			androidName = "./" + androidName;
			emulatorName = "./" + emulatorName;
		}

		if (project.environment.exists("JAVA_HOME"))
		{
			Sys.putEnv("JAVA_HOME", project.environment.get("JAVA_HOME"));
		}
	}

	public static function install(project:HXProject, targetPath:String, deviceID:String = null):String
	{
		if (project.targetFlags.exists("emulator") || project.targetFlags.exists("simulator"))
		{
			Log.info("", "Searching for Android emulator");

			var devices = listDevices();

			for (device in devices)
			{
				if (device.indexOf("emulator") > -1)
				{
					deviceID = device;
				}
			}

			// TODO: Check emulator capabilities, if it is GPU enabled and if API LEVEL >15 (http://developer.android.com/tools/devices/emulator.html)

			if (deviceID == null)
			{
				var avds = listAVDs();

				if (avds.length == 0)
				{
					Log.error("Cannot find emulator, please use AVD manager to create one");
				}

				Log.info("Starting AVD: " + avds[0]);

				System.runProcess(emulatorPath, emulatorName, ["-avd", avds[0], "-gpu", "on"], false);

				while (deviceID == null)
				{
					devices = listDevices();

					for (device in devices)
					{
						if (device.indexOf("emulator") > -1)
						{
							deviceID = device;
						}
					}

					if (deviceID == null)
					{
						Sys.sleep(3);

						if (!Log.verbose)
						{
							Sys.print(".");
						}
					}
					else
					{
						Sys.println("");
					}
				}
			}

			System.runCommand(adbPath, adbName, ["-s", deviceID, "shell", "input", "keyevent", "82"]);
		}

		var args = ["install", "-r"];

		// if (getDeviceSDKVersion (deviceID) > 16) {

		args.push("-d");

		// }

		args.push(targetPath);

		if (deviceID != null && deviceID != "")
		{
			args.unshift(deviceID);
			args.unshift("-s");

			connect(deviceID);
		}

		System.runCommand(adbPath, adbName, args);

		return deviceID;
	}

	public static function listAVDs():Array<String>
	{
		var avds = new Array<String>();
		var output = System.runProcess(androidPath, androidName, ["list", "avd"]);

		if (output != null && output != "")
		{
			for (line in output.split("\n"))
			{
				if (line.indexOf("Name") > -1)
				{
					avds.push(StringTools.trim(line.substr(line.indexOf("Name") + 6)));
				}
			}
		}

		return avds;
	}

	public static function listDevices():Array<String>
	{
		var devices = new Array<String>();
		var output = "";

		if (System.hostPlatform != WINDOWS)
		{
			/*
			 * using System.runProcess on *NIX platforms for `adb devices` usually
			 * hangs when adb also starts the server.
			 * To avoid this, we start the server beforehand
			 */
			System.runCommand(adbPath, adbName, ["start-server"], true);
		}
		output = System.runProcess(adbPath, adbName, ["devices"], true, true);

		if (output != null && output != "")
		{
			for (line in output.split("\n"))
			{
				if (line.indexOf("device") > -1 && line.indexOf("attached") == -1)
				{
					devices.push(StringTools.trim(line.substr(0, line.indexOf("device"))));
				}
			}
		}

		return devices;
	}

	public static function run(activityName:String, deviceID:String = null):Void
	{
		var args = ["shell", "am", "start", "-a", "android.intent.action.MAIN", "-n", activityName];

		if (deviceID != null && deviceID != "")
		{
			args.unshift(deviceID);
			args.unshift("-s");

			connect(deviceID);
		}

		System.runCommand(adbPath, adbName, args);
	}

	public static function trace(project:HXProject, debug:Bool, deviceID:String = null, customFilter:String = null):Void
	{
		// Use -DFULL_LOGCAT or  <set name="FULL_LOGCAT" /> if you do not want to filter log messages

		var args = ["logcat"];

		if (deviceID != null && deviceID != "")
		{
			args.unshift(deviceID);
			args.unshift("-s");

			connect(deviceID);
		}

		if (customFilter != null)
		{
			System.runCommand(adbPath, adbName, args.concat([customFilter]));
		}
		else if (project.environment.exists("FULL_LOGCAT") || Log.verbose)
		{
			System.runCommand(adbPath, adbName, args.concat(["-c"]));
			System.runCommand(adbPath, adbName, args);
		}
		else if (debug)
		{
			var filter = "*:E";
			var includeTags = [
				"lime",
				"Lime",
				"Main",
				"GameActivity",
				"SDLActivity",
				"GLThread",
				"trace",
				"Haxe"
			];

			for (tag in includeTags)
			{
				filter += " " + tag + ":D";
			}

			Sys.println(filter);

			System.runCommand(adbPath, adbName, args.concat([filter]));
		}
		else
		{
			System.runCommand(adbPath, adbName, args.concat(["*:S trace:I"]));
		}
	}

	public static function uninstall(packageName:String, deviceID:String = null):Void
	{
		var args = ["uninstall", packageName];

		if (deviceID != null && deviceID != "")
		{
			args.unshift(deviceID);
			args.unshift("-s");

			connect(deviceID);
		}

		System.runCommand(adbPath, adbName, args);
	}
}
