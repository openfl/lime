package lime.net;

@:enum abstract HTTPRequestMethod(String) from String to String
{
	public var DELETE = "DELETE";
	public var GET = "GET";
	public var HEAD = "HEAD";
	public var OPTIONS = "OPTIONS";
	public var POST = "POST";
	public var PUT = "PUT";
}
