#ifndef LIME_MATH_COLOR_MATRIX_H
#define LIME_MATH_COLOR_MATRIX_H


#include <system/CFFI.h>
#include <system/System.h>
#include <utils/ArrayBufferView.h>
#include <stdint.h>


namespace lime {


	class ColorMatrix {


		public:

			ColorMatrix ();
			ColorMatrix (value colorMatrix);
			ColorMatrix (ArrayBufferView* colorMatrix);
			~ColorMatrix ();

			float GetAlphaMultiplier ();
			float GetAlphaOffset ();
			void GetAlphaTable (unsigned char* table);
			float GetBlueMultiplier ();
			float GetBlueOffset ();
			void GetBlueTable (unsigned char* table);
			int32_t GetColor ();
			float GetGreenMultiplier ();
			float GetGreenOffset ();
			void GetGreenTable (unsigned char* table);
			float GetRedMultiplier ();
			float GetRedOffset ();
			void GetRedTable (unsigned char* table);

			float data[20];

		private:

			void GetDataTable (unsigned char* table, float multiplier, float offset);


	};


}


#endif