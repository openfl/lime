#include <curl/curl.h>
#include <hx/CFFI.h>
#include <string.h>


namespace lime {
	
	
	value lime_curl_easy_cleanup (value handle) {
		
		curl_easy_cleanup ((CURL*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_curl_easy_duphandle (value handle) {
		
		return alloc_float ((intptr_t)curl_easy_duphandle ((CURL*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_curl_easy_escape (value curl, value url, value length) {
		
		char* result = curl_easy_escape ((CURL*)(intptr_t)val_float (curl), val_string (url), val_int (length));
		
		value str = alloc_string (result);
		curl_free (result);
		return str;
		
	}
	
	
	value lime_curl_easy_getinfo (value curl, value info) {
		
		CURLcode code = CURLE_OK;
		CURL* handle = (CURL*)(intptr_t)val_float (curl);
		CURLINFO type = (CURLINFO)val_int (info);
		
		switch (type) {
			
			case CURLINFO_EFFECTIVE_URL:
			case CURLINFO_REDIRECT_URL:
			case CURLINFO_CONTENT_TYPE:
			case CURLINFO_PRIVATE:
			case CURLINFO_PRIMARY_IP:
			case CURLINFO_LOCAL_IP:
			case CURLINFO_FTP_ENTRY_PATH:
			case CURLINFO_RTSP_SESSION_ID:
				
				char stringValue;
				code = curl_easy_getinfo (handle, type, &stringValue);
				return alloc_string (&stringValue);
				break;
			
			case CURLINFO_RESPONSE_CODE:
			case CURLINFO_HTTP_CONNECTCODE:
			case CURLINFO_FILETIME:
			case CURLINFO_REDIRECT_COUNT:
			case CURLINFO_HEADER_SIZE:
			case CURLINFO_REQUEST_SIZE:
			case CURLINFO_SSL_VERIFYRESULT:
			case CURLINFO_HTTPAUTH_AVAIL:
			case CURLINFO_PROXYAUTH_AVAIL:
			case CURLINFO_OS_ERRNO:
			case CURLINFO_NUM_CONNECTS:
			case CURLINFO_PRIMARY_PORT:
			case CURLINFO_LOCAL_PORT:
			case CURLINFO_LASTSOCKET:
			case CURLINFO_CONDITION_UNMET:
			case CURLINFO_RTSP_CLIENT_CSEQ:
			case CURLINFO_RTSP_SERVER_CSEQ:
			case CURLINFO_RTSP_CSEQ_RECV:
				
				long intValue;
				code = curl_easy_getinfo (handle, type, &intValue);
				return alloc_int (intValue);
				break;
			
			case CURLINFO_TOTAL_TIME:
			case CURLINFO_NAMELOOKUP_TIME:
			case CURLINFO_CONNECT_TIME:
			case CURLINFO_APPCONNECT_TIME:
			case CURLINFO_PRETRANSFER_TIME:
			case CURLINFO_STARTTRANSFER_TIME:
			case CURLINFO_REDIRECT_TIME:
			case CURLINFO_SIZE_UPLOAD:
			case CURLINFO_SIZE_DOWNLOAD:
			case CURLINFO_SPEED_DOWNLOAD:
			case CURLINFO_SPEED_UPLOAD:
			case CURLINFO_CONTENT_LENGTH_DOWNLOAD:
			case CURLINFO_CONTENT_LENGTH_UPLOAD:
				
				double floatValue;
				code = curl_easy_getinfo (handle, type, &floatValue);
				return alloc_float (floatValue);
				break;
			
			case CURLINFO_SSL_ENGINES:
			case CURLINFO_COOKIELIST:
			case CURLINFO_CERTINFO:
			case CURLINFO_TLS_SESSION:
				
				// todo
				break;
			
			case CURLINFO_NONE:
			case CURLINFO_LASTONE:
				
				// ignore
				break;
			
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_curl_easy_init () {
		
		return alloc_float ((intptr_t)curl_easy_init ());
		
	}
	
	
	value lime_curl_easy_pause (value handle, value bitmask) {
		
		return alloc_int ((int)curl_easy_pause ((CURL*)(intptr_t)val_float (handle), val_int (bitmask)));
		
	}
	
	
	value lime_curl_easy_perform (value easy_handle) {
		
		return alloc_int ((int)curl_easy_perform ((CURL*)(intptr_t)val_float (easy_handle)));
		
	}
	
	
	value lime_curl_easy_recv (value curl, value buffer, value buflen, value n) {
		
		// todo
		return alloc_null ();
		
	}
	
	
	value lime_curl_easy_reset (value curl) {
		
		curl_easy_reset ((CURL*)(intptr_t)val_float (curl));
		return alloc_null ();
		
	}
	
	
	value lime_curl_easy_send (value curl, value buffer, value buflen, value n) {
		
		// todo
		return alloc_null ();
		
	}
	
	
	static size_t write_callback (void *ptr, size_t size, size_t nmemb, void *userp) {
		
		AutoGCRoot* callback = (AutoGCRoot*)userp;
		
		if (size * nmemb < 1) {
			
			return 0;
			
		}
		
		value str = alloc_string_len ((const char*)ptr, size * nmemb);
		return val_int (val_call3 (callback->get (), str, alloc_int (size), alloc_int (nmemb)));
		
	}

	static size_t read_callback (void *buffer, size_t size, size_t nmemb, void *userp) {
		
		AutoGCRoot* callback = (AutoGCRoot*)userp;

		size_t bytes = size * nmemb;
		const char *input = val_string (val_call1 (callback->get (), alloc_int (bytes)));
		size_t length = strlen(input);

		if(length <= bytes) bytes = length;

		memcpy(buffer, input, bytes);

		return bytes;
		
	}	

	static size_t progress_callback (void *userp, double dltotal, double dlnow, double ultotal, double ulnow) {

		AutoGCRoot* callback = (AutoGCRoot*)userp;

		value vals[] = {
			alloc_float(dltotal),
			alloc_float(dlnow),
			alloc_float(ultotal),
			alloc_float(ulnow),
		};

		return val_int (val_callN (callback->get (), vals, 4));

	}
	
	
	value lime_curl_easy_setopt (value handle, value option, value parameter) {
		
		CURLcode code = CURLE_OK;
		CURL* curl = (CURL*)(intptr_t)val_float (handle);
		CURLoption type = (CURLoption)val_int (option);
		
		switch (type) {
			
			case CURLOPT_VERBOSE:
			case CURLOPT_HEADER:
			case CURLOPT_NOPROGRESS:
			case CURLOPT_NOSIGNAL:
			case CURLOPT_WILDCARDMATCH:
			case CURLOPT_FAILONERROR:
			case CURLOPT_DNS_USE_GLOBAL_CACHE:
			case CURLOPT_TCP_NODELAY:
			case CURLOPT_TCP_KEEPALIVE:
			case CURLOPT_SASL_IR:
			case CURLOPT_AUTOREFERER:
			case CURLOPT_TRANSFER_ENCODING:
			case CURLOPT_FOLLOWLOCATION:
			case CURLOPT_UNRESTRICTED_AUTH:
			case CURLOPT_PUT:
			case CURLOPT_POST:
			case CURLOPT_COOKIESESSION:
			case CURLOPT_HTTPGET:
			case CURLOPT_IGNORE_CONTENT_LENGTH:
			case CURLOPT_HTTP_CONTENT_DECODING:
			case CURLOPT_HTTP_TRANSFER_DECODING:
			case CURLOPT_DIRLISTONLY:
			case CURLOPT_APPEND:
			case CURLOPT_FTP_USE_EPRT:
			case CURLOPT_FTP_USE_EPSV:
			case CURLOPT_FTP_USE_PRET:
			case CURLOPT_FTP_CREATE_MISSING_DIRS:
			case CURLOPT_FTP_SKIP_PASV_IP:
			case CURLOPT_TRANSFERTEXT:
			case CURLOPT_CRLF:
			case CURLOPT_NOBODY:
			case CURLOPT_UPLOAD:
			case CURLOPT_FRESH_CONNECT:
			case CURLOPT_FORBID_REUSE:
			case CURLOPT_CONNECT_ONLY:
			case CURLOPT_USE_SSL:
			//case CURLOPT_SSL_ENABLE_ALPN:
			//case CURLOPT_SSL_ENABLE_NPN:
			case CURLOPT_SSL_VERIFYPEER:
			case CURLOPT_SSL_VERIFYHOST:
			case CURLOPT_SSL_SESSIONID_CACHE:
				
				code = curl_easy_setopt (curl, type, val_bool (parameter));
				break;
				
			case CURLOPT_PROTOCOLS:
			case CURLOPT_REDIR_PROTOCOLS:
			case CURLOPT_PROXYPORT:
			case CURLOPT_PROXYTYPE:
			case CURLOPT_HTTPPROXYTUNNEL:
			case CURLOPT_SOCKS5_GSSAPI_NEC:
			case CURLOPT_LOCALPORT:
			case CURLOPT_LOCALPORTRANGE:
			case CURLOPT_DNS_CACHE_TIMEOUT:
			case CURLOPT_BUFFERSIZE:
			case CURLOPT_PORT:
			case CURLOPT_ADDRESS_SCOPE:
			case CURLOPT_TCP_KEEPIDLE:
			case CURLOPT_TCP_KEEPINTVL:
			case CURLOPT_NETRC:
			case CURLOPT_HTTPAUTH:
			case CURLOPT_PROXYAUTH:
			case CURLOPT_MAXREDIRS:
			case CURLOPT_POSTREDIR:
			case CURLOPT_POSTFIELDSIZE:
			//case CURLOPT_HEADEROPT:
			case CURLOPT_HTTP_VERSION:
			//case CURLOPT_EXPECT_100_TIMEOUT_MS:
			case CURLOPT_TFTP_BLKSIZE:
			case CURLOPT_FTP_RESPONSE_TIMEOUT:
			case CURLOPT_FTPSSLAUTH:
			case CURLOPT_FTP_SSL_CCC:
			case CURLOPT_FTP_FILEMETHOD:
			case CURLOPT_RTSP_REQUEST:
			case CURLOPT_RTSP_CLIENT_CSEQ:
			case CURLOPT_RTSP_SERVER_CSEQ:
			case CURLOPT_PROXY_TRANSFER_MODE:
			case CURLOPT_RESUME_FROM:
			case CURLOPT_FILETIME:
			case CURLOPT_INFILESIZE:
			case CURLOPT_MAXFILESIZE:
			case CURLOPT_TIMECONDITION:
			case CURLOPT_TIMEVALUE:
			case CURLOPT_TIMEOUT:
			case CURLOPT_TIMEOUT_MS:
			case CURLOPT_LOW_SPEED_LIMIT:
			case CURLOPT_LOW_SPEED_TIME:
			case CURLOPT_MAXCONNECTS:
			case CURLOPT_CONNECTTIMEOUT:
			case CURLOPT_CONNECTTIMEOUT_MS:
			case CURLOPT_IPRESOLVE:
			case CURLOPT_ACCEPTTIMEOUT_MS:
			case CURLOPT_SSLENGINE_DEFAULT:
			case CURLOPT_SSLVERSION:
			case CURLOPT_CERTINFO:
			case CURLOPT_SSL_OPTIONS:
			case CURLOPT_GSSAPI_DELEGATION:
			case CURLOPT_SSH_AUTH_TYPES:
			case CURLOPT_NEW_FILE_PERMS:
			case CURLOPT_NEW_DIRECTORY_PERMS:
				
				code = curl_easy_setopt (curl, type, val_int (parameter));
				break;
			
			case CURLOPT_POSTFIELDSIZE_LARGE:
			case CURLOPT_RESUME_FROM_LARGE:
			case CURLOPT_INFILESIZE_LARGE:
			case CURLOPT_MAXFILESIZE_LARGE:
			case CURLOPT_MAX_SEND_SPEED_LARGE:
			case CURLOPT_MAX_RECV_SPEED_LARGE:
				
				code = curl_easy_setopt (curl, type, val_float (parameter));
				break;
			
			case CURLOPT_ERRORBUFFER:
			case CURLOPT_URL:
			case CURLOPT_PROXY:
			case CURLOPT_NOPROXY:
			case CURLOPT_SOCKS5_GSSAPI_SERVICE:
			case CURLOPT_INTERFACE:
			case CURLOPT_NETRC_FILE:
			case CURLOPT_USERPWD:
			case CURLOPT_PROXYUSERPWD:
			case CURLOPT_USERNAME:
			case CURLOPT_PASSWORD:
			case CURLOPT_LOGIN_OPTIONS:
			case CURLOPT_PROXYUSERNAME:
			case CURLOPT_PROXYPASSWORD:
			case CURLOPT_TLSAUTH_USERNAME:
			case CURLOPT_TLSAUTH_PASSWORD:
			case CURLOPT_XOAUTH2_BEARER:
			case CURLOPT_ACCEPT_ENCODING:
			case CURLOPT_POSTFIELDS:
			case CURLOPT_COPYPOSTFIELDS:
			case CURLOPT_REFERER:
			case CURLOPT_USERAGENT:
			case CURLOPT_COOKIE:
			case CURLOPT_COOKIEFILE:
			case CURLOPT_COOKIEJAR:
			case CURLOPT_COOKIELIST:
			case CURLOPT_MAIL_FROM:
			case CURLOPT_MAIL_AUTH:
			case CURLOPT_FTPPORT:
			case CURLOPT_FTP_ALTERNATIVE_TO_USER:
			case CURLOPT_FTP_ACCOUNT:
			case CURLOPT_RTSP_SESSION_ID:
			case CURLOPT_RTSP_STREAM_URI:
			case CURLOPT_RTSP_TRANSPORT:
			case CURLOPT_RANGE:
			case CURLOPT_CUSTOMREQUEST:
			case CURLOPT_DNS_INTERFACE:
			case CURLOPT_DNS_LOCAL_IP4:
			case CURLOPT_DNS_LOCAL_IP6:
			case CURLOPT_SSLCERT:
			case CURLOPT_SSLCERTTYPE:
			case CURLOPT_SSLKEY:
			case CURLOPT_SSLKEYTYPE:
			case CURLOPT_KEYPASSWD:
			case CURLOPT_SSLENGINE:
			case CURLOPT_CAINFO:
			case CURLOPT_ISSUERCERT:
			case CURLOPT_CAPATH:
			case CURLOPT_CRLFILE:
			case CURLOPT_RANDOM_FILE:
			case CURLOPT_EGDSOCKET:
			case CURLOPT_SSL_CIPHER_LIST:
			case CURLOPT_KRBLEVEL:
			case CURLOPT_SSH_HOST_PUBLIC_KEY_MD5:
			case CURLOPT_SSH_PUBLIC_KEYFILE:
			case CURLOPT_SSH_PRIVATE_KEYFILE:
			case CURLOPT_SSH_KNOWNHOSTS:
				
				code = curl_easy_setopt (curl, type, val_string (parameter));
				break;
			
			case CURLOPT_IOCTLFUNCTION:
			case CURLOPT_IOCTLDATA:
			case CURLOPT_SEEKFUNCTION:
			case CURLOPT_SEEKDATA:
			case CURLOPT_SOCKOPTFUNCTION:
			case CURLOPT_SOCKOPTDATA:
			case CURLOPT_OPENSOCKETFUNCTION:
			case CURLOPT_OPENSOCKETDATA:
			case CURLOPT_CLOSESOCKETFUNCTION:
			case CURLOPT_CLOSESOCKETDATA:
			case CURLOPT_XFERINFOFUNCTION:
			//case CURLOPT_XFERINFODATA:
			case CURLOPT_DEBUGFUNCTION:
			case CURLOPT_DEBUGDATA:
			case CURLOPT_SSL_CTX_FUNCTION:
			case CURLOPT_SSL_CTX_DATA:
			case CURLOPT_CONV_TO_NETWORK_FUNCTION:
			case CURLOPT_CONV_FROM_NETWORK_FUNCTION:
			case CURLOPT_CONV_FROM_UTF8_FUNCTION:
			case CURLOPT_INTERLEAVEFUNCTION:
			case CURLOPT_INTERLEAVEDATA:
			case CURLOPT_CHUNK_BGN_FUNCTION:
			case CURLOPT_CHUNK_END_FUNCTION:
			case CURLOPT_CHUNK_DATA:
			case CURLOPT_FNMATCH_FUNCTION:
			case CURLOPT_FNMATCH_DATA:
			case CURLOPT_STDERR:
			case CURLOPT_HTTPPOST:
			//case CURLOPT_PROXYHEADER:
			case CURLOPT_HTTP200ALIASES:
			case CURLOPT_MAIL_RCPT:
			case CURLOPT_QUOTE:
			case CURLOPT_POSTQUOTE:
			case CURLOPT_PREQUOTE:
			case CURLOPT_RESOLVE:
			case CURLOPT_SSH_KEYFUNCTION:
			case CURLOPT_SSH_KEYDATA:
			case CURLOPT_PRIVATE:
			case CURLOPT_SHARE:
			case CURLOPT_TELNETOPTIONS:
				
				//todo
				break;
			
			//case CURLOPT_READDATA:
			//case CURLOPT_WRITEDATA:
			//case CURLOPT_HEADERDATA:
			//case CURLOPT_PROGRESSDATA:

			case CURLOPT_READFUNCTION:
			{
				AutoGCRoot* callback = new AutoGCRoot (parameter);
				code = curl_easy_setopt (curl, type, read_callback);
				curl_easy_setopt (curl, CURLOPT_READDATA, callback);
				break;
			}
			case CURLOPT_WRITEFUNCTION:
			{
				AutoGCRoot* callback = new AutoGCRoot (parameter);
				code = curl_easy_setopt (curl, type, write_callback);
				curl_easy_setopt (curl, CURLOPT_WRITEDATA, callback);
				break;
			}
			case CURLOPT_HEADERFUNCTION:
			{
				AutoGCRoot* callback = new AutoGCRoot (parameter);
				code = curl_easy_setopt (curl, type, write_callback);
				curl_easy_setopt (curl, CURLOPT_HEADERDATA, callback);
				break;
			}
			case CURLOPT_PROGRESSFUNCTION:
			{
				AutoGCRoot* callback = new AutoGCRoot (parameter);
				code = curl_easy_setopt (curl, type, progress_callback);
				curl_easy_setopt (curl, CURLOPT_PROGRESSDATA, callback);
				curl_easy_setopt (curl, CURLOPT_NOPROGRESS, false);
				break;
			}
			
			case CURLOPT_HTTPHEADER:
			{
				struct curl_slist *chunk = NULL;
				int size = val_array_size (parameter);
				
				for (int i = 0; i < size; i++) {
					
					chunk = curl_slist_append (chunk, val_string (val_array_i (parameter, i)));
					
				}
				
				code = curl_easy_setopt (curl, type, chunk);
				break;
			}
			
			default:
			
				break;
			
		}
		
		return alloc_int (code);                 
		
	}
	
	
	value lime_curl_easy_strerror (value errornum) {
		
		const char* result = curl_easy_strerror ((CURLcode)val_int (errornum));
		
		value str = alloc_string (result);
		curl_free ((void*)result);
		return str;
		
	}
	
	
	value lime_curl_easy_unescape (value curl, value url, value inlength, value outlength) {
		
		int length = val_int (outlength);
		char* result = curl_easy_unescape ((CURL*)(intptr_t)val_float (curl), val_string (url), val_int (inlength), &length);
		
		value str = alloc_string (result);
		curl_free (result);
		return str;
		
	}
	
	
	//lime_curl_formadd;
	//lime_curl_formfree;
	//lime_curl_formget;
	
	
	value lime_curl_getdate (value datestring, value now) {
		
		time_t time = (time_t)val_float (now);
		return alloc_float (curl_getdate (val_string (datestring), &time));
		
	}
	
	
	value lime_curl_global_cleanup () {
		
		curl_global_cleanup ();
		return alloc_null ();
		
	}
	
	
	value lime_curl_global_init (value flags) {
		
		return alloc_int (curl_global_init (val_int (flags)));
		
	}
	
	
	//lime_curl_multi_add_handle
	//lime_curl_multi_assign
	//lime_curl_multi_cleanup
	//lime_curl_multi_fdset
	//lime_curl_multi_info_read
	//lime_curl_multi_init
	//lime_curl_multi_perform
	//lime_curl_multi_remove_handle
	//lime_curl_multi_setopt
	//lime_curl_multi_socket
	//lime_curl_multi_socket_action
	//lime_curl_multi_strerror
	//lime_curl_multi_timeout
	
	//lime_curl_share_cleanup
	//lime_curl_share_init
	//lime_curl_share_setopt
	//lime_curl_share_strerror
	
	//lime_curl_slist_append 
	//lime_curl_slist_free_all
	
	
	value lime_curl_version () {
		
		char* result = curl_version ();
		
		value str = alloc_string (result);
		curl_free (result);
		return str;
		
	}
	
	
	value lime_curl_version_info (value type) {
		
		curl_version_info_data* data = curl_version_info ((CURLversion)val_int (type));
		
		//todo
		
		return alloc_null ();
		
	}
	
	
	DEFINE_PRIM (lime_curl_easy_cleanup, 1);
	DEFINE_PRIM (lime_curl_easy_duphandle, 1);
	DEFINE_PRIM (lime_curl_easy_escape, 3);
	DEFINE_PRIM (lime_curl_easy_getinfo, 2);
	DEFINE_PRIM (lime_curl_easy_init, 0);
	DEFINE_PRIM (lime_curl_easy_pause, 2);
	DEFINE_PRIM (lime_curl_easy_perform, 1);
	DEFINE_PRIM (lime_curl_easy_recv, 4);
	DEFINE_PRIM (lime_curl_easy_reset, 1);
	DEFINE_PRIM (lime_curl_easy_send, 4);
	DEFINE_PRIM (lime_curl_easy_setopt, 3);
	DEFINE_PRIM (lime_curl_easy_strerror, 1);
	DEFINE_PRIM (lime_curl_easy_unescape, 4);
	DEFINE_PRIM (lime_curl_getdate, 2);
	DEFINE_PRIM (lime_curl_global_cleanup, 0);
	DEFINE_PRIM (lime_curl_global_init, 1);
	DEFINE_PRIM (lime_curl_version, 0);
	DEFINE_PRIM (lime_curl_version_info, 1);
	
	
}