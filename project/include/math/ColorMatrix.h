#ifndef LIME_MATH_COLOR_MATRIX_H
#define LIME_MATH_COLOR_MATRIX_H


#include <hx/CFFI.h>
#include <system/System.h>


namespace lime {
	
	
	class ColorMatrix {
		
		
		public:
			
			ColorMatrix ();
			ColorMatrix (value colorMatrix);
			~ColorMatrix ();
			
			float GetAlphaMultiplier ();
			float GetAlphaOffset ();
			float GetBlueMultiplier ();
			float GetBlueOffset ();
			int GetColor ();
			float GetGreenMultiplier ();
			float GetGreenOffset ();
			float GetRedMultiplier ();
			float GetRedOffset ();
			
			float data[20];
		
		
	};
	
	
}


#endif