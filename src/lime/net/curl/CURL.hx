package lime.net.curl;

#if (!lime_doc_gen || lime_curl)
import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class CURL
{
	public static inline var GLOBAL_SSL:Int = 1 << 0;
	public static inline var GLOBAL_WIN32:Int = 1 << 1;
	public static inline var GLOBAL_ALL:Int = GLOBAL_SSL | GLOBAL_WIN32;
	public static inline var GLOBAL_NOTHING:Int = 0;
	public static inline var GLOBAL_DEFAULT:Int = GLOBAL_ALL;
	public static inline var GLOBAL_ACK_EINTR:Int = 1 << 2;

	@:noCompletion private var handle:CFFIPointer;
	@:noCompletion private var headerBytes:Bytes;
	@:noCompletion private var writeBytes:Bytes;

	public function new(handle:CFFIPointer = null)
	{
		if (handle != null)
		{
			this.handle = handle;
		}
		else
		{
			#if (lime_cffi && lime_curl && !macro)
			this.handle = NativeCFFI.lime_curl_easy_init();
			#end
		}
	}

	public function cleanup():Void
	{
		#if (lime_cffi && lime_curl && !macro)
		NativeCFFI.lime_curl_easy_cleanup(handle);
		#end
	}

	public function clone():CURL
	{
		#if (lime_cffi && lime_curl && !macro)
		return new CURL(NativeCFFI.lime_curl_easy_duphandle(handle));
		#else
		return null;
		#end
	}

	public function escape(url:String, length:Int):String
	{
		#if (lime_cffi && lime_curl && !macro)
		var result = NativeCFFI.lime_curl_easy_escape(handle, url, length);
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public static function getDate(date:String, now:Int):Int
	{
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_getdate(date, cast now);
		#else
		return 0;
		#end
	}

	public function getInfo(info:CURLInfo):Dynamic
	{
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_easy_getinfo(handle, cast(info, Int));
		#else
		return null;
		#end
	}

	public static function globalCleanup():Void
	{
		#if (lime_cffi && lime_curl && !macro)
		NativeCFFI.lime_curl_global_cleanup();
		#end
	}

	public static function globalInit(flags:Int):CURLCode
	{
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_global_init(flags);
		#else
		return cast 0;
		#end
	}

	public function pause(bitMask:Int):CURLCode
	{
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_pause(handle, bitMask);
		#else
		return cast 0;
		#end
	}

	public function perform():CURLCode
	{
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_perform(handle);
		#else
		return cast 0;
		#end
	}

	/*public static function recv (handle:Dynamic):CURLCode {

		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end

	}*/
	public function reset():Void
	{
		#if (lime_cffi && lime_curl && !macro)
		NativeCFFI.lime_curl_easy_reset(handle);
		#end
	}

	/*public static function send (handle:Dynamic):CURLCode {

		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end

	}*/
	public function setOption(option:CURLOption, parameter:Dynamic):CURLCode
	{
		#if (lime_cffi && lime_curl && !macro)
		var bytes = null;

		switch (option)
		{
			case CURLOption.PROGRESSFUNCTION:
				var callback:CURL->Float->Float->Float->Float->Void = cast parameter;
				parameter = function(dltotal:Float, dlnow:Float, ultotal:Float, ulnow:Float)
				{
					callback(this, dltotal, dlnow, ultotal, ulnow);
				}

			case CURLOption.XFERINFOFUNCTION:
				var callback:CURL->Int->Int->Int->Int->Int = cast parameter;
				parameter = function(dltotal:Int, dlnow:Int, ultotal:Int, ulnow:Int):Int
				{
					return callback(this, dltotal, dlnow, ultotal, ulnow);
				}

			case CURLOption.WRITEFUNCTION:
				var callback:CURL->Bytes->Int = cast parameter;
				parameter = function(bytes:Bytes, length:Int):Int
				{
					var cacheLength = bytes.length;
					@:privateAccess bytes.length = length;
					var read = callback(this, bytes);
					@:privateAccess bytes.length = cacheLength;
					return read;
				}
				bytes = Bytes.alloc(0);

			// case CURLOption.READFUNCTION:

			// Impossible to support with GC blocking restrictions
			// TODO: Unsafe version?
			// return cast 0;

			case CURLOption.READDATA:
				bytes = parameter;

			case CURLOption.HEADERFUNCTION:
				var callback:CURL->String->Void = cast parameter;
				#if hl
				parameter = function(header:hl.Bytes)
				{
					callback(this, @:privateAccess String.fromUTF8(header));
				}
				#else
				parameter = function(header:String)
				{
					callback(this, header);
				}
				#end

			case CURLOption.HTTPHEADER:
				#if hl
				var headers:Array<String> = cast parameter;
				var _headers = new hl.NativeArray<String>(headers.length);
				for (i in 0...headers.length)
					_headers[i] = headers[i];
				parameter = _headers;
				#end

			default:
		}

		return cast NativeCFFI.lime_curl_easy_setopt(handle, cast(option, Int), parameter, bytes);
		#else
		return cast 0;
		#end
	}

	public static function strerror(code:CURLCode):String
	{
		#if (lime_cffi && lime_curl && !macro)
		var result = NativeCFFI.lime_curl_easy_strerror(cast(code, Int));
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public function unescape(url:String, inLength:Int, outLength:Int):String
	{
		#if (lime_cffi && lime_curl && !macro)
		var result = NativeCFFI.lime_curl_easy_unescape(handle, url, inLength, outLength);
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public static function version():String
	{
		#if (lime_cffi && lime_curl && !macro)
		var result = NativeCFFI.lime_curl_version();
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public static function versionInfo(type:CURLVersion):Dynamic
	{
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_version_info(cast(type, Int));
		#else
		return null;
		#end
	}
}
#end
