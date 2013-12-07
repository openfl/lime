#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
// Include neko glue....
#define NEKO_COMPATIBLE
#endif



#ifdef ANDROID
#include <android/log.h>
#endif

#include <Utils.h>
#include <ExternalInterface.h>
#include <Display.h>
#include <TextField.h>
#include "renderer/common/Surface.h"
#include "renderer/common/SimpleSurface.h"
#include "renderer/common/AutoSurfaceRender.h"
#include <Tilesheet.h>
#include <Font.h>
#include <Sound.h>
#include <Video.h>
#include <Input.h>
#include <algorithm>
#include <URL.h>
#include <ByteArray.h>
#include <Lzma.h>
#include <LimeThread.h>



#ifdef min
#undef min
#undef max
#endif


namespace lime
{

static int _id_type;
static int _id_x;
static int _id_y;
static int _id_z;
static int _id_sx;
static int _id_sy;
static int _id_width;
static int _id_height;
static int _id_length;
static int _id_value;
static int _id_id;
static int _id_flags;
static int _id_result;
static int _id_code;
static int _id_a;
static int _id_b;
static int _id_c;
static int _id_d;
static int _id_tx;
static int _id_ty;
static int _id_angle;
static int _id_distance;
static int _id_strength;
static int _id_alpha;
static int _id_hideObject;
static int _id_knockout;
static int _id_inner;
static int _id_blurX;
static int _id_blurY;
static int _id_quality;
static int _id_align;
static int _id_blockIndent;
static int _id_bold;
static int _id_bullet;
static int _id_color;
static int _id_font;
static int _id_indent;
static int _id_italic;
static int _id_kerning;
static int _id_leading;
static int _id_leftMargin;
static int _id_letterSpacing;
static int _id_rightMargin;
static int _id_size;
static int _id_tabStops;
static int _id_target;
static int _id_underline;
static int _id_url;
static int _id_error;
static int _id_state;
static int _id_bytesTotal;
static int _id_bytesLoaded;
static int _id_volume;
static int _id_pan;

static int _id_alphaMultiplier;
static int _id_redMultiplier;
static int _id_greenMultiplier;
static int _id_blueMultiplier;

static int _id_alphaOffset;
static int _id_redOffset;
static int _id_greenOffset;
static int _id_blueOffset;
static int _id_rgb;

static int _id_authType;
static int _id_credentials;
static int _id_cookieString;
static int _id_verbose;

static int _id_method;
static int _id_requestHeaders;
static int _id_name;
static int _id_contentType;
static int _id___bytes;

static int _id_rect;
static int _id_matrix;

static int _id_ascent;
static int _id_descent;


vkind gObjectKind;

static int sgIDsInit = false;

extern "C" void InitIDs()
{
   sgIDsInit = true;
   _id_type = val_id("type");
   _id_x = val_id("x");
   _id_y = val_id("y");
   _id_z = val_id("z");
   _id_sx = val_id("sx");
   _id_sy = val_id("sy");
   _id_width = val_id("width");
   _id_height = val_id("height");
   _id_length = val_id("length");
   _id_value = val_id("value");
   _id_id = val_id("id");
   _id_flags = val_id("flags");
   _id_result = val_id("result");
   _id_code = val_id("code");
   _id_a = val_id("a");
   _id_b = val_id("b");
   _id_c = val_id("c");
   _id_d = val_id("d");
   _id_tx = val_id("tx");
   _id_ty = val_id("ty");
   _id_angle = val_id("angle");
   _id_distance = val_id("distance");
   _id_strength = val_id("strength");
   _id_alpha = val_id("alpha");
   _id_hideObject = val_id("hideObject");
   _id_knockout = val_id("knockout");
   _id_inner = val_id("inner");
   _id_blurX = val_id("blurX");
   _id_blurY = val_id("blurY");
   _id_quality = val_id("quality");
   _id_align = val_id("align");
   _id_blockIndent = val_id("blockIndent");
   _id_bold = val_id("bold");
   _id_bullet = val_id("bullet");
   _id_color = val_id("color");
   _id_font = val_id("font");
   _id_indent = val_id("indent");
   _id_italic = val_id("italic");
   _id_kerning = val_id("kerning");
   _id_leading = val_id("leading");
   _id_leftMargin = val_id("leftMargin");
   _id_letterSpacing = val_id("letterSpacing");
   _id_rightMargin = val_id("rightMargin");
   _id_size = val_id("size");
   _id_tabStops = val_id("tabStops");
   _id_target = val_id("target");
   _id_underline = val_id("underline");
   _id_url = val_id("url");
   _id_error = val_id("error");
   _id_bytesTotal = val_id("bytesTotal");
   _id_state = val_id("state");
   _id_bytesLoaded = val_id("bytesLoaded");
   _id_volume = val_id("volume");
   _id_pan = val_id("pan");

   _id_alphaMultiplier = val_id("alphaMultiplier");
   _id_redMultiplier = val_id("redMultiplier");
   _id_greenMultiplier = val_id("greenMultiplier");
   _id_blueMultiplier = val_id("blueMultiplier");

   _id_alphaOffset = val_id("alphaOffset");
   _id_redOffset = val_id("redOffset");
   _id_greenOffset = val_id("greenOffset");
   _id_blueOffset = val_id("blueOffset");
   _id_rgb = val_id("rgb");

   _id_authType = val_id("authType");
   _id_credentials = val_id("credentials");
   _id_cookieString = val_id("cookieString");
   _id_verbose = val_id("verbose");
   _id_method = val_id("method");
   _id_requestHeaders = val_id("requestHeaders");
   _id_name = val_id("name");
   _id_contentType = val_id("contentType");
   _id___bytes = val_id("__bytes");
   _id_rect = val_id("rect");
   _id_matrix = val_id("matrix");

   _id_ascent = val_id("ascent");
   _id_descent = val_id("descent");

   gObjectKind = alloc_kind();
}

DEFINE_ENTRY_POINT(InitIDs)


static void release_object(value inValue)
{
   if (val_is_kind(inValue,gObjectKind))
   {
      Object *obj = (Object *)val_to_kind(inValue,gObjectKind);
      if (obj)
         obj->DecRef();
   }
}

value ObjectToAbstract(Object *inObject)
{
   inObject->IncRef();
   value result = alloc_abstract(gObjectKind,inObject);
   val_gc(result,release_object);
   return result;
}

WString val2stdwstr(value inVal)
{
   const wchar_t *val = val_wstring(inVal);
   int len=0;
   while(val[len]) len++;
   return WString(val,len);
}


template<typename T>
void FillArrayInt(QuickVec<T> &outArray,value inVal)
{
   if (val_is_null(inVal))
      return;
   int n = val_array_size(inVal);
   outArray.resize(n);
   int *c = val_array_int(inVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         outArray[i] = c[i];
   }
   else
   {
      value *vals = val_array_value(inVal);
      if (vals)
      {
         for(int i=0;i<n;i++)
            outArray[i] = val_int(vals[i]);
      }
      else
      {
         for(int i=0;i<n;i++)
            outArray[i] = val_int(val_array_i(inVal,i));
      }
   }

}

template<typename T>
void FillArrayInt(value outVal, const QuickVec<T> &inArray)
{
   int n = inArray.size();
   val_array_set_size(outVal,n);
   int *c = val_array_int(outVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         c[i] = inArray[i];
   }
   else
   {
      value *vals = val_array_value(outVal);
      if (vals)
         for(int i=0;i<n;i++)
            vals[i] = alloc_int(inArray[i]);
      else
         for(int i=0;i<n;i++)
            val_array_set_i(outVal,i,alloc_int(inArray[i]));
   }
}

template<typename T>
void FillArrayDouble(value outVal, const QuickVec<T> &inArray)
{
   int n = inArray.size();
   val_array_set_size(outVal,n);
   double *c = val_array_double(outVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         c[i] = inArray[i];
   }
   else
   {
      float *f = val_array_float(outVal);
      if (f)
      {
         for(int i=0;i<n;i++)
            f[i] = inArray[i];
      }
      else
      {
         value *vals = val_array_value(outVal);
         if (vals)
            for(int i=0;i<n;i++)
               vals[i] = alloc_float(inArray[i]);
         else
            for(int i=0;i<n;i++)
               val_array_set_i(outVal,i,alloc_float(inArray[i]));
      }
   }
}




template<typename T,int N>
void FillArrayDoubleN(QuickVec<T,N> &outArray,value inVal)
{
   if (val_is_null(inVal))
      return;
   int n = val_array_size(inVal);
   outArray.resize(n);
   double *c = val_array_double(inVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         outArray[i] = c[i];
   }
   else
   {
      float *f = val_array_float(inVal);
      if (f)
      {
         for(int i=0;i<n;i++)
            outArray[i] = f[i];
      }
      else
      {
         value *vals = val_array_value(inVal);
         if (vals)
            for(int i=0;i<n;i++)
               outArray[i] = val_number(vals[i]);
         else
            for(int i=0;i<n;i++)
               outArray[i] = val_number(val_array_i(inVal,i));
      }
   }
}


template<typename T>
void FillArrayDouble(QuickVec<T> &outArray,value inVal)
{
   FillArrayDoubleN<T,16>(outArray,inVal);
}


void FromValue(Matrix &outMatrix, value inValue)
{
   if (!val_is_null(inValue))
   {
      outMatrix.m00 =  val_field_numeric(inValue,_id_a);
      outMatrix.m01 =  val_field_numeric(inValue,_id_c);
      outMatrix.m10 =  val_field_numeric(inValue,_id_b);
      outMatrix.m11 =  val_field_numeric(inValue,_id_d);
      outMatrix.mtx =  val_field_numeric(inValue,_id_tx);
      outMatrix.mty =  val_field_numeric(inValue,_id_ty);
   }
}

int ValInt(value inObject, int inID, int inDefault)
{
   value field = val_field(inObject,inID);
   if (val_is_null(field))
      return inDefault;
   return (int)val_number(field);
}


void FromValue(Event &outEvent, value inValue)
{
   outEvent.type = (EventType)ValInt(inValue,_id_type,etUnknown);
   outEvent.x = ValInt(inValue,_id_x,0);
   outEvent.y = ValInt(inValue,_id_y,0);
   outEvent.value = ValInt(inValue,_id_value,0);
   outEvent.id = ValInt(inValue,_id_id,-1);
   outEvent.flags = ValInt(inValue,_id_flags,0);
   outEvent.code = ValInt(inValue,_id_code,0);
   outEvent.result = (EventResult)ValInt(inValue,_id_result,0);
}


void FromValue(ColorTransform &outTrans, value inValue)
{
   if (!val_is_null(inValue))
   {
      outTrans.alphaOffset = val_field_numeric(inValue,_id_alphaOffset);
      outTrans.redOffset = val_field_numeric(inValue,_id_redOffset);
      outTrans.greenOffset = val_field_numeric(inValue,_id_greenOffset);
      outTrans.blueOffset = val_field_numeric(inValue,_id_blueOffset);

      outTrans.alphaMultiplier = val_field_numeric(inValue,_id_alphaMultiplier);
      outTrans.redMultiplier = val_field_numeric(inValue,_id_redMultiplier);
      outTrans.greenMultiplier = val_field_numeric(inValue,_id_greenMultiplier);
      outTrans.blueMultiplier = val_field_numeric(inValue,_id_blueMultiplier);
   }
}



int RGB2Int32(value inRGB)
{
   if (val_is_int(inRGB))
      return val_int(inRGB);
   if (val_is_object(inRGB))
   {
      return (int)(val_field_numeric(inRGB,_id_rgb)) |
             ( ((int)val_field_numeric(inRGB,_id_a)) << 24 );
   }
   return 0;
}


void FromValue(SoundTransform &outTrans, value inValue)
{
   if (!val_is_null(inValue))
   {
       outTrans.volume = val_number( val_field(inValue,_id_volume) );
       outTrans.pan = val_number( val_field(inValue,_id_pan) );
   }
}

void FromValue(DRect &outRect, value inValue)
{
   if (val_is_null(inValue))
      return;
   outRect.x = val_field_numeric(inValue,_id_x);
   outRect.y = val_field_numeric(inValue,_id_y);
   outRect.w = val_field_numeric(inValue,_id_width);
   outRect.h = val_field_numeric(inValue,_id_height);
}

void FromValue(Rect &outRect, value inValue)
{
   if (val_is_null(inValue))
      return;
   outRect.x = val_field_numeric(inValue,_id_x);
   outRect.y = val_field_numeric(inValue,_id_y);
   outRect.w = val_field_numeric(inValue,_id_width);
   outRect.h = val_field_numeric(inValue,_id_height);
}

Filter *FilterFromValue(value filter)
{
   WString type = val2stdwstr( val_field(filter,_id_type) );
   if (type==L"BlurFilter")
   {
      int q = val_int(val_field(filter,_id_quality));
      if (q<1) return 0;
      return( new BlurFilter( q,
          (int)val_field_numeric(filter,_id_blurX),
          (int)val_field_numeric(filter,_id_blurY) ) );
   }
   else if (type==L"ColorMatrixFilter")
   {
      QuickVec<float> inMatrix;
      FillArrayDouble(inMatrix, val_field(filter,_id_matrix));
      return( new ColorMatrixFilter(inMatrix) );
   }
   else if (type==L"DropShadowFilter")
   {
      int q = val_int(val_field(filter,_id_quality));
      if (q<1) return 0;
      return( new DropShadowFilter( q,
          (int)val_field_numeric(filter,_id_blurX),
          (int)val_field_numeric(filter,_id_blurY),
          val_field_numeric(filter,_id_angle),
          val_field_numeric(filter,_id_distance),
          val_int( val_field(filter,_id_color) ),
          val_field_numeric(filter,_id_strength),
          val_field_numeric(filter,_id_alpha),
          (bool)val_field_numeric(filter,_id_hideObject),
          (bool)val_field_numeric(filter,_id_knockout),
          (bool)val_field_numeric(filter,_id_inner)
          ) );
   }
   return 0;
}

void ToValue(value &outVal,const Rect &inRect)
{
    alloc_field(outVal,_id_x, alloc_float(inRect.x) );
    alloc_field(outVal,_id_y, alloc_float(inRect.y) );
    alloc_field(outVal,_id_width, alloc_float(inRect.w) );
    alloc_field(outVal,_id_height, alloc_float(inRect.h) );
}

void FromValue(ImagePoint &outPoint,value inValue)
{
   outPoint.x = val_field_numeric(inValue,_id_x);
   outPoint.y = val_field_numeric(inValue,_id_y);
}

void FromValue(UserPoint &outPoint,value inValue)
{
   outPoint.x = val_field_numeric(inValue,_id_x);
   outPoint.y = val_field_numeric(inValue,_id_y);
}



void ToValue(value &outVal,const Matrix &inMatrix)
{
    alloc_field(outVal,_id_a, alloc_float(inMatrix.m00) );
    alloc_field(outVal,_id_c, alloc_float(inMatrix.m01) );
    alloc_field(outVal,_id_b, alloc_float(inMatrix.m10) );
    alloc_field(outVal,_id_d, alloc_float(inMatrix.m11) );
    alloc_field(outVal,_id_tx, alloc_float(inMatrix.mtx) );
    alloc_field(outVal,_id_ty, alloc_float(inMatrix.mty) );
}

void ToValue(value &outVal,const ColorTransform &inTrans)
{
    alloc_field(outVal,_id_alphaMultiplier, alloc_float(inTrans.alphaMultiplier) );
    alloc_field(outVal,_id_redMultiplier, alloc_float(inTrans.redMultiplier) );
    alloc_field(outVal,_id_greenMultiplier, alloc_float(inTrans.greenMultiplier) );
    alloc_field(outVal,_id_blueMultiplier, alloc_float(inTrans.blueMultiplier) );

    alloc_field(outVal,_id_alphaOffset, alloc_float(inTrans.alphaOffset) );
    alloc_field(outVal,_id_redOffset, alloc_float(inTrans.redOffset) );
    alloc_field(outVal,_id_greenOffset, alloc_float(inTrans.greenOffset) );
    alloc_field(outVal,_id_blueOffset, alloc_float(inTrans.blueOffset) );
}



void FromValue(value obj, URLRequest &request)
{
   request.url = val_string( val_field(obj, _id_url) );
   request.authType = val_field_numeric(obj, _id_authType );
   request.credentials = val_string( val_field(obj, _id_credentials) );
   request.cookies = val_string( val_field(obj, _id_cookieString) );
   request.method = val_string( val_field(obj, _id_method) );
   request.contentType = val_string( val_field(obj, _id_contentType) );
   request.debug = val_field_numeric( obj, _id_verbose );
   request.postData = ByteArray( val_field(obj,_id___bytes) );

   // headers
  if (!val_is_null(val_field(obj, _id_requestHeaders)) && val_array_size(val_field(obj, _id_requestHeaders)) )
  {
    int size = val_array_size(val_field(obj, _id_requestHeaders));
    QuickVec<URLRequestHeader> headers;
     value *header_array = val_array_value(val_field(obj, _id_requestHeaders));
     for(int i = 0; i < val_array_size(val_field(obj, _id_requestHeaders)); i++)
     {
        value headerVal = header_array ? header_array[i] : val_array_i(val_field(obj, _id_requestHeaders), i);
        URLRequestHeader header;
        header.name = val_string(val_field(headerVal, _id_name));
        header.value = val_string(val_field(headerVal, _id_value));
        headers.push_back(header);
    }
  request.headers = headers;
  }
}
}

