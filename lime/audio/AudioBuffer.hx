package lime.audio;


import haxe.io.Bytes;
import lime.audio.openal.AL;
import lime.net.URLLoader;
import lime.net.URLRequest;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;

#if (js && html5)
import js.html.Audio;
#elseif flash
import flash.media.Sound;
#elseif lime_console
import lime.audio.fmod.Sound;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end


class AudioBuffer {
	
	
	public var bitsPerSample:Int;
	public var channels:Int;
	public var data:UInt8Array;
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
		#end
		
	}
	
	
	public static function fromBytes (bytes:ByteArray):AudioBuffer {
		
		#if lime_console
		
		openfl.Lib.notImplemented ("Sound.fromBytes");
		
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
		
		#elseif ((cpp || neko || nodejs) && !macro)
		
		var data:Dynamic = lime_audio_load (bytes);
		
		if (data != null) {
			
			var audioBuffer = new AudioBuffer ();
			audioBuffer.bitsPerSample = data.bitsPerSample;
			audioBuffer.channels = data.channels;
			audioBuffer.data = new UInt8Array (@:privateAccess new Bytes (data.data.length, data.data.b));
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
		
		#elseif ((cpp || neko || nodejs) && !macro)
		
		var data:Dynamic = lime_audio_load (path);
		
		if (data != null) {
			
			var audioBuffer = new AudioBuffer ();
			audioBuffer.bitsPerSample = data.bitsPerSample;
			audioBuffer.channels = data.channels;
			audioBuffer.data = new UInt8Array (@:privateAccess new Bytes (data.data.length, data.data.b));
			audioBuffer.sampleRate = data.sampleRate;
			return audioBuffer;
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public static function fromURL (url:String, handler:AudioBuffer->Void):Void {
		
		if (url != null && url.indexOf ("http://") == -1 && url.indexOf ("https://") == -1) {
			
			handler (AudioBuffer.fromFile (url));
			
		} else {
			
			// TODO: Support streaming sound
			
			#if flash
			
			var loader = new flash.net.URLLoader ();
			loader.addEventListener (flash.events.Event.COMPLETE, function (_) {
				handler (AudioBuffer.fromBytes (cast loader.data));
			});
			loader.addEventListener (flash.events.IOErrorEvent.IO_ERROR, function (_) {
				handler (null);
			});
			loader.load (new flash.net.URLRequest (url));
			
			#else
			
			var loader = new URLLoader ();
			loader.onComplete.add (function (_) {
				var bytes = Bytes.ofString (loader.data);
				handler (AudioBuffer.fromBytes (ByteArray.fromBytes (bytes)));
			});
			loader.onIOError.add (function (_, msg) {
				handler (null);
			});
			loader.load (new URLRequest (url));
			
			#end
			
		}
		
	}
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_audio_load (data:Dynamic):Dynamic;
	#end
	
	
}