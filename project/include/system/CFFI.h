#ifndef LIME_SYSTEM_CFFI_H
#define LIME_SYSTEM_CFFI_H


#define HL_NAME(n) hl_##n
#include <hl.h>

struct hl_varray : varray {};
struct hl_vstring : vstring {};

#undef hl_aptr
#define hl_aptr(a,t)	((t*)(((hl_varray*)(a))+1))

#include <hx/CFFIPrime.h>


#ifndef LIME_HASHLINK
// define stubs in CFFI.cpp
#endif


#endif