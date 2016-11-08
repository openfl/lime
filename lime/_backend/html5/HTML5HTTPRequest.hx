package lime._backend.html5;


import js.html.Event;
import js.html.ProgressEvent;
import js.html.XMLHttpRequest;
import haxe.io.Bytes;
import lime.app.Future;
import lime.app.Promise;
import lime.net.HTTPRequest;


class HTML5HTTPRequest {
	
	
	private var binary:Bool;
	private var parent:IHTTPRequest;
	private var request:XMLHttpRequest;
	
	
	public function new () {
		
		
		
	}
	
	
	public function cancel ():Void {
		
		if (request != null) {
			
			request.abort ();
			
		}
		
	}
	
	
	public function init (parent:IHTTPRequest):Void {
		
		this.parent = parent;
		
	}
	
	
	private function load (uri:String, progress:Dynamic, readyStateChange:Dynamic):Void {
		
		request = new XMLHttpRequest ();
		request.addEventListener ("progress", progress, false);
		request.onreadystatechange = readyStateChange;
		
		if (parent.timeout > 0) {
			
			request.timeout = parent.timeout;
			
		}
		
		var query = "";
		
		for (key in parent.formData.keys ()) {
			
			if (query.length > 0) query += "&";
			query += StringTools.urlEncode (key) + "=" + StringTools.urlEncode (Std.string (parent.formData.get (key)));
			
		}
		
		if (parent.method == GET) {
			
			if (uri.indexOf ("?") > -1) {
				
				uri += "&" + query;
				
			} else {
				
				uri += "?" + query;
				
			}
			
			query = "";
			
		}
		
		request.open (Std.string (parent.method), uri, true);
		
		if (binary) {
			
			request.responseType = ARRAYBUFFER;
			
		}
		
		for (header in parent.headers) {
			
			request.setRequestHeader (header.name, header.value);
			
		}
		
		request.send (query);
		
	}
	
	
	public function loadData (uri:String):Future<Bytes> {
		
		var promise = new Promise<Bytes> ();
		
		var progress = function (event) {
			
			promise.progress (event.loaded / event.total);
			
		}
		
		var readyStateChange = function (event) {
			
			if (request.readyState != 4) return;
			
			if (request.status != null && request.status >= 200 && request.status <= 400) {
				
				var bytes;
				
				if (request.responseType == NONE) {
					
					bytes = Bytes.ofString (request.responseText);
					
				}
				
				bytes = Bytes.ofData (request.response);
				
				promise.complete (bytes);
				
			} else {
				
				promise.error (request.status);
				
			}
			
			request = null;
			
		}
		
		binary = true;
		load (uri, progress, readyStateChange);
		
		return promise.future;
		
	}
	
	
	public function loadText (uri:String):Future<String> {
		
		var promise = new Promise<String> ();
		
		var progress = function (event) {
			
			promise.progress (event.loaded / event.total);
			
		}
		
		var readyStateChange = function (event) {
			
			if (request.readyState != 4) return;
			
			if (request.status != null && request.status >= 200 && request.status <= 400) {
				
				promise.complete (request.responseText);
				
			} else {
				
				promise.error (request.status);
				
			}
			
			request = null;
			
		}
		
		binary = false;
		load (uri, progress, readyStateChange);
		
		return promise.future;
		
	}
	
	
}