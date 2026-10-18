"""Run a cart in the patched fake-08 with a scripted input sequence.

Script mini-language (semicolon separated):
  w N [keys]    hold keys for N frames (keys: l r u d o x s)
  t keys        tap: 2 frames pressed + 2 released
  hold A B      while A is held, tap B (e.g. "hold x r" = next page)
  shot NAME     save a screenshot (NAME.png)
  wav NAME      start capturing audio (NAME.wav, 22050 Hz stereo)
  wavend        stop capturing audio
"""
import os, subprocess
from PIL import Image

TESTS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORK = os.path.join(TESTS, ".work")
REPO = os.path.dirname(TESTS)
CORE = os.path.join(WORK, "fake-08/platform/libretro/fake08_libretro.so")
FRONT = os.path.join(WORK, "front")
BITS = dict(l=1, r=2, u=4, d=8, o=16, x=32, s=64)


def cart(name, lang="es"):
    return os.path.join(REPO, "carts", lang, name + ".p8")


def mask(keys):
    m = 0
    for k in keys:
        m |= BITS[k]
    return m


def compile_script(src):
    out = []
    for cmd in [c.strip() for c in src.split(";") if c.strip()]:
        p = cmd.split()
        if p[0] == "w":
            out.append(f"w {int(p[1])} {mask(p[2]) if len(p) > 2 else 0}")
        elif p[0] == "t":
            out += [f"w 2 {mask(p[1])}", "w 2 0"]
        elif p[0] == "hold":
            a, b = p[1], p[2]
            out += [f"w 2 {mask(a)}", f"w 2 {mask(a + b)}", f"w 2 {mask(a)}", "w 2 0"]
        else:
            out.append(cmd)
    return "\n".join(out) + "\n"


def run(cart_path, outdir, src, scale=3):
    """Run the script; cartdata lives in outdir/sys/cdata (shared by carts using the same outdir)."""
    os.makedirs(os.path.join(outdir, "sys"), exist_ok=True)
    sc = os.path.join(outdir, "script.txt")
    open(sc, "w").write(compile_script(src))
    r = subprocess.run([FRONT, CORE, cart_path, sc, outdir], capture_output=True, text=True)
    for f in os.listdir(outdir):
        if f.endswith(".ppm"):
            im = Image.open(os.path.join(outdir, f))
            im.resize((128 * scale, 128 * scale), Image.NEAREST).save(os.path.join(outdir, f[:-4] + ".png"))
            os.remove(os.path.join(outdir, f))
    errors = [l for l in (r.stdout + r.stderr).splitlines() if "LUAERR" in l or "attempt to" in l]
    if errors:
        raise RuntimeError("\n".join(errors))
    return r


# pause menu: open, move to item 1 ("record song"), confirm
RECORD = "w 10 s;w 10;w 6 d;w 6;w 6 o;w 6"
