#ifndef LIME_SYSTEM_SENSOR_EVENT_H
#define LIME_SYSTEM_SENSOR_EVENT_H


#include <hl.h>
#include <hx/CFFI.h>
#include <system/ValuePointer.h>


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
			
			static ValuePointer* callback;
			static ValuePointer* eventObject;
			
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