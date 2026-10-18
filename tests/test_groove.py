"""Dilla-style groove features of swing_beats (PCM engine): per-track swing,
8th-note swing base, groove templates, wide negative nudge, flams, phrase
drift and the humanize modes.

Every test plays one track and compares its onsets against the straight grid
measured from a reference take.
"""
import os, sys, shutil
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "harness"))
import run as R, songfile as sf, onsets as on

OUT = os.path.join(R.WORK, "groove")
BPM = 90
STEP = 15 / BPM * 1000  # ms
Z = "0" * 16


def capture(name, rows, frames=240, hold=0.06, bpm=BPM, sswing=50, **kw):
    out = os.path.join(OUT, name)
    shutil.rmtree(out, ignore_errors=True)
    b = sf.blank(bpm=bpm, swing=sswing)
    b[16] = 0
    sf.beats_pattern(b, 0, rows)
    sf.beats_params(b, **kw)
    sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
    R.run(R.cart("swing_beats"), out, f"w 20;t o;w 30;t x;w 30;wav k;w {frames};wavend")
    sig, sr = on.load(os.path.join(out, "k.wav"))
    return on.onsets(sig, sr, hold=hold)



def hats(**kw):
    return capture(kw.pop("name"), [Z, Z, Z, "3" * 16, Z], **kw)


def test_track_swing():
    # song swing 50 (straight), hat track at 57% (septuplet feel)
    o = hats(name="trk57", swing=(0, 0, 0, 57, 0))
    d = [(o[i + 1] - o[i]) * 1000 for i in range(len(o) - 1)]
    hi, lo = STEP * 57 / 50, STEP * (2 - 57 / 50)
    longs, shorts = d[0::2], d[1::2]
    if abs(longs[0] - hi) > abs(longs[0] - lo):
        longs, shorts = shorts, longs
    err = max(max(abs(x - hi) for x in longs), max(abs(x - lo) for x in shorts))
    print(f"hat track swing 57% over straight song: max error {err:.2f}ms")
    assert err < 1.5


def test_base8():
    # 8th-note swing at 60%: offsets per 16th in the beat are 0, k, 2k, k
    k = (60 - 50) / 50 * STEP
    o = hats(name="base8", swing=(0, 0, 0, 60, 0), base8=True)
    d = [(o[i + 1] - o[i]) * 1000 for i in range(len(o) - 1)]
    exp = [STEP + k, STEP + k, STEP - k, STEP - k]
    # find phase
    best = min(range(4), key=lambda p: sum(abs(d[i] - exp[(i + p) % 4]) for i in range(len(d))))
    err = max(abs(d[i] - exp[(i + best) % 4]) for i in range(len(d)))
    print(f"8th swing 60%: k={k:.1f}ms, max error {err:.2f}ms")
    assert err < 1.5


def snare_shift(name, **kw):
    """median shift (ms) of a snare on every beat vs. a kick on every beat"""
    base = capture(name + "_ref", ["3000300030003000", Z, Z, Z, Z])
    o = capture(name, [Z, "3000300030003000", Z, Z, Z], **kw)
    sh = [(min(o, key=lambda x: abs(x - t)) - t) * 1000 for t in base[1:-1]]
    return sorted(sh)[len(sh) // 2]


def test_template_5_192():
    exp = -20 / 48 * STEP  # 5/192 of a bar
    m = snare_shift("t5192", groove=3)
    print(f"template 5/192: snare at {m:+.1f}ms (expected {exp:+.1f})")
    assert abs(m - exp) < 1.5


def test_wide_nudge():
    m = snare_shift("n64", nudge=(0, -64, 0, 0, 0))
    print(f"nudge -64ms: snare at {m:+.1f}ms")
    assert abs(m + 64) < 1.5


def test_flam():
    o = capture("flam", [Z, Z, "3000300030003000", Z, Z], hold=0.005, flam=(0, 0, 3, 0, 0))
    gaps = [(o[i + 1] - o[i]) * 1000 for i in range(len(o) - 1)]
    small = [g for g in gaps if g < 60]
    print(f"flam 30ms: grace-to-main gaps {[round(g, 1) for g in small]}")
    assert len(small) >= 3 and all(abs(g - 30) < 2 for g in small)


def test_drift():
    # hat swing 57 + 2%/bar drift: the off-step delay grows bar by bar
    o = hats(name="drift", swing=(0, 0, 0, 57, 0), drift=2, frames=660)
    d = [(o[i + 1] - o[i]) * 1000 for i in range(len(o) - 1)]
    longs = d[0::2]
    if longs[0] < STEP:
        longs = d[1::2]
    per_bar = [sum(longs[b * 8:(b + 1) * 8]) / 8 for b in range(len(longs) // 8)]
    sw = [round(x / STEP * 50, 1) for x in per_bar]
    print(f"drift +2%/bar from 57%: measured swing per bar {sw}")
    assert abs(sw[0] - 57) < 0.6 and abs(sw[1] - 59) < 0.6 and abs(sw[2] - 61) < 0.6


def bar_offsets(o):
    t0 = o[0]
    off = [((t - t0) * 1000) - round((t - t0) * 1000 / STEP) * STEP for t in o]
    return [off[b * 16:(b + 1) * 16] for b in range(len(off) // 16)]


def test_lock():
    o = hats(name="lock", hum=12, hummode=2, frames=420)
    bars = bar_offsets(o)
    dev = max(abs(a - b) for a, b in zip(bars[0], bars[1]))
    spread = max(bars[0]) - min(bars[0])
    print(f"lock: bar-to-bar difference {dev:.2f}ms, spread inside a bar {spread:.1f}ms")
    assert dev < 1.0 and spread > 6


def test_free_and_drift_vary():
    lag = {}
    for m, name in ((0, "free"), (1, "ar1")):
        o = hats(name=name, hum=12, hummode=m, frames=420)
        bars = bar_offsets(o)
        dev = max(abs(a - b) for a, b in zip(bars[0], bars[1]))
        flat = [x for b in bars for x in b]
        lag[name] = sum((flat[i] - flat[i + 1]) ** 2 for i in range(len(flat) - 1)) / (len(flat) - 1)
        print(f"{name}: bar-to-bar difference {dev:.1f}ms, range {max(flat) - min(flat):.1f}ms, "
              f"mean squared step-to-step change {lag[name]:.1f}")
        assert dev > 2 and max(flat) - min(flat) < 24 + 1.5
    assert lag["ar1"] < lag["free"]  # correlated: neighbours stay close


if __name__ == "__main__":
    test_track_swing()
    test_base8()
    test_template_5_192()
    test_wide_nudge()
    test_flam()
    test_drift()
    test_lock()
    test_free_and_drift_vary()
    print("groove ok")
