#include <Graphics.h>
#include <stdio.h>
#include <Hardware.h>
#include <set>

//#define USE_POLY2TRI

#ifdef USE_POLY2TRI
#include "poly2tri/Poly2Tri.h"
#endif

namespace nme
{

const double INSIDE_TOL = 1e-12;





struct TriSearch
{
   UserPoint next;
   UserPoint prev;
   UserPoint min;
   UserPoint max;
   UserPoint p;
   UserPoint v1;
   UserPoint v2;
   double    denom;
   bool      isFlat;
   bool      isConcave;

   TriSearch(const UserPoint &inP0, const UserPoint &inPrev, const UserPoint &inNext)
   {
      p = inP0;
      next = inNext;
      prev = inPrev;
      v1 = next - p;
      v2 = prev - p;

      denom = v1.Cross(v2);

      isConcave = denom<0;

      if (!isConcave)
      {
         isFlat = denom<INSIDE_TOL;  // flat triangle 

         if (!isFlat)
         {
            denom -= INSIDE_TOL;

            min = p;
            if (next.x<min.x) min.x=next.x;
            if (next.y<min.y) min.y=next.y;
            if (prev.x<min.x) min.x=prev.x;
            if (prev.y<min.y) min.y=prev.y;
            max = p;
            if (next.x>max.x) max.x=next.x;
            if (next.y>max.y) max.y=next.y;
            if (prev.x>max.x) max.x=prev.x;
            if (prev.y>max.y) max.y=prev.y;
         }
      }
   }

   inline bool pointInTri(UserPoint concave)
   {
      UserPoint v( concave - p );
      double a = v.Cross(v2);
      if (a>INSIDE_TOL && a<denom)
      {
         double b = v1.Cross(v);
         // Ear contains concave point?
         return (b>INSIDE_TOL && (a+b)<denom && (a+b)>INSIDE_TOL);
      }
      return false;
   }
};




struct EdgePoint
{
   UserPoint p;
   EdgePoint *prev;
   EdgePoint *next;
   bool      isConcave;

   void init(const UserPoint &inPoint,EdgePoint *inPrev, EdgePoint *inNext)
   {
      p = inPoint;
      next = inNext;
      prev = inPrev;
      isConcave = false;
   }

   void unlink()
   {
      prev->next = next;
      next->prev = prev;
   }

   bool calcConcave()
   {
      return (prev->p - p).Cross(next->p - p) > 0.0;
   }
};


struct ConcaveSet
{
   typedef std::multiset<UserPoint> PointSet;
   PointSet points;

   void add(EdgePoint *edge)
   {
      edge->isConcave = true;
      points.insert(edge->p);
   }

   void remove(EdgePoint *edge)
   {
      edge->isConcave = false;
      points.erase(edge->p);
   }

