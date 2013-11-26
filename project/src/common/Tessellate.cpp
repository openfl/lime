#include <Graphics.h>
#include <stdio.h>

namespace nme
{

struct EdgePoint
{
   UserPoint p;
   EdgePoint *prev;
   EdgePoint *next;
   EdgePoint *prevConcave;
   EdgePoint *nextConcave;

   void init(const UserPoint &inPoint,EdgePoint *inPrev, EdgePoint *inNext)
   {
      p = inPoint;
      next = inNext;
      prev = inPrev;
      prevConcave = 0;
      nextConcave = 0;
   }
   inline bool isConcave() const { return nextConcave; }

   void linkConcave(EdgePoint &ioHead)
   {
      nextConcave = ioHead.nextConcave;
      ioHead.nextConcave = this;
      prevConcave = nextConcave->prevConcave;
      nextConcave->prevConcave = this;
   }
   void unlinkConcave()
   {
      prevConcave->nextConcave = nextConcave;
      nextConcave->prevConcave = prevConcave;
      nextConcave =0;
      prevConcave =0;
   }
   void unlink()
   {
      prev->next = next;
      next->prev = prev;
   }

   bool empty()
   {
      return nextConcave == this;
   }

   void calcConcave(EdgePoint &ioHead)
   {
      if (Cross()>0.0)
      {
         if (!nextConcave)
            linkConcave(ioHead);
      }
      else
      {
         if (nextConcave)
            unlinkConcave();
      }
   }

   double Cross()
   {
      return (prev->p - p).Cross(next->p - p);
   }

