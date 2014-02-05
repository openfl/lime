#include <Graphics.h>
#include "renderer/common/Surface.h"
#include "renderer/common/SimpleSurface.h"


#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


namespace lime
{


struct CurveEdge
{
   CurveEdge(const UserPoint &inP, float inT) : p(inP), t(inT) { }
   inline CurveEdge(){}
   
   UserPoint p;
   float t;
};
typedef QuickVec<CurveEdge> Curves;

struct Range
{
   inline Range() {}
   inline Range(float inT0, const UserPoint &l0, const UserPoint &r0,
               float inT1, const UserPoint &l1, const UserPoint &r1) :
      t0(inT0), t1(inT1),
      left0(l0), right0(r0),
      left1(l1), right1(r1) { }
   
   float     t0,t1;
   UserPoint left0;
   UserPoint right0;
   UserPoint left1;
   UserPoint right1;
};



typedef QuickVec<float> Normals;

class HardwareBuilder
{
public:
   HardwareBuilder(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                   HardwareContext &inHardware, const RenderState &inState) : data(ioData)
   {
      mTexture = 0;
      
      bool tessellate_lines = true;
      bool tile_mode = false;
      bool alphaAA = true;
      
      memset(&mElement,0,sizeof(mElement));
      mElement.mWidth = -1;
      mElement.mColour = 0xffffffff;
      mElement.mVertexOffset = ioData.mArray.size();
      mElement.mStride = 2*sizeof(float);
      
      mSolidMode = false;
      mAlphaAA = false;
      mPerpLen = 0.5;
      mScale = data.scaleOf(inState);
      if (mScale<=0.001)
         mScale = 0.001;
      mCurveThresh2 = 0.125/mScale/mScale;
      mFatLineCullThresh = 5.0/mScale;

      if (inJob.mIsTileJob)
      {
         mElement.mPrimType = ptTriangles;
         mElement.mScaleMode = ssmNormal;

         GraphicsBitmapFill *bmp = inJob.mFill->AsBitmapFill();
         mElement.mSurface = bmp->bitmapData->IncRef();

         mTexture = mElement.mSurface->GetOrCreateTexture(inHardware);
         if (bmp->smooth)
            mElement.mFlags |= DRAW_BMP_SMOOTH;
         tile_mode = true;
      }
      else if (inJob.mFill)
      {
         mSolidMode = true;
         mElement.mPrimType = inJob.mTriangles ? ptTriangles : ptTriangleFan;
         mElement.mScaleMode = ssmNormal;
         if (!SetFill(inJob.mFill,inHardware))
            return;
      }
      else if (tessellate_lines && inJob.mStroke->scaleMode==ssmNormal)
      {
         mElement.mPrimType = ptTriangles;
         GraphicsStroke *stroke = inJob.mStroke;
         mElement.mWidth = stroke->thickness;
         if (!SetFill(stroke->fill,inHardware))
            return;

         mPerpLen = stroke->thickness * 0.5;
         if (mPerpLen<=0.0)
         {
            mPerpLen = 0.5;
            mElement.mWidth = 1.0;
         }

         mCaps = stroke->caps;
         mJoints = stroke->joints;
         mMiterLimit = stroke->miterLimit*mPerpLen;
         
         if (mPerpLen<0.5/mScale)
         {
            int a = (mElement.mColour>>24)*mPerpLen*mScale/0.5;
            mElement.mColour = (mElement.mColour & 0x00ffffff) | (a<<24);
            mPerpLen = 0.5/mScale;
            mElement.mWidth = 1.0/mScale;
         }
         
         if (alphaAA)
         {
            mPerpLen += 0.5/mScale;
            mElement.mWidth += 1.0/mScale;
            mElement.mFlags |= DRAW_HAS_NORMAL;
            mElement.mNormalOffset = mElement.mVertexOffset + mElement.mStride;
            mElement.mStride += sizeof(float)*2.0;
            mAlphaAA = true;
         }
      }
      else
      {
         tessellate_lines = false;
         mElement.mPrimType = ptLineStrip;
         GraphicsStroke *stroke = inJob.mStroke;
         mElement.mScaleMode = stroke->scaleMode;
         mElement.mWidth = stroke->thickness;
         SetFill(stroke->fill,inHardware);
      }
      
      if (mElement.mSurface)
      {
         mElement.mFlags |= DRAW_HAS_TEX;
         mElement.mTexOffset = mElement.mVertexOffset + mElement.mStride;
         mElement.mStride += 2*sizeof(float);
      }
      
      if (inJob.mTriangles)
      {
         if (inJob.mTriangles->mType == vtVertexUVT && mElement.mSurface)
         {
            // Add z,w to position coordinates...
            mElement.mStride += 2*sizeof(float);
            mElement.mTexOffset += 2*sizeof(float);
            mElement.mFlags |= DRAW_HAS_PERSPECTIVE;
         }
         
         if (inJob.mTriangles->mColours.size())
         {
            mElement.mColourOffset = mElement.mVertexOffset + mElement.mStride;
            mElement.mStride += sizeof(int);
            mElement.mFlags |= DRAW_HAS_COLOUR;
            mElement.mColour = 0xffffffff;
         }
         
         mElement.mBlendMode =inJob.mTriangles->mBlendMode;
         
         AddTriangles(inJob.mTriangles);

         if (inJob.mStroke && inJob.mStroke->fill)
         {
            if (mElement.mSurface)
               mElement.mSurface->DecRef();
            memset(&mElement,0,sizeof(mElement));
            mElement.mColour = 0xffffffff;
            mElement.mVertexOffset = ioData.mArray.size();
            mElement.mStride = 2*sizeof(float);
            mElement.mScaleMode = ssmNormal;
            mElement.mWidth = inJob.mStroke->thickness;
            
            mElement.mPrimType = ptLines;
            GraphicsStroke *stroke = inJob.mStroke;
            if (!SetFill(stroke->fill,inHardware))
               return;

            if (mElement.mSurface)
            {
               mElement.mFlags |= DRAW_HAS_TEX;
               mElement.mTexOffset = mElement.mVertexOffset + mElement.mStride;
               mElement.mStride = 2*sizeof(float);
            }
            
            mElement.mWidth = stroke->thickness;
            AddTriangleLines(inJob.mTriangles);
         }
      }
      else if (tile_mode)
      {
         bool has_colour = false;
         const uint8 *cmd = &inPath.commands[inJob.mCommand0];
         int cc = inJob.mCommandCount;
         int tiles = 0;
         
         for(int i=0;i<cc;i++)
         {
            if (cmd[i] == pcTileCol || cmd[i]==pcTileTransCol)
            {
               has_colour = true;
               tiles++;
            }
            else if (cmd[i] == pcTile || cmd[i]==pcTileTrans)
               tiles++;
            else if (cmd[i] == pcBlendModeAdd)
               mElement.mBlendMode = bmAdd;
            else if (cmd[i] == pcBlendModeMultiply)
               mElement.mBlendMode = bmMultiply;
            else if (cmd[i] == pcBlendModeScreen)
               mElement.mBlendMode = bmScreen;
         }
         
         if (has_colour)
         {
            mElement.mColourOffset = mElement.mVertexOffset + mElement.mStride;
            mElement.mStride += sizeof(int);
            mElement.mFlags |= DRAW_HAS_COLOUR;
            mElement.mColour = 0xffffffff;
         }
         
         ReserveArrays(tiles*6);
         
         AddTiles(cmd,cc, &inPath.data[inJob.mData0], tiles);
      }
      else if (tessellate_lines && !mSolidMode)
      {
         AddLineTriangles(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]);
      }
      else
      {
         AddObject(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]);
      }
   }
   
   void ReserveArrays(int inN)
   {
      mElement.mCount = inN;
      data.mArray.resize( mElement.mVertexOffset + mElement.mStride*inN );
   }
   
   
   bool SetFill(IGraphicsFill *inFill,HardwareContext &inHardware)
   {
      mGradFlags = 0;
      if (mElement.mSurface)
      {
         mElement.mSurface->DecRef();
         mElement.mSurface = 0;
      }

      GraphicsSolidFill *solid = inFill->AsSolidFill();
      if (solid)
      {
         mElement.mColour = solid->mRGB.ToInt();
      }
      else
      {
         GraphicsGradientFill *grad = inFill->AsGradientFill();
         if (grad)
         {
            mGradReflect = grad->spreadMethod == smReflect;
            int w = mGradReflect ? 512 : 256;
            mElement.mSurface = new SimpleSurface(w,1,pfARGB);
            mElement.mSurface->IncRef();
            grad->FillArray( (ARGB *)mElement.mSurface->GetBase(), false);

            if (grad->spreadMethod!=smPad)
               mElement.mFlags |= DRAW_BMP_REPEAT;
            mElement.mFlags |= DRAW_BMP_SMOOTH;
            
            mTextureMapper = grad->matrix.Inverse();
            if (!grad->isLinear)
            {
               mElement.mFlags |= DRAW_RADIAL;
               if (grad->focalPointRatio!=0)
               {
                  int r = grad->focalPointRatio*10000.0;
                  if (r<-10000) r = -10000;
                  if (r>10000) r = 10000;
                  mElement.mRadialPos = r;
               }
            }
         }
         else
         {
            GraphicsBitmapFill *bmp = inFill->AsBitmapFill();
            mTextureMapper = bmp->matrix.Inverse();
            mElement.mSurface = bmp->bitmapData->IncRef();
            mTexture = mElement.mSurface->GetOrCreateTexture(inHardware);
            if (bmp->repeat)
               mElement.mFlags |= DRAW_BMP_REPEAT;
            if (bmp->smooth)
               mElement.mFlags |= DRAW_BMP_SMOOTH;
          }
       }
       //return false;
       return true;
   }

   ~HardwareBuilder()
   {
      if (mElement.mSurface)
         mElement.mSurface->DecRef();
   }


   void CalcTexCoords()
   {
      UserPoint *vertices = (UserPoint *)&data.mArray[ mElement.mVertexOffset ];
      UserPoint *tex = (UserPoint *)&data.mArray[ mElement.mTexOffset ];

      bool radial = mElement.mFlags &  DRAW_RADIAL;
      for(int i=0;i<mElement.mCount;i++)
      {
         UserPoint p = mTextureMapper.Apply(vertices->x,vertices->y);
         Next(vertices);

         if (mTexture)
         {
            p = mTexture->PixelToTex(p);
         }
         else
         {
            // The point will be in the (-819.2 ... 819.2) range...
            if (radial)
            {
               p.x = (p.x +819.2) / 819.2 - 1.0;
               p.y = (p.y +819.2) / 819.2 - 1.0;
               if (mGradReflect)
               {
                  p.x *= 0.5;
                  p.y *= 0.5;
               }
 
            }
            else
            {
               p.x = (p.x +819.2) / 1638.4;
               p.y = 0;
               if (mGradReflect)
                  p.x *= 0.5;
            }
         }
         *tex = p;
         Next(tex);
       }
   }
   
   template<typename T>
   void Next(T *&ptr)
   {
      ptr = (T *)( (char *)ptr + mElement.mStride );
   }


   void AddTriangles(GraphicsTrianglePath *inPath)
   {
      int n = inPath->mVertices.size();
      ReserveArrays(n);

      UserPoint *vertices = (UserPoint *)&data.mArray[ mElement.mVertexOffset ];
      int *colours = (mElement.mFlags & DRAW_HAS_COLOUR) ? (int *)&data.mArray[ mElement.mColourOffset ] : 0;
      UserPoint *tex = (mElement.mFlags & DRAW_HAS_TEX) ? (UserPoint *)&data.mArray[ mElement.mTexOffset ] : 0;
      bool persp = mElement.mFlags & DRAW_HAS_PERSPECTIVE;
      int stride = mElement.mStride;
      
      mElement.mPrimType = ptTriangles;
      
      const float *t = &inPath->mUVT[0];
      for(int v=0;v<n;v++)
      {
         if (!persp)
         {
           *vertices = inPath->mVertices[v];
            Next(vertices);
         }
         
         if(colours)
         {
            *colours = inPath->mColours[v];
            Next(colours);
         }

         if (inPath->mType != vtVertex)
         {
            *tex = mTexture->TexToPaddedTex( UserPoint(t[0],t[1]) );
            Next(tex);

            t+=2;
            if (persp)
            {
               float w= 1.0/ *t++;
               vertices[0] = inPath->mVertices[v]*w;
               vertices[1] = UserPoint(0,w);
               Next(vertices);
            }
         }
      }

      mElement.mCount = n;

      PushElement();
   }


   void AddTriangleLines(GraphicsTrianglePath *inPath)
   {
      mElement.mPrimType = ptLines;
      
      int tri_count = inPath->mVertices.size()/3;
      ReserveArrays(tri_count*6);
 
      UserPoint *vertices = (UserPoint *)&data.mArray[mElement.mVertexOffset];
      UserPoint *tri =  &inPath->mVertices[0];
      for(int v=0;v<tri_count;v++)
      {
         *vertices = tri[0];
         Next(vertices);
         *vertices = tri[1];
         Next(vertices);
         *vertices = tri[1];
         Next(vertices);
         *vertices = tri[2];
         Next(vertices);
         *vertices = tri[2];
         Next(vertices);
         *vertices = tri[0];
         Next(vertices);
         tri+=3;
      }

      if (mElement.mFlags & DRAW_HAS_TEX)
         CalcTexCoords();
      
      PushElement();
   }

  void AddTiles(const uint8* inCommands, int inCount, const float *inData, int inTiles)
  {
      UserPoint *vertices = (UserPoint *)&data.mArray[mElement.mVertexOffset];
      UserPoint *tex = (mElement.mFlags & DRAW_HAS_TEX) ? (UserPoint *)&data.mArray[ mElement.mTexOffset ] : 0;
      int *colours = (mElement.mFlags & DRAW_HAS_COLOUR) ? (int *)&data.mArray[ mElement.mColourOffset ] : 0;

      UserPoint *point = (UserPoint *)inData;

      for(int i=0;i<inCount;i++)
      {
         switch(inCommands[i])
         {
            case pcBeginAt: case pcMoveTo: case pcLineTo:
               point++;
               break;
            case pcCurveTo:
               point+=2;
               break;

            case pcTile:
            case pcTileTrans:
            case pcTileCol:
            case pcTileTransCol:
               {
                  UserPoint pos(point[0]);
                  UserPoint tex_pos(point[1]);
                  UserPoint size(point[2]);
                  point += 3;
              
                  if (inCommands[i]&pcTile_Trans_Bit)
                  {
                     UserPoint trans_x = *point++;
                     UserPoint trans_y = *point++;

                     UserPoint p1(pos.x + size.x*trans_x.x,
                                  pos.y + size.x*trans_x.y);
                     UserPoint p2(pos.x + size.x*trans_x.x + size.y*trans_y.x,
                                  pos.y + size.x*trans_x.y + size.y*trans_y.y );
                     UserPoint p3(pos.x + size.y*trans_y.x,
                                  pos.y + size.y*trans_y.y );

                     *vertices = ( pos );
                     Next(vertices);
                     *vertices = ( p1 );
                     Next(vertices);
                     *vertices = ( p2 );
                     Next(vertices);
                     *vertices = ( pos) ;
                     Next(vertices);
                     *vertices = ( p2 );
                     Next(vertices);
                     *vertices = ( p3 );
                     Next(vertices);
                  }
                  else
                  {
                     *vertices = (pos);
                     Next(vertices);
                     *vertices = ( UserPoint(pos.x+size.x,pos.y) );
                     Next(vertices);
                     *vertices = ( UserPoint(pos.x+size.x,pos.y+size.y) );
                     Next(vertices);
                     *vertices = (pos);
                     Next(vertices);
                     *vertices = ( UserPoint(pos.x+size.x,pos.y+size.y) );
                     Next(vertices);
                     *vertices = ( UserPoint(pos.x,pos.y+size.y) );
                     Next(vertices);
                  }


                  pos = tex_pos;
                  *tex = ( mTexture->PixelToTex(pos) );
                  Next(tex);
                  *tex = ( mTexture->PixelToTex(UserPoint(pos.x+size.x,pos.y)) );
                  Next(tex);
                  *tex = ( mTexture->PixelToTex(UserPoint(pos.x+size.x,pos.y+size.y)) );
                  Next(tex);
                  *tex = ( mTexture->PixelToTex(pos) );
                  Next(tex);
                  *tex = ( mTexture->PixelToTex(UserPoint(pos.x+size.x,pos.y+size.y)) );
                  Next(tex);
                  *tex = ( mTexture->PixelToTex(UserPoint(pos.x,pos.y+size.y)) );
                  Next(tex);

                  if (inCommands[i]&pcTile_Col_Bit)
                  {
                     UserPoint rg = *point++;
                     UserPoint ba = *point++;
                     #ifdef BLACKBERRY
                     uint32 col = ((int)(rg.x*255)) |
                                  (((int)(rg.y*255))<<8) |
                                  (((int)(ba.x*255))<<16) |
                                  (((int)(ba.y*255))<<24);
                     #else
                     uint32 col = ((rg.x<0 ? 0 : rg.x>1?255 : (int)(rg.x*255))) |
                                  ((rg.y<0 ? 0 : rg.y>1?255 : (int)(rg.y*255))<<8) |
                                  ((ba.x<0 ? 0 : ba.x>1?255 : (int)(ba.x*255))<<16) |
                                  ((ba.y<0 ? 0 : ba.y>1?255 : (int)(ba.y*255))<<24);
                     #endif

                     *colours = ( col );
                     Next(colours);
                     *colours = ( col );
                     Next(colours);
                     *colours = ( col );
                     Next(colours);
                     *colours = ( col );
                     Next(colours);
                     *colours = ( col );
                     Next(colours);
                     *colours = ( col );
                     Next(colours);
                  }
               }
         }
      }

      mElement.mCount = inTiles*6;
      if (mElement.mCount>0)
         PushElement();
   }
   
   void PushElement()
   {
      if (mElement.mCount>0)
      {
         /*
         if (data.mElements.size()>0)
         {
            DrawElement &e = data.mElements.last();
            if (e.mFlags==mElement.mFlags &&
                (e.mPrimType==ptLines || e.mPrimType==ptTriangles || e.mPrimType==ptPoints) &&
                e.mPrimType==mElement.mPrimType &&
                e.mBlendMode==mElement.mBlendMode &&
                e.mRadialPos==mElement.mRadialPos &&
                e.mSurface==mElement.mSurface &&
                e.mColour==mElement.mColour &&
                e.mWidth==mElement.mWidth )
            {
               e.mCount += mElement.mCount;
               return;
            }
         }
         */
         data.mElements.push_back(mElement);
         if (mElement.mSurface)
            mElement.mSurface->IncRef();
      }
   }

   void PushVertices(const Vertices &inV)
   {
      ReserveArrays(inV.size());

      //printf("PushVertices %d\n", inV.size());

      UserPoint *v = (UserPoint *)&data.mArray[mElement.mVertexOffset];
      for(int i=0;i<inV.size();i++)
      {
         *v = inV[i];
         Next(v);
      }

      if (mElement.mSurface)
         CalcTexCoords();

      PushElement();
   }


   #define FLAT 0.000001
   void AddPolygon(Vertices &inOutline,const QuickVec<int> &inSubPolys)
   {
      if (mSolidMode && inOutline.size()<3)
         return;

      bool isConvex = inSubPolys.size()==1;
      if (mSolidMode)
      {
         if (isConvex)
         {
            UserPoint base = inOutline[0];
            int last = inOutline.size()-2;
            int i = 0;
            bool positive = true;
            for( ;i<last;i++)
            {
               UserPoint v0 = inOutline[i+1]-base;
               UserPoint v1 = inOutline[i+2]-base;
               double diff = v0.Cross(v1);
               if (fabs(diff)>FLAT)
               {
                  positive = diff > 0;
                  break;
               }
            }

            for(++i;i<last;i++)
            {
               UserPoint v0 = inOutline[i+1]-base;
               UserPoint v1 = inOutline[i+2]-base;
               double diff = v0.Cross(v1);
               if (fabs(diff)>FLAT && (diff>0)!=positive)
               {
                  isConvex = false;
                  break;
               }
            }
         }
         if (!isConvex)
            ConvertOutlineToTriangles(inOutline,inSubPolys);
      }


      mElement.mVertexOffset = data.mArray.size();
      if (mElement.mSurface)
         mElement.mTexOffset = mElement.mVertexOffset + 2*sizeof(float);

      PushVertices(inOutline);

      if (!isConvex)
         data.mElements.last().mPrimType = ptTriangles;
   }


  void AddObject(const uint8* inCommands, int inCount, const float *inData)
  {
      UserPoint *point = (UserPoint *)inData;
      UserPoint last_move;
      UserPoint last_point;
      int points = 0;
      QuickVec<int> sub_poly_start;
      Vertices outline;


      for(int i=0;i<inCount;i++)
      {
         switch(inCommands[i])
         {
            case pcBeginAt:
               if (points>0)
               {
                  point++;
                  continue;
               }
               // fallthrough
            case pcMoveTo:
               if (points>1)
               {
                  // Move in the middle of a solid polygon - treat like a line...
                  if (mSolidMode)
                  {
                     sub_poly_start.push_back(outline.size());
                     outline.push_back(*point);
                     last_point = *point++;
                     points++;
                     break;
                  }
                  sub_poly_start.push_back(outline.size());
                  AddPolygon(outline,sub_poly_start);
               }
               else if (points==1 && last_move==*point)
               {
                  point++;
                  continue;
               }

               outline.resize(0);
               sub_poly_start.resize(0);
               points = 1;
               last_point = *point++;
               last_move = last_point;
               if (outline.empty()||outline.last()!=last_move)
                  outline.push_back(last_move);
               break;

            case pcLineTo:
               if (points>0)
               {
                  if (outline.empty() || outline.last()!=*point)
                     outline.push_back(*point);
                  last_point = *point++;
                  points++;
               }
               break;

            case pcCurveTo:
               {
               double len = ((last_point-point[0]).Norm() + (point[1]-point[0]).Norm()) * 0.25;
               if (len==0)
                  break;
               int steps = (int)len;
               if (steps<3) steps = 3;
               if (steps>100) steps = 100;
               double step = 1.0/(steps+1);
               double t = 0;
               for(int s=0;s<steps;s++)
               {
                  t+=step;
                  double t_ = 1.0-t;
                  UserPoint p = last_point * (t_*t_) + point[0] * (2.0*t*t_) + point[1] * (t*t);
                  if (outline.last()!=p)
                     outline.push_back(p);
               }
               last_point = point[1];
               if (outline.last()!=last_point)
                   outline.push_back(last_point);
               point += 2;
               points++;
               }
               break;

            case pcTile:
            case pcTileTrans:
            case pcTileCol:
            case pcTileTransCol:
               point += 3;
               if (inCommands[i]&pcTile_Trans_Bit)
                  point+=2;
               if (inCommands[i]&pcTile_Col_Bit)
                  point+=2;
         }
      }

      if (!outline.empty())
      {
         int n = outline.size();
         if (sub_poly_start.empty() || sub_poly_start.last()!=n)
            sub_poly_start.push_back(n);
         AddPolygon(outline,sub_poly_start);
      }
   }

   struct Segment
   {
      inline Segment() { }
      inline Segment(const UserPoint &inP) : p(inP), curve(inP) { }
      inline Segment(const UserPoint &inP,const UserPoint &inCurve) : p(inP), curve(inCurve) { }

      UserPoint getDir0(const UserPoint &inP0) const { return curve-inP0; }
      UserPoint getDir1(const UserPoint &inP0) const { return isCurve() ? p-curve : p-inP0; }
      UserPoint getDirAverage(const UserPoint &inP0) const { return p-inP0; }

      inline bool isCurve() const { return p!=curve; }

      UserPoint p;
      UserPoint curve;
   };

   void AddArc(Curves &outCurve, UserPoint inP, double angle, UserPoint inVx, UserPoint inVy, float t)
   {
      int steps = 1 + mPerpLen*angle*3;
      if (steps>60)
         steps = 60;
      double d_theta = angle / (steps+1);
      double theta = d_theta;
      for(int i=1;i<steps;i++)
      {
         UserPoint x = inP + inVx*cos(theta) + inVy*sin(theta);
         outCurve.push_back( CurveEdge(x,t) );
         t+= 1.0/steps;
         theta += d_theta;
      }
   }

   void AddMiter(Curves &outCurves, UserPoint inP, UserPoint p0, UserPoint p1, double inAlpha,
                UserPoint dir1, UserPoint dir2, float t)
   {
       if (inAlpha>mMiterLimit)
       {
          UserPoint corner0 = p0+dir1*mMiterLimit;
          UserPoint corner1 = p1-dir2*mMiterLimit;

          outCurves.push_back( CurveEdge(corner0, t+0.33) );
          outCurves.push_back( CurveEdge(corner1, t+0.66) );
       }
       else
       {
          UserPoint corner0 = p0+dir1*inAlpha;
          UserPoint corner1 = p1-dir2*inAlpha;
          UserPoint diff = corner1-corner0;
          outCurves.push_back( CurveEdge(corner1, t+0.501) );
       }
   }
   
   
   void removeLoops(QuickVec<CurveEdge> &curve,int startPoint,float turningPoint)
   {
      for(int i=startPoint;i<curve.size()-2;i++)
      {
         const UserPoint &p0 = curve[i].p;
         UserPoint &p1 = curve[i+1].p;
         UserPoint dp = p1-p0;
         if (fabs(dp.x) + fabs(dp.y) < 0.001)
         {
            curve.erase(i,1);
            i--;
            continue;
         }
         float minX = std::min(p0.x,p1.x);
         float maxX = std::max(p0.x,p1.x);
         float minY = std::min(p0.y,p1.y);
         float maxY = std::max(p0.y,p1.y);
         float ct = curve[i].t;
         int   cti = (int)ct;
         bool afterTurning = turningPoint!=0 && ct>turningPoint;
         for(int j=i+2;j<curve.size()-1;j++)
         {
            const UserPoint &l0 = curve[j].p;
            const UserPoint &l1 = curve[j+1].p;
            if ( (l0.x<minX && l1.x<minX) ||
                 (l0.x>maxX && l1.x>maxX) ||
                 (l0.y<minY && l1.y<minY) ||
                 (l0.y>maxY && l1.y>maxY) )
              continue;

            // Only consider intersection with self or joint for second half of curve
            if (turningPoint>0 && curve[j].t>turningPoint && cti<(int)curve[j].t-1)
               break;

            UserPoint dl = l1-l0;
            // Solve p0.x + a dp.x = l0.x + b dl.x
            //       p0.y + a dp.y = l0.y + b dl.y

            // Solve p0.x*dp.y + a dp.x*dp.y = l0.x*dp.y + b dl.x*dp.y
            //       p0.y*dp.x + a dp.y*dp.x = l0.y*dp.x + b dl.y*dp.x
            //    p0 x dp - l0 x dp = b dl x dp
            //    (p0-l0) x dp = b dl x dp
            double denom = dl.Cross(dp);
            if (denom!=0.0)
            {
               double b = (p0-l0).Cross(dp)/denom;
               if (b>=0 && b<=1.0)
               {
                  double a =  (fabs(dp.x) > fabs(dp.y)) ? (l0.x + b*dl.x - p0.x)/dp.x :
                                                          (l0.y + b*dl.y - p0.y)/dp.y;
                  if (a>=0 && a<=1)
                  {
                     if (a>0 && a<1 && b>0 && b<1)
                     {
                        UserPoint p = p0 + dp*a;
                        // Remove the loop 
                        //   c[i]
                        //    p  <- new point between c[i] and c[i+1]
                        //    c[i+1]
                        //    c[i+2]
                        //    ...
                        //    c[j]
                        //    p  <- new point between c[j] and c[j+1]
                        //    c[j+1]
                        {
                           // replace c[i+1] with p, and erase upto and including c[j]
                           p1 = p;
                           curve.EraseAt(i+2,j+1);
                           break;
                        }
                     }
                  }
               }
            }
         }
      }
   }
   

   void AddCurveSegment(Curves &leftCurve, Curves &rightCurve,
                        UserPoint perp0, UserPoint perp1,
                        UserPoint inP0,UserPoint inP1,UserPoint inP2,
                        UserPoint p0_left, UserPoint p0_right,UserPoint p1_left, UserPoint p1_right, float t0)
   {

      QuickVec<Range> stack;
      Range r0(0,inP0-perp0, inP0+perp0, 1,inP2-perp1, inP2+perp1);
      stack.push_back(r0);

      while(stack.size())
      {
         Range r = stack.qpop();
         if (r.t1-r.t0 > 0.001 )
         {
            // Calc midpoint...
            double t = (r.t0+r.t1)*0.5;
            double t_ = 1.0 - t;
            UserPoint mid_p = inP0 * (t_ * t_) + inP1 * (2.0 * t * t_) + inP2 * (t * t);
            UserPoint dir = (inP0 * -t_ + inP1 * (1.0 - 2.0 * t) + inP2 * t);
            UserPoint mid_l = mid_p - dir.Perp(mPerpLen);
            UserPoint mid_r = mid_p + dir.Perp(mPerpLen);

            UserPoint average_l = (r.left0+r.left1)*0.5;
            UserPoint average_r = (r.right0+r.right1)*0.5;
            if ( mid_l.Dist2(average_l)>mCurveThresh2 || mid_r.Dist2(average_r)>mCurveThresh2)
            {
               // Reverse order, LIFO
               stack.push_back( Range(t,mid_l,mid_r, r.t1,r.left1,r.right1) );
               r.t1 = t;
               r.left1 = mid_l;
               r.right1 = mid_r;
               stack.push_back(r);
               continue;
            }
            // Too much curvature?
            // dir = pert @ mid_t
            /*
            t+=0.001;
            t_ = 1.0 - t;
            UserPoint p_plus = inP0 * (t_ * t_) + inP1 * (2.0 * t * t_) + inP2 * (t * t);
            UserPoint perp_plus = (inP0 * -t_ + inP1 * (1.0 - 2.0 * t) + inP2 * t).Perp(mPerpLen);

            if (r.t0==0.0 || (mid_p-p_plus).Dot(mid_l-(p_plus-perp_plus)) > 0)
               leftCurve.push_back( CurveEdge(r.left0,r.t0+t0) );

            if ( (mid_p-p_plus).Dot(mid_r-(p_plus+perp_plus)) > 0)
               rightCurve.push_back( CurveEdge(r.right0,r.t0+t0) );

            continue;
            */
         }
         leftCurve.push_back( CurveEdge(r.left0,r.t0+t0) );
         rightCurve.push_back( CurveEdge(r.right0,r.t0+t0) );
      }
      leftCurve.push_back( CurveEdge(inP2-perp1,0.9999+t0) );
      rightCurve.push_back( CurveEdge(inP2+perp1,0.9999+t0) );
   }

   void EndCap(Curves &left, Curves &right, UserPoint p0, UserPoint perp, double t)
   {
      bool first = t==0;

      UserPoint back(-perp.y, perp.x);
      if (!first)
      {
         back.x*=-1;
         back.y*=-1;
      }
 
      if (mCaps==scSquare)
      {
         if (first)
         {
            left.push_back(CurveEdge(p0+back-perp,t));
            right.push_back(CurveEdge(p0+back+perp,t));
         }
         else
         {
            left.push_back(CurveEdge(p0+back-perp,t));
            right.push_back(CurveEdge(p0+back+perp,t));
         }
      }
      else
      {
         int n = std::max(2,(int)(mPerpLen * 4));
         double dtheta = M_PI*0.5 / n;

         for(int i=1;i<n;i++)
         {
            double theta = (first ? n-i : i) * dtheta;
            left.push_back(CurveEdge(p0 - perp*cos(theta) + back*sin(theta),t)  );
            right.push_back(CurveEdge(p0 + perp*cos(theta) + back*sin(theta),t)  );
            t+= 0.0001;
         }
      }
   }
   
   UserPoint CalcNormalInfo(const UserPoint &base, UserPoint prev, UserPoint p, float inSign, bool inAllowSmaller)
   {
       /*

        prev                 p
         +------------------+
         |                /  
         |            _/
         |          /
         |       /
         |    /
         | /
        base

        Thickness at p =  perp distance from base to prev->p

       */

      float dist = fabs( (p-base).Dot( (p-prev).Perp(1.0) ) );
      if (!inAllowSmaller && dist<mElement.mWidth)
          dist = mElement.mWidth;
      dist*=0.5*mScale;
      return UserPoint(dist,dist*inSign);
   }

   void AddStrip(const QuickVec<Segment> &inPath, bool inLoop)
   {
      if (inPath.size()<2)
         return;

      Curves leftCurve;
      Curves rightCurve;

      float t = 0.0;
      int   prevSegLeft = 0;
      int   prevSegRight = 0;

      // Endcap 0 ...
      if (!inLoop)
      {
         if (mCaps==scSquare || mCaps==scRound)
         {
            UserPoint p0 = inPath[0].p;
            EndCap(leftCurve, rightCurve, p0, inPath[1].getDir0(p0).Perp(mPerpLen),t);
         }
      }
      t+=1.0;

      UserPoint p;
      UserPoint dir1;

      for(int i=1;i<inPath.size();i++)
      {
          const Segment &seg = inPath[i];
          UserPoint p0 = inPath[i-1].p;
          p = seg.p;

          UserPoint dir0 = seg.getDir0(p0).Normalized();
          dir1 = seg.getDir1(p0).Normalized();

          UserPoint next_dir;
          if (i+1<inPath.size())
             next_dir = inPath[i+1].getDir0(p).Normalized();
          else if (!inLoop)
          {
             next_dir = dir1;
             //printf("Dup next_dir\n");
          }
          else
             next_dir = inPath[1].getDir0(p).Normalized();


          UserPoint perp0(-dir0.y*mPerpLen, dir0.x*mPerpLen);
          UserPoint perp1(-dir1.y*mPerpLen, dir1.x*mPerpLen);
          UserPoint next_perp(-next_dir.y*mPerpLen, next_dir.x*mPerpLen);

 
          UserPoint p1_left = p-perp1;
          UserPoint p1_right = p+perp1;

          UserPoint p0_left = p0-perp0;
          UserPoint p0_right = p0+perp0;

          int segStartLeft = leftCurve.size();
          int segStartRight = rightCurve.size();

          if (seg.isCurve())
          {
             AddCurveSegment(leftCurve,rightCurve,perp0, perp1,p0,seg.curve,seg.p, p0_left, p0_right, p1_left, p1_right,t);
             t+=1.0;
          }
          else
          {
             leftCurve.push_back( CurveEdge(p0_left,t) );
             leftCurve.push_back( CurveEdge(p1_left,t+0.99) );

             rightCurve.push_back( CurveEdge(p0_right,t) );
             rightCurve.push_back( CurveEdge(p1_right,t+0.99) );

             t+=1.0;
          }

          float segJoinLeft = leftCurve.last().t;
          float segJoinRight = rightCurve.last().t;

          bool reversed = next_dir.Dot(dir1)<0;
          bool fullReverse = reversed && next_dir.Dot(dir1)<-0.99;
          if (fullReverse)
          {
             leftCurve.push_back( CurveEdge(p1_right,t) );
             rightCurve.push_back( CurveEdge(p1_left,t) );
             segStartLeft = prevSegLeft = leftCurve.size();
             segStartRight = prevSegRight = rightCurve.size();
          }
          else if (mPerpLen>1 && (mJoints==sjRound || mJoints==sjMiter) && (reversed || fabs(next_dir.Cross(dir1))>0.25 ) )
          {
             /*
   
                              ---
                           ---
                        ---
                    - B-           next segment
                  Z   \         ...
                  |    \     ...
                  D_____\ ...____
                  |      p      C    ---.
                  |      .\     | ---
                  |      . \   -Y-
                  |      .  A-- |
                  |      .      |
                  |      .      |   p = end segment
                  |      .      |   
                  |      .      |   
                  |      .      |
   
                A = p + next_perp
                B = p - next_perp
   
                C = p + perp1
                D = p - perp1
   
                Y = A + alpha*next_dir
                  = C - alpha*dir1
   
                   = p + next_perp + alpha*next_dir
                   = p + perp1 - alpha*dir1
   
                   -> next_perp-perp1 = alpha*(dir1+next_dir)
                   -> alpha = prep1-next_perp     in either x or y direction...
                              ---------------
                              dir1+next_dir
   
                On the overlap side, we will draw a bevel, and let the removeLoops code fix it.
                On the non-overlay side, we will draw a joint
             */
   
   
   
             double denom_x = dir1.x+next_dir.x;
             double denom_y = dir1.y+next_dir.y;
             double alpha=0;
   
             // Choose the better-conditioned axis
             if (fabs(denom_x)>fabs(denom_y))
                alpha = denom_x==0 ? 0 : (perp1.x-next_perp.x)/denom_x;
             else
                alpha = denom_y==0 ? 0 : (perp1.y-next_perp.y)/denom_y;
   
             if ( fabs(alpha)>0.01 )
             {
                if (mJoints==sjRound)
                {
                      double angle = acos(dir1.Dot(next_dir));
                      if (angle<0) angle += M_PI;
                      if (alpha>0) // left
                         AddArc(leftCurve, p, angle, -perp1, dir1*mPerpLen, t );
                      else // right
                         AddArc(rightCurve, p, angle, perp1, dir1*mPerpLen, t );
                }
                else
                {
                      if (alpha>0) // left
                      {
                         AddMiter(leftCurve, p, p1_left, p-next_perp, alpha, dir1, next_dir,t);
                      }
                      else // Right
                      {
                         AddMiter(rightCurve, p, p1_right, p+next_perp, -alpha, dir1, next_dir,t);
                      }
                }
             }
          }
          t+=1.0;

          float turnLeft = seg.isCurve() ? segJoinLeft - 0.66 : 0;
          float turnRight = seg.isCurve() ? segJoinRight - 0.66 : 0;
          removeLoops(leftCurve,prevSegLeft,turnLeft);
          removeLoops(rightCurve,prevSegRight,turnRight);

          prevSegLeft = segStartLeft;
          prevSegRight = segStartRight;
      }

      // Endcap end ...
      if (!inLoop && (mCaps==scSquare || mCaps==scRound))
      {
         EndCap(leftCurve, rightCurve, p, dir1.Perp(mPerpLen),t);
      }

      removeLoops(leftCurve,prevSegLeft,0);
      removeLoops(rightCurve,prevSegRight,0);


      if (leftCurve.size()<2 || rightCurve.size()<2)
         return;

      bool useTriStrip = true;
      bool keepTriSense = true;

      data.mArray.reserve( mElement.mVertexOffset + (leftCurve.size() + rightCurve.size()) * mElement.mStride * (useTriStrip?2:3) );

      UserPoint *v = (UserPoint *)&data.mArray[mElement.mVertexOffset];
      UserPoint *normal = (mElement.mFlags & DRAW_HAS_NORMAL) ? (UserPoint *)&data.mArray[mElement.mNormalOffset] : 0;

      UserPoint pLeft = leftCurve[0].p;
      UserPoint pRight = rightCurve[0].p;

      UserPoint leftNormal(mElement.mWidth*0.5, -mPerpLen);
      UserPoint rightNormal(mElement.mWidth*0.5, mPerpLen);


      if (useTriStrip)
      {
         *v = pRight; Next(v);
         if (normal)
            {  *normal = rightNormal; Next(normal); }

         *v = pLeft; Next(v);
         if (normal)
            {  *normal = leftNormal; Next(normal); }
      }

      int added = useTriStrip ? 2 : 0;
      int left = 1;
      int right = 1;


      enum { PREV_LEFT, PREV_RIGHT };
      int prevEdge = PREV_LEFT;


      while(left<leftCurve.size() || right<rightCurve.size())
      {
         //printf("  %d(%f),%d(%f)\n", left, leftCurve[left].t, right, rightCurve[right].t );
         bool preferRight =
             left>=leftCurve.size() || (right<rightCurve.size() && rightCurve[right].t < leftCurve[left].t);
         if (preferRight)
         {
            float testT = rightCurve[right].t;
            UserPoint test = rightCurve[right++].p;
            if ( mPerpLen<mFatLineCullThresh || (test-pLeft).Cross(pRight-pLeft)>=0)
            {
               if (!useTriStrip)
               {
                  *v = pRight; Next(v);
                  if (normal)
                     { *normal = rightNormal; Next(normal); }

                  *v = pLeft; Next(v);
                  if (normal)
                     { *normal = leftNormal; Next(normal); }
                  added+=2;
               }
               else if (keepTriSense && prevEdge!=PREV_LEFT)
               {
                  *v = pLeft; Next(v);
                  if (normal)
                     { *normal = leftNormal; Next(normal); }
                  added++;
               }
               added++;
               if (normal)
               {
                  *normal = rightNormal = CalcNormalInfo(pLeft, pRight, test, 1.0, testT<1 ||testT>=t);
                  Next(normal);
               }
               *v = pRight = test;
               Next(v);
               prevEdge = PREV_RIGHT;
            }
         }
         else
         {
            float testT = rightCurve[left].t;
            UserPoint test = leftCurve[left++].p;
            if ( mPerpLen<mFatLineCullThresh || (test-pLeft).Cross(pRight-pLeft)>=0)
            {
               if (!useTriStrip)
               {
                  *v = pRight; Next(v);
                  if (normal)
                     { *normal = rightNormal; Next(normal); }

                  *v = pLeft; Next(v);
                  if (normal)
                     { *normal = leftNormal; Next(normal); }
                  added+=2;
               }
               else if (keepTriSense && prevEdge!=PREV_RIGHT)
               {
                  *v = pRight; Next(v);
                  if (normal)
                     {  *normal = rightNormal; Next(normal); }
                  added++;
               }
 
               added++;
               if (normal)
               {
                  *normal = leftNormal = CalcNormalInfo(pRight, pLeft, test, -1.0, testT<1 || testT>=t);
                  Next(normal);
               }
               *v = pLeft = test;
               Next(v);
               prevEdge = PREV_LEFT;
            }
         }
      }

      // Build triangle strip....
      mElement.mPrimType = useTriStrip ? ptTriangleStrip : ptTriangles;
      mElement.mCount = added;
      data.mArray.resize( mElement.mVertexOffset + mElement.mCount*mElement.mStride );

      if (mElement.mSurface)
         CalcTexCoords();

      PushElement();
      
      int extra = added * mElement.mStride;
      mElement.mVertexOffset += extra;

      if (mElement.mNormalOffset)
         mElement.mNormalOffset += extra;
      if (mElement.mTexOffset)
         mElement.mTexOffset += extra;
      if (mElement.mColourOffset)
         mElement.mColourOffset += extra;
      mElement.mCount = 0;
   }
   
   
   void AddLineTriangles(const uint8* inCommands, int inCount, const float *inData)
   {
      UserPoint *point = (UserPoint *)inData;

      // It is a loop if the path has no breaks, it has more than 2 points
      //  and it finishes where it starts...
      UserPoint first;
      UserPoint prev;

      QuickVec<Segment> strip;

      for(int i=0;i<inCount;i++)
      {
         switch(inCommands[i])
            {
            case pcWideMoveTo:
               point++;
            case pcBeginAt:
            case pcMoveTo:
               if (strip.size()==1 && prev==*point)
               {
                  point++;
                  continue;
               }

               if (strip.size()>1)
                  AddStrip(strip,false);

               strip.resize(0);
               strip.push_back(Segment(*point));
               prev = *point;
               first = *point++;
               break;
               
            case pcWideLineTo:
               point++;
            case pcLineTo:
               {
               if (strip.size()>0 && *point==prev)
               {
                  point++;
                  continue;
               }
 
               strip.push_back(Segment(*point));

               // Implicit loop closing...
               if (strip.size()>2 && *point==first)
               {
                  AddStrip(strip,true);
                  strip.resize(0);
               }
               
               prev = *point;
               point++;
               }
               break;
               
            case pcCurveTo:
               {
                  if (strip.size()>0 && *point==prev && point[1]==prev)
                  {
                     point+=2;
                     continue;
                  }
 
                  strip.push_back(Segment(point[1],point[0]));

                  // Implicit loop closing...
                  if (strip.size()>=2 && point[1]==first)
                  {
                     AddStrip(strip,true);
                     strip.resize(0);
                  }

                  prev = point[1];
                  point +=2;
              }
               break;
            case pcTile: point+=3; break;
            case pcTileTrans: point+=4; break;
            case pcTileCol: point+=5; break;
            case pcTileTransCol: point+=6; break;
         }
      }

      if (strip.size()>1)
      {
         float s = mScale * 0.707;
         if (data.mMinScale==0 || s>data.mMinScale)
            data.mMinScale = s;

         s = mScale * 1.41;
         if (data.mMaxScale==0 || s<data.mMaxScale)
            data.mMaxScale = s;
       
         AddStrip(strip,false);
      }
   }



   DrawElement mElement;
   HardwareData &data;
   Texture     *mTexture;
   bool        mGradReflect;
   unsigned int mGradFlags;
   bool        mSolidMode;
   bool        mAlphaAA;
   double      mMiterLimit;
   double      mPerpLen;
   double      mScale;
   double      mCurveThresh2;
   double      mFatLineCullThresh;
   Matrix      mTextureMapper;
   StrokeCaps   mCaps;
   StrokeJoints mJoints;
};

