#ifndef LIME_OPENGL_EGL
#define LIME_OPENGL_EGL

void limeEGLDestroy();
void limeEGLSwapBuffers();
bool limeEGLResize(void *inX11Window, int &ioWidth, int &ioHeight);
bool limeEGLCreate(void *inX11Window, int &ioWidth, int &ioHeight,
                int inOGLESVersion,
                int inDepthBits,
                int inStencilBits,
                int inAlphaBits
                );
#endif
