#include <Graphics.h>
#include <algorithm>


namespace nme
{

// --- Transform -------------------------------------------------------------------

static Matrix sgIdentity;
static Scale9 sgNoScale9;

Transform::Transform()
{
	mAAFactor = 1;
	mScale9 = &sgNoScale9;
	mMatrix = &sgIdentity;
	mMatrix3D = &sgIdentity;
}

UserPoint Transform::Apply(float inX, float inY) const
{
	if (mScale9->Active())
	{
		inX = mScale9->TransX(inX);
		inY = mScale9->TransY(inY);
	}
	return UserPoint( (mMatrix->m00*inX + mMatrix->m01*inY + mMatrix->mtx) ,
	                  (mMatrix->m10*inX + mMatrix->m11*inY + mMatrix->mty) );
}



bool Transform::operator==(const Transform &inRHS) const
{
	return *mMatrix==*inRHS.mMatrix &&
         (mScale9==inRHS.mScale9 ||*mScale9==*inRHS.mScale9) &&
          mAAFactor == inRHS.mAAFactor;
}

Fixed10 Transform::ToImageAA(const UserPoint &inPoint) const
{
   return Fixed10( inPoint.x*mAAFactor + 0.5, inPoint.y*mAAFactor + 0.5 );
}


Rect Transform::GetTargetRect(const Extent2DF &inExtent) const
{
   return Rect( floor((inExtent.mMinX)),
                floor((inExtent.mMinY)),
                 ceil((inExtent.mMaxX)),
                 ceil((inExtent.mMaxY)), true );
}


}
