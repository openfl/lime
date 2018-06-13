#include <system/CFFI.h>


#ifndef LIME_HASHLINK

HL_API hl_type hlt_void = hl_type ();
HL_API hl_type hlt_i32 = hl_type ();
HL_API hl_type hlt_i64 = hl_type ();
HL_API hl_type hlt_f64 = hl_type ();
HL_API hl_type hlt_f32 = hl_type ();
HL_API hl_type hlt_dyn = hl_type ();
HL_API hl_type hlt_array = hl_type ();
HL_API hl_type hlt_bytes = hl_type ();
HL_API hl_type hlt_dynobj = hl_type ();
HL_API hl_type hlt_bool = hl_type ();
HL_API hl_type hlt_abstract = hl_type ();

HL_API double hl_nan( void ) { return 0; }

HL_API varray *hl_alloc_array( hl_type *t, int size ) { return 0; }
HL_API vdynobj *hl_alloc_dynobj( void ) { return 0; }
HL_API char *hl_to_utf8( const uchar *bytes ) { return 0; }

HL_API int hl_hash_utf8 ( const char *str ) { return 0; }

HL_API vdynamic *hl_dyn_call( vclosure *c, vdynamic **args, int nargs ) { return 0; }

HL_API void hl_dyn_seti( vdynamic *d, int hfield, hl_type *t, int value ) {}
HL_API void hl_dyn_setp( vdynamic *d, int hfield, hl_type *t, void *ptr ) {}
HL_API void hl_dyn_setf( vdynamic *d, int hfield, float f ) {}
HL_API void hl_dyn_setd( vdynamic *d, int hfield, double v ) {}

HL_API void *hl_gc_alloc_gen( hl_type *t, int size, int flags ) { return 0; }
HL_API void hl_add_root( void *ptr ) {}
HL_API void hl_remove_root( void *ptr ) {}
HL_API void hl_gc_major( void ) {}
HL_API bool hl_is_gc_ptr( void *ptr ) { return false; }

#endif