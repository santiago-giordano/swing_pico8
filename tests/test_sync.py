"""Stem sync: record the same song with the three carts (pause menu ->
record song) and check that the count-in clicks and bar 1 line up.

Each take starts with 4 count-in clicks (the first one at 2.2 kHz, the rest
at 1.6 kHz); bar 1 must land exactly one bar after the first click.
"""
import os, sys, shutil
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "harness"))
import run as R, songfile as sf, onsets as on

OUT = os.path.join(R.WORK, "sync")
CARTS = ("swing_beats", "swing_keys", "swing_noise")


def band(x, sr, lo, hi):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    X[(f < lo) | (f > hi)] = 0
    return np.fft.irfft(X, len(x))


def first(y, sr, t0, thr):
    a = np.abs(y)
    i = int(t0 * sr)
    while i < len(a) and a[i] < thr:
        i += 1
    return i / sr


def test_sync():
    shutil.rmtree(OUT, ignore_errors=True)
    init = os.path.join(OUT, "init")
    for c in CARTS:  # every cart writes its defaults into song 1
        R.run(R.cart(c), init, "w 20;t o;w 70")
    path = os.path.join(init, "sys/cdata/swingbox_cancion1.p8d.txt")
    b = sf.read(path)
    assert [b[127] >> 7, b[239] >> 7, b[255] >> 7] == [1, 1, 1]
    b[7], b[16], b[17] = 2, 0, 1 | 4  # 2 bars: A then B
    b[6] = 39  # fixed seed; with 39 the old keys clock jumped 2 frames (+33 ms)
    sf.write(path, b)
    bar = 16 * 15 / b[2]
    expected = [bar / 4, bar / 2, bar * 3 / 4]
    for c in CARTS:
        out = os.path.join(OUT, c)
        shutil.copytree(os.path.join(init, "sys"), os.path.join(out, "sys"))
        R.run(R.cart(c), out, "w 20;t o;w 40;w 10 s;w 10;w 6 d;w 6;wav rec;w 6 o;w 6;w 720;wavend")
        x, sr = on.load(os.path.join(out, "rec.wav"))
        x = np.array(x)
        acc = band(x, sr, 2050, 2350)
        t1 = first(acc, sr, 0, 0.5 * np.abs(acc[:sr]).max())
        clk = band(x, sr, 1450, 1750)
        ref = 0.5 * np.abs(clk[int(t1 * sr):int((t1 + bar) * sr)]).max()
        clicks, t = [], t1 + 0.3
        for _ in range(3):
            tk = first(clk, sr, t, ref)
            clicks.append(tk - t1)
            t = tk + 0.3
        low = band(x, sr, 30, 200)
        win = np.abs(low[int((t1 + bar) * sr):int((t1 + bar + 0.6) * sr)]).max()
        start = first(low, sr, t1 + bar - 0.3, 0.3 * win) - t1
        cerr = max(abs(a - e) for a, e in zip(clicks, expected)) * 1000
        serr = (start - bar) * 1000
        print(f"{c:12s} click error {cerr:.1f}ms, bar 1 at {serr:+.1f}ms")
        assert cerr < 5          # keys fires per frame (+-8ms max)
        assert abs(serr) < 15    # humanize (+-4ms) + default nudges


if __name__ == "__main__":
    test_sync()
    print("sync ok")
