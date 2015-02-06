package lime.audio.fmod;


import lime.system.System;


class FMOD {
	

	public static function createSound (name:String):Sound {

		#if lime_console
		return lime_fmod_sound_create (name);		
		#end
	
	}


	#if lime_console
	private static var lime_fmod_sound_create:Dynamic = System.load ("lime", "lime_fmod_sound_create", 1);
	#end
	
	
}
