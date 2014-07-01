extern "C" {



}

#include <graphics/ImageData.h>
#include <graphics/PVRTC.h>


typedef struct _PVRTexHeader {

	uint32_t headerLength;
	uint32_t height;
	uint32_t width;
	uint32_t numMipmaps;
	uint32_t flags;
	uint32_t dataLength;
	uint32_t bpp;
	uint32_t bitmaskRed;
	uint32_t bitmaskGreen;
	uint32_t bitmaskBlue;
	uint32_t bitmaskAlpha;
	uint32_t pvrTag;
	uint32_t numSurfs;

} PVRTexHeader;

static char gPVRTexIdentifier[5] = "PVR!";


namespace lime {


	extern FILE *OpenRead (const char *);


	bool PVRTC::Decode (const char *path, ImageData *imageData) {

		PVRTexHeader header;
		FILE *file = OpenRead (path);

		fread (&header, sizeof(header), 1, file);

		if (gPVRTexIdentifier[0] != ((header.pvrTag >>  0) & 0xFF) ||
			gPVRTexIdentifier[1] != ((header.pvrTag >>  8) & 0xFF) ||
			gPVRTexIdentifier[2] != ((header.pvrTag >> 16) & 0xFF) ||
			gPVRTexIdentifier[3] != ((header.pvrTag >> 24) & 0xFF)) {

			return false;

		}

		return false;

	}

}
