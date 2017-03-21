package lime._backend.native;


import haxe.io.Bytes;
import haxe.Timer;
import lime.app.Future;
import lime.app.Promise;
import lime.net.curl.CURLCode;
import lime.net.curl.CURLEasy;
import lime.net.curl.CURL;
import lime.net.HTTPRequest;
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
	private var curl:CURL;
	private var parent:_IHTTPRequest;
	private var promise:Promise<Bytes>;
	
	
	public function new () {
		
		curl = 0;
		promise = new Promise<Bytes> ();
		
	}
	
	
	public function cancel ():Void {
		
		if (curl != 0) {
			
			CURLEasy.reset (curl);
			CURLEasy.perform (curl);
			
		}
		
	}
	
	
	public function init (parent:_IHTTPRequest):Void {
		
		this.parent = parent;
		
	}
	
	
	public function loadData (uri:String, binary:Bool = true):Future<Bytes> {
		
		if (threadPool == null) {
			
			CURL.globalInit (CURL.GLOBAL_ALL);
			
			threadPool = new ThreadPool (1, 5);
			threadPool.doWork.add (threadPool_doWork);
			threadPool.onComplete.add (threadPool_onComplete);
			threadPool.onError.add (threadPool_onError);
			
		}
		
		if (parent.timeout > 0) {
			
			Timer.delay (function () {
				
				if (bytesLoaded == 0 && bytesTotal == 0 && !promise.isComplete && !promise.isError) {
					
					//cancel ();
					
					promise.error (CURLCode.OPERATION_TIMEDOUT);
					
				}
				
			}, parent.timeout);
			
		}
		
		threadPool.queue ({ instance: this, uri: uri, binary: binary });
		
		return promise.future;
		
	}
	
	
	private function loadFile (path:String):Void {
		
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
			
			threadPool.sendError ({ promise: promise, error: "Cannot load file: " + path });
			
		} else {
			
			bytes = lime.utils.Bytes.fromFile (path);
			
			if (bytes != null) {
				
				threadPool.sendComplete ({ promise: promise, result: bytes });
				
			} else {
				
				threadPool.sendError ({ promise: promise, error: "Cannot load file: " + path });
				
			}
			
		}
		
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
	
	
	private function loadURL (uri:String, binary:Bool):Void {
		
		bytes = Bytes.alloc (0);
		
		bytesLoaded = 0;
		bytesTotal = 0;
		
		if (curl == 0) {
			
			curl = CURLEasy.init ();
			
		} else {
			
			CURLEasy.reset (curl);
			
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
		}
		
		CURLEasy.setopt (curl, URL, uri);
		
		switch (parent.method) {
			
			case HEAD:
				
				CURLEasy.setopt (curl, NOBODY, true);
			
			case GET:
				
				CURLEasy.setopt (curl, HTTPGET, true);
			
			case POST:
				
				CURLEasy.setopt (curl, POST, true);
				CURLEasy.setopt (curl, READFUNCTION, curl_onRead.bind (_, data));
				CURLEasy.setopt (curl, POSTFIELDSIZE, data.length);
				CURLEasy.setopt (curl, INFILESIZE, data.length);
			
			case PUT:
				
				CURLEasy.setopt (curl, UPLOAD, true);
				CURLEasy.setopt (curl, READFUNCTION, curl_onRead.bind (_, data));
				CURLEasy.setopt (curl, INFILESIZE, data.length);
			
			case _:
				
				CURLEasy.setopt (curl, CUSTOMREQUEST, Std.string (parent.method));
				CURLEasy.setopt (curl, READFUNCTION, curl_onRead.bind (_, data));
				CURLEasy.setopt (curl, INFILESIZE, data.length);
			
		}
		
		CURLEasy.setopt (curl, FOLLOWLOCATION, parent.followRedirects);
		CURLEasy.setopt (curl, AUTOREFERER, true);
		
		var headers = [];
		headers.push ("Expect: ");
		
		var hasContentType = false;
		
		for (header in cast (parent.headers, Array<Dynamic>)) {
			
			if (header.name == "Content-Type") hasContentType = true;
			headers.push ('${header.name}: ${header.value}');
			
		}
		
		if (!hasContentType) {
			
			headers.push ("Content-Type: " + parent.contentType);
			
		}
		
		CURLEasy.setopt (curl, HTTPHEADER, headers);
		
		CURLEasy.setopt (curl, PROGRESSFUNCTION, curl_onProgress);
		CURLEasy.setopt (curl, WRITEFUNCTION, curl_onWrite);
		
		if (parent.enableResponseHeaders) {
			
			CURLEasy.setopt (curl, HEADERFUNCTION, curl_onHeader);
			
		}
		
		CURLEasy.setopt (curl, SSL_VERIFYPEER, false);
		CURLEasy.setopt (curl, SSL_VERIFYHOST, 0);
		CURLEasy.setopt (curl, USERAGENT, parent.userAgent == null ? "libcurl-agent/1.0" : parent.userAgent);
		
		//CURLEasy.setopt (curl, CONNECTTIMEOUT, 30);
		CURLEasy.setopt (curl, NOSIGNAL, true);
		
		CURLEasy.setopt (curl, TRANSFERTEXT, !binary);
		
		var result = CURLEasy.perform (curl);
		parent.responseStatus = CURLEasy.getinfo (curl, RESPONSE_CODE);
		
		if (result == CURLCode.OK) {
			
			threadPool.sendComplete ({ promise: promise, result: bytes });
			
		} else {
			
			threadPool.sendError ({ promise: promise, error: result });
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function curl_onHeader (output:Bytes, size:Int, nmemb:Int):Int {
		
		parent.responseHeaders = [];
		
		// TODO
		
		return size * nmemb;
		
	}
	
	
	private function curl_onProgress (dltotal:Float, dlnow:Float, uptotal:Float, upnow:Float):Int {
		
		if (upnow > bytesLoaded || dlnow > bytesLoaded || uptotal > bytesTotal || dltotal > bytesTotal) {
			
			if (upnow > bytesLoaded) bytesLoaded = Std.int (upnow);
			if (dlnow > bytesLoaded) bytesLoaded = Std.int (dlnow);
			if (uptotal > bytesTotal) bytesTotal = Std.int (uptotal);
			if (dltotal > bytesTotal) bytesTotal = Std.int (dltotal);
			
			promise.progress (bytesLoaded, bytesTotal);
			
		}
		
		return 0;
		
	}
	
	
	private function curl_onRead (max:Int, input:Bytes):Bytes {
		
		return input;
		
	}
	
	
	private function curl_onWrite (output:Bytes, size:Int, nmemb:Int):Int {
		
		var cacheBytes = bytes;
		bytes = Bytes.alloc (bytes.length + output.length);
		bytes.blit (0, cacheBytes, 0, cacheBytes.length);
		bytes.blit (cacheBytes.length, output, 0, output.length);
		
		return size * nmemb;
		
	}
	
	
	private static function threadPool_doWork (state:Dynamic):Void {
		
		var instance:NativeHTTPRequest = state.instance;
		var uri:String = state.uri;
		var binary:Bool = state.binary;
		
		if (uri.indexOf ("http://") == -1 && uri.indexOf ("https://") == -1) {
			
			instance.loadFile (uri);
			
		} else {
			
			instance.loadURL (uri, binary);
			
		}
		
	}
	
	
	private static function threadPool_onComplete (state:Dynamic):Void {
		
		state.promise.complete (state.result);
		
	}
	
	
	private static function threadPool_onError (state:Dynamic):Void {
		
		state.promise.error (state.error);
		
	}
	
	
}