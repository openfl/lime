package lime.media;

#if (!lime_doc_gen || flash)
#if flash
import flash.media.Sound;
#end

class FlashAudioContext
{
	@:noCompletion private function new() {}

	public function createBuffer(stream:Dynamic /*URLRequest*/ = null, context:Dynamic /*SoundLoaderContext*/ = null):AudioBuffer
	{
		#if flash
		var buffer = new AudioBuffer();
		buffer.src = new Sound(stream, context);
		return buffer;
		#else
		return null;
		#end
	}

	public function getBytesLoaded(buffer:AudioBuffer):UInt
	{
		#if flash
		if (buffer.src != null)
		{
			return buffer.src.bytesLoaded;
		}
		#end

		return 0;
	}

	public function getBytesTotal(buffer:AudioBuffer):Int
	{
		#if flash
		if (buffer.src != null)
		{
			return buffer.src.bytesTotal;
		}
		#end

		return 0;
	}

	public function getID3(buffer:AudioBuffer):Dynamic /*ID3Info*/
	{
		#if flash
		if (buffer.src != null)
		{
			return buffer.src.id3;
		}
		#end

		return null;
	}

	public function getIsBuffering(buffer:AudioBuffer):Bool
	{
		#if flash
		if (buffer.src != null)
		{
			return buffer.src.isBuffering;
		}
		#end

		return false;
	}

	public function getIsURLInaccessible(buffer:AudioBuffer):Bool
	{
		#if flash
		if (buffer.src != null)
		{
			return buffer.src.isURLInaccessible;
		}
		#end

		return false;
	}

	public function getLength(buffer:AudioBuffer):Float
	{
		#if flash
		if (buffer.src != null)
		{
			return buffer.src.length;
		}
		#end

		return 0;
	}

	public function getURL(buffer:AudioBuffer):String
	{
		#if flash
		if (buffer.src != null)
		{
			return buffer.src.url;
		}
		#end

		return null;
	}

	public function close(buffer:AudioBuffer):Void
	{
		#if flash
		if (buffer.src != null)
		{
			buffer.src.close();
		}
		#end
	}

	public function extract(buffer:AudioBuffer, target:Dynamic /*flash.utils.ByteArray*/, length:Float, startPosition:Float = -1):Float
	{
		#if flash
		if (buffer.src != null)
		{
			return buffer.src.extract(target, length, startPosition);
		}
		#end

		return 0;
	}

	public function load(buffer:AudioBuffer, stream:Dynamic /*flash.net.URLRequest*/, context:Dynamic /*SoundLoaderContext*/ = null):Void
	{
		#if flash
		if (buffer.src != null)
		{
			buffer.src.load(stream, context);
		}
		#end
	}

	public function loadCompressedDataFromByteArray(buffer:AudioBuffer, bytes:Dynamic /*flash.utils.ByteArray*/, bytesLength:UInt):Void
	{
		#if flash11
		if (buffer.src != null)
		{
			buffer.src.loadCompressedDataFromByteArray(bytes, bytesLength);
		}
		#end
	}

	public function loadPCMFromByteArray(buffer:AudioBuffer, bytes:Dynamic /*flash.utils.ByteArray*/, samples:UInt, format:String = null, stereo:Bool = true,
			sampleRate:Float = 44100):Void
	{
		#if flash11
		if (buffer.src != null)
		{
			buffer.src.loadPCMFromByteArray(bytes, samples, format, stereo, sampleRate);
		}
		#end
	}

	public function play(buffer:AudioBuffer, startTime:Float = 0, loops:Int = 0, sndTransform:Dynamic /*SoundTransform*/ = null):Dynamic /*SoundChannel*/
	{
		#if flash
		if (buffer.src != null)
		{
			return buffer.src.play(startTime, loops, sndTransform);
		}
		#end

		return null;
	}
}
#end
