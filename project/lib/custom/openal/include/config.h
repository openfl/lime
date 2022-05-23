#ifdef HX_MACOS

#include "config-macos-x86_64.h"

#elif defined(HX_WINDOWS)

#ifdef HXCPP_M64
#include "config-windows-x86_64.h"
#else
#include "config-windows-x86.h"
#endif

#elif defined(HX_LINUX)

#include "config-linux-x86_64.h"

#elif defined (HX_ANDROID)

#include "config-android.h"

#endif
