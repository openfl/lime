package lime._internal.backend.native;


import haxe.io.Bytes;
import haxe.Timer;
import lime.app.Future;
import lime.app.Promise;
import lime.net.curl.CURL;
import lime.net.curl.CURLCode;
import lime.net.curl.CURLMulti;
import lime.net.HTTPRequest;
import lime.net.HTTPRequestHeader;
import lime.net.HTTPRequestMethod;
import lime.system.ThreadPool;

#if sys
import sys.FileSystem;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class NativeHTTPRequest {


	private static var multi:CURLMulti;
	private static var multiInstances:Map<CURL, NativeHTTPRequest>;
	private static var multiTimer:Timer;
	private static var threadPool:ThreadPool;

	private var bytes:Bytes;
	private var bytesLoaded:Int;
	private var bytesTotal:Int;
	private var canceled:Bool;
	private var curl:CURL;
	private var parent:_IHTTPRequest;
	private var promise:Promise<Bytes>;
	private var writePosition:Int;
	private var timeout:Timer;


	public function new () {

		curl = null;
		timeout = null;

	}


	public function cancel ():Void {

		canceled = true;

		if (curl != null) {

			// This is probably run from a different thread if cURL is running
			// TODO

			//CURLEasy.cleanup (curl);
			//CURLEasy.reset (curl);
			//CURLEasy.perform (curl);

		}

		if (timeout != null) {

			timeout.stop ();
			timeout = null;

		}

	}


	public function init (parent:_IHTTPRequest):Void {

		this.parent = parent;

	}


	private function initRequest (uri:String, binary:Bool):Void {

		bytes = Bytes.alloc (0);

		bytesLoaded = 0;
		bytesTotal = 0;
		writePosition = 0;

		if (curl == null) {

			curl = new CURL ();

		} else {

			curl.reset ();

		}

		var data = parent.data;
		var query = "";

		if (data == null) {

			for (key in parent.formData.keys ()) {

				if (query.length > 0) query += "&";
				query += StringTools.urlEncode (key) + "=" + StringTools.urlEncode (Std.string (parent.formData.get (key)));

			}

			if (query != "") {

				if (parent.method == GET) {

					if (uri.indexOf ("?") > -1) {

						uri += "&" + query;

					} else {

						uri += "?" + query;

					}

					query = "";

				} else {

					data = Bytes.ofString (query);

				}

			}

			if (data != null && data.length == 0) data = null;

		}

		curl.setOption (URL, uri);

		switch (parent.method) {

			case HEAD:

				curl.setOption (NOBODY, true);

			case GET:

				curl.setOption (HTTPGET, true);

			case POST:

				curl.setOption (POST, true);

				if (data != null) {

					curl.setOption (INFILE, data);
					curl.setOption (INFILESIZE, data.length);
					curl.setOption (POSTFIELDSIZE, data.length);

				} else {

					curl.setOption (POSTFIELDSIZE, 0);

				}

			case PUT:

				curl.setOption (UPLOAD, true);

				if (data != null) {

					curl.setOption (INFILE, data);
					curl.setOption (INFILESIZE, data.length);

				}

			case _:

				curl.setOption (CUSTOMREQUEST, Std.string (parent.method));

				if (data != null) {

					curl.setOption (INFILE, data);
					curl.setOption (INFILESIZE, data.length);

				}

		}

		curl.setOption (FOLLOWLOCATION, parent.followRedirects);
		curl.setOption (AUTOREFERER, true);

		var headers = [];
		headers.push ("Expect: ");

		var contentType = null;

		for (header in cast (parent.headers, Array<Dynamic>)) {

			if (header.name == "Content-Type") {

				contentType = header.value;

			} else {

				headers.push ('${header.name}: ${header.value}');

			}

		}

		if (parent.contentType != null) {

			contentType = parent.contentType;

		}

		if (contentType == null) {

			if (parent.data != null) {

				contentType = "application/octet-stream";

			} else if (query != "") {

				contentType = "application/x-www-form-urlencoded";

			}

		}

		if (contentType != null) {

			headers.push ("Content-Type: " + contentType);

		}

		curl.setOption (HTTPHEADER, headers);

		curl.setOption (PROGRESSFUNCTION, curl_onProgress);
		curl.setOption (WRITEFUNCTION, curl_onWrite);

		if (parent.enableResponseHeaders) {

			parent.responseHeaders = [];
			curl.setOption (HEADERFUNCTION, curl_onHeader);

		}

		// TODO: Add support for cookies: https://curl.haxx.se/docs/http-cookies.html

		if (parent.withCredentials) {

			// TODO: Send cookies with request

		}

		curl.setOption (SSL_VERIFYPEER, false);
		curl.setOption (SSL_VERIFYHOST, 0);
		curl.setOption (USERAGENT, parent.userAgent == null ? "libcurl-agent/1.0" : parent.userAgent);

		//curl.setOption (CONNECTTIMEOUT, 30);
		curl.setOption (NOSIGNAL, true);

		curl.setOption (TRANSFERTEXT, !binary);

		#if curl_verbose
		curl.setOption (VERBOSE, true);
		#end

	}


	public function loadData (uri:String, binary:Bool = true):Future<Bytes> {

		if (uri == null) {

			return cast Future.withError ("The URI must not be null");

		}

		var promise = new Promise<Bytes> ();
		this.promise = promise;

		canceled = false;

		if (uri.indexOf ("http://") == -1 && uri.indexOf ("https://") == -1) {

			if (threadPool == null) {

				threadPool = new ThreadPool (0, 1);
				threadPool.doWork.add (threadPool_doWork);
				threadPool.onProgress.add (threadPool_onProgress);
				threadPool.onComplete.add (threadPool_onComplete);
				threadPool.onError.add (threadPool_onError);

			}

			threadPool.queue ({ instance: this, uri: uri });

		} else {

			if (multi == null) {

				CURL.globalInit (CURL.GLOBAL_ALL);

				multi = new CURLMulti ();
				multiInstances = new Map ();

			}

			initRequest (uri, binary);

			if (curl != null) {

				multiInstances.set (curl, this);
				multi.addHandle (curl);

				if (multiTimer == null) {

					// TODO: Reduce sleep when network is busy?

					multiTimer = new Timer (8);
					multiTimer.run = multiTimer_onRun;
					multiTimer_onRun ();

				}

			}

		}

		return promise.future;

	}


	public function loadText (uri:String):Future<String> {

		var promise = new Promise<String> ();
		var future = loadData (uri, false);

		future.onProgress (promise.progress);
		future.onError (promise.error);

		future.onComplete (function (bytes) {

			if (bytes == null) {

				promise.complete (null);

			} else {

				promise.complete (bytes.getString (0, bytes.length));

			}

		});

		return promise.future;

	}


	private function growBuffer (length:Int) {

		if (length > bytes.length) {

			var cacheBytes = bytes;
			bytes = Bytes.alloc (length);
			bytes.blit (0, cacheBytes, 0, cacheBytes.length);

		}

	}




	// Event Handlers




	private function curl_onHeader (curl:CURL, header:String):Void {

		var parts = header.split (': ');

		if (parts.length == 2) {

			parent.responseHeaders.push (new HTTPRequestHeader (StringTools.trim (parts[0]), StringTools.trim (parts[1])));

		}

	}


	private function curl_onProgress (curl:CURL, dltotal:Int, dlnow:Int, uptotal:Int, upnow:Int):Int {

		if (upnow > bytesLoaded || dlnow > bytesLoaded || uptotal > bytesTotal || dltotal > bytesTotal) {

			if (upnow > bytesLoaded) bytesLoaded = upnow;
			if (dlnow > bytesLoaded) bytesLoaded = dlnow;
			if (uptotal > bytesTotal) bytesTotal = uptotal;
			if (dltotal > bytesTotal) bytesTotal = dltotal;

			promise.progress (bytesLoaded, bytesTotal);

		}

		return 0;

	}


	private function curl_onWrite (curl:CURL, output:Bytes):Int {

		growBuffer (writePosition + output.length);
		bytes.blit (writePosition, output, 0, output.length);

		writePosition += output.length;

		return output.length;

	}


	private static function multiTimer_onRun ():Void {

		multi.perform ();

		var message = multi.infoRead ();
		var curl, instance, status;

		if (message == null && multi.runningHandles == 0) {

			multiTimer.stop ();
			multiTimer = null;

		}

		while (message != null) {

			curl = message.curl;

			if (multiInstances.exists (curl)) {

				instance = multiInstances.get (curl);
				multiInstances.remove (curl);

				status = curl.getInfo (RESPONSE_CODE);
				instance.parent.responseStatus = status;

				curl.cleanup ();
				curl = null;

				if (message.result == CURLCode.OK) {

					if ((status >= 200 && status < 400) || status == 0) {

						if (!instance.promise.isError) {

							instance.promise.complete (instance.bytes);

						}

					} else if (instance.bytes != null) {

						instance.promise.error (instance.bytes.getString (0, instance.bytes.length));

					} else {

						instance.promise.error ('Status ${status}');

					}

				} else {

					instance.promise.error (CURL.strerror (message.result));

				}

				if (instance.timeout != null) {

					instance.timeout.stop ();
					instance.timeout = null;

				}

				instance.bytes = null;
				instance.promise = null;

			}

			message = multi.infoRead ();

		}

	}


	private static function threadPool_doWork (state:Dynamic):Void {

		var instance:NativeHTTPRequest = state.instance;
		var path:String = state.uri;

		var index = path.indexOf ("?");

		if (index > -1) {

			path = path.substring (0, index);

		}

		#if (sys && !windows)
		if (StringTools.startsWith (path, "~/")) {

			path = Sys.getEnv ("HOME") + "/" + path.substr (2);

		}
		#end

		if (path == null #if (sys && !android) || !FileSystem.exists (path) #end) {

			threadPool.sendError ({ instance: instance, promise: instance.promise, error: "Cannot load file: " + path });

		} else {

			instance.bytes = lime.utils.Bytes.fromFile (path);

			if (instance.bytes != null) {

				threadPool.sendProgress ({ instance: instance, promise: instance.promise, bytesLoaded: instance.bytes.length, bytesTotal: instance.bytes.length });
				threadPool.sendComplete ({ instance: instance, promise: instance.promise, result: instance.bytes });

			} else {

				threadPool.sendError ({ instance: instance, promise: instance.promise, error: "Cannot load file: " + path });

			}

		}

	}


	private static function threadPool_onComplete (state:Dynamic):Void {

		var promise:Promise<Bytes> = state.promise;
		if (promise.isError) return;
		promise.complete (state.result);

		var instance = state.instance;

		if (instance.timeout != null) {

			instance.timeout.stop ();
			instance.timeout = null;

		}

		instance.bytes = null;
		instance.promise = null;

	}


	private static function threadPool_onError (state:Dynamic):Void {

		var promise:Promise<Bytes> = state.promise;
		promise.error (state.error);

		var instance = state.instance;

		if (instance.timeout != null) {

			instance.timeout.stop ();
			instance.timeout = null;

		}

		instance.bytes = null;
		instance.promise = null;

	}


	private static function threadPool_onProgress (state:Dynamic):Void {

		var promise:Promise<Bytes> = state.promise;
		if (promise.isComplete || promise.isError) return;
		promise.progress (state.bytesLoaded, state.bytesTotal);

	}


}
