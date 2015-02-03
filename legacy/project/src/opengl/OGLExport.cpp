#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
// Include neko glue....
#define NEKO_COMPATIBLE
#endif


#define OGLEXPORT


#ifdef ANDROID
#include <android/log.h>
#include <EGL/egl.h>
#endif

#include <nme/NmeCffi.h>
#include <ByteArray.h>
#include "OGL.h"
#include "Utils.h"


#define INT(a) val_int(arg[a])


// --- General -------------------------------------------

namespace nme
{

int gDirectMaxAttribArray = 0;

enum ResoType
{
   resoNone, //0
   resoBuffer, //1
   resoTexture, //2
   resoShader, //3
   resoProgram, //4
   resoFramebuffer, //5
   resoRenderbuffer, //6
};

const char *getTypeString(int inType)
{
   switch(inType)
   {
      case resoNone: return "None";
      case resoBuffer: return "Buffer";
      case resoTexture: return "Texture";
      case resoShader: return "Shader";
      case resoProgram: return "Program";
      case resoFramebuffer: return "Framebuffer";
      case resoRenderbuffer: return "Renderbuffer";
   }
   return "Unknown";
}


struct NmeFloats
{
   int   floatCount;
   bool  deleteData;
   float *data;

   NmeFloats(value inArray)
   {
      floatCount = 0;
      data = 0;
      deleteData = false;

      if (val_is_array(inArray))
      {
         floatCount = val_array_size(inArray);
         float *f = val_array_float(inArray);
         if (f)
            data = f;
         else
         {
            data = new float[floatCount];
            deleteData = true;

            double *d = val_array_double(inArray);
            if (d)
            {
               for(int f=0;f<floatCount;f++)
                  data[f] = d[f];
            }
            else
            {
               int *i = val_array_int(inArray);
               if (i)
               {
                  for(int f=0;f<floatCount;f++)
                     data[f] = i[f];
               }
               else
               {
                  for(int f=0;f<floatCount;f++)
                     data[f] = val_number( val_array_i(inArray,f) );
               }
            }
         }
      }
      else
      {
         ByteArray bytes(inArray);
         data = (float *)bytes.Bytes();
         floatCount = bytes.Size()/sizeof(float);
      }
   }
   ~NmeFloats()
   {
      if (deleteData)
         delete [] data;
   }
};




struct NmeInts
{
   int   intCount;
   bool  deleteData;
   int   *data;

   NmeInts(value inArray)
   {
      intCount = 0;
      data = 0;
      deleteData = false;

      if (val_is_array(inArray))
      {
         intCount = val_array_size(inArray);
         int *i = val_array_int(inArray);
         if (i)
            data = i;
         else
         {
            data = new int[intCount];
            deleteData = true;

            for(int i=0;i<intCount;i++)
               data[i] = val_int( val_array_i(inArray,i) );
         }
      }
      else
      {
         ByteArray bytes(inArray);
         data = (int *)bytes.Bytes();
         intCount = bytes.Size()/sizeof(int);
      }
   }
   ~NmeInts()
   {
      if (deleteData)
         delete [] data;
   }
};




// #define CHECK_ERROR

const char *sDebugName = "init";
struct DebugFunc
{
   DebugFunc(const char *inName)
   {
      sDebugName = inName;
      #ifdef CHECK_ERROR
      int err = glGetError();
      if (err)
         ELOG("Error %d prior to %s", err, inName);
      #endif
   }
   ~DebugFunc()
   {
      #ifdef CHECK_ERROR
      int err = glGetError();
      if (err)
         ELOG("Error %d in %s", err, sDebugName);
      #endif

      sDebugName=0;
   }
};
#define DBGFUNC(x) DebugFunc _f(x);

class NmeResource : public nme::Object
{
public:
   NmeResource(int inId, ResoType inType)
   {
      id= inId;
      type = inType;
      contextVersion = gTextureContextVersion;
   }
   virtual ~NmeResource()
   {
      release();
   }
   void release()
   {
      HardwareRenderer *ctx = HardwareRenderer::current;
      if (ctx && id && contextVersion==gTextureContextVersion)
      {
         switch(type)
         {
            case resoNone:
               break;
            case resoBuffer:
               ctx->DestroyVbo(id);
               break;
            case resoTexture:
               ctx->DestroyTexture(id);
               break;
            case resoShader:
               ctx->DestroyShader(id);
               break;
            case resoProgram:
               ctx->DestroyProgram(id);
               break;
            case resoFramebuffer:
               ctx->DestroyFramebuffer(id);
               break;
            case resoRenderbuffer:
               ctx->DestroyRenderbuffer(id);
               break;
         }
      }
      type = resoNone;
      id = 0;
   }
   bool is(ResoType inType)
   {
      return id && type==inType && contextVersion==gTextureContextVersion;
   }

