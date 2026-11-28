// Compiles OpenAL Soft's core/mixer/mixer_sse2.cpp only when config_simd.h
// enables HAVE_SSE2 for the target, so Lime's build files don't need per-arch
// conditions that could disagree with config_simd.h.
#include "config_simd.h"

#if HAVE_SSE2
#include "core/mixer/mixer_sse2.cpp"
#endif
