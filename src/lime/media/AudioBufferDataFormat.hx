package lime.media;

#if (haxe_ver >= 4.0) enum #else @:enum #end abstract AudioBufferDataFormat(Int) from Int to Int
{
	var PCM = 1;
	var IEEEFloat = 3;
}
