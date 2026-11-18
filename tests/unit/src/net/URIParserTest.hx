package net;

import lime.net.URIParser;
import utest.Assert;
import utest.Test;

/**
	Parts are expected as `URIParser`'s docs give them, and where the docs are
	silent, as RFC 3986 splits a URI up: an authority runs from `//` to the next
	`/`, `?` or `#`, and a part that isn't there is `null`.
**/
class URIParserTest extends Test
{
	public function new()
	{
		super();
	}

	public function testEveryPartOfAFullURI():Void
	{
		var source = "https://john:secret@subdomain.example.com:443/files/website/index.php?action=upload&token=12345#header";
		var uri = new URIParser(source);

		Assert.equals(source, uri.source);
		Assert.equals("https", uri.protocol);
		Assert.equals("john:secret@subdomain.example.com:443", uri.authority);
		Assert.equals("john:secret", uri.userInfo);
		Assert.equals("john", uri.user);
		Assert.equals("secret", uri.password);
		Assert.equals("subdomain.example.com", uri.host);
		Assert.equals("443", uri.port);
		Assert.equals("/files/website/index.php?action=upload&token=12345#header", uri.relative);
		Assert.equals("/files/website/index.php", uri.path);
		Assert.equals("/files/website/", uri.directory);
		Assert.equals("index.php", uri.file);
		Assert.equals("action=upload&token=12345", uri.query);
		Assert.equals("header", uri.anchor);
	}

	public function testQueryArrayHoldsEachPairInOrder():Void
	{
		var uri = new URIParser("https://example.com/index.php?action=upload&token=12345#header");
		Assert.same([{k: "action", v: "upload"}, {k: "token", v: "12345"}], uri.queryArray);
	}

	public function testFragmentKeepsSlashesAndEquals():Void
	{
		var uri = new URIParser("https://example.com/index.php?action=upload#header=/abc/1234");

		Assert.equals("action=upload", uri.query);
		Assert.equals("header=/abc/1234", uri.anchor);
		Assert.equals("/index.php", uri.path);
	}

	@Ignored("Waiting on #2144")
	public function testFragmentMayHoldAQuestionMark():Void
	{
		// RFC 3986 3.5: a fragment runs to the end and may contain "?"
		var uri = new URIParser("https://example.com/page#section?x=1");

		Assert.isNull(uri.query);
		Assert.equals("section?x=1", uri.anchor);
		Assert.same([], uri.queryArray);
	}

	public function testQueryMayHoldAQuestionMarkAndSlashes():Void
	{
		// RFC 3986 3.4: a query runs to "#" and may contain "?" and "/"
		var uri = new URIParser("https://example.com/search?q=a/b?c#top");

		Assert.equals("/search", uri.path);
		Assert.equals("q=a/b?c", uri.query);
		Assert.equals("top", uri.anchor);
	}

	@Ignored("Waiting on #2144")
	public function testMissingPartsAreNull():Void
	{
		var uri = new URIParser("https://example.com/index.html");

		Assert.equals("https", uri.protocol);
		Assert.equals("example.com", uri.authority);
		Assert.equals("example.com", uri.host);
		Assert.isNull(uri.userInfo, "userInfo");
		Assert.isNull(uri.user, "user");
		Assert.isNull(uri.password, "password");
		Assert.isNull(uri.port, "port");
		Assert.isNull(uri.query, "query");
		Assert.isNull(uri.anchor, "anchor");
		Assert.same([], uri.queryArray);
	}

	public function testHostAndPortWithoutAPath():Void
	{
		var uri = new URIParser("http://example.com:8080");

		Assert.equals("http", uri.protocol);
		Assert.equals("example.com:8080", uri.authority);
		Assert.equals("example.com", uri.host);
		Assert.equals("8080", uri.port);
		// RFC 3986 3.3: the path is there but empty
		Assert.isTrue(uri.path == null || uri.path == "", "path was " + uri.path);
		Assert.isTrue(uri.file == null || uri.file == "", "file was " + uri.file);
	}

	public function testHostWithoutAPathEndsAtTheQuery():Void
	{
		var uri = new URIParser("http://example.com?a=1#f");

		Assert.equals("example.com", uri.host);
		Assert.isNull(uri.port);
		Assert.equals("a=1", uri.query);
		Assert.equals("f", uri.anchor);
	}

