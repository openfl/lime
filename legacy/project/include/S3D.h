#ifndef S3D_H
#define S3D_H

namespace nme {

enum S3DOrientation {
   S3D_ORIENTATION_VERTICAL,
   S3D_ORIENTATION_HORIZONTAL
};

namespace S3D {

void SetEnabled (bool enabled);
void SetOrientation (S3DOrientation orientation);
bool GetEnabled ();
bool IsSupported ();

} // end namespace S3D
} // end namespace nme

#endif