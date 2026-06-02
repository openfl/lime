#include <curl/curl.h>
#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/Mutex.h>
#include <system/System.h>
#include <system/ValuePointer.h>
#include <utils/Bytes.h>
#include <string.h>
#include <map>
#include <vector>


namespace lime {


	struct CURL_Progress {

		double dltotal;
		double dlnow;
		double ultotal;
		double ulnow;

	};

	struct CURL_XferInfo {

		curl_off_t dltotal;
		curl_off_t dlnow;
		curl_off_t ultotal;
		curl_off_t ulnow;

	};

	std::map<void*, std::vector<void*>* > curlMultiHandles;
	std::map<void*, ValuePointer*> curlMultiObjects;
	std::map<void*, void*> curlMultiReferences;
	std::map<void*, int> curlMultiRunningHandles;
	std::map<void*, bool> curlMultiValid;
	std::map<CURL*, void*> curlObjects;
	std::map<void*, bool> curlValid;
	std::map<void*, ValuePointer*> headerCallbacks;
	std::map<void*, curl_slist*> headerSLists;
	std::map<void*, std::vector<char*>* > headerValues;
	std::map<void*, ValuePointer*> progressCallbacks;
	std::map<void*, CURL_Progress*> progressValues;
	std::map<void*, Bytes*> readBytes;
	std::map<void*, int> readBytesPosition;
	std::map<void*, ValuePointer*> readBytesRoot;
	// TODO: Switch to structs
	std::map<void*, char*> writeBuffers;
	std::map<void*, int> writeBufferPosition;
	std::map<void*, int> writeBufferSize;
	std::map<void*, Bytes*> writeBytes;
	std::map<void*, ValuePointer*> writeBytesRoot;
	std::map<void*, ValuePointer*> writeCallbacks;
	std::map<void*, ValuePointer*> xferInfoCallbacks;
	std::map<void*, CURL_XferInfo*> xferInfoValues;
	Mutex curl_gc_mutex;

	void free_header_values (const std::vector<char*>* values) {

		if (values) {

			for (auto it = values->begin (); it != values->end (); ++it) {

				free (*it);

			}

		}

	}

	void gc_curl (value handle) {

		if (!val_is_null (handle)) {

			curl_gc_mutex.Lock ();

			if (curlMultiReferences.find (handle) != curlMultiReferences.end ()) {

				value multi_handle = (value)curlMultiReferences[handle];
				curl_multi_remove_handle ((CURLM*)val_data (multi_handle), (CURL*)val_data (handle));
				curlMultiReferences.erase (handle);

				std::vector<void*>* handles = curlMultiHandles[multi_handle];

				if (handles->size () > 0) {

					for (std::vector<void*>::iterator it = handles->begin (); it != handles->end (); ++it) {

						if (*it == handle) {

							handles->erase (it);
							delete curlMultiObjects[handle];
							curlMultiObjects.erase (handle);
							break;

						}

					}

				}

			}

			if (curlValid.find (handle) != curlValid.end ()) {

				CURL* curl = (CURL*)val_data (handle);

				curlValid.erase (handle);
				curlObjects.erase (curl);
				curl_easy_cleanup (curl);

				if (writeBuffers[handle]) {

					free (writeBuffers[handle]);

				}

				writeBuffers.erase (handle);
				writeBufferPosition.erase (handle);
				writeBufferSize.erase (handle);

			}

			ValuePointer* callback;
			Bytes* bytes;
			ValuePointer* bytesRoot;

			if (headerCallbacks.find (handle) != headerCallbacks.end ()) {

				callback = headerCallbacks[handle];
				std::vector<char*>* values = headerValues[handle];
				headerCallbacks.erase (handle);
				headerValues.erase (handle);
				free_header_values (values);
				delete callback;
				delete values;

			}

			if (headerSLists.find (handle) != headerSLists.end ()) {

				curl_slist* chunk = headerSLists[handle];
				headerSLists.erase (handle);
				curl_slist_free_all (chunk);

			}

			if (progressCallbacks.find (handle) != progressCallbacks.end ()) {

				callback = progressCallbacks[handle];
				CURL_Progress* progress = progressValues[handle];
				progressCallbacks.erase (handle);
				progressValues.erase (progress);
				delete callback;
				delete progress;

			}

			if (readBytes.find (handle) != readBytes.end ()) {

				bytes = readBytes[handle];
				bytesRoot = readBytesRoot[handle];
				readBytes.erase (handle);
				readBytesPosition.erase (handle);
				readBytesRoot.erase (handle);
				delete bytes;
				delete bytesRoot;

			}

			if (writeCallbacks.find (handle) != writeCallbacks.end ()) {

				callback = writeCallbacks[handle];
				bytes = writeBytes[handle];
				bytesRoot = writeBytesRoot[handle];
				writeCallbacks.erase (handle);
				writeBytes.erase (handle);
				writeBytesRoot.erase (handle);
				delete callback;
				delete bytes;
				delete bytesRoot;

			}

			if (xferInfoCallbacks.find (handle) != xferInfoCallbacks.end ()) {

				callback = xferInfoCallbacks[handle];
				CURL_XferInfo* info = xferInfoValues[handle];
				xferInfoCallbacks.erase (handle);
				xferInfoValues.erase (handle);
				delete callback;
				delete info;

			}

			val_gc (handle, 0);

			curl_gc_mutex.Unlock ();

		}

	}


	void hl_gc_curl (HL_CFFIPointer* handle) {

		if (handle) {

			curl_gc_mutex.Lock ();

			if (curlMultiReferences.find (handle) != curlMultiReferences.end ()) {

				HL_CFFIPointer* multi_handle = (HL_CFFIPointer*)curlMultiReferences[handle];
				curl_multi_remove_handle ((CURLM*)multi_handle->ptr, (CURL*)handle->ptr);
				curlMultiReferences.erase (handle);

				std::vector<void*>* handles = curlMultiHandles[multi_handle];

				if (handles->size () > 0) {

					for (std::vector<void*>::iterator it = handles->begin (); it != handles->end (); ++it) {

						if (*it == handle) {

							handles->erase (it);
							delete curlMultiObjects[handle];
							curlMultiObjects.erase (handle);
							break;

						}

					}

				}

			}

			if (curlValid.find (handle) != curlValid.end ()) {

				CURL* curl = (CURL*)handle->ptr;

				curlValid.erase (handle);
				curlObjects.erase (curl);
				curl_easy_cleanup (curl);

				if (writeBuffers[handle]) {

					free (writeBuffers[handle]);

				}

				writeBuffers.erase (handle);
				writeBufferPosition.erase (handle);
				writeBufferSize.erase (handle);

			}

			ValuePointer* callback;
			Bytes* bytes;
			ValuePointer* bytesRoot;

			if (headerCallbacks.find (handle) != headerCallbacks.end ()) {

				callback = headerCallbacks[handle];
				std::vector<char*>* values = headerValues[handle];
				headerCallbacks.erase (handle);
				headerValues.erase (handle);
				free_header_values (values);
				delete callback;
				delete values;

			}

			if (headerSLists.find (handle) != headerSLists.end ()) {

				curl_slist* chunk = headerSLists[handle];
				headerSLists.erase (handle);
				curl_slist_free_all (chunk);

			}

			if (progressCallbacks.find (handle) != progressCallbacks.end ()) {

				callback = progressCallbacks[handle];
				CURL_Progress* progress = progressValues[handle];
				progressCallbacks.erase (handle);
				progressValues.erase (progress);
				delete callback;
				delete progress;

			}

			if (readBytes.find (handle) != readBytes.end ()) {

				bytes = readBytes[handle];
				bytesRoot = readBytesRoot[handle];
				readBytes.erase (handle);
				readBytesPosition.erase (handle);
				readBytesRoot.erase (handle);
				delete bytesRoot;

			}

			if (writeCallbacks.find (handle) != writeCallbacks.end ()) {

				callback = writeCallbacks[handle];
				bytes = writeBytes[handle];
				bytesRoot = writeBytesRoot[handle];
				writeCallbacks.erase (handle);
				writeBytes.erase (handle);
				writeBytesRoot.erase (handle);
				delete callback;
				delete bytesRoot;

			}

			if (xferInfoCallbacks.find (handle) != xferInfoCallbacks.end ()) {

				callback = xferInfoCallbacks[handle];
				CURL_XferInfo* info = xferInfoValues[handle];
				xferInfoCallbacks.erase (handle);
				xferInfoValues.erase (handle);
				delete callback;
				delete info;

			}

			handle->finalizer = NULL;

			curl_gc_mutex.Unlock ();

		}

	}


