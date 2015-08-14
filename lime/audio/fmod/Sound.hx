package lime.audio.fmod;
#if lime_console


import lime.ConsoleIncludePaths;
import lime.system.System;
import lime.utils.ByteArray;


@:include("ConsoleFmodSound.h")
@:native("cpp::Struct<lime::ConsoleFmodSound>")
extern class Sound {


	// valid returns true if this represents a valid handle to a sound.
	public var valid (get, never):Bool;


	// fromFile creates a sound from the named file.
	@:native("lime::ConsoleFmodSound::fromFile")
	public static function fromFile (name:String):Sound;


	// play plays the sound and returns the channel it was assigned.
	public function play ():Channel;


	// release releases the sound.
	public function release ():Void;


	private function get_valid ():Bool;


}


#end
