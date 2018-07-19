#ifndef LIME_MATH_COLOR_RGBA_H
#define LIME_MATH_COLOR_RGBA_H


#include <graphics/PixelFormat.h>
#include <system/Endian.h>
#include <stdint.h>
#include <math.h>


namespace lime {


	int __alpha16[0xFF + 1];
	int __clamp[0xFF + 0xFF + 1];
	static int a16;
	static double unmult;

	int initValues () {

		for (int i = 0; i < 256; i++) {

			__alpha16[i] = (int) ceil ((float)(i + 1) * ((1 << 16) / 0xFF));

		}

		for (int i = 0; i < 0xFF; i++) {

			__clamp[i] = i;

		}

		for (int i = 0xFF; i < (0xFF + 0xFF + 1); i++) {

			__clamp[i] = 0xFF;

		}

		return 0;

	}

	static int initValues_ = initValues ();


	struct RGBA {


		public:

			inline RGBA () {

				r = 0;
				g = 0;
				b = 0;
				a = 0;

			}


			inline RGBA (int32_t rgba) {

				r = (rgba >> 24) & 0xFF;
				g = (rgba >> 16) & 0xFF;
				b = (rgba >> 8) & 0xFF;
				a = rgba & 0xFF;

			}


			inline RGBA (unsigned char r, unsigned char g, unsigned char b, unsigned char a) {

				Set (r, g, b, a);

			}


			inline int32_t Get () {

				int32_t value = ((r & 0xFF) << 24) | ((g & 0xFF) << 16) | ((b & 0xFF) << 8) | (a & 0xFF);
				return value;

			}


			inline void MultiplyAlpha () {

				if (a == 0) {

					Set (0, 0, 0, 0);

				} else if (a != 0xFF) {

					a16 = __alpha16[a];
					Set ((r * a16) >> 16, (g * a16) >> 16, (b * a16) >> 16, a);

				}

			}


			inline void UnmultiplyAlpha () {

				if (a != 0 && a != 0xFF) {

					unmult = 255.0 / a;
					Set (__clamp[(int)(r * unmult)], __clamp[(int)(g * unmult)], __clamp[(int)(b * unmult)], a);

				}

			}


			inline void ReadUInt8 (const unsigned char* data, int offset, PixelFormat format, bool premultiplied, Endian endian) {

				switch (format) {

					case BGRA32:

						if (endian == LIME_LITTLE_ENDIAN)
							Set (data[offset + 1], data[offset + 2], data[offset + 3], data[offset]);
						else
							Set (data[offset + 2], data[offset + 1], data[offset], data[offset + 3]);
						break;

					case RGBA32:

						if (endian == LIME_LITTLE_ENDIAN)
							Set (data[offset + 3], data[offset + 2], data[offset + 1], data[offset]);
						else
							Set (data[offset], data[offset + 1], data[offset + 2], data[offset + 3]);
						break;

					case ARGB32:

						if (endian == LIME_LITTLE_ENDIAN)
							Set (data[offset + 2], data[offset + 1], data[offset], data[offset + 3]);
						else
							Set (data[offset + 1], data[offset + 2], data[offset + 3], data[offset]);
						break;

				}

				if (premultiplied) {

					UnmultiplyAlpha ();

				}

			}


			inline void Set (unsigned char r, unsigned char g, unsigned char b, unsigned char a) {

				this->r = r;
				this->g = g;
				this->b = b;
				this->a = a;

			}


			inline void WriteUInt8 (unsigned char* data, int offset, PixelFormat format, bool premultiplied) {

				if (premultiplied) {

					MultiplyAlpha ();

				}

				switch (format) {

					case BGRA32:

						data[offset] = b;
						data[offset + 1] = g;
						data[offset + 2] = r;
						data[offset + 3] = a;
						break;

					case RGBA32:

						data[offset] = r;
						data[offset + 1] = g;
						data[offset + 2] = b;
						data[offset + 3] = a;
						break;

					case ARGB32:

						data[offset] = a;
						data[offset + 1] = r;
						data[offset + 2] = g;
						data[offset + 3] = b;
						break;

				}

			}


			inline bool operator == (RGBA& rgba) {

				return (a == rgba.a && r == rgba.r && g == rgba.g && b == rgba.b);

			}


			unsigned char r;
			unsigned char g;
			unsigned char b;
			unsigned char a;


	};


}


#endif
