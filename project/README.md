# C++ backend project
Lime uses this C/C++ code to build its ndlls (shared object files) for native targets. Each target requires its own set of ndlls. Ndlls for common targets are included in the Haxelib download (stored in the [ndll directory](https://github.com/openfl/lime/tree/develop/ndll)), so you won't need to build those yourself unless you modify this directory's contents.

Tip: if you install Lime from Git, you can still copy the ndlls from Lime's latest Haxelib release.

## Project overview
The backend project consists of two categories of code: Lime-specific code, and [included libraries](#submodule-projects) such as Cairo, SDL, and OpenAL.

Lime-specific headers and source files can be found under [include](include) and [src](src), respectively. Of particular note is [`ExternalInterface`](src/ExternalInterface.cpp), as that exposes functions for use by [`NativeCFFI`](https://github.com/openfl/lime/blob/develop/src/lime/_internal/backend/native/NativeCFFI.hx).

Lime invokes hxcpp to compile the code, passing [Build.xml](Build.xml) so that it knows which sources and headers to include. Build.xml recursively includes all the xml files inside [lib](lib), each of which contains instructions to build one of the included libraries.

### Rebuilding
Run `lime rebuild <target>` to perform an incremental rebuild, or add `-clean` to force it to build from scratch.

Possible targets:

- `windows`
- `mac` / `macos`
- `linux`
- `cpp` (special case: maps to `windows`, `mac`, or `linux`, depending on your machine)
- `android`
- `ios` / `iphone` / `iphoneos`
- `rpi` / `raspberrypi`
- `neko`
- `hl` / `hashlink`
- All other strings in [`Platform`](https://github.com/openfl/lime/blob/develop/src/lime/tools/Platform.hx)
- All other cases listed in [`CommandLineTools`](https://github.com/openfl/lime/blob/50488aee5353c2918b7a00bbe2930c5cf51fe1c9/tools/CommandLineTools.hx#L233-L292)

### Build troubleshooting
Most build errors can be fixed by updating the correct xml file. If the error happened inside [src](src), you can fix it by editing [Build.xml](Build.xml). Whereas if it happened in an included library, you'll want to [find that library's xml file](lib).

Common problems and their solutions:

- `[header].h: No such file or directory`: Include the header.

   ```xml
   <compilerflag value="-Iinclude/path/to/header/" />
   <compilerflag value="-I${NATIVE_TOOLKIT_PATH}/path/to/another/header/" />
   ```

- `undefined reference to [symbol]`: Locate the source file that defines the symbol, then add it.

   ```xml
   <file name="src/path/to/file.cpp"/>
   <file name="${NATIVE_TOOLKIT_PATH}/path/to/anotherfile.c"/>
   ```

- `'std::istringstream' has no member named 'swap'`: Your Android NDK is out of date; switch to version 20 or higher. (Version 21 recommended.)

- Another problem related to an included library: see [submodule troubleshooting](#submodule-troubleshooting).

## Submodule projects
Lime includes code from several other C/C++ libraries, each of which is treated as a [submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules). For more details about the libraries, see [lib/README.md](lib/README.md).

### Overrides
The [overrides folder](lib/overrides) contains a number of customized headers and source files, to be used instead of the equivalent file(s) in the submodule.

Caution: overridden files require extra maintenance. Avoid overriding if possible, and instead use `-D` flags to make the customizations you need.

When overriding a header, always include the overrides folder first.

```xml
<compilerflag value="-I${NATIVE_TOOLKIT_PATH}/overrides/sdl/include/" />
<compilerflag value="-I${NATIVE_TOOLKIT_PATH}/sdl/include/" />
```

### Updating a submodule
Submodules are Git repositories in their own right, and are typically kept in "detached HEAD" state. Lime never modifies its submodules directly, but instead changes which commit the HEAD points to.

To update to a more recent version of a submodule:

1. Open the project's primary repo or GitHub mirror.
2. Browse the tags until you find the version you wish to update to. (Or browse commits, but that's discouraged.)
3. Copy the commit ID for your chosen version.
4. Open your local submodule folder on the command line. (From here, any `git` commands will affect the submodule instead of Lime.)
5. Update the library:

   ```bash
   $ git checkout [commit ID]
   Previous HEAD position was [old commit ID] [old commit message]
   HEAD is now at [commit ID] [commit message]
   ```

   If you get a "reference is not a tree" error, run `git fetch --unshallow`, then try again. (Lime downloads submodules in "shallow" mode to save time and space, and not all commits are fetched until you explicitly fetch them.)
6. If you exit the submodule and run `git status`, you'll find an unstaged change representing the update. Once you [finish testing](#rebuilding), you can commit this change and submit it as a pull request.

### Submodule troubleshooting
Here are some problems you might run into while attempting to build these submodules, and their solutions.

- All submodules are empty:

   ```bash
   git submodule init
   git submodule update
   ```

- The project is missing a crucial header file, or has `[header].h.in` instead of the header you need:

   1. Look for an `autogen.sh` file. If it exists, run it. (On Windows, you may need [WSL](https://docs.microsoft.com/en-us/windows/wsl/about), or you might be able to find a .bat file that does what you need.)
   2. If step 1 fails, look for instructions on how to configure the project. This will often involving using `make`, `cmake`, and/or `./configure`. (Again, Windows users may need WSL.)
   3. One of the above steps should hopefully generate the missing header. Place the generated file inside [the overrides folder](#overrides).

- You've attempted to override a header, but it still uses the original:

   1. Double-check your xml files to ensure the override folder is included first. (Search more than one xml file, as libraries can include each other's headers.)
   2. If a source file includes a header in its own directory, you can't override that header. (At least, not without overriding the source file too.) Instead, try setting compiler flags to make the changes you need.
