#ifndef NME_RECT_H
#define NME_RECT_H

#include <algorithm>

#ifdef min
#undef min
#undef max
#endif

namespace nme
{

enum GlyphRotation { gr0, gr90, gr180, gr270 };

template<typename T>
struct TRect
{
   T x,y;
   T w,h;

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

};

typedef TRect<int>    Rect;
typedef TRect<double> DRect;




} // end namespace nme



#endif

