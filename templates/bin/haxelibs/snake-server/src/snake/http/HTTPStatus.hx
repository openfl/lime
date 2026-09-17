package snake.http;

/**
	HTTP status codes.
**/
class HTTPStatus {
	// informational

	/**
		[HTTP 100](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/100)
	**/
	public static final CONTINUE = new HTTPStatus(100, 'Continue');

	/**
		[HTTP 101](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/101)
	**/
	public static final SWITCHING_PROTOCOLS = new HTTPStatus(101, 'Switching Protocols');

	/**
		[HTTP 102](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/102)
	**/
	public static final PROCESSING = new HTTPStatus(102, 'Processing');

	/**
		[HTTP 103](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/103)
	**/
	public static final EARLY_HINTS = new HTTPStatus(103, 'Early Hints');

	// success

	/**
		[HTTP 200](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/200)
	**/
	public static final OK = new HTTPStatus(200, 'OK');

	/**
		[HTTP 201](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/201)
	**/
	public static final CREATED = new HTTPStatus(201, 'Created');

	/**
		[HTTP 202](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/202)
	**/
	public static final ACCEPTED = new HTTPStatus(202, 'Accepted');

	/**
		[HTTP 203](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/203)
	**/
	public static final NON_AUTHORITATIVE_INFORMATION = new HTTPStatus(203, 'Non-Authoritative Information');

	/**
		[HTTP 204](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/204)
	**/
	public static final NO_CONTENT = new HTTPStatus(204, 'No Content');

	/**
		[HTTP 205](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/205)
	**/
	public static final RESET_CONTENT = new HTTPStatus(205, 'Reset Content');

	/**
		[HTTP 206](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/206)
	**/
	public static final PARTIAL_CONTENT = new HTTPStatus(206, 'Partial Content');

	/**
		[HTTP 207](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/207)
	**/
	public static final MULTI_STATUS = new HTTPStatus(207, 'Multi-Status');

	/**
		[HTTP 208](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/208)
	**/
	public static final ALREADY_REPORTED = new HTTPStatus(208, 'Already Reported');

	/**
		[HTTP 226](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/226)
	**/
	public static final IM_USED = new HTTPStatus(226, 'IM Used');

	// redirection

	/**
		[HTTP 300](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/300)
	**/
	public static final MULTIPLE_CHOICES = new HTTPStatus(300, 'Multiple Choices');

	/**
		[HTTP 301](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/301)
	**/
	public static final MOVED_PERMANENTLY = new HTTPStatus(301, 'Moved Permanently');

	/**
		[HTTP 302](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/302)
	**/
	public static final FOUND = new HTTPStatus(302, 'Found');

	/**
		[HTTP 303](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/303)
	**/
	public static final SEE_OTHER = new HTTPStatus(303, 'See Other');

	/**
		[HTTP 304](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/304)
	**/
	public static final NOT_MODIFIED = new HTTPStatus(304, 'Not Modified');

	/**
		[HTTP 305](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/305)
	**/
	public static final USE_PROXY = new HTTPStatus(305, 'Use Proxy');

	/**
		[HTTP 307](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/307)
	**/
	public static final TEMPORARY_REDIRECT = new HTTPStatus(307, 'Temporary Redirect');

	/**
		[HTTP 308](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/308)
	**/
	public static final PERMANENT_REDIRECT = new HTTPStatus(308, 'Permanent Redirect');

	// client error

	/**
		[HTTP 400](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/400)
	**/
	public static final BAD_REQUEST = new HTTPStatus(400, 'Bad Request');

	/**
		[HTTP 401](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401)
	**/
	public static final UNAUTHORIZED = new HTTPStatus(401, 'Unauthorized');

	/**
		[HTTP 402](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/402)
	**/
	public static final PAYMENT_REQUIRED = new HTTPStatus(402, 'Payment Required');

	/**
		[HTTP 403](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/403)
	**/
	public static final FORBIDDEN = new HTTPStatus(403, 'Forbidden');

	/**
		[HTTP 404](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/404)
	**/
	public static final NOT_FOUND = new HTTPStatus(404, 'Not Found');

	/**
		[HTTP 405](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/405)
	**/
	public static final METHOD_NOT_ALLOWED = new HTTPStatus(405, 'Method Not Allowed');

	/**
		[HTTP 406](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/406)
	**/
	public static final NOT_ACCEPTABLE = new HTTPStatus(406, 'Not Acceptable');

	/**
		[HTTP 407](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/407)
	**/
	public static final PROXY_AUTHENTICATION_REQUIRED = new HTTPStatus(407, 'Proxy Authentication Required');

	/**
		[HTTP 408](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/408)
	**/
	public static final REQUEST_TIMEOUT = new HTTPStatus(408, 'Request Timeout');

	/**
		[HTTP 409](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/409)
	**/
	public static final CONFLICT = new HTTPStatus(409, 'Conflict');

	/**
		[HTTP 410](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/410)
	**/
	public static final GONE = new HTTPStatus(410, 'Gone');

