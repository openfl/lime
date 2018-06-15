#include <math/Vector2.h>


namespace lime {
	
	
	static int id_x;
	static int id_y;
	static bool init = false;
	
	
	Vector2::Vector2 () {
		
		x = 0;
		y = 0;
		
	}
	
	
	Vector2::Vector2 (double x, double y) {
		
		this->x = x;
		this->y = y;
		
	}
	
	
	Vector2::Vector2 (value vec) {
		
		if (!init) {
			
			id_x = val_id ("x");
			id_y = val_id ("y");
			init = true;
			
		}
		
		if (!val_is_null (vec)) {
			
			x = val_number (val_field (vec, id_x));
			y = val_number (val_field (vec, id_y));
			
		} else {
			
			x = 0;
			y = 0;
			
		}
		
	}
	
	
	Vector2::Vector2 (HL_Vector2* vec) {
		
		x = vec->x;
		y = vec->y;
		
	}
	
	
	vdynamic* Vector2::Dynamic () {
		
		HL_Vector2* result = (HL_Vector2*)malloc (sizeof (HL_Vector2));
		result->x = x;
		result->y = y;
		return (vdynamic*) result;
		
	}
	
	
	value Vector2::Value () {
		
		if (!init) {
			
			id_x = val_id ("x");
			id_y = val_id ("y");
			init = true;
			
		}
		
		value result = alloc_empty_object ();
		alloc_field (result, id_x, alloc_float (x));
		alloc_field (result, id_y, alloc_float (y));
		return result;
		
	}
	
	
}