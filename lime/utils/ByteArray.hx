package lime.utils;

#if lime_html5
   typedef ByteArray = lime.utils.html5.ByteArray;
#else
   typedef ByteArray = lime.utils.native.ByteArray;
#end //lime_html5
