package lime._backend.native;


import haxe.io.Bytes;
import haxe.Timer;
import lime.app.Future;
import lime.app.Promise;
import lime.net.curl.CURLCode;
import lime.net.curl.CURL;
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
	
	
	private static var threadPool:ThreadPool;
	
	private var bytes:Bytes;
	private var bytesLoaded:Int;
	private var bytesTotal:Int;
	private var canceled:Bool;
	private var curl:CURL;
	private var parent:_IHTTPRequest;
	private var promise:Promise<Bytes>;
	private var readPosition:Int;
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
	
	
	private function doWork_loadFile (path:String):Void {
		
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
			
			threadPool.sendError ({ instance: this, promise: promise, error: "Cannot load file: " + path });
			
		} else {
			
			bytes = lime.utils.Bytes.fromFile (path);
			
			if (bytes != null) {
				
				threadPool.sendComplete ({ instance: this, promise: promise, result: bytes });
				
			} else {
				
				threadPool.sendError ({ instance: this, promise: promise, error: "Cannot load file: " + path });
				
			}
			
		}
		
	}
	
	
	private function doWork_loadURL (uri:String, binary:Bool):Void {
		
		if (uri == null) {
			
			threadPool.sendError ({ instance: this, promise: promise, error: "The URI must not be null" });
			return;
			
		}
		
		bytes = Bytes.alloc (0);
		
		bytesLoaded = 0;
		bytesTotal = 0;
		readPosition = 0;
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
				
			} else {
				
				data = Bytes.alloc (0);
				
			}
			
		}
		
		curl.setOption (URL, uri);
		
		switch (parent.method) {
			
			case HEAD:
				
				curl.setOption (NOBODY, true);
			
			case GET:
				
				curl.setOption (HTTPGET, true);
			
			case POST:
				
				curl.setOption (POST, true);
				curl.setOption (READFUNCTION, curl_onRead.bind (_, data));
				curl.setOption (POSTFIELDSIZE, data.length);
				curl.setOption (INFILESIZE, data.length);
			
			case PUT:
				
				curl.setOption (UPLOAD, true);
				curl.setOption (READFUNCTION, curl_onRead.bind (_, data));
				curl.setOption (INFILESIZE, data.length);
			
			case _:
				
				curl.setOption (CUSTOMREQUEST, Std.string (parent.method));
				curl.setOption (READFUNCTION, curl_onRead.bind (_, data));
				curl.setOption (INFILESIZE, data.length);
			
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
			
		}
		
		curl.setOption (HEADERFUNCTION, curl_onHeader);
		
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
		
		var result = curl.perform ();
		parent.responseStatus = curl.getInfo (RESPONSE_CODE);
		
		curl.cleanup ();
		curl = null;
		
		if (result == CURLCode.OK) {
			
			if ((parent.responseStatus >= 200 && parent.responseStatus < 400) || parent.responseStatus == 0) {
				
				threadPool.sendComplete ({ instance: this, promise: promise, result: bytes });
				
			} else if (bytes != null) {
				
				threadPool.sendError ({ instance: this, promise: promise, error: bytes.getString (0, bytes.length) });
				
			} else {
				
				threadPool.sendError ({ instance: this, promise: promise, error: 'Status ${parent.responseStatus}' });
				
			}
			
		} else {
			
			threadPool.sendError ({ instance: this, promise: promise, error: CURL.strerror (result) });
			
		}
		
	}
	
	
	public function init (parent:_IHTTPRequest):Void {
		
		this.parent = parent;
		
	}
	
	
	public function loadData (uri:String, binary:Bool = true):Future<Bytes> {
		
		var promise = new Promise<Bytes> ();
		this.promise = promise;
		
		if (threadPool == null) {
			
			CURL.globalInit (CURL.GLOBAL_ALL);
			
			threadPool = new ThreadPool (1, 4);
			threadPool.doWork.add (threadPool_doWork);
			threadPool.onRun.add (threadPool_onRun);
			threadPool.onProgress.add (threadPool_onProgress);
			threadPool.onComplete.add (threadPool_onComplete);
			threadPool.onError.add (threadPool_onError);
			
		}
		
		canceled = false;
		threadPool.queue ({ instance: this, uri: uri, binary: binary, timeout: parent.timeout });
		
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
	
	
	
	
	private function curl_onHeader (output:Bytes, size:Int, nmemb:Int):Int {
		
		var parts = Std.string (output).split (': ');
		
		if (parts.length == 2) {
			
			if (parent.enableResponseHeaders) {
				
				parent.responseHeaders.push (new HTTPRequestHeader (parts[0], parts[1]));
				
			}
			
			switch (parts[0]) {
				
				case 'Content-Length': 
					
					growBuffer (Std.parseInt (parts[1]));
				
			}
			
		}
		
		return size * nmemb;
		
	}
	
	
	private function curl_onProgress (dltotal:Float, dlnow:Float, uptotal:Float, upnow:Float):Int {
		
		if (upnow > bytesLoaded || dlnow > bytesLoaded || uptotal > bytesTotal || dltotal > bytesTotal) {
			
			if (upnow > bytesLoaded) bytesLoaded = Std.int (upnow);
			if (dlnow > bytesLoaded) bytesLoaded = Std.int (dlnow);
			if (uptotal > bytesTotal) bytesTotal = Std.int (uptotal);
			if (dltotal > bytesTotal) bytesTotal = Std.int (dltotal);
			
			threadPool.sendProgress ({ instance: this, promise: promise, bytesLoaded: bytesLoaded, bytesTotal: bytesTotal });
			
		}
		
		return 0;
		
	}
	
	
	private function curl_onRead (max:Int, input:Bytes):Bytes {
		
		if (readPosition == 0 && max >= input.length) {
			
			return input;
			
		} else if (readPosition >= input.length) {
			
			return Bytes.alloc (0);
			
		} else {
			
			var length = max;
			
			if (readPosition + length > input.length) {
				
				length = input.length - readPosition;
				
			}
			
			var data = input.sub (readPosition, length);
			readPosition += length;
			return data;
			
		}
		
	}
	
	
	private function curl_onWrite (output:Bytes, size:Int, nmemb:Int):Int {
		
		growBuffer (writePosition + output.length);
		bytes.blit (writePosition, output, 0, output.length);

		writePosition += output.length;

		return size * nmemb;
		
	}
	
	
	private static function threadPool_doWork (state:Dynamic):Void {
		
		var instance:NativeHTTPRequest = state.instance;
		var uri:String = state.uri;
		var binary:Bool = state.binary;
		
		if (uri.indexOf ("http://") == -1 && uri.indexOf ("https://") == -1) {
			
			instance.doWork_loadFile (uri);
			
		} else {
			
			instance.doWork_loadURL (uri, binary);
			
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
	
	
	private static function threadPool_onRun (state:Dynamic):Void {
		
		if (state.timeout > 0) {
			
			state.instance.timeout = Timer.delay (function () {
				
				if (state.promise != null && state.instance.bytesLoaded == 0 && state.instance.bytesTotal == 0 && !state.promise.isComplete && !state.promise.isError) {
					
					//cancel ();
					
					state.promise.error (CURL.strerror (CURLCode.OPERATION_TIMEDOUT));
					
				}
				
			}, state.timeout);
			
		}
		
	}
	
	
}