void CreatePointJob(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                   HardwareContext &inHardware)
{
   DrawElement elem;
   
   memset(&elem,0,sizeof(elem));
   elem.mColour = 0xffffffff;
   GraphicsSolidFill *fill = inJob.mFill ? inJob.mFill->AsSolidFill() : 0;
   if (fill)
      elem.mColour = fill->mRGB.ToInt();
   GraphicsStroke *stroke = inJob.mStroke;
   if (stroke)
   {
      elem.mScaleMode = stroke->scaleMode;
      elem.mWidth = stroke->thickness;
   }
   else
   {
      elem.mScaleMode = ssmNormal;
      elem.mWidth = -1;
   }

   elem.mPrimType = ptPoints;
   elem.mVertexOffset = ioData.mArray.size();
   elem.mStride = sizeof(float)*2;
   if (!fill)
   {
     elem.mColourOffset = elem.mVertexOffset + elem.mStride;
     elem.mStride += sizeof(int);
     elem.mFlags |= DRAW_HAS_COLOUR;
     elem.mColour = 0xffffffff;
   }

   elem.mCount = inJob.mDataCount / (fill ? 2 : 3);
   ioData.mArray.resize( elem.mVertexOffset + elem.mStride*elem.mCount );

   UserPoint *srcV =  (UserPoint *)&inPath.data[ inJob.mData0 ];
   UserPoint *v = (UserPoint *)&ioData.mArray[ elem.mVertexOffset ];
   
   for(int i=0;i<elem.mCount;i++)
   {
      *v = *srcV++;
      v = (UserPoint *)( (char *)v + elem.mStride );
   }

   if (!fill)
   {
      const int * src = (const int *)(&inPath.data[ inJob.mData0 + elem.mCount*2]);
      int * dest =  (int *)&ioData.mArray[ elem.mColourOffset ];
      for(int i=0;i<elem.mCount;i++)
      {
         int s = src[i];
         *dest = (s & 0xff00ff00) | ((s>>16)&0xff) | ((s<<16) & 0xff0000);
         dest = (int *)( (char *)dest + elem.mStride );
      }
   }

   ioData.mElements.push_back(elem);
}

