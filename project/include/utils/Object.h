#ifndef LIME_UTILS_OBJECT_H
#define LIME_UTILS_OBJECT_H


namespace lime {


	class Object {


		protected:

			virtual ~Object () {}

		public:

			Object (bool has_initial_ref = false) : ref_count (has_initial_ref ? 1 : 0) {}

			Object *grab () {

				ref_count++;

				return this;

			}

			Object *IncRef () {

				ref_count++;
				return this;

			}

			void DecRef () {

				ref_count--;

				if (ref_count <= 0) {

					delete this;

				}

			}

			void drop () {

				ref_count--;

				if (ref_count <= 0) {
					delete this;
				}

			}

			int ref_count;


	};


}


#endif