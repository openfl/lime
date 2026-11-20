package lime._internal.backend.flash;

import flash.events.Event;
import flash.events.SampleDataEvent;
import flash.events.StatusEvent;
import flash.media.Microphone;
#if flash10_2
import flash.media.MicrophoneEnhancedMode;
import flash.media.MicrophoneEnhancedOptions;
#end
import haxe.io.Bytes;
import haxe.Timer;
import lime.media.AudioInput;
import lime.media.AudioInputDevice;
import lime.system.PermissionStatus;

private typedef AudioInputData =
{
	var bytes:Bytes;
	var offset:Int;
}

@:access(lime.media.AudioInput)
class FlashAudioInput
{
	private static inline var MAX_QUEUED_MS = 10000;

	private static var permissionDenied:Bool;
	private static var permissionMicrophone:Microphone;
	private static var permissionRequests:Int = 0;

	private var buffers:Array<AudioInputData>;
	private var frameSize:Int;
	private var microphone:Microphone;
	private var parent:AudioInput;
	private var processing:Int;
	private var queuedBytes:Int;

	public static function getDefaultDevice():AudioInputDevice
	{
		if (!isSupported())
		{
			return null;
		}

		var microphone = Microphone.getMicrophone();

		if (microphone != null)
		{
			return new AudioInputDevice(microphone.name, Std.string(microphone.index), true);
		}

		var devices = getDevices();
		return devices.length > 0 ? devices[0] : null;
	}

	public static function getDevices():Array<AudioInputDevice>
	{
		var devices:Array<AudioInputDevice> = [];

		if (!isSupported() || Microphone.names == null)
		{
			return devices;
		}

		for (i in 0...Microphone.names.length)
		{
			var name = Std.string(Microphone.names[i]);
			devices.push(new AudioInputDevice(name, Std.string(i), i == 0));
		}

		return devices;
	}

	public static function getPermissionStatus():PermissionStatus
	{
		if (!isSupported())
		{
			return UNDETERMINED;
		}

		var status = getAIRPermissionStatus();

		if (status != null)
		{
			return status == "granted" ? GRANTED : (status == "denied" ? DENIED : UNDETERMINED);
		}

		// Flash Player keeps a microphone muted until the user allows it in its dialog
		var microphone = Microphone.getMicrophone();

		if (microphone != null && !microphone.muted)
		{
			return GRANTED;
		}

		return permissionDenied ? DENIED : UNDETERMINED;
	}

	public static function isSupported():Bool
	{
		return Microphone.isSupported;
	}

	public static function requestPermission():Void
	{
		var microphone = isSupported() ? Microphone.getMicrophone() : null;

		if (microphone == null)
		{
			Timer.delay(AudioInput.onPermission.dispatch.bind(false), 0);
			return;
		}

		if (getAIRPermissionStatus() != null)
		{
			// AIR 24 and later ask with requestPermission() and answer with a PermissionEvent,
			// which answers every request made meanwhile
			if (permissionRequests++ > 0) return;
			microphone.addEventListener("permissionStatus", microphone_onPermissionStatus);
			untyped microphone.requestPermission();
			return;
		}

		if (!microphone.muted)
		{
			Timer.delay(AudioInput.onPermission.dispatch.bind(true), 0);
			return;
		}

		// One dialog answers every request made while it is shown
		permissionRequests++;

		if (permissionMicrophone != null)
		{
			return;
		}

		// Flash Player shows its dialog when a microphone is listened to, and answers with a StatusEvent
		permissionMicrophone = microphone;
		microphone.addEventListener(StatusEvent.STATUS, microphone_onStatus);
		microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, microphone_onPermissionSampleData);
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
		if (parent.running || !isSupported() || !isFormatSupported())
		{
			return parent.running;
		}

		var index = -1;

		if (parent.device != null && !parent.device.isDefault && parent.device.id != null)
		{
			var parsedIndex = Std.parseInt(parent.device.id);

			if (parsedIndex != null)
			{
				index = parsedIndex;
			}
		}

		var requested = parent.__processing;
		processing = 0;
		microphone = null;

		#if flash10_2
		// The enhanced microphone cancels echo in full duplex, and its automatic gain
		// comes with that mode
		if ((requested & 1) != 0)
		{
			microphone = Microphone.getEnhancedMicrophone(index);

			if (microphone != null)
			{
				var options = new MicrophoneEnhancedOptions();
				options.mode = MicrophoneEnhancedMode.FULL_DUPLEX;
				options.autoGain = (requested & 4) != 0;
				microphone.enhancedOptions = options;
				processing = requested & (1 | 4);
			}
		}
		#end

