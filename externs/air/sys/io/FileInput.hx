package sys.io;

import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Error;

@:coreApi
class FileInput extends haxe.io.Input
{
	private var fd:Int;
	private var pos:Int;

	@:allow(sys.io.File)
	private function new(fd:Int)
	{
		this.fd = fd;
		pos = 0;
	}

	override public function readByte():Int
	{
		return 0;
	}

	override public function readBytes(s:Bytes, pos:Int, len:Int):Int
	{
		return 0;
	}

	override public function close():Void {}

	public function seek(p:Int, pos:FileSeek):Void
	{
		switch (pos)
		{
			case SeekBegin:
			// this.pos = p;
			case SeekEnd:
			// this.pos = cast Fs.fstatSync(fd).size + p;
			case SeekCur:
				// this.pos += p;
		}
	}

	public function tell():Int
	{
		return 0;
	}

	public function eof():Bool
	{
		return false;
	}
}
