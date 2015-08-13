#ifndef LIME_CAIRO_PATTERN_H
#define LIME_CAIRO_PATTERN_H


#include <graphics/cairo/CairoSurface.h>


typedef struct _cairo_pattern cairo_pattern_t;


namespace lime {


	struct CairoPattern {

		CairoPattern (cairo_pattern_t *ptr = NULL) {
			m_ptr = ptr;
		}

		static CairoPattern createForSurface (CairoSurface target);

		void destroy ();

		inline cairo_pattern_t *ptr () { return m_ptr; }

		void setExtend (int extend);
		void setFilter (int filter);
		void setMatrix (double xx, double yx, double xy, double yy, double x0, double y0);

	private:

		cairo_pattern_t *m_ptr;

	};


}


#endif
