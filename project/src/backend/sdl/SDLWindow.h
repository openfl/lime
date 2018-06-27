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
			virtual void ContextFlip ();
			virtual void* ContextLock (bool useCFFIValue, void* object);
			virtual void ContextMakeCurrent ();
			virtual void ContextUnlock ();
			virtual void Focus ();
			virtual void* GetContext ();
			virtual const char* GetContextType ();
			virtual int GetDisplay ();
			virtual void GetDisplayMode (DisplayMode* displayMode);
			virtual bool GetEnableTextEvents ();
			virtual int GetHeight ();
			virtual uint32_t GetID ();
			virtual double GetScale ();
			virtual int GetWidth ();
			virtual int GetX ();
			virtual int GetY ();
			virtual void Move (int x, int y);
			virtual void ReadPixels (ImageBuffer *buffer, Rectangle *rect);
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
			
			SDL_Renderer* sdlRenderer;
			SDL_Texture* sdlTexture;
			SDL_Window* sdlWindow;
		
		private:
			
			SDL_GLContext context;
			int contextHeight;
			int contextWidth;
		
	};
	
	
}


#endif