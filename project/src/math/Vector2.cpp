#include <math/Vector2.h>


namespace lime {


	static int id_x;
	static int id_y;
	static bool init = false;


	Vector2::Vector2 (double x, double y) {

		t = 0;

		SetTo (x, y);

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


	void Vector2::SetTo (double x, double y) {

		this->x = x;
		this->y = y;

	}


	value Vector2::Value () {

		return Value (alloc_empty_object ());

	}


	value Vector2::Value (value vec) {

		if (!init) {

			id_x = val_id ("x");
			id_y = val_id ("y");
			init = true;

		}

		alloc_field (vec, id_x, alloc_float (x));
		alloc_field (vec, id_y, alloc_float (y));
		return vec;

	}


}