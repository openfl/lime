package net;

#if (sys && target.threaded)
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Eof;
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Mutex;
import sys.thread.Thread;

/**
	Answers HTTP requests on a local port with the response a test scripts for
	each, and keeps every request as it arrived. Each connection is served on
	a thread of its own and carries one exchange.
**/
#if (cpp && !windows)
@:cppFileCode("#include <signal.h>")
#end
class ScriptedServer
{
	/**
		The server's origin, as `http://127.0.0.1:port`, with no path.
	**/
	public var origin(default, null):String;

	public var port(default, null):Int;

	private var answer:RecordedRequest->ScriptedResponse;
	private var disconnects:Int = 0;
	private var listener:Socket;
	private var lock:Mutex;
	private var received:Array<RecordedRequest> = [];
	private var stopped:Bool;

	public function new(answer:RecordedRequest->ScriptedResponse)
	{
		#if (cpp && !windows)
		// Clients hang up on answers they no longer want, and a write to them
		// would end the tests with SIGPIPE
		untyped __cpp__("signal(SIGPIPE, SIG_IGN)");
		#end

		this.answer = answer;
		lock = new Mutex();

		listener = new Socket();
		listener.bind(new Host("127.0.0.1"), 0);
		listener.listen(32);
		port = listener.host().port;
		origin = "http://127.0.0.1:" + port;

		Thread.create(acceptConnections);
	}

	/**
		Checks `done` as the application's loop runs, until it holds or
		`seconds` pass, then calls `then` with whether it held.
	**/
	public static function poll(done:Void->Bool, seconds:Float, then:Bool->Void):Void
	{
		var end = haxe.Timer.stamp() + seconds;

		function check():Void
		{
			if (done())
			{
				then(true);
			}
			else if (haxe.Timer.stamp() > end)
			{
				then(false);
			}
			else
			{
				haxe.Timer.delay(check, 10);
			}
		}

		check();
	}

	/**
		Runs `step` on each item in turn, each once the one before it calls
		`next`, then calls `done`.
	**/
	public static function each<T>(items:Array<T>, step:T->(Void->Void)->Void, done:Void->Void):Void
	{
		var remaining = items.copy();

		function next():Void
		{
			if (remaining.length == 0)
			{
				done();
			}
			else
			{
				step(remaining.shift(), next);
			}
		}

		next();
	}

	/**
		A URL on a local port that nothing listens on.
	**/
	public static function refusedURL(path:String = "/"):String
	{
		var closed = new Socket();
		closed.bind(new Host("127.0.0.1"), 0);
		var url = "http://127.0.0.1:" + closed.host().port + path;
		closed.close();
		return url;
	}

	/**
		How many connections the client closed before the server was done with
		them.
	**/
	public function countDisconnects():Int
	{
		lock.acquire();
		var count = disconnects;
		lock.release();
		return count;
	}

	/**
		The requests received so far, in the order they finished arriving.
	**/
	public function requests():Array<RecordedRequest>
	{
		lock.acquire();
		var copy = received.copy();
		lock.release();
		return copy;
	}

	public function stop():Void
	{
		stopped = true;
	}

	public function url(path:String):String
	{
		return origin + path;
	}

	private function acceptConnections():Void
	{
		while (!stopped)
		{
			// Waits briefly, so stopping is seen
			if (Socket.select([listener], [], [], 0.05).read.length == 0) continue;

			try
			{
				var connection = listener.accept();
				Thread.create(function() serve(connection));
			}
			catch (e:Dynamic) {}
		}

		listener.close();
	}

	private function disconnected():Void
	{
		lock.acquire();
		disconnects++;
		lock.release();
	}

	private function hold(connection:Socket):Void
	{
		// Keeps the connection open, sending nothing, until the client closes it
		// or the server stops
		var buffer = Bytes.alloc(4096);

		while (!stopped)
		{
			if (Socket.select([connection], [], [], 0.05).read.length == 0) continue;

			try
			{
				if (connection.input.readBytes(buffer, 0, buffer.length) <= 0)
				{
					disconnected();
					return;
				}
			}
			catch (e:Dynamic)
			{
				disconnected();
				return;
			}
		}
	}

	private function pause(seconds:Float):Void
	{
		var end = haxe.Timer.stamp() + seconds;
		while (!stopped && haxe.Timer.stamp() < end)
		{
			Sys.sleep(Math.min(0.01, end - haxe.Timer.stamp() + 0.001));
		}
	}

