package snake.http;

import haxe.Exception;
import haxe.Json;
import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Path;
import snake.socket.BaseServer;
import snake.socket.StreamRequestHandler;
import sys.io.File;
import sys.net.Host;
#if (eval && (haxe_ver >= 4.2))
import snake._internal.net.Socket as Socket;
#else
import sys.net.Socket;
#end

class BaseHTTPRequestHandler extends StreamRequestHandler {
	private static final DATE_STRING_DAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
	private static final DATE_STRING_MONTH_NAMES = [
		"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
	];

	private static macro function getLibraryVersion():haxe.macro.Expr {
		var posInfos = haxe.macro.Context.getPosInfos(haxe.macro.Context.currentPos());
		var directory = Path.directory(posInfos.file);
		var haxelibPath = if (Path.withoutDirectory(posInfos.file) == "Run.hx") {
			Path.join([directory, "..", "..", "haxelib.json"]);
		} else {
			Path.join([directory, "..", "..", "..", "haxelib.json"]);
		}
		var json:Dynamic = Json.parse(File.getContent(haxelibPath));
		return macro $v{json.version};
	}

	private static final DEFAULT_ERROR_CONTENT_TYPE = "text/html;charset=utf-8";

	/**

		The default request version.  This only affects responses up until
		the point where the request line is parsed, so it mainly decides what
		the client gets back when sending a malformed request line.
		Most web servers default to HTTP 0.9, i.e. don't send a status line.
	**/
	private static final DEFAULT_REQUEST_VERSION = "HTTP/0.9";

	private static final EREG_TRAILING_CR_AND_LEFT = ~/^(.*)[\r\n]+$/;
	private static final EREG_LEADING_SLASHES = ~/^\/\/+(.*)$/;
	private static final MAX_HEADERS = 100;
	private static final MAX_LINE = 65536;

	/**
		The server software version.  You may want to override this.
		The format is multiple whitespace-separated strings,
		where each string is of the form name[\/version].
	**/
	private var serverVersion:String = 'BaseHTTP/${getLibraryVersion()}';

	/**
		The Haxe system version.
	**/
	private var sysVersion:String = 'Haxe/${haxe.macro.Compiler.getDefine("haxe")}';

	private var commandHandlers:Map<String, () -> Void> = [];
	private var command:String;
	private var path:String;
	private var closeConnection:Bool = false;
	private var headersBuffer:String;
	private var headers:Map<String, String>;
	private var rawRequestLine:String;
	private var requestLine:String;
	private var requestVersion:String;
	private var errorContentType:String = DEFAULT_ERROR_CONTENT_TYPE;

	/**
		The version of the HTTP protocol we support.
		Set this to `"HTTP/1.1"` to enable automatic keepalive.
	**/
	public static var protocolVersion:String = "HTTP/1.0";

	/**
		Constructor.
	**/
	public function new(request:Socket, clientAddress:{host:Host, port:Int}, server:BaseServer) {
		super(request, clientAddress, server);
	}

