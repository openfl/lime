#ifndef LIME_MATH_RECTANGLE_H
#define LIME_MATH_RECTANGLE_H


#include <system/CFFI.h>


namespace lime {


	struct Rectangle {

		hl_type* t;
		double height;
		double width;
		double x;
		double y;

		Rectangle ();
		Rectangle (double x, double y, double width, double height);
		Rectangle (value rect);

		void Contract (double x, double y, double width, double height);
		void SetTo (double x, double y, double width, double height);
		value Value ();
		value Value (value rect);

	};


}


#endif