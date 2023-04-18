package lime.media.vorbis;

#if (!lime_doc_gen || lime_vorbis)
@:headerCode("
#undef EFAULT
#undef EINVAL
")
class Vorbis
{
	public static inline var FALSE = -1;
	public static inline var EOF = -2;
	public static inline var HOLE = -3;
	public static inline var EREAD = -128;
	public static inline var EFAULT = -129;
	public static inline var EIMPL = -130;
	public static inline var EINVAL = -131;
	public static inline var ENOTVORBIS = -132;
	public static inline var EBADHEADER = -133;
	public static inline var EVERSION = -134;
	public static inline var ENOTAUDIO = -135;
	public static inline var EBADPACKET = -136;
	public static inline var EBADLINK = -137;
	public static inline var ENOSEEK = -138;
	// TODO: Vorbis primitives
}
#end
