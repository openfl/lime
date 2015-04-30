#ifndef LIME_CAIRO_SURFACE_H
#define LIME_CAIRO_SURFACE_H


typedef struct _cairo_surface cairo_surface_t;


namespace lime {


	struct CairoSurface {

		CairoSurface (cairo_surface_t *ptr = NULL) {
			m_ptr = ptr;
		}

		static CairoSurface createForData (
			uint8_t *data,
			int format,
			int width,
			int height,
			int stride
		);

		void destroy ();

		inline cairo_surface_t *ptr () { return m_ptr; }

	private:

		cairo_surface_t *m_ptr;

	};


}


#endif
