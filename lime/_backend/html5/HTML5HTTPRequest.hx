package lime._backend.html5;


import js.html.Event;
import js.html.Image in JSImage;
import js.html.ProgressEvent;
import js.html.XMLHttpRequest;
import haxe.io.Bytes;
import lime.app.Future;
import lime.app.Promise;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.net.HTTPRequest;
import lime.net.HTTPRequestHeader;
import lime.utils.AssetType;

@:access(lime.graphics.ImageBuffer)


class HTML5HTTPRequest {
	
	
	private static var activeRequests = 0;
	private static var requestLimit = 4;
	private static var requestQueue = new List<QueueItem> ();
	
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
		
		if (activeRequests < requestLimit) {
			
			activeRequests++;
			__loadData (uri, promise);
			
		} else {
			
			requestQueue.add ({ instance: this, uri: uri, promise: promise, type: AssetType.BINARY });
			
		}
		
		return promise.future;
		
	}
	
	
	private static function loadImage (uri:String):Future<Image> {
		
		var promise = new Promise<Image> ();
		
		if (activeRequests < requestLimit) {
			
			activeRequests++;
			__loadImage (uri, promise);
			
		} else {
			
			requestQueue.add ({ instance: null, uri: uri, promise: promise, type: AssetType.IMAGE });
			
		}
		
		return promise.future;
		
	}
	
	
	public function loadText (uri:String):Future<String> {
		
		var promise = new Promise<String> ();
		
		if (activeRequests < requestLimit) {
			
			activeRequests++;
			__loadText (uri, promise);
			
		} else {
			
			requestQueue.add ({ instance: this, uri: uri, promise: promise, type: AssetType.TEXT });
			
		}
		
		return promise.future;
		
	}
	
	
	private static function processQueue ():Void {
		
		if (activeRequests < requestLimit && requestQueue.length > 0) {
			
			activeRequests++;
			
			var queueItem = requestQueue.pop ();
			
			switch (queueItem.type) {
				
				case IMAGE:
					
					__loadImage (queueItem.uri, queueItem.promise);
				
				case TEXT:
					
					queueItem.instance.__loadText (queueItem.uri, queueItem.promise);
				
				case BINARY:
					
					queueItem.instance.__loadData (queueItem.uri, queueItem.promise);
				
				default:
					
					activeRequests--;
				
			}
			
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
	
	
	public function __loadData (uri:String, promise:Promise<Bytes>):Void {
		
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
		load (uri, progress, readyStateChange);
		
	}
	
	
	private static function __loadImage (uri:String, promise:Promise<Image>):Void {
		
		var image = new JSImage ();
		image.crossOrigin = "Anonymous";
		
		image.addEventListener ("load", function (event) {
			
			var buffer = new ImageBuffer (null, image.width, image.height);
			buffer.__srcImage = cast image;
			
			activeRequests--;
			processQueue ();
			
			promise.complete (new Image (buffer));
			
		}, false);
		
		image.addEventListener ("progress", function (event) {
			
			promise.progress (event.loaded, event.total);
			
		}, false);
		
		image.addEventListener ("error", function (event) {
			
			activeRequests--;
			processQueue ();
			
			promise.error (event.detail);
			
		}, false);
		
		image.src = uri;
		
	}
	
	
	private function __loadText (uri:String, promise:Promise<String>):Void {
		
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
		load (uri, progress, readyStateChange);
		
	}
	
	
}


@:dox(hide) typedef QueueItem = {
	
	var instance:HTML5HTTPRequest;
	var type:AssetType;
	var promise:Dynamic;
	var uri:String;
	
}