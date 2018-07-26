class Build extends hxp.Script { public function new () { super ();

	var flash = new hxp.HXML ();
	flash.xml = "xml/Flash.xml";
	flash.swf = "obj/docs";
	flash.swfVersion = "17.0";
	flash.define ("display");
	flash.define ("doc_gen");
	flash.define ("lime-doc-gen");
	flash.addClassName ("ImportAll");
	flash.lib ("lime");
	flash.noOutput = true;
	flash.build ();

	var windows = new hxp.HXML ("
		-xml xml/Windows.xml
		-cpp obj/docs
		-D display
		-D native
		-D lime-cffi
		-D windows
		-D doc_gen
		-D lime-doc-gen
		ImportAll
		-lib lime
		--no-output
	");
	windows.build ();

	var mac = new hxp.HXML (sys.io.File.getContent ("hxml/mac.hxml")).build ();
	var linux = new hxp.HXML (sys.io.File.getContent ("hxml/linux.hxml")).build ();
	var ios = new hxp.HXML (sys.io.File.getContent ("hxml/ios.hxml")).build ();
	var android = new hxp.HXML (sys.io.File.getContent ("hxml/android.hxml")).build ();
	var html5 = new hxp.HXML (sys.io.File.getContent ("hxml/html5.hxml")).build ();

	Sys.command ("haxelib run dox -i xml -in lime --title \"Lime API Reference\" -D website \"http://lime.software\" -D logo \"/images/logo.png\" -D textColor 0x777777 -theme ../../assets/docs-theme --toplevel-package lime");

} }