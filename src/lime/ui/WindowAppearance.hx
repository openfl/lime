package lime.ui;

/**
	Preferred appearance for native window decorations and supported menus. This does not recolor rendered content.
	Platforms may ignore the preference or apply it to only some native surfaces.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract WindowAppearance(String) to String
{
	/** Use the platform's appearance preference. **/
	var System = "system";
	/** Prefer light window decorations. **/
	var Light = "light";
	/** Prefer dark window decorations. **/
	var Dark = "dark";
}
