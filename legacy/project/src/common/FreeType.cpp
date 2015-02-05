#include <Font.h>
#include <Utils.h>
#include <map>

#ifdef HX_WINRT
#define generic userGeneric
#endif

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_BITMAP_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include <ftoutln.h>

#ifdef ANDROID
#include <android/log.h>
#endif

#ifdef WEBOS
#include "PDL.h"
#endif

#ifndef HX_WINDOWS
#ifndef EPPC
#include <dirent.h>
#include <sys/stat.h>
#endif
#endif

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
#define NOMINMAX
#include <windows.h>
#include <tchar.h>
#endif

#include "ByteArray.h"

#define NME_FREETYPE_FLAGS  (FT_LOAD_FORCE_AUTOHINT|FT_LOAD_DEFAULT)

namespace nme
{

FT_Library sgLibrary = 0;


class FreeTypeFont : public FontFace
{
public:
   FreeTypeFont(FT_Face inFace, int inPixelHeight, int inTransform, void* inBuffer) :
     mFace(inFace), mPixelHeight(inPixelHeight),mTransform(inTransform), mBuffer(inBuffer)
   {
   }


   ~FreeTypeFont()
   {
      FT_Done_Face(mFace);
	  if (mBuffer) free(mBuffer);
   }

   bool LoadBitmap(int inChar)
   {
      int idx = FT_Get_Char_Index( mFace, inChar );

      int renderFlags = FT_LOAD_DEFAULT;
      //if (!(mTransform & (ffItalic|ffBold) ))
         renderFlags |= FT_LOAD_FORCE_AUTOHINT;

      int err = FT_Load_Glyph( mFace, idx, renderFlags  );
      if (err)
         return false;

      bool emboldened = false;
      if (mTransform & ffItalic)
      {
         if ( mFace->glyph->format == FT_GLYPH_FORMAT_OUTLINE )
         {
            FT_Outline*  outline = &mFace->glyph->outline;

            FT_Matrix    transform;
            transform.xx = 0x10000L;
            transform.yx = 0x00000L;
            transform.xy = 0x06000L;
            transform.yy = 0x10000L;

            FT_Outline_Transform( outline, &transform );
         }
      }

      if (mTransform & ffBold)
      {
         if ( mFace->glyph->format == FT_GLYPH_FORMAT_OUTLINE )
         {
            emboldened = true;
            FT_Outline*  outline = &mFace->glyph->outline;
            FT_Outline_Embolden( outline, 1<<6 );
         }
      }




      FT_Render_Mode mode = FT_RENDER_MODE_NORMAL;
      // mode = FT_RENDER_MODE_MONO;
      if (mFace->glyph->format != FT_GLYPH_FORMAT_BITMAP)
         err = FT_Render_Glyph( mFace->glyph, mode );
      if (err)
         return false;

      #ifndef GPH
      if (mTransform & ffBold)
      {
         if ( mFace->glyph->format != FT_GLYPH_FORMAT_OUTLINE && !emboldened)
         {
            FT_GlyphSlot_Own_Bitmap(mFace->glyph);
            FT_Bitmap_Embolden(sgLibrary, &mFace->glyph->bitmap, 1<<6, 0);
         }
      }
      #endif
      return true;
   }

   int getUnderlineOffset() { return 1; }
   int getUnderlineHeight() { return getUnderlineOffset(); }


   bool GetGlyphInfo(int inChar, int &outW, int &outH, int &outAdvance,
                           int &outOx, int &outOy)
   {
      if (!LoadBitmap(inChar))
         return false;

      outOx = mFace->glyph->bitmap_left;
      outOy = -mFace->glyph->bitmap_top;
      FT_Bitmap &bitmap = mFace->glyph->bitmap;
      outW = bitmap.width;
      outH = bitmap.rows;

      if (mTransform & ffUnderline)
      {
         int underlineY0 = mFace->glyph->bitmap_top + getUnderlineOffset();
         int underlineY1 = underlineY0 + getUnderlineHeight();
         if (outH<underlineY1)
            outH = underlineY1;
      }

      outAdvance = (mFace->glyph->advance.x);
      return true;
   }