void BuildHardwareJob(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                      HardwareContext &inHardware, const RenderState &inState)
{
   ioData.releaseVbo();
   
   if (inJob.mIsPointJob)
      CreatePointJob(inJob,inPath,ioData,inHardware);
   else
   {
      HardwareBuilder builder(inJob,inPath,ioData,inHardware, inState);
   }
}


// --- HardwareData ---------------------------------------------------------------------

HardwareData::HardwareData()
{
   mRendersWithoutVbo = 0;
   mVertexBo = 0;
   mContextId = 0;
   mVboOwner = 0;
   mMinScale = mMaxScale = 0.0;
}

void HardwareData::releaseVbo()
{
   if (mVboOwner)
   {
      if (mVertexBo && mContextId==gTextureContextVersion)
         mVboOwner->DestroyVbo(mVertexBo);
      mVboOwner->DecRef();
      mVboOwner=0;
   }
   mContextId = 0;
   mVertexBo = 0;
   mRendersWithoutVbo = 0;
}

float HardwareData::scaleOf(const RenderState &inState) const
{
   const Matrix &m = *inState.mTransform.mMatrix;
   return sqrt( 0.5*( m.m00*m.m00 + m.m01*m.m01 + m.m10*m.m10 + m.m11*m.m11 ) );
}

