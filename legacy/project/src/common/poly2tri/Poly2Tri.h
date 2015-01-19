/* 
 * Poly2Tri Copyright (c) 2009-2010, Poly2Tri Contributors
 * http://code.google.com/p/poly2tri/
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * * Neither the name of Poly2Tri nor the names of its contributors may be
 *   used to endorse or promote products derived from this software without specific
 *   prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef POLY2TRI_H
#define POLY2TRI_H

#include <nme/Point.h>
#include <vector>


namespace p2t
{

struct Edge;

// ============ Point =============================================================

struct Point : public nme::UserPoint
{
   Edge  *edges[2];
   int   edgeCount;

   /// Default constructor does nothing (for performance).
   Point() : edgeCount(0) { }

    /// Construct using coordinates.
   Point(double x, double y) : nme::UserPoint(x,y), edgeCount(0) { }

   inline void  addEdge(Edge *inEdge)
   {
      if (edgeCount>=2)
         *(int *)0=0;
      edges[edgeCount++] = inEdge;
   }

   /// Set this point to all zeros.
   void set_zero()
   {
     x = 0.0;
     y = 0.0;
   }

   /// Set this point to some specified coordinates.
   void set(double x_, double y_)
   {
     x = x_;
     y = y_;
   }

   /// Negate this point.
   Point operator -() const
   {
     Point v;
     v.set(-x, -y);
     return v;
   }

#if 0
   /// Add a point to this point.
   void operator +=(const Point& v)
   {
     x += v.x;
     y += v.y;
   }

  /// Subtract a point from this point.
  void operator -=(const Point& v)
  {
    x -= v.x;
    y -= v.y;
  }

  /// Multiply this point by a scalar.
  void operator *=(double a)
  {
    x *= a;
    y *= a;
  }
#endif

  /// Get the length of this point (the norm).
  double Length() const
  {
    return sqrt(x * x + y * y);
  }

  /// Convert this point into a unit point. Returns the Length.
  double Normalize()
  {
    double len = Length();
    x /= len;
    y /= len;
    return len;
  }

};

// ============ Edge =============================================================

// Represents a simple polygon's edge
struct Edge {

  Point* p, *q;

  /// Constructor
  Edge(Point& p1, Point& p2) : p(&p1), q(&p2)
  {
    if (p1.y > p2.y) {
      q = &p1;
      p = &p2;
    } else if (p1.y == p2.y) {
      if (p1.x > p2.x) {
        q = &p1;
        p = &p2;
      } else if (p1.x == p2.x) {
        // Repeat points
        //assert(false);
      }
    }

    q->addEdge(this);
    //q->edge_list.push_back(this);
  }
};

// ============ Triangle =============================================================

// Triangle-based data structures are know to have better performance than quad-edge structures
// See: J. Shewchuk, "Triangle: Engineering a 2D Quality Mesh Generator and Delaunay Triangulator"
//      "Triangulations in CGAL"
class Triangle
{
private:
   /// Triangle points
   Point* points_[3];
   /// Neighbor list
   Triangle* neighbors_[3];

   /// Has this triangle been marked as an interior triangle?
   bool interior_;


public:

   /// Flags to determine if an edge is a Constrained edge
   bool constrained_edge[3];
   /// Flags to determine if an edge is a Delauney edge
   bool delaunay_edge[3];

   
   
   inline Triangle(Point& a, Point& b, Point& c)
   {
     points_[0] = &a; points_[1] = &b; points_[2] = &c;
     neighbors_[0] = 0; neighbors_[1] = 0; neighbors_[2] = 0;
     constrained_edge[0] = constrained_edge[1] = constrained_edge[2] = false;
     delaunay_edge[0] = delaunay_edge[1] = delaunay_edge[2] = false;
     interior_ = false;
   }
   
   // Update neighbor pointers
   inline void MarkNeighbor(Point* p1, Point* p2, Triangle* t)
   {
     if ((p1 == points_[2] && p2 == points_[1]) || (p1 == points_[1] && p2 == points_[2]))
       neighbors_[0] = t;
     else if ((p1 == points_[0] && p2 == points_[2]) || (p1 == points_[2] && p2 == points_[0]))
       neighbors_[1] = t;
     else if ((p1 == points_[0] && p2 == points_[1]) || (p1 == points_[1] && p2 == points_[0]))
       neighbors_[2] = t;
     else
     {
        // assert(0);
     }
   }
   
   // Exhaustive search to update neighbor pointers
   inline void MarkNeighbor(Triangle& t)
   {
     if (t.Contains(points_[1], points_[2])) {
       neighbors_[0] = &t;
       t.MarkNeighbor(points_[1], points_[2], this);
     } else if (t.Contains(points_[0], points_[2])) {
       neighbors_[1] = &t;
       t.MarkNeighbor(points_[0], points_[2], this);
     } else if (t.Contains(points_[0], points_[1])) {
       neighbors_[2] = &t;
       t.MarkNeighbor(points_[0], points_[1], this);
     }
   }
   
   /**
    * Clears all references to all other triangles and points
    */
   inline void Clear()
   {
       Triangle *t;
       for( int i=0; i<3; i++ )
       {
           t = neighbors_[i];
           if( t != 0 )
           {
               t->ClearNeighbor( this );
           }
       }
       ClearNeighbors();
       points_[0]=points_[1]=points_[2] = 0;
   }
   
   inline void ClearNeighbor(Triangle *triangle )
   {
       if( neighbors_[0] == triangle )
       {
           neighbors_[0] = 0;
       }
       else if( neighbors_[1] == triangle )
       {
           neighbors_[1] = 0;            
       }
       else
       {
           neighbors_[2] = 0;
       }
   }
       
   inline void ClearNeighbors()
   {
     neighbors_[0] = 0;
     neighbors_[1] = 0;
     neighbors_[2] = 0;
   }
   
   inline void ClearDelunayEdges()
   {
     delaunay_edge[0] = delaunay_edge[1] = delaunay_edge[2] = false;
   }
   
   inline Point* OppositePoint(Triangle& t, Point& p)
   {
     Point *cw = t.PointCW(p);
     double x = cw->x;
     double y = cw->y;
     x = p.x;
     y = p.y;
     return PointCW(*cw);
   }
   
   // Legalized triangle by rotating clockwise around point(0)
   inline void Legalize(Point& point)
   {
     points_[1] = points_[0];
     points_[0] = points_[2];
     points_[2] = &point;
   }
   
   // Legalize triagnle by rotating clockwise around oPoint
   inline void Legalize(Point& opoint, Point& npoint)
   {
     if (&opoint == points_[0]) {
       points_[1] = points_[0];
       points_[0] = points_[2];
       points_[2] = &npoint;
     } else if (&opoint == points_[1]) {
       points_[2] = points_[1];
       points_[1] = points_[0];
       points_[0] = &npoint;
     } else if (&opoint == points_[2]) {
       points_[0] = points_[2];
       points_[2] = points_[1];
       points_[1] = &npoint;
     } else {
        // assert(0);
     }
   }
   
   inline int Index(const Point* p)
   {
     if (p == points_[0]) {
       return 0;
     } else if (p == points_[1]) {
       return 1;
     } else if (p == points_[2]) {
       return 2;
     }
      // assert(0);
     return 0;
   }
   
   inline int EdgeIndex(const Point* p1, const Point* p2)
   {
     if (points_[0] == p1) {
       if (points_[1] == p2) {
         return 2;
       } else if (points_[2] == p2) {
         return 1;
       }
     } else if (points_[1] == p1) {
       if (points_[2] == p2) {
         return 0;
       } else if (points_[0] == p2) {
         return 2;
       }
     } else if (points_[2] == p1) {
       if (points_[0] == p2) {
         return 1;
       } else if (points_[1] == p2) {
         return 0;
       }
     }
     return -1;
   }
   
   inline void MarkConstrainedEdge(const int index)
   {
     constrained_edge[index] = true;
   }
   
   inline void MarkConstrainedEdge(Edge& edge)
   {
     MarkConstrainedEdge(edge.p, edge.q);
   }
   
   // Mark edge as constrained
   inline void MarkConstrainedEdge(Point* p, Point* q)
   {
     if ((q == points_[0] && p == points_[1]) || (q == points_[1] && p == points_[0])) {
       constrained_edge[2] = true;
     } else if ((q == points_[0] && p == points_[2]) || (q == points_[2] && p == points_[0])) {
       constrained_edge[1] = true;
     } else if ((q == points_[1] && p == points_[2]) || (q == points_[2] && p == points_[1])) {
       constrained_edge[0] = true;
     }
   }
   
   // The point counter-clockwise to given point
   inline Point* PointCW(Point& point)
   {
     if (&point == points_[0]) {
       return points_[2];
     } else if (&point == points_[1]) {
       return points_[0];
     } else if (&point == points_[2]) {
       return points_[1];
     }
     //assert(0);
     return 0;
   }
   
   // The point counter-clockwise to given point
   inline Point* PointCCW(Point& point)
   {
     if (&point == points_[0]) {
       return points_[1];
     } else if (&point == points_[1]) {
       return points_[2];
     } else if (&point == points_[2]) {
       return points_[0];
     }
     //assert(0);
     return 0;
   }
   
   // The neighbor clockwise to given point
   Triangle* NeighborCW(Point& point)
   {
     if (&point == points_[0]) {
       return neighbors_[1];
     } else if (&point == points_[1]) {
       return neighbors_[2];
     }
     return neighbors_[0];
   }
   
   // The neighbor counter-clockwise to given point
   inline Triangle* NeighborCCW(Point& point)
   {
     if (&point == points_[0]) {
       return neighbors_[2];
     } else if (&point == points_[1]) {
       return neighbors_[0];
     }
     return neighbors_[1];
   }
   
   inline bool GetConstrainedEdgeCCW(Point& p)
   {
     if (&p == points_[0]) {
       return constrained_edge[2];
     } else if (&p == points_[1]) {
       return constrained_edge[0];
     }
     return constrained_edge[1];
   }
   
   inline bool GetConstrainedEdgeCW(Point& p)
   {
     if (&p == points_[0]) {
       return constrained_edge[1];
     } else if (&p == points_[1]) {
       return constrained_edge[2];
     }
     return constrained_edge[0];
   }
   
   inline void SetConstrainedEdgeCCW(Point& p, bool ce)
   {
     if (&p == points_[0]) {
       constrained_edge[2] = ce;
     } else if (&p == points_[1]) {
       constrained_edge[0] = ce;
     } else {
       constrained_edge[1] = ce;
     }
   }
   
   inline void SetConstrainedEdgeCW(Point& p, bool ce)
   {
     if (&p == points_[0]) {
       constrained_edge[1] = ce;
     } else if (&p == points_[1]) {
       constrained_edge[2] = ce;
     } else {
       constrained_edge[0] = ce;
     }
   }
   
   inline bool GetDelunayEdgeCCW(Point& p)
   {
     if (&p == points_[0]) {
       return delaunay_edge[2];
     } else if (&p == points_[1]) {
       return delaunay_edge[0];
     }
     return delaunay_edge[1];
   }
   
   inline bool GetDelunayEdgeCW(Point& p)
   {
     if (&p == points_[0]) {
       return delaunay_edge[1];
     } else if (&p == points_[1]) {
       return delaunay_edge[2];
     }
     return delaunay_edge[0];
   }
   
   inline void SetDelunayEdgeCCW(Point& p, bool e)
   {
     if (&p == points_[0]) {
       delaunay_edge[2] = e;
     } else if (&p == points_[1]) {
       delaunay_edge[0] = e;
     } else {
       delaunay_edge[1] = e;
     }
   }
   
   inline void SetDelunayEdgeCW(Point& p, bool e)
   {
     if (&p == points_[0]) {
       delaunay_edge[1] = e;
     } else if (&p == points_[1]) {
       delaunay_edge[2] = e;
     } else {
       delaunay_edge[0] = e;
     }
   }
   
   // The neighbor across to given point
   inline Triangle& NeighborAcross(Point& opoint)
   {
     if (&opoint == points_[0]) {
       return *neighbors_[0];
     } else if (&opoint == points_[1]) {
       return *neighbors_[1];
     }
     return *neighbors_[2];
   }
 

   inline Point* GetPoint(const int& index)
   {
     return points_[index];
   }

   inline Triangle* GetNeighbor(const int& index)
   {
     return neighbors_[index];
   }

   inline bool Contains(Point* p)
   {
     return p == points_[0] || p == points_[1] || p == points_[2];
   }

   inline bool Contains(const Edge& e)
   {
     return Contains(e.p) && Contains(e.q);
   }

   inline bool Contains(Point* p, Point* q)
   {
     return Contains(p) && Contains(q);
   }

   inline bool IsInterior()
   {
     return interior_;
   }

   inline void IsInterior(bool b)
   {
     interior_ = b;
   }

  
   inline void DebugPrint()
   {
     /*
     using namespace std;
     cout << points_[0]->x << "," << points_[0]->y << " ";
     cout << points_[1]->x << "," << points_[1]->y << " ";
     cout << points_[2]->x << "," << points_[2]->y << endl;
     */
   }
   
};



