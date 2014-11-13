#ifndef NME_FIXED_POINT_H
#define NME_FIXED_POINT_H

namespace nme
{

template<int FIXED>
struct FixedPoint
{
   int x;
   int y;

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
};

typedef FixedPoint<10> Fixed10;

} // end namespace nme

#endif


