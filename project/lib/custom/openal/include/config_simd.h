#if defined(HX_MACOS) && defined(HXCPP_ARM64)

#include "simd/config_simd-macos-arm64.h"

#elif defined(HX_MACOS)

#include "simd/config_simd-macos-x86_64.h"

#elif defined(HX_WINDOWS)

#ifdef HXCPP_M64
#include "simd/config_simd-windows-x86_64.h"
#else
#include "simd/config_simd-windows-x86.h"
#endif

#elif defined(HX_LINUX)

#include "simd/config_simd-linux-x86_64.h"

#elif defined (HX_ANDROID)

#include "simd/config_simd-android.h"

#endif
