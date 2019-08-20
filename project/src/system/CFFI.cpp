#include <system/CFFI.h>


#ifndef LIME_HASHLINK

HL_API int hl_type_size( hl_type *t ) { return 0; }
HL_API int hl_pad_struct( int size, hl_type *t ) { return 0; }

HL_API hl_runtime_obj *hl_get_obj_rt( hl_type *ot ) { return NULL; }
HL_API hl_runtime_obj *hl_get_obj_proto( hl_type *ot ) { return NULL; }
HL_API void hl_flush_proto( hl_type *ot ) {}
HL_API void hl_init_enum( hl_type *et, hl_module_context *m ) {}

hl_type hlt_void = hl_type ();
hl_type hlt_i32 = hl_type ();
hl_type hlt_i64 = hl_type ();
hl_type hlt_f64 = hl_type ();
hl_type hlt_f32 = hl_type ();
hl_type hlt_dyn = hl_type ();
hl_type hlt_array = hl_type ();
hl_type hlt_bytes = hl_type ();
hl_type hlt_dynobj = hl_type ();
hl_type hlt_bool = hl_type ();
hl_type hlt_abstract = hl_type ();

HL_API double hl_nan( void ) { return 0; }
HL_API bool hl_is_dynamic( hl_type *t ) { return false; }
HL_API bool hl_same_type( hl_type *a, hl_type *b ) { return false; }
HL_API bool hl_safe_cast( hl_type *t, hl_type *to ) { return false; }

HL_API varray *hl_alloc_array( hl_type *t, int size ) { return NULL; }
HL_API vdynamic *hl_alloc_dynamic( hl_type *t ) { return NULL; }
HL_API vdynamic *hl_alloc_dynbool( bool b ) { return NULL; }
HL_API vdynamic *hl_alloc_obj( hl_type *t ) { return NULL; }
HL_API venum *hl_alloc_enum( hl_type *t, int index ) { return NULL; }
HL_API vvirtual *hl_alloc_virtual( hl_type *t ) { return NULL; }
HL_API vdynobj *hl_alloc_dynobj( void ) { return 0; }
HL_API vbyte *hl_alloc_bytes( int size ) { return NULL; }
HL_API vbyte *hl_copy_bytes( const vbyte *byte, int size ) { return NULL; }
HL_API int hl_utf8_length( const vbyte *s, int pos ) { return 0; }
HL_API int hl_from_utf8( uchar *out, int outLen, const char *str ) { return 0; }
HL_API char *hl_to_utf8( const uchar *bytes ) { return 0; }
HL_API uchar *hl_to_utf16( const char *str ) { return NULL; }
HL_API vdynamic *hl_virtual_make_value( vvirtual *v ) { return NULL; }
HL_API hl_obj_field *hl_obj_field_fetch( hl_type *t, int fid ) { return NULL; }

HL_API int hl_hash( vbyte *name ) { return 0; }
HL_API int hl_hash_utf8 ( const char *str ) { return 0; } // no cache
HL_API int hl_hash_gen( const uchar *name, bool cache_name ) { return 0; }
HL_API vbyte *hl_field_name( int hash ) { return NULL; }

HL_API void hl_error_msg( const uchar *msg, ... ) {}
HL_API void hl_assert( void ) {}
HL_API void hl_throw( vdynamic *v ) { throw ""; }
HL_API void hl_rethrow( vdynamic *v ) { throw ""; }
HL_API void hl_setup_longjump( void *j ) {}
HL_API void hl_setup_exception( void *resolve_symbol, void *capture_stack ) {}
HL_API void hl_dump_stack( void ) {}
HL_API varray *hl_exception_stack( void ) { return NULL; }
HL_API bool hl_detect_debugger( void ) { return false; }

HL_API vvirtual *hl_to_virtual( hl_type *vt, vdynamic *obj ) { return NULL; }
HL_API void hl_init_virtual( hl_type *vt, hl_module_context *ctx ) {}
HL_API hl_field_lookup *hl_lookup_find( hl_field_lookup *l, int size, int hash ) { return NULL; }
HL_API hl_field_lookup *hl_lookup_insert( hl_field_lookup *l, int size, int hash, hl_type *t, int index ) { return NULL; }

HL_API int hl_dyn_geti( vdynamic *d, int hfield, hl_type *t ) { return 0; }
HL_API void *hl_dyn_getp( vdynamic *d, int hfield, hl_type *t ) { return NULL; }
HL_API float hl_dyn_getf( vdynamic *d, int hfield ) { return 0; }
HL_API double hl_dyn_getd( vdynamic *d, int hfield ) { return 0; }

HL_API int hl_dyn_casti( void *data, hl_type *t, hl_type *to ) { return 0; }
HL_API void *hl_dyn_castp( void *data, hl_type *t, hl_type *to ) { return NULL; }
HL_API float hl_dyn_castf( void *data, hl_type *t ) { return 0; }
HL_API double hl_dyn_castd( void *data, hl_type *t ) { return 0; }

