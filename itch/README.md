# itch.io page

Swing Lofi is on itch.io: https://giordams.itch.io/swing-lofi (preview video: https://www.youtube.com/watch?v=n9OyCdPD6Is).

This folder holds the assets for that page:

| File | Use |
|---|---|
| `cover.png` | Cover image (630×500, itch's recommended size) |
| `screenshots/` | Page screenshots, in this order: `swing_beats.png`, `swing_keys.png`, `swing_noise.png`, `swing_mix.png`, `all_pages.png` |
| `PAGE.en.md`, `PAGE.es.md` | Tagline, description and metadata |

The download on itch is the same zip as the [GitHub release](https://github.com/santiago-giordano/swing_pico8/releases/latest).

## Updating

When a new release goes out, rebuild the images with `python3 tools/itch.py`, grab the new zip from the release and upload it with `butler push` or from the itch.io dashboard.
