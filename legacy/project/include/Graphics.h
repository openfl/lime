#ifndef NME_GRAPHICS_H
#define NME_GRAPHICS_H

#include <nme/Object.h>
#include <nme/QuickVec.h>
#include <Matrix.h>
#include <Scale9.h>
#include <nme/Pixel.h>

typedef unsigned int uint32;
typedef unsigned char uint8;

namespace nme
{

enum GraphicsAPIType { gatBase, gatInternal,  gatQuartz, gatCairo, gatOpenGL, gatOpenGLES };

// enum SurfaceAPIType  { satInternal, satSDL, satCairo };

enum StageQuality
{
   sqLow,
   sqMedium,
   sqHigh,
   sqBest,
};

enum StageDisplayState
{
   sdsNormal,
   sdsFullscreen,
   sdsFullscreenInteractive,
};




// --- Graphics Data -------------------------------------------------------

// These classes match the flash API very closely...
class GraphicsEndFill;
class GraphicsSolidFill;
class GraphicsGradientFill;
class GraphicsBitmapFill;

class GraphicsPath;
class GraphicsTrianglePath;

class GraphicsStroke;

class Surface;

// Don't know if these belong in the c++ level?
class IGraphicsFill;
class IGraphicsPath;
class IGraphicsStroke;


enum GraphicsDataType
{
   gdtUnknown, gdtEndFill, gdtSolidFill, gdtGradientFill, gdtBitmapFill,
   gdtPath, gdtTrianglePath, gdtStroke
};


class IGraphicsData : public Object
{
public:
   IGraphicsData() { };

   IGraphicsData *IncRef() { mRefCount++; return this; }

   virtual GraphicsDataType GetType() { return gdtUnknown; }
   virtual GraphicsAPIType  GetAPI() { return gatBase; }

   virtual IGraphicsFill   *AsIFill() { return 0; }
   virtual IGraphicsPath   *AsIPath() { return 0; }
   virtual IGraphicsStroke   *AsIStroke() { return 0; }

   virtual GraphicsEndFill      *AsEndFill() { return 0; }
   virtual GraphicsSolidFill    *AsSolidFill() { return 0; }
   virtual GraphicsGradientFill *AsGradientFill() { return 0; }
   virtual GraphicsBitmapFill   *AsBitmapFill() { return 0; }

   virtual GraphicsStroke         *AsStroke() { return 0; }

   virtual GraphicsPath           *AsPath() { return 0; }
   virtual GraphicsTrianglePath   *AsTrianglePath() { return 0; }

   virtual int Version() const { return 0; }


protected:
   virtual ~IGraphicsData() { }
private:
   IGraphicsData(const IGraphicsData &inRHS);
   void operator=(const IGraphicsData &inRHS);
};


class IGraphicsFill : public IGraphicsData
{
public:
   IGraphicsFill() : mSolidStyle(true) { }
   virtual IGraphicsFill *AsIFill() { return this; }
	IGraphicsFill *IncRef() { IGraphicsData::IncRef(); return this; }
   bool isSolidStyle() { return mSolidStyle; }
   void setIsSolidStyle(bool inSolid) { mSolidStyle = inSolid; }

protected:
   virtual ~IGraphicsFill() { };
   bool    mSolidStyle;
};


class GraphicsEndFill : public IGraphicsFill
{
public:
   GraphicsDataType GetType() { return gdtEndFill; }
   GraphicsEndFill   *AsEndFill() { return this; }
};

class GraphicsSolidFill : public IGraphicsFill
{
public:
   GraphicsSolidFill(int inRGB=0, float inAlpha=1) : mRGB(inRGB,inAlpha) { }
   GraphicsDataType GetType() { return gdtSolidFill; }
   GraphicsSolidFill   *AsSolidFill() { return this; }

   ARGB  mRGB;
};


struct GradStop
{
   GradStop(int inRGB=0, float inAlpha=0, float inRatio=0) :
      mARGB(inRGB, inAlpha ),
      mPos(inRatio<=0 ? 0 : inRatio>=1.0 ? 255 : inRatio*255.0 ) { }

