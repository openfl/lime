package lime.net.oauth;

import haxe.crypto.Sha1;

// import lime.net.URLRequestMethod;
// import lime.net.URLRequest;
class OAuthClient
{
	public var version:OAuthVersion;
	public var consumer:OAuthConsumer;

	public function new(version:OAuthVersion, consumer:OAuthConsumer)
	{
		this.version = version;
		this.consumer = consumer;
	}

	// public function createRequest (method:URLRequestMethod, url:String):URLRequest {
	//
	// var parameters = new Map<String, String>();
	//
	// parameters.set("oauth_version", Std.string(version));
	// parameters.set("oauth_signature_method", Std.string(OAuthSignatureMethod.HMAC_SHA1));
	// parameters.set("oauth_nonce", generateNonce ());
	// parameters.set("oauth_timestamp", Std.string(Std.int(Date.now ().getTime () / 1000)));
	// parameters.set("oauth_consumer_key", consumer.key);
	//
	// var oauth = new OAuthRequest (version, method, url, parameters);
	// if(version == V1) oauth.sign (consumer, OAuthSignatureMethod.HMAC_SHA1);
	// oauth.request.requestHeaders.push(oauth.getHeader());
	// return oauth.request;
	//
	// }
	public function generateNonce():String
	{
		return Sha1.encode(Std.string(Math.random()));
	}
}
