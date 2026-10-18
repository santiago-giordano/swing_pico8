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

if __name__ == "__main__":
    test_kit_change_while_playing()
