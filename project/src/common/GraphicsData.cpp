#include <Graphics.h>

namespace lime
{

// --- GraphicsPath ------------------------------------------

void GraphicsPath::initPosition(const UserPoint &inPoint)
{
   commands.push_back(pcBeginAt);
   data.push_back(inPoint.x);
   data.push_back(inPoint.y);
}

void GraphicsPath::clear()
{
   commands.resize(0);
   data.resize(0);
}



void GraphicsPath::curveTo(float controlX, float controlY, float anchorX, float anchorY)
{
	commands.push_back(pcCurveTo);
	data.push_back(controlX);
	data.push_back(controlY);
	data.push_back(anchorX);
	data.push_back(anchorY);
}

void GraphicsPath::arcTo(float controlX, float controlY, float anchorX, float anchorY)
{
	commands.push_back(pcArcTo);
	data.push_back(controlX);
	data.push_back(controlY);
	data.push_back(anchorX);
	data.push_back(anchorY);
}

void GraphicsPath::elementBlendMode(int inMode)
{
   switch(inMode)
   {
      case bmAdd:
         commands.push_back(pcBlendModeAdd);
         break;
      case bmMultiply:
         commands.push_back(pcBlendModeMultiply);
         break;
      case bmScreen:
         commands.push_back(pcBlendModeScreen);
         break;
   }
}



void GraphicsPath::lineTo(float x, float y)
{
	commands.push_back(pcLineTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::moveTo(float x, float y)
{
	commands.push_back(pcMoveTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::wideLineTo(float x, float y)
{
	commands.push_back(pcLineTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::wideMoveTo(float x, float y)
{
	commands.push_back(pcMoveTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::tile(float x, float y, const Rect &inTileRect,float *inTrans,float *inRGBA)
{
	data.push_back(x);
	data.push_back(y);
	data.push_back(inTileRect.x);
	data.push_back(inTileRect.y);
	data.push_back(inTileRect.w);
	data.push_back(inTileRect.h);
   int command = pcTile;
   if (inTrans)
   {
      command |= pcTile_Trans_Bit;
	   data.push_back(inTrans[0]);
	   data.push_back(inTrans[1]);
	   data.push_back(inTrans[2]);
	   data.push_back(inTrans[3]);
   }
   if (inRGBA)
   {
      command |= pcTile_Col_Bit;
	   data.push_back(inRGBA[0]);
	   data.push_back(inRGBA[1]);
	   data.push_back(inRGBA[2]);
	   data.push_back(inRGBA[3]);
   }
	commands.push_back((PathCommand)command);
}

void GraphicsPath::closeLine(int inCommand0, int inData0)
{
   float *point = &data[inData0];
   float *move = 0;
   for(int c=inCommand0; c<commands.size(); c++)
   {
      switch(commands[c])
      {
         case pcWideMoveTo:
            point+=2;
         case pcBeginAt:
         case pcMoveTo:
            move = point;
            break;

         case pcWideLineTo:
         case pcCurveTo:
            point+=2;
         case pcLineTo:
            if (move && move[0]==point[0] && move[1]==point[1])
            {
               // Closed loop detected - no need to close.
               move = 0;
            }
            break;
      }
      point+=2;
   }
   if (move)
      lineTo(move[0], move[1]);
}


void GraphicsPath::drawPoints(QuickVec<float> inXYs, QuickVec<int> inRGBAs)
{
   int n = inXYs.size()/2;
   int d0 = data.size();

   if (inRGBAs.size()==n)
   {
       commands.push_back(pcPointsXYRGBA);
       data.resize(d0 + n*3);
       memcpy(&data[d0], &inXYs[0], n*2*sizeof(float));
       d0+=n*2;
       memcpy(&data[d0], &inRGBAs[0], n*sizeof(int));
   }
   else
   {
       commands.push_back(pcPointsXY);
       data.resize(d0 + n*2);
       memcpy(&data[d0], &inXYs[0], n*sizeof(float));
   }
}

// -- GraphicsTrianglePath ---------------------------------------------------------

GraphicsTrianglePath::GraphicsTrianglePath( const QuickVec<float> &inXYs,
            const QuickVec<int> &inIndices,
            const QuickVec<float> &inUVT, int inCull,
            const QuickVec<int> &inColours,
            int inBlendMode, const QuickVec<float,4> &inViewport )
{
	UserPoint *v = (UserPoint *) &inXYs[0];
    uint32 *c = (uint32 *) &inColours[0];
    if(inColours.empty()) c=NULL;
	
	int v_count = inXYs.size()/2;
	int uv_parts = inUVT.size()==v_count*2 ? 2 : inUVT.size()==v_count*3 ? 3 : 0;
	const float *uvt = &inUVT[0];

	mBlendMode = inBlendMode;
	mViewport = inViewport;
	
	if (inIndices.empty())
	{
		int t_count = v_count/3;
		if (inCull==tcNone)
		{
			mVertices.resize(6*t_count);
			memcpy(&mVertices[0],v,3*sizeof(UserPoint));
			if (uv_parts)
			{
				mUVT.resize(uv_parts*3*t_count);
				memcpy(&mUVT[0],&inUVT[0],uv_parts*sizeof(UserPoint));
			}
		}
		else
		{
			for(int i=0;i<t_count;i++)
			{
				UserPoint p0 = *v++;
				UserPoint p1 = *v++;
				UserPoint p2 = *v++;
				if ( (p1-p0).Cross(p2-p0)*inCull > 0)
				{
					mTriangleCount++;
					mVertices.push_back(p0);
					mVertices.push_back(p1);
					mVertices.push_back(p2);
					for(int i=0;i<uv_parts*3;i++)
						mUVT.push_back( *uvt++ );
				}
				else
					uvt += uv_parts;
			}
		}
	}
	else
	{
		const int *idx = &inIndices[0];
		int t_count = inIndices.size()/3;
		for(int i=0;i<t_count;i++)
		{
			int i0 = *idx++;
			int i1 = *idx++;
			int i2 = *idx++;
			if (i0>=0 && i1>=0 && i2>=0 && i0<v_count && i1<v_count && i2<v_count)
			{
				UserPoint p0 = v[i0];
				UserPoint p1 = v[i1];
				UserPoint p2 = v[i2];
				if ( (p1-p0).Cross(p2-p0)*inCull >= 0)
				{
					mVertices.push_back(p0);
					mVertices.push_back(p1);
					mVertices.push_back(p2);
		                    if(c)
		                    {
		                       uint32 co0 = c[i0];
		                       uint32 co1 = c[i1];
		                       uint32 co2 = c[i2];
							   co0 = ((co0 >> 24) & 0xFF) << 24 | (co0 & 0xFF) << 16 | ((co0 >> 8) & 0xFF) << 8 | ((co0 >> 16) & 0xFF);
							   co1 = ((co1 >> 24) & 0xFF) << 24 | (co1 & 0xFF) << 16 | ((co1 >> 8) & 0xFF) << 8 | ((co1 >> 16) & 0xFF);
							   co2 = ((co2 >> 24) & 0xFF) << 24 | (co2 & 0xFF) << 16 | ((co2 >> 8) & 0xFF) << 8 | ((co2 >> 16) & 0xFF);
		                       mColours.push_back(co0);
		                       mColours.push_back(co1);
		                       mColours.push_back(co2);
		                    }
					if (uv_parts)
					{
						const float *f = uvt + uv_parts*i0;
						for(int i=0;i<uv_parts;i++) mUVT.push_back( *f++ );
						f = uvt + uv_parts*i1;
						for(int i=0;i<uv_parts;i++) mUVT.push_back( *f++ );
						f = uvt + uv_parts*i2;
						for(int i=0;i<uv_parts;i++) mUVT.push_back( *f++ );
					}
				}
			}
		}
	}

	mTriangleCount = mVertices.size()/3;
   mType = uv_parts==2 ? vtVertexUV : uv_parts==3? vtVertexUVT : vtVertex;
}



} // end namespace lime

