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
		Bytes bytes;
		bytes.Set (buffer_value);
		float* src = (float*)bytes.b;

		for (int i = 0; i < 20; i++) {

			data[i] = src[i];

		}

	}


	ColorMatrix::ColorMatrix (ArrayBufferView* colorMatrix) {

		float* src = (float*)colorMatrix->buffer->b;

		for (int i = 0; i < 20; i++) {

			data[i] = src[i];

		}

	}


	ColorMatrix::~ColorMatrix () {



	}


	float inline ColorMatrix::GetAlphaMultiplier () {

		return data[18];

	}


	float inline ColorMatrix::GetAlphaOffset () {

		return data[19] * 255;

	}


	void ColorMatrix::GetAlphaTable (unsigned char* table) {

		GetDataTable (table, GetAlphaMultiplier (), GetAlphaOffset ());
		table[0] = 0;

	}


	float inline ColorMatrix::GetBlueMultiplier () {

		return data[12];

	}


	float inline ColorMatrix::GetBlueOffset () {

		return data[14] * 255;

	}


	void ColorMatrix::GetBlueTable (unsigned char* table) {

		GetDataTable (table, GetBlueMultiplier (), GetBlueOffset ());

	}


	int32_t inline ColorMatrix::GetColor () {

		return ((int (GetRedOffset ()) << 16) | (int (GetGreenOffset ()) << 8) | int (GetBlueOffset ()));

	}


	void inline ColorMatrix::GetDataTable (unsigned char* table, float multiplier, float offset) {

		int32_t value;

		for (int i = 0; i < 256; i++) {

			value = (int)(i * multiplier + offset);
			if (value > 0xFF) value = 0xFF;
			if (value < 0) value = 0;
			table[i] = value;

		}

	}


	float inline ColorMatrix::GetGreenMultiplier () {

		return data[6];

	}


	float inline ColorMatrix::GetGreenOffset () {

		return data[9] * 255;

	}


	void ColorMatrix::GetGreenTable (unsigned char* table) {

		GetDataTable (table, GetGreenMultiplier (), GetGreenOffset ());

	}


	float inline ColorMatrix::GetRedMultiplier () {

		return data[0];

	}


	float inline ColorMatrix::GetRedOffset () {

		return data[4] * 255;

	}


	void ColorMatrix::GetRedTable (unsigned char* table) {

		GetDataTable (table, GetRedMultiplier (), GetRedOffset ());

	}


}