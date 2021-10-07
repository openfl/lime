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
		The original URI value from the constructor.
	**/
	public var source:String;

	/**
		In `"https://example.com/page/index.html"` this would be `"https"`.
		`null` if unspecified.
	**/
	public var protocol:String;

	/**
		In `"https://user:password@example.com:443/page/index.html"` this would be `"user:password@example.com:443"`.
		`null` if unspecified.
	**/
	public var authority:String;

	/**
		In `"https://user:password@example.com/page/index.html"` this would be `"user:password"`.
		`null` if unspecified.
	**/
	public var userInfo:String;

	/**
		In `"https://john:password@example.com/index.html"` this would be `"john"`.
		`null` if unspecified.
	**/
	public var user:String;

	/**
		In `"https://john:secret@example.com/index.html"` this would be `"secret"`.
		`null` if unspecified.
	**/
	public var password:String;

	/**
		Domain/hostname/IP in the address.
		In `"https://subdomain.example.com:443/index.html"` this would be `"subdomain.example.com"`
		`null` if unspecified.
	**/
	public var host:String;

	/**
		Port used in the address as **String**.
		In `"https://subdomain.example.com:443/index.html"` this would be `"443"`.
		`null` if unspecified.
	**/
	public var port:String;

	/**
		Full path after the domain with all the directories and parameters.
		In `"https://subdomain.example.com/files/website/index.php?action=upload&token=12345#header"`
		this would be `"/files/website/index.php?action=upload&token=12345#header"`.
		`null` if unspecified.
	**/
	public var relative:String;

	/**
		Full path after the domain with directories, without parameters.
		In `"https://subdomain.example.com/files/website/index.php?action=upload&token=12345#header"`
		this would be `"/files/website/index.php"`.
		`null` if unspecified.
	**/
	public var path:String;

	/**
		Directory where the target file lays.
		In `"https://subdomain.example.com/files/website/index.php"` this would be `"/files/website/"`.
		`null` if unspecified.
	**/
	public var directory:String;

	/**
		Name of the file pointed.
		In `"https://example.com/files/website/index.php?action=upload"` this would be `"index.php"`.
		`null` if unspecified.
	**/
	public var file:String;

	/**
		Query string passed.
		In `"https://example.com/index.php?action=upload&token=12345#header"`
		this would be `"action=upload&token=12345"`.
		`null` if unspecified.
	**/
	public var query:String;

	/**
		The "#hash" part of the query.
		In `"https://example.com/index.php?action=upload&token=12345#header"` this would be `"header"`.
		In a more sophisicated example `"https://example.com/index.php?action=upload#header=/abc/1234"`
		that would be `"header=/abc/1234"`.
		`null` if unspecified.
	**/
	public var anchor:String;

	/**
		Value from `query` returned as an array of key pair values.
		In `"https://example.com/index.php?action=upload&token=12345#header"` the array would contain
		`{k: "action", v: "upload"}, {k: "token", v: "12345"}`. If query is not present it is just an empty
		array.

		```haxe
		var uri = new URIParser("https://example.com/index.php?action=upload&token=12345#header");
		for( q in uri.queryArray )
			trace( q.k + " = " + q.v); 	// action = upload
										// token = 12345
		```
	**/
	public var queryArray:Array<KVPair>;

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
