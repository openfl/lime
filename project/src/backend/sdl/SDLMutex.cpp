#include <system/Mutex.h>
#include <SDL.h>


namespace lime {


	Mutex::Mutex () {

		mutex = SDL_CreateMutex ();

	}


	Mutex::~Mutex () {

		if (mutex) {

			SDL_DestroyMutex ((SDL_mutex*)mutex);

		}

	}


	bool Mutex::Lock () const {

		if (mutex) {

			return SDL_LockMutex ((SDL_mutex*)mutex) == 0;

		}

		return false;

	}


	bool Mutex::TryLock () const {

		if (mutex) {

			return SDL_TryLockMutex ((SDL_mutex*)mutex) == 0;

		}

		return false;

	}


	bool Mutex::Unlock () const {

		if (mutex) {

			return SDL_UnlockMutex ((SDL_mutex*)mutex) == 0;

		}

		return false;

	}


}
