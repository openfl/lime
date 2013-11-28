#define CURL_STATICLIB 1
#include <URL.h>
#include <curl/curl.h>
#include <Utils.h>
#include <map>
#include <string>

#ifdef HX_WINDOWS
#include <stdio.h>
#define snprintf _snprintf
#endif

/**
 * TODO:
 * HTTP redirects
 */

namespace lime
{



static std::string sCACertFile("");
static CURLM *sCurlM = 0;
static int sRunning = 0;
static int sLoaders = 0;

typedef std::map<CURL *,class CURLLoader *> CurlMap;
typedef std::vector<class CURLLoader *> CurlList;
void processMultiMessages();

CurlMap *sCurlMap = 0;
CurlList *sCurlList = 0;

enum { MAX_ACTIVE = 64 };

class CURLLoader : public URLLoader
{
public:
	CURL *mHandle;
	int mBytesLoaded;
	int mBytesTotal;
	URLState mState;
	int mHttpCode;
	char mErrorBuf[CURL_ERROR_SIZE];
	QuickVec<unsigned char> mBytes;

  size_t         mBufferRemaining;
  unsigned char *mBufferPos;
  unsigned char *mPutBuffer;

  struct curl_slist *headerlist;

	CURLLoader(URLRequest &r)
	{
		mState = urlInit;
		if (!sCurlM)
			sCurlM = curl_multi_init();
		mBytesTotal = -1;
		mBytesLoaded = 0;
		mHttpCode = 0;
		sLoaders++;
		mHandle = curl_easy_init();
		if (!sCurlMap)
			sCurlMap = new CurlMap;

    mBufferRemaining = 0;
    mPutBuffer = 0;
    mBufferPos = 0;
    headerlist = NULL;

		curl_easy_setopt(mHandle, CURLOPT_URL, r.url);

    /* send all data to this function  */ 
    curl_easy_setopt(mHandle, CURLOPT_WRITEFUNCTION, staticOnData);
    curl_easy_setopt(mHandle, CURLOPT_WRITEDATA, (void *)this);
		curl_easy_setopt(mHandle, CURLOPT_NOPROGRESS, 0);
		curl_easy_setopt(mHandle, CURLOPT_FOLLOWLOCATION, 1);
    if (r.authType!=0)
    {
      curl_easy_setopt(mHandle, CURLOPT_HTTPAUTH, r.authType);
      if (r.credentials && r.credentials[0])
        curl_easy_setopt(mHandle, CURLOPT_USERPWD, r.credentials);
    }
    curl_easy_setopt(mHandle, CURLOPT_PROGRESSFUNCTION, staticOnProgress);
    curl_easy_setopt(mHandle, CURLOPT_PROGRESSDATA, (void *)this);
    curl_easy_setopt(mHandle, CURLOPT_ERRORBUFFER, mErrorBuf );
    if (r.debug)
      curl_easy_setopt(mHandle, CURLOPT_VERBOSE, 1);
    curl_easy_setopt( mHandle, CURLOPT_COOKIEFILE, "" );
    if (r.cookies && r.cookies[0])
      curl_easy_setopt( mHandle, CURLOPT_COOKIE, r.cookies );
    if (sCACertFile.empty())
      curl_easy_setopt(mHandle, CURLOPT_SSL_VERIFYPEER, false);
    else
      curl_easy_setopt(mHandle, CURLOPT_CAINFO, sCACertFile.c_str());

    if (r.method)
    { 
      if (!strcmp(r.method,"POST"))
      {
        curl_easy_setopt(mHandle, CURLOPT_POST, true);

        if (r.postData.Ok())
        {
          curl_easy_setopt(mHandle, CURLOPT_POSTFIELDSIZE, r.postData.Size());
          curl_easy_setopt(mHandle, CURLOPT_COPYPOSTFIELDS, r.postData.Bytes());
        }
      }
      else if (!strcmp(r.method,"PUT"))
      {
        // The file to PUT must be set with CURLOPT_INFILE and CURLOPT_INFILESIZE.
        curl_easy_setopt(mHandle, CURLOPT_PUT, true);

        curl_easy_setopt(mHandle, CURLOPT_UPLOAD, 1);
        if (r.postData.Ok())
          SetPutBuffer(r.postData.Bytes(),r.postData.Size());
      } 
      else if (!strcmp(r.method,"GET"))
      {
        // GET is the default, so this is not necessary but here for completeness.
        curl_easy_setopt(mHandle, CURLOPT_HTTPGET, true);
      }
      else if (!strcmp(r.method,"DELETE"))
      {
        curl_easy_setopt(mHandle, CURLOPT_CUSTOMREQUEST, r.method);
      }
      else
      {
        // unsupported method !!
      }
    }

    if (r.contentType)
    {
      std::vector<char> buffer;
      buffer.resize(512);
      snprintf(&buffer[0], buffer.size(), "Content-Type: %s", r.contentType);
      headerlist = curl_slist_append(headerlist, &buffer[0]);
    }
    headerlist = curl_slist_append(headerlist, "Expect:");

    int n = r.headers.size();
    if (n >= 0) {
      for(int i = 0; i < n; i++)
      {
        URLRequestHeader h = r.headers[i];
        std::vector<char> buffer;
        buffer.resize(512);
        snprintf(&buffer[0], buffer.size(), "%s: %s", h.name, h.value);
        headerlist = curl_slist_append(headerlist, &buffer[0]);
      }
    }

    curl_easy_setopt(mHandle, CURLOPT_HTTPHEADER, headerlist);
 
    mErrorBuf[0] = '\0';
 
    /* some servers don't like requests that are made without a user-agent
      field, so we provide one */ 
    curl_easy_setopt(mHandle, CURLOPT_USERAGENT, "libcurl-agent/1.0");

		mState = urlLoading;

    if (sCurlMap->size()<MAX_ACTIVE)
    {
      StartProcessing();
    }
    else
    {
      if (sCurlList==0)
        sCurlList = new CurlList;
      sCurlList->push_back(this);
    }
  }

