#ifndef LIME_GRAPHICS_OPENGL_OPENGL_SHARE_GROUPS_H
#define LIME_GRAPHICS_OPENGL_OPENGL_SHARE_GROUPS_H


#include <map>
#include <mutex>
#include <set>


namespace lime {


	// The OpenGL contexts Lime makes for its windows, by the group of contexts
	// that share their textures and other objects. A group lasts while one of
	// its contexts does, and its number is never given to another group, so an
	// object made in a group can be used while the group lasts, from any of its
	// contexts. Each context also has a number of its own, never given to
	// another, for the objects contexts don't share, such as framebuffers.
	class OpenGLShareGroups {

		public:

			// Records a context made sharing with shareWith, or with none
			static void Add (void* context, void* shareWith) {

				if (!context) return;

				State* state = GetState ();
				std::lock_guard<std::mutex> lock (state->mutex);
				Forget (state, context);

				int group = 0;
				std::map<void*, Entry>::iterator shared = shareWith ? state->contexts.find (shareWith) : state->contexts.end ();
				if (shared != state->contexts.end ()) group = shared->second.group;
				if (!group) group = state->next++;

				Entry entry;
				entry.group = group;
				entry.id = state->next++;
				state->contexts[context] = entry;
				state->ids.insert (entry.id);
				state->sizes[group]++;

			}

			// Whether the context with a number from GetContextId is still alive
			static bool ContextExists (int id) {

				if (!id) return false;

				State* state = GetState ();
				std::lock_guard<std::mutex> lock (state->mutex);
				return state->ids.find (id) != state->ids.end ();

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
				std::map<void*, Entry>::iterator found = state->contexts.find (context);
				return found != state->contexts.end () ? found->second.group : 0;

			}

			// The number of a context Lime made, or 0 for any other
			static int GetContextId (void* context) {

				if (!context) return 0;

				State* state = GetState ();
				std::lock_guard<std::mutex> lock (state->mutex);
				std::map<void*, Entry>::iterator found = state->contexts.find (context);
				return found != state->contexts.end () ? found->second.id : 0;

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

			struct Entry {

				int group;
				int id;

			};

			struct State {

				std::mutex mutex;
				std::map<void*, Entry> contexts;
				std::set<int> ids;
				std::map<int, int> sizes;
				int next;

				State () : next (1) {}

			};

			static void Forget (State* state, void* context) {

				std::map<void*, Entry>::iterator found = state->contexts.find (context);
				if (found == state->contexts.end ()) return;

				int group = found->second.group;
				state->ids.erase (found->second.id);
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
