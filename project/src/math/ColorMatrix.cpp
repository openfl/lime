#include <math/ColorMatrix.h>
#include <utils/Bytes.h>


namespace lime {
	
	
	static int id_buffer;
	static bool init = false;
	
	
	ColorMatrix::ColorMatrix () {
		
		for (int i = 0; i < 20; i++) {
			
			if (i % 6 == 0) {
				
				data[i] = 1;
				
			} else {
				
				data[i] = 0;
				
			}
			
		}
		
	}
	
	
	ColorMatrix::ColorMatrix (value colorMatrix) {
		
		if (!init) {
			
			id_buffer = val_id ("buffer");
			init = true;
			
		}
		
		value buffer_value = val_field (colorMatrix, id_buffer);
		Bytes bytes = Bytes (buffer_value);
		float* src = (float*)bytes.Data ();
		
		for (int i = 0; i < 20; i++) {
			
			data[i] = src[i];
			
		}
		
	}
	
	
	ColorMatrix::~ColorMatrix () {
		
		
		
	}
	
	
	float ColorMatrix::GetAlphaMultiplier () {
		
		return data[18];
		
	}
	
	
	float ColorMatrix::GetAlphaOffset () {
		
		return data[19] * 255;
		
	}
	
	
	float ColorMatrix::GetBlueMultiplier () {
		
		return data[12];
		
	}
	
	
	float ColorMatrix::GetBlueOffset () {
		
		return data[14] * 255;
		
	}
	
	
	int ColorMatrix::GetColor () {
		
		return ((int (GetRedOffset ()) << 16) | (int (GetGreenOffset ()) << 8) | int (GetBlueOffset ()));
		
	}
	
	
	float ColorMatrix::GetGreenMultiplier () {
		
		return data[6];
		
	}
	
	
	float ColorMatrix::GetGreenOffset () {
		
		return data[9] * 255;
		
	}
	
	
	float ColorMatrix::GetRedMultiplier () {
		
		return data[0];
		
	}
	
	
	float ColorMatrix::GetRedOffset () {
		
		return data[4] * 255;
		
	}
	
	
}