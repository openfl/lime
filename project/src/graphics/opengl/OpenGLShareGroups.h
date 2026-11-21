#ifndef LIME_GRAPHICS_OPENGL_OPENGL_SHARE_GROUPS_H
#define LIME_GRAPHICS_OPENGL_OPENGL_SHARE_GROUPS_H


#include <map>
#include <mutex>


namespace lime {


	// The OpenGL contexts Lime makes for its windows, by the group of contexts
	// that share their textures and other objects. A group lasts while one of
	// its contexts does, and its number is never given to another group, so an
	// object made in a group can be used while the group lasts, from any of its
	// contexts.
	class OpenGLShareGroups {

		public:

			// Records a context made sharing with shareWith, or with none
			static void Add (void* context, void* shareWith) {

				if (!context) return;

				State* state = GetState ();
				std::lock_guard<std::mutex> lock (state->mutex);
				Forget (state, context);

				int group = 0;
				std::map<void*, int>::iterator shared = shareWith ? state->contexts.find (shareWith) : state->contexts.end ();
				if (shared != state->contexts.end ()) group = shared->second;
				if (!group) group = state->next++;

				state->contexts[context] = group;
				state->sizes[group]++;

			}

			// Whether a group still has a context
			static bool Exists (int group) {

				if (!group) return false;

				State* state = GetState ();
				std::lock_guard<std::mutex> lock (state->mutex);
				return state->sizes.find (group) != state->sizes.end ();

			}

			// The group of a context Lime made, or 0 for any other
			static int Get (void* context) {

				if (!context) return 0;

				State* state = GetState ();
				std::lock_guard<std::mutex> lock (state->mutex);
				std::map<void*, int>::iterator found = state->contexts.find (context);
				return found != state->contexts.end () ? found->second : 0;

			}

			// Records that a context is about to be deleted
			static void Remove (void* context) {

				if (!context) return;

				State* state = GetState ();
				std::lock_guard<std::mutex> lock (state->mutex);
				Forget (state, context);

			}

			// Whether an object made with context, in group, can be used where
			// current is current: in the same group, or, for contexts Lime did
			// not make, in the same context
			static bool Shares (void* context, int group, void* current) {

				if (!current) return false;

				int currentGroup = Get (current);
				if (group || currentGroup) return group == currentGroup;
				return context == current;

			}

		private:

			struct State {

				std::mutex mutex;
				std::map<void*, int> contexts;
				std::map<int, int> sizes;
				int next;

				State () : next (1) {}

			};

			static void Forget (State* state, void* context) {

				std::map<void*, int>::iterator found = state->contexts.find (context);
				if (found == state->contexts.end ()) return;

				int group = found->second;
				state->contexts.erase (found);
				if (--state->sizes[group] <= 0) state->sizes.erase (group);

			}

			// Never destroyed, as threads can still be closing videos while
			// static destructors run
			static State* GetState () {

				static State* state = new State ();
				return state;

			}

	};


}


#endif
