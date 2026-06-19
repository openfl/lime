#include <system/Mutex.h>
#include <SDL3/SDL.h>


namespace lime {


	Mutex::Mutex () {

		mutex = SDL_CreateMutex ();

	}


	Mutex::~Mutex () {

		if (mutex) {

			SDL_DestroyMutex ((SDL_Mutex*)mutex);

		}

	}


	bool Mutex::Lock () const {

		if (mutex) {

			SDL_LockMutex ((SDL_Mutex*)mutex);
			return true;

		}

		return false;

	}


	bool Mutex::TryLock () const {

		if (mutex) {

			return SDL_TryLockMutex ((SDL_Mutex*)mutex);

		}

		return false;

	}


	bool Mutex::Unlock () const {

		if (mutex) {

			SDL_UnlockMutex ((SDL_Mutex*)mutex);
			return true;

		}

		return false;

	}


}
