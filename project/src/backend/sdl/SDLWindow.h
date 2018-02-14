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
			
			virtual void Alert (const char* message, const char* title);
			virtual void Close ();
			virtual void Focus ();
			virtual int GetDisplay ();
			virtual void GetDisplayMode (DisplayMode* displayMode);
			virtual bool GetEnableTextEvents ();
			virtual int GetHeight ();
			virtual uint32_t GetID ();
			virtual int GetWidth ();
			virtual int GetX ();
			virtual int GetY ();
			virtual void Move (int x, int y);
			virtual void Resize (int width, int height);
			virtual bool SetBorderless (bool borderless);
			virtual void SetDisplayMode (DisplayMode* displayMode);
			virtual void SetEnableTextEvents (bool enabled);
			virtual bool SetFullscreen (bool fullscreen);
			virtual void SetIcon (ImageBuffer *imageBuffer);
			virtual bool SetMaximized (bool maximized);
			virtual bool SetMinimized (bool minimized);
			virtual bool SetResizable (bool resizable);
			virtual const char* SetTitle (const char* title);
			
			SDL_Window* sdlWindow;

        #if defined (IPHONE) || defined (APPLETV)
		private:

		    SDL_GLContext context;

		#endif
	};
	
	
}


#endif