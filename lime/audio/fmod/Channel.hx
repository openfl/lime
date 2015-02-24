package lime.audio.fmod;
#if lime_console


import lime.ConsoleIncludePaths;
import lime.system.System;
import lime.utils.ByteArray;


@:include("ConsoleFmodAPI.h")
@:native("lime::hxapi::ConsoleFmodChannel")
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


	private function get_valid ():Bool;


}


#end
