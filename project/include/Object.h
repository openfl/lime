#ifndef LIME_OBJECT_H
#define LIME_OBJECT_H

namespace lime
{

class Object
{
public:
	Object(bool inInitialRef=0) : mRefCount(inInitialRef?1:0) { }
	Object *IncRef() { mRefCount++; return this; }
	void DecRef() { mRefCount--; if (mRefCount<=0) delete this; }
   int GetRefCount() { return mRefCount; }

protected:
	virtual ~Object() { }

   int mRefCount;
};

} // end namespace lime


#endif
