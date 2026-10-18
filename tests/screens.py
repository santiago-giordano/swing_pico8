"""Capture every page of the three carts in both languages and save
contact sheets to docs/ (also a smoke test: any Lua error raises)."""
import os, sys, shutil
from PIL import Image
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "harness"))
import run as R

OUT = os.path.join(R.WORK, "screens")
DOCS = os.path.join(R.REPO, "docs")
PAGES = {"swing_beats": 4, "swing_keys": 3, "swing_noise": 3}


def main():
    shutil.rmtree(OUT, ignore_errors=True)
    for lang in ("es", "en"):
        sheet = Image.new("RGB", (256 * 5, 256 * 3), (17, 29, 53))
        for row, (c, n) in enumerate(PAGES.items()):
            out = os.path.join(OUT, lang, c)
            script = "w 20;shot p0;t o;w 20;t x;w 120;shot p1"
            for i in range(2, n + 1):
                script += f";hold x r;w 10;shot p{i}"
            R.run(R.cart(c, lang), out, script)
            for i in range(n + 1):
                im = Image.open(os.path.join(out, f"p{i}.png")).resize((256, 256), Image.NEAREST)
                sheet.paste(im, (i * 256, row * 256))
        sheet.save(os.path.join(DOCS, f"pages_{lang}.png"))
    # hero image: the three carts playing
    hero = Image.new("RGB", (384 * 3 + 24, 384 + 12), (17, 29, 53))
    for i, c in enumerate(PAGES):
        hero.paste(Image.open(os.path.join(OUT, "en", c, "p1.png")), (6 + i * 390, 6))
    hero.save(os.path.join(DOCS, "swing_lofi.png"))
    print("screens ok ->", DOCS)


if __name__ == "__main__":
    main()