bool HardwareData::isScaleOk(const RenderState &inState) const
{
   if (mMinScale==0 && mMaxScale==0)
      return true;
   
   float scale = scaleOf(inState);
   if (mMinScale>0 && scale<mMinScale)
   {
      //printf("%f<%f\n", scale, mMinScale);
      return false;
   }
   if (mMaxScale>0 && scale>mMaxScale)
   {
      //printf("%f>%f\n", scale, mMaxScale);
      return false;
   }
   return true;
}


void HardwareData::clear()
{
   releaseVbo();
   mArray.resize(0);
   mElements.resize(0);
   mMinScale = mMaxScale = 0.0;
}

HardwareData::~HardwareData()
{
   releaseVbo();
   for(int i=0;i<mElements.size();i++)
      if (mElements[i].mSurface)
         mElements[i].mSurface->DecRef();
}

// --- Texture -----------------------------
void Texture::Dirty(const Rect &inRect)
{
   if (!mDirtyRect.HasPixels())
      mDirtyRect = inRect;
   else
      mDirtyRect = mDirtyRect.Union(inRect);
}

// --- HardwareContext -----------------------------


// Cache line thickness transforms...
static Matrix sLastMatrix;
double sLineScaleV = -1;
double sLineScaleH = -1;
double sLineScaleNormal = -1;


