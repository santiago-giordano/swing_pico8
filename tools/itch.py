#!/usr/bin/env python3
"""Builds the itch.io kit under itch/: cover (630x500) and screenshots, from knulli/images.
Run tools/media.py first if the images changed."""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "knulli", "images")
OUT = os.path.join(ROOT, "itch")
CARTS = ("swing_beats", "swing_keys", "swing_noise")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
BG, FG, ACC, DIM = (18, 24, 44), (255, 236, 215), (255, 119, 168), (131, 118, 156)


def cover():
    W, H = 630, 500
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    ft = ImageFont.truetype(FONT, 46)
    fs = ImageFont.truetype(FONT, 17)
    d.text((W // 2, 52), "SWING PICO-8", font=ft, fill=FG, anchor="mm")
    d.text((W // 2, 94), "lofi beats with J Dilla swing", font=fs, fill=ACC, anchor="mm")
    sz, gap = 190, 15
    x0 = (W - 3 * sz - 2 * gap) // 2
    for i, c in enumerate(CARTS):
        s = Image.open(os.path.join(IMG, f"{c}-image.png")).convert("RGB").resize((sz, sz), Image.NEAREST)
        x = x0 + i * (sz + gap)
        d.rectangle((x - 3, 138, x + sz + 2, 138 + sz + 5), fill=DIM)
        im.paste(s, (x, 141))
        d.text((x + sz // 2, 141 + sz + 26), c.replace("swing_", "").upper(), font=fs, fill=FG, anchor="mm")
    d.text((W // 2, 455), "drums · keys · noise  —  stems for your DAW", font=fs, fill=DIM, anchor="mm")
    d.text((W // 2, 480), "for PICO-8 · Anbernic · Knulli", font=fs, fill=DIM, anchor="mm")
    im.save(os.path.join(OUT, "cover.png"))


def shots():
    os.makedirs(os.path.join(OUT, "screenshots"), exist_ok=True)
    for c in CARTS + ("swing_mix",):
        Image.open(os.path.join(IMG, f"{c}-image.png")).save(os.path.join(OUT, "screenshots", f"{c}.png"))
    Image.open(os.path.join(ROOT, "docs", "pages_en.png")).save(os.path.join(OUT, "screenshots", "all_pages.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    cover()
    shots()
    print("itch kit ok ->", OUT)
