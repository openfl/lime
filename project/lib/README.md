Submodule projects
==================

Lime's native target uses code from several C/C++ projects, each of which is treated as a [submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules).

Where possible, Lime prefers to use GitHub repositories as submodules, as this makes browsing easier. (GitHub refuses to link to non-GitHub repos.) However, several of these repositories are mirrored from elsewhere, and will ignore issues and pull requests submitted on GitHub.

**Always submit issues and pull requests to the primary repo, not to a GitHub mirror.**

Cairo: [homepage](https://www.cairographics.org/) | [primary repo](https://gitlab.freedesktop.org/cairo/cairo) | [GitHub mirror](https://github.com/freedesktop/cairo)

cURL: [homepage](https://curl.se/) | [primary repo](https://github.com/curl/curl)

efsw: [primary repo](https://github.com/SpartanJ/efsw)

FreeType: [homepage](https://freetype.org/) | [primary repo](https://gitlab.freedesktop.org/freetype/freetype) | [GitHub mirror](https://github.com/freetype/freetype)

HarfBuzz: [homepage](https://harfbuzz.github.io/) | [primary repo](https://github.com/harfbuzz/harfbuzz)

libjpeg: [homepage](https://ijg.org/) | [download](https://ijg.org/files/) | [unofficial GitHub mirror](https://github.com/openfl/libjpeg)

LZMA: [homepage + download](https://www.7-zip.org/sdk.html) | [unofficial GitHub mirror](https://github.com/openfl/liblzma)

mbed TLS: [homepage](https://tls.mbed.org/) | [primary repo](https://github.com/Mbed-TLS/mbedtls)

MojoAL: [homepage](https://icculus.org/mojoAL/) | [primary repo](https://github.com/icculus/mojoAL/)

Neko: [homepage](https://nekovm.org/) | [primary repo](https://github.com/HaxeFoundation/neko)

Ogg: [homepage](https://www.xiph.org/ogg/) | [primary repo](https://github.com/xiph/ogg)

OpenAL soft: [homepage](https://openal-soft.org/) | [primary repo](https://github.com/kcat/openal-soft)

Pixman: [homepage](http://pixman.org/) | [primary repo](https://gitlab.freedesktop.org/pixman/pixman) | [GitHub mirror](https://github.com/freedesktop/pixman)

libpng: [homepage](http://www.libpng.org/pub/png/libpng.html) | [primary repo](https://sourceforge.net/p/libpng/code)

SDL: [homepage](https://www.libsdl.org/) | [primary repo](https://github.com/libsdl-org/SDL)

tiny file dialogs: [homepage](https://sourceforge.net/projects/tinyfiledialogs/) | [primary repo](https://sourceforge.net/p/tinyfiledialogs/code)

Vorbis: [homepage](https://www.xiph.org/vorbis/) | [primary repo](https://github.com/xiph/vorbis)

libvpx: [homepage](https://www.webmproject.org/tools/) | [primary repo](https://chromium.googlesource.com/webm/libvpx/) | [GitHub mirror](https://github.com/webmproject/libvpx/)

libwebm: [homepage](https://www.webmproject.org/about/) | [primary repo](https://chromium.googlesource.com/webm/libwebm) | [GitHub mirror](https://github.com/webmproject/libwebm)

zlib: [homepage](https://zlib.net/) | [primary repo](https://github.com/madler/zlib)

Shallow submodules
------------------
To save space, submodules use "shallow" mode, meaning you'll only download the single commit that you're using.

To download a submodule's entire commit history, use `git fetch --unshallow`, but be warned that the download may take a while. For instance, cURL has over 20,000 commits.

Overrides
---------

The overrides folder contains a number of customized headers and source files, to be used instead of the equivalent file(s) in the submodule. (Or in addition to: some submodules intentionally omit files, expecting the user to generate them.)

All cases require updating the corresponding files.xml file. Since some projects refer to others, you may need to update multiple different files.xml files, and/or [Lime's primary Build.xml file](https://github.com/openfl/lime/blob/develop/project/Build.xml).

- To add or override a header, include the overrides folder first (if not already included).

   ```diff
   +<compilerflag value="-I${NATIVE_TOOLKIT_PATH}/overrides/sdl/include/" />
   <compilerflag value="-I${NATIVE_TOOLKIT_PATH}/sdl/include/" />
   ```

- To add a source file, insert a `<file />` tag.

   ```diff
   +<file name="${NATIVE_TOOLKIT_PATH}/overrides/sdl/src/SDL_extra.c" />
   ```

- To override a source file, replace the `<file />` tag.

   ```diff
   -<file name="${NATIVE_TOOLKIT_PATH}/sdl/src/SDL_log.c" />
   +<file name="${NATIVE_TOOLKIT_PATH}/overrides/sdl/src/SDL_log.c" />
   ```
