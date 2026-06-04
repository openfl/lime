package lime.media;

/**
	The decoded pixel format represented by a `VideoFrame`.
**/
enum abstract VideoFrameFormat(String) from String to String
{
	/**
		Interleaved red, green, blue, alpha bytes.
	**/
	var RGBA = "rgba";
}
