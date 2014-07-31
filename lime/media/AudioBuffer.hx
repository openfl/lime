package lime.media;


import lime.media.openal.AL;
import lime.system.System;
import lime.utils.ByteArray;
import lime.utils.Float32Array;


class AudioBuffer {
	
	
	public var bitsPerSample:Int;
	public var channels:Int;
	public var data:Float32Array;
	public var id:UInt;
	public var sampleRate:Int;
	
	
	public function new () {
		
		id = 0;
		
	}
	
	
	public function createALBuffer ():Void {
		
		var format = 0;
		
		if (channels == 1) {
			
			if (bitsPerSample == 8) {
				
				format = AL.FORMAT_MONO8;
				
			} else if (bitsPerSample == 16) {
				
				format = AL.FORMAT_MONO16;
				
			}
			
		} else if (channels == 2) {
			
			if (bitsPerSample == 8) {
				
				format = AL.FORMAT_STEREO8;
				
			} else if (bitsPerSample == 16) {
				
				format = AL.FORMAT_STEREO16;
				
			}
			
		}
		
		id = AL.genBuffer ();
		AL.bufferData (id, format, data, data.length << 2, sampleRate);
		
	}
	
	
	public static function fromBytes (bytes:ByteArray):AudioBuffer {
		
		#if (cpp || neko)
		
		var data = lime_audio_load (bytes);
		var audioBuffer = new AudioBuffer ();
		audioBuffer.bitsPerSample = data.bitsPerSample;
		audioBuffer.channels = data.channels;
		audioBuffer.data = new Float32Array (data.data);
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
		audioBuffer.data = new Float32Array (data.data);
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