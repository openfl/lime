#include <Graphics.h>
#include "renderer/common/Surface.h"
#include "renderer/common/SimpleSurface.h"


#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


namespace lime
{

class HardwareBuilder
{
public:
   HardwareBuilder(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                   HardwareContext &inHardware)
   {
      mTexture = 0;
      bool tile_mode = false;
      mElement.mColour = 0xffffffff;
      mSolidMode = false;
      mPerpLen = 0.5;
      bool tessellate_lines = true;

      if (inJob.mIsTileJob)
      {
         mElement.mBitmapRepeat = true;
         mElement.mBitmapSmooth = false;

         mElement.mPrimType = ptTriangles;
         mElement.mScaleMode = ssmNormal;
         mElement.mWidth = -1;

         GraphicsBitmapFill *bmp = inJob.mFill->AsBitmapFill();
         mSurface = bmp->bitmapData->IncRef();
         mTexture = mSurface->GetOrCreateTexture(inHardware);
         mElement.mBitmapRepeat = false;
         mElement.mBitmapSmooth = bmp->smooth;
         tile_mode = true;
      }
      else if (inJob.mFill)
      {
         mSolidMode = true;
         mElement.mPrimType = inJob.mTriangles ? ptTriangles : ptTriangleFan;
         mElement.mScaleMode = ssmNormal;
         mElement.mWidth = -1;
         if (!SetFill(inJob.mFill,inHardware))
            return;
      }
      else if (tessellate_lines && inJob.mStroke->scaleMode==ssmNormal)
      {
         // ptTriangleStrip?
         mElement.mPrimType = ptTriangles;
         GraphicsStroke *stroke = inJob.mStroke;
         if (!SetFill(stroke->fill,inHardware))
            return;

         mPerpLen = stroke->thickness * 0.5;
         if (mPerpLen<=0.0)
            mPerpLen = 0.5;
         else if (mPerpLen<0.5)
         {
            mPerpLen = 0.5;
         }

         mCaps = stroke->caps;
         mJoints = stroke->joints;
         if (mJoints==sjMiter)
            mMiterLimit = stroke->miterLimit*mPerpLen;
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
      mElement.mFirst = 0;
      mElement.mCount = 0;


      if (inJob.mTriangles)
      {
         bool has_colour = inJob.mTriangles->mColours.size()>0;
         unsigned int flags = 0;
         if (inJob.mTriangles->mType == vtVertexUVT)
            flags |= HardwareArrays::PERSPECTIVE;
         if (inJob.mTriangles->mBlendMode==bmAdd)
            flags |= HardwareArrays::BM_ADD;
         if (inJob.mTriangles->mBlendMode==bmMultiply)
            flags |= HardwareArrays::BM_MULTIPLY;
         if (inJob.mTriangles->mBlendMode==bmScreen)
            flags |= HardwareArrays::BM_SCREEN;
         if (mSurface && (mSurface->GetAlphaMode () == amPremultiplied))
            flags |= HardwareArrays::AM_PREMULTIPLIED;
         mArrays = &ioData.GetArrays(mSurface,has_colour,flags);
         AddTriangles(inJob.mTriangles);

         if (inJob.mStroke && inJob.mStroke->fill)
         {
            mElement.mPrimType = ptLines;
            GraphicsStroke *stroke = inJob.mStroke;
            if (!SetFill(stroke->fill,inHardware))
               return;

            mArrays = &ioData.GetArrays(mSurface,false,mGradFlags);
            mElement.mFirst = 0;
            mElement.mCount = 0;
            mElement.mScaleMode = ssmNormal;
            mElement.mWidth = stroke->thickness;
            AddTriangleLines(inJob.mTriangles);
         }
      }
      else if (tile_mode)
      {
         bool has_colour = false;
         BlendMode bm = bmNormal;
         GetTileFlags(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, has_colour, bm);
         mArrays = &ioData.GetArrays(mSurface,has_colour,(bm == bmAdd) ? HardwareArrays::BM_ADD : (bm == bmMultiply) ? HardwareArrays::BM_MULTIPLY : (bm == bmScreen) ? HardwareArrays::BM_SCREEN : 0);
         AddTiles(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]);
      }
      else if (tessellate_lines && !mSolidMode)
      {
         mArrays = &ioData.GetArrays(mSurface,false,(mSurface && (mSurface->GetAlphaMode() == amPremultiplied)) ? mGradFlags | HardwareArrays::AM_PREMULTIPLIED : mGradFlags);
         AddLineTriangles(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]);
      }
      else
      {
         mArrays = &ioData.GetArrays(mSurface,false,(mSurface && (mSurface->GetAlphaMode() == amPremultiplied)) ? mGradFlags | HardwareArrays::AM_PREMULTIPLIED : mGradFlags);
         AddObject(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]);
      }
   }

  
   bool SetFill(IGraphicsFill *inFill,HardwareContext &inHardware)
   {
      mSurface = 0;
      mElement.mBitmapRepeat = true;
      mElement.mBitmapSmooth = false;
      mGradFlags = 0;

      GraphicsSolidFill *solid = inFill->AsSolidFill();
      if (solid)
      {
         //if (solid -> mRGB.a == 0)
            //return false;
         mElement.mColour = solid->mRGB.ToInt();
      }
      else
      {
         GraphicsGradientFill *grad = inFill->AsGradientFill();
         if (grad)
         {
            mGradReflect = grad->spreadMethod == smReflect;
            int w = mGradReflect ? 512 : 256;
            mSurface = new SimpleSurface(w,1,pfARGB);
            mSurface->IncRef();
            grad->FillArray( (ARGB *)mSurface->GetBase(), false);

            mElement.mBitmapRepeat = grad->spreadMethod!=smPad;
            mElement.mBitmapSmooth = true;

            mTextureMapper = grad->matrix.Inverse();
            if (!grad->isLinear)
            {
               mGradFlags |= HardwareArrays::RADIAL;
               if (grad->focalPointRatio!=0)
               {
                  int r = fabs(grad->focalPointRatio)*256.0;
                  if (r>255) r = 255;
                  
                  mGradFlags |= (r << 8);
                  if (grad->focalPointRatio<0)
                     mGradFlags |= HardwareArrays::FOCAL_SIGN;
               }
            }
            //return true;
         }
         else
         {
            GraphicsBitmapFill *bmp = inFill->AsBitmapFill();
            mTextureMapper = bmp->matrix.Inverse();
            mSurface = bmp->bitmapData->IncRef();
            mTexture = mSurface->GetOrCreateTexture(inHardware);
            mElement.mBitmapRepeat = bmp->repeat;
            mElement.mBitmapSmooth = bmp->smooth;
          }
       }
       //return false;
       return true;
   }

   ~HardwareBuilder()
   {
      if (mSurface)
         mSurface->DecRef();
   }


   void CalcTexCoords()
   {
      Vertices &vertices = mArrays->mVertices;
      Vertices &tex = mArrays->mTexCoords;
      int v0 = vertices.size();
      int t0 = tex.size();
      tex.resize(v0);
      bool radial = mGradFlags & HardwareArrays::RADIAL;
      for(int i=t0;i<v0;i++)
      {
         UserPoint p = mTextureMapper.Apply(vertices[i].x,vertices[i].y);
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
         tex[i] = p;
       }
   }


   void AddTriangles(GraphicsTrianglePath *inPath)
   {
      Vertices &vertices = mArrays->mVertices;
      Colours &colours = mArrays->mColours;
      Vertices &tex = mArrays->mTexCoords;
      DrawElements &elements = mArrays->mElements;
      bool persp = inPath->mType == vtVertexUVT;
      mElement.mFirst = vertices.size() / (persp?2:1);
      mElement.mPrimType = ptTriangles;
      
      //Just overwriting viewport
      mArrays->mViewport = inPath->mViewport;
      
      const float *t = &inPath->mUVT[0];
      for(int v=0;v<inPath->mVertices.size();v++)
      {
         if (!persp)
         {
           vertices.push_back(inPath->mVertices[v]);
           if(inPath->mColours.size()>0)
           {
              colours.push_back(inPath->mColours[v]);/*mwb*/
           }
         }

         if (inPath->mType != vtVertex)
         {
            tex.push_back( mTexture->TexToPaddedTex( UserPoint(t[0],t[1]) ) );
            t+=2;
            if (persp)
            {
               float w= 1.0/ *t++;
               vertices.push_back(inPath->mVertices[v]*w);
               vertices.push_back( UserPoint(0,w) );
            }
         }
      }

      mElement.mCount = (vertices.size() - mElement.mFirst)/(persp ? 2:1);
      elements.push_back(mElement);
   }


   void AddTriangleLines(GraphicsTrianglePath *inPath)
   {
      Vertices &vertices = mArrays->mVertices;
      DrawElements &elements = mArrays->mElements;
      mElement.mFirst = vertices.size();
      mElement.mPrimType = ptLines;
      
      //Just overwriting blend mode and viewport
      mArrays->mViewport = inPath->mViewport;
      
      int tri_count = inPath->mVertices.size()/3;
      UserPoint *tri =  &inPath->mVertices[0];
      for(int v=0;v<tri_count;v++)
      {
         vertices.push_back(tri[0]);
         vertices.push_back(tri[1]);
         vertices.push_back(tri[1]);
         vertices.push_back(tri[2]);
         vertices.push_back(tri[2]);
         vertices.push_back(tri[0]);
         tri+=3;
      }

      mElement.mCount = (vertices.size() - mElement.mFirst);
      if (mSurface)
         CalcTexCoords();
      elements.push_back(mElement);
   }


  void GetTileFlags(const uint8* inCommands, int inCount,bool &outColour, BlendMode &outBlendMode)
  {
     for(int i=0;i<inCount;i++)
        if (inCommands[i] == pcTileCol || inCommands[i]==pcTileTransCol)
           outColour = true;
        else if (inCommands[i] == pcBlendModeAdd)
           outBlendMode = bmAdd;
		else if (inCommands[i] == pcBlendModeMultiply)
           outBlendMode = bmMultiply;
		else if (inCommands[i] == pcBlendModeScreen)
           outBlendMode = bmScreen;
  }

  void AddTiles(const uint8* inCommands, int inCount, const float *inData)
  {
      Vertices &vertices = mArrays->mVertices;
      Vertices &tex = mArrays->mTexCoords;
      Colours &colours = mArrays->mColours;
      const UserPoint *point = (const UserPoint *)inData;
      mElement.mFirst = vertices.size();

      vertices.reserve(vertices.size() + (6 * inCount));
      tex.reserve(tex.size() + (6 * inCount));
      colours.reserve(colours.size() + (6 * inCount));

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
                  const UserPoint &pos = point[0];
                  const UserPoint &tex_pos = point[1];
                  const UserPoint &size = point[2];
                  point += 3;
				  
                  if (inCommands[i]&pcTile_Trans_Bit)
                  {
                     const UserPoint &trans_x = *point++;
                     const UserPoint &trans_y = *point++;

                     const UserPoint p1(pos.x + size.x*trans_x.x,
                                        pos.y + size.x*trans_x.y);
                     const UserPoint p2(pos.x + size.x*trans_x.x + size.y*trans_y.x,
                                        pos.y + size.x*trans_x.y + size.y*trans_y.y);
                     const UserPoint p3(pos.x + size.y*trans_y.x,
                                        pos.y + size.y*trans_y.y);

                     vertices.push_back( pos );
                     vertices.push_back( p1 );
                     vertices.push_back( p2 );
                     vertices.push_back( pos );
                     vertices.push_back( p2 );
                     vertices.push_back( p3 );
                  }
                  else
                  {
                     vertices.push_back( pos );
                     vertices.push_back( UserPoint(pos.x+size.x,pos.y) );
                     vertices.push_back( UserPoint(pos.x+size.x,pos.y+size.y) );
                     vertices.push_back( pos );
                     vertices.push_back( UserPoint(pos.x+size.x,pos.y+size.y) );
                     vertices.push_back( UserPoint(pos.x,pos.y+size.y) );
                  }

                  const UserPoint tp1 = mTexture->PixelToTex(tex_pos);
                  const UserPoint tp2 = mTexture->PixelToTex(UserPoint(tex_pos.x+size.x,tex_pos.y+size.y));

                  tex.push_back( tp1 );
                  tex.push_back( mTexture->PixelToTex(UserPoint(tex_pos.x+size.x,tex_pos.y)) );
                  tex.push_back( tp2 );
                  tex.push_back( tp1 );
                  tex.push_back( tp2 );
                  tex.push_back( mTexture->PixelToTex(UserPoint(tex_pos.x,tex_pos.y+size.y)) );

                  if (inCommands[i]&pcTile_Col_Bit)
                  {
                     const UserPoint &rg = *point++;
                     const UserPoint &ba = *point++;
                     #ifdef BLACKBERRY
                     const uint32 col = ((int)(rg.x*255)) |
                                        (((int)(rg.y*255))<<8) |
                                        (((int)(ba.x*255))<<16) |
                                        (((int)(ba.y*255))<<24);
                     #else
                     const uint32 col = ((rg.x<0 ? 0 : rg.x>1?255 : (int)(rg.x*255))) |
                                        ((rg.y<0 ? 0 : rg.y>1?255 : (int)(rg.y*255))<<8) |
                                        ((ba.x<0 ? 0 : ba.x>1?255 : (int)(ba.x*255))<<16) |
                                        ((ba.y<0 ? 0 : ba.y>1?255 : (int)(ba.y*255))<<24);
                     #endif
                     colours.push_back( col );
                     colours.push_back( col );
                     colours.push_back( col );
                     colours.push_back( col );
                     colours.push_back( col );
                     colours.push_back( col );
                  }
               }
         }
      }

      mElement.mCount = vertices.size() - mElement.mFirst;
      if (mElement.mCount>0)
         mArrays->mElements.push_back(mElement);
   }


   #define FLAT 0.000001
   void AddPolygon(Vertices &inOutline,const QuickVec<int> &inSubPolys)
   {
      if (mSolidMode && inOutline.size()<3)
         return;

      Vertices &vertices = mArrays->mVertices;
      mElement.mFirst = vertices.size();
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


      mElement.mCount = inOutline.size();
      vertices.resize(mElement.mFirst + mElement.mCount);
      for(int i=0;i<inOutline.size();i++)
         vertices[i+mElement.mFirst] = inOutline[i];
      if (mSurface)
         CalcTexCoords();
      mArrays->mElements.push_back(mElement);

      if (!isConvex)
         mArrays->mElements.last().mPrimType = ptTriangles;
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

   void AddArc(Vertices &vertices,UserPoint inP, double angle, UserPoint inVx, UserPoint inVy, UserPoint p0, UserPoint p1)
   {
      int steps = 1 + angle*8;
      double d_theta = angle / (steps+1);
      double theta = d_theta;
      for(int i=0;i<steps;i++)
      {
         UserPoint x = inP + inVx*cos(theta) + inVy*sin(theta);
         theta += d_theta;
         vertices.push_back(inP);
         vertices.push_back(p0);
         vertices.push_back(x);
         p0 = x;
      }
      vertices.push_back(inP);
      vertices.push_back(p0);
      vertices.push_back(p1);
   }

   void AddMiter(Vertices &vertices,UserPoint inP, UserPoint p0, UserPoint p1, double inAlpha,
                UserPoint dir1, UserPoint dir2)
   {
       if (inAlpha>mMiterLimit)
       {
          UserPoint corner0 = p0+dir1*mMiterLimit;
          UserPoint corner1 = p1-dir2*mMiterLimit;

          vertices.push_back(inP);
          vertices.push_back(p0);
          vertices.push_back(corner0);

          vertices.push_back(inP);
          vertices.push_back(corner0);
          vertices.push_back(corner1);

          vertices.push_back(inP);
          vertices.push_back(corner1);
          vertices.push_back(p1);
       }
       else
       {
          UserPoint corner = p0+dir1*inAlpha;
          vertices.push_back(inP);
          vertices.push_back(p0);
          vertices.push_back(corner);

          vertices.push_back(inP);
          vertices.push_back(corner);
          vertices.push_back(p1);
       }
   }

   void AddCurveSegment(Vertices &vertices,UserPoint inP0,UserPoint inP1,UserPoint inP2, UserPoint perp0, UserPoint perp1,
                        UserPoint p0_left, UserPoint p0_right, UserPoint p1_left, UserPoint p1_right)
   {
      double len = (inP0 - inP1).Norm() + (inP2 - inP1).Norm();
      
      int steps = (int)len*0.1;
      
      if (len < 50 && steps < 10) steps = 50;
      else if (steps < 1) steps = 1;
      else if (steps > 100) steps = 100;

      double step = 1.0 / (steps);
      double t = 0;

      UserPoint v0 = p0_right - p0_left;
      UserPoint v1 = p1_right - p1_left;
      
      UserPoint last_p_left = inP0 - perp0;
      UserPoint last_p_right = inP0 + perp0;

      // Clip against end ...
      if ( v0.Cross(last_p_left-p0_left)>0  )
         last_p_left = p0_left;
      if ( v0.Cross(last_p_right-p0_left)>0 )
         last_p_right = p0_right;
      // TODO - against other end?
      for (int s=1; s <= steps; s++)
      {
         t += step;
         double t_ = 1.0 - t;
         UserPoint p = inP0 * (t_ * t_) + inP1 * (2.0 * t * t_) + inP2 * (t * t);
         UserPoint dir = (inP0 * -t_ + inP1 * (1.0 - 2.0 * t) + inP2 * t);
         UserPoint perp = dir.Perp(mPerpLen);
         if (s==step)
         {
            p = inP2;
            perp = perp1;
         }

         UserPoint p_right = p + perp;
         UserPoint p_left = p - perp;

         if (v0.Cross(dir) < 0  ) // if pointing in same direction (left-handed)
         {
            if ( v0.Cross(p_left-p0_left)>0)
               p_left = p0_left;
            if ( v0.Cross(p_right-p0_left)>0)
               p_right = p0_right;
         }

         if (v1.Cross(dir) < 0 ) // if pointing in same direction (left-handed)
         {
            if ( v1.Cross(p_left-p1_left)<0)
               p_left = p1_left;
            if ( v1.Cross(p_right-p1_left)<0)
               p_right = p1_right;
         }

         if (p_left==last_p_left)
         {
            if (p_right!=last_p_right)
            {
               vertices.push_back(p_left);
               vertices.push_back(last_p_right);
               vertices.push_back(p_right);
            }
         }
         else if (p_right==last_p_right)
         {
            if (p_left!=last_p_left)
            {
               vertices.push_back(last_p_left);
               vertices.push_back(p_right);
               vertices.push_back(p_left);
            }
         }
         else
         {
            vertices.push_back(last_p_left);
            vertices.push_back(last_p_right);
            vertices.push_back(p_left);

            vertices.push_back(p_left);
            vertices.push_back(last_p_right);
            vertices.push_back(p_right);
         }

         last_p_left = p_left;
         last_p_right = p_right;
      }
   }

   void EndCap(Vertices &vertices,UserPoint p0, UserPoint perp)
   {
      UserPoint back(-perp.y, perp.x);
      if (mCaps==scSquare)
      {
         vertices.push_back(p0+perp);
         vertices.push_back(p0+perp + back);
         vertices.push_back(p0-perp);

         vertices.push_back(p0+perp + back);
         vertices.push_back(p0-perp + back);
         vertices.push_back(p0-perp);
      }
      else
      {
         int n = std::max(2,(int)(mPerpLen * 4));
         double dtheta = M_PI / n;
         double theta = 0.0;
         UserPoint prev(perp);
         for(int i=1;i<n;i++)
         {
            UserPoint p =  perp*cos(theta) + back*sin(theta);
            vertices.push_back(p0);
            vertices.push_back(p0+prev);
            vertices.push_back(p0+p);
            prev = p;
            theta += dtheta;
         }

         vertices.push_back(p0);
         vertices.push_back(p0+prev);
         vertices.push_back(p0-perp);
      }
   }

   void AddStrip(const QuickVec<Segment> &inPath, bool inLoop)
   {
      Vertices &vertices = mArrays->mVertices;
      mElement.mFirst = vertices.size();

      // Endcap 0 ...
      if (!inLoop && (mCaps==scSquare || mCaps==scRound))
      {
         UserPoint p0 = inPath[0].p;
         EndCap(vertices, p0, inPath[1].getDir0(p0).Perp(mPerpLen));
      }

      double prev_alpha = 0;
      for(int i=1;i<inPath.size();i++)
      {
          const Segment &seg = inPath[i];
          UserPoint p0 = inPath[i-1].p;
          UserPoint p = seg.p;

          UserPoint dir0 = seg.getDir0(p0).Normalized();
          UserPoint dir1 = seg.getDir1(p0).Normalized();


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

             Make the split such that DpY and down belongs to this segment - first add this DpY triangle, then
              the remainder of the segment happens below the D-Y line.

             On one side (right hand, drawn here) the segments will overlap - on the other side, there
              will be a join.  Which side this will be depends on the sign of alpha.  When reversed, the
              roles of Y and Z will change.

             BpY is for this upper segment  - but there is an equivalent B'p0Y' for this segment.
              First we add B'p-Y' triangle, and work from B'Y' line
          */

          UserPoint perp0(-dir0.y*mPerpLen, dir0.x*mPerpLen);
          UserPoint perp1(-dir1.y*mPerpLen, dir1.x*mPerpLen);
          UserPoint next_perp(-next_dir.y*mPerpLen, next_dir.x*mPerpLen);

          double denom_x = dir1.x+next_dir.x;
          double denom_y = dir1.y+next_dir.y;
          double alpha=0;

          // Choose the better-conditioned axis
          if (fabs(denom_x)>fabs(denom_y))
             alpha = denom_x==0 ? 0 : (perp1.x-next_perp.x)/denom_x;
          else
             alpha = denom_y==0 ? 0 : (perp1.y-next_perp.y)/denom_y;
 
          UserPoint p1_left = p-perp1;
          UserPoint p1_right = p+perp1;

          // This could start getting dodgy when the line doubles-back
          double max_alpha = std::max( (p0-p).Norm()*0.5, mPerpLen );
          if (fabs(alpha)>max_alpha)
          {
             // draw overlapped
          }
          else if (alpha>0)
          {
             p1_right -= dir1 * alpha;
             vertices.push_back(p1_left);
             vertices.push_back(p);
             vertices.push_back(p1_right);
          }
          else if (alpha<0)
          {
             p1_left += dir1 * alpha;
             vertices.push_back(p1_left);
             vertices.push_back(p);
             vertices.push_back(p1_right);
          }

          UserPoint p0_left = p0-perp0;
          UserPoint p0_right = p0+perp0;

          if (i==1 && inLoop)
          {
             UserPoint prev_dir = inPath[inPath.size()-1].getDir1(inPath[inPath.size()-2].p).Normalized();
             UserPoint prev_perp(-prev_dir.y*mPerpLen, prev_dir.x*mPerpLen);
             double denom_x = prev_dir.x+dir0.x;
             double denom_y = prev_dir.y+dir0.y;

             // Choose the better-conditioned axis
             if (fabs(denom_x)>fabs(denom_y))
                prev_alpha = denom_x==0 ? 0 : (prev_perp.x-perp0.x)/denom_x;
             else
                prev_alpha = denom_y==0 ? 0 : (prev_perp.y-perp0.y)/denom_y;
          }

          if (fabs(prev_alpha)>max_alpha)
          {
              // do nothing
          }
          else if (prev_alpha>0)
          {
             p0_right += dir0 * std::min(prev_alpha,max_alpha);
             vertices.push_back(p0_left);
             vertices.push_back(p0);
             vertices.push_back(p0_right);
          }
          else if (prev_alpha<0)
          {
             p0_left -= dir0 * std::max(prev_alpha,-max_alpha);
             vertices.push_back(p0_left);
             vertices.push_back(p0);
             vertices.push_back(p0_right);
          }

          if (alpha)
             switch(mPerpLen<1 ? sjBevel : mJoints)
             {
                case sjRound:
                   {
                   double angle = acos(dir1.Dot(next_dir));
                   if (angle<0) angle += M_PI;
                   if (alpha>0) // left
                      AddArc(vertices, p, angle, -perp1, dir1*mPerpLen, p1_left, p-next_perp );
                   else // right
                      AddArc(vertices, p, angle, perp1, dir1*mPerpLen, p1_right, p+next_perp );
                   }
                   break;

                case sjMiter:
                   if (alpha>0) // left
                      AddMiter(vertices, p, p-perp1, p-next_perp, alpha, dir1, next_dir);
                   else // Right
                      AddMiter(vertices, p, p+perp1, p+next_perp, -alpha, dir1, next_dir);
                   break;

                case sjBevel:
                   if (alpha>0) // left
                   {
                      vertices.push_back(p1_left);
                      vertices.push_back(p);
                      vertices.push_back(p-next_perp);
                   }
                   else
                   {
                      vertices.push_back(p1_right);
                      vertices.push_back(p);
                      vertices.push_back(p+next_perp);
                   }
                   break;
             }

          if (seg.isCurve())
          {
             AddCurveSegment(vertices,p0,seg.curve,seg.p, perp0, perp1, p0_left, p0_right, p1_left, p1_right);
          }
          else
          {
             vertices.push_back(p0_left);
             vertices.push_back(p0_right);
             vertices.push_back(p1_right);

             vertices.push_back(p0_left);
             vertices.push_back(p1_right);
             vertices.push_back(p1_left);
          }

          // Endcap end ...
          if (!inLoop && (i+1==inPath.size()) && (mCaps==scSquare || mCaps==scRound))
             EndCap(vertices, p, dir1.Perp(-mPerpLen));

          prev_alpha = alpha;
      }


      mElement.mCount = vertices.size()-mElement.mFirst;
      if (mSurface)
         CalcTexCoords();
      mArrays->mElements.push_back(mElement);
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
                  first = *point;
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
                  if (strip.size()>2 && point[1]==first)
                  {
                     AddStrip(strip,true);
                     strip.resize(0);
                     first = point[1];
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

      if (strip.size()>0)
         AddStrip(strip,false);
   }



   HardwareArrays *mArrays;
   Surface      *mSurface;
   DrawElement mElement;
   Texture     *mTexture;
   bool        mGradReflect;
   unsigned int mGradFlags;
   bool        mSolidMode;
   double      mMiterLimit;
   double      mPerpLen;
   Matrix      mTextureMapper;
   StrokeCaps   mCaps;
   StrokeJoints mJoints;
};

void CreatePointJob(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                   HardwareContext &inHardware)
{
   DrawElement elem;

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

   elem.mCount = inJob.mDataCount / (fill ? 2 : 3);

   HardwareArrays *arrays = &ioData.GetArrays(0,fill==0, /* TODO: bm add ? */ 0);
   Vertices &vertices = arrays->mVertices;
   elem.mFirst = vertices.size();
   vertices.resize( elem.mFirst + elem.mCount );
   memcpy( &vertices[elem.mFirst], &inPath.data[ inJob.mData0 ], elem.mCount*sizeof(UserPoint) );

   if (!fill)
   {
      Colours &colours = arrays->mColours;
      colours.resize( elem.mFirst + elem.mCount );
      const int * src = (const int *)(&inPath.data[ inJob.mData0 + elem.mCount*2]);
      int * dest = &colours[elem.mFirst];
      int n = elem.mCount;
      for(int i=0;i<n;i++)
      {
         int s = src[i];
         dest[i] = (s & 0xff00ff00) | ((s>>16)&0xff) | ((s<<16) & 0xff0000);
      }
   }

   arrays->mElements.push_back(elem);
}

void BuildHardwareJob(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                      HardwareContext &inHardware)
{
   if (inJob.mIsPointJob)
      CreatePointJob(inJob,inPath,ioData,inHardware);
   else
   {
      HardwareBuilder builder(inJob,inPath,ioData,inHardware);
   }
}


// --- HardwareArrays ---------------------------------------------------------------------

HardwareArrays::HardwareArrays(Surface *inSurface,unsigned int inFlags)
{
   mFlags = inFlags;
   mSurface = inSurface;
   if (inSurface)
      inSurface->IncRef();
}

HardwareArrays::~HardwareArrays()
{
   if (mSurface)
      mSurface->DecRef();
}

bool HardwareArrays::ColourMatch(bool inWantColour)
{
   if (mVertices.empty())
      return true;
   return mColours.empty() != inWantColour;
}



// --- HardwareData ---------------------------------------------------------------------
HardwareData::~HardwareData()
{
   mCalls.DeleteAll();
}

HardwareArrays &HardwareData::GetArrays(Surface *inSurface,bool inWithColour,unsigned int inFlags)
{
   if (mCalls.empty() || mCalls.last()->mSurface != inSurface ||
           !mCalls.last()->ColourMatch(inWithColour) ||
           mCalls.last()->mFlags != inFlags )
   {
       HardwareArrays *arrays = new HardwareArrays(inSurface,inFlags);
       mCalls.push_back(arrays);
   }

   return *mCalls.last();
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


bool HardwareContext::Hits(const RenderState &inState, const HardwareCalls &inCalls )
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


    for(int c=0;c<inCalls.size();c++)
   {
      HardwareArrays &arrays = *inCalls[c];
      Vertices &vert = arrays.mVertices;

      // TODO: include extent in HardwareArrays

      DrawElements &elements = arrays.mElements;
      for(int e=0;e<elements.size();e++)
      {
         DrawElement draw = elements[e];

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

            UserPoint *v = &vert[ draw.mFirst ];
            UserPoint p0 = *v;

            int prev = 0;
            if (p0.x<x0) prev |= 0x01;
            if (p0.x>x1) prev |= 0x02;
            if (p0.y<y0) prev |= 0x04;
            if (p0.y>y1) prev |= 0x08;
            if (prev==0 && pos.Dist2(p0)<=w2)
               return true;
            for(int i=1;i<draw.mCount;i++)
            {
               UserPoint p = v[i];
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
            UserPoint *v = &vert[ draw.mFirst ];
            UserPoint p0 = *v;
            int count_left = 0;
            for(int i=1;i<=draw.mCount;i++)
            {
               UserPoint p = v[i%draw.mCount];
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
            UserPoint *v = &vert[ draw.mFirst ];
			
			   int numTriangles = draw.mCount / 3;
			
            for(int i=0;i<numTriangles;i++)
            {
               UserPoint base = *v++;
               bool bgx = pos.x>base.x;
               if ( bgx!=(pos.x>v[0].x) || bgx!=(pos.x>v[1].x) )
               {
                  bool bgy = pos.y>base.y;
                  if ( bgy!=(pos.y>v[0].y) || bgy!=(pos.y>v[1].y) )
                  {
                     UserPoint v0 = v[0] - base;
                     UserPoint v1 = v[1] - base;
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
               v+=2;
            }
         }
      }
   }

   return false;
}



} // end namespace lime

