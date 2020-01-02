package lime._internal.backend.native;

import haxe.io.Bytes;
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
	#end

	private var bytes:Bytes;
	private var bytesLoaded:Int;
	private var bytesTotal:Int;
	private var canceled:Bool;
	private var curl:CURL;
	private var parent:_IHTTPRequest;
	private var promise:Promise<Bytes>;
	private var writeBytesLoaded:Int;
	private var writeBytesTotal:Int;
	private var writePosition:Int;
	private var timeout:Timer;

	public function new()
	{
		curl = null;
		timeout = null;
	}

	public function cancel():Void
	{
		canceled = true;

		if (curl != null)
		{
			// This is probably run from a different thread if cURL is running
			// TODO

			// CURLEasy.cleanup (curl);
			// CURLEasy.reset (curl);
			// CURLEasy.perform (curl);
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

	private function initRequest(uri:String, binary:Bool):Void
	{
		bytes = Bytes.alloc(0);

		bytesLoaded = 0;
		bytesTotal = 0;
		writeBytesLoaded = 0;
		writeBytesTotal = 0;
		writePosition = 0;

		if (curl == null)
		{
			curl = new CURL();
		}
		else
		{
			curl.reset();
		}

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

		curl.setOption(URL, uri);

		switch (parent.method)
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

			case _:
				curl.setOption(CUSTOMREQUEST, Std.string(parent.method));

				if (data != null)
				{
					curl.setOption(INFILE, data);
					curl.setOption(INFILESIZE, data.length);
				}
		}

		curl.setOption(FOLLOWLOCATION, parent.followRedirects);
		curl.setOption(AUTOREFERER, true);

		var headers = [];
		headers.push("Expect: ");

		var contentType = null;

		for (header in cast(parent.headers, Array<Dynamic>))
		{
			if (header.name == "Content-Type")
			{
				contentType = header.value;
			}
			else
			{
				headers.push('${header.name}: ${header.value}');
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

		// TODO: Add support for cookies: https://curl.haxx.se/docs/http-cookies.html

		if (parent.withCredentials)
		{
			// TODO: Send cookies with request
		}

		curl.setOption(SSL_VERIFYPEER, false);
		curl.setOption(SSL_VERIFYHOST, 0);
		curl.setOption(USERAGENT, parent.userAgent == null ? "libcurl-agent/1.0" : parent.userAgent);

		// curl.setOption (CONNECTTIMEOUT, 30);
		curl.setOption(NOSIGNAL, true);

		curl.setOption(TRANSFERTEXT, !binary);

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
				localThreadPool.doWork.add(localThreadPool_doWork);
				localThreadPool.onProgress.add(localThreadPool_onProgress);
				localThreadPool.onComplete.add(localThreadPool_onComplete);
				localThreadPool.onError.add(localThreadPool_onError);
			}

			localThreadPool.queue({instance: this, uri: uri});
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

			initRequest(uri, binary);

			if (curl != null)
			{
				activeInstances.push(this);
				multiInstances.set(curl, this);

				#if (cpp || neko || hl)
				if (multiAddHandle == null) multiAddHandle = new Deque<CURL>();
				multiAddHandle.add(curl);
				#end

				if (multiThreadPool == null)
				{
					multiThreadPool = new ThreadPool(0, 1);
					multiThreadPool.doWork.add(multiThreadPool_doWork);
					multiThreadPool.onProgress.add(multiThreadPool_onProgress);
					multiThreadPool.onComplete.add(multiThreadPool_onComplete);
				}

				if (!multiThreadPoolRunning)
				{
					multiThreadPoolRunning = true;
					multiThreadPool.queue();
				}

				if (multiProgressTimer == null)
				{
					multiProgressTimer = new Timer(8);
					multiProgressTimer.run = multiProgressTimer_onRun;
					multiProgressTimer_onRun();
				}
			}
		}

		return promise.future;
	}

	public function loadText(uri:String):Future<String>
	{
		var promise = new Promise<String>();
		var future = loadData(uri, false);

		future.onProgress(promise.progress);
		future.onError(promise.error);

		future.onComplete(function(bytes)
		{
			if (bytes == null)
			{
				promise.complete(null);
			}
			else
			{
				promise.complete(bytes.getString(0, bytes.length));
			}
		});

		return promise.future;
	}

	private function growBuffer(length:Int)
	{
		if (length > bytes.length)
		{
			var cacheBytes = bytes;
			bytes = Bytes.alloc(length);
			bytes.blit(0, cacheBytes, 0, cacheBytes.length);
		}
	}

	// Event Handlers
	private function curl_onHeader(curl:CURL, header:String):Void
	{
		var parts = header.split(': ');

		if (parts.length == 2)
		{
			parent.responseHeaders.push(new HTTPRequestHeader(StringTools.trim(parts[0]), StringTools.trim(parts[1])));
		}
	}

	private function curl_onProgress(curl:CURL, dltotal:Float, dlnow:Float, uptotal:Float, upnow:Float):Void
	{
		if (upnow > writeBytesLoaded || dlnow > writeBytesLoaded || uptotal > writeBytesTotal || dltotal > writeBytesTotal)
		{
			if (upnow > writeBytesLoaded) writeBytesLoaded = Std.int(upnow);
			if (dlnow > writeBytesLoaded) writeBytesLoaded = Std.int(dlnow);
			if (uptotal > writeBytesTotal) writeBytesTotal = Std.int(uptotal);
			if (dltotal > writeBytesTotal) writeBytesTotal = Std.int(dltotal);

			// Wrong thread
			// promise.progress (bytesLoaded, bytesTotal);
		}
	}

	private function curl_onWrite(curl:CURL, output:Bytes):Int
	{
		growBuffer(writePosition + output.length);
		bytes.blit(writePosition, output, 0, output.length);

		writePosition += output.length;

		return output.length;
	}

	private static function localThreadPool_doWork(state:Dynamic):Void
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
			localThreadPool.sendError({instance: instance, promise: instance.promise, error: "Cannot load file: " + path});
		}
		else
		{
			instance.bytes = lime.utils.Bytes.fromFile(path);

			if (instance.bytes != null)
			{
				localThreadPool.sendProgress(
					{
						instance: instance,
						promise: instance.promise,
						bytesLoaded: instance.bytes.length,
						bytesTotal: instance.bytes.length
					});
				localThreadPool.sendComplete({instance: instance, promise: instance.promise, result: instance.bytes});
			}
			else
			{
				localThreadPool.sendError({instance: instance, promise: instance.promise, error: "Cannot load file: " + path});
			}
		}
	}

	private static function localThreadPool_onComplete(state:{instance:NativeHTTPRequest, promise:Promise<Bytes>, result:Bytes}):Void
	{
		var promise:Promise<Bytes> = state.promise;
		if (promise.isError) return;
		promise.complete(state.result);

		var instance = state.instance;

		if (instance.timeout != null)
		{
			instance.timeout.stop();
			instance.timeout = null;
		}

		instance.bytes = null;
		instance.promise = null;
	}

	private static function localThreadPool_onError(state:{instance:NativeHTTPRequest, promise:Promise<Bytes>, error:String}):Void
	{
		var promise:Promise<Bytes> = state.promise;
		promise.error(state.error);

		var instance = state.instance;

		if (instance.timeout != null)
		{
			instance.timeout.stop();
			instance.timeout = null;
		}

		instance.bytes = null;
		instance.promise = null;
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
		if (promise.isComplete || promise.isError) return;
		promise.progress(state.bytesLoaded, state.bytesTotal);
	}

	private static function multiThreadPool_doWork(_):Void
	{
		while (true)
		{
			#if (cpp || neko || hl)
			var curl = multiAddHandle.pop(false);
			if (curl != null) multi.addHandle(curl);
			#end

			var code = multi.wait(1000);

			if (code == CURLMultiCode.OK)
			{
				multi.perform();
				var message = multi.infoRead();

				if (message == null && multi.runningHandles == 0)
				{
					multiThreadPool.sendComplete();
					break;
				}

				while (message != null)
				{
					var curl = message.curl;
					var status = curl.getInfo(RESPONSE_CODE);

					multi.removeHandle(curl);
					curl.cleanup();

					multiThreadPool.sendProgress({curl: curl, result: message.result, status: status});
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
			multiThreadPool.queue();
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

	private static function multiThreadPool_onProgress(state:{curl:CURL, result:Int, status:Int}):Void
	{
		if (multiInstances.exists(state.curl))
		{
			var instance = multiInstances.get(state.curl);
			activeInstances.remove(instance);
			multiInstances.remove(state.curl);

			instance.parent.responseStatus = state.status;

			if (state.result == CURLCode.OK)
			{
				if ((state.status >= 200 && state.status < 400) || state.status == 0)
				{
					if (!instance.promise.isError)
					{
						instance.promise.complete(instance.bytes);
					}
				}
				else if (instance.bytes != null)
				{
					instance.promise.error(instance.bytes.getString(0, instance.bytes.length));
				}
				else
				{
					instance.promise.error('Status ${state.status}');
				}
			}
			else
			{
				instance.promise.error(CURL.strerror(state.result));
			}

			if (instance.timeout != null)
			{
				instance.timeout.stop();
				instance.timeout = null;
			}

			instance.bytes = null;
			instance.promise = null;
		}

		state.curl = null;
	}

	private static function multiProgressTimer_onRun():Void
	{
		for (instance in activeInstances)
		{
			if (instance.bytesLoaded != instance.writeBytesLoaded || instance.bytesTotal != instance.writeBytesTotal)
			{
				instance.bytesLoaded = instance.writeBytesLoaded;
				instance.bytesTotal = instance.writeBytesTotal;
				instance.promise.progress(instance.bytesLoaded, instance.bytesTotal);
			}
		}
	}
}
