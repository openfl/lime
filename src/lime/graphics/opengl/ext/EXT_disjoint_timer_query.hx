package lime.graphics.opengl.ext;

#if (js && html5)
@:keep
@:native("EXT_disjoint_timer_query")
@:noCompletion extern class EXT_disjoint_timer_query
{
	public var QUERY_COUNTER_BITS_EXT:Int;
	public var CURRENT_QUERY_EXT:Int;
	public var QUERY_RESULT_EXT:Int;
	public var QUERY_RESULT_AVAILABLE_EXT:Int;
	public var TIME_ELAPSED_EXT:Int;
	public var TIMESTAMP_EXT:Int;
	public var GPU_DISJOINT_EXT:Int;
	public function createQueryEXT():Dynamic; /*WebGLQuery*/
	public function deleteQueryEXT(query:Dynamic /*WebGLQuery*/):Void;
	public function isQueryEXT(query:Dynamic /*WebGLQuery*/):Bool;
	public function beginQueryEXT(target:Int, query:Dynamic /*WebGLQuery*/):Void;
	public function endQueryEXT(target:Int):Void;
	public function queryCounterEXT(query:Dynamic /*WebGLQuery*/, target:Int):Void;
	public function getQueryEXT(target:Int, pname:Int):Dynamic; /*WebGLQuery or Int*/
	public function getQueryObjectEXT(query:Dynamic /*WebGLQuery*/, pname:Int):Dynamic;
}
#end
