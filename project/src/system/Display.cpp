#include <system/Display.h>
#include <math/Rectangle.h>


namespace lime {


	void Display::GetSafeAreaInsets (int displayIndex, Rectangle * rect) {

		rect->SetTo(0.0, 0.0, 0.0, 0.0);
	}

}