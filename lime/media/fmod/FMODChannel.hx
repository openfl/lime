package lime.media.fmod;
#if lime_console


import lime.ConsoleIncludePaths;


@:include("ConsoleFmodChannel.h")
@:native("cpp::Struct<lime::ConsoleFmodChannel>")
extern class FMODChannel {


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

	// getVolume retrieves the current linear volume level of the channel.
	public function getVolume ():cpp.Float32;

	// setVolume sets the channel's linear volume level.
	public function setVolume (volume:cpp.Float32):Void;


	// INVALID represents an invalid channel handle
	public static var INVALID (get, never):FMODChannel;


	private function get_valid ():Bool;

	@:native("lime::ConsoleFmodChannel")
	private static function get_INVALID ():FMODChannel;


}


#end
