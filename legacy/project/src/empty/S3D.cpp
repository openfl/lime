#include <S3D.h>
#include <hx/CFFI.h>
#include <nme/Object.h>

namespace nme {
namespace S3D {

void SetEnabled (bool enabled) { }
void SetOrientation (S3DOrientation orientation) { }
bool GetEnabled () { return false; }
bool IsSupported () { return false; }


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
