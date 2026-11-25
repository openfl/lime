package lime._internal.backend.native;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.Timer;
import lime.app.Future;
import lime.app.Promise;
import lime.net.curl.CURL;
import lime.net.curl.CURLCode;
import lime.net.curl.CURLMulti;
import lime.net.curl.CURLMultiCode;
import lime.net.curl.CURLMultiMessage;
import lime.net.HTTPRequest;
import lime.net.HTTPRequestHeader;
import lime.net.HTTPRequestMethod;
import lime.system.ThreadPool;
import lime.system.WorkOutput;
#if sys
#if haxe4
import sys.thread.Deque;
#elseif cpp
import cpp.vm.Deque;
#elseif neko
import neko.vm.Deque;
#end
import sys.FileSystem;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class NativeHTTPRequest
{
	private static var activeInstances:Array<NativeHTTPRequest>;
	private static var localThreadPool:ThreadPool;
	private static var multi:CURLMulti;
	private static var multiInstances:Map<CURL, NativeHTTPRequest>;
	private static var multiProgressTimer:Timer;
	private static var multiThreadPool:ThreadPool;
	private static var multiThreadPoolRunning:Bool;
	#if (cpp || neko || hl)
	private static var multiAddHandle:Deque<CURL>;
	private static var multiRemoveHandle:Deque<CURL>;
	#end
	private static var cookieList:Array<String>;

	// libcurl's own limit
	private static inline var MAX_REDIRECTS = 30;

	private var buffer:BytesBuffer = new BytesBuffer();
	private var bytes:Bytes;
	private var bytesLoaded:Int;
	private var bytesTotal:Int;
	private var canceled:Bool;
	private var contentType:String;
	private var curl:CURL;
	private var followManually:Bool;
	// The transfer's bytes when the progress timer last saw them change, and when that was
	private var idleBytes:Float;
	private var idleSince:Float;
	private var parent:_IHTTPRequest;
	private var promise:Promise<Bytes>;
	private var redirects:Int;
	private var requestData:Bytes;
	private var requestMethod:HTTPRequestMethod;
	private var requestUri:String;
	private var writeBytesLoaded:Int;
	private var writeBytesTotal:Int;
	private var timeout:Timer;
	// Bytes received and sent so far, as the transfer thread reports them
	private var transferredBytes:Float;

	public function new()
	{
		curl = null;
		timeout = null;
	}

	public function cancel():Void
	{
		canceled = true;

		// Nothing more is reported for the load, as with URLLoader.close()
		promise = null;

		if (curl != null)
		{
			var curl = this.curl;
			this.curl = null;

			if (multiInstances != null) multiInstances.remove(curl);
			if (activeInstances != null) activeInstances.remove(this);

			#if (cpp || neko || hl)
			// The transfer thread owns the handle, so it stops the transfer and closes the connection
			if (multiRemoveHandle != null)
			{
				multiRemoveHandle.add(curl);
				multi.wakeup();
			}
			#end
		}

		if (timeout != null)
		{
			timeout.stop();
			timeout = null;
		}
	}

	public function init(parent:_IHTTPRequest):Void
	{
		this.parent = parent;
	}

	private function initRequest(uri:String):Void
	{
		bytesLoaded = 0;
		bytesTotal = 0;
		writeBytesLoaded = 0;
		writeBytesTotal = 0;
		redirects = 0;

		var data = parent.data;
		var query = "";

		if (data == null)
		{
			for (key in parent.formData.keys())
			{
				if (query.length > 0) query += "&";
				query += StringTools.urlEncode(key) + "=" + StringTools.urlEncode(Std.string(parent.formData.get(key)));
			}

			if (query != "")
			{
				if (parent.method == GET)
				{
					if (uri.indexOf("?") > -1)
					{
						uri += "&" + query;
					}
					else
					{
						uri += "?" + query;
					}

					query = "";
				}
				else
				{
					data = Bytes.ofString(query);
				}
			}

			if (data != null && data.length == 0) data = null;
		}

		var contentType = null;

		for (header in cast(parent.headers, Array<Dynamic>))
		{
			if (header.name == "Content-Type")
			{
				contentType = header.value;
			}
		}

		if (parent.contentType != null)
		{
			contentType = parent.contentType;
		}

		if (contentType == null)
		{
			if (parent.data != null)
			{
				contentType = "application/octet-stream";
			}
			else if (query != "")
			{
				contentType = "application/x-www-form-urlencoded";
			}
		}

		initTransfer(uri, parent.method, data, contentType, null);
	}

	// One request of the load: the first, or one a redirect leads to
	private function initTransfer(uri:String, method:HTTPRequestMethod, data:Bytes, contentType:String, referer:String):Void
	{
		bytes = Bytes.alloc(0);
		buffer = new BytesBuffer();

		requestUri = uri;
		requestMethod = method;
		requestData = data;
		this.contentType = contentType;

		// The multi thread cleans up a handle when its transfer ends, and a
		// transfer may still be running, so every load has a handle of its own
		curl = new CURL();

		curl.setOption(URL, uri);

		switch (method)
		{
			case HEAD:
				curl.setOption(NOBODY, true);

			case GET:
				curl.setOption(HTTPGET, true);

			case POST:
				curl.setOption(POST, true);

				if (data != null)
				{
					curl.setOption(INFILE, data);
					curl.setOption(INFILESIZE, data.length);
					curl.setOption(POSTFIELDSIZE, data.length);
				}
				else
				{
					curl.setOption(POSTFIELDSIZE, 0);
				}

			case PUT:
				curl.setOption(UPLOAD, true);

				if (data != null)
				{
					curl.setOption(INFILE, data);
					curl.setOption(INFILESIZE, data.length);
				}
				else
				{
					// Without a size, libcurl sends the upload chunked and reads it from the
					// application's standard input, which may never end
					curl.setOption(INFILESIZE, 0);
				}

			case _:
				curl.setOption(CUSTOMREQUEST, Std.string(method));

				if (data != null)
				{
					curl.setOption(INFILE, data);
					curl.setOption(INFILESIZE, data.length);
				}
		}

		// A request whose method a redirect can change follows redirects itself, as curl
		// would send its Content-Type header on to a GET without content (RFC 9110 section 15.4)
		followManually = parent.followRedirects && method != GET && method != HEAD;
		curl.setOption(FOLLOWLOCATION, parent.followRedirects && !followManually);
		curl.setOption(AUTOREFERER, true);
		if (referer != null) curl.setOption(REFERER, referer);

		var headers = [];
		headers.push("Expect: ");

		for (header in cast(parent.headers, Array<Dynamic>))
		{
			if (header.name != "Content-Type")
			{
				headers.push('${header.name}: ${header.value}');
			}
		}

		if (contentType != null)
		{
			headers.push("Content-Type: " + contentType);
		}

		curl.setOption(HTTPHEADER, headers);

		curl.setOption(PROGRESSFUNCTION, curl_onProgress);
		curl.setOption(WRITEFUNCTION, curl_onWrite);

		if (parent.enableResponseHeaders)
		{
			parent.responseHeaders = [];
			curl.setOption(HEADERFUNCTION, curl_onHeader);
		}

		if (parent.manageCookies)
		{
			// an empty string means store cookies in memory
			// cookies are stored only for the current session
			curl.setOption(COOKIEFILE, "");
			if (cookieList != null)
			{
				for (cookie in cookieList)
				{
					// pass in each stored cookie individually
					curl.setOption(COOKIELIST, cookie);
				}
			}
		}

		curl.setOption(SSL_VERIFYPEER, parent.verifyCertificates);
		curl.setOption(SSL_VERIFYHOST, parent.verifyCertificates ? 2 : 0);
		curl.setOption(USERAGENT, parent.userAgent == null ? "libcurl-agent/1.0" : parent.userAgent);

		// The timeout is how long the request may go without data, which the progress
		// timer measures, not a limit on the whole transfer as curl's TIMEOUT_MS is

		curl.setOption(NOSIGNAL, true);

		#if curl_verbose
		curl.setOption(VERBOSE, true);
		#end
	}

	public function loadData(uri:String, binary:Bool = true):Future<Bytes>
	{
		if (uri == null)
		{
			return cast Future.withError("The URI must not be null");
		}

		var promise = new Promise<Bytes>();
		this.promise = promise;

		canceled = false;

		if (uri.indexOf("http://") == -1 && uri.indexOf("https://") == -1)
		{
			if (localThreadPool == null)
			{
				localThreadPool = new ThreadPool(0, 1);
				localThreadPool.onProgress.add(localThreadPool_onProgress);
				localThreadPool.onComplete.add(localThreadPool_onComplete);
				localThreadPool.onError.add(localThreadPool_onError);
			}

			localThreadPool.run(localThreadPool_doWork, {instance: this, uri: uri});
		}
		else
		{
			if (multi == null)
			{
				CURL.globalInit(CURL.GLOBAL_ALL);

				multi = new CURLMulti();
				activeInstances = new Array();
				multiInstances = new Map();
			}

			initRequest(uri);
			startTransfer();
		}

		return promise.future;
	}

	// Hands the request initTransfer() made to the transfer thread
	private function startTransfer():Void
	{
		if (curl == null) return;

		if (activeInstances.indexOf(this) == -1) activeInstances.push(this);
		multiInstances.set(curl, this);

		transferredBytes = 0;
		idleBytes = 0;
		idleSince = Timer.stamp();

		#if (cpp || neko || hl)
		if (multiAddHandle == null) multiAddHandle = new Deque<CURL>();
		if (multiRemoveHandle == null) multiRemoveHandle = new Deque<CURL>();
		multiAddHandle.add(curl);
		// The transfer thread may be waiting on other transfers' sockets
		multi.wakeup();
		#end

		if (multiThreadPool == null)
		{
			multiThreadPool = new ThreadPool(0, 1);
			multiThreadPool.onProgress.add(multiThreadPool_onProgress);
			multiThreadPool.onComplete.add(multiThreadPool_onComplete);
		}

		if (!multiThreadPoolRunning)
		{
			multiThreadPoolRunning = true;
			multiThreadPool.run(multiThreadPool_doWork, multi);
		}

		if (multiProgressTimer == null)
		{
			multiProgressTimer = new Timer(8);
			multiProgressTimer.run = multiProgressTimer_onRun;
			multiProgressTimer_onRun();
		}
	}

	private function followRedirect(status:Int, uri:String):Void
	{
		redirects++;

		var method = requestMethod;
		var data = requestData;
		var contentType = this.contentType;

		// RFC 9110 sections 15.4.2 to 15.4.4: a 303 is followed with GET, as is a POST after
		// a 301 or 302, as browsers and curl do, and without the content. 307 and 308 keep both.
		if ((status == 303 && method != HEAD) || ((status == 301 || status == 302) && method == POST))
		{
			method = GET;
			data = null;
			contentType = null;
		}

		initTransfer(uri, method, data, contentType, requestUri);
		startTransfer();
	}

	public function loadText(uri:String):Future<String>
	{
		var promise = new Promise<String>();
		var future = loadData(uri, false);

		future.onProgress(promise.progress);

		future.onError(function(error:Dynamic)
		{
			// The body of an error status is text too, for a text request
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (error, _HTTPRequestErrorResponse))
			{
				var response:_HTTPRequestErrorResponse<Bytes> = cast error;
				promise.error(new _HTTPRequestErrorResponse(response.error, response.responseData == null ? null : decodeText(response.responseData)));
			}
			else
			{
				promise.error(error);
			}
		});

		future.onComplete(function(bytes)
		{
			promise.complete(bytes == null ? null : decodeText(bytes));
		});

		return promise.future;
	}

	// The Encoding Standard's UTF-8 decode, as XMLHttpRequest's responseText: a leading
	// byte order mark is dropped, and each invalid sequence becomes U+FFFD
	private static function decodeText(bytes:Bytes):String
	{
		var start = (bytes.length >= 3 && bytes.get(0) == 0xEF && bytes.get(1) == 0xBB && bytes.get(2) == 0xBF) ? 3 : 0;

		// Replaced here, as hxcpp ends the text at the first invalid sequence, and
		// Neko and HashLink keep its bytes
		var text = validUTF8(bytes, start);
		return text.getString(0, text.length);
	}

	// The bytes from start, with each invalid sequence, the lead byte and the continuation
	// bytes that fit it, replaced by U+FFFD
	private static function validUTF8(bytes:Bytes, start:Int):Bytes
	{
		var length = bytes.length;
		var output:BytesBuffer = null;
		var copied = start;
		var i = start;

		while (i < length)
		{
			var lead = bytes.get(i);

			if (lead < 0x80)
			{
				i++;
				continue;
			}

			var needed = 0;
			var lower = 0x80;
			var upper = 0xBF;

			if (lead >= 0xC2 && lead <= 0xDF)
			{
				needed = 1;
			}
			else if (lead >= 0xE0 && lead <= 0xEF)
			{
				needed = 2;
				if (lead == 0xE0) lower = 0xA0;
				else if (lead == 0xED) upper = 0x9F;
			}
			else if (lead >= 0xF0 && lead <= 0xF4)
			{
				needed = 3;
				if (lead == 0xF0) lower = 0x90;
				else if (lead == 0xF4) upper = 0x8F;
			}

			var fit = 0;

			while (fit < needed && i + 1 + fit < length)
			{
				var next = bytes.get(i + 1 + fit);
				if (next < (fit == 0 ? lower : 0x80) || next > (fit == 0 ? upper : 0xBF)) break;
				fit++;
			}

			if (needed > 0 && fit == needed)
			{
				i += needed + 1;
				continue;
			}

			if (output == null) output = new BytesBuffer();
			output.addBytes(bytes, copied, i - copied);
			output.addByte(0xEF);
			output.addByte(0xBF);
			output.addByte(0xBD);

			i += 1 + fit;
			copied = i;
		}

		if (output == null) return start == 0 ? bytes : bytes.sub(start, length - start);

		output.addBytes(bytes, copied, length - copied);
		return output.getBytes();
	}

	private function timeOut():Void
	{
		var promise = this.promise;

		// Stops the transfer and leaves nothing more to report
		cancel();

		// No response finished, as when curl itself times out
		parent.responseStatus = 0;

		if (promise != null)
		{
			promise.error(new _HTTPRequestErrorResponse(CURL.strerror(CURLCode.OPERATION_TIMEDOUT), null));
		}
	}

	private function buildBuffer()
	{
		bytes = buffer.getBytes();
		return bytes;
	}

	// Called before the load's promise is completed, which may load the
	// request again
	private function finishLoad(promise:Promise<Bytes>):Void
	{
		if (this.promise != promise) return;

		if (timeout != null)
		{
			timeout.stop();
			timeout = null;
		}

		bytes = null;
		this.promise = null;
	}

	// Event Handlers
	private function curl_onHeader(curl:CURL, header:String):Void
	{
		if (curl != this.curl) return;

		// A status line starts each response, and only the last one's headers are kept,
		// not those of the redirects and interim 1xx responses before it
		if (StringTools.startsWith(header, "HTTP/"))
		{
			parent.responseHeaders = [];
			return;
		}

		// RFC 9112 section 5.1: the name, a colon, and the value with optional whitespace around it
		var colon = header.indexOf(":");

		if (colon > 0)
		{
			parent.responseHeaders.push(new HTTPRequestHeader(StringTools.trim(header.substr(0, colon)), StringTools.trim(header.substr(colon + 1))));
		}
	}

	private function curl_onProgress(curl:CURL, dltotal:Float, dlnow:Float, uptotal:Float, upnow:Float):Int
	{
		if (curl != this.curl) return 0;

		transferredBytes = dlnow + upnow;

		if (upnow > writeBytesLoaded || dlnow > writeBytesLoaded || uptotal > writeBytesTotal || dltotal > writeBytesTotal)
		{
			if (upnow > writeBytesLoaded) writeBytesLoaded = Std.int(upnow);
			if (dlnow > writeBytesLoaded) writeBytesLoaded = Std.int(dlnow);
			if (uptotal > writeBytesTotal) writeBytesTotal = Std.int(uptotal);
			if (dltotal > writeBytesTotal) writeBytesTotal = Std.int(dltotal);

			// Wrong thread
			// promise.progress (bytesLoaded, bytesTotal);
		}

		return 0;
	}

	private function curl_onWrite(curl:CURL, output:Bytes):Int
	{
		// The request was loaded again, so this transfer is stopped
		if (curl != this.curl) return 0;

		buffer.addBytes(output, 0, output.length);

		return output.length;
	}

	private static function localThreadPool_doWork(state:Dynamic, output:WorkOutput):Void
	{
		var instance:NativeHTTPRequest = state.instance;
		var path:String = state.uri;

		var index = path.indexOf("?");

		if (index > -1)
		{
			path = path.substring(0, index);
		}

		#if (sys && !windows)
		if (StringTools.startsWith(path, "~/"))
		{
			path = Sys.getEnv("HOME") + "/" + path.substr(2);
		}
		#end

		if (path == null #if (sys && !android) || !FileSystem.exists(path) #end)
		{
			output.sendError({instance: instance, promise: instance.promise, error: "Cannot load file: " + path});
		}
		else
		{
			instance.bytes = lime.utils.Bytes.fromFile(path);

			if (instance.bytes != null)
			{
				output.sendProgress(
					{
						instance: instance,
						promise: instance.promise,
						bytesLoaded: instance.bytes.length,
						bytesTotal: instance.bytes.length
					});
				output.sendComplete({instance: instance, promise: instance.promise, result: instance.bytes});
			}
			else
			{
				output.sendError({instance: instance, promise: instance.promise, error: "Cannot load file: " + path});
			}
		}
	}

	private static function localThreadPool_onComplete(state:{instance:NativeHTTPRequest, promise:Promise<Bytes>, result:Bytes}):Void
	{
		var promise:Promise<Bytes> = state.promise;
		// Cancelled, or loaded again
		if (state.instance.promise != promise || promise.isError) return;
		state.instance.finishLoad(promise);
		promise.complete(state.result);
	}

	private static function localThreadPool_onError(state:{instance:NativeHTTPRequest, promise:Promise<Bytes>, error:String}):Void
	{
		var promise:Promise<Bytes> = state.promise;
		if (state.instance.promise != promise) return;
		state.instance.finishLoad(promise);
		promise.error(new _HTTPRequestErrorResponse(state.error, null));
	}

	private static function localThreadPool_onProgress(state:
		{
			instance:NativeHTTPRequest,
			promise:Promise<Bytes>,
			bytesLoaded:Int,
			bytesTotal:Int
		}):Void
	{
		var promise:Promise<Bytes> = state.promise;
		if (state.instance.promise != promise || promise.isComplete || promise.isError) return;
		promise.progress(state.bytesLoaded, state.bytesTotal);
	}

	private static function multiThreadPool_doWork(multi:CURLMulti, output:WorkOutput):Void
	{
		// The handles this pass added that are still running
		var transfers:Array<CURL> = [];

		while (true)
		{
			#if (cpp || neko || hl)
			// Every request queued since the last pass
			var curl = multiAddHandle.pop(false);

			while (curl != null)
			{
				multi.addHandle(curl);
				transfers.push(curl);
				curl = multiAddHandle.pop(false);
			}

			// Then those cancelled, whose transfers end here
			curl = multiRemoveHandle.pop(false);

			while (curl != null)
			{
				if (transfers.remove(curl))
				{
					multi.removeHandle(curl);
					curl.cleanup();
				}

				curl = multiRemoveHandle.pop(false);
			}
			#end

			// load() wakes this when it queues a request, which wait() would leave queued until
			// the other transfers' sockets had activity or the second ran out
			var code = multi.poll(1000);

			if (code == CURLMultiCode.OK)
			{
				multi.perform();
				var message = multi.infoRead();

				if (message == null && multi.runningHandles == 0)
				{
					output.sendComplete();
					break;
				}

				while (message != null)
				{
					var curl = message.curl;
					var status = curl.getInfo(RESPONSE_CODE);

					// Where a redirect leads, for a request that follows them itself
					var redirect:String = (status >= 300 && status < 400) ? curl.getInfo(REDIRECT_URL) : null;

					// returns an array of cookie values
					cookieList = curl.getInfo(COOKIELIST);

					multi.removeHandle(curl);
					transfers.remove(curl);
					curl.cleanup();

					output.sendProgress({curl: curl, result: message.result, status: status, redirect: redirect});
					message = multi.infoRead();
				}
			}
		}
	}

	private static function multiThreadPool_onComplete(_):Void
	{
		#if (cpp || neko || hl)
		var curl = multiAddHandle.pop(false);

		if (curl != null)
		{
			multiAddHandle.push(curl);
			multiThreadPool.run(multiThreadPool_doWork, multi);
		}
		else
		{
			if (multiProgressTimer != null)
			{
				multiProgressTimer.stop();
				multiProgressTimer = null;
			}

			multiThreadPoolRunning = false;
		}
		#end
	}

	private static function multiThreadPool_onProgress(state:{curl:CURL, result:Int, status:Int, redirect:String}):Void
	{
		if (multiInstances.exists(state.curl))
		{
			var instance = multiInstances.get(state.curl);
			multiInstances.remove(state.curl);

			// The request was loaded again before this transfer ended
			if (state.curl != instance.curl)
			{
				state.curl = null;
				return;
			}

			activeInstances.remove(instance);

			// Cleaned up on the multi thread
			instance.curl = null;

			instance.parent.responseStatus = state.status;

			var promise = instance.promise;

			if (state.result == CURLCode.OK && instance.followManually && state.redirect != null && state.redirect != ""
				&& [301, 302, 303, 307, 308].indexOf(state.status) > -1)
			{
				if (instance.redirects < MAX_REDIRECTS)
				{
					instance.followRedirect(state.status, state.redirect);
				}
				else
				{
					instance.finishLoad(promise);
					promise.error(new _HTTPRequestErrorResponse(CURL.strerror(CURLCode.TOO_MANY_REDIRECTS), null));
				}
			}
			else if (state.result == CURLCode.OK)
			{
				if ((state.status >= 200 && state.status < 400) || state.status == 0)
				{
					var data = instance.buildBuffer();

					// The last report has every byte, as the transfer can end between two ticks
					// of the progress timer. A total that is unknown, or counts the body before
					// it was decoded, is the body's length by now.
					var loaded = data != null ? data.length : 0;
					var total = instance.writeBytesTotal > loaded ? instance.writeBytesTotal : loaded;

					if (instance.bytesLoaded != loaded || instance.bytesTotal != total)
					{
						instance.bytesLoaded = loaded;
						instance.bytesTotal = total;
						promise.progress(loaded, total);
					}

					instance.finishLoad(promise);

					if (!promise.isError)
					{
						promise.complete(data);
					}
				}
				else
				{
					// The body is kept as responseData, as XMLHttpRequest keeps it
					var error = 'Status ${state.status}';
					var responseData = instance.buildBuffer();
					instance.finishLoad(promise);
					promise.error(new _HTTPRequestErrorResponse(error, responseData));
				}
			}
			else
			{
				var error = CURL.strerror(state.result);
				instance.finishLoad(promise);
				promise.error(new _HTTPRequestErrorResponse(error, null));
			}
		}

		state.curl = null;
	}

	private static function multiProgressTimer_onRun():Void
	{
		var now = Timer.stamp();

		// A request that times out leaves the list
		for (instance in activeInstances.copy())
		{
			// The timeout counts from the last data either way, as OpenFL's
			// URLRequest.idleTimeout, which it sets it from, does: a download or upload
			// that is still under way carries on past it
			if (instance.transferredBytes != instance.idleBytes)
			{
				instance.idleBytes = instance.transferredBytes;
				instance.idleSince = now;
			}
			else if (instance.parent.timeout > 0 && (now - instance.idleSince) * 1000 >= instance.parent.timeout)
			{
				instance.timeOut();
				continue;
			}

			if (instance.bytesLoaded != instance.writeBytesLoaded || instance.bytesTotal != instance.writeBytesTotal)
			{
				instance.bytesLoaded = instance.writeBytesLoaded;
				instance.bytesTotal = instance.writeBytesTotal;
				instance.promise.progress(instance.bytesLoaded, instance.bytesTotal);
			}
		}
	}
}
