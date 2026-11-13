/* OpenAL Soft config.h for Lime's hxcpp build.
 *
 * OpenAL Soft's CMake build writes this from config.h.in. Lime compiles the
 * sources with hxcpp instead, so the values are picked here from compiler
 * macros. Keep this in sync with config.h.in when updating the submodule.
 */

/* Symbol visibility for the AL and ALC entry points. Upstream passes these on
 * the command line. Every source that defines an entry point includes this
 * file first, before AL/al.h. */
#ifndef AL_API
#if defined(_WIN32)
#define AL_API __declspec(dllexport)
#define ALC_API __declspec(dllexport)
#else
#define AL_API __attribute__((visibility("default")))
#define ALC_API __attribute__((visibility("default")))
#endif
#endif

/* Define the alignment attribute for externally callable functions. */
#if defined(__GNUC__) && defined(__i386__)
#define FORCE_ALIGN __attribute__((force_align_arg_pointer))
#else
#define FORCE_ALIGN
#endif

/* Define if HRTF data is embedded in the library */
#define ALSOFT_EMBED_HRTF_DATA

/* Define if we have the proc_pidpath function */
#if defined(__APPLE__)
#define HAVE_PROC_PIDPATH
#endif

/* Define if we have dlfcn.h */
#if !defined(_WIN32)
#define HAVE_DLFCN_H
#endif

/* Define if we have pthread_np.h */
/* #undef HAVE_PTHREAD_NP_H */

#if defined(__i386__) || defined(__x86_64__) || defined(_M_IX86) || (defined(_M_X64) && !defined(_M_ARM64EC))
#if defined(__GNUC__)
/* Define if we have cpuid.h */
#define HAVE_CPUID_H
/* Define if we have GCC's __get_cpuid() */
#define HAVE_GCC_GET_CPUID
#elif defined(_MSC_VER)
/* Define if we have the __cpuid() intrinsic */
#define HAVE_CPUID_INTRINSIC
#endif
#endif

#if defined(_WIN32)
/* Define if we have intrin.h */
#define HAVE_INTRIN_H
/* Define if we have guiddef.h */
#define HAVE_GUIDDEF_H
#else
/* Define if we have pthread_setschedparam() */
#define HAVE_PTHREAD_SETSCHEDPARAM
/* Define if we have pthread_setname_np() */
#define HAVE_PTHREAD_SETNAME_NP
#endif

/* Define if we have pthread_set_name_np() */
/* #undef HAVE_PTHREAD_SET_NAME_NP */

/* Define the installation data directory */
/* #undef ALSOFT_INSTALL_DATADIR */

/* Define if the compiler supports ELF notes */
/* #undef HAVE_DLOPEN_NOTES */

/* Define to 1 if we have C++20 modules, else 0 */
#define HAVE_CXXMODULES 0

/* Define to 1 to enable dynamic loading of optional libs, else 0 */
#define HAVE_DYNLOAD 1

/* Define to 1 if we have DBus/RTKit, else 0 */
#define HAVE_RTKIT 0

/* Define to 1 if building for winuwp, else 0 */
#define ALSOFT_UWP 0

/* Define to 1 if building with legacy EAX API support, else 0. Upstream
 * enables it on Windows by default. Lime has no EAX bindings, so it is left
 * out to keep lime.ndll smaller. */
#define ALSOFT_EAX 0