   int id;
   int contextVersion;
   ResoType type;
};

value createResource(unsigned int inResource, ResoType inType)
{
   value result = ObjectToAbstract( new NmeResource(inResource,inType) );
   return result;
}

void releaseResource(value inValue)
{
   NmeResource *resource = 0;
   if (AbstractToObject(inValue,resource))
      resource->release();
}

unsigned int getResource(value inResource, ResoType inType)
{
   if (val_is_null(inResource))
      return 0;

   NmeResource *resource = 0;
   if (AbstractToObject(inResource,resource))
   {
      if (resource->is(inType))
      {
         if (sDebugName && !resource->id)
            ELOG("Warning old resource %d in %s", inType, sDebugName);
         return resource->id;
      }
   }

   if (sDebugName)
   {
      if (!resource)
      {
         ELOG("Warning: provided object if not a resource in %s", sDebugName);
      }
      else if (!resource->id)
      {
         ELOG("Warning: resource has id 0 in %s", sDebugName);
      }
      else if (resource->contextVersion!=gTextureContextVersion)
      {
         ELOG("Warning: %s resource is from old context in %s", getTypeString(inType), sDebugName);
      }
      else if (resource->type!=inType)
      {
         ELOG("Warning: wrong resource type in %s (wanted %s, got %s)", sDebugName, getTypeString(inType), getTypeString(resource->type));
      }
      else
      {
         ELOG("Warning: Unknown resource error in %s", sDebugName);
      }
   }

   return 0;

}

value isResource(value inValue, ResoType inType)
{
   return alloc_bool( getResource(inValue,inType) );
}



value nme_gl_get_error()
{
   return alloc_int( glGetError() );
}
DEFINE_PRIM(nme_gl_get_error,0);


value nme_gl_finish()
{
   glFinish();
   return alloc_null();
}
DEFINE_PRIM(nme_gl_finish,0);


value nme_gl_flush()
{
   glFlush();
   return alloc_null();
}
DEFINE_PRIM(nme_gl_flush,0);



value nme_gl_version()
{
   return alloc_int( gTextureContextVersion );
}
DEFINE_PRIM(nme_gl_version,0);

value nme_gl_enable(value inCap)
{
   glEnable(val_int(inCap));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_enable,1);


value nme_gl_disable(value inCap)
{
   glDisable(val_int(inCap));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_disable,1);


value nme_gl_hint(value inTarget, value inValue)
{
   glHint(val_int(inTarget),val_int(inValue));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_hint,2);


value nme_gl_line_width(value inWidth)
{
   glLineWidth(val_number(inWidth));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_line_width,1);




value nme_gl_get_context_attributes()
{
   value result = alloc_empty_object( );

   // TODO:
   alloc_field(result,val_id("alpha"),alloc_bool(true));
   alloc_field(result,val_id("depth"),alloc_bool(true));
   alloc_field(result,val_id("stencil"),alloc_bool(true));
   alloc_field(result,val_id("antialias"),alloc_bool(true));
   return result;
}
DEFINE_PRIM(nme_gl_get_context_attributes,0);

value nme_gl_get_supported_extensions(value ioList)
{
   const char *ext = (const char *)glGetString(GL_EXTENSIONS);
   if (ext && *ext)
   {
      while(true)
      {
         const char *next = ext;
         while(*next && *next!=' ')
            next++;
         val_array_push( ioList, alloc_string_len(ext, next-ext) );
         if (!*next || !next[1])
           break;
         ext = next+1;
      }
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gl_get_supported_extensions,1);


value nme_gl_get_extension(value inName)
{
   void *result = 0;
   const char *name = val_string(inName);

   #ifdef HX_WINDOWS
      result = (void *)wglGetProcAddress(name);
   #elif defined(ANDROID)
      result = (void *)eglGetProcAddress(name);
   //Wait until I can test this...
   //#elif defined(HX_LINUX)
   //   result = dlsym(nme::gOGLLibraryHandle,#func);
   #endif

   if (result)
   {
      static bool init = false;
      static vkind functionKind;
      if (!init==0)
      {
         init = true;
         kind_share(&functionKind,"function");
      }
      return alloc_abstract(functionKind,result);
   }

   return alloc_null();
}
DEFINE_PRIM(nme_gl_get_extension,1);


value nme_gl_front_face(value inFace)
{
   glFrontFace(val_int(inFace));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_front_face,1);


value nme_gl_get_parameter(value pname_val)
{
   int floats = 0;
   int ints = 0;
   int strings = 0;
   int pname = val_int(pname_val);

   switch(pname)
   {
      case GL_ALIASED_LINE_WIDTH_RANGE:
      case GL_ALIASED_POINT_SIZE_RANGE:
      case GL_DEPTH_RANGE:
         floats = 2;
         break;

      case GL_BLEND_COLOR:
      case GL_COLOR_CLEAR_VALUE:
         floats = 4;
         break;

      case GL_COLOR_WRITEMASK:
         ints = 4;
         break;

      //case GL_COMPRESSED_TEXTURE_FORMATS  null

      case GL_MAX_VIEWPORT_DIMS:
         ints = 2;
         break;
      case GL_SCISSOR_BOX:
      case GL_VIEWPORT:
         ints = 4;
         break;

      case GL_ARRAY_BUFFER_BINDING:
      case GL_CURRENT_PROGRAM:
      case GL_ELEMENT_ARRAY_BUFFER_BINDING:
      case GL_FRAMEBUFFER_BINDING:
      case GL_RENDERBUFFER_BINDING:
      case GL_TEXTURE_BINDING_2D:
      case GL_TEXTURE_BINDING_CUBE_MAP:
         ints = 1;
         break;

      case GL_DEPTH_CLEAR_VALUE:
      case GL_LINE_WIDTH:
      case GL_POLYGON_OFFSET_FACTOR:
      case GL_POLYGON_OFFSET_UNITS:
      case GL_SAMPLE_COVERAGE_VALUE:
         ints = 1;
         break;

      case GL_BLEND:
      case GL_DEPTH_WRITEMASK:
      case GL_DITHER:
      case GL_CULL_FACE:
      case GL_POLYGON_OFFSET_FILL:
      case GL_SAMPLE_COVERAGE_INVERT:
      case GL_STENCIL_TEST:
      //case GL_UNPACK_FLIP_Y_WEBGL:
      //case GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL:
         ints = 1;
         break;

      case GL_ALPHA_BITS:
      case GL_ACTIVE_TEXTURE:
      case GL_BLEND_DST_ALPHA:
      case GL_BLEND_DST_RGB:
      case GL_BLEND_EQUATION_ALPHA:
      case GL_BLEND_EQUATION_RGB:
      case GL_BLEND_SRC_ALPHA:
      case GL_BLEND_SRC_RGB:
      case GL_BLUE_BITS:
      case GL_CULL_FACE_MODE:
      case GL_DEPTH_BITS:
      case GL_DEPTH_FUNC:
      case GL_DEPTH_TEST:
      case GL_FRONT_FACE:
      case GL_GENERATE_MIPMAP_HINT:
      case GL_GREEN_BITS:
      case GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
      case GL_MAX_CUBE_MAP_TEXTURE_SIZE:
      //case GL_MAX_FRAGMENT_UNIFORM_VECTORS:
      //case GL_MAX_RENDERBUFFER_SIZE:
      case GL_MAX_TEXTURE_IMAGE_UNITS:
      case GL_MAX_TEXTURE_SIZE:
      //case GL_MAX_VARYING_VECTORS:
      case GL_MAX_VERTEX_ATTRIBS:
      case GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:
      //case GL_MAX_VERTEX_UNIFORM_VECTORS:
      case GL_NUM_COMPRESSED_TEXTURE_FORMATS:
      case GL_PACK_ALIGNMENT:
      case GL_RED_BITS:
      case GL_SAMPLE_BUFFERS:
      case GL_SAMPLES:
      case GL_SCISSOR_TEST:
      case GL_SHADING_LANGUAGE_VERSION:
      case GL_STENCIL_BACK_FAIL:
      case GL_STENCIL_BACK_FUNC:
      case GL_STENCIL_BACK_PASS_DEPTH_FAIL:
      case GL_STENCIL_BACK_PASS_DEPTH_PASS:
      case GL_STENCIL_BACK_REF:
      case GL_STENCIL_BACK_VALUE_MASK:
      case GL_STENCIL_BACK_WRITEMASK:
      case GL_STENCIL_BITS:
      case GL_STENCIL_CLEAR_VALUE:
      case GL_STENCIL_FAIL:
      case GL_STENCIL_FUNC:
      case GL_STENCIL_PASS_DEPTH_FAIL:
      case GL_STENCIL_PASS_DEPTH_PASS:
      case GL_STENCIL_REF:
      case GL_STENCIL_VALUE_MASK:
      case GL_STENCIL_WRITEMASK:
      case GL_SUBPIXEL_BITS:
      case GL_UNPACK_ALIGNMENT:
      //case GL_UNPACK_COLORSPACE_CONVERSION_WEBGL:
         ints = 1;
         break;

      case GL_VENDOR:
      case GL_VERSION:
      case GL_RENDERER:
         strings = 1;
         break;
   }
   if (ints==1)
   {
      int val;
      glGetIntegerv(pname,&val);
      return alloc_int(val);
   }
   else if (strings==1)
   {
      return alloc_string((const char *)glGetString(pname));
   }
   else if (floats==1)
   {
      float f;
      glGetFloatv(pname,&f);
      return alloc_float(f);
   }
   else if (ints>0)
   {
      int vals[4];
      glGetIntegerv(pname,vals);
      value  result = alloc_array(ints);
      for(int i=0;i<ints;i++)
         val_array_set_i(result,i,alloc_int(vals[i]));
      return result;
   }
   else if (floats>0)
   {
      float vals[4];
      glGetFloatv(pname,vals);
      value  result = alloc_array(ints);
      for(int i=0;i<ints;i++)
         val_array_set_i(result,i,alloc_int(vals[i]));
      return result;
   }





   return alloc_null();
}
DEFINE_PRIM(nme_gl_get_parameter,1);


// --- Is -------------------------------------------

#define GL_IS(name,type) \
   value nme_gl_is_##name(value val) { return isResource(val,type); } \
   DEFINE_PRIM(nme_gl_is_##name,1);

GL_IS(buffer,resoBuffer)
GL_IS(program,resoProgram)
GL_IS(renderbuffer,resoRenderbuffer)
GL_IS(framebuffer,resoFramebuffer)
GL_IS(shader,resoShader)
GL_IS(texture,resoTexture)

value nme_gl_is_enabled(value val)
{
   return alloc_bool( glIsEnabled( val_int(val) ) );
}
DEFINE_PRIM(nme_gl_is_enabled,1);


// --- Delete -------------------------------------------

#define GL_DELETE_RESO(name) \
   value nme_gl_delete_##name(value val) { releaseResource(val); return alloc_null(); } \
   DEFINE_PRIM(nme_gl_delete_##name,1);

GL_DELETE_RESO(texture)
GL_DELETE_RESO(shader)
GL_DELETE_RESO(program)
GL_DELETE_RESO(framebuffer)
GL_DELETE_RESO(renderbuffer)
GL_DELETE_RESO(buffer)

// --- Create -------------------------------------------


value nme_gl_create_program()
{
   DBGFUNC("createProgram");
   return createResource(glCreateProgram(),resoProgram);
}
DEFINE_PRIM(nme_gl_create_program,0);

value nme_gl_create_shader(value inType)
{
   DBGFUNC("createShader");
   return createResource(glCreateShader(val_int(inType)),resoShader);
}
DEFINE_PRIM(nme_gl_create_shader,1);


#define GL_GEN_RESO(name,gen,type) \
   value nme_gl_create_##name() { \
      DBGFUNC("create" #name); \
      GLuint id=0; gen(1,&id); \
      return createResource(id,type); \
   } \
   DEFINE_PRIM(nme_gl_create_##name,0);

GL_GEN_RESO(texture,glGenTextures,resoTexture)
GL_GEN_RESO(buffer,glGenBuffers,resoBuffer)

#define GL_GEN_RESO_CHK(name,gen,type) \
   value nme_gl_create_##name() { \
      if (!CHECK_EXT(gen)) return alloc_null(); \
      DBGFUNC("create" #name); \
      GLuint id=0; gen(1,&id); return createResource(id,type); } \
   DEFINE_PRIM(nme_gl_create_##name,0);

GL_GEN_RESO(framebuffer,glGenFramebuffers,resoFramebuffer)
GL_GEN_RESO(render_buffer,glGenRenderbuffers,resoRenderbuffer)


// --- Stencil -------------------------------------------


value nme_gl_stencil_func(value func, value ref, value mask)
{
   glStencilFunc(val_int(func),val_int(ref),val_int(mask));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_stencil_func,3);


value nme_gl_stencil_func_separate(value face,value func, value ref, value mask)
{
   glStencilFuncSeparate(val_int(face),val_int(func),val_int(ref),val_int(mask));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_stencil_func_separate,4);




value nme_gl_stencil_mask(value mask)
{
   glStencilMask(val_int(mask));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_stencil_mask,1);


value nme_gl_stencil_mask_separate(value face,value mask)
{
   glStencilMaskSeparate(val_int(face),val_int(mask));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_stencil_mask_separate,2);


value nme_gl_stencil_op(value fail,value zfail, value zpass)
{
   glStencilOp(val_int(fail),val_int(zfail),val_int(zpass));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_stencil_op,3);


value nme_gl_stencil_op_separate(value face,value fail,value zfail, value zpass)
{
   glStencilOpSeparate(val_int(face),val_int(fail),val_int(zfail),val_int(zpass));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_stencil_op_separate,4);




// --- Blend -------------------------------------------

value nme_gl_blend_color(value r, value g, value b, value a)
{
   glBlendColor(val_number(r),val_number(g),val_number(b), val_number(a));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_blend_color,4);

value nme_gl_blend_equation(value mode)
{
   glBlendEquation(val_int(mode));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_blend_equation,1);


value nme_gl_blend_equation_separate(value rgb, value a)
{
   glBlendEquationSeparate(val_int(rgb), val_int(a));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_blend_equation_separate,2);


value nme_gl_blend_func(value s, value d)
{
   glBlendFunc(val_int(s), val_int(d));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_blend_func,2);


value nme_gl_blend_func_separate(value srgb, value drgb, value sa, value da)
{
   glBlendFuncSeparate(val_int(srgb), val_int(drgb), val_int(sa), val_int(da) );
   return alloc_null();
}
DEFINE_PRIM(nme_gl_blend_func_separate,4);



// --- Program -------------------------------------------

value nme_gl_link_program(value inId)
{
   DBGFUNC("linkProgram");
   int prog = getResource(inId,resoProgram);
   glLinkProgram(prog);

   return alloc_null();
}
DEFINE_PRIM(nme_gl_link_program,1);


value nme_gl_validate_program(value inId)
{
   DBGFUNC("validateProgram");
   int id = getResource(inId,resoProgram);
   if (id)
     glValidateProgram(id);

   return alloc_null();
}
DEFINE_PRIM(nme_gl_validate_program,1);


value nme_gl_get_program_info_log(value inId)
{
   DBGFUNC("getProgramInfoLog");
   char buf[1024];
   int id = getResource(inId,resoProgram);
   glGetProgramInfoLog(id,1024,0,buf);
   return alloc_string(buf);
}
DEFINE_PRIM(nme_gl_get_program_info_log,1);



value nme_gl_bind_attrib_location(value inId,value inSlot,value inName)
{
   DBGFUNC("bindAttribLocation");
   int id = getResource(inId,resoProgram);
   glBindAttribLocation(id,val_int(inSlot),val_string(inName));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_bind_attrib_location,3);




value nme_gl_get_attrib_location(value inId,value inName)
{
   DBGFUNC("getAttribLocation");
   int id = getResource(inId,resoProgram);
   return alloc_int(glGetAttribLocation(id,val_string(inName)));
}
DEFINE_PRIM(nme_gl_get_attrib_location,2);


value nme_gl_get_uniform_location(value inId,value inName)
{
   DBGFUNC("getUniformLocation");
   int id = getResource(inId,resoProgram);
   return alloc_int(glGetUniformLocation(id,val_string(inName)));
}
DEFINE_PRIM(nme_gl_get_uniform_location,2);


value nme_gl_get_uniform(value inId,value inLocation)
{
   DBGFUNC("getUniform");
   int id = getResource(inId,resoProgram);
   int loc = val_int(inLocation); 

   char buf[1];
   GLsizei outLen = 1;
   GLsizei size = 0;
   GLenum  type = 0;
   
   glGetActiveUniform(id, loc, 1, &outLen, &size, &type, buf);
   int ints = 0;
   int floats = 0;
   int bools = 0;
   switch(type)
   {
      case  GL_FLOAT:
        {
           float result = 0;
           glGetUniformfv(id,loc,&result);
           return alloc_float(result);
        }
 
      case  GL_FLOAT_VEC2: floats=2;
      case  GL_FLOAT_VEC3:  floats++;
      case  GL_FLOAT_VEC4:  floats++;
           break;

      case  GL_INT_VEC2: ints=2;
      case  GL_INT_VEC3: ints++;
      case  GL_INT_VEC4: ints++;
           break;

      case  GL_BOOL_VEC2: bools = 2;
      case  GL_BOOL_VEC3: bools++;
      case  GL_BOOL_VEC4: bools++;
           break;

      case  GL_FLOAT_MAT2: floats = 4; break;
      case  GL_FLOAT_MAT3: floats = 9; break;
      case  GL_FLOAT_MAT4: floats = 16; break;
      #ifdef HX_MACOS
      case  GL_FLOAT_MAT2x3: floats = 4*3; break;
      case  GL_FLOAT_MAT2x4: floats = 4*4; break;
      case  GL_FLOAT_MAT3x2: floats = 9*2; break;
      case  GL_FLOAT_MAT3x4: floats = 9*4; break;
      case  GL_FLOAT_MAT4x2: floats = 16*2; break;
      case  GL_FLOAT_MAT4x3: floats = 16*3; break;
      #endif

      case  GL_INT:
      case  GL_BOOL:
      case  GL_SAMPLER_2D:
      #ifdef HX_MACOS
      case  GL_SAMPLER_1D:
      case  GL_SAMPLER_3D:
      case  GL_SAMPLER_CUBE:
      case  GL_SAMPLER_1D_SHADOW:
      case  GL_SAMPLER_2D_SHADOW:
      #endif
        {
           int result = 0;
           glGetUniformiv(id,loc,&result);
           return alloc_int(result);
        }
   }

   if (ints + bools > 0)
   {
      int buffer[4];
      glGetUniformiv(id,loc,buffer);
      value result = alloc_array( ints+bools );
      for(int i=0;i<ints+bools;i++)
         val_array_set_i(result,i,alloc_int(buffer[i]));
      return result;
   }
   if (floats>0)
   {
      float buffer[16*3];
      glGetUniformfv(id,loc,buffer);
      value result = alloc_array( floats );
      for(int i=0;i<floats;i++)
         val_array_set_i(result,i,alloc_float(buffer[i]));
      return result;
 
   }
 
   return alloc_null();
}
DEFINE_PRIM(nme_gl_get_uniform,2);



value nme_gl_get_program_parameter(value inId,value inName)
{
   DBGFUNC("getProgramParameter");
   int id = getResource(inId,resoProgram);
   int result = 0;
   glGetProgramiv(id, val_int(inName), &result);
   return alloc_int(result);
}
DEFINE_PRIM(nme_gl_get_program_parameter,2);


value nme_gl_use_program(value inId)
{
   DBGFUNC("useProgram");
   int id = getResource(inId,resoProgram);
   glUseProgram(id);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_use_program,1);


value nme_gl_get_active_attrib(value inProg, value inIndex)
{
   DBGFUNC("getActiveAttrib");
   int id = getResource(inProg,resoProgram);
   value result = alloc_empty_object( );

   char buf[1024];
   GLsizei outLen = 1024;
   GLsizei size = 0;
   GLenum  type = 0;
   
   glGetActiveAttrib(id, val_int(inIndex), 1024, &outLen, &size, &type, buf);
   
   alloc_field(result,val_id("size"),alloc_int(size));
   alloc_field(result,val_id("type"),alloc_int(type));
   alloc_field(result,val_id("name"),alloc_string(buf));

   return result;
}
DEFINE_PRIM(nme_gl_get_active_attrib,2);


value nme_gl_get_active_uniform(value inProg, value inIndex)
{
   DBGFUNC("getActiveUniform");
   int id = getResource(inProg,resoProgram);

   char buf[1024];
   GLsizei outLen = 1024;
   GLsizei size = 0;
   GLenum  type = 0;
   
   glGetActiveUniform(id, val_int(inIndex), 1024, &outLen, &size, &type, buf);
   
   value result = alloc_empty_object( );
   alloc_field(result,val_id("size"),alloc_int(size));
   alloc_field(result,val_id("type"),alloc_int(type));
   alloc_field(result,val_id("name"),alloc_string(buf));

   return result;
}
DEFINE_PRIM(nme_gl_get_active_uniform,2);





value nme_gl_uniform_matrix(value inLocation, value inTranspose, value inBytes,value inCount)
{
   int loc = val_int(inLocation);
   int count = val_int(inCount);
   ByteArray bytes(inBytes);
   int size = bytes.Size();
   int floats = size/sizeof(float);

   const float *data = (float *)bytes.Bytes();

   bool trans = val_bool(inTranspose);
   if (count==2)
      glUniformMatrix2fv(loc, floats/4 ,trans,data);
   else if (count==3)
      glUniformMatrix3fv(loc, floats/9 ,trans,data);
   else if (count==4)
      glUniformMatrix4fv(loc, floats/16 ,trans,data);

   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform_matrix,4);


#define GL_UNFORM_1(TYPE,GET) \
value nme_gl_uniform1##TYPE(value inLocation, value inV0) \
{ \
   glUniform1##TYPE(val_int(inLocation),GET(inV0)); \
   return alloc_null(); \
} \
DEFINE_PRIM(nme_gl_uniform1##TYPE,2);

#define GL_UNFORM_2(TYPE,GET) \
value nme_gl_uniform2##TYPE(value inLocation, value inV0,value inV1) \
{ \
   glUniform2##TYPE(val_int(inLocation),GET(inV0),GET(inV1)); \
   return alloc_null(); \
} \
DEFINE_PRIM(nme_gl_uniform2##TYPE,3);

#define GL_UNFORM_3(TYPE,GET) \
value nme_gl_uniform3##TYPE(value inLocation, value inV0,value inV1,value inV2) \
{ \
   glUniform3##TYPE(val_int(inLocation),GET(inV0),GET(inV1),GET(inV2)); \
   return alloc_null(); \
} \
DEFINE_PRIM(nme_gl_uniform3##TYPE,4);

#define GL_UNFORM_4(TYPE,GET) \
value nme_gl_uniform4##TYPE(value inLocation, value inV0,value inV1,value inV2,value inV3) \
{ \
   glUniform4##TYPE(val_int(inLocation),GET(inV0),GET(inV1),GET(inV2),GET(inV3)); \
   return alloc_null(); \
} \
DEFINE_PRIM(nme_gl_uniform4##TYPE,5);

GL_UNFORM_1(i,val_int)
GL_UNFORM_1(f,val_number)
GL_UNFORM_2(i,val_int)
GL_UNFORM_2(f,val_number)
GL_UNFORM_3(i,val_int)
GL_UNFORM_3(f,val_number)
GL_UNFORM_4(i,val_int)
GL_UNFORM_4(f,val_number)

value nme_gl_uniform1iv(value inLocation,value inArray)
{
   NmeInts ints(inArray);
   if (ints.intCount>0)
      glUniform1iv(val_int(inLocation),ints.intCount,ints.data);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform1iv,2);

value nme_gl_uniform2iv(value inLocation,value inArray)
{
   NmeInts ints(inArray);
   if (ints.intCount>0)
      glUniform2iv(val_int(inLocation),ints.intCount>>1,ints.data);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform2iv,2);

value nme_gl_uniform3iv(value inLocation,value inArray)
{
   NmeInts ints(inArray);
   if (ints.intCount>0)
      glUniform3iv(val_int(inLocation),ints.intCount/3,ints.data);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform3iv,2);

value nme_gl_uniform4iv(value inLocation,value inArray)
{
   NmeInts ints(inArray);
   if (ints.intCount>0)
      glUniform4iv(val_int(inLocation),ints.intCount>>2,ints.data);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform4iv,2);




value nme_gl_uniform1fv(value inLocation,value inArray)
{
   NmeFloats floats(inArray);
   if (floats.floatCount>0)
      glUniform1fv(val_int(inLocation),floats.floatCount,floats.data);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform1fv,2);



value nme_gl_uniform2fv(value inLocation,value inArray)
{
   NmeFloats floats(inArray);
   if (floats.floatCount>1)
      glUniform2fv(val_int(inLocation),floats.floatCount/2,floats.data);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform2fv,2);



value nme_gl_uniform3fv(value inLocation,value inArray)
{
   NmeFloats floats(inArray);
   if (floats.floatCount>2)
      glUniform3fv(val_int(inLocation),floats.floatCount/3,floats.data);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform3fv,2);



value nme_gl_uniform4fv(value inLocation,value inArray)
{
   NmeFloats floats(inArray);
   if (floats.floatCount>3)
      glUniform4fv(val_int(inLocation),floats.floatCount/4,floats.data);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform4fv,2);

// Attrib

value nme_gl_vertex_attrib1f(value inLocation, value inV0)
{
   #ifndef EMSCRIPTEN
   glVertexAttrib1f(val_int(inLocation),val_number(inV0));
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_gl_vertex_attrib1f,2);


value nme_gl_vertex_attrib2f(value inLocation, value inV0,value inV1)
{
   #ifndef EMSCRIPTEN
   glVertexAttrib2f(val_int(inLocation),val_number(inV0),val_number(inV1));
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_gl_vertex_attrib2f,3);


value nme_gl_vertex_attrib3f(value inLocation, value inV0,value inV1,value inV2)
{
   #ifndef EMSCRIPTEN
   glVertexAttrib3f(val_int(inLocation),val_number(inV0),val_number(inV1),val_number(inV2));
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_gl_vertex_attrib3f,4);


value nme_gl_vertex_attrib4f(value inLocation, value inV0,value inV1,value inV2, value inV3)
{
   #ifndef EMSCRIPTEN
   glVertexAttrib4f(val_int(inLocation),val_number(inV0),val_number(inV1),val_number(inV2),val_number(inV3));
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_gl_vertex_attrib4f,5);



value nme_gl_vertex_attrib1fv(value inLocation,value inArray)
{
   #ifndef EMSCRIPTEN
   NmeFloats floats(inArray);
   if (floats.data)
      glVertexAttrib1fv(val_int(inLocation),floats.data);
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_gl_vertex_attrib1fv,2);



value nme_gl_vertex_attrib2fv(value inLocation,value inArray)
{
   #ifndef EMSCRIPTEN
   NmeFloats floats(inArray);
   if (floats.data)
      glVertexAttrib2fv(val_int(inLocation),floats.data);
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_gl_vertex_attrib2fv,2);



value nme_gl_vertex_attrib3fv(value inLocation,value inArray)
{
   #ifndef EMSCRIPTEN
   NmeFloats floats(inArray);
   if (floats.data)
      glVertexAttrib3fv(val_int(inLocation),floats.data);
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_gl_vertex_attrib3fv,2);



value nme_gl_vertex_attrib4fv(value inLocation,value inArray)
{
   #ifndef EMSCRIPTEN
   NmeFloats floats(inArray);
   if (floats.data)
      glVertexAttrib4fv(val_int(inLocation),floats.data);
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_gl_vertex_attrib4fv,2);




// --- Shader -------------------------------------------



value nme_gl_shader_source(value inId,value inSource)
{
   DBGFUNC("shaderSource");
   int id = getResource(inId,resoShader);
   const char *source = val_string(inSource);
   #ifdef NME_GLES
   // TODO - do something better here
   std::string buffer;
   buffer = std::string("precision mediump float;\n") + source;
   source = buffer.c_str();
   #endif

   glShaderSource(id,1,&source,0);

   return alloc_null();
}
DEFINE_PRIM(nme_gl_shader_source,2);


value nme_gl_attach_shader(value inProg,value inShader)
{
   DBGFUNC("attachShader");
   int prog = getResource(inProg,resoProgram);
   int shader = getResource(inShader,resoShader);

   glAttachShader(prog, shader);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_attach_shader,2);


value nme_gl_detach_shader(value inProg,value inShader)
{
   DBGFUNC("detachShader");
   int prog = getResource(inProg,resoProgram);
   int shader = getResource(inShader,resoShader);
   glDetachShader(prog,shader);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_detach_shader,2);



value nme_gl_compile_shader(value inId)
{
   DBGFUNC("compileShader");
   int id = getResource(inId,resoShader);
   glCompileShader(id);

   return alloc_null();
}
DEFINE_PRIM(nme_gl_compile_shader,1);


value nme_gl_get_shader_parameter(value inId,value inName)
{
   DBGFUNC("getShaderParameter");
   int id = getResource(inId,resoShader);
   int result = 0;
   glGetShaderiv(id,val_int(inName), & result);
   return alloc_int(result);
}
DEFINE_PRIM(nme_gl_get_shader_parameter,2);


value nme_gl_get_shader_info_log(value inId)
{
   DBGFUNC("getShaderInfoLog");
   int id = getResource(inId,resoShader);
   int len = 0;
   
   glGetShaderiv(id, GL_INFO_LOG_LENGTH, &len);
   
   if (len==0)
      return alloc_string("");
   len++;
   char *buf = new char[len+1];
   
   glGetShaderInfoLog(id, len, 0, buf);
   
   value result = alloc_string(buf);
   delete [] buf;
   return result;
}
DEFINE_PRIM(nme_gl_get_shader_info_log,1);


value nme_gl_get_shader_source(value inId)
{
   DBGFUNC("getShaderSource");
   int id = getResource(inId,resoShader);

   int len = 0;
   glGetShaderiv(id,GL_SHADER_SOURCE_LENGTH,&len);
   if (len==0)
      return alloc_null();
   char *buf = new char[len+1];
   glGetShaderSource(id,len+1,0,buf);
   value result = alloc_string(buf);
   delete [] buf;

   return result;
}
DEFINE_PRIM(nme_gl_get_shader_source,1);




value nme_gl_get_shader_precision_format(value inShaderType,value inPrec)
{
   DBGFUNC("getShaderPrecisionFormat");
   #ifdef NME_GLES
   int range[2];
   int precision;
   glGetShaderPrecisionFormat(val_int(inShaderType), val_int(inPrec), range, &precision);

   value result = alloc_empty_object( );
   alloc_field(result,val_id("rangeMin"),alloc_int(range[0]));
   alloc_field(result,val_id("rangeMax"),alloc_int(range[1]));
   alloc_field(result,val_id("precision"),alloc_int(precision));

   return result;
   #else
   return alloc_null();
   #endif
}
DEFINE_PRIM(nme_gl_get_shader_precision_format,2);




// --- Buffer -------------------------------------------


value nme_gl_bind_buffer(value inTarget, value inId )
{
   DBGFUNC("bindBuffer");
   int id = val_is_int(inId) ? val_int(inId) : getResource(inId,resoBuffer);
   glBindBuffer(val_int(inTarget),id);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_bind_buffer,2);


value nme_gl_buffer_data(value inTarget, value inByteBuffer, value inStart, value inLen, value inUsage)
{
   DBGFUNC("bufferData");
   int len = val_int(inLen);
   int start = val_int(inStart);

   ByteArray bytes(inByteBuffer);
   const unsigned char *data = bytes.Bytes();
   int size = bytes.Size();

   if (len+start>size)
      val_throw(alloc_string("Invalid byte length"));

   glBufferData(val_int(inTarget), len, data + start, val_int(inUsage) );

   return alloc_null();
}
DEFINE_PRIM(nme_gl_buffer_data,5);


value nme_gl_buffer_sub_data(value inTarget, value inOffset, value inByteBuffer, value inStart, value inLen)
{
   DBGFUNC("bufferSubData");
   int len = val_int(inLen);
   int start = val_int(inStart);

   ByteArray bytes(inByteBuffer);
   const unsigned char *data = bytes.Bytes();
   int size = bytes.Size();

   if (len+start>size)
      val_throw(alloc_string("Invalid byte length"));

   glBufferSubData(val_int(inTarget), val_int(inOffset), len, data + start );

   return alloc_null();
}
DEFINE_PRIM(nme_gl_buffer_sub_data,5);


value nme_gl_get_vertex_attrib_offset(value index, value name)
{
   int result = 0;
   glGetVertexAttribPointerv(val_int(index), val_int(name), (void **)&result);
   return alloc_int(result);
}
DEFINE_PRIM(nme_gl_get_vertex_attrib_offset,2);




value nme_gl_get_vertex_attrib(value index, value name)
{
   int result = 0;
   glGetVertexAttribiv(val_int(index), val_int(name), &result);
   return alloc_int(result);
}
DEFINE_PRIM(nme_gl_get_vertex_attrib,2);


value nme_gl_vertex_attrib_pointer(value *arg, int nargs)
{
   enum { aIndex, aSize, aType, aNormalized, aStride, aOffset, aSIZE };

   glVertexAttribPointer( val_int(arg[aIndex]),
                          val_int(arg[aSize]),
                          val_int(arg[aType]),
                          val_bool(arg[aNormalized]),
                          val_int(arg[aStride]),
                          (void *)(intptr_t)val_int(arg[aOffset]) );

   return alloc_null();
}

DEFINE_PRIM_MULT(nme_gl_vertex_attrib_pointer);

value nme_gl_enable_vertex_attrib_array(value inIndex)
{
   int index = val_int(inIndex);
   if (index>gDirectMaxAttribArray)
      gDirectMaxAttribArray = index;
   glEnableVertexAttribArray(index);
   return alloc_null();
}

DEFINE_PRIM(nme_gl_enable_vertex_attrib_array,1);


value nme_gl_disable_vertex_attrib_array(value inIndex)
{
   glDisableVertexAttribArray(val_int(inIndex));
   return alloc_null();
}

DEFINE_PRIM(nme_gl_disable_vertex_attrib_array,1);



value nme_gl_get_buffer_paramerter(value inTarget, value inPname)
{
   int result = 0;
   glGetBufferParameteriv(val_int(inTarget), val_int(inPname),&result);
   return alloc_int(result);
}

DEFINE_PRIM(nme_gl_get_buffer_paramerter,2);

value nme_gl_get_buffer_parameter(value inTarget, value inIndex)
{
   GLint data = 0;
   glGetBufferParameteriv(val_int(inTarget), val_int(inIndex), &data);
   return alloc_int(data);
}
DEFINE_PRIM(nme_gl_get_buffer_parameter,2);





// --- Framebuffer -------------------------------

value nme_gl_bind_framebuffer(value target, value framebuffer)
{
   DBGFUNC("bindFramebuffer");
   if (CHECK_EXT(glBindFramebuffer))
   {
      int id = val_is_int(framebuffer) ? val_int(framebuffer) : getResource(framebuffer,resoFramebuffer);
      glBindFramebuffer(val_int(target), id );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gl_bind_framebuffer,2);

value nme_gl_bind_renderbuffer(value target, value renderbuffer)
{
   DBGFUNC("bindRenderbuffer");
   if (CHECK_EXT(glBindRenderbuffer))
   {
      int id = val_is_int(renderbuffer) ? val_int(renderbuffer) : getResource(renderbuffer,resoRenderbuffer);
      glBindRenderbuffer(val_int(target),id);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gl_bind_renderbuffer,2);

value nme_gl_delete_render_buffer(value target)
{
   GLuint id = val_int(target);
   if (&glDeleteRenderbuffers) glDeleteRenderbuffers(1, &id);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_delete_render_buffer,1);

value nme_gl_framebuffer_renderbuffer(value target, value attachment, value renderbuffertarget, value renderbuffer)
{
   DBGFUNC("framebufferRenderBuffer");
   if (CHECK_EXT(glFramebufferRenderbuffer))
   {
      int id = val_is_int(renderbuffer) ? val_int(renderbuffer) : getResource(renderbuffer,resoRenderbuffer);
      glFramebufferRenderbuffer(val_int(target), val_int(attachment), val_int(renderbuffertarget), id );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gl_framebuffer_renderbuffer,4);


value nme_gl_framebuffer_texture2D(value target, value attachment, value textarget, value texture, value level)
{
   DBGFUNC("framebufferTexture2D");
   if (CHECK_EXT(glFramebufferTexture2D))
   {
      int tId = val_is_int(texture) ? val_int(texture) : getResource(texture,resoTexture);
      glFramebufferTexture2D( val_int(target), val_int(attachment), val_int(textarget), tId, val_int(level) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gl_framebuffer_texture2D,5);

value nme_gl_renderbuffer_storage(value target, value internalFormat, value width, value height)
{
   DBGFUNC("framebufferStorage");
   if (CHECK_EXT(glRenderbufferStorage))
   {
      glRenderbufferStorage( val_int(target), val_int(internalFormat), val_int(width), val_int(height) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gl_renderbuffer_storage,4);

value nme_gl_check_framebuffer_status(value inTarget)
{
   DBGFUNC("framebufferStatus");
   if (CHECK_EXT(glCheckFramebufferStatus))
   {
      return alloc_int( glCheckFramebufferStatus(val_int(inTarget)));
   }
   return alloc_int(0);
}
DEFINE_PRIM(nme_gl_check_framebuffer_status,1);

value nme_gl_get_framebuffer_attachment_parameter(value target, value attachment, value pname)
{
   DBGFUNC("framebufferAttachmentParameter");
   GLint result = 0;
   if (CHECK_EXT(glGetFramebufferAttachmentParameteriv))
      glGetFramebufferAttachmentParameteriv( val_int(target), val_int(attachment), val_int(pname), &result);
   return alloc_int(result);
}
DEFINE_PRIM(nme_gl_get_framebuffer_attachment_parameter,3);

value nme_gl_get_render_buffer_parameter(value target, value pname)
{
   DBGFUNC("getRenderbufferParameter");
   int result = 0;
   if (CHECK_EXT(glGetRenderbufferParameteriv))
      glGetRenderbufferParameteriv(val_int(target), val_int(pname), &result);
   return alloc_int(result);
}
DEFINE_PRIM(nme_gl_get_render_buffer_parameter,2);

// --- Drawing -------------------------------


value nme_gl_draw_arrays(value inMode, value inFirst, value inCount)
{
   DBGFUNC("drawArrays");
   glDrawArrays( val_int(inMode), val_int(inFirst), val_int(inCount) );
   return alloc_null();
}
DEFINE_PRIM(nme_gl_draw_arrays,3);


value nme_gl_draw_elements(value inMode, value inCount, value inType, value inOffset)
{
   DBGFUNC("drawElements");
   glDrawElements( val_int(inMode), val_int(inCount), val_int(inType), (void *)(intptr_t)val_int(inOffset) );
   return alloc_null();
}
DEFINE_PRIM(nme_gl_draw_elements,4);




// --- Windowing -------------------------------

value nme_gl_viewport(value inX, value inY, value inW,value inH)
{
   glViewport(val_int(inX),val_int(inY),val_int(inW),val_int(inH));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_viewport,4);


value nme_gl_scissor(value inX, value inY, value inW,value inH)
{
   glScissor(val_int(inX),val_int(inY),val_int(inW),val_int(inH));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_scissor,4);

value nme_gl_clear(value inMask)
{
   glClear(val_int(inMask));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_clear,1);


value nme_gl_clear_color(value r,value g, value b, value a)
{
   glClearColor(val_number(r),val_number(g),val_number(b),val_number(a));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_clear_color,4);



value nme_gl_clear_depth(value depth)
{
   #ifdef NME_GLES
   glClearDepthf(val_number(depth));
   #else
   glClearDepth(val_number(depth));
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_gl_clear_depth,1);


value nme_gl_clear_stencil(value stencil)
{
   glClearStencil(val_int(stencil));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_clear_stencil,1);


value nme_gl_color_mask(value r,value g, value b, value a)
{
   glColorMask(val_bool(r),val_bool(g),val_bool(b),val_bool(a));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_color_mask,4);



value nme_gl_depth_func(value func)
{
   glDepthFunc(val_int(func));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_depth_func,1);

value nme_gl_depth_mask(value mask)
{
   glDepthMask(val_bool(mask));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_depth_mask,1);



value nme_gl_depth_range(value inNear, value inFar)
{
   #ifdef NME_GLES
   glDepthRangef(val_number(inNear), val_number(inFar));
   #else
   glDepthRange(val_number(inNear), val_number(inFar));
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_gl_depth_range,2);


value nme_gl_cull_face(value mode)
{
   glCullFace(val_int(mode));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_cull_face,1);



value nme_gl_polygon_offset(value factor, value units)
{
   glPolygonOffset(val_number(factor), val_number(units));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_polygon_offset,2);


value nme_gl_read_pixels(value *arg, int argCount)
{
   enum { aX, aY, aWidth, aHeight, aFormat, aType, aBuffer, aOffset };

   unsigned char *data = 0;
   ByteArray bytes( arg[aBuffer] );
   if (bytes.mValue)
      data = bytes.Bytes() + val_int(arg[aOffset]);

   glReadPixels( INT(aX), INT(aY),
                    INT(aWidth),   INT(aHeight),
                    INT(aFormat),  INT(aType),
                    data );

   return alloc_null();
}
DEFINE_PRIM_MULT(nme_gl_read_pixels);


value nme_gl_pixel_storei(value pname, value param)
{
   glPixelStorei(val_int(pname), val_int(param));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_pixel_storei,2);


value nme_gl_sample_coverage(value f, value invert)
{
   glSampleCoverage(val_number(f), val_bool(invert));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_sample_coverage,2);






// --- Texture -------------------------------------------

value nme_gl_active_texture(value inSlot)
{
   glActiveTexture( val_int(inSlot) );
   return alloc_null();
}
DEFINE_PRIM(nme_gl_active_texture,1);



value nme_gl_bind_texture(value inTarget, value inTexture)
{
   DBGFUNC("bindTexture");
   int tid = val_is_int(inTexture) ? val_int(inTexture) : getResource(inTexture,resoTexture);
   glBindTexture(val_int(inTarget), tid );
   return alloc_null();
}
DEFINE_PRIM(nme_gl_bind_texture,2);

value nme_gl_bind_bitmap_data_texture(value inBitmapData)
{
   DBGFUNC("bindBitmapData");
   Surface  *surface;
   if (AbstractToObject(inBitmapData,surface) )
   {
      HardwareRenderer *ctx = gDirectRenderContext;
      if (!ctx)
         ctx = nme::HardwareRenderer::current;
      if (ctx)
      {
         Texture *texture = surface->GetTexture(gDirectRenderContext);
         if (texture)
            texture->Bind(-1);
      }
   }

   return alloc_null();
}
DEFINE_PRIM(nme_gl_bind_bitmap_data_texture,1);


value nme_gl_tex_image_2d(value *arg, int argCount)
{
   DBGFUNC("texImage2D");
   enum { aTarget, aLevel, aInternal, aWidth, aHeight, aBorder, aFormat, aType, aBuffer, aOffset };

   unsigned char *data = 0;

   ByteArray bytes( arg[aBuffer] );
   if (!val_is_null(bytes.mValue))
      data = bytes.Bytes() + val_int(arg[aOffset]);

   glTexImage2D(INT(aTarget), INT(aLevel),  INT(aInternal),
                INT(aWidth),  INT(aHeight), INT(aBorder),
                INT(aFormat), INT(aType), data );

   return alloc_null();
}
DEFINE_PRIM_MULT(nme_gl_tex_image_2d);


   
value nme_gl_tex_sub_image_2d(value *arg, int argCount)
{
   DBGFUNC("texSubImage2D");
   enum { aTarget, aLevel, aXOffset, aYOffset, aWidth, aHeight, aFormat, aType, aBuffer, aOffset };

   unsigned char *data = 0;
   ByteArray bytes( arg[aBuffer] );
   if (bytes.mValue)
      data = bytes.Bytes() + val_int(arg[aOffset]);
 
   glTexSubImage2D( INT(aTarget),  INT(aLevel),
                    INT(aXOffset), INT(aYOffset),
                    INT(aWidth),   INT(aHeight),
                    INT(aFormat),  INT(aType),
                    data );

   return alloc_null();
}
DEFINE_PRIM_MULT(nme_gl_tex_sub_image_2d);



value nme_gl_compressed_tex_image_2d(value *arg, int argCount)
{
   DBGFUNC("ompressedTexImage2D");
   enum { aTarget, aLevel, aInternal, aWidth, aHeight, aBorder, aBuffer, aOffset };

   unsigned char *data = 0;
   int size = 0;

   ByteArray bytes( arg[aBuffer] );
   if (!val_is_null(bytes.mValue))
   {
      data = bytes.Bytes() + INT(aOffset);
      size = bytes.Size() - INT(aOffset);
   }

   glCompressedTexImage2D(INT(aTarget), INT(aLevel),  INT(aInternal),
                INT(aWidth),  INT(aHeight), INT(aBorder),
                size, data );

   return alloc_null();
}
DEFINE_PRIM_MULT(nme_gl_compressed_tex_image_2d);


value nme_gl_compressed_tex_sub_image_2d(value *arg, int argCount)
{
   DBGFUNC("compressedTexSubImage2D");
   enum { aTarget, aLevel, aXOffset, aYOffset, aWidth, aHeight, aFormat, aBuffer, aOffset };

   unsigned char *data = 0;
   int size = 0;

   ByteArray bytes( arg[aBuffer] );
   if (!val_is_null(bytes.mValue))
   {
      data = bytes.Bytes() + INT(aOffset);
      size = bytes.Size() - INT(aOffset);
   }

   glCompressedTexSubImage2D(INT(aTarget), INT(aLevel),  INT(aXOffset), INT(aYOffset),
                INT(aWidth),  INT(aHeight), INT(aFormat),
                size, data );

   return alloc_null();
}
DEFINE_PRIM_MULT(nme_gl_compressed_tex_sub_image_2d);






value nme_gl_tex_parameterf(value inTarget, value inPName, value inVal)
{
   glTexParameterf(val_int(inTarget), val_int(inPName), val_number(inVal) );
   return alloc_null();
}
DEFINE_PRIM(nme_gl_tex_parameterf,3);


value nme_gl_tex_parameteri(value inTarget, value inPName, value inVal)
{
   glTexParameterf(val_int(inTarget), val_int(inPName), val_int(inVal) );
   return alloc_null();
}
DEFINE_PRIM(nme_gl_tex_parameteri,3);


value nme_gl_copy_tex_image_2d(value *arg, int argCount)
{
   DBGFUNC("copyTexImage2d");
   enum { aTarget, aLevel, aInternalFormat, aX, aY, aWidth, aHeight, aBorder };

   glCopyTexImage2D( INT(aTarget), INT(aLevel), INT(aInternalFormat),
                     INT(aX), INT(aY), INT(aWidth), INT(aHeight), INT(aBorder) );
   return alloc_null();
}
DEFINE_PRIM_MULT(nme_gl_copy_tex_image_2d);


value nme_gl_copy_tex_sub_image_2d(value *arg, int argCount)
{
   DBGFUNC("copyTexSubImage2d");
   enum { aTarget, aLevel, aXOffset, aYOffset, aX, aY, aWidth, aHeight };

   glCopyTexSubImage2D( INT(aTarget), INT(aLevel), INT(aXOffset), INT(aYOffset),
                        INT(aX), INT(aY), INT(aWidth), INT(aHeight) );
   return alloc_null();
}
DEFINE_PRIM_MULT(nme_gl_copy_tex_sub_image_2d);



value nme_gl_generate_mipmap(value inTarget)
{
   DBGFUNC("generateMipmap");
   if (CHECK_EXT(glGenerateMipmap))
      glGenerateMipmap(val_int(inTarget));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_generate_mipmap,1);



value nme_gl_get_tex_parameter(value inTarget,value inPname)
{
   int result = 0;
   glGetTexParameteriv(val_int(inTarget), val_int(inPname), &result);
   return alloc_int(result);
}
DEFINE_PRIM(nme_gl_get_tex_parameter,2);


}

extern "C" int nme_oglexport_register_prims() { return 0; }

