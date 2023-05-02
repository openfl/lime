package flash.media;

@:native("flash.media.MediaType")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract MediaType(String)
{
	var IMAGE;
	var VIDEO;
}
