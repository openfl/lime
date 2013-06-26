package lime.utils;
#if (lime_native || lime_html5)
// #if (cpp || neko)

enum CompressionAlgorithm {
    DEFLATE;
    ZLIB;
    LZMA;
    GZIP;
} 

#else
typedef CompressionAlgorithm = flash.utils.CompressionAlgorithm;
#end