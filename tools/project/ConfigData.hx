package project;


import haxe.xml.Fast;
import helpers.LogHelper;
import helpers.ObjectHelper;

	
	//this class wraps up the dynamic return with access to 
private class ConfigDataValue {

	public var value : Dynamic;

	public function new(_value:Dynamic){

		value = _value;

	}

	public function get( _value:String ) {
		
		return ConfigData.get(value, _value);

	} 

	public function exists( _value:String ) {

		return ConfigData.exists( value, _value );

	} 

}
	
class ConfigData {
	
	public var config : Dynamic;

	public function new () {

		config = {};

	}
	
	
	public function clone ():ConfigData {
		
		var new_configdata : ConfigData = new ConfigData();
			
			new_configdata.config = ObjectHelper.deepCopy (config);
		
		return new_configdata;

	}
	
	
	public static function get (from_config:Dynamic, value:String):Dynamic {
		
		var tree = value.split('.');

			//no leafs? just fetch a value
		if(tree.length <= 1) {
			return Reflect.field(from_config, value);
		}

			//for each leaf in the tree the current advances till the last one
		var current = from_config;
		for(leaf in tree) {
			current = Reflect.field(current, leaf);
			if(current == null) {
				return null;
			}
		}

			//if it reaches here, 
			//its a valid field
		return new ConfigDataValue(current);
		
	}
	
	public static function exists (from_config:Dynamic, value:String):Bool {
		
		return get(from_config, value) != null;

	}
	
	
	public function merge (other:ConfigData):Void {
		
		if(other != null) {
			ObjectHelper.copyFieldsPreferObjectOverValue( other.config, config );
		}
		
	}

	function add_bucket( bucket:String, parent:Dynamic ) {
		
			//if it already exists, we don't create it
		if(!Reflect.hasField(parent, bucket )) {
			log("config data > adding a bucket_type " + bucket);
			Reflect.setField(parent, bucket, {} );
		}

		return Reflect.field(parent, bucket);

	}

	function set_node( bucket:Dynamic, node:String, value:Dynamic ) {
			
		// log("config data > setting a node " + node + " to " + value + " on " + bucket);

		var do_copy = true;
		var exists = Reflect.hasField( bucket, node );
		
		if( exists ) {

			var value_dest = Reflect.field (bucket, node);
			var type_source = Type.typeof(value).getName();
			var type_dest = Type.typeof(value_dest).getName();

			// trace(node + " / existed in dest as " + type_dest + " / " + type_source );

				//if trying to copy a non object over an object, don't
			if(type_source != "TObject" && type_dest == "TObject") {
				do_copy = false;
				if(LogHelper.verbose) {
					LogHelper.println(node + " not merged by preference over object" );
				}
			}

		}

		if(do_copy) {
			Reflect.setField (bucket, node, value);
		}

	}

	function parse_attributes( elem:Fast, bucket:Dynamic ) {

			//for each attribute, set the value onto the bucket
		for( attr_name in elem.x.attributes() ) {

			if(attr_name != "type") {

				var attr_value = elem.x.get(attr_name);

				set_node(bucket, attr_name, attr_value);

			}

		}

	}

	function parse_value( elem:Fast, bucket:Dynamic ) {

		if(elem.innerHTML != "") {
			set_node( bucket, elem.name, elem.innerHTML);
		}

	}

	function log(v:Dynamic) {

		if(LogHelper.verbose) {
			LogHelper.println(v);
		}

	}

	function parse_children( elem:Fast, bucket:Dynamic, ?depth:Int=0 ) {

		for( child in elem.elements ) {
			if(child.name != "config") {
				
				// log("config data > child : " + child.name);
				
				var d = depth + 1;
				var child_bucket = add_bucket(child.name, bucket);

				var has_children = child.x.elements().hasNext();
				var has_attributes = child.x.attributes().hasNext();

				if(has_attributes) {
					parse_attributes(child, child_bucket);
				}

					//if there are any children, parse those too
				if(has_children) {
					parse_children(child, child_bucket, d);
				}

				if(!has_children && !has_attributes) {
					parse_value(child, bucket);
				}

			}
		}

	}


	public function parse( elem:Fast ) {

		var bucket = config;
		var bucket_type = "";

			//pul out the type from the node name
		if(StringTools.startsWith(elem.name, "config:")) {
			var items = elem.name.split(':');
			bucket_type = items[1];
		}

		if(elem.has.type) {
			bucket_type = elem.att.type;
		}

			//create the bucket if there is a type, 
			//otherwise it will store it in the root config
		if(bucket_type != "") {
			bucket = add_bucket( bucket_type, config );
		}

			//parse root attributes
		parse_attributes( elem, bucket );

			//parse children recursively
		parse_children( elem, bucket );

		if(LogHelper.verbose) {
			LogHelper.println("> current config : " + config);
		}

	}
	
}