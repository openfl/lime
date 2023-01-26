# C++ backend project
Lime uses this C/C++ code to build reusable binaries for native targets, stored in the [ndll directory](https://github.com/openfl/lime/tree/develop/ndll). Binaries for common targets are included in the Haxelib download, so you won't need to build those yourself unless you make changes.

Tip: if you install Lime from Git, you can still copy the ndlls from Lime's latest Haxelib release.

## Project overview
This directory contains two categories of code.

- Lime-specific headers and source files can be found under [include](include) and [src](src), respectively. [`ExternalInterface`](src/ExternalInterface.cpp) serves as the entry point into this code.
- [Submodules](#submodule-projects) such as Cairo, SDL, and OpenAL can be found under [lib](lib).

### Prerequisites

- All platforms require [hxcpp](https://lib.haxe.org/p/hxcpp/).
- Windows requires [Visual Studio C++ components](https://visualstudio.microsoft.com/vs/features/cplusplus/).
- Mac requires [Xcode](https://developer.apple.com/xcode/).
- Linux requires several packages (names may vary per distro).

   ```bash
   sudo apt install libgl1-mesa-dev libglu1-mesa-dev g++ g++-multilib gcc-multilib libasound2-dev libx11-dev libxext-dev libxi-dev libxrandr-dev libxinerama-dev libpulse-dev
   ```

### Rebuilding
Use `lime rebuild <target>` to build or rebuild a set of binaries. Once finished, you can find them in the [ndll directory](https://github.com/openfl/lime/tree/develop/ndll).

```bash
lime rebuild windows #Recompile the Windows binary (lime.ndll).
lime rebuild android -clean #Compile the Android binaries (liblime-##.so) from scratch, even if no changes are detected.
lime rebuild mac -64 #Recompile only the x86-64 binary (lime.ndll) for Mac.
lime rebuild hl #Recompile the HashLink binaries (lime.hdll and others).
```

See `lime help rebuild` for details and additional options.

> Note: even without an explicit `rebuild` command, running `lime` will automatically build lime.ndll for your machine. Even if you never target C++ or Neko, this binary will help with small tasks such as rendering icons.

### Build troubleshooting
If errors appeared after updating Lime, the update process may not be complete. Run these commands:

```bash
git submodule update --init
lime rebuild tools
```

For errors that appeared after changing a source file, you may need to update the build configuration.

- Errors in the [src](src) and [include](include) directories usually require updating [Build.xml](Build.xml).
- Errors in the [lib](lib) directory usually require updating that submodule's xml file. So for instance, if the error message points to lib/cairo/src/cairo.c, you most likely need to edit [cairo-files.xml](lib/cairo-files.xml). If the error message points to lib/hashlink/src/main.c, look at [BuildHashlink.xml](BuildHashlink.xml). (Though libraries do reference one another sometimes, so this isn't a hard rule.)

Common errors and their solutions:

- `[header].h: No such file or directory`: Include the header if it exists. If not, run `git status` to confirm that your submodules are up to date.

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

See also [submodule troubleshooting](#submodule-troubleshooting).

## Submodule projects
Lime includes code from several other C/C++ libraries, each of which is treated as a [submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules). For more information on the individual libraries, see [lib/README.md](lib/README.md).

### Custom headers and source files
All submodules are used as-is, meaning Lime never modifies the contents of the submodule folder. When Lime needs to modify or add a file, the file goes in [lib/custom](lib/custom).

Caution: overriding a file requires extra maintenance. Always try to find a different solution first. lib/custom should contain as few files as possible.

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
Here are some submodule-specific problems you might run into while rebuilding.

- The project is missing a crucial header file, or has `[header].h.in` instead of the header you need:

   1. Look for an `autogen.sh` file. If it exists, run it. (On Windows, you may need [WSL](https://docs.microsoft.com/en-us/windows/wsl/about), or you might be able to find a .bat file that does what you need.)
   2. If step 1 fails, look for instructions on how to configure the project. This will often involving using `make`, `cmake`, and/or `./configure`. (Again, Windows users may need WSL.)
   3. One of the above steps should hopefully generate the missing header. Place the generated file inside [the custom folder](#custom-headers-and-source-files).

- The compiler uses the submodule's original header instead of Lime's custom header:

   1. Make sure the custom folder is included first.

      ```xml
      <compilerflag value="-I${NATIVE_TOOLKIT_PATH}/custom/cairo/src/" />
      <compilerflag value="-I${NATIVE_TOOLKIT_PATH}/cairo/src/" />
      ```

   2. If the header is in the same directory as the corresponding source files, you cannot override it. Try setting compiler flags to get the result you want, or look for a different file to override.

      ```xml
      <compilerflag value="-DDISABLE_FEATURE" />
      <compilerflag value="-DENABLE_OTHER_FEATURE" />
      ```

   3. Approach the problem from a different angle. Upgrade or downgrade the submodule, or open an issue.
