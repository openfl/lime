#include <math/Rectangle.h>


namespace lime {


	static int id_height;
	static int id_width;
	static int id_x;
	static int id_y;
	static bool init = false;


	Rectangle::Rectangle () {

		t = 0;

		SetTo (0, 0, 0, 0);

	}


	Rectangle::Rectangle (double x, double y, double width, double height) {

		t = 0;

		SetTo (x, y, width, height);

	}


	Rectangle::Rectangle (value rect) {

		if (!init) {

			id_height = val_id ("height");
			id_width = val_id ("width");
			id_x = val_id ("x");
			id_y = val_id ("y");
			init = true;

		}

		width = val_number (val_field (rect, id_width));
		height = val_number (val_field (rect, id_height));
		x = val_number (val_field (rect, id_x));
		y = val_number (val_field (rect, id_y));

	}


	void Rectangle::Contract (double x, double y, double width, double height) {

		if (this->width == 0 && this->height == 0) {

			return;

		}

		//double cacheRight = this->x + this->width;
		//double cacheBottom = this->y + this->height;

		if (this->x < x) this->x = x;
		if (this->y < y) this->y = y;
		if (this->x + this->width > x + width) this->width = x + width - this->x;
		if (this->y + this->height > y + height) this->height = y + height - this->y;

	}


	void Rectangle::SetTo (double x, double y, double width, double height) {

		this->height = height;
		this->width = width;
		this->x = x;
		this->y = y;

	}


	value Rectangle::Value () {

		return Value (alloc_empty_object ());

	}


	value Rectangle::Value (value rect) {

		if (!init) {

			id_height = val_id ("height");
			id_width = val_id ("width");
			id_x = val_id ("x");
			id_y = val_id ("y");
			init = true;

		}

		alloc_field (rect, id_height, alloc_float (height));
		alloc_field (rect, id_width, alloc_float (width));
		alloc_field (rect, id_x, alloc_float (x));
		alloc_field (rect, id_y, alloc_float (y));
		return rect;

	}


}