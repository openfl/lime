package lime.tools;

import hxp.*;
import lime.tools.HXProject;

class XCodeHelper
{
	// different computers may have different sets of simulators installed
	// so there isn't necessarily a reasonable default for ipads
	private static var DEFAULT_IPAD_SIMULATOR_NAMES = [
		"ipad",
		"ipad-air"
	];
	private static var DEFAULT_IPAD_AIR_SIMULATOR_FALLBACK_REGEX = ~/ipad-air-.+/g;
	private static var DEFAULT_IPAD_SIMULATOR_FALLBACK_REGEX = ~/ipad-.+/g;
	// this should be a standard iPhone of a particular generation
	private static var DEFAULT_IPHONE_SIMULATOR_REGEX = ~/iphone-\d+/g;
	private static var DEFAULT_IPHONE_SIMULATOR_FALLBACK_REGEX = ~/iphone-.+/g;

	private static function extractSimulatorFlagName(line:String):String
	{
		var device = line.substring(0, line.indexOf("(") - 1);
		device = device.toLowerCase();
		device = StringTools.replace(device, " ", "-");
		return device;
	}

	private static function extractSimulatorFullName(line:String):String
	{
		var name = "";

		if (line.indexOf("inch") > -1 || line.indexOf("generation") > -1)
		{
			name = line.substring(0, line.indexOf(")") + 1);
		}
		else
		{
			name = line.substring(0, line.indexOf("(") - 1);
		}

		return name;
	}

	private static function extractSimulatorID(line:String):String
	{
		var id = line.substring(line.indexOf("(") + 1, line.indexOf(")"));

		if (id.indexOf("inch") > -1 || id.indexOf("generation") > -1)
		{
			var startIndex = line.indexOf(")") + 2;
			id = line.substring(line.indexOf("(", startIndex) + 1, line.indexOf(")", startIndex));
		}

		return id;
	}

	public static function getSelectedSimulator(project:HXProject):SimulatorInfo
	{
		var output = getSimulators();
		var lines = output.split("\n");
		var foundSection = false;
		var device = "";
		var deviceID = "";
		var deviceName = "";
		var devices = new Map<String, SimulatorInfo>();
		var currentDevice:SimulatorInfo = null;

		for (line in lines)
		{
			if (StringTools.startsWith(line, "--"))
			{
				if (line.indexOf("Unavailable") > -1)
				{
					foundSection = false;
				}
				else if (line.indexOf("iOS") > -1)
				{
					foundSection = true;
				}
				else if (foundSection)
				{
					break;
				}
			}
			else if (foundSection)
			{
				deviceName = extractSimulatorFullName(StringTools.trim(line));
				deviceID = extractSimulatorID(StringTools.trim(line));
				device = extractSimulatorFlagName(StringTools.trim(line));
				devices.set(device, {id: deviceID, name: deviceName});

				if (project.targetFlags.exists(device))
				{
					currentDevice = devices.get(device);
					break;
				}
			}
		}

		if (currentDevice == null)
		{
			if (project.targetFlags.exists("ipad") || project.config.getString("ios.device", "universal") == "ipad")
			{
				for (device in DEFAULT_IPAD_SIMULATOR_NAMES)
				{
					// try to find a relatively standard ipad simulator
					currentDevice = devices.get(device);
					if (currentDevice != null)
					{
						break;
					}
				}
				// if we couldn't find one of the default names, let's try to
				// find any iPad Air, which should be a reasonable default
				if (currentDevice == null)
				{
					for (device in devices.keys())
					{
						if (DEFAULT_IPAD_AIR_SIMULATOR_FALLBACK_REGEX.match(device))
						{
							currentDevice = devices.get(device);
							break;
						}
					}
				}
				// worst case, if we still haven't found a good name, choose the
				// first ipad that we find. it could be a mini or pro, which
				// might not necessarily be ideal, but it's better than nothing.
				if (currentDevice == null)
				{
					for (device in devices.keys())
					{
						if (DEFAULT_IPAD_SIMULATOR_FALLBACK_REGEX.match(device))
						{
							currentDevice = devices.get(device);
							break;
						}
					}
				}
			}
			else
			{
				for (device in devices.keys())
				{
					// try to find a standard iphone, which should have an name
					// like iphone-15 or iphone-16
					if (DEFAULT_IPHONE_SIMULATOR_REGEX.match(device))
					{
						currentDevice = devices.get(device);
						break;
					}
				}
				// of we can't find a standard iphone for some reason, choose
				// the first iphone- name that we find. it could be a plus, pro,
				// se, or something that might not necessarily be ideal, but
				// it's better than nothing at all.
				if (currentDevice == null)
				{
					for (device in devices.keys())
					{
						if (DEFAULT_IPHONE_SIMULATOR_FALLBACK_REGEX.match(device))
						{
							currentDevice = devices.get(device);
							break;
						}
					}
				}
			}
		}

		return currentDevice;
	}

	public static function getSimulatorID(project:HXProject):String
	{
		var simulator = getSelectedSimulator(project);
		if (simulator == null)
		{
			return null;
		}
		return simulator.id;
	}

	public static function getSimulatorName(project:HXProject):String
	{
		var simulator = getSelectedSimulator(project);
		if (simulator == null)
		{
			return null;
		}
		return simulator.name;
	}

	private static function getSimulators():String
	{
		return System.runProcess("", "xcrun", ["simctl", "list", "devices"]);
	}
}

private typedef SimulatorInfo =
{
	public var id:String;
	public var name:String;
}
