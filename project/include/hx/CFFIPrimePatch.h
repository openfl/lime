#ifndef HX_CFFIPRIME_INCLUDED
#define HX_CFFIPRIME_INCLUDED

#include "hx/CFFI.h"


#ifdef HXCPP_JS_PRIME
#include <string>
typedef std::string HxString;
#else
struct HxString
{
   inline HxString(const HxString &inRHS)
   {
      length = inRHS.length;
      __s = inRHS.__s;
   }
   inline HxString(const char *inS,int inLen=-1) : length(inLen), __s(inS)
   {
      if (length<0)
         for(length=0; __s[length]; length++) { }
   }

   inline int size() { return length; }
   inline const char *c_str() { return __s; }

   inline HxString() : length(0), __s(0) { }

   int length;
   const char *__s;

};
#endif


namespace cffi
{

inline value alloc_pointer(void *inPtr) { return alloc_abstract((vkind)(0x100 + 2),inPtr); }


template<typename T> struct SigType { enum { Char='?' }; };
template<> struct SigType<bool> { enum { Char='b' }; };
template<> struct SigType<int> { enum { Char='i' }; };
template<> struct SigType<float> { enum { Char='f' }; };
template<> struct SigType<double> { enum { Char='d' }; };
template<> struct SigType<value> { enum { Char='o' }; };
template<> struct SigType<void> { enum { Char='v' }; };
template<> struct SigType<const char *> { enum { Char='c' }; };
template<> struct SigType<HxString> { enum { Char='s' }; };

template<typename RET>
bool CheckSig0( RET (func)(), const char *inSig)
{
   return SigType<RET>::Char==inSig[0] &&
          0 == inSig[1];
}


template<typename RET, typename A0>
bool CheckSig1( RET (func)(A0), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<RET>::Char==inSig[1] &&
          0 == inSig[2];
}


template<typename RET, typename A0, typename A1>
bool CheckSig2( RET (func)(A0,A1), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<RET>::Char==inSig[2] &&
          0 == inSig[3];
}


template<typename RET, typename A0, typename A1, typename A2>
bool CheckSig3( RET (func)(A0,A1,A2), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<A2>::Char==inSig[2] &&
          SigType<RET>::Char==inSig[3] &&
          0 == inSig[4];
}


template<typename RET, typename A0, typename A1, typename A2, typename A3>
bool CheckSig4( RET (func)(A0,A1,A2,A3), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<A2>::Char==inSig[2] &&
          SigType<A3>::Char==inSig[3] &&
          SigType<RET>::Char==inSig[4] &&
          0 == inSig[5];
}


template<typename RET, typename A0, typename A1, typename A2, typename A3, typename A4>
bool CheckSig5( RET (func)(A0,A1,A2,A3,A4), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<A2>::Char==inSig[2] &&
          SigType<A3>::Char==inSig[3] &&
          SigType<A4>::Char==inSig[4] &&
          SigType<RET>::Char==inSig[5] &&
          0 == inSig[6];
}

template<typename RET, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5>
bool CheckSig6( RET (func)(A0,A1,A2,A3,A4,A5), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<A2>::Char==inSig[2] &&
          SigType<A3>::Char==inSig[3] &&
          SigType<A4>::Char==inSig[4] &&
          SigType<A5>::Char==inSig[5] &&
          SigType<RET>::Char==inSig[6] &&
          0 == inSig[7];
}


template<typename RET, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5, typename A6>
bool CheckSig7( RET (func)(A0,A1,A2,A3,A4,A5,A6), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<A2>::Char==inSig[2] &&
          SigType<A3>::Char==inSig[3] &&
          SigType<A4>::Char==inSig[4] &&
          SigType<A5>::Char==inSig[5] &&
          SigType<A6>::Char==inSig[6] &&
          SigType<RET>::Char==inSig[7] &&
          0 == inSig[8];
}

template<typename RET, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5, typename A6, typename A7>
bool CheckSig8( RET (func)(A0,A1,A2,A3,A4,A5,A6,A7), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<A2>::Char==inSig[2] &&
          SigType<A3>::Char==inSig[3] &&
          SigType<A4>::Char==inSig[4] &&
          SigType<A5>::Char==inSig[5] &&
          SigType<A6>::Char==inSig[6] &&
          SigType<A7>::Char==inSig[7] &&
          SigType<RET>::Char==inSig[8] &&
          0 == inSig[9];
}


template<typename RET, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5, typename A6, typename A7, typename A8>
bool CheckSig9( RET (func)(A0,A1,A2,A3,A4,A5,A6,A7,A8), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<A2>::Char==inSig[2] &&
          SigType<A3>::Char==inSig[3] &&
          SigType<A4>::Char==inSig[4] &&
          SigType<A5>::Char==inSig[5] &&
          SigType<A6>::Char==inSig[6] &&
          SigType<A7>::Char==inSig[7] &&
          SigType<A8>::Char==inSig[8] &&
          SigType<RET>::Char==inSig[9] &&
          0 == inSig[10];
}

template<typename RET, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5, typename A6, typename A7, typename A8, typename A9>
bool CheckSig10( RET (func)(A0,A1,A2,A3,A4,A5,A6,A7,A8,A9), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<A2>::Char==inSig[2] &&
          SigType<A3>::Char==inSig[3] &&
          SigType<A4>::Char==inSig[4] &&
          SigType<A5>::Char==inSig[5] &&
          SigType<A6>::Char==inSig[6] &&
          SigType<A7>::Char==inSig[7] &&
          SigType<A8>::Char==inSig[8] &&
          SigType<A9>::Char==inSig[9] &&
          SigType<RET>::Char==inSig[10] &&
          0 == inSig[11];
}

template<typename RET, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5, typename A6, typename A7, typename A8, typename A9, typename A10>
bool CheckSig11( RET (func)(A0,A1,A2,A3,A4,A5,A6,A7,A8,A9, A10), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<A2>::Char==inSig[2] &&
          SigType<A3>::Char==inSig[3] &&
          SigType<A4>::Char==inSig[4] &&
          SigType<A5>::Char==inSig[5] &&
          SigType<A6>::Char==inSig[6] &&
          SigType<A7>::Char==inSig[7] &&
          SigType<A8>::Char==inSig[8] &&
          SigType<A9>::Char==inSig[9] &&
          SigType<A10>::Char==inSig[10] &&
          SigType<RET>::Char==inSig[11] &&
          0 == inSig[12];
}


template<typename RET, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5, typename A6, typename A7, typename A8, typename A9, typename A10, typename A11>
bool CheckSig12( RET (func)(A0,A1,A2,A3,A4,A5,A6,A7,A8,A9, A10, A11), const char *inSig)
{
   return SigType<A0>::Char==inSig[0] &&
          SigType<A1>::Char==inSig[1] &&
          SigType<A2>::Char==inSig[2] &&
          SigType<A3>::Char==inSig[3] &&
          SigType<A4>::Char==inSig[4] &&
          SigType<A5>::Char==inSig[5] &&
          SigType<A6>::Char==inSig[6] &&
          SigType<A7>::Char==inSig[7] &&
          SigType<A8>::Char==inSig[8] &&
          SigType<A9>::Char==inSig[9] &&
          SigType<A10>::Char==inSig[10] &&
          SigType<A11>::Char==inSig[11] &&
          SigType<RET>::Char==inSig[12] &&
          0 == inSig[13];
}




inline value ToValue(int inVal) { return alloc_int(inVal); }
inline value ToValue(float inVal) { return alloc_float(inVal); }
inline value ToValue(double inVal) { return alloc_float(inVal); }
inline value ToValue(value inVal) { return inVal; }
inline value ToValue(bool inVal) { return alloc_bool(inVal); }
inline value ToValue(HxString inVal) { return alloc_string_len(inVal.c_str(),inVal.size()); }

struct AutoValue
{
   value mValue;
   
