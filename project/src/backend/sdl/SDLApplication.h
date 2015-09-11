#ifndef LIME_SDL_APPLICATION_H
#define LIME_SDL_APPLICATION_H


#include <SDL.h>
#include <app/Application.h>
#include <app/UpdateEvent.h>
#include <graphics/RenderEvent.h>
#include <ui/GamepadEvent.h>
#include <ui/KeyEvent.h>
#include <ui/MouseEvent.h>
#include <ui/TextEvent.h>
#include <ui/TouchEvent.h>
#include <ui/WindowEvent.h>
#include "SDLWindow.h"


namespace lime {
	
	
	class SDLApplication : public Application {
		
		public:
			
			SDLApplication ();
			~SDLApplication ();
			
			virtual int Exec ();
			virtual void Init ();
			virtual int Quit ();
			virtual void SetFrameRate (double frameRate);
			virtual bool Update ();
			
			void RegisterWindow (SDLWindow *window);
		
		private:
			
			void HandleEvent (SDL_Event* event);
			void ProcessGamepadEvent (SDL_Event* event);
			void ProcessKeyEvent (SDL_Event* event);
			void ProcessMouseEvent (SDL_Event* event);
			void ProcessTextEvent (SDL_Event* event);
			void ProcessTouchEvent (SDL_Event* event);
			void ProcessWindowEvent (SDL_Event* event);
			
			static void UpdateFrame ();
			static void UpdateFrame (void*);
			
			static SDLApplication* currentApplication;
			
			bool active;
			Uint32 currentUpdate;
			double framePeriod;
			GamepadEvent gamepadEvent;
			KeyEvent keyEvent;
			Uint32 lastUpdate;
			MouseEvent mouseEvent;
			double nextUpdate;
			RenderEvent renderEvent;
			TextEvent textEvent;
			TouchEvent touchEvent;
			UpdateEvent updateEvent;
			WindowEvent windowEvent;
		
	};
	
	
}


#endif