   ARGB   mARGB;
   int    mPos;
};
typedef QuickVec<GradStop>  Stops;

enum InterpolationMethod {  imRGB, imLinearRGB };
enum SpreadMethod { smPad, smRepeat, smReflect };

class GraphicsGradientFill : public IGraphicsFill
{
public:
   GraphicsGradientFill(bool inIsLinear=true, const Matrix &inMatrix=Matrix(),
      SpreadMethod inSpread=smPad,
      InterpolationMethod inInterp=imLinearRGB, double inFocal = 0.0 ) :
         isLinear(inIsLinear), matrix(inMatrix), spreadMethod(inSpread),
         interpolationMethod(inInterp), focalPointRatio(inFocal) { } 

   void AddStop(int inRGB, float inAlpha=1, float inRatio=0)
   {
      mStops.push_back( GradStop(inRGB, inAlpha, inRatio) );
   }
   void FillArray(ARGB *outColours);


   GraphicsDataType GetType() { return gdtGradientFill; }
   GraphicsGradientFill   *AsGradientFill() { return this; }

   Stops               mStops;

   double              focalPointRatio;
   Matrix              matrix;
   InterpolationMethod interpolationMethod;
   SpreadMethod        spreadMethod;
   bool                isLinear;
};


class GraphicsBitmapFill : public IGraphicsFill
{
public:
   GraphicsBitmapFill(Surface *inBitmapData, const Matrix &inMatrix, bool inRepeat, bool inSmooth);
   ~GraphicsBitmapFill();

   GraphicsDataType GetType() { return gdtBitmapFill; }
   GraphicsBitmapFill   *AsBitmapFill() { return this; }
   int  Version() const;

   Surface             *bitmapData;
   Matrix              matrix;
   bool                repeat;
   bool                smooth;
};

class IGraphicsStroke : public IGraphicsData
{
public:
   IGraphicsStroke *AsIStroke() { return this; }
	IGraphicsStroke *IncRef() { IGraphicsData::IncRef(); return this; }
   virtual GraphicsDataType GetType() { return gdtStroke; }
};

enum StrokeCaps { scRound, scNone, scSquare };
enum StrokeJoints { sjRound, sjMiter, sjBevel };
enum StrokeScaleMode { ssmNormal, ssmNone, ssmVertical, ssmHorizontal, ssmOpenGL };

class GraphicsStroke : public IGraphicsStroke
{
public:
   GraphicsStroke(IGraphicsFill *fill=0, double thickness=0,
                  bool pixelHinting = false, StrokeScaleMode saleMode = ssmNormal,
                  StrokeCaps caps = scRound,
                  StrokeJoints joints = sjBevel, double miterLimit= 3.0);

   ~GraphicsStroke();
	GraphicsStroke *IncRef() { Object::IncRef(); return this; }

   GraphicsStroke *AsStroke() { return this; }
   int  Version() const { return fill ? fill->Version() : 0; }

   bool IsClear() { return false; }

   GraphicsStroke *CloneWithFill(IGraphicsFill *inFill);

   StrokeCaps      caps;
   IGraphicsFill   *fill;
   StrokeJoints    joints;
   double          miterLimit;
   bool            pixelHinting;
   StrokeScaleMode scaleMode;
   double          thickness;
};


class IGraphicsPath : public IGraphicsData
{
public:
   IGraphicsPath *AsIPath() { return this; }
   virtual GraphicsDataType GetType() { return gdtPath; }
};

enum PathCommand
{
   pcNoOp  = 0,
   pcMoveTo  = 1,
   pcLineTo = 2,
   pcCurveTo =  3,
   pcWideMoveTo = 4,
   pcWideLineTo = 5,
   pcArcTo =  6,

   // Special code so we can mix lines and fills...
   pcBeginAt  = 7,
   // Quad combining vertices & texture-coords
   pcPointsXY  = 9,
   pcPointsXYRGBA  = 11,

   pcTile           = 0x10,
   pcTile_Trans_Bit = 0x01,
   pcTile_Col_Bit   = 0x02,
   pcTileTrans      = 0x11,
   pcTileCol        = 0x12,
   pcTileTransCol   = 0x13,

   pcBlendModeAdd   = 0x20,
   pcBlendModeMultiply   = 0x21,
   pcBlendModeScreen   = 0x22,
   pcBlendModeSubtract   = 0x23,
};

enum WindingRule { wrOddEven, wrNonZero };


class GraphicsPath : public IGraphicsPath
{
public:
   GraphicsPath *AsPath() { return this; }
   bool empty() const { return commands.empty(); }

