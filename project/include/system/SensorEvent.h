#ifndef LIME_SYSTEM_SENSOR_EVENT_H
#define LIME_SYSTEM_SENSOR_EVENT_H


#include <hl.h>
#include <hx/CFFI.h>


namespace lime {
	
	
	enum SensorEventType {
		
		SENSOR_ACCELEROMETER
		
	};
	
	
	struct HL_SensorEvent {
		
		hl_type* t;
		int id;
		double x;
		double y;
		double z;
		SensorEventType type;
		
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