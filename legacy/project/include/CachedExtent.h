#ifndef NME_CACHED_EXTENT_H
#define NME_CACHED_EXTENT_H

#include <Graphics.h>
#include <Scale9.h>

namespace nme
{

extern int gCachedExtentID;
struct CachedExtent
{
   CachedExtent() : mID(0), mIncludeStroke(false), mIsSet(false), mForScreen(false) {}
   Extent2DF Get(const Transform &inTransform);

   Transform mTransform;
   Matrix    mTestMatrix;
   Matrix    mMatrix;
   Scale9    mScale9;
   Extent2DF mExtent;
   bool      mIncludeStroke;
   bool      mIsSet;
   bool      mForScreen;
   int       mID;
};



class CachedExtentRenderer : public Renderer
{
public:
   bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent,bool inIncludeStroke);
   bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent,bool inForBitmap,bool inIncludeStroke);


   // Implement this one instead...
   virtual void GetExtent(CachedExtent &ioCache) = 0;

private:
   CachedExtent mExtentCache[3];
};

} // end namespace NME

#endif