	public function testUserWithoutAPassword():Void
	{
		var uri = new URIParser("ftp://anonymous@ftp.example.com/pub/file.txt");

		Assert.equals("anonymous", uri.userInfo);
		Assert.equals("anonymous", uri.user);
		Assert.isNull(uri.password);
		Assert.equals("ftp.example.com", uri.host);
		Assert.equals("/pub/", uri.directory);
		Assert.equals("file.txt", uri.file);
	}

	@Ignored("Waiting on #2144")
	public function testPasswordMayHoldAColon():Void
	{
		// RFC 3986 3.2.1: userinfo may contain ":"; the user name ends at the first
		var uri = new URIParser("https://john:pass:word@example.com/");

		Assert.equals("example.com", uri.host);
		Assert.equals("john:pass:word", uri.userInfo);
		Assert.equals("john", uri.user);
		Assert.equals("pass:word", uri.password);
	}

	@Ignored("Waiting on #2144")
	public function testAtSignInTheQueryIsNotUserInfo():Void
	{
		// RFC 3986 3.2: the authority ends at the first "/", "?" or "#"
		var uri = new URIParser("http://example.com/contact?email=john@example.org");

		Assert.equals("example.com", uri.host);
		Assert.equals("example.com", uri.authority);
		Assert.isNull(uri.userInfo);
		Assert.equals("/contact", uri.path);
		Assert.equals("email=john@example.org", uri.query);
	}

	@Ignored("Waiting on #2144")
	public function testAtSignInThePathIsNotUserInfo():Void
	{
		var uri = new URIParser("https://example.com/users/@john/profile");

		Assert.equals("example.com", uri.host);
		Assert.isNull(uri.userInfo);
		Assert.equals("/users/@john/profile", uri.path);
	}

	@Ignored("Waiting on #2144")
	public function testAtSignInTheFragmentIsNotUserInfo():Void
	{
		var uri = new URIParser("https://example.com#john@example.org");

		Assert.equals("example.com", uri.host);
		Assert.isNull(uri.userInfo);
		Assert.equals("john@example.org", uri.anchor);
	}

	public function testIPv4Host():Void
	{
		var uri = new URIParser("http://192.168.0.1:8000/status");

		Assert.equals("192.168.0.1", uri.host);
		Assert.equals("8000", uri.port);
		Assert.equals("/status", uri.path);
	}

	@Ignored("Waiting on #2144")
	public function testIPv6LiteralHost():Void
	{
		// RFC 3986 3.2.2: an IPv6 address is written in brackets, which are part
		// of the host; a host without them is accepted too
		var uri = new URIParser("http://[::1]:8080/index.html");

		Assert.isTrue(uri.host == "[::1]" || uri.host == "::1", "host was " + uri.host);
		Assert.equals("8080", uri.port);
		Assert.equals("[::1]:8080", uri.authority);
		Assert.equals("/index.html", uri.path);
	}

	@Ignored("Waiting on #2144")
	public function testIPv6LiteralHostWithoutAPort():Void
	{
		// From RFC 3986 1.1.2
		var uri = new URIParser("ldap://[2001:db8::7]/c=GB?objectClass?one");

		Assert.equals("ldap", uri.protocol);
		Assert.isTrue(uri.host == "[2001:db8::7]" || uri.host == "2001:db8::7", "host was " + uri.host);
		Assert.isNull(uri.port, "port");
		Assert.equals("/c=GB", uri.path);
		Assert.equals("objectClass?one", uri.query);
	}

	public function testSchemeMayHoldPlusDotAndDash():Void
	{
		// RFC 3986 3.1
		var uri = new URIParser("svn+ssh://example.com/repo");

		Assert.equals("svn+ssh", uri.protocol);
		Assert.equals("example.com", uri.host);
		Assert.equals("/repo", uri.path);
	}

	public function testURIsWithoutAnAuthority():Void
	{
		// From RFC 3986 1.1.2
		var mail = new URIParser("mailto:John.Doe@example.com");
		Assert.equals("mailto", mail.protocol);
		Assert.isNull(mail.authority, "mailto authority");
		Assert.isNull(mail.host, "mailto host");
		Assert.isNull(mail.userInfo, "mailto userInfo");
		Assert.equals("John.Doe@example.com", mail.path);

		var urn = new URIParser("urn:oasis:names:specification:docbook:dtd:xml:4.1.2");
		Assert.equals("urn", urn.protocol);
		Assert.isNull(urn.host, "urn host");
		Assert.equals("oasis:names:specification:docbook:dtd:xml:4.1.2", urn.path);

		var tel = new URIParser("tel:+1-816-555-1212");
		Assert.equals("tel", tel.protocol);
		Assert.equals("+1-816-555-1212", tel.path);
	}

