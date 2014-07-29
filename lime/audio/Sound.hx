package lime.audio;


import lime.system.System;
import lime.utils.ByteArray;


class Sound {
	
	
	public var bitsPerSample:Int;
	public var channels:Int;
	public var data:ByteArray;
	public var sampleRate:Int;
	
	
	public function new () {
		
		
		
	}
	
	
	public static function loadFromBytes (bytes:ByteArray):Sound {
		
		#if (cpp || neko)
		
		var data = lime_sound_load_bytes (bytes);
		var sound = new Sound ();
		sound.bitsPerSample = data.bitsPerSample;
		sound.channels = data.channels;
		sound.data = data.data;
		sound.sampleRate = data.sampleRate;
		return sound;
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function loadFromFile (path:String):Sound {
		
		#if (cpp || neko)
		
		var data = lime_sound_load (path);
		var sound = new Sound ();
		sound.bitsPerSample = data.bitsPerSample;
		sound.channels = data.channels;
		sound.data = data.data;
		sound.sampleRate = data.sampleRate;
		return sound;
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_sound_load = System.load ("lime", "lime_sound_load", 1);
	private static var lime_sound_load_bytes = System.load ("lime", "lime_sound_load_bytes", 1);
	#end
	
	
}