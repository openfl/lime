package lime.utils;


import lime.utils.ByteArray;


interface IMemoryRange {
	
	
	public function getByteBuffer ():ByteArray;
	public function getStart ():Int;
	public function getLength ():Int;
	
	
}