#define DO_PROP_READ(Obj,obj_prefix,prop,Prop,to_val) \
value lime_##obj_prefix##_get_##prop(value inObj) \
{ \
   Obj *obj; \
   if (AbstractToObject(inObj,obj)) \
      return to_val( obj->get##Prop() ); \
   return alloc_float(0); \
} \
\
DEFINE_PRIM(lime_##obj_prefix##_get_##prop,1)

#define DO_PROP(Obj,obj_prefix,prop,Prop,to_val,from_val) \
DO_PROP_READ(Obj,obj_prefix,prop,Prop,to_val) \
value lime_##obj_prefix##_set_##prop(value inObj,value inVal) \
{ \
   Obj *obj; \
   if (AbstractToObject(inObj,obj)) \
      obj->set##Prop(from_val(inVal)); \
   return alloc_null(); \
} \
\
DEFINE_PRIM(lime_##obj_prefix##_set_##prop,2)


#define DO_DISPLAY_PROP(prop,Prop,to_val,from_val) \
   DO_PROP(DisplayObject,display_object,prop,Prop,to_val,from_val) 

#define DO_STAGE_PROP(prop,Prop,to_val,from_val) \
   DO_PROP(Stage,stage,prop,Prop,to_val,from_val) 


using namespace lime;


value lime_time_stamp()
{
   return alloc_float( GetTimeStamp() );
}
DEFINE_PRIM(lime_time_stamp,0);


value lime_error_output(value message)
{
   fprintf (stderr, "%s", val_string (message));
   return alloc_null();
}
DEFINE_PRIM(lime_error_output,1);



// --- ByteArray -----------------------------------------------------

AutoGCRoot *gByteArrayCreate = 0;
AutoGCRoot *gByteArrayLen = 0;
AutoGCRoot *gByteArrayResize = 0;
AutoGCRoot *gByteArrayBytes = 0;

value lime_byte_array_init(value inFactory, value inLen, value inResize, value inBytes)
{
   gByteArrayCreate = new AutoGCRoot(inFactory);
   gByteArrayLen = new AutoGCRoot(inLen);
   gByteArrayResize = new AutoGCRoot(inResize);
   gByteArrayBytes = new AutoGCRoot(inBytes);
   return alloc_null();
}
DEFINE_PRIM(lime_byte_array_init,4);

ByteArray::ByteArray(int inSize)
{
   mValue = val_call1(gByteArrayCreate->get(), alloc_int(inSize) );
}

ByteArray::ByteArray() : mValue(0) { }

ByteArray::ByteArray(const QuickVec<uint8> &inData)
{
   mValue = val_call1(gByteArrayCreate->get(), alloc_int(inData.size()) );
   uint8 *bytes = Bytes();
   if (bytes)
     memcpy(bytes, &inData[0], inData.size() );
}

ByteArray::ByteArray(const ByteArray &inRHS) : mValue(inRHS.mValue) { }

ByteArray::ByteArray(value inValue) : mValue(inValue) { }

void ByteArray::Resize(int inSize)
{
   val_call2(gByteArrayResize->get(), mValue, alloc_int(inSize) );
}

int ByteArray::Size() const
{
   return val_int( val_call1(gByteArrayLen->get(), mValue ));
}


const unsigned char *ByteArray::Bytes() const
{
   value bytes = val_call1(gByteArrayBytes->get(),mValue);
   if (val_is_string(bytes))
      return (unsigned char *)val_string(bytes);
   buffer buf = val_to_buffer(bytes);
   if (buf==0)
   {
      val_throw(alloc_string("Bad ByteArray"));
   }
   return (unsigned char *)buffer_data(buf);
}


unsigned char *ByteArray::Bytes()
{
   value bytes = val_call1(gByteArrayBytes->get(),mValue);
   if (val_is_string(bytes))
      return (unsigned char *)val_string(bytes);
   buffer buf = val_to_buffer(bytes);
   if (buf==0)
   {
      val_throw(alloc_string("Bad ByteArray"));
   }
   return (unsigned char *)buffer_data(buf);
}

// --------------------


// [ddc]
value lime_byte_array_overwrite_file(value inFilename, value inBytes)
{
   // file is created if it doesn't exist,
   // if it exists, it is truncated to zero
   FILE *file = OpenOverwrite(val_os_string(inFilename));
   if (!file)
   {
      #ifdef ANDROID
      // [todo]
      #endif
      return alloc_null();
   }

   ByteArray array(inBytes);

   // The function fwrite() writes nitems objects, each size bytes long, to the
   // stream pointed to by stream, obtaining them from the location given by
   // ptr.
   // fwrite(const void *restrict ptr, size_t size, size_t nitems, FILE *restrict stream);
   fwrite( array.Bytes() , 1, array.Size() , file);

   fclose(file);
   return alloc_null();
}
DEFINE_PRIM(lime_byte_array_overwrite_file,2);

value lime_byte_array_read_file(value inFilename)
{
   ByteArray result = ByteArray::FromFile(val_os_string(inFilename));
   return result.mValue;
}
DEFINE_PRIM(lime_byte_array_read_file,1);


value lime_byte_array_get_native_pointer(value inByteArray)
{
   ByteArray bytes (inByteArray);
   if (!val_is_null (bytes.mValue))
   {
      return alloc_int((intptr_t)bytes.Bytes ());
   }
   return alloc_null();
}
DEFINE_PRIM(lime_byte_array_get_native_pointer,1);


struct ByteData
{
   uint8 *data;
   int   length;
};

bool FromValue(ByteData &outData,value inData)
{
   ByteArray array(inData);
   outData.data = array.Bytes();
   outData.length = array.Size();
   return true;
}

// --- WeakRef -----------------------------------------------------

struct WeakRefInfo
{
   int64 mHolder;
   int64 mPtr;
};

static QuickVec<WeakRefInfo> sWeakRefs;
static QuickVec<int> sFreeRefIDs;

#define PTR_MANGLE 0x11010101

static void release_weak_ref(value inValue)
{
   int64 key = ((int64)(inValue)) ^ PTR_MANGLE;
   for(int i=0;i<sWeakRefs.size();i++)
   {
      if (sWeakRefs[i].mPtr==key)
         // Wait until controlling object access it again
         sWeakRefs[i].mPtr = 0;
   }
}

static void release_weak_ref_holder(value inValue)
{
   int64 key = ((int64)(inValue)) ^ PTR_MANGLE;
   for(int i=0;i<sWeakRefs.size();i++)
   {
      if (sWeakRefs[i].mHolder==key)
      {
         sWeakRefs[i].mHolder = 0;
         sWeakRefs[i].mPtr = 0;
         sFreeRefIDs.push_back(i);
         break;
      }
   }
}

value lime_weak_ref_create(value inHolder,value inRef)
{
   int id = 0;
   if (!sFreeRefIDs.empty())
      id = sFreeRefIDs.qpop();
   else
   {
      id = sWeakRefs.size();
      sWeakRefs.resize(id+1);
   }

   WeakRefInfo &info = sWeakRefs[id];
   info.mHolder = ((int64)(inHolder)) ^ PTR_MANGLE;
   info.mPtr = ((int64)(inRef)) ^ PTR_MANGLE;
   val_gc(inHolder,release_weak_ref_holder);
   val_gc(inRef,release_weak_ref);

   return alloc_int(id);
}
DEFINE_PRIM(lime_weak_ref_create,2);

value lime_weak_ref_get(value inValue)
{
   int id = val_int(inValue);
   if (sWeakRefs[id].mPtr==0)
   {
      sWeakRefs[id].mHolder = 0;
      sFreeRefIDs.push_back(id);
      return alloc_null();
   }
   return (value)( sWeakRefs[id].mPtr ^ PTR_MANGLE );
}
DEFINE_PRIM(lime_weak_ref_get,1);



value lime_get_unique_device_identifier()
{
#if defined(IPHONE)
  return alloc_string(GetUniqueDeviceIdentifier().c_str());
#else
  return alloc_null();
#endif
}
DEFINE_PRIM(lime_get_unique_device_identifier,0);



value lime_set_icon( value path ) {
   //printf( "setting icon\n" );
   #if defined( HX_WINDOWS ) || defined( HX_MACOS )
       SetIcon( val_string( path ) );
   #endif   
   return alloc_null();
}

DEFINE_PRIM(lime_set_icon,1);

// --- lime.system.Capabilities -----------------------------------------------------

value lime_capabilities_get_screen_resolutions () {
   

   //Only really makes sense on PC platforms
   #if defined( HX_WINDOWS ) || defined( HX_MACOS )
   
      
      QuickVec<int>* res = CapabilitiesGetScreenResolutions();
      
      value result = alloc_array( res->size());
      
            for(int i=0;i<res->size();i++) {
               int outres = (*res)[ i ];
               val_array_set_i(result,i,alloc_int( outres ) );
      
      }
   
      return result;
   
   #endif
   
   return alloc_null();
   
   
}

DEFINE_PRIM( lime_capabilities_get_screen_resolutions, 0 );


value lime_capabilities_get_pixel_aspect_ratio () {
   
   return alloc_float (CapabilitiesGetPixelAspectRatio ());
   
}
DEFINE_PRIM (lime_capabilities_get_pixel_aspect_ratio, 0);

value lime_capabilities_get_screen_dpi () {
   
   return alloc_float (CapabilitiesGetScreenDPI ());
   
}
DEFINE_PRIM (lime_capabilities_get_screen_dpi, 0);

value lime_capabilities_get_screen_resolution_x () {
   
   return alloc_float (CapabilitiesGetScreenResolutionX ());
   
}
DEFINE_PRIM (lime_capabilities_get_screen_resolution_x, 0);

value lime_capabilities_get_screen_resolution_y () {
   
   return alloc_float (CapabilitiesGetScreenResolutionY ());
   
}
DEFINE_PRIM (lime_capabilities_get_screen_resolution_y, 0);

value lime_capabilities_get_language() {
   
   return alloc_string(CapabilitiesGetLanguage().c_str());
   
}
DEFINE_PRIM (lime_capabilities_get_language, 0);


// ---  lime.filesystem -------------------------------------------------------------
value lime_get_resource_path()
{
#if defined(IPHONE)
  return alloc_string(GetResourcePath().c_str());
#else
  return alloc_null();
#endif
}
DEFINE_PRIM(lime_get_resource_path,0);

value lime_filesystem_get_special_dir(value inWhich)
{
   static std::string dirs[DIR_SIZE];
   int idx = val_int(inWhich);

   if (dirs[idx]=="")
      GetSpecialDir((SpecialDir)idx,dirs[idx]);

   return alloc_string(dirs[idx].c_str());
}
DEFINE_PRIM(lime_filesystem_get_special_dir,1);

value lime_filesystem_get_volumes(value outVolumes, value inFactory)
{
   std::vector<VolumeInfo> volumes;
   lime::GetVolumeInfo(volumes);
   for(int v=0;v<volumes.size();v++)
   {
      VolumeInfo &info = volumes[v];
      value args = alloc_array(6);
      val_array_set_i(args,0,alloc_string(info.path.c_str()));
      val_array_set_i(args,1,alloc_string(info.name.c_str()));
      val_array_set_i(args,2,alloc_bool(info.writable));
      val_array_set_i(args,3,alloc_bool(info.removable));
      val_array_set_i(args,4,alloc_string(info.fileSystemType.c_str()));
      val_array_set_i(args,5,alloc_string(info.drive.c_str()));
      val_array_push(outVolumes, val_call1(inFactory,args) );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_filesystem_get_volumes,2);



// --- getURL ----------------------------------------------------------------------
value lime_get_url(value url)
{
   bool result=LaunchBrowser(val_string(url));
   return alloc_bool(result);
}
DEFINE_PRIM(lime_get_url,1);


// --- Haptic Vibrate ---------------------------------------------------------------

value lime_haptic_vibrate(value inPeriod, value inDuration)
{
   #if defined(WEBOS) || defined(ANDROID)
   HapticVibrate (val_int(inPeriod), val_int(inDuration));
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_haptic_vibrate,2);


// --- SharedObject ----------------------------------------------------------------------
value lime_set_user_preference(value inId,value inValue)
{
   #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN)
      bool result=SetUserPreference(val_string(inId),val_string(inValue));
      return alloc_bool(result);
   #endif
   return alloc_bool(false);
}
DEFINE_PRIM(lime_set_user_preference,2);

value lime_get_user_preference(value inId)
{
   #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN)
      std::string result=GetUserPreference(val_string(inId));
      return alloc_string(result.c_str());
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_get_user_preference,1);

value lime_clear_user_preference(value inId)
{
   #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN)
      bool result=ClearUserPreference(val_string(inId));
      return alloc_bool(result);
   #endif
   return alloc_bool(false);
}
DEFINE_PRIM(lime_clear_user_preference,1);

// --- Stage ----------------------------------------------------------------------

value lime_stage_set_fixed_orientation(value inValue)
{
#if defined(IPHONE) || defined(TIZEN)
   gFixedOrientation = val_int(inValue);
#endif
   return alloc_null();
}
DEFINE_PRIM(lime_stage_set_fixed_orientation,1);

value lime_get_frame_stage(value inValue)
{
   Frame *frame;
   if (!AbstractToObject(inValue,frame))
      return alloc_null();

   return ObjectToAbstract(frame->GetStage());
}
DEFINE_PRIM(lime_get_frame_stage,1);


AutoGCRoot *sOnCreateCallback = 0;

void OnMainFrameCreated(Frame *inFrame)
{
   SetMainThread();
   value frame = inFrame ? ObjectToAbstract(inFrame) : alloc_null();
   val_call1( sOnCreateCallback->get(),frame );
   delete sOnCreateCallback;
}


value lime_set_package(value inCompany,value inFile,value inPackage,value inVersion)
{
   gCompany = val_string(inCompany);
   gFile = val_string(inFile);
   gPackage = val_string(inPackage);
   gVersion = val_string(inVersion);
   return val_null;
}
DEFINE_PRIM(lime_set_package,4);


value lime_create_main_frame(value *arg, int nargs)
{
   if (!sgIDsInit)
      InitIDs();
   enum { aCallback, aWidth, aHeight, aFlags, aTitle, aIcon, aSIZE };

   sOnCreateCallback = new AutoGCRoot(arg[aCallback]);

   Surface *icon=0;
   AbstractToObject(arg[aIcon],icon);

   CreateMainFrame(OnMainFrameCreated,
       (int)val_number(arg[aWidth]), (int)val_number(arg[aHeight]),
       val_int(arg[aFlags]), val_string(arg[aTitle]), icon );

   return alloc_null();
}

DEFINE_PRIM_MULT(lime_create_main_frame);

value lime_set_asset_base(value inBase)
{
   gAssetBase = val_string(inBase);
   return val_null;
}
DEFINE_PRIM(lime_set_asset_base,1);

value lime_terminate()
{
   exit(0);
   return alloc_null();
}
DEFINE_PRIM(lime_terminate,0);

value lime_close( value force )
{
   StopAnimation();
   return alloc_null();
}
DEFINE_PRIM(lime_close,0);

value lime_start_animation()
{
   StartAnimation();
   return alloc_null();
}
DEFINE_PRIM(lime_start_animation,0);

value lime_pause_animation()
{
   PauseAnimation();
   return alloc_null();
}
DEFINE_PRIM(lime_pause_animation,0);

value lime_resume_animation()
{
   ResumeAnimation();
   return alloc_null();
}
DEFINE_PRIM(lime_resume_animation,0);

value lime_stop_animation()
{
   StopAnimation();
   return alloc_null();
}
DEFINE_PRIM(lime_stop_animation,0);

value lime_stage_set_next_wake(value inStage, value inNextWake)
{
   Stage *stage;

   if (AbstractToObject(inStage,stage))
   {
      stage->SetNextWakeDelay(val_number(inNextWake));
   }

   return alloc_null();
}

DEFINE_PRIM(lime_stage_set_next_wake,2);

void external_handler( lime::Event &ioEvent, void *inUserData )
{
   AutoGCRoot *handler = (AutoGCRoot *)inUserData;
   if (ioEvent.type == etDestroyHandler)
   {
      delete handler;
      return;
   }

   value o = alloc_empty_object( );
   alloc_field(o,_id_type,alloc_int(ioEvent.type));
   alloc_field(o,_id_x,alloc_int(ioEvent.x));
   alloc_field(o,_id_y,alloc_int(ioEvent.y));
   alloc_field(o,_id_value,alloc_int(ioEvent.value));
   alloc_field(o,_id_id,alloc_int(ioEvent.id));
   alloc_field(o,_id_flags,alloc_int(ioEvent.flags));
   alloc_field(o,_id_code,alloc_int(ioEvent.code));
   alloc_field(o,_id_result,alloc_int(ioEvent.result));
   alloc_field(o,_id_sx,alloc_float(ioEvent.sx));
   alloc_field(o,_id_sy,alloc_float(ioEvent.sy));
   val_call1(handler->get(), o);
   ioEvent.result = (EventResult)val_int( val_field(o,_id_result) );
}


value lime_set_stage_handler(value inStage,value inHandler,value inNomWidth, value inNomHeight)
{
   Stage *stage;
   if (!AbstractToObject(inStage,stage))
      return alloc_null();

   AutoGCRoot *data = new AutoGCRoot(inHandler);

   stage->SetNominalSize(val_int(inNomWidth), val_int(inNomHeight) );
   stage->SetEventHandler(external_handler,data);

   return alloc_null();
}

DEFINE_PRIM(lime_set_stage_handler,4);


value lime_render_stage(value inStage)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      stage->RenderStage();
   }

   return alloc_null();
}

DEFINE_PRIM(lime_render_stage,1);


value lime_stage_resize_window(value inStage, value inWidth, value inHeight)
{
   #if (defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX))
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      stage->ResizeWindow(val_int(inWidth), val_int(inHeight));
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_stage_resize_window,3);


value lime_stage_get_focus_id(value inValue)
{
   int result = -1;
   Stage *stage;
   if (AbstractToObject(inValue,stage))
   {
      DisplayObject *obj = stage->GetFocusObject();
      if (obj)
         result = obj->getID();
   }

   return alloc_int(result);
}
DEFINE_PRIM(lime_stage_get_focus_id,1);

value lime_stage_set_focus(value inStage,value inObject,value inDirection)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      DisplayObject *obj = 0;
      AbstractToObject(inObject,obj);
      stage->SetFocusObject(obj);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_stage_set_focus,3);

DO_STAGE_PROP(focus_rect,FocusRect,alloc_bool,val_bool)
DO_STAGE_PROP(scale_mode,ScaleMode,alloc_int,val_int)
DO_STAGE_PROP(align,Align,alloc_int,val_int)
DO_STAGE_PROP(quality,Quality,alloc_int,val_int)
DO_STAGE_PROP(display_state,DisplayState,alloc_int,val_int)
DO_STAGE_PROP(multitouch_active,MultitouchActive,alloc_bool,val_bool)
DO_PROP_READ(Stage,stage,stage_width,StageWidth,alloc_float);
DO_PROP_READ(Stage,stage,stage_height,StageHeight,alloc_float);
DO_PROP_READ(Stage,stage,dpi_scale,DPIScale,alloc_float);
DO_PROP_READ(Stage,stage,multitouch_supported,MultitouchSupported,alloc_bool);


value lime_stage_is_opengl(value inStage)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      return alloc_bool(stage->isOpenGL());
   }
   return alloc_bool(false);
}
DEFINE_PRIM(lime_stage_is_opengl,1);
 
