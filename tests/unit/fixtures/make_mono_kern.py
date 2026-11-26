"""Writes assets/mono-kern.ttf: assets/mono.ttf with a 'kern' table added.

FreeType's FT_Get_Kerning reads the 'kern' table, and neither bundled font has one, so text.FontTest
uses this copy for Font.decompose()'s kerning. The pairs are listed by character below. Besides
ordinary pairs, the table holds a pair of zero, which isn't kerning, and pairs with the .notdef
glyph, which no character maps to, so neither should be reported.

Run from tests/unit with any Python 3: python fixtures/make_mono_kern.py
"""

import struct

PAIRS = [
    ("A", "V", -120), ("V", "A", -110), ("A", "T", -90), ("T", "o", -75), ("L", "T", -140),
    ("P", ".", -160), ("Y", "a", -60), ("f", "f", 30), ("r", ",", -50), ("W", "e", -40),
    ("o", "x", 0), ("1", "1", -20), (" ", "A", -10), ("~", "!", 15),
]
NOTDEF_PAIRS = [(0, "A", -70), ("Z", 0, -30)]


def checksum(data):
    data += b"\0" * (-len(data) % 4)
    return sum(struct.unpack(">%dI" % (len(data) // 4), data)) & 0xFFFFFFFF


def read_cmap(font, tables):
    offset = tables["cmap"][0]
    count = struct.unpack(">H", font[offset + 2:offset + 4])[0]
    for i in range(count):
        platform, encoding, sub = struct.unpack(">HHI", font[offset + 4 + i * 8:offset + 12 + i * 8])
        start = offset + sub
        if struct.unpack(">H", font[start:start + 2])[0] != 4:
            continue
        segs = struct.unpack(">H", font[start + 6:start + 8])[0] // 2
        ends = struct.unpack(">%dH" % segs, font[start + 14:start + 14 + segs * 2])
        p = start + 16 + segs * 2
        starts = struct.unpack(">%dH" % segs, font[p:p + segs * 2])
        deltas = struct.unpack(">%dh" % segs, font[p + segs * 2:p + segs * 4])
        range_at = p + segs * 4
        ranges = struct.unpack(">%dH" % segs, font[range_at:range_at + segs * 2])
        result = {}
        for s in range(segs):
            for code in range(starts[s], ends[s] + 1):
                if code == 0xFFFF:
                    continue
                if ranges[s] == 0:
                    glyph = (code + deltas[s]) & 0xFFFF
                else:
                    at = range_at + s * 2 + ranges[s] + (code - starts[s]) * 2
                    glyph = struct.unpack(">H", font[at:at + 2])[0]
                    if glyph:
                        glyph = (glyph + deltas[s]) & 0xFFFF
                if glyph:
                    result[chr(code)] = glyph
        return result
    raise SystemExit("no format 4 cmap")


def main():
    font = open("assets/mono.ttf", "rb").read()
    count = struct.unpack(">H", font[4:6])[0]
    tables = {}
    for i in range(count):
        tag, check, offset, length = struct.unpack(">4sIII", font[12 + i * 16:28 + i * 16])
        tables[tag.decode()] = (offset, length)

    cmap = read_cmap(font, tables)
    glyph = lambda c: c if isinstance(c, int) else cmap[c]
    pairs = sorted(((glyph(l), glyph(r)), v) for l, r, v in PAIRS + NOTDEF_PAIRS)

    n = len(pairs)
    search = 1
    while search * 2 <= n:
        search *= 2
    selector = search.bit_length() - 1
    body = struct.pack(">HHHH", n, search * 6, selector, n * 6 - search * 6)
    for (left, right), value in pairs:
        body += struct.pack(">HHh", left, right, value)
    # Version 0, one subtable: version 0, its length, horizontal kerning in format 0
    kern = struct.pack(">HH", 0, 1) + struct.pack(">HHH", 0, 6 + len(body), 0x0001) + body

    data = {tag: font[o:o + l] for tag, (o, l) in tables.items()}
    data["kern"] = kern
    tags = sorted(data)
    head_offset = 12 + 16 * len(tags)
    out_tables = b""
    directory = b""
    for tag in tags:
        table = data[tag]
        if tag == "head":
            # checkSumAdjustment is worked out once the file is complete
            table = table[:8] + b"\0\0\0\0" + table[12:]
        directory += struct.pack(">4sIII", tag.encode(), checksum(table), head_offset + len(out_tables), len(table))
        out_tables += table + b"\0" * (-len(table) % 4)

    search = 1
    while search * 2 <= len(tags):
        search *= 2
    header = font[0:4] + struct.pack(">HHHH", len(tags), search * 16, search.bit_length() - 1, len(tags) * 16 - search * 16)
    result = bytearray(header + directory + out_tables)

    head_at = head_offset + sum(len(data[t]) + (-len(data[t]) % 4) for t in tags[:tags.index("head")])
    adjustment = (0xB1B0AFBA - checksum(bytes(result))) & 0xFFFFFFFF
    result[head_at + 8:head_at + 12] = struct.pack(">I", adjustment)
    open("assets/mono-kern.ttf", "wb").write(result)

    for (left, right), value in pairs:
        print(left, right, value)


main()