HL_API int hl_dyn_compare( vdynamic *a, vdynamic *b ) { return 0; }
HL_API vdynamic *hl_make_dyn( void *data, hl_type *t ) { return NULL; }
HL_API void hl_write_dyn( void *data, hl_type *t, vdynamic *v, bool is_tmp ) {}

HL_API void hl_dyn_seti( vdynamic *d, int hfield, hl_type *t, int value ) {}
HL_API void hl_dyn_setp( vdynamic *d, int hfield, hl_type *t, void *ptr ) {}
HL_API void hl_dyn_setf( vdynamic *d, int hfield, float f ) {}
HL_API void hl_dyn_setd( vdynamic *d, int hfield, double v ) {}

HL_API vdynamic *hl_dyn_op( int op, vdynamic *a, vdynamic *b ) { return NULL; }

HL_API vclosure *hl_alloc_closure_void( hl_type *t, void *fvalue ) { return NULL; }
HL_API vclosure *hl_alloc_closure_ptr( hl_type *fullt, void *fvalue, void *ptr ) { return NULL; }
HL_API vclosure *hl_make_fun_wrapper( vclosure *c, hl_type *to ) { return NULL; }
HL_API void *hl_wrapper_call( void *value, void **args, vdynamic *ret ) { return NULL; }
HL_API void *hl_dyn_call_obj( vdynamic *obj, hl_type *ft, int hfield, void **args, vdynamic *ret ) { return NULL; }
HL_API vdynamic *hl_dyn_call( vclosure *c, vdynamic **args, int nargs ) { return 0; }
HL_API vdynamic *hl_dyn_call_safe( vclosure *c, vdynamic **args, int nargs, bool *isException ) { return NULL; }

HL_API hl_thread *hl_thread_start( void *callback, void *param, bool withGC ) { return NULL; }
HL_API hl_thread *hl_thread_current( void ) { return NULL; }
HL_API void hl_thread_yield(void) {}
HL_API void hl_register_thread( void *stack_top ) {}
HL_API void hl_unregister_thread( void ) {}

HL_API hl_mutex *hl_mutex_alloc( bool gc_thread ) { return NULL; }
HL_API void hl_mutex_acquire( hl_mutex *l ) {}
HL_API bool hl_mutex_try_acquire( hl_mutex *l ) { return false; }
HL_API void hl_mutex_release( hl_mutex *l ) {}
HL_API void hl_mutex_free( hl_mutex *l ) {}

HL_API hl_tls *hl_tls_alloc( bool gc_value ) { return NULL; }
HL_API void hl_tls_set( hl_tls *l, void *value ) {}
HL_API void *hl_tls_get( hl_tls *l );
HL_API void hl_tls_free( hl_tls *l ) {}

HL_API void *hl_gc_alloc_gen( hl_type *t, int size, int flags ) { return 0; }
HL_API void hl_add_root( void *ptr ) {}
HL_API void hl_remove_root( void *ptr ) {}
HL_API void hl_gc_major( void ) {}
HL_API bool hl_is_gc_ptr( void *ptr ) { return false; }

HL_API void hl_blocking( bool b ) {}
HL_API bool hl_is_blocking( void ) { return false; }

HL_API void hl_gc_set_dump_types( hl_types_dump tdump ) {}

HL_API void hl_alloc_init( hl_alloc *a ) {}
HL_API void *hl_malloc( hl_alloc *a, int size ) { return NULL; }
HL_API void *hl_zalloc( hl_alloc *a, int size ) { return NULL; }
HL_API void hl_free( hl_alloc *a ) {}

HL_API void hl_global_init( void ) {}
HL_API void hl_global_free( void ) {}

HL_API void *hl_alloc_executable_memory( int size ) { return NULL; }
HL_API void hl_free_executable_memory( void *ptr, int size ) {}

HL_API hl_buffer *hl_alloc_buffer( void ) { return NULL; }
HL_API void hl_buffer_val( hl_buffer *b, vdynamic *v ) {}
HL_API void hl_buffer_char( hl_buffer *b, uchar c ) {}
HL_API void hl_buffer_str( hl_buffer *b, const uchar *str ) {}
HL_API void hl_buffer_cstr( hl_buffer *b, const char *str ) {}
HL_API void hl_buffer_str_sub( hl_buffer *b, const uchar *str, int len ) {}
HL_API int hl_buffer_length( hl_buffer *b ) { return 0; }
HL_API uchar *hl_buffer_content( hl_buffer *b, int *len ) { return NULL; }
HL_API uchar *hl_to_string( vdynamic *v ) { return NULL; }
HL_API const uchar *hl_type_str( hl_type *t ) { return NULL; }

HL_API void *hl_fatal_error( const char *msg, const char *file, int line ) { return NULL; }
HL_API void hl_fatal_fmt( const char *file, int line, const char *fmt, ...) {}
HL_API void hl_sys_init(void **args, int nargs, void *hlfile) {}
HL_API void hl_setup_callbacks(void *sc, void *gw) {}
HL_API void hl_setup_reload_check( void *freload, void *param ) {}

HL_API hl_thread_info *hl_get_thread() { return NULL; }

#endif