package lime._backend.html5;


import js.html.Event;
import js.html.ProgressEvent;
import js.html.XMLHttpRequest;
import haxe.io.Bytes;
import lime.app.Future;
import lime.app.Promise;
import lime.net.HTTPRequest;
import lime.net.HTTPRequestHeader;


class HTML5HTTPRequest {
	
	
	private static var activeRequests:Int;
	private static var requestLimit:Int;
	private static var requestQueue:List<QueueItem>;
	
	private var binary:Bool;
	private var parent:_IHTTPRequest;
	private var request:XMLHttpRequest;
	
	
	public function new () {
		
		
		
	}
	
	
	public function cancel ():Void {
		
		if (request != null) {
			
			request.abort ();
			
		}
		
	}
	
	
	public function init (parent:_IHTTPRequest):Void {
		
		this.parent = parent;
		
		if (requestQueue == null) {
			
			activeRequests = 0;
			requestLimit = 6;
			requestQueue = new List<QueueItem> ();
			
		}
		
	}
	
	
	private function load (uri:String, progress:Dynamic, readyStateChange:Dynamic):Void {
		
		request = new XMLHttpRequest ();
		request.addEventListener ("progress", progress, false);
		request.onreadystatechange = readyStateChange;
		
		var query = "";
		
		if (parent.data == null) {
			
			for (key in parent.formData.keys ()) {
				
				if (query.length > 0) query += "&";
				query += StringTools.urlEncode (key) + "=" + StringTools.urlEncode (Std.string (parent.formData.get (key)));
				
			}
			
			if (parent.method == GET && query != "") {
				
				if (uri.indexOf ("?") > -1) {
					
					uri += "&" + query;
					
				} else {
					
					uri += "?" + query;
					
				}
				
				query = "";
				
			}
			
		}
		
		request.open (Std.string (parent.method), uri, true);
		if (parent.timeout > 0) {
			request.timeout = parent.timeout;
		}
		
		if (binary) {
			
			request.responseType = ARRAYBUFFER;
			
		}
		
		var hasContentType = false;
		
		for (header in parent.headers) {
			
			if (header.name == "Content-Type") hasContentType = true;
			request.setRequestHeader (header.name, header.value);
			
		}
		
		if (!hasContentType) {
			
			request.setRequestHeader ("Content-Type", parent.contentType);
			
		}
		
		if (parent.data != null) {
			
			request.send (parent.data.getData ());
			
		} else {
			
			request.send (query);
			
		}
		
	}
	
	
	public function loadData (uri:String):Future<Bytes> {
		
		var promise = new Promise<Bytes> ();
		
		var progress = function (event) {
			
			promise.progress (event.loaded, event.total);
			
		}
		
		var readyStateChange = function (event) {
			
			if (request.readyState != 4) return;
			
			if (request.status != null && request.status >= 200 && request.status <= 400) {
				
				var bytes;
				
				if (request.responseType == NONE) {
					
					bytes = Bytes.ofString (request.responseText);
					
				} else {
					
					bytes = Bytes.ofData (request.response);
					
				}
				
				processResponse ();
				promise.complete (bytes);
				
			} else {
				
				processResponse ();
				promise.error (request.status);
				
			}
			
			request = null;
			
			activeRequests--;
			processQueue ();
			
		}
		
		binary = true;
		
		if (activeRequests < requestLimit) {
			
			activeRequests++;
			load (uri, progress, readyStateChange);
			
		} else {
			
			requestQueue.add ({ instance: this, uri: uri, progress: progress, readyStateChange: readyStateChange });
			
		}
		
		return promise.future;
		
	}
	
	
	public function loadText (uri:String):Future<String> {
		
		var promise = new Promise<String> ();
		
		var progress = function (event) {
			
			promise.progress (event.loaded, event.total);
			
		}
		
		var readyStateChange = function (event) {
			
			if (request.readyState != 4) return;
			
			if (request.status != null && request.status >= 200 && request.status <= 400) {
				
				processResponse ();
				promise.complete (request.responseText);
				
			} else {
				
				processResponse ();
				promise.error (request.status);
				
			}
			
			request = null;
			
			activeRequests--;
			processQueue ();
			
		}
		
		binary = false;
		
		if (activeRequests < requestLimit) {
			
			activeRequests++;
			load (uri, progress, readyStateChange);
			
		} else {
			
			requestQueue.add ({ instance: this, uri: uri, progress: progress, readyStateChange: readyStateChange });
			
		}
		
		return promise.future;
		
	}
	
	
	private function processQueue ():Void {
		
		if (activeRequests < requestLimit && requestQueue.length > 0) {
			
			activeRequests++;
			
			var queueItem = requestQueue.pop ();
			queueItem.instance.load (queueItem.uri, queueItem.progress, queueItem.readyStateChange);
			
		}
		
	}
	
	
	private function processResponse ():Void {
		
		if (parent.enableResponseHeaders) {
			
			parent.responseHeaders = [];
			var name, value;
			
			for (line in request.getAllResponseHeaders ().split ("\n")) {
				
				name = StringTools.trim (line.substr (0, line.indexOf (":")));
				value = StringTools.trim (line.substr (line.indexOf (":") + 1));
				
				if (name != "") {
					
					parent.responseHeaders.push (new HTTPRequestHeader (name, value));
					
				}
				
			}
			
		}
		
		parent.responseStatus = request.status;
		
	}
	
	
}


@:dox(hide) private typedef QueueItem = {
	
	var instance:HTML5HTTPRequest;
	var uri:String;
	var progress:Dynamic;
	var readyStateChange:Dynamic;
	
}