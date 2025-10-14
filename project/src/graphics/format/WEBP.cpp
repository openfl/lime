#ifdef LIME_WEBP

extern "C" {
	#include <webp/decode.h>
	#include <webp/encode.h>
}

#include <graphics/format/WEBP.h>
#include <graphics/ImageBuffer.h>
#include <system/System.h>
#include <utils/Bytes.h>
#include <utils/Resource.h>
#include <cstring>
#include <limits>

namespace lime {

	static inline int clampi (int v, int lo, int hi) {
		return v < lo ? lo : (v > hi ? hi : v);
	}

	static bool LoadResourceToMemory (Resource* resource, Bytes*& owned, const uint8_t*& src, size_t& len) {

		owned = nullptr;
		src = nullptr;
		len = 0;

		if (!resource) return false;

		if (resource->path) {

			FILE_HANDLE* file = lime::fopen (resource->path, "rb");
			if (!file) return false;

			unsigned char sig[12] = {0};
			int readOK = lime::fread (&sig[0], 12, 1, file);
			lime::fclose (file);

			if (readOK != 1) return false;

			const bool isRIFF = (sig[0]=='R' && sig[1]=='I' && sig[2]=='F' && sig[3]=='F');
			const bool isWEBP = (sig[8]=='W' && sig[9]=='E' && sig[10]=='B' && sig[11]=='P');
			if (!isRIFF || !isWEBP) return false;

			Bytes* b = new Bytes ();
			b->ReadFile (resource->path);
			if (b->length <= 0) { delete b; return false; }

			owned = b;
			src = reinterpret_cast<const uint8_t*>(b->b);
			len = static_cast<size_t>(b->length);
			return true;

		} else if (resource->data) {

			src = reinterpret_cast<const uint8_t*>(resource->data->b);
			len = static_cast<size_t>(resource->data->length);
			if (len == 0) return false;

			return true;

		}

		return false;
	}

	
	bool WEBP::Decode (Resource* resource, ImageBuffer* imageBuffer, bool decodeData) {

		if (!resource || !imageBuffer) return false;

		Bytes* owned = nullptr;
		const uint8_t* src = nullptr;
		size_t len = 0;

		if (!LoadResourceToMemory (resource, owned, src, len)) {
			return false;
		}

		int w = 0, h = 0;
		if (!WebPGetInfo (src, len, &w, &h) || w <= 0 || h <= 0) {
			if (owned) delete owned;
			return false;
		}

		if (!decodeData) {
			imageBuffer->width = w;
			imageBuffer->height = h;
			if (owned) delete owned;
			return true;
		}

		imageBuffer->Resize (w, h, 32);
		unsigned char* dst = imageBuffer->data && imageBuffer->data->buffer
			? imageBuffer->data->buffer->b : nullptr;
		if (!dst) {
			if (owned) delete owned;
			return false;
		}

		const int stride = imageBuffer->Stride ();
		const size_t dstSize = static_cast<size_t>(h) * static_cast<size_t>(stride);

		uint8_t* ok = WebPDecodeRGBAInto (src, len, dst, dstSize, stride);
		if (!ok) {
			if (owned) delete owned;
			return false;
		}

		if (owned) delete owned;
		return true;
	}



	bool WEBP::Encode (ImageBuffer* imageBuffer, Bytes* bytes, int quality) {

		if (!imageBuffer || !bytes) return false;

		const int w = imageBuffer->width;
		const int h = imageBuffer->height;
		if (w <= 0 || h <= 0) return false;

		const int stride = imageBuffer->Stride ();
		const uint8_t* src = imageBuffer->data && imageBuffer->data->buffer
			? reinterpret_cast<const uint8_t*>(imageBuffer->data->buffer->b) : nullptr;
		if (!src) return false;


		uint8_t* out = nullptr;
		const float q = static_cast<float>(clampi (quality, 0, 100));
		size_t out_size = WebPEncodeRGBA (src, w, h, stride, q, &out);

		if (!out || out_size == 0) {
			if (out) WebPFree (out);
			return false;
		}

		if (out_size > static_cast<size_t>((std::numeric_limits<int>::max)())) {
			WebPFree (out);
			return false;
		}

		bytes->Resize (static_cast<int>(out_size));
		std::memcpy (bytes->b, out, out_size);
		WebPFree (out);

		return true;
	}

} // namespace lime

#endif // LIME_WEBP