   bool isEar(EdgePoint *edge)
   {
      if (points.empty())
         return true;

      if (edge->isConcave)
         return false;

      TriSearch test(edge->p, edge->prev->p, edge->next->p);
      if (test.isConcave)
         return false;
      if (test.isFlat)
         return true;

      // TODO - maybe some quadtree style structure
      PointSet::const_iterator p = points.lower_bound(test.min);
      PointSet::const_iterator last = points.upper_bound(test.max);
      for( ; p!=last; ++p )
      {
         UserPoint concave = *p;
         // Y-bounds should be good since they are sorted by Y
         if (concave.x<test.min.x || concave.x>test.max.x )
            continue;

         if (test.pointInTri(concave))
            return false;
      }

      return true;
   }
};


void ConvertOutlineToTriangles(EdgePoint *head, int size, Vertices &outTriangles)
{
   outTriangles.reserve( outTriangles.size() + (size-2)*3);

   ConcaveSet concaveSet;

   for(EdgePoint *p = head; ; )
   {
      if (p->calcConcave())
         concaveSet.add(p);
      p = p->next; if (p==head) break;
   }

   EdgePoint *pi= head;
   EdgePoint *p_end = pi->prev;

   while( pi!=p_end && size>2)
   {
      if ( concaveSet.isEar(pi) )
      {
         // Have ear triangle - yay - clip it
         outTriangles.push_back(pi->prev->p);
         outTriangles.push_back(pi->p);
         outTriangles.push_back(pi->next->p);

         //printf("  ear : %f,%f %f,%f %f,%f\n", pi->prev->p.x, pi->prev->p.y,
                //pi->p.x, pi->p.y,
                //pi->next->p.x, pi->next->p.y );

         pi->unlink();

         // Has it stopped being concave?
         if (pi->next->isConcave && !pi->next->calcConcave())
            concaveSet.remove(pi->next); 
         // Has it stopped being concave?
         if (pi->prev->isConcave && !pi->prev->calcConcave())
            concaveSet.remove(pi->prev);

         // Take a step back and try again...
         pi = pi->prev;
         p_end = pi->prev;

         size --;
      }
      else
         pi = pi->next;
   }
}



// --- External interface ----------


enum PIPResult { PIP_NO, PIP_YES, PIP_MAYBE };

PIPResult PointInPolygon(UserPoint p0, UserPoint *ioPtr,int inN)
{
   int crossing = 0;
   for(int i=0;i<inN;i++)
   {
      UserPoint p1 = ioPtr[i];
      UserPoint p2 = ioPtr[ (i+1)%inN ];
      // Should probably do something a bit better here...
      if (p1.y==p0.y || p2.y==p0.y)
         return PIP_MAYBE;

      if (p1.y<p0.y && p2.y>p0.y)
      {
         double cross = (p1-p0).Cross(p2-p0);
         if (cross==0)
            return PIP_MAYBE;
         if (cross>0)
            crossing++;
      }
      else if(p1.y>p0.y && p2.y<p0.y)
      {
         double cross = (p1-p0).Cross(p2-p0);
         if (cross==0)
            return PIP_MAYBE;
         if (cross<0)
            crossing++;
      }
   }
   return (crossing & 1) ? PIP_YES : PIP_NO;
}

void AddSubPoly(EdgePoint *outEdge, UserPoint *inP, int inN,bool inReverse)
{
   for(int i=0;i<inN;i++)
   {
      int prev = (i+inN-1) % inN;
      int next = (i+1) % inN;
      if (inReverse)
         std::swap(prev,next);
      outEdge[i].init(inP[i], &outEdge[prev], &outEdge[next]);
   }
}

/*

       ^ next          v next
       |               |
       |               |
       |               |
 outer +               + inner
       |               |
       |               |
       |               |
       ^ prev          v  next



       ^ next          v next
       |               |
       |               |
       |               |
 buf0  +----<----------+ inner
 outer +---->----------+ buf1  
       |               |
       |               |
       |               |
       ^ prev          v  next

*/




int LinkSubPolys(EdgePoint *inOuter,  EdgePoint *inInner, EdgePoint *inBuffer)
{
   int count = 0;

   // Holes are sorted left-to-right, and connected to the left, to avoid
   //  connecting holes with lines that might go through other holes
   //
   //  Find left-most inner(hole) point
   EdgePoint *bestIn = inInner;
   double leftX = bestIn->p.x;
   for(EdgePoint *in = inInner;  ; )
   {
      count++;
      if (in->p.x < leftX)
      {
         leftX = in->p.x;
         bestIn = in;
      }
      in = in->next; if (in==inInner) break;
   }
   double leftY = bestIn->p.y;

   // Now, shoot ray left to find outer intersection

   double closestX = -1e39;
   double bestAlpha = 0.0;
   EdgePoint *bestOut = 0;
   EdgePoint *e0 = inOuter;
   for(EdgePoint *e0 = inOuter;  ; )
   {
      if ( fabs(e0->p.y-leftY) < 0.0001 )
      {
         if (e0->p.x<=leftX && e0->p.x>closestX)
         {
            bestOut = e0;
            closestX = e0->p.x;
            bestAlpha = 0.0;
         }
      }
      else if ( ( (e0->p.y<leftY) && (e0->next->p.y>leftY) ) ||
                  (e0->p.y>leftY) && (e0->next->p.y<leftY) )
      {
         if (e0->p.x < leftX || e0->next->p.x<leftX)
         {
            double alpha = fabs( e0->p.y - leftY ) / fabs( e0->p.y - e0->next->p.y);
            double x = e0->p.x + (e0->next->p.x-e0->p.x) * alpha;
            if (x<=leftX && x>closestX)
            {
               closestX = x;
               bestOut = e0;
               bestAlpha = alpha;
            }
         }
      }

      e0 = e0->next;
      if (e0==inOuter)
         break;
   }

   if (!bestOut)
   {
      //printf("Could not link hole\n");
      return 0;
   }

   if (bestAlpha>0.9999)
   {
      bestOut = bestOut->next;
   }
   else if (bestAlpha>0.0001)
   {
      // Insert node into outline
      EdgePoint *b = inBuffer + 2;
      b->init( UserPoint(closestX,bestOut->p.y + ( bestOut->next->p.y- bestOut->p.y) * bestAlpha),
                bestOut, bestOut->next );

      bestOut->next->prev = b;
      bestOut->next = b;

      bestOut = b;
      count ++;
   }


   inBuffer[0] = *bestOut;
   inBuffer[1] = *bestIn;

   bestOut->next = inBuffer+1;
   inBuffer[1].prev = bestOut;
   inBuffer[1].next->prev = inBuffer + 1;

   bestIn->next = inBuffer;
   bestIn->prev->next = bestIn;
   inBuffer[0].prev = bestIn;
   inBuffer[0].next->prev = inBuffer;

   return count+2;
}

struct SubInfo
{
   void set(int inP0, int inSize, UserPoint *inVertices)
   {
      p0 = inP0;
      size = inSize;
      vertices = inVertices + p0;

      x0 = x1 = vertices[0].x;
      y0 = y1 = vertices[0].y;
      for(int i=1;i<size;i++)
      {
         UserPoint &p = vertices[i];
         if (p.x < x0) x0 = p.x;
         if (p.x > x1) x1 = p.x;
         if (p.y < y0) y0 = p.y;
         if (p.y > y1) y1 = p.y;
      }
   }

