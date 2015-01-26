package lime.utils;


#if (js && !display)
typedef ArrayBuffer = js.html.ArrayBuffer;
#else
typedef ArrayBuffer = lime.utils.ByteArray;
#end