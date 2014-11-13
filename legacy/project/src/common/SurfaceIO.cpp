#include <stdio.h>
#include <Surface.h>
#include <ByteArray.h>


extern "C" {
#include <jpeglib.h>
#include <png.h>
   #include <pngstruct.h>
   #define PNG_SIG_SIZE 8
}
#include <setjmp.h>

using namespace nme;

struct ReadBuf
{
   ReadBuf(const uint8 *inData, int inLen) : mData(inData), mLen(inLen) { }

   bool Read(uint8 *outBuffer, int inN)
   {
      if (inN>mLen)
      {
         memset(outBuffer,0,inN);
         return false;
      }
      memcpy(outBuffer,mData,inN);
      mData+=inN;
      mLen -= inN;
      return true;
   }

   const uint8 *mData;
   int mLen;
};

struct ErrorData
{
   struct jpeg_error_mgr base; // base
   jmp_buf on_error;     // return;
};

static void OnOutput(j_common_ptr cinfo)
{
}
static void OnError(j_common_ptr cinfo)
{
   ErrorData * err = (ErrorData *)cinfo->err;
   // return...
   longjmp(err->on_error, 1);
}

struct MySrcManager
{
   MySrcManager(const JOCTET *inData, int inLen) : mData(inData), mLen(inLen)
   {
      pub.init_source = my_init_source;
      pub.fill_input_buffer = my_fill_input_buffer;
      pub.skip_input_data = my_skip_input_data;
      pub.resync_to_restart = my_resync_to_restart;
      pub.term_source = my_term_source;
      pub.next_input_byte = 0;
      pub.bytes_in_buffer = 0;
      mUsed = false;
      mEOI[0] = 0xff;
      mEOI[1] = JPEG_EOI;
   }

   struct jpeg_source_mgr pub;   /* public fields */
   const JOCTET * mData;
   size_t mLen;
   bool   mUsed;
   unsigned char mEOI[2];

   static void my_init_source(j_decompress_ptr cinfo)
   {
      MySrcManager *man = (MySrcManager *)cinfo->src;
      man->mUsed = false;
   }
   static boolean my_fill_input_buffer(j_decompress_ptr cinfo)
   {
      MySrcManager *man = (MySrcManager *)cinfo->src;
      if (man->mUsed)
      {
          man->pub.next_input_byte = man->mEOI;
          man->pub.bytes_in_buffer = 2;
      }
      else
      {
         man->pub.next_input_byte = man->mData;
         man->pub.bytes_in_buffer = man->mLen;
         man->mUsed = true;
      }
      return true;
   }
   static void my_skip_input_data(j_decompress_ptr cinfo, long num_bytes)
   {
      MySrcManager *man = (MySrcManager *)cinfo->src;
      man->pub.next_input_byte += num_bytes;
      man->pub.bytes_in_buffer -= num_bytes;
      if (man->pub.bytes_in_buffer == 0) // was < 0 and was always false PJK 16JUN12
      {
         man->pub.next_input_byte = man->mEOI;
         man->pub.bytes_in_buffer = 2;
      }
   }
   static boolean my_resync_to_restart(j_decompress_ptr cinfo, int desired)
   {
      MySrcManager *man = (MySrcManager *)cinfo->src;
      man->mUsed = false;
      return true;
   }
   static void my_term_source(j_decompress_ptr cinfo)
   {
   }
 };

