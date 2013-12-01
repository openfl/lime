#include <Utils.h>


namespace lime {


	
	double CapabilitiesGetPixelAspectRatio () {
		
		return 1;
		
	}
	
	
	double CapabilitiesGetScreenDPI () {
		
		return 200;
		
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
	
	
	bool ClearUserPreference (const char *inId) {
		
		return true;
		
	   /*JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/lime/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "clearUserPreference", "(Ljava/lang/String;)V");
		if (mid == 0)
			return false;
		
		jstring jInId = env->NewStringUTF( inId );
		env->CallStaticVoidMethod(cls, mid, jInId );
		return true;*/
		
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
	
	
	bool GetAcceleration (double &outX, double &outY, double &outZ) {
		
		//if (gFixedOrientation == 3 || gFixedOrientation == 4) {
			
			outX = 0;
			outY = 0;
			outZ = 1;
			
		//}
		
		/*int result = accelerometer_read_forces (&outX, &outY, &outZ);
		
		if (getenv ("FORCE_PORTRAIT") != NULL) {
			
			int cache = outX;
			outX = outY;
			outY = -cache;
			
		}
		
		outZ = -outZ;*/
		
		return true;
		
	}
	
	
	std::string GetUserPreference (const char *inId) {
		
		return "";
		
	   /*JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/lime/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "getUserPreference", "(Ljava/lang/String;)Ljava/lang/String;");
		if (mid == 0)
		{
			return std::string("");
		}
		
		jstring jInId = env->NewStringUTF(inId);
		jstring jPref = (jstring) env->CallStaticObjectMethod(cls, mid, jInId);
		env->DeleteLocalRef(jInId);
		const char *nativePref = env->GetStringUTFChars(jPref, 0);
		std::string result(nativePref);
		env->ReleaseStringUTFChars(jPref, nativePref);
		return result;*/
		
	}
	
	
	void HapticVibrate (int period, int duration) {
		
		
			
	}
	

	bool LaunchBrowser (const char *inUtf8URL) {
		
		return false;	
		
	}
	
	
	bool SetUserPreference (const char *inId, const char *inPreference) {
		
		/*JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/lime/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "setUserPreference", "(Ljava/lang/String;Ljava/lang/String;)V");
		if (mid == 0)
			return false;
	
		jstring jInId = env->NewStringUTF( inId );
		jstring jPref = env->NewStringUTF ( inPreference );
		env->CallStaticVoidMethod(cls, mid, jInId, jPref );
		env->DeleteLocalRef(jInId);
		env->DeleteLocalRef(jPref);
		return true;*/
		
		return true;
		
	}
	
	
}




	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	