   GraphicsPath() : winding(wrOddEven) { }
   QuickVec<uint8> commands;
   QuickVec<float> data;
   WindingRule     winding;

   void clear();
   void initPosition(const UserPoint &inPos);

   void curveTo(float controlX, float controlY, float anchorX, float anchorY);
   void arcTo(float controlX, float controlY, float anchorX, float anchorY);
   void lineTo(float x, float y);
   void moveTo(float x, float y);
   void wideLineTo(float x, float y);
   void wideMoveTo(float x, float y);
   void tile(float x, float y, const Rect &inTileRect, float *inTrans,float *inColour);
   void elementBlendMode(int inMode);
   void drawPoints(QuickVec<float> inXYs, QuickVec<int> inRGBAs);
   void closeLine(int inCommand0, int inData0);
};


enum TriangleCulling { tcNegative = -1, tcNone = 0, tcPositive = 1};

enum VertexType { vtVertex, vtVertexUV, vtVertexUVT };

class GraphicsTrianglePath : public IGraphicsPath
{
public:
   GraphicsTrianglePath( const QuickVec<float> &inXYs,
            const QuickVec<int> &inIndixes,
            const QuickVec<float> &inUVT, int inCull,
            const QuickVec<int> &inColours,
            int blendMode );

   VertexType       mType;
   int              mTriangleCount;
   QuickVec<UserPoint>  mVertices;
   QuickVec<float>  mUVT;
   QuickVec<uint32> mColours;
   int mBlendMode;
};

// ----------------------------------------------------------------------


enum BlendMode
{
   bmNormal,
   bmLayer,
   bmMultiply,
   bmScreen,
   bmLighten,
   bmDarken,
   bmDifference,
   bmAdd,
   bmSubtract,
   bmInvert,
   bmAlpha,
   bmErase,
   bmOverlay,
   bmHardLight,
   bmCopy,
   bmInner,

   // Used for rendering text
   bmTinted,
   // Used for rendering inner filters
   bmTintedInner,
   // Used for rendering coloured tiles, with add
   bmTintedAdd,
};

class ColorTransform
{
public:
   ColorTransform() :
      redMultiplier(1), redOffset(0),
      greenMultiplier(1), greenOffset(0),
      blueMultiplier(1), blueOffset(0),
      alphaMultiplier(1), alphaOffset(0) { }

   uint32 Transform(uint32 inValue) const;

   void Combine(const ColorTransform &inParent, const ColorTransform &inChild);

   inline bool IsIdentityColour() const
   {
      return redMultiplier==1 && greenMultiplier==1 && blueMultiplier==1 &&
             redOffset==0 && greenOffset==0 && blueOffset==0;
   }
   inline bool HasOffset() const
   {
      return redOffset!=0 || greenOffset!=0 || blueOffset!=0 || alphaOffset!=0;
   }
   inline bool IsIdentityAlpha() const
   {
      return alphaMultiplier==1 && alphaOffset == 0;
   }
   inline bool IsIdentity() const { return IsIdentityAlpha() && IsIdentityColour(); }

   static void TidyCache();


   const uint8 *GetAlphaLUT() const;
   const uint8 *GetRLUT() const;
   const uint8 *GetGLUT() const;
   const uint8 *GetBLUT() const;

   double redMultiplier, redOffset;
   double greenMultiplier, greenOffset;
   double blueMultiplier, blueOffset;
   double alphaMultiplier, alphaOffset;
};

struct SoftwareMask;

struct Transform
{
   Transform();
   bool operator==(const Transform &inRHS) const;
   bool operator!=(const Transform &inRHS) const
      { return !(operator==(inRHS)); }

   UserPoint      Apply(float inX, float inY) const;
   Fixed10        ToImageAA(const UserPoint &inPoint) const;

   Rect           GetTargetRect(const Extent2DF &inExtent) const;

   const Matrix3D *mMatrix3D;
   const Matrix   *mMatrix;
   const Scale9   *mScale9;

   int            mAAFactor;
};



class BitmapCache
{
public:
   BitmapCache(Surface *inSurface,const Transform &inTrans, const Rect &inRect,bool inMaskOnly,
					 BitmapCache *inMask);
   ~BitmapCache();