static Surface *TryJPEG(FILE *inFile,const uint8 *inData, int inDataLen)
{
   struct jpeg_decompress_struct cinfo;

   // Don't exit on error!
   struct ErrorData jpegError;
   cinfo.err = jpeg_std_error(&jpegError.base);
   jpegError.base.error_exit = OnError;
   jpegError.base.output_message = OnOutput;

   Surface *result = 0;
   uint8 *row_buf = 0;

   // Establish the setjmp return context for ErrorFunction to use
   if (setjmp(jpegError.on_error))
   {
      if (row_buf)
         free(row_buf);
      if (result)
         result->DecRef();

      jpeg_destroy_decompress(&cinfo);
      return 0;
   }

   // Initialize the JPEG decompression object.
   jpeg_create_decompress(&cinfo);

   // Specify data source (ie, a file, or buffer)
   MySrcManager manager(inData,inDataLen);
   if (inFile)
      jpeg_stdio_src(&cinfo, inFile);
   else
   {
      cinfo.src = &manager.pub;
   }

   // Read file parameters with jpeg_read_header().
   if (jpeg_read_header(&cinfo, TRUE)!=JPEG_HEADER_OK)
      return 0;

   cinfo.out_color_space = JCS_RGB;

   // Start decompressor.
   jpeg_start_decompress(&cinfo);

   result = new SimpleSurface(cinfo.output_width, cinfo.output_height, pfXRGB);
   result->IncRef();


   RenderTarget target = result->BeginRender(Rect(cinfo.output_width, cinfo.output_height));


   row_buf = (uint8 *)malloc(cinfo.output_width * 3);

   while (cinfo.output_scanline < cinfo.output_height)
   {
      uint8 * src = row_buf;
      uint8 * dest = target.Row(cinfo.output_scanline);

      jpeg_read_scanlines(&cinfo, &row_buf, 1);

      uint8 *end = dest + cinfo.output_width*4;
      while (dest<end)
      {
         dest[0] = src[2];
         dest[1] = src[1];
         dest[2] = src[0];
         dest[3] = 0xff;
         dest+=4;
         src+=3;
      }
   }
   result->EndRender();

   free(row_buf);

   // Finish decompression.
   jpeg_finish_decompress(&cinfo);

   // Release JPEG decompression object
   jpeg_destroy_decompress(&cinfo);

   return result;
}

struct MyDestManager
{
   enum { BUF_SIZE = 4096 };
   struct jpeg_destination_mgr pub;   /* public fields */
   QuickVec<uint8> mOutput;
   uint8   mTmpBuf[BUF_SIZE];

   MyDestManager()
   {
      pub.init_destination    = init_buffer;
      pub.empty_output_buffer = copy_buffer;
      pub.term_destination    = term_buffer;
      pub.next_output_byte    = mTmpBuf;
      pub.free_in_buffer      = BUF_SIZE;
   }

   void CopyBuffer()
   {
      mOutput.append( mTmpBuf, BUF_SIZE);
      pub.next_output_byte    = mTmpBuf;
      pub.free_in_buffer      = BUF_SIZE;
   }

   void TermBuffer()
   {
      mOutput.append( mTmpBuf, BUF_SIZE - pub.free_in_buffer );
   }


   static void init_buffer(jpeg_compress_struct* cinfo) {}

   static boolean copy_buffer(jpeg_compress_struct* cinfo)
   {
      MyDestManager *man = (MyDestManager *)cinfo->dest;
      man->CopyBuffer( );
      return TRUE;
   }

   static void term_buffer(jpeg_compress_struct* cinfo)
   {
      MyDestManager *man = (MyDestManager *)cinfo->dest;
      man->TermBuffer();
   }

};



static bool EncodeJPG(Surface *inSurface, ByteArray *outBytes,double inQuality)
{
     struct jpeg_compress_struct cinfo;

   // Don't exit on error!
   struct ErrorData jpegError;
   cinfo.err = jpeg_std_error(&jpegError.base);
   jpegError.base.error_exit = OnError;
   jpegError.base.output_message = OnOutput;

   MyDestManager dest;

   int w = inSurface->Width();
   int h = inSurface->Height();
   QuickVec<uint8> row_buf(w*3);

   jpeg_create_compress(&cinfo);
 

   // Establish the setjmp return context for ErrorFunction to use
   if (setjmp(jpegError.on_error))
   {
      jpeg_destroy_compress(&cinfo);
      return false;
   }


   cinfo.dest = (jpeg_destination_mgr *)&dest;
 
   cinfo.image_width      = w;
   cinfo.image_height     = h;
   cinfo.input_components = 3;
   cinfo.in_color_space   = JCS_RGB;
 
   jpeg_set_defaults(&cinfo);
   jpeg_set_quality (&cinfo, (int)(inQuality * 100), true);
   jpeg_start_compress(&cinfo, true);
 
   JSAMPROW row_pointer = &row_buf[0];

   /* main code to write jpeg data */
   while (cinfo.next_scanline < cinfo.image_height)
   {
      const uint8 *src =  (const uint8 *)inSurface->Row(cinfo.next_scanline);
      uint8 *dest = &row_buf[0];

      for(int x=0;x<w;x++)
      {
         dest[0] = src[2];
         dest[1] = src[1];
         dest[2] = src[0];
         dest+=3;
         src+=4;
      }
      jpeg_write_scanlines(&cinfo, &row_pointer, 1);
   }
   jpeg_finish_compress(&cinfo);

   *outBytes = ByteArray(dest.mOutput);
 
   return true;
}



