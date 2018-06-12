#include <curl/curl.h>
#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/Mutex.h>
#include <utils/Bytes.h>
#include <string.h>
#include <map>


namespace lime {
	
	
	std::map<value, value> curlMultiHandles;
	std::map<value, int> curlMultiRunningHandles;
	std::map<value, bool> curlMultiValid;
	std::map<CURL*, value> curlObjects;
	std::map<value, bool> curlValid;
	std::map<value, AutoGCRoot*> headerCallbacks;
	std::map<value, curl_slist*> headerSLists;
	std::map<value, AutoGCRoot*> progressCallbacks;
	std::map<value, AutoGCRoot*> readCallbacks;
	std::map<AutoGCRoot*, Bytes*> writeBytes;
	std::map<AutoGCRoot*, AutoGCRoot*> writeBytesRoot;
	std::map<value, AutoGCRoot*> writeCallbacks;
	Mutex curl_gc_mutex;
	
	
	void gc_curl (value handle) {
		
		if (!val_is_null (handle)) {
			
			curl_gc_mutex.Lock ();
			
			if (curlMultiHandles.find (handle) != curlMultiHandles.end ()) {
				
				CURLM* multi = curlMultiHandles[handle];
				curl_multi_remove_handle (multi, handle);
				curlMultiHandles.erase (handle);
				
			}
			
			if (curlValid.find (handle) != curlValid.end ()) {
				
				CURL* curl = (CURL*)val_data (handle);
				
				curlValid.erase (handle);
				curlObjects.erase (curl);
				curl_easy_cleanup (curl);
				
			}
			
			AutoGCRoot* callback;
			
			if (headerCallbacks.find (handle) != headerCallbacks.end ()) {
				
				callback = headerCallbacks[handle];
				
				if (writeBytes.find (callback) != writeBytes.end ()) {
					
					Bytes* _writeBytes = writeBytes[callback];
					delete _writeBytes;
					writeBytes.erase (callback);
					
					AutoGCRoot* _writeBytesRoot = writeBytesRoot[callback];
					delete _writeBytesRoot;
					writeBytesRoot.erase (callback);
					
				}
				
				headerCallbacks.erase (handle);
				delete callback;
				
			}
			
			if (headerSLists.find (handle) != headerSLists.end ()) {
				
				curl_slist* chunk = headerSLists[handle];
				headerSLists.erase (handle);
				curl_slist_free_all (chunk);
				
			}
			
			if (progressCallbacks.find (handle) != progressCallbacks.end ()) {
				
				callback = progressCallbacks[handle];
				progressCallbacks.erase (handle);
				delete callback;
				
			}
			
			if (readCallbacks.find (handle) != readCallbacks.end ()) {
				
				callback = readCallbacks[handle];
				readCallbacks.erase (handle);
				delete callback;
				
			}
			
			if (writeCallbacks.find (handle) != writeCallbacks.end ()) {
				
				callback = writeCallbacks[handle];
				
				if (writeBytes.find (callback) != writeBytes.end ()) {
					
					Bytes* _writeBytes = writeBytes[callback];
					delete _writeBytes;
					writeBytes.erase (callback);
					
					AutoGCRoot* _writeBytesRoot = writeBytesRoot[callback];
					delete _writeBytesRoot;
					writeBytesRoot.erase (callback);
					
				}
				
				writeCallbacks.erase (handle);
				delete callback;
				
			}
			
			val_gc (handle, 0);
			//handle = alloc_null ();
			
			curl_gc_mutex.Unlock ();
			
		}
		
	}
	
	
	void gc_curl_multi (value handle) {
		
		if (!val_is_null (handle)) {
			
			curl_gc_mutex.Lock ();
			
			if (curlMultiValid.find (handle) != curlMultiValid.end ()) {
				
				curlMultiValid.erase (handle);
				curl_multi_cleanup ((CURL*)val_data(handle));
				
			}
			
			for (std::map<value, value>::iterator it = curlMultiHandles.begin (); it != curlMultiHandles.end (); ++it) {
				
				if (curlMultiHandles[it->first] == handle) {
					
					gc_curl (it->first);
					
				}
				
			}
			
			val_gc (handle, 0);
			//handle = alloc_null ();
			
			curl_gc_mutex.Unlock ();
			
		}
		
	}
	
	
	void lime_curl_easy_cleanup (value handle) {
		
		// Disabled due to collision with GC-based cleanup
		// when GC occurs on a different thread
		
		// if (!val_is_null (handle)) {
			
		// 	if (curlValid.find (handle) != curlValid.end ()) {
				
		// 		curlValid.erase (handle);
		// 		curl_easy_cleanup ((CURL*)val_data(handle));
				
		// 	}
			
		// }
		
	}
	
	
	value lime_curl_easy_duphandle (value handle) {
		
		curl_gc_mutex.Lock ();
		
		CURL* dup = curl_easy_duphandle ((CURL*)val_data(handle));
		value duphandle = CFFIPointer (dup, gc_curl);
		curlValid[duphandle] = true;
		curlObjects[dup] = duphandle;
		
		AutoGCRoot* callback;
		Bytes* _writeBytes;
		
		if (headerCallbacks.find (handle) != headerCallbacks.end ()) {
			callback = headerCallbacks[handle];
			_writeBytes = new Bytes (1024);
			writeBytes[callback] = _writeBytes;
			writeBytesRoot[callback] = new AutoGCRoot (_writeBytes->Value ());
			headerCallbacks[duphandle] = new AutoGCRoot (headerCallbacks[handle]->get());
		}
		
		if (progressCallbacks.find (handle) != progressCallbacks.end ()) {
			progressCallbacks[duphandle] = new AutoGCRoot (progressCallbacks[handle]->get());
		}
		
		if (readCallbacks.find (handle) != readCallbacks.end ()) {
			readCallbacks[duphandle] = new AutoGCRoot (readCallbacks[handle]->get());
		}
		
		if (writeCallbacks.find (handle) != writeCallbacks.end ()) {
			callback = writeCallbacks[handle];
			_writeBytes = new Bytes (1024);
			writeBytes[callback] = _writeBytes;
			writeBytesRoot[callback] = new AutoGCRoot (_writeBytes->Value ());
			writeCallbacks[duphandle] = new AutoGCRoot (writeCallbacks[handle]->get());
		}
		
		curl_gc_mutex.Unlock ();
		
		return duphandle;
		
	}
	
	
	value lime_curl_easy_escape (value curl, HxString url, int length) {
		
		char* result = curl_easy_escape ((CURL*)val_data(curl), url.__s, length);
		return result ? alloc_string (result) : alloc_null ();
		
	}
	
	
	value lime_curl_easy_getinfo (value curl, int info) {
		
		CURLcode code = CURLE_OK;
		CURL* handle = (CURL*)val_data(curl);
		CURLINFO type = (CURLINFO)info;
		
		switch (type) {
			
			case CURLINFO_EFFECTIVE_URL:
			case CURLINFO_REDIRECT_URL:
			case CURLINFO_CONTENT_TYPE:
			case CURLINFO_PRIVATE:
			case CURLINFO_PRIMARY_IP:
			case CURLINFO_LOCAL_IP:
			case CURLINFO_FTP_ENTRY_PATH:
			case CURLINFO_RTSP_SESSION_ID:
			case CURLINFO_SCHEME:
				
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
			case CURLINFO_HTTP_VERSION:
			case CURLINFO_PROXY_SSL_VERIFYRESULT:
			case CURLINFO_PROTOCOL:
			case CURLINFO_SIZE_UPLOAD_T: // TODO: These should be larger
			case CURLINFO_SIZE_DOWNLOAD_T:
			case CURLINFO_SPEED_DOWNLOAD_T:
			case CURLINFO_SPEED_UPLOAD_T:
			case CURLINFO_CONTENT_LENGTH_DOWNLOAD_T:
			case CURLINFO_CONTENT_LENGTH_UPLOAD_T:
				
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
			case CURLINFO_TLS_SSL_PTR:
			case CURLINFO_ACTIVESOCKET:
				
				// TODO
				
				break;
			
			case CURLINFO_NONE:
			case CURLINFO_LASTONE:
				
				// ignore
				
				break;
			
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_curl_easy_init () {
		
		curl_gc_mutex.Lock ();
		
		CURL* curl = curl_easy_init ();
		value handle = CFFIPointer (curl, gc_curl);
		
		if (curlValid.find (handle) != curlValid.end ()) {
			
			printf ("Error: Duplicate cURL handle\n");
			
		}
			
		if (headerCallbacks.find (handle) != headerCallbacks.end ()) {
			
			printf ("Error: cURL handle already has header callback\n");
			
		}
		
		if (progressCallbacks.find (handle) != progressCallbacks.end ()) {
			
			printf ("Error: cURL handle already has progress callback\n");
			
		}
		
		if (readCallbacks.find (handle) != readCallbacks.end ()) {
			
			printf ("Error: cURL handle already has read callback\n");
			
		}
		
		if (writeCallbacks.find (handle) != writeCallbacks.end ()) {
			
			printf ("Error: cURL handle already has write callback\n");
			
		}
		
		curlValid[handle] = true;
		curlObjects[curl] = handle;
		
		curl_gc_mutex.Unlock ();
		
		return handle;
		
	}
	
	
	int lime_curl_easy_pause (value handle, int bitmask) {
		
		return curl_easy_pause ((CURL*)val_data(handle), bitmask);
		
	}
	
	
	int lime_curl_easy_perform (value easy_handle) {
		
		int code;
		gc_enter_blocking ();
		
		code = curl_easy_perform ((CURL*)val_data(easy_handle));
		
		gc_exit_blocking ();
		return code;
		
	}
	
	
	int lime_curl_easy_recv (value curl, value buffer, int buflen, int n) {
		
		// TODO
		
		return 0;
		
	}
	
	
	void lime_curl_easy_reset (value curl) {
		
		curl_easy_reset ((CURL*)val_data(curl));
		
	}
	
	
	int lime_curl_easy_send (value curl, value buffer, int buflen, int n) {
		
		// TODO
		
		return 0;
		
	}
	
	
	static size_t write_callback (void *ptr, size_t size, size_t nmemb, void *userp) {
		
		AutoGCRoot* callback = (AutoGCRoot*)userp;
		value method = callback->get ();
		
		if (size * nmemb < 1) {
			
			return 0;
			
		}
		
		if (method && !val_is_null (method)) {
			
			Bytes* _writeBytes = writeBytes[callback];
			if (!_writeBytes) return 0;
			_writeBytes->Resize (size * nmemb);
			memcpy (_writeBytes->Data (), ptr, size * nmemb);
			
			return val_int (val_call3 (callback->get (), _writeBytes->Value (), alloc_int (size), alloc_int (nmemb)));
			
		} else {
			
			return size * nmemb;
			
		}
		
	}
	
	
	static size_t read_callback (void *buffer, size_t size, size_t nmemb, void *userp) {
		
		AutoGCRoot* callback = (AutoGCRoot*)userp;
		value method = callback->get ();
		
		size_t length = size * nmemb;
		
		if (method && !val_is_null (method)) {
			
			Bytes bytes;
			bytes.Set (val_call1 (callback->get (), alloc_int (length)));
			
			if (bytes.Length () <= length) length = bytes.Length ();
			
			memcpy (buffer, bytes.Data (), length);
			
		}
		
		return length;
		
	}
	
	
	static size_t progress_callback (void *userp, double dltotal, double dlnow, double ultotal, double ulnow) {
		
		AutoGCRoot* callback = (AutoGCRoot*)userp;
		value method = callback->get ();
		
		if (method && !val_is_null (method)) {
			
			value vals[] = {
				alloc_float (dltotal),
				alloc_float (dlnow),
				alloc_float (ultotal),
				alloc_float (ulnow),
			};
			
			return val_int (val_callN (callback->get (), vals, 4));
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	int lime_curl_easy_setopt (value handle, int option, value parameter, value bytes) {
		
		CURLcode code = CURLE_OK;
		CURL* curl = (CURL*)val_data(handle);
		CURLoption type = (CURLoption)option;
		
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
			case CURLOPT_SSL_SESSIONID_CACHE:
			case CURLOPT_TCP_FASTOPEN:
			case CURLOPT_KEEP_SENDING_ON_ERROR:
			case CURLOPT_PATH_AS_IS:
			case CURLOPT_SSL_VERIFYSTATUS:
			case CURLOPT_SSL_FALSESTART:
			case CURLOPT_PIPEWAIT:
			case CURLOPT_TFTP_NO_OPTIONS:
			case CURLOPT_SUPPRESS_CONNECT_HEADERS:
			case CURLOPT_SSH_COMPRESSION:
				
				code = curl_easy_setopt (curl, type, val_bool (parameter));
				break;
			
			case CURLOPT_SSL_VERIFYHOST:
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
			case CURLOPT_STREAM_WEIGHT:
			case CURLOPT_PROXY_SSL_VERIFYPEER:
			case CURLOPT_PROXY_SSL_VERIFYHOST:
			case CURLOPT_PROXY_SSLVERSION:
			case CURLOPT_PROXY_SSL_OPTIONS:
			case CURLOPT_SOCKS5_AUTH:
				
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
			case CURLOPT_PINNEDPUBLICKEY:
			case CURLOPT_UNIX_SOCKET_PATH:
			case CURLOPT_PROXY_SERVICE_NAME:
			case CURLOPT_SERVICE_NAME:
			case CURLOPT_DEFAULT_PROTOCOL:
			case CURLOPT_PROXY_CAINFO:
			case CURLOPT_PROXY_CAPATH:
			case CURLOPT_PROXY_TLSAUTH_USERNAME:
			case CURLOPT_PROXY_TLSAUTH_PASSWORD:
			case CURLOPT_PROXY_TLSAUTH_TYPE:
			case CURLOPT_PROXY_SSLCERT:
			case CURLOPT_PROXY_SSLCERTTYPE:
			case CURLOPT_PROXY_SSLKEY:
			case CURLOPT_PROXY_SSLKEYTYPE:
			case CURLOPT_PROXY_KEYPASSWD:
			case CURLOPT_PROXY_SSL_CIPHER_LIST:
			case CURLOPT_PROXY_CRLFILE:
			case CURLOPT_PRE_PROXY:
			case CURLOPT_PROXY_PINNEDPUBLICKEY:
			case CURLOPT_ABSTRACT_UNIX_SOCKET:
			case CURLOPT_REQUEST_TARGET:
				
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
			case CURLOPT_STREAM_DEPENDS:
			case CURLOPT_STREAM_DEPENDS_E:
			case CURLOPT_CONNECT_TO:
			case CURLOPT_MIMEPOST:
				
				//todo
				break;
			
			//case CURLOPT_READDATA:
			//case CURLOPT_WRITEDATA:
			//case CURLOPT_HEADERDATA:
			//case CURLOPT_PROGRESSDATA:
			
			case CURLOPT_READFUNCTION:
			{
				curl_gc_mutex.Lock ();
				AutoGCRoot* callback = new AutoGCRoot (parameter);
				readCallbacks[handle] = callback;
				code = curl_easy_setopt (curl, type, read_callback);
				curl_easy_setopt (curl, CURLOPT_READDATA, callback);
				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_WRITEFUNCTION:
			{
				curl_gc_mutex.Lock ();
				AutoGCRoot* callback = new AutoGCRoot (parameter);
				writeCallbacks[handle] = callback;
				Bytes* _writeBytes = new Bytes (bytes);
				writeBytes[callback] = _writeBytes;
				writeBytesRoot[callback] = new AutoGCRoot (bytes);
				code = curl_easy_setopt (curl, type, write_callback);
				curl_easy_setopt (curl, CURLOPT_WRITEDATA, callback);
				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_HEADERFUNCTION:
			{
				curl_gc_mutex.Lock ();
				AutoGCRoot* callback = new AutoGCRoot (parameter);
				headerCallbacks[handle] = callback;
				Bytes* _writeBytes = new Bytes (bytes);
				writeBytes[callback] = _writeBytes;
				writeBytesRoot[callback] = new AutoGCRoot (bytes);
				code = curl_easy_setopt (curl, type, write_callback);
				curl_easy_setopt (curl, CURLOPT_HEADERDATA, callback);
				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_PROGRESSFUNCTION:
			{
				curl_gc_mutex.Lock ();
				AutoGCRoot* callback = new AutoGCRoot (parameter);
				progressCallbacks[handle] = callback;
				code = curl_easy_setopt (curl, type, progress_callback);
				curl_easy_setopt (curl, CURLOPT_PROGRESSDATA, callback);
				curl_easy_setopt (curl, CURLOPT_NOPROGRESS, false);
				curl_gc_mutex.Unlock ();
				break;
			}
			
			case CURLOPT_HTTPHEADER:
			{
				curl_gc_mutex.Lock ();
				if (headerSLists.find (handle) != headerSLists.end ()) {
					
					curl_slist_free_all (headerSLists[handle]);
					
				}
				
				struct curl_slist *chunk = NULL;
				int size = val_array_size (parameter);
				
				for (int i = 0; i < size; i++) {
					
					chunk = curl_slist_append (chunk, val_string (val_array_i (parameter, i)));
					
				}
				
				headerSLists[handle] = chunk;
				
				code = curl_easy_setopt (curl, type, chunk);
				curl_gc_mutex.Unlock ();
				break;
			}
			
			default:
				
				break;
			
		}
		
		return code;
		
	}
	
	
	value lime_curl_easy_strerror (int errornum) {
		
		const char* result = curl_easy_strerror ((CURLcode)errornum);
		return result ? alloc_string (result) : alloc_null ();
		
	}
	
	
	value lime_curl_easy_unescape (value curl, HxString url, int inlength, int outlength) {
		
		char* result = curl_easy_unescape ((CURL*)val_data(curl), url.__s, inlength, &outlength);
		return result ? alloc_string (result) : alloc_null ();
		
	}
	
	
	//lime_curl_formadd;
	//lime_curl_formfree;
	//lime_curl_formget;
	
	
	double lime_curl_getdate (HxString datestring, double now) {
		
		time_t time = (time_t)now;
		return curl_getdate (datestring.__s, &time);
		
	}
	
	
	void lime_curl_global_cleanup () {
		
		curl_global_cleanup ();
		
	}
	
	
	int lime_curl_global_init (int flags) {
		
		return curl_global_init (flags);
		
	}
	
	
	int lime_curl_multi_cleanup (value multi_handle) {
		
		curl_gc_mutex.Lock ();
		
		// CURLMcode result = curl_multi_cleanup ((CURLM*)val_data (multi_handle));
		gc_curl_multi (multi_handle);
		
		curl_gc_mutex.Unlock ();
		
		return CURLM_OK;
		
	}
	
	
	value lime_curl_multi_init () {
		
		curl_gc_mutex.Lock ();
		
		value handle = CFFIPointer (curl_multi_init (), gc_curl_multi);
		
		if (curlMultiValid.find (handle) != curlMultiValid.end ()) {
			
			printf ("Error: Duplicate cURL Multi handle\n");
			
		}
		
		curlMultiValid[handle] = true;
		curlMultiRunningHandles[handle] = 0;
		
		curl_gc_mutex.Unlock ();
		
		return handle;
		
	}
	
	
	int lime_curl_multi_add_handle (value multi_handle, value curl_handle) {
		
		curl_gc_mutex.Lock ();
		
		CURLMcode result = curl_multi_add_handle ((CURLM*)val_data (multi_handle), (CURL*)val_data (curl_handle));
		
		if (result == CURLM_OK) {
			
			curlMultiHandles[curl_handle] = multi_handle;
			
		}
		
		curl_gc_mutex.Unlock ();
		
		return result;
		
	}
	
	
	int lime_curl_multi_get_running_handles (value multi_handle) {
		
		return curlMultiRunningHandles[multi_handle];
		
	}
	
	
	value lime_curl_multi_info_read (value multi_handle) {
		
		int msgs_in_queue;
		CURLMsg* msg = curl_multi_info_read ((CURLM*)val_data (multi_handle), &msgs_in_queue);
		
		if (msg) {
			
			//const field val_id ("msg");
			const field easy_handle = val_id ("easy_handle");
			const field _result = val_id ("result");
			
			CURL* curl = msg->easy_handle;
			value result = alloc_empty_object ();
			
			if (curlObjects.find (curl) != curlObjects.end ()) {
				
				alloc_field (result, easy_handle, curlObjects[curl]);
				
			} else {
				
				// TODO?
				alloc_field (result, easy_handle, alloc_null ());
				
			}
			
			alloc_field (result, _result, alloc_int (msg->data.result));
			return result;
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	int lime_curl_multi_perform (value multi_handle) {
		
		curl_gc_mutex.Lock ();
		
		int runningHandles = 0;
		CURLMcode result = curl_multi_perform ((CURLM*)val_data (multi_handle), &runningHandles);
		
		curlMultiRunningHandles[multi_handle] = runningHandles;
		
		curl_gc_mutex.Unlock ();
		
		return result;
		
	}
	
	
	int lime_curl_multi_remove_handle (value multi_handle, value curl_handle) {
		
		curl_gc_mutex.Lock ();
		
		CURLMcode result = curl_multi_remove_handle ((CURLM*)val_data (multi_handle), (CURL*)val_data (curl_handle));
		
		if (/*result == CURLM_OK &&*/ curlMultiHandles.find (curl_handle) != curlMultiHandles.end ()) {
			
			curlMultiHandles.erase (curl_handle);
			
		}
		
		curl_gc_mutex.Unlock ();
		
		return result;
		
	}
	
	
	int lime_curl_multi_wait (value multi_handle, int timeout_ms) {
		
		gc_enter_blocking ();
		
		int retcode;
		CURLMcode result = curl_multi_wait ((CURLM*)val_data (multi_handle), 0, 0, timeout_ms, &retcode);
		
		gc_exit_blocking ();
		return result;
		
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
		return result ? alloc_string (result) : alloc_null ();
		
	}
	
	
	value lime_curl_version_info (int type) {
		
		curl_version_info_data* data = curl_version_info ((CURLversion)type);
		
		// TODO
		
		return alloc_null ();
		
	}
	
	
	DEFINE_PRIME1v (lime_curl_easy_cleanup);
	DEFINE_PRIME1 (lime_curl_easy_duphandle);
	DEFINE_PRIME3 (lime_curl_easy_escape);
	DEFINE_PRIME2 (lime_curl_easy_getinfo);
	DEFINE_PRIME0 (lime_curl_easy_init);
	DEFINE_PRIME2 (lime_curl_easy_pause);
	DEFINE_PRIME1 (lime_curl_easy_perform);
	DEFINE_PRIME4 (lime_curl_easy_recv);
	DEFINE_PRIME1v (lime_curl_easy_reset);
	DEFINE_PRIME4 (lime_curl_easy_send);
	DEFINE_PRIME4 (lime_curl_easy_setopt);
	DEFINE_PRIME1 (lime_curl_easy_strerror);
	DEFINE_PRIME4 (lime_curl_easy_unescape);
	DEFINE_PRIME2 (lime_curl_getdate);
	DEFINE_PRIME0v (lime_curl_global_cleanup);
	DEFINE_PRIME1 (lime_curl_global_init);
	DEFINE_PRIME0 (lime_curl_multi_init);
	DEFINE_PRIME2 (lime_curl_multi_add_handle);
	DEFINE_PRIME1 (lime_curl_multi_get_running_handles);
	DEFINE_PRIME1 (lime_curl_multi_perform);
	DEFINE_PRIME1 (lime_curl_multi_info_read);
	DEFINE_PRIME2 (lime_curl_multi_remove_handle);
	DEFINE_PRIME2 (lime_curl_multi_wait);
	DEFINE_PRIME0 (lime_curl_version);
	DEFINE_PRIME1 (lime_curl_version_info);
	
	
}


extern "C" int lime_curl_register_prims () {
	
	return 0;
	
}