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

if __name__ == "__main__":
    test_bass_speaker()
    test_metronome()
    test_keys_align()
    test_mute()
    test_record()
    print("mix ok")