static void user_error_fn(png_structp png_ptr, png_const_charp error_msg)
{
   longjmp(png_ptr->jmp_buf_local, 1);
}
static void user_warning_fn(png_structp png_ptr, png_const_charp warning_msg) { }
static void user_read_data_fn(png_structp png_ptr, png_bytep data, png_size_t length)
{
    png_voidp buffer = png_get_io_ptr(png_ptr);
    ((ReadBuf *)buffer)->Read(data,length);
}

void user_write_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
    QuickVec<unsigned char> *buffer = (QuickVec<unsigned char> *)png_get_io_ptr(png_ptr);
    buffer->append((unsigned char *)data,(int)length);
} 
void user_flush_data(png_structp png_ptr) { }


static Surface *TryPNG(FILE *inFile,const uint8 *inData, int inDataLen)
{
   png_structp png_ptr;
   png_infop info_ptr;
   png_uint_32 width, height;
   int bit_depth, color_type, interlace_type;

   /* Create and initialize the png_struct with the desired error handler
    * functions.  If you want to use the default stderr and longjump method,
    * you can supply NULL for the last three parameters.  We also supply the
    * the compiler header file version, so that we know if the application
    * was compiled with a compatible version of the library.  REQUIRED
    */
   png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING,
      0, user_error_fn, user_warning_fn);

   if (png_ptr == NULL)
      return (0);

   /* Allocate/initialize the memory for image information.  REQUIRED. */
   info_ptr = png_create_info_struct(png_ptr);
   if (info_ptr == NULL)
   {
      png_destroy_read_struct(&png_ptr, (png_infopp)NULL, (png_infopp)NULL);
      return (0);
   }

   /* Set error handling if you are using the setjmp/longjmp method (this is
    * the normal method of doing things with libpng).  REQUIRED unless you
    * set up your own error handlers in the png_create_read_struct() earlier.
    */

   Surface *result = 0;
   RenderTarget target;

   if (setjmp(png_jmpbuf(png_ptr)))
   {
      if (result)
      {
         result->EndRender();
         result->DecRef();
      }

      /* Free all of the memory associated with the png_ptr and info_ptr */
      png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);
      /* If we get here, we had a problem reading the file */
      return (0);
   }

   ReadBuf buffer(inData,inDataLen);
   if (inFile)
   {
      png_init_io(png_ptr, inFile);
   }
   else
   {
      png_set_read_fn(png_ptr,(void *)&buffer, user_read_data_fn);
   }

   png_read_info(png_ptr, info_ptr);

   png_get_IHDR(png_ptr, info_ptr, &width, &height, &bit_depth, &color_type,
       &interlace_type, NULL, NULL);

   bool has_alpha = color_type== PNG_COLOR_TYPE_GRAY_ALPHA ||
                    color_type==PNG_COLOR_TYPE_RGB_ALPHA ||
                    png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS);
   
   /* Add filler (or alpha) byte (before/after each RGB triplet) */
   png_set_expand(png_ptr);
   png_set_filler(png_ptr, 0xff, PNG_FILLER_AFTER);
   //png_set_gray_1_2_4_to_8(png_ptr);
   png_set_palette_to_rgb(png_ptr);
   png_set_gray_to_rgb(png_ptr);

   // Stripping 16 bits per channel to 8 bits per channel.
   if (bit_depth == 16)
      png_set_strip_16(png_ptr);

   png_set_bgr(png_ptr);

   result = new SimpleSurface(width,height, (has_alpha) ? pfARGB : pfXRGB);
   result->IncRef();
   target = result->BeginRender(Rect(width,height));
   
   /* if the image is interlaced, run multiple passes */
   int number_of_passes = png_set_interlace_handling(png_ptr);
   
   for (int pass = 0; pass < number_of_passes; pass++)
   {
      for (int i = 0; i < height; i++)
      {
         png_bytep anAddr = (png_bytep) target.Row(i);
         png_read_rows(png_ptr, (png_bytepp) &anAddr, NULL, 1);
      }
   }

   result->EndRender();

   /* read rest of file, and get additional chunks in info_ptr - REQUIRED */
   png_read_end(png_ptr, info_ptr);

   /* clean up after the read, and free any memory allocated - REQUIRED */
   png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);

   /* that's it */
   return result;
}