namespace lime { void AndroidRequestRender(); }
value lime_stage_request_render()
{
   #ifdef ANDROID
   AndroidRequestRender();
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_stage_request_render,0);
 

value lime_stage_show_cursor(value inStage,value inShow)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      stage->ShowCursor(val_bool(inShow));
   }
   return alloc_null();
}
DEFINE_PRIM(lime_stage_show_cursor,2);

value lime_stage_constrain_cursor_to_window_frame(value inStage, value inLock)
{
    Stage *stage;
    if (AbstractToObject(inStage,stage)) {       
        bool lock = val_bool(inLock);
        stage->ConstrainCursorToWindowFrame( lock );
    }
    return alloc_null();
}
DEFINE_PRIM(lime_stage_constrain_cursor_to_window_frame,2);

value lime_stage_set_cursor_position_in_window( value inStage, value inX, value inY )
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      int x = val_int(inX);
      int y = val_int(inY);      
      stage->SetCursorPositionInWindow(x,y);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_stage_set_cursor_position_in_window,3);

value lime_stage_set_window_position( value inStage, value inX, value inY ) {

    Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      int x = val_int(inX);
      int y = val_int(inY);      
      stage->SetStageWindowPosition(x,y);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_stage_set_window_position,3);


value lime_stage_get_orientation() {

   #if defined(IPHONE) || defined(ANDROID) || defined(BLACKBERRY)
      return alloc_int( GetDeviceOrientation() );
   
   #else
   
      return alloc_int( 0 );
      
   #endif
   
}

DEFINE_PRIM (lime_stage_get_orientation, 0);

value lime_stage_get_normal_orientation() {

   #if defined(ANDROID)
      return alloc_int( GetNormalOrientation() );
   #elif defined(IPHONE)
      return alloc_int( 1 ); // ios device sensors are always portrait orientated  
   #else
      return alloc_int( 0 );  
   #endif
}

DEFINE_PRIM (lime_stage_get_normal_orientation, 0);


// --- ManagedStage ----------------------------------------------------------------------

#ifndef HX_WINRT

value lime_managed_stage_create(value inW,value inH,value inFlags)
{
   SetMainThread();
   ManagedStage *stage = new ManagedStage(val_int(inW),val_int(inH),val_int(inFlags));
   return ObjectToAbstract(stage);
}
DEFINE_PRIM(lime_managed_stage_create,3);


value lime_managed_stage_pump_event(value inStage,value inEvent)
{
   ManagedStage *stage;
   if (AbstractToObject(inStage,stage))
   {
      Event event;
      FromValue(event,inEvent);
      stage->PumpEvent(event);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_managed_stage_pump_event,2);


#endif




// --- Input --------------------------------------------------------------

value lime_input_get_acceleration()
{
   double x,y,z;
   if (!GetAcceleration(x,y,z))
       return alloc_null();

   value obj = alloc_empty_object();
   alloc_field(obj,_id_x, alloc_float(x));
   alloc_field(obj,_id_y, alloc_float(y));
   alloc_field(obj,_id_z, alloc_float(z));
   return obj;
}

DEFINE_PRIM(lime_input_get_acceleration,0);


// --- DisplayObject --------------------------------------------------------------

value lime_create_display_object()
{
   return ObjectToAbstract( new DisplayObject() );
}

DEFINE_PRIM(lime_create_display_object,0);

value lime_display_object_get_graphics(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
      return ObjectToAbstract( &obj->GetGraphics() );

   return alloc_null();
}

DEFINE_PRIM(lime_display_object_get_graphics,1);

value lime_display_object_draw_to_surface(value *arg,int count)
{
   enum { aObject, aSurface, aMatrix, aColourTransform, aBlendMode, aClipRect, aSIZE};

   DisplayObject *obj;
   Surface *surf;
   if (AbstractToObject(arg[aObject],obj) && AbstractToObject(arg[aSurface],surf))
   {
      Rect r(surf->Width(),surf->Height());
      if (!val_is_null(arg[aClipRect]))
         FromValue(r,arg[aClipRect]);
      AutoSurfaceRender render(surf,r);

      Matrix matrix;
      if (!val_is_null(arg[aMatrix]))
         FromValue(matrix,arg[aMatrix]);
      int aa = 4;
      Stage *stage = Stage::GetCurrent();
      if (stage)
      {
         switch(stage->getQuality())
         {
             case sqLow:    aa=1; break;
             case sqMedium: aa=2; break;
             case sqHigh:   aa=4; break;
             case sqBest:   aa=4; break;
         }
      }
      RenderState state(surf,aa);
      state.mTransform.mMatrix = &matrix;

      ColorTransform col_trans;
      if (!val_is_null(arg[aColourTransform]))
      {
         ColorTransform t;
         FromValue(t,arg[aColourTransform]);
         state.CombineColourTransform(state,&t,&col_trans);
      }

      // TODO: Blend mode
      state.mRoundSizeToPOW2 = false;
      state.mPhase = rpBitmap;

      // get current transformation
      Matrix objMatrix = obj->GetLocalMatrix();
      
      // untransform for draw (set matrix to identity)
      float m00 = objMatrix.m00;
      float m01 = objMatrix.m01;
      float m10 = objMatrix.m10;
      float m11 = objMatrix.m11;
      float mtx = objMatrix.mtx;
      float mty = objMatrix.mty;
      objMatrix.m00 = 1;
      objMatrix.m01 = 0;
      objMatrix.m10 = 0;
      objMatrix.m11 = 1;
      objMatrix.mtx = 0;
      objMatrix.mty = 0;
      obj->setMatrix(objMatrix);

      // save current alpha but set to baseline for draw
      float objAlpha = obj->getAlpha();
      obj->setAlpha(1);

      DisplayObjectContainer *dummy = new DisplayObjectContainer(true);
      dummy->hackAddChild(obj);
      dummy->Render(render.Target(), state);

      state.mPhase = rpRender;
      dummy->Render(render.Target(), state);
      dummy->hackRemoveChildren();
      dummy->DecRef();

      // restore original transformation now that surface has rendered
      objMatrix.m00 = m00;
      objMatrix.m01 = m01;
      objMatrix.m10 = m10;
      objMatrix.m11 = m11;
      objMatrix.mtx = mtx;
      objMatrix.mty = mty;
      obj->setMatrix(objMatrix);

      // restore alpha
      obj->setAlpha(objAlpha);
   }

   return alloc_null();
}

DEFINE_PRIM_MULT(lime_display_object_draw_to_surface)


value lime_display_object_get_id(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
      return alloc_int( obj->id );

   return alloc_null();
}

DEFINE_PRIM(lime_display_object_get_id,1);

value lime_display_object_global_to_local(value inObj,value ioPoint)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      UserPoint point( val_field_numeric(ioPoint, _id_x),
                     val_field_numeric(ioPoint, _id_y) );
      UserPoint trans = obj->GlobalToLocal(point);
      alloc_field(ioPoint, _id_x, alloc_float(trans.x) );
      alloc_field(ioPoint, _id_y, alloc_float(trans.y) );
   }

   return alloc_null();
}

