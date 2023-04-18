package lime._internal.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

class CFFIMacro
{
	public static function build(defaultLibrary:String = "lime"):Array<Field>
	{
		var pos = Context.currentPos();
		var fields = Context.getBuildFields();
		var newFields:Array<Field> = [];

		for (field in fields)
		{
			switch (field)
			{
				case _ => {kind: FFun(fun), meta: meta}:
					for (m in meta)
					{
						if (m.name == ":cffi")
						{
							var library = null;
							var method = null;
							var lazy = false;

							if (Reflect.hasField(m, "params"))
							{
								if (m.params.length > 0) library = m.params[0].getValue();
								if (m.params.length > 1) method = m.params[1].getValue();
								if (m.params.length > 2) lazy = m.params[2].getValue();
							}

							if (library == null || library == "")
							{
								library = defaultLibrary;
							}

							if (method == null || method == "")
							{
								method = field.name;
							}

							var typeArgs = [];

							for (arg in fun.args)
							{
								typeArgs.push({name: arg.name, opt: false, t: arg.type.toType()});
							}

							var type = __getFunctionType(typeArgs, fun.ret.toType());

							var typeString = type.string;
							var typeSignature = type.signature;
							var expr = "";

							if (Context.defined("display") || Context.defined("disable_cffi"))
							{
								switch (type.result.toString())
								{
									case "Int", "Float", "cpp.Float32", "cpp.Int16", "cpp.Int32", "cpp.Float64":
										expr += "return 0";

									case "Bool":
										expr += "return false";

									case "Void":
										expr += "return";

									default:
										expr += "return null";
								}
							}
							else
							{
								var cffiName = "cffi_" + field.name;
								var cffiExpr, cffiType;

								if (Context.defined("cpp"))
								{
									cffiExpr = 'new cpp.Callable<$typeString> (cpp.Prime._loadPrime ("$library", "$method", "$typeSignature", $lazy))';

									// Sys.println ("private static var " + field.name + ':$typeString = CFFI.loadPrime ("$library", "$method", "$typeSignature");');
									// Sys.println ("private static var " + field.name + ' = new cpp.Callable<$typeString> (cpp.Prime._loadPrime ("$library", "$method", "$typeSignature", $lazy));');
								}
								else
								{
									var args = typeSignature.length - 1;

									if (args > 5)
									{
										args = -1;
									}

									cffiExpr = 'new cpp.Callable<$typeString> (lime.system.CFFI.load ("$library", "$method", $args, $lazy))';

									// Sys.println ("private static var " + field.name + ':$typeString = CFFI.load ("$library", "$method", $args);');
								}

								cffiType = TPath({pack: ["cpp"], name: "Callable", params: [TPType(TFun(type.args, type.result).toComplexType())]});

								newFields.push(
									{
										name: cffiName,
										access: [APrivate, AStatic],
										kind: FieldType.FVar(cffiType, Context.parse(cffiExpr, field.pos)),
										pos: field.pos
									});

								if (type.result.toString() != "Void" && type.result.toString() != "cpp.Void")
								{
									expr += "return ";
								}

								expr += '$cffiName.call (';

								for (i in 0...type.args.length)
								{
									if (i > 0) expr += ", ";
									expr += type.args[i].name;
								}

								expr += ")";

								// if (Context.defined ("cpp")) {

								// 	Sys.println ('private static var $cffiName = new cpp.Callable<$typeString> (cpp.Prime._loadPrime ("$library", "$method", "$typeSignature", $lazy));');

								// 	var _args = "";
								// 	for (i in 0...typeArgs.length) {
								// 		if (i > 0) _args += ", ";
								// 		_args += typeArgs[i].name + ":" + typeArgs[i].t.toString ();
								// 	}

								// 	Sys.println ('private static function ${field.name} ($_args) { $expr; }');

								// }
							}

							field.access.push(AInline);
							fun.expr = Context.parse(expr, field.pos);
						}
					}

				default:
			}
		}

		fields = fields.concat(newFields);
		return fields;
	}

	private static function __getFunctionType(args:Array<{name:String, opt:Bool, t:Type}>, result:Type)
	{
		#if (!disable_cffi && !display)
		var useCPPTypes = Context.defined("cpp");
		#else
		var useCPPTypes = false;
		#end

		var typeArgs = [];
		var typeResult = null;
		var typeSignature = "";

		for (arg in args)
		{
			switch (arg.t.toString())
			{
				case "Int", "cpp.Int16", "cpp.Int32":
					typeArgs.push(arg);
					typeSignature += "i";

				case "Bool":
					typeArgs.push(arg);
					typeSignature += "b";

				case "cpp.Float32":
					if (useCPPTypes)
					{
						typeArgs.push({name: arg.name, opt: false, t: (macro:cpp.Float32).toType()});
					}
					else
					{
						typeArgs.push(arg);
					}

					typeSignature += "f";

				case "Float", "cpp.Float64", "lime.utils.DataPointer":
					typeArgs.push(arg);
					typeSignature += "d";

				case "String":
					typeArgs.push(arg);
					typeSignature += "s";

				case "cpp.ConstCharStar":
					typeArgs.push(arg);
					typeSignature += "c";

				case "Void", "cpp.Void":
					if (useCPPTypes)
					{
						typeArgs.push({name: arg.name, opt: false, t: (macro:cpp.Void).toType()});
					}
					else
					{
						typeArgs.push(arg);
					}

					typeSignature += "v";

				default:
					if (useCPPTypes)
					{
						typeArgs.push({name: arg.name, opt: false, t: (macro:cpp.Object).toType()});
					}
					else
					{
						typeArgs.push({name: arg.name, opt: false, t: (macro:Dynamic).toType()});
					}

					typeSignature += "o";
			}
		}

		switch (result.toString())
		{
			case "Int", "cpp.Int16", "cpp.Int32":
				typeResult = result;
				typeSignature += "i";

			case "Bool":
				typeResult = result;
				typeSignature += "b";

			case "cpp.Float32":
				if (useCPPTypes)
				{
					typeResult = (macro:cpp.Float32).toType();
				}
				else
				{
					typeResult = result;
				}

				typeSignature += "f";

			case "Float", "cpp.Float64", "lime.utils.DataPointer":
				typeResult = result;
				typeSignature += "d";

			case "String":
				typeResult = result;
				typeSignature += "s";

			case "cpp.ConstCharStar":
				typeResult = result;
				typeSignature += "c";

			case "Void", "cpp.Void":
				if (useCPPTypes)
				{
					typeResult = (macro:cpp.Void).toType();
				}
				else
				{
					typeResult = result;
				}

				typeSignature += "v";

			default:
				if (useCPPTypes)
				{
					typeResult = (macro:cpp.Object).toType();
				}
				else
				{
					typeResult = (macro:Dynamic).toType();
				}

				typeSignature += "o";
		}

		var typeString = "";

		if (typeArgs.length == 0)
		{
			typeString = "Void->";
		}
		else
		{
			for (arg in typeArgs)
			{
				typeString += arg.t.toString() + "->";
			}
		}

		typeString += typeResult.toString();

		return {
			args: typeArgs,
			result: typeResult,
			string: typeString,
			signature: typeSignature
		};
	}
}
#end
