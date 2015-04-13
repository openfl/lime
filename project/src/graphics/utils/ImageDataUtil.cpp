#include <graphics/utils/ImageDataUtil.h>
#include <system/System.h>


namespace lime {
	
	
	static long int __alpha16[256];
	
	int initValues () {
		
		for (int i = 0; i < 256; i++) {
			
			__alpha16[i] = i * ((1 << 16) / 255); 
			
		}
		
		return 0;
		
	}
	
	static int initValues_ = initValues ();
	
	
	void ImageDataUtil::MultiplyAlpha (ByteArray* bytes) {
		
		int a16 = 0;
		int length = bytes->Size () / 4;
		uint8_t* data = (uint8_t*)bytes->Bytes ();
		
		for (int i = 0; i < length; i++) {
			
			a16 = __alpha16[data[3]];
			data[0] = (data[0] * a16) >> 16;
			data[1] = (data[1] * a16) >> 16;
			data[2] = (data[2] * a16) >> 16;
			data += 4;
			
		}
		
	}
	
	
	void ImageDataUtil::UnmultiplyAlpha (ByteArray* bytes) {
		
		
	}
	
	
}