#ifndef NME_CFFI_H
#define NME_CFFI_H

#include <hx/CFFI.h>

#include <nme/Object.h>


namespace nme
{

extern vkind gObjectKind;


namespace
{
   inline void release_object(value inValue)
   {
      if (val_is_kind(inValue,gObjectKind))
      {
         Object *obj = (Object *)val_to_kind(inValue,gObjectKind);
         if (obj)
            obj->DecRef();
      }
   }
}


inline value ObjectToAbstract(Object *inObject)
{
   inObject->IncRef();
   value result = alloc_abstract(gObjectKind,inObject);
   val_gc(result,release_object);
   return result;
}


template<typename OBJ>
bool AbstractToObject(value inValue, OBJ *&outObj)
{
   outObj = 0;
   if ( ! val_is_kind(inValue,gObjectKind) )
      return false;
   Object *obj = (Object *)val_to_kind(inValue,gObjectKind);
   outObj = dynamic_cast<OBJ *>(obj);
   return outObj;
}


}


#endif
