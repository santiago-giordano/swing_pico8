#!/usr/bin/env python3
"""Builds the itch.io kit under itch/: cover (630x500), banner (1920x480) and
screenshots, all from the English carts. Captures them with the test rig
(bash tests/setup.sh) the same way tools/media.py does; needs Pillow and the
DejaVu fonts."""
import os, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import media as M

OUT = os.path.join(ROOT, "itch")
CARTS = ("swing_beats", "swing_keys", "swing_noise", "swing_mix")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
BG, FG, ACC, DIM = (18, 24, 44), (255, 236, 215), (255, 119, 168), (131, 118, 156)
BOX = {"swing_beats": (255, 157, 129), "swing_keys": (255, 119, 168),
       "swing_noise": (41, 98, 196), "swing_mix": (0, 190, 80)}
TITLE = "SWING LOFI"
# PICO-8 font, 3x5, taken from the carts' own header text
GLYPHS = {
    "S": (".##", "#..", "###", "..#", "##."),
    "W": ("#.#", "#.#", "#.#", "###", "###"),
    "I": ("###", ".#.", ".#.", ".#.", "###"),
    "N": ("##.", "#.#", "#.#", "#.#", "#.#"),
    "G": (".##", "#..", "#..", "#.#", "###"),
    "L": ("#..", "#..", "#..", "#..", "###"),
    "O": (".##", "#.#", "#.#", "#.#", "##."),
    "F": ("###", "#..", "##.", "#..", "#.."),
    " ": ("...",) * 5,
}


def frames():
    """screen of each cart while playing (English), 128x128"""
    b = None
    shots = {}
    for c in CARTS:
        f = os.path.join(M.WORK, "en", c, f"f{M.FPS * 4:04d}.png")
        if not os.path.exists(f):
            b = b or M.song()
            M.capture(c, b, "en")
        shots[c] = Image.open(f).convert("RGB").resize((128, 128), Image.NEAREST)
    return shots


def pixtitle(d, cx, y, px):
    """draws TITLE in the PICO-8 font, centred on cx, px screen pixels per font pixel"""
    w = (len(TITLE) * 4 - 1) * px
    x0 = cx - w // 2
    for i, ch in enumerate(TITLE):
        for r, row in enumerate(GLYPHS[ch]):
            for c, v in enumerate(row):
                if v == "#":
                    x = x0 + (i * 4 + c) * px
                    d.rectangle((x, y + r * px, x + px - 1, y + (r + 1) * px - 1), fill=FG)


def cover(shots):
    W, H = 630, 500
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    fs, fl = ImageFont.truetype(FONT, 18), ImageFont.truetype(FONT, 17)
    pixtitle(d, W // 2, 30, 8)
    d.text((W // 2, 96), "lofi beats with J Dilla swing", font=fs, fill=ACC, anchor="mm")
    sz, gap = 140, 14
    x0 = (W - 4 * sz - 3 * gap) // 2
    for i, c in enumerate(CARTS):
        x = x0 + i * (sz + gap)
        d.rectangle((x - 2, 148, x + sz + 1, 150 + sz + 1), fill=DIM)
        im.paste(shots[c].resize((sz, sz), Image.LANCZOS), (x, 150))
        d.text((x + sz // 2, 150 + sz + 30), c.replace("swing_", "").upper(), font=fl, fill=FG, anchor="mm")
    d.text((W // 2, 420), "drums · keys · noise  —  stems for your DAW  +  mix", font=fl, fill=DIM, anchor="mm")
    d.text((W // 2, 448), "for PICO-8", font=fl, fill=DIM, anchor="mm")
    im.save(os.path.join(OUT, "cover.png"))


def banner():
    W, H = 1920, 480
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    # dithered bands top and bottom, like the carts' header
    for y in list(range(0, 32)) + list(range(H - 32, H)):
        for x in range(y % 4 // 2 * 2, W, 4):
            d.rectangle((x, y, x + 1, y), fill=(45, 26, 44))
    d.rectangle((0, 32, W, 35), fill=DIM)
    d.rectangle((0, H - 36, W, H - 33), fill=DIM)
    pixtitle(d, W // 2, 110, 20)
    d.text((W // 2, 287), "lofi beats with J Dilla swing", font=ImageFont.truetype(FONT, 50), fill=ACC, anchor="mm")
    fb = ImageFont.truetype(FONT, 36)
    labels = [c.replace("swing_", "").upper() for c in CARTS]
    widths = [d.textlength(t, font=fb) + 60 for t in labels]
    gap = 70
    x = (W - sum(widths) - gap * (len(labels) - 1)) // 2
    for c, t, w in zip(CARTS, labels, widths):
        d.rectangle((x, 342, x + w, 406), outline=BOX[c], width=4)
        d.text((x + w / 2, 374), t, font=fb, fill=FG, anchor="mm")
        x += w + gap
    im.save(os.path.join(OUT, "banner.png"))


def screenshots(shots):
    os.makedirs(os.path.join(OUT, "screenshots"), exist_ok=True)
    for c in CARTS:
        shots[c].resize((768, 768), Image.NEAREST).save(os.path.join(OUT, "screenshots", f"{c}.png"))
    Image.open(os.path.join(ROOT, "docs", "pages_en.png")).save(os.path.join(OUT, "screenshots", "all_pages.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    s = frames()
    cover(s)
    banner()
    screenshots(s)
    print("itch kit ok ->", OUT)
