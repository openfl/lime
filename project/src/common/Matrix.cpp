#include <math.h>
#include <Matrix.h>

#ifndef M_PI
#define M_PI 3.141592653589793238462643
#endif

namespace lime
{

UserPoint Matrix::Apply(float inX,float inY) const
{
   return UserPoint( inX*m00 + inY*m01 + mtx,
                     inX*m10 + inY*m11 + mty  );
}



/*

inline static void Set(double &outVal, value inValue)
{
   //if ( val_is_float(inValue) )
      outVal = val_number(inValue);
}

Matrix::Matrix(value inMatrix)
{
   m01 = m10 = mtx = mty = 0.0;
   m00 = m11 = 1.0;

   static int a_id = val_id("a");
   static int b_id = val_id("b");
   static int c_id = val_id("c");
   static int d_id = val_id("d");
   static int tx_id = val_id("tx");
   static int ty_id = val_id("ty");

   if (val_is_object( inMatrix ) )
   {
      Set(m00,val_field(inMatrix,a_id));
      // Note: change in meaning of "c" and "b"
      Set(m01,val_field(inMatrix,c_id));
      Set(m10,val_field(inMatrix,b_id));

      Set(m11,val_field(inMatrix,d_id));
      Set(mtx,val_field(inMatrix,tx_id));
      Set(mty,val_field(inMatrix,ty_id));
   }
}



static void Dump(const char *inName,const Matrix &inMtx)
{
   printf("%s x: %f %f %f\n", inName, inMtx.m00, inMtx.m01,  inMtx.mtx);
   printf("%s y: %f %f %f\n", inName, inMtx.m10, inMtx.m11,  inMtx.mty);
}
*/

void Matrix::ContravariantTrans(const Matrix &inMtx, Matrix &outTrans) const
{
   //Dump("This", *this);
   //Dump("In  ", inMtx);
   //outTrans = inMtx.Mult(Inverse());
   outTrans = inMtx.Mult(Inverse());
   //outTrans = inMtx.Mult(*this);
   //Dump("Out ", outTrans);
   //printf("===\n");
}

Matrix Matrix::Mult(const Matrix &inRHS) const
{
   Matrix t;
   t.m00 = m00*inRHS.m00 + m01*inRHS.m10;
   t.m01 = m00*inRHS.m01 + m01*inRHS.m11;
   t.mtx = m00*inRHS.mtx + m01*inRHS.mty + mtx;

   t.m10 = m10*inRHS.m00 + m11*inRHS.m10;
   t.m11 = m10*inRHS.m01 + m11*inRHS.m11;
   t.mty = m10*inRHS.mtx + m11*inRHS.mty + mty;

   t.mtz = inRHS.mtz + mtz;

   return t;
}

Matrix Matrix::Invert2x2() const
{
   double det = m00*m11 - m01*m10;
   if (det==0)
      return Matrix();

   det = 1.0/det;
   Matrix result(m11*det, m00*det);
   result.m01 = -m01*det;
   result.m10 = -m10*det;
   return result;
}


Matrix Matrix::Inverse() const
{
   double det = m00*m11 - m01*m10;
   if (det==0)
      return Matrix();

   det = 1.0/det;
   Matrix result(m11*det, m00*det);
   result.m01 = -m01*det;
   result.m10 = -m10*det;

   result.mtx = - result.m00*mtx - result.m01*mty;
   result.mty = - result.m10*mtx - result.m11*mty;
   return result;
}

UserPoint Matrix::ApplyInverse(const UserPoint &inPoint) const
{
   double det = m00*m11 - m01*m10;
   if (det==0)
      return inPoint;

   det = 1.0/det;

   double x = inPoint.x - mtx;
   double y = inPoint.y - mty;
   return UserPoint( (m11*x - m01*y)*det, (-m10*x + m00*y)*det );
}


void Matrix::MatchTransform(double inX,double inY,
                            double inTargetX,double inTargetY)
{
   mtx = inTargetX-(m00*inX + m01*inY);
   mty = inTargetY-(m10*inX + m11*inY);
}


Matrix &Matrix::Translate(double inX,double inY)
{
   mtx += inX;
   mty += inY;
   return *this;
}

Matrix &Matrix::Rotate(double inDeg)
{
   double c = cos(inDeg * (M_PI/180.0));
   double s = sin(inDeg * (M_PI/180.0));
   double m00_  = m00 * c + m10 * s;
   double m01_  = m01 * c + m11 * s;
   double m10_  = m00 * -s + m10 * c;
   double m11_  = m01 * -s + m11 * c;
   double tx_ = c*mtx + s*mty;
   double ty_ = -s*mtx + c*mty;

   m00 = m00_;
   m01 = m01_;
   m10 = m10_;
   m11 = m11_;
   mtx = tx_;
   mty = ty_;

   return *this;
}

Matrix &Matrix::operator *= (double inScale)
{
   m00 *= inScale;
   m01 *= inScale;
   m10 *= inScale;
   m11 *= inScale;
   mtx *= inScale;
   mty *= inScale;
   return *this;
}

Matrix &Matrix::Scale(double inSx, double inSy)
{
   m00 *= inSx;
   m01 *= inSx;
   mtx *= inSx;
   m10 *= inSy;
   m11 *= inSy;
   mty *= inSy;
   return *this;
}

double Matrix::GetScaleX() const
{
   return sqrt( m00*m00 + m01*m01 ); 
}

double Matrix::GetScaleY() const
{
   return sqrt( m10*m10 + m11*m11 ); 
}


Matrix &Matrix::TranslateData(double inTX, double inTY)
{
   mtx += m00*inTX + m01*inTY;
   mty += m10*inTX + m11*inTY;
   return *this;
}




Matrix &Matrix::createGradientBox(double inWidth, double inHeight,
                          double inRot, double inTX, double inTY )
{
   m00 = inWidth/1638.4;
   m11 = inHeight/1638.4;

   // rotation is clockwise
   if (inRot!=0.0)
   {
      double c = cos(inRot * (M_PI/180.0));
      double s = sin(inRot * (M_PI/180.0));
      m01 = -s*m00;
      m10 = s*m11;
      m00 *= c;
      m11 *= c;
   }
   else
   {
      m01 = m10 = 0;
   }

   mtx = inTX+inWidth*0.5;
   mty = inTY+inHeight*0.5;
   return *this;
}


} // end namespace lime

