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
@:genericBuild(lime.system.CFFI.build())
#end


@:dce class CFFI<T> {
	
	
	#if macro
	private static function build ():ComplexType {
		
		var typeArgs = [];
		var typeResult = null;
		
		var isCPP = Context.defined ("cpp");
		var signature = "";
		
		switch (Context.getLocalType ()) {
			
			case TInst (_, [ type ]):
				
				switch (type) {
					
					case TFun (args, result):
						
						for (arg in args) {
							
							switch (arg.t.toString ()) {
								
								case "Int", "Int16", "Int32":
									
									typeArgs.push (arg);
									signature += "i";
								
								case "Bool":
									
									typeArgs.push (arg);
									signature += "b";
								
								case "Float32":
									
									if (isCPP) {
										
										typeArgs.push ( { name: "arg", opt: false, t: (macro :cpp.Float32).toType () } );
										
									} else {
										
										typeArgs.push (arg);
										
									}
									
									signature += "f";
								
								case "Float", "Float64":
									
									typeArgs.push (arg);
									signature += "d";
								
								case "String":
									
									typeArgs.push (arg);
									signature += "s";
								
								case "ConstCharStar":
									
									typeArgs.push (arg);
									signature += "c";
								
								case "Void":
									
									if (isCPP) {
										
										typeArgs.push ( { name: "arg", opt: false, t: (macro :cpp.Void).toType () } );
										
									} else {
										
										typeArgs.push (arg);
										
									}
									
									if (signature.length > 0) {
										
										signature += "v";
										
									}
									
								default:
									
									if (isCPP) {
										
										typeArgs.push ( { name: "arg", opt: false, t: (macro :cpp.Object).toType () } );
										
									} else {
										
										typeArgs.push ( { name: "arg", opt: false, t: (macro :Dynamic).toType () } );
										
									}
									
									signature += "o";
								
							}
							
						}
						
						switch (result.toString ()) {
							
							case "Int", "Int16", "Int32":
								
								typeResult = result;
								signature += "i";
							
							case "Bool":
								
								typeResult = result;
								signature += "b";
							
							case "Float32":
								
								if (isCPP) {
									
									typeResult = (macro :cpp.Float32).toType ();
									
								} else {
									
									typeResult = result;
									
								}
								
								signature += "f";
							
							case "Float", "Float64":
								
								typeResult = result;
								signature += "d";
							
							case "String":
								
								typeResult = result;
								signature += "s";
							
							case "ConstCharStar":
								
								typeResult = result;
								signature += "c";
							
							case "Void":
								
								if (isCPP) {
									
									typeResult = (macro :cpp.Void).toType ();
									
								} else {
									
									typeResult = result;
									
								}
								signature += "v";
								
							default:
								
								if (isCPP) {
									
									typeResult = (macro :cpp.Object).toType ();
									
								} else {
									
									typeResult = (macro :Dynamic).toType ();
									
								}
								
								signature += "o";
							
						}
					
					default:
						
						throw false;
					
				}
				
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
		
		var pos = Context.currentPos ();
		var name = "CFFI$" + StringTools.replace (typeString, ".", "_");
		
		try {
			
			Context.getType ("lime.system." + name);
			
		} catch (e:Dynamic) {
			
			var constructor:String;
			
			if (isCPP) {
				
				constructor = 'this = new cpp.Callable<$typeString> (cpp.Prime._loadPrime (library, method, "$signature", lazy))';
				
			} else {
				
				var args = signature.length - 1;
				
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
	#end
	
	
}