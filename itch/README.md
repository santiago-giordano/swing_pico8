# itch.io kit

Everything to publish swing_pico8 on itch.io with your own account.

Published at https://giordams.itch.io/swing-lofi, with the [preview video](https://www.youtube.com/watch?v=n9OyCdPD6Is) on YouTube (English carts, 16 s each: beats, keys, noise, mix, captured with the test rig like `tools/media.py` does).

| File | Use |
|---|---|
| `cover.png` | Cover image (630×500, itch's recommended size) |
| `screenshots/` | Upload in this order: `swing_beats.png`, `swing_keys.png`, `swing_noise.png`, `swing_mix.png`, `all_pages.png` |
| `swing_pico8_v2.8.0.zip` | The download (same as the GitHub release) |
| `PAGE.en.md`, `PAGE.es.md` | Tagline, description and metadata to paste |

## Steps

1. itch.io → Dashboard → **Create new project**.
2. Title `Swing Lofi`, URL `swing-lofi`. Paste the tagline and description (English first; add Spanish below it, itch has no per-language page).
3. Kind of project: Downloadable. Fill pricing and tags from the bottom of `PAGE.en.md`.
4. Upload the zip, tick Windows / macOS / Linux.
5. Cover image + screenshots. For video, paste a YouTube link (itch doesn't host mp4 on the page); currently the preview above.
6. Save as **Draft**, preview, then set Visibility to Public.

## Updating

When a new release goes out, rebuild with `python3 tools/itch.py`, grab the new zip from the release and upload it with `butler push` or from the dashboard.
