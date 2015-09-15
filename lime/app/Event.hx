package lime.app;


#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;
#end

#if !macro
@:genericBuild(lime.app.Event.build())
#end


class Event<T> {
	
	
	@:noCompletion @:dox(hide) public var listeners:Array<T>;
	@:noCompletion @:dox(hide) public var repeat:Array<Bool>;
	
	private var priorities:Array<Int>;
	
	
	public function new () {
		
		#if !macro
		listeners = new Array ();
		priorities = new Array<Int> ();
		repeat = new Array<Bool> ();
		#end
		
	}
	
	
	public function add (listener:T, once:Bool = false, priority:Int = 0):Void {
		
		#if !macro
		for (i in 0...priorities.length) {
			
			if (priority > priorities[i]) {
				
				listeners.insert (i, cast listener);
				priorities.insert (i, priority);
				repeat.insert (i, !once);
				return;
				
			}
			
		}
		
		listeners.push (cast listener);
		priorities.push (priority);
		repeat.push (!once);
		#end
		
	}
	
	
	#if macro
	private static function build () {
		
		var typeArgs;
		var typeResult;
		
		switch (Context.getLocalType ()) {
			
			case TInst (_, [ TFun (args, result) ]):
				
				typeArgs = args;
				typeResult = result;
				
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
		
		var name = "Event_" + typeString;
		
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
				
				var listeners = this.listeners;
				var repeat = this.repeat;
				var i = 0;
				
				while (i < listeners.length) {
					
					listeners[i] ($a{argNames});
					
					if (!repeat[i]) {
						
						this.remove (cast listeners[i]);
						
					} else {
						
						i++;
						
					}
					
				}
				
			}
			
			var i = 0;
			var field;
			
			while (i < fields.length) {
				
				field = fields[i];
				
				if (field.name == "listeners" || field.name == "dispatch") {
					
					fields.remove (field);
					
				} else {
					
					i++;
					
				}
				
			}
			
			fields.push ( { name: "listeners", access: [ APublic ], kind: FVar (TPath ({ pack: [], name: "Array", params: [ TPType (typeParam.toComplexType ()) ] })), pos: pos } );
			fields.push ( { name: "dispatch", access: [ APublic ], kind: FFun ( { args: args, expr: dispatch, params: [], ret: macro :Void } ), pos: pos } );
			
			Context.defineType ({
				pos: pos,
				pack: [ "lime", "app" ],
				name: name,
				kind: TDClass (),
				fields: fields,
				params: [ { name: "T" } ],
				meta: [ ]
			});
			
		}
		
		return TPath ( { pack: [ "lime", "app" ], name: name, params: [ TPType (typeParam.toComplexType ()) ] } ).toType ();
		
	}
	#end
	
	
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
		for (l in listeners) {
			
			if (Reflect.compareMethods (l, listener)) return true;
			
		}
		#end
		
		return false;
		
	}
	
	
	public function remove (listener:T):Void {
		
		#if !macro
		var i = listeners.length;
		
		while (--i >= 0) {
			
			if (Reflect.compareMethods (listeners[i], listener)) {
				
				listeners.splice (i, 1);
				priorities.splice (i, 1);
				repeat.splice (i, 1);
				
			}
			
		}
		#end
		
	}
	
	
}