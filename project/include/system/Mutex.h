#ifndef LIME_SYSTEM_MUTEX_H
#define LIME_SYSTEM_MUTEX_H


namespace lime {


	class Mutex {


		public:

			Mutex ();
			~Mutex ();

			bool Lock () const;
			bool TryLock () const;
			bool Unlock () const;

		private:

			void* mutex;


	};


}


#endif
