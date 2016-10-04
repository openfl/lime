package lime.audio;


import haxe.Timer;
import lime.app.Event;
import lime.audio.openal.AL;
import lime.audio.openal.ALSource;
import lime.math.Vector4;

#if flash
import flash.media.SoundChannel;
#elseif lime_console
import lime.audio.fmod.FMODChannel;
#end

#if lime_console
// TODO(james4k): this is terribly hacky. looking for more sane solutions.  the
// caller uses an extern declaration of this function so that it does not need
// to include haxe dependencies, but that's not really the hacky part. need a
// good way to export a c++ callable haxe function.
@:cppNamespaceCode("
void haxe_staticfunc_onFmodChannelEnd (ConsoleFmodChannel c) {
	AudioSource_obj::onFmodChannelEnd (c);
}
")
#end

@:access(lime.audio.AudioBuffer)


class AudioSource {
	
	
	public var onComplete = new Event<Void->Void> ();
	
	public var buffer:AudioBuffer;
	public var currentTime (get, set):Int;
	public var gain (get, set):Float;
	public var length (get, set):Int;
	public var loops (get, set):Int;
	public var offset:Int;
	public var position (get, set):Vector4;
	
	private var id:Dynamic;
	private var playing:Bool;
	private var pauseTime:Int;
	private var __completed:Bool;
	private var __length:Null<Int>;
	private var __loops:Int;
	private var __position:Vector4;
	
	#if flash
	private var channel:SoundChannel;
	#elseif lime_console
	private var channel:FMODChannel;
	private var __gain:Float = 1.0;
	#end
	
	#if lime_cffi
	private var timer:Timer;
	#end
	
	
	public function new (buffer:AudioBuffer = null, offset:Int = 0, length:Null<Int> = null, loops:Int = 0) {
		
		this.buffer = buffer;
		this.offset = offset;
		
		if (length != null && length != 0) {
			
			this.length = length;
			
		}
		
		this.loops = loops;
		id = null;
		__completed = false;
		
		__position = new Vector4 ();
		
		if (buffer != null) {
			
			init ();
			
		}
		
	}
	
	
	public function dispose ():Void {
		
		switch (AudioManager.context) {
			
			case OPENAL (alc, al):
				
				if (id != 0) {
					
					al.deleteSource (id);
					
				}
			
			default:
				
		}
		
	}
	
	
	private function init ():Void {
		
		switch (AudioManager.context) {
			
			case OPENAL (alc, al):
				
				if (buffer.__srcBuffer == null) {
					
					buffer.__srcBuffer = al.genBuffer ();
					
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
					
					al.bufferData (buffer.__srcBuffer, format, buffer.data, buffer.data.length, buffer.sampleRate);
					
				}
				
				id = al.genSource ();
				al.sourcei (id, al.BUFFER, buffer.__srcBuffer);
			
			default:
			
		}
		
	}
	
	
	public function play ():Void {
		
		#if html5
		#if howlerjs
		
		if (playing || buffer == null) {
			
			return;
			
		}
		
		playing = true;
		
		var time = currentTime;
		
		__completed = false;
		id = buffer.__srcHowl.play ();
		buffer.__srcHowl.on ("end", howl_onEnd, id);
		
		currentTime = time;
		
		#end
		#elseif flash
		
		if (channel != null) channel.stop ();
		channel = buffer.__srcSound.play (pauseTime / 1000 + offset, loops + 1);
		
		#elseif lime_console
		
		if (channel.valid) {
			
			channel.resume ();
			
		} else {
			
			channel = buffer.__srcSound.play ();
			channel.setLoopCount (__loops);
			if (__gain < 1.0) {
				channel.setVolume (__gain);
			}
			
			var old = setFmodActive (channel, this);
			
			if (old != this) {
				
				old.channel = FMODChannel.INVALID;
				
			}
			
		}
		
		#else
		
		if (playing || id == null) {
			
			return;
			
		}
		
		playing = true;
		
		var time = currentTime;
		
		AL.sourcePlay (id);
		
		currentTime = time;
		
		#end
		
	}
	
	
	public function pause ():Void {
		
		#if html5
		#if howlerjs
		
		playing = false;
		buffer.__srcHowl.pause (id);
		
		#end
		#elseif flash
		
		if (channel != null) {
			
			pauseTime = Std.int (channel.position * 1000);
			channel.stop ();
			
		}
		
		#elseif lime_console
		
		if (channel.valid) {
			
			channel.pause ();
			
		}
		
		#else
		
		playing = false;
		AL.sourcePause (id);
		
		if (timer != null) {
			
			timer.stop ();
			
		}
		
		#end
		
	}
	
	
	public function stop ():Void {
		
		#if html5
		#if howlerjs
		
		playing = false;
		buffer.__srcHowl.stop (id);
		
		#end
		#elseif flash
		
		pauseTime = 0;
		
		if (channel != null) {
			
			channel.stop ();
			
		}
		
		#elseif lime_console
		
		if (channel.valid) {
			
			channel.stop ();
			
		}
		
		#else
		
		playing = false;
		AL.sourceStop (id);
		
		if (timer != null) {
			
			timer.stop ();
			
		}
		
		#end
		
	}
	
	
	#if lime_console
	
	// TODO(james4k): these arrays become Array<Dynamic> so a lot of hidden
	// boxing and allocations going on.
	
	// can't use Maps because we need by-value key comparisons, so use two arrays.
	private static var fmodActiveChannels = new Array<FMODChannel> ();
	private static var fmodActiveSources = new Array<AudioSource> ();
	
	
	// onFmodChannelEnd is called from C++ when an fmod channel end callback is
	// called.
	private static function onFmodChannelEnd (channel:FMODChannel) {
		
		var source = removeFmodActive (channel);
		
		if (source != null) {
			
			source.channel = FMODChannel.INVALID;
			source.onComplete.dispatch ();
			
		}
		
	}
	
	
	// removeFmodActive disassociates an FMODChannel with its AudioSource, returning
	// the AudioSource it was associated with.
	private static function removeFmodActive(key:FMODChannel):AudioSource {
		
		for (i in 0...fmodActiveChannels.length) {
			
			if (fmodActiveChannels[i] == key) {
				
				var source = fmodActiveSources[i];
				
				// swap in the last element and pop() to remove from array
				var last = fmodActiveChannels.length - 1;
				fmodActiveChannels[i] = fmodActiveChannels[last];
				fmodActiveSources[i] = fmodActiveSources[last];
				
				fmodActiveChannels.pop ();
				fmodActiveSources.pop ();
				
				return source;
				
			}
			
		}
		
		return null;
		
	}
	
	
	// setFmodActive associates an FMODChannel with an AudioSource to allow for fmod
	// channel callbacks to propagate to the user's AudioSource onComplete
	// callbacks. Returns the previous AudioSource associated with the channel
	// if there was one, or the passed in AudioSource if not.
	private static function setFmodActive (key:FMODChannel, value:AudioSource):AudioSource {
		
		for (i in 0...fmodActiveChannels.length) {
			
			if (fmodActiveChannels[i] == key) {
				
				var old = fmodActiveSources[i];
				fmodActiveSources[i] = value;
				return old;
				
			}
			
		}
		
		fmodActiveChannels.push (key);
		fmodActiveSources.push (value);
		return value;
		
	}
	
	#end
	
	
	
	
	// Event Handlers
	
	
	
	
	private function howl_onEnd () {
		
		#if howlerjs
		
		playing = false;
		
		if (loops > 0) {
			
			loops--;
			stop ();
			//currentTime = 0;
			play ();
			return;
			
		} else {
			
			buffer.__srcHowl.stop (id);
			
		}
		
		__completed = true;
		onComplete.dispatch ();
		
		#end
		
	}
	
	
	private function timer_onRun () {
		
		#if (!flash && !html5)
		
		playing = false;
		
		if (loops > 0) {
			
			loops--;
			currentTime = 0;
			play ();
			return;
			
		} else {
			
			AL.sourceStop (id);
			timer.stop ();
			
		}
		
		__completed = true;
		onComplete.dispatch ();
		
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_currentTime ():Int {
		
		#if html5
		#if howlerjs
		
		if (__completed) {
			
			return length;
			
		} else {
			
			return Std.int (buffer.__srcHowl.seek (id) * 1000);
			
		}
		
		#else
		
		return 0;
		
		#end
		#elseif flash
		
		if (channel != null) {
			
			return Std.int (channel.position) - offset;
			
		} else {
			
			return 0;
			
		}
		
		#elseif lime_console
		
		lime.Lib.notImplemented ("AudioSource.get_currentTime");
		return 0;
		
		#else
		
		if (__completed) {
			
			return length;
			
		} else {
			
			var time = Std.int (AL.getSourcef (id, AL.SEC_OFFSET) * 1000) - offset;
			if (time < 0) return 0;
			return time;
			
		}
		
		#end
		
	}
	
	
	private function set_currentTime (value:Int):Int {
		
		#if html5
		#if howlerjs
		
		if (buffer != null) {
			
			//if (playing) buffer.__srcHowl.play (id);
			buffer.__srcHowl.seek ((value + offset) / 1000, id);
			
		}
		
		return value;
		
		#else
		
		return pauseTime = value;
		
		#end
		#elseif flash
		
		// TODO: create new sound channel
		//channel.position = value;
		return pauseTime = value;
		
		#elseif lime_console
		
		lime.Lib.notImplemented ("AudioSource.set_currentTime");
		return value;
		
		#else
		
		if (buffer != null) {
			
			AL.sourceRewind (id);
			if (playing) AL.sourcePlay (id);
			AL.sourcef (id, AL.SEC_OFFSET, (value + offset) / 1000);
			
		}
		
		if (playing) {
			
			if (timer != null) {
				
				timer.stop ();
				
			}
			
			var timeRemaining = length - value;
			
			if (timeRemaining > 0) {
				
				__completed = false;
				timer = new Timer (timeRemaining);
				timer.run = timer_onRun;
				
			} else {
				
				__completed = true;
				
			}
			
		}
		
		return value;
		
		#end
		
	}
	
	
	private function get_gain ():Float {
		
		#if html5
		#if howlerjs
		
		return buffer.__srcHowl.volume (id);
		
		#else
		
		return 1;
		
		#end
		#elseif flash
		
		return channel.soundTransform.volume;
		
		#elseif lime_console
		
		if (channel.valid) {
			
			__gain = channel.getVolume ();
			
		}
		
		return __gain;
		
		#else
		
		return AL.getSourcef (id, AL.GAIN);
		
		#end
		
	}
	
	
	private function set_gain (value:Float):Float {
		
		#if html5
		#if howlerjs
		
		buffer.__srcHowl.volume (value, id);
		return value;
		
		#else
		
		return 1;
		
		#end
		#elseif flash
		
		var soundTransform = channel.soundTransform;
		soundTransform.volume = value;
		channel.soundTransform = soundTransform;
		return value;
		
		#elseif lime_console
		
		if (channel.valid) {
			
			channel.setVolume (value);
			
		}
		
		return __gain = value;
		
		#else
		
		AL.sourcef (id, AL.GAIN, value);
		return value;
		
		#end
		
	}
	
	
	private function get_length ():Int {
		
		if (__length != null) {
			
			return __length;
			
		}
		
		#if html5
		#if howlerjs
		
		return Std.int (buffer.__srcHowl.duration () * 1000);
		
		#else
		
		return 0;
		
		#end
		#elseif flash
		
		return Std.int (buffer.__srcSound.length) - offset;
		
		#elseif lime_console
		
		lime.Lib.notImplemented ("AudioSource.get_length");
		return 0;
		
		#else
		
		var samples = (buffer.data.length * 8) / (buffer.channels * buffer.bitsPerSample);
		return Std.int (samples / buffer.sampleRate * 1000) - offset;
		
		#end
		
	}
	
	
	private function set_length (value:Int):Int {
		
		#if lime_console
		
		lime.Lib.notImplemented ("AudioSource.set_length");
		return value;
		
		#elseif (!flash && !html5)
		
		if (playing && __length != value) {
			
			if (timer != null) {
				
				timer.stop ();
				
			}
			
			var timeRemaining = value - currentTime;
			
			if (timeRemaining > 0) {
				
				timer = new Timer (value - currentTime);
				timer.run = timer_onRun;
				
			}
			
		}
		
		#end
		
		return __length = value;
		
	}
	
	
	private function get_loops ():Int {
		
		#if lime_console
		
		if (channel.valid) {
			
			__loops = channel.getLoopCount ();
			
		}
		
		#end
		
		return __loops;
		
	}
	
	
	private function set_loops (loops:Int):Int {
		
		#if lime_console
		
		if (channel.valid) {
			
			channel.setLoopCount (loops);
			
		}
		
		#end
		
		return __loops = loops;
		
	}
	
	
	private function get_position ():Vector4 {
		
		#if html5
		#if howlerjs
		
		// TODO: Use 3D audio plugin
		
		#end
		#elseif flash
		
		__position.x = channel.soundTransform.pan;
		
		#elseif lime_console
		#else
		
		var value = AL.getSource3f (id, AL.POSITION);
		__position.x = value[0];
		__position.y = value[1];
		__position.z = value[2];
		
		#end
		
		return __position;
		
	}
	
	
	private function set_position (value:Vector4):Vector4 {
		
		__position.x = value.x;
		__position.y = value.y;
		__position.z = value.z;
		__position.w = value.w;
		
		#if html5
		#elseif flash
		
		var soundTransform = channel.soundTransform;
		soundTransform.pan = __position.x;
		channel.soundTransform = soundTransform;
		
		#elseif lime_console
		#else
		
		AL.distanceModel (AL.NONE);
		AL.source3f (id, AL.POSITION, __position.x, __position.y, __position.z);
		
		#end
		
		return __position;
		
	}
	
	
}