	private function readRequest(connection:Socket):RecordedRequest
	{
		var request = new RecordedRequest();
		var line = connection.input.readLine();
		request.head = line + "\r\n";

		var parts = line.split(" ");
		request.method = parts[0];
		request.target = parts.length > 1 ? parts[1] : "";
		request.version = parts.length > 2 ? parts[2] : "";

		while ((line = connection.input.readLine()) != "")
		{
			request.head += line + "\r\n";
			var colon = line.indexOf(":");
			if (colon < 0) continue;
			request.headers.push({name: line.substr(0, colon), value: StringTools.trim(line.substr(colon + 1))});
		}

		var expect = request.header("Expect");
		if (expect != null && expect.toLowerCase() == "100-continue")
		{
			connection.output.writeString("HTTP/1.1 100 Continue\r\n\r\n");
			connection.output.flush();
		}

		var encoding = request.header("Transfer-Encoding");
		var length = request.header("Content-Length");

		if (encoding != null && encoding.toLowerCase().indexOf("chunked") > -1)
		{
			request.chunked = true;
			var body = new BytesBuffer();

			while (true)
			{
				var size = connection.input.readLine();
				var extension = size.indexOf(";");
				if (extension > -1) size = size.substr(0, extension);
				var count = Std.parseInt("0x" + StringTools.trim(size));
				if (count == null || count == 0) break;
				body.add(connection.input.read(count));
				connection.input.readLine();
			}

			// Trailer fields, up to the blank line
			while (connection.input.readLine() != "") {}
			request.body = body.getBytes();
		}
		else if (length != null)
		{
			request.body = connection.input.read(Std.parseInt(length));
		}
		else
		{
			request.body = Bytes.alloc(0);
		}

		return request;
	}

	private function serve(connection:Socket):Void
	{
		try
		{
			connection.setTimeout(10);
			var request = readRequest(connection);

			lock.acquire();
			received.push(request);
			lock.release();

			var response = answer(request);
			if (response == null) response = ScriptedResponse.text(404, "not scripted");

			if (response.delay > 0) pause(response.delay);

			if (!stopped)
			{
				write(connection, request, response);
			}
		}
		catch (e:Dynamic) {}

		try connection.close() catch (e:Dynamic) {}
	}

	private function send(connection:Socket, data:Bytes, response:ScriptedResponse):Bool
	{
		// Sends in pieces, with a pause between them, and says whether the
		// client was still there
		var piece = response.pieceSize > 0 ? response.pieceSize : data.length;
		var position = 0;

		while (position < data.length)
		{
			if (stopped) return false;
			if (position > 0 && response.pause > 0) pause(response.pause);

			var count = Std.int(Math.min(piece, data.length - position));

			try
			{
				connection.output.writeFullBytes(data, position, count);
				connection.output.flush();
			}
			catch (e:Dynamic)
			{
				disconnected();
				return false;
			}

			position += count;
		}

		return true;
	}

	private function write(connection:Socket, request:RecordedRequest, response:ScriptedResponse):Void
	{
		if (response.silent)
		{
			hold(connection);
			return;
		}

		if (response.raw != null)
		{
			if (send(connection, response.raw, response) && response.hold) hold(connection);
			return;
		}

		for (interim in response.interim)
		{
			connection.output.writeString(interim);
		}

		var head = new StringBuf();
		head.add("HTTP/1.1 " + response.status + " " + response.reason + "\r\n");

		for (header in response.headers)
		{
			head.add(header + "\r\n");
		}

		var body = response.body != null ? response.body : Bytes.alloc(0);

		if (response.chunks != null)
		{
			head.add("Transfer-Encoding: chunked\r\n");

			var chunked = new BytesBuffer();
			for (chunk in response.chunks)
			{
				chunked.addString(StringTools.hex(chunk.length) + (response.chunkExtensions ? ";piece=" + chunk.length : "") + "\r\n");
				chunked.add(chunk);
				chunked.addString("\r\n");
			}

			if (response.finishChunks)
			{
				chunked.addString("0\r\n");
				for (trailer in response.trailers) chunked.addString(trailer + "\r\n");
				chunked.addString("\r\n");
			}

			body = chunked.getBytes();
		}
		else if (response.declaredLength >= 0)
		{
			head.add("Content-Length: " + response.declaredLength + "\r\n");
		}
		else if (!response.closeDelimited && response.status != 204)
		{
			// RFC 9110 section 8.6: no Content-Length in a 204
			head.add("Content-Length: " + body.length + "\r\n");
		}

		head.add("Connection: close\r\n\r\n");

		var headBytes = Bytes.ofString(head.toString());
		connection.output.writeFullBytes(headBytes, 0, headBytes.length);
		connection.output.flush();

		// A response to HEAD has no content, whatever its header fields say
		if (request.method != "HEAD")
		{
			if (response.cutAfter >= 0 && response.cutAfter < body.length) body = body.sub(0, response.cutAfter);
			if (!send(connection, body, response)) return;
		}

		if (response.hold) hold(connection);
	}
}

