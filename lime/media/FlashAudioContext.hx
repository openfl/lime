package lime.media;


#if flash
import flash.media.Sound;
#end


class FlashAudioContext {
	
	
	public function new () {
		
		
		
	}
	
	
	public function createSource (stream:Dynamic /*URLRequest*/ = null, context:Dynamic /*SoundLoaderContext*/ = null):AudioSource {
		
		#if flash
		var source = new AudioSource ();
		source.src = new Sound (stream, context);
		return source;
		#else
		return null;
		#end
		
	}
	
	
	public function getBytesLoaded (source:AudioSource):UInt {
		
		#if flash
		if (source.src != null) {
			
			return source.src.bytesLoaded;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getBytesTotal (source:AudioSource):Int {
		
		#if flash
		if (source.src != null) {
			
			return source.src.bytesTotal;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getID3 (source:AudioSource):Dynamic /*ID3Info*/ {
		
		#if flash
		if (source.src != null) {
			
			return source.src.id3;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getIsBuffering (source:AudioSource):Bool {
		
		#if flash
		if (source.src != null) {
			
			return source.src.isBuffering;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getIsURLInaccessible (source:AudioSource):Bool {
		
		#if flash
		if (source.src != null) {
			
			return source.src.isURLInaccessible;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getLength (source:AudioSource):Float {
		
		#if flash
		if (source.src != null) {
			
			return source.src.length;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getURL (source:AudioSource):String {
		
		#if flash
		if (source.src != null) {
			
			return source.src.url;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function close (source:AudioSource):Void {
		
		#if flash
		if (source.src != null) {
			
			source.src.close ();
			
		}
		#end
		
	}
	
	
	public function extract (source:AudioSource, target:Dynamic /*flash.utils.ByteArray*/, length:Float, startPosition:Float = -1):Float {
		
		#if flash
		if (source.src != null) {
			
			return source.src.extract (target, length, startPosition);
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function load (source:AudioSource, stream:Dynamic /*flash.net.URLRequest*/, context:Dynamic /*SoundLoaderContext*/ = null):Void {
		
		#if flash
		if (source.src != null) {
			
			source.src.load (stream, context);
			
		}
		#end
		
	}
	
	
	public function loadCompressedDataFromByteArray (source:AudioSource, bytes:Dynamic /*flash.utils.ByteArray*/, bytesLength:UInt):Void {
		
		#if flash
		if (source.src != null) {
			
			source.src.loadCompressedDataFromByteArray (bytes, bytesLength);
			
		}
		#end
		
	}
	
	
	public function loadPCMFromByteArray (source:AudioSource, bytes:Dynamic /*flash.utils.ByteArray*/, samples:UInt, format:String = null, stereo:Bool = true, sampleRate:Float = 44100):Void {
		
		#if flash
		if (source.src != null) {
			
			source.src.loadPCMFromByteArray (bytes, samples, format, stereo, sampleRate);
			
		}
		#end
		
	}
	
	
	public function play (source:AudioSource, startTime:Float = 0, loops:Int = 0, sndTransform:Dynamic /*SoundTransform*/ = null):Dynamic /*SoundChannel*/ {
		
		#if flash
		if (source.src != null) {
			
			return source.src.play (startTime, loops, sndTransform);
			
		}
		#end
		
		return null;
		
	}
	
	
}