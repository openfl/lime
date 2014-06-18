package lime.net;


import lime.app.Event;
import lime.utils.ByteArray;

#if js
import js.html.EventTarget;
import js.html.XMLHttpRequest;
import js.Browser;
import js.Lib;
#end


class URLLoader {
	
	
	public var bytesLoaded:Int;
	public var bytesTotal:Int;
	public var data:Dynamic;
	public var dataFormat (default, set):URLLoaderDataFormat;
	public var onComplete = new Event<URLLoader->Void> ();
	public var onHTTPStatus = new Event<URLLoader->Int->Void> ();
	public var onIOError = new Event<URLLoader->String->Void> ();
	public var onOpen = new Event<URLLoader->Void> ();
	public var onProgress = new Event<URLLoader->Int->Int->Void> ();
	public var onSecurityError = new Event<URLLoader->String->Void> ();
	
	
	public function new (request:URLRequest = null) {
		
		bytesLoaded = 0;
		bytesTotal = 0;
		dataFormat = URLLoaderDataFormat.TEXT;
		
		if (request != null) {
			
			load (request);
			
		}
		
	}
	
	
	public function close ():Void {
		
		
		
	}
	
	
	private dynamic function getData ():Dynamic {
		
		return null;
		
	}
	
	
	public function load (request:URLRequest):Void {
		
		#if js
		requestUrl (request.url, request.method, request.data, request.formatRequestHeaders ());
		#end
		
	}
	
	
	#if js
	private function registerEvents (subject:EventTarget):Void {
		
		var self = this;
		if (untyped __js__("typeof XMLHttpRequestProgressEvent") != __js__('"undefined"')) {
			
			subject.addEventListener ("progress", __onProgress, false);
			
		}
		
		untyped subject.onreadystatechange = function () {
			
			if (subject.readyState != 4) return;
			
			var s = try subject.status catch (e:Dynamic) null;
			
			if (s == untyped __js__("undefined")) {
				
				s = null;
				
			}
			
			if (s != null) {
				
				self.onHTTPStatus.dispatch (this, s);
				
			}
			
			//js.Lib.alert (s);
			
			if (s != null && s >= 200 && s < 400) {
				
				self.__onData (subject.response);
				
			} else {
				
				if (s == null) {
					
					self.onIOError.dispatch (this, "Failed to connect or resolve host");
					
				} else if (s == 12029) {
					
					self.onIOError.dispatch (this, "Failed to connect to host");
					
				} else if (s == 12007) {
					
					self.onIOError.dispatch (this, "Unknown host");
					
				} else if (s == 0) {
					
					self.onIOError.dispatch (this, "Unable to make request (may be blocked due to cross-domain permissions)");
					self.onSecurityError.dispatch (this, "Unable to make request (may be blocked due to cross-domain permissions)");
					
				} else {
					
					self.onIOError.dispatch (this, "Http Error #" + subject.status);
					
				}
				
			}
			
		};
		
	}
	
	
	private function requestUrl (url:String, method:String, data:Dynamic, requestHeaders:Array<URLRequestHeader>):Void {
		
		var xmlHttpRequest:XMLHttpRequest = untyped __new__("XMLHttpRequest");
		registerEvents (cast xmlHttpRequest);
		var uri:Dynamic = "";
		
		if (Std.is (data, ByteArray)) {
			
			var data:ByteArray = cast data;
			
			switch (dataFormat) {
				
				//case BINARY: uri = data.__getBuffer ();
				default: uri = data.readUTFBytes (data.length);
				
			}
			
		} else if (Std.is (data, URLVariables)) {
			
			var data:URLVariables = cast data;
			
			for (p in Reflect.fields (data)) {
				
				if (uri.length != 0) uri += "&";
				uri += StringTools.urlEncode (p) + "=" + StringTools.urlEncode (Reflect.field (data, p));
				
			}
			
		} else {
			
			if (data != null) {
				
				uri = data.toString ();
				
			}
			
		}
		
		try {
			
			if (method == "GET" && uri != null && uri != "") {
				
				var question = url.split ("?").length <= 1;
				xmlHttpRequest.open (method, url + (if (question) "?" else "&") + uri, true);
				uri = "";
				
			} else {
				
				//js.Lib.alert ("open: " + method + ", " + url + ", true");
				xmlHttpRequest.open (method, url, true);
				
			}
			
		} catch (e:Dynamic) {
			
			onIOError.dispatch (this, e.toString ());
			return;
			
		}
		
		//js.Lib.alert ("dataFormat: " + dataFormat);
		
		switch (dataFormat) {
			
			case BINARY: untyped xmlHttpRequest.responseType = 'arraybuffer';
			default:
			
		}
		
		for (header in requestHeaders) {
			
			//js.Lib.alert ("setRequestHeader: " + header.name + ", " + header.value);
			xmlHttpRequest.setRequestHeader (header.name, header.value);
			
		}
		
		//js.Lib.alert ("uri: " + uri);
		
		xmlHttpRequest.send (uri);
		onOpen.dispatch (this);
		
		getData = function () {
			
			if (xmlHttpRequest.response != null) {
				
				return xmlHttpRequest.response;
				
			} else { 
				
				return xmlHttpRequest.responseText;
				
			}
			
		};
		
	}
	#end
	
	
	
	
	// Event Handlers
	
	
	
	
	private function __onData (_):Void {
		
		#if js
		var content:Dynamic = getData ();
		
		switch (dataFormat) {
			
			//case BINARY: this.data = ByteArray.__ofBuffer (content);
			default: this.data = Std.string (content);
			
		}
		#end
		
		onComplete.dispatch (this);
		
	}
	
	
	private function __onProgress (event:XMLHttpRequestProgressEvent):Void {
		
		bytesLoaded = event.loaded;
		bytesTotal = event.total;
		
		onProgress.dispatch (this, bytesLoaded, bytesTotal);
		
	}
	
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function set_dataFormat (inputVal:URLLoaderDataFormat):URLLoaderDataFormat {
		
		#if js
		// prevent inadvertently using typed arrays when they are unsupported
		// @todo move these sorts of tests somewhere common in the vein of Modernizr
		
		if (inputVal == URLLoaderDataFormat.BINARY && !Reflect.hasField (Browser.window, "ArrayBuffer")) {
			
			dataFormat = URLLoaderDataFormat.TEXT;
			
		} else {
			
			dataFormat = inputVal;
			
		}
		
		return dataFormat;
		#else
		return inputVal;
		#end
		
	}
	
	
}


typedef XMLHttpRequestProgressEvent = Dynamic;