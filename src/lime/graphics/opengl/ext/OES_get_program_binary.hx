package lime.graphics.opengl.ext;

@:keep
@:noCompletion class OES_get_program_binary
{
	public var PROGRAM_BINARY_LENGTH_OES = 0x8741;
	public var NUM_PROGRAM_BINARY_FORMATS_OES = 0x87FE;
	public var PROGRAM_BINARY_FORMATS_OES = 0x87FF;

	@:noCompletion private function new() {}

	// public function getProgramBinaryOES (program:GLProgram, bufSize:Int, length:Int, binaryFormat:Int, binary:BytesPointer):Void {}
	// public function programBinaryOES (program:GLProgram, binaryFormat:Int, binary:BytesPointer, length:Int):Void {}
}
