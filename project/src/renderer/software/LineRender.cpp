#include "PolygonRender.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif



namespace nme
{

// --- LineRender ---------------------------------------------------

class LineRender : public PolygonRender
{
public:
   typedef void (LineRender::*ItFunc)(const UserPoint &inP0, const UserPoint &inP1);
   ItFunc ItLine;
   double mDTheta;
   GraphicsStroke *mStroke;


   LineRender(const GraphicsJob &inJob, const GraphicsPath &inPath) : PolygonRender(inJob, inPath, inJob.mStroke->fill)
   {
      mStroke = inJob.mStroke;
   }
   
   
   void AddJoint(const UserPoint &p0, const UserPoint &perp1, const UserPoint &perp2)
   {
      bool miter = false;
      switch(mStroke->joints)
      {
         case sjMiter:
            miter = true;
         case sjRound:
         {
            double acw_rot = perp2.Cross(perp1);
            // One side is easy since it is covered by the fat bits of the lines, so
            //  just join up with simple line...
            UserPoint p1,p2;
            if (acw_rot==0)
            {
               // Exactly doubled-back. Assume clockwise rotation...
            }
            if (acw_rot>0)
            {
               (*this.*ItLine)(p0-perp2,p0-perp1);
               p1 = perp1;
               p2 = perp2;
            }
            else
            {
               (*this.*ItLine)(p0+perp1,p0+perp2);
               p1 = -perp2;
               p2 = -perp1;
            }
            // The other size, we must treat properly...
            if (miter)
            {
               UserPoint dir1 = p1.CWPerp();
               UserPoint dir2 = p2.Perp();
               // Find point where:
               //   p0+p1 + a * dir1 = p0+p2 + a * dir2
               //   a [ dir1.x-dir2.x] = p0.x+p2.x - p0.x - p1.x;
               //
               //    also (which ever is better conditioned)
               //
               //   a [ dir1.y-dir2.y] = p0.y+p2.y - p0.x - p1.y;
               double ml = mStroke->miterLimit;
               double denom_x = dir1.x-dir2.x;
               double denom_y = dir1.y-dir2.y;
               double a = (denom_x==0 && denom_y==0) ? ml :
                          fabs(denom_x)>fabs(denom_y) ? std::min(ml,(p2.x-p1.x)/denom_x) :
                                                        std::min(ml,(p2.y-p1.y)/denom_y);
               if (a<ml)
               {
                  UserPoint point = p0+p1 + dir1*a;
                  (*this.*ItLine)(p0+p1,point);
                  (*this.*ItLine)(point, p0+p2);
               }
               else
               {
                  UserPoint point1 = p0+p1 + dir1*a;
                  UserPoint point2 = p0+p2 + dir2*a;
                  (*this.*ItLine)(p0+p1,point1);
                  (*this.*ItLine)(point1,point2);
                  (*this.*ItLine)(point2, p0+p2);
               }
            }
            else
            {
               // Find angle ...
               double denom = perp1.Norm2() * perp2.Norm2();
               if (denom>0)
               {
                  double dot = perp1.Dot(perp2) / sqrt( denom );
                  double theta = dot >= 1.0 ? 0 : dot<= -1.0 ? M_PI : acos(dot);
                  IterateCircle(p0,p1,theta,p2);
               }
            }
            break;
         }
         default:
            (*this.*ItLine)(p0+perp1,p0+perp2);
            (*this.*ItLine)(p0-perp2,p0-perp1);
      }
   }
   
   
   void AddLinePart(UserPoint p0, UserPoint p1, UserPoint p2, UserPoint p3)
   {
      (*this.*ItLine)(p0,p1);
      (*this.*ItLine)(p2,p3);
   }
   
   
   void AlignOrthogonal()
   {
      int n = mCommandCount;
      UserPoint *point = &mTransformed[0];

      if (mStroke->pixelHinting)
      {
         n = mTransformed.size();
         for(int i=0;i<n;i++)
         {
            UserPoint &p = mTransformed[i];
            p.x = floor(p.x) + 0.5;
            p.y = floor(p.y) + 0.5;
         }
         return;
      }

      UserPoint *first = 0;
      UserPoint unaligned_first;
      UserPoint *prev = 0;
      UserPoint unaligned_prev;
      for(int i=0;i<n;i++)
      {
         UserPoint p = *point;
         switch(mCommands[mCommand0 + i])
         {
            case pcWideMoveTo:
               point++;
               p = *point;
            case pcBeginAt:
            case pcMoveTo:
               unaligned_first = *point;
               first = point;
               break;
            
            case pcWideLineTo:
               point++;
               p = *point;
            case pcLineTo:
               if (first && *point==unaligned_first)
                  *point = *first;
               else if (prev)
                  Align(unaligned_prev,*point,*prev,*point);
               break;

            case pcCurveTo:
               point++;
               p = *point;
               break;
         }
         unaligned_prev = p;
         prev = point++;
      }
   }
   
   
   void BuildExtent(const UserPoint &inP0, const UserPoint &inP1)
   {
      mBuildExtent->Add(inP0);
   }
   
   
   inline void EndCap(UserPoint p0, UserPoint perp)
   {
      switch(mStroke->caps)
      {
         case  scSquare:
            {
               UserPoint edge(perp.y,-perp.x);
               (*this.*ItLine)(p0+perp,p0+perp+edge);
               (*this.*ItLine)(p0+perp+edge,p0-perp+edge);
               (*this.*ItLine)(p0-perp+edge,p0-perp);
            break;
            }
         case  scRound:
            IterateCircle(p0,perp,M_PI,-perp);
            break;
         
         default:
            (*this.*ItLine)(p0+perp,p0-perp);
      }
   }
   
   
   double GetPerpLen(const Matrix &m, bool inForExtent)
   {
      if (!mIncludeStrokeInExtent && inForExtent)
      {
         mDTheta = 1e20;
         return 0.0;
      }


      // Convert line data to solid data
      double perp_len = mStroke->thickness;
      if (perp_len==0.0)
         perp_len = 0.5;
      else if (perp_len>=0)
      {
         perp_len *= 0.5;
         switch(mStroke->scaleMode)
         {
            case ssmNone:
               // Done!
               break;
            case ssmNormal:
            case ssmOpenGL:
               perp_len *= sqrt( 0.5*(m.m00*m.m00 + m.m01*m.m01 + m.m10*m.m10 + m.m11*m.m11) );
               break;
            case ssmVertical:
               perp_len *= sqrt( m.m00*m.m00 + m.m01*m.m01 );
               break;
            case ssmHorizontal:
               perp_len *= sqrt( m.m10*m.m10 + m.m11*m.m11 );
               break;
         }
      }
      
      // This may be too fine ....
      mDTheta = M_PI/perp_len;
      return perp_len;
   }
   
   
   int Iterate(IterateMode inMode,const Matrix &m)
   {
      ItLine = inMode==itGetExtent ? &LineRender::BuildExtent :
               inMode==itCreateRenderer ? &LineRender::BuildSolid :
                       &LineRender::BuildHitTest;

     double perp_len = 0.0;
     int alpha = 256;
     
     perp_len = GetPerpLen(m,inMode==itGetExtent);



      int n = mCommandCount;
      UserPoint *point = 0;

      if (inMode==itHitTest)
      {
         point = (UserPoint *)&mData[ mData0 ];
      }
      else
         point = &mTransformed[0];

      // It is a loop if the path has no breaks, it has more than 2 points
      //  and it finishes where it starts...
      UserPoint first;
      UserPoint first_perp;

      UserPoint prev;
      UserPoint prev_perp;

      int points = 0;

      for(int i=0;i<n;i++)
      {
         switch(mCommands[mCommand0 + i])
            {
            case pcWideMoveTo:
               point++;
            case pcBeginAt:
            case pcMoveTo:
               if (points==1 && prev==*point)
               {
                  point++;
                  continue;
               }
               if (points>1)
               {
                  if (points>2 && *point==first)
                  {
                     AddJoint(first,prev_perp,first_perp);
                     points = 1;
                  }
                  else
                  {
                     EndCap(first,-first_perp);
                     EndCap(prev,prev_perp);
                  }
               }
               prev = *point;
               first = *point++;
               points = 1;
               break;
               
            case pcWideLineTo:
               point++;
            case pcLineTo:
               {
               if (points>0)
               {
                  if (*point==prev)
                  {
                     point++;
                     continue;
                  }
                  
                  UserPoint perp = (*point - prev).Perp(perp_len);
                  if (points>1)
                     AddJoint(prev,prev_perp,perp);
                  else
                     first_perp = perp;
                  
                  // Add edges ...
                  AddLinePart(prev+perp,*point+perp,*point-perp,prev-perp);
                  prev = *point;
                  prev_perp = perp;
               }
               
               points++;
               // Implicit loop closing...
               if (points>2 && *point==first)
               {
                  AddJoint(first,prev_perp,first_perp);
                  points = 1;
               }

               point++;
               }
               break;
               
            case pcCurveTo:
               {
                  // Gradients pointing from end-point to control point - trajectory
                  //  is initially parallel to these, end cap perpendicular...
                  UserPoint g0 = point[0]-prev;
                  UserPoint g2 = point[1]-point[0];

                  UserPoint perp = g0.Perp(perp_len);
                  UserPoint perp_end = g2.Perp(perp_len);

                 
                  if (points>0)
                  {
                     if (points>1)
                        AddJoint(prev,prev_perp,perp);
                     else
                        first_perp = perp;
                  }
 
                  if (fabs(g0.Cross(g2))<0.0001)
                  {
                     // Treat as line, rather than curve
                     perp_end = perp;

                     // Add edges ...
                     AddLinePart(prev+perp,point[1]+perp,point[1]-perp,prev-perp);
                     prev = *point;
                     prev_perp = perp;
                  }
                  else
                  {
                     // Add curvy bits
                     if (inMode==itGetExtent)
                     {
                        FatCurveExtent(prev, point[0], point[1],perp_len);
                     }
                     else if (inMode==itHitTest)
                     {
                        HitTestFatCurve(prev, point[0], point[1],perp_len, perp, perp_end);
                     }
                     else
                     {
                        BuildFatCurve(prev, point[0], point[1],perp_len, perp, perp_end);
                     }
                  }
                  
                  prev = point[1];
                  prev_perp = perp_end;
                  point +=2;
                  points++;
                  // Implicit loop closing...
                  if (points>2 && prev==first)
                  {
                     AddJoint(first,perp_end,first_perp);
                     points = 1;
                  }
               }
               break;
            case pcTile: point+=3; break;
            case pcTileTrans: point+=4; break;
            case pcTileCol: point+=5; break;
            case pcTileTransCol: point+=6; break;
         }
      }
      
      if (points>1)
      {
         EndCap(first,-first_perp);
         EndCap(prev,prev_perp);
      }
      
      return alpha;
   }
   
   
   void IterateCircle(const UserPoint &inP0, const UserPoint &inPerp, double inTheta, const UserPoint &inPerp2 )
   {
      UserPoint other(inPerp.CWPerp());
      UserPoint last = inP0+inPerp;
      for(double t=mDTheta; t<inTheta; t+=mDTheta)
      {
         double c = cos(t);
         double s = sin(t);
         UserPoint p = inP0+inPerp*c + other*s;
         (*this.*ItLine)(last,p);
         last = p;
      }
      (*this.*ItLine)(last,inP0+inPerp2);
   }

};

// --- TriangleLineRender ---------------------------------------------------

class TriangleLineRender : public LineRender
{
public:
   Renderer *mSolid;
   GraphicsTrianglePath *mTriangles;

