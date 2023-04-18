package lime._internal.backend.flash;

import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
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

class FlashHTTPRequest
{
	private var parent:_IHTTPRequest;
	private var urlLoader:URLLoader;
	private var urlRequest:URLRequest;

	public function new() {}

	public function cancel():Void
	{
		if (urlLoader != null)
		{
			urlLoader.close();
		}
	}

	private function construct(binary:Bool):Void
	{
		urlLoader = new URLLoader();
		urlRequest = new URLRequest();

		var query = "";
		var uri = parent.uri;

		if (parent.data != null)
		{
			urlRequest.data = parent.data.getData();
		}
		else
		{
			for (key in parent.formData.keys())
			{
				if (query.length > 0) query += "&";
				query += StringTools.urlEncode(key) + "=" + StringTools.urlEncode(Std.string(parent.formData.get(key)));
			}

			if (query != "" && parent.method == GET)
			{
				if (uri.indexOf("?") > -1)
				{
					uri += "&" + query;
				}
				else
				{
					uri += "?" + query;
				}

				query = "";
			}
		}

		if (binary)
		{
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
		}

		urlRequest.url = uri;
		urlRequest.contentType = parent.contentType;

		// urlRequest.userAgent = parent.userAgent;
		// urlRequest.followRedirects = parent.followRedirects;

		urlRequest.method = switch (parent.method)
		{
			case POST: URLRequestMethod.POST;
			default: URLRequestMethod.GET;
		}

		for (header in parent.headers)
		{
			urlRequest.requestHeaders.push(new URLRequestHeader(header.name, header.value));
		}
	}

	public function init(parent:_IHTTPRequest):Void
	{
		this.parent = parent;
	}

	public function loadData(uri:String):Future<Bytes>
	{
		var promise = new Promise<Bytes>();
		construct(true);

		urlLoader.addEventListener(ProgressEvent.PROGRESS, function(event)
		{
			promise.progress(Std.int(event.bytesLoaded), Std.int(event.bytesTotal));
		});

		urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(event)
		{
			parent.responseStatus = event.status;

			if (parent.enableResponseHeaders)
			{
				parent.responseHeaders = cast event.responseHeaders;
			}
		});

		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function(event)
		{
			promise.error(event.errorID);
		});

		urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event)
		{
			promise.error(403);
		});

		urlLoader.addEventListener(Event.COMPLETE, function(event)
		{
			promise.complete(Bytes.ofData(cast(urlLoader.data, ByteArray)));
		});

		urlLoader.load(urlRequest);
		return promise.future;
	}

	public function loadText(uri:String):Future<String>
	{
		var promise = new Promise<String>();
		construct(false);

		urlLoader.addEventListener(ProgressEvent.PROGRESS, function(event)
		{
			promise.progress(Std.int(event.bytesLoaded), Std.int(event.bytesTotal));
		});

		urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(event)
		{
			parent.responseStatus = event.status;

			if (parent.enableResponseHeaders)
			{
				parent.responseHeaders = cast event.responseHeaders;
			}
		});

		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function(event)
		{
			promise.error(event.errorID);
		});

		urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event)
		{
			promise.error(403);
		});

		urlLoader.addEventListener(Event.COMPLETE, function(event)
		{
			promise.complete(cast(urlLoader.data, String));
		});

		urlLoader.load(urlRequest);
		return promise.future;
	}
}
