#!/usr/bin/env python3
"""Paint out the simulator's black Dynamic Island.

The reference video frames show the page colour where a 17 Pro draws a black
island. simctl saves that black into the framebuffer even with --mask=ignored,
so this rewrites the island pixels to the page colour sampled from the same row.
Only the wide black run in the centre of the top band is touched, so the clock
and the status icons stay.
"""

import os
import struct
import sys
import zlib


def read_png(path):
    data = open(path, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    pos = 8
    width = height = None
    color = None
    idat = []
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, bit, color, comp, filt, inter = struct.unpack(">IIBBBBB", chunk)
            if bit != 8 or inter != 0 or color not in (2, 6):
                raise SystemExit(f"unsupported png {path}: bit {bit} color {color} inter {inter}")
        elif kind == b"IDAT":
            idat.append(chunk)
        elif kind == b"IEND":
            break
    channels = 4 if color == 6 else 3
    raw = zlib.decompress(b"".join(idat))
    stride = width * channels
    rows = []
    i = 0
    prev = bytearray(stride)
    for _ in range(height):
        filt = raw[i]
        i += 1
        row = bytearray(raw[i:i + stride])
        i += stride
        if filt == 1:
            for x in range(channels, stride):
                row[x] = (row[x] + row[x - channels]) & 255
        elif filt == 2:
            for x in range(stride):
                row[x] = (row[x] + prev[x]) & 255
        elif filt == 3:
            for x in range(stride):
                left = row[x - channels] if x >= channels else 0
                row[x] = (row[x] + ((left + prev[x]) // 2)) & 255
        elif filt == 4:
            for x in range(stride):
                left = row[x - channels] if x >= channels else 0
                up = prev[x]
                ul = prev[x - channels] if x >= channels else 0
                row[x] = (row[x] + paeth(left, up, ul)) & 255
        elif filt != 0:
            raise SystemExit(f"bad filter {filt}")
        rows.append(row)
        prev = row
    return width, height, channels, rows


def paeth(left, up, ul):
    estimate = left + up - ul
    dl, du, dul = abs(estimate - left), abs(estimate - up), abs(estimate - ul)
    if dl <= du and dl <= dul:
        return left
    if du <= dul:
        return up
    return ul


def write_png(path, width, height, channels, rows):
    def chunk(kind, payload):
        return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)

    raw = bytearray()
    for row in rows:
        raw.append(0)
        raw.extend(row)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6 if channels == 4 else 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    open(path, "wb").write(png)


def punch(path):
    width, height, channels, rows = read_png(path)
    band = int(height * 0.075)
    x_lo, x_hi = int(width * 0.28), int(width * 0.72)
    sample_lo, sample_hi = int(width * 0.04), int(width * 0.14)
    changed = 0
    for y in range(band):
        row = rows[y]
        dark = []
        for x in range(x_lo, x_hi):
            i = x * channels
            if row[i] < 26 and row[i + 1] < 26 and row[i + 2] < 26:
                dark.append(x)
        if len(dark) < 40 or dark[-1] - dark[0] < width * 0.12:
            continue
        samples = [row[x * channels:x * channels + 3] for x in range(sample_lo, sample_hi)]
        samples.sort(key=lambda px: px[0] + px[1] + px[2])
        bg = samples[len(samples) // 2]
        for x in dark:
            i = x * channels
            row[i:i + 3] = bg
            changed += 1
    if changed:
        write_png(path, width, height, channels, rows)
    print(f"{os.path.basename(path)} island pixels {changed}")


# Shop, friends and the friends intro sheet show a dark status band in the
# reference, so a black island is closer there than the page colour.
SKIP = {"shop.png", "friends.png", "friends-intro.png"}


def main():
    folder = sys.argv[1]
    for name in sorted(os.listdir(folder)):
        if name.endswith(".png") and name not in SKIP:
            punch(os.path.join(folder, name))


if __name__ == "__main__":
    main()
