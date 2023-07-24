package flash.media;

@:native("flash.media.MediaType")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract MediaType(String)
{
	var IMAGE;
	var VIDEO;
}