   void RenderGlyph(int inChar,const RenderTarget &outTarget)
   {
      if (!LoadBitmap(inChar))
         return;

      int underlineY0 = -1;
      int underlineY1 = -1;

      FT_Bitmap &bitmap = mFace->glyph->bitmap;
      int w = bitmap.width;
      int h = bitmap.rows;


      if (mTransform & ffUnderline)
      {
         underlineY0 = mFace->glyph->bitmap_top + getUnderlineOffset();
         underlineY1 = underlineY0 + getUnderlineHeight();
      }

      if (h<underlineY1)
         h = underlineY1;

      if (w>outTarget.mRect.w || h>outTarget.mRect.h)
         return;

      for(int r=0;r<h;r++)
      {
         uint8  *dest = (uint8 *)outTarget.Row(r + outTarget.mRect.y) + outTarget.mRect.x;

         int underline = (r>=underlineY0 && r<underlineY1) ? 0xff : 0;

         if (r<bitmap.rows)
         {
            unsigned char *row = bitmap.buffer + r*bitmap.pitch;
            if (bitmap.pixel_mode == FT_PIXEL_MODE_MONO)
            {
               int bit = 0;
               int data = 0;
               for(int x=0;x<outTarget.mRect.w;x++)
               {
                  if (!bit)
                  {
                     bit = 128;
                     data = *row++;
                  }
                  *dest++ =  (underline || (data & bit)) ? 0xff: 0x00;
                  bit >>= 1;
               }
            }
            else if (bitmap.pixel_mode == FT_PIXEL_MODE_GRAY)
            {
               for(int x=0;x<w;x++)
                  *dest ++ = *row++ | underline;
            }
         }
         else if (r>=underlineY0 && r<underlineY1)
         {
            memset( dest, 0xff, bitmap.pixel_mode == FT_PIXEL_MODE_MONO ? w/8 : w);
         }
         else
         {
            memset( dest, 0x00, bitmap.pixel_mode == FT_PIXEL_MODE_MONO ? w/8 : w);
         }
      }
   }


   int Height()
   {
      return mFace->size->metrics.height/(1<<6);
   }


