#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif


#include <hx/CFFI.h>
#include "Utils.h"


using namespace ::extensionLowerCase::;



static value ::extensionLowerCase::_sample_method (value inputValue) {
	
	int returnValue = SampleMethod(val_int(inputValue));
	return alloc_int(returnValue);
	
}
DEFINE_PRIM (::extensionLowerCase::_sample_method, 1);



extern "C" void ::extensionLowerCase::_main () {
	
	val_int(0); // Fix Neko init
	
}
DEFINE_ENTRY_POINT (::extensionLowerCase::_main);



extern "C" int ::extensionLowerCase::_register_prims () { return 0; }