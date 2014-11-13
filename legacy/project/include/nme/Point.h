#ifndef NME_POINT_H
#define NME_POINT_H

#include <math.h>

namespace nme
{

template<typename T>
struct Point2D
{
   T x;
   T y;

   inline Point2D() { }
   inline Point2D(T inX,T inY) : x(inX), y(inY) { }
   inline Point2D(T *inPtr) : x(inPtr[0]), y(inPtr[1]) { }

   inline bool operator==(const Point2D &inRHS) const
      { return x==inRHS.x && y==inRHS.y; }
   inline bool operator!=(const Point2D &inRHS) const
      { return x!=inRHS.x || y!=inRHS.y; }

   inline Point2D &operator+=(const Point2D &inRHS)
      { x+=inRHS.x;y+=inRHS.y; return *this; }
   inline Point2D &operator-=(const Point2D &inRHS)
      { x-=inRHS.x;y-=inRHS.y; return *this; }
   inline Point2D operator+(const Point2D &inRHS) const
      { return Point2D(x+inRHS.x,y+inRHS.y); }
   inline Point2D operator-(const Point2D &inRHS) const
      { return Point2D(x-inRHS.x,y-inRHS.y); }
   inline Point2D operator*(double inScale) const
      { return Point2D(x*inScale,y*inScale); }
   inline Point2D operator-() const
      { return Point2D(-x,-y); }
   inline T Norm2() const
      { return x*x + y*y; }
   inline Point2D Normalized() const
   {
      double len = sqrt((double)(x*x + y*y));
      if (len>0)
         return Point2D(x/len,y/len);
      return *this;
   }
   inline double Norm() const
      { return sqrt((double)(x*x + y*y)); }
   inline Point2D Perp() const
      { return Point2D(-y,x); }
   inline Point2D CWPerp() const
      { return Point2D(y,-x); }
   inline Point2D Perp(double inLen) const
   {
      double norm = Norm();
      if (norm>0)
      {
         norm = inLen/norm;
         return Point2D(-y*norm,x*norm);
      }
      return Point2D(0,0);
   }
   inline double Cross(const Point2D &inRHS) const
      { return x*inRHS.y - y*inRHS.x; }
   inline double Dot(const Point2D &inRHS) const
      { return x*inRHS.x + y*inRHS.y; }
   inline double Dist2(const Point2D &inRHS) const
      { return (*this-inRHS).Norm2(); }
   Point2D &SetLength(double inLen)
   {
      double norm = Norm();
      if (norm>0)
      {
         norm = inLen/norm;
         x*=norm;
         y*=norm;
      }
      return *this;
   }
   inline bool operator<(const Point2D &inRHS) const
   {
      if (y<inRHS.y) return true;
      if (y>inRHS.y) return false;
      return x<inRHS.x;
   }
   inline bool operator>(const Point2D &inRHS) const
   {
      if (y>inRHS.y) return true;
      if (y<inRHS.y) return false;
      return x>inRHS.x;
   }
};


typedef Point2D<float> UserPoint;
typedef Point2D<int>   ImagePoint;

} // end namespace nme

#endif
