#include <cairo.h>
#include <graphics/cairo/CairoContext.h>
#include <graphics/cairo/CairoPattern.h>
#include <graphics/cairo/CairoSurface.h>


namespace lime {


	CairoContext CairoContext::create (CairoSurface target) {

		cairo_t *c = cairo_create (target.ptr ());
		return CairoContext (c);

	}


	void CairoContext::destroy () {

		cairo_destroy (m_ptr);

	}


	void CairoContext::clip () {

		cairo_clip (m_ptr);

	}


	void CairoContext::closePath () {

		cairo_close_path (m_ptr);

	}


	void CairoContext::fill () {

		cairo_fill (m_ptr);

	}


	void CairoContext::fillPreserve () {

		cairo_fill_preserve (m_ptr);

	}


	void CairoContext::lineTo (double x, double y) {

		cairo_line_to (m_ptr, x, y);

	}


	void CairoContext::moveTo (double x, double y) {

		cairo_move_to (m_ptr, x, y);

	}


	void CairoContext::mask (CairoPattern pattern) {

		cairo_mask (m_ptr, pattern.ptr ());

	}


	void CairoContext::newPath () {

		cairo_new_path (m_ptr);

	}


	void CairoContext::paint () {

		cairo_paint (m_ptr);

	}


	void CairoContext::paintWithAlpha (double alpha) {

		cairo_paint_with_alpha (m_ptr, alpha);

	}


	void CairoContext::pushGroup () {

		cairo_push_group (m_ptr);

	}


	void CairoContext::pushGroupWithContent (int content) {

		cairo_push_group_with_content (m_ptr, (cairo_content_t)content);

	}


	CairoPattern CairoContext::popGroup () {

		return cairo_pop_group (m_ptr);

	}


	void CairoContext::popGroupToSource () {

		cairo_pop_group_to_source (m_ptr);

	}


	void CairoContext::rectangle (double x, double y, double w, double h) {

		cairo_rectangle (m_ptr, x, y, w, h);

	}


	void CairoContext::resetClip () {

		cairo_reset_clip (m_ptr);

	}


	void CairoContext::restore () {

		cairo_restore (m_ptr);

	}


	void CairoContext::save () {

		cairo_save (m_ptr);

	}


	void CairoContext::setLineCap (int cap) {

		cairo_set_line_cap (m_ptr, (cairo_line_cap_t)cap);

	}


	void CairoContext::setLineJoin (int join) {

		cairo_set_line_join (m_ptr, (cairo_line_join_t)join);

	}


	void CairoContext::setLineWidth (double width) {

		cairo_set_line_width (m_ptr, width);

	}


	void CairoContext::setMatrix (double xx, double yx, double xy, double yy, double x0, double y0) {

		cairo_matrix_t m;
		m.xx = xx;
		m.yx = yx;
		m.xy = xy;
		m.yy = yy;
		m.x0 = x0;
		m.y0 = y0;
		cairo_set_matrix (m_ptr, &m);

	}


	void CairoContext::setMiterLimit (double miterLimit) {

		cairo_set_miter_limit (m_ptr, miterLimit);

	}


	void CairoContext::setOperator (int op) {

		cairo_set_operator (m_ptr, (cairo_operator_t)op);

	}


	void CairoContext::setSource (CairoPattern pattern) {

		cairo_set_source (m_ptr, pattern.ptr ());

	}


	void CairoContext::setSourceRGBA (double r, double g, double b, double a) {

		cairo_set_source_rgba (m_ptr, r, g, b, a);

	}


	void CairoContext::setSourceSurface (CairoSurface surface, double x, double y) {

		cairo_set_source_surface (m_ptr, surface.ptr (), x, y);

	}


	void CairoContext::stroke () {

		cairo_stroke (m_ptr);

	}


	void CairoContext::strokePreserve () {

		cairo_stroke_preserve (m_ptr);

	}


	void CairoContext::transform (double xx, double yx, double xy, double yy, double x0, double y0) {

		cairo_matrix_t m;
		m.xx = xx;
		m.yx = yx;
		m.xy = xy;
		m.yy = yy;
		m.x0 = x0;
		m.y0 = y0;
		cairo_transform (m_ptr, &m);

	}



	CairoPattern CairoPattern::createForSurface (CairoSurface surface) {

		cairo_pattern_t *p = cairo_pattern_create_for_surface (surface.ptr ());
		return CairoPattern (p);

	}


	void CairoPattern::destroy () {

		cairo_pattern_destroy (m_ptr);

	}


	void CairoPattern::setExtend (int extend) {

		cairo_pattern_set_extend (m_ptr, (cairo_extend_t)extend);

	}


	void CairoPattern::setFilter (int filter) {

		cairo_pattern_set_filter (m_ptr, (cairo_filter_t)filter);

	}


	void CairoPattern::setMatrix (double xx, double yx, double xy, double yy, double x0, double y0) {

		cairo_matrix_t m;
		m.xx = xx;
		m.yx = yx;
		m.xy = xy;
		m.yy = yy;
		m.x0 = x0;
		m.y0 = y0;
		cairo_pattern_set_matrix (m_ptr, &m);

	}



	CairoSurface CairoSurface::createForData (
		uint8_t *data,
		int format,
		int width,
		int height,
		int stride
	) {

		cairo_surface_t *s = cairo_image_surface_create_for_data (
			data, (cairo_format_t)format, width, height, stride
		);
		return CairoSurface (s);

	}


	void CairoSurface::destroy () {

		cairo_surface_destroy (m_ptr);

	}


}

