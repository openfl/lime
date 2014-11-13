#ifndef NME_GEOM_H
#define NME_GEOM_H

#include <vector>
#include <math.h>
#include <nme/Rect.h>
#include <nme/Point.h>
#include <nme/FixedPoint.h>
#include <nme/Extent.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


namespace nme
{

#ifdef WIN32
typedef __int64 int64;
#else
typedef long long int64;
#endif


struct Tri
{
   Tri(int i0=0, int i1=0, int i2=0)
   {
      mIndex[0] = i0;
      mIndex[1] = i1;
      mIndex[2]=i2;
   }
   int mIndex[3];
};


} // end namespace nme

#endif