	void gc_curl_multi (value handle) {

		if (!val_is_null (handle)) {

			curl_gc_mutex.Lock ();

			if (curlMultiValid.find (handle) != curlMultiValid.end ()) {

				curlMultiValid.erase (handle);
				curl_multi_cleanup ((CURLM*)val_data(handle));

			}

			std::vector<void*>* handles = curlMultiHandles[handle];

			for (std::vector<void*>::iterator it = handles->begin (); it != handles->end (); ++it) {

				delete curlMultiObjects[*it];
				curlMultiObjects.erase (*it);

				curl_gc_mutex.Unlock ();
				gc_curl ((value)*it);
				curl_gc_mutex.Lock ();

			}

			delete curlMultiHandles[handle];
			curlMultiHandles.erase (handle);

			val_gc (handle, 0);
			//handle = alloc_null ();

			curl_gc_mutex.Unlock ();

		}

	}


	void hl_gc_curl_multi (HL_CFFIPointer* handle) {

		if (handle) {

			curl_gc_mutex.Lock ();

			if (curlMultiValid.find (handle) != curlMultiValid.end ()) {

				curlMultiValid.erase (handle);
				curl_multi_cleanup ((CURLM*)handle->ptr);

			}

			std::vector<void*>* handles = curlMultiHandles[handle];

			for (std::vector<void*>::iterator it = handles->begin (); it != handles->end (); ++it) {

				delete curlMultiObjects[*it];
				curlMultiObjects.erase (*it);

				curl_gc_mutex.Unlock ();
				hl_gc_curl ((HL_CFFIPointer*)*it);
				curl_gc_mutex.Lock ();

			}

			delete curlMultiHandles[handle];
			curlMultiHandles.erase (handle);

			handle->finalizer = NULL;
			//handle = alloc_null ();

			curl_gc_mutex.Unlock ();

		}

	}


	void lime_curl_easy_cleanup (value handle) {

		gc_curl (handle);

	}


	HL_PRIM void HL_NAME(hl_curl_easy_cleanup) (HL_CFFIPointer* handle) {

		hl_gc_curl (handle);

	}


	value lime_curl_easy_duphandle (value handle) {

		curl_gc_mutex.Lock ();

		CURL* dup = curl_easy_duphandle ((CURL*)val_data(handle));
		value duphandle = CFFIPointer (dup, gc_curl);
		curlValid[duphandle] = true;
		curlObjects[dup] = duphandle;

		value callbackValue;
		Bytes* bytes;
		value bytesValue;

		if (headerCallbacks.find (handle) != headerCallbacks.end ()) {

			callbackValue = (value)headerCallbacks[handle]->Get ();
			headerCallbacks[duphandle] = new ValuePointer (callbackValue);
			headerValues[duphandle] = new std::vector<char*> ();

		}

		if (progressCallbacks.find (handle) != progressCallbacks.end ()) {

			callbackValue = (value)progressCallbacks[handle]->Get ();
			progressCallbacks[duphandle] = new ValuePointer (callbackValue);
			progressValues[duphandle] = new CURL_Progress ();

		}

		if (readBytes.find (handle) != readBytes.end ()) {

			bytesValue = (value)readBytesRoot[handle]->Get ();
			bytes = new Bytes (bytesValue);
			readBytes[duphandle] = bytes;
			readBytesPosition[duphandle] = 0;
			readBytesRoot[duphandle] = new ValuePointer (bytesValue);

		}

		if (writeCallbacks.find (handle) != writeCallbacks.end ()) {

			callbackValue = (value)writeCallbacks[handle]->Get ();
			bytesValue = (value)writeBytesRoot[handle]->Get ();
			bytes = new Bytes (bytesValue);
			writeCallbacks[duphandle] = new ValuePointer (callbackValue);
			writeBuffers[duphandle] = NULL;
			writeBufferPosition[duphandle] = 0;
			writeBufferSize[duphandle] = 0;
			writeBytes[duphandle] = bytes;
			writeBytesRoot[duphandle] = new ValuePointer (bytesValue);

		}

		if (xferInfoCallbacks.find (handle) != xferInfoCallbacks.end ()) {

			callbackValue = (value)xferInfoCallbacks[handle]->Get ();
			xferInfoCallbacks[duphandle] = new ValuePointer (callbackValue);
			xferInfoValues[duphandle] = new CURL_XferInfo ();

		}

		curl_gc_mutex.Unlock ();

		return duphandle;

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_curl_easy_duphandle) (HL_CFFIPointer* handle) {

		curl_gc_mutex.Lock ();

		CURL* dup = curl_easy_duphandle ((CURL*)handle->ptr);
		HL_CFFIPointer* duphandle = HLCFFIPointer (dup, (hl_finalizer)hl_gc_curl);
		curlValid[duphandle] = true;
		curlObjects[dup] = duphandle;

		vclosure* callbackValue;
		Bytes* bytes;

		if (headerCallbacks.find (handle) != headerCallbacks.end ()) {

			callbackValue = (vclosure*)headerCallbacks[handle]->Get ();
			headerCallbacks[duphandle] = new ValuePointer (callbackValue);
			headerValues[duphandle] = new std::vector<char*> ();

		}

		if (progressCallbacks.find (handle) != progressCallbacks.end ()) {

			callbackValue = (vclosure*)progressCallbacks[handle]->Get ();
			progressCallbacks[duphandle] = new ValuePointer (callbackValue);
			progressValues[duphandle] = new CURL_Progress ();

		}

		if (readBytes.find (handle) != readBytes.end ()) {

			readBytes[duphandle] = readBytes[handle];
			readBytesPosition[duphandle] = 0;
			readBytesRoot[duphandle] = new ValuePointer ((vobj*)readBytes[handle]);

		}

		if (writeCallbacks.find (handle) != writeCallbacks.end ()) {

			callbackValue = (vclosure*)writeCallbacks[handle]->Get ();
			writeCallbacks[duphandle] = new ValuePointer (callbackValue);
			writeBuffers[duphandle] = NULL;
			writeBufferPosition[duphandle] = 0;
			writeBufferSize[duphandle] = 0;
			writeBytes[duphandle] = writeBytes[handle];
			writeBytesRoot[duphandle] = new ValuePointer ((vobj*)writeBytes[handle]);

		}

		if (xferInfoCallbacks.find (handle) != xferInfoCallbacks.end ()) {

			callbackValue = (vclosure*)xferInfoCallbacks[handle]->Get ();
			xferInfoCallbacks[duphandle] = new ValuePointer (callbackValue);
			xferInfoValues[duphandle] = new CURL_XferInfo ();

		}

		curl_gc_mutex.Unlock ();

		return duphandle;

	}


