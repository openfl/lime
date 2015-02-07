package lime.audio.fmod;
#if lime_console


import lime.system.System;
import lime.utils.ByteArray;


abstract Sound(Int) {


	public var valid (get, never):Bool;


	public static inline function fromBytes (bytes:ByteArray):Sound {

		// TODO(james4k): with FMOD_OPENMEMORY_POINT? We probably want to
		// discourage this, or even not support it. Should avoid using haxe's
		// heap when feasible.

		#if lime_console
		trace("not implemented");
		return cast (0, Sound);
		#end

	}


	public static inline function fromFile (name:String):Sound {

		#if lime_console
		return lime_fmod_sound_create (name);
		#end

	}


	public inline function play ():Channel {

		#if lime_console
		return lime_fmod_sound_play (this);
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
	private static var lime_fmod_sound_create:Dynamic = System.load ("lime", "lime_fmod_sound_create", 1);
	private static var lime_fmod_sound_play:Dynamic = System.load ("lime", "lime_fmod_sound_play", 1);
	private static var lime_fmod_sound_release:Dynamic = System.load ("lime", "lime_fmod_sound_release", 1);
	#end


}


#end