  size_t ReadFunc( void *ptr, size_t size, size_t nmemb)
  {
    size_t bytes = size * nmemb;
    if (mBufferRemaining<=bytes)
      bytes = mBufferRemaining;

    memcpy(ptr,mBufferPos,bytes);
    mBufferPos += bytes;
    mBufferRemaining -= bytes;

    return bytes;
  }

  static size_t SReadFunc( void *ptr, size_t size, size_t nmemb, void *userdata)
  {
    return ((CURLLoader *)userdata)->ReadFunc(ptr,size,nmemb);
  }

  void SetPutBuffer(const unsigned char *inBuffer, size_t inLen)
  {
    mPutBuffer = new unsigned char[inLen];
    mBufferRemaining = 0;
    mBufferPos = mPutBuffer;
    memcpy(mPutBuffer,inBuffer,inLen);
    curl_easy_setopt(mHandle, CURLOPT_READFUNCTION, SReadFunc);
    curl_easy_setopt(mHandle, CURLOPT_INFILESIZE, inLen);
  }

  void StartProcessing()
  {
		(*sCurlMap)[mHandle] = this;
    //int c1 = curl_multi_add_handle(sCurlM,mHandle);
    curl_multi_add_handle(sCurlM,mHandle);
    //int result = curl_multi_perform(sCurlM, &sRunning);
    curl_multi_perform(sCurlM, &sRunning);
    processMultiMessages();
	}

	~CURLLoader()
	{
    delete [] mPutBuffer;
		curl_easy_cleanup(mHandle);
		sLoaders--;
		if (sLoaders==0)
		{
			curl_multi_cleanup(sCurlM);
			sCurlM = 0;
		}
	}

	size_t onData( void *inBuffer, size_t inItemSize, size_t inItems)
	{
		size_t size = inItemSize*inItems;
		if (size>0)
		{
			int s = mBytes.size();
			mBytes.resize(s+size);
			memcpy(&mBytes[s],inBuffer,size);
		}
		return inItems;
	}

	int onProgress( double inBytesTotal, double inBytesDownloaded, 
                    double inUploadTotal, double inBytesUploaded )
	{
		mBytesTotal = inBytesTotal;
		mBytesLoaded = inBytesDownloaded;
		return 0;
	}

	void setResult(CURLcode inResult)
	{
		sCurlMap->erase(mHandle);
		curl_multi_remove_handle(sCurlM,mHandle);
		mState = inResult==0 ? urlComplete : urlError;
	}


	static size_t staticOnData( void *inBuffer, size_t size, size_t inItems, void *userdata)
	{
		return ((CURLLoader *)userdata)->onData(inBuffer,size,inItems);
	}

	static size_t staticOnProgress(void* inCookie, double inBytesTotal, double inBytesDownloaded, 
                    double inUploadTotal, double inBytesUploaded)

	{
		return ((CURLLoader *)inCookie)->onProgress(
			inBytesTotal,inBytesDownloaded,inUploadTotal,inBytesUploaded);
	}

   void getCookies( std::vector<std::string> &outCookies )
   {
      curl_slist *list = 0;
		if (CURLE_OK == curl_easy_getinfo(mHandle,CURLINFO_COOKIELIST,&list) && list)
      {
         curl_slist *item = list;
         while(item)
         {
            outCookies.push_back(item->data);
            item = item->next;
         }
         curl_slist_free_all(list);
      }
	}
      

