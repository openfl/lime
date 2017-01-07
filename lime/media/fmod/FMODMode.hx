package lime.media.fmod;
#if lime_console


import lime.ConsoleIncludePaths;


@:enum abstract FMODMode(Int) {

	var LOOP_OFF    = 0x00000001;
	var LOOP_NORMAL = 0x00000002;

}


#end
