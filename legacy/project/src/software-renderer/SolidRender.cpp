#include "PolygonRender.h"


namespace nme
{   

class SolidRender : public PolygonRender
{
public:
      
   
   SolidRender(const GraphicsJob &inJob, const GraphicsPath &inPath) : PolygonRender(inJob, inPath, inJob.mFill) { }
   
   int GetWinding() { return 0x0001; }
   
   int Iterate(IterateMode inMode,const Matrix &)
   {
      int n = mCommandCount;
      if (n<3)
         return 0;

      const UserPoint *point = 0;

      if (inMode==itHitTest)
         point = (const UserPoint *)&mData[ mData0 ];
      else
         point = &mTransformed[0];


      if (inMode==itGetExtent)
      {
         UserPoint last;

         for(int i=0;i<n;i++)
         {
            switch(mCommands[ mCommand0 + i])
            {
               case pcWideMoveTo:
                  point++;
               case pcMoveTo:
               case pcBeginAt:
                  last = *point;
                  point++;
                  break;

               case pcWideLineTo:
                  point++;
               case pcLineTo:
                  mBuildExtent->Add(last);
                  last = *point;
                  mBuildExtent->Add(last);
                  point++;
                  break;
               case pcCurveTo:
                  CurveExtent(last, point[0], point[1]);
                  last = point[1];
                  mBuildExtent->Add(last);
                  point += 2;
                  break;
            }
         }
      }
      else
      {
         UserPoint last_move;
         UserPoint last_point;
         int points = 0;

         typedef void (PolygonRender::*ItFunc)(const UserPoint &inP0, const UserPoint &inP1);
         ItFunc func = inMode==itCreateRenderer ? &PolygonRender::BuildSolid :
                  &PolygonRender::BuildHitTest;

         for(int i=0;i<n;i++)
         {
            switch(mCommands[ mCommand0 + i])
            {
               case pcWideMoveTo:
                  point++;
               case pcMoveTo:
               case pcBeginAt:
                  if (points>1)
                     (*this.*func)(last_point,last_move);
                  points = 1;
                  last_point = *point++;
                  last_move = last_point;
                  break;

               case pcWideLineTo:
                  point++;
               case pcLineTo:
                  if (points>0)
                     (*this.*func)(last_point,*point);
                  last_point = *point++;
                  points++;
                  break;

               case pcCurveTo:
                  if (inMode==itHitTest)
                     HitTestCurve(last_point, point[0], point[1]);
                  else
                     BuildCurve(last_point, point[0], point[1]);
                  last_point = point[1];
                  point += 2;
                  points++;
                  break;
                  case pcTile: points+=3; break;
                  case pcTileTrans: points+=4; break;
                  case pcTileCol: points+=5; break;
                  case pcTileTransCol: points+=6; break;
            }
         }
         if (last_point!=last_move)
            (*this.*func)(last_point,last_move);
      }
      return 256;
   }
};

Renderer *CreateSolidRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath)
{
   return new SolidRender(inJob,inPath);
}


} // end namespace nme