/**
	How a load ended: the value it completed with, or the error it failed with,
	and the progress it reported before that, with when each came.
**/
class LoadOutcome<T>
{
	public var completed:Bool = false;
	public var error:Dynamic;
	public var failed:Bool = false;
	public var finishedAt:Float;

	/**
		Each progress report, as `[loaded, total]`.
	**/
	public var progress:Array<Array<Int>> = [];

	/**
		Whether progress was reported after the load had finished.
	**/
	public var progressAfterFinishing:Bool = false;

	public var startedAt:Float;
	public var value:T;

	public function new()
	{
		startedAt = haxe.Timer.stamp();
	}

	/**
		How long the load took, in seconds.
	**/
	public var seconds(get, never):Float;

	/**
		Calls `then` once `future` completes or fails, unless the test has
		ended by then, as when it timed out.
	**/
	public static function watch<V>(future:lime.app.Future<V>, async:utest.Async, then:LoadOutcome<V>->Void):Void
	{
		var outcome = new LoadOutcome<V>();
		var finished = false;

		future.onProgress(function(loaded, total)
		{
			if (finished) outcome.progressAfterFinishing = true;
			outcome.progress.push([loaded, total]);
		});

		future.onComplete(function(value)
		{
			if (finished) return;
			finished = true;
			outcome.completed = true;
			outcome.value = value;
			outcome.finishedAt = haxe.Timer.stamp();
			if (!async.resolved) then(outcome);
		});

		future.onError(function(error)
		{
			if (finished) return;
			finished = true;
			outcome.failed = true;
			outcome.error = error;
			outcome.finishedAt = haxe.Timer.stamp();
			if (!async.resolved) then(outcome);
		});
	}

	public function toString():String
	{
		return completed ? "completed with " + Std.string(value) : failed ? "failed with " + Std.string(error) : "not finished";
	}

	private function get_seconds():Float
	{
		return finishedAt - startedAt;
	}
}

/**
	A request as the server received it.
**/
class RecordedRequest
{
	public var body:Bytes;
	public var chunked:Bool = false;

	/**
		The request line and header fields, as sent, with CRLF line endings.
	**/
	public var head:String;

	public var headers:Array<{name:String, value:String}> = [];
	public var method:String;
	public var path(get, never):String;
	public var query(get, never):String;
	public var target:String;
	public var version:String;

	public function new() {}

	/**
		The name and value pairs of `application/x-www-form-urlencoded` text, as
		the URL Standard parses them: split at `&` and the first `=`, with `+`
		read as a space and percent-encoded bytes as UTF-8.
	**/
	public static function formFields(text:String):Array<{name:String, value:String}>
	{
		var fields = [];
		if (text == null) return fields;

		for (sequence in text.split("&"))
		{
			if (sequence == "") continue;

			var equals = sequence.indexOf("=");
			var name = equals > -1 ? sequence.substr(0, equals) : sequence;
			var value = equals > -1 ? sequence.substr(equals + 1) : "";
			fields.push({name: formDecode(name), value: formDecode(value)});
		}

		return fields;
	}

	private static function formDecode(text:String):String
	{
		var input = Bytes.ofString(StringTools.replace(text, "+", " "));
		var output = new BytesBuffer();
		var i = 0;

		while (i < input.length)
		{
			var byte = input.get(i);

			if (byte == "%".code && i + 2 < input.length && isHex(input.get(i + 1)) && isHex(input.get(i + 2)))
			{
				output.addByte(Std.parseInt("0x" + input.getString(i + 1, 2)));
				i += 3;
			}
			else
			{
				output.addByte(byte);
				i++;
			}
		}

		return output.getBytes().toString();
	}

	private static function isHex(byte:Int):Bool
	{
		return (byte >= "0".code && byte <= "9".code) || (byte >= "a".code && byte <= "f".code) || (byte >= "A".code && byte <= "F".code);
	}

	/**
		The value of the first field with this name, ignoring case, or `null`.
	**/
	public function header(name:String):String
	{
		var values = headerValues(name);
		return values.length > 0 ? values[0] : null;
	}

	/**
		The values of every field with this name, ignoring case.
	**/
	public function headerValues(name:String):Array<String>
	{
		var values = [];
		for (header in headers)
		{
			if (header.name.toLowerCase() == name.toLowerCase()) values.push(header.value);
		}
		return values;
	}