	/**
		Parse a request (internal).

		The request should be stored in rawRequestLine; the results
		are in command, path, requestVersion and headers.

		@return true for success, false for failure; on failure, any relevant
		error response has already been sent back.
	**/
	private function parseRequest():Bool {
		command = null;
		var version = DEFAULT_REQUEST_VERSION;
		requestVersion = DEFAULT_REQUEST_VERSION;
		closeConnection = true;
		// TODO: iso-8859-1
		requestLine = rawRequestLine;
		if (EREG_TRAILING_CR_AND_LEFT.match(requestLine)) {
			requestLine = EREG_TRAILING_CR_AND_LEFT.matched(1);
		}

		var baseVersionNumber:String = null;
		// Enough to determine protocol version
		var words = ~/\s/g.split(requestLine);
		if (words.length >= 3) {
			version = words[words.length - 1];
			var parsedVersionNumber:Array<Int> = null;
			try {
				if (!StringTools.startsWith(version, 'HTTP/')) {
					throw new Exception("http version must start with HTTP/");
				}
				baseVersionNumber = version.split("/")[1];
				var versionNumber = baseVersionNumber.split(".");
				// RFC 2145 section 3.1 says there can be only one "." and
				//   - major and minor numbers MUST be treated as
				//      separate integers;
				//   - HTTP/2.4 is a lower version than HTTP/2.13, which in
				//      turn is lower than HTTP/12.3;
				//   - Leading zeros MUST be ignored by recipients.
				if (versionNumber.length != 2) {
					throw new Exception("too many . separators in http version");
				}
				if (Lambda.exists(versionNumber, component -> !~/^\d+$/.match(component))) {
					throw new Exception("non digit in http version");
				}
				if (Lambda.exists(versionNumber, component -> component.length > 10)) {
					throw new Exception("unreasonable length http version");
				}
				parsedVersionNumber = [Std.parseInt(versionNumber[0]), Std.parseInt(versionNumber[1])];
			} catch (e:Exception) {
				sendError(HTTPStatus.BAD_REQUEST, 'Bad request version (${version})');
				return false;
			}
			if ((parsedVersionNumber[0] > 1 || (parsedVersionNumber[0] == 1 && parsedVersionNumber[1] >= 1))
				&& protocolVersion >= "HTTP/1.1") {
				closeConnection = false;
			}
			if (parsedVersionNumber[0] >= 2) {
				sendError(HTTPStatus.HTTP_VERSION_NOT_SUPPORTED, 'Invalid HTTP version (%s)" (${baseVersionNumber})');
				return false;
			}
			requestVersion = version;
		}

		if (!(2 <= words.length && words.length <= 3)) {
			sendError(HTTPStatus.BAD_REQUEST, 'Bad request syntax (${requestLine})');
			return false;
		}

		var parsedCommand = words[0];
		var parsedPath = words[1];

		if (words.length == 2) {
			closeConnection = true;
			if (parsedCommand != 'GET') {
				sendError(HTTPStatus.BAD_REQUEST, 'Bad HTTP/0.9 request type (${parsedCommand})');
				return false;
			}
		}

		command = parsedCommand;
		path = parsedPath;

		// gh-87389: The purpose of replacing '//' with '/' is to protect
		// against open redirect attacks possibly triggered if the path starts
		// with '//' because http clients treat //path as an absolute URI
		// without scheme (similar to http://path) rather than a path.
		if (EREG_LEADING_SLASHES.match(path)) {
			path = '/' + EREG_LEADING_SLASHES.matched(1);
		}

		// Examine the headers and look for a Connection directive.
		try {
			headers = HeaderParser.parseHeaders(rfile);
		} catch (e:Exception) {
			sendError(HTTPStatus.REQUEST_HEADER_FIELDS_TOO_LARGE, "Line too long or too many headers");
			return false;
		}

		var connType = headers.get('Connection');
		if (connType == null) {
			connType = "";
		}
		if (connType.toLowerCase() == "close") {
			closeConnection = true;
		} else if (connType.toLowerCase() == 'keep-alive' && protocolVersion >= "HTTP/1.1") {
			closeConnection = false;
		}

		// Examine the headers and look for an Expect directive
		var expect = headers.get('Expect');
		if (expect == null) {
			expect = "";
		}
		if (expect.toLowerCase() == "100-continue" && protocolVersion >= "HTTP/1.1" && requestVersion >= "HTTP/1.1") {
			if (!handleExpect100()) {
				return false;
			}
		}

		return true;
	}

	/**
		Decide what to do with an "Expect: 100-continue" header.

		If the client is expecting a 100 Continue response, we must
		respond with either a 100 Continue or a final response before
		waiting for the request body. The default is to always respond
		with a 100 Continue. You can behave differently (for example,
		reject unauthorized requests) by overriding this method.

		@return This method should either return true (possibly after sending
		a 100 Continue response) or send an error response and return
		false.
	**/
	private function handleExpect100():Bool {
		sendResponseOnly(HTTPStatus.CONTINUE);
		endHeaders();
		return true;
	}

	/**
		Handle a single HTTP request.

		You normally don't need to override this method; see the class
		doc string for information on how to handle specific HTTP
		commands such as GET and POST.
	**/
	private function handleOneRequest():Void {
		try {
			var selected = Socket.select([connection], null, null, 5);
			if (selected.read.length == 0) {
				closeConnection = true;
				return;
			}
			rawRequestLine = "";
			var lineLength = 0;
			var char:String = null;
			// can't seem to rely on Haxe socket input readLine() because it
			// sometimes blocks until the connection is dropped, even if
			// Socket.select() says that the socket is ready to read.
			try {
				while (true) {
					char = rfile.readString(1);
					if (char == "\r") {
						continue;
					} else if (char == "\n") {
						break;
					} else {
						rawRequestLine += char;
						if (lineLength > MAX_LINE) {
							break;
						}
					}
				}
			} catch (e:Eof) {
				closeConnection = true;
				return;
			}
			if (lineLength > MAX_LINE) {
				requestLine = '';
				requestVersion = '';
				command = '';
				sendError(HTTPStatus.REQUEST_URI_TOO_LONG);
				return;
			}
			if (rawRequestLine.length == 0) {
				closeConnection = true;
				return;
			}
			if (!parseRequest()) {
				// An error code has been sent, just exit
				return;
			}
			if (commandHandlers.exists(command)) {
				commandHandlers.get(command)();
			} else {
				sendError(HTTPStatus.NOT_IMPLEMENTED, 'Unsupported method ($command)');
				return;
			}
			// actually send the response if not already done.
			// NOTE: Haxe does not seem to actually flush here!
			wfile.flush();
		} catch (e:Exception) {
			try {
				connection.peer();
			} catch (e:Exception) {
				// the peer disconnected before we could complete the request
				closeConnection = true;
				return;
			}
			logError("Unknown exception: " + e.toString());
			closeConnection = true;
			return;
		}
	}

