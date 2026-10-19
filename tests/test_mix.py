"""swing_mix: the three engines in one cart.

1. keys (chip channels) must land on time against beats (PCM): hats on
   steps 1 and 9, bass on 5 and 13; each bass note must sit halfway
   between the hats around it.
2. levels: muting a stem in the mixer removes it from the output.
3. record mix: the count-in and bar 1 line up like the stems do.
"""
import os, sys, shutil
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "harness"))
import run as R, songfile as sf, onsets as on
from test_sync import band, first

OUT = os.path.join(R.WORK, "mix")


def song(mix15=0):
    b = sf.blank(bpm=90, swing=50)
    b[16] = 0
    sf.beats_pattern(b, 0, ["0" * 16, "0" * 16, "0" * 16, "3000000030000000", "0" * 16])
    sf.beats_params(b, nudge=(0,) * 5)
    for r in range(3):  # keys: wave, octave, level, fx, nudge
        for j, v in enumerate((0, 1, 7, 0, 64)):
            b[224 + r * 5 + j] = v
    b[239] = 128
    for s in (4, 12):
        sf.fset(b, 128, s * 3, 4, 1)  # bass, degree 1
    b[14] = 128 | 7 | 7 << 3  # beats 7, keys 7
    b[15] = mix15             # noise 0, mute/solo bits
    return b


def capture(name, b, script="w 20;t o;w 30;t x;w 20;wav a;w 300;wavend"):
    out = os.path.join(OUT, name)
    shutil.rmtree(out, ignore_errors=True)
    sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
    R.run(R.cart("swing_mix"), out, script)
    x, sr = on.load(os.path.join(out, "a.wav"))
    return np.array(x), sr


def test_keys_align():
    x, sr = capture("align", song())
    hat = band(x, sr, 2000, 2700)
    bas = band(x, sr, 40, 400)
    th = 0.4 * np.abs(hat).max()
    tb = 0.4 * np.abs(bas).max()
    step = 15 / 90
    hats, t = [], 0
    while True:
        h = first(hat, sr, t, th)
        if h >= len(x) / sr - 0.01:
            break
        hats.append(h)
        t = h + 4 * step
    offs = []
    for a, c in zip(hats, hats[1:]):
        bb = first(bas, sr, a + step, tb)
        offs.append((bb - (a + c) / 2) * 1000)
    print("keys vs beats (ms):", " ".join(f"{o:+.1f}" for o in offs))
    assert len(offs) >= 3
    assert max(abs(o) for o in offs) < 20


def test_mute():
    rms = {}
    for name, m in (("all", 0), ("mute_beats", 8), ("solo_beats", 1 << 6)):
        x, sr = capture(name, song(m))
        rms[name] = (np.sqrt(np.mean(band(x, sr, 2000, 2700) ** 2)),
                     np.sqrt(np.mean(band(x, sr, 40, 400) ** 2)))
    print("hat/bass rms:", {k: tuple(round(float(u), 4) for u in v) for k, v in rms.items()})
    assert rms["mute_beats"][0] < rms["all"][0] * 0.1     # hats gone
    assert rms["solo_beats"][1] < rms["all"][1] * 0.3     # bass gone
    assert rms["solo_beats"][0] > rms["all"][0] * 0.8     # hats still there


def test_record():
    b = song()
    b[8] = 1  # count-in click
    x, sr = capture("rec", b, "w 20;t o;w 40;w 10 s;w 10;w 6 d;w 6;wav a;w 6 o;w 6;w 400;wavend")
    bar = 16 * 15 / 90
    acc = band(x, sr, 2050, 2350)
    t1 = first(acc, sr, 0, 0.5 * np.abs(acc[:sr]).max())
    hat = band(x, sr, 2500, 2750)
    win = np.abs(hat[int((t1 + bar - 0.1) * sr):int((t1 + bar + 0.2) * sr)]).max()
    start = first(hat, sr, t1 + bar - 0.1, 0.4 * win) - t1
    err = (start - bar) * 1000
    print(f"record mix: bar 1 at {err:+.1f}ms after the count-in")
    assert abs(err) < 10


