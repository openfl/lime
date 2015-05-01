#ifndef LIME_MATH_MATRIX_3_H
#define LIME_MATH_MATRIX_3_H


#include <hx/CFFI.h>


namespace lime {
	
	
	class Matrix3 {
		
		
		public:
			
			Matrix3 ();
			Matrix3 (double a, double b, double c, double d, double tx, double ty);
			Matrix3 (value matrix3);
			
			value Value ();
			
			double a;
			double b;
			double c;
			double d;
			double tx;
			double ty;
		
		
	};
	
	
}


#endif