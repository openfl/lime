#ifndef LIME_CAIRO_CONTEXT_H
#define LIME_CAIRO_CONTEXT_H


#include <graphics/cairo/CairoPattern.h>
#include <graphics/cairo/CairoSurface.h>


typedef struct _cairo cairo_t;


namespace lime {


	struct CairoContext {

		CairoContext (cairo_t *ptr = NULL) {
			m_ptr = ptr;
		}

		static CairoContext create (CairoSurface target);

		void destroy ();

		void clip ();
		void closePath ();
		void fill ();
		void fillPreserve ();
		void lineTo (double x, double y);
		void moveTo (double x, double y);
		void newPath ();
		void mask (CairoPattern pattern);
		void paint ();
		void paintWithAlpha (double alpha);
		void pushGroup ();
		void pushGroupWithContent (int content);
		CairoPattern popGroup ();
		void popGroupToSource ();
		void rectangle (double x, double y, double w, double h);
		void resetClip ();
		void restore ();
		void save ();
		void setLineCap (int cap);
		void setLineJoin (int join);
		void setLineWidth (double width);
		void setMatrix (double xx, double yx, double xy, double yy, double x0, double y0);
		void setMiterLimit (double miterLimit);
		void setOperator (int op);
		void setSource (CairoPattern pattern);
		void setSourceRGBA (double r, double g, double b, double a);
		void setSourceSurface (CairoSurface surface, double x, double y);
		void stroke ();
		void strokePreserve ();
		void transform (double xx, double yx, double xy, double yy, double x0, double y0);

	private:

		cairo_t *m_ptr;

	};


}


#endif
