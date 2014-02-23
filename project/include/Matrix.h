#ifndef LIME_MATRIX_H
#define LIME_MATRIX_H

#include <Geom.h>
#include <string.h>

namespace lime {

class Matrix
{
public:
   Matrix(double inSX=1,double inSY=1, double inTX=0, double inTY=0) :
       m00(inSX), m01(0), mtx(inTX),
       m10(0), m11(inSY), mty(inTY), mtz(0)
   {
   }

   Matrix Mult(const Matrix &inLHS) const;

   bool IsIdentity() const
      { return m00==1.0 && m01==0.0 && mtx==0.0 &&
               m10==0.0 && m11==1.0 && mty==0.0; }
   bool IsIntTranslation() const
      { return m00==1.0 && m01==0.0 && mtx==(int)mtx &&
               m10==0.0 && m11==1.0 && mty==(int)mty; }
   bool IsIntTranslation(const Matrix &inRHS,int &outTX,int &outTY) const
   {
      if (m00!=inRHS.m00 || m01!=inRHS.m01 || m10!=inRHS.m10 || m11!=inRHS.m11)
         return false;
      double dx = inRHS.mtx - mtx;
      int idx = (int)dx;
      if (dx!=idx)
         return false;
      double dy = inRHS.mty - mty;
      int idy = (int)dy;
      if (dy!=idy)
         return false;
      outTX = idx;
      outTY = idy;
      return true;
   }

	double GetScaleX() const;
	double GetScaleY() const;

	Matrix &Rotate(double inDeg);
	Matrix &Translate(double inTX, double inTY);
	Matrix Translated(double inTX, double inTY)
	{
		Matrix mat(*this);
		return mat.Translate(inTX,inTY);
	}
	Matrix &Scale(double inSX, double inSY);
	Matrix &operator *= (double inScale);


   Matrix &createGradientBox(double inWidth, double inHeight=0,
                             double inRot=0, double inTX=0, double inTY=0 );

   inline bool operator==(const Matrix &inRHS) const
      { return !memcmp(this,&inRHS,sizeof(*this)); }
   inline bool operator!=(const Matrix &inRHS) const
      { return memcmp(this,&inRHS,sizeof(*this))!=0; }

   Matrix Invert2x2() const;
   void MatchTransform(double inX,double inY,double inTargetX,double inTargetY);


   UserPoint Apply(float inX,float inY) const;

   void ContravariantTrans(const Matrix &inMtx, Matrix &outTrans) const;

   Matrix Inverse() const;
   UserPoint ApplyInverse(const UserPoint &inPoint) const;

   void GLMult() const;

   Matrix &TranslateData(double inTX, double inTY);

   double m00, m01, mtx;
   double m10, m11, mty;
   double mtz;
};




typedef Matrix Matrix3D;

} // end namespace lime

#endif
