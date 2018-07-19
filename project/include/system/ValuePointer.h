#ifndef LIME_SYSTEM_VALUE_POINTER_H
#define LIME_SYSTEM_VALUE_POINTER_H


#include <system/CFFI.h>


namespace lime {


	class ValuePointer {


		public:

			ValuePointer (vobj* handle);
			ValuePointer (vdynamic* handle);
			ValuePointer (vclosure* handle);
			ValuePointer (value handle);
			~ValuePointer ();

			void* Call ();
			void* Call (void* arg0);
			void* Call (void* arg0, void* arg1);
			void* Call (void* arg0, void* arg1, void* arg2);
			void* Call (void* arg0, void* arg1, void* arg2, void* arg3);
			void* Call (void* arg0, void* arg1, void* arg2, void* arg3, void* arg4);
			void* Get () const;
			bool IsCFFIValue ();
			bool IsHLValue ();
			void Set (vobj* handle);
			void Set (value handle);

		private:

			gcroot cffiRoot;
			value* cffiValue;
			vobj* hlValue;

	};


}


#endif