package flash.sampler;

extern class ScriptSampler
{
	function new():Void;
	static function getFilename(p1:Float):String;
	static function getInvocationCount(p1:Float):Float;
	static function getMembers(p1:Float):flash.Vector<ScriptMember>;
	static function getName(p1:Float):String;
	static function getSize(p1:Float):Float;
	static function getType(p1:Float):String;
}
