#include <cairo.h>
#include <hx/CFFI.h>


namespace lime {
	
	
	value lime_cairo_version () {
		
		return alloc_int (cairo_version ());
		
	}
	
	
	value lime_cairo_version_string () {
		
		return alloc_string (cairo_version_string ());
		
	}
	
	
	DEFINE_PRIM (lime_cairo_version, 0);
	DEFINE_PRIM (lime_cairo_version_string, 0);
	
	
}


extern "C" int lime_cairo_register_prims () {
	
	return 0;
	
}