DEFINE_PRIM(lime_display_object_global_to_local,2);

void print_field(value inObj, int id, void *cookie)
{
   printf("Field : %d (%s)\n",id,val_string(val_field_name(id)));
}

value lime_type(value inObj)
{
   val_iter_fields(inObj, print_field, 0);
   return alloc_null();
}
DEFINE_PRIM(lime_type,1);


value lime_display_object_local_to_global(value inObj,value ioPoint)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      UserPoint point( val_field_numeric(ioPoint, _id_x),
                     val_field_numeric(ioPoint, _id_y) );
      UserPoint trans = obj->LocalToGlobal(point);
      alloc_field(ioPoint, _id_x, alloc_float(trans.x) );
      alloc_field(ioPoint, _id_y, alloc_float(trans.y) );
   }

   return alloc_null();
}

DEFINE_PRIM(lime_display_object_local_to_global,2);



value lime_display_object_hit_test_point(
            value inObj,value inX, value inY, value inShape, value inRecurse)
{
   DisplayObject *obj;
   UserPoint pos(val_number(inX),val_number(inY));

   if (AbstractToObject(inObj,obj))
   {
      if (val_bool(inShape))
      {
         Stage *stage = obj->getStage();
         if (stage)
         {
            bool recurse = val_bool(inRecurse);
            return alloc_bool( stage->HitTest( pos, obj, recurse ) );
         }
      }
      else
      {
         Matrix m = obj->GetFullMatrix(false);
         Transform trans;
         trans.mMatrix = &m;

         Extent2DF ext;
         obj->GetExtent(trans, ext, true, true );
         return alloc_bool( ext.Contains(pos) );
      }
   }

   return alloc_null();
}
DEFINE_PRIM(lime_display_object_hit_test_point,5);


value lime_display_object_set_filters(value inObj,value inFilters)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      FilterList filters;
      if (!val_is_null(inFilters) && val_array_size(inFilters) )
      {
         value *filter_array = val_array_value(inFilters);
         for(int f=0;f<val_array_size(inFilters);f++)
         {
            value filter = filter_array ? filter_array[f] : val_array_i(inFilters,f);
            Filter *fil = FilterFromValue(filter);
            if (fil)
               filters.push_back(fil);
        }
      }
      obj->setFilters(filters);
   }

   return alloc_null();
}

DEFINE_PRIM(lime_display_object_set_filters,2);

value lime_display_object_set_scale9_grid(value inObj,value inRect)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      if (val_is_null(inRect))
         obj->setScale9Grid(DRect(0,0,0,0));
      else
      {
         DRect rect;
         FromValue(rect,inRect);
         obj->setScale9Grid(rect);
      }
   }
   return alloc_null();
}
DEFINE_PRIM(lime_display_object_set_scale9_grid,2);

value lime_display_object_set_scroll_rect(value inObj,value inRect)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      if (val_is_null(inRect))
         obj->setScrollRect(DRect(0,0,0,0));
      else
      {
         DRect rect;
         FromValue(rect,inRect);
         obj->setScrollRect(rect);
      }
   }
   return alloc_null();
}
DEFINE_PRIM(lime_display_object_set_scroll_rect,2);

value lime_display_object_set_mask(value inObj,value inMask)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      DisplayObject *mask = 0;
      AbstractToObject(inMask,mask);
      obj->setMask(mask);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_display_object_set_mask,2);


value lime_display_object_set_matrix(value inObj,value inMatrix)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
       Matrix m;
       FromValue(m,inMatrix);

       obj->setMatrix(m);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_display_object_set_matrix,2);

value lime_display_object_get_matrix(value inObj,value outMatrix, value inFull)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      Matrix m = val_bool(inFull) ? obj->GetFullMatrix(false) : obj->GetLocalMatrix();
      ToValue(outMatrix,m);
   }

   return alloc_null();
}
DEFINE_PRIM(lime_display_object_get_matrix,3);

value lime_display_object_set_color_transform(value inObj,value inTrans)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
       ColorTransform trans;
       FromValue(trans,inTrans);

       obj->setColorTransform(trans);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_display_object_set_color_transform,2);

value lime_display_object_get_color_transform(value inObj,value outTrans, value inFull)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      ColorTransform t = val_bool(inFull) ? obj->GetFullColorTransform() :
                                            obj->GetLocalColorTransform();
      ToValue(outTrans,t);
   }

   return alloc_null();
}
DEFINE_PRIM(lime_display_object_get_color_transform,3);

value lime_display_object_get_pixel_bounds(value inObj,value outBounds)
{
   return alloc_null();
}
DEFINE_PRIM(lime_display_object_get_pixel_bounds,2);

value lime_display_object_get_bounds(value inObj, value inTarget, value outBounds, value inIncludeStroke)
{
   DisplayObject *obj;
   DisplayObject *target;
   if (AbstractToObject(inObj,obj) && AbstractToObject(inTarget,target))
   {
      Matrix reference = target->GetFullMatrix(false);
      Matrix ref_i = reference.Inverse();

      Matrix m = obj->GetFullMatrix(false);
      m = ref_i.Mult(m);

      Transform trans;
      trans.mMatrix = &m;

      Extent2DF ext;
      obj->GetExtent(trans, ext, false, val_bool(inIncludeStroke) );
      
      Rect rect;
      if (ext.GetRect(rect))
         ToValue(outBounds,rect);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_display_object_get_bounds,4);


value lime_display_object_request_soft_keyboard(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      Stage *stage = obj->getStage();
      if (stage)
      {
         // TODO: return whether it pops up
         stage->EnablePopupKeyboard(true);
         return alloc_bool(true);
      }
   }

   return alloc_bool(false);
}
DEFINE_PRIM(lime_display_object_request_soft_keyboard,1);


value lime_display_object_dismiss_soft_keyboard(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      Stage *stage = obj->getStage();
      if (stage)
      {
         // TODO: return whether it pops up
         stage->EnablePopupKeyboard(false);
         return alloc_bool(true);
      }
   }

   return alloc_bool(false);
}
DEFINE_PRIM(lime_display_object_dismiss_soft_keyboard,1);


DO_DISPLAY_PROP(x,X,alloc_float,val_number)
DO_DISPLAY_PROP(y,Y,alloc_float,val_number)
DO_DISPLAY_PROP(scale_x,ScaleX,alloc_float,val_number)
DO_DISPLAY_PROP(scale_y,ScaleY,alloc_float,val_number)
DO_DISPLAY_PROP(rotation,Rotation,alloc_float,val_number)
DO_DISPLAY_PROP(width,Width,alloc_float,val_number)
DO_DISPLAY_PROP(height,Height,alloc_float,val_number)
DO_DISPLAY_PROP(alpha,Alpha,alloc_float,val_number)
DO_DISPLAY_PROP(bg,OpaqueBackground,alloc_int,val_int)
DO_DISPLAY_PROP(mouse_enabled,MouseEnabled,alloc_bool,val_bool)
DO_DISPLAY_PROP(cache_as_bitmap,CacheAsBitmap,alloc_bool,val_bool)
DO_DISPLAY_PROP(pedantic_bitmap_caching,PedanticBitmapCaching,alloc_bool,val_bool)
DO_DISPLAY_PROP(pixel_snapping,PixelSnapping,alloc_int,val_int)
DO_DISPLAY_PROP(visible,Visible,alloc_bool,val_bool)
DO_DISPLAY_PROP(name,Name,alloc_wstring,val2stdwstr)
DO_DISPLAY_PROP(blend_mode,BlendMode,alloc_int,val_int)
DO_DISPLAY_PROP(needs_soft_keyboard,NeedsSoftKeyboard,alloc_bool,val_bool)
DO_DISPLAY_PROP(moves_for_soft_keyboard,MovesForSoftKeyboard,alloc_bool,val_bool)
DO_PROP_READ(DisplayObject,display_object,mouse_x,MouseX,alloc_float)
DO_PROP_READ(DisplayObject,display_object,mouse_y,MouseY,alloc_float)

// --- DirectRenderer -----------------------------------------------------

void onDirectRender(void *inHandle,const Rect &inRect, const Transform &inTransform)
{
   if (inHandle)
   {
      AutoGCRoot *root = (AutoGCRoot *)inHandle;
      value rect = alloc_empty_object();
      ToValue(rect,inRect);
      val_call1(root->get(),rect);
   }
}

value lime_direct_renderer_create()
{
   return ObjectToAbstract( new DirectRenderer(onDirectRender) );
}
DEFINE_PRIM(lime_direct_renderer_create,0);

value lime_direct_renderer_set(value inRenderer, value inCallback)
{
   DirectRenderer *renderer = 0;

   if (AbstractToObject(inRenderer,renderer))
   {
      if (val_is_null(inCallback))
      {
         if (renderer->renderHandle)
         {
            AutoGCRoot *root = (AutoGCRoot *)renderer->renderHandle;
            delete root;
            renderer->renderHandle = 0;
         }
      }
      else
      {
         if (renderer->renderHandle)
         {
            AutoGCRoot *root = (AutoGCRoot *)renderer->renderHandle;
            root->set(inCallback);
         }
         else
         {
            renderer->renderHandle = new AutoGCRoot(inCallback);
         }
      }
   }

   return alloc_null();
}
DEFINE_PRIM(lime_direct_renderer_set,2);

// --- SimpleButton -----------------------------------------------------

value lime_simple_button_create()
{
   return ObjectToAbstract( new SimpleButton() );
}
DEFINE_PRIM(lime_simple_button_create,0);

value lime_simple_button_set_state(value inButton, value inState, value inObject)
{
   SimpleButton *button = 0;

   if (AbstractToObject(inButton,button))
   {
      DisplayObject *object = 0;
      AbstractToObject(inObject,object);
      button->setState(val_int(inState), object);
   }

   return alloc_null();
}
DEFINE_PRIM(lime_simple_button_set_state,3);




DO_PROP(SimpleButton,simple_button,enabled,Enabled,alloc_bool,val_bool) 
DO_PROP(SimpleButton,simple_button,hand_cursor,UseHandCursor,alloc_bool,val_bool) 

// --- DisplayObjectContainer -----------------------------------------------------

value lime_create_display_object_container()
{
   return ObjectToAbstract( new DisplayObjectContainer() );
}

DEFINE_PRIM(lime_create_display_object_container,0);

value lime_doc_add_child(value inParent, value inChild)
{
   DisplayObjectContainer *parent;
   DisplayObject *child;
   if (AbstractToObject(inParent,parent) && AbstractToObject(inChild,child))
   {
      parent->addChild(child);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_doc_add_child,2);


value lime_doc_swap_children(value inParent, value inChild0, value inChild1)
{
   DisplayObjectContainer *parent;
   if (AbstractToObject(inParent,parent))
   {
      parent->swapChildrenAt(val_int(inChild0), val_int(inChild1) );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_doc_swap_children,3);


value lime_doc_remove_child(value inParent, value inPos)
{
   DisplayObjectContainer *parent;
   if (AbstractToObject(inParent,parent))
   {
      parent->removeChildAt(val_int(inPos));
   }
   return alloc_null();
}
DEFINE_PRIM(lime_doc_remove_child,2);

value lime_doc_set_child_index(value inParent, value inChild, value inPos)
{
   DisplayObjectContainer *parent;
   DisplayObject *child;
   if (AbstractToObject(inParent,parent) && AbstractToObject(inChild,child))
   {
      parent->setChildIndex(child,val_int(inPos));
   }
   return alloc_null();
}
DEFINE_PRIM(lime_doc_set_child_index,3);


DO_PROP(DisplayObjectContainer,doc,mouse_children,MouseChildren,alloc_bool,val_bool);


// --- ExternalInterface -----------------------------------------------------

AutoGCRoot *sExternalInterfaceHandler = 0;

value lime_external_interface_add_callback (value inFunctionName, value inClosure)
{
   #ifdef WEBOS
      if (sExternalInterfaceHandler == 0) {
         AutoGCRoot *sExternalInterfaceHandler = new AutoGCRoot (inClosure);
      }
      ExternalInterface_AddCallback (val_string (inFunctionName), sExternalInterfaceHandler);
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_external_interface_add_callback,2);

value lime_external_interface_available ()
{
   #ifdef WEBOS
      return alloc_bool(true);
   #else
      return alloc_bool(false);
   #endif
}
DEFINE_PRIM(lime_external_interface_available,0);

value lime_external_interface_call (value inFunctionName, value args)
{
   #ifdef WEBOS
      int n = val_array_size(args);
      const char *params[n];
      for (int i = 0; i < n; i++) {
         params[i] = val_string (val_array_i(args, i));
      }
      ExternalInterface_Call (val_string (inFunctionName), params, n);
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_external_interface_call,2);

value lime_external_interface_register_callbacks ()
{
   #ifdef WEBOS
      ExternalInterface_RegisterCallbacks ();
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_external_interface_register_callbacks,0);


// --- Graphics -----------------------------------------------------

value lime_gfx_clear(value inGfx)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
      gfx->clear();
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_clear,1);

value lime_gfx_begin_fill(value inGfx,value inColour, value inAlpha)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->beginFill( val_int(inColour), val_number(inAlpha) );
   }
   return alloc_null();
}

