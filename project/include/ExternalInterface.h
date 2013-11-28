#ifndef EXTERNAL_INTERFACE
#define EXTERNAL_INTERFACE

#include <hx/CFFI.h>

#include <Object.h>


namespace lime
{

extern vkind gObjectKind;

value ObjectToAbstract(Object *inObject);

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
