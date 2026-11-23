# Tools tests

Tests for how the command-line tools read project files: `ProjectXMLParser`, `HXProject`,
`ConfigData`, assets and the other types in `src/lime/tools`. Their expectations come from
[the XML format documentation](https://lime.openfl.org/docs/project-files/xml-format/), its
[config options](https://lime.openfl.org/docs/project-files/xml-format/config/), doc comments
and the changelog, rather than from what the parser does now.

They build against this checkout's `src` and run as a plain Neko program. Nothing needs
`lime setup`, a native library, an SDK or a display. Each test writes its project files to a
new folder in the system's temporary directory and reads them from there, as `lime` does.
Haxelibs are folders given to `Haxelib.pathOverrides`, so the `haxelib` command never runs.

## Running

With `format`, `hxp` and `utest` installed:

```
cd tests/tools
haxe test.hxml
```

This builds `bin/tools-tests.n` and runs it. Run it again with `neko bin/tools-tests.n`. The
exit code is 0 when every test passes.

The tools exit on an error (`Log.error()` calls `Sys.exit(1)`), so a test that reaches one
ends the run. Each test's name is printed as it starts, so the last name shows which one.

## Writing tests

`Fixture` holds a project folder. Set its `target`, `targetFlags`, `command` or `defines`
(as given with `-D` on the command line), then `parse()` a project file. Fixture XML is
written in single-quoted strings, where `$$` is a literal `$`, so `$${meta.title}` reaches
the parser as `${meta.title}`.
