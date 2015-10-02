package lime.net;


import haxe.io.Bytes;
import lime.app.Event;
import lime.utils.ByteArray;

#if (js && html5)
import js.html.EventTarget;
import js.html.XMLHttpRequest;
import js.Browser;
import js.Lib;
#end

#if lime_curl
import lime.net.curl.CURL;
import lime.net.curl.CURLEasy;
import lime.net.curl.CURLCode;
import lime.net.curl.CURLInfo;
import lime.net.curl.CURLOption;
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
	
	#if lime_curl
	private var __curl:CURL;
	private var __data:ByteArray;
	#end
	
	public function new (request:URLRequest = null) {
		
		bytesLoaded = 0;
		bytesTotal = 0;
		dataFormat = URLLoaderDataFormat.TEXT;

		#if lime_curl
		__data = new ByteArray ();
		__curl = CURLEasy.init();
		#end

		if (request != null) {
			
			load (request);
			
		}
		
	}
	
	
	public function close ():Void {
		
		#if lime_curl
		CURLEasy.cleanup(__curl);
		#end
		
	}
	
	
	private dynamic function getData ():Dynamic {
		
		return null;
		
	}
	
	
	public function load (request:URLRequest):Void {
		
		#if (js && html5)
		requestUrl (request.url, request.method, request.data, request.formatRequestHeaders ());
		#elseif lime_curl
		requestUrl (request.url, request.method, request.data, request.formatRequestHeaders ());
		#end
		
	}
	
	
	#if (js && html5)
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
	
	
	private function requestUrl (url:String, method:URLRequestMethod, data:Dynamic, requestHeaders:Array<URLRequestHeader>):Void {
		
		var xmlHttpRequest:XMLHttpRequest = untyped __new__("XMLHttpRequest");
		registerEvents (cast xmlHttpRequest);
		var uri:Dynamic = "";
		
		if (Std.is (data, ByteArray)) {
			
			var data:ByteArray = cast data;
			
			switch (dataFormat) {
				
				case BINARY: uri = data.__getBuffer ();
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
			
			if (method == GET && uri != null && uri != "") {
				
				var question = url.split ("?").length <= 1;
				xmlHttpRequest.open ("GET", url + (if (question) "?" else "&") + uri, true);
				uri = "";
				
			} else {
				
				//js.Lib.alert ("open: " + method + ", " + url + ", true");
				xmlHttpRequest.open (cast (method, String), url, true);
				
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
	#elseif lime_curl

	private function prepareData(data:Dynamic):ByteArray {

		var uri:ByteArray = new ByteArray();
		if (Std.is (data, ByteArray)) {
			
			var data:ByteArray = cast data;
			uri = data;
			
		} else if (Std.is (data, URLVariables)) {
			
			var data:URLVariables = cast data;
			var tmp:String = "";
			for (p in Reflect.fields (data)) {
				
				if (tmp.length != 0) tmp += "&";
				tmp += StringTools.urlEncode (p) + "=" + StringTools.urlEncode (Std.string (Reflect.field (data, p)));
				
			}

			uri.writeUTFBytes(tmp);

			
		} else {
			
			if (data != null) {
				
				uri.writeUTFBytes(Std.string(data));
				
			}
			
		}

		return uri;

	}

	private function requestUrl (url:String, method:URLRequestMethod, data:Dynamic, requestHeaders:Array<URLRequestHeader>):Void {

		var uri = prepareData(data);
		uri.position = 0;

		__data = new ByteArray ();
		bytesLoaded = 0;
		bytesTotal = 0;

		CURLEasy.reset(__curl);
		CURLEasy.setopt(__curl, URL, url);

		switch(method) {
			case HEAD:
				CURLEasy.setopt(__curl, NOBODY, true);
			case GET:
				CURLEasy.setopt(__curl, HTTPGET, true);
				if (uri.length > 0) CURLEasy.setopt (__curl, URL, url + "?" + uri.readUTFBytes (uri.length));
			case POST:
				CURLEasy.setopt(__curl, POST, true);
				CURLEasy.setopt(__curl, READFUNCTION, readFunction.bind(_, uri));
				CURLEasy.setopt(__curl, POSTFIELDSIZE, uri.length);
				CURLEasy.setopt(__curl, INFILESIZE, uri.length);
			case PUT:
				CURLEasy.setopt(__curl, UPLOAD, true);
				CURLEasy.setopt(__curl, READFUNCTION, readFunction.bind(_, uri));
				CURLEasy.setopt(__curl, INFILESIZE, uri.length);
			case _:
				CURLEasy.setopt(__curl, CUSTOMREQUEST, cast method);
				CURLEasy.setopt(__curl, READFUNCTION, readFunction.bind(_, uri));
				CURLEasy.setopt(__curl, INFILESIZE, uri.length);
		}

		var headers:Array<String> = [];
		headers.push("Expect: "); // removes the default cURL value
		for (requestHeader in requestHeaders) {

			headers.push('${requestHeader.name}: ${requestHeader.value}');

		}

		CURLEasy.setopt(__curl, HTTPHEADER, headers);

		CURLEasy.setopt(__curl, PROGRESSFUNCTION, progressFunction);

		CURLEasy.setopt(__curl, WRITEFUNCTION, writeFunction);
		CURLEasy.setopt(__curl, HEADERFUNCTION, headerFunction);

		CURLEasy.setopt(__curl, SSL_VERIFYPEER, false);
		CURLEasy.setopt(__curl, SSL_VERIFYHOST, false);
		CURLEasy.setopt(__curl, USERAGENT, "libcurl-agent/1.0");
		CURLEasy.setopt(__curl, CONNECTTIMEOUT, 30);

		var result = CURLEasy.perform(__curl);


		var responseCode = CURLEasy.getinfo(__curl, RESPONSE_CODE);

		if (result == CURLCode.OK) {
			/*
			switch(dataFormat) {
				case BINARY: this.data = __data;
				default: this.data = __data.asString();
			}
			*/
			//this.data = __data;
			__data.position = 0;
			this.data = __data.readUTFBytes (__data.length);
			onHTTPStatus.dispatch (this, Std.parseInt(responseCode));
			onComplete.dispatch (this);
		} else {
			onIOError.dispatch (this, "Problem with curl: " + result);
		}
		
	}

	private function writeFunction (output:Bytes, size:Int, nmemb:Int):Int {

		__data.writeBytes (ByteArray.fromBytes (output));
		return size * nmemb;

	}

	private function headerFunction (output:Bytes, size:Int, nmemb:Int):Int {

		// TODO
		return size * nmemb;

	}

	private function progressFunction (dltotal:Float, dlnow:Float, uptotal:Float, upnow:Float):Int {
		
		if(upnow>bytesLoaded || dlnow>bytesLoaded || uptotal>bytesTotal || dltotal>bytesTotal) {
			if(upnow > bytesLoaded) bytesLoaded = Std.int(upnow);
			if(dlnow > bytesLoaded) bytesLoaded = Std.int(dlnow);
			if(uptotal > bytesTotal) bytesTotal = Std.int(uptotal);
			if(dltotal > bytesTotal) bytesTotal = Std.int(dltotal);
			onProgress.dispatch(this, bytesLoaded, bytesTotal);
		}
		return 0;
	}

	private function readFunction(max:Int, input:ByteArray):Bytes {
		return input;
	}

	#end
	
	
	
	
	// Event Handlers
	
	
	
	
	private function __onData (_):Void {
		
		#if (js && html5)
		var content:Dynamic = getData ();
		
		switch (dataFormat) {
			
			case BINARY: this.data = ByteArray.__ofBuffer (content);
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
		
		#if (js && html5)
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