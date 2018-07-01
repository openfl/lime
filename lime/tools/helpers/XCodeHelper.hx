package lime.tools.helpers;

import lime.tools.helpers.ProcessHelper;

private class SimulatorInfo {
	public var id: String;
	public var name: String;
	public function new(id: String, name: String) {
		this.id = id;
		this.name = name;
	}
}
class XCodeHelper {
	static inline var DefaultIPadSimulator = "ipad-air";
	static inline var DefaultIPhoneSimulator = "iphone-6";
	public function new () {}
	public static function getSimulatorId(targetFlags: Map<String, String>): String {
		return getSelectedSimulator(targetFlags).id;
	}
	public static function getSimulatorName(targetFlags: Map<String, String>): String {
		return getSelectedSimulator(targetFlags).name;
	}
	static function getSelectedSimulator(targetFlags: Map<String, String>): SimulatorInfo {
		var output = getSimulators();
		var lines = output.split("\n");
		var foundSection = false;
		var device = "";
		var deviceID = "";
		var deviceName = "";
		var devices = new Map<String, SimulatorInfo> ();
		var currentDevice: Null<SimulatorInfo> = null;
		
		for (line in lines) {
			if (StringTools.startsWith (line, "--")) {
				if (line.indexOf("iOS") > -1) {
					foundSection = true;
				} else if (foundSection) {
					break;
				}
			} else if (foundSection) {
				deviceName = extractSimulatorFullName(StringTools.trim(line));
				deviceID = extractSimulatorId(StringTools.trim(line));
				device = extractSimulatorFlagName(StringTools.trim(line));
				devices.set(device, new SimulatorInfo(deviceID, deviceName));
				if (targetFlags.exists(device)) {
					currentDevice = devices.get(device);
					break;	
				}
			}
		}
		if (currentDevice == null) {
			if (targetFlags.exists("ipad")) {
				currentDevice = devices.get(DefaultIPadSimulator);
			} else {
				currentDevice = devices.get(DefaultIPhoneSimulator);
			}
		}
		return currentDevice;
	}
	static function getSimulators(): String {
		return ProcessHelper.runProcess("", "xcrun", ["simctl", "list", "devices"]);
	}
	static function extractSimulatorId(line: String): String {
		var id = line.substring(line.indexOf("(") + 1, line.indexOf(")"));
		if (id.indexOf("inch") > -1 || id.indexOf("generation") > -1) {
			var startIndex = line.indexOf(")") + 2;
			id = line.substring(line.indexOf("(", startIndex) + 1, line.indexOf(")", startIndex));
		}
		return id;
	}
	static function extractSimulatorFullName(line: String): String {
		var name = "";
		if (line.indexOf("inch") > -1 || line.indexOf("generation") > -1) {
			name = line.substring(0, line.indexOf(")") + 1);
		} else {
			name = line.substring(0, line.indexOf("(") - 1);
		}
		return name;
	}
	static function extractSimulatorFlagName(line: String): String {
		var device = line.substring(0, line.indexOf("(") - 1);
		device = device.toLowerCase();
		device = StringTools.replace(device, " ", "-");
		return device;
	}
}
