package lime._internal.backend.html5;

import haxe.io.Bytes;
import haxe.Timer;
import js.Browser;
import lime.media.AudioInput;
import lime.media.AudioInputDevice;
import lime.system.PermissionStatus;

private typedef AudioInputData =
{
	var bytes:Bytes;
	var offset:Int;
}

@:access(lime.media.AudioInput)
class HTML5AudioInput
{
	private static inline var MAX_QUEUED_MS = 10000;

	private static var cachedDevices:Array<AudioInputDevice>;
	private static var enumeratingDevices:Bool;
	private static var permissionQueried:Bool;
	private static var permissionRequests:Int = 0;
	private static var permissionState:PermissionStatus = UNDETERMINED;

	private var audioContext:Dynamic;
	private var buffers:Array<AudioInputData>;
	private var disposed:Bool;
	private var frameSize:Int;
	private var mediaStream:Dynamic;
	private var parent:AudioInput;
	private var processorNode:Dynamic;
	private var queuedBytes:Int;
	private var sourceNode:Dynamic;
	private var starting:Bool;

	public static function getDefaultDevice():AudioInputDevice
	{
		if (!isSupported())
		{
			return null;
		}

		return new AudioInputDevice("Default Audio Input", null, true);
	}

	public static function getDevices():Array<AudioInputDevice>
	{
		refreshDevices();

		if (cachedDevices != null)
		{
			return cachedDevices.copy();
		}

		var defaultDevice = getDefaultDevice();
		return defaultDevice != null ? [defaultDevice] : [];
	}

	public static function getPermissionStatus():PermissionStatus
	{
		queryPermission();
		return permissionState;
	}

	public static function isSupported():Bool
	{
		var navigator:Dynamic = Browser.navigator;
		return navigator != null && navigator.mediaDevices != null && navigator.mediaDevices.getUserMedia != null;
	}

	public static function requestPermission():Void
	{
		if (!isSupported())
		{
			// Without a secure context there is no getUserMedia to ask with
			Timer.delay(AudioInput.onPermission.dispatch.bind(false), 0);
			return;
		}

		queryPermission();
		permissionRequests++;

		var navigator:Dynamic = Browser.navigator;
		var promise:Dynamic = navigator.mediaDevices.getUserMedia({audio: true});

		promise.then(function(stream)
		{
			// Browsers only ask when a page opens the microphone, so it is closed again at once
			stopMediaStream(stream);
			permissionRequests--;
			permissionState = GRANTED;
			refreshDevices();
			AudioInput.onPermission.dispatch(true);
		}, function(error)
		{
			permissionRequests--;

			if (isPermissionError(error))
			{
				permissionState = DENIED;
			}

			AudioInput.onPermission.dispatch(false);
		});
	}

	public function new(parent:AudioInput)
	{
		this.parent = parent;

		buffers = [];
		frameSize = getFrameSize();
		queuedBytes = 0;
	}

	public function dispose():Void
	{
		disposed = true;
		stop();
		buffers = [];
		queuedBytes = 0;
	}

	public function getSamplesAvailable():Int
	{
		if (frameSize <= 0)
		{
			return 0;
		}

		return Std.int(queuedBytes / frameSize);
	}

	public function read(buffer:Bytes, samples:Int):Int
	{
		if (buffer == null || samples <= 0 || frameSize <= 0)
		{
			return 0;
		}

		var samplesToRead = samples;
		var available = getSamplesAvailable();
		var maxSamples = Std.int(buffer.length / frameSize);

		if (samplesToRead > available)
		{
			samplesToRead = available;
		}

		if (samplesToRead > maxSamples)
		{
			samplesToRead = maxSamples;
		}

		if (samplesToRead <= 0)
		{
			return 0;
		}

		var bytesToRead = samplesToRead * frameSize;
		var remaining = bytesToRead;
		var writePosition = 0;

		while (remaining > 0 && buffers.length > 0)
		{
			var data = buffers[0];
			var availableBytes = data.bytes.length - data.offset;
			var copyBytes = availableBytes < remaining ? availableBytes : remaining;

			buffer.blit(writePosition, data.bytes, data.offset, copyBytes);

			data.offset += copyBytes;
			writePosition += copyBytes;
			remaining -= copyBytes;
			queuedBytes -= copyBytes;

			if (data.offset >= data.bytes.length)
			{
				buffers.shift();
			}
		}

		return Std.int((bytesToRead - remaining) / frameSize);
	}

