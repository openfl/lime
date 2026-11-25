package lime._internal.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

class EventMacro
{
	public static function build()
	{
		var typeArgs;
		var typeResult;

		switch (Context.follow(Context.getLocalType()))
		{
			case TInst(_, [Context.follow(_) => TFun(args, result)]):
				typeArgs = args;
				typeResult = result;

			case TInst(_, []):
				Context.fatalError("Expected type parameter. Did you mean Event<Void -> Void>?", Context.currentPos());
				return null;

			case TInst(_, [paramType]):
				Context.fatalError("Expected function type. Did you mean Event<" + paramType.toString() + " -> Void>?", Context.currentPos());
				return null;

			case TInst(_, paramTypes):
				Context.fatalError("Expected only one type parameter. Did you mean Event<" + paramTypes.map(haxe.macro.TypeTools.toString).join(" -> ") + ">?",
					Context.currentPos());
				return null;

			default:
				throw false;
		}

		var typeParam = TFun(typeArgs, typeResult);
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
		typeString = StringTools.replace(typeString, "->", "_");
		typeString = StringTools.replace(typeString, ".", "_");
		typeString = StringTools.replace(typeString, "<", "_");
		typeString = StringTools.replace(typeString, ">", "_");

		var name = "_Event_" + typeString;

		try
		{
			Context.getType("lime.app." + name);
		}
		catch (e:Dynamic)
		{
			var pos = Context.currentPos();
			var fields = Context.getBuildFields();

			var args:Array<FunctionArg> = [];
			var argName, argNames = [];

			for (i in 0...typeArgs.length)
			{
				if (i == 0)
				{
					argName = "a";
				}
				else
				{
					argName = "a" + i;
				}

				argNames.push(Context.parse(argName, pos));
				args.push({name: argName, type: typeArgs[i].t.toComplexType()});
			}

			var dispatchListeners = macro
				{
					var listeners = __listeners;
					var repeat = __repeat;
					var i = 0;

					while (i < listeners.length)
					{
						var listener = listeners[i];
						var once = !repeat[i];
						var previous = null;
						var next = null;
						var priority = 0;

						// A once listener stops being a listener before it is called, so neither a
						// dispatch from inside it nor an exception from it can reach it again
						if (once)
						{
							previous = (i > 0) ? listeners[i - 1] : null;
							priority = __priorities[i];
							__removeAt(i);
							next = (i < listeners.length) ? listeners[i] : null;
						}

						var edits = __edits;

						listener($a{argNames});

						if (__edits == edits)
						{
							// A once listener's place has already been taken by the one after it
							if (!once) i++;
						}
						else if (once)
						{
							// The listener added or removed listeners: carry on from the one that was
							// after it, or after the one that was before it
							var index = (next != null) ? __indexOf(cast next, i) : -1;

							if (index < 0 && previous != null)
							{
								index = __indexOf(cast previous, i);
								if (index >= 0) index++;
							}

							if (index < 0)
							{
								// Neither is left: skip those added ahead of it, which have a higher priority
								index = 0;
								while (index < listeners.length && __priorities[index] > priority) index++;
							}

							i = index;
						}
						else
						{
							// When it was removed, the listener after it has already moved into its place
							var index = __indexOf(cast listener, i);
							if (index >= 0) i = index + 1;
						}

						if (canceled)
						{
							break;
						}
					}
				};

			// Keep listener exceptions on the original dispatch path without a cleanup wrapper.
			var dispatch = macro
				{
					__timestamp = lime.system.System.getTimer();
					canceled = false;
					$dispatchListeners;
				};

			var timestampDispatch = macro
				{
					__timestamp = timestamp;
					canceled = false;
					$dispatchListeners;
				};

			var i = 0;
			var field;

			while (i < fields.length)
			{
				field = fields[i];

				if (field.name == "__listeners" || field.name == "dispatch" || field.name == "__dispatchWithTimestamp")
				{
					fields.remove(field);
				}
				else
				{
					i++;
				}
			}

			fields.push(
				{
					name: "__listeners",
					access: [APublic],
					kind: FVar(TPath({pack: [], name: "Array", params: [TPType(typeParam.toComplexType())]})),
					pos: pos
				});
			fields.push(
				{
					name: "dispatch",
					access: [APublic],
					kind: FFun(
						{
							args: args,
							expr: dispatch,
							params: [],
							ret: macro :Void
						}),
					pos: pos
				});
			fields.push(
				{
					name: "__dispatchWithTimestamp",
					access: [APublic],
					kind: FFun(
						{
							args: [
								{name: "timestamp", type: macro :Int}].concat(args),
							expr: timestampDispatch,
							params: [],
							ret: macro :Void
						}),
					meta: [
						{name: ":dox", params: [macro hide], pos: pos},
						{name: ":noCompletion", pos: pos}
					],
					pos: pos
				});

			var meta:Array<MetadataEntry> = [
				{name: ":dox", params: [macro hide], pos: pos},
				{name: ":noCompletion", pos: pos}
			];

			#if !lime_debug
			meta.push({name: ":fileXml", params: [macro 'tags="haxe,release"'], pos: pos});
			meta.push({name: ":noDebug", pos: pos});
			#end

			Context.defineType(
				{
					pos: pos,
					pack: ["lime", "app"],
					name: name,
					kind: TDClass(),
					fields: fields,
					params: [
						{name: "T"}],
					meta: meta
				});
		}

		return TPath({pack: ["lime", "app"], name: name, params: [TPType(typeParam.toComplexType())]}).toType();
	}
}
#end
