#include <Utils.h>


namespace lime {


	
	double CapabilitiesGetPixelAspectRatio () {
		
		return 1;
		
	}
	
	
	double CapabilitiesGetScreenDPI () {
		
		return 306;
		
	}
	
	
	QuickVec<int>* CapabilitiesGetScreenResolutions () {
		
		// glfwInit();
		int count;
		QuickVec<int> *out = new QuickVec<int>();
		/*const GLFWvidmode *modes = glfwGetVideoModes(glfwGetPrimaryMonitor(), &count);
		for (int i = 0; i < count; i++)
		{
		  out->push_back( modes[i].width );
		  out->push_back( modes[i].height );
		}*/
		return out;
		
	}
	
	
	double CapabilitiesGetScreenResolutionX () {
		
		if (gFixedOrientation == 3 || gFixedOrientation == 4) {
			
			return 1280;
			
		} else {
			
			return 720;
			
		}
		
	}
	
	
	double CapabilitiesGetScreenResolutionY () {
		
		if (gFixedOrientation == 3 || gFixedOrientation == 4) {
			
			return 720;
			
		} else {
			
			return 1280;
			
		}
		
	}
	
	
	std::string CapabilitiesGetLanguage () {
		
		return "en-US";
		
	}
	
	
	std::string FileDialogFolder (const std::string &title, const std::string &text) {
		
		return "";
		
	}
	
	
	std::string FileDialogOpen (const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes) {
		
		return "";
		
	}
	
	
	std::string FileDialogSave (const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes) {
		
		return "";
		
	}
	
	
	void HapticVibrate (int period, int duration) {
		
		
		
	}
	
	
}




	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	