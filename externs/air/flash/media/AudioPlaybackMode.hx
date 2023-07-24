package flash.media;

@:native("flash.media.AudioPlaybackMode")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract AudioPlaybackMode(String)
{
	var AMBIENT;
	var MEDIA;
	var VOICE;
}
