/* OpenAL Soft config_simd.h for Lime's hxcpp build.
 *
 * Written by hand from config_simd.h.in. The SIMD mixers are compiled through
 * the wrappers in custom/openal/simd, which use these same values, so the
 * mixer sources and these flags can't disagree on any target.
 */

/* Define to 1 if we have SSE CPU extensions, else 0 */
#if defined(__i386__) || defined(__x86_64__) || defined(_M_IX86) || (defined(_M_X64) && !defined(_M_ARM64EC))
#define HAVE_SSE 1
#define HAVE_SSE2 1
#define HAVE_SSE3 1
#define HAVE_SSE4_1 1

#define HAVE_SSE_INTRINSICS 1
#else
#define HAVE_SSE 0
#define HAVE_SSE2 0
#define HAVE_SSE3 0
#define HAVE_SSE4_1 0

#define HAVE_SSE_INTRINSICS 0
#endif

/* Define to 1 if we have ARM Neon CPU extensions, else 0 */
#if defined(__ARM_NEON) || defined(__ARM_NEON__) || defined(_M_ARM64) || defined(_M_ARM64EC)
#define HAVE_NEON 1
#else
#define HAVE_NEON 0
#endif