	private function get_path():String
	{
		var mark = target.indexOf("?");
		return mark > -1 ? target.substr(0, mark) : target;
	}

	private function get_query():String
	{
		var mark = target.indexOf("?");
		return mark > -1 ? target.substr(mark + 1) : null;
	}
}

/**
	What the server answers a request with. Unless `raw` is set, it sends a
	status line, the header fields, `Connection: close`, a `Content-Length` for
	the body unless it is chunked, and the body.
**/
class ScriptedResponse
{
	public var body:Bytes;

	/**
		The body's pieces, sent with chunked transfer coding.
	**/
	public var chunks:Array<Bytes>;

	/**
		Whether each chunk carries a chunk extension.
	**/
	public var chunkExtensions:Bool = false;

	/**
		Whether the body ends without a length, when the connection closes.
	**/
	public var closeDelimited:Bool = false;

	/**
		How many bytes of the body to send before closing, or -1 for all.
	**/
	public var cutAfter:Int = -1;

	/**
		The `Content-Length` to declare instead of the body's own, or -1.
	**/
	public var declaredLength:Int = -1;

	/**
		Seconds to wait before answering.
	**/
	public var delay:Float = 0;

	/**
		Whether chunked bodies end with the last chunk.
	**/
	public var finishChunks:Bool = true;

	public var headers:Array<String> = [];

	/**
		Whether to keep the connection open once the answer is sent, until the
		client closes it.
	**/
	public var hold:Bool = false;

	/**
		Interim responses sent before the final one, as raw text.
	**/
	public var interim:Array<String> = [];

	/**
		Seconds to wait between pieces of the body.
	**/
	public var pause:Float = 0;

	/**
		How many bytes to send at a time, or 0 for all at once.
	**/
	public var pieceSize:Int = 0;

	/**
		Bytes sent as they are, instead of a response made from the other fields.
	**/
	public var raw:Bytes;

	public var reason:String;

	/**
		Whether to send nothing at all, and keep the connection open.
	**/
	public var silent:Bool = false;

	public var status:Int;

	/**
		Trailer fields sent after the last chunk.
	**/
	public var trailers:Array<String> = [];

	public function new(status:Int = 200, body:Bytes = null, headers:Array<String> = null)
	{
		this.status = status;
		this.body = body;
		if (headers != null) this.headers = headers;
		reason = reasonPhrase(status);
	}

	public static function bytes(status:Int, body:Bytes, ?headers:Array<String>):ScriptedResponse
	{
		return new ScriptedResponse(status, body, headers);
	}

	/**
		`data` in the gzip format of RFC 1952: a header, the DEFLATE data that
		zlib makes, and the CRC-32 and length of `data`.
	**/
	public static function gzip(data:Bytes):Bytes
	{
		// zlib's format is the DEFLATE data between a 2 byte header and a 4 byte
		// Adler-32 checksum
		var zlib = haxe.zip.Compress.run(data, 6);
		var output = new BytesBuffer();
		for (byte in [0x1F, 0x8B, 8, 0, 0, 0, 0, 0, 0, 0xFF]) output.addByte(byte);
		output.addBytes(zlib, 2, zlib.length - 6);

		var crc = haxe.crypto.Crc32.make(data);
		for (value in [crc, data.length])
		{
			for (shift in [0, 8, 16, 24]) output.addByte((value >>> shift) & 0xFF);
		}

		return output.getBytes();
	}

	public static function redirect(status:Int, location:String, ?headers:Array<String>):ScriptedResponse
	{
		var response = text(status, "moved");
		response.headers.push("Location: " + location);
		if (headers != null) response.headers = response.headers.concat(headers);
		return response;
	}

	public static function rawText(text:String):ScriptedResponse
	{
		var response = new ScriptedResponse();
		response.raw = Bytes.ofString(text);
		return response;
	}

	public static function text(status:Int, body:String, ?headers:Array<String>):ScriptedResponse
	{
		return new ScriptedResponse(status, Bytes.ofString(body), headers);
	}

	public static function unanswered():ScriptedResponse
	{
		var response = new ScriptedResponse();
		response.silent = true;
		return response;
	}

	private static function reasonPhrase(status:Int):String
	{
		return switch (status)
		{
			case 200: "OK";
			case 201: "Created";
			case 204: "No Content";
			case 301: "Moved Permanently";
			case 302: "Found";
			case 303: "See Other";
			case 307: "Temporary Redirect";
			case 308: "Permanent Redirect";
			case 400: "Bad Request";
			case 404: "Not Found";
			case 500: "Internal Server Error";
			case 503: "Service Unavailable";
			default: "Status";
		}
	}
}
#end
