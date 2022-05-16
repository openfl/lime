# Submodule projects
Lime includes code from several other C/C++ libraries, listed below. Lime prefers to use GitHub repositories as its submodules, purely so that the links will be clickable when viewed on github.com. However, some of these repos are mirrors, with the development being conducted elsewhere.

**_Always submit issues and pull requests to the primary repo, not to a GitHub mirror._**

- [**Cairo**](https://www.cairographics.org/) | [primary repo](https://gitlab.freedesktop.org/cairo/cairo) | [GitHub mirror](https://github.com/freedesktop/cairo)
- [**cURL**](https://curl.se/) | [primary repo](https://github.com/curl/curl)
- **efsw** | [primary repo](https://github.com/SpartanJ/efsw)
- [**FreeType**](https://freetype.org/) | [primary repo](https://gitlab.freedesktop.org/freetype/freetype) | [GitHub mirror](https://github.com/freetype/freetype)
- [**HarfBuzz**](https://harfbuzz.github.io/) | [primary repo](https://github.com/harfbuzz/harfbuzz)
- [**libjpeg**](https://ijg.org/) | [download](https://ijg.org/files/) | [unofficial GitHub mirror](https://github.com/openfl/libjpeg)
- **LZMA** | [download](https://www.7-zip.org/sdk.html) | [unofficial GitHub mirror](https://github.com/openfl/liblzma)
- [**mbed TLS**](https://tls.mbed.org/) | [primary repo](https://github.com/Mbed-TLS/mbedtls)
- [**MojoAL**](https://icculus.org/mojoAL/) | [primary repo](https://github.com/icculus/mojoAL/)
- [**Neko**](https://nekovm.org/) | [primary repo](https://github.com/HaxeFoundation/neko)
- [**Ogg**](https://www.xiph.org/ogg/) | [primary repo](https://github.com/xiph/ogg)
- [**OpenAL Soft**](https://openal-soft.org/) | [primary repo](https://github.com/kcat/openal-soft)
- [**Pixman**](http://pixman.org/) | [primary repo](https://gitlab.freedesktop.org/pixman/pixman) | [GitHub mirror](https://github.com/freedesktop/pixman)
- [**libpng**](http://www.libpng.org/pub/png/libpng.html) | [primary repo](https://sourceforge.net/p/libpng/code)
- [**SDL**](https://www.libsdl.org/) | [primary repo](https://github.com/libsdl-org/SDL)
- [**tiny file dialogs**](https://sourceforge.net/projects/tinyfiledialogs/) | [primary repo](https://sourceforge.net/p/tinyfiledialogs/code)
- [**Vorbis**](https://www.xiph.org/vorbis/) | [primary repo](https://github.com/xiph/vorbis)
- [**libvpx**](https://www.webmproject.org/tools/) | [primary repo](https://chromium.googlesource.com/webm/libvpx/) | [GitHub mirror](https://github.com/webmproject/libvpx/)
- [**libwebm**](https://www.webmproject.org/about/) | [primary repo](https://chromium.googlesource.com/webm/libwebm) | [GitHub mirror](https://github.com/webmproject/libwebm)
- [**zlib**](https://zlib.net/) | [primary repo](https://github.com/madler/zlib)

## Non-submodule libraries
In some cases, we use such a small fraction of a library that it isn't worth creating a submodule. This reduces download time but increases the difficulty of performing updates.

- [**PulseAudio**](http://pulseaudio.org/) | [primary repo](https://gitlab.freedesktop.org/pulseaudio/pulseaudio) | [GitHub mirror](https://github.com/pulseaudio/pulseaudio) | Reason: only used on Linux, and only a few headers are used.
