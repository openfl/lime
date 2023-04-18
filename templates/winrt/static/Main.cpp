#include <stdbool.h>

#define DECLSPEC __declspec(dllexport)
#define SDLCALL __cdecl
#ifdef _MSC_VER
#pragma warning(disable:4103)
#pragma warning(disable:4447)
#endif
#pragma pack(push,8)
extern "C" {
extern DECLSPEC int SDLCALL SDL_WinRTRunApp(int (*mainFunction)(int, char **), void * reserved);
}
#pragma pack(pop)

#include <hxcpp.h>
#include <wrl.h>

#ifdef main
#undef main
#endif
#ifndef __WINRT__
#define __WINRT__
#endif
#ifndef SDL_BUILDING_WINRT
#define SDL_BUILDING_WINRT 1
#endif

#define LIME_SDL
#define LIME_OPENGL
#define LIME_CAIRO
#define NATIVE_TOOLKIT_SDL_ANGLE

#ifndef SDL_WINRT_METADATA_FILE_AVAILABLE
#ifndef __cplusplus_winrt
#error Main.cpp must be compiled with /ZW, otherwise build errors due to missing .winmd files can occur.
#endif
#endif

#ifdef _MSC_VER
#pragma comment(lib, "runtimeobject.lib")
#endif

#define DEBUG_PRINTF
#ifdef DEBUG_PRINTF
# ifdef UNICODE
#  define DLOG(fmt, ...) {wchar_t buf[1024];swprintf(buf,L"****LOG: %s(%d): %s \n    [" fmt "]\n",__FILE__,__LINE__,__FUNCTION__, __VA_ARGS__);OutputDebugString(buf);}
# else
#  define DLOG(fmt, ...) {char buf[1024];sprintf(buf,"****LOG: %s(%d): %s \n    [" fmt "]\n",__FILE__,__LINE__,__FUNCTION__, __VA_ARGS__);OutputDebugString(buf);}
# endif
#else
# define DLOG(fmt, ...) {}
#endif

extern "C" const char *hxRunLibrary ();
extern "C" void hxcpp_set_top_of_stack ();
extern "C" int zlib_register_prims ();
extern "C" int lime_cairo_register_prims ();
::foreach ndlls::::if (registerStatics)::
extern "C" int ::nameSafe::_register_prims ();::end::::end::

										
int _main(int argc, char *argv[])
{
   //DLOG("HELLO WORLD");
   //Sleep(10000);  //uncomment to attach here in debugger
   //DLOG("HELLO WORLD2");

   try
   {
        hxcpp_set_top_of_stack ();  
        zlib_register_prims ();
        lime_cairo_register_prims ();
        ::foreach ndlls::::if (registerStatics)::
        ::nameSafe::_register_prims ();::end::::end::
        
        const char *err = NULL;
        err = hxRunLibrary ();
        if (err) {            
            DLOG("Error: %s\n", err);
        }
   }
   catch (Dynamic e)
   {
       DLOG("Main Error\n",);
//      __hx_dump_stack();
       return -1;
   }
   return 0;
}

int CALLBACK WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{ 
   SDL_WinRTRunApp(_main, NULL);
   return 0;
}

