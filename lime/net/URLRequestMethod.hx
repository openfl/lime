package lime.net; #if !flash


@:enum abstract URLRequestMethod(String) {
	
	var DELETE = "DELETE";
	var GET = "GET";
	var HEAD = "HEAD";
	var OPTIONS = "OPTIONS";
	var POST = "POST";
	var PUT = "PUT";
	
}


#else
typedef URLRequestMethod = flash.net.URLRequestMethod;
#end