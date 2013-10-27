package project;


import helpers.ArrayHelper;
import helpers.ObjectHelper;


class PlatformConfig {
	
	
	public var android:AndroidConfig;
	public var cpp:CPPConfig;
	public var ios:IOSConfig;
	
	private static var defaultAndroid:AndroidConfig = {
		
		extensions: [],
		installLocation: "preferExternal",
		minimumSDKVersion: 9,
		permissions: [ "android.permission.WAKE_LOCK", "android.permission.INTERNET", "android.permission.VIBRATE", "android.permission.ACCESS_NETWORK_STATE" ],
		targetSDKVersion: 16
		
	};
	
	private static var defaultCPP:CPPConfig = {
		
		buildLibrary: "hxlibc",
		requireBuild: true
		
	}
	
	private static var defaultIOS:IOSConfig = {
		
		compiler: "clang",
		deployment: /*3.2*/ 5,
		device: IOSConfigDevice.UNIVERSAL,
		linkerFlags: "",
		prerenderedIcon: false
		
	};
	
	
	public function new () {
		
		android = { };
		cpp = { };
		ios = { };
		
		ObjectHelper.copyFields (defaultAndroid, android);
		ObjectHelper.copyFields (defaultCPP, cpp);
		ObjectHelper.copyFields (defaultIOS, ios);
		
	}
	
	
	public function clone ():PlatformConfig {
		
		var copy = new PlatformConfig ();
		
		ObjectHelper.copyFields (android, copy.android);
		ObjectHelper.copyFields (defaultCPP, copy.cpp);
		ObjectHelper.copyFields (ios, copy.ios);
		
		return copy;
		
	}
	
	
	public function merge (config:PlatformConfig):Void {
		
		var extensions = ArrayHelper.concatUnique (android.extensions, config.android.extensions);
		var permissions = ArrayHelper.concatUnique (android.permissions, config.android.permissions);
		
		ObjectHelper.copyUniqueFields (config.android, android, defaultAndroid);
		
		android.extensions = extensions;
		android.permissions = permissions;
		
		ObjectHelper.copyUniqueFields (config.cpp, cpp, defaultCPP);
		ObjectHelper.copyUniqueFields (config.ios, ios, defaultIOS);
		
	}
	
	
	public function populate ():Void {
		
		ObjectHelper.copyMissingFields (android, defaultAndroid);
		ObjectHelper.copyMissingFields (cpp, defaultCPP);
		ObjectHelper.copyMissingFields (ios, defaultIOS);
		
	}
	
	
}


typedef AndroidConfig = {
	
	@:optional var extensions:Array<String>;
	@:optional var installLocation:String;
	@:optional var minimumSDKVersion:Int;
	@:optional var permissions:Array<String>;
	@:optional var targetSDKVersion:Int;
	
}


typedef CPPConfig = {
	
	@:optional var buildLibrary:String;
	@:optional var requireBuild:Bool;
	
}


typedef IOSConfig = {
	
	@:optional var compiler:String;
	@:optional var deployment:Float;
	@:optional var device:IOSConfigDevice;
	@:optional var linkerFlags:String;
	@:optional var prerenderedIcon:Bool;
	
}


enum IOSConfigDevice {
	
	UNIVERSAL;
	IPHONE;
	IPAD;
	
}