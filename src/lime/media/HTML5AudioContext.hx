package lime.media;

#if (!lime_doc_gen || (js && html5))
#if (js && html5)
import js.html.Audio;
#end

@:access(lime.media.AudioBuffer)
class HTML5AudioContext
{
	public var HAVE_CURRENT_DATA:Int = 2;
	public var HAVE_ENOUGH_DATA:Int = 4;
	public var HAVE_FUTURE_DATA:Int = 3;
	public var HAVE_METADATA:Int = 1;
	public var HAVE_NOTHING:Int = 0;
	public var NETWORK_EMPTY:Int = 0;
	public var NETWORK_IDLE:Int = 1;
	public var NETWORK_LOADING:Int = 2;
	public var NETWORK_NO_SOURCE:Int = 3;

	@:noCompletion private function new() {}

	public function canPlayType(buffer:AudioBuffer, type:String):String
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.canPlayType(type);
		}
		#end

		return null;
	}

	public function createBuffer(urlString:String = null):AudioBuffer
	{
		#if (js && html5)
		var buffer = new AudioBuffer();
		buffer.__srcAudio = new Audio();
		buffer.__srcAudio.src = urlString;
		return buffer;
		#else
		return null;
		#end
	}

	public function getAutoplay(buffer:AudioBuffer):Bool
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.autoplay;
		}
		#end

		return false;
	}

	public function getBuffered(buffer:AudioBuffer):Dynamic /*TimeRanges*/
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.buffered;
		}
		#end

		return null;
	}

	public function getCurrentSrc(buffer:AudioBuffer):String
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.currentSrc;
		}
		#end

		return null;
	}

	public function getCurrentTime(buffer:AudioBuffer):Float
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.currentTime;
		}
		#end

		return 0;
	}

	public function getDefaultPlaybackRate(buffer:AudioBuffer):Float
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.defaultPlaybackRate;
		}
		#end

		return 1;
	}

	public function getDuration(buffer:AudioBuffer):Float
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.duration;
		}
		#end

		return 0;
	}

	public function getEnded(buffer:AudioBuffer):Bool
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.ended;
		}
		#end

		return false;
	}

	public function getError(buffer:AudioBuffer):Dynamic /*MediaError*/
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.error;
		}
		#end

		return null;
	}

	public function getLoop(buffer:AudioBuffer):Bool
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.loop;
		}
		#end

		return false;
	}

	public function getMuted(buffer:AudioBuffer):Bool
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.muted;
		}
		#end

		return false;
	}

	public function getNetworkState(buffer:AudioBuffer):Int
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.networkState;
		}
		#end

		return 0;
	}

	public function getPaused(buffer:AudioBuffer):Bool
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.paused;
		}
		#end

		return false;
	}

	public function getPlaybackRate(buffer:AudioBuffer):Float
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.playbackRate;
		}
		#end

		return 1;
	}

	public function getPlayed(buffer:AudioBuffer):Dynamic /*TimeRanges*/
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.played;
		}
		#end

		return null;
	}

	public function getPreload(buffer:AudioBuffer):String
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.preload;
		}
		#end

		return null;
	}

	public function getReadyState(buffer:AudioBuffer):Int
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.readyState;
		}
		#end

		return 0;
	}

	public function getSeekable(buffer:AudioBuffer):Dynamic /*TimeRanges*/
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.seekable;
		}
		#end

		return null;
	}

	public function getSeeking(buffer:AudioBuffer):Bool
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.seeking;
		}
		#end

		return false;
	}

	public function getSrc(buffer:AudioBuffer):String
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.src;
		}
		#end

		return null;
	}

	public function getStartTime(buffer:AudioBuffer):Float
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.playbackRate;
		}
		#end

		return 0;
	}

	public function getVolume(buffer:AudioBuffer):Float
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			return buffer.__srcAudio.volume;
		}
		#end

		return 1;
	}

	public function load(buffer:AudioBuffer):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.load();
		}
		#end
	}

	public function pause(buffer:AudioBuffer):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.pause();
		}
		#end
	}

	public function play(buffer:AudioBuffer):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.play();
		}
		#end
	}

	public function setAutoplay(buffer:AudioBuffer, value:Bool):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.autoplay = value;
		}
		#end
	}

	public function setCurrentTime(buffer:AudioBuffer, value:Float):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.currentTime = value;
		}
		#end
	}

	public function setDefaultPlaybackRate(buffer:AudioBuffer, value:Float):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.defaultPlaybackRate = value;
		}
		#end
	}

	public function setLoop(buffer:AudioBuffer, value:Bool):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.loop = value;
		}
		#end
	}

	public function setMuted(buffer:AudioBuffer, value:Bool):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.muted = value;
		}
		#end
	}

	public function setPlaybackRate(buffer:AudioBuffer, value:Float):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.playbackRate = value;
		}
		#end
	}

	public function setPreload(buffer:AudioBuffer, value:String):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.preload = value;
		}
		#end
	}

	public function setSrc(buffer:AudioBuffer, value:String):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.src = value;
		}
		#end
	}

	public function setVolume(buffer:AudioBuffer, value:Float):Void
	{
		#if (js && html5)
		if (buffer.__srcAudio != null)
		{
			buffer.__srcAudio.volume = value;
		}
		#end
	}
}
#end
