package lime.net.curl;

#if (!lime_doc_gen || lime_curl)
import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFI;
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
		return CFFI.stringValue(result);
		#else
		return null;
		#end
	}

	/**
		What libcurl wrote to this handle's error buffer, which
		`setOption(ERRORBUFFER, true)` turns on: why the last transfer failed,
		in more detail than `strerror` gives for its code, or `""` if it did not
		fail. `null` while the error buffer is off, as it is by default and
		after `reset`. Read it once the transfer is over.
	**/
	public function getErrorBuffer():String
	{
		#if (lime_cffi && lime_curl && !macro)
		var result = NativeCFFI.lime_curl_easy_errorbuffer(handle);
		#if hl
		return result == null ? null : @:privateAccess String.fromUTF8(result);
		#else
		return CFFI.stringValue(result);
		#end
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
		#if hl
		var result:Dynamic = NativeCFFI.lime_curl_easy_getinfo(handle, cast(info, Int));
		// String infos come back as their UTF-8 bytes
		if (result != null && hl.Type.getDynamic(result).kind == HBytes)
		{
			var text = @:privateAccess String.fromUTF8((result : hl.Bytes));

			// The cookie list comes as a line for each cookie, and is an array of them, as elsewhere
			if (info == CURLInfo.COOKIELIST)
			{
				return text == "" ? [] : text.split("\n");
			}

			return text;
		}
		return result;
		#else
		return NativeCFFI.lime_curl_easy_getinfo(handle, cast(info, Int));
		#end
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
				parameter = function(header)
				{
					callback(this, CFFI.stringValue(header));
				}

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
		return CFFI.stringValue(result);
		#else
		return null;
		#end
	}

	public function unescape(url:String, inLength:Int, outLength:Int):String
	{
		#if (lime_cffi && lime_curl && !macro)
		var result = NativeCFFI.lime_curl_easy_unescape(handle, url, inLength, outLength);
		#if hl
		// The decoded length comes first, as a %00 decodes to a zero, which would end
		// the string if it were read up to its first zero
		if (result == null) return null;
		return __utf8String(result.offset(4), result.getI32(0));
		#else
		return CFFI.stringValue(result);
		#end
		#else
		return null;
		#end
	}

	#if hl
	// length bytes of UTF-8 as a String, zeros included
	private static function __utf8String(bytes:hl.Bytes, length:Int):String
	{
		var text = new StringBuf();
		var i = 0;

		while (i < length)
		{
			var lead = bytes[i];

			if (lead < 0x80)
			{
				text.addChar(lead);
				i++;
			}
			else if (lead >= 0xC2 && lead < 0xE0 && i + 1 < length)
			{
				text.addChar(((lead & 0x1F) << 6) | (bytes[i + 1] & 0x3F));
				i += 2;
			}
			else if (lead >= 0xE0 && lead < 0xF0 && i + 2 < length)
			{
				text.addChar(((lead & 0x0F) << 12) | ((bytes[i + 1] & 0x3F) << 6) | (bytes[i + 2] & 0x3F));
				i += 3;
			}
			else if (lead >= 0xF0 && lead < 0xF5 && i + 3 < length)
			{
				text.addChar(((lead & 0x07) << 18) | ((bytes[i + 1] & 0x3F) << 12) | ((bytes[i + 2] & 0x3F) << 6) | (bytes[i + 3] & 0x3F));
				i += 4;
			}
			else
			{
				text.addChar(0xFFFD);
				i++;
			}
		}

		return text.toString();
	}
	#end

	public static function version():String
	{
		#if (lime_cffi && lime_curl && !macro)
		var result = NativeCFFI.lime_curl_version();
		return CFFI.stringValue(result);
		#else
		return null;
		#end
	}

	/**
		Returns facts about the curl library Lime was built with, as in
		`curl_version_info`: its `age`, its `versionNum`, and its `features`, a
		mask of `CURL_VERSION_*` bits. Returns `null` where curl isn't available.
	**/
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