   bool operator <(const SubInfo &inOther) const
   {
      // Extents not overlap - call it even
      if (x1 <= inOther.x0 || x0>=inOther.x1 || y1 <= inOther.y0 || y0>=inOther.y1 )
         return false;

      bool allOtherInExtent = true;
      for(int i=0;i<inOther.size;i++)
         if (!contains(inOther.vertices[i]))
         {
            allOtherInExtent = false;
            break;
         }

      bool allInOtherExtent = true;
      for(int i=0;i<size;i++)
         if (!inOther.contains(vertices[i]))
         {
            allInOtherExtent = false;
            break;
         }
      if (allOtherInExtent != allInOtherExtent)
      {
         // This is less than (parent-to) other
         return allOtherInExtent;
      }

      // Extents overlap - even.  Possibly some situation here?
      //if (allInOtherExtent) printf("HUH?");

      return false;
   }

   bool contains(const UserPoint inP) const
   {
      return inP.x>=x0 && inP.x<=x1 && inP.y>=y0 && inP.y<=y1;
   }

   UserPoint *vertices;
   EdgePoint *first;
   EdgePoint  link[3];
   int        group;
   bool       is_internal;
   int        p0;
   int        size;
   float      x0,x1;
   float      y0,y1;
};

bool sortLeft(SubInfo *a, SubInfo *b)
{
   return a->x0 < b->x0;
}

void ConvertOutlineToTriangles(Vertices &ioOutline,const QuickVec<int> &inSubPolys)
{
   // Order polygons ...
   int subs = inSubPolys.size();
   if (subs<1)
      return;

   QuickVec<SubInfo> subInfo(subs);
   int bigSubs = 0;
   int p0 = 0;
   for(int i=0;i<subs;i++)
   {
      int size = inSubPolys[i]-p0;
      if (size>2 && ioOutline[p0] == ioOutline[p0+size-1])
         size--;

      if (size>2)
         subInfo[bigSubs++].set(p0,size, &ioOutline[0]);

      p0 = inSubPolys[i];
   }
   subInfo.resize(subs=bigSubs);
   std::sort(subInfo.begin(), subInfo.end());



   QuickVec<EdgePoint> edges(ioOutline.size());
   int index = 0;
   int groupId = 0;

   for(int sub=0;sub<subs;sub++)
   {
      SubInfo &info = subInfo[sub];

         UserPoint *p = &ioOutline[info.p0];
         double area = 0.0;
         for(int i=2;i<info.size;i++)
         {
            UserPoint v_prev = p[i-1] - p[0];
            UserPoint v_next = p[i] - p[0];
            area += v_prev.Cross(v_next);
         }
         bool reverse = area < 0;
         int  parent = -1;

         for(int prev=sub-1; prev>=0 && parent==-1; prev--)
         {
            if (subInfo[prev].contains(p[0]))
            {
               int prev_p0 = subInfo[prev].p0;
               int prev_size = subInfo[prev].size;
               int inside = PIP_MAYBE;
               for(int test_point = 0; test_point<info.size && inside==PIP_MAYBE; test_point++)
               {
                  inside =  PointInPolygon( p[test_point], &ioOutline[prev_p0], prev_size);
                  if (inside==PIP_YES)
                     parent = prev;
               }
            }
         }

         if (parent==-1 || subInfo[parent].is_internal )
         {
            info.group = groupId++;
            info.is_internal = false;
         }
         else
         {
            info.group = subInfo[parent].group;
            info.is_internal = true;
         }

         info.first = &edges[index];
         AddSubPoly(info.first,p,info.size,reverse!=info.is_internal);
         index += info.size;
   }

   Vertices triangles;

   for(int group=0;group<groupId;group++)
   {
      int first = -1;
      int size = 0;
      int totalSize = 0;
      QuickVec<SubInfo *> holes;
      for(int sub=0;sub<subInfo.size();sub++)
      {
         SubInfo &info = subInfo[sub];
         if (info.group==group)
         {
            if (first<0)
            {
               first = sub;
               totalSize = size = info.size;
            }
            else
            {
               totalSize += info.size;
               holes.push_back(&info);
            }
         }
      }
      if (first>=0)
      {
         int holeCount = holes.size();

         #ifdef USE_POLY2TRI
            p2t::Poly2Tri *poly2Tri = p2t::Poly2Tri::create();

            std::vector< p2t::Point> pointBuffer(totalSize);
            UserPoint *p = subInfo[first].vertices;
            int p0 = 0;
            for(int i=0;i<size;i++)
               pointBuffer[i].set( p[i].x, p[i].y );
            poly2Tri->AddSubPoly(&pointBuffer[0],size);
            p0 += size;

            for(int h=0;h<holeCount;h++)
            {
               SubInfo &poly = *holes[h];
               int size = poly.size;
               UserPoint *p = poly.vertices;
               for(int i=0;i<size;i++)
                  pointBuffer[p0+i].set( p[i].x, p[i].y );

               poly2Tri->AddSubPoly(&pointBuffer[p0],size);
               p0 += size;
            }

            const std::vector< p2t::Triangle* > &tris = poly2Tri->Triangulate();

            for(int i=0;i<tris.size();i++)
            {
               p2t::Triangle *tri = tris[i];
               triangles.push_back( *tri->GetPoint(0) );
               triangles.push_back( *tri->GetPoint(1) );
               triangles.push_back( *tri->GetPoint(2) );
            }

            delete poly2Tri;

         #else
            if (holeCount)
            {
               std::sort(holes.begin(), holes.end(), sortLeft);

               for(int h=0;h<holeCount;h++)
               {
                  SubInfo &info = *holes[h];
                  size += LinkSubPolys(subInfo[first].first,info.first, info.link);
               }
            }
            ConvertOutlineToTriangles(subInfo[first].first, size,triangles);
         #endif
      }
   }

   ioOutline.swap(triangles);
}

} // end namespace nme
