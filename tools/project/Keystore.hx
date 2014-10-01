package project;


class Keystore {
	
	public var alias:String;
	public var aliasPassword:String;
	public var identity:String;
	public var password:String;
	public var path:String;
	public var type:String;
	
	public function new (path:String = null, password:String = null, alias:String = null, aliasPassword:String = null, identity:String = null) {
		
		this.path = path;
		this.password = password;
		this.alias = alias;
		this.aliasPassword = aliasPassword;
		this.identity = identity;
		
	}
	
	public function clone ():Keystore {
		
		return new Keystore (path, password, alias, aliasPassword, identity);
		
	}
	
	public function merge (keystore:Keystore):Void {
		
		if (keystore != null) {
			
			if (keystore.path != null && keystore.path != "") path = keystore.path;
			if (keystore.password != null) path = keystore.password;
			if (keystore.alias != null) path = keystore.alias;
			if (keystore.aliasPassword != null) path = keystore.aliasPassword;
			if (keystore.identity != null) identity = keystore.identity;
			
		}
		
	}
	
}