		if (microphone == null)
		{
			microphone = Microphone.getMicrophone(index);
		}

		if (microphone == null)
		{
			return false;
		}

		// The enhanced microphone only captures at 16 kHz
		if (processing == 0)
		{
			microphone.rate = getMicrophoneRate(parent.sampleRate);
		}

		parent.sampleRate = getSampleRate(microphone.rate);

		#if flash10_1
		// Flash suppresses noise by 30 dB unless it is told not to
		microphone.noiseSuppressionLevel = (requested & 2) != 0 ? -30 : 0;
		if ((requested & 2) != 0) processing |= 2;
		#end

		microphone.setLoopBack(false);
		microphone.setSilenceLevel(0, -1);
		microphone.setUseEchoSuppression(false);
		microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, microphone_onSampleData);

		return true;
	}

	public function stop():Void
	{
		parent.running = false;

		if (microphone != null)
		{
			microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, microphone_onSampleData);
			microphone = null;
		}
	}

	private function appendSample(bytes:Bytes, position:Int, sample:Float):Int
	{
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

		return position;
	}

	public function getProcessing():Int
	{
		return processing;
	}

	private function getFrameSize():Int
	{
		return Std.int((parent.channels * parent.bitsPerSample) / 8);
	}

	private function getMicrophoneRate(sampleRate:Int):Int
	{
		if (sampleRate >= 44100)
		{
			return 44;
		}
		else if (sampleRate >= 22050)
		{
			return 22;
		}
		else if (sampleRate >= 11025)
		{
			return 11;
		}
		else if (sampleRate >= 8000)
		{
			return 8;
		}

		return 5;
	}

	// Flash names its rates in rounded kHz
	private static function getSampleRate(rate:Int):Int
	{
		return switch (rate)
		{
			case 44: 44100;
			case 22: 22050;
			case 16: 16000;
			case 11: 11025;
			case 8: 8000;
			default: 5512;
		}
	}

	private function isFormatSupported():Bool
	{
		return (parent.channels == 1 || parent.channels == 2) && (parent.bitsPerSample == 8 || parent.bitsPerSample == 16);
	}

	private function microphone_onSampleData(event:SampleDataEvent):Void
	{
		if (!parent.running || frameSize <= 0)
		{
			return;
		}

		event.data.position = 0;

		var samples = Std.int(event.data.bytesAvailable / 4);
		var bytes = Bytes.alloc(samples * frameSize);
		var position = 0;

		for (i in 0...samples)
		{
			var sample = event.data.readFloat();

			for (channel in 0...parent.channels)
			{
				position = appendSample(bytes, position, sample);
			}
		}

		buffers.push({bytes: bytes, offset: 0});
		queuedBytes += bytes.length;
		trimQueue();
	}

	private static function getAIRPermissionStatus():String
	{
		try
		{
			if (Reflect.hasField(Microphone, "permissionStatus"))
			{
				return Reflect.field(Microphone, "permissionStatus");
			}
		}
		catch (e:Dynamic) {}

		return null;
	}

	private static function microphone_onPermissionSampleData(event:SampleDataEvent):Void {}

	private static function microphone_onPermissionStatus(event:Event):Void
	{
		event.target.removeEventListener("permissionStatus", microphone_onPermissionStatus);

		var granted = (untyped event.status) == "granted";
		var requests = permissionRequests;
		permissionRequests = 0;

		for (i in 0...requests)
		{
			AudioInput.onPermission.dispatch(granted);
		}
	}

	private static function microphone_onStatus(event:StatusEvent):Void
	{
		if (event.code != "Microphone.Muted" && event.code != "Microphone.Unmuted")
		{
			return;
		}

		permissionMicrophone.removeEventListener(StatusEvent.STATUS, microphone_onStatus);
		permissionMicrophone.removeEventListener(SampleDataEvent.SAMPLE_DATA, microphone_onPermissionSampleData);
		permissionMicrophone = null;

		permissionDenied = event.code == "Microphone.Muted";

		var requests = permissionRequests;
		permissionRequests = 0;

		for (i in 0...requests)
		{
			AudioInput.onPermission.dispatch(!permissionDenied);
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
