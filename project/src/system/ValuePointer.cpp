#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {


	ValuePointer::ValuePointer (value handle) {

		cffiRoot = 0;
		cffiValue = alloc_root ();

		if (cffiValue) {

			*cffiValue = handle;

		} else {

			cffiRoot = create_root (handle);

		}

		hlValue = 0;

	}


	ValuePointer::ValuePointer (vobj* handle) {

		hlValue = handle;
		hl_add_root (&hlValue);

		cffiRoot = 0;
		cffiValue = 0;

	}


	ValuePointer::ValuePointer (vdynamic* handle) {

		hlValue = (vobj*)handle;
		hl_add_root (&hlValue);

		cffiRoot = 0;
		cffiValue = 0;

	}


	ValuePointer::ValuePointer (vclosure* callback) {

		hlValue = (vobj*)callback;
		hl_add_root (&hlValue);

		cffiRoot = 0;
		cffiValue = 0;

	}


	ValuePointer::~ValuePointer () {

		if (cffiValue) {

			free_root (cffiValue);

		} else if (cffiRoot) {

			destroy_root (cffiRoot);

		} else if (hlValue) {

			hl_remove_root (&hlValue);

		}

	}


	void* ValuePointer::Call () {

		if (!hlValue) {

			return val_call0 ((value)Get ());

		} else {

			return hl_dyn_call ((vclosure*)hlValue, 0, 0);

		}

	}


	void* ValuePointer::Call (void* arg0) {

		if (!hlValue) {

			return val_call1 ((value)Get (), (value)arg0);

		} else {

			vdynamic* arg = (vdynamic*) arg0;
			return hl_dyn_call ((vclosure*)hlValue, &arg, 1);

		}

	}


	void* ValuePointer::Call (void* arg0, void* arg1) {

		if (!hlValue) {

			return val_call2 ((value)Get (), (value)arg0, (value)arg1);

		} else {

			vdynamic* args[] = {
				(vdynamic*)arg0,
				(vdynamic*)arg1,
			};

			return hl_dyn_call ((vclosure*)hlValue, (vdynamic**)&args, 2);

		}

	}


	void* ValuePointer::Call (void* arg0, void* arg1, void* arg2) {

		if (!hlValue) {

			return val_call3 ((value)Get (), (value)arg0, (value)arg1, (value)arg2);

		} else {

			vdynamic* args[] = {
				(vdynamic*)arg0,
				(vdynamic*)arg1,
				(vdynamic*)arg2,
			};

			return hl_dyn_call ((vclosure*)hlValue, (vdynamic**)&args, 3);

		}

	}


	void* ValuePointer::Call (void* arg0, void* arg1, void* arg2, void* arg3) {

		if (!hlValue) {

			value vals[] = {
				(value)arg0,
				(value)arg1,
				(value)arg2,
				(value)arg3,
			};

			return val_callN ((value)Get (), vals, 4);

		} else {

			vdynamic* args[] = {
				(vdynamic*)arg0,
				(vdynamic*)arg1,
				(vdynamic*)arg2,
				(vdynamic*)arg3,
			};

			return hl_dyn_call ((vclosure*)hlValue, (vdynamic**)&args, 4);

		}

	}


	void* ValuePointer::Call (void* arg0, void* arg1, void* arg2, void* arg3, void* arg4) {

		if (!hlValue) {

			value vals[] = {
				(value)arg0,
				(value)arg1,
				(value)arg2,
				(value)arg3,
				(value)arg4,
			};

			return val_callN ((value)Get (), vals, 5);

		} else {

			vdynamic* args[] = {
				(vdynamic*)arg0,
				(vdynamic*)arg1,
				(vdynamic*)arg2,
				(vdynamic*)arg3,
				(vdynamic*)arg4,
			};

			return hl_dyn_call ((vclosure*)hlValue, (vdynamic**)&args, 5);

		}

	}


	void* ValuePointer::Get () const {

		if (cffiValue) {

			return *cffiValue;

		} else if (cffiRoot) {

			return query_root (cffiRoot);

		} else if (hlValue) {

			return hlValue;

		}

		return 0;

	}


	bool ValuePointer::IsCFFIValue () {

		return hlValue == 0;

	}


	bool ValuePointer::IsHLValue () {

		return hlValue != 0;

	}


	void ValuePointer::Set (value handle) {

		if (cffiValue) {

			*cffiValue = handle;

		} else {

			if (cffiRoot) destroy_root (cffiRoot);
			cffiRoot = create_root (handle);

		}

	}


	void ValuePointer::Set (vobj* handle) {

		hlValue = handle;

	}


}