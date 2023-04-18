// include order is important
#include <efsw/efsw.hpp>
#include <system/FileWatcher.h>


namespace lime {


	class UpdateListener : public efsw::FileWatchListener {

		public:

			UpdateListener (FileWatcher* _watcher) {

				watcher = _watcher;

			}

			void handleFileAction (efsw::WatchID watchid, const std::string& dir, const std::string& filename, efsw::Action action, std::string oldFilename = "") {

				FileWatcherEvent event = { watchid, std::string (dir.begin (), dir.end ()), std::string (filename.begin (), filename.end ()), action, oldFilename };
				watcher->QueueEvent (event);

			}

			FileWatcher* watcher;

	};


	FileWatcher::FileWatcher (value _callback) {

		callback = new AutoGCRoot (_callback);
		fileWatcher = new efsw::FileWatcher ();
		mutex = 0;

	}


	FileWatcher::~FileWatcher () {

		delete callback;
		delete (efsw::FileWatcher*)fileWatcher;

		if (mutex) {

			delete mutex;

		}

		std::map<long, void*>::iterator it;

		for (it = listeners.begin (); it != listeners.end (); it++) {

			delete (UpdateListener*)listeners[it->first];

		}

	}


	long FileWatcher::AddDirectory (std::string directory, bool recursive) {

		UpdateListener* listener = new UpdateListener (this);
		efsw::WatchID watchID = ((efsw::FileWatcher*)fileWatcher)->addWatch (directory, listener, true);

		if (watchID >= 0) {

			listeners[watchID] = listener;

			if (!mutex) {

				mutex = new Mutex ();
				((efsw::FileWatcher*)fileWatcher)->watch ();

			}

		}

		return watchID;

	}


	void FileWatcher::QueueEvent (FileWatcherEvent event) {

		mutex->Lock ();
		queue.push_back (event);
		mutex->Unlock ();

	}


	void FileWatcher::RemoveDirectory (long watchID) {

		((efsw::FileWatcher*)fileWatcher)->removeWatch (watchID);

		if (listeners.find (watchID) != listeners.end ()) {

			delete (UpdateListener*)listeners[watchID];
			listeners.erase (watchID);

		}

	}


	void FileWatcher::Update () {

		if (mutex) {

			mutex->Lock ();

			int size = queue.size ();

			if (size > 0) {

				FileWatcherEvent event;
				value _callback = callback->get ();

				for (int i = 0; i < size; i++) {

					event = queue[i];
					value args[4] = { alloc_string (event.dir.c_str ()), alloc_string (event.file.c_str ()), alloc_int (event.action), alloc_string (event.oldFile.c_str ()) };
					val_callN (_callback, args, 4);

				}

				queue.clear ();

			}

			mutex->Unlock ();

		}

	}


}