# Variable font fixture

`variable.ttf` is a small subset of the Inter variable font, renamed **Lime Variable Test**.
It retains the original `wght` axis (100–900) and `opsz` axis (14–32) and contains space,
H and digits. The corresponding SIL Open Font License is in `variable-OFL.txt`; the
font's original copyright and license metadata are retained in its name table.

The source is Inter by the Inter Project Authors: https://github.com/rsms/inter.
The subset was made with FontTools' Subsetter, keeping all name records and the characters
` H0123456789`. Family/full/PostScript/typographic names were changed to Lime Variable Test.
FontTools is needed only to regenerate the fixture, not to run tests or CI.

`text.FontTest` loads this bundled fixture with the normal unit-test project. Tests compare
glyph coverage against another rendering on the same runner rather than hard-coded pixel
hashes. They exercise weight changes and resets, independent native faces, optical-size
preservation, bounds clamping, unsupported axes/static fonts, invalid requests and byte loading.
The tests run wherever the existing unit suite enables `lime_cffi` (C++, Neko and HashLink).
