package project;


#if openfl

import openfl.Assets;
typedef AssetType = openfl.AssetType;

#else

enum AssetType {
	
	BINARY;
	FONT;
	IMAGE;
	MOVIE_CLIP;
	MUSIC;
	SOUND;
	TEMPLATE;
	TEXT;
	
}

#end