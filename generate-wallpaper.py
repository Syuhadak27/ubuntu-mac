#!/usr/bin/env python3
"""
generate-wallpaper.py — Build free, macOS Sequoia-inspired gradient wallpapers.

Generates two wallpapers (light + dark) entirely from code, so no third-party
or proprietary artwork is involved. Everything is smooth gradients and soft
light blobs, which is exactly what glass/frosted surfaces blur best.

Output: ~/Pictures/Wallpapers/Sequoia-light.jpg, Sequoia-dark.jpg (1920x1080)
"""
import math
import os
from PIL import Image, ImageFilter

W, H = 1920, 1080
OUT_DIR = os.path.expanduser("~/Pictures/Wallpapers")
os.makedirs(OUT_DIR, exist_ok=True)

# --- palettes ---------------------------------------------------------------
# (r, g, b) stop colours, left/top -> right/bottom
LIGHT = [
    ( 36,  64, 143),   # deep ocean blue (top-left)
    ( 58, 110, 216),   # vivid mac blue
    (110, 141, 235),   # periwinkle
    (158, 133, 233),   # soft violet
    (206, 168, 240),   # lilac highlight (bottom-right)
]
DARK = [
    ( 10,  14,  38),   # near-black indigo
    ( 22,  32,  84),   # deep navy
    ( 36,  54, 130),   # royal blue
    ( 66,  56, 148),   # violet
    (104,  74, 170),   # muted purple glow
]
# soft light blobs: (x, y, radius, colour, strength) in normalised coords
LIGHT_BLOBS = [
    (0.18, 0.20, 0.55, (150, 190, 255), 0.55),
    (0.82, 0.78, 0.60, (232, 205, 255), 0.45),
    (0.55, 0.45, 0.45, (120, 160, 250), 0.35),
]
DARK_BLOBS = [
    (0.20, 0.25, 0.55, ( 48,  78, 170), 0.55),
    (0.80, 0.75, 0.60, (110,  70, 180), 0.50),
    (0.50, 0.55, 0.40, ( 30,  44, 120), 0.45),
]


def lerp(a, b, t):
    return a + (b - a) * t


def sample(stops, t):
    """Sample a multi-stop gradient at t in [0,1]."""
    t = max(0.0, min(1.0, t))
    n = len(stops) - 1
    seg = t * n
    i = min(int(seg), n - 1)
    f = seg - i
    c0, c1 = stops[i], stops[i + 1]
    # smoothstep for an even silkier falloff
    f = f * f * (3 - 2 * f)
    return tuple(lerp(c0[k], c1[k], f) for k in range(3))


def build(stops, blobs, name, wave=0.0):
    # Render at low resolution, then upscale with bicubic — cheap and perfectly
    # smooth (no banding), which matters a lot on an Intel HD 520.
    lw, lh = 96, 54
    img = Image.new("RGB", (lw, lh))
    px = img.load()

    for y in range(lh):
        for x in range(lw):
            u = x / (lw - 1)
            v = y / (lh - 1)
            # diagonal gradient with a gentle sine "wave" like macOS wallpapers
            t = 0.62 * u + 0.38 * v + wave * math.sin(u * math.pi) * 0.12
            r, g, b = sample(stops, t)

            # soft radial highlights
            for bx, by, br, bc, strength in blobs:
                d = math.hypot((u - bx) * 1.0, (v - by) * 0.62)
                if d < br:
                    k = (1.0 - d / br) ** 2 * strength
                    r = lerp(r, bc[0], k)
                    g = lerp(g, bc[1], k)
                    b = lerp(b, bc[2], k)

            px[x, y] = (int(max(0, min(255, r))),
                        int(max(0, min(255, g))),
                        int(max(0, min(255, b))))

    img = img.resize((W, H), Image.BICUBIC)
    img = img.filter(ImageFilter.GaussianBlur(1.2))

    # very light film grain prevents gradient banding on 6/8-bit panels
    grain = Image.effect_noise((W, H), 6).convert("L")
    img = Image.blend(img, Image.merge("RGB", (grain, grain, grain)), 0.012)

    path = os.path.join(OUT_DIR, name)
    img.save(path, quality=92, optimize=True)
    print(f"wrote {path} ({os.path.getsize(path) // 1024} KiB)")


build(LIGHT, LIGHT_BLOBS, "Sequoia-light.jpg", wave=0.10)
build(DARK, DARK_BLOBS, "Sequoia-dark.jpg", wave=0.10)
