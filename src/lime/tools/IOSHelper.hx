package lime.tools;

import hxp.*;
import lime.tools.Platform;
import lime.tools.HXProject;
import sys.io.Process;
import sys.FileSystem;

class IOSHelper
{
	private static var initialized = false;

	/**
		Whether a simulator build is for arm64, which the simulator runs on an Apple
		silicon Mac without Rosetta, rather than x86_64. It is where the Mac is Apple
		silicon, or `-arm64` asks for it, as long as the hxcpp that builds the
		libraries can build them for the arm64 simulator and every native library has
		an arm64 simulator build. `-x86_64` asks for an x86_64 build.
	**/
	public static function useArm64Simulator(project:HXProject):Bool
	{
		if (project.targetFlags.exists("x86_64")
			|| project.targetFlags.exists("i386")
			|| project.targetFlags.exists("32")
			|| project.targetFlags.exists("x86_32"))
		{
			return false;
		}

		var asked = project.targetFlags.exists("arm64");
		if (!asked && !isAppleSiliconMac()) return false;

		var buildLibrary = project.config.getString("cpp.buildLibrary", "hxcpp");

		if (!buildsArm64Simulator(buildLibrary))
		{
			if (asked) Log.warn("The " + buildLibrary + " haxelib can't build for the arm64 simulator, so the simulator build is for x86_64. libhxcpp can.");
			return false;
		}

		for (ndll in project.ndlls)
		{
			if (!FileSystem.exists(NDLL.getLibraryPath(ndll, "iPhone", "lib", ".iphonesim-arm64.a")))
			{
				if (asked) Log.warn("\"" + ndll.name + "\" has no library for the arm64 simulator, so the simulator build is for x86_64");
				return false;
			}
		}

		// A static library a project depends on is linked into every architecture, and one built
		// for devices can't link into an arm64 simulator build, so that is only made when asked for
		if (!asked)
		{
			for (dependency in project.dependencies)
			{
				if (StringTools.endsWith(dependency.path, ".a")) return false;
			}
		}

		return true;
	}