   bool StillGood(const Transform &inTransform, const Rect &inVisiblePixels,BitmapCache *inMask);

   void Render(const struct RenderTarget &inTarget,const Rect &inClipRect,const BitmapCache *inMask,BlendMode inBlend);
   bool HitTest(double inX, double inY);

   PixelFormat Format() const;

   Rect GetRect() const { return mRect.Translated(mTX,mTY); }

   const uint8 *Row(int inRow) const;
   const uint8 *DestRow(int inRow) const;
   int GetTX() const { return mTX; }
   int GetTY() const { return mTX; }
   int GetDestX() const { return mTX + mRect.x; }
   int GetDestY() const { return mTY + mRect.y; }
	void PushTargetOffset(const ImagePoint &inOffset, ImagePoint &outBuffer);
	void PopTargetOffset(ImagePoint &inBuffer);

//private:
   int        mTX,mTY;
	int        mVersion;
   Rect       mRect;
   Matrix     mMatrix;
   Scale9     mScale9;
   Surface    *mBitmap;

	ImagePoint mMaskOffset;
	int        mMaskVersion;
};


enum RenderPhase { rpBitmap, rpRender, rpHitTest, rpCreateMask };


struct RenderState
{
   RenderState(Surface *inSurface=0,int inAA=1);

   void CombineColourTransform(const RenderState &inState,
                           const ColorTransform *inObjTrans,
                           ColorTransform *inBuf);

   // Spatial Transform
   Transform      mTransform;

   // Colour transform
   bool HasAlphaLUT() const { return mAlpha_LUT; }
   bool HasColourLUT() const { return mR_LUT; }

   const ColorTransform *mColourTransform;
   const uint8 *mR_LUT;
   const uint8 *mG_LUT;
   const uint8 *mB_LUT;
   const uint8 *mAlpha_LUT;

   // Viewport
   Rect           GetAARect() const { return mClipRect*mTransform.mAAFactor; }
   Rect           mClipRect;

   ImagePoint     mTargetOffset;

   RenderPhase    mPhase;
   bool           mRoundSizeToPOW2;
	bool           mRecurse;
	bool           *mWasDirtyPtr;
   // Masking...
   class BitmapCache    *mMask;
   // HitTest result...
   mutable class DisplayObject  *mHitResult;
};


class HardwareData;
class HardwareRenderer;


int UpToPower2(int inX);
inline int IsPower2(unsigned int inX) { return (inX & (inX-1))==0; }


struct RenderTarget
{
   RenderTarget(const Rect &inRect,PixelFormat inFormat,uint8 *inPtr, int inStride);
   RenderTarget(const Rect &inRect,HardwareRenderer *inHardware);
   RenderTarget();

   bool IsHardware() const { return mHardware; }

   void Clear(uint32 inColour,const Rect &inRect ) const;

   RenderTarget ClipRect(const Rect &inRect) const;

   inline int Width() const { return mRect.w; }
   inline int Height() const { return mRect.h; }
	inline PixelFormat Format() const { return mPixelFormat; }

   Rect        mRect;
   PixelFormat mPixelFormat;

   // Software target
   uint8 *mSoftPtr;
   int   mSoftStride;
   uint8 *Row(int inRow) const { return mSoftPtr+mSoftStride*inRow; }

   // Hardware target - RenderTarget does not hold reference on HardwareContext
   HardwareRenderer *mHardware;
};


class Renderer
{
public:
   virtual void Destroy()=0;

   virtual bool Render( const RenderTarget &inTarget, const RenderState &inState ) = 0;

   virtual bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent, bool inIncludeStroke) = 0;

   virtual bool Hits(const RenderState &inState) { return false; }
   
   #ifdef NME_DIRECTFB
   static Renderer *CreateHardware(const class GraphicsJob &inJob,const GraphicsPath &inPath,HardwareContext &inHardware);
   #endif
   
   static Renderer *CreateSoftware(const class GraphicsJob &inJob,const GraphicsPath &inPath);

protected:
   virtual ~Renderer() { }
};


struct GraphicsJob
{
   GraphicsJob() { memset(this,0,sizeof(GraphicsJob)); }

   void clear();
   int  Version() const { return (mFill?mFill->Version():0) + (mStroke?mStroke->Version():0); }