   void UpdateMetrics(TextLineMetrics &ioMetrics)
   {
      if (mFace)
      {
         FT_Size_Metrics &metrics = mFace->size->metrics;
         ioMetrics.ascent = std::max( ioMetrics.ascent, (float)metrics.ascender/(1<<6) );
         ioMetrics.descent = std::max( ioMetrics.descent, (float)fabs((float)metrics.descender/(1<<6)) );
         ioMetrics.height = std::max( ioMetrics.height, (float)metrics.height/(1<<6) );
      }
   }

   
   void* mBuffer;
   FT_Face  mFace;
   uint32 mTransform;
   int    mPixelHeight;

};

int MyNewFace(const std::string &inFace, int inIndex, FT_Face *outFace, AutoGCRoot *inBytes, void** outBuffer)
{
   *outFace = 0;
   *outBuffer = 0;
   int result = 0;
   result = FT_New_Face(sgLibrary, inFace.c_str(), inIndex, outFace);
   if (*outFace==0)
   {
     ByteArray bytes;
     if (inBytes == 0)
     {
         bytes = ByteArray::FromFile(inFace.c_str());
     }
     else
     {
         bytes = ByteArray(inBytes->get());
     }
      if (bytes.Ok())
      {
         int l = bytes.Size();
         unsigned char *buf = (unsigned char*)malloc(l);
         memcpy(buf,bytes.Bytes(),l);
         result = FT_New_Memory_Face(sgLibrary, buf, l, inIndex, outFace);

         // The font owns the bytes here - so we just leak (fonts are not actually cleaned)
         if (!*outFace)
            free(buf);
         else *outBuffer = buf;
      }
   }
   return result;
}





static FT_Face OpenFont(const std::string &inFace, unsigned int inFlags, AutoGCRoot *inBytes, void** outBuffer)
{
   *outBuffer = 0;
   FT_Face face = 0;
   void* pBuffer = 0;
   MyNewFace(inFace.c_str(), 0, &face, inBytes, &pBuffer);
   if (face && inFlags!=0 && face->num_faces>1)
   {
      int n = face->num_faces;
      // Look for other font that may match
      for(int f=1;f<n;f++)
      {
         FT_Face test = 0;
         void* pTestBuffer = 0;
         MyNewFace(inFace.c_str(), f, &test, NULL, &pTestBuffer);
         if (test && test->style_flags == inFlags)
         {
            // A goodie!
            FT_Done_Face(face);
            if (pBuffer) free(pBuffer);
            *outBuffer = pTestBuffer;
            return test;
         }
         else if (test)
            FT_Done_Face(test);
      }
      // The original face will have to do...
   }
   *outBuffer = pBuffer;
   return face;
}





#ifdef HX_WINRT

bool GetFontFile(const std::string& inName,std::string &outFile)
{
   return false;
}

#elif defined(HX_WINDOWS)

#define strcasecmp stricmp

bool GetFontFile(const std::string& inName,std::string &outFile)
{
   
   std::string name = inName;
   
   if (!strcasecmp(inName.c_str(),"_serif"))
   {
      name = "georgia.ttf";
   }
   else if (!strcasecmp(inName.c_str(),"_sans"))
   {
      name = "arial.ttf";
   }
   else if (!strcasecmp(inName.c_str(),"_typewriter"))
   {
      name = "cour.ttf";
   }
   
   _TCHAR win_path[2 * MAX_PATH];
   GetWindowsDirectory(win_path, 2*MAX_PATH);
   outFile = std::string(win_path) + "\\Fonts\\" + name;

   return true;
}


#elif defined(GPH)

bool GetFontFile(const std::string& inName,std::string &outFile)
{
   outFile = "/usr/gp2x/HYUni_GPH_B.ttf";
   return true;
}

#elif defined(__APPLE__)
bool GetFontFile(const std::string& inName,std::string &outFile)
{
// printf("Looking for font %s...", inName.c_str() );

#ifdef IPHONEOS
#define FONT_BASE "/System/Library/Fonts/Cache/"
#else
#define FONT_BASE "/Library/Fonts/"
#endif

   outFile = FONT_BASE + inName;
   FILE *file = fopen(outFile.c_str(),"rb");
   if (file)
   {
      //printf("Found actual file %s\n", outFile.c_str());
      fclose(file);
      return true;
   }



   const char *serifFonts[] = { "Georgia.ttf", "Times.ttf", "Times New Roman.ttf", 0 };
   const char *sansFonts[] = { "Arial Black.ttf", "Arial.ttf", "Helvetica.ttf", 0 };
   const char *fixedFonts[] = { "Courier New.ttf", "Courier.ttf", 0 };

   const char **test = 0;

   if (!strcasecmp(inName.c_str(),"_serif") || !strcasecmp(inName.c_str(),"times.ttf") || !strcasecmp(inName.c_str(),"times"))
      test = serifFonts;
   else if (!strcasecmp(inName.c_str(),"_sans") || !strcasecmp(inName.c_str(),"helvetica.ttf"))
      test = sansFonts;
   else if (!strcasecmp(inName.c_str(),"_typewriter") || !strcasecmp(inName.c_str(),"courier.ttf"))
      test = fixedFonts;
   else if (!strcasecmp(inName.c_str(),"arial.ttf"))
      test = sansFonts;

   if (test)
   {
      while(*test)
      {
         outFile = FONT_BASE + std::string(*test);

         //printf("Try %s\n", outFile.c_str());

	 FILE *file = fopen(outFile.c_str(),"rb");
	 if (file)
	 {
	    //printf("Found sub file %s\n", outFile.c_str());
	    fclose(file);
	    return true;
	 }
         test++;
      }
   }

   return false;
}
#else

bool GetFontFile(const std::string& inName,std::string &outFile)
{
   const char *alternate = 0;
   if (!strcasecmp(inName.c_str(),"_serif") ||
       !strcasecmp(inName.c_str(),"times.ttf") || !strcasecmp(inName.c_str(),"times"))
   {
      
      #if defined (ANDROID)
         outFile = "/system/fonts/DroidSerif-Regular.ttf";
         alternate = "/system/fonts/NotoSerif-Regular.ttf";
      #elif defined (WEBOS)
         outFile = "/usr/share/fonts/times.ttf";
      #elif defined (BLACKBERRY)
         outFile = "/usr/fonts/font_repository/monotype/times.ttf";
      #elif defined (TIZEN)
         outFile = "/usr/share/fonts/TizenSansRegular.ttf";
      #else
         outFile = "/usr/share/fonts/truetype/freefont/FreeSerif.ttf";
      #endif
      
   }
   else if (!strcasecmp(inName.c_str(),"_sans") || !strcasecmp(inName.c_str(),"arial.ttf") ||
              !strcasecmp(inName.c_str(),"arial") || !strcasecmp(inName.c_str(),"sans-serif") )
   {
      
      #if defined (ANDROID)
         outFile = "/system/fonts/DroidSans.ttf";
      #elif defined (WEBOS)
         outFile = "/usr/share/fonts/Prelude-Medium.ttf";
      #elif defined (BLACKBERRY)
         outFile = "/usr/fonts/font_repository/monotype/arial.ttf";
      #elif defined (TIZEN)
         outFile = "/usr/share/fonts/TizenSansRegular.ttf";
      #else
         outFile = "/usr/share/fonts/truetype/freefont/FreeSans.ttf";
      #endif
      
   }
   else if (!strcasecmp(inName.c_str(),"_typewriter") || !strcasecmp(inName.c_str(),"courier.ttf") || !strcasecmp(inName.c_str(),"courier"))
   {
      #if defined (ANDROID)
         outFile = "/system/fonts/DroidSansMono.ttf";
      #elif defined (WEBOS)
         outFile = "/usr/share/fonts/cour.ttf";
      #elif defined (BLACKBERRY)
         outFile = "/usr/fonts/font_repository/monotype/cour.ttf";
      #elif defined (TIZEN)
         outFile = "/usr/share/fonts/TizenSansRegular.ttf";
      #else
         outFile = "/usr/share/fonts/truetype/freefont/FreeMono.ttf";
      #endif
      
   }
   else
   {
      #ifdef ANDROID
       //__android_log_print(ANDROID_LOG_INFO, "GetFontFile", "Could not load font %s.", inName.c_str() );
       #endif
      
      //printf("Unfound font: %s\n",inName.c_str());
      return false;
   }

   #ifdef ANDROID
   if (alternate)
   {
       struct stat s;
       if (stat(outFile.c_str(),&s)!=0 && stat(alternate,&s)==0)
          outFile = alternate;
   }

    //__android_log_print(ANDROID_LOG_INFO, "GetFontFile", "mapped '%s' to '%s'.", inName.c_str(), outFile.c_str());
   #endif
   return true;
}
#endif


std::string ToAssetName(const std::string &inPath)
{
#if HX_MACOS
   std::string flat;
   for(int i=0;i<inPath.size();i++)
   {
      int ch = inPath[i];
      if ( (ch>='a' && ch<='z') || (ch>='0' && ch<='9') )
         { }
      else if (ch>='A' && ch<='Z')
         ch += 'a' - 'A';
      else
         ch = '_';

      flat.push_back(ch);
   }

   char name[1024];
   GetBundleFilename(flat.c_str(),name,1024);
   return name;
#else
   return gAssetBase + "/" + inPath;
#endif
}

FT_Face FindFont(const std::string &inFontName, unsigned int inFlags, AutoGCRoot *inBytes, void** pBuffer)
{
   std::string fname = inFontName;
   
   #ifndef ANDROID
   if (fname.find(".") == std::string::npos && fname.find("_") == std::string::npos)
      fname += ".ttf";
   #endif
     
   FT_Face font = OpenFont(fname,inFlags,inBytes, pBuffer);

   if (font==0 && fname.find("\\")==std::string::npos && fname.find("/")==std::string::npos)
   {
      std::string file_name;

      #if HX_MACOS
      font = OpenFont(ToAssetName(fname).c_str(),inFlags,NULL,pBuffer);
      #endif

      if (font==0 && GetFontFile(fname,file_name))
      {
         // printf("Found font in %s\n", file_name.c_str());
         font = OpenFont(file_name.c_str(),inFlags,NULL,pBuffer);

         // printf("Opened : %p\n", font);
      }
   }


   return font;
}




FontFace *FontFace::CreateFreeType(const TextFormat &inFormat,double inScale,AutoGCRoot *inBytes)
{
   if (!sgLibrary)
     FT_Init_FreeType( &sgLibrary );
   if (!sgLibrary)
      return 0;

   FT_Face face = 0;
   std::string str = WideToUTF8(inFormat.font);

   uint32 flags = 0;
   if (inFormat.bold)
      flags |= ffBold;
   if (inFormat.italic)
      flags |= ffItalic;
   
   void* pBuffer = 0;
   face = FindFont(str,flags,inBytes,&pBuffer);
   if (!face)
      return 0;

   int height = (int )(inFormat.size*inScale + 0.5);
   FT_Set_Pixel_Sizes(face,0, height);


   uint32 transform = 0;
   if ( !(face->style_flags & ffBold) && inFormat.bold )
      transform |= ffBold;
   if ( !(face->style_flags & ffItalic) && inFormat.italic )
      transform |= ffItalic;
   if ( inFormat.underline )
      transform |= ffUnderline;
   return new FreeTypeFont(face,height,transform,pBuffer);
}





} // end namespace nme