   inline operator int()  { return val_int(mValue); }
   inline operator value() { return mValue; }
   inline operator double() { return val_number(mValue); }
   inline operator float() { return val_number(mValue); }
   inline operator bool() { return val_bool(mValue); }
   inline operator const char *() { return val_string(mValue); }
   inline operator HxString() { return HxString(val_string(mValue), val_strlen(mValue)); }
};



} // end namespace cffi


#define PRIME_ARG_DECL0
#define PRIME_ARG_DECL1 cffi::AutoValue a0
#define PRIME_ARG_DECL2 PRIME_ARG_DECL1, cffi::AutoValue a1
#define PRIME_ARG_DECL3 PRIME_ARG_DECL2, cffi::AutoValue a2
#define PRIME_ARG_DECL4 PRIME_ARG_DECL3, cffi::AutoValue a3
#define PRIME_ARG_DECL5 PRIME_ARG_DECL4, cffi::AutoValue a4

#define PRIME_ARG_LIST0
#define PRIME_ARG_LIST1 a0
#define PRIME_ARG_LIST2 PRIME_ARG_LIST1, a1
#define PRIME_ARG_LIST3 PRIME_ARG_LIST2, a2
#define PRIME_ARG_LIST4 PRIME_ARG_LIST3, a3
#define PRIME_ARG_LIST5 PRIME_ARG_LIST4, a4
#define PRIME_ARG_LIST6 arg[0],arg[1],arg[2],arg[3],arg[4],arg[5]
#define PRIME_ARG_LIST7 PRIME_ARG_LIST6 ,arg[6]
#define PRIME_ARG_LIST8 PRIME_ARG_LIST7 ,arg[7]
#define PRIME_ARG_LIST9 PRIME_ARG_LIST8 ,arg[8]
#define PRIME_ARG_LIST10 PRIME_ARG_LIST9 ,arg[9]
#define PRIME_ARG_LIST11 PRIME_ARG_LIST10 ,arg[10]
#define PRIME_ARG_LIST12 PRIME_ARG_LIST11 ,arg[11]



