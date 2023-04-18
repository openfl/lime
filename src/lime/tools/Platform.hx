package lime.tools;

@:enum abstract Platform(String)
{
	var AIR = "air";
	var ANDROID = "android";
	var BLACKBERRY = "blackberry";
	var CONSOLE_PC = "console-pc";
	var FIREFOX = "firefox";
	var FLASH = "flash";
	var HTML5 = "html5";
	var IOS = "ios";
	var LINUX = "linux";
	var MAC = "mac";
	var PS3 = "ps3";
	var PS4 = "ps4";
	var TIZEN = "tizen";
	var VITA = "vita";
	var WINDOWS = "windows";
	var WEBOS = "webos";
	var WIIU = "wiiu";
	var XBOX1 = "xbox1";
	var EMSCRIPTEN = "emscripten";
	var TVOS = "tvos";
	var CUSTOM = null;
}
