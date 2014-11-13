#ifndef NME_URL_H
#define NME_URL_H

#include <nme/Object.h>
#include "ByteArray.h"
#include <vector>
#include <string>
#include <hx/CFFI.h>


namespace nme
{

enum URLState
{
   urlInvalid,
   urlInit,
   urlLoading,
   urlComplete,
   urlError,
};

struct URLRequestHeader
{
   const char *name;
   const char *value;
};

struct URLRequest
{
   const char *url;
   const char *userAgent;
   int        authType;
   const char *credentials;
   const char *cookies;
   const char *method;
   const char *contentType;
   ByteArray  postData;
   bool       debug;
   bool       followRedirects;
   QuickVec<URLRequestHeader> headers; 
};

class URLLoader : public Object
{
   public:
      static URLLoader *create(URLRequest &inRequest);

      static bool processAll();
      static void initialize(const char *inCACertFilePath);

      virtual ~URLLoader() { };
      virtual URLState getState()=0;
      virtual int      bytesLoaded()=0;
      virtual int      bytesTotal()=0;
      virtual int      getHttpCode()=0;
      virtual const char *getErrorMessage()=0;
      virtual ByteArray releaseData()=0;
      virtual void     getCookies( std::vector<std::string> &outCookies )=0;
      virtual void getResponseHeaders( std::vector<std::string> &outHeaders )=0;
};

}



#endif


