/* config.h.in.  Generated from configure.ac by autoheader.  */

/* Define if building universal (internal helper macro) */
/* #undef AC_APPLE_UNIVERSAL_BUILD */

/* Whether we have alarm() */
#ifdef HX_LINUX
#define HAVE_ALARM 1
#else
/* #undef HAVE_ALARM */
#endif

/* Whether the compiler supports __builtin_clz */
#if defined(HX_LINUX) || defined(HX_MACOS) || defined(HX_ANDROID)
#define HAVE_BUILTIN_CLZ /**/
#else
/* #undef HAVE_BUILTIN_CLZ */
#endif

/* Define to 1 if you have the <dlfcn.h> header file. */
#ifndef HX_WINDOWS
#define HAVE_DLFCN_H 1
#else
/* #undef HAVE_DLFCN_H */
#endif

/* Whether we have feenableexcept() */
#ifdef HX_LINUX
#define HAVE_FEENABLEEXCEPT 1
#else
/* #undef HAVE_FEENABLEEXCEPT */
#endif

/* Define to 1 if we have <fenv.h> */
#ifndef HX_WINDOWS
#define HAVE_FENV_H 1
#else
/* #undef HAVE_FENV_H */
#endif

/* Whether the tool chain supports __float128 */
#ifdef HX_LINUX
#define HAVE_FLOAT128 /**/
#else
/* #undef HAVE_FLOAT128 */
#endif

/* Whether the compiler supports GCC vector extensions */
#ifdef HX_LINUX
#define HAVE_GCC_VECTOR_EXTENSIONS /**/
#else
/* #undef HAVE_GCC_VECTOR_EXTENSIONS */
#endif

/* Define to 1 if you have the `getisax' function. */
/* #undef HAVE_GETISAX */

/* Whether we have getpagesize() */
#ifdef HX_LINUX
#define HAVE_GETPAGESIZE 1
#else
/* #undef HAVE_GETPAGESIZE */
#endif

/* Whether we have gettimeofday() */
#ifdef HX_LINUX
#define HAVE_GETTIMEOFDAY 1
#else
/* #undef HAVE_GETTIMEOFDAY */
#endif

/* Define to 1 if you have the <inttypes.h> header file. */
#ifndef HX_WINDOWS
#define HAVE_INTTYPES_H 1
#else
/* #undef HAVE_INTTYPES_H */
#endif

/* Define to 1 if you have the `pixman-1' library (-lpixman-1). */
/* #undef HAVE_LIBPIXMAN_1 */

/* Whether we have libpng */
#ifdef NATIVE_TOOLKIT_HAVE_PNG
#define HAVE_LIBPNG 1
#else
/* #undef HAVE_LIBPNG */
#endif

/* Define to 1 if you have the <memory.h> header file. */
#ifdef HX_LINUX
#define HAVE_MEMORY_H 1
#else
/* #undef HAVE_MEMORY_H */
#endif

/* Whether we have mmap() */
#ifdef HX_LINUX
#define HAVE_MMAP 1
#else
/* #undef HAVE_MMAP */
#endif

/* Whether we have mprotect() */
#ifdef HX_LINUX
#define HAVE_MPROTECT 1
#else
/* #undef HAVE_MPROTECT */
#endif

/* Whether we have posix_memalign() */
#ifdef HX_LINUX
#define HAVE_POSIX_MEMALIGN 1
#else
/* #undef HAVE_POSIX_MEMALIGN */
#endif

/* Whether pthreads is supported */
#ifndef HX_WINDOWS
#define HAVE_PTHREADS /**/
#else
/* #undef HAVE_PTHREADS */
#endif

/* Whether we have sigaction() */
#ifdef HX_LINUX
#define HAVE_SIGACTION 1
#else
/* #undef HAVE_SIGACTION */
#endif

/* Define to 1 if you have the <stdint.h> header file. */
#ifndef HX_WINDOWS
#define HAVE_STDINT_H 1
#else
/* #undef HAVE_STDINT_H */
#endif

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#ifndef HX_WINDOWS
#define HAVE_STRINGS_H 1
#else
/* #undef HAVE_STRINGS_H */
#endif

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if we have <sys/mman.h> */
#ifndef HX_WINDOWS
#define HAVE_SYS_MMAN_H 1
#else
/* #undef HAVE_SYS_MMAN_H */
#endif

/* Define to 1 if you have the <sys/stat.h> header file. */
#ifndef HX_WINDOWS
#define HAVE_SYS_STAT_H 1
#else
/* #undef HAVE_SYS_STAT_H */
#endif

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <unistd.h> header file. */
#ifndef HX_WINDOWS
#define HAVE_UNISTD_H 1
#else
/* #undef HAVE_UNISTD_H */
#endif

