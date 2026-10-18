"""Read/write swingbox song cartdata files (fake-08 p8d.txt format) for tests."""
import os

def read(path):
    words = []
    for line in open(path):
        line = line.strip()
        for k in range(0, len(line), 8):
            words.append(int(line[k:k+8], 16))
    b = bytearray()
    for w in words[:64]:
        b += bytes([w & 255, (w >> 8) & 255, (w >> 16) & 255, (w >> 24) & 255])
    return b

def write(path, b):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    words = [b[i] | b[i+1] << 8 | b[i+2] << 16 | b[i+3] << 24 for i in range(0, 256, 4)]
    lines = []
    for r in range(8):
        lines.append("".join("%08x" % w for w in words[r*8:(r+1)*8]))
    open(path, "w").write("\n".join(lines) + "\n")

def fset(b, base, idx, w, v):
    k = idx * w
    a = base + k // 8
    sh = k % 8
    m = ((1 << w) - 1) << sh
    b[a] = (b[a] & ~m & 255) | (v << sh)

def fget(b, base, idx, w):
    k = idx * w
    return (b[base + k // 8] >> (k % 8)) & ((1 << w) - 1)

def blank(bpm=82, swing=62, key=9, scale=0, seed=7, length=1, click=1):
    b = bytearray(256)
    for i, v in enumerate([0x5b, 1, bpm, swing, key, scale, seed, length, click]):
        b[i] = v
    return b

def beats_pattern(b, p, rows):
    """rows: 5 strings of 16 digits (kick,snare,rim,hat,open)"""
    for t, r in enumerate(rows):
        for s, ch in enumerate(r):
            fset(b, 32 + p * 20, t * 16 + s, 2, int(ch))

def beats_params(b, nudge=(0,)*5, hum=0, levels=(7,)*5, kit=0, tone=7, drive=0, room=0, crush=0, tune=0):
    for t in range(5):
        b[112 + t] = 64 + nudge[t]
        b[118 + t] = levels[t]
    b[117] = hum; b[123] = kit; b[124] = tone; b[125] = drive; b[126] = room
    b[127] = 128 | crush | (tune + 3) << 2