	/**
		[HTTP 411](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/411)
	**/
	public static final LENGTH_REQUIRED = new HTTPStatus(411, 'Length Required');

	/**
		[HTTP 412](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/412)
	**/
	public static final PRECONDITION_FAILED = new HTTPStatus(412, 'Precondition Failed');

	/**
		[HTTP 413](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/413)
	**/
	public static final REQUEST_ENTITY_TOO_LARGE = new HTTPStatus(413, 'Request Entity Too Large');

	/**
		[HTTP 414](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/414)
	**/
	public static final REQUEST_URI_TOO_LONG = new HTTPStatus(414, 'Request-URI Too Long');

	/**
		[HTTP 415](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/415)
	**/
	public static final UNSUPPORTED_MEDIA_TYPE = new HTTPStatus(415, 'Unsupported Media Type');

	/**
		[HTTP 416](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/416)
	**/
	public static final REQUESTED_RANGE_NOT_SATISFIABLE = new HTTPStatus(416, 'Requested Range Not Satisfiable');

	/**
		[HTTP 417](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/417)
	**/
	public static final EXPECTATION_FAILED = new HTTPStatus(417, 'Expectation Failed');

	/**
		[HTTP 418](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/418)
	**/
	public static final IM_A_TEAPOT = new HTTPStatus(418, 'I\'m a Teapot');

	/**
		[HTTP 421](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/421)
	**/
	public static final MISDIRECTED_REQUEST = new HTTPStatus(421, 'Misdirected Request');

	/**
		[HTTP 422](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/422)
	**/
	public static final UNPROCESSABLE_ENTITY = new HTTPStatus(422, 'Unprocessable Entity');

	/**
		[HTTP 423](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/423)
	**/
	public static final LOCKED = new HTTPStatus(423, 'Locked');

	/**
		[HTTP 424](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/424)
	**/
	public static final FAILED_DEPENDENCY = new HTTPStatus(424, 'Failed Dependency');

	/**
		[HTTP 425](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/425)
	**/
	public static final TOO_EARLY = new HTTPStatus(425, 'Too Early');

	/**
		[HTTP 426](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/426)
	**/
	public static final UPGRADE_REQUIRED = new HTTPStatus(426, 'Upgrade Required');

	/**
		[HTTP 428](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/428)
	**/
	public static final PRECONDITION_REQUIRED = new HTTPStatus(428, 'Precondition Required');

	/**
		[HTTP 429](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429)
	**/
	public static final TOO_MANY_REQUESTS = new HTTPStatus(429, 'Too Many Requests');

	/**
		[HTTP 431](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/431)
	**/
	public static final REQUEST_HEADER_FIELDS_TOO_LARGE = new HTTPStatus(431, 'Request Header Fields Too Large');

	/**
		[HTTP 451](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/451)
	**/
	public static final UNAVAILABLE_FOR_LEGAL_REASONS = new HTTPStatus(451, 'Unavailable For Legal Reasons');

	// server errors

	/**
		[HTTP 500](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/500)
	**/
	public static final INTERNAL_SERVER_ERROR = new HTTPStatus(500, 'Internal Server Error');

	/**
		[HTTP 501](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/501)
	**/
	public static final NOT_IMPLEMENTED = new HTTPStatus(501, 'Not Implemented');

	/**
		[HTTP 502](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/502)
	**/
	public static final BAD_GATEWAY = new HTTPStatus(502, 'Bad Gateway');

	/**
		[HTTP 503](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/503)
	**/
	public static final SERVICE_UNAVAILABLE = new HTTPStatus(503, 'Service Unavailable');

	/**
		[HTTP 504](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/504)
	**/
	public static final GATEWAY_TIMEOUT = new HTTPStatus(504, 'Gateway Timeout');

	/**
		[HTTP 505](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/505)
	**/
	public static final HTTP_VERSION_NOT_SUPPORTED = new HTTPStatus(505, 'HTTP Version Not Supported');

	/**
		[HTTP 506](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/506)
	**/
	public static final VARIANT_ALSO_NEGOTIATES = new HTTPStatus(506, 'Variant Also Negotiates');

	/**
		[HTTP 507](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/507)
	**/
	public static final INSUFFICIENT_STORAGE = new HTTPStatus(507, 'Insufficient Storage');

	/**
		[HTTP 508](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/508)
	**/
	public static final LOOP_DETECTED = new HTTPStatus(508, 'Loop Detected');

	/**
		[HTTP 510](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/510)
	**/
	public static final NOT_EXTENDED = new HTTPStatus(510, 'Not Extended');

	/**
		[HTTP 511](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/511)
	**/
	public static final NETWORK_AUTHENTICATION_REQUIRED = new HTTPStatus(511, 'Network Authentication Required');

	/**
		The numeric HTTP status code.
	**/
	public var code:Int;

	/**
		The default message describing the HTTP status.
	**/
	public var message:String;

	private function new(code:Int, message:String) {
		this.code = code;
		this.message = message;
	}
}
