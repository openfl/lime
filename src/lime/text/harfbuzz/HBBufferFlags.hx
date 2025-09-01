package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract HBBufferFlags(Int) from Int to Int
{
	public var DEFAULT = 0x00000000;
	public var BOT = 0x00000001;
	public var EOT = 0x00000002;
	public var PRESERVE_DEFAULT_IGNORABLES = 0x00000004;
}
#end
