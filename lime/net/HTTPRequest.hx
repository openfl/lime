package lime.net; #if !macro


import haxe.io.Bytes;
import lime.app.Event;
import lime.app.Future;
import lime.app.Promise;


#if display

class HTTPRequest<T> {

#else

@:genericBuild(lime.net.HTTPRequest.build())
class HTTPRequest<T> extends AbstractHTTPRequest<T> {}

private class AbstractHTTPRequest<T> implements _IHTTPRequest {
	
#end
	
	public var contentType:String;
	public var data:Bytes;
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
	
	#if !display
	private var backend:HTTPRequestBackend;
	private var promise:Promise<T>;
	#end
	
	
	public function new (uri:String = null) {
		
		this.uri = uri;
		
		contentType = "application/x-www-form-urlencoded";
		followRedirects = true;
		formData = new Map ();
		headers = [];
		method = GET;
		timeout = 30000;
		
		#if !display
		backend = new HTTPRequestBackend ();
		backend.init (this);
		#end
		
	}
	
	
	public function cancel ():Void {
		
		#if !display
		backend.cancel ();
		#end
		
	}
	
	
	public function load (uri:String = null):Future<T> {
		
		return null;
		
	}
	
	
}


#if !display


class _HTTPRequest_Bytes<T> extends AbstractHTTPRequest<T> {
	
	
	public function new (uri:String = null) {
		
		super (uri);
		
	}
	
	
	private function fromBytes (bytes:Bytes):T {
		
		return cast bytes;
		
	}
	
	
	public override function load (uri:String = null):Future<T> {
		
		if (promise != null) {
			
			return promise.future;
			
		}

		if (uri != null) {
			
			this.uri = uri;
			
		}
		
		promise = new Promise<T> ();
		var future = backend.loadData (this.uri);
		
		future.onProgress (promise.progress);
		future.onError (promise.error);
		
		future.onComplete (function (bytes) {
			
			responseData = fromBytes (bytes);
			promise.complete (responseData);
			
		});
		
		return promise.future;
		
	}
	
	
}


class _HTTPRequest_String<T> extends AbstractHTTPRequest<T> {
	
	
	public function new (uri:String = null) {
		
		super (uri);
		
	}
	
	
	public override function load (uri:String = null):Future<T> {
		
		if (promise != null) {
			
			return promise.future;
			
		}

		if (uri != null) {
			
			this.uri = uri;
			
		}
		
		promise = new Promise<T> ();
		var future = backend.loadText (this.uri);
		
		future.onProgress (promise.progress);
		future.onError (promise.error);
		
		future.onComplete (function (text) {
			
			responseData = cast text;
			promise.complete (responseData);
			
		});
		
		return promise.future;
		
	}
	
	
}


interface _IHTTPRequest {
	
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
	
	public function cancel ():Void;
	
}


#if flash
private typedef HTTPRequestBackend = lime._backend.flash.FlashHTTPRequest;
#elseif (js && html5)
private typedef HTTPRequestBackend = lime._backend.html5.HTML5HTTPRequest;
#else
private typedef HTTPRequestBackend = lime._backend.native.NativeHTTPRequest;
#end
#end


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
					
					case TType (t, args):
						
						type = t.get ();
						typeArgs = args;
					
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
		
		if (typeString == "String" || stringAbstract) {
			
			return TPath ( { pack: [ "lime", "net" ], name: "HTTPRequest", sub: "_HTTPRequest_String", params: [ TPType (paramType.toComplexType ()) ] } ).toType ();
			
		} else if (typeString == "haxe.io.Bytes" || bytesAbstract) {
			
			return TPath ( { pack: [ "lime", "net" ], name: "HTTPRequest", sub: "_HTTPRequest_Bytes", params: [ TPType (paramType.toComplexType ()) ] } ).toType ();
			
		} else {
		
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
				
				var fields = [
					{ name: "new", access: [ APublic ], kind: FFun({ args: [ { name: "uri", type: macro :String, opt: true } ], expr: macro { super (uri); }, params: [], ret: macro :Void }), pos: Context.currentPos () },
					{ name: "fromBytes", access: [ APrivate, AOverride ], kind: FFun ( { args: [ { name: "bytes", type: macro :haxe.io.Bytes } ], expr: Context.parse ("return " + typeString + ".fromBytes (bytes)", pos), params: [], ret: paramType.toComplexType () } ), pos: pos }
				];
				
				Context.defineType ({
					
					name: name,
					pack: [ "lime", "net" ],
					kind: TDClass ({ pack: [ "lime", "net" ], name: "HTTPRequest", sub: "_HTTPRequest_Bytes", params: [ TPType (paramType.toComplexType ()) ] }, null, false),
					fields: fields,
					pos: pos
					
				});
				
			}
			
			return TPath ( { pack: [ "lime", "net" ], name: name, params: [] } ).toType ();
			
		}
		
	}
	
	
	private static function isBytesAbstract (type:AbstractType):Bool {
		
		while (type != null) {
			
			switch (type.type) {
				
				case TInst (t, _):
					
					return t.get ().module == "haxe.io.Bytes";
				
				case TAbstract (t, _):
					
					type = t.get ();
				
				default:
					
					return false;
				
			}
			
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