#include <hx/CFFI.h>

// Font outlines as data - from the SamHaXe project

#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_OUTLINE_H

namespace {
enum {
   PT_MOVE = 1,
   PT_LINE = 2,
   PT_CURVE = 3
};

struct point {
   int            x, y;
   unsigned char  type;

   point() { }
   point(int x, int y, unsigned char type) : x(x), y(y), type(type) { }
};

struct glyph {
   FT_ULong                char_code;
   FT_Vector               advance;
   FT_Glyph_Metrics        metrics;
   int                     index, x, y;
   std::vector<int>        pts;

   glyph(): x(0), y(0) { }
};

struct kerning {
   int                     l_glyph, r_glyph;
   int                     x, y;

   kerning() { }
   kerning(int l, int r, int x, int y): l_glyph(l), r_glyph(r), x(x), y(y) { }
};

struct glyph_sort_predicate {
   bool operator()(const glyph* g1, const glyph* g2) const {
      return g1->char_code <  g2->char_code;
   }
};

#ifdef GPH
typedef FT_Vector *FVecPtr;
#else
typedef const FT_Vector *FVecPtr;
#endif

int outline_move_to(FVecPtr to, void *user) {
   glyph       *g = static_cast<glyph*>(user);

   g->pts.push_back(PT_MOVE);
   g->pts.push_back(to->x);
   g->pts.push_back(to->y);

   g->x = to->x;
   g->y = to->y;
   
   return 0;
}

int outline_line_to(FVecPtr to, void *user) {
   glyph       *g = static_cast<glyph*>(user);

   g->pts.push_back(PT_LINE);
   g->pts.push_back(to->x - g->x);
   g->pts.push_back(to->y - g->y);
   
   g->x = to->x;
   g->y = to->y;
   
   return 0;
}

int outline_conic_to(FVecPtr ctl, FVecPtr to, void *user) {
   glyph       *g = static_cast<glyph*>(user);

   g->pts.push_back(PT_CURVE);
   g->pts.push_back(ctl->x - g->x);
   g->pts.push_back(ctl->y - g->y);
   g->pts.push_back(to->x - ctl->x);
   g->pts.push_back(to->y - ctl->y);
   
   g->x = to->x;
   g->y = to->y;
   
   return 0;
}

int outline_cubic_to(FVecPtr, FVecPtr , FVecPtr , void *user) {
   // Cubic curves are not supported
   return 1;
}

wchar_t *get_familyname_from_sfnt_name(FT_Face face)
{
   wchar_t *family_name = NULL;
   FT_SfntName sfnt_name;
   FT_UInt num_sfnt_names, sfnt_name_index;
   int len, i;
   
   if (FT_IS_SFNT(face))
   {
      num_sfnt_names = FT_Get_Sfnt_Name_Count(face);
      sfnt_name_index = 0;
      while (sfnt_name_index < num_sfnt_names)
      {
         if (!FT_Get_Sfnt_Name(face, sfnt_name_index++, (FT_SfntName *)&sfnt_name) && sfnt_name.name_id == TT_NAME_ID_FULL_NAME)
         {
            if (sfnt_name.platform_id == TT_PLATFORM_MACINTOSH)
            {
               len = sfnt_name.string_len;
               family_name = new wchar_t[len + 1];
               mbstowcs(&family_name[0], &reinterpret_cast<const char*>(sfnt_name.string)[0], len);
               family_name[len] = L'\0';
               return family_name;
            }
            else if ((sfnt_name.platform_id == TT_PLATFORM_MICROSOFT) && (sfnt_name.encoding_id == TT_MS_ID_UNICODE_CS))
            {
               /* Note that most fonts contains a Unicode charmap using
                  TT_PLATFORM_MICROSOFT, TT_MS_ID_UNICODE_CS.
               */
               
               /* .string :
                     Note that its format differs depending on the 
                     (platform,encoding) pair. It can be a Pascal String, 
                     a UTF-16 one, etc..
                     Generally speaking, the string is "not" zero-terminated.
                     Please refer to the TrueType specification for details..
                      
                  .string_len :
                     The length of `string' in bytes.
               */
               
               len = sfnt_name.string_len / 2;
               family_name = (wchar_t*)malloc((len + 1) * sizeof(wchar_t));
               for(i = 0; i < len; i++)
               {
                  family_name[i] = ((wchar_t)sfnt_name.string[i*2 + 1]) | (((wchar_t)sfnt_name.string[i*2]) << 8);
               }
               family_name[len] = L'\0';
               return family_name;
            }
         }
      }
   }
   
   return NULL;
}

} // end namespace

