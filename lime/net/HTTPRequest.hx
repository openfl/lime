package lime.net;


import lime.app.Future;
import lime.app.Promise;
import lime.net.curl.CURLCode;
import lime.net.curl.CURLEasy;
import lime.system.BackgroundWorker;
import lime.system.CFFI;
import lime.utils.Bytes;

#if (js && html5)
import js.html.XMLHttpRequest;
#end


class HTTPRequest {
	
	
	public var bytes:Bytes;
	
	private var bytesLoaded:Int;
	private var bytesTotal:Int;
	private var promise:Promise<Bytes>;
	
	
	public function new () {
		
		promise = new Promise<Bytes> ();
		
	}
	
	
	public function load (url:String):Future<Bytes> {
		
		bytesLoaded = 0;
		bytesTotal = 0;
		
		#if flash
		
		
		
		#elseif (js && html5)
		
		var request = new XMLHttpRequest ();
		request.addEventListener ("progress", request_onProgress, false);
		request.onreadystatechange = function () {
			
			if (request.readyState != 4) return;
			
			if (request.status != null && request.status >= 200 && request.status <= 400) {
				
				bytes = Bytes.ofData (request.response);
				promise.complete (bytes);
				
			} else {
				
				promise.error (request.status);
				
			}
			
		};
		
		request.open ("GET", url, true);
		request.responseType = ARRAYBUFFER;
		request.send ("");
		
		#else
		
		if (url.indexOf ("http://") == -1 && url.indexOf ("https://") == -1) {
			
			var worker = new BackgroundWorker ();
			worker.doWork.add (function (_) {
				
				var path = url;
				var index = path.indexOf ("?");
				
				if (index > -1) {
					
					path = path.substring (0, index);
					
				}
				
				var bytes = Bytes.readFile (path);
				promise.complete (bytes);
				
			});
			worker.run ();
			
		} else {
			
			bytes = Bytes.alloc (0);
			
			bytesLoaded = 0;
			bytesTotal = 0;
			
			var curl = CURLEasy.init ();
			
			CURLEasy.setopt (curl, URL, url);
			CURLEasy.setopt (curl, HTTPGET, true);
			
			CURLEasy.setopt (curl, FOLLOWLOCATION, true);
			CURLEasy.setopt (curl, AUTOREFERER, true);
			CURLEasy.setopt (curl, HTTPHEADER, [ "Expect: " ]);
			
			CURLEasy.setopt (curl, PROGRESSFUNCTION, curl_onProgress);
			CURLEasy.setopt (curl, WRITEFUNCTION, curl_onWrite);
			
			CURLEasy.setopt (curl, SSL_VERIFYPEER, false);
			CURLEasy.setopt (curl, SSL_VERIFYHOST, 0);
			CURLEasy.setopt (curl, USERAGENT, "libcurl-agent/1.0");
			CURLEasy.setopt (curl, CONNECTTIMEOUT, 30);
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
			
		}
		
		#end
		
		return promise.future;
		
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
	
	
	private function request_onProgress (event:Dynamic):Void {
		
		promise.progress (event.loaded / event.total);
		
	}
	
	
}