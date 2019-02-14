package lime.net.curl;

#if (!lime_doc_gen || lime_curl)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.net.curl.CURL)
@:access(lime.net.curl.CURLMultiMessage)
class CURLMulti
{
	public var runningHandles(get, never):Int;

	@:noCompletion private var handle:CFFIPointer;
	#if hl
	@:noCompletion private var infoObject:CURLMultiMessage;
	#end

	public function new(handle:CFFIPointer = null)
	{
		if (handle != null)
		{
			this.handle = handle;
		}
		else
		{
			#if (lime_cffi && lime_curl && !macro)
			this.handle = NativeCFFI.lime_curl_multi_init();
			#end
		}

		#if hl
		infoObject = new CURLMultiMessage(null, 0);
		#end
	}

	public function addHandle(curl:CURL):CURLMultiCode
	{
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_multi_add_handle(handle, curl, curl.handle);
		#else
		return cast 0;
		#end
	}

	public function infoRead():CURLMultiMessage
	{
		#if (lime_cffi && lime_curl && !macro)
		var msg:Dynamic = NativeCFFI.lime_curl_multi_info_read(handle #if hl, infoObject #end);

		if (msg != null)
		{
			return new CURLMultiMessage(msg.curl, msg.result);
		}
		#end

		return null;
	}

	public function perform():CURLMultiCode
	{
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_multi_perform(handle);
		#else
		return cast 0;
		#end
	}

	public function removeHandle(curl:CURL):CURLMultiCode
	{
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_multi_remove_handle(handle, curl.handle);
		#else
		return cast 0;
		#end
	}

	public function setOption(option:CURLMultiOption, parameter:Dynamic):CURLMultiCode
	{
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_multi_setopt(handle, option, parameter);
		#else
		return cast 0;
		#end
	}

	public function wait(timeoutMS:Int):CURLMultiCode
	{
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_multi_wait(handle, timeoutMS);
		#else
		return cast 0;
		#end
	}

	// Get & Set Methods
	@:noCompletion private function get_runningHandles():Int
	{
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_multi_get_running_handles(handle);
		#else
		return 0;
		#end
	}
}
#end
