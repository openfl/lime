#ifdef ANDROID


#include <utils/JNI.h>
#include <SDL_system.h>


namespace lime {
	
	
	void *JNI::GetEnv () {
		
		return SDL_AndroidGetJNIEnv ();
		
	}
	
	
}


#endif