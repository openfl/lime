#ifndef LIME_MATH_RECTANGLE_H
#define LIME_MATH_RECTANGLE_H


#include <hx/CFFI.h>


namespace lime {
	
	
	class Rectangle {
		
		
		public:
			
			Rectangle ();
			Rectangle (double x, double y, double width, double height);
			Rectangle (value rect);
			
			void Contract (double x, double y, double width, double height);
			value Value ();
			
			double height;
			double width;
			double x;
			double y;
		
		
	};
	
	
}


#endif