/// Add two points_ component-wise.
inline Point operator +(const Point& a, const Point& b)
{
  return Point(a.x + b.x, a.y + b.y);
}

/// Subtract two points_ component-wise.
inline Point operator -(const Point& a, const Point& b)
{
  return Point(a.x - b.x, a.y - b.y);
}

/// Multiply point by scalar
inline Point operator *(double s, const Point& a)
{
  return Point(s * a.x, s * a.y);
}

inline bool operator ==(const Point& a, const Point& b)
{
  return a.x == b.x && a.y == b.y;
}

inline bool operator !=(const Point& a, const Point& b)
{
  return !(a.x == b.x) && !(a.y == b.y);
}

/// Peform the dot product on two vectors.
inline double Dot(const Point& a, const Point& b)
{
  return a.x * b.x + a.y * b.y;
}

/// Perform the cross product on two vectors. In 2D this produces a scalar.
inline double Cross(const Point& a, const Point& b)
{
  return a.x * b.y - a.y * b.x;
}

/// Perform the cross product on a point and a scalar. In 2D this produces
/// a point.
inline Point Cross(const Point& a, double s)
{
  return Point(s * a.y, -s * a.x);
}

/// Perform the cross product on a scalar and a point. In 2D this produces
/// a point.
inline Point Cross(const double s, const Point& a)
{
  return Point(-s * a.y, s * a.x);
}





class Poly2Tri
{
public:

  /**
   * Constructor - add polyline with non repeating points
   * 
   * @param polyline
   */
  static Poly2Tri *create();
  
   /**
   * Destructor - clean up memory
   */
  virtual ~Poly2Tri() { };
  
  /**
   * Add polygon or hole
   */
  virtual void AddSubPoly(Point *inP0, int inSize) = 0;
 
  // Create and get result 
  virtual const std::vector<Triangle*> &Triangulate() = 0;
  
};


}


#endif

