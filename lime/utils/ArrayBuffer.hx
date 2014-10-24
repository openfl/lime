package lime.utils;


#if html5
typedef ArrayBuffer = js.html.ArrayBuffer;
#else
typedef ArrayBuffer = lime.utils.ByteArray;
#end