   GraphicsStroke  *mStroke;
   IGraphicsFill   *mFill;
   GraphicsTrianglePath  *mTriangles;
   #ifdef NME_DIRECTFB
   class Renderer  *mHardwareRenderer;
   #endif
   class Renderer  *mSoftwareRenderer;
   int             mCommand0;
   int             mData0;
   int             mCommandCount;
   int             mDataCount;
   bool            mIsTileJob;
   bool            mIsPointJob;
};



typedef QuickVec<GraphicsJob> GraphicsJobs;


class Graphics : public Object
{
public:
   Graphics(DisplayObject *inOwner, bool inInitRef = false);
   ~Graphics();

   void clear();

   Extent2DF GetSoftwareExtent(const Transform &inTransform,bool inIncludeStroke);

   bool Render( const RenderTarget &inTarget, const RenderState &inState );

   void drawGraphicsDatum(IGraphicsData *inData);
   void drawGraphicsData(IGraphicsData **graphicsData,int inN);
   void beginFill(unsigned int color, float alpha = 1.0);
   void endFill();
   void beginBitmapFill(Surface *bitmapData, const Matrix &inMatrix = Matrix(),
                        bool inRepeat = true, bool inSmooth = false);
   void lineStyle(double thickness, unsigned int color = 0, double alpha = 1.0,
                  bool pixelHinting = false, StrokeScaleMode scaleMode = ssmNormal,
                  StrokeCaps caps = scRound,
                  StrokeJoints joints = sjBevel, double miterLimit= 3.0);
   void setLineFill(IGraphicsFill *inFill);

   void lineTo(float x, float y);
   void moveTo(float x, float y);
   void curveTo(float cx,float cy,float x, float y);
   void arcTo(float cx,float cy,float x, float y);
   void drawPath(const QuickVec<uint8> &inCommands, const QuickVec<float> &inData,
           WindingRule inWinding );

   void drawEllipse(float x,float  y,float  width,float  height);
   void drawCircle(float x,float y, float radius) { drawEllipse(x,y,radius,radius); }
   void drawRect(float x,float  y,float  width,float  height)
   {
      Flush();
      moveTo(x,y);
      lineTo(x+width,y);
      lineTo(x+width,y+height);
      lineTo(x,y+height);
      lineTo(x,y);
      Flush();
		mVersion++;
   }
   void drawRoundRect(float x,float  y,float  width,float  height,float  ellipseWidth,float  ellipseHeight);
   void beginTiles(Surface *inSurface,bool inSmooth=false,int inBlendMode=0);
   void endTiles();
   void tile(float x, float y, const Rect &inTileRect, float *inTrans,float *inColour);
   void drawPoints(QuickVec<float> inXYs, QuickVec<int> inRGBAs, unsigned int inDefaultRGBA=0xffffffff, double inSize=-1.0 );
   void drawTriangles(const QuickVec<float> &inXYs, const QuickVec<int> &inIndixes,
            const QuickVec<float> &inUVT, int inCull, const QuickVec<int> &inColours,
            int blendMode );

   const Extent2DF &GetExtent0(double inRotation);
   bool  HitTest(const UserPoint &inPoint);

   bool empty() const { return !mPathData || mPathData->empty(); }
   void removeOwner(DisplayObject *inOwner) { if (mOwner==inOwner) mOwner = 0; }

   int Version() const;

protected:
   void                      BuildHardware();
   void                      Flush(bool inLine=true,bool inFill=true,bool inTile=true);
   inline void               OnChanged();

private:
   DisplayObject             *mOwner;
   GraphicsJobs              mJobs;
   int                       mVersion;

   int                       mConvertedJobs;
   int                       mMeasuredJobs;
   int                       mBuiltHardware;

   GraphicsPath              *mPathData;
   HardwareData              *mHardwareData;

   double                    mRotation0;
   Extent2DF                 mExtent0;

   GraphicsJob               mFillJob;
   GraphicsJob               mLineJob;
   GraphicsJob               mTileJob;

   UserPoint                 mCursor;

   void BuiltExtent0(double inRotation);


private:
   // Rule of 3 - we must manually clean up the jobs (performance optimisation)
   Graphics(const Graphics &inRHS);
   void operator=(const Graphics &inRHS);
};





} // end namespace nme

#endif
