package lime.audio;


import haxe.io.Bytes;
import lime.audio.openal.AL;
import lime.system.System;
import lime.utils.ByteArray;
import lime.utils.Float32Array;

#if (js && html5)
import js.html.Audio;
#elseif flash
import flash.media.Sound;
#elseif lime_console
import lime.audio.fmod.Sound;
#end


class AudioBuffer {
	
	
	public var bitsPerSample:Int;
	public var channels:Int;
	public var data:ByteArray;
	public var id:UInt;
	public var sampleRate:Int;
	
	#if (js && html5)
	public var src:Audio;
	#elseif flash
	public var src:Sound;
	#elseif lime_console
	public var src:Sound;
	#else
	public var src:Dynamic;
	#end
	
	
	public function new () {
		
		id = 0;
		
	}
	
	
	public function dispose ():Void {
		
		#if lime_console

			src.release ();
		
		#else

			// TODO

		#end
		
	}
	
	
	public static function fromBytes (bytes:ByteArray):AudioBuffer {
		
		#if lime_console

			trace ("not implemented");
/*
			var sound:Sound = Sound.fromBytes (bytes);

			if (sound.valid) {

				var audioBuffer = new AudioBuffer ();
				audioBuffer.bitsPerSample = 0;
				audioBuffer.channels = 0;
				audioBuffer.data = null;
				audioBuffer.sampleRate = 0;
				audioBuffer.src = sound;
				return audioBuffer;

			}
*/
	
		#elseif (cpp || neko || nodejs)
			
			var data = lime_audio_load (bytes);
			
			if (data != null) {
				
				var audioBuffer = new AudioBuffer ();
				audioBuffer.bitsPerSample = data.bitsPerSample;
				audioBuffer.channels = data.channels;
				audioBuffer.data = ByteArray.fromBytes (@:privateAccess new Bytes (data.data.length, data.data.b));
				audioBuffer.sampleRate = data.sampleRate;
				return audioBuffer;
				
			}
			
		#end
		
		return null;
		
	}
	
	
	public static function fromFile (path:String):AudioBuffer {
		
		#if lime_console

			var sound:Sound = Sound.fromFile (path);

			if (sound.valid) {
	
				var audioBuffer = new AudioBuffer ();
				audioBuffer.bitsPerSample = 0;
				audioBuffer.channels = 0;
				audioBuffer.data = null;
				audioBuffer.sampleRate = 0;
				audioBuffer.src = sound;
				return audioBuffer;
	
			}	

		#elseif (cpp || neko || nodejs)
			
			var data = lime_audio_load (path);
			
			if (data != null) {
				
				var audioBuffer = new AudioBuffer ();
				audioBuffer.bitsPerSample = data.bitsPerSample;
				audioBuffer.channels = data.channels;
				audioBuffer.data = ByteArray.fromBytes (@:privateAccess new Bytes (data.data.length, data.data.b));
				audioBuffer.sampleRate = data.sampleRate;
				return audioBuffer;
				
			}
			
		#end
		
		return null;
		
	}
	
	
	public static function fromURL (url:String, handler:AudioBuffer->Void):Void {
		
		// TODO
		
	}
	
	
	#if (cpp || neko || nodejs)
	private static var lime_audio_load:Dynamic = System.load ("lime", "lime_audio_load", 1);
	#end
	
	
}
