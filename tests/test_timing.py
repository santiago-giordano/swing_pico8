"""Swing and nudge accuracy of swing_beats (PCM engine).

Plays a hat on every step and measures the onset intervals in the
emulator's audio output; then shifts the hat track by several nudge values.
"""
import os, sys, shutil
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "harness"))
import run as R, songfile as sf, onsets as on

OUT = os.path.join(R.WORK, "timing")


def song(path, bpm, swing, hats, nudge=0):
    b = sf.blank(bpm=bpm, swing=swing)
    b[16] = 0
    sf.beats_pattern(b, 0, ["0" * 16, "0" * 16, "0" * 16, hats, "0" * 16])
    sf.beats_params(b, nudge=(0, 0, 0, nudge, 0))
    sf.write(path, b)


def capture(name, **kw):
    out = os.path.join(OUT, name)
    shutil.rmtree(out, ignore_errors=True)
    song(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), **kw)
    R.run(R.cart("swing_beats"), out, "w 20;t o;w 30;t x;w 30;wav k;w 240;wavend")
    sig, sr = on.load(os.path.join(out, "k.wav"))
    return on.onsets(sig, sr)


def test_swing():
    bpm, swing = 90, 66
    o = capture("swing", bpm=bpm, swing=swing, hats="3" * 16)
    d = [(o[i + 1] - o[i]) * 1000 for i in range(len(o) - 1)]
    step = 15 / bpm * 1000
    lo, hi = step * (2 - swing / 50), step * swing / 50
    longs, shorts = d[0::2], d[1::2]
    if abs(longs[0] - hi) > abs(longs[0] - lo):
        longs, shorts = shorts, longs
    err = max(max(abs(x - hi) for x in longs), max(abs(x - lo) for x in shorts))
    print(f"swing {swing}% @ {bpm}bpm: long {hi:.1f}ms short {lo:.1f}ms, max error {err:.2f}ms")
    assert err < 1.5


def test_nudge():
    base = capture("n0", bpm=90, swing=50, hats="3030303030303030")
    for nd in (5, -40, 40):
        o = capture(f"n{nd}", bpm=90, swing=50, hats="3030303030303030", nudge=nd)
        shifts = [(min(o, key=lambda x: abs(x - t)) - t) * 1000 for t in base[1:-1]]
        med = sorted(shifts)[len(shifts) // 2]
        print(f"nudge {nd:+d}ms -> measured {med:+.1f}ms")
        assert abs(med - nd) < 1.0


if __name__ == "__main__":
    test_swing()
    test_nudge()
    print("timing ok")
