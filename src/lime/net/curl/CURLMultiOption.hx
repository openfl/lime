package lime.net.curl;

#if (!lime_doc_gen || lime_curl)
@:enum abstract CURLMultiOption(Int) from Int to Int from UInt to UInt
{
	/* This is the socket callback function pointer */
	var SOCKETFUNCTION = 200001;
	/* This is the argument passed to the socket callback */
	var SOCKETDATA = 100002;
	/* set to 1 to enable pipelining for this multi handle */
	var PIPELINING = 3;
	/* This is the timer callback function pointer */
	var TIMERFUNCTION = 20004;
	/* This is the argument passed to the timer callback */
	var TIMERDATA = 10005;
	/* maximum number of entries in the connection cache */
	var MAXCONNECTS = 6;
	/* maximum number of (pipelining) connections to one host */
	var MAX_HOST_CONNECTIONS = 7;
	/* maximum number of requests in a pipeline */
	var MAX_PIPELINE_LENGTH = 8;
	/* a connection with a content-length longer than this
		will not be considered for pipelining */
	var CONTENT_LENGTH_PENALTY_SIZE = 30009;
	/* a connection with a chunk length longer than this
		will not be considered for pipelining */
	var CHUNK_LENGTH_PENALTY_SIZE = 30010;
	/* a list of site names(+port) that are blacklisted from
		pipelining */
	var PIPELINING_SITE_BL = 10011;
	/* a list of server types that are blacklisted from
		pipelining */
	var PIPELINING_SERVER_BL = 10012;
	/* maximum number of open connections in total */
	var MAX_TOTAL_CONNECTIONS = 13;
	/* This is the server push callback function pointer */
	var PUSHFUNCTION = 20014;
	/* This is the argument passed to the server push callback */
	var PUSHDATA = 10015;
}
#end
