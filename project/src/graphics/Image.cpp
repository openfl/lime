#include <graphics/Image.h>


namespace lime {
	
	
	static int id_buffer;
	static int id_height;
	static int id_offsetX;
	static int id_offsetY;
	static int id_transparent;
	static int id_width;
	static bool init = false;
	
	
	Image::Image () {
		
		buffer = 0;
		height = 0;
		offsetX = 0;
		offsetY = 0;
		transparent = true;
		width = 0;
		
	}
	
	
	Image::Image (value image) {
		
		if (!init) {
			
			id_buffer = val_id ("buffer");
			id_height = val_id ("height");
			id_offsetX = val_id ("offsetX");
			id_offsetY = val_id ("offsetY");
			id_transparent = val_id ("transparent");
			id_width = val_id ("width");
			init = true;
			
		}
		
		width = val_int (val_field (image, id_width));
		height = val_int (val_field (image, id_height));
		buffer = new ImageBuffer (val_field (image, id_buffer));
		offsetX = val_int (val_field (image, id_offsetX));
		offsetY = val_int (val_field (image, id_offsetY));
		transparent = val_bool (val_field (image, id_transparent));
		
	}
	
	
	Image::~Image () {
		
		delete buffer;
		
	}
	
	
}