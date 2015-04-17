package lime.audio;


import haxe.Timer;
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
	
	private var loops:Int;
	
	#if (cpp || neko)
	@:noCompletion private var timer:Timer;
	@:noCompletion private var __playing:Bool = false;
	@:noCompletion private var __paused:Bool = false;
	#end
	
	@:noCompletion private var __offsetMs:Int = -1;
	
	public function new (buffer:AudioBuffer = null, offsetMs:Int = -1, loops:Int = 0) {
		
		this.buffer = buffer;
		this.loops = loops;
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
	
	
	public function play (offsetMs:Int=-1):Void {
		
		if (offsetMs < 0) {
			if (__offsetMs >= 0) {
				offsetMs = __offsetMs;
				offsetMs = -1;
			}
		}
		
		#if html5
		#elseif flash
			
			if (channel != null) channel.stop ();
			var channel = buffer.src.play (pauseTime / 1000);
			
		#else
			
			if (__playing && !__paused) {
				return;
			}
			
			AL.sourceRewind(id);	//you have to rewind the sound if you're going to set position accurately
			
			if (offsetMs >= 0) {
				set_timeOffset(offsetMs); //Set the sound position offset if we're resuming from pause or whatever
			}
			
			AL.sourcePlay (id);		//Play the sound from the resume point, or otherwise play from the start
			
			__paused = false;
			
			if (timer != null) {
				timer.stop();
			}
			
			//Calculate the exact playing time of the sound
			var lengthInSamples = buffer.data.length * 8 / (buffer.channels * buffer.bitsPerSample);
			var durationInMs = (lengthInSamples / buffer.sampleRate * 1000) - offsetMs;
			
			//Set a timer to keep track of the play time duration so we can dispatch an onComplete event
			timer = new Timer(durationInMs);
			timer.run = function() {
				if (loops > 0) {
					loops--;
					AL.sourcePlay(id);
				}
				else {
					AL.sourceStop(id);
					timer.stop();
					__playing = false;
				}
				onComplete.dispatch();
			}
			
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
			
			__paused = true;
			AL.sourcePause (id);
			if (timer != null) {
				timer.stop();
			}
			
		#end
		
	}
	
	
	public function stop ():Void {
		
		#if html5
		#elseif flash
			
			pauseTime = 0;
			if (channel != null) channel.stop ();
			
		#else
			
			AL.sourceStop (id);
			if (timer != null) {
				timer.stop();
			}
			
		#end
		
	}
	
	
	// Get & Set Methods
	
	
	
	
	private function get_gain ():Float {
		
		#if html5
		
		return 1;
		
		#elseif flash
			
			return channel.soundTransform.volume;
			
		#else
			
			return AL.getSourcef (id, AL.GAIN);
			
		#end
		
	}
	
	
	private function set_gain (value:Float):Float {
		
		#if html5
		
		return 1;
		
		#elseif flash
			
			var soundTransform = channel.soundTransform;
			soundTransform.volume = value;
			channel.soundTransform = soundTransform;
			return value;
			
		#else
			
			AL.sourcef (id, AL.GAIN, value);
			return value;
			
		#end
		
	}
	
	
	private function get_timeOffset ():Int {
		
		#if html5
		
		return 0;
		
		#elseif flash
			
			return Std.int (channel.position);
			
		#else
			
			return Std.int (AL.getSourcef (id, AL.SEC_OFFSET) * 1000);
			
		#end
		
	}
	
	
	private function set_timeOffset (value:Int):Int {
		
		#if html5
		
		return 0;
		
		#elseif flash
			
			// TODO: create new sound channel
			//channel.position = value;
			return value;
			
		#else
			
			AL.sourcef (id, AL.SEC_OFFSET, value / 1000);
			return value;
			
		#end
		
	}
	
}