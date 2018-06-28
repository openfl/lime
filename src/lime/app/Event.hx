package lime.app;


#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;
#end

#if (!macro && !display)
@:genericBuild(lime._internal.macros.EventMacro.build())
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class Event<T> {
	
	
	public var canceled (default, null):Bool;
	
	@:noCompletion @:dox(hide) public var __listeners:Array<T>;
	@:noCompletion @:dox(hide) public var __repeat:Array<Bool>;
	@:noCompletion private var __priorities:Array<Int>;
	
	
	public function new () {
		
		#if !macro
		canceled = false;
		__listeners = new Array ();
		__priorities = new Array<Int> ();
		__repeat = new Array<Bool> ();
		#end
		
	}
	
	
	public function add (listener:T, once:Bool = false, priority:Int = 0):Void {
		
		#if !macro
		for (i in 0...__priorities.length) {
			
			if (priority > __priorities[i]) {
				
				__listeners.insert (i, cast listener);
				__priorities.insert (i, priority);
				__repeat.insert (i, !once);
				return;
				
			}
			
		}
		
		__listeners.push (cast listener);
		__priorities.push (priority);
		__repeat.push (!once);
		#end
		
	}
	
	
	#if macro
	private static function build () {
		
		var typeArgs;
		var typeResult;
		
		switch (Context.follow (Context.getLocalType ())) {
			
			case TInst (_, [ Context.follow (_) => TFun (args, result) ]):
				
				typeArgs = args;
				typeResult = result;
			
			case TInst (localType, _):
				
				Context.fatalError ("Invalid number of type parameters for " + localType.toString (), Context.currentPos ());
				return null;
			
			default:
				
				throw false;
			
		}
		
		var typeParam = TFun (typeArgs, typeResult);
		var typeString = "";
		
		if (typeArgs.length == 0) {
			
			typeString = "Void->";
			
		} else {
			
			for (arg in typeArgs) {
				
				typeString += arg.t.toString () + "->";
				
			}
			
		}
		
		typeString += typeResult.toString ();
		typeString = StringTools.replace (typeString, "->", "_");
		typeString = StringTools.replace (typeString, ".", "_");
		typeString = StringTools.replace (typeString, "<", "_");
		typeString = StringTools.replace (typeString, ">", "_");
		
		var name = "_Event_" + typeString;
		
		try {
			
			Context.getType ("lime.app." + name);
			
		} catch (e:Dynamic) {
			
			var pos = Context.currentPos ();
			var fields = Context.getBuildFields ();
			
			var args:Array<FunctionArg> = [];
			var argName, argNames = [];
			
			for (i in 0...typeArgs.length) {
				
				if (i == 0) {
					
					argName = "a";
					
				} else {
					
					argName = "a" + i;
					
				}
				
				argNames.push (Context.parse (argName, pos));
				args.push ({ name: argName, type: typeArgs[i].t.toComplexType () });
				
			}
			
			var dispatch = macro {
				
				canceled = false;
				
				var listeners = __listeners;
				var repeat = __repeat;
				var i = 0;
				
				while (i < listeners.length) {
					
					listeners[i] ($a{argNames});
					
					if (!repeat[i]) {
						
						this.remove (cast listeners[i]);
						
					} else {
						
						i++;
						
					}
					
					if (canceled) {
						
						break;
						
					}
					
				}
				
			}
			
			var i = 0;
			var field;
			
			while (i < fields.length) {
				
				field = fields[i];
				
				if (field.name == "__listeners" || field.name == "dispatch") {
					
					fields.remove (field);
					
				} else {
					
					i++;
					
				}
				
			}
			
			fields.push ( { name: "__listeners", access: [ APublic ], kind: FVar (TPath ({ pack: [], name: "Array", params: [ TPType (typeParam.toComplexType ()) ] })), pos: pos } );
			fields.push ( { name: "dispatch", access: [ APublic ], kind: FFun ( { args: args, expr: dispatch, params: [], ret: macro :Void } ), pos: pos } );
			
			Context.defineType ({
				
				pos: pos,
				pack: [ "lime", "app" ],
				name: name,
				kind: TDClass (),
				fields: fields,
				params: [ { name: "T" } ],
				meta: [ { name: ":dox", params: [ macro hide ], pos: pos }, { name: ":noCompletion", pos: pos } ]
				
			});
			
		}
		
		return TPath ( { pack: [ "lime", "app" ], name: name, params: [ TPType (typeParam.toComplexType ()) ] } ).toType ();
		
	}
	#end
	
	
	public function cancel ():Void {
		
		canceled = true;
		
	}
	
	
	public var dispatch:Dynamic;
	
	//macro public function dispatch (ethis:Expr, args:Array<Expr>):Void {
		//
		//return macro {
			//
			//var listeners = $ethis.listeners;
			//var repeat = $ethis.repeat;
			//var i = 0;
			//
			//while (i < listeners.length) {
				//
				//listeners[i] ($a{args});
				//
				//if (!repeat[i]) {
					//
					//$ethis.remove (listeners[i]);
					//
				//} else {
					//
					//i++;
					//
				//}
				//
			//}
			//
		//}
		//
	//}
	
	
	public function has (listener:T):Bool {
		
		#if !macro
		for (l in __listeners) {
			
			if (Reflect.compareMethods (l, listener)) return true;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function remove (listener:T):Void {
		
		#if !macro
		var i = __listeners.length;
		
		while (--i >= 0) {
			
			if (Reflect.compareMethods (__listeners[i], listener)) {
				
				__listeners.splice (i, 1);
				__priorities.splice (i, 1);
				__repeat.splice (i, 1);
				
			}
			
		}
		#end
		
	}
	
	
}