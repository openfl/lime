#include <stdio.h>

extern "C" const char *hxRunLibrary ();
extern "C" void hxcpp_set_top_of_stack ();

extern "C" int zlib_register_prims ();
extern "C" int lime_cairo_register_prims ();
extern "C" int lime_curl_register_prims ();
extern "C" int lime_harfbuzz_register_prims ();
extern "C" int lime_openal_register_prims ();
extern "C" int lime_opengl_register_prims ();
extern "C" int lime_vorbis_register_prims ();
::foreach ndlls::::if (registerStatics)::
extern "C" int ::nameSafe::_register_prims ();::end::::end::


extern "C" int SDL_main (int argc, char *argv[]) {

	hxcpp_set_top_of_stack ();

	zlib_register_prims ();
	lime_cairo_register_prims ();
	lime_curl_register_prims ();
	lime_harfbuzz_register_prims ();
	lime_openal_register_prims ();
	lime_opengl_register_prims ();
	lime_vorbis_register_prims ();
	::foreach ndlls::::if (registerStatics)::
	::nameSafe::_register_prims ();::end::::end::

	const char *err = NULL;
	err = hxRunLibrary ();

	if (err) {

		printf ("Error %s\n", err);
		return -1;

	}

	return 0;

}