#include <vm/NekoVM.h>
#include <stdio.h>
#include <neko_vm.h>


extern "C" { void std_main (); }


namespace lime {


	static void report( neko_vm *vm, value exc, int isexc ) {
		int i;
		buffer b = alloc_buffer(NULL);
		value st = neko_exc_stack(vm);
		for(i=0;i<val_array_size(st);i++) {
			value s = val_array_ptr(st)[i];
			buffer_append(b,"Called from ");
			if( val_is_null(s) )
				buffer_append(b,"a C function");
			else if( val_is_string(s) ) {
				buffer_append(b,val_string(s));
				buffer_append(b," (no debug available)");
			} else if( val_is_array(s) && val_array_size(s) == 2 && val_is_string(val_array_ptr(s)[0]) && val_is_int(val_array_ptr(s)[1]) ) {
				val_buffer(b,val_array_ptr(s)[0]);
				buffer_append(b," line ");
				val_buffer(b,val_array_ptr(s)[1]);
			} else
				val_buffer(b,s);
			buffer_append_char(b,'\n');
		}
		if( isexc )
			buffer_append(b,"Uncaught exception - ");
		val_buffer(b,exc);
	#	ifdef NEKO_STANDALONE
		neko_standalone_error(val_string(buffer_to_string(b)));
	#	else
		fprintf(stderr,"%s\n",val_string(buffer_to_string(b)));
	#	endif
	}


	void NekoVM::Execute (const char *modulePath) {

		neko_vm *vm;

		neko_global_init ();
		vm = neko_vm_alloc (NULL);
		neko_vm_select (vm);

		std_main ();

		value mload = neko_default_loader(NULL, 0);

		value args2[] = { alloc_string(modulePath), mload };
		value exc = NULL;

		val_callEx(mload,val_field(mload,val_id("loadmodule")),args2,2,&exc);

		if( exc != NULL ) {

			report(vm,exc,1);
			//return 1;
		}
		//return 0;

	}


}