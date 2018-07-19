#ifndef HX_CFFIEXT_INCLUDED
#define HX_CFFIEXT_INCLUDED

#include <hx/CFFI.h>

#if defined(STATIC_LINK) && defined(IMPLEMENT_CFFI_EXT)
void *LoadFunc(const char *inName) { return 0; }
#else
extern void *LoadFunc(const char *inName);
#endif

#ifdef IMPLEMENT_CFFI_EXT
#define DEFFUNC_EXT(name,ret,def_args,call_args) \
   typedef ret (*FUNC_##name)def_args; \
   FUNC_##name IMPL_##name = NULL; \
   extern FUNC_##name EXT_##name; \
   bool LOADED_##name = false; \
   bool HAS_##name () \
   { \
     if (!LOADED_##name) \
     { \
       IMPL_##name = (FUNC_##name)LoadFunc(#name); \
       LOADED_##name = true; \
     } \
     return IMPL_##name != NULL; \
   } \
   ret REAL_##name def_args \
   { \
      if (!HAS_##name()) \
      { \
        fprintf(stderr,"Could not find external function:" #name " \n"); \
        abort(); \
      } \
      EXT_##name = IMPL_##name; \
      return IMPL_##name call_args; \
   } \
   FUNC_##name EXT_##name = REAL_##name;
#else
#define DEFFUNC_EXT(name,ret,def_args,call_args) \
typedef ret (*FUNC_##name)def_args; \
extern bool HAS_##name (); \
extern FUNC_##name EXT_##name;
#endif

#define DEFFUNC_EXT_0(ret,name) DEFFUNC_EXT(name,ret, (), ())
#define DEFFUNC_EXT_1(ret,name,t1) DEFFUNC_EXT(name,ret, (t1 a1), (a1))
#define DEFFUNC_EXT_2(ret,name,t1,t2) DEFFUNC_EXT(name,ret, (t1 a1, t2 a2), (a1,a2))
#define DEFFUNC_EXT_3(ret,name,t1,t2,t3) DEFFUNC_EXT(name,ret, (t1 a1, t2 a2, t3 a3), (a1,a2,a3))
#define DEFFUNC_EXT_4(ret,name,t1,t2,t3,t4) DEFFUNC_EXT(name,ret, (t1 a1, t2 a2, t3 a3, t4 a4), (a1,a2,a3,a4))
#define DEFFUNC_EXT_5(ret,name,t1,t2,t3,t4,t5) DEFFUNC_EXT(name,ret, (t1 a1, t2 a2, t3 a3, t4 a4,t5 a5), (a1,a2,a3,a4,a5))

DEFFUNC_EXT_1(value,pin_buffer,buffer);
DEFFUNC_EXT_1(void,unpin_buffer,value);
DEFFUNC_EXT_2(value,alloc_array_type,int,hxValueType);

static value alloc_array_type_wrap(int size, hxValueType type)
{
    return HAS_alloc_array_type() ? EXT_alloc_array_type(size, type) : alloc_array (size);
}

#endif