	value lime_curl_easy_escape (value curl, HxString url, int length) {

		char* result = curl_easy_escape ((CURL*)val_data(curl), url.__s, length);
		return result ? alloc_string (result) : alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_curl_easy_escape) (HL_CFFIPointer* curl, hl_vstring* url, int length) {

		char* result = curl_easy_escape ((CURL*)curl->ptr, url ? hl_to_utf8 (url->bytes) : NULL, length);
		return (vbyte*)result;

	}


	void lime_curl_easy_flush (value easy_handle) {

		curl_gc_mutex.Lock ();
		int code;

		if (headerCallbacks.find (easy_handle) != headerCallbacks.end ()) {

			ValuePointer* headerCallback = headerCallbacks[easy_handle];
			std::vector<char*>* values = headerValues[easy_handle];

			if (values->size () > 0) {

				for (std::vector<char*>::iterator it = values->begin (); it != values->end (); ++it) {

					curl_gc_mutex.Unlock ();
					headerCallback->Call (alloc_string (*it));
					curl_gc_mutex.Lock ();

				}

				free_header_values (values);
				values->clear ();

			}

		}

		if (writeBuffers.find (easy_handle) != writeBuffers.end ()) {

			char* buffer = writeBuffers[easy_handle];
			int position = writeBufferPosition[easy_handle];
			int length = writeBufferSize[easy_handle];

			if (buffer && position > 0) {

				if (writeCallbacks.find (easy_handle) != writeCallbacks.end ()) {

					ValuePointer* writeCallback = writeCallbacks[easy_handle];
					ValuePointer* bytesRoot = writeBytesRoot[easy_handle];

					Bytes* bytes = writeBytes[easy_handle];
					if (bytes->length < position) bytes->Resize (position);
					memcpy ((char*)bytes->b, buffer, position);
					// free (buffer);
					// writeBuffers[easy_handle] = NULL;
					// writeBufferSize[easy_handle] = 0;
					writeBufferPosition[easy_handle] = 0;

					value _bytes = bytes->Value ((value)bytesRoot->Get ());

					curl_gc_mutex.Unlock ();
					length = val_int ((value)writeCallback->Call (_bytes, alloc_int (position)));
					curl_gc_mutex.Lock ();

					if (length == CURL_WRITEFUNC_PAUSE) {

						// TODO: Handle pause

					}

				}

			}

		}

		if (progressCallbacks.find (easy_handle) != progressCallbacks.end ()) {

			CURL_Progress* progress = progressValues[easy_handle];
			ValuePointer* progressCallback = progressCallbacks[easy_handle];

			curl_gc_mutex.Unlock ();
			code = val_int ((value)progressCallback->Call (alloc_float (progress->dltotal), alloc_float (progress->dlnow), alloc_float (progress->ultotal), alloc_float (progress->ulnow)));
			curl_gc_mutex.Lock ();

			if (code != 0) { // CURLE_OK

				// TODO: Abort

			}

		}

		if (xferInfoCallbacks.find (easy_handle) != xferInfoCallbacks.end ()) {

			CURL_XferInfo* xferInfo = xferInfoValues[easy_handle];
			ValuePointer* xferInfoCallback = xferInfoCallbacks[easy_handle];

			curl_gc_mutex.Unlock ();
			code = val_int ((value)xferInfoCallback->Call (alloc_int (xferInfo->dltotal), alloc_int (xferInfo->dlnow), alloc_int (xferInfo->ultotal), alloc_int (xferInfo->ulnow)));
			curl_gc_mutex.Lock ();

			if (code != 0) {

				// TODO: Abort

			}

		}

		curl_gc_mutex.Unlock ();

	}


