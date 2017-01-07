package lime.media;


import lime.app.Event;
import lime.media.openal.AL;
import lime.media.openal.ALSource;
import lime.math.Vector4;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class AudioSource {
	
	
	public var onComplete = new Event<Void->Void> ();
	
	public var buffer:AudioBuffer;
	public var currentTime (get, set):Int;
	public var gain (get, set):Float;
	public var length (get, set):Int;
	public var loops (get, set):Int;
	public var offset:Int;
	public var position (get, set):Vector4;
	
	@:noCompletion private var backend:AudioSourceBackend;
	
	
	public function new (buffer:AudioBuffer = null, offset:Int = 0, length:Null<Int> = null, loops:Int = 0) {
		
		this.buffer = buffer;
		this.offset = offset;
		
		backend = new AudioSourceBackend (this);
		
		if (length != null && length != 0) {
			
			this.length = length;
			
		}
		
		this.loops = loops;
		
		if (buffer != null) {
			
			init ();
			
		}
		
	}
	
	
	public function dispose ():Void {
		
		backend.dispose ();
		
	}
	
	
	private function init ():Void {
		
		backend.init ();
		
	}
	
	
	public function play ():Void {
		
		backend.play ();
		
	}
	
	
	public function pause ():Void {
		
		backend.pause ();
		
	}
	
	
	public function stop ():Void {
		
		backend.stop ();
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_currentTime ():Int {
		
		return backend.getCurrentTime ();
		
	}
	
	
	private function set_currentTime (value:Int):Int {
		
		return backend.setCurrentTime (value);
		
	}
	
	
	private function get_gain ():Float {
		
		return backend.getGain ();
		
	}
	
	
	private function set_gain (value:Float):Float {
		
		return backend.setGain (value);
		
	}
	
	
	private function get_length ():Int {
		
		return backend.getLength ();
		
	}
	
	
	private function set_length (value:Int):Int {
		
		return backend.setLength (value);
		
	}
	
	
	private function get_loops ():Int {
		
		return backend.getLoops ();
		
	}
	
	
	private function set_loops (value:Int):Int {
		
		return backend.setLoops (value);
		
	}
	
	
	private function get_position ():Vector4 {
		
		return backend.getPosition ();
		
	}
	
	
	private function set_position (value:Vector4):Vector4 {
		
		return backend.setPosition (value);
		
	}
	
	
}


#if flash
@:noCompletion private typedef AudioSourceBackend = lime._backend.flash.FlashAudioSource;
#elseif (js && html5)
@:noCompletion private typedef AudioSourceBackend = lime._backend.html5.HTML5AudioSource;
#else
@:noCompletion private typedef AudioSourceBackend = lime._backend.native.NativeAudioSource;
#end