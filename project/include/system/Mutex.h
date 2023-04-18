#ifndef LIME_SYSTEM_MUTEX_H
#define LIME_SYSTEM_MUTEX_H


namespace lime {


	class Mutex {


		public:

			Mutex ();
			~Mutex ();

			bool Lock ();
			bool TryLock ();
			bool Unlock ();

		private:

			void* mutex;


	};


}


#endif