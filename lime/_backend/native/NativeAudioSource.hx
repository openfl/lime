package lime._backend.native;


import haxe.Timer;
import lime.audio.AudioManager;
import lime.audio.AudioSource;
import lime.audio.openal.AL;
import lime.audio.openal.ALSource;
import lime.math.Vector4;

@:access(lime.audio.AudioBuffer)


class NativeAudioSource {
	
	
	private var completed:Bool;
	private var handle:ALSource;
	private var length:Null<Int>;
	private var loops:Int;
	private var parent:AudioSource;
	private var playing:Bool;
	private var position:Vector4;
	private var timer:Timer;
	
	
	public function new (parent:AudioSource) {
		
		this.parent = parent;
		
		position = new Vector4 ();
		
		
	}
	
	
	public function dispose ():Void {
		
		if (handle != null) {
			
			AL.deleteSource (handle);
			
		}
		
	}
	
	
	public function init ():Void {
		
		if (parent.buffer.__srcBuffer == null) {
			
			parent.buffer.__srcBuffer = AL.genBuffer ();
			
			var format = 0;
			
			if (parent.buffer.channels == 1) {
				
				if (parent.buffer.bitsPerSample == 8) {
					
					format = AL.FORMAT_MONO8;
					
				} else if (parent.buffer.bitsPerSample == 16) {
					
					format = AL.FORMAT_MONO16;
					
				}
				
			} else if (parent.buffer.channels == 2) {
				
				if (parent.buffer.bitsPerSample == 8) {
					
					format = AL.FORMAT_STEREO8;
					
				} else if (parent.buffer.bitsPerSample == 16) {
					
					format = AL.FORMAT_STEREO16;
					
				}
				
			}
			
			AL.bufferData (parent.buffer.__srcBuffer, format, parent.buffer.data, parent.buffer.data.length, parent.buffer.sampleRate);
			
		}
		
		handle = AL.genSource ();
		AL.sourcei (handle, AL.BUFFER, parent.buffer.__srcBuffer);
		
	}
	
	
	public function play ():Void {
		
		if (playing || handle == null) {
			
			return;
			
		}
		
		playing = true;
		
		var time = getCurrentTime ();
		
		AL.sourcePlay (handle);
		
		setCurrentTime (time);
		
	}
	
	
	public function pause ():Void {
		
		playing = false;
		AL.sourcePause (handle);
		
		if (timer != null) {
			
			timer.stop ();
			
		}
		
	}
	
	
	public function stop ():Void {
		
		playing = false;
		AL.sourceStop (handle);
		
		if (timer != null) {
			
			timer.stop ();
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function timer_onRun () {
		
		playing = false;
		
		if (loops > 0) {
			
			loops--;
			setCurrentTime (0);
			play ();
			return;
			
		} else {
			
			AL.sourceStop (handle);
			timer.stop ();
			
		}
		
		completed = true;
		parent.onComplete.dispatch ();
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	public function getCurrentTime ():Int {
		
		if (completed) {
			
			return getLength ();
			
		} else {
			
			var time = Std.int (AL.getSourcef (handle, AL.SEC_OFFSET) * 1000) - parent.offset;
			if (time < 0) return 0;
			return time;
			
		}
		
	}
	
	
	public function setCurrentTime (value:Int):Int {
		
		if (parent.buffer != null) {
			
			AL.sourceRewind (handle);
			if (playing) AL.sourcePlay (handle);
			AL.sourcef (handle, AL.SEC_OFFSET, (value + parent.offset) / 1000);
			
		}
		
		if (playing) {
			
			if (timer != null) {
				
				timer.stop ();
				
			}
			
			var timeRemaining = getLength () - value;
			
			if (timeRemaining > 0) {
				
				completed = false;
				timer = new Timer (timeRemaining);
				timer.run = timer_onRun;
				
			} else {
				
				completed = true;
				
			}
			
		}
		
		return value;
		
	}
	
	
	public function getGain ():Float {
		
		return AL.getSourcef (handle, AL.GAIN);
		
	}
	
	
	public function setGain (value:Float):Float {
		
		AL.sourcef (handle, AL.GAIN, value);
		return value;
		
	}
	
	
	public function getLength ():Int {
		
		if (length != null) {
			
			return length;
			
		}
		
		var samples = (parent.buffer.data.length * 8) / (parent.buffer.channels * parent.buffer.bitsPerSample);
		return Std.int (samples / parent.buffer.sampleRate * 1000) - parent.offset;
		
	}
	
	
	public function setLength (value:Int):Int {
		
		if (playing && length != value) {
			
			if (timer != null) {
				
				timer.stop ();
				
			}
			
			var timeRemaining = value - getCurrentTime ();
			
			if (timeRemaining > 0) {
				
				timer = new Timer (timeRemaining);
				timer.run = timer_onRun;
				
			}
			
		}
		
		return length = value;
		
	}
	
	
	public function getLoops ():Int {
		
		return loops;
		
	}
	
	
	public function setLoops (value:Int):Int {
		
		return loops = value;
		
	}
	
	
	public function getPosition ():Vector4 {
		
		var value = AL.getSource3f (handle, AL.POSITION);
		position.x = value[0];
		position.y = value[1];
		position.z = value[2];
		return position;
		
	}
	
	
	public function setPosition (value:Vector4):Vector4 {
		
		position.x = value.x;
		position.y = value.y;
		position.z = value.z;
		position.w = value.w;
		
		AL.distanceModel (AL.NONE);
		AL.source3f (handle, AL.POSITION, position.x, position.y, position.z);
		
		return position;
		
	}
	
	
}