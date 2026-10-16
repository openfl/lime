package media;

#if (lime_cffi && lime_openal)
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALC;
import lime.media.openal.ALSource;
import lime.utils.UInt8Array;
#end
import utest.Assert;
import utest.Test;

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

	private function createQueuedSource():ALSource
	{
		if (ALC.getCurrentContext() == null)
		{
			Assert.warn("There is no audio output here, so OpenAL was not tested");
			return null;
		}

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
