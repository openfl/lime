#ifndef LIME_MATH_RECTANGLE_H
#define LIME_MATH_RECTANGLE_H


#include <hx/CFFI.h>


namespace lime {
	
	
	class Rectangle {
		
		
		public:
			
			Rectangle ();
			Rectangle (value rect);
			
			double height;
			double width;
			double x;
			double y;
		
		
	};
	
	
}


#endif