#include <hx/CFFI.h>

#include <S3D.h>
#include <nme/Object.h>

#include <fstream>

namespace nme {
namespace S3D {

const char* MI3D_TN_CTRL_FILE = "/dev/mi3d_tn_ctrl";

bool gS3DEnabled = false;
S3DOrientation gS3DOrientation = S3D_ORIENTATION_VERTICAL;

const int MI3D_GET_TN_STATUS = 128;
const int MI3D_SET_HORIZONTAL_TN_ON = 64;
const int MI3D_SET_TN_OFF = 16;
const int MI3D_SET_VERTICAL_TN_ON = 32;


void Enact () {

   unsigned char value = MI3D_SET_TN_OFF; 
   if (gS3DEnabled) {

      if (gS3DOrientation == S3D_ORIENTATION_VERTICAL) {

         value = MI3D_SET_VERTICAL_TN_ON;

      } else {

         value = MI3D_SET_HORIZONTAL_TN_ON;

      }

   }

   std::fstream file;
   file.open (MI3D_TN_CTRL_FILE);

   if (file.is_open ()) {

      file << value;
      file.close ();

   }
}


void SetEnabled (bool enabled) {

   gS3DEnabled = enabled;
   Enact ();

}



void SetOrientation (S3DOrientation orientation) {

   gS3DOrientation = orientation;
   Enact ();

}


bool GetEnabled () {

   return gS3DEnabled;

}


bool IsSupported () {

   std::fstream file;
   file.open (MI3D_TN_CTRL_FILE, std::ios_base::in);

   bool result = file.is_open ();
   file.close ();

   return result;

}

value nme_get_s3d_enabled () {

   return alloc_bool (S3D::GetEnabled ());

}
DEFINE_PRIM (nme_get_s3d_enabled, 0);

value nme_set_s3d_enabled (value enabled) {

   S3D::SetEnabled (val_bool (enabled));
   return alloc_null ();

}
DEFINE_PRIM (nme_set_s3d_enabled, 1);

value nme_get_s3d_supported () {

   return alloc_bool (S3D::IsSupported ());

}
DEFINE_PRIM (nme_get_s3d_supported, 0);

} // end namespace S3D
} // end namespace nme
