"""Onset detection on a fake-08 WAV capture (22050 Hz stereo int16)."""
import wave, struct

def load(path):
    w = wave.open(path)
    n = w.getnframes()
    d = struct.unpack("<%dh" % (n * 2), w.readframes(n))
    return [x / 32768 for x in d[0::2]], w.getframerate()

def onsets(sig, sr, thr=0.08, hold=0.06, win=0.004):
    """return onset times (s) where short-term peak jumps above thr and above 2x prior energy"""
    hop = int(sr * win)
    env = []
    for i in range(0, len(sig) - hop, hop):
        env.append(max(abs(x) for x in sig[i:i+hop]))
    out = []
    last = -1e9
    for k in range(3, len(env)):
        prev = max(env[k-3:k])
        if env[k] > thr and env[k] > prev * 2.0 + 0.02 and (k * hop / sr - last) > hold:
            # refine: first sample in window above half of window peak
            s0 = k * hop
            pk = env[k]
            j = s0
            while j < s0 + hop and abs(sig[j]) < pk * 0.5:
                j += 1
            t = j / sr
            out.append(t)
            last = t
    return out
