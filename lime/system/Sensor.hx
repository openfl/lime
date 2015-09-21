package lime.system;


import lime.app.Event;


class Sensor {
	
	
	private static var sensorByID = new Map<Int, Sensor> ();
	private static var sensors = new Array<Sensor> ();
	
	public var id:Int;
	public var onUpdate = new Event<Float->Float->Float->Void> ();
	public var type:SensorType;
	
	
	private function new (type:SensorType, id:Int) {
		
		this.type = type;
		this.id = id;
		
	}
	
	
	public static function getSensors (type:SensorType = null):Array<Sensor> {
		
		if (type == null) {
			
			return sensors.copy ();
			
		} else {
			
			var result = [];
			
			for (sensor in sensors) {
				
				if (sensor.type == type) {
					
					result.push (sensor);
					
				}
				
			}
			
			return result;
			
		}
		
	}
	
	
	private static function registerSensor (type:SensorType, id:Int):Void {
		
		var sensor = new Sensor (type, id);
		
		sensors.push (sensor);
		sensorByID.set (id, sensor);
		
	}
	
	
}