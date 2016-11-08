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
import lime.system.BackgroundWorker;


class NativeHTTPRequest {
	
	
	private var bytes:Bytes;
	private var bytesLoaded:Int;
	private var bytesTotal:Int;
	private var curl:CURL;
	private var parent:IHTTPRequest;
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
	
	
	public function init (parent:IHTTPRequest):Void {
		
		this.parent = parent;
		
	}
	
	
	public function loadData (uri:String):Future<Bytes> {
		
		if (uri.indexOf ("http://") == -1 && uri.indexOf ("https://") == -1) {
			
			loadFile (uri);
			
		} else {
			
			loadURL (uri);
			
		}
		
		return promise.future;
		
	}
	
	
	private function loadFile (path:String):Void {
		
		var worker = new BackgroundWorker ();
		worker.doWork.add (function (_) {
			
			var index = path.indexOf ("?");
			
			if (index > -1) {
				
				path = path.substring (0, index);
				
			}
			
			bytes = lime.utils.Bytes.readFile (path);
			promise.complete (bytes);
			
		});
		worker.run ();
		
	}
	
	
	public function loadText (uri:String):Future<String> {
		
		var promise = new Promise<String> ();
		var future = loadData (uri);
		
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
	
	
	private function loadURL (url:String):Void {
		
		bytes = Bytes.alloc (0);
		
		bytesLoaded = 0;
		bytesTotal = 0;
		
		if (curl == 0) {
			
			curl = CURLEasy.init ();
			
		} else {
			
			CURLEasy.reset (curl);
			
		}
		
		CURLEasy.setopt (curl, URL, url);
		CURLEasy.setopt (curl, HTTPGET, parent.method == HTTPRequestMethod.GET);
		
		CURLEasy.setopt (curl, FOLLOWLOCATION, true);
		CURLEasy.setopt (curl, AUTOREFERER, true);
		
		var headers = [];
		headers.push ("Expect: ");
		
		for (header in cast (parent.headers, Array<Dynamic>)) {
			
			headers.push ('${header.name}: ${header.value}');
			
		}
		
		CURLEasy.setopt (curl, HTTPHEADER, headers);
		
		CURLEasy.setopt (curl, PROGRESSFUNCTION, curl_onProgress);
		CURLEasy.setopt (curl, WRITEFUNCTION, curl_onWrite);
		
		CURLEasy.setopt (curl, SSL_VERIFYPEER, false);
		CURLEasy.setopt (curl, SSL_VERIFYHOST, 0);
		CURLEasy.setopt (curl, USERAGENT, "libcurl-agent/1.0");
		
		//CURLEasy.setopt (curl, CONNECTTIMEOUT, 30);
		CURLEasy.setopt (curl, NOSIGNAL, true);
		
		CURLEasy.setopt (curl, TRANSFERTEXT, 0);
		
		var worker = new BackgroundWorker ();
		worker.doWork.add (function (_) {
			
			var result = CURLEasy.perform (curl);
			
			worker.sendComplete (result);
			
		});
		worker.onComplete.add (function (result) {
			
			var responseCode = CURLEasy.getinfo (curl, RESPONSE_CODE);
			
			if (result == CURLCode.OK) {
				
				promise.complete (bytes);
				
			} else {
				
				promise.error (result);
				
			}
			
		});
		worker.run ();
		
		if (parent.timeout > 0) {
			
			Timer.delay (function () {
				
				if (!worker.completed) {
					
					worker.cancel ();
					cancel ();
					
					promise.error (CURLCode.OPERATION_TIMEDOUT);
					
				}
				
			}, parent.timeout);
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function curl_onProgress (dltotal:Float, dlnow:Float, uptotal:Float, upnow:Float):Int {
		
		if (upnow > bytesLoaded || dlnow > bytesLoaded || uptotal > bytesTotal || dltotal > bytesTotal) {
			
			if (upnow > bytesLoaded) bytesLoaded = Std.int (upnow);
			if (dlnow > bytesLoaded) bytesLoaded = Std.int (dlnow);
			if (uptotal > bytesTotal) bytesTotal = Std.int (uptotal);
			if (dltotal > bytesTotal) bytesTotal = Std.int (dltotal);
			
			promise.progress (bytesLoaded / bytesTotal);
			
		}
		
		return 0;
		
	}
	
	
	private function curl_onWrite (output:Bytes, size:Int, nmemb:Int):Int {
		
		var cacheBytes = bytes;
		bytes = Bytes.alloc (bytes.length + output.length);
		bytes.blit (0, cacheBytes, 0, cacheBytes.length);
		bytes.blit (cacheBytes.length, output, 0, output.length);
		
		return size * nmemb;
		
	}
	
	
}