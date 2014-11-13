#ifndef NME_EXTENT_H
#define NME_EXTENT_H

namespace nme
{

   


template<typename T_>
struct Extent2D
{
   T_ minX,maxX;
   T_ minY,maxY;
   bool validX,validY;


   Extent2D() : validX(false), validY(false)
   {
      minX = minY = maxX = maxY = 0;
   }

   template<typename P_>
   inline void AddX(P_ inX)
   {
      if (validX)
      {
         if (inX<minX) minX = (T_)inX;
         else if (inX>maxX) maxX = (T_)inX;
      }
      else
      {
         minX = maxX = (T_)inX;
         validX = true;
      }

   }

   template<typename P_>
   inline void AddY(P_ inY)
   {
      if (validY)
      {
         if (inY<minY) minY = (T_)inY;
         else if (inY>maxY) maxY = (T_)inY;
      }
      else
      {
         minY = maxY = (T_)inY;
         validY = true;
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
      if (inExtent.validX)
      {
         AddX(inExtent.minX);
         AddX(inExtent.maxX);
      }
      if (inExtent.validY)
      {
         AddY(inExtent.minY);
         AddY(inExtent.maxY);
      }
   }

   bool Intersect(T_ inX0,T_ inY0, T_ inX1, T_ inY1)
   {
      if (!validX)
      {
         minX = inX0;
         maxX = inX1;
         validX = true;
      }
      else
      {
         if (inX0 > minX) minX = inX0;
         if (inX1 < maxX) maxX = inX1;
      }
      if (!validY)
      {
         minY = inY0;
         maxY = inY1;
         validY = true;
      }
      else
      {
         if (inY0 > minY) minY = inY0;
         if (inY1 < maxY) maxY = inY1;
      }
      return minX<maxX && minY<maxY;
   }

   template<typename O_>
   bool Contains(const O_ &inOther) const
   {
      return validX && validY && inOther.x>=minX && inOther.x<maxX &&
             inOther.y>=minY && inOther.y<maxY;
   }


   void Translate(int inTX,int inTY)
   {
      minX += inTX;
      maxX += inTX;
      minY += inTY;
      maxY += inTY;
   }

   void Transform(double inSX, double inSY, double inTX, double inTY)
   {
      minX = inTX + inSX*(minX);
      maxX = inTX + inSX*(maxX);
      minY = inTY + inSY*(minY);
      maxY = inTY + inSY*(maxY);
   }

   TRect<T_> Rect() const
   {
      if (!Valid()) return TRect<T_>(0,0,0,0);
      return TRect<T_>(minX,minY,maxX,maxY,true);
   }

   template<typename RECT>
   bool GetRect(RECT &outRect,double inExtraX=0,double inExtraY=0)
   {
       if (!Valid())
       {
          outRect = RECT(0,0,0,0);
          return false;
       }

       outRect = RECT(minX,minY,maxX+inExtraX,maxY+inExtraY,true);
       return true;
   }

   inline bool Valid() const { return validX && validY; }
   void Invalidate() { validX = validY = false; }

   T_ Width() const { return maxX-minX; }
   T_ Height() const { return maxY-minY; }

};

typedef Extent2D<int> Extent2DI;
typedef Extent2D<float> Extent2DF;



} // end namespace nme

#endif