	/**
		Handle multiple requests if necessary.
	**/
	override private function handle():Void {
		closeConnection = true;
		handleOneRequest();
		while (!closeConnection) {
			handleOneRequest();
		}
	}

	/**
		Send and log an error reply.

		@param code an HTTP error code
					3 digits
		@param message a simple optional 1 line reason phrase.
				*( HTAB / SP / VCHAR / %x80-FF )
				defaults to short entry matching the response code

		This sends an error response (so it must be called before any
		output has been generated), logs the error, and finally sends
		a piece of HTML explaining the error to the user.
	**/
	private function sendError(status:HTTPStatus, ?message:String):Void {
		if (message == null) {
			message = status.message;
		}
		logError('code ${status.code} message ${message}');
		sendResponse(status, message);
		sendHeader('Connection', 'close');

		// Message body is omitted for cases described in:
		//  - RFC7230: 3.3. 1xx, 204(No Content), 304(Not Modified)
		//  - RFC7231: 6.3.6. 205(Reset Content)
		var body:String = null;
		if (status.code >= 200 && ![HTTPStatus.NO_CONTENT, HTTPStatus.RESET_CONTENT, HTTPStatus.NOT_MODIFIED].contains(status)) {
			// HTML encode to prevent Cross Site Scripting attacks
			// (see bug #1100201)

			var contentMessage = StringTools.htmlEscape(status.message);
			body = '<!DOCTYPE HTML>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<title>Error response</title>
	</head>
	<body>
		<h1>Error response</h1>
		<p>Error code: ${status.code}</p>
		<p>Message: ${contentMessage}.</p>
	</body>
</html>';
			sendHeader("Content-Type", errorContentType);
			sendHeader('Content-Length', Std.string(body.length));
		}
		endHeaders();

		if (command != 'HEAD' && body != null) {
			wfile.writeString(body);
		}
	}

	/**
		Add the response header to the headers buffer and log the
		response code.

		Also send two standard headers with the server software
		version and the current date.
	**/
	private function sendResponse(status:HTTPStatus, ?message:String):Void {
		logRequest(status);
		sendResponseOnly(status, message);
		sendHeader('Server', versionString());
		sendHeader('Date', dateTimeString());
	}

	/**
		Send the response header only.
	**/
	private function sendResponseOnly(status:HTTPStatus, ?message:String):Void {
		if (requestVersion != 'HTTP/0.9') {
			if (message == null) {
				message = status.message;
			}
			if (headersBuffer == null) {
				headersBuffer = "";
			}
			headersBuffer += '${protocolVersion} ${status.code} ${message}\r\n';
		}
	}

	/**
		Send a MIME header to the headers buffer.
	**/
	private function sendHeader(keyword:String, value:String):Void {
		if (requestVersion != 'HTTP/0.9') {
			if (headersBuffer == null) {
				headersBuffer = "";
			}
			headersBuffer += '${keyword}: ${value}\r\n';
		}

		if (keyword.toLowerCase() == 'connection') {
			if (value.toLowerCase() == 'close') {
				closeConnection = true;
			} else if (value.toLowerCase() == 'keep-alive') {
				closeConnection = false;
			}
		}
	}

	/**
		Send the blank line ending the MIME headers.
	**/
	private function endHeaders():Void {
		if (requestVersion != "HTTP/0.9") {
			headersBuffer += "\r\n";
			flushHeaders();
		}
	}

	private function flushHeaders():Void {
		if (headersBuffer != null && headersBuffer.length > 0) {
			wfile.writeString(headersBuffer);
			headersBuffer = "";
		}
	}

