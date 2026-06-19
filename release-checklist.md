# Lime Release Checklist

- Add release notes to _CHANGELOG.md_
	- Compare to previous tag on GitHub:
		`https://github.com/openfl/lime/compare/a.b.c...develop`
	- Compare to previous tag in terminal:
		```sh
		git log a.b.c...develop --oneline
		```
	- Sometimes, commits from previous releases show up, but most should be correct
- Update release note in _haxelib.json_
- Update version in _haxelib.json_ (may be updated already)
- Update release date in _CHANGELOG.md_
- For Lime 9.0.0 native desktop releases, verify the SDL3 migration gates before uploading final artifacts:
	- GitHub Actions rebuilt Windows, Linux, and macOS with SDL3 as the default backend
	- Explicit SDL2 fallback rebuilds passed with `-Dlime-sdl2` and the equivalent `-DLIME_SDL2` define
	- Direct desktop rebuilds with `-DLIME_SDL` fail with guidance to use the documented SDL2 fallback defines
	- Default SDL3 rebuilds include `-DSDL_DISABLE_OLD_NAMES` so SDL2 compatibility names cannot hide in the SDL3 backend
	- Default desktop HXML does not define the SDL2-only `lime_sdl_sound` bridge, while SDL2 fallback HXML still does
	- Mixed SDL2/SDL3 rebuilds fail instead of producing a native binary
	- No `sdl2-compat` reference appears in Lime build files, backend sources, or runtime dependency lists except documentation saying it is unsupported
- Smoke test the Lime 9.0.0 SDL3 desktop backend before release:
	- Window create, show, hide, resize, fullscreen, scale, and display refresh handling
	- OpenGL context create/swap and Vulkan surface creation where Vulkan is available
	- Keyboard events, text input/editing, mouse motion/buttons/wheel, relative mouse mode, and drag/drop file and text events
	- Gamepad/joystick connect, disconnect, axis, button, hat, name/GUID lookup, and rumble where hardware is available
	- Audio output path through the current Lime audio stack
- Tag release and push
	```sh
	git tag -s x.y.z -m "version x.y.z"
	git push origin x.y.z
	```
- Download _lime-haxelib_ and _lime-docs_ artifacts for tag from GitHub Actions
- Submit _.zip_ file to Haxelib with following command:
	```sh
	haxelib submit lime-haxelib.zip
	```
	- Lime releases are sometimes too large for Haxelib. If required, unzip and rezip with higher compresssion
		- First, unzip _lime-haxelib.zip_
		- Then, zip with highest compresssion (command for macOS terminal below):
			```sh
			cd lime-haxelib/
			zip -r path/to/new/lime-haxelib.zip . -9
			```
- Create new release for tag on GitHub
	- Upload _lime-haxelib.zip_ and _lime-docs.zip_
	- Link to _CHANGELOG.md_ from tag and to _https://community.openfl.org_ announcement thread)
		- _CHANGELOG.md_ tag URL format: `https://github.com/openfl/lime/blob/x.y.z/CHANGELOG.md`
		- It's okay to skip link to announcement at first, and edit the release to add it later
- Deploy API reference by updating Git ref in _.github/workflows/deploy.yml_ in _openfl/lime.openfl.org_ repo
	```yaml
    - uses: actions/checkout@v4
      with:
        repository: openfl/lime
        path: _lime-git
        ref: x.y.z
	```
- Make announcement on _https://community.openfl.org_ in _Announcements_ category
	- For feature releases, it's good to write a summary of noteworthy new features
	- For bugfix releases, intro can be short
	- Include full list of changes from _CHANGELOG.md_
	- If also releasing OpenFL at the same time, announcement thread should be combined
	- After posting, go back and add link to thread GitHub release description, if needed