inline bool HitTri(const UserPoint &base, const UserPoint &_v0, const UserPoint &_v1, const UserPoint &pos)
{
   bool bgx = pos.x>base.x;
   if ( bgx!=(pos.x>_v0.x) || bgx!=(pos.x>_v1.x) )
   {
      bool bgy = pos.y>base.y;
      if ( bgy!=(pos.y>_v0.y) || bgy!=(pos.y>_v1.y) )
      {
         UserPoint v0 = _v0 - base;
         UserPoint v1 = _v1 - base;
         UserPoint v2 = pos - base;
         double dot00 = v0.Dot(v0);
         double dot01 = v0.Dot(v1);
         double dot02 = v0.Dot(v2);
         double dot11 = v1.Dot(v1);
         double dot12 = v1.Dot(v2);

         // Compute barycentric coordinates
         double denom = (dot00 * dot11 - dot01 * dot01);
         if (denom!=0)
         {
            denom = 1 / denom;
            double u = (dot11 * dot02 - dot01 * dot12) * denom;
            if (u>=0)
            {
               double v = (dot00 * dot12 - dot01 * dot02) * denom;

               // Check if point is in triangle
               if ( (v >= 0) && (u + v < 1) )
                  return true;
            }
         }
      }
   }
 
   return false;
}