DEFINE_PRIM(lime_gfx_begin_fill,3);


void lime_gfx_begin_set_bitmap_fill(value inGfx,value inBMP, value inMatrix,
     value inRepeat, value inSmooth, bool inForSolid)
{
   Graphics *gfx;
   Surface  *surface;
   if (AbstractToObject(inGfx,gfx) && AbstractToObject(inBMP,surface) )
   {
      Matrix matrix;
      FromValue(matrix,inMatrix);

      GraphicsBitmapFill *fill = new GraphicsBitmapFill(surface,matrix,val_bool(inRepeat), val_bool(inSmooth));
      fill->setIsSolidStyle(inForSolid);
      fill->IncRef();
      gfx->drawGraphicsDatum(fill);
      fill->DecRef();
   }
}

value lime_gfx_begin_bitmap_fill(value inGfx,value inBMP, value inMatrix,
     value inRepeat, value inSmooth)
{
   lime_gfx_begin_set_bitmap_fill(inGfx,inBMP,inMatrix,inRepeat,inSmooth,true);
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_begin_bitmap_fill,5);

value lime_gfx_line_bitmap_fill(value inGfx,value inBMP, value inMatrix,
     value inRepeat, value inSmooth)
{
   lime_gfx_begin_set_bitmap_fill(inGfx,inBMP,inMatrix,inRepeat,inSmooth,false);
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_line_bitmap_fill,5);



void lime_gfx_begin_set_gradient_fill(value *arg, int args, bool inForSolid)
{
   enum { aGfx, aType, aColors, aAlphas, aRatios, aMatrix, aSpreadMethod, aInterpMethod,
          aFocal, aSIZE };

   Graphics *gfx;
   if (AbstractToObject(arg[aGfx],gfx))
   {
      Matrix matrix;
      FromValue(matrix,arg[aMatrix]);
      GraphicsGradientFill *grad = new GraphicsGradientFill(val_int(arg[aType]), 
         matrix,
         (SpreadMethod)val_int( arg[aSpreadMethod]),
         (InterpolationMethod)val_int( arg[aInterpMethod]),
         val_number( arg[aFocal] ) );
      int n = std::min( val_array_size(arg[aColors]),
           std::min(val_array_size(arg[aAlphas]), val_array_size(arg[aRatios]) ) );
      for(int i=0;i<n;i++)
         grad->AddStop( val_int( val_array_i( arg[aColors], i ) ),
                        val_number( val_array_i( arg[aAlphas], i ) ),
                        val_number( val_array_i( arg[aRatios], i ) )/255.0 );

      grad->setIsSolidStyle(inForSolid);
      grad->IncRef();
      gfx->drawGraphicsDatum(grad);
      grad->DecRef();
   }
}

value lime_gfx_begin_gradient_fill(value *arg, int args)
{
   lime_gfx_begin_set_gradient_fill(arg,args, true);
   return alloc_null();
}
DEFINE_PRIM_MULT(lime_gfx_begin_gradient_fill)

value lime_gfx_line_gradient_fill(value *arg, int args)
{
   lime_gfx_begin_set_gradient_fill(arg,args, false);
   return alloc_null();
}
DEFINE_PRIM_MULT(lime_gfx_line_gradient_fill)



value lime_gfx_end_fill(value inGfx)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
      gfx->endFill();
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_end_fill,1);


value lime_gfx_line_style(value* arg, int nargs)
{
   enum { argGfx, argThickness, argColour, argAlpha, argPixelHinting, argScaleMode, argCapsStyle,
          argJointStyle, argMiterLimit, argSIZE };

   Graphics *gfx;
   if (AbstractToObject(arg[argGfx],gfx))
   {
      double thickness = -1;
      if (!val_is_null(arg[argThickness]))
      {
         thickness = val_number(arg[argThickness]);
         if (thickness<0)
            thickness = 0;
      }
      gfx->lineStyle(thickness, val_int(arg[argColour]), val_number(arg[argAlpha]),
                 val_bool(arg[argPixelHinting]),
                 (StrokeScaleMode)val_int(arg[argScaleMode]),
                 (StrokeCaps)val_int(arg[argCapsStyle]),
                 (StrokeJoints)val_int(arg[argJointStyle]),
                 val_number(arg[argMiterLimit]) );
   }
   return alloc_null();
}
DEFINE_PRIM_MULT(lime_gfx_line_style)





value lime_gfx_move_to(value inGfx,value inX, value inY)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->moveTo( val_number(inX), val_number(inY) );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_move_to,3);

value lime_gfx_line_to(value inGfx,value inX, value inY)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->lineTo( val_number(inX), val_number(inY) );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_line_to,3);

value lime_gfx_curve_to(value inGfx,value inCX, value inCY, value inX, value inY)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->curveTo( val_number(inCX), val_number(inCY), val_number(inX), val_number(inY) );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_curve_to,5);

value lime_gfx_arc_to(value inGfx,value inCX, value inCY, value inX, value inY)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->arcTo( val_number(inCX), val_number(inCY), val_number(inX), val_number(inY) );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_arc_to,5);

value lime_gfx_draw_ellipse(value inGfx,value inX, value inY, value inWidth, value inHeight)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->drawEllipse( val_number(inX), val_number(inY), val_number(inWidth), val_number(inHeight) );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_draw_ellipse,5);

value lime_gfx_draw_rect(value inGfx,value inX, value inY, value inWidth, value inHeight)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->drawRect( val_number(inX), val_number(inY), val_number(inWidth), val_number(inHeight) );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_draw_rect,5);

value lime_gfx_draw_path(value inGfx, value inCommands, value inData, value inWinding)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      QuickVec<uint8> commands;
      QuickVec<float> data;
      
      FillArrayInt(commands, inCommands);
      FillArrayDouble(data, inData);
      
      if (!val_bool(inWinding))
         gfx->drawPath(commands, data, wrNonZero);
      else
         gfx->drawPath(commands, data, wrOddEven);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_draw_path, 4);

value lime_gfx_draw_round_rect(value *arg, int args)
{
   enum { aGfx, aX, aY, aW, aH, aRx, aRy, aSIZE };
   Graphics *gfx;
   if (AbstractToObject(arg[aGfx],gfx))
   {
      gfx->drawRoundRect( val_number(arg[aX]), val_number(arg[aY]), val_number(arg[aW]), val_number(arg[aH]), val_number(arg[aRx]), val_number(arg[aRy]) );
   }
   return alloc_null();
}
DEFINE_PRIM_MULT(lime_gfx_draw_round_rect);

value lime_gfx_draw_triangles(value *arg, int args )
{

   enum { aGfx, aVertices, aIndices, aUVData, aCull, aColours, aBlend, aViewport };
   
   Graphics *gfx;
   if (AbstractToObject(arg[aGfx],gfx))
   {
      QuickVec<float> vertices;
      QuickVec<int> indices;
      QuickVec<float> uvt;
      QuickVec<int> colours;
      QuickVec<float,4> viewport;
      
      FillArrayDouble(vertices,arg[aVertices]);
      FillArrayInt(indices,arg[aIndices]);
      FillArrayDouble(uvt,arg[aUVData]);
      FillArrayInt(colours, arg[aColours]);
      FillArrayDoubleN<float,4>(viewport, arg[aViewport] );
      
      gfx->drawTriangles(vertices, indices, uvt, val_int(arg[aCull]), colours, val_int( arg[ aBlend ] ), viewport );
   }
   
   return alloc_null();
}
DEFINE_PRIM_MULT(lime_gfx_draw_triangles);


value lime_gfx_draw_data(value inGfx,value inData)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      int n = val_array_size(inData);
      for(int i=0;i<n;i++)
      {
         IGraphicsData *data;
         if (AbstractToObject(val_array_i(inData,i),data))
            gfx->drawGraphicsDatum(data);
      }
   }
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_draw_data,2);


value lime_gfx_draw_datum(value inGfx,value inDatum)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      IGraphicsData *datum;
      if (AbstractToObject(inDatum,datum))
            gfx->drawGraphicsDatum(datum);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_draw_datum,2);

value lime_gfx_draw_tiles(value inGfx,value inSheet, value inXYIDs,value inFlags)
{
   Graphics *gfx;
   Tilesheet *sheet;
   if (AbstractToObject(inGfx,gfx) && AbstractToObject(inSheet,sheet))
   {
      enum
      {
        TILE_SCALE    = 0x0001,
        TILE_ROTATION = 0x0002,
        TILE_RGB      = 0x0004,
        TILE_ALPHA    = 0x0008,
        TILE_TRANS_2x2= 0x0010,
        TILE_SMOOTH   = 0x1000,

        TILE_BLEND_ADD   = 0x10000,
        TILE_BLEND_MULTIPLY   = 0x20000,
        TILE_BLEND_SCREEN   = 0x40000,
        TILE_BLEND_MASK  = 0xf0000,
      };

      int  flags = val_int(inFlags);
      BlendMode blend = bmNormal;
      switch(flags & TILE_BLEND_MASK)
      {
         case TILE_BLEND_ADD:
            blend = bmAdd;
            break;
         case TILE_BLEND_MULTIPLY:
            blend = bmMultiply;
            break;
         case TILE_BLEND_SCREEN:
            blend = bmScreen;
            break;
      }

      bool smooth = flags & TILE_SMOOTH;
      gfx->beginTiles(&sheet->GetSurface(), smooth, blend);

      int components = 3;
      int scale_pos = 3;
      int rot_pos = 3;

      if (flags & TILE_TRANS_2x2)
         components+=4;
      else
      {
         scale_pos = components;
         if (flags & TILE_SCALE)
            components++;
         rot_pos = components;
         if (flags & TILE_ROTATION)
            components++;
      }
      if (flags & TILE_RGB)
         components+=3;
      if (flags & TILE_ALPHA)
         components++;

      int n = val_array_size(inXYIDs)/components;
      double *vals = val_array_double(inXYIDs);
      float *fvals = val_array_float(inXYIDs);
      int max = sheet->Tiles();
      float rgba_buf[] = { 1, 1, 1, 1 };
      float trans_2x2_buf[] = { 1, 0, 0, 1 };
      float *rgba = (flags & ( TILE_RGB | TILE_ALPHA)) ? rgba_buf : 0;
      float *trans_2x2 = (flags & ( TILE_TRANS_2x2 | TILE_SCALE | TILE_ROTATION )) ? trans_2x2_buf : 0;
      int id;
      double x;
      double y;
      value *val_ptr = val_array_value(inXYIDs);

      for(int i=0;i<n;i++)
      {
         if (vals)
         {
            x = vals[0];
            y = vals[1];
            id =vals[2];
         }
         else if (fvals)
         {
            x = fvals[0];
            y = fvals[1];
            id =fvals[2];
         }
         else
         {
            x = val_number(val_ptr[0]);
            y = val_number(val_ptr[1]);
            id =val_number(val_ptr[2]);
         }
         if (id>=0 && id<max)
         {
            const Tile &tile =  sheet->GetTile(id);

            double ox = tile.mOx;
            double oy = tile.mOy;
            const Rect &r = tile.mRect;
            int pos = 3;

            if (trans_2x2)
            {
               if (flags & TILE_TRANS_2x2)
               {
                  trans_2x2[0] = vals?vals[pos++] : fvals?fvals[pos++] : val_number(val_ptr[pos++]);
                  trans_2x2[1] = vals?vals[pos++] : fvals?fvals[pos++] : val_number(val_ptr[pos++]);
                  trans_2x2[2] = vals?vals[pos++] : fvals?fvals[pos++] : val_number(val_ptr[pos++]);
                  trans_2x2[3] = vals?vals[pos++] : fvals?fvals[pos++] : val_number(val_ptr[pos++]);
               }
               else if (trans_2x2)
               {
                  double scale = 1.0;
                  double cos_theta = 1.0;
                  double sin_theta = 0.0;

                  if (flags & TILE_SCALE)
                     scale = vals?vals[pos++] : fvals?fvals[pos++] : val_number(val_ptr[pos++]);

                  if (flags & TILE_ROTATION)
                  {
                     double theta = vals?vals[pos++] : fvals?fvals[pos++] : val_number(val_ptr[pos++]);
                     cos_theta = cos(theta);
                     sin_theta = sin(theta);
                  }

                  trans_2x2[0] = scale*cos_theta;
                  trans_2x2[1] = scale*sin_theta;
                  trans_2x2[2] = -trans_2x2[1];
                  trans_2x2[3] = trans_2x2[0];
               }
               double ox_ = ox*trans_2x2[0] + oy*trans_2x2[2];
                      oy  = ox*trans_2x2[1] + oy*trans_2x2[3];
               ox = ox_;
            }

            if (flags & TILE_RGB)
            {
               if (vals)
               {
                  rgba[0] = vals[pos++];
                  rgba[1] = vals[pos++];
                  rgba[2] = vals[pos++];
               }
               else if (fvals)
               {
                  rgba[0] = fvals[pos++];
                  rgba[1] = fvals[pos++];
                  rgba[2] = fvals[pos++];
               }
               else
               {
                  rgba[0] = val_number(val_ptr[pos++]);
                  rgba[1] = val_number(val_ptr[pos++]);
                  rgba[2] = val_number(val_ptr[pos++]);
               }
            }

            if (flags & TILE_ALPHA)
            {
               if (vals)
                  rgba[3] = vals[pos++];
               else if (fvals)
                  rgba[3] = fvals[pos++];
               else
                  rgba[3] = val_number(val_ptr[pos++]);
            }

            gfx->tile(x-ox,y-oy,r,trans_2x2,rgba);
            if (vals)
               vals+=components;
            else if (fvals)
               fvals+=components;
            else
               val_ptr += components;
         }
      }
   }
   return alloc_null();
}
DEFINE_PRIM(lime_gfx_draw_tiles,4);


