package lime.utils;


#if html5
typedef ArrayBuffer = js.html.ArrayBuffer;
#elseif nodejs
typedef ArrayBuffer = nodejs.ArrayBuffer;
#else
typedef ArrayBuffer = lime.utils.ByteArray;
#end