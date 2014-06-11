
#include <hx/CFFI.h>

#include <utils/ByteArray.h>
#include <string>


namespace lime {


	// --- ByteArray -----------------------------------------------------

	AutoGCRoot *gByteArrayCreate = 0;
	AutoGCRoot *gByteArrayLen = 0;
	AutoGCRoot *gByteArrayResize = 0;
	AutoGCRoot *gByteArrayBytes = 0;

	value lime_byte_array_init(value inFactory, value inLen, value inResize, value inBytes) {

		gByteArrayCreate = new AutoGCRoot(inFactory);
		gByteArrayLen = new AutoGCRoot(inLen);
		gByteArrayResize = new AutoGCRoot(inResize);
		gByteArrayBytes = new AutoGCRoot(inBytes);

		return alloc_null();

	} DEFINE_PRIM(lime_byte_array_init,4);


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
	
	
	


    value lime_byte_array_read_file(value inFilename) {

        ByteArray result = ByteArray::FromFile(val_os_string(inFilename));

        return result.mValue;

    } DEFINE_PRIM(lime_byte_array_read_file,1);


    value lime_byte_array_get_native_pointer(value inByteArray) {

        ByteArray bytes(inByteArray);

        if (!val_is_null (bytes.mValue)) {
            return alloc_int((intptr_t)bytes.Bytes ());
        }

        return alloc_null();

    } DEFINE_PRIM(lime_byte_array_get_native_pointer,1);
    
    
    #ifdef HX_WINDOWS
typedef wchar_t OSChar;
#define val_os_string val_wstring
#define OpenRead(x) _wfopen(x,L"rb")
#define OpenOverwrite(x) _wfopen(x,L"wb") // [ddc]

#else
typedef char OSChar;
#define val_os_string val_string

#if defined(IPHONE)
FILE *OpenRead(const char *inName);
FILE *OpenOverwrite(const char *inName); // [ddc]
extern int gFixedOrientation;

#elif defined(HX_MACOS)
} // close namespace nme
extern "C" FILE *OpenRead(const char *inName);
extern "C" bool GetBundleFilename(const char *inName, char *outBuffer,int inBufSize);
extern "C" FILE *OpenOverwrite(const char *inName);
namespace nme {
#else
#ifdef TIZEN
extern int gFixedOrientation;
#endif
#define OpenRead(x) fopen(x,"rb")
#define OpenOverwrite(x) fopen(x,"wb") // [ddc]
#endif
#endif
    
    
    ByteArray ByteArray::FromFile(const OSChar *inFilename)
{
   FILE *file = OpenRead(inFilename);
   if (!file)
   {
      #ifdef ANDROID
      return AndroidGetAssetBytes(inFilename);
      #endif
      return ByteArray();
   }

   fseek(file,0,SEEK_END);
   int len = ftell(file);
   fseek(file,0,SEEK_SET);

   ByteArray result(len);
   int status = fread(result.Bytes(),len,1,file);
   fclose(file);

   return result;
}


value lime_byte_array_overwrite_file(value inFilename, value inBytes) {

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

    } DEFINE_PRIM(lime_byte_array_overwrite_file, 2);

}