def test_metronome():
    """click 2 = metronome while playing, in every cart; click 1 = count-in only"""
    q = 15 / 90 * 4
    for cart in ("swing_beats", "swing_keys", "swing_noise", "swing_mix"):
        res = {}
        for ck in (1, 2):
            b = sf.blank(bpm=90, swing=50, click=ck)
            b[16] = 0
            b[127] = 128 | 3 << 2   # beats initialized, empty pattern
            b[239] = 128            # keys initialized, empty pattern
            b[255] = 128            # noise initialized, all layers at 0
            b[253] = 5
            b[14] = 128 | 7 | 7 << 3
            out = os.path.join(OUT, f"metro_{cart}_{ck}")
            shutil.rmtree(out, ignore_errors=True)
            sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
            R.run(R.cart(cart), out, "w 20;t o;w 30;t x;w 20;wav a;w 300;wavend")
            x, sr = on.load(os.path.join(out, "a.wav"))
            x = np.array(x)
            clk = np.abs(band(x, sr, 500, 2400))
            ts, t = [], 0
            thr = max(0.02, 0.25 * clk.max())
            while True:
                tk = first(clk, sr, t, thr)
                if tk >= len(x) / sr - 0.05:
                    break
                ts.append(tk)
                t = tk + 0.2
            res[ck] = ts if clk.max() > 0.02 else []
        d = np.diff(res[2])
        print(f"{cart:12s} metronome: {len(res[2])} clicks, every {np.median(d) * 1000:.0f} ms; count-in mode while playing: {len(res[1])} clicks")
        assert len(res[2]) >= 6 and abs(np.median(d) - q) < 0.01
        assert len(res[1]) == 0




def test_bass_speaker():
    """speaker on lifts bass notes below ~160 Hz an octave; off leaves them; mix follows byte 127"""
    freqs = {}
    for cart in ("swing_keys", "swing_mix"):
        for on in (True, False):
            b = song()
            b[4] = 0        # key C: degree 1 = pitch 0 (65 Hz)
            b[225] = 0      # bass octave 0
            b[239] = 128 | (0 if on else 32)
            if cart == "swing_mix":
                b[127] = 128 | 3 << 2 | (0 if on else 32)
                b[239] = 128
            out = os.path.join(OUT, f"spk_{cart}_{on}")
            shutil.rmtree(out, ignore_errors=True)
            sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
            R.run(R.cart(cart), out, "w 20;t o;w 30;t x;w 20;wav a;w 200;wavend")
            x, sr = on_load(out)
            lo = band(x, sr, 40, 400)
            sp = np.abs(np.fft.rfft(lo * np.hanning(len(lo))))
            fr = np.fft.rfftfreq(len(lo), 1 / sr)
            freqs[cart, on] = fr[1:][np.argmax(sp[1:])]
    print("bass fundamental (Hz):", {f"{k[0]}/{'on' if k[1] else 'off'}": round(float(v)) for k, v in freqs.items()})
    for cart in ("swing_keys", "swing_mix"):
        assert 1.8 < freqs[cart, True] / freqs[cart, False] < 2.2


def on_load(out):
    x, sr = on.load(os.path.join(out, "a.wav"))
    return np.array(x), sr


