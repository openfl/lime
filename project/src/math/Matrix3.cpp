#include <math/Matrix3.h>


namespace lime {
	
	
	static int id_a;
	static int id_b;
	static int id_c;
	static int id_d;
	static int id_tx;
	static int id_ty;
	static bool init = false;
	
	
	Matrix3::Matrix3 () {
		
		a = 1;
		b = 0;
		c = 0;
		d = 1;
		tx = 0;
		ty = 0;
		
	}
	
	
	Matrix3::Matrix3 (double a, double b, double c, double d, double tx, double ty) {
		
		this->a = a;
		this->b = b;
		this->c = c;
		this->d = d;
		this->tx = tx;
		this->ty = ty;
		
	}
	
	
	Matrix3::Matrix3 (value mat3) {
		
		if (!init) {
			
			id_a = val_id ("a");
			id_b = val_id ("b");
			id_c = val_id ("c");
			id_d = val_id ("d");
			id_tx = val_id ("tx");
			id_ty = val_id ("ty");
			init = true;
			
		}
		
		a = val_number (val_field (mat3, id_a));
		b = val_number (val_field (mat3, id_b));
		c = val_number (val_field (mat3, id_c));
		d = val_number (val_field (mat3, id_d));
		tx = val_number (val_field (mat3, id_tx));
		ty = val_number (val_field (mat3, id_ty));
		
	}
	
	
	Matrix3::Matrix3 (HL_Matrix3* matrix3) {
		
		a = matrix3->a;
		b = matrix3->b;
		c = matrix3->c;
		d = matrix3->d;
		tx = matrix3->tx;
		ty = matrix3->ty;
		
	}
	
	
	vdynamic* Matrix3::Dynamic () {
		
		HL_Matrix3* result = (HL_Matrix3*)malloc (sizeof (HL_Matrix3));
		result->a = a;
		result->b = b;
		result->c = c;
		result->d = d;
		result->tx = tx;
		result->ty = ty;
		return (vdynamic*) result;
		
	}
	
	
	value Matrix3::Value () {
		
		value result = alloc_empty_object ();
		alloc_field (result, id_a, alloc_float (a));
		alloc_field (result, id_b, alloc_float (b));
		alloc_field (result, id_c, alloc_float (c));
		alloc_field (result, id_d, alloc_float (d));
		alloc_field (result, id_tx, alloc_float (tx));
		alloc_field (result, id_ty, alloc_float (ty));
		return result;
		
	}
	
	
}