	public function testFileURIWithAnEmptyHost():Void
	{
		var uri = new URIParser("file:///home/user/notes.txt");

		Assert.equals("file", uri.protocol);
		Assert.isTrue(uri.host == null || uri.host == "", "host was " + uri.host);
		Assert.equals("/home/user/notes.txt", uri.path);
		Assert.equals("/home/user/", uri.directory);
		Assert.equals("notes.txt", uri.file);
	}

	public function testNetworkPathReference():Void
	{
		// RFC 3986 4.2: a reference starting with "//" has an authority but no scheme
		var uri = new URIParser("//cdn.example.com/lib/app.js");

		Assert.isNull(uri.protocol, "protocol");
		Assert.equals("cdn.example.com", uri.host);
		Assert.equals("/lib/app.js", uri.path);
		Assert.equals("app.js", uri.file);
	}

	public function testAbsolutePathReference():Void
	{
		var uri = new URIParser("/images/icons/logo.png?size=2#top");

		Assert.isNull(uri.protocol, "protocol");
		Assert.isNull(uri.authority, "authority");
		Assert.isNull(uri.host, "host");
		Assert.equals("/images/icons/logo.png?size=2#top", uri.relative);
		Assert.equals("/images/icons/logo.png", uri.path);
		Assert.equals("/images/icons/", uri.directory);
		Assert.equals("logo.png", uri.file);
		Assert.equals("size=2", uri.query);
		Assert.equals("top", uri.anchor);
	}

	public function testRelativePathReference():Void
	{
		var uri = new URIParser("../images/logo.png");

		Assert.isNull(uri.protocol, "protocol");
		Assert.isNull(uri.host, "host");
		Assert.equals("../images/logo.png", uri.path);
		Assert.equals("../images/", uri.directory);
		Assert.equals("logo.png", uri.file);
	}

	public function testRelativePathWithAColonAfterTheFirstSegment():Void
	{
		// RFC 3986 4.2: "./" keeps a colon in the path from being read as a scheme
		var uri = new URIParser("./this:that");

		Assert.isNull(uri.protocol, "protocol");
		Assert.equals("./this:that", uri.path);
		Assert.equals("this:that", uri.file);
	}

	public function testQueryOnlyReference():Void
	{
		var uri = new URIParser("?page=2");

		Assert.isNull(uri.protocol, "protocol");
		Assert.isNull(uri.host, "host");
		Assert.equals("page=2", uri.query);
		Assert.same([{k: "page", v: "2"}], uri.queryArray);
	}

	public function testFragmentOnlyReference():Void
	{
		var uri = new URIParser("#section-2");

		Assert.isNull(uri.protocol, "protocol");
		Assert.isNull(uri.query, "query");
		Assert.equals("section-2", uri.anchor);
	}

	@Ignored("Waiting on #2144")
	public function testEmptyQueryAndFragmentAreNotMissing():Void
	{
		// RFC 3986 6.2.3: "?" and "#" with nothing after them are empty parts,
		// which are kept apart from parts that aren't there
		var uri = new URIParser("http://example.com/?#");

		Assert.equals("", uri.query);
		Assert.equals("", uri.anchor);
		Assert.same([], uri.queryArray);
	}

	public function testParseQuerySplitsPairsInOrder():Void
	{
		Assert.same([{k: "a", v: "1"}, {k: "b", v: "2"}], URIParser.parseQuery("a=1&b=2"));
	}

	public function testParseQueryKeepsRepeatedKeys():Void
	{
		Assert.same([{k: "a", v: "1"}, {k: "a", v: "2"}], URIParser.parseQuery("a=1&a=2"));
	}

	public function testParseQueryGivesKeysWithoutValuesAnEmptyValue():Void
	{
		Assert.same([{k: "flag", v: ""}, {k: "a", v: "1"}, {k: "b", v: ""}], URIParser.parseQuery("flag&a=1&b="));
	}

	public function testParseQuerySplitsAtTheFirstEquals():Void
	{
		// As URLSearchParams does
		Assert.same([{k: "expr", v: "x=1"}], URIParser.parseQuery("expr=x=1"));
	}

	@Ignored("Waiting on #2144")
	public function testParseQueryOfAnEmptyQueryIsEmpty():Void
	{
		Assert.same([], URIParser.parseQuery(""));
	}
}
