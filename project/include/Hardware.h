#ifndef LIME_HARDWARE_H
#define LIME_HARDWARE_H

#include "Graphics.h"

namespace lime
{

void ResetHardwareContext();

typedef QuickVec<UserPoint>   Vertices;

enum PrimType { ptTriangleFan, ptTriangleStrip, ptTriangles, ptLineStrip, ptPoints, ptLines };

enum
{
   DRAW_HAS_COLOUR      = 0x00000001,
   DRAW_HAS_NORMAL      = 0x00000002,
   DRAW_HAS_PERSPECTIVE = 0x00000004,
   DRAW_RADIAL          = 0x00000008,

   DRAW_HAS_TEX         = 0x00000010,
   DRAW_BMP_REPEAT      = 0x00000020,
   DRAW_BMP_SMOOTH      = 0x00000040,
};




struct DrawElement
{
   uint8        mFlags;
   uint8        mPrimType;
   uint8        mBlendMode;
   uint8        mScaleMode;
   short        mRadialPos;

   uint8        mStride;
   int          mCount;

   int          mVertexOffset;
   int          mTexOffset;
   int          mColourOffset;
   int          mNormalOffset;

   uint32       mColour;
   Surface      *mSurface;

   // For  ptLineStrip/ptLines
   float    mWidth;

};

typedef QuickVec<DrawElement> DrawElements;

class HardwareData
{
public:
   HardwareData();
   ~HardwareData();

   void            releaseVbo();
   float           scaleOf(const RenderState &inState) const;
   bool            isScaleOk(const RenderState &inState) const;
   void            clear();

   DrawElements    mElements;
   QuickVec<uint8> mArray;
   float           mMinScale;
   float           mMaxScale;

   mutable HardwareContext *mVboOwner;
   mutable int             mRendersWithoutVbo;
   mutable unsigned int    mVertexBo;
   mutable int             mContextId;
};


void ConvertOutlineToTriangles(Vertices &ioOutline,const QuickVec<int> &inSubPolys);

extern HardwareContext *gDirectRenderContext;

void BuildHardwareJob(const class GraphicsJob &inJob,const GraphicsPath &inPath,
                      HardwareData &ioData, HardwareContext &inHardware,const RenderState &inState);


}

#endif
