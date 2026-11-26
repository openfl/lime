/* zlib_name_mangling.h has been automatically generated from
 * zlib_name_mangling.h.in because ZLIB_SYMBOL_PREFIX was set.
 */

#ifndef ZLIB_NAME_MANGLING_H
#define ZLIB_NAME_MANGLING_H

/* all linked symbols and init macros */
#define _dist_code            lime__dist_code
#define _length_code          lime__length_code
#define _tr_align             lime__tr_align
#define _tr_flush_bits        lime__tr_flush_bits
#define _tr_flush_block       lime__tr_flush_block
#define _tr_init              lime__tr_init
#define _tr_stored_block      lime__tr_stored_block
#define _tr_tally             lime__tr_tally
#define adler32               lime_adler32
#define adler32_combine       lime_adler32_combine
#define adler32_combine64     lime_adler32_combine64
#define adler32_z             lime_adler32_z
#ifndef Z_SOLO
#  define compress              lime_compress
#  define compress2             lime_compress2
#  define compressBound         lime_compressBound
#endif
#define crc32                 lime_crc32
#define crc32_combine         lime_crc32_combine
#define crc32_combine64       lime_crc32_combine64
#define crc32_combine_gen     lime_crc32_combine_gen
#define crc32_combine_gen64   lime_crc32_combine_gen64
#define crc32_combine_op      lime_crc32_combine_op
#define crc32_z               lime_crc32_z
#define deflate               lime_deflate
#define deflateBound          lime_deflateBound
#define deflateCopy           lime_deflateCopy
#define deflateEnd            lime_deflateEnd
#define deflateGetDictionary  lime_deflateGetDictionary
#define deflateInit           lime_deflateInit
#define deflateInit2          lime_deflateInit2
#define deflateInit2_         lime_deflateInit2_
#define deflateInit_          lime_deflateInit_
#define deflateParams         lime_deflateParams
#define deflatePending        lime_deflatePending
#define deflatePrime          lime_deflatePrime
#define deflateReset          lime_deflateReset
#define deflateResetKeep      lime_deflateResetKeep
#define deflateSetDictionary  lime_deflateSetDictionary
#define deflateSetHeader      lime_deflateSetHeader
#define deflateTune           lime_deflateTune
#define deflate_copyright     lime_deflate_copyright
#define fill_window           lime_fill_window
#define fixedtables           lime_fixedtables
#define flush_pending         lime_flush_pending
#define get_crc_table         lime_get_crc_table
#ifndef Z_SOLO
#  define gz_error              lime_gz_error
#  define gz_strwinerror        lime_gz_strwinerror
#  define gzbuffer              lime_gzbuffer
#  define gzclearerr            lime_gzclearerr
#  define gzclose               lime_gzclose
#  define gzclose_r             lime_gzclose_r
#  define gzclose_w             lime_gzclose_w
#  define gzdirect              lime_gzdirect
#  define gzdopen               lime_gzdopen
#  define gzeof                 lime_gzeof
#  define gzerror               lime_gzerror
#  define gzflush               lime_gzflush
#  define gzfread               lime_gzfread
#  define gzfwrite              lime_gzfwrite
#  define gzgetc                lime_gzgetc
#  define gzgetc_               lime_gzgetc_
#  define gzgets                lime_gzgets
#  define gzoffset              lime_gzoffset
#  define gzoffset64            lime_gzoffset64
#  define gzopen                lime_gzopen
#  define gzopen64              lime_gzopen64
#  ifdef _WIN32
#    define gzopen_w              lime_gzopen_w
#  endif
#  define gzprintf              lime_gzprintf
#  define gzputc                lime_gzputc
#  define gzputs                lime_gzputs
#  define gzread                lime_gzread
#  define gzrewind              lime_gzrewind
#  define gzseek                lime_gzseek
#  define gzseek64              lime_gzseek64
#  define gzsetparams           lime_gzsetparams
#  define gztell                lime_gztell
#  define gztell64              lime_gztell64
#  define gzungetc              lime_gzungetc
#  define gzvprintf             lime_gzvprintf
#  define gzwrite               lime_gzwrite
#endif
#define inflate               lime_inflate
#define inflateBack           lime_inflateBack
#define inflateBackEnd        lime_inflateBackEnd
#define inflateBackInit       lime_inflateBackInit
#define inflateBackInit_      lime_inflateBackInit_
#define inflateCodesUsed      lime_inflateCodesUsed
#define inflateCopy           lime_inflateCopy
#define inflateEnd            lime_inflateEnd
#define inflateGetDictionary  lime_inflateGetDictionary
#define inflateGetHeader      lime_inflateGetHeader
#define inflateInit           lime_inflateInit
#define inflateInit2          lime_inflateInit2
#define inflateInit2_         lime_inflateInit2_
#define inflateInit_          lime_inflateInit_
#define inflateMark           lime_inflateMark
#define inflatePrime          lime_inflatePrime
#define inflateReset          lime_inflateReset
#define inflateReset2         lime_inflateReset2
#define inflateResetKeep      lime_inflateResetKeep
#define inflateSetDictionary  lime_inflateSetDictionary
#define inflateSync           lime_inflateSync
#define inflateSyncPoint      lime_inflateSyncPoint
#define inflateUndermine      lime_inflateUndermine
#define inflateValidate       lime_inflateValidate
#define inflate_copyright     lime_inflate_copyright
#define inflate_ensure_window lime_inflate_ensure_window
#define inflate_fast          lime_inflate_fast
#define inflate_table         lime_inflate_table
#define read_buf              lime_read_buf
#ifndef Z_SOLO
#  define uncompress            lime_uncompress
#  define uncompress2           lime_uncompress2
#endif
#define zError                lime_zError
#ifndef Z_SOLO
#  define zcalloc               lime_zcalloc
#  define zcfree                lime_zcfree
#endif
#define zlibCompileFlags      lime_zlibCompileFlags
#define zlibVersion           lime_zlibVersion

/* all zlib typedefs in zlib.h and zconf.h */
#define Byte                  lime_Byte
#define Bytef                 lime_Bytef
#define alloc_func            lime_alloc_func
#define charf                 lime_charf
#define free_func             lime_free_func
#ifndef Z_SOLO
#  define gzFile                lime_gzFile
#endif
#define gz_header             lime_gz_header
#define gz_headerp            lime_gz_headerp
#define in_func               lime_in_func
#define intf                  lime_intf
#define out_func              lime_out_func
#define uInt                  lime_uInt
#define uIntf                 lime_uIntf
#define uLong                 lime_uLong
#define uLongf                lime_uLongf
#define voidp                 lime_voidp
#define voidpc                lime_voidpc
#define voidpf                lime_voidpf

/* all zlib structs in zlib.h and zconf.h */
#define gz_header_s           lime_gz_header_s
#define internal_state        lime_internal_state

/* all zlib structs in zutil.h */
#define z_errmsg              lime_z_errmsg
#define z_vstring             lime_z_vstring
#define zlibng_version        lime_zlibng_version

/* zlib-ng specific symbols */
#define zng_alloc_aligned     lime_zng_alloc_aligned
#define zng_free_aligned      lime_zng_free_aligned

#endif /* ZLIB_NAME_MANGLING_H */
