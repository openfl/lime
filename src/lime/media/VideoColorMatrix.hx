package lime.media;

/**
	The matrix that converts a video's YCbCr samples to RGB.

	Streams without color information use `BT601` for standard definition and
	`BT709` for high definition.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract VideoColorMatrix(Int) from Int to Int
{
	/**
		ITU-R BT.601, used by standard definition video.
	**/
	var BT601 = 0;

	/**
		ITU-R BT.709, used by high definition video.
	**/
	var BT709 = 1;

	/**
		ITU-R BT.2020, used by ultra high definition and HDR video.
	**/
	var BT2020 = 2;
}
