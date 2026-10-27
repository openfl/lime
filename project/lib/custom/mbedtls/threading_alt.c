#include "mbedtls/threading.h"

#if defined(MBEDTLS_THREADING_ALT) && defined(_WIN32)

static void lime_mutex_init (mbedtls_threading_mutex_t* mutex) {

	if (mutex == NULL) return;
	InitializeCriticalSection (&mutex->cs);
	mutex->is_valid = 1;

}


static void lime_mutex_free (mbedtls_threading_mutex_t* mutex) {

	if (mutex == NULL || !mutex->is_valid) return;
	DeleteCriticalSection (&mutex->cs);
	mutex->is_valid = 0;

}


static int lime_mutex_lock (mbedtls_threading_mutex_t* mutex) {

	if (mutex == NULL || !mutex->is_valid) return MBEDTLS_ERR_THREADING_BAD_INPUT_DATA;
	EnterCriticalSection (&mutex->cs);
	return 0;

}


static int lime_mutex_unlock (mbedtls_threading_mutex_t* mutex) {

	if (mutex == NULL || !mutex->is_valid) return MBEDTLS_ERR_THREADING_BAD_INPUT_DATA;
	LeaveCriticalSection (&mutex->cs);
	return 0;

}


void lime_threading_init (void) {

	mbedtls_threading_set_alt (lime_mutex_init, lime_mutex_free, lime_mutex_lock, lime_mutex_unlock);

}

#endif