static bool sNekoLutInit = false;
static int sNekoLut[256];

value lime_gfx_draw_points(value *arg, int nargs)
{
   enum { aGfx, aXYs, aRGBAs, aDefaultRGBA, aIs31Bits, aPointSize, aSIZE };

   Graphics *gfx;
   if (AbstractToObject(arg[aGfx],gfx))
   {
      QuickVec<float> xys;
      FillArrayDouble(xys,arg[aXYs]);

      QuickVec<int> RGBAs;
      FillArrayInt(RGBAs,arg[aRGBAs]);

      int def_rgba = val_int(arg[aDefaultRGBA]);

      if (val_bool(arg[aIs31Bits]))
      {
         if (!sNekoLutInit)
         {
            sNekoLutInit = true;
            for(int i=0;i<64;i++)
               sNekoLut[i] = ((int)(i*255.0/63.0 + 0.5)) << 24;
         }
         for(int i=0;i<RGBAs.size();i++)
         {
            int &rgba = RGBAs[i];
            rgba = (rgba & 0xffffff) | sNekoLut[(rgba>>24) & 63];
         }
         def_rgba = (def_rgba & 0xffffff) | sNekoLut[(def_rgba>>24) & 63];
      }

      gfx->drawPoints(xys,RGBAs,def_rgba, val_number(arg[aPointSize]));
   }
   return alloc_null();
}
DEFINE_PRIM_MULT(lime_gfx_draw_points);




// --- IGraphicsData -----------------------------------------------------



value lime_graphics_path_create(value inCommands,value inData,value inWinding)
{
   GraphicsPath *result = new GraphicsPath();

   if (!val_bool(inWinding))
      result->winding = wrNonZero;

   FillArrayInt(result->commands,inCommands);
   FillArrayDouble(result->data,inData);

   return ObjectToAbstract(result);
}
DEFINE_PRIM(lime_graphics_path_create,3)


value lime_graphics_path_curve_to(value inPath,value inX1, value inY1, value inX2, value inY2)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      path->curveTo(val_number(inX1), val_number(inY1), val_number(inX2), val_number(inY2) );
   return alloc_null();
}
DEFINE_PRIM(lime_graphics_path_curve_to,5)



value lime_graphics_path_line_to(value inPath,value inX1, value inY1)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      path->lineTo(val_number(inX1), val_number(inY1));
   return alloc_null();
}
DEFINE_PRIM(lime_graphics_path_line_to,3)

value lime_graphics_path_move_to(value inPath,value inX1, value inY1)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      path->moveTo(val_number(inX1), val_number(inY1));
   return alloc_null();
}
DEFINE_PRIM(lime_graphics_path_move_to,3)


   
value lime_graphics_path_wline_to(value inPath,value inX1, value inY1)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      path->wideLineTo(val_number(inX1), val_number(inY1));
   return alloc_null();
}
DEFINE_PRIM(lime_graphics_path_wline_to,3)

value lime_graphics_path_wmove_to(value inPath,value inX1, value inY1)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      path->wideMoveTo(val_number(inX1), val_number(inY1));
   return alloc_null();
}
DEFINE_PRIM(lime_graphics_path_wmove_to,3)


value lime_graphics_path_get_commands(value inPath,value outCommands)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      FillArrayInt(outCommands,path->commands);
   return alloc_null();
}
DEFINE_PRIM(lime_graphics_path_get_commands,2)

value lime_graphics_path_set_commands(value inPath,value inCommands)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      FillArrayInt(path->commands,inCommands);
   return alloc_null();
}
DEFINE_PRIM(lime_graphics_path_set_commands,2)

value lime_graphics_path_get_data(value inPath,value outData)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      FillArrayDouble(outData,path->data);
   return alloc_null();
}
DEFINE_PRIM(lime_graphics_path_get_data,2)

value lime_graphics_path_set_data(value inPath,value inData)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      FillArrayDouble(path->data,inData);
   return alloc_null();
}
DEFINE_PRIM(lime_graphics_path_set_data,2)



// --- IGraphicsData - Fills ---------------------------------------------

value lime_graphics_solid_fill_create(value inColour, value inAlpha)
{
   GraphicsSolidFill *solid = new GraphicsSolidFill( val_int(inColour), val_number(inAlpha) );
   return ObjectToAbstract(solid);
}
DEFINE_PRIM(lime_graphics_solid_fill_create,2)


value lime_graphics_end_fill_create()
{
   GraphicsEndFill *end = new GraphicsEndFill;
   return ObjectToAbstract(end);
}
DEFINE_PRIM(lime_graphics_end_fill_create,0)


// --- IGraphicsData - Stroke ---------------------------------------------

value lime_graphics_stroke_create(value* arg, int nargs)
{
   enum { argThickness, argPixelHinting, argScaleMode, argCapsStyle,
          argJointStyle, argMiterLimit, argFill, argSIZE };

   double thickness = -1;
   if (!val_is_null(arg[argThickness]))
   {
      thickness = val_number(arg[argThickness]);
      if (thickness<0)
         thickness = 0;
   }

   IGraphicsFill *fill=0;
   AbstractToObject(arg[argFill],fill);

   GraphicsStroke *stroke = new GraphicsStroke(fill, thickness,
                 val_bool(arg[argPixelHinting]),
                 (StrokeScaleMode)val_int(arg[argScaleMode]),
                 (StrokeCaps)val_int(arg[argCapsStyle]),
                 (StrokeJoints)val_int(arg[argJointStyle]),
                 val_number(arg[argMiterLimit]) );

   return ObjectToAbstract(stroke);
}

DEFINE_PRIM_MULT(lime_graphics_stroke_create)



// --- TextField --------------------------------------------------------------

value lime_text_field_create()
{
   TextField *text = new TextField();
   return ObjectToAbstract(text);
}
DEFINE_PRIM(lime_text_field_create,0)

inline value alloc_wstring(const WString &inStr)
{
   return alloc_wstring_len(inStr.c_str(),inStr.length());
}


void FromValue(Optional<int> &outVal,value inVal) { outVal = (int)val_number(inVal); }
void FromValue(Optional<uint32> &outVal,value inVal) { outVal = (uint32)val_number(inVal); }
void FromValue(Optional<bool> &outVal,value inVal) { outVal = val_bool(inVal); }
void FromValue(Optional<WString> &outVal,value inVal)
{
   outVal = val2stdwstr(inVal);
}
void FromValue(Optional<QuickVec<int> > &outVal,value inVal)
{
   QuickVec<int> &val = outVal.Set();
   int n = val_array_size(inVal);
   val.resize(n);
   for(int i=0;i<n;i++)
      val[i] = val_int( val_array_i(inVal,i) );
}
void FromValue(Optional<TextFormatAlign> &outVal,value inVal)
{
   WString name = val2stdwstr(inVal);
   if (name==L"center")
      outVal = tfaCenter;
   else if (name==L"justify")
      outVal = tfaJustify;
   else if (name==L"right")
      outVal = tfaRight;
   else
      outVal = tfaLeft;
}

#define STF(attrib) \
{ \
   value tmp = val_field(inValue,_id_##attrib); \
   if (!val_is_null(tmp)) FromValue(outFormat.attrib, tmp); \
}

void SetTextFormat(TextFormat &outFormat, value inValue)
{
   STF(align);
   STF(blockIndent);
   STF(bold);
   STF(bullet);
   STF(color);
   STF(font);
   STF(indent);
   STF(italic);
   STF(kerning);
   STF(leading);
   STF(leftMargin);
   STF(letterSpacing);
   STF(rightMargin);
   STF(size);
   STF(tabStops);
   STF(target);
   STF(underline);
   STF(url);
}



value ToValue(const int &inVal) { return alloc_int(inVal); }
value ToValue(const uint32 &inVal) { return alloc_int(inVal); }
value ToValue(const bool &inVal) { return alloc_bool(inVal); }
value ToValue(const WString &inVal) { return alloc_wstring(inVal); }
value ToValue(const QuickVec<int> &outVal)
{
   // TODO:
   return alloc_null();
}
value ToValue(const TextFormatAlign &inTFA)
{
   switch(inTFA)
   {
      case tfaLeft : return alloc_wstring(L"left");
      case tfaRight : return alloc_wstring(L"right");
      case tfaCenter : return alloc_wstring(L"center");
      case tfaJustify : return alloc_wstring(L"justify");
   }

   return alloc_wstring(L"left");
}


#define GTF(attrib,ifSet) \
{ \
   if (!ifSet || inFormat.attrib.IsSet()) alloc_field(outValue, _id_##attrib, ToValue( inFormat.attrib.Get() ) ); \
}


void GetTextFormat(const TextFormat &inFormat, value &outValue, bool inIfSet = false)
{
   GTF(align,inIfSet);
   GTF(blockIndent,inIfSet);
   GTF(bold,inIfSet);
   GTF(bullet,inIfSet);
   GTF(color,inIfSet);
   GTF(font,inIfSet);
   GTF(indent,inIfSet);
   GTF(italic,inIfSet);
   GTF(kerning,inIfSet);
   GTF(leading,inIfSet);
   GTF(leftMargin,inIfSet);
   GTF(letterSpacing,inIfSet);
   GTF(rightMargin,inIfSet);
   GTF(size,inIfSet);
   GTF(tabStops,inIfSet);
   GTF(target,inIfSet);
   GTF(underline,inIfSet);
   GTF(url,inIfSet);
}


value lime_text_field_set_def_text_format(value inText,value inFormat)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      TextFormat *fmt = TextFormat::Create(true);
      SetTextFormat(*fmt,inFormat);
      text->setDefaultTextFormat(fmt);
      fmt->DecRef();
   }
   return alloc_null();
}

DEFINE_PRIM(lime_text_field_set_def_text_format,2)

value lime_text_field_get_text_format(value inText,value outFormat,value inStart,value inEnd)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      TextFormat *fmt = text->getTextFormat(val_int(inStart),val_int(inEnd));
      GetTextFormat(*fmt,outFormat,true);
   }
   return alloc_null();
}

DEFINE_PRIM(lime_text_field_get_text_format,4)


value lime_text_field_set_text_format(value inText,value inFormat,value inStart,value inEnd)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      TextFormat *fmt = TextFormat::Create(true);
      SetTextFormat(*fmt,inFormat);
      text->setTextFormat(fmt,val_int(inStart),val_int(inEnd));
      fmt->DecRef();
   }
   return alloc_null();
}

DEFINE_PRIM(lime_text_field_set_text_format,4)


value lime_text_field_get_def_text_format(value inText,value outFormat)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      const TextFormat *fmt = text->getDefaultTextFormat();
      GetTextFormat(*fmt,outFormat);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_text_field_get_def_text_format,2);


void GetTextLineMetrics(const TextLineMetrics &inMetrics, value &outValue)
{
   alloc_field(outValue,_id_x, alloc_float(inMetrics.x));
   alloc_field(outValue,_id_width, alloc_float(inMetrics.width));
   alloc_field(outValue,_id_height, alloc_float(inMetrics.height));
   alloc_field(outValue,_id_ascent, alloc_float(inMetrics.ascent));
   alloc_field(outValue,_id_descent, alloc_float(inMetrics.descent));
   alloc_field(outValue,_id_leading, alloc_float(inMetrics.leading));
}

value lime_text_field_get_line_metrics(value inText,value inIndex,value outMetrics)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      const TextLineMetrics *mts = text->getLineMetrics(val_int(inIndex));
      GetTextLineMetrics(*mts, outMetrics);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_text_field_get_line_metrics,3);


