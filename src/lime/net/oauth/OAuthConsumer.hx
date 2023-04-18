package lime.net.oauth;

class OAuthConsumer
{
	public var key:String;
	public var secret:String;

	public function new(key:String, secret:String)
	{
		this.key = key;
		this.secret = secret;
	}
}
