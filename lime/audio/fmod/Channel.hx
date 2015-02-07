package lime.audio.fmod;
#if lime_console


import lime.system.System;
import lime.utils.ByteArray;


abstract Channel(Int) {


	public var valid (get, never):Bool;


	public static inline function fromHandle (handle:Int):Channel {

		#if lime_console
		trace("not implemented");	
		return cast (0, Channel);
		#end
	
	}


	public inline function pause ():Void {

		#if lime_console
		lime_fmod_channel_pause (this);
		#end

	}


	public inline function resume ():Void {

		#if lime_console
		lime_fmod_channel_resume (this);
		#end

	}


	public inline function stop ():Void {

		#if lime_console
		lime_fmod_channel_stop (this);
		this = 0;
		#end

	}



	private inline function get_valid ():Bool {

		return this != 0;

	}


	#if lime_console
	private static var lime_fmod_channel_pause:Dynamic = System.load ("lime", "lime_fmod_channel_pause", 1);
	private static var lime_fmod_channel_resume:Dynamic = System.load ("lime", "lime_fmod_channel_resume", 1);
	private static var lime_fmod_channel_stop:Dynamic = System.load ("lime", "lime_fmod_channel_stop", 1);
	#end


}


#end
