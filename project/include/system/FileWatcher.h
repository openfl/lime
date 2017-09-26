#ifndef LIME_SYSTEM_FILE_WATCHER_H
#define LIME_SYSTEM_FILE_WATCHER_H

#ifdef RemoveDirectory
#undef RemoveDirectory
#endif

#include <hx/CFFI.h>
#include <map>
#include <string>


namespace lime {
	
	
	class FileWatcher {
		
		
		public:
			
			FileWatcher (value callback);
			~FileWatcher ();
			
			unsigned long AddDirectory (const std::string directory, bool recursive);
			void RemoveDirectory (unsigned long watchID);
			void Update ();
			
			AutoGCRoot* callback;
		
		private:
			
			void* fileWatcher = 0;
			std::map<unsigned long, void*> watchListeners;
		
		
	};
	
	
}


#endif