/* Define to the sub-directory in which libtool stores uninstalled libraries.
   */
/* #undef LT_OBJDIR */

/* Name of package */
#define PACKAGE "pixman"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "pixman@lists.freedesktop.org"

/* Define to the full name of this package. */
#define PACKAGE_NAME "pixman"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "pixman 0.32.8"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "pixman"

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION "0.32.8"

/* enable TIMER_BEGIN/TIMER_END macros */
/* #undef PIXMAN_TIMERS */

/* The size of `long', as computed by sizeof. */
#if (defined(HX_LINUX) && defined(HXCPP_M64)) || defined(HX_MACOS)
#define SIZEOF_LONG 8
#else
#define SIZEOF_LONG 4
#endif

/* Define to 1 if you have the ANSI C header files. */
#ifndef HX_WINDOWS
#define STDC_HEADERS 1
#else
/* #undef STDC_HEADERS */
#endif

/* The compiler supported TLS storage class */
#if !defined(HX_WINDOWS) && !defined(IPHONE)
#define TLS __thread
#else
/* #undef TLS */
#endif

/* Whether the tool chain supports __attribute__((constructor)) */
#ifdef __GNUC__
#define TOOLCHAIN_SUPPORTS_ATTRIBUTE_CONSTRUCTOR /**/
#else
/* #undef TOOLCHAIN_SUPPORTS_ATTRIBUTE_CONSTRUCTOR */
#endif

/* use ARM IWMMXT compiler intrinsics */
// #if !defined(HX_LINUX) && !defined(HX_MACOS) && !defined(HX_WINDOWS) && !defined(EMSCRIPTEN)
// #define USE_ARM_IWMMXT 1
// #else
/* #undef USE_ARM_IWMMXT */
// #endif

/* use ARM NEON assembly optimizations */
// #if defined(HXCPP_ARMV7) || defined(HXCPP_ARMV7S) || defined(HXCPP_ARM64)
// #define USE_ARM_NEON 1
// #else
/* #undef USE_ARM_NEON */
// #endif

/* use ARM SIMD assembly optimizations */
// #if defined(HXCPP_ARMV7) || defined(HXCPP_ARMV7S) || defined(HXCPP_ARM64)
// #define USE_ARM_SIMD 1
// #else
/* #undef USE_ARM_SIMD */
// #endif

/* use GNU-style inline assembler */
#ifdef __GNUC__
#define USE_GCC_INLINE_ASM 1
#else
/* #undef USE_GCC_INLINE_ASM */
#endif

/* use Loongson Multimedia Instructions */
/* #undef USE_LOONGSON_MMI */

/* use MIPS DSPr2 assembly optimizations */
/* #undef USE_MIPS_DSPR2 */

/* use OpenMP in the test suite */
/* #undef USE_OPENMP */

/* use SSE2 compiler intrinsics */
#if defined(HX_WINDOWS) || defined(HX_MACOS) || (defined(HX_LINUX) && !defined(RASPBERRYPI))
#define USE_SSE2 1
#else
/* #undef USE_SSE2 */
#endif

/* use SSSE3 compiler intrinsics */
#if defined(HX_WINDOWS) || defined(HX_MACOS) || (defined(HX_LINUX) && !defined(RASPBERRYPI))
#define USE_SSE3 1
#else
/* #undef USE_SSE3 */
#endif

/* use VMX compiler intrinsics */
/* #undef USE_VMX */

/* use x86 MMX compiler intrinsics */
#if (defined(HX_WINDOWS) || /*defined(HX_MACOS) ||*/ (defined(HX_LINUX) && !defined(RASPBERRYPI)) ) && !defined(HXCPP_M64)
#define USE_X86_MMX 1
#else
/* #undef USE_X86_MMX */
#endif

/* Version number of package */
#define VERSION "0.32.8"

/* Define WORDS_BIGENDIAN to 1 if your processor stores words with the most
   significant byte first (like Motorola and SPARC, unlike Intel). */
#if defined AC_APPLE_UNIVERSAL_BUILD
# if defined __BIG_ENDIAN__
#  define WORDS_BIGENDIAN 1
# endif
#else
# ifndef WORDS_BIGENDIAN
/* #  undef WORDS_BIGENDIAN */
# endif
#endif

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
/* #undef inline */
#endif

/* Define to sqrt if you do not have the `sqrtf' function. */
/* #undef sqrtf */