bool HardwareContext::Hits(const RenderState &inState, const HardwareData &inData )
{
   if (inState.mClipRect.w!=1 || inState.mClipRect.h!=1)
      return false;

   UserPoint screen(inState.mClipRect.x, inState.mClipRect.y);
   UserPoint pos = inState.mTransform.mMatrix->ApplyInverse(screen);

   if (sLastMatrix!=*inState.mTransform.mMatrix)
   {
      sLastMatrix=*inState.mTransform.mMatrix;
      sLineScaleV = -1;
      sLineScaleH = -1;
      sLineScaleNormal = -1;
   }


   // TODO: include extent in HardwareArrays

   const DrawElements &elements = inData.mElements;
   for(int e=0;e<elements.size();e++)
   {
      const DrawElement &draw = elements[e];
      UserPoint *v0 = (UserPoint *)&inData.mArray[ draw.mVertexOffset ];
      #define V(i) *((UserPoint *)((char *)v0+(i)*draw.mStride))

      if (draw.mPrimType == ptLineStrip)
      {
         if ( draw.mCount < 2 || draw.mWidth==0)
            continue;

         double width = 1;
         Matrix &m = sLastMatrix;
         switch(draw.mScaleMode)
         {
            case ssmNone: width = draw.mWidth; break;
            case ssmNormal:
            case ssmOpenGL:
               if (sLineScaleNormal<0)
                  sLineScaleNormal =
                     sqrt( 0.5*( m.m00*m.m00 + m.m01*m.m01 +
                                 m.m10*m.m10 + m.m11*m.m11 ) );
               width = draw.mWidth*sLineScaleNormal;
               break;
            case ssmVertical:
               if (sLineScaleV<0)
                  sLineScaleV =
                     sqrt( m.m00*m.m00 + m.m01*m.m01 );
               width = draw.mWidth*sLineScaleV;
               break;

            case ssmHorizontal:
               if (sLineScaleH<0)
                  sLineScaleH =
                     sqrt( m.m10*m.m10 + m.m11*m.m11 );
               width = draw.mWidth*sLineScaleH;
               break;
         }

         double x0 = pos.x - width;
         double x1 = pos.x + width;
         double y0 = pos.y - width;
         double y1 = pos.y + width;
         double w2 = width*width;

         UserPoint p0 = V(0);

         int prev = 0;
         if (p0.x<x0) prev |= 0x01;
         if (p0.x>x1) prev |= 0x02;
         if (p0.y<y0) prev |= 0x04;
         if (p0.y>y1) prev |= 0x08;
         if (prev==0 && pos.Dist2(p0)<=w2)
            return true;
         for(int i=1;i<draw.mCount;i++)
         {
            UserPoint p = V(i);
            int flags = 0;
            if (p.x<x0) flags |= 0x01;
            if (p.x>x1) flags |= 0x02;
            if (p.y<y0) flags |= 0x04;
            if (p.y>y1) flags |= 0x08;
            if (flags==0 && pos.Dist2(p)<=w2)
               return true;
            if ( !(flags & prev) )
            {
               // Line *may* pass though the point...
               UserPoint vec = p-p0;
               double len = sqrt(vec.x*vec.x + vec.y*vec.y);
               if (len>0)
               {
                  double a = vec.Dot(pos-p0)/len;
                  if (a>0 && a<1)
                  {
                     if ( (p0 + vec*a).Dist2(pos) < w2 )
                        return true;
                  }
               }
            }
            prev = flags;
            p0 = p;
         }
      }
      else if (draw.mPrimType == ptTriangleFan)
      {
         if (draw.mCount<3)
            continue;
         UserPoint p0 = V(0);
         int count_left = 0;
         for(int i=1;i<=draw.mCount;i++)
         {
            UserPoint p = V(i%draw.mCount);
            if ( (p.y<pos.y) != (p0.y<pos.y) )
            {
               // Crosses, but to the left?
               double ratio = (pos.y-p0.y)/(p.y-p0.y);
               double x = p0.x + (p.x-p0.x) * ratio;
               if (x<pos.x)
                  count_left++;
            }
            p0 = p;
         }
         if (count_left & 1)
            return true;
      }
      else if (draw.mPrimType == ptTriangles)
      {
         if (draw.mCount<3)
            continue;
         
         int numTriangles = draw.mCount / 3;
      
         int vidx = 0;
         for(int i=0;i<numTriangles;i++)
         {
            UserPoint base = V(vidx++);
            UserPoint _v0 = V(vidx++);
            UserPoint _v1 = V(vidx++);
            if (HitTri(base,_v0,_v1,pos))
               return true;
        }
      }
      else if (draw.mPrimType == ptTriangleStrip)
      {
         for(int i=2;i<draw.mCount;i++)
         {
            if (HitTri(V(i-2), V(i-2),V(i), pos ))
               return true;
         }
      }
   }

   return false;
}



} // end namespace lime