#define TEXT_PROP_GET(prop,Prop,to_val) \
value lime_text_field_get_##prop(value inHandle) \
{ \
   TextField *t; \
   if (AbstractToObject(inHandle,t)) \
      return to_val(t->get##Prop()); \
   return alloc_null(); \
} \
DEFINE_PRIM(lime_text_field_get_##prop,1);


#define TEXT_PROP(prop,Prop,to_val,from_val) \
   TEXT_PROP_GET(prop,Prop,to_val) \
value lime_text_field_set_##prop(value inHandle,value inValue) \
{ \
   TextField *t; \
   if (AbstractToObject(inHandle,t)) \
      t->set##Prop(from_val(inValue)); \
   return alloc_null(); \
} \
DEFINE_PRIM(lime_text_field_set_##prop,2);

#define TEXT_PROP_GET_IDX(prop,Prop,to_val) \
value lime_text_field_get_##prop(value inHandle,value inIndex) \
{ \
   TextField *t; \
   if (AbstractToObject(inHandle,t)) \
      return to_val(t->get##Prop(val_int(inIndex))); \
   return alloc_null(); \
} \
DEFINE_PRIM(lime_text_field_get_##prop,2);

TEXT_PROP(text,Text,alloc_wstring,val2stdwstr);
TEXT_PROP(html_text,HTMLText,alloc_wstring,val2stdwstr);
TEXT_PROP(text_color,TextColor,alloc_int,val_int);
TEXT_PROP(selectable,Selectable,alloc_bool,val_bool);
TEXT_PROP(display_as_password,DisplayAsPassword,alloc_bool,val_bool);
TEXT_PROP(type,IsInput,alloc_bool,val_bool);
TEXT_PROP(multiline,Multiline,alloc_bool,val_bool);
TEXT_PROP(word_wrap,WordWrap,alloc_bool,val_bool);
TEXT_PROP(background,Background,alloc_bool,val_bool);
TEXT_PROP(background_color,BackgroundColor,alloc_int,val_int);
TEXT_PROP(border,Border,alloc_bool,val_bool);
TEXT_PROP(border_color,BorderColor,alloc_int,val_int);
TEXT_PROP(embed_fonts,EmbedFonts,alloc_bool,val_bool);
TEXT_PROP(auto_size,AutoSize,alloc_int,val_int);
TEXT_PROP_GET(text_width,TextWidth,alloc_float);
TEXT_PROP_GET(text_height,TextHeight,alloc_float);
TEXT_PROP_GET(max_scroll_h,MaxScrollH,alloc_int);
TEXT_PROP_GET(max_scroll_v,MaxScrollV,alloc_int);
TEXT_PROP_GET(bottom_scroll_v,BottomScrollV,alloc_int);
TEXT_PROP(scroll_h,ScrollH,alloc_int,val_int);
TEXT_PROP(scroll_v,ScrollV,alloc_int,val_int);
TEXT_PROP_GET(num_lines,NumLines,alloc_int);
TEXT_PROP(max_chars,MaxChars,alloc_int,val_int);
TEXT_PROP_GET_IDX(line_text,LineText,alloc_wstring);
TEXT_PROP_GET_IDX(line_offset,LineOffset,alloc_int);


value lime_bitmap_data_create(value* arg, int nargs)
{
   enum { aWidth, aHeight, aFlags, aRGB, aA, aGPU };

   int w = val_number(arg[aWidth]);
   int h = val_number(arg[aHeight]);
   uint32 flags = val_int(arg[aFlags]);

   PixelFormat format = (flags & 0x01) ? pfARGB : pfXRGB;
   int gpu = -1;
   if (!val_is_null(arg[aGPU]))
      gpu = val_int(arg[aGPU]);
   
   Surface *result = new SimpleSurface( w, h, format, 1, gpu );
   if (!(flags & 0x01))
      result->SetAllowTrans(false);
   if (gpu==-1 && val_is_int(arg[aRGB]))
   {
      int rgb = val_int(arg[aRGB]);
      value inA = arg[aA];
      int alpha = val_is_int(inA) ? val_int(inA) : 255;
      result->Clear( rgb + (alpha<<24) );
   }
   return ObjectToAbstract(result);
}
DEFINE_PRIM_MULT(lime_bitmap_data_create);

value lime_bitmap_data_width(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      return alloc_int(surface->Width());
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_width,1);

value lime_bitmap_data_height(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      return alloc_int(surface->Height());
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_height,1);

value lime_bitmap_data_clear(value inHandle,value inRGB)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      surface->Clear( val_int(inRGB) );
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_clear,2);

value lime_bitmap_data_get_transparent(value inHandle,value inRGB)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      //return alloc_bool( surface->Format() & pfHasAlpha );
      return alloc_bool( surface->GetAllowTrans() );
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_get_transparent,1);

value lime_bitmap_data_set_flags(value inHandle,value inFlags)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      surface->SetFlags(val_int(inFlags));
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_set_flags,1);



value lime_bitmap_data_fill(value inHandle, value inRect, value inRGB, value inA)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
   {
      if (val_is_null(inRect))
         surface->Clear( val_int(inRGB) | (val_int(inA)<<24) );
      else
      {
       Rect rect;
       FromValue(rect,inRect);
         surface->Clear( val_int(inRGB) | (val_int(inA)<<24), &rect );
      }
   }
   return alloc_null();

}
DEFINE_PRIM(lime_bitmap_data_fill,4);

value lime_bitmap_data_load(value inFilename, value format)
{
   Surface *surface = Surface::Load(val_os_string(inFilename));
   if (surface)
   {
      value result = ObjectToAbstract(surface);
      surface->DecRef();
      
      if ( val_int( format ) == 1 ) 
         surface->setGPUFormat( pfARGB4444 );
      else if ( val_int( format ) == 2 ) 
         surface->setGPUFormat( pfRGB565 );
         
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_load,2);

value lime_bitmap_data_set_format(value inHandle, value format)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
   {
      if ( val_int( format ) == 1 ) 
         surface->setGPUFormat( pfARGB4444 );
      else if ( val_int( format ) == 2 ) 
         surface->setGPUFormat( pfRGB565 );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_set_format,2);

value lime_bitmap_data_from_bytes(value inRGBBytes, value inAlphaBytes)
{
   ByteData bytes;
   if (!FromValue(bytes,inRGBBytes))
      return alloc_null();

   Surface *surface = Surface::LoadFromBytes(bytes.data,bytes.length);
   surface->SetAllowTrans(true);
   
   if (surface)
   {
      if (!val_is_null(inAlphaBytes))
      {
         ByteData alphabytes;
         if (!FromValue(alphabytes,inAlphaBytes))
            return alloc_null();
            
         if(alphabytes.length > 0)
         {
            int index = 0;
            for (int y=0; y < surface->Height(); y++)
            {
               for (int x=0; x < surface->Width(); x++)
            {
                  uint32 alpha = alphabytes.data[index++] << 24;
                  uint32 pixel = surface->getPixel(x, y) << 8;
                  surface->setPixel(x, y, (pixel >> 8) + alpha, true);
               }
            } 
         }
      }
     
      value result = ObjectToAbstract(surface);
      surface->DecRef();
      return result;
   }

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_from_bytes,2);


value lime_bitmap_data_encode(value inSurface, value inFormat,value inQuality)
{
   Surface *surf;
   if (!AbstractToObject(inSurface,surf))
      return alloc_null();

   ByteArray array;

   bool ok = surf->Encode(&array, !strcmp(val_string(inFormat),"png"), val_number(inQuality) );

   if (!ok)
      return alloc_null();
  
   return array.mValue;
}
DEFINE_PRIM(lime_bitmap_data_encode,3);




value lime_bitmap_data_clone(value inSurface)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Surface *result = surf->clone();
      value val = ObjectToAbstract(result);
      result->DecRef();
      return val;
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_clone,1);


value lime_bitmap_data_color_transform(value inSurface,value inRect, value inColorTransform)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      ColorTransform trans;
      FromValue(trans,inColorTransform);
      Rect rect;
      FromValue(rect,inRect);

      surf->colorTransform(rect,trans);

   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_color_transform,3);


value lime_bitmap_data_apply_filter(value inDest, value inSrc,value inRect, value inOffset, value inFilter)
{
   Surface *src;
   Surface *dest;
   if (AbstractToObject(inSrc,src) && AbstractToObject(inDest,dest))
   {
      Filter *filter = FilterFromValue(inFilter);
      if (filter)
      {
         Rect rect;
         FromValue(rect,inRect);
         ImagePoint offset;
         FromValue(offset,inOffset);
         dest->applyFilter(src, rect, offset, filter);
      }
      //delete filter;
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_apply_filter,5);



value lime_bitmap_data_copy(value inSource, value inSourceRect, value inTarget, value inOffset, value inMergeAlpha)
{
   Surface *source;
   Surface *dest;
   if (AbstractToObject(inSource,source) && AbstractToObject(inTarget,dest))
   {
      Rect rect;
      FromValue(rect,inSourceRect);
      ImagePoint offset;
      FromValue(offset,inOffset);

      AutoSurfaceRender render(dest);
      
      BlendMode blend = val_bool(inMergeAlpha) ? bmNormal : bmCopy;
      source->BlitTo(render.Target(),rect,offset.x, offset.y, blend, 0);
   }

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_copy,5);

value lime_bitmap_data_copy_channel(value* arg, int nargs)
{
   enum { aSrc, aSrcRect, aDest, aDestPoint, aSrcChannel, aDestChannel, aSIZE };
   Surface *source;
   Surface *dest;
   if (AbstractToObject(arg[aSrc],source) && AbstractToObject(arg[aDest],dest))
   {
      Rect rect;
      FromValue(rect,arg[aSrcRect]);
      ImagePoint offset;
      FromValue(offset,arg[aDestPoint]);

      AutoSurfaceRender render(dest);
      source->BlitChannel(render.Target(),rect,offset.x, offset.y,
                          val_int(arg[aSrcChannel]), val_int(arg[aDestChannel]) );
   }

   return alloc_null();
}
DEFINE_PRIM_MULT(lime_bitmap_data_copy_channel);


value lime_bitmap_data_get_pixels(value inSurface, value inRect)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Rect rect(0,0,surf->Width(),surf->Height());
      FromValue(rect,inRect);
      if (rect.w>0 && rect.h>0)
      {
         int size = rect.w * rect.h*4;
         ByteArray array(size);

         surf->getPixels(rect,(unsigned int *)array.Bytes());

         return array.mValue;
      }
   }

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_get_pixels,2);

value lime_bitmap_data_get_array(value inSurface, value inRect, value outArray)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Rect rect(0,0,surf->Width(),surf->Height());
      FromValue(rect,inRect);
      if (rect.w>0 && rect.h>0)
      {
         int *ints = val_array_int(outArray);
         if (ints)
            surf->getPixels(rect,(unsigned int *)ints,false,true);
      }
   }

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_get_array,3);




value lime_bitmap_data_get_color_bounds_rect(value inSurface, value inMask, value inCol, value inFind, value outRect)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Rect result;

      int mask = RGB2Int32(inMask);
      int col = RGB2Int32(inCol);
      surf->getColorBoundsRect(mask,col,val_bool(inFind),result);

      ToValue(outRect,result);
   }

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_get_color_bounds_rect,5);


value lime_bitmap_data_get_pixel(value inSurface, value inX, value inY)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
      return alloc_int(surf->getPixel(val_int(inX),val_int(inY)) & 0xffffff);

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_get_pixel,3);

value lime_bitmap_data_get_pixel32(value inSurface, value inX, value inY)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
      return alloc_int(surf->getPixel(val_int(inX),val_int(inY)));

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_get_pixel32,3);


value lime_bitmap_data_get_pixel_rgba(value inSurface, value inX,value inY)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      int rgb = surf->getPixel(val_int(inX),val_int(inY));
      value result = alloc_empty_object();
      alloc_field(result,_id_rgb, alloc_int( rgb & 0xffffff) );
      alloc_field(result,_id_a, alloc_int( (rgb >> 24) & 0xff) );
      return result;
   }

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_get_pixel_rgba,3);

value lime_bitmap_data_scroll(value inSurface, value inDX, value inDY)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
      surf->scroll(val_int(inDX),val_int(inDY));

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_scroll,3);

value lime_bitmap_data_set_pixel(value inSurface, value inX, value inY, value inRGB)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
      surf->setPixel(val_int(inX),val_int(inY),val_int(inRGB));

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_set_pixel,4);

value lime_bitmap_data_set_pixel32(value inSurface, value inX, value inY, value inRGB)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
      surf->setPixel(val_int(inX),val_int(inY),val_int(inRGB),surf->GetAllowTrans());

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_set_pixel32,4);


value lime_bitmap_data_set_pixel_rgba(value inSurface, value inX, value inY, value inRGBA)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      value a = val_field(inRGBA,_id_a);
      value rgb = val_field(inRGBA,_id_rgb);
      if (val_is_int(a) && val_is_int(rgb))
         surf->setPixel(val_int(inX),val_int(inY),(val_int(a)<<24) | val_int(rgb), surf->GetAllowTrans() );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_set_pixel_rgba,4);


value lime_bitmap_data_set_bytes(value inSurface, value inRect, value inBytes,value inOffset)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Rect rect(0,0,surf->Width(),surf->Height());
      FromValue(rect,inRect);
      if (rect.w>0 && rect.h>0)
      {
         ByteArray array(inBytes);
         surf->setPixels(rect,(unsigned int *)(array.Bytes() + val_int(inOffset)) );
      }
   }

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_set_bytes,4);

value lime_bitmap_data_set_array(value inSurface, value inRect, value inArray)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Rect rect(0,0,surf->Width(),surf->Height());
      FromValue(rect,inRect);
      if (rect.w>0 && rect.h>0)
      {
         int *ints = val_array_int(inArray);
         if (ints)
            surf->setPixels(rect,(unsigned int *)ints,false,true);
      }
   }

   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_set_array,3);



value lime_bitmap_data_generate_filter_rect(value inRect, value inFilter, value outRect)
{
   Rect rect;
   FromValue(rect,inRect);

   Filter *filter = FilterFromValue(inFilter);
   if (filter)
   {
      int quality = filter->GetQuality();
      for(int q=0;q<quality;q++)
         filter->ExpandVisibleFilterDomain(rect, q);
      delete filter;
   }

   ToValue(outRect,rect);
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_generate_filter_rect,3);



value lime_bitmap_data_noise(value *args, int nArgs)
{
   enum { aSurface, aRandomSeed, aLow, aHigh, aChannelOptions, aGrayScale };

   Surface *surf;
   if (AbstractToObject(args[aSurface],surf))
   {
      surf->noise(val_int(args[aRandomSeed]), val_int(args[aLow]), val_int(args[aHigh]),
            val_int(args[aChannelOptions]), val_int(args[aGrayScale]));
   }

   return alloc_null();
}
DEFINE_PRIM_MULT(lime_bitmap_data_noise);



value lime_bitmap_data_flood_fill(value inSurface, value inX, value inY, value inColor)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      int x = val_int(inX);
      int y = val_int(inY);
      int color = val_int(inColor);
      
      int width = surf->Width();
      int height = surf->Height();
      
      std::vector<UserPoint> queue;
      queue.push_back(UserPoint(x,y));
      
      int old = surf->getPixel(x,y);
      bool useAlpha = surf->GetAllowTrans();
      
      bool *search = new bool[width*height];
      std::fill_n(search, width*height, false);
      
      while (queue.size() > 0)
      {
         UserPoint currPoint = queue.back();
       queue.pop_back();
         
         x = currPoint.x;
         y = currPoint.y;
       
         if (x<0 || x>=width) continue;
         if (y<0 || y>=height) continue;
         
         search[y*width + x] = true;
         
         if (surf->getPixel(x,y) == old)
         {
            surf->setPixel(x,y,color,useAlpha);
            if (x<width && !search[y*width + (x+1)])
            {
               queue.push_back(UserPoint(x+1,y));
            }
            if (y<height && !search[(y+1)*width + x])
            {
               queue.push_back(UserPoint(x,y+1));
            }
            if (x>0 && !search[y*width + (x-1)])
            {
               queue.push_back(UserPoint(x-1,y));
            }
            if (y>0 && !search[(y-1)*width + x])
            {
               queue.push_back(UserPoint(x,y-1));
            }
         }
      }
      delete [] search;
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_flood_fill,4);