#ifdef HXCPP_JS_PRIME

#define DEFINE_PRIME0(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME1(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME2(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME3(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME4(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME5(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME6(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME7(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME8(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME9(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME10(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME11(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME12(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }


#define DEFINE_PRIME0v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME1v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME2v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME3v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME4v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME5(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME6v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME7vv(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME8v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME9v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME10v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME11v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }
#define DEFINE_PRIME12v(func) EMSCRIPTEN_BINDINGS(func) { function(#func, &func); }


#elif STATIC_LINK


#define DEFINE_PRIME0(func) extern "C" { \
  EXPORT value func##__prime(const char *inSig) { \
     if (!cffi::CheckSig0(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap() { return cffi::ToValue( func() ); } \
  EXPORT void *func##__0() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__0",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME0v(func) extern "C" { \
  EXPORT value func##__prime(const char *inSig) { \
     if (!cffi::CheckSig0(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap() { func(); return alloc_null(); } \
  EXPORT void *func##__0() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__0",(void *)(&func##__wrap)); \
}


#define DEFINE_PRIME1(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig1(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL1) { return cffi::ToValue( func(PRIME_ARG_LIST1) ); } \
  EXPORT void *func##__1() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__1",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME1v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig1(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL1) { func(PRIME_ARG_LIST1); return alloc_null(); } \
  EXPORT void *func##__1() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__1",(void *)(&func##__wrap)); \
}


#define DEFINE_PRIME2(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig2(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL2) { return cffi::ToValue( func(PRIME_ARG_LIST2) ); } \
  EXPORT void *func##__2() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__2",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME2v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig2(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL2) { func(PRIME_ARG_LIST2); return alloc_null(); } \
  EXPORT void *func##__2() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__2",(void *)(&func##__wrap)); \
}


#define DEFINE_PRIME3(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig3(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL3) { return cffi::ToValue( func(PRIME_ARG_LIST3) ); } \
  EXPORT void *func##__3() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__3",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME3v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig3(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL3) { func(PRIME_ARG_LIST3); return alloc_null(); } \
  EXPORT void *func##__3() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__3",(void *)(&func##__wrap)); \
}


#define DEFINE_PRIME4(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig4(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL4) { return cffi::ToValue( func(PRIME_ARG_LIST4) ); } \
  EXPORT void *func##__4() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__4",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME4v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig4(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL4) { func(PRIME_ARG_LIST4); return alloc_null(); } \
  EXPORT void *func##__4() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__4",(void *)(&func##__wrap)); \
}


#define DEFINE_PRIME5(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig5(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL5) { return cffi::ToValue( func(PRIME_ARG_LIST5) ); } \
  EXPORT void *func##__5() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__5",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME5v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig5(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL5) { func(PRIME_ARG_LIST5); return alloc_null(); } \
  EXPORT void *func##__5() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__5",(void *)(&func##__wrap)); \
}


#define DEFINE_PRIME6(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig6(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST6) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME6v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig6(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST6); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}


