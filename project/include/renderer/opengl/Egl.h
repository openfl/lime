#ifndef NME_OPENGL_EGL
#define NME_OPENGL_EGL

void nmeEGLDestroy();
void nmeEGLSwapBuffers();
bool nmeEGLResize(void *inX11Window, int &ioWidth, int &ioHeight);
bool nmeEGLCreate(void *inX11Window, int &ioWidth, int &ioHeight,
                int inOGLESVersion,
                int inDepthBits,
                int inStencilBits,
                int inAlphaBits
                );
#endif