def test_fill():
    """block x2 with fill: the last bar gets a snare roll (steps 12-15) and/or an open hat on step 15; bar 1 stays plain"""
    step = 15 / 90
    bar = 16 * step
    res = {}
    for fill in (0, 1, 2):
        b = sf.blank(bpm=90, swing=50, length=1)
        b[1] = 1 | fill << 1
        b[16] = 1 << 4          # block 0: pattern a, x2
        sf.beats_pattern(b, 0, ["3000000000000000", "0" * 16, "0" * 16, "0" * 16, "0" * 16])
        sf.beats_params(b, nudge=(0,) * 5)
        out = os.path.join(OUT, f"fill_{fill}")
        shutil.rmtree(out, ignore_errors=True)
        sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
        R.run(R.cart("swing_beats"), out, "w 20;t o;w 40;w 10 s;w 10;w 6 d;w 6;wav a;w 6 o;w 6;w 700;wavend")
        x, sr = on.load(os.path.join(out, "a.wav"))
        x = np.array(x)
        acc = band(x, sr, 2050, 2350)
        t1 = first(acc, sr, 0, 0.5 * np.abs(acc[:sr]).max())
        hi = band(x, sr, 3000, 2700 + 1300)
        def e(bar_i, a, c):
            t0 = t1 + (1 + bar_i) * bar + a * step
            seg = x[int(t0 * sr):int((t0 + (c - a) * step) * sr)]
            return float(np.sqrt(np.mean(seg ** 2)))
        res[fill] = (e(0, 12, 16), e(1, 12, 16))
    print("rms steps 12-15, bar1/bar2:", {k: tuple(round(v, 4) for v in r) for k, r in res.items()})
    for f in (0, 1, 2):
        assert res[f][0] < 0.01            # first bar: nothing but the tail
    assert res[0][1] < 0.01
    assert res[1][1] > 5 * max(res[0][1], 0.002)
    assert res[2][1] > 5 * max(res[0][1], 0.002)


def test_duplicate():
    """x+o: pattern -> next letter when empty; block -> inserted copy"""
    b = sf.blank(bpm=90, swing=50, length=2)
    b[16], b[17] = 0b00010001, 0b00100010   # block 0: beats b x2, keys a; block 1: beats c x4
    b[127] = 128 | 3 << 2
    sf.beats_pattern(b, 0, ["3000300030003000", "0" * 16, "0" * 16, "2222222222222222", "0" * 16])
    sf.beats_pattern(b, 1, ["0" * 16, "0" * 16, "0" * 16, "0" * 16, "0" * 16])
    sf.beats_pattern(b, 2, ["0" * 16, "0" * 16, "0" * 16, "0" * 16, "0" * 16])
    sf.fset(b, 32 + 2 * 20, 5, 2, 1)       # pattern c is not empty
    out = os.path.join(OUT, "dup")
    shutil.rmtree(out, ignore_errors=True)
    path = os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt")
    sf.write(path, b)
    R.run(R.cart("swing_beats"), out, "w 20;t o;w 20;hold x o;w 10;hold x o;w 10;w 60")
    c = sf.read(path)
    a, bb, cc = c[32:52], c[52:72], c[72:92]
    print("pattern a -> b copied:", a == bb, "; c (not empty) untouched:", cc == b[72:92])
    assert a == bb and a != bytes(20)
    assert cc == b[72:92]
    # block copy: song page, down x3 to the first block
    out = os.path.join(OUT, "dup2")
    shutil.rmtree(out, ignore_errors=True)
    path = os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt")
    sf.write(path, b)
    R.run(R.cart("swing_beats"), out, "w 20;t o;w 20;hold x r;hold x r;hold x r;t d;t d;t d;hold x o;w 10;w 60")
    c = sf.read(path)
    print("blocks:", [bin(v) for v in c[16:20]], "len", c[7])
    assert c[7] == 3 and c[16] == 0b00010001 and c[17] == 0b00010001 and c[18] == 0b00100010


