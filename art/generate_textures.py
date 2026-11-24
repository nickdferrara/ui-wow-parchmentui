#!/usr/bin/env python3
"""Generates the placeholder textures in ParchmentUI/Art.

Every texture is drawn from scratch by the code below, so the artwork is original to this
project. Textures are near-white with an alpha channel: the addon tints them with the theme's
colors, which lets one file serve both the light and the dark theme.

Output is deterministic. Run from the repository root:

    python3 art/generate_textures.py
"""

import math
import os
import random
import struct

OUTPUT_DIR = os.path.join("ParchmentUI", "Art")
SEED = 16001


def clamp(value, low=0.0, high=1.0):
    return max(low, min(high, value))


def smoothstep(edge0, edge1, value):
    t = clamp((value - edge0) / (edge1 - edge0))
    return t * t * (3 - 2 * t)


class ValueNoise:
    """Tileable smooth noise on a lattice, so textures have no visible seam."""

    def __init__(self, rng, cells):
        self.cells = cells
        self.lattice = [[rng.random() for _ in range(cells)] for _ in range(cells)]

    def at(self, u, v):
        x, y = u * self.cells, v * self.cells
        x0, y0 = int(math.floor(x)), int(math.floor(y))
        fx, fy = x - x0, y - y0
        fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
        n = self.cells

        def cell(cx, cy):
            return self.lattice[cy % n][cx % n]

        top = cell(x0, y0) * (1 - fx) + cell(x0 + 1, y0) * fx
        bottom = cell(x0, y0 + 1) * (1 - fx) + cell(x0 + 1, y0 + 1) * fx
        return top * (1 - fy) + bottom * fy


def write_tga(name, width, height, pixel):
    """Writes a 32-bit uncompressed TGA. pixel(x, y) returns (luminance, alpha) in 0..1."""
    # Rows are stored bottom-up with 8 alpha bits, the layout image editors write by default
    # and the one most widely read.
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, width, height, 32, 0x08)
    rows = bytearray()
    for y in range(height - 1, -1, -1):
        for x in range(width):
            luminance, alpha = pixel(x, y)
            value = int(round(clamp(luminance) * 255))
            rows += bytes((value, value, value, int(round(clamp(alpha) * 255))))
    path = os.path.join(OUTPUT_DIR, name)
    with open(path, "wb") as handle:
        handle.write(header)
        handle.write(rows)
    print("wrote", path, f"{width}x{height}")


def scroll_surface(rng):
    """The parchment sheet: paper grain, darker torn side edges, straight top and bottom."""
    size = 256
    coarse, fine = ValueNoise(rng, 6), ValueNoise(rng, 48)
    tear = ValueNoise(rng, 10)

    def pixel(x, y):
        u, v = x / size, y / size
        inset = 3 + 5 * tear.at(0.25, v) if x < size / 2 else 3 + 5 * tear.at(0.75, v)
        distance = x if x < size / 2 else size - 1 - x
        alpha = smoothstep(inset - 1.5, inset + 1.5, distance)
        grain = 0.07 * coarse.at(u, v) + 0.05 * fine.at(u, v)
        edge_shade = 0.16 * (1 - smoothstep(inset, inset + 26, distance))
        return 1.0 - grain - edge_shade, alpha

    write_tga("ScrollSurface.tga", size, size, pixel)


def scroll_roll(rng):
    """The rolled end of the scroll: a shaded cylinder with a soft shadow underneath."""
    width, height = 256, 32
    streaks = ValueNoise(rng, 32)
    body = 24

    def pixel(x, y):
        if y < body:
            angle = math.pi * (y + 0.5) / body
            shade = 0.50 + 0.50 * math.sin(angle) ** 0.8
            highlight = 0.10 * math.exp(-((y - body * 0.32) ** 2) / 6.0)
            grain = 0.05 * streaks.at(x / width, 0.5)
            cap = min(x, width - 1 - x)
            return shade + highlight - grain, smoothstep(0, 2.5, cap)
        fade = 1 - (y - body) / (height - body)
        return 0.0, 0.35 * fade * fade

    write_tga("ScrollRoll.tga", width, height, pixel)


def divider(_rng):
    """A thin ink rule that fades out at both ends."""
    width, height = 256, 8

    def pixel(x, y):
        across = math.sin(math.pi * (x + 0.5) / width) ** 0.6
        down = math.exp(-(((y + 0.5) - height / 2) ** 2) / 1.6)
        return 1.0, across * down

    write_tga("Divider.tga", width, height, pixel)


def button_outline(rng):
    """An ink-outlined rounded rectangle with a faint wash inside, for nine-slice buttons."""
    size, radius, line = 64, 10, 1.6
    wobble = ValueNoise(rng, 8)

    def pixel(x, y):
        half = size / 2 - 3
        px, py = abs(x + 0.5 - size / 2), abs(y + 0.5 - size / 2)
        qx, qy = max(px - (half - radius), 0), max(py - (half - radius), 0)
        outside = math.hypot(qx, qy) - radius
        inside = min(max(px - (half - radius), py - (half - radius)), 0)
        distance = outside + inside + 1.2 * (wobble.at(x / size, y / size) - 0.5)
        stroke = 1 - smoothstep(line - 0.8, line + 0.8, abs(distance))
        wash = 0.10 * (1 - smoothstep(-1, 1, distance))
        return 1.0, max(stroke * 0.9, wash)

    write_tga("ButtonOutline.tga", size, size, pixel)


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    rng = random.Random(SEED)
    for draw in (scroll_surface, scroll_roll, divider, button_outline):
        draw(rng)


if __name__ == "__main__":
    main()