	HL_PRIM void HL_NAME(hl_curl_easy_flush) (HL_CFFIPointer* easy_handle) {

		curl_gc_mutex.Lock ();
		int code;

		if (headerCallbacks.find (easy_handle) != headerCallbacks.end ()) {

			ValuePointer* headerCallback = headerCallbacks[easy_handle];
			std::vector<char*>* values = headerValues[easy_handle];

			if (values->size () > 0) {

				for (std::vector<char*>::iterator it = values->begin (); it != values->end (); ++it) {

					vdynamic* bytes = hl_alloc_dynamic (&hlt_bytes);
					bytes->v.bytes = (vbyte*)*it;

					curl_gc_mutex.Unlock ();
					headerCallback->Call (bytes);
					curl_gc_mutex.Lock ();

				}

				free_header_values (values);
				values->clear ();

			}

		}

		if (writeBuffers.find (easy_handle) != writeBuffers.end ()) {

			char* buffer = writeBuffers[easy_handle];
			int position = writeBufferPosition[easy_handle];
			int length = writeBufferSize[easy_handle];

			if (buffer && position > 0) {

				if (writeCallbacks.find (easy_handle) != writeCallbacks.end ()) {

					ValuePointer* writeCallback = writeCallbacks[easy_handle];

					Bytes* bytes = writeBytes[easy_handle];
					if (bytes->length < position) bytes->Resize (position);
					memcpy ((char*)bytes->b, buffer, position);
					// free (buffer);
					// writeBuffers[easy_handle] = NULL;
					// writeBufferSize[easy_handle] = 0;
					writeBufferPosition[easy_handle] = 0;

					vdynamic* pos = hl_alloc_dynamic (&hlt_i32);
					pos->v.i = position;

					curl_gc_mutex.Unlock ();
					vdynamic* _length = (vdynamic*)writeCallback->Call (bytes, pos);
					length = (_length != NULL ? _length->v.i : 0);
					curl_gc_mutex.Lock ();

					if (length == CURL_WRITEFUNC_PAUSE) {

						// TODO: Handle pause

					}

				}

			}

		}

		if (progressCallbacks.find (easy_handle) != progressCallbacks.end ()) {

			CURL_Progress* progress = progressValues[easy_handle];
			ValuePointer* progressCallback = progressCallbacks[easy_handle];

			vdynamic* dltotal = hl_alloc_dynamic (&hlt_f64);
			vdynamic* dlnow = hl_alloc_dynamic (&hlt_f64);
			vdynamic* ultotal = hl_alloc_dynamic (&hlt_f64);
			vdynamic* ulnow = hl_alloc_dynamic (&hlt_f64);

			dltotal->v.d = progress->dltotal;
			dlnow->v.d = progress->dlnow;
			ultotal->v.d = progress->ultotal;
			ulnow->v.d = progress->ulnow;

			curl_gc_mutex.Unlock ();
			vdynamic* _code = (vdynamic*)progressCallback->Call (dltotal, dlnow, ultotal, ulnow);
			code = (_code != NULL ? _code->v.i : 0);
			curl_gc_mutex.Lock ();

			if (code != 0) { // CURLE_OK

				// TODO: Abort

			}

		}

		if (xferInfoCallbacks.find (easy_handle) != xferInfoCallbacks.end ()) {

			CURL_XferInfo* xferInfo = xferInfoValues[easy_handle];
			ValuePointer* xferInfoCallback = xferInfoCallbacks[easy_handle];

			vdynamic* dltotal = hl_alloc_dynamic (&hlt_i32);
			vdynamic* dlnow = hl_alloc_dynamic (&hlt_i32);
			vdynamic* ultotal = hl_alloc_dynamic (&hlt_i32);
			vdynamic* ulnow = hl_alloc_dynamic (&hlt_i32);

			dltotal->v.i = xferInfo->dltotal;
			dlnow->v.i = xferInfo->dlnow;
			ultotal->v.i = xferInfo->ultotal;
			ulnow->v.i = xferInfo->ulnow;

			curl_gc_mutex.Unlock ();
			vdynamic* _code = (vdynamic*)xferInfoCallback->Call (dltotal, dlnow, ultotal, ulnow);
			code = (_code != NULL ? _code->v.i : 0);
			curl_gc_mutex.Lock ();

			if (code != 0) {

				// TODO: Abort

			}

		}

		curl_gc_mutex.Unlock ();

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

			case CURLINFO_COOKIELIST:
			{
				struct curl_slist *cookies;
				code = curl_easy_getinfo(handle, CURLINFO_COOKIELIST, &cookies);
				struct curl_slist *each = cookies;
				value result = alloc_array(0);
				while (each) {
					val_array_push(result, alloc_string(each->data));
					each = each->next;
				}
				curl_slist_free_all(cookies);
				return result;
				break;
			}

			case CURLINFO_SSL_ENGINES:
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


	HL_PRIM vdynamic* HL_NAME(hl_curl_easy_getinfo) (HL_CFFIPointer* curl, int info) {

		CURLcode code = CURLE_OK;
		CURL* handle = (CURL*)curl->ptr;
		CURLINFO type = (CURLINFO)info;

		int size;
		vdynamic* result = NULL;

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
			{
				char stringValue;
				code = curl_easy_getinfo (handle, type, &stringValue);

				int size = strlen (&stringValue) + 1;
				char* val = (char*)malloc (size);
				memcpy (val, &stringValue, size);

				result = hl_alloc_dynamic (&hlt_bytes);
				result->v.b = val;
				return result;
				break;
			}

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
			{
				long intValue;
				code = curl_easy_getinfo (handle, type, &intValue);

				result = hl_alloc_dynamic (&hlt_i32);
				result->v.i = intValue;
				return result;
				break;
			}

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
			{
				double floatValue;
				code = curl_easy_getinfo (handle, type, &floatValue);

				result = hl_alloc_dynamic (&hlt_f64);
				result->v.d = floatValue;
				return result;
				break;
			}

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

		return NULL;

	}


	value lime_curl_easy_init () {

		curl_gc_mutex.Lock ();

		CURL* curl = curl_easy_init ();
		value handle = CFFIPointer (curl, gc_curl);

		if (curlValid.find (handle) != curlValid.end ()) {

			printf ("Error: Duplicate cURL handle\n");

		}

		if (headerCallbacks.find (handle) != headerCallbacks.end ()) {

			printf ("Error: cURL handle already has a header callback\n");

		}

		if (progressCallbacks.find (handle) != progressCallbacks.end ()) {

			printf ("Error: cURL handle already has a progress callback\n");

		}

		if (readBytes.find (handle) != readBytes.end ()) {

			printf ("Error: cURL handle already has a read data value\n");

		}

		if (writeCallbacks.find (handle) != writeCallbacks.end ()) {

			printf ("Error: cURL handle already has a write callback\n");

		}

		curlValid[handle] = true;
		curlObjects[curl] = handle;

		writeBuffers[handle] = NULL;
		writeBufferPosition[handle] = 0;
		writeBufferSize[handle] = 0;

		CURLcode setopt_result = curl_easy_setopt(curl, CURLOPT_ACCEPT_ENCODING, "");
		if(setopt_result != CURLE_OK) {
			printf("Failed to set CURLOPT_ACCEPT_ENCODING: %s\n", curl_easy_strerror(setopt_result));
		}

		curl_gc_mutex.Unlock ();

		return handle;

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_curl_easy_init) () {

		curl_gc_mutex.Lock ();

		CURL* curl = curl_easy_init ();
		HL_CFFIPointer* handle = HLCFFIPointer (curl, (hl_finalizer)hl_gc_curl);

		if (curlValid.find (handle) != curlValid.end ()) {

			printf ("Error: Duplicate cURL handle\n");

		}

		if (headerCallbacks.find (handle) != headerCallbacks.end ()) {

			printf ("Error: cURL handle already has a header callback\n");

		}

		if (progressCallbacks.find (handle) != progressCallbacks.end ()) {

			printf ("Error: cURL handle already has a progress callback\n");

		}

		if (readBytes.find (handle) != readBytes.end ()) {

			printf ("Error: cURL handle already has a read data value\n");

		}

		if (writeCallbacks.find (handle) != writeCallbacks.end ()) {

			printf ("Error: cURL handle already has a write callback\n");

		}

		curlValid[handle] = true;
		curlObjects[curl] = handle;

		writeBuffers[handle] = NULL;
		writeBufferPosition[handle] = 0;
		writeBufferSize[handle] = 0;

		CURLcode setopt_result = curl_easy_setopt(curl, CURLOPT_ACCEPT_ENCODING, "");
		if(setopt_result != CURLE_OK) {
			printf("Failed to set CURLOPT_ACCEPT_ENCODING: %s\n", curl_easy_strerror(setopt_result));
		}

		curl_gc_mutex.Unlock ();

		return handle;

	}


	int lime_curl_easy_pause (value handle, int bitmask) {

		return curl_easy_pause ((CURL*)val_data(handle), bitmask);

	}


	HL_PRIM int HL_NAME(hl_curl_easy_pause) (HL_CFFIPointer* handle, int bitmask) {

		return curl_easy_pause ((CURL*)handle->ptr, bitmask);

	}


	int lime_curl_easy_perform (value easy_handle) {

		int code;
		System::GCEnterBlocking ();

		code = curl_easy_perform ((CURL*)val_data(easy_handle));

		System::GCExitBlocking ();

		lime_curl_easy_flush (easy_handle);

		return code;

	}


	HL_PRIM int HL_NAME(hl_curl_easy_perform) (HL_CFFIPointer* easy_handle) {

		int code;
		System::GCEnterBlocking ();

		code = curl_easy_perform ((CURL*)easy_handle->ptr);

		System::GCExitBlocking ();

		lime_hl_curl_easy_flush (easy_handle);

		return code;

	}


	int lime_curl_easy_recv (value curl, value buffer, int buflen, int n) {

		// TODO

		return 0;

	}


	HL_PRIM int HL_NAME(hl_curl_easy_recv) (HL_CFFIPointer* curl, double buffer, int buflen, int n) {

		// TODO

		return 0;

	}


	void lime_curl_easy_reset (value curl) {

		curl_easy_reset ((CURL*)val_data(curl));

	}


	HL_PRIM void HL_NAME(hl_curl_easy_reset) (HL_CFFIPointer* curl) {

		curl_easy_reset ((CURL*)curl->ptr);

	}


	int lime_curl_easy_send (value curl, value buffer, int buflen, int n) {

		// TODO

		return 0;

	}


	HL_PRIM int HL_NAME(hl_curl_easy_send) (HL_CFFIPointer* curl, double buffer, int buflen, int n) {

		// TODO

		return 0;

	}


	static size_t header_callback (void *ptr, size_t size, size_t nmemb, void *userp) {

		std::vector<char*>* values = headerValues[userp];

		if (size * nmemb > 0) {

			char* data = (char*)malloc (size * nmemb + 1);
			memcpy (data, ptr, size * nmemb);
			data[size * nmemb] = '\0';
			values->push_back (data);

		}

		return size * nmemb;

	}


	static size_t write_callback (void *ptr, size_t size, size_t nmemb, void *userp) {

		if (size * nmemb < 1) {

			return 0;

		}

		char* buffer = writeBuffers[userp];
		int writeSize = (size * nmemb);

		if (!buffer) {

			buffer = (char*)malloc (CURL_MAX_WRITE_SIZE);
			memcpy (buffer, ptr, writeSize);
			writeBuffers[userp] = buffer;
			writeBufferPosition[userp] = writeSize;
			writeBufferSize[userp] = CURL_MAX_WRITE_SIZE;

		} else {

			int position = writeBufferPosition[userp];
			int currentSize = writeBufferSize[userp];

			if (position + writeSize > currentSize) {

				int newSize = currentSize;
				while (newSize < position + writeSize) newSize += CURL_MAX_WRITE_SIZE;

				buffer = (char*)realloc (buffer, newSize);
				writeBufferSize[userp] = newSize;
				writeBuffers[userp] = buffer;

			}

			memcpy (buffer + position, ptr, writeSize);
			writeBufferPosition[userp] = position + writeSize;

		}

		return writeSize;

	}

	static int seek_callback (void *userp, curl_off_t offset, int origin) {
		if (origin == SEEK_SET)  {
			readBytesPosition[userp] = offset;
			return CURL_SEEKFUNC_OK;
		}
		return CURL_SEEKFUNC_CANTSEEK;
	}

	static size_t read_callback (void *buffer, size_t size, size_t nmemb, void *userp) {

		Bytes* bytes = readBytes[userp];
		int position = readBytesPosition[userp];
		int length = size * nmemb;

		if (bytes->length < position + length) {

			length = bytes->length - position;

		}

		if (length <= 0) return 0;

		memcpy (buffer, bytes->b + position, length);
		readBytesPosition[userp] = position + length;

		return length;

	}


	static int progress_callback (void *userp, double dltotal, double dlnow, double ultotal, double ulnow) {

		CURL_Progress* progress = progressValues[userp];

		progress->dltotal = dltotal;
		progress->dlnow = dlnow;
		progress->ultotal = ultotal;
		progress->ulnow = ulnow;

		return 0;

	}


	static int xferinfo_callback (void *userp, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow) {

		CURL_XferInfo* xferInfo = xferInfoValues[userp];

		xferInfo->dltotal = dltotal;
		xferInfo->dlnow = dlnow;
		xferInfo->ultotal = ultotal;
		xferInfo->ulnow = ulnow;

		return 0;

	}


	int lime_curl_easy_setopt (value handle, int option, value parameter, value bytes) {

		CURLcode code = CURLE_OK;
		CURL* easy_handle = (CURL*)val_data(handle);
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

				code = curl_easy_setopt (easy_handle, type, val_bool (parameter));
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

				code = curl_easy_setopt (easy_handle, type, val_int (parameter));
				break;

			case CURLOPT_POSTFIELDSIZE_LARGE:
			case CURLOPT_RESUME_FROM_LARGE:
			case CURLOPT_INFILESIZE_LARGE:
			case CURLOPT_MAXFILESIZE_LARGE:
			case CURLOPT_MAX_SEND_SPEED_LARGE:
			case CURLOPT_MAX_RECV_SPEED_LARGE:

				code = curl_easy_setopt (easy_handle, type, val_float (parameter));
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

				code = curl_easy_setopt (easy_handle, type, val_string (parameter));
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
				// curl_gc_mutex.Lock ();
				// ValuePointer* callback = new ValuePointer (parameter);
				// readCallbacks[handle] = callback;
				// code = curl_easy_setopt (easy_handle, type, read_callback);
				// curl_easy_setopt (easy_handle, CURLOPT_READDATA, handle);
				// curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_READDATA:
			{
				curl_gc_mutex.Lock ();

				if (readBytes.find (handle) == readBytes.end ()) {

					delete readBytes[handle];
					delete readBytesRoot[handle];

				}

				Bytes* _readBytes = new Bytes (bytes);
				readBytes[handle] = _readBytes;
				readBytesPosition[handle] = 0;
				readBytesRoot[handle] = new ValuePointer (bytes);

				// seek function is needed to support redirects
				curl_easy_setopt (easy_handle, CURLOPT_SEEKFUNCTION, seek_callback);
				curl_easy_setopt (easy_handle, CURLOPT_SEEKDATA, handle);
				code = curl_easy_setopt (easy_handle, CURLOPT_READFUNCTION, read_callback);
				curl_easy_setopt (easy_handle, CURLOPT_READDATA, handle);

				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_WRITEFUNCTION:
			{
				curl_gc_mutex.Lock ();

				if (writeCallbacks.find (handle) == writeCallbacks.end ()) {

					delete writeCallbacks[handle];
					delete writeBytes[handle];
					delete writeBytesRoot[handle];

				}

				ValuePointer* callback = new ValuePointer (parameter);
				writeCallbacks[handle] = callback;
				Bytes* _writeBytes = new Bytes (bytes);
				writeBytes[handle] = _writeBytes;
				writeBytesRoot[handle] = new ValuePointer (bytes);

				code = curl_easy_setopt (easy_handle, type, write_callback);
				curl_easy_setopt (easy_handle, CURLOPT_WRITEDATA, handle);

				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_HEADERFUNCTION:
			{
				curl_gc_mutex.Lock ();

				if (headerCallbacks.find (handle) != headerCallbacks.end ()) {

					free_header_values (headerValues[handle]);
					delete headerCallbacks[handle];
					delete headerValues[handle];

				}

				ValuePointer* callback = new ValuePointer (parameter);
				headerCallbacks[handle] = callback;
				headerValues[handle] = new std::vector<char*> ();

				code = curl_easy_setopt (easy_handle, type, header_callback);
				curl_easy_setopt (easy_handle, CURLOPT_HEADERDATA, handle);

				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_PROGRESSFUNCTION:
			{
				curl_gc_mutex.Lock ();

				if (progressCallbacks.find (handle) != progressCallbacks.end ()) {

					delete progressCallbacks[handle];
					delete progressValues[handle];

				}

				progressCallbacks[handle] = new ValuePointer (parameter);
				progressValues[handle] = new CURL_Progress ();

				code = curl_easy_setopt (easy_handle, type, progress_callback);
				curl_easy_setopt (easy_handle, CURLOPT_PROGRESSDATA, handle);
				curl_easy_setopt (easy_handle, CURLOPT_NOPROGRESS, false);

				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_XFERINFOFUNCTION:
			{
				curl_gc_mutex.Lock ();

				if (xferInfoCallbacks.find (handle) != xferInfoCallbacks.end ()) {

					delete xferInfoCallbacks[handle];
					delete xferInfoValues[handle];

				}

				xferInfoCallbacks[handle] = new ValuePointer (parameter);
				xferInfoValues[handle] = new CURL_XferInfo ();

				code = curl_easy_setopt (easy_handle, type, xferinfo_callback);
				curl_easy_setopt (easy_handle, CURLOPT_XFERINFODATA, handle);
				curl_easy_setopt (easy_handle, CURLOPT_NOPROGRESS, false);

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

				code = curl_easy_setopt (easy_handle, type, chunk);
				curl_gc_mutex.Unlock ();
				break;
			}

			default:

				break;

		}

		return code;

	}


	HL_PRIM int HL_NAME(hl_curl_easy_setopt) (HL_CFFIPointer* handle, int option, vdynamic* parameter, Bytes* bytes) {

		CURLcode code = CURLE_OK;
		CURL* easy_handle = (CURL*)handle->ptr;
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

				code = curl_easy_setopt (easy_handle, type, parameter->v.b);
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

				code = curl_easy_setopt (easy_handle, type, parameter->v.i);
				break;

			case CURLOPT_POSTFIELDSIZE_LARGE:
			case CURLOPT_RESUME_FROM_LARGE:
			case CURLOPT_INFILESIZE_LARGE:
			case CURLOPT_MAXFILESIZE_LARGE:
			case CURLOPT_MAX_SEND_SPEED_LARGE:
			case CURLOPT_MAX_RECV_SPEED_LARGE:

				code = curl_easy_setopt (easy_handle, type, parameter->v.f);
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
			{
				hl_vstring* str = (hl_vstring*)parameter;
				code = curl_easy_setopt (easy_handle, type, str ? hl_to_utf8 (str->bytes) : NULL);
				break;
			}

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
				// curl_gc_mutex.Lock ();
				// ValuePointer* callback = new ValuePointer (parameter);
				// readCallbacks[handle] = callback;
				// code = curl_easy_setopt (easy_handle, type, read_callback);
				// curl_easy_setopt (easy_handle, CURLOPT_READDATA, handle);
				// curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_READDATA:
			{
				curl_gc_mutex.Lock ();

				if (readBytes.find (handle) == readBytes.end ()) {

					delete readBytesRoot[handle];

				}

				readBytes[handle] = bytes;
				readBytesPosition[handle] = 0;
				readBytesRoot[handle] = new ValuePointer ((vobj*)bytes);

				curl_easy_setopt (easy_handle, CURLOPT_SEEKFUNCTION, seek_callback);
				curl_easy_setopt (easy_handle, CURLOPT_SEEKDATA, handle);
				code = curl_easy_setopt (easy_handle, CURLOPT_READFUNCTION, read_callback);
				curl_easy_setopt (easy_handle, CURLOPT_READDATA, handle);

				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_WRITEFUNCTION:
			{
				curl_gc_mutex.Lock ();

				if (writeCallbacks.find (handle) == writeCallbacks.end ()) {

					delete writeCallbacks[handle];
					delete writeBytesRoot[handle];

				}

				ValuePointer* callback = new ValuePointer (parameter);
				writeCallbacks[handle] = callback;
				writeBytes[handle] = bytes;
				writeBytesRoot[handle] = new ValuePointer ((vobj*)bytes);

				code = curl_easy_setopt (easy_handle, type, write_callback);
				curl_easy_setopt (easy_handle, CURLOPT_WRITEDATA, handle);

				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_HEADERFUNCTION:
			{
				curl_gc_mutex.Lock ();

				if (headerCallbacks.find (handle) != headerCallbacks.end ()) {

					free_header_values (headerValues[handle]);
					delete headerCallbacks[handle];
					delete headerValues[handle];

				}

				ValuePointer* callback = new ValuePointer (parameter);
				headerCallbacks[handle] = callback;
				headerValues[handle] = new std::vector<char*> ();

				code = curl_easy_setopt (easy_handle, type, header_callback);
				curl_easy_setopt (easy_handle, CURLOPT_HEADERDATA, handle);

				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_PROGRESSFUNCTION:
			{
				curl_gc_mutex.Lock ();

				if (progressCallbacks.find (handle) != progressCallbacks.end ()) {

					delete progressCallbacks[handle];
					delete progressValues[handle];

				}

				progressCallbacks[handle] = new ValuePointer (parameter);
				progressValues[handle] = new CURL_Progress ();

				code = curl_easy_setopt (easy_handle, type, progress_callback);
				curl_easy_setopt (easy_handle, CURLOPT_PROGRESSDATA, handle);
				curl_easy_setopt (easy_handle, CURLOPT_NOPROGRESS, false);

				curl_gc_mutex.Unlock ();
				break;
			}
			case CURLOPT_XFERINFOFUNCTION:
			{
				curl_gc_mutex.Lock ();

				if (xferInfoCallbacks.find (handle) != xferInfoCallbacks.end ()) {

					delete xferInfoCallbacks[handle];
					delete xferInfoValues[handle];

				}

				xferInfoCallbacks[handle] = new ValuePointer (parameter);
				xferInfoValues[handle] = new CURL_XferInfo ();

				code = curl_easy_setopt (easy_handle, type, xferinfo_callback);
				curl_easy_setopt (easy_handle, CURLOPT_XFERINFODATA, handle);
				curl_easy_setopt (easy_handle, CURLOPT_NOPROGRESS, false);

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
				varray* stringList = (varray*)parameter;
				hl_vstring** stringListData = hl_aptr (stringList, hl_vstring*);
				int size = stringList->size;
				hl_vstring* data;

				for (int i = 0; i < size; i++) {

					data = *stringListData++;
					chunk = curl_slist_append (chunk, data ? hl_to_utf8 (data->bytes) : NULL);

				}

				headerSLists[handle] = chunk;

				code = curl_easy_setopt (easy_handle, type, chunk);
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


	HL_PRIM vbyte* HL_NAME(hl_curl_easy_strerror) (int errornum) {

		const char* result = curl_easy_strerror ((CURLcode)errornum);
		int length = strlen (result);
		char* _result = (char*)malloc (length + 1);
		strcpy (_result, result);
		return (vbyte*)_result;

	}


	value lime_curl_easy_unescape (value curl, HxString url, int inlength, int outlength) {

		char* result = curl_easy_unescape ((CURL*)val_data(curl), url.__s, inlength, &outlength);
		return result ? alloc_string (result) : alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_curl_easy_unescape) (HL_CFFIPointer* curl, hl_vstring* url, int inlength, int outlength) {

		char* result = curl_easy_unescape ((CURL*)curl->ptr, url ? hl_to_utf8 (url->bytes) : NULL, inlength, &outlength);
		int length = strlen (result);
		char* _result = (char*)malloc (length + 1);
		strcpy (_result, result);
		return (vbyte*)_result;

	}


	//lime_curl_formadd;
	//lime_curl_formfree;
	//lime_curl_formget;


	double lime_curl_getdate (HxString datestring, double now) {

		time_t time = (time_t)now;
		return curl_getdate (datestring.__s, &time);

	}


	HL_PRIM double HL_NAME(hl_curl_getdate) (hl_vstring* datestring, double now) {

		time_t time = (time_t)now;
		return curl_getdate (datestring ? hl_to_utf8 (datestring->bytes) : NULL, &time);

	}


	void lime_curl_global_cleanup () {

		curl_global_cleanup ();

	}


	HL_PRIM void HL_NAME(hl_curl_global_cleanup) () {

		curl_global_cleanup ();

	}


	int lime_curl_global_init (int flags) {

		return curl_global_init (flags);

	}


	HL_PRIM int HL_NAME(hl_curl_global_init) (int flags) {

		return curl_global_init (flags);

	}


	int lime_curl_multi_cleanup (value multi_handle) {

		// curl_gc_mutex.Lock ();

		// CURLMcode result = curl_multi_cleanup ((CURLM*)val_data (multi_handle));
		gc_curl_multi (multi_handle);

		// curl_gc_mutex.Unlock ();

		return CURLM_OK;

	}


	HL_PRIM int HL_NAME(hl_curl_multi_cleanup) (HL_CFFIPointer* multi_handle) {

		// curl_gc_mutex.Lock ();

		// CURLMcode result = curl_multi_cleanup ((CURLM*)val_data (multi_handle));
		hl_gc_curl_multi (multi_handle);

		// curl_gc_mutex.Unlock ();

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
		curlMultiHandles[handle] = new std::vector<void*> ();

		curl_gc_mutex.Unlock ();

		return handle;

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_curl_multi_init) () {

		curl_gc_mutex.Lock ();

		HL_CFFIPointer* handle = HLCFFIPointer (curl_multi_init (), (hl_finalizer)hl_gc_curl_multi);

		if (curlMultiValid.find (handle) != curlMultiValid.end ()) {

			printf ("Error: Duplicate cURL Multi handle\n");

		}

		curlMultiValid[handle] = true;
		curlMultiRunningHandles[handle] = 0;
		curlMultiHandles[handle] = new std::vector<void*> ();

		curl_gc_mutex.Unlock ();

		return handle;

	}


	int lime_curl_multi_add_handle (value multi_handle, value curl_object, value curl_handle) {

		curl_gc_mutex.Lock ();

		CURLMcode result = curl_multi_add_handle ((CURLM*)val_data (multi_handle), (CURL*)val_data (curl_handle));

		if (result == CURLM_OK) {

			curlMultiReferences[curl_handle] = multi_handle;
			curlMultiHandles[multi_handle]->push_back (curl_handle);
			curlMultiObjects[curl_handle] = new ValuePointer (curl_object);

		}

		curl_gc_mutex.Unlock ();

		return result;

	}


	HL_PRIM int HL_NAME(hl_curl_multi_add_handle) (HL_CFFIPointer* multi_handle, vdynamic* curl_object, HL_CFFIPointer* curl_handle) {

		curl_gc_mutex.Lock ();

		CURLMcode result = curl_multi_add_handle ((CURLM*)multi_handle->ptr, (CURL*)curl_handle->ptr);

		if (result == CURLM_OK) {

			curlMultiReferences[curl_handle] = multi_handle;
			curlMultiHandles[multi_handle]->push_back (curl_handle);
			curlMultiObjects[curl_handle] = new ValuePointer (curl_object);

		}

		curl_gc_mutex.Unlock ();

		return result;

	}


	int lime_curl_multi_get_running_handles (value multi_handle) {

		return curlMultiRunningHandles[multi_handle];

	}


	HL_PRIM int HL_NAME(hl_curl_multi_get_running_handles) (HL_CFFIPointer* multi_handle) {

		return curlMultiRunningHandles[multi_handle];

	}


	value lime_curl_multi_info_read (value multi_handle) {

		int msgs_in_queue;
		CURLMsg* msg = curl_multi_info_read ((CURLM*)val_data (multi_handle), &msgs_in_queue);

		if (msg) {

			//const field val_id ("msg");
			const field id_curl = val_id ("curl");
			const field id_result = val_id ("result");

			CURL* curl = msg->easy_handle;
			value result = alloc_empty_object ();

			if (curlObjects.find (curl) != curlObjects.end ()) {

				value handle = (value)curlObjects[curl];
				alloc_field (result, id_curl, (value)curlMultiObjects[handle]->Get ());

			} else {

				// TODO?
				alloc_field (result, id_curl, alloc_null ());

			}

			alloc_field (result, id_result, alloc_int (msg->data.result));
			return result;

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM vdynamic* HL_NAME(hl_curl_multi_info_read) (HL_CFFIPointer* multi_handle, vdynamic* result) {

		int msgs_in_queue;
		CURLMsg* msg = curl_multi_info_read ((CURLM*)multi_handle->ptr, &msgs_in_queue);

		if (msg) {

			//const field val_id ("msg");
			const int id_curl = hl_hash_utf8 ("curl");
			const int id_result = hl_hash_utf8 ("result");

			CURL* curl = msg->easy_handle;

			if (curlObjects.find (curl) != curlObjects.end ()) {

				HL_CFFIPointer* handle = (HL_CFFIPointer*)curlObjects[curl];
				hl_dyn_setp (result, id_curl, &hlt_dyn, (vdynamic*)curlMultiObjects[handle]->Get ());

			} else {

				// TODO?
				hl_dyn_setp (result, id_curl, &hlt_dyn, NULL);

			}

			hl_dyn_seti (result, id_result, &hlt_i32, msg->data.result);
			return result;

		} else {

			return NULL;

		}

	}


	int lime_curl_multi_perform (value multi_handle) {

		curl_gc_mutex.Lock ();

		int runningHandles = 0;
		CURLMcode result = curl_multi_perform ((CURLM*)val_data (multi_handle), &runningHandles);

		std::vector<void*>* handles = curlMultiHandles[multi_handle];

		for (std::vector<void*>::iterator it = handles->begin (); it != handles->end (); ++it) {

			curl_gc_mutex.Unlock ();
			lime_curl_easy_flush ((value)*it);
			curl_gc_mutex.Lock ();

		}

		curlMultiRunningHandles[multi_handle] = runningHandles;

		curl_gc_mutex.Unlock ();

		return result;

	}


	HL_PRIM int HL_NAME(hl_curl_multi_perform) (HL_CFFIPointer* multi_handle) {

		curl_gc_mutex.Lock ();

		int runningHandles = 0;
		CURLMcode result = curl_multi_perform ((CURLM*)multi_handle->ptr, &runningHandles);

		std::vector<void*>* handles = curlMultiHandles[multi_handle];

		for (std::vector<void*>::iterator it = handles->begin (); it != handles->end (); ++it) {

			curl_gc_mutex.Unlock ();
			lime_hl_curl_easy_flush ((HL_CFFIPointer*)*it);
			curl_gc_mutex.Lock ();

		}

		curlMultiRunningHandles[multi_handle] = runningHandles;

		curl_gc_mutex.Unlock ();

		return result;

	}


	int lime_curl_multi_remove_handle (value multi_handle, value curl_handle) {

		curl_gc_mutex.Lock ();

		CURLMcode result = curl_multi_remove_handle ((CURLM*)val_data (multi_handle), (CURL*)val_data (curl_handle));

		if (/*result == CURLM_OK &&*/ curlMultiReferences.find (curl_handle) != curlMultiReferences.end ()) {

			curlMultiReferences.erase (curl_handle);

		}

		std::vector<void*>* handles = curlMultiHandles[multi_handle];

		if (handles->size () > 0) {

			for (std::vector<void*>::iterator it = handles->begin (); it != handles->end (); ++it) {

				if (*it == curl_handle) {

					handles->erase (it);
					delete curlMultiObjects[curl_handle];
					curlMultiObjects.erase (curl_handle);
					break;

				}

			}

		}

		curl_gc_mutex.Unlock ();

		return result;

	}


	HL_PRIM int HL_NAME(hl_curl_multi_remove_handle) (HL_CFFIPointer* multi_handle, HL_CFFIPointer* curl_handle) {

		curl_gc_mutex.Lock ();

		CURLMcode result = curl_multi_remove_handle ((CURLM*)multi_handle->ptr, (CURL*)curl_handle->ptr);

		if (/*result == CURLM_OK &&*/ curlMultiReferences.find (curl_handle) != curlMultiReferences.end ()) {

			curlMultiReferences.erase (curl_handle);

		}

		std::vector<void*>* handles = curlMultiHandles[multi_handle];

		if (handles->size () > 0) {

			for (std::vector<void*>::iterator it = handles->begin (); it != handles->end (); ++it) {

				if (*it == curl_handle) {

					handles->erase (it);
					delete curlMultiObjects[curl_handle];
					curlMultiObjects.erase (curl_handle);
					break;

				}

			}

		}

		curl_gc_mutex.Unlock ();

		return result;

	}


	int lime_curl_multi_setopt (value multi_handle, int option, value parameter) {

		CURLMcode code = CURLM_OK;
		CURLM* multi = (CURLM*)val_data (multi_handle);
		CURLMoption type = (CURLMoption)option;

		switch (type) {

			case CURLMOPT_PIPELINING:

				code = curl_multi_setopt (multi, type, val_bool (parameter));
				break;

			case CURLMOPT_MAXCONNECTS:
			case CURLMOPT_MAX_HOST_CONNECTIONS:
			case CURLMOPT_MAX_PIPELINE_LENGTH:
			case CURLMOPT_MAX_TOTAL_CONNECTIONS:
			case CURLMOPT_CONTENT_LENGTH_PENALTY_SIZE:
			case CURLMOPT_CHUNK_LENGTH_PENALTY_SIZE:

				code = curl_multi_setopt (multi, type, val_int (parameter));
				break;

			case CURLMOPT_SOCKETFUNCTION:
			case CURLMOPT_SOCKETDATA:
			case CURLMOPT_TIMERFUNCTION:
			case CURLMOPT_TIMERDATA:
			case CURLMOPT_PUSHFUNCTION:
			case CURLMOPT_PUSHDATA:

				// TODO?
				break;

			case CURLMOPT_PIPELINING_SITE_BL:
			case CURLMOPT_PIPELINING_SERVER_BL:

				// TODO, array to slist
				break;

			default:

				break;

		}

		return code;

	}


	HL_PRIM int HL_NAME(hl_curl_multi_setopt) (HL_CFFIPointer* multi_handle, int option, vdynamic* parameter) {

		CURLMcode code = CURLM_OK;
		CURLM* multi = (CURLM*)multi_handle->ptr;
		CURLMoption type = (CURLMoption)option;

		switch (type) {

			case CURLMOPT_PIPELINING:

				code = curl_multi_setopt (multi, type, parameter->v.b);
				break;

			case CURLMOPT_MAXCONNECTS:
			case CURLMOPT_MAX_HOST_CONNECTIONS:
			case CURLMOPT_MAX_PIPELINE_LENGTH:
			case CURLMOPT_MAX_TOTAL_CONNECTIONS:
			case CURLMOPT_CONTENT_LENGTH_PENALTY_SIZE:
			case CURLMOPT_CHUNK_LENGTH_PENALTY_SIZE:

				code = curl_multi_setopt (multi, type, parameter->v.i);
				break;

			case CURLMOPT_SOCKETFUNCTION:
			case CURLMOPT_SOCKETDATA:
			case CURLMOPT_TIMERFUNCTION:
			case CURLMOPT_TIMERDATA:
			case CURLMOPT_PUSHFUNCTION:
			case CURLMOPT_PUSHDATA:

				// TODO?
				break;

			case CURLMOPT_PIPELINING_SITE_BL:
			case CURLMOPT_PIPELINING_SERVER_BL:

				// TODO, array to slist
				break;

			default:

				break;

		}

		return code;

	}


	int lime_curl_multi_wait (value multi_handle, int timeout_ms) {

		System::GCEnterBlocking ();

		int retcode;
		CURLMcode result = curl_multi_wait ((CURLM*)val_data (multi_handle), 0, 0, timeout_ms, &retcode);

		System::GCExitBlocking ();
		return result;

	}


	HL_PRIM int HL_NAME(hl_curl_multi_wait) (HL_CFFIPointer* multi_handle, int timeout_ms) {

		System::GCEnterBlocking ();

		int retcode;
		CURLMcode result = curl_multi_wait ((CURLM*)multi_handle->ptr, 0, 0, timeout_ms, &retcode);

		System::GCExitBlocking ();
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


	HL_PRIM vbyte* HL_NAME(hl_curl_version) () {

		char* result = curl_version ();
		int length = strlen (result);
		char* _result = (char*)malloc (length + 1);
		strcpy (_result, result);
		return (vbyte*)_result;

	}


	value lime_curl_version_info (int type) {

		curl_version_info_data* data = curl_version_info ((CURLversion)type);

		// TODO

		return alloc_null ();

	}


	HL_PRIM vdynamic* HL_NAME(hl_curl_version_info) (int type) {

		curl_version_info_data* data = curl_version_info ((CURLversion)type);

		// TODO

		return NULL;

	}


	DEFINE_PRIME1v (lime_curl_easy_cleanup);
	DEFINE_PRIME1 (lime_curl_easy_duphandle);
	DEFINE_PRIME3 (lime_curl_easy_escape);
	DEFINE_PRIME2 (lime_curl_easy_getinfo);
	DEFINE_PRIME0 (lime_curl_easy_init);
	DEFINE_PRIME1v (lime_curl_easy_flush);
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
	DEFINE_PRIME1 (lime_curl_multi_cleanup);
	DEFINE_PRIME0 (lime_curl_multi_init);
	DEFINE_PRIME3 (lime_curl_multi_add_handle);
	DEFINE_PRIME1 (lime_curl_multi_get_running_handles);
	DEFINE_PRIME1 (lime_curl_multi_info_read);
	DEFINE_PRIME1 (lime_curl_multi_perform);
	DEFINE_PRIME2 (lime_curl_multi_remove_handle);
	DEFINE_PRIME3 (lime_curl_multi_setopt);
	DEFINE_PRIME2 (lime_curl_multi_wait);
	DEFINE_PRIME0 (lime_curl_version);
	DEFINE_PRIME1 (lime_curl_version_info);


	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN

	DEFINE_HL_PRIM (_VOID, hl_curl_easy_cleanup, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_curl_easy_duphandle, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BYTES, hl_curl_easy_escape, _TCFFIPOINTER _STRING _I32);
	DEFINE_HL_PRIM (_DYN, hl_curl_easy_getinfo, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_curl_easy_init, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_curl_easy_flush, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_curl_easy_pause, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_I32, hl_curl_easy_perform, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_curl_easy_recv, _TCFFIPOINTER _F64 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_curl_easy_reset, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_curl_easy_send, _TCFFIPOINTER _F64 _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_curl_easy_setopt, _TCFFIPOINTER _I32 _DYN _TBYTES);
	DEFINE_HL_PRIM (_BYTES, hl_curl_easy_strerror, _I32);
	DEFINE_HL_PRIM (_BYTES, hl_curl_easy_unescape, _TCFFIPOINTER _STRING _I32 _I32);
	DEFINE_HL_PRIM (_F64, hl_curl_getdate, _STRING _F64);
	DEFINE_HL_PRIM (_VOID, hl_curl_global_cleanup, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_curl_global_init, _I32);
	DEFINE_HL_PRIM (_I32, hl_curl_multi_cleanup, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_curl_multi_init, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_curl_multi_add_handle, _TCFFIPOINTER _DYN _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_curl_multi_get_running_handles, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN, hl_curl_multi_info_read, _TCFFIPOINTER _DYN);
	DEFINE_HL_PRIM (_I32, hl_curl_multi_perform, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_curl_multi_remove_handle, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_curl_multi_setopt, _TCFFIPOINTER _I32 _DYN);
	DEFINE_HL_PRIM (_I32, hl_curl_multi_wait, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_BYTES, hl_curl_version, _NO_ARG);
	DEFINE_HL_PRIM (_DYN, hl_curl_version_info, _I32);


}


extern "C" int lime_curl_register_prims () {

	return 0;

}
