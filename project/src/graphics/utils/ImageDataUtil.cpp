#include <graphics/utils/ImageDataUtil.h>
#include <math/color/RGBA.h>
#include <utils/QuickVec.h>
#include <math.h>


namespace lime {


	unsigned char alphaTable[256];
	unsigned char redTable[256];
	unsigned char greenTable[256];
	unsigned char blueTable[256];


	void ImageDataUtil::ColorTransform (Image* image, Rectangle* rect, ColorMatrix* colorMatrix) {

		PixelFormat format = image->buffer->format;
		bool premultiplied = image->buffer->premultiplied;
		uint8_t* data = (uint8_t*)image->buffer->data->buffer->b;

		Rectangle* _rect = (Rectangle*)(image->type);
		ImageDataView dataView = ImageDataView (image, rect);

		colorMatrix->GetAlphaTable (alphaTable);
		colorMatrix->GetRedTable (redTable);
		colorMatrix->GetGreenTable (greenTable);
		colorMatrix->GetBlueTable (blueTable);

		int row, offset;
		RGBA pixel;

		for (int y = 0; y < dataView.height; y++) {

			row = dataView.Row (y);

			for (int x = 0; x < dataView.width; x++) {

				offset = row + (x * 4);

				pixel.ReadUInt8 (data, offset, format, premultiplied, LIME_BIG_ENDIAN);
				pixel.Set (redTable[pixel.r], greenTable[pixel.g], blueTable[pixel.b], alphaTable[pixel.a]);
				pixel.WriteUInt8 (data, offset, format, premultiplied);

			}

		}

	}


	void ImageDataUtil::CopyChannel (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int srcChannel, int destChannel) {

		uint8_t* srcData = (uint8_t*)sourceImage->buffer->data->buffer->b;
		uint8_t* destData = (uint8_t*)image->buffer->data->buffer->b;

		ImageDataView srcView = ImageDataView (sourceImage, sourceRect);
		Rectangle destRect = Rectangle (destPoint->x, destPoint->y, srcView.width, srcView.height);
		ImageDataView destView = ImageDataView (image, &destRect);

		PixelFormat srcFormat = sourceImage->buffer->format;
		PixelFormat destFormat = image->buffer->format;
		bool srcPremultiplied = sourceImage->buffer->premultiplied;
		bool destPremultiplied = image->buffer->premultiplied;

		int srcPosition, destPosition;
		RGBA srcPixel, destPixel;
		unsigned char value = 0;

		for (int y = 0; y < destView.height; y++) {

			srcPosition = srcView.Row (y);
			destPosition = destView.Row (y);

			for (int x = 0; x < destView.width; x++) {

				srcPixel.ReadUInt8 (srcData, srcPosition, srcFormat, srcPremultiplied, LIME_BIG_ENDIAN);
				destPixel.ReadUInt8 (destData, destPosition, destFormat, destPremultiplied, LIME_BIG_ENDIAN);

				switch (srcChannel) {

					case 0: value = srcPixel.r; break;
					case 1: value = srcPixel.g; break;
					case 2: value = srcPixel.b; break;
					case 3: value = srcPixel.a; break;

				}

				switch (destChannel) {

					case 0: destPixel.r = value; break;
					case 1: destPixel.g = value; break;
					case 2: destPixel.b = value; break;
					case 3: destPixel.a = value; break;

				}

				destPixel.WriteUInt8 (destData, destPosition, destFormat, destPremultiplied);

				srcPosition += 4;
				destPosition += 4;

			}

		}

	}


