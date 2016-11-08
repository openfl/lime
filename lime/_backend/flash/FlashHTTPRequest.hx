package lime._backend.flash;


import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.utils.ByteArray;
import haxe.io.Bytes;
import lime.app.Future;
import lime.app.Promise;
import lime.net.HTTPRequest;


class FlashHTTPRequest {
	
	
	private var binary:Bool;
	private var parent:IHTTPRequest;
	private var urlLoader:URLLoader;
	private var urlRequest:URLRequest;
	
	
	public function new () {
		
		
		
	}
	
	
	public function cancel ():Void {
		
		if (urlLoader != null) {
			
			urlLoader.close ();
			
		}
		
	}
	
	
	public function init (parent:IHTTPRequest):Void {
		
		this.parent = parent;
		
	}
	
	
	private function createURLLoader ():Void {
		
		urlLoader = new URLLoader ();
		
		var query = "";
		var uri = parent.uri;
		
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
		
		if (binary) {
			
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
		}
		
		urlRequest = new URLRequest (uri);
		//urlRequest.userAgent = parent.userAgent;
		urlRequest.method = switch (parent.method) {
			
			case POST: URLRequestMethod.POST;
			default: URLRequestMethod.GET;
			
		}
		
		for (header in parent.headers) {
			
			urlRequest.requestHeaders.push (new URLRequestHeader (header.name, header.value));
			
		}
		
	}
	
	
	public function loadData (uri:String):Future<Bytes> {
		
		var promise = new Promise<Bytes> ();
		
		binary = true;
		createURLLoader ();
		
		urlLoader.addEventListener (ProgressEvent.PROGRESS, function (event) {
			
			if (event.bytesTotal == 0) {
				
				promise.progress (0);
				
			} else {
				
				promise.progress (event.bytesLoaded / event.bytesTotal);
				
			}
			
		});
		
		urlLoader.addEventListener (IOErrorEvent.IO_ERROR, function (event) {
			
			promise.error (event.errorID);
			
		});
		
		urlLoader.addEventListener (Event.COMPLETE, function (event) {
			
			promise.complete (Bytes.ofData (cast (urlLoader.data, ByteArray)));
			
		});
		
		urlLoader.load (urlRequest);
		return promise.future;
		
	}
	
	
	public function loadText (uri:String):Future<String> {
		
		var promise = new Promise<String> ();
		
		binary = false;
		createURLLoader ();
		
		urlLoader.addEventListener (ProgressEvent.PROGRESS, function (event) {
			
			if (event.bytesTotal == 0) {
				
				promise.progress (0);
				
			} else {
				
				promise.progress (event.bytesLoaded / event.bytesTotal);
				
			}
			
		});
		
		urlLoader.addEventListener (IOErrorEvent.IO_ERROR, function (event) {
			
			promise.error (event.errorID);
			
		});
		
		urlLoader.addEventListener (Event.COMPLETE, function (event) {
			
			promise.complete (cast (urlLoader.data, String));
			
		});
		
		urlLoader.load (urlRequest);
		return promise.future;
		
	}
	
	
}