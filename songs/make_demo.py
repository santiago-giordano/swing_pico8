#!/usr/bin/env python3
"""Draft arrangement of the "borracho" loop used in the Knulli videos.

Takes the same song as tools/media.py (default cartdata + drunk groove, 82 BPM),
fills the empty patterns and writes a 16-block arrangement (32 bars, ~94 s).
Then renders it with swing_mix in the test rig (bash tests/setup.sh first).

  beats A,B = the video loop        beats C = new snare fill (B + roll)
  keys  A,B = the video loop        keys C/D  = chords only of A / B (intro, quiet parts)

Chain byte (see src/core.lua chaincell): b0-1 beats pat, b2-3 keys pat,
b4-5 repeats (1/2/4/8), b6 mute beats, b7 mute keys.

  python3 songs/make_demo.py [outdir]
"""
import os, sys, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(ROOT, "tests", "harness"))
import media, run as R, songfile as sf

A, B, C, D = 0, 1, 2, 3
MB, MK = 64, 128
# (beats pattern, keys pattern, repeats code 0..3 = x1 x2 x4 x8, mute flags)
BLOCKS = [
    # intro: only noise (vinyl) and chords, 4 bars
    (A, C, 1, MB), (A, D, 1, MB),
    # beats come in over the chords, 8 bars
    (A, C, 1, 0), (B, D, 1, 0), (A, C, 1, 0), (B, D, 1, 0),
    # everything together, 8 bars (the loop of the video, twice)
    (A, A, 1, 0), (B, B, 1, 0), (A, A, 1, 0), (B, B, 1, 0),
    # break without drums, 4 bars
    (A, A, 1, MB), (B, B, 1, MB),
    # full again with a fill on the last bar, 4 bars
    (A, A, 1, 0), (B, B, 0, 0), (C, B, 0, 0),
    # outro: chords only, noise rings out, 4 bars
    (A, C, 2, MB),
]


def build():
    b = media.song()
    # beats C: pattern B with a snare roll on the last beat
    sf.beats_pattern(b, C, ["3000000200030200", "0000300000303333", "0000000100000000",
                            "2010201020102000", "0000000000000020"])
    # keys C / D: the chord row of A / B only
    for dst, src in ((C, A), (D, B)):
        for s in range(16):
            sf.fset(b, 128 + dst * 24, s * 3 + 2, 4, sf.fget(b, 128 + src * 24, s * 3 + 2, 4))
    reps = lambda r: 1 << r
    for i in range(16):
        b[16 + i] = 0
    for i, (bp, kp, r, m) in enumerate(BLOCKS):
        b[16 + i] = bp | kp << 2 | r << 4 | m
    b[7] = len(BLOCKS)
    b[8] = 0  # no click / count-in
    bars = sum(1 << r for _, _, r, _ in BLOCKS)
    return b, bars


def main():
    out = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "out")
    b, bars = build()
    secs = bars * 4 * 60 / b[2]
    print(f"{len(BLOCKS)} blocks, {bars} bars, {b[2]} BPM -> {secs:.1f} s")
    os.makedirs(out, exist_ok=True)
    sf.write(os.path.join(out, "swingbox_cancion1.p8d.txt"), b)
    run = os.path.join(media.WORK, "demo")
    shutil.rmtree(run, ignore_errors=True)
    sf.write(os.path.join(run, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
    frames = int((secs + 3) * 60)
    # menu -> "record mix" is what the test rig does in tests/test_mix.py (test_record)
    script = f"w 20;t o;w 40;w 10 s;w 10;w 6 d;w 6;wav a;w 6 o;w 6;w {frames};wavend"
    R.run(R.cart("swing_mix", "en"), run, script)
    shutil.copy(os.path.join(run, "a.wav"), os.path.join(out, "demo_draft.wav"))
    print("ok ->", out)


if __name__ == "__main__":
    main()
