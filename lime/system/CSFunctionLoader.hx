package lime.system;
import cs.ndll.NDLLFunction;
import cs.NativeArray;

class CSFunctionLoader
{
	public static function load (name:String, func:String, args:Int):Dynamic {
		
		var func:NDLLFunction = NDLLFunction.Load (name, func, args);
		
		if (func == null) {
			
			return null;
			
		}
		
		if (args == -1) {
			
			var haxeFunc:Dynamic = function (args:Array<Dynamic>):Dynamic {
				
				return func.CallMult(args);
				
			}
			
			return Reflect.makeVarArgs (haxeFunc);
			
		} else if (args == 0) {
			
			return function ():Dynamic {
				
				return func.Call0();
				
			}
			
		} else if (args == 1) {
			
			return function (arg1:Dynamic):Dynamic {
				
				return func.Call1(arg1);
				
			}
			
		} else if (args == 2) {
			
			return function (arg1:Dynamic, arg2:Dynamic):Dynamic {
				
				return func.Call2(arg1, arg2);
				
			}
			
		} else if (args == 3) {
			
			return function (arg1:Dynamic, arg2:Dynamic, arg3:Dynamic):Dynamic {
				
				return func.Call3(arg1, arg2, arg3);
				
			}
			
		} else if (args == 4) {
			
			return function (arg1:Dynamic, arg2:Dynamic, arg3:Dynamic, arg4:Dynamic):Dynamic {
				
				return func.Call4(arg1, arg2, arg3, arg4);
				
			}
			
			
		} else if (args == 5) {
			
			return function (arg1:Dynamic, arg2:Dynamic, arg3:Dynamic, arg4:Dynamic, arg5:Dynamic):Dynamic {
				
				return func.Call5(arg1, arg2, arg3, arg4, arg5);
				
			}
			
		}
		
		return null;
		
	}
}