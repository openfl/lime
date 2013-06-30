package lime.utils;

#if lime_native
   typedef ByteArray = lime.utils.native.ByteArray;
#end //lime_native

#if lime_html5
   typedef ByteArray = lime.utils.html5.ByteArray;
#end //lime_html5
