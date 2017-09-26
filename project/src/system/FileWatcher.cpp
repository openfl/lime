#include <system/FileWatcher.h>
#include <FileWatcher/FileWatcher.h>


namespace lime {
	
	
	class UpdateListener : public FW::FileWatchListener {
		
		public:
			
			UpdateListener (FileWatcher* _watcher) {
				
				watcher = _watcher;
				
			}
			
			void handleFileAction (FW::WatchID watchid, const FW::String& dir, const FW::String& filename, FW::Action action) {
				
				value callback = watcher->callback->get ();
				val_call3 (callback, alloc_string (dir.c_str ()), alloc_string (filename.c_str ()), alloc_int (action));
				
			}
			
			FileWatcher* watcher;
		
	};
	
	
	FileWatcher::FileWatcher (value _callback) {
		
		callback = new AutoGCRoot (_callback);
		fileWatcher = new FW::FileWatcher ();
		
	}
	
	
	FileWatcher::~FileWatcher () {
		
		delete callback;
		delete fileWatcher;
		
		std::map<unsigned long, void*>::iterator it;
		
		for (it = watchListeners.begin (); it != watchListeners.end (); it++) {
			
			delete (UpdateListener*)watchListeners[it->first];
			
		}
		
	}
	
	
	unsigned long FileWatcher::AddDirectory (std::string directory, bool recursive) {
		
		UpdateListener* listener = new UpdateListener (this);
		FW::WatchID watchID = ((FW::FileWatcher*)fileWatcher)->addWatch (directory, listener, true);
		watchListeners[watchID] = listener;
		return watchID;
		
	}
	
	
	void FileWatcher::RemoveDirectory (unsigned long watchID) {
		
		((FW::FileWatcher*)fileWatcher)->removeWatch (watchID);
		
		if (watchListeners.find (watchID) != watchListeners.end ()) {
			
			delete (UpdateListener*)watchListeners[watchID];
			watchListeners.erase (watchID);
			
		}
		
	}
	
	
	void FileWatcher::Update () {
		
		((FW::FileWatcher*)fileWatcher)->update ();
		
	}
	
	
}