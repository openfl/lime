package lime.media.vorbis;

#if (!lime_doc_gen || lime_vorbis)
class VorbisInfo
{
	public var bitrateLower:Int;
	public var bitrateNominal:Int;
	public var bitrateUpper:Int;
	// public var bitrateWindow:Int;
	public var channels:Int;
	public var rate:Int;
	public var version:Int;

	public function new() {}
}
#end
