#ifndef LIME_SYSTEM_DIRECTORY_WATCHER_H
#define LIME_SYSTEM_DIRECTORY_WATCHER_H

#include <hx/CFFI.h>
#include <map>
#include <string>


namespace lime {
	
	
	class DirectoryWatcher {
		
		
		public:
			
			DirectoryWatcher (value callback);
			~DirectoryWatcher ();
			
			unsigned long AddWatch (const std::string directory, bool recursive);
			void RemoveWatch (unsigned long watchID);
			void Update ();
			
			AutoGCRoot* callback;
		
		private:
			
			void* fileWatcher = 0;
			std::map<unsigned long, void*> watchListeners;
		
		
	};
	
	
}


#endif