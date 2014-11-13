#include <CachedExtent.h>

namespace nme
{

int gCachedExtentID = 1;

// --- CachedExtent --------------------------------------

Extent2DF CachedExtent::Get(const Transform &inTransform)
{
   mID = gCachedExtentID++;
   if (!mExtent.Valid())
      return Extent2DF();
   /*
   double ratio = mMatrix.m00!=0.0 ? inTransform.mMatrix->m00/mMatrix.m00 :
                  mMatrix.m01!=0.0 ? inTransform.mMatrix->m01/mMatrix.m01 : 1.0;
   */
   double ratio = 1;
   Extent2DF result = mExtent;
   result.Transform(ratio, ratio, inTransform.mMatrix->mtx - mMatrix.mtx,
                                  inTransform.mMatrix->mty - mMatrix.mty);
   return result;
}

// --- CachedExtentRenderer --------------------------------------

bool CachedExtentRenderer::GetExtent(const Transform &inTransform,Extent2DF &ioExtent,bool inIncludeStroke)
{
   Matrix test = *inTransform.mMatrix;
   /*
   Do not normalize for scale ...
   double norm = test.m00*test.m00 + test.m01*test.m01 +
                 test.m10*test.m10 + test.m11*test.m11;
   if (norm<=0)
      return true;
   norm = 1.0/sqrt(norm);
   test.m00 *= norm;
   test.m01 *= norm;
   test.m10 *= norm;
   test.m11 *= norm;
   */
   test.mtx = 0;
   test.mty = 0;

   int smallest = mExtentCache[0].mID;
   int slot = 0;
   for(int i=0;i<3;i++)
   {
      CachedExtent &cache = mExtentCache[i];
      if (cache.mIsSet && test==cache.mTestMatrix &&
            *inTransform.mScale9==cache.mScale9 && cache.mIncludeStroke==inIncludeStroke)
      {
         // Maybe set but not valid - ie, 0 size
         if (cache.mExtent.Valid())
            ioExtent.Add(cache.Get(inTransform));
         return true;
      }
      if (cache.mID<gCachedExtentID)
         cache.mID = gCachedExtentID;

      if (cache.mID<smallest)
      {
         smallest = cache.mID;
         slot = i;
      }
   }

   // Not in cache - fill slot
   CachedExtent &cache = mExtentCache[slot];
   cache.mMatrix = *inTransform.mMatrix;
   cache.mTestMatrix = test;
   cache.mScale9 = *inTransform.mScale9;
   cache.mTransform = inTransform;
   cache.mTransform.mMatrix = &cache.mMatrix;
   cache.mTransform.mMatrix3D = &cache.mMatrix;
   cache.mTransform.mScale9 = &cache.mScale9;
   cache.mIncludeStroke = inIncludeStroke;
   cache.mIsSet = true;
   GetExtent(cache);

   cache.Get(inTransform);

   ioExtent.Add(cache.mExtent);

   return true;
}

} // end namespace nme