   TriangleLineRender(const GraphicsJob &inJob, const GraphicsPath &inPath, Renderer *inSolid) :
        LineRender(inJob, inPath)
   {
      mSolid = inSolid;
      mTriangles = inJob.mTriangles;
   }
   
   
   ~TriangleLineRender()
   {
      if (mSolid) mSolid->Destroy();
   }
   

   bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent,bool inIncludeStroke)
   {
      bool result = false;
      if (mSolid)
         result = mSolid->GetExtent(inTransform,ioExtent,inIncludeStroke);
      return CachedExtentRenderer::GetExtent(inTransform,ioExtent,inIncludeStroke) || result;
   }
   
   
   bool Hits(const RenderState &inState)
   {
      if (mSolid && mSolid->Hits(inState))
         return true;
      return LineRender::Hits(inState);
   }
   
   
   int Iterate(IterateMode inMode,const Matrix &m)
   {
      ItLine = inMode==itGetExtent ? &LineRender::BuildExtent :
            inMode==itCreateRenderer ? &LineRender::BuildSolid :
                  &LineRender::BuildHitTest;
      
     double perp_len = GetPerpLen(m,inMode==itGetExtent);
     
     UserPoint *point = 0;
     if (inMode==itHitTest)
       point = &mTriangles->mVertices[0];
     else
       point = &mTransformed[0];
      
      int tris = mTriangles->mTriangleCount;
     for(int i=0;i<tris;i++)
      {
         UserPoint v0 = *point++;
         UserPoint v1 = *point++;
         UserPoint v2 = *point++;
         
         UserPoint perp0 = (v1-v0).Perp(perp_len);
         UserPoint perp1 = (v2-v1).Perp(perp_len);
         UserPoint perp2 = (v0-v2).Perp(perp_len);
         
         AddJoint(v0,perp2,perp0);
       AddLinePart(v0+perp0,v1+perp0,v1-perp0,v0-perp0);
         AddJoint(v1,perp0,perp1);
       AddLinePart(v1+perp1,v2+perp1,v2-perp1,v1-perp1);
         AddJoint(v2,perp1,perp2);
       AddLinePart(v2+perp2,v0+perp2,v0-perp2,v2-perp2);
      }
      
     return 256;
   }
   
   
   bool Render( const RenderTarget &inTarget, const RenderState &inState )
   {
      if (mSolid)
         mSolid->Render(inTarget,inState);
      return LineRender::Render(inTarget,inState);
   }
   

   void SetTransform(const Transform &inTransform)
   {
      int points = mTriangles->mVertices.size();
      if (points!=mTransformed.size() || inTransform!=mTransform)
      {
         mTransform = inTransform;
         mTransMat = *inTransform.mMatrix;
         mTransform.mMatrix = &mTransMat;
         mTransform.mMatrix3D = &mTransMat;
         mTransScale9 = *inTransform.mScale9;
         mTransform.mScale9 = &mTransScale9;
         mTransformed.resize(points);
         UserPoint *src= (UserPoint *)&mTriangles->mVertices[ 0 ];
         for(int i=0;i<points;i++)
         mTransformed[i] = mTransform.Apply(src[i].x,src[i].y);
      }
   }
};

Renderer *CreateLineRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath)
{
   return new LineRender(inJob,inPath);
}

Renderer *CreateTriangleLineRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath, Renderer *inSolid)
{
   return new TriangleLineRender(inJob,inPath,inSolid);
}




} // end namespace nme
