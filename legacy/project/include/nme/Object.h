#ifndef NME_OBJECT_H
#define NME_OBJECT_H

#include "NmeApi.h"

namespace nme
{



class ImageBuffer;


class Object
{
protected:
   virtual ~Object() { }

public:
   Object(bool inInitialRef=0) : mRefCount(inInitialRef?1:0) { }
   Object *IncRef() { mRefCount++; return this; }
   void DecRef() { mRefCount--; if (mRefCount<=0) delete this; }
   virtual int GetRefCount() { return mRefCount; }

   virtual int getApiVersion() { return NME_API_VERSION; }

   virtual ImageBuffer *asImageBuffer() { return 0; }
   virtual void *asReserved1() { return 0; }
   virtual void *asReserved2() { return 0; }
   virtual void *asReserved3() { return 0; }
   virtual void *asReserved4() { return 0; }
   virtual void *asReserved5() { return 0; }
   virtual void *asReserved6() { return 0; }
   virtual void *asReserved7() { return 0; }
   virtual void *asReserved8() { return 0; }
   virtual void *asReserved9() { return 0; }


   int mRefCount;
};

class ApiObject : public Object
{
public:
   ApiObject(bool inInitialRef=0) : Object(inInitialRef) { }

   virtual NmeApi *getApi() { return &gNmeApi; }
};


} // end namespace nme


#endif
