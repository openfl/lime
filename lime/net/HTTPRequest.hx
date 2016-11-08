package lime.net; #if !macro


#if (!macro && !display)
@:genericBuild(lime.net.HTTPRequest.build())
#end


class HTTPRequest<T> implements IHTTPRequest {
	
	
	public var contentType:String;
	public var data:haxe.io.Bytes;
	public var enableResponseHeaders:Bool;
	public var followRedirects:Bool;
	public var formData:Map<String, Dynamic>;
	public var headers:Array<HTTPRequestHeader>;
	public var method:HTTPRequestMethod;
	public var responseData:T;
	public var responseHeaders:Array<HTTPRequestHeader>;
	public var responseStatus:Int;
	public var timeout:Int;
	public var uri:String;
	public var userAgent:String;
	
	#if flash
	private var backend = new lime._backend.flash.FlashHTTPRequest ();
	#elseif (js && html5)
	private var backend = new lime._backend.html5.HTML5HTTPRequest ();
	#else
	private var backend = new lime._backend.native.NativeHTTPRequest ();
	#end
	
	
	public function new (uri:String = null) {
		
		this.uri = uri;
		
		formData = new Map ();
		headers = [];
		method = GET;
		timeout = 30000;
		
		backend.init (this);
		
	}
	
	
	public function cancel ():Void {
		
		backend.cancel ();
		
	}
	
	
	public function load (uri:String = null):lime.app.Future<T> {
		
		return null;
		
	}
	
	
}


@:dox(hide) @:noCompletion interface IHTTPRequest {
	
	public var contentType:String;
	public var data:haxe.io.Bytes;
	public var enableResponseHeaders:Bool;
	public var followRedirects:Bool;
	public var formData:Map<String, Dynamic>;
	public var headers:Array<HTTPRequestHeader>;
	public var method:HTTPRequestMethod;
	//public var responseData:T;
	public var responseHeaders:Array<HTTPRequestHeader>;
	public var responseStatus:Int;
	public var timeout:Int;
	public var uri:String;
	public var userAgent:String;
	
}


#else


import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;


