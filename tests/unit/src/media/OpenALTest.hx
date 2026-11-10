package media;

#if (lime_cffi && lime_openal)
import lime._internal.backend.native.NativeCFFI;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALC;
import lime.media.openal.ALSource;
import lime.utils.UInt8Array;
#end
#if (lime_cffi && lime_openal && sys && target.threaded)
import haxe.Timer;
import sys.thread.Deque;
import sys.thread.Lock;
import sys.thread.Thread;
#end
import utest.Assert;
import utest.Test;

#if (lime_cffi && lime_openal)
@:access(lime._internal.backend.native.NativeCFFI)
#end
class OpenALTest extends Test
{
	#if (lime_cffi && lime_openal)
	private var buffers:Array<ALBuffer>;
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_openal)
	public function testUnqueueingUnplayedBuffersReturnsNone():Void
	{
		var source = createQueuedSource();
		if (source == null) return;

		// Nothing has played, so OpenAL refuses and no buffer comes back
		Assert.equals(0, AL.sourceUnqueueBuffers(source, 2).length);
		Assert.equals(2, AL.getSourcei(source, AL.BUFFERS_QUEUED));
		AL.getError();

		deleteSource(source);
	}

	public function testRemovingTheBufferClearsTheQueue():Void
	{
		var source = createQueuedSource();
		if (source == null) return;

		AL.sourcePlay(source);
		AL.sourceRewind(source);
		AL.sourcei(source, AL.BUFFER, null);

		Assert.equals(AL.NO_ERROR, AL.getError());
		Assert.equals(AL.INITIAL, AL.getSourcei(source, AL.SOURCE_STATE));
		Assert.equals(0, AL.getSourcei(source, AL.BUFFERS_QUEUED));

		deleteSource(source);
	}

	public function testDeviceListsNameEachDevice():Void
	{
		// Each name ends in a null character, so getString() sees only the first
		for (param in [ALC.DEVICE_SPECIFIER, ALC.ALL_DEVICES_SPECIFIER])
		{
			var names = ALC.getStringList(null, param);
			var first = ALC.getString(null, param);

			if (first == null)
			{
				Assert.same([], names);
				continue;
			}

			Assert.isTrue(names.length > 0);
			Assert.equals(first, names[0]);

			for (name in names)
			{
				Assert.isTrue(name.length > 0);
			}
		}
	}

	public function testDeviceListOfAnOpenDeviceIsItsName():Void
	{
		var context = ALC.getCurrentContext();

		if (context == null)
		{
			Assert.pass("There is no audio output here, so no device was open");
			return;
		}

		var device = ALC.getContextsDevice(context);
		Assert.same([ALC.getString(device, ALC.DEVICE_SPECIFIER)], ALC.getStringList(device, ALC.DEVICE_SPECIFIER));
	}

	public function testSourceLatencyGivesTheOffsetAndTheLatency():Void
	{
		var source = createQueuedSource();
		if (source == null) return;

		// OpenAL Soft writes both values, however many are asked for
		Assert.equals(2, AL.getSourcedvSOFT(source, AL.SEC_OFFSET_LATENCY_SOFT).length);
		Assert.equals(1, AL.getSourcedvSOFT(source, AL.SEC_OFFSET_LATENCY_SOFT, 1).length);

		var values = AL.getSourcedvSOFT(source, AL.SEC_OFFSET_LATENCY_SOFT, 4);
		Assert.equals(4, values.length);
		Assert.equals(0.0, values[3]);

		deleteSource(source);
	}

	public function testOtherStringsComeBackAlone():Void
	{
		Assert.same([ALC.getString(null, ALC.EXTENSIONS)], ALC.getStringList(null, ALC.EXTENSIONS));
	}

	public function testDroppingASourceAndItsBuffersLeavesNoError():Void
	{
		if (!hasContext()) return;

		release();
		AL.getError();

		// The collector can finalize a buffer before the source that holds it
		var highest = dropSources(64);
		release();
		Assert.equals(AL.NO_ERROR, AL.getError());

		// OpenAL Soft gives out the lowest free ID, so leaked buffers push these up
		var next = dropSources(64);
		release();
		Assert.isTrue(next <= highest + 16, 'buffers reached $next after $highest');
	}

	public function testABufferDroppedWhileInUseWaitsForItsSource():Void
	{
		if (!hasContext()) return;

		release();
		AL.getError();

		var sources = [for (i in 0...8) AL.createSource()];
		var highest = 0;

		for (source in sources)
		{
			highest = Std.int(Math.max(highest, attachDroppedBuffer(source)));
		}

		release();
		Assert.equals(AL.NO_ERROR, AL.getError());

		for (source in sources)
		{
			Assert.equals(1, AL.getSourcei(source, AL.BUFFERS_QUEUED));
		}

		// Trying the release again doesn't lose the application's own error
		AL.getSourcei(sources[0], 0);
		NativeCFFI.lime_al_cleanup();
		Assert.equals(AL.INVALID_ENUM, AL.getError());
		Assert.equals(AL.NO_ERROR, AL.getError());

		// A buffer can still be found through its source, which gives it a handle again
		var buffer:ALBuffer = AL.getSourcei(sources[0], AL.BUFFER);
		Assert.isTrue(AL.isBuffer(buffer));

		for (source in sources)
		{
			AL.sourcei(source, AL.BUFFER, null);
		}

		AL.deleteBuffer(buffer);
		AL.deleteSources(sources);
		release();
		Assert.equals(AL.NO_ERROR, AL.getError());

		// They are all gone, so their IDs come back
		var next = dropSources(sources.length);
		release();
		Assert.isTrue(next <= highest + 2, 'buffers reached $next after $highest');
	}

	public function testBuffersDroppedWhileQueuedComeBackWhenUnqueued():Void
	{
		if (!hasContext()) return;

		release();
		AL.getError();

		var sources = [for (i in 0...8) AL.createSource()];

		for (source in sources)
		{
			queueDroppedBuffers(source, 2);
		}

		// Their handles go while the sources still hold them
		release();
		Assert.equals(AL.NO_ERROR, AL.getError());

		for (source in sources)
		{
			Assert.equals(2, AL.getSourcei(source, AL.BUFFERS_QUEUED));
		}

		AL.sourcePlayv(sources);
		var end = haxe.Timer.stamp() + 5;

		for (source in sources)
		{
			while (AL.getSourcei(source, AL.BUFFERS_PROCESSED) < 2 && haxe.Timer.stamp() < end)
			{
				Sys.sleep(0.01);
			}
		}

		// Each is the application's again, not deleted as the one before it was taken back
		var buffers:Array<ALBuffer> = [];
		var data = new UInt8Array(64);

		for (source in sources)
		{
			var unqueued = AL.sourceUnqueueBuffers(source, 2);
			Assert.equals(2, unqueued.length);

			for (buffer in unqueued)
			{
				Assert.isTrue(AL.isBuffer(buffer));
				AL.bufferData(buffer, AL.FORMAT_MONO16, data, data.length, 44100);
				buffers.push(buffer);
			}
		}

		Assert.equals(AL.NO_ERROR, AL.getError());

		AL.deleteSources(sources);
		AL.deleteBuffers(buffers);
		release();
		Assert.equals(AL.NO_ERROR, AL.getError());
	}

	public function testDroppedEffectsLeaveNoError():Void
	{
		if (!hasContext()) return;

		if (AL.createAux() == null)
		{
			Assert.pass("This OpenAL has no effects");
			return;
		}

		release();
		AL.getError();

		dropEffects(32);
		release();

		Assert.equals(AL.NO_ERROR, AL.getError());
	}

	public function testDroppedObjectsOfAClosedDeviceLeaveItsReplacementAlone():Void
	{
		if (!hasContext()) return;

		var context = ALC.getCurrentContext();
		var device = ALC.openDevice();
		var replaced = ALC.createContext(device);
		ALC.makeContextCurrent(replaced);

		dropSources(32);

		ALC.makeContextCurrent(null);
		ALC.destroyContext(replaced);
		ALC.closeDevice(device);

		// A new device numbers its objects from the start, as the old one did
		device = ALC.openDevice();
		var replacement = ALC.createContext(device);
		ALC.makeContextCurrent(replacement);

		var sources = [for (i in 0...32) AL.createSource()];
		var buffers = AL.genBuffers(32);

		release();
		Assert.equals(AL.NO_ERROR, AL.getError());

		for (source in sources)
		{
			Assert.isTrue(AL.isSource(source));
		}

		for (buffer in buffers)
		{
			Assert.isTrue(AL.isBuffer(buffer));
		}

		AL.deleteSources(sources);
		AL.deleteBuffers(buffers);

		ALC.makeContextCurrent(context);
		ALC.destroyContext(replacement);
		ALC.closeDevice(device);
	}

	#if (sys && target.threaded)
	public function testCollectingWhileObjectsAreMadeOnAnotherThread():Void
	{
		if (!hasContext()) return;

		// Objects are made under the lock that the finalizers of dropped objects
		// waited for, while the collector held up the thread that had it
		var made = new Deque<Bool>();
		var collected = new Lock();

		Thread.create(function()
		{
			for (i in 0...1000)
			{
				AL.deleteBuffer(AL.createBuffer());
			}

			made.add(true);

			// Neko's collector can abort if a thread ends while it collects
			collected.wait();
		});

		var finished = false;
		var end = Timer.stamp() + 10;

		while (!finished && Timer.stamp() < end)
		{
			// Objects for the collector to finalize
			for (i in 0...8)
			{
				AL.createBuffer();
			}

			collect();

			finished = made.pop(false) != null;
		}

		collected.release();
		Sys.sleep(0.1);

		Assert.isTrue(finished, "the other thread did not finish making objects");
	}
	#end

	private function attachDroppedBuffer(source:ALSource):Int
	{
		var buffer = AL.createBuffer();
		var data = new UInt8Array(64);

		AL.bufferData(buffer, AL.FORMAT_MONO16, data, data.length, 44100);
		AL.sourcei(source, AL.BUFFER, buffer);

		return AL.getSourceiv(source, AL.BUFFER)[0];
	}

	private function dropEffects(count:Int):Void
	{
		for (i in 0...count)
		{
			AL.createAux();
			AL.createEffect();
			AL.createFilter();
		}
	}

	private function queueDroppedBuffers(source:ALSource, count:Int):Void
	{
		var buffers = AL.genBuffers(count);
		var data = new UInt8Array(64);

		for (buffer in buffers)
		{
			AL.bufferData(buffer, AL.FORMAT_MONO16, data, data.length, 44100);
		}

		AL.sourceQueueBuffers(source, buffers.length, buffers);
	}

	private function dropSources(count:Int):Int
	{
		var highest = 0;

		for (i in 0...count)
		{
			highest = Std.int(Math.max(highest, attachDroppedBuffer(AL.createSource())));
		}

		return highest;
	}

	private function hasContext():Bool
	{
		if (ALC.getCurrentContext() == null)
		{
			Assert.warn("There is no audio output here, so OpenAL was not tested");
			return false;
		}

		return true;
	}

	private static function collect():Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		#elseif neko
		neko.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}

	private static function release():Void
	{
		collect();
		collect();
		NativeCFFI.lime_al_cleanup();
	}

	private function createQueuedSource():ALSource
	{
		if (!hasContext()) return null;

		var source = AL.createSource();
		buffers = AL.genBuffers(2);
		var data = new UInt8Array(4410 * 2);

		for (buffer in buffers)
		{
			AL.bufferData(buffer, AL.FORMAT_MONO16, data, data.length, 44100);
		}

		AL.sourceQueueBuffers(source, buffers.length, buffers);
		return source;
	}

	private function deleteSource(source:ALSource):Void
	{
		// Deleting the source releases its queue, so the buffers can go too
		AL.deleteSource(source);
		AL.deleteBuffers(buffers);
		buffers = null;
	}
	#end
}
