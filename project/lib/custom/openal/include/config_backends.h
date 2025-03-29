#if defined(HX_MACOS) && defined(HXCPP_ARM64)

#include "backends/config_backends-macos-arm64.h"

#elif defined(HX_MACOS)

#include "backends/config_backends-macos-x86_64.h"

#elif defined(HX_WINDOWS)

#ifdef HXCPP_M64
#include "backends/config_backends-windows-x86_64.h"
#else
#include "backends/config_backends-windows-x86.h"
#endif

#elif defined(HX_LINUX)

#include "backends/config_backends-linux-x86_64.h"

#elif defined (HX_ANDROID)

#include "backends/config_backends-android.h"

#endif
