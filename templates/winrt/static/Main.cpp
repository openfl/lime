#include <stdio.h>

#ifdef HX_WINDOWS
#include <windows.h>
#endif

extern "C" const char *hxRunLibrary ();
extern "C" void hxcpp_set_top_of_stack ();

extern "C" int zlib_register_prims ();
extern "C" int lime_cairo_register_prims ();
extern "C" int lime_openal_register_prims ();
::foreach ndlls::::if (registerStatics)::
extern "C" int ::nameSafe::_register_prims ();::end::::end::


#ifdef HX_WINDOWS
int __stdcall WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
#else
extern "C" int main(int argc, char *argv[]) {
#endif
	
	hxcpp_set_top_of_stack ();
	
	zlib_register_prims ();
	lime_cairo_register_prims ();
	lime_openal_register_prims ();
	::foreach ndlls::::if (registerStatics)::
	::nameSafe::_register_prims ();::end::::end::
	
	const char *err = NULL;
 	err = hxRunLibrary ();
	
	if (err) {
		
		printf("Error: %s\n", err);
		return -1;
		
	}
	
	return 0;
	
}