value lime_bitmap_data_unmultiply_alpha(value inSurface)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      surf->unmultiplyAlpha();
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_unmultiply_alpha,1);


value lime_bitmap_data_multiply_alpha(value inSurface)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      surf->multiplyAlpha();
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_multiply_alpha,1);


value lime_bitmap_data_set_alpha_mode(value inHandle, value inAlphaMode)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
   {
      if ( val_int( inAlphaMode ) == 0 ) 
         surface->setAlphaMode( amUnknown );
      else if ( val_int( inAlphaMode ) == 1 ) 
         surface->setAlphaMode( amPremultiplied );
      else if ( val_int( inAlphaMode ) == 2 ) 
         surface->setAlphaMode( amStraight );
      else if ( val_int( inAlphaMode ) == 4 ) 
         surface->setAlphaMode( amIgnore );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_set_alpha_mode,2);


value lime_render_surface_to_surface(value* arg, int nargs)
{
   enum { aTarget, aSurface, aMatrix, aColourTransform, aBlendMode, aClipRect, aSmooth, aSIZE};

   Surface *surf;
   Surface *src;
   if (AbstractToObject(arg[aTarget],surf) && AbstractToObject(arg[aSurface],src))
   {
      Rect r(surf->Width(),surf->Height());
      if (!val_is_null(arg[aClipRect]))
         FromValue(r,arg[aClipRect]);
      AutoSurfaceRender render(surf,r);

      Matrix matrix;
      if (!val_is_null(arg[aMatrix]))
         FromValue(matrix,arg[aMatrix]);
      RenderState state(surf,4);
      state.mTransform.mMatrix = &matrix;

      ColorTransform col_trans;
      if (!val_is_null(arg[aColourTransform]))
      {
         ColorTransform t;
         FromValue(t,arg[aColourTransform]);
         state.CombineColourTransform(state,&t,&col_trans);
      }

      // TODO: Blend mode
      state.mRoundSizeToPOW2 = false;
      state.mPhase = rpRender;

      Graphics *gfx = new Graphics(0,true);
      gfx->beginBitmapFill(src,Matrix(),false,val_bool(arg[aSmooth]));
      gfx->moveTo(0,0);
      gfx->lineTo(src->Width(),0);
      gfx->lineTo(src->Width(),src->Height());
      gfx->lineTo(0,src->Height());
      gfx->lineTo(0,0);

      gfx->Render(render.Target(),state);

      gfx->DecRef();


   }

   return alloc_null();
}
DEFINE_PRIM_MULT(lime_render_surface_to_surface);


value lime_bitmap_data_dispose(value inSurface)
{
   Surface *surf;
   if (AbstractToObject(inSurface, surf))
   {
       surf->dispose();
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_dispose,1);


value lime_bitmap_data_destroy_hardware_surface(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      surface->destroyHardwareSurface();
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_destroy_hardware_surface,1);

value lime_bitmap_data_create_hardware_surface(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      surface->createHardwareSurface();
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_create_hardware_surface,1);


value lime_bitmap_data_dump_bits(value inSurface)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      surf->dumpBits();
   }
   return alloc_null();
}
DEFINE_PRIM(lime_bitmap_data_dump_bits,1);


/*value lime_surface_get_pixel_format(value inSurface)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      return alloc_int(surf->GetStride());
   }
   return alloc_null();
}*/



// --- Video --------------------------------------------------

value lime_video_create(value inWidth, value inHeight)
{
   Video *video = Video::Create( val_int(inWidth), val_int(inHeight) );
   if (video)
   {
      value result = ObjectToAbstract(video);
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(lime_video_create,2);

value lime_video_load(value inHandle, value inFilename)
{
   Video *video;
   if (AbstractToObject(inHandle,video))
      video->Load(val_string(inFilename));
   return alloc_null();
}
DEFINE_PRIM(lime_video_load,2);

value lime_video_play(value inHandle)
{
   Video *video;
   if (AbstractToObject(inHandle,video))
      video->Play();
   return alloc_null();
}
DEFINE_PRIM(lime_video_play,1);

value lime_video_clear(value inHandle)
{
   Video *video;
   if (AbstractToObject(inHandle,video))
      video->Clear();
   return alloc_null();
}
DEFINE_PRIM(lime_video_clear,1);

value lime_video_set_smoothing(value inHandle, value inSmoothing)
{
   Video *video;
   if (AbstractToObject(inHandle,video))
      video->smoothing = val_bool(inSmoothing);
   return alloc_null();
}
DEFINE_PRIM(lime_video_set_smoothing,2);



// --- Sound --------------------------------------------------

value lime_sound_from_file(value inFilename,value inForceMusic)
{
   Sound *sound = val_is_null(inFilename) ? 0 :
                  Sound::Create( val_string(inFilename), val_bool(inForceMusic) );

   if (sound)
   {
      value result =  ObjectToAbstract(sound);
      sound->DecRef();
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_from_file,2);

value lime_sound_from_data(value inData, value inLen, value inForceMusic)
{
   int length = val_int(inLen);
   Sound *sound;
  // printf("trying bytes with length %d", length);
   if (!val_is_null(inData) && length > 0) {
      ByteArray buf = ByteArray(inData);
      //printf("I'm here! trying bytes with length %d", length);
      sound = Sound::Create((float *)buf.Bytes(), length, val_bool(inForceMusic) );
   } else {
      val_throw(alloc_string("Empty ByteArray"));
   }

   if (sound)
   {
      value result =  ObjectToAbstract(sound);
      sound->DecRef();
      return result;
   } else {
      val_throw(alloc_string("Not Sound"));
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_from_data, 3);

#define GET_ID3(name) \
  sound->getID3Value(name,val); \
  alloc_field(outVar, val_id(name), alloc_string(val.c_str() ) );

value lime_sound_get_id3(value inSound, value outVar)
{
   Sound *sound;
   if (AbstractToObject(inSound,sound))
   {
      std::string val;
      GET_ID3("album")
      GET_ID3("artist")
      GET_ID3("comment")
      GET_ID3("genre")
      GET_ID3("songName")
      GET_ID3("track")
      GET_ID3("year")
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_get_id3,2);

value lime_sound_get_length(value inSound)
{
   Sound *sound;
   if (AbstractToObject(inSound, sound))
   {
      return alloc_float( sound->getLength() );
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_get_length,1);
 
value lime_sound_close(value inSound)
{
   Sound *sound;
   if (AbstractToObject(inSound,sound))
   {
      sound->close();
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_close,1);
 
value lime_sound_get_status(value inSound)
{
   Sound *sound;
   if (AbstractToObject(inSound,sound))
   {
      value result = alloc_empty_object();
      alloc_field(result, _id_bytesLoaded, alloc_int(sound->getBytesLoaded()));
      alloc_field(result, _id_bytesTotal, alloc_int(sound->getBytesTotal()));
      if (!sound->ok())
         alloc_field(result, _id_error, alloc_string(sound->getError().c_str()));
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_get_status,1);
 
// --- SoundChannel --------------------------------------------------------

value lime_sound_channel_is_complete(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_bool(channel->isComplete());
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_is_complete,1);

value lime_sound_channel_get_left(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_float(channel->getLeft());
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_get_left,1);

value lime_sound_channel_get_right(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_float(channel->getRight());
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_get_right,1);

value lime_sound_channel_get_position(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_float(channel->getPosition());
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_get_position,1);

value lime_sound_channel_set_position(value inChannel, value inFloat)
{
   #ifdef HX_MACOS
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {    
      float position = val_number(inFloat);
      channel->setPosition(position);
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_set_position,2);

value lime_sound_channel_stop(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      channel->stop();
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_stop,1);

value lime_sound_channel_set_transform(value inChannel, value inTransform)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      SoundTransform trans;
      FromValue(trans,inTransform);
      channel->setTransform(trans);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_set_transform,2);

value lime_sound_channel_create(value inSound, value inStart, value inLoops, value inTransform)
{
   Sound *sound;
   if (AbstractToObject(inSound,sound))
   {
      SoundTransform trans;
      FromValue(trans,inTransform);
      SoundChannel *channel = sound->openChannel(val_number(inStart),val_int(inLoops),trans);
      if (channel)
      {
         value result = ObjectToAbstract(channel);
         return result;
      }
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_create,4);

// --- dynamic sound ---


value lime_sound_channel_needs_data(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_bool(channel->needsData());
   }
   return alloc_bool(false);
}
DEFINE_PRIM(lime_sound_channel_needs_data,1);


value lime_sound_channel_add_data(value inChannel, value inBytes)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      channel->addData(ByteArray(inBytes));
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_add_data,2);


value lime_sound_channel_get_data_position(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_float(channel->getDataPosition());
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_get_data_position,1);



value lime_sound_channel_create_dynamic(value inBytes, value inTransform)
{
   ByteArray bytes(inBytes);
   SoundTransform trans;
   FromValue(trans,inTransform);
   SoundChannel *channel = SoundChannel::Create(bytes,trans);
   if (channel)
   {
      value result = ObjectToAbstract(channel);
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(lime_sound_channel_create_dynamic,2);


// --- Tilesheet -----------------------------------------------

value lime_tilesheet_create(value inSurface)
{
   Surface *surface;
   if (AbstractToObject(inSurface,surface))
   {
      surface->IncRef();
      Tilesheet *sheet = new Tilesheet(surface);
      surface->DecRef();
      return ObjectToAbstract(sheet);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_tilesheet_create,1);

value lime_tilesheet_add_rect(value inSheet,value inRect, value inHotSpot)
{
   Tilesheet *sheet;
   if (AbstractToObject(inSheet,sheet))
   {
      Rect rect;
      FromValue(rect,inRect);
      UserPoint p(0,0);
      if (!val_is_null(inHotSpot))
         FromValue(p,inHotSpot);
      int tile = sheet->addTileRect(rect,p.x,p.y);
     return alloc_int(tile);
   }
   return alloc_null();
}
DEFINE_PRIM(lime_tilesheet_add_rect,3);

// --- URL ----------------------------------------------------------

value lime_curl_initialize(value inCACertFilePath)
{
   #ifndef EMSCRIPTEN
   URLLoader::initialize(val_string(inCACertFilePath));
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_curl_initialize,1);

value lime_curl_create(value inURLRequest)
{
   #ifndef EMSCRIPTEN
   URLRequest request;
   FromValue(inURLRequest,request);
   URLLoader *loader = URLLoader::create(request);
   return ObjectToAbstract(loader);
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_curl_create,1);

value lime_curl_process_loaders()
{
   #ifndef EMSCRIPTEN
   return alloc_bool(URLLoader::processAll());
   #endif
   return alloc_bool(true);
}
DEFINE_PRIM(lime_curl_process_loaders,0);

value lime_curl_update_loader(value inLoader,value outHaxeObj)
{
   #ifndef EMSCRIPTEN
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      alloc_field(outHaxeObj,_id_state, alloc_int(loader->getState()) );
      alloc_field(outHaxeObj,_id_bytesTotal, alloc_int(loader->bytesTotal()) );
      alloc_field(outHaxeObj,_id_bytesLoaded, alloc_int(loader->bytesLoaded()) );
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_curl_update_loader,2);

value lime_curl_get_error_message(value inLoader)
{
   #ifndef EMSCRIPTEN
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      return alloc_string(loader->getErrorMessage());
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_curl_get_error_message,1);

value lime_curl_get_code(value inLoader)
{
   #ifndef EMSCRIPTEN
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      return alloc_int(loader->getHttpCode());
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_curl_get_code,1);


value lime_curl_get_data(value inLoader)
{
   #ifndef EMSCRIPTEN
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      ByteArray b = loader->releaseData();
      return b.mValue;
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(lime_curl_get_data,1);

value lime_curl_get_cookies(value inLoader)
{
   #ifndef EMSCRIPTEN
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      std::vector<std::string> cookies;
      loader->getCookies(cookies);
      value result = alloc_array(cookies.size());
      for(int i=0;i<cookies.size();i++)
         val_array_set_i(result,i,alloc_string_len(cookies[i].c_str(),cookies[i].length()));
      return result;
   }
   #endif
   return alloc_array(0);
}
DEFINE_PRIM(lime_curl_get_cookies,1);

value lime_lzma_encode(value input_value)
{
   buffer input_buffer = val_to_buffer(input_value);
   buffer output_buffer = alloc_buffer_len(0);
   Lzma::Encode(input_buffer, output_buffer);
   return buffer_val(output_buffer);
}
DEFINE_PRIM(lime_lzma_encode,1);

value lime_lzma_decode(value input_value)
{
   buffer input_buffer = val_to_buffer(input_value);
   buffer output_buffer = alloc_buffer_len(0);
   Lzma::Decode(input_buffer, output_buffer);
   return buffer_val(output_buffer);
}
DEFINE_PRIM(lime_lzma_decode,1);


value lime_file_dialog_folder(value in_title, value in_text )
{ 
    std::string _title( val_string( in_title ) );
    std::string _text( val_string( in_text ) );

    std::string path = FileDialogFolder( _title, _text );

    return alloc_string( path.c_str() );
}
DEFINE_PRIM(lime_file_dialog_folder,2);

value lime_file_dialog_open(value in_title, value in_text, value in_types )
{ 
    std::string _title( val_string( in_title ) );
    std::string _text( val_string( in_text ) );

    value *_types = val_array_value( in_types );

    std::string path = FileDialogOpen( _title, _text, std::vector<std::string>() );

    return alloc_string( path.c_str() );
}
DEFINE_PRIM(lime_file_dialog_open,3);

value lime_file_dialog_save(value in_title, value in_text, value in_types )
{ 
    std::string _title( val_string( in_title ) );
    std::string _text( val_string( in_text ) );

    value *_types = val_array_value( in_types );

    std::string path = FileDialogSave( _title, _text, std::vector<std::string>() );

    return alloc_string( path.c_str() );
}
DEFINE_PRIM(lime_file_dialog_save,3);

// Reference this to bring in all the symbols for the static library
#ifdef STATIC_LINK
extern "C" int lime_oglexport_register_prims();
#endif

extern "C" int lime_register_prims()
{
   #ifdef STATIC_LINK
   lime_oglexport_register_prims();
   #endif
   return 0;
}

