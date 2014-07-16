#include "ConsoleWindow.h"
#include "ConsoleRenderer.h"


namespace lime {
	
	
	ConsoleRenderer::ConsoleRenderer (Window* window) {
		
		currentWindow = window;
		
	}
	
	
	ConsoleRenderer::~ConsoleRenderer () {
		
		
		
	}
	
	
	void ConsoleRenderer::Flip () {
		
		
		
	}
	
	
	Renderer* CreateRenderer (Window* window) {
		
		return new ConsoleRenderer (window);
		
	}
	
	
}