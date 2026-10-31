#include <system/System.h>

#if defined (HX_WINDOWS) || defined (_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <bcrypt.h>
#elif defined (__APPLE__) || defined (__FreeBSD__) || defined (__OpenBSD__) || defined (__NetBSD__)
#include <stdlib.h>
#else
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#if defined (__linux__) || defined (ANDROID)
#include <sys/syscall.h>
#endif
#endif


namespace lime {


	// Bytes from the platform's cryptographically secure source, for what
	// must not be guessed, such as a WebSocket client's masks and key
	bool System::GetSecureRandomBytes (unsigned char* data, int length) {

		if (length <= 0) return true;
		if (!data) return false;

		#if defined (HX_WINDOWS) || defined (_WIN32)

		return BCryptGenRandom (NULL, data, (ULONG)length, BCRYPT_USE_SYSTEM_PREFERRED_RNG) >= 0;

		#elif defined (__APPLE__) || defined (__FreeBSD__) || defined (__OpenBSD__) || defined (__NetBSD__)

		arc4random_buf (data, (size_t)length);
		return true;

		#else

		int filled = 0;

		#if (defined (__linux__) || defined (ANDROID)) && defined (SYS_getrandom)
		// getrandom where the kernel has it, which needs no descriptor and
		// waits only until the pool is first seeded
		while (filled < length) {

			long result = syscall (SYS_getrandom, data + filled, (size_t)(length - filled), 0);

			if (result > 0) {

				filled += (int)result;

			} else if (result < 0 && errno == EINTR) {

				continue;

			} else {

				break;

			}

		}

		if (filled == length) return true;
		#endif

		int file = open ("/dev/urandom", O_RDONLY);
		if (file < 0) return false;

		while (filled < length) {

			ssize_t result = read (file, data + filled, (size_t)(length - filled));

			if (result > 0) {

				filled += (int)result;

			} else if (result < 0 && errno == EINTR) {

				continue;

			} else {

				break;

			}

		}

		close (file);
		return filled == length;

		#endif

	}


}
