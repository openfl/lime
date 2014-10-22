package lime.audio;


import lime.audio.openal.AL;
import lime.system.System;
import lime.utils.ByteArray;
import lime.utils.Float32Array;

#if js
import js.html.Audio;
#elseif flash
import flash.media.Sound;
#end


class AudioBuffer {
	
	
	public var bitsPerSample:Int;
	public var channels:Int;
	public var data:ByteArray;
	public var id:UInt;
	public var sampleRate:Int;
	
	#if js
	public var src:Audio;
	#elseif flash
	public var src:Sound;
	#else
	public var src:Dynamic;
	#end
	
	
	public function new () {
		
		id = 0;
		
	}
	
	
	public function dispose ():Void {
		
		// TODO
		
	}
	
	
	public static function fromBytes (bytes:ByteArray):AudioBuffer {
		
		#if (cpp || neko)
		
		var data = lime_audio_load (bytes);
		
		if (data != null) {
			
			var audioBuffer = new AudioBuffer ();
			audioBuffer.bitsPerSample = data.bitsPerSample;
			audioBuffer.channels = data.channels;
			audioBuffer.data = data.data;
			audioBuffer.sampleRate = data.sampleRate;
			return audioBuffer;
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public static function fromFile (path:String):AudioBuffer {
		
		#if (cpp || neko)
		
		var data = lime_audio_load (path);
		
		if (data != null) {
			
			var audioBuffer = new AudioBuffer ();
			audioBuffer.bitsPerSample = data.bitsPerSample;
			audioBuffer.channels = data.channels;
			audioBuffer.data = data.data;
			audioBuffer.sampleRate = data.sampleRate;
			return audioBuffer;
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public static function fromURL (url:String, handler:AudioBuffer->Void):Void {
		
		// TODO
		
	}
	
	
	#if (cpp || neko)
	private static var lime_audio_load:Dynamic = System.load ("lime", "lime_audio_load", 1);
	#end
	
	
}