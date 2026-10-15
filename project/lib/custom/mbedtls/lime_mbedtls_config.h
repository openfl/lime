#include "lime_mbedtls_prefix.h"

#define MBEDTLS_THREADING_C

#ifdef _WIN32
#define MBEDTLS_THREADING_ALT
#else
#define MBEDTLS_THREADING_PTHREAD
#endif
