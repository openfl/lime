package lime.net.oauth;

class RequestToken
{
	public var token(default, null):String;
	public var secret(default, null):String;

	public function new(token:String, secret:String)
	{
		this.token = token;
		this.secret = secret;
	}
}

class AccessToken
{
	public var token(default, null):String;

	public function new(token:String)
	{
		this.token = token;
	}
}

class OAuth1AccessToken extends AccessToken
{
	public var secret(default, null):String;

	public function new(token:String, ?secret:String)
	{
		super(token);
		this.secret = secret;
	}
}

class OAuth2AccessToken extends AccessToken
{
	public var expires(default, null):Int = -1;

	public function new(token:String, ?expires:Int)
	{
		super(token);
		this.expires = expires;
	}
}

class RefreshToken
{
	public var token(default, null):String;

	public function new(token:String)
	{
		this.token = token;
	}
}
