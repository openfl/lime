#ifndef LIME_MATH_MATRIX_3_H
#define LIME_MATH_MATRIX_3_H


#include <system/CFFI.h>


namespace lime {
	
	
	struct HL_Matrix3 {
		
		hl_type* t;
		double a;
		double b;
		double c;
		double d;
		double tx;
		double ty;
		
	};
	
	
	class Matrix3 {
		
		
		public:
			
			Matrix3 ();
			Matrix3 (double a, double b, double c, double d, double tx, double ty);
			Matrix3 (value matrix3);
			Matrix3 (HL_Matrix3* matrix3);
			
			vdynamic* Dynamic ();
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