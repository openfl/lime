package lime.audio;


import lime.app.Event;
import lime.audio.openal.AL;

#if flash
import flash.media.SoundChannel;
#end


class AudioSource {
	
	
	public var onComplete = new Event<Void->Void> ();
	
	public var buffer:AudioBuffer;
	public var gain (get, set):Float;
	public var timeOffset (get, set):Int;
	
	private var id:UInt;
	private var pauseTime:Int;
	
	#if flash
	private var channel:SoundChannel;
	#end
	
	
	public function new (buffer:AudioBuffer = null) {
		
		this.buffer = buffer;
		id = 0;
		pauseTime = 0;
		
		if (buffer != null) {
			
			init ();
			
		}
		
	}
	
	
	private function init ():Void {
		
		switch (AudioManager.context) {
			
			case OPENAL (alc, al):
				
				if (buffer.id == 0) {
					
					buffer.id = al.genBuffer ();
					
					var format = 0;
					
					if (buffer.channels == 1) {
						
						if (buffer.bitsPerSample == 8) {
							
							format = al.FORMAT_MONO8;
							
						} else if (buffer.bitsPerSample == 16) {
							
							format = al.FORMAT_MONO16;
							
						}
						
					} else if (buffer.channels == 2) {
						
						if (buffer.bitsPerSample == 8) {
							
							format = al.FORMAT_STEREO8;
							
						} else if (buffer.bitsPerSample == 16) {
							
							format = al.FORMAT_STEREO16;
							
						}
						
					}
					
					al.bufferData (buffer.id, format, buffer.data, buffer.data.length, buffer.sampleRate);
					
				}
				
				id = al.genSource ();
				al.sourcei (id, al.BUFFER, buffer.id);
			
			default:
			
		}
		
	}
	
	
	public function play ():Void {
		
		#if html5
		#elseif flash
		if (channel != null) channel.stop ();
		var channel = buffer.src.play (pauseTime / 1000);
		#else
		AL.sourcePlay (id);
		#end
		
	}
	
	
	public function pause ():Void {
		
		#if html5
		#elseif flash
		if (channel != null) {
			
			pauseTime = Std.int (channel.position * 1000);
			channel.stop ();
			
		}
		#else
		AL.sourcePause (id);
		#end
		
	}
	
	
	public function stop ():Void {
		
		#if html5
		#elseif flash
		pauseTime = 0;
		if (channel != null) channel.stop ();
		#else
		AL.sourceStop (id);
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_gain ():Float {
		
		// TODO
		
		return 1;
		
	}
	
	
	private function set_gain (value:Float):Float {
		
		// TODO
		
		return value;
		
	}
	
	
	private function get_timeOffset ():Int {
		
		// TODO
		
		return 0;
		
	}
	
	
	private function set_timeOffset (value:Int):Int {
		
		// TODO
		
		return value;
		
	}
	
	
}