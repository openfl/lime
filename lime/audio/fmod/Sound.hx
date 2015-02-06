package lime.audio.fmod;


import lime.system.System;


abstract Sound(Int) {


	public var valid (get, never):Bool;


	public inline function play ():Void {

		#if lime_console
		// TODO(james4k): return channel
		lime_fmod_sound_play (this);
		#end

	}


	public inline function release ():Void {

		#if lime_console
		lime_fmod_sound_release (this);
		this = 0;
		#end

	}



	private inline function get_valid ():Bool {

		return this != 0;

	}


	#if lime_console
	private static var lime_fmod_sound_play:Dynamic = System.load ("lime", "lime_fmod_sound_play", 1);
	private static var lime_fmod_sound_release:Dynamic = System.load ("lime", "lime_fmod_sound_release", 1);
	#end


}

