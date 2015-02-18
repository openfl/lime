package lime.project;


@:enum abstract Platform(String) {
	
	var ANDROID = "Android";
	var BLACKBERRY = "BlackBerry";
	var FIREFOX = "Firefox";
	var FLASH = "Flash";
	var HTML5 = "HTML5";
	var IOS = "iOS";
	var LINUX = "Linux";
	var MAC = "Mac";
	var TIZEN = "Tizen";
	var WINDOWS = "Windows";
	var WEBOS = "webOS";
	var EMSCRIPTEN = "Emscripten";
	var CUSTOM = null;
	
}