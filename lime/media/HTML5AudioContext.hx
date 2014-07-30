package lime.media;


#if js
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
	
	
	public function canPlayType (source:AudioSource, type:String):String {
		
		#if js
		if (source.src != null) {
			
			return source.src.canPlayType (type);
			
		}
		#end
		
		return null;
		
	}
	
	
	public function createSource (urlString:String = null):AudioSource {
		
		#if js
		var source = new AudioSource ();
		source.src = new Audio ();
		source.src.src = urlString;
		return source;
		#else
		return null;
		#end
		
	}
	
	
	public function getAudioDecodedByteCount (source:AudioSource):Int {
		
		#if js
		if (source.src != null) {
			
			return source.src.audioDecodedByteCount;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getAutoplay (source:AudioSource):Bool {
		
		#if js
		if (source.src != null) {
			
			return source.src.autoplay;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getBuffered (source:AudioSource):Dynamic /*TimeRanges*/ {
		
		#if js
		if (source.src != null) {
			
			return source.src.buffered;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getController (source:AudioSource):Dynamic /*MediaController*/ {
		
		#if js
		if (source.src != null) {
			
			return source.src.controller;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getCurrentSrc (source:AudioSource):String {
		
		#if js
		if (source.src != null) {
			
			return source.src.currentSrc;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getCurrentTime (source:AudioSource):Float {
		
		#if js
		if (source.src != null) {
			
			return source.src.currentTime;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getDefaultPlaybackRate (source:AudioSource):Float {
		
		#if js
		if (source.src != null) {
			
			return source.src.defaultPlaybackRate;
			
		}
		#end
		
		return 1;
		
	}
	
	
	public function getDuration (source:AudioSource):Float {
		
		#if js
		if (source.src != null) {
			
			return source.src.duration;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getEnded (source:AudioSource):Bool {
		
		#if js
		if (source.src != null) {
			
			return source.src.ended;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getError (source:AudioSource):Dynamic /*MediaError*/ {
		
		#if js
		if (source.src != null) {
			
			return source.src.error;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getInitialTime (source:AudioSource):Float {
		
		#if js
		if (source.src != null) {
			
			return source.src.initialTime;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getLoop (source:AudioSource):Bool {
		
		#if js
		if (source.src != null) {
			
			return source.src.loop;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getMediaGroup (source:AudioSource):String {
		
		#if js
		if (source.src != null) {
			
			return source.src.mediaGroup;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getMuted (source:AudioSource):Bool {
		
		#if js
		if (source.src != null) {
			
			return source.src.muted;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getNetworkState (source:AudioSource):Int {
		
		#if js
		if (source.src != null) {
			
			return source.src.networkState;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getPaused (source:AudioSource):Bool {
		
		#if js
		if (source.src != null) {
			
			return source.src.paused;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getPlaybackRate (source:AudioSource):Float {
		
		#if js
		if (source.src != null) {
			
			return source.src.playbackRate;
			
		}
		#end
		
		return 1;
		
	}
	
	
	public function getPlayed (source:AudioSource):Dynamic /*TimeRanges*/ {
		
		#if js
		if (source.src != null) {
			
			return source.src.played;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getPreload (source:AudioSource):String {
		
		#if js
		if (source.src != null) {
			
			return source.src.preload;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getReadyState (source:AudioSource):Int {
		
		#if js
		if (source.src != null) {
			
			return source.src.readyState;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getSeekable (source:AudioSource):Dynamic /*TimeRanges*/ {
		
		#if js
		if (source.src != null) {
			
			return source.src.seekable;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getSeeking (source:AudioSource):Bool {
		
		#if js
		if (source.src != null) {
			
			return source.src.seeking;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function getSrc (source:AudioSource):String {
		
		#if js
		if (source.src != null) {
			
			return source.src.src;
			
		}
		#end
		
		return null;
		
	}
	
	
	public function getStartTime (source:AudioSource):Float {
		
		#if js
		if (source.src != null) {
			
			return source.src.playbackRate;
			
		}
		#end
		
		return 0;
		
	}
	
	
	public function getVolume (source:AudioSource):Float {
		
		#if js
		if (source.src != null) {
			
			return source.src.volume;
			
		}
		#end
		
		return 1;
		
	}
	
	
	public function load (source:AudioSource):Void {
		
		#if js
		if (source.src != null) {
			
			return source.src.load ();
			
		}
		#end
		
	}
	
	
	public function pause (source:AudioSource):Void {
		
		#if js
		if (source.src != null) {
			
			return source.src.pause ();
			
		}
		#end
		
	}
	
	
	public function play (source:AudioSource):Void {
		
		#if js
		if (source.src != null) {
			
			return source.src.play ();
			
		}
		#end
		
	}
	
	
	public function setAutoplay (source:AudioSource, value:Bool):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.autoplay = value;
			
		}
		#end
		
	}
	
	
	public function setController (source:AudioSource, value:Dynamic /*MediaController*/):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.controller = value;
			
		}
		#end
		
	}
	
	
	public function setCurrentTime (source:AudioSource, value:Float):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.currentTime = value;
			
		}
		#end
		
	}
	
	
	public function setDefaultPlaybackRate (source:AudioSource, value:Float):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.defaultPlaybackRate = value;
			
		}
		#end
		
	}
	
	
	public function setLoop (source:AudioSource, value:Bool):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.loop = value;
			
		}
		#end
		
	}
	
	
	public function setMediaGroup (source:AudioSource, value:String):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.mediaGroup = value;
			
		}
		#end
		
	}
	
	
	public function setMuted (source:AudioSource, value:Bool):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.muted = value;
			
		}
		#end
		
	}
	
	
	public function setPlaybackRate (source:AudioSource, value:Float):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.playbackRate = value;
			
		}
		#end
		
	}
	
	
	public function setPreload (source:AudioSource, value:String):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.preload = value;
			
		}
		#end
		
	}
	
	
	public function setSrc (source:AudioSource, value:String):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.src = value;
			
		}
		#end
		
	}
	
	
	public function setVolume (source:AudioSource, value:Float):Void {
		
		#if js
		if (source.src != null) {
			
			source.src.volume = value;
			
		}
		#end
		
	}
	
	
}