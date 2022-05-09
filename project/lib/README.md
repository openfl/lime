Submodule projects
==================

Cairo: [homepage](https://www.cairographics.org/) | [repo](https://gitlab.freedesktop.org/cairo/cairo) | [GitHub mirror](https://github.com/freedesktop/cairo)

cURL: [homepage](https://curl.se/) | [repo](https://github.com/curl/curl)

efsw: [repo](https://github.com/SpartanJ/efsw)

FreeType: [homepage](https://freetype.org/) | [repo](https://gitlab.freedesktop.org/freetype/freetype) | [GitHub mirror](https://github.com/freetype/freetype)

HarfBuzz: [homepage](https://harfbuzz.github.io/) | [repo](https://github.com/harfbuzz/harfbuzz)

libjpeg: [homepage](https://ijg.org/) | [download](https://ijg.org/files/) | [unofficial GitHub mirror](https://github.com/openfl/libjpeg)

LZMA: [homepage + download](https://www.7-zip.org/sdk.html) | [unofficial GitHub mirror](https://github.com/openfl/liblzma)

Mbed TLS: [homepage](https://tls.mbed.org/) | [repo](https://github.com/Mbed-TLS/mbedtls)

MojoAL: [homepage](https://icculus.org/mojoAL/) | [repo](https://github.com/icculus/mojoAL/)

Neko: [homepage](https://nekovm.org/) | [repo](https://github.com/HaxeFoundation/neko)

Ogg: [homepage](https://www.xiph.org/ogg/) | [repo](https://github.com/xiph/ogg)

OpenAL soft: [homepage](https://openal-soft.org/) | [repo](https://github.com/kcat/openal-soft)

Pixman: [homepage](http://pixman.org/) | [repo](https://gitlab.freedesktop.org/pixman/pixman) | [GitHub mirror](https://github.com/freedesktop/pixman)

libpng: [homepage](http://www.libpng.org/pub/png/libpng.html) | [repo](https://sourceforge.net/p/libpng/code)

SDL: [homepage](https://www.libsdl.org/) | [repo](https://github.com/libsdl-org/SDL)

tiny file dialogs: [homepage](https://sourceforge.net/projects/tinyfiledialogs/) | [repo](https://sourceforge.net/p/tinyfiledialogs/code)

Vorbis: [homepage](https://www.xiph.org/vorbis/) | [repo](https://github.com/xiph/vorbis)

libvpx: [homepage](https://www.webmproject.org/tools/) | [repo](https://chromium.googlesource.com/webm/libvpx/) | [GitHub mirror](https://github.com/webmproject/libvpx/)

libwebm: [homepage](https://www.webmproject.org/about/) | [repo](https://chromium.googlesource.com/webm/libwebm) | [GitHub mirror](https://github.com/webmproject/libwebm)

zlib: [homepage](https://zlib.net/) | [repo](https://github.com/madler/zlib)

Overrides
---------

The overrides folder contains a number of customized headers and source files, to be used instead of the equivalent file(s) in the submodule. (Or in addition to: some submodules intentionally omit files, expecting the user to generate them.)

All cases require updating the corresponding files.xml file.

- To add or override a header, include the overrides folder first (if not already included).

   ```diff
   +<compilerflag value="-I${NATIVE_TOOLKIT_PATH}/overrides/sdl/" />
   <compilerflag value="-I${NATIVE_TOOLKIT_PATH}/sdl/include/" />
   ```

- To add a source file, insert a `<file />` tag.

   ```diff
   +<file name="${NATIVE_TOOLKIT_PATH}/overrides/sdl/SDL_extra.c" />
   ```

- To override a source file, replace the `<file />` tag.

   ```diff
   -<file name="${NATIVE_TOOLKIT_PATH}/sdl/src/SDL_log.c" />
   +<file name="${NATIVE_TOOLKIT_PATH}/overrides/sdl/SDL_log.c" />
   ```
