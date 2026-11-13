// Compiles OpenAL Soft's core/mixer/mixer_neon.cpp only when config_simd.h
// enables HAVE_NEON for the target, so Lime's build files don't need per-arch
// conditions that could disagree with config_simd.h.
#include "config_simd.h"

#if HAVE_NEON
#include "core/mixer/mixer_neon.cpp"
#endif