def test_keys_reference():
    """swing_keys with the drum reference on: hats sound, and the bass lands between them like in the mix;
    with it off (and while recording) nothing changes"""
    res = {}
    for ref in (False, True):
        b = song()
        b[239] = 128 | (64 if ref else 0)
        out = os.path.join(OUT, f"ref_{int(ref)}")
        shutil.rmtree(out, ignore_errors=True)
        sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
        R.run(R.cart("swing_keys"), out, "w 20;t o;w 30;t x;w 20;wav a;w 420;wavend")
        x, sr = on.load(os.path.join(out, "a.wav"))
        x = np.array(x)
        hat = band(x, sr, 2000, 2700)
        bas = band(x, sr, 40, 400)
        res[ref] = (x, sr, hat, bas)
    x, sr, hat, bas = res[True]
    print("hat band peak, reference off/on:", float(np.abs(res[False][2]).max()), float(np.abs(hat).max()))
    assert np.abs(res[False][2]).max() < 0.3 * np.abs(hat).max(), "hats only with the reference"
    th, tb = 0.4 * np.abs(hat).max(), 0.4 * np.abs(bas).max()
    step = 15 / 90
    hats, t = [], 0
    while True:
        h = first(hat, sr, t, th)
        if h >= len(x) / sr - 0.01:
            break
        hats.append(h)
        t = h + 4 * step
    offs = []
    for a, c in zip(hats, hats[1:]):
        bb = first(bas, sr, a + step, tb)
        offs.append((bb - (a + c) / 2) * 1000)
    print("keys vs drum reference (ms):", " ".join(f"{o:+.1f}" for o in offs))
    assert len(offs) >= 3 and max(abs(o) for o in offs) < 25
    # recording: the reference stays off
    b = song()
    b[239] = 128 | 64
    b[8] = 1
    out = os.path.join(OUT, "ref_rec")
    shutil.rmtree(out, ignore_errors=True)
    sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
    R.run(R.cart("swing_keys"), out, "w 20;t o;w 40;w 10 s;w 10;w 6 d;w 6;wav a;w 6 o;w 6;w 400;wavend")
    x, sr = on.load(os.path.join(out, "a.wav"))
    x = np.array(x)
    h = band(x, sr, 2500, 2750)
    print("hat energy while recording:", float(np.abs(h).max()))
    assert np.abs(h).max() < 0.02


def set_trim(b, t, v):
    if t < 3:
        sf.fset(b, 11, 5 + t, 2, v)
    else:
        sf.fset(b, 13, t - 2, 2, v)


def test_trim():
    """trim 3 skips the first 48 samples (~8.7 ms) of the drum: the hit's content arrives that much earlier"""
    xs = {}
    for tr in (0, 3):
        b = sf.blank(bpm=90, swing=50)
        b[16] = 0
        b[127] = 128 | 3 << 2 | 32      # speaker off: plain kick
        sf.beats_pattern(b, 0, ["3" + "0" * 15, "0" * 16, "0" * 16, "0" * 16, "0" * 16])
        sf.beats_params(b, nudge=(0,) * 5)
        b[127] = 128 | 3 << 2 | 32
        set_trim(b, 0, tr)
        out = os.path.join(OUT, f"trim_{tr}")
        shutil.rmtree(out, ignore_errors=True)
        sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
        R.run(R.cart("swing_beats"), out, "w 20;t o;w 20;t x;w 20;wav a;w 100;wavend")
        x, sr = on.load(os.path.join(out, "a.wav"))
        xs[tr] = (np.array(x), sr)
    x0, sr = xs[0]
    x3, _ = xs[3]
    i0 = int(np.argmax(np.abs(x0) > 0.05 * np.abs(x0).max()))
    i3 = int(np.argmax(np.abs(x3) > 0.05 * np.abs(x3).max()))
    a = x0[i0 - 40:i0 + 800]
    best, bl = -1, 0
    for lag in range(-400, 100):
        seg = x3[i0 - 40 + lag:i0 + 800 + lag]
        if len(seg) != len(a) or lag + i0 - 40 < 0:
            continue
        c = float(np.dot(a, seg) / (np.linalg.norm(a) * np.linalg.norm(seg) + 1e-9))
        if c > best:
            best, bl = c, lag
    ms = bl / sr * 1000
    print(f"trim 3: content arrives {ms:+.1f} ms (expected -8.7), correlation {best:.2f}")
    assert -10.5 < ms < -7 and best > 0.8


