#ifndef LIME_MATH_VECTOR2_H
#define LIME_MATH_VECTOR2_H


#include <system/CFFI.h>


namespace lime {


	struct Vector2 {

		hl_type* t;
		double x;
		double y;

		Vector2 (double x, double y);
		Vector2 (value vec);

		void SetTo (double x, double y);
		value Value ();
		value Value (value vec);

	};


}


#endif