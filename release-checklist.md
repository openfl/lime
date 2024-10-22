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
			# tested on macOS, but not other platforms
			zip -r path/to/new/lime-haxelib.zip . -9
			```
- Create new release for tag on GitHub
	- Upload _lime-haxelib.zip_ and _lime-docs.zip_
	- Link to _CHANGELOG.md_ from tag and to _https://community.openfl.org_ announcement thread)
		- _CHANGELOG.md_ tag URL: `https://github.com/openfl/lime/blob/x.y.z/CHANGELOG.md`
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