package lime.utils;


#if js
typedef ArrayBuffer = js.html.ArrayBuffer;
#else
typedef ArrayBuffer = lime.utils.ByteArray;
#end