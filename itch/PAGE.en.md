# Swing PICO-8

**Lofi beats with J Dilla–style swing, made on a handheld. Three PICO-8 carts that record stems for your DAW.**

## Short description (tagline, max ~100 chars)

Lofi beat-making with Dilla swing for PICO-8: drums, keys and noise that record as stems.

## Page text (paste into the description field)

Swing PICO-8 is a small lofi studio in three PICO-8 carts:

- **Swing Beats**: drums. 5 tracks × 16 steps, 3 velocities per step, 3 kits (dust, soft, tape).
- **Swing Keys**: bass, lead and chords written as scale degrees, with diatonic 7th chords, reverb, filter, detune, tape wobble and a tempo-synced echo.
- **Swing Noise**: vinyl, tape, rain, fire, sea and night textures, with kick-synced ducking, fades and a vinyl needle drop.

All three share the same song (8 slots), so tempo, swing, key, scale and arrangement stay in sync. Each cart records its own stem with a count-in click: line-out into your interface, align the three takes on the first click, done.

### The groove is the point

Dilla time isn't randomness, it's *programmed* timing that repeats every bar. So the swing here works that way:

- Swing 50–75 %, on a 16th or 8th base, plus **per-track swing**
- **Groove templates** with per-step offsets (septuplet, 5/192 snare, golden ratio, "drunk"…)
- Per-track **nudge** from −64 to +60 ms, **flam**, and **phrase drift**
- **Humanize** in three modes: random, smooth (correlated, 1/f-like) or locked (same offsets every bar)
- Sample-accurate timing with the official PICO-8 (PCM output)

Takes come out identical every time, so stems always line up.

### Runs on a US$60 handheld

Built and tested for the **Anbernic RG CubeXX** running Knulli. Drums sit at about 35–40 % CPU on the console while playing. It also runs on desktop PICO-8.

### What you need

- **PICO-8** (official, from lexaloffle.com). Recommended: swing_beats and swing_noise use PCM output, which fake-08 doesn't implement (swing_keys works anywhere; swing_beats falls back to a simpler "chip" mode).
- Optional: line-out cable and an audio interface to record the stems.

### What's in the download

- `es/` and `en/`: the three carts (Spanish and English; language can also be switched in-cart with X)
- `knulli/`: images, 16 s preview videos and `gamelist.xml` so the carts show up with art and descriptions in EmulationStation (Knulli, Batocera, ROCKNIX)
- README and license (MIT)

Open source: https://github.com/santiago-giordano/swing_pico8

Made by Santiago Giordano, Buenos Aires.

---

## Metadata to set on itch.io

- **Kind of project:** Downloadable
- **Classification:** Tool (or Game → Other; Tool fits better)
- **Genre / tags:** music, lofi, pico-8, tracker, sequencer, drum-machine, handheld, anbernic, open-source
- **Pricing:** Pay what you want, suggested US$3 (minimum 0). It's MIT on GitHub, so keep it friendly.
- **Platforms:** Windows, macOS, Linux (it's a zip of .p8 carts; PICO-8 runs on all)
- **Release status:** Released
- **Community:** comments on
- **Embed:** none (PICO-8 web export would lose the PCM/audio recording flow; link to the GitHub for source)
