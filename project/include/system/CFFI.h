#ifndef LIME_SYSTEM_CFFI_H
#define LIME_SYSTEM_CFFI_H


#define HL_NAME(n) lime_##n
#include <hl.h>
#undef DEFINE_PRIM
#define DEFINE_HL_PRIM(t, name, args) DEFINE_PRIM_WITH_NAME(t, name, args, name)

typedef vdynamic hl_vdynamic;
typedef vobj hl_vobj;
typedef vvirtual hl_vvirtual;
typedef varray hl_varray;
typedef vclosure hl_vclosure;
typedef vclosure_wrapper hl_vclosure_wrapper;
typedef vdynobj hl_vdynobj;
typedef venum hl_venum;
typedef vstring hl_vstring;

#undef hl_aptr
#define hl_aptr(a,t)	((t*)(((hl_varray*)(a))+1))


#include <hx/CFFIPrime.h>


#ifndef LIME_HASHLINK
// define stubs in CFFI.cpp
#endif


#endif