static bool EncodePNG(Surface *inSurface, ByteArray *outBytes)
{
   /* initialize stuff */
   png_structp png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, user_error_fn, user_warning_fn);

   if (!png_ptr)
      return false;

   png_infop info_ptr = png_create_info_struct(png_ptr);
   if (!info_ptr)
      return false;

   if (setjmp(png_jmpbuf(png_ptr)))
   {
      /* Free all of the memory associated with the png_ptr and info_ptr */
      png_destroy_write_struct(&png_ptr, &info_ptr );
      /* If we get here, we had a problem reading the file */
      return false;
   }

   QuickVec<uint8> out_buffer;

   png_set_write_fn(png_ptr, &out_buffer, user_write_data, user_flush_data);

   int w = inSurface->Width();
   int h = inSurface->Height();

   int bit_depth = 8;
   int color_type = (inSurface->Format()&pfHasAlpha) ?
                    PNG_COLOR_TYPE_RGB_ALPHA :
                    PNG_COLOR_TYPE_RGB;
   png_set_IHDR(png_ptr, info_ptr, w, h,
           bit_depth, color_type, PNG_INTERLACE_NONE,
           PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

   png_write_info(png_ptr, info_ptr);

   bool do_alpha = color_type==PNG_COLOR_TYPE_RGBA;
   
   /*if (do_alpha)
   {
      QuickVec<png_bytep> row_pointers(h);
      for(int y=0;y<h;y++)
         row_pointers[y] = (png_bytep)inSurface->Row(y);
      png_write_image(png_ptr, &row_pointers[0]);
   }
   else*/
   {
      QuickVec<uint8> row_data(w*4);
      png_bytep row = &row_data[0];
      for(int y=0;y<h;y++)
      {
         uint8 *buf = &row_data[0];
         const uint8 *src = (const uint8 *)inSurface->Row(y);
         for(int x=0;x<w;x++)
         {
            buf[0] = src[2];
            buf[1] = src[1];
            buf[2] = src[0];
            src+=3;
            buf+=3;
            if (do_alpha)
               *buf++ = *src;
            src++;
         }
         png_write_rows(png_ptr, &row, 1);
      }
   }

   png_write_end(png_ptr, NULL);

   *outBytes = ByteArray(out_buffer);

   return true;
}

namespace nme {

Surface *Surface::Load(const OSChar *inFilename)
{
   FILE *file = OpenRead(inFilename);
   if (!file)
   {
      #ifdef ANDROID
      ByteArray bytes = AndroidGetAssetBytes(inFilename);
      if (bytes.Ok())
      {
         Surface *result = LoadFromBytes(bytes.Bytes(), bytes.Size());
         return result;
      }

      #endif
      return 0;
   }

   Surface *result = TryJPEG(file,0,0);
   if (!result)
   {
      rewind(file);
      result = TryPNG(file,0,0);
   }

   fclose(file);
   return result;
}

Surface *Surface::LoadFromBytes(const uint8 *inBytes,int inLen)
{
   if (!inBytes || !inLen)
      return 0;

   Surface *result = TryJPEG(0,inBytes,inLen);
   if (!result)
      result = TryPNG(0,inBytes,inLen);

   return result;
}

bool Surface::Encode( ByteArray *outBytes,bool inPNG,double inQuality)
{
   if (inPNG)
      return EncodePNG(this,outBytes);
   
   else
      return EncodeJPG(this,outBytes,inQuality);
}


}
