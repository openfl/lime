package lime.net.oauth; #if !flash


import haxe.crypto.Base64;
import haxe.crypto.Hmac;
import haxe.io.Bytes;
import lime.net.URLRequestMethod;
import lime.net.URLRequestHeader;
import lime.net.URLRequest;
import lime.net.oauth.OAuthToken;

using StringTools;

class OAuthRequest extends URLRequest {
	
	public var version:OAuthVersion = V1;
	public var parameters:Map<String, String>;
	
	
	public function new (version:OAuthVersion = V1, method:URLRequestMethod, url:String, parameters:Map<String, String>) {
		
		super(url);
		this.version = version;
		this.method = method;
		this.parameters = parameters;
		
	}
	
	
	public function getHeader ():URLRequestHeader {
		
		var result = "";

		switch(version) {

			case V1:
				result = "OAuth ";

				var keys = parameters.keys();
				for(key in keys) {
					result += '${key.urlEncode()}="${parameters.get(key).urlEncode()}"';
					if(keys.hasNext()) {
						result += ", ";
					}
				}

			case V2:
				// TODO
		}

		return new URLRequestHeader("Authorization", result);
		
	}
	
	/**
	 * Signs the petition, only for OAuth 1.0
	 */
	public function sign (consumer:OAuthConsumer, ?accessToken:OAuth1AccessToken, ?signatureMethod:OAuthSignatureMethod = HMAC_SHA1):Void {
		
		var key = consumer.secret.urlEncode() + "&";
		if(accessToken != null) {
			key += accessToken.secret == null ? "" : accessToken.secret.urlEncode();
		}
		var message = method + "&" + url.urlEncode() + "&" + messageParameters();
		var hash = new Hmac (SHA1);
		var bytes = hash.make (Bytes.ofString (key), Bytes.ofString (message));

		parameters.set("oauth_signature", Base64.encode (bytes));
	}
	
	// SIGNING FUNCTIONS

	/**
	 * Prepares the message parameters for the signing process
	 */
	private function messageParameters():String {

		var result = new Array<KVPair>();

		// TODO add get params if GET
		// TODO add data if POST

		for(key in parameters.keys()) {

			if(key == "realm") continue;
			result.push( { k: key, v: parameters.get(key) } );

		}


		result.sort(OAuthSort);

		return result.map(function(p:KVPair) return p.k.urlEncode()+"="+p.v.urlEncode()).join("&").urlEncode();
	}

	/**
	 * Parameters are sorted by name, using lexicographical byte value ordering.
	 * If two or more parameters share the same name, they are sorted by their value.
	 */
	private function OAuthSort(a:KVPair, b:KVPair) {
		return if(a.k < b.k) -1 else if (a.k > b.k) 1 else if (a.v < b.v) -1 else 1;
	}
	
}
#end
typedef KVPair = {k:String, v:String};