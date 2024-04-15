package flash.media;

@:native("flash.media.AudioPlaybackMode")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract AudioPlaybackMode(String)
{
	var AMBIENT = "ambient";
	var MEDIA = "media";
	var VOICE = "voice";
}
