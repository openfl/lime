#ifndef LIME_MATH_MATRIX_3_H
#define LIME_MATH_MATRIX_3_H


#include <system/CFFI.h>


namespace lime {


	struct Matrix3 {

		hl_type* t;
		double a;
		double b;
		double c;
		double d;
		double tx;
		double ty;

		Matrix3 (double a, double b, double c, double d, double tx, double ty);
		Matrix3 (value matrix3);

		void SetTo (double a, double b, double c, double d, double tx, double ty);
		value Value ();
		value Value (value matrix3);

	};


}


#endif