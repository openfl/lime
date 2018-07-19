#ifndef LIME_SYSTEM_FILE_WATCHER_H
#define LIME_SYSTEM_FILE_WATCHER_H

#ifdef RemoveDirectory
#undef RemoveDirectory
#endif

#include <system/CFFI.h>
#include <system/Mutex.h>
#include <map>
#include <string>
#include <vector>


namespace lime {


	struct FileWatcherEvent {

		long watchID;
		std::string dir;
		std::string file;
		int action;
		std::string oldFile;

	};


	class FileWatcher {


		public:

			FileWatcher (value callback);
			~FileWatcher ();

			long AddDirectory (const std::string directory, bool recursive);
			void QueueEvent (FileWatcherEvent event);
			void RemoveDirectory (long watchID);
			void Update ();


		private:

			AutoGCRoot* callback;
			void* fileWatcher;
			Mutex* mutex;
			std::vector<FileWatcherEvent> queue;
			std::map<long, void*> listeners;


	};


}


#endif