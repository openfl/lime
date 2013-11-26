#include <Graphics.h>
#include "PolygonRender.h"

namespace nme
{

Renderer *CreateLineRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);
Renderer *CreateTriangleLineRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath, Renderer *inSolid);
Renderer *CreateSolidRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);
Renderer *CreatePointRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);
Renderer *CreateTileRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);
Renderer *CreateTriangleRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);


Renderer *Renderer::CreateSoftware(const GraphicsJob &inJob, const GraphicsPath &inPath)
{
   if (inJob.mTriangles)
   {
      Renderer *solid = 0;
      if (inJob.mFill)
       solid = CreateTriangleRenderer(inJob,inPath);
      return inJob.mStroke ? CreateTriangleLineRenderer(inJob,inPath,solid) : solid;
   }
   else if (inJob.mIsTileJob)
     return CreateTileRenderer(inJob,inPath);
   else if (inJob.mIsPointJob)
     return CreatePointRenderer(inJob,inPath);
   else if (inJob.mStroke)
     return CreateLineRenderer(inJob,inPath);
   else
     return CreateSolidRenderer(inJob,inPath);
}


} // end namespace nme