class HTTPRequest {
	
	
	private static function build () {
		
		var paramType;
		var type:BaseType, typeArgs;
		var stringAbstract = false;
		var bytesAbstract = false;
		
		switch (Context.follow (Context.getLocalType ())) {
			
			case TInst (localType, [ t ]):
				
				paramType = t;
				
				switch (t) {
					
					case TInst (t, args):
						
						type = t.get ();
						typeArgs = args;
					
					case TAbstract (t, args):
						
						type = t.get ();
						typeArgs = args;
						
						stringAbstract = isStringAbstract (t.get ());
						if (!stringAbstract) bytesAbstract = isBytesAbstract (t.get ());
					
					case TMono (_):
						
						Context.fatalError ("Invalid number of type parameters for " + localType.toString (), Context.currentPos ());
						return null;
					
					case TDynamic (_):
						
						switch (Context.getType ("haxe.io.Bytes")) {
							
							case TInst (t, args):
								
								type = t.get ();
								typeArgs = args;
							
							default:
								
								throw false;
							
						}
					
					default:
						
						throw false;
					
				}
				
			default:
				
				throw false;
			
		}
		
		var typeString = type.module;
		
		if (type.name != type.module && !StringTools.endsWith (type.module, "." + type.name)) {
			
			typeString += "." + type.name;
			
		}
		
		var typeParamString = typeString;
		
		if (typeArgs.length > 0) {
			
			typeParamString += "<";
			
			for (i in 0...typeArgs.length) {
				
				if (i > 0) typeParamString += ",";
				typeParamString += typeArgs[i].toString ();
				
			}
			
			typeParamString += ">";
			
		}
		
		var flattenedTypeString = typeParamString;
		
		flattenedTypeString = StringTools.replace (flattenedTypeString, "->", "_");
		flattenedTypeString = StringTools.replace (flattenedTypeString, ".", "_");
		flattenedTypeString = StringTools.replace (flattenedTypeString, "<", "_");
		flattenedTypeString = StringTools.replace (flattenedTypeString, ">", "_");
		
		var name = "_HTTPRequest_" + flattenedTypeString;
		
		try {
			
			Context.getType ("lime.net." + name);
			
		} catch (e:Dynamic) {
			
			var pos = Context.currentPos ();
			var fields = Context.getBuildFields ();
			var load = null;
			
			for (field in fields) {
				
				if (field.name == "load") {
					
					load = field;
					break;
					
				}
				
			}
			
			switch (load.kind) {
				
				case FFun (fun):
					
					if (typeString == "String") {
						
						fun.expr = macro { 
							
							if (uri != null) {
								
								this.uri = uri;
								
							}
							
							return cast backend.loadText (this.uri);
							
						};
						
					} else if (stringAbstract) {
						
						fun.expr = macro { 
							
							if (uri != null) {
								
								this.uri = uri;
								
							}
							
							var promise = new lime.app.Promise<T> ();
							var future = backend.loadText (this.uri);
							
							future.onProgress (promise.progress);
							future.onError (promise.error);
							
							future.onComplete (function (text) {
								
								responseData = cast text;
								promise.complete (responseData);
								
							});
							
							return promise.future;
							
						};
						
					} else {
						
						fun.expr = macro { 
							
							if (uri != null) {
								
								this.uri = uri;
								
							}
							
							var promise = new lime.app.Promise<T> ();
							var future = backend.loadData (this.uri);
							
							future.onProgress (promise.progress);
							future.onError (promise.error);
							
							future.onComplete (function (bytes) {
								
								responseData = cast fromBytes (bytes);
								promise.complete (responseData);
								
							});
							
							return promise.future;
							
						};
						
						var fromBytes = null;
						
						if (typeString == "haxe.io.Bytes" || bytesAbstract) {
							
							fromBytes = macro { return bytes; }
							
						} else {
							
							fromBytes = Context.parse ("return " + typeString + ".fromBytes (bytes)", pos);
							
						}
						
						fields.push ( { name: "fromBytes", access: [ APrivate, AInline ], kind: FFun ( { args: [ { name: "bytes", type: macro :haxe.io.Bytes } ], expr: fromBytes, params: [], ret: paramType.toComplexType () } ), pos: pos } );
						
					}
				
				default:
				
			}
			
			Context.defineType ({
				
				pos: pos,
				pack: [ "lime", "net" ],
				name: name,
				kind: TDClass (null, [ { pack: [ "lime", "net" ], name: "HTTPRequest", sub: "IHTTPRequest", params: [] } ], null),
				fields: fields,
				params: [ { name: "T" } ],
				meta: [ { name: ":dox", params: [ macro hide ], pos: pos }, { name: ":noCompletion", pos: pos } ]
				
			});
			
		}
		
		return TPath ( { pack: [ "lime", "net" ], name: name, params: [ TPType (paramType.toComplexType ()) ] } ).toType ();
		
	}
	
	
	private static function isBytesAbstract (type:AbstractType):Bool {
		
		while (type != null) {
			
			switch (type.type) {
				
				case TInst (t, _):
					
					return isBytesType (t.get ());
				
				case TAbstract (t, _):
					
					type = t.get ();
				
				default:
					
					return false;
				
			}
			
		}
		
		return false;
		
	}
	
	
	private static function isBytesType (type:ClassType):Bool {
		
		while (true) {
			
			if (type.module == "haxe.io.Bytes") return true;
			if (type.superClass == null) break;
			type = type.superClass.t.get ();
			
		}
		
		return false;
		
	}
	
	
	private static function isStringAbstract (type:AbstractType):Bool {
		
		while (type != null) {
			
			switch (type.type) {
				
				case TInst (t, _):
					
					return t.get ().module == "String";
				
				case TAbstract (t, _):
					
					type = t.get ();
				
				default:
					
					return false;
				
			}
			
		}
		
		return false;
		
	}
	
	
	
	
}


#end