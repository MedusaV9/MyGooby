#!/usr/bin/env python3
"""Draw the alternate Gooby app icons. Backgrounds match ThemeIconBadge in ThemePreviewArt.swift."""

import json
import struct
import zlib
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Gooby" / "Assets.xcassets"

# (asset name, top, bottom, outline or None). Kept in step with ThemeIconBadge.
ICONS = [
    ("AppIcon-Cream", (0xF8, 0xF1, 0xE6), (0xE3, 0xD6, 0xF3), None),
    ("AppIcon-Forest", (0xA8, 0xD0, 0x95), (0x4E, 0x8A, 0x4C), None),
    ("AppIcon-Sakura", (0xFF, 0xE6, 0xEE), (0xF2, 0xA7, 0xC1), None),
    ("AppIcon-Ocean", (0xC4, 0xE8, 0xF6), (0x3A, 0x93, 0xBA), None),
    ("AppIcon-Honey", (0xFF, 0xE9, 0xAE), (0xF0, 0xA4, 0x3A), None),
    ("AppIcon-Contrast", (0xFF, 0xD6, 0x0A), (0xFF, 0xC3, 0x00), (0x00, 0x00, 0x00)),
    ("AppIcon-Night", (0x2E, 0x3D, 0x6E), (0x17, 0x15, 0x2A), None),
    ("AppIcon-Firefly", (0x2A, 0x5A, 0x3B), (0x10, 0x1A, 0x14), None),
    ("AppIcon-ContrastDark", (0x1A, 0x1A, 0x1A), (0x00, 0x00, 0x00), (0xFF, 0xD6, 0x0A)),
]

FUR = np.array([255, 246, 234], dtype=np.float32)
EAR = np.array([255, 194, 214], dtype=np.float32)
EYE = np.array([58, 36, 22], dtype=np.float32)
CHEEK = np.array([255, 183, 204], dtype=np.float32)
NOSE = np.array([255, 155, 184], dtype=np.float32)
WHITE = np.array([255, 255, 255], dtype=np.float32)

CONTENTS = """{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""


def write_png(path, rgb):
    height, width, _ = rgb.shape
    raw = b"".join(b"\x00" + rgb[y].tobytes() for y in range(height))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def stamp(img, cx, cy, rx, ry, color):
    height, width, _ = img.shape
    y, x = np.ogrid[:height, :width]
    nx = (x - cx) / rx
    ny = (y - cy) / ry
    radius = np.sqrt(nx * nx + ny * ny)
    edge = 1.6 / min(rx, ry)
    mask = np.clip((1 - radius) / edge + 0.5, 0, 1).astype(np.float32)
    img[:] = img * (1 - mask[..., None]) + color * mask[..., None]


def bunny(img, outline):
    parts = [
        (512, 860, 320, 250),
        (392, 300, 100, 250),
        (632, 300, 100, 250),
        (512, 500, 280, 280),
    ]
    if outline is not None:
        rim = np.array(outline, dtype=np.float32)
        for cx, cy, rx, ry in parts:
            stamp(img, cx, cy, rx + 26, ry + 26, rim)
    stamp(img, 512, 860, 320, 250, FUR)
    stamp(img, 392, 300, 100, 250, FUR)
    stamp(img, 632, 300, 100, 250, FUR)
    stamp(img, 392, 320, 52, 160, EAR)
    stamp(img, 632, 320, 52, 160, EAR)
    stamp(img, 512, 500, 280, 280, FUR)
    stamp(img, 430, 510, 48, 52, EYE)
    stamp(img, 594, 510, 48, 52, EYE)
    stamp(img, 414, 494, 14, 16, WHITE)
    stamp(img, 578, 494, 14, 16, WHITE)
    stamp(img, 350, 590, 52, 34, CHEEK)
    stamp(img, 674, 590, 52, 34, CHEEK)
    stamp(img, 512, 590, 24, 18, NOSE)


def draw(top, bottom, outline):
    height = width = 1024
    column = np.linspace(0, 1, height, dtype=np.float32)[:, None]
    top = np.array(top, dtype=np.float32)
    bottom = np.array(bottom, dtype=np.float32)
    gradient = top * (1 - column) + bottom * column
    img = np.broadcast_to(gradient[:, None, :], (height, width, 3)).astype(np.float32).copy()
    bunny(img, outline)
    return np.clip(img, 0, 255).astype(np.uint8)


def main():
    images = []
    for name, top, bottom, outline in ICONS:
        folder = ASSETS / f"{name}.appiconset"
        folder.mkdir(parents=True, exist_ok=True)
        image = draw(top, bottom, outline)
        write_png(folder / "icon-1024.png", image)
        (folder / "Contents.json").write_text(CONTENTS, encoding="utf-8")
        images.append(image[96:928:4, 96:928:4])
        print(name, image.shape, int(image.min()), int(image.max()))
    gap = np.full((images[0].shape[0], 16, 3), 255, dtype=np.uint8)
    row = images[0]
    for image in images[1:]:
        row = np.concatenate([row, gap, image], axis=1)
    write_png(Path("/tmp/theme-icons.png"), row)
    json.dumps({"icons": [name for name, *_ in ICONS]})


if __name__ == "__main__":
    main()
