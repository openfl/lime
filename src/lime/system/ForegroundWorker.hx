package lime.system;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#if target.threaded
import sys.thread.Thread;
#elseif cpp
import cpp.vm.Thread;
#elseif neko
import neko.vm.Thread;
#end

/**
	An object whose instance functions always run on the main thread. If called
	from any other thread, they'll switch to the main thread before proceeding.

	Usage:

	```haxe
	class MyClass extends ForegroundWorker
	{
		public function foregroundFunction():Void
		{
			// Code here is guaranteed to run on Haxe's main thread.
		}

		@:anyThread public function anyThreadFunction():Void
		{
			// Code here will run on whichever thread calls the function, thanks
			// to `@:anyThread`.
		}
	}
	```

	@see `ForegroundWorkerBuilder` for details and more options.
**/
#if (target.threaded || cpp || neko)
@:autoBuild(lime.system.ForegroundWorkerBuilder.modifyInstanceFunctions())
#end
// Yes, this could also be an interface, but that opens up edge cases. Better to
// leave those for advanced users who use `ForegroundWorkerBuilder`.
class ForegroundWorker
{
	#if (target.threaded || cpp || neko)
	private static var mainThread:Thread = Thread.current();
	#end

	/**
		@return Whether the calling function is being run on the main thread.
	**/
	public static inline function onMainThread():Bool
	{
		#if (target.threaded || cpp || neko)
		return Thread.current() == mainThread;
		#else
		return true;
		#end
	}
}

class ForegroundWorkerBuilder
{
	/**
		A build macro that iterates through a class's instance functions
		(excluding those marked `@:anyThread`) and inserts code to ensure these
		functions run only on the main thread.

		Caution: build macros never directly modify superclasses. To make a
		superclass's functions run on the main thread, either annotate that
		class with its own `@:build` metadata or override all of its functions.

		Usage:

		```haxe
		@:build(lime.system.ForegroundWorker.ForegroundWorkerBuilder.modifyInstanceFunctions())
		class MyClass
		{
			public var array0:Array<String> = [];
			private var array1:Array<String> = [];

			public function copyItems():Void
			{
				//Thread safety code will be inserted automatically. You can
				//write thread-unsafe code as normal.
				for (i in 0...array0.length)
					if (this.array0[i] != null)
						this.array1.push(this.array0[i]);
			}
		}
		```
	**/
	public static macro function modifyInstanceFunctions():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();

		for (field in fields)
		{
			if (field.access.indexOf(AStatic) >= 0)
				continue;

			modifyField(field);
		}

		return fields;
	}

	/**
		A build macro that iterates through a class's static functions
		(excluding those marked `@:anyThread`) and inserts code to ensure these
		functions run only on the main thread.

		Usage:

		```haxe
		@:build(lime.system.ForegroundWorker.ForegroundWorkerBuilder.modifyStaticFunctions())
		class MyClass
		{
			private static var eventCount:Map<String, Int> = new Map();
			public static function countEvent(event:String):Void
			{
				//Thread safety code will be inserted automatically. You can
				//write thread-unsafe code as normal.
				if (eventCount.exists(event))
					eventCount[event]++;
				else
					eventCount[event] = 1;
			}
		}
		```
	**/
	public static macro function modifyStaticFunctions():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();

		for (field in fields)
		{
			if (field.access.indexOf(AStatic) < 0)
				continue;

			modifyField(field);
		}

		return fields;
	}

	#if macro
	private static function modifyField(field:Field):Void
	{
		if (field.name == "new")
			return;

		if (field.meta != null)
		{
			for (meta in field.meta)
			{
				if (meta.name == ":anyThread")
					return;
			}
		}

		switch (field.kind)
		{
			case FFun(f):
				var qualifiedIdent:Array<String>;
				if (field.access.indexOf(AStatic) >= 0)
				{
					if (Context.getLocalClass() == null)
						throw "ForegroundWorkerBuilder is only designed to work on classes.";

					var localClass:ClassType = Context.getLocalClass().get();
					qualifiedIdent = localClass.pack.copy();
					if (localClass.module != localClass.name)
						qualifiedIdent.push(localClass.module);
					qualifiedIdent.push(localClass.name);
				}
				else
				{
					qualifiedIdent = [];
				}
				qualifiedIdent.push(field.name);

				var args:Array<Expr> = [for (arg in f.args) macro $i{arg.name}];

				var exprs:Array<Expr>;
				switch (f.expr.expr)
				{
					case EBlock(e):
						exprs = e;
					default:
						exprs = [f.expr];
						f.expr = { pos: field.pos, expr: EBlock(exprs) };
				}

				exprs.unshift(macro
					if (!lime.system.ForegroundWorker.onMainThread())
					{
						haxe.MainLoop.runInMainThread($p{qualifiedIdent}.bind($a{args}));
						return;
					}
				);
			default:
		}
	}
	#end
}