	/**
		Log an accepted request.

		This is called by sendResponse().
	**/
	private function logRequest(?code:Any, ?size:Any):Void {
		if (code == null) {
			code = "-";
		}
		if (size == null) {
			size = "-";
		}
		if ((code is HTTPStatus)) {
			code = (code : HTTPStatus).code;
		}
		logMessage('"${requestLine}" ${code} ${size}');
	}

	/**
		Log an error.

		This is called when a request cannot be fulfilled.  By
		default it passes the message on to logMessage().

		Arguments are the same as for logMessage().

		XXX This should go to the separate error log.
	**/
	private function logError(message:String):Void {
		logMessage(message);
	}

	/**
		Log an arbitrary message.

		This is used by all other logging functions.  Override
		it if you have specific logging wishes.

		The client ip and current date/time are prefixed to
		every message.

		Unicode control characters are replaced with escaped hex
		before writing the output to stderr.
	**/
	private function logMessage(message:String):Void {
		message = escapeMessageForLog(message);
		Sys.print('${addressString()} - - [${dateTimeStringForLog()}] ${message}\n');
	}

	private function escapeMessageForLog(message:String):String {
		var result = "";
		for (i in 0...message.length) {
			var charCode = message.charCodeAt(i);
			if (charCode < 0x20 || (charCode >= 0x7f && charCode < 0xa0)) {
				result += '\\x${StringTools.hex(charCode, 2)}';
			} else {
				result += String.fromCharCode(charCode);
			}
		}
		return result;
	}

	/**
		Return the server software version string.
	**/
	private function versionString():String {
		return '${serverVersion} ${sysVersion}';
	}

	/**
		Return the current date and time formatted for a message header.

		Format:

		```
		Date: <day-name>, <day> <month> <year> <hour>:<minute>:<second> GMT
		```

		@see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
	**/
	private function dateTimeString(?timestamp:Date):String {
		if (timestamp == null) {
			timestamp = Date.now();
		}
		var utcDayName = DATE_STRING_DAY_NAMES[timestamp.getUTCDay()];
		var utcDate = StringTools.lpad(Std.string(timestamp.getUTCDate()), "0", 2);
		var utcMonthName = DATE_STRING_MONTH_NAMES[timestamp.getUTCMonth()];
		var utcYear = timestamp.getUTCFullYear();
		var utcHours = StringTools.lpad(Std.string(timestamp.getUTCHours()), "0", 2);
		var utcMinutes = StringTools.lpad(Std.string(timestamp.getUTCMinutes()), "0", 2);
		var utcSeconds = StringTools.lpad(Std.string(timestamp.getUTCSeconds()), "0", 2);
		return '$utcDayName, $utcDate $utcMonthName $utcYear $utcHours:$utcMinutes:$utcSeconds GMT';
	}

	/**
		Return the current time formatted for logging.
	**/
	private function dateTimeStringForLog():String {
		return Date.now().toString();
	}

	/**
		Return the client address.
	**/
	private function addressString():String {
		return '${clientAddress.host.toString()}';
	}
}

private class HeaderParser {
	private static final MAX_HEADERS = 100;
	private static final MAX_LINE = 65536;

	public static function parseHeaders(input:Input):Map<String, String> {
		var headers = readHeaders(input);
		return parseHeaderLines(headers);
	}

	private static function readHeaders(input:Input):Array<String> {
		var headers:Array<String> = [];
		while (true) {
			var line = "";
			var lineLength = 0;
			var char:String = null;
			while (true) {
				char = input.readString(1);
				if (char == "\r") {
					continue;
				} else if (char == "\n") {
					break;
				} else {
					line += char;
					lineLength++;
					if (lineLength > MAX_LINE) {
						break;
					}
				}
			}
			if (lineLength > MAX_LINE) {
				throw new Exception("header line too long");
			}
			headers.push(line);
			if (headers.length > MAX_HEADERS) {
				throw new Exception('got more than ${MAX_HEADERS} headers');
			}
			if (line == "\r\n" || line == "\n" || line == "") {
				break;
			}
		}
		return headers;
	}

	private static function parseHeaderLines(headers:Array<String>):Map<String, String> {
		var result:Map<String, String> = [];
		for (header in headers) {
			if (header.length == 0) {
				return result;
			}
			var colonIndex = header.indexOf(":");
			if (colonIndex == -1) {
				// TODO: should probably do something more
				return result;
			}
			var name = StringTools.trim(header.substr(0, colonIndex));
			var value = StringTools.trim(header.substr(colonIndex + 1));
			result.set(name, value);
		}
		return result;
	}
}
