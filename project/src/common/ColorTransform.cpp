#include <Graphics.h>
#include <map>

namespace lime
{

static void CombineCol(double &outMultiplier, double &outOff,  double inPMultiplier, double inPOff,
							  double inCMultiplier, double inCOff)
{
	outMultiplier = inPMultiplier * inCMultiplier;
	outOff = inPMultiplier * inCOff + inPOff;
}

void ColorTransform::Combine(const ColorTransform &inParent, const ColorTransform &inChild)
{
	CombineCol(redMultiplier,redOffset,
				  inParent.redMultiplier,inParent.redOffset,
				  inChild.redMultiplier, inChild.redOffset);
	CombineCol(greenMultiplier,greenOffset,
				  inParent.greenMultiplier,inParent.greenOffset,
				  inChild.greenMultiplier, inChild.greenOffset);
	CombineCol(blueMultiplier,blueOffset,
				  inParent.blueMultiplier,inParent.blueOffset,
				  inChild.blueMultiplier, inChild.blueOffset);
	CombineCol(alphaMultiplier,alphaOffset,
				  inParent.alphaMultiplier,inParent.alphaOffset,
				  inChild.alphaMultiplier, inChild.alphaOffset);
}

inline uint32 ByteTrans(uint32 inVal, double inMultiplier, double inOffset, int inShift)
{
   double val = ((inVal>>inShift) & 0xff) * inMultiplier + inOffset;
   if (val<0) return 0;
   if (val>255) return 0xff<<inShift;
   return ((int)val) << inShift;
}

uint32 ColorTransform::Transform(uint32 inVal) const
{
   return ByteTrans(inVal,alphaMultiplier,alphaOffset,24) |
          ByteTrans(inVal,redMultiplier,redOffset,16) |
          ByteTrans(inVal,greenMultiplier,greenOffset,8) |
          ByteTrans(inVal,blueMultiplier,blueOffset,0);
}


static uint8 *sgIdentityLUT = 0;

typedef std::pair<int,int> Trans;

struct LUT
{
	int mLastUsed;
	uint8 mLUT[256];
};
static int sgLUTID = 0;
typedef std::map<Trans,LUT> LUTMap;
static LUTMap sgLUTs;

enum { LUT_CACHE = 256 };

void ColorTransform::TidyCache()
{
	if (sgLUTID>(1<<30))
	{
		sgLUTID = 1;
		sgLUTs.clear();
	}
}


const uint8 *GetLUT(double inMultiplier, double inOffset)
{
	if (inMultiplier==1 && inOffset==0)
	{
		if (sgIdentityLUT==0)
		{
			sgIdentityLUT = new uint8[256];
			for(int i=0;i<256;i++)
				sgIdentityLUT[i] = i;
		}
		return sgIdentityLUT;
	}

	sgLUTID++;

   Trans t((int)(inMultiplier*128),(int)(inOffset/2));
	LUTMap::iterator it = sgLUTs.find(t);
	if (it!=sgLUTs.end())
	{
       it->second.mLastUsed = sgLUTID;
		 return it->second.mLUT;
	}

	if (sgLUTs.size()>LUT_CACHE)
	{
		LUTMap::iterator where = sgLUTs.begin();
		int oldest = where->second.mLastUsed;
		for(LUTMap::iterator i=sgLUTs.begin(); i!=sgLUTs.end();++i)
		{
			if (i->second.mLastUsed < oldest)
			{
			   oldest = i->second.mLastUsed;
				where = i;
			}
		}
		sgLUTs.erase(where);
	}

	LUT &lut = sgLUTs[t];
	lut.mLastUsed = sgLUTID;
	for(int i=0;i<256;i++)
	{
		double ival = i*inMultiplier + inOffset;
		lut.mLUT[i] = ival < 0 ? 0 : ival>255 ? 255 : (int)ival;
	}
	return lut.mLUT;
}



const uint8 *ColorTransform::GetAlphaLUT() const
{
	return GetLUT(alphaMultiplier,alphaOffset);
}

const uint8 *ColorTransform::GetC0LUT() const
{
	if (gC0IsRed)
	   return GetLUT(redMultiplier,redOffset);
	else
	   return GetLUT(blueMultiplier,blueOffset);
}

const uint8 *ColorTransform::GetC1LUT() const
{
	return GetLUT(greenMultiplier,greenOffset);
}

const uint8 *ColorTransform::GetC2LUT() const
{
	if (gC0IsRed)
	   return GetLUT(blueMultiplier,blueOffset);
	else
	   return GetLUT(redMultiplier,redOffset);
}


} // end namespace lime

