package lime.media;


import lime.system.System;
import lime.utils.ByteArray;
import lime.utils.Float32Array;


class AudioBuffer {
	
	
	public var bitsPerSample:Int;
	public var channels:Int;
	public var data:Float32Array;
	public var sampleRate:Int;
	
	
	public function new () {
		
		
		
	}
	
	
	public static function fromBytes (bytes:ByteArray):AudioBuffer {
		
		#if (cpp || neko)
		
		var data = lime_audio_load (bytes);
		var audioBuffer = new AudioBuffer ();
		audioBuffer.bitsPerSample = data.bitsPerSample;
		audioBuffer.channels = data.channels;
		audioBuffer.data = data.data;
		audioBuffer.sampleRate = data.sampleRate;
		return audioBuffer;
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function fromFile (path:String):AudioBuffer {
		
		#if (cpp || neko)
		
		var data = lime_audio_load (path);
		var audioBuffer = new AudioBuffer ();
		audioBuffer.bitsPerSample = data.bitsPerSample;
		audioBuffer.channels = data.channels;
		audioBuffer.data = data.data;
		audioBuffer.sampleRate = data.sampleRate;
		return audioBuffer;
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_audio_load:Dynamic = System.load ("lime", "lime_audio_load", 1);
	#end
	
	
}