value freetype_init()
{
   if (!nme::sgLibrary)
     FT_Init_FreeType( &nme::sgLibrary );

   return alloc_bool(nme::sgLibrary);
}
DEFINE_PRIM(freetype_init, 0);

value freetype_import_font(value font_file, value char_vector, value em_size, value inBytes)
{
   freetype_init();

   FT_Face           face;
   int               result, i, j;

   val_check(font_file, string);
   val_check(em_size, int);
   
   AutoGCRoot *bytes = !val_is_null(inBytes) ? new AutoGCRoot(inBytes) : NULL;

   void* pBuffer = 0;
   result = nme::MyNewFace(val_string(font_file), 0, &face, bytes, &pBuffer);
   
   if (result == FT_Err_Unknown_File_Format)
   {
      val_throw(alloc_string("Unknown file format!"));
      return alloc_null();
   }
   else if (result != 0)
   {
      val_throw(alloc_string("File open error!"));
      return alloc_null();
   }

   if (!FT_IS_SCALABLE(face))
   {
      FT_Done_Face(face);
      if (pBuffer) free(pBuffer);
      
      val_throw(alloc_string("Font is not scalable!"));
      return alloc_null();
   }


   int em = val_int(em_size);

   FT_Set_Char_Size(face, em, em, 72, 72);

   std::vector<glyph*> glyphs;

   FT_Outline_Funcs ofn =
   {
      outline_move_to,
      outline_line_to,
      outline_conic_to,
      outline_cubic_to,
      0, // shift
      0  // delta
   };

   if (!val_is_null(char_vector))
   {
      // Import only specified characters
      int  num_char_codes = val_array_size(char_vector);

      for(i=0; i<num_char_codes; i++)
      {
         FT_ULong    char_code = (FT_ULong)val_int(val_array_i(char_vector,i));
         FT_UInt     glyph_index = FT_Get_Char_Index(face, char_code);

         if(glyph_index != 0 && FT_Load_Glyph(face, glyph_index, NME_FREETYPE_FLAGS) == 0)
         {
            glyph *g = new glyph;

            result = FT_Outline_Decompose(&face->glyph->outline, &ofn, g);
            if(result == 0)
            {
               g->index = glyph_index;
               g->char_code = char_code;
               g->metrics = face->glyph->metrics;
               glyphs.push_back(g);
            }
            else
               delete g;
         }
      }

   }
   else
   {
      // Import every character in face
      FT_ULong    char_code;
      FT_UInt     glyph_index;

      char_code = FT_Get_First_Char(face, &glyph_index);
      while(glyph_index != 0)
      {
         if(FT_Load_Glyph(face, glyph_index, NME_FREETYPE_FLAGS) == 0)
         {
            glyph *g = new glyph;

            result = FT_Outline_Decompose(&face->glyph->outline, &ofn, g);
            if(result == 0)
            {
               g->index = glyph_index;
               g->char_code = char_code;
               g->metrics = face->glyph->metrics;
               glyphs.push_back(g);
            }
            else
               delete g;
         }
         
         char_code = FT_Get_Next_Char(face, char_code, &glyph_index);  
      }
   }

   // Ascending sort by character codes
   std::sort(glyphs.begin(), glyphs.end(), glyph_sort_predicate());

   std::vector<kerning>  kern;
   if (FT_HAS_KERNING(face))
   {
      int         n = glyphs.size();
      FT_Vector   v;

      for(i = 0; i < n; i++)
      {
         int  l_glyph = glyphs[i]->index;

         for(j = 0; j < n; j++)
         {
            int   r_glyph = glyphs[j]->index;

            FT_Get_Kerning(face, l_glyph, r_glyph, FT_KERNING_DEFAULT, &v);
            if(v.x != 0 || v.y != 0)
               kern.push_back( kerning(i, j, v.x, v.y) );
         }
      }
   }
   
   int               num_glyphs = glyphs.size();
   wchar_t*          family_name = get_familyname_from_sfnt_name(face);
   
   value             ret = alloc_empty_object();
   alloc_field(ret, val_id("has_kerning"), alloc_bool(FT_HAS_KERNING(face)));
   alloc_field(ret, val_id("is_fixed_width"), alloc_bool(FT_IS_FIXED_WIDTH(face)));
   alloc_field(ret, val_id("has_glyph_names"), alloc_bool(FT_HAS_GLYPH_NAMES(face)));
   alloc_field(ret, val_id("is_italic"), alloc_bool(face->style_flags & FT_STYLE_FLAG_ITALIC));
   alloc_field(ret, val_id("is_bold"), alloc_bool(face->style_flags & FT_STYLE_FLAG_BOLD));
   alloc_field(ret, val_id("num_glyphs"), alloc_int(num_glyphs));
   alloc_field(ret, val_id("family_name"), family_name == NULL ? alloc_string(face->family_name) : alloc_wstring(family_name));
   alloc_field(ret, val_id("style_name"), alloc_string(face->style_name));
   alloc_field(ret, val_id("em_size"), alloc_int(face->units_per_EM));
   alloc_field(ret, val_id("ascend"), alloc_int(face->ascender));
   alloc_field(ret, val_id("descend"), alloc_int(face->descender));
   alloc_field(ret, val_id("height"), alloc_int(face->height));

   // 'glyphs' field
   value             neko_glyphs = alloc_array(num_glyphs);
   for(i=0; i < glyphs.size(); i++)
   {
      glyph          *g = glyphs[i];
      int            num_points = g->pts.size();

      value          points = alloc_array(num_points);
      
      for(j = 0; j < num_points; j++)
         val_array_set_i(points,j,alloc_int(g->pts[j]));

      value item = alloc_empty_object();
      val_array_set_i(neko_glyphs,i,item);
      alloc_field(item, val_id("char_code"), alloc_int(g->char_code));
      alloc_field(item, val_id("advance"), alloc_int(g->metrics.horiAdvance));
      alloc_field(item, val_id("min_x"), alloc_int(g->metrics.horiBearingX));
      alloc_field(item, val_id("max_x"), alloc_int(g->metrics.horiBearingX + g->metrics.width));
      alloc_field(item, val_id("min_y"), alloc_int(g->metrics.horiBearingY - g->metrics.height));
      alloc_field(item, val_id("max_y"), alloc_int(g->metrics.horiBearingY));
      alloc_field(item, val_id("points"), points);

      delete g;
   }
   alloc_field(ret, val_id("glyphs"), neko_glyphs);

   // 'kerning' field
   if (FT_HAS_KERNING(face))
   {
      value       neko_kerning = alloc_array(kern.size());

      for(i = 0; i < kern.size(); i++)
      {
         kerning  *k = &kern[i];

         value item = alloc_empty_object();
         val_array_set_i(neko_kerning,i,item);
         alloc_field(item, val_id("left_glyph"), alloc_int(k->l_glyph));
         alloc_field(item, val_id("right_glyph"), alloc_int(k->r_glyph));
         alloc_field(item, val_id("x"), alloc_int(k->x));
         alloc_field(item, val_id("y"), alloc_int(k->y));
      }
      
      alloc_field(ret, val_id("kerning"), neko_kerning);
   }
   else
      alloc_field(ret, val_id("kerning"), alloc_null());

   FT_Done_Face(face);
   if (pBuffer) free(pBuffer);
   
   return ret;
}

