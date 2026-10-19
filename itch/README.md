# itch.io kit

Everything to publish swing_pico8 on itch.io with your own account.

| File | Use |
|---|---|
| `cover.png` | Cover image (630×500, itch's recommended size) |
| `screenshots/` | Upload in this order: `swing_beats.png`, `swing_keys.png`, `swing_noise.png`, `swing_mix.png`, `all_pages.png` |
| `swing_pico8_v2.5.0.zip` | The download (same as the GitHub release) |
| `PAGE.en.md`, `PAGE.es.md` | Tagline, description and metadata to paste |

## Steps

1. itch.io → Dashboard → **Create new project**.
2. Title `Swing PICO-8`, URL `swing-pico8`. Paste the tagline and description (English first; add Spanish below it, itch has no per-language page).
3. Kind of project: Downloadable. Fill pricing and tags from the bottom of `PAGE.en.md`.
4. Upload the zip, tick Windows / macOS / Linux.
5. Cover image + screenshots. For video, paste a YouTube link of the CubeXX recording (itch doesn't host mp4 on the page).
6. Save as **Draft**, preview, then set Visibility to Public.

## Updating

When a new release goes out, rebuild with `python3 tools/itch.py`, grab the new zip from the release and upload it with `butler push` or from the dashboard.