#define DEFINE_PRIME7(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig7(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST7) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME7v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig7(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST7); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME8(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig8(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST8) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME8v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig8(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST8); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}


#define DEFINE_PRIME9(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig9(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST9) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME9v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig9(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST9); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME10(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig10(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST10) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME10v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig10(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST10); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}


#define DEFINE_PRIME11(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig11(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST11) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME11v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig11(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST11); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}


#define DEFINE_PRIME12(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig12(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST12) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}

#define DEFINE_PRIME12v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig12(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST12); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
  int __reg_##func##__prime = hx_register_prim(#func "__prime",(void *)(&func##__prime)); \
  int __reg_##func = hx_register_prim(#func "__MULT",(void *)(&func##__wrap)); \
}


#else


#define DEFINE_PRIME0(func) extern "C" { \
  EXPORT value func##__prime(const char *inSig) { \
     if (!cffi::CheckSig0(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap() { return cffi::ToValue( func() ); } \
  EXPORT void *func##__0() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME0v(func) extern "C" { \
  EXPORT value func##__prime(const char *inSig) { \
     if (!cffi::CheckSig0(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap() { func(); return alloc_null(); } \
  EXPORT void *func##__0() { return (void*)(&func##__wrap); } \
}


#define DEFINE_PRIME1(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig1(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL1) { return cffi::ToValue( func(PRIME_ARG_LIST1) ); } \
  EXPORT void *func##__1() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME1v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig1(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL1) { func(PRIME_ARG_LIST1); return alloc_null(); } \
  EXPORT void *func##__1() { return (void*)(&func##__wrap); } \
}


#define DEFINE_PRIME2(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig2(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL2) { return cffi::ToValue( func(PRIME_ARG_LIST2) ); } \
  EXPORT void *func##__2() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME2v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig2(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL2) { func(PRIME_ARG_LIST2); return alloc_null(); } \
  EXPORT void *func##__2() { return (void*)(&func##__wrap); } \
}


#define DEFINE_PRIME3(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig3(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL3) { return cffi::ToValue( func(PRIME_ARG_LIST3) ); } \
  EXPORT void *func##__3() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME3v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig3(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL3) { func(PRIME_ARG_LIST3); return alloc_null(); } \
  EXPORT void *func##__3() { return (void*)(&func##__wrap); } \
}


#define DEFINE_PRIME4(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig4(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL4) { return cffi::ToValue( func(PRIME_ARG_LIST4) ); } \
  EXPORT void *func##__4() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME4v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig4(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL4) { func(PRIME_ARG_LIST4); return alloc_null(); } \
  EXPORT void *func##__4() { return (void*)(&func##__wrap); } \
}


#define DEFINE_PRIME5(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig5(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL5) { return cffi::ToValue( func(PRIME_ARG_LIST5) ); } \
  EXPORT void *func##__5() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME5v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig5(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(PRIME_ARG_DECL5) { func(PRIME_ARG_LIST5); return alloc_null(); } \
  EXPORT void *func##__5() { return (void*)(&func##__wrap); } \
}


#define DEFINE_PRIME6(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig6(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST6) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME6v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig6(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST6); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}


#define DEFINE_PRIME7(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig7(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST7) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME7v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig7(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST7); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME8(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig8(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST8) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME8v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig8(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST8); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}


#define DEFINE_PRIME9(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig9(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST9) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME9v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig9(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST9); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME10(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig10(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
}

#define DEFINE_PRIME10v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig10(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST10); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}


#define DEFINE_PRIME11(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig11(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST11) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME11v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig11(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST11); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}


#define DEFINE_PRIME12(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig12(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg,int) { return cffi::ToValue( func(PRIME_ARG_LIST12) ); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}

#define DEFINE_PRIME12v(func) extern "C" { \
  EXPORT void *func##__prime(const char *inSig) { \
     if (!cffi::CheckSig12(func,inSig)) return 0; return cffi::alloc_pointer((void*)&func); } \
  value func##__wrap(cffi::AutoValue  *arg, int) { func(PRIME_ARG_LIST12); return alloc_null(); } \
  EXPORT void *func##__MULT() { return (void*)(&func##__wrap); } \
}
#endif

#endif


