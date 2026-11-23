/* OpenAL Soft config_backends.h for Lime's hxcpp build.
 *
 * Written by hand from config_backends.h.in. Each backend enabled here must
 * have its source file listed for the same platform in openal-files.xml.
 */

/* Define to 1 if the given backend is enabled, else 0 */

#if defined(__linux__) && !defined(__ANDROID__)
#define HAVE_ALSA 1
#define HAVE_OSS 1
#define HAVE_PULSEAUDIO 1
#else
#define HAVE_ALSA 0
#define HAVE_OSS 0
#define HAVE_PULSEAUDIO 0
#endif

/* PipeWire needs libpipewire-0.3 headers at build time. PulseAudio covers
 * PipeWire systems through pipewire-pulse. */
#define HAVE_PIPEWIRE 0

#define HAVE_SOLARIS 0

#define HAVE_SNDIO 0

#if defined(_WIN32)
#define HAVE_WASAPI 1
#define HAVE_DSOUND 1
#define HAVE_WINMM 1
#else
#define HAVE_WASAPI 0
#define HAVE_DSOUND 0
#define HAVE_WINMM 0
#endif

#define HAVE_PORTAUDIO 0

#define HAVE_JACK 0

#if defined(__APPLE__)
#define HAVE_COREAUDIO 1
#else
#define HAVE_COREAUDIO 0
#endif

#if defined(__ANDROID__)
#define HAVE_OPENSL 1
#else
#define HAVE_OPENSL 0
#endif

/* Oboe needs the Oboe sources at build time. */
#define HAVE_OBOE 0

#define HAVE_WAVE 1

#define HAVE_SDL3 0

/* openal-files.xml passes -DHAVE_SDL2 when Lime builds with SDL. */
#ifndef HAVE_SDL2
#define HAVE_SDL2 0
#endif