DEFINE_PRIM(freetype_import_font, 4);


bool ChompEnding(std::string &ioName, const std::string &inEnding)
{
   int leadIn =  ioName.size() - inEnding.size();
   if (leadIn>0 && ioName.substr(leadIn)==inEnding)
   {
      ioName = ioName.substr(0,leadIn);
      return true;
   }
   return false;
}

void SendFont(std::string name, value inFunc)
{
   enum FontStyle
   {
      BOLD,
      BOLD_ITALIC,
      ITALIC,
      REGULAR,
   };
   size_t pos = name.find_last_of('.');
   if (pos!=std::string::npos)
      name = name.substr(0,pos);

   FontStyle style = REGULAR; 
   if (ChompEnding(name," Bold Italic"))
      style = BOLD_ITALIC;
   else if (ChompEnding(name," Italic"))
      style = ITALIC;
   else if (ChompEnding(name," Bold"))
      style = BOLD;
      
   val_call2(inFunc,alloc_string_len(name.c_str(),name.size()), alloc_int(style) );
}

#ifndef HX_WINRT


void ItererateFontDir(const std::string &inDir, value inFunc, int inMaxDepth)
{
   #ifdef HX_WINDOWS
   std::string search = inDir + "*.ttf";

   WIN32_FIND_DATA d;
   HANDLE handle = FindFirstFile(search.c_str(),&d);
   if( handle == INVALID_HANDLE_VALUE )
   {
      return;
   }
   while( true )
   {
      // skip magic dirs
      //if( d.cFileName[0] != '.' || (d.cFileName[1] != 0 && (d.cFileName[1] != '.' || d.cFileName[2] != 0)) )
      SendFont(d.cFileName,inFunc);

      if( !FindNextFile(handle,&d) )
         break;
   }
   #elif !defined(EPPC)
   DIR *d = opendir(inDir.c_str());
   if (d)
   {
      while( true )
      {
         struct dirent *e = readdir(d);
         if (!e)
           break;
         // skip magic dirs
         if( e->d_name[0] == '.' && (e->d_name[1] == 0 || (e->d_name[1] == '.' && e->d_name[2] == 0)) )
            continue;
         std::string full = inDir + e->d_name + "/";

         struct stat s;
         if ( inMaxDepth>0 && stat(full.c_str(),&s)==0 && (s.st_mode & S_IFDIR) )
         {
            // TODO - record sub directory for later?
            ItererateFontDir(full, inFunc, inMaxDepth-1);
         }
         else
         {
            const char *dot = e->d_name;
            while(*dot && *dot!='.') dot++;
            if (dot && !strcmp(dot+1,"ttf"))
              SendFont(e->d_name,inFunc);
         }
      }
      closedir(d);
   }
   #endif
}
#endif

value nme_font_iterate_device_fonts(value inFunc)
{
   #ifndef HX_WINRT
      #ifdef HX_WINDOWS
      char win_path[2 * MAX_PATH];
      GetWindowsDirectory(win_path, 2*MAX_PATH);
      #endif
   
   
      std::string fontDir = 
         #if defined (ANDROID)
            "/system/fonts/";
         #elif defined (WEBOS)
            "/usr/share/fonts/";
         #elif defined (BLACKBERRY)
            "/usr/fonts/font_repository/";
         #elif defined(IPHONEOS)
            "/System/Library/Fonts/Cache/";
         #elif defined(__APPLE__)
            "/Library/Fonts/";
         #elif defined(HX_WINDOWS)
           std::string(win_path) + "\\Fonts\\";
         #else
            "/usr/share/fonts/truetype/";
         #endif
   
      ItererateFontDir(fontDir, inFunc, 1);
   #endif
   
   return alloc_null();
}

DEFINE_PRIM(nme_font_iterate_device_fonts,1)