	URLState getState()
	{
		long http_code = 0;
		int curl_code = curl_easy_getinfo(mHandle,CURLINFO_RESPONSE_CODE,&http_code);
		if (curl_code != CURLE_OK)
			mState = urlError;
		else if (http_code>0)
		{
			// XXX : A HTTP code >= 400 should be an error. Handle this in URLLoader.hx for now.
			mHttpCode = http_code;
		}
		return mState;
	}

	int bytesLoaded() { return mBytesLoaded; }
	int bytesTotal() { return mBytesTotal; }

	virtual int getHttpCode() { return mHttpCode; }

	virtual const char *getErrorMessage() { return mErrorBuf; }
	virtual ByteArray releaseData()
	{
		if (mBytes.size())
		{
         return ByteArray(mBytes);
		}
		return ByteArray();
	}


};

void processMultiMessages()
{
		int remaining;
		CURLMsg *msg;
		while( (msg=curl_multi_info_read(sCurlM,&remaining) ) )
		{
			if (msg->msg==CURLMSG_DONE)
			{
				CurlMap::iterator i = sCurlMap->find(msg->easy_handle);
				if (i!=sCurlMap->end())
					i->second->setResult( msg->data.result );
			}
		}
}

bool URLLoader::processAll()
{
   bool added = false;
   do {
      added = false;
	   bool check = sRunning;
	   for(int go=0; go<10 && sRunning; go++)
	   {
		   int code = curl_multi_perform(sCurlM,&sRunning);
		   if (code!= CURLM_CALL_MULTI_PERFORM)
			   break;
	   }
	   if (check) {
         processMultiMessages();
      }
      while(sCurlMap && sCurlList && !sCurlList->empty() && sCurlMap->size()<MAX_ACTIVE )
      {
         CURLLoader *curl = (*sCurlList)[0];
         sCurlList->erase(sCurlList->begin());
         added = true;
         curl->StartProcessing();
      }

   } while(added);
   
   return sRunning || (sCurlList && sCurlList->size());
}

URLLoader *URLLoader::create(URLRequest &r)
{
	return new CURLLoader(r);
}

typedef int (*get_file_callback_func)(const char *filename, unsigned char **buf);
extern "C"
{
extern get_file_callback_func get_file_callback;
}

#if (defined(HX_MACOS) || defined(ANDROID) ) && defined(LIME_CURL_SSL)
#define TRY_GET_FILE
#endif

#ifdef TRY_GET_FILE
static int sGetFile(const char *inFilename, unsigned char **outBuf)
{
   #ifdef ANDROID
   ByteArray bytes = AndroidGetAssetBytes(inFilename);
   #else
   ByteArray bytes = ByteArray::FromFile(inFilename);
   #endif
   
   ELOG("Loaded cert %s %d bytes.", inFilename, bytes.Size());
   if (bytes.Size()>0)
   {
      *outBuf = (unsigned char *)malloc(bytes.Size());
      memcpy(*outBuf,bytes.Bytes(),bytes.Size());
      return bytes.Size();
   }

   return -1;
}
#endif

void URLLoader::initialize(const char *inCACertFilePath)
{
  #ifdef HX_WINDOWS
  unsigned int flags = CURL_GLOBAL_WIN32;
  #else
  unsigned int flags = 0;
  #endif
  curl_global_init(flags | CURL_GLOBAL_SSL);
  sCACertFile = std::string(inCACertFilePath);

  #ifdef TRY_GET_FILE
  get_file_callback = sGetFile;
  #endif


  /* Set to 1 to print version information for libcurl. */
  if (!sCACertFile.empty())
  {
     FILE *f = fopen(sCACertFile.c_str(),"rb");
     bool loaded = f;
     if (f)
        fclose(f);
     ELOG("Open cert file: %s %s\n", sCACertFile.c_str(), loaded ? "Yes" : "NO!!" );
     #ifdef IPHONE
     if (!loaded)
     {
        sCACertFile = GetResourcePath() + gAssetBase + inCACertFilePath;
        FILE *f = fopen(sCACertFile.c_str(),"rb");
        loaded = f;
        if (f)
          fclose(f);
        ELOG("Open cert file: %s %s\n", sCACertFile.c_str(), loaded ? "Yes" : "NO!!" );
     }
     #endif
  }

  #if 0
  curl_version_info_data * info = curl_version_info(CURLVERSION_NOW);
  ELOG("SSL cert: %s\n", inCACertFilePath);
  ELOG("libcurl version: %s\n", info->version);
  ELOG("Support for SSL in libcurl: %d\n", (info->features) & CURL_VERSION_SSL);
  ELOG("Supported libcurl protocols: ");
  for (int i=0; info->protocols[i] != 0; i++) {
    ELOG(" protocol %d: %s",i,  info->protocols[i]);
  }
  #endif
}

}
