#ifndef NME_SCALE9_H
#define NME_SCALE9_H

#include <Matrix.h>
#include <Geom.h>

namespace nme
{

class Scale9
{
public:
   bool   mActive;
   double X0,Y0;
   double X1,Y1;
   double SX,SY;
   double X1Off,Y1Off;
   
   Scale9() : mActive(false) { }
   bool Active() const { return mActive; }
   void Activate(const DRect &inGrid, const Extent2DF &inExt, double inSX, double inSY)
   {
      mActive = true;

      double fixed_x0 = inGrid.x - inExt.mMinX;
      double fixed_x1 = inExt.mMaxX - inGrid.x1();
      X0 = inGrid.x;
      X1 = inGrid.x1();
      X1Off = inExt.mMaxX*inSX - fixed_x1 - X1;
      SX = inGrid.w ? (inExt.Width()*inSX - fixed_x0 - fixed_x1)/inGrid.w : 0;

      double fixed_y0 = inGrid.y - inExt.mMinY;
      double fixed_y1 = inExt.mMaxY - inGrid.y1();
      Y0 = inGrid.y;
      Y1 = inGrid.y1();
      Y1Off = inExt.mMaxY*inSY - fixed_y1 - Y1;
      SY = inGrid.h ? (inExt.Height()*inSY - fixed_y0 - fixed_y1)/inGrid.h : 0;
   }
   void Deactivate() { mActive = false; }
   bool operator==(const Scale9 &inRHS) const
   {
      if (mActive!=inRHS.mActive) return false;
      if (!mActive) return true;
      return X0==inRHS.X0 && X1==inRHS.X1 && Y0==inRHS.Y0 && Y1==inRHS.Y1 &&
             X1Off==inRHS.X1Off && Y1Off==inRHS.Y1Off;
   }
   bool operator!=(const Scale9 &inRHS) const { return ! operator==(inRHS); }
   double TransX(double inX) const
   {
      if (inX<=X0) return inX;
      return inX>X1 ? inX + X1Off : X0 + (inX-X0)*SX;
   }
   double TransY(double inY) const
   {
      if (inY<=Y0) return inY;
      return inY>Y1 ? inY + Y1Off : Y0 + (inY-Y0)*SY;
   }
   double InvTransX(double inX) const
   {
      if (inX<=X0) return inX;
      return inX>X1 ? inX - X1Off : X0 + (inX-X0)/(SX<=0 ? 1e-99 : SX);
   }
   double InvTransY(double inY) const
   {
      if (inY<=Y0) return inY;
      return inY>Y1 ? inY - Y1Off : Y0 + (inY-Y0)/(SY<=0 ? 1e-99 : SY);
   }

   Matrix GetFillMatrix(const Extent2DF &inExtent)
   {
      // The mapping of the edges should remain unchanged ...
      double x0 = TransX(inExtent.mMinX);
      double x1 = TransX(inExtent.mMaxX);
      double y0 = TransY(inExtent.mMinY);
      double y1 = TransY(inExtent.mMaxY);
      double w = inExtent.Width();
      double h = inExtent.Height();
      Matrix result;
      result.mtx = -inExtent.mMinX;
      if (w!=0)
      {
         double s = (x1-x0)/w;
         result.m00 = s;
         result.mtx *= s;
      }
      result.mtx += x0;

      result.mty = -inExtent.mMinY;
      if (h!=0)
      {
         double s = (y1-y0)/h;
         result.m11 = s;
         result.mty *= s;
      }
      result.mty += y0;
      return result;
   }

};


} // end namespace nme


#endif