def test_poly():
    """hat on a triplet grid (12 cells per bar) against a straight kick"""
    step = 15 / 90
    for code, n in ((0, 12), (1, 10)):
        b = sf.blank(bpm=90, swing=50)
        b[16] = 0
        b[1] = 1 | 4 << 3 | code << 6          # poly track 4 (hat), grid code
        row = "2" * 5 + "0" * (16 - 5)
        sf.beats_pattern(b, 0, ["0" * 16, "0" * 16, "0" * 16, row, "0" * 16])
        sf.beats_params(b, nudge=(0,) * 5)
        out = os.path.join(OUT, f"poly_{n}")
        shutil.rmtree(out, ignore_errors=True)
        sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
        R.run(R.cart("swing_beats"), out, "w 20;t o;w 20;t x;w 20;wav a;w 300;wavend")
        x, sr = on.load(os.path.join(out, "a.wav"))
        x = np.array(x)
        hat = band(x, sr, 2500, 2750)
        th = 0.4 * np.abs(hat).max()
        ts, t = [], 0
        while len(ts) < 5:
            h = first(hat, sr, t, th)
            if h >= len(x) / sr - 0.01:
                break
            ts.append(h)
            t = h + 0.05
        d = np.diff(ts) * 1000
        exp = 16 * step / n * 1000
        print(f"poly {n}: hat gaps (ms) {np.round(d, 1)} expected {exp:.1f}")
        assert len(d) >= 3 and np.all(np.abs(d - exp) < 2.5)


def test_boom_kit():
    """kit 4 (boom bap) loads and sounds: kick and snare at least as present as dusty above 150 Hz, no clipping"""
    pk = {}
    for kit in (0, 3):
        b = sf.blank(bpm=90, swing=50)
        b[16] = 0
        sf.beats_pattern(b, 0, ["3000000000000000", "0000300000000000", "0" * 16, "0" * 16, "0" * 16])
        sf.beats_params(b, nudge=(0,) * 5, kit=kit)
        out = os.path.join(OUT, f"kit_{kit}")
        shutil.rmtree(out, ignore_errors=True)
        sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
        R.run(R.cart("swing_beats"), out, "w 20;t o;w 20;t x;w 10;wav a;w 200;wavend")
        x, sr = on.load(os.path.join(out, "a.wav"))
        x = np.array(x)
        mid = band(x, sr, 150, 2000)
        pk[kit] = (float(np.abs(x).max()), float(np.sqrt(np.mean(mid ** 2))))
    print("peak / mid rms (dusty, boom):", {k: tuple(round(v, 3) for v in t) for k, t in pk.items()})
    assert pk[3][0] < 0.99 and pk[3][1] >= pk[0][1] * 0.9


def test_navigation():
    """song page cursor moves by rows: down/right/up/down land where a person expects"""
    b = sf.blank(bpm=90, swing=50, length=4)
    b[127] = 128 | 3 << 2
    out = os.path.join(OUT, "nav")
    shutil.rmtree(out, ignore_errors=True)
    path = os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt")
    sf.write(path, b)
    script = ("w 20;t o;w 20;hold x r;hold x r;hold x r;"
              "t d;t r;hold o r;"          # bpm -> down -> len, right -> click, O+right: click 1 -> 2
              "t r;t d;t l;hold o u;"      # mode, down -> btn, left -> poly, O+up: poly grid 12 -> 10
              "t d;t o;w 60")              # down -> block under poly, tap O
    R.run(R.cart("swing_beats"), out, script)
    c = sf.read(path)
    print("click", c[8], "poly grid code", c[1] >> 6, "block 4 beats letter", c[16 + 4] & 3)
    assert c[8] == 2
    assert c[1] >> 6 == 1
    assert c[16 + 4] & 3 == 1

if __name__ == "__main__":
    test_bass_speaker()
    test_fill()
    test_duplicate()
    test_keys_reference()
    test_trim()
    test_poly()
    test_boom_kit()
    test_navigation()
    test_metronome()
    test_keys_align()
    test_mute()
    test_record()
    print("mix ok")
