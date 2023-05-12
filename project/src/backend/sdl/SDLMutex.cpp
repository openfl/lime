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


	bool Mutex::Lock () {

		if (mutex) {

			return SDL_LockMutex ((SDL_Mutex*)mutex) == 0;

		}

		return false;

	}


	bool Mutex::TryLock () {

		if (mutex) {

			return SDL_TryLockMutex ((SDL_Mutex*)mutex) == 0;

		}

		return false;

	}


	bool Mutex::Unlock () {

		if (mutex) {

			return SDL_UnlockMutex ((SDL_Mutex*)mutex) == 0;

		}

		return false;

	}


}