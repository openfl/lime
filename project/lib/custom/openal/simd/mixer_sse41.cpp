// Compiles OpenAL Soft's core/mixer/mixer_sse41.cpp only when config_simd.h
// enables HAVE_SSE4_1 for the target, so Lime's build files don't need per-arch
// conditions that could disagree with config_simd.h.
#include "config_simd.h"

#if HAVE_SSE4_1
#include "core/mixer/mixer_sse41.cpp"
#endif
