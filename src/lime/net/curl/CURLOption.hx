package lime.net.curl;

#if (!lime_doc_gen || lime_curl)
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract CURLOption(Int) from Int to Int from UInt to UInt

{
	// var FILE = 10001;
	// var WRITEDATA = 10001;
	var URL = 10002;
	var PORT = 3;
	var PROXY = 10004;
	var USERPWD = 10005;
	var PROXYUSERPWD = 10006;
	var RANGE = 10007;
	var INFILE = 10009;
	var READDATA = 10009;
	var ERRORBUFFER = 10010;
	var WRITEFUNCTION = 20011;
	var READFUNCTION = 20012;
	var TIMEOUT = 13;
	var INFILESIZE = 14;
	var POSTFIELDS = 10015;
	var REFERER = 10016;
	var FTPPORT = 10017;
	var USERAGENT = 10018;
	var LOW_SPEED_LIMIT = 19;
	var LOW_SPEED_TIME = 20;
	var RESUME_FROM = 21;
	var COOKIE = 22;
	var HTTPHEADER = 10023;
	var RTSPHEADER = 10023;
	var HTTPPOST = 10024;
	var SSLCERT = 10025;
	var KEYPASSWD = 10026;
	var CRLF = 27;
	var QUOTE = 10028;
	var WRITEHEADER = 10029;
	var HEADERDATA = 10029;
	var COOKIEFILE = 10031;
	var SSLVERSION = 32;
	var TIMECONDITION = 33;
	var TIMEVALUE = 34;
	var CUSTOMREQUEST = 10036;
	var STDERR = 10037;
	var POSTQUOTE = 10039;
	var WRITEINFO = 10040;
	var VERBOSE = 41;
	var HEADER = 42;
	var NOPROGRESS = 43;
	var NOBODY = 44;
	var FAILONERROR = 45;
	var UPLOAD = 46;
	var POST = 47;
	var DIRLISTONLY = 48;
	var APPEND = 50;
	var NETRC = 51;
	var FOLLOWLOCATION = 52;
	var TRANSFERTEXT = 53;
	var PUT = 54;
	var PROGRESSFUNCTION = 20056;
	var PROGRESSDATA = 10057;
	var XFERINFODATA = 10057;
	var AUTOREFERER = 58;
	var PROXYPORT = 59;
	var POSTFIELDSIZE = 60;
	var HTTPPROXYTUNNEL = 61;
	var INTERFACE = 10062;
	var KRBLEVEL = 10063;
	var SSL_VERIFYPEER = 64;
	var CAINFO = 10065;
	var MAXREDIRS = 68;
	var FILETIME = 69;
	var TELNETOPTIONS = 10070;
	var MAXCONNECTS = 71;
	var CLOSEPOLICY = 72;
	var FRESH_CONNECT = 74;
	var FORBID_REUSE = 75;
	var RANDOM_FILE = 10076;
	var EGDSOCKET = 10077;
	var CONNECTTIMEOUT = 78;
	var HEADERFUNCTION = 20079;
	var HTTPGET = 80;
	var SSL_VERIFYHOST = 81;
	var COOKIEJAR = 10082;
	var SSL_CIPHER_LIST = 10083;
	var HTTP_VERSION = 84;
	var FTP_USE_EPSV = 85;
	var SSLCERTTYPE = 10086;
	var SSLKEY = 10087;
	var SSLKEYTYPE = 10088;
	var SSLENGINE = 10089;
	var SSLENGINE_DEFAULT = 90;
	var DNS_USE_GLOBAL_CACHE = 91;
	var DNS_CACHE_TIMEOUT = 92;
	var PREQUOTE = 10093;
	var DEBUGFUNCTION = 20094;
	var DEBUGDATA = 10095;
	var COOKIESESSION = 96;
	var CAPATH = 10097;
	var BUFFERSIZE = 98;
	var NOSIGNAL = 99;
	var SHARE = 10100;
	var PROXYTYPE = 101;
	var ACCEPT_ENCODING = 10102;
	var PRIVATE = 10103;
	var HTTP200ALIASES = 10104;
	var UNRESTRICTED_AUTH = 105;
	var FTP_USE_EPRT = 106;
	var HTTPAUTH = 107;
	var SSL_CTX_FUNCTION = 20108;
	var SSL_CTX_DATA = 10109;
	var FTP_CREATE_MISSING_DIRS = 110;
	var PROXYAUTH = 111;
	var FTP_RESPONSE_TIMEOUT = 112;
	var SERVER_RESPONSE_TIMEOUT = 112;
	var IPRESOLVE = 113;
	var MAXFILESIZE = 114;
	var INFILESIZE_LARGE = 30115;
	var RESUME_FROM_LARGE = 30116;
	var MAXFILESIZE_LARGE = 30117;
	var NETRC_FILE = 10118;
	var USE_SSL = 119;
	var POSTFIELDSIZE_LARGE = 30120;
	var TCP_NODELAY = 121;
	var FTPSSLAUTH = 129;
	var IOCTLFUNCTION = 20130;
	var IOCTLDATA = 10131;
	var FTP_ACCOUNT = 10134;
	var COOKIELIST = 10135;
	var IGNORE_CONTENT_LENGTH = 10136;
	var FTP_SKIP_PASV_IP = 137;
	var FTP_FILEMETHOD = 138;
	var LOCALPORT = 139;
	var LOCALPORTRANGE = 140;
	var CONNECT_ONLY = 141;
	var CONV_FROM_NETWORK_FUNCTION = 20142;
	var CONV_TO_NETWORK_FUNCTION = 20143;
	var CONV_FROM_UTF8_FUNCTION = 20144;
	var MAX_SEND_SPEED_LARGE = 30145;
	var MAX_RECV_SPEED_LARGE = 30146;
	var FTP_ALTERNATIVE_TO_USER = 10147;
	var SOCKOPTFUNCTION = 20148;
	var SOCKOPTDATA = 10149;
	var SSL_SESSIONID_CACHE = 150;
	var SSH_AUTH_TYPES = 151;
	var SSH_PUBLIC_KEYFILE = 10152;
	var SSH_PRIVATE_KEYFILE = 10153;
	var FTP_SSL_CCC = 154;
	var TIMEOUT_MS = 155;
	var CONNECTTIMEOUT_MS = 156;
	var HTTP_TRANSFER_DECODING = 157;
	var HTTP_CONTENT_DECODING = 158;
	var NEW_FILE_PERMS = 159;
	var NEW_DIRECTORY_PERMS = 160;
	var POSTREDIR = 161;
	var SSH_HOST_PUBLIC_KEY_MD5 = 10162;
	var OPENSOCKETFUNCTION = 20163;
	var OPENSOCKETDATA = 10164;
	var COPYPOSTFIELDS = 10165;
	var PROXY_TRANSFER_MODE = 166;
	var SEEKFUNCTION = 20167;
	var SEEKDATA = 10168;
	var CRLFILE = 10169;
	var ISSUERCERT = 10170;
	var ADDRESS_SCOPE = 171;
	var CERTINFO = 172;
	var USERNAME = 10173;
	var PASSWORD = 10174;
	var PROXYUSERNAME = 10175;
	var PROXYPASSWORD = 10176;
	var NOPROXY = 10177;
	var TFTP_BLKSIZE = 178;
	var SOCKS5_GSSAPI_SERVICE = 10179;
	var SOCKS5_GSSAPI_NEC = 180;
	var PROTOCOLS = 181;
	var REDIR_PROTOCOLS = 182;
	var SSH_KNOWNHOSTS = 10183;
	var SSH_KEYFUNCTION = 20184;
	var SSH_KEYDATA = 10185;
	var MAIL_FROM = 10186;
	var MAIL_RCPT = 10187;
	var FTP_USE_PRET = 188;
	var RTSP_REQUEST = 189;
	var RTSP_SESSION_ID = 10190;
	var RTSP_STREAM_URI = 10191;
	var RTSP_TRANSPORT = 10192;
	var RTSP_CLIENT_CSEQ = 193;
	var RTSP_SERVER_CSEQ = 194;
	var INTERLEAVEDATA = 10195;
	var INTERLEAVEFUNCTION = 20196;
	var WILDCARDMATCH = 197;
	var CHUNK_BGN_FUNCTION = 20198;
	var CHUNK_END_FUNCTION = 20199;
	var FNMATCH_FUNCTION = 20200;
	var CHUNK_DATA = 10201;
	var FNMATCH_DATA = 10202;
	var RESOLVE = 10203;
	var TLSAUTH_USERNAME = 10204;
	var TLSAUTH_PASSWORD = 10205;
	var TLSAUTH_TYPE = 10206;
	var TRANSFER_ENCODING = 207;
	var CLOSESOCKETFUNCTION = 20208;
	var CLOSESOCKETDATA = 10209;
	var GSSAPI_DELEGATION = 210;
	var DNS_SERVERS = 10211;
	var ACCEPTTIMEOUT_MS = 212;
	var TCP_KEEPALIVE = 213;
	var TCP_KEEPIDLE = 214;
	var TCP_KEEPINTVL = 215;
	var SSL_OPTIONS = 216;
	var MAIL_AUTH = 10217;
	var SASL_IR = 218;
	var XFERINFOFUNCTION = 20219;
	var XOAUTH2_BEARER = 10220;
	var DNS_INTERFACE = 10221;
	var DNS_LOCAL_IP4 = 10222;
	var DNS_LOCAL_IP6 = 10223;
	var LOGIN_OPTIONS = 10224;
	var SSL_ENABLE_NPN = 225;
	var SSL_ENABLE_ALPN = 226;
	var EXPECT_100_TIMEOUT_MS = 227;
	var PROXYHEADER = 10228;
	var HEADEROPT = 229;
	var PINNEDPUBLICKEY = 10230;
	var UNIX_SOCKET_PATH = 10231;
	var SSL_VERIFYSTATUS = 232;
	var SSL_FALSESTART = 233;
	var PATH_AS_IS = 234;
	var PROXY_SERVICE_NAME = 10235;
	var SERVICE_NAME = 10236;
	var PIPEWAIT = 237;
	var DEFAULT_PROTOCOL = 10238;
	var STREAM_WEIGHT = 239;
	var STREAM_DEPENDS = 10240;
	var STREAM_DEPENDS_E = 10241;
	var TFTP_NO_OPTIONS = 242;
	var CONNECT_TO = 243;
	var TCP_FASTOPEN = 244;
	var KEEP_SENDING_ON_ERROR = 245;
	var PROXY_CAINFO = 10246;
	var PROXY_CAPATH = 10247;
	var PROXY_SSL_VERIFYPEER = 248;
	var PROXY_SSL_VERIFYHOST = 249;
	var PROXY_SSLVERSION = 250;
	var PROXY_TLSAUTH_USERNAME = 10251;
	var PROXY_TLSAUTH_PASSWORD = 10252;
	var PROXY_TLSAUTH_TYPE = 10253;
	var PROXY_SSLCERT = 10254;
	var PROXY_SSLCERTTYPE = 10255;
	var PROXY_SSLKEY = 10256;
	var PROXY_SSLKEYTYPE = 10257;
	var PROXY_KEYPASSWD = 10258;
	var PROXY_SSL_CIPHER_LIST = 10259;
	var PROXY_CRLFILE = 10260;
	var PROXY_SSL_OPTIONS = 261;
	var PRE_PROXY = 10262;
	var PROXY_PINNEDPUBLICKEY = 10263;
	var ABSTRACT_UNIX_SOCKET = 10264;
	var SUPPRESS_CONNECT_HEADERS = 265;
	var REQUEST_TARGET = 10266;
	var SOCKS5_AUTH = 267;
	var SSH_COMPRESSION = 268;
	var MIMEPOST = 10269;
}
#end
