package lime.net;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
// Based on http://blog.stevenlevithan.com/archives/parseuri
class URIParser
{
	public static var URI_REGEX = ~/^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/;
	public static var QUERY_REGEX = ~/(?:^|&)([^&=]*)=?([^&]*)/;

	public var source:String;
	public var protocol:String;
	public var authority:String;
	public var userInfo:String;
	public var user:String;
	public var password:String;
	public var host:String;
	public var port:String;
	public var relative:String;
	public var path:String;
	public var directory:String;
	public var file:String;
	public var query:String;
	public var anchor:String;
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