   //bool convex() { return(Cross()<0.0); }
};


bool IsEar(EdgePoint *concaveHead,EdgePoint *pi)
{
   if (concaveHead->empty())
      return true;

   if (pi->isConcave())
      return false;

   UserPoint v1( pi->next->p - pi->p ); 
   UserPoint v2( pi->prev->p - pi->p );
   double denom = v1.Cross(v2);

   if (denom==0.0)  // flat triangle 
   {
      //printf(" -> flat\n");
      return true;
   }

   for(EdgePoint *concave = concaveHead->nextConcave;
       concave!=concaveHead; concave = concave->nextConcave)
   {
      UserPoint v( concave->p - pi->p );
      double a = v.Cross(v2);
      double b = v1.Cross(v);
      // Ear contains concave point?
      if (a>=0.0 && b>=0.0 && (a+b)<denom && (a+b)>=0)
         return false;
   }

   return true;
}

bool Intersect(UserPoint dir,UserPoint p0,UserPoint p1)
{
   // Test for simple overlap first ?
   if (dir==p0 || dir==p1)
      return true;

   UserPoint v = p1-p0;
   double denom = dir.Cross(v);
   if (denom==0) // parallel - co-linear or not
   {
      if (p0.Cross(dir)!=0.0) // p0 is not on dir ...
         return false;

      // co-linear - find closest point on +ve direction on line ...
      double b[2];
      if (dir.x==0)
      {
         b[0] = (double)p0.y/(double)dir.y;
         b[1] = (double)p1.y/(double)dir.y;
      }
      else
      {
         b[0] = (double)p0.x/(double)dir.x;
         b[1] = (double)p1.x/(double)dir.x;
      }

      int point;
      if (b[0]>=0 && b[1]>=0)
         point = b[1]<b[0];
      else if (b[0]>=0)
         point = 0;
      else if (b[1]>=0)
         point = 1;
      else
         point = b[1]>b[0];
      
      return(b[point]>=0 && b[point]<=1.0);
   }

   double beta = p0.Cross(v)/denom;
   if (beta<0.0 || beta>1.0)
      return(false);

   // Test alpha ...
   double alpha = p0.Cross(dir)/denom;
   return(alpha>=0 && alpha<=1.0);
}

bool FindDiag(EdgePoint *concaveHead,EdgePoint *&p1,EdgePoint *&p2)
{
   for(EdgePoint *p = concaveHead->nextConcave; p!=concaveHead; p = p->nextConcave)
   {
      UserPoint corner = p->p;
      UserPoint v1( p->prev->p - corner ); 
      UserPoint v2( p->next->p - corner );
      for(EdgePoint *other=p->next; ;  )
      {
         UserPoint v( other->p-corner );
         double a = v.Cross(v2);
         double b = v1.Cross(v);
         if (a>=0.0 && b>=0.0)
         {
            // Found candidate, check for intersections ...
            EdgePoint *l=p->prev;
            for( ;l!=other->next;l=l->prev)
               if (Intersect(v,l->p-corner,l->prev->p-corner))
                  break;
            if (l==other->next)
            {
               EdgePoint *r=p->next;
               for(;l!=other->prev;r=r->next)
                  if (Intersect(v,r->p-corner,r->next->p-corner))
                     break;
               if (r==other->prev)
               {
                  // found !
                  p1 = p;
                  p2 = other;
                  return true;
               }
            }
         }
         other = other->next;
         if (other == p->prev)
            break;
      }
   }
   return(false);
}



void ConvertOutlineToTriangles(EdgePoint *head, int size, Vertices &outTriangles)
{
   outTriangles.reserve( outTriangles.size() + (size-2)*3);

   EdgePoint concaveHead;
   concaveHead.nextConcave = concaveHead.prevConcave = &concaveHead;

   for(EdgePoint *p = head; ; )
   {
      p->calcConcave(concaveHead);
      p = p->next; if (p==head) break;
   }

   EdgePoint *pi= head;
   EdgePoint *p_end = pi->prev;

   while(size>2)
   {
      while( pi!=p_end && size>2)
      {
         if ( IsEar(&concaveHead,pi) )
         {
            // Have ear triangle - yay - clip it
            outTriangles.push_back(pi->prev->p);
            outTriangles.push_back(pi->p);
            outTriangles.push_back(pi->next->p);

            //printf("  ear : %f,%f %f,%f %f,%f\n", pi->prev->p.x, pi->prev->p.y,
                   //pi->p.x, pi->p.y,
                   //pi->next->p.x, pi->next->p.y );

            if (pi->isConcave())
               pi->unlinkConcave();
            pi->unlink();
            // Have we become concave or convex ?
            pi->next->calcConcave(concaveHead);
            // Has the previous one become convex ?
            pi->prev->calcConcave(concaveHead);

            // Take a step back and try again...
            pi = pi->prev;
            p_end = pi->prev;

            size --;
         }
         else
            pi = pi->next;
      }

      if (size==3)
      {
         /*
         printf("Triangle : %f,%f  %f,%f  %f,%f\n",
                pi->prev->p.x, pi->prev->p.y,
                pi->p.x, pi->p.y,
                pi->next->p.x, pi->next->p.y );
         */
         break;
      }
      else if (size>2 )
      {
         break;

         EdgePoint *b1=0,*b2=0;
         //printf("Diag %d ?\n",size);
         if ( FindDiag(&concaveHead,b1,b2))
         {
            // Call recursively...
            /*
            Vertices loop1;
            loop1.reserve(size);
            EdgePoint *p;
            for(p=b1;p!=b2;p=p->next)
               loop1.push_back(p->p);
            loop1.push_back(p->p);

            ConvertOutlineToTriangles(loop1,outTriangles);


            Vertices loop2;
            loop2.reserve(size);
            for(p=b2;p!=b1;p=p->next)
               loop2.push_back(p->p);
            loop2.push_back(p->p);
            ConvertOutlineToTriangles(loop2,outTriangles);
            */
         }
         else
         {
            #if 1
            //printf("No diag?\n");
            break;
            #else
            // Hmmm look for "least concave" point ...
            pi = p0->next->next;
            double best_val = -1e99;
            EdgePoint *least_concave = 0;
            double smallest_val = 1e99;
            EdgePoint *smallest = 0;
            while(pi!=p0)
            {
               if (concave_points.find(pi->prev)!=concave_points.end())
               {
                  double cross = pi->Cross();
                  if (cross>best_val)
                  {
                     best_val = cross;
                     least_concave = pi;
                  }
               }
               else if (!least_concave)
               {
                  double cross = pi->Cross();
                  if (cross<smallest_val)
                  {
                     smallest_val = cross;
                     smallest = pi;
                  }
               }
               pi = pi->next;
            }

            if (least_concave)
               pi = least_concave;
            else
               pi = smallest;

            force_ear = true;
            #endif
         }
      }
   }
}

// --- External interface ----------

void ReverseSubPoly(UserPoint *ioPtr,int inN)
{
   int half = inN>>1;
   for(int i=0;i<half;i++)
      std::swap(ioPtr[i],ioPtr[inN-i]);
}

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


void LinkSubPolys(EdgePoint *inOuter,  EdgePoint *inInner, EdgePoint *inBuffer)
{
   double best = 1e39;
   EdgePoint *bestIn = inInner;
   EdgePoint *bestOut = inOuter;

   // This is not technically correct - it needs to find a connection that
   //  does not intersect with any of the line-segments.
   for(EdgePoint *in = inInner;  ; )
   {
      for(EdgePoint *out = inOuter; ; )
      {
         double dist = in->p.Dist2(out->p);
         if (dist<best)
         {
            best = dist;
            bestIn = in;
            bestOut = out;
         }
         out = out->next; if (out==inOuter) break;
      }
      in = in->next; if (in==inInner) break;
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
}

struct SubInfo
{
   void calcExtent()
   {
     x0 = x1 = first->p.x;
     y0 = y1 = first->p.y;
     for(EdgePoint *p = first->next; p!=first; p = p->next )
     {
        if (p->p.x < x0) x0 = p->p.x;
        if (p->p.x > x1) x1 = p->p.x;
        if (p->p.y < y0) y0 = p->p.y;
        if (p->p.y > y1) y1 = p->p.y;
     }
   }
   bool contains(UserPoint inP)
   {
      return inP.x>=x0 && inP.x<=x1 && inP.y>=y0 && inP.y<=y1;
   }

   EdgePoint *first;
   EdgePoint  link[2];
   int        group;
   bool       is_internal;
   int        p0;
   int        size;
   float      x0,x1;
   float      y0,y1;
};

void ConvertOutlineToTriangles(Vertices &ioOutline,const QuickVec<int> &inSubPolys)
{
   // Order polygons ...
   int subs = inSubPolys.size();
   if (subs<1)
      return;

   QuickVec<SubInfo> subInfo;
   QuickVec<EdgePoint> edges(ioOutline.size());
   int index = 0;
   int groupId = 0;

   for(int sub=0;sub<subs;sub++)
   {
      SubInfo info;

      info.p0 = sub>0?inSubPolys[sub-1]:0;
      info.size = inSubPolys[sub] - info.p0;
      if (ioOutline[info.p0] == ioOutline[info.p0+info.size-1])
         info.size--;

      if (info.size>2)
      {
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

         for(int prev=subInfo.size()-1; prev>=0 && parent==-1; prev--)
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
         if (sub<subs-1)
            info.calcExtent();
         index += info.size;

         subInfo.push_back(info);
      }
   }

   Vertices triangles;
   for(int group=0;group<groupId;group++)
   {
      int first = -1;
      int size = 0;
      for(int sub=0;sub<subInfo.size();sub++)
      {
         SubInfo &info = subInfo[sub];
         if (info.group==group)
         {
            if (first<0)
            {
               first = sub;
               size = info.size;
            }
            else
            {
               LinkSubPolys(subInfo[first].first,info.first, info.link);
               size += info.size + 2;
            }
         }
      }
      ConvertOutlineToTriangles(subInfo[first].first, size,triangles);
   }

   ioOutline.swap(triangles);
}

} // end namespace nme