	public function start():Bool
	{
		if (disposed || starting || parent.running || !isSupported() || !isFormatSupported())
		{
			return parent.running;
		}

		starting = true;
		audioContext = createAudioContext();

		if (audioContext == null)
		{
			starting = false;
			return false;
		}

		if (audioContext.resume != null)
		{
			audioContext.resume();
		}

		var constraints:Dynamic =
			{
				audio:
					{
						channelCount: parent.channels,
						echoCancellation: false,
						noiseSuppression: false,
						autoGainControl: false
					}
			};

		if (parent.sampleRate > 0)
		{
			constraints.audio.sampleRate = parent.sampleRate;
		}

		if (parent.device != null && !parent.device.isDefault && parent.device.id != null && parent.device.id != "")
		{
			constraints.audio.deviceId = {exact: parent.device.id};
		}

		var navigator:Dynamic = Browser.navigator;
		var promise:Dynamic = navigator.mediaDevices.getUserMedia(constraints);

		queryPermission();
		permissionRequests++;

		promise.then(function(stream)
		{
			permissionRequests--;
			setPermissionState(GRANTED, true);

			if (disposed || !starting)
			{
				stopMediaStream(stream);
				return;
			}

			open(stream);
		}, function(error)
		{
			permissionRequests--;
			starting = false;
			parent.running = false;

			if (isPermissionError(error))
			{
				setPermissionState(DENIED, true);
			}
		});

		return false;
	}

	public function stop():Void
	{
		starting = false;
		parent.running = false;

		if (sourceNode != null)
		{
			sourceNode.disconnect();
			sourceNode = null;
		}

		if (processorNode != null)
		{
			processorNode.disconnect();
			processorNode.onaudioprocess = null;
			processorNode = null;
		}

		if (audioContext != null && audioContext.close != null)
		{
			audioContext.close();
			audioContext = null;
		}

		if (mediaStream != null)
		{
			stopMediaStream(mediaStream);
			mediaStream = null;
		}
	}

	private function appendSamples(event:Dynamic):Void
	{
		var outputBuffer:Dynamic = event.outputBuffer;

		if (outputBuffer != null)
		{
			for (channel in 0...outputBuffer.numberOfChannels)
			{
				var output = outputBuffer.getChannelData(channel);

				for (frame in 0...outputBuffer.length)
				{
					output[frame] = 0;
				}
			}
		}

		if (!parent.running || disposed || frameSize <= 0)
		{
			return;
		}

		var inputBuffer:Dynamic = event.inputBuffer;
		var frames:Int = inputBuffer.length;
		var inputChannels:Int = inputBuffer.numberOfChannels;
		var channelData:Array<Dynamic> = [];

		for (channel in 0...parent.channels)
		{
			var sourceChannel = channel < inputChannels ? channel : 0;
			channelData.push(inputBuffer.getChannelData(sourceChannel));
		}

		var bytes = Bytes.alloc(frames * frameSize);
		var position = 0;

		for (frame in 0...frames)
		{
			for (channel in 0...parent.channels)
			{
				var sample:Float = channelData[channel][frame];

				if (sample > 1)
				{
					sample = 1;
				}
				else if (sample < -1)
				{
					sample = -1;
				}

				if (parent.bitsPerSample == 8)
				{
					bytes.set(position++, Std.int((sample * 0.5 + 0.5) * 255) & 0xFF);
				}
				else
				{
					var value = sample < 0 ? Std.int(sample * 32768) : Std.int(sample * 32767);
					bytes.set(position++, value & 0xFF);
					bytes.set(position++, (value >> 8) & 0xFF);
				}
			}
		}

		buffers.push({bytes: bytes, offset: 0});
		queuedBytes += bytes.length;
		trimQueue();
	}

	private function createAudioContext():Dynamic
	{
		var window:Dynamic = Browser.window;
		var audioContextClass:Dynamic = window.AudioContext != null ? window.AudioContext : window.webkitAudioContext;

		if (audioContextClass == null)
		{
			return null;
		}

		try
		{
			return untyped #if haxe4 js.Syntax.code #else __js__ #end ("new audioContextClass({ sampleRate: {0} })", parent.sampleRate);
		}
		catch (e:Dynamic)
		{
			return untyped #if haxe4 js.Syntax.code #else __js__ #end ("new audioContextClass()");
		}
	}

	private function getFrameSize():Int
	{
		return Std.int((parent.channels * parent.bitsPerSample) / 8);
	}

	private function getProcessorBufferSize():Int
	{
		var size = 256;

		while (size < parent.bufferSize && size < 16384)
		{
			size *= 2;
		}

		return size;
	}

	private function isFormatSupported():Bool
	{
		return (parent.channels == 1 || parent.channels == 2) && (parent.bitsPerSample == 8 || parent.bitsPerSample == 16);
	}

