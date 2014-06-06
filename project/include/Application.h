#ifndef LIME_APPLICATION_H
#define LIME_APPLICATION_H


namespace lime {
	
	
	class Application {
		
		
		public:
			
			virtual int Exec () = 0;
		
		
	};
	
	
	Application* CreateApplication ();
	
	
}


#endif