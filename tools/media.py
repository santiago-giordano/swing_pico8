#!/usr/bin/env python3
"""Scraper media for EmulationStation frontends (Knulli, Batocera, ROCKNIX).

Runs each cart in the test rig (patched fake-08, same PCM path as official
PICO-8) and writes, under knulli/:

  images/<cart>-image.png   screenshot while playing (main page)
  images/<cart>-thumb.png   song picker / title screen
  videos/<cart>-video.mp4   ~16 s capture of the cart playing, with its stem
  gamelist.xml              metadata for the three carts (Spanish)
  gamelist.en.xml           same, in English

Needs the test rig (bash tests/setup.sh), Pillow and ffmpeg.
"""
import os, sys, shutil, subprocess
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tests", "harness"))
import run as R, songfile as sf

OUT = os.path.join(ROOT, "knulli")
WORK = os.path.join(R.WORK, "media")
FPS, SECS, SCALE = 30, 16, 4
CARTS = ("swing_beats", "swing_keys", "swing_noise")
# a groove preset worth showing: "borracho" / drunk (see src/beats.lua gpre)
DRUNK = "AAAHH02000511"

META = {
    "swing_beats": {
        "es": ("Swing Beats", "Batería lofi por PCM con swing estilo J Dilla: 5 pistas de 16 pasos, swing por pista, groove templates, flam, deriva y humanización. Graba su stem con click de conteo para mezclar en un DAW. Parte de swing_pico8 junto con swing_keys y swing_noise."),
        "en": ("Swing Beats", "Lofi drums over PCM with J Dilla-style swing: 5 tracks of 16 steps, per-track swing, groove templates, flam, phrase drift and humanize. Records its stem with a click count-in for mixing in a DAW. Part of swing_pico8 with swing_keys and swing_noise."),
    },
    "swing_keys": {
        "es": ("Swing Keys", "Bajo, lead y acordes por grados de la escala, con cuatriadas diatónicas, reverb, filtro, detune, wobble de cinta y eco sincronizado. Comparte la canción con swing_beats y swing_noise."),
        "en": ("Swing Keys", "Bass, lead and chords written as scale degrees, with diatonic 7th chords, reverb, filter, detune, tape wobble and tempo-synced echo. Shares the song with swing_beats and swing_noise."),
    },
    "swing_noise": {
        "es": ("Swing Noise", "Ambiente lofi por PCM: vinilo, cinta, lluvia, fuego, mar y noche, con presets, ducking con el bombo, fades y aguja de vinilo. Comparte la canción con swing_beats y swing_keys."),
        "en": ("Swing Noise", "Lofi ambience over PCM: vinyl, tape, rain, fire, sea and night, with presets, kick-synced ducking, fades and needle drop. Shares the song with swing_beats and swing_keys."),
    },
}


def song():
    """default song written by the three carts, with the drunk groove applied"""
    d = os.path.join(WORK, "init")
    if not os.path.exists(d):
        for c in CARTS:
            R.run(R.cart(c), d, "w 20;t o;w 70")
    b = sf.read(os.path.join(d, "sys/cdata/swingbox_cancion1.p8d.txt"))
    b[9] = 7
    for t in range(5):
        b[118 + t] = (b[118 + t] & 7) | ((ord(DRUNK[t]) - 64) << 3)
        b[112 + t] = 64
        sf.fset(b, 11, t, 2, ord(DRUNK[t + 5]) - 48)
    b[117] = (ord(DRUNK[10]) - 48) | ((ord(DRUNK[11]) - 48) << 4)
    b[10] = ord(DRUNK[12]) - 48
    return b


def capture(cart, b, lang):
    out = os.path.join(WORK, lang, cart)
    shutil.rmtree(out, ignore_errors=True)
    sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
    n = FPS * SECS
    step = 60 // FPS
    s = "w 20;shot thumb;t o;w 40;t x;w 30;wav a;"
    s += "".join(f"shot f{i:04d};w {step};" for i in range(n))
    s += "wavend"
    R.run(R.cart(cart, lang), out, s, scale=SCALE)
    return out


def main():
    lang_cart = sys.argv[1] if len(sys.argv) > 1 else "es"
    for d in ("images", "videos"):
        os.makedirs(os.path.join(OUT, d), exist_ok=True)
    b = song()
    for c in CARTS:
        out = capture(c, b, lang_cart)
        shutil.copy(os.path.join(out, "thumb.png"), os.path.join(OUT, "images", f"{c}-thumb.png"))
        shutil.copy(os.path.join(out, f"f{FPS * 4:04d}.png"), os.path.join(OUT, "images", f"{c}-image.png"))
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(FPS), "-i", os.path.join(out, "f%04d.png"),
                        "-i", os.path.join(out, "a.wav"), "-shortest",
                        "-vf", "scale=512:512:flags=neighbor", "-c:v", "libx264", "-pix_fmt", "yuv420p",
                        "-crf", "26", "-preset", "slow", "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart",
                        os.path.join(OUT, "videos", f"{c}-video.mp4")], check=True)
        print("media ok:", c)
    for lang, name in (("es", "gamelist.xml"), ("en", "gamelist.en.xml")):
        rows = ['<?xml version="1.0"?>', "<gameList>"]
        for c in CARTS:
            title, desc = META[c][lang]
            rows += [
                "\t<game>",
                f"\t\t<path>./{c}.p8</path>",
                f"\t\t<name>{escape(title)}</name>",
                f"\t\t<desc>{escape(desc)}</desc>",
                f"\t\t<image>./images/{c}-image.png</image>",
                f"\t\t<thumbnail>./images/{c}-thumb.png</thumbnail>",
                f"\t\t<video>./videos/{c}-video.mp4</video>",
                "\t\t<releasedate>20261018T000000</releasedate>",
                "\t\t<developer>Santiago Giordano</developer>",
                "\t\t<publisher>Santiago Giordano</publisher>",
                f"\t\t<genre>{'Música' if lang == 'es' else 'Music'}</genre>",
                "\t\t<players>1</players>",
                f"\t\t<lang>{lang}</lang>",
                "\t</game>",
            ]
        rows.append("</gameList>")
        open(os.path.join(OUT, name), "w").write("\n".join(rows) + "\n")
    print("gamelists ok ->", OUT)


if __name__ == "__main__":
    main()
