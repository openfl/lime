package lime.audio.fmod;
#if lime_console


import lime.ConsoleIncludePaths;
import lime.system.System;
import lime.utils.ByteArray;


@:include("ConsoleFmodChannel.h")
@:native("cpp::Struct<lime::ConsoleFmodChannel>")
extern class Channel {


	// valid is true if this represents a valid handle to a channel.
	public var valid (get, never):Bool;


	// pause sets channel to a paused state.
	public function pause ():Void;

	// resume sets channel to an unpaused state.
	public function resume ():Void;

	// stop stops the channel from playing, making it available for another
	// sound to use.
	public function stop ():Void;


	// getLoopCount retrieves the current loop count for the channel.
	public function getLoopCount ():Int;

	// setLoopCount sets the channel to loop count times before stopping.
	public function setLoopCount (count:Int):Void;


	// INVALID represents an invalid channel handle
	public static var INVALID (get, never):Channel;


	private function get_valid ():Bool;

	@:native("lime::ConsoleFmodChannel")
	private static function get_INVALID ():Channel;


}


#end
