#include <math/Matrix3.h>


namespace lime {


	static int id_a;
	static int id_b;
	static int id_c;
	static int id_d;
	static int id_tx;
	static int id_ty;
	static bool init = false;


	Matrix3::Matrix3 (double a, double b, double c, double d, double tx, double ty) {

		t = 0;

		SetTo (a, b, c, d, tx, ty);

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


	void Matrix3::SetTo (double a, double b, double c, double d, double tx, double ty) {

		this->a = a;
		this->b = b;
		this->c = c;
		this->d = d;
		this->tx = tx;
		this->ty = ty;

	}


	value Matrix3::Value () {

		return Value (alloc_empty_object ());

	}


	value Matrix3::Value (value matrix3) {

		alloc_field (matrix3, id_a, alloc_float (a));
		alloc_field (matrix3, id_b, alloc_float (b));
		alloc_field (matrix3, id_c, alloc_float (c));
		alloc_field (matrix3, id_d, alloc_float (d));
		alloc_field (matrix3, id_tx, alloc_float (tx));
		alloc_field (matrix3, id_ty, alloc_float (ty));
		return matrix3;

	}


}