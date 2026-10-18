# Swing PICO-8

**Beats lofi con swing estilo J Dilla, hechos en una consola portátil. Tres cartuchos de PICO-8 que graban stems para tu DAW.**

## Descripción corta (tagline)

Beats lofi con swing Dilla para PICO-8: batería, teclas y ruido que se graban en stems.

## Texto de la página (pegar en la descripción)

Swing PICO-8 es un pequeño estudio lofi en tres cartuchos de PICO-8:

- **Swing Beats**: batería. 5 pistas × 16 pasos, 3 velocidades por paso, 3 kits (polvo, suave, cinta).
- **Swing Keys**: bajo, lead y acordes escritos por grados de la escala, con cuatriadas diatónicas, reverb, filtro, detune, wobble de cinta y eco sincronizado al tempo.
- **Swing Noise**: texturas de vinilo, cinta, lluvia, fuego, mar y noche, con ducking sincronizado al bombo, fades y aguja de vinilo.

Los tres comparten la misma canción (8 espacios), así que tempo, swing, tono, escala y arreglo quedan sincronizados. Cada cartucho graba su propio stem con un click de conteo: salida de línea a tu interfaz, alineás las tres tomas por el primer click y listo.

### El groove es lo importante

El tiempo Dilla sale de un timing programado: cada voz de la batería tiene sus propios corrimientos y se repiten en cada compás. El swing de acá funciona así:

- Swing de 50 a 75 %, con base de semicorchea o corchea, más **swing por pista**
- **Groove templates** con desfasajes por paso (septillo, snare 5/192, áureo, "borracho"…)
- **Nudge** por pista de −64 a +60 ms, **flam** y **deriva** de frase
- **Humanización** en tres modos: azar, suave (correlacionada, tipo 1/f) o fija (los mismos desfasajes en cada compás)
- Timing con precisión de muestra en el PICO-8 oficial (salida PCM)

Las tomas salen idénticas cada vez, así que los stems siempre coinciden.

### Corre en una consola de US$60

Hecho y probado en la **Anbernic RG CubeXX** con Knulli. La batería consume cerca de 35–40 % de CPU en la consola mientras suena. También corre en PICO-8 de escritorio.

### Qué necesitás

- **PICO-8** oficial (en lexaloffle.com). Es lo recomendado: swing_beats y swing_noise usan salida PCM, que fake-08 no implementa (swing_keys anda en cualquiera; swing_beats cae a un modo "chip" más simple).
- Opcional: cable de salida de línea e interfaz de audio para grabar los stems.

### Qué trae la descarga

- `es/` y `en/`: los tres cartuchos (español e inglés; el idioma también se cambia dentro con X)
- `knulli/`: imágenes, videos de 16 s y `gamelist.xml` para que aparezcan con carátula y descripción en EmulationStation (Knulli, Batocera, ROCKNIX)
- README y licencia (MIT)

Código abierto: https://github.com/santiago-giordano/swing_pico8

Hecho por Santiago Giordano, Buenos Aires.