	/**
		Whether the hxcpp at `buildLibrary` builds libraries for the arm64 simulator,
		as libhxcpp does and hxcpp up to 4.3 does not.
	**/
	public static function buildsArm64Simulator(buildLibrary:String = "hxcpp"):Bool
	{
		try
		{
			var path = Haxelib.getPath(new Haxelib(buildLibrary));
			if (path == null || path == "") return false;

			var finishSetup = Path.combine(path, "toolchain/finish-setup.xml");
			return FileSystem.exists(finishSetup) && sys.io.File.getContent(finishSetup).indexOf(".iphonesim-arm64") > -1;
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	/**
		Whether an app built with the hxcpp at `buildLibrary` links Security.framework.
		libhxcpp's TLS checks a server's certificate against the system's trust store on
		iOS and tvOS, and a static build there leaves the framework to the app's link;
		hxcpp up to 4.3 uses it on macOS only. Read from the hxcpp's own TLS build file,
		so an hxcpp that does not ask for it is built as before.
	**/
	public static function linksSecurityFramework(buildLibrary:String = "hxcpp"):Bool
	{
		try
		{
			var path = Haxelib.getPath(new Haxelib(buildLibrary));
			if (path == null || path == "") return false;

			var buildXml = Path.combine(path, "src/hx/libs/ssl/Build.xml");
			return FileSystem.exists(buildXml) && sslBuildLinksSecurity(sys.io.File.getContent(buildXml));
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	/**
		Whether `buildXml`, an hxcpp TLS library's Build.xml, links Security.framework on
		an Apple platform other than macOS: a `Security` flag with no condition, or none
		that limits it to macOS, on it or on a section around it.
	**/
	@:noCompletion public static function sslBuildLinksSecurity(buildXml:String):Bool
	{
		try
		{
			return hasSecurityFlag(Xml.parse(buildXml), false);
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	private static function hasSecurityFlag(parent:Xml, macOSOnly:Bool):Bool
	{
		for (element in parent.elements())
		{
			var condition = element.get("if");
			var limited = macOSOnly || (condition != null && (StringTools.trim(condition) == "macos" || StringTools.trim(condition) == "mac"));

			switch (element.nodeName)
			{
				case "flag", "vflag":
					if (element.get("value") == "Security" && !limited) return true;

				default:
					if (hasSecurityFlag(element, limited)) return true;
			}
		}

		return false;
	}

	private static var appleSiliconMac:Null<Bool>;

	// The Mac itself, which uname reports as x86_64 to tools that run through Rosetta
	private static function isAppleSiliconMac():Bool
	{
		if (appleSiliconMac == null)
		{
			var output = (System.hostPlatform == MAC) ? System.runProcess("", "sysctl", ["-n", "hw.optional.arm64"], true, true, true) : null;
			appleSiliconMac = (output != null && StringTools.trim(output) == "1");
		}

		return appleSiliconMac;
	}

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
		else
		{
			commands.push("build");
			if (project.targetFlags.exists("nosign"))
			{
				commands.push("CODE_SIGN_IDENTITY=\"\"");
				commands.push("CODE_SIGNING_REQUIRED=\"NO\"");
				commands.push("CODE_SIGN_ENTITLEMENTS=\"\"");
				commands.push("CODE_SIGNING_ALLOWED=\"NO\"");
			}
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

		var supportedExportMethods = ["adhoc", "development", "enterprise", "appstore"];
		var exportMethods:Array<String> = [];
		for (m in supportedExportMethods)
		{
			if (project.targetFlags.exists(m))
			{
				exportMethods.push(m);
			}
		}

		if (exportMethods.length == 0)
		{
			exportMethods.push("appstore");
		}

		for (exportMethod in exportMethods)
		{
			// generate IPA from xcarchive
			var exportCommands = commands.concat([]);

			exportCommands.push("-exportArchive");
			exportCommands.push("-archivePath");
			exportCommands.push(Path.combine("build", Path.combine(configuration + "-" + platformName, project.app.file + ".xcarchive")));
			exportCommands.push("-exportOptionsPlist");
			exportCommands.push(Path.combine(project.app.file, "exportOptions-" + exportMethod + ".plist"));
			exportCommands.push("-exportPath");
			exportCommands.push(Path.combine("dist", exportMethod));

			System.runCommand(workingDirectory, "xcodebuild", exportCommands);
		}
	}

	private static function getXCodeArgs(project:HXProject):Array<String>
	{
		var platformName = "iphoneos";
		var iphoneVersion = project.environment.get("IPHONE_VER");

		if (project.targetFlags.exists("simulator"))
		{
			platformName = "iphonesimulator";
		}

		var configuration = "Release";

		if (project.debug)
		{
			configuration = "Debug";
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
			if (project.targetFlags.exists("i386") || project.targetFlags.exists("32") || project.targetFlags.exists("x86_32"))
			{
				commands.push("-arch");
				commands.push("i386");
			}
			else
			{
				commands.push("-arch");
				commands.push(useArm64Simulator(project) ? "arm64" : "x86_64");
			}
		}
		else if (project.targetFlags.exists("armv7"))
		{
			commands.push("-arch");
			commands.push("armv7");
		}
		else if (project.targetFlags.exists("armv7s"))
		{
			commands.push("-arch");
			commands.push("armv7s");
		}
		else if (project.targetFlags.exists("arm64"))
		{
			commands.push("-arch");
			commands.push("arm64");
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

	public static function getSDKDirectory(project:HXProject):String
	{
		initialize(project);

		var platformName = "iPhoneOS";

		if (project.targetFlags.exists("simulator"))
		{
			platformName = "iPhoneSimulator";
		}

		var process = new Process("xcode-select", ["--print-path"]);
		var directory = process.stdout.readLine();
		process.close();

		if (directory == "" || directory.indexOf("Run xcode-select") > -1)
		{
			directory = "/Applications/Xcode.app/Contents/Developer";
		}

		directory += "/Platforms/"
			+ platformName
			+ ".platform/Developer/SDKs/"
			+ platformName
			+ project.environment.get("IPHONE_VER")
			+ ".sdk";
		return directory;
	}

	public static function getIOSVersion(project:HXProject):Void
	{
		if (!project.environment.exists("IPHONE_VER") || project.environment.get("IPHONE_VER") == "4.2")
		{
			if (!project.environment.exists("DEVELOPER_DIR") && System.hostPlatform == MAC)
			{
				var process = new Process("xcode-select", ["--print-path"]);
				var developerDir = process.stdout.readLine();
				process.close();

				project.environment.set("DEVELOPER_DIR", developerDir);
			}

			var devPath = project.environment.get("DEVELOPER_DIR") + "/Platforms/iPhoneOS.platform/Developer/SDKs";

			if (FileSystem.exists(devPath))
			{
				var files = FileSystem.readDirectory(devPath);
				var extractVersion = ~/^iPhoneOS(.*).sdk$/;
				var best = "0", version;

				for (file in files)
				{
					if (extractVersion.match(file))
					{
						version = extractVersion.matched(1);

						if (Std.parseFloat(version) > Std.parseFloat(best))
						{
							best = version;
						}
					}
				}

				if (best != "")
				{
					project.environment.set("IPHONE_VER", best);
				}
			}
		}
	}

	private static function getOSXVersion():String
	{
		var output = System.runProcess("", "sw_vers", ["-productVersion"]);

		return StringTools.trim(output);
	}

	public static function getProvisioningFile(project:HXProject = null):String
	{
		if (project != null && project.config.exists("ios.provisioning-profile"))
		{
			return Path.tryFullPath(project.config.getString("ios.provisioning-profile"));
		}
		else if (System.hostPlatform == MAC)
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
		}

		return "";
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
				applicationPath = workingDirectory + "/build/" + configuration + "-iphonesimulator/" + project.app.file + ".app";
			}

			var currentDeviceID = XCodeHelper.getSimulatorID(project);

			if (Log.verbose)
			{
				var currentSimulatorName = XCodeHelper.getSimulatorName(project);
				Log.info("Using iOS simulator: " + currentSimulatorName);
			}

			try
			{
				System.runProcess("", "open", ["-Ra", "iOS Simulator"], true, false);
				System.runCommand("", "open", ["-a", "iOS Simulator", "--args", "-CurrentDeviceUDID", currentDeviceID]);
			}
			catch (e:Dynamic)
			{
				System.runCommand("", "open", ["-a", "Simulator", "--args", "-CurrentDeviceUDID", currentDeviceID]);
			}

			waitForDeviceState("xcrun", ["simctl", "boot", currentDeviceID]);
			waitForDeviceState("xcrun", ["simctl", "uninstall", currentDeviceID, project.meta.packageName]);
			waitForDeviceState("xcrun", ["simctl", "install", currentDeviceID, applicationPath]);
			waitForDeviceState("xcrun", ["simctl", "launch", currentDeviceID, project.meta.packageName]);

			System.runCommand("", "tail", ["-F", "$HOME/Library/Logs/CoreSimulator/" + currentDeviceID + "/system.log"]);
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
				applicationPath = workingDirectory + "/build/" + configuration + "-iphoneos/" + project.app.file + ".app";
			}

			var requireIPad = project.config.getString("ios.device", "universal") == "ipad";
			var requireIPhone = project.config.getString("ios.device", "universal") == "iphone";

			var xcodeVersion = Std.parseFloat(getXcodeVersion());
			if (!Math.isNaN(xcodeVersion) && xcodeVersion >= 16)
			{
				// ios-deploy doesn't work with newer iOS SDKs where it can't
				// find DeveloperDiskImage.dmg. however, Xcode 16 adds new
				// commands for installing and launching apps on connected
				// devices, so we'll prefer those, if available.

				var deviceUUID:String = null;

				// we'll try various combinations of the following filters to
				// select an iOS device. there may be multiple devices to choose
				// from, so these filters help us figure out the best one.

				var filterPlatformIOS = "Platform == 'iOS'"; // includes iPadOS
				var filterDeveloperModeEnabled = "deviceProperties.developerModeStatus == 'enabled'";
				var filterStateConnected = "State == 'connected'";
				var filterStateAvailable = "State == 'available (paired)'";
				var filterTransportTypeWired = "connectionProperties.transportType == 'wired'";
				var filterTransportTypeLocalNetwork = "connectionProperties.transportType == 'localNetwork'";
				var filterDeviceTypeIPhone = "hardwareProperties.deviceType == 'iPhone'";
				var filterDeviceTypeIPad = "hardwareProperties.deviceType == 'iPad'";

				// first, some strictly required filters:
				// 1. the platform must always be iOS (which includes iPadOS).
				// 2. the device must be in developer mode.
				// 3. if required by the project config, limit to iPhone or iPad only
				var baseFilters = [filterPlatformIOS, filterDeveloperModeEnabled,];
				if (requireIPad)
				{
					baseFilters.push(filterDeviceTypeIPad);
				}
				else if (requireIPhone)
				{
					baseFilters.push(filterDeviceTypeIPhone);
				}

				// after that, we have the following preferences, in order:
				// 1. state: "connected" preferred over "available (paired)"
				// 2. transportType: "wired" preferred over "localNetwork"
				var stateFilters = [filterStateConnected, filterStateAvailable];
				var transportTypeFilters = [filterTransportTypeWired, filterTransportTypeLocalNetwork];
				for (stateFilter in stateFilters)
				{
					for (transportTypeFilter in transportTypeFilters)
					{
						deviceUUID = findDeviceUUIDWithFilters(baseFilters.concat([stateFilter, transportTypeFilter]));
						if (deviceUUID != null && deviceUUID.length > 0)
						{
							break;
						}
					}
					if (deviceUUID != null && deviceUUID.length > 0)
					{
						break;
					}
				}

				if (deviceUUID == null || deviceUUID.length == 0)
				{
					// devices running iOS 16 and older don't support
					// xcrun devicectl, so if no device was found, try falling
					// back to ios-deploy
					fallbackLaunch(project, applicationPath);
					// Log.error("No device connected");
					return;
				}

				if (Log.verbose)
				{
					Log.info("Detected iOS device UUID: " + deviceUUID);
				}

				System.runCommand("", "xcrun", [
					"devicectl",
					"device",
					"install",
					"app",
					"--device",
					deviceUUID,
					FileSystem.fullPath(applicationPath)
				]);
				System.runCommand("", "xcrun", [
					"devicectl",
					"device",
					"process",
					"launch",
					"--console",
					"--device",
					deviceUUID,
					project.meta.packageName
				]);
			}
			else
			{
				// continue using ios-deploy if Xcode version is 15 or older
				fallbackLaunch(project, applicationPath);
			}
		}
	}

	private static function findDeviceUUIDWithFilters(filters:Array<String>):String
	{
		var listDevicesOutput = System.runProcess("", "xcrun", [
			"devicectl",
			"list",
			"devices",
			"--hide-default-columns",
			"--columns",
			"Identifier",
			"--filter",
			filters.join(" AND ")
		]);
		var ready = false;
		for (line in listDevicesOutput.split("\n"))
		{
			if (!ready)
			{
				ready = StringTools.startsWith(line, "----");
				continue;
			}
			return line;
		}
		return null;
	}

	private static function fallbackLaunch(project:HXProject, applicationPath:String):Void
	{
		var templatePaths = [
			Path.combine(Haxelib.getPath(new Haxelib(#if lime "lime" #else "hxp" #end)), #if lime "templates" #else "" #end)
		].concat(project.templatePaths);
		var launcher = System.findTemplate(templatePaths, "bin/ios-deploy");
		Sys.command("chmod", ["+x", launcher]);

		System.runCommand("", launcher, [
			"install",
			"--noninteractive",
			"--debug",
			"--bundle",
			FileSystem.fullPath(applicationPath)
		]);
	}

	public static function sign(project:HXProject, workingDirectory:String):Void
	{
		initialize(project);

		var configuration = "Release";

		if (project.debug)
		{
			configuration = "Debug";
		}

		var identity = project.config.getString("ios.identity", "iPhone Developer");

		var commands = ["-s", identity, "CODE_SIGN_IDENTITY=" + identity];

		if (project.config.exists("ios.provisioning-profile"))
		{
			commands.push("PROVISIONING_PROFILE=" + project.config.getString("ios.provisioning-profile"));
		}

		var applicationPath = "build/" + configuration + "-iphoneos/" + project.app.file + ".app";
		commands.push(applicationPath);

		System.runCommand(workingDirectory, "codesign", commands, true, true);
	}

	private static function waitForDeviceState(command:String, args:Array<String>):Void
	{
		var output:String;

		while (true)
		{
			output = System.runProcess("", command, args, true, true, true);

			if (output != null && output.toLowerCase().indexOf("invalid device state") > -1)
			{
				Sys.sleep(3);
			}
			else
			{
				break;
			}
		}
	}
}
