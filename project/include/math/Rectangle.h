#ifndef LIME_MATH_RECTANGLE_H
#define LIME_MATH_RECTANGLE_H


#include <hl.h>
#include <hx/CFFI.h>


namespace lime {
	
	
	struct HL_Rectangle {
		
		hl_type* t;
		double height;
		double width;
		double x;
		double y;
		
	};
	
	
	class Rectangle {
		
		
		public:
			
			Rectangle ();
			Rectangle (double x, double y, double width, double height);
			Rectangle (value rect);
			Rectangle (HL_Rectangle* rect);
			
			void Contract (double x, double y, double width, double height);
			value Value ();
			
			double height;
			double width;
			double x;
			double y;
		
		
	};
	
	
}


#endif