	void ImageDataUtil::CopyPixels (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, Image* alphaImage, Vector2* alphaPoint, bool mergeAlpha) {

		uint8_t* sourceData = (uint8_t*)sourceImage->buffer->data->buffer->b;
		uint8_t* destData = (uint8_t*)image->buffer->data->buffer->b;

		if (!sourceData || !destData) return;

		ImageDataView sourceView = ImageDataView (sourceImage, sourceRect);
		Rectangle destRect = Rectangle (destPoint->x, destPoint->y, sourceView.width, sourceView.height);
		ImageDataView destView = ImageDataView (image, &destRect);

		PixelFormat sourceFormat = sourceImage->buffer->format;
		PixelFormat destFormat = image->buffer->format;

		int sourcePosition, destPosition;
		float sourceAlpha, destAlpha, oneMinusSourceAlpha, blendAlpha;
		RGBA sourcePixel, destPixel;

		bool sourcePremultiplied = sourceImage->buffer->premultiplied;
		bool destPremultiplied = image->buffer->premultiplied;
		int sourceBytesPerPixel = sourceImage->buffer->bitsPerPixel / 8;
		int destBytesPerPixel = image->buffer->bitsPerPixel / 8;

		bool useAlphaImage = (alphaImage && alphaImage->buffer->transparent);
		bool blend = (mergeAlpha || (useAlphaImage && !image->buffer->transparent) || (!mergeAlpha && !image->buffer->transparent && sourceImage->buffer->transparent));

		if (!useAlphaImage) {

			if (blend) {

				for (int y = 0; y < destView.height; y++) {

					sourcePosition = sourceView.Row (y);
					destPosition = destView.Row (y);

					for (int x = 0; x < destView.width; x++) {

						sourcePixel.ReadUInt8 (sourceData, sourcePosition, sourceFormat, sourcePremultiplied, LIME_BIG_ENDIAN);
						destPixel.ReadUInt8 (destData, destPosition, destFormat, destPremultiplied, LIME_BIG_ENDIAN);

						sourceAlpha = sourcePixel.a / 255.0;
						destAlpha = destPixel.a / 255.0;
						oneMinusSourceAlpha = 1 - sourceAlpha;
						blendAlpha = sourceAlpha + (destAlpha * oneMinusSourceAlpha);

						if (blendAlpha == 0) {

							destPixel.Set (0, 0, 0, 0);

						} else {

							destPixel.r = __clamp[int (0.5 + (sourcePixel.r * sourceAlpha + destPixel.r * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
							destPixel.g = __clamp[int (0.5 + (sourcePixel.g * sourceAlpha + destPixel.g * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
							destPixel.b = __clamp[int (0.5 + (sourcePixel.b * sourceAlpha + destPixel.b * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
							destPixel.a = __clamp[int (0.5 + blendAlpha * 255.0)];

						}

						destPixel.WriteUInt8 (destData, destPosition, destFormat, destPremultiplied);

						sourcePosition += 4;
						destPosition += 4;

					}

				}

			} else if (sourceFormat == destFormat && sourcePremultiplied == destPremultiplied && sourceBytesPerPixel == destBytesPerPixel) {

				for (int y = 0; y < destView.height; y++) {

					sourcePosition = sourceView.Row (y);
					destPosition = destView.Row (y);

					memcpy (&destData[destPosition], &sourceData[sourcePosition], destView.width * destBytesPerPixel);

				}

			} else {

				for (int y = 0; y < destView.height; y++) {

					sourcePosition = sourceView.Row (y);
					destPosition = destView.Row (y);

					for (int x = 0; x < destView.width; x++) {

						sourcePixel.ReadUInt8 (sourceData, sourcePosition, sourceFormat, sourcePremultiplied, LIME_BIG_ENDIAN);
						sourcePixel.WriteUInt8 (destData, destPosition, destFormat, destPremultiplied);

						sourcePosition += 4;
						destPosition += 4;

					}

				}

			}

		} else {

			uint8_t* alphaData = (uint8_t*)alphaImage->buffer->data->buffer->b;
			PixelFormat alphaFormat = alphaImage->buffer->format;
			bool alphaPremultiplied = alphaImage->buffer->premultiplied;
			int alphaPosition;
			RGBA alphaPixel;

			Rectangle alphaRect = Rectangle (sourceView.x + alphaPoint->x, sourceView.y + alphaPoint->y, sourceView.width, sourceView.height);
			ImageDataView alphaView = ImageDataView (alphaImage, &alphaRect);

			destView.Clip (destPoint->x, destPoint->y, alphaView.width, alphaView.height);

			if (blend) {

				for (int y = 0; y < destView.height; y++) {

					sourcePosition = sourceView.Row (y);
					destPosition = destView.Row (y);
					alphaPosition = alphaView.Row (y);

					for (int x = 0; x < destView.width; x++) {

						sourcePixel.ReadUInt8 (sourceData, sourcePosition, sourceFormat, sourcePremultiplied, LIME_BIG_ENDIAN);
						destPixel.ReadUInt8 (destData, destPosition, destFormat, destPremultiplied, LIME_BIG_ENDIAN);
						alphaPixel.ReadUInt8 (alphaData, alphaPosition, alphaFormat, false, LIME_BIG_ENDIAN);

						sourceAlpha = (alphaPixel.a / 255.0) * (sourcePixel.a / 255.0);

						if (sourceAlpha > 0) {

							destAlpha = destPixel.a / 255.0;
							oneMinusSourceAlpha = 1 - sourceAlpha;
							blendAlpha = sourceAlpha + (destAlpha * oneMinusSourceAlpha);

							destPixel.r = __clamp[int (0.5 + (sourcePixel.r * sourceAlpha + destPixel.r * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
							destPixel.g = __clamp[int (0.5 + (sourcePixel.g * sourceAlpha + destPixel.g * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
							destPixel.b = __clamp[int (0.5 + (sourcePixel.b * sourceAlpha + destPixel.b * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
							destPixel.a = __clamp[int (0.5 + blendAlpha * 255.0)];

							destPixel.WriteUInt8 (destData, destPosition, destFormat, destPremultiplied);

						}

						sourcePosition += 4;
						destPosition += 4;
						alphaPosition += 4;

					}

				}

			} else {

				for (int y = 0; y < destView.height; y++) {

					sourcePosition = sourceView.Row (y);
					destPosition = destView.Row (y);
					alphaPosition = alphaView.Row (y);

					for (int x = 0; x < destView.width; x++) {

						sourcePixel.ReadUInt8 (sourceData, sourcePosition, sourceFormat, sourcePremultiplied, LIME_BIG_ENDIAN);
						alphaPixel.ReadUInt8 (alphaData, alphaPosition, alphaFormat, false, LIME_BIG_ENDIAN);

						sourcePixel.a = int (0.5 + (sourcePixel.a * (alphaPixel.a / 255.0)));
						sourcePixel.WriteUInt8 (destData, destPosition, destFormat, destPremultiplied);

						sourcePosition += 4;
						destPosition += 4;
						alphaPosition += 4;

					}

				}

			}

		}

	}


	void ImageDataUtil::FillRect (Image* image, Rectangle* rect, int32_t color) {

		uint8_t* data = (uint8_t*)image->buffer->data->buffer->b;
		PixelFormat format = image->buffer->format;
		bool premultiplied = image->buffer->premultiplied;
		RGBA fillColor (color);

		if (rect->x == 0 && rect->y == 0 && rect->width == image->width && rect->height == image->height) {

			if (fillColor.a == fillColor.r && fillColor.r == fillColor.g && fillColor.g == fillColor.b) {

				memset (data, fillColor.a, image->buffer->data->byteLength);
				return;

			}

		}

		ImageDataView dataView = ImageDataView (image, rect);
		int row;

		if (premultiplied) fillColor.MultiplyAlpha ();

		for (int y = 0; y < dataView.height; y++) {

			row = dataView.Row (y);

			for (int x = 0; x < dataView.width; x++) {

				fillColor.WriteUInt8 (data, row + (x * 4), format, false);

			}

		}

	}


	void ImageDataUtil::FloodFill (Image* image, int x, int y, int32_t color) {

		uint8_t* data = (uint8_t*)image->buffer->data->buffer->b;
		PixelFormat format = image->buffer->format;
		bool premultiplied = image->buffer->premultiplied;

		RGBA fillColor (color);

		if (premultiplied) fillColor.MultiplyAlpha ();

		RGBA hitColor;
		hitColor.ReadUInt8 (data, ((y + image->offsetY) * (image->buffer->width * 4)) + ((x + image->offsetX) * 4), format, premultiplied, LIME_BIG_ENDIAN);

		if (!image->buffer->transparent) {

			fillColor.a = 0xFF;
			hitColor.a = 0xFF;

		}

		if (fillColor == hitColor) return;

		int dx[4] = { 0, -1, 1, 0 };
		int dy[4] = { -1, 0, 0, 1 };

		int minX = -image->offsetX;
		int minY = -image->offsetY;
		int maxX = minX + image->width;
		int maxY = minY + image->height;

		QuickVec<int> queue = QuickVec<int> ();
		queue.push_back (x);
		queue.push_back (y);

		int curPointX, curPointY, i, nextPointX, nextPointY, nextPointOffset;
		RGBA readColor;

		while (queue.size () > 0) {

			curPointY = queue.qpop ();
			curPointX = queue.qpop ();

			for (i = 0; i < 4; i++) {

				nextPointX = curPointX + dx[i];
				nextPointY = curPointY + dy[i];

				if (nextPointX < minX || nextPointY < minY || nextPointX >= maxX || nextPointY >= maxY) {

					continue;

				}

				nextPointOffset = (nextPointY * image->width + nextPointX) * 4;
				readColor.ReadUInt8 (data, nextPointOffset, format, premultiplied, LIME_BIG_ENDIAN);

				if (readColor == hitColor) {

					fillColor.WriteUInt8 (data, nextPointOffset, format, false);

					queue.push_back (nextPointX);
					queue.push_back (nextPointY);

				}

			}

		}

	}


	void ImageDataUtil::GetPixels (Image* image, Rectangle* rect, PixelFormat format, Bytes* pixels) {

		int length = int (rect->width * rect->height);
		pixels->Resize (length * 4);

		uint8_t* data = (uint8_t*)image->buffer->data->buffer->b;
		uint8_t* destData = (uint8_t*)pixels->b;

		PixelFormat sourceFormat = image->buffer->format;
		bool premultiplied = image->buffer->premultiplied;

		ImageDataView dataView = ImageDataView (image, rect);
		int position, destPosition = 0;
		RGBA pixel;

		for (int y = 0; y < dataView.height; y++) {

			position = dataView.Row (y);

			for (int x = 0; x < dataView.width; x++) {

				pixel.ReadUInt8 (data, position, sourceFormat, premultiplied, LIME_BIG_ENDIAN);
				pixel.WriteUInt8 (destData, destPosition, format, false);

				position += 4;
				destPosition += 4;

			}

		}

	}


	void ImageDataUtil::Merge (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int redMultiplier, int greenMultiplier, int blueMultiplier, int alphaMultiplier) {

		ImageDataView sourceView = ImageDataView (sourceImage, sourceRect);
		Rectangle destRect = Rectangle (destPoint->x, destPoint->y, sourceView.width, sourceView.height);
		ImageDataView destView = ImageDataView (image, &destRect);

		uint8_t* sourceData = (uint8_t*)sourceImage->buffer->data->buffer->b;
		uint8_t* destData = (uint8_t*)image->buffer->data->buffer->b;
		PixelFormat sourceFormat = sourceImage->buffer->format;
		PixelFormat destFormat = image->buffer->format;
		bool sourcePremultiplied = sourceImage->buffer->premultiplied;
		bool destPremultiplied = image->buffer->premultiplied;

		int sourcePosition, destPosition;
		RGBA sourcePixel, destPixel;

		for (int y = 0; y < destView.height; y++) {

			sourcePosition = sourceView.Row (y);
			destPosition = destView.Row (y);

			for (int x = 0; x < destView.width; x++) {

				sourcePixel.ReadUInt8 (sourceData, sourcePosition, sourceFormat, sourcePremultiplied, LIME_BIG_ENDIAN);
				destPixel.ReadUInt8 (destData, destPosition, destFormat, destPremultiplied, LIME_BIG_ENDIAN);

				destPixel.r = int (((sourcePixel.r * redMultiplier) + (destPixel.r * (256 - redMultiplier))) / 256);
				destPixel.g = int (((sourcePixel.g * greenMultiplier) + (destPixel.g * (256 - greenMultiplier))) / 256);
				destPixel.b = int (((sourcePixel.b * blueMultiplier) + (destPixel.b * (256 - blueMultiplier))) / 256);
				destPixel.a = int (((sourcePixel.a * alphaMultiplier) + (destPixel.a * (256 - alphaMultiplier))) / 256);

				destPixel.WriteUInt8 (destData, destPosition, destFormat, destPremultiplied);

				sourcePosition += 4;
				destPosition += 4;

			}

		}

	}


	void ImageDataUtil::MultiplyAlpha (Image* image) {

		PixelFormat format = image->buffer->format;
		uint8_t* data = (uint8_t*)image->buffer->data->buffer->b;
		int length = int (image->buffer->data->length / 4);
		RGBA pixel;

		for (int i = 0; i < length; i++) {

			pixel.ReadUInt8 (data, i * 4, format, false, LIME_BIG_ENDIAN);
			pixel.WriteUInt8 (data, i * 4, format, true);

		}

	}


	void ImageDataUtil::Resize (Image* image, ImageBuffer* buffer, int newWidth, int newHeight) {

		int imageWidth = image->width;
		int imageHeight = image->height;

		uint8_t* data = (uint8_t*)image->buffer->data->buffer->b;
		uint8_t* newData = (uint8_t*)buffer->data->buffer->b;

		int sourceIndex, sourceIndexX, sourceIndexY, sourceIndexXY, index;
		int sourceX, sourceY;
		float u, v, uRatio, vRatio, uOpposite, vOpposite;

		for (int y = 0; y < newHeight; y++) {

			for (int x = 0; x < newWidth; x++) {

				u = ((x + 0.5) / newWidth) * imageWidth - 0.5;
				v = ((y + 0.5) / newHeight) * imageHeight - 0.5;

				sourceX = int (u);
				sourceY = int (v);

				sourceIndex = (sourceY * imageWidth + sourceX) * 4;
				sourceIndexX = (sourceX < imageWidth - 1) ? sourceIndex + 4 : sourceIndex;
				sourceIndexY = (sourceY < imageHeight - 1) ? sourceIndex + (imageWidth * 4) : sourceIndex;
				sourceIndexXY = (sourceIndexX != sourceIndex) ? sourceIndexY + 4 : sourceIndexY;

				index = (y * newWidth + x) * 4;

				uRatio = u - sourceX;
				vRatio = v - sourceY;
				uOpposite = 1 - uRatio;
				vOpposite = 1 - vRatio;

				newData[index] = int ((data[sourceIndex] * uOpposite + data[sourceIndexX] * uRatio) * vOpposite + (data[sourceIndexY] * uOpposite + data[sourceIndexXY] * uRatio) * vRatio);
				newData[index + 1] = int ((data[sourceIndex + 1] * uOpposite + data[sourceIndexX + 1] * uRatio) * vOpposite + (data[sourceIndexY + 1] * uOpposite + data[sourceIndexXY + 1] * uRatio) * vRatio);
				newData[index + 2] = int ((data[sourceIndex + 2] * uOpposite + data[sourceIndexX + 2] * uRatio) * vOpposite + (data[sourceIndexY + 2] * uOpposite + data[sourceIndexXY + 2] * uRatio) * vRatio);

				// Maybe it would be better to not weigh colors with an alpha of zero, but the below should help prevent black fringes caused by transparent pixels made visible

				if (data[sourceIndexX + 3] == 0 || data[sourceIndexY + 3] == 0 || data[sourceIndexXY + 3] == 0) {

					newData[index + 3] = 0;

				} else {

					newData[index + 3] = data[sourceIndex + 3];

				}

			}

		}

	}


	void ImageDataUtil::SetFormat (Image* image, PixelFormat format) {

		int index;
		int length = image->buffer->data->length / 4;
		int r1, g1, b1, a1, r2, g2, b2, a2;
		int r, g, b, a;

		switch (image->buffer->format) {

			case RGBA32:

				r1 = 0;
				g1 = 1;
				b1 = 2;
				a1 = 3;
				break;

			case ARGB32:

				r1 = 1;
				g1 = 2;
				b1 = 3;
				a1 = 0;
				break;

			case BGRA32:

				r1 = 2;
				g1 = 1;
				b1 = 0;
				a1 = 3;
				break;

		}

		switch (format) {

			case RGBA32:

				r2 = 0;
				g2 = 1;
				b2 = 2;
				a2 = 3;
				break;

			case ARGB32:

				r2 = 1;
				g2 = 2;
				b2 = 3;
				a2 = 0;
				break;

			case BGRA32:

				r2 = 2;
				g2 = 1;
				b2 = 0;
				a2 = 3;
				break;

		}

		unsigned char* data = image->buffer->data->buffer->b;

		for (int i = 0; i < length; i++) {

			index = i * 4;

			r = data[index + r1];
			g = data[index + g1];
			b = data[index + b1];
			a = data[index + a1];

			data[index + r2] = r;
			data[index + g2] = g;
			data[index + b2] = b;
			data[index + a2] = a;

		}

	}


	void ImageDataUtil::SetPixels (Image* image, Rectangle* rect, Bytes* bytes, int offset, PixelFormat format, Endian endian) {

		uint8_t* data = (uint8_t*)image->buffer->data->buffer->b;
		PixelFormat sourceFormat = image->buffer->format;
		bool premultiplied = image->buffer->premultiplied;
		ImageDataView dataView = ImageDataView (image, rect);
		int row;
		RGBA pixel;

		uint8_t* byteArray = (uint8_t*)bytes->b;
		int srcPosition = offset;

		bool transparent = image->buffer->transparent;

		for (int y = 0; y < dataView.height; y++) {

			row = dataView.Row (y);

			for (int x = 0; x < dataView.width; x++) {

				pixel.ReadUInt8 (byteArray, srcPosition, format, false, endian);
				if (!transparent) pixel.a = 0xFF;
				pixel.WriteUInt8 (data, row + (x * 4), sourceFormat, premultiplied);

				srcPosition += 4;

			}

		}

	}


	int __pixelCompare (int32_t n1, int32_t n2) {

		int tmp1;
		int tmp2;

		tmp1 = (n1 >> 24) & 0xFF;
		tmp2 = (n2 >> 24) & 0xFF;

		if (tmp1 != tmp2) {

			return (tmp1 > tmp2 ? 1 : -1);

		} else {

			tmp1 = (n1 >> 16) & 0xFF;
			tmp2 = (n2 >> 16) & 0xFF;

			if (tmp1 != tmp2) {

				return (tmp1 > tmp2 ? 1 : -1);

			} else {

				tmp1 = (n1 >> 8) & 0xFF;
				tmp2 = (n2 >> 8) & 0xFF;

				if (tmp1 != tmp2) {

					return (tmp1 > tmp2 ? 1 : -1);

				} else {

					tmp1 = n1 & 0xFF;
					tmp2 = n2 & 0xFF;

					if (tmp1 != tmp2) {

						return (tmp1 > tmp2 ? 1 : -1);

					} else {

						return 0;

					}

				}

			}

		}

		return 0;

	}


	int ImageDataUtil::Threshold (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int operation, int32_t threshold, int32_t color, int32_t mask, bool copySource) {

		RGBA _color (color);
		int hits = 0;

		uint8_t* srcData = (uint8_t*)sourceImage->buffer->data->buffer->b;
		uint8_t* destData = (uint8_t*)image->buffer->data->buffer->b;

		ImageDataView srcView = ImageDataView (sourceImage, sourceRect);
		Rectangle destRect = Rectangle (destPoint->x, destPoint->y, srcView.width, srcView.height);
		ImageDataView destView = ImageDataView (image, &destRect);

		PixelFormat srcFormat = sourceImage->buffer->format;
		PixelFormat destFormat = image->buffer->format;
		bool srcPremultiplied = sourceImage->buffer->premultiplied;
		bool destPremultiplied = image->buffer->premultiplied;

		int srcPosition, destPosition, value;
		RGBA srcPixel, destPixel;
		int32_t pixelMask;
		bool test;

		for (int y = 0; y < destView.height; y++) {

			srcPosition = srcView.Row (y);
			destPosition = destView.Row (y);

			for (int x = 0; x < destView.width; x++) {

				srcPixel.ReadUInt8 (srcData, srcPosition, srcFormat, srcPremultiplied, LIME_BIG_ENDIAN);

				pixelMask = srcPixel.Get () & mask;

				value = __pixelCompare (pixelMask, threshold);

				switch (operation) {

					case 0: test = (value != 0); break;
					case 1: test = (value == 0); break;
					case 2: test = (value == -1); break;
					case 3: test = (value == 0 || value == -1); break;
					case 4: test = (value == 1); break;
					case 5: test = (value == 0 || value == 1); break;

				}

				if (test) {

					_color.WriteUInt8 (destData, destPosition, destFormat, destPremultiplied);
					hits++;

				} else if (copySource) {

					srcPixel.WriteUInt8 (destData, destPosition, destFormat, destPremultiplied);

				}

				srcPosition += 4;
				destPosition += 4;

			}

		}

		return hits;

	}


	void ImageDataUtil::UnmultiplyAlpha (Image* image) {

		PixelFormat format = image->buffer->format;
		uint8_t* data = (uint8_t*)image->buffer->data->buffer->b;
		int length = int (image->buffer->data->length / 4);
		RGBA pixel;

		for (int i = 0; i < length; i++) {

			pixel.ReadUInt8 (data, i * 4, format, true, LIME_BIG_ENDIAN);
			pixel.WriteUInt8 (data, i * 4, format, false);

		}

	}


	ImageDataView::ImageDataView (Image* image, Rectangle* rect) {

		this->image = image;
		this->rect = Rectangle(rect->x, rect->y, rect->width, rect->height);

		if (this->rect.x < 0) this->rect.x = 0;
		if (this->rect.y < 0) this->rect.y = 0;
		if (this->rect.x + this->rect.width > image->width) this->rect.width = image->width - this->rect.x;
		if (this->rect.y + this->rect.height > image->height) this->rect.height = image->height - this->rect.y;
		if (this->rect.width < 0) this->rect.width = 0;
		if (this->rect.height < 0) this->rect.height = 0;

		stride = image->buffer->Stride ();

		__Update ();


	}


	void ImageDataView::Clip (int x, int y, int width, int height) {

		rect.Contract (x, y, width, height);
		__Update ();

	}


	inline bool ImageDataView::HasRow (int y) {

		return (y >= 0 && y < height);

	}


	void ImageDataView::Offset (int x, int y) {

		if (x < 0) {

			rect.x += x;
			if (rect.x < 0) rect.x = 0;

		} else {

			rect.x += x;
			rect.width -= x;

		}

		if (y < 0) {

			rect.y += y;
			if (rect.y < 0) rect.y = 0;

		} else {

			rect.y += y;
			rect.height -= y;

		}

		__Update ();

	}


	inline int ImageDataView::Row (int y) {

		return byteOffset + stride * y;

	}


	inline void ImageDataView::__Update () {

		this->x = (int) ceil (rect.x);
		this->y = (int) ceil (rect.y);
		this->width = (int) floor (rect.width);
		this->height = (int) floor (rect.height);
		byteOffset = (stride * (this->y + image->offsetY)) + ((this->x + image->offsetX) * 4);

	}


}
