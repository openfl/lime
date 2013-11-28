#include <URL.h>

namespace lime
{


class WinRTURLLoader : public URLLoader
{
public:
   WinRTURLLoader(URLRequest &inRequest)
   {
   }

   ~WinRTURLLoader()
   {
   }

   URLState getState()
   {
      return urlError;
   }

   int bytesLoaded()
   {
      return 0;
   }

   int bytesTotal()
   {
      return 0;
   }

   int  getHttpCode()
   {
      return 404;
   }

   const char *getErrorMessage()
   {
      return "";
   }

   ByteArray releaseData()
   {
      return ByteArray();
   }

   void  getCookies( std::vector<std::string> &outCookies )
   {
   }
};


URLLoader *URLLoader::create(URLRequest &inRequest)
{
   return new WinRTURLLoader(inRequest);
}

bool URLLoader::processAll()
{
   return false;
}

void URLLoader::initialize(const char *inCACertFilePath)
{
}


}
