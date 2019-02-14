package cs.ndll;

extern class NDLLFunction
{
	static var Initialized(get, never):Bool;
	static function Initialize(arrayType:Class<Dynamic>, reflectType:Class<Dynamic>, functionType:Class<Dynamic>, hxObjectype:Class<Dynamic>):Void;
	static function Load(name:String, func:String, numArgs:Int):Dynamic;
	function CallMult(args:Dynamic):Dynamic;
	function Call0():Dynamic;
	function Call1(arg1:Dynamic):Dynamic;
	function Call2(arg1:Dynamic, arg2:Dynamic):Dynamic;
	function Call3(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic):Dynamic;
	function Call4(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic, arg4:Dynamic):Dynamic;
	function Call5(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic, arg4:Dynamic, arg5:Dynamic):Dynamic;
}
