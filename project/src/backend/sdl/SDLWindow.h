#ifndef LIME_SDL_WINDOW_H
#define LIME_SDL_WINDOW_H


#include <SDL.h>
#include <graphics/ImageBuffer.h>
#include <ui/Window.h>


namespace lime {
	
	
	class SDLWindow : public Window {
		
		public:
			
			SDLWindow (Application* application, int width, int height, int flags, const char* title);
			~SDLWindow ();
			
			virtual void Close ();
			virtual bool GetEnableTextEvents ();
			virtual int GetHeight ();
			virtual int GetWidth ();
			virtual int GetX ();
			virtual int GetY ();
			virtual void Move (int x, int y);
			virtual void Resize (int width, int height);
			virtual void SetEnableTextEvents (bool enabled);
			virtual bool SetFullscreen (bool fullscreen);
			virtual void SetIcon (ImageBuffer *imageBuffer);
			virtual bool SetMinimized (bool minimized);
			virtual const char* SetTitle (const char* title);
			
			SDL_Window* sdlWindow;
		
	};
	
	
}


#endif