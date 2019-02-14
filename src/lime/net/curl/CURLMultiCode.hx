package lime.net.curl;

#if (!lime_doc_gen || lime_curl)
@:enum abstract CURLMultiCode(Int) from Int to Int from UInt /*to UInt*/
{
	/* please call curl_multi_perform() or curl_multi_socket*() soon */
	var CALL_MULTI_PERFORM = -1;
	var OK = 0;
	/* the passed-in handle is not a valid CURLM handle */
	var BAD_HANDLE = 1;
	/* an easy handle was not good/valid */
	var BAD_EASY_HANDLE = 2;
	/* if you ever get this, you're in trouble */
	var OUT_OF_MEMORY = 3;
	/* this is a libcurl bug */
	var INTERNAL_ERROR = 4;
	/* the passed in socket argument did not match */
	var BAD_SOCKET = 5;
	/* curl_multi_setopt() with unsupported option */
	var UNKNOWN_OPTION = 6;
	/* an easy handle already added to a multi handle was attempted to get added - again */
	var ADDED_ALREADY = 7;
	// LAST
}
#end
