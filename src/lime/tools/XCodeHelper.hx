package lime.tools;


import hxp.*;
import lime.tools.Project;


class XCodeHelper {


	private static inline var DEFAULT_IPAD_SIMULATOR = "ipad-air";
	private static inline var DEFAULT_IPHONE_SIMULATOR = "iphone-6";


	private static function extractSimulatorFlagName (line:String):String {

		var device = line.substring (0, line.indexOf ("(") - 1);
		device = device.toLowerCase ();
		device = StringTools.replace (device, " ", "-");
		return device;

	}


	private static function extractSimulatorFullName (line:String):String {

		var name = "";

		if (line.indexOf ("inch") > -1 || line.indexOf ("generation") > -1) {

			name = line.substring (0, line.indexOf (")") + 1);

		} else {

			name = line.substring (0, line.indexOf ("(") - 1);

		}

		return name;

	}


	private static function extractSimulatorID (line:String):String {

		var id = line.substring (line.indexOf ("(") + 1, line.indexOf (")"));

		if (id.indexOf ("inch") > -1 || id.indexOf ("generation") > -1) {

			var startIndex = line.indexOf (")") + 2;
			id = line.substring (line.indexOf ("(", startIndex) + 1, line.indexOf (")", startIndex));

		}

		return id;

	}


	public static function getSelectedSimulator (project:Project):SimulatorInfo {

		var output = getSimulators ();
		var lines = output.split ("\n");
		var foundSection = false;
		var device = "";
		var deviceID = "";
		var deviceName = "";
		var devices = new Map<String, SimulatorInfo> ();
		var currentDevice:SimulatorInfo = null;

		for (line in lines) {

			if (StringTools.startsWith (line, "--")) {

				if (line.indexOf ("iOS") > -1) {

					foundSection = true;

				} else if (foundSection) {

					break;

				}

			} else if (foundSection) {

				deviceName = extractSimulatorFullName (StringTools.trim (line));
				deviceID = extractSimulatorID (StringTools.trim (line));
				device = extractSimulatorFlagName (StringTools.trim (line));
				devices.set (device, { id: deviceID, name: deviceName });

				if (project.targetFlags.exists (device)) {

					currentDevice = devices.get (device);
					break;

				}

			}
		}

		if (currentDevice == null) {

			if (project.targetFlags.exists ("ipad")) {

				currentDevice = devices.get (DEFAULT_IPAD_SIMULATOR);

			} else {

				currentDevice = devices.get (DEFAULT_IPHONE_SIMULATOR);

			}
		}

		return currentDevice;

	}


	public static function getSimulatorID (project:Project):String {

		return getSelectedSimulator (project).id;

	}


	public static function getSimulatorName (project:Project):String {

		return getSelectedSimulator (project).name;

	}


	private static function getSimulators ():String {

		return System.runProcess ("", "xcrun", [ "simctl", "list", "devices" ]);

	}


}


private typedef SimulatorInfo = {

	public var id:String;
	public var name:String;

}