package lime.net;

/**
	Class used for parsing URIs and URLs.
	Based on http://blog.stevenlevithan.com/archives/parseuri
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class URIParser
{
	public static var URI_REGEX = ~/^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/;
	public static var QUERY_REGEX = ~/(?:^|&)([^&=]*)=?([^&]*)/;

	/**
		The original URI from the constructor if the parsing is successful.
		Otherwise `null`.
	**/
	public var source:String;

	/**
		Protocol found in this URI.
		In `"https://example.com/page/index.html"` this would be `"https"`.
		`null` if unspecified or malformed.
	**/
	public var protocol:String;

	/**
		Hostname and port along with the credentials found in this URI.
		In `"https://john:secret@example.com:443/page/index.html"` this would be `"john:secret@example.com:443"`.
		`null` if unspecified or malformed.
	**/
	public var authority:String;

	/**
		Credentials found in this URI.
		In `"https://john:secret@example.com/page/index.html"` this would be `"john:secret"`.
		`null` if unspecified or malformed.
	**/
	public var userInfo:String;

	/**
		Username found in this URI.
		In `"https://john:secret@example.com/index.html"` this would be `"john"`.
		`null` if unspecified or malformed.
	**/
	public var user:String;

	/**
		Password found in this URI.
		In `"https://john:secret@example.com/index.html"` this would be `"secret"`.
		`null` if unspecified or malformed.
	**/
	public var password:String;

	/**
		Hostname (domain/IP) found in this URI.
		In `"https://subdomain.example.com:443/index.html"` this would be `"subdomain.example.com"`
		`null` if unspecified or malformed.
	**/
	public var host:String;

	/**
		Port used in this URI as **String**.
		In `"https://subdomain.example.com:443/index.html"` this would be `"443"`.
		`null` if unspecified or malformed.
	**/
	public var port:String;

	/**
		Full path after the host with all the directories and parameters, starting with `/`.
		In `"https://subdomain.example.com/files/website/index.php?action=upload&token=12345#header"`
		this would be `"/files/website/index.php?action=upload&token=12345#header"`.
		`null` if unspecified or malformed.
	**/
	public var relative:String;

	/**
		Full path after the domain with directories, starting with `/`, without parameters
		In `"https://subdomain.example.com/files/website/index.php?action=upload&token=12345#header"`
		this would be `"/files/website/index.php"`.
		`null` if unspecified or malformed.
	**/
	public var path:String;

	/**
		Directory where the target file pointed by the URI is located. Starts and ends with `/`.
		In `"https://subdomain.example.com/files/website/index.php"` this would be `"/files/website/"`.
		`null` if unspecified or malformed.
	**/
	public var directory:String;

	/**
		Name of the file pointed by the URI.
		In `"https://example.com/files/website/index.php?action=upload"` this would be `"index.php"`.
		`null` if unspecified or malformed.
	**/
	public var file:String;

	/**
		Query string passed to the URI.
		In `"https://example.com/index.php?action=upload&token=12345#header"`
		this would be `"action=upload&token=12345"`.
		`null` if unspecified or malformed.
	**/
	public var query:String;

	/**
		The "#hash" part of the URI.
		In `"https://example.com/index.php?action=upload&token=12345#header"` this would be `"header"`.
		In a more sophisicated example `"https://example.com/index.php?action=upload#header=/abc/1234"`
		that would be `"header=/abc/1234"`.
		`null` if unspecified or malformed.
	**/
	public var anchor:String;

	/**
		Value from `query` returned as an array of key-value pairs.
		In `"https://example.com/index.php?action=upload&token=12345#header"` the array would be
		`[{k: "action", v: "upload"}, {k: "token", v: "12345"}]`. If query is not present or the URI
		is malformed, it is just an empty array.

		```haxe
		var uri = new URIParser("https://example.com/index.php?action=upload&token=12345#header");
		for( q in uri.queryArray )
			trace( q.k + " = " + q.v); // action = upload
									   // token = 12345
		```
	**/
	public var queryArray:Array<KVPair>;

	/**
		Parses the given URI with regular expression and stores its parts in class variables.
		If the URI is malformed and cannot be parsed, the values will be `null`.
		@param uri the URI to be parsed.
	**/
	public function new(uri:String)
	{
		if (URI_REGEX.match(uri))
		{
			source = uri;
			protocol = URI_REGEX.matched(1);
			authority = URI_REGEX.matched(2);
			userInfo = URI_REGEX.matched(3);
			user = URI_REGEX.matched(4);
			password = URI_REGEX.matched(5);
			host = URI_REGEX.matched(6);
			port = URI_REGEX.matched(7);
			relative = URI_REGEX.matched(8);
			path = URI_REGEX.matched(9);
			directory = URI_REGEX.matched(10);
			file = URI_REGEX.matched(11);
			query = URI_REGEX.matched(12);
			anchor = URI_REGEX.matched(13);

			if (query != null && query.length > 0)
			{
				queryArray = parseQuery(query);
			}
		}
		else
		{
			trace('URI "$uri" isn\'t well formed.');
		}
	}

	public static function parseQuery(query:String):Array<KVPair>
	{
		var result:Array<KVPair> = [];

		for (str in query.split("&"))
		{
			if (QUERY_REGEX.match(str))
			{
				result.push({k: QUERY_REGEX.matched(1), v: QUERY_REGEX.matched(2)});
			}
		}

		return result;
	}
}

@:dox(hide) typedef KVPair =
{
	k:String,
	v:String
};
