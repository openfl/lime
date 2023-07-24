#ifndef DEFINITIONS_H
#define DEFINITIONS_H


#ifdef LIME_OPENGL


#define CreateContext SDL_GL_CreateContext
#define DeleteContext SDL_GL_DeleteContext
#define GetDrawableSize SDL_GL_GetDrawableSize
#define Context SDL_GLContext
#define WINDOW_GRAPHICS SDL_WINDOW_OPENGL
#define SetAttribute SDL_GL_SetAttribute
#define MakeCurrent SDL_GL_MakeCurrent
#define SwapWindow SDL_GL_SwapWindow
#define SetSwapInterval SDL_GL_SetSwapInterval


#endif


#define EMPTY(...) (0)


#endif