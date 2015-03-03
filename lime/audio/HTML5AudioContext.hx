package lime.audio;


#if (js && html5)
import js.html.Audio;
#end


class HTML5AudioContext {
	
	
	public var HAVE_CURRENT_DATA:Int = 2;
	public var HAVE_ENOUGH_DATA:Int = 4;
	public var HAVE_FUTURE_DATA:Int = 3;
	public var HAVE_METADATA:Int = 1;
	public var HAVE_NOTHING:Int = 0;
	public var NETWORK_EMPTY:Int = 0;
	public var NETWORK_IDLE:Int = 1;
	public var NETWORK_LOADING:Int = 2;
	public var NETWORK_NO_SOURCE:Int = 3;
	
	
	public function new () {
		
		
		
	}
	
	
	public function canPlayType (buffer:AudioBuffer, type:String):String {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.canPlayType (type);
			
		}
		#end
		
		return null;
		
	}
	
	
	public function createBuffer (urlString:String = null):AudioBuffer {
		
		#if (js && html5)
		var buffer = new AudioBuffer ();
		buffer.src = new Audio ();
		buffer.src.src = urlString;
		return buffer;
		#else
		return null;
		#end
		
	}
	
	
	#if (haxe_ver < "3.2")
	public function getAudioDecodedByteCount (buffer:AudioBuffer):Int {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.audioDecodedByteCount;
			
		}
		#end
		
		return 0;
		
	}
	#end
	
	
	public function getAutoplay (buffer:AudioBuffer):Bool {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.autoplay;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getBuffered (buffer:AudioBuffer):Dynamic /*TimeRanges*/ {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.buffered;
			
		}
		#end
		
		return null;
		
	}
	
	
	#if (haxe_ver < "3.2")
	public function getController (buffer:AudioBuffer):Dynamic /*MediaController*/ {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.controller;
			
		}
		#end
		
		return null;
		
	}
	#end
	
	
	public function getCurrentSrc (buffer:AudioBuffer):String {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.currentSrc;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getCurrentTime (buffer:AudioBuffer):Float {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.currentTime;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getDefaultPlaybackRate (buffer:AudioBuffer):Float {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.defaultPlaybackRate;
			
		}
		#end
		
		return 1;
		
	}
	
	
	public function getDuration (buffer:AudioBuffer):Float {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.duration;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getEnded (buffer:AudioBuffer):Bool {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.ended;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getError (buffer:AudioBuffer):Dynamic /*MediaError*/ {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.error;
			
		}
		#end
		
		return null;
		
	}
	
	
	#if (haxe_ver < "3.2")
	public function getInitialTime (buffer:AudioBuffer):Float {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.initialTime;
			
		}
		#end
		
		return 0;
		
	}
	#end
	
	
	public function getLoop (buffer:AudioBuffer):Bool {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.loop;
			
		}
		#end
		
		return false;
		
	}
	
	
	#if (haxe_ver < "3.2")
	public function getMediaGroup (buffer:AudioBuffer):String {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.mediaGroup;
			
		}
		#end
		
		return null;
		
	}
	#end
	
	
	public function getMuted (buffer:AudioBuffer):Bool {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.muted;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getNetworkState (buffer:AudioBuffer):Int {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.networkState;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getPaused (buffer:AudioBuffer):Bool {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.paused;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getPlaybackRate (buffer:AudioBuffer):Float {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.playbackRate;
			
		}
		#end
		
		return 1;
		
	}
	
	
	public function getPlayed (buffer:AudioBuffer):Dynamic /*TimeRanges*/ {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.played;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getPreload (buffer:AudioBuffer):String {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.preload;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getReadyState (buffer:AudioBuffer):Int {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.readyState;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getSeekable (buffer:AudioBuffer):Dynamic /*TimeRanges*/ {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.seekable;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getSeeking (buffer:AudioBuffer):Bool {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.seeking;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getSrc (buffer:AudioBuffer):String {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.src;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getStartTime (buffer:AudioBuffer):Float {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.playbackRate;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getVolume (buffer:AudioBuffer):Float {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.volume;
			
		}
		#end
		
		return 1;
		
	}
	
	
	public function load (buffer:AudioBuffer):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.load ();
			
		}
		#end
		
	}
	
	
	public function pause (buffer:AudioBuffer):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.pause ();
			
		}
		#end
		
	}
	
	
	public function play (buffer:AudioBuffer):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			return buffer.src.play ();
			
		}
		#end
		
	}
	
	
	public function setAutoplay (buffer:AudioBuffer, value:Bool):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.autoplay = value;
			
		}
		#end
		
	}
	
	
	#if (haxe_ver < "3.2")
	public function setController (buffer:AudioBuffer, value:Dynamic /*MediaController*/):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.controller = value;
			
		}
		#end
		
	}
	#end
	
	
	public function setCurrentTime (buffer:AudioBuffer, value:Float):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.currentTime = value;
			
		}
		#end
		
	}
	
	
	public function setDefaultPlaybackRate (buffer:AudioBuffer, value:Float):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.defaultPlaybackRate = value;
			
		}
		#end
		
	}
	
	
	public function setLoop (buffer:AudioBuffer, value:Bool):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.loop = value;
			
		}
		#end
		
	}
	
	
	#if (haxe_ver < "3.2")
	public function setMediaGroup (buffer:AudioBuffer, value:String):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.mediaGroup = value;
			
		}
		#end
		
	}
	#end
	
	
	public function setMuted (buffer:AudioBuffer, value:Bool):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.muted = value;
			
		}
		#end
		
	}
	
	
	public function setPlaybackRate (buffer:AudioBuffer, value:Float):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.playbackRate = value;
			
		}
		#end
		
	}
	
	
	public function setPreload (buffer:AudioBuffer, value:String):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.preload = value;
			
		}
		#end
		
	}
	
	
	public function setSrc (buffer:AudioBuffer, value:String):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.src = value;
			
		}
		#end
		
	}
	
	
	public function setVolume (buffer:AudioBuffer, value:Float):Void {
		
		#if (js && html5)
		if (buffer.src != null) {
			
			buffer.src.volume = value;
			
		}
		#end
		
	}
	
	
}