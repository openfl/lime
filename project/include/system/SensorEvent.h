#ifndef LIME_SYSTEM_SENSOR_EVENT_H
#define LIME_SYSTEM_SENSOR_EVENT_H


#include <hx/CFFI.h>


namespace lime {
	
	
	enum SensorEventType {
		
		SENSOR_ACCELEROMETER
		
	};
	
	
	class SensorEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			SensorEvent ();
			
			static void Dispatch (SensorEvent* event);
			
			int id;
			SensorEventType type;
			double x;
			double y;
			double z;
			
		
	};
	
	
}


#endif