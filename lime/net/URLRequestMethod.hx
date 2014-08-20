package lime.net; #if !flash


@:enum abstract URLRequestMethod(String) {
	
	#if !console_pc
	var DELETE = "DELETE";
	#end
	var GET = "GET";
	var HEAD = "HEAD";
	#if !console_pc
	var OPTIONS = "OPTIONS";
	#end
	var POST = "POST";
	var PUT = "PUT";
	
}


#else
typedef URLRequestMethod = flash.net.URLRequestMethod;
#end