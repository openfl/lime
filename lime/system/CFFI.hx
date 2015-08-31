package lime.system;


import lime.system.System;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.ComplexTypeTools;
using haxe.macro.Tools;
#end

#if !macro
@:genericBuild(lime.system.CFFI.buildInstance())
#end


@:dce class CFFI<T> {
	
	
	#if macro
	public static function build ():Array<Field> {
		
		var pos = Context.currentPos ();
		var fields = Context.getBuildFields ();
		var newFields = [];
		
		for (field in fields) {
			
			switch (field) {
				
				case _ => { kind: FFun (fun), meta: meta } :
					
					for (m in meta) {
						
						if (m.name == ":cffi" && m.params.length >= 2) {
							
							var typeArgs = [];
							
							for (arg in fun.args) {
								
								typeArgs.push ( { name: arg.name, opt: false, t: arg.type.toType () } );
								
							}
							
							var type = getFunctionType (typeArgs, fun.ret.toType ());
							var typeString = type.string;
							
							var library = m.params[0].getValue ();
							var method = m.params[1].getValue ();
							var lazy = (m.params.length > 2) ? m.params[2].getValue () : false;
							var expr = 'new CFFI<$typeString> ("$library", "$method", $lazy)';
							var name = "cffi_" + field.name;
							
							var cffiType = TPath ( { pack: [ "lime", "system" ], name: "CFFI", params: [ TPType (TFun (type.args, type.result).toComplexType ()) ] } );
							
							newFields.push ( { name: name, access: [ APrivate, AStatic ], kind: FieldType.FVar (cffiType, Context.parse (expr, pos)), pos: pos } );
							
							var expr = "";
							
							if (type.result.toString () != "Void" && type.result.toString () != "cpp.Void") {
								
								expr = "return ";
								
							}
							
							expr += '$name.call (';
							
							for (i in 0...type.args.length) {
								
								if (i > 0) expr += ", ";
								expr += type.args[i].name;
								
							}
							
							expr += ")";
							
							fun.expr = Context.parse (expr, pos);
							field.access.push (AInline);
							
						}
						
					}
				
				default:
				
			}
			
		}
		
		fields = fields.concat (newFields);
		return fields;
		
	}
	
	
	private static function buildInstance ():ComplexType {
		
		var typeArgs = [];
		var typeResult = null;
		var typeString;
		var typeSignature = "";
		
		switch (Context.getLocalType ()) {
			
			case TInst (_, [ TFun (args, result) ]):
				
				var type = getFunctionType (args, result);
				typeArgs = type.args;
				typeResult = type.result;
				typeString = type.string;
				typeSignature = type.signature;
				
			default:
				
				throw false;
			
		}
		
		var typeParam = TFun (typeArgs, typeResult);
		
		var pos = Context.currentPos ();
		var name = "CFFI$" + StringTools.replace (typeString, ".", "_");
		
		try {
			
			Context.getType ("lime.system." + name);
			
		} catch (e:Dynamic) {
			
			var constructor:String;
			
			if (Context.defined ("cpp")) {
				
				constructor = 'this = new cpp.Callable<$typeString> (cpp.Prime._loadPrime (library, method, "$typeSignature", lazy))';
				
			} else {
				
				var args = typeSignature.length - 1;
				
				if (args > 5) {
					
					args = -1;
					
				}
				
				constructor = 'this = new cpp.Callable<$typeString> (lime.system.System.load (library, method, $args, lazy))';
				
			}
			
			var constructor = {
				pos: pos,
				name: "new",
				kind: FFun ({
					args: [ { name: "library", opt: false, type: macro :String }, { name: "method", opt: false, type: macro :String }, { name: "lazy", opt: true, value: macro false, type: macro :Bool } ],
					ret: null,
					expr: Context.parse (constructor, pos)
				}),
				access: [ APublic, AInline ]
			};
			
			var callable = TPath ( { pack: [ "cpp" ], name: "Callable", params: [ TPType (typeParam.toComplexType ()) ] } );
			
			Context.defineType ({
				pos: pos,
				pack: [ "lime", "system" ],
				name: name,
				kind: TDAbstract (callable, null, [ callable ]),
				fields: [ constructor ],
				params: [ { name: "T" } ],
				meta: [ { name: ":dce", pos: pos }, { name: ":forward", pos: pos } ]
			});
			
		}
		
		return TPath ( { pack: [ "lime", "system" ], name: name, params: [ TPType (typeParam.toComplexType ()) ] } );
		
	}
	
	
	private static function getFunctionType (args:Array<{ name : String, opt : Bool, t : Type }>, result:Type) {
		
		var isCPP = Context.defined ("cpp");
		
		var typeArgs = [];
		var typeResult = null;
		var typeSignature = "";
		
		for (arg in args) {
			
			switch (arg.t.toString ()) {
				
				case "Int", "cpp.Int16", "cpp.Int32":
					
					typeArgs.push (arg);
					typeSignature += "i";
				
				case "Bool":
					
					typeArgs.push (arg);
					typeSignature += "b";
				
				case "cpp.Float32":
					
					if (isCPP) {
						
						typeArgs.push ( { name: arg.name, opt: false, t: (macro :cpp.Float32).toType () } );
						
					} else {
						
						typeArgs.push (arg);
						
					}
					
					typeSignature += "f";
				
				case "Float", "cpp.Float64":
					
					typeArgs.push (arg);
					typeSignature += "d";
				
				case "String":
					
					typeArgs.push (arg);
					typeSignature += "s";
				
				case "cpp.ConstCharStar":
					
					typeArgs.push (arg);
					typeSignature += "c";
				
				case "Void", "cpp.Void":
					
					if (isCPP) {
						
						typeArgs.push ( { name: arg.name, opt: false, t: (macro :cpp.Void).toType () } );
						
					} else {
						
						typeArgs.push (arg);
						
					}
					
					if (typeSignature.length > 0) {
						
						typeSignature += "v";
						
					}
					
				default:
					
					if (isCPP) {
						
						typeArgs.push ( { name: arg.name, opt: false, t: (macro :cpp.Object).toType () } );
						
					} else {
						
						typeArgs.push ( { name: arg.name, opt: false, t: (macro :Dynamic).toType () } );
						
					}
					
					typeSignature += "o";
				
			}
			
		}
		
		switch (result.toString ()) {
			
			case "Int", "cpp.Int16", "cpp.Int32":
				
				typeResult = result;
				typeSignature += "i";
			
			case "Bool":
				
				typeResult = result;
				typeSignature += "b";
			
			case "cpp.Float32":
				
				if (isCPP) {
					
					typeResult = (macro :cpp.Float32).toType ();
					
				} else {
					
					typeResult = result;
					
				}
				
				typeSignature += "f";
			
			case "Float", "cpp.Float64":
				
				typeResult = result;
				typeSignature += "d";
			
			case "String":
				
				typeResult = result;
				typeSignature += "s";
			
			case "cpp.ConstCharStar":
				
				typeResult = result;
				typeSignature += "c";
			
			case "Void", "cpp.Void":
				
				if (isCPP) {
					
					typeResult = (macro :cpp.Void).toType ();
					
				} else {
					
					typeResult = result;
					
				}
				
				typeSignature += "v";
				
			default:
				
				if (isCPP) {
					
					typeResult = (macro :cpp.Object).toType ();
					
				} else {
					
					typeResult = (macro :Dynamic).toType ();
					
				}
				
				typeSignature += "o";
			
		}
		
		var typeString = "";
		
		if (typeArgs.length == 0) {
			
			typeString = "Void->";
			
		} else {
			
			for (arg in typeArgs) {
				
				typeString += arg.t.toString () + "->";
				
			}
			
		}
		
		typeString += typeResult.toString ();
		
		return { args: typeArgs, result: typeResult, string: typeString, signature: typeSignature,  };
		
	}
	#end
	
	
}