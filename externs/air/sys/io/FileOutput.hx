package sys.io;

import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Error;

@:coreApi
class FileOutput extends haxe.io.Output
{
	private var fd:Int;
	private var pos:Int;

	@:allow(sys.io.File)
	private function new(fd:Int)
	{
		this.fd = fd;
		pos = 0;
	}

	override public function writeByte(b:Int):Void {}

	override public function writeBytes(s:Bytes, pos:Int, len:Int):Int
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
}