	private function open(stream:Dynamic):Void
	{
		if (audioContext == null)
		{
			starting = false;
			stopMediaStream(stream);
			return;
		}

		if (audioContext.sampleRate != null)
		{
			parent.sampleRate = Std.int(audioContext.sampleRate);
		}

		mediaStream = stream;
		watchTracks(stream);
		sourceNode = audioContext.createMediaStreamSource(stream);
		processorNode = audioContext.createScriptProcessor(getProcessorBufferSize(), parent.channels, parent.channels);

		processorNode.onaudioprocess = appendSamples;
		sourceNode.connect(processorNode);
		processorNode.connect(audioContext.destination);

		if (audioContext.resume != null)
		{
			audioContext.resume();
		}

		starting = false;
		parent.running = true;
		refreshDevices();
	}

	private static function isPermissionError(error:Dynamic):Bool
	{
		var name:String = error != null ? error.name : null;

		// PermissionDeniedError is what older Chrome versions used
		return name == "NotAllowedError" || name == "SecurityError" || name == "PermissionDeniedError";
	}

	private static function queryPermission():Void
	{
		if (permissionQueried)
		{
			return;
		}

		permissionQueried = true;

		var navigator:Dynamic = Browser.navigator;

		if (navigator == null || navigator.permissions == null || navigator.permissions.query == null)
		{
			return;
		}

		try
		{
			var promise:Dynamic = navigator.permissions.query({name: "microphone"});

			promise.then(function(status:Dynamic)
			{
				// Firefox answers "prompt" again after a refusal for this visit only,
				// so the first answer does not replace what a request learned
				if (permissionState == UNDETERMINED)
				{
					permissionState = toPermissionStatus(status.state);
				}

				status.onchange = function(event)
				{
					// A pending request dispatches the answer itself
					setPermissionState(toPermissionStatus(status.state), permissionRequests == 0);
				};
			}, function(error) {});
		}
		catch (e:Dynamic)
		{
			// Some browsers throw for a permission name they do not know
		}
	}

	private static function setPermissionState(status:PermissionStatus, dispatch:Bool):Void
	{
		if (status == permissionState)
		{
			return;
		}

		permissionState = status;

		if (dispatch && status != UNDETERMINED)
		{
			AudioInput.onPermission.dispatch(status == GRANTED);
		}
	}

	private static function toPermissionStatus(state:String):PermissionStatus
	{
		return switch (state)
		{
			case "granted": GRANTED;
			case "denied": DENIED;
			default: UNDETERMINED;
		}
	}

	private static function refreshDevices():Void
	{
		if (enumeratingDevices || !isSupported())
		{
			return;
		}

		enumeratingDevices = true;

		var navigator:Dynamic = Browser.navigator;
		var promise:Dynamic = navigator.mediaDevices.enumerateDevices();

		promise.then(function(devices)
		{
			var result:Array<AudioInputDevice> = [];
			var length:Int = devices.length;

			for (i in 0...length)
			{
				var device:Dynamic = devices[i];

				if (device.kind == "audioinput")
				{
					var label:String = device.label != null && device.label != "" ? device.label : "Audio Input";
					result.push(new AudioInputDevice(label, device.deviceId, result.length == 0));
				}
			}

			if (result.length > 0)
			{
				cachedDevices = result;
			}

			enumeratingDevices = false;
		}, function(error)
		{
			enumeratingDevices = false;
		});
	}

	private function watchTracks(stream:Dynamic):Void
	{
		// A track ends when its device is unplugged or the permission is taken back, not when it is stopped
		var tracks:Dynamic = stream.getTracks();
		var length:Int = tracks.length;

		for (i in 0...length)
		{
			tracks[i].onended = function(event)
			{
				if (disposed || mediaStream != stream) return;
				stop();
				parent.running = false;
				parent.onDisconnect.dispatch();
			};
		}
	}

	private static function stopMediaStream(stream:Dynamic):Void
	{
		if (stream == null || stream.getTracks == null)
		{
			return;
		}

		var tracks:Dynamic = stream.getTracks();
		var length:Int = tracks.length;

		for (i in 0...length)
		{
			tracks[i].stop();
		}
	}

	private function trimQueue():Void
	{
		var maxQueuedBytes = Std.int((parent.sampleRate * MAX_QUEUED_MS / 1000) * frameSize);

		while (queuedBytes > maxQueuedBytes && buffers.length > 0)
		{
			var data = buffers.shift();
			queuedBytes -= data.bytes.length - data.offset;
		}
	}
}
