"""Regression: changing kit / tune while the pattern plays must not crash
(the new drum buffers can be shorter than a voice that is still sounding)."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "harness"))
import run as R

def test_kit_change_while_playing():
    out = os.path.join(R.WORK, "live_edit")
    # kit page, play, cycle kits and tune with O held
    s = "w 20;t o;w 20;hold x r;hold x r;w 10;t x;w 30;" + "hold o r;w 20;" * 6
    s += "t r;w 4;" + "hold o r;w 20;hold o l;w 20;" * 3
    R.run(R.cart("swing_beats", "en"), out, s)  # raises on any Lua error
    print("live kit/tune edits: no runtime error")

def test_room_tail_stops():
    """with room up, stopping must end in exact silence (no leftover tail)"""
    import numpy as np, songfile as sf, onsets as on
    for cart in ("swing_beats", "swing_mix"):
        for crush in (0, 2):
            b = sf.blank(bpm=90, swing=50)
            b[16] = 0
            sf.beats_pattern(b, 0, ["3000300030003000", "0" * 16, "0" * 16, "2222222222222222", "0" * 16])
            sf.beats_params(b, room=7, crush=crush, drive=3)
            b[14] = 128 | 7 | 7 << 3
            out = os.path.join(R.WORK, f"tail_{cart}_{crush}")
            sf.write(os.path.join(out, "sys/cdata/swingbox_cancion1.p8d.txt"), b)
            R.run(R.cart(cart), out, "w 20;t o;w 20;t x;w 120;t x;w 60;wav a;w 240;wavend")
            x, sr = on.load(os.path.join(out, "a.wav"))
            x = np.array(x)
            tail = float(np.abs(x[-sr:]).max())
            print(f"{cart} crush {crush}: last second peak {tail:.4f}")
            assert tail == 0.0

if __name__ == "__main__":
    test_kit_change_while_playing()
    test_room_tail_stops()
