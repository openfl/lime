#ifndef LIME_GEOM_H
#define LIME_GEOM_H

#include <vector>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace lime
{

enum GlyphRotation { gr0, gr90, gr180, gr270 };

#ifdef WIN32
typedef __int64 int64;
#else
typedef long long int64;
#endif


template<typename T>
struct TRect
{
   TRect(T inW=0,T inH=0) : x(0), y(0), w(inW), h(inH) { } 
   TRect(T inX,T inY,T inW,T inH) : x(inX), y(inY), w(inW), h(inH) { } 
   TRect(T inX0,T inY0,T inX1,T inY1, bool inDummy) :
      x(inX0), y(inY0), w(inX1-inX0), h(inY1-inY0) { } 

   TRect Intersect(const TRect &inOther) const
   {
      T x0 = std::max(x,inOther.x);
      T y0 = std::max(y,inOther.y);
      T x1 = std::min(this->x1(),inOther.x1());
      T y1 = std::min(this->y1(),inOther.y1());
      return TRect(x0,y0,x1>x0 ? x1-x0 : 0, y1>y0 ? y1-y0 : 0);
   }
   TRect Union(const TRect &inOther) const
   {
      T x0 = std::min(x,inOther.x);
      T y0 = std::min(y,inOther.y);
      T x1 = std::max(this->x1(),inOther.x1());
      T y1 = std::max(this->y1(),inOther.y1());
      return TRect(x0,y0,x1>x0 ? x1-x0 : 0, y1>y0 ? y1-y0 : 0);
   }
   bool operator==(const TRect &inRHS) const
      { return x==inRHS.x && y==inRHS.y && w==inRHS.w && h==inRHS.h; }
   bool operator!=(const TRect &inRHS) const
      { return x!=inRHS.x || y!=inRHS.y || w!=inRHS.w || h!=inRHS.h; }
   TRect operator *(T inScale) const { return TRect(x*inScale,y*inScale,w*inScale,h*inScale); }
   TRect operator /(T inScale) const { return TRect(x/inScale,y/inScale,w/inScale,h/inScale); }
   T x1() const { return x+w; }
   T y1() const { return y+h; }
   void Translate(T inTx,T inTy) { x+=inTx; y+= inTy; }
   bool HasPixels() const { return w>0 && h>0; }
	T Area() const { return w * h; }
   bool Contains(const TRect &inOther) const
   {
      return inOther.x>=x && inOther.x1()<=x1() &&
             inOther.y>=y && inOther.y1()<=y1();
   }

	template<typename T_>
   bool Contains(const T_ &inOther) const
   {
      return inOther.x>=x && inOther.x<x1() &&
             inOther.y>=y && inOther.y<y1();
   }

	TRect Rotated(GlyphRotation inRotation) const
	{
		switch(inRotation)
		{
         case gr0: break;
         case gr90: return TRect(y-h,x,h,w);
			case gr180: return TRect(-x-w,-y-h,w,h);
			case gr270: return TRect(-y,-x-w,h,w);
		}
		return *this;
	}


   void ClipY(T &ioY0, T &ioY1) const
   {
      if (ioY0 < y) ioY0 = y;
      else if (ioY0>y+h) ioY0 = y+h;

      if (ioY1 < y) ioY1 = y;
      else if (ioY1>y+h) ioY1 = y+h;
   }

   void ClipX(T &ioX0, T &ioX1) const
   {
      if (ioX0 < x) ioX0 = x;
      else if (ioX0>x+w) ioX0 = x+w;

      if (ioX1 < x) ioX1 = x;
      else if (ioX1>x+w) ioX1 = x+w;
   }

   TRect Translated(T inTX,T inTY) const
   {
      return TRect(x+inTX,y+inTY,w,h);
   }
	template<typename POINT>
	TRect Translated(const POINT &inPoint) const
   {
      return TRect(x+inPoint.x,y+inPoint.y,w,h);
   }

   void MakePositive()
   {
      if (w<0) { x-=w; w=-w; }
      if (h<0) { y-=h; h=-h; }
   }
	TRect &RemoveBorder(T inBorder)
	{
		if (w<inBorder*2) { x+= w/2; w = 0; }
		else { x+=inBorder; w-=inBorder*2; }

		if (h<inBorder*2) { y+= h/2; h = 0; }
		else { y+=inBorder; h-=inBorder*2; }

		return *this;
	}



   T x,y;
   T w,h;
};

typedef TRect<int>    Rect;
typedef TRect<double> DRect;



template<typename T>
struct Point2D
{
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
	inline bool operator < (const Point2D &inRHS) const
	{
		if (y<inRHS.y) return true;
		if (y>inRHS.y) return false;
		return x<inRHS.x;
	}
	inline bool operator > (const Point2D &inRHS) const
	{
		if (y>inRHS.y) return true;
		if (y<inRHS.y) return false;
		return x>inRHS.x;
	}

   T x;
   T y;
};


typedef Point2D<float> UserPoint;
typedef Point2D<int>   ImagePoint;


template<int FIXED>
struct FixedPoint
{
   enum { Bits = FIXED };

   inline FixedPoint() {}
   inline FixedPoint(int inX,int inY) :x(inX), y(inY) {}
   inline FixedPoint(double inX,double inY)
   {
      x =  (int)(inX * (double)(1<<Bits) );
      y =  (int)(inY * (double)(1<<Bits));
   }

   inline int X() const { return x>>Bits; };
   inline int Y() const { return y>>Bits; };
   inline int X(int inAABits) const { return x>>(Bits-inAABits); };
   inline int Y(int inAABits) const { return y>>(Bits-inAABits); };

   inline FixedPoint(const FixedPoint &inRHS) :x(inRHS.x), y(inRHS.y) {}
   inline FixedPoint(const ImagePoint &inRHS) :
                x(inRHS.x<<Bits), y(inRHS.y<<Bits) { }
   
   inline bool operator==(const FixedPoint inRHS) const
      { return x==inRHS.x && y==inRHS.y; }

   inline bool operator!=(const FixedPoint inRHS) const
      { return x!=inRHS.x && y!=inRHS.y; }


   inline FixedPoint operator-(const FixedPoint inRHS) const
      { return FixedPoint(x-inRHS.x,y-inRHS.y); }

   inline FixedPoint operator+(const FixedPoint inRHS) const
      { return FixedPoint(x+inRHS.x,y+inRHS.y); }

   inline FixedPoint operator*(int inScalar) const
      { return FixedPoint(x*inScalar,y*inScalar); }

   inline FixedPoint operator/(int inDivisor) const
      { return FixedPoint(x/inDivisor,y/inDivisor); }

   inline FixedPoint operator>>(int inShift) const
      { return FixedPoint(x>>inShift,y>>inShift); }

   inline FixedPoint operator<<(int inShift) const
      { return FixedPoint(x<<inShift,y<<inShift); }

   inline void operator+=(const FixedPoint &inRHS)
      { x+=inRHS.x, y+=inRHS.y; }

   int x;
   int y;
};

typedef FixedPoint<10> Fixed10;


template<typename T_>
struct Extent2D
{
   Extent2D() : mValidX(false), mValidY(false)
   {
      mMinX = mMinY = mMaxX = mMaxY = 0;
   }


   template<typename P_>
   inline void AddX(P_ inX)
   {
      if (mValidX)
      {
         if (inX<mMinX) mMinX = (T_)inX;
         else if (inX>mMaxX) mMaxX = (T_)inX;
      }
      else
      {
         mMinX = mMaxX = (T_)inX;
         mValidX = true;
      }

   }

   template<typename P_>
   inline void AddY(P_ inY)
   {
      if (mValidY)
      {
         if (inY<mMinY) mMinY = (T_)inY;
         else if (inY>mMaxY) mMaxY = (T_)inY;
      }
      else
      {
         mMinY = mMaxY = (T_)inY;
         mValidY = true;
      }
   }

   template<typename P_>
   inline void Add(P_ inX, P_ inY)
   {
      AddX(inX);
      AddY(inY);
   }


   template<typename P_>
   inline void Add(const P_ &inPoint)
   {
      AddX(inPoint.x);
      AddY(inPoint.y);
   }

   inline void Add(const Extent2D<T_> &inExtent)
   {
      if (inExtent.mValidX)
      {
         AddX(inExtent.mMinX);
         AddX(inExtent.mMaxX);
      }
      if (inExtent.mValidY)
      {
         AddY(inExtent.mMinY);
         AddY(inExtent.mMaxY);
      }
   }

   bool Intersect(T_ inX0,T_ inY0, T_ inX1, T_ inY1)
   {
      if (!mValidX)
      {
         mMinX = inX0;
         mMaxX = inX1;
         mValidX = true;
      }
      else
      {
         if (inX0 > mMinX) mMinX = inX0;
         if (inX1 < mMaxX) mMaxX = inX1;
      }
      if (!mValidY)
      {
         mMinY = inY0;
         mMaxY = inY1;
         mValidY = true;
      }
      else
      {
         if (inY0 > mMinY) mMinY = inY0;
         if (inY1 < mMaxY) mMaxY = inY1;
      }
      return mMinX<mMaxX && mMinY<mMaxY;
   }

	template<typename O_>
   bool Contains(const O_ &inOther) const
   {
		return mValidX && mValidY && inOther.x>=mMinX && inOther.x<mMaxX &&
             inOther.y>=mMinY && inOther.y<mMaxY;
   }




   void Translate(int inTX,int inTY)
   {
      mMinX += inTX;
      mMaxX += inTX;
      mMinY += inTY;
      mMaxY += inTY;
   }

   void Transform(double inSX, double inSY, double inTX, double inTY)
   {
      mMinX = inTX + inSX*(mMinX);
      mMaxX = inTX + inSX*(mMaxX);
      mMinY = inTY + inSY*(mMinY);
      mMaxY = inTY + inSY*(mMaxY);
   }

   TRect<T_> Rect() const
   {
      if (!Valid()) return TRect<T_>(0,0,0,0);
      return TRect<T_>(mMinX,mMinY,mMaxX,mMaxY,true);
   }

   template<typename RECT>
   bool GetRect(RECT &outRect,double inExtraX=0,double inExtraY=0)
   {
       if (!Valid())
       {
          outRect = RECT(0,0,0,0);
          return false;
       }

       outRect = RECT(mMinX,mMinY,mMaxX+inExtraX,mMaxY+inExtraY,true);
       return true;
   }



   inline bool Valid() const { return mValidX && mValidY; }
   void Invalidate() { mValidX = mValidY = false; }

   T_ Width() const { return mMaxX-mMinX; }
   T_ Height() const { return mMaxY-mMinY; }

   T_ mMinX,mMaxX;
   T_ mMinY,mMaxY;
   bool mValidX,mValidY;
};

typedef Extent2D<int> Extent2DI;
typedef Extent2D<float> Extent2DF;


struct Tri
{
   Tri(int i0=0, int i1=0, int i2=0) { mIndex[0] = i0; mIndex[1] = i1; mIndex[2]=i2; }
   int mIndex[3];
};


} // end namespace lime

#endif
