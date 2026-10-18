// minimal libretro frontend for headless testing of pico-8 carts via fake-08
// usage: front core.so cart.p8 script.txt outdir
// script lines:
//   w N MASK      run N frames holding MASK (bits: 1=L 2=R 4=U 8=D 16=O 32=X 64=START)
//   shot NAME     save current frame to outdir/NAME.ppm
//   wav NAME      start capturing audio to outdir/NAME.wav (until end/wavend)
//   wavend        stop audio capture
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include "libretro.h"

static uint16_t fb[256*256];
static unsigned fbw, fbh;
static int mask = 0;
static FILE *wav = NULL;
static long wavframes = 0;
static char outdir[512];
static char sysdir[512];

static bool env(unsigned cmd, void *data) {
  switch (cmd) {
    case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
      *(const char **)data = sysdir; return true;
    case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT: return true;
    case RETRO_ENVIRONMENT_GET_CAN_DUPE: *(bool*)data = true; return true;
    case RETRO_ENVIRONMENT_GET_LOG_INTERFACE: return false;
    case RETRO_ENVIRONMENT_GET_VARIABLE: return false;
    default: return false;
  }
}
static void video(const void *data, unsigned w, unsigned h, size_t pitch) {
  if (!data) return;
  fbw = w; fbh = h;
  for (unsigned y = 0; y < h; y++)
    memcpy(fb + y*w, (const uint8_t*)data + y*pitch, w*2);
}
static void audio1(int16_t l, int16_t r) {}
static size_t audiob(const int16_t *d, size_t frames) {
  if (wav) { fwrite(d, 4, frames, wav); wavframes += frames; }
  return frames;
}
static void poll(void) {}
static int16_t state(unsigned port, unsigned dev, unsigned idx, unsigned id) {
  if (port || dev != RETRO_DEVICE_JOYPAD) return 0;
  switch (id) {
    case RETRO_DEVICE_ID_JOYPAD_LEFT: return (mask & 1) != 0;
    case RETRO_DEVICE_ID_JOYPAD_RIGHT: return (mask & 2) != 0;
    case RETRO_DEVICE_ID_JOYPAD_UP: return (mask & 4) != 0;
    case RETRO_DEVICE_ID_JOYPAD_DOWN: return (mask & 8) != 0;
    case RETRO_DEVICE_ID_JOYPAD_B: return (mask & 16) != 0;
    case RETRO_DEVICE_ID_JOYPAD_A: return (mask & 32) != 0;
    case RETRO_DEVICE_ID_JOYPAD_START: return (mask & 64) != 0;
  }
  return 0;
}
static void wavhdr(FILE *f, long frames) {
  uint32_t datasz = frames * 4;
  fseek(f, 0, SEEK_SET);
  fwrite("RIFF", 1, 4, f); uint32_t v = 36 + datasz; fwrite(&v, 4, 1, f);
  fwrite("WAVEfmt ", 1, 8, f); v = 16; fwrite(&v, 4, 1, f);
  uint16_t s = 1; fwrite(&s, 2, 1, f); s = 2; fwrite(&s, 2, 1, f);
  v = 22050; fwrite(&v, 4, 1, f); v = 22050*4; fwrite(&v, 4, 1, f);
  s = 4; fwrite(&s, 2, 1, f); s = 16; fwrite(&s, 2, 1, f);
  fwrite("data", 1, 4, f); fwrite(&datasz, 4, 1, f);
}
static void closewav(void) {
  if (!wav) return;
  wavhdr(wav, wavframes); fclose(wav); wav = NULL;
}

int main(int argc, char **argv) {
  if (argc < 5) { fprintf(stderr, "usage\n"); return 1; }
  strcpy(outdir, argv[4]);
  snprintf(sysdir, sizeof sysdir, "%s/sys", outdir);
  void *h = dlopen(argv[1], RTLD_NOW);
  if (!h) { fprintf(stderr, "%s\n", dlerror()); return 1; }
#define L(n) typeof(&n) p_##n = dlsym(h, #n)
  L(retro_init); L(retro_set_environment); L(retro_set_video_refresh);
  L(retro_set_audio_sample); L(retro_set_audio_sample_batch);
  L(retro_set_input_poll); L(retro_set_input_state); L(retro_load_game);
  L(retro_run); L(retro_deinit); L(retro_unload_game);
  p_retro_set_environment(env);
  p_retro_init();
  p_retro_set_video_refresh(video);
  p_retro_set_audio_sample(audio1);
  p_retro_set_audio_sample_batch(audiob);
  p_retro_set_input_poll(poll);
  p_retro_set_input_state(state);
  struct retro_game_info gi = {0};
  gi.path = argv[2];
  FILE *cf = fopen(argv[2], "rb");
  fseek(cf, 0, SEEK_END); long sz = ftell(cf); fseek(cf, 0, SEEK_SET);
  void *buf = malloc(sz); fread(buf, 1, sz, cf); fclose(cf);
  gi.data = buf; gi.size = sz;
  if (!p_retro_load_game(&gi)) { fprintf(stderr, "load failed\n"); return 1; }
  FILE *sc = fopen(argv[3], "r");
  char line[512];
  long fr = 0;
  while (fgets(line, sizeof line, sc)) {
    char cmd[32], arg[400]; int n, m;
    if (sscanf(line, "w %d %d", &n, &m) == 2) {
      mask = m;
      for (int i = 0; i < n; i++) { p_retro_run(); fr++; }
    } else if (sscanf(line, "shot %s", arg) == 1) {
      char p[1024]; snprintf(p, sizeof p, "%s/%s.ppm", outdir, arg);
      FILE *f = fopen(p, "wb");
      fprintf(f, "P6 %u %u 255\n", fbw, fbh);
      for (unsigned i = 0; i < fbw*fbh; i++) {
        uint16_t c = fb[i];
        unsigned char rgb[3] = { (c >> 11) << 3, ((c >> 5) & 63) << 2, (c & 31) << 3 };
        fwrite(rgb, 1, 3, f);
      }
      fclose(f);
    } else if (strncmp(line, "wavend", 6) == 0) {
      closewav();
    } else if (sscanf(line, "wav %s", arg) == 1) {
      closewav();
      char p[1024]; snprintf(p, sizeof p, "%s/%s.wav", outdir, arg);
      wav = fopen(p, "wb"); wavframes = 0; wavhdr(wav, 0);
    } else if (strncmp(line, "wavend", 6) == 0) {
      closewav();
    }
  }
  closewav();
  p_retro_unload_game();
  p_retro_deinit();
  fprintf(stderr, "ran %ld frames\n", fr);
  return 0;
}
