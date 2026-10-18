# swing_pico8

[![ci](https://github.com/santiago-giordano/swing_pico8/actions/workflows/ci.yml/badge.svg)](https://github.com/santiago-giordano/swing_pico8/actions/workflows/ci.yml) [![release](https://img.shields.io/github/v/release/santiago-giordano/swing_pico8)](https://github.com/santiago-giordano/swing_pico8/releases/latest) [![license: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

*[Read in English](README.md)*

Tres cartuchos de PICO-8 para armar y grabar **lofi por stems**, pensados para consolas de mano (el diseño está probado para la Anbernic RG CubeXX, de pantalla cuadrada):

| Cartucho | Qué hace |
|---|---|
| `swing_beats.p8` | Batería por PCM: 5 pistas, swing con precisión de muestra (estilo MPC y grooves por pista estilo Dilla), nudge por pista, 3 kits, color, saturación, sala y crush |
| `swing_keys.p8` | Bajo, lead y acordes por grados de la escala, con reverb, filtro, detune, wobble y eco sincronizado por instrumento |
| `swing_noise.p8` | Ambiente por PCM: vinilo, cinta, lluvia, fuego, mar y noche, con presets, ducking con el bombo, fades y aguja de vinilo |

Los tres comparten un **archivo de canción** con tempo, swing, tono, escala y arreglo. Cada cartucho graba su stem empezando con un compás de click de conteo, para alinear las tomas en el DAW.

![los tres cartuchos](docs/swing_lofi.png)

## Escuchá

<img src="docs/demo.gif" width="256" align="right" alt="swing_beats sonando">

Renderizado con el banco de pruebas (el mismo camino PCM del PICO-8 oficial), canción por defecto a 82 BPM:

- [Mezcla completa, groove "borracho"](docs/audio/5_mezcla_borracho.mp3): los stems de beats, keys y noise sumados
- Batería sola, mismo patrón, cuatro grooves:
  [MPC 62 %](docs/audio/1_mpc62_sin_groove.mp3) ·
  [septillo](docs/audio/2_septillo.mp3) ·
  [snare 5/192 adelantada](docs/audio/3_snare_5-192.mp3) ·
  [borracho](docs/audio/4_borracho.mp3)

Las diferencias entre grooves son de 20 a 70 ms: escuchalos seguidos y con auriculares.

<br clear="right">

## Instalación

Bajá el zip del [último release](https://github.com/santiago-giordano/swing_pico8/releases/latest) (o cloná el repo). Copiá una de las carpetas de idioma a la carpeta de cartuchos de PICO-8 (`roms/pico8` en Knulli):

- `carts/es/`: arranca en español
- `carts/en/`: arranca en inglés

En cualquiera de las dos se cambia el idioma con **X** en la pantalla de elegir canción.

### ¿Qué PICO-8?

| Motor | beats | keys | noise |
|---|---|---|---|
| PICO-8 oficial (0.2.4+) | completo (PCM) | completo | completo |
| fake-08 (el de Knulli por defecto) | modo "chip" de respaldo | completo | sin sonido |

La batería y los ruidos usan el canal PCM de PICO-8 (`serial(0x808)`), que fake-08 no implementa. En Knulli el oficial se instala desde *Device Settings → Install Pico-8*; después elegí el emulador **LEXALOFFLE: PICO8 OFFICIAL**. Más detalles en la [documentación de Knulli](https://knulli.org/systems/pico-8).

## Controles (iguales en los tres)

| Acción | Control |
|---|---|
| Mover el cursor | D-pad |
| Acción sobre la celda o el ítem (activar, escuchar) | tocar **O** |
| Ajustar un valor | mantener **O** + flechas |
| Play / stop | tocar **X** |
| Cambiar de página | mantener **X** + ← → |
| Patrón A–D | mantener **X** + ↑ ↓ |
| Grabar, copiar/pegar/borrar patrón, cambiar canción | menú de pausa |

## Canciones

- Al abrir un cartucho elegís la canción, de c1 a c8. **Elegí la misma en los tres.**
- Cada canción es un archivo de cartdata, `swingbox_cancionN.p8d.txt`, en la carpeta `cdata` de PICO-8. Copiando ese archivo respaldás o compartís la canción entera.
- En la página **canción** se configuran BPM, swing, tono, escala, largo del arreglo, click de conteo y modo (loop o cadena). El arreglo tiene 16 bloques. Cada bloque elige un patrón de beats (letra de arriba) y uno de keys (letra de abajo), y se repite de ×1 a ×8. Cada parte se puede silenciar por bloque para hacer breaks.

## Groove: timing estilo Dilla

El feel "borracho" de J Dilla no es más swing ni más azar: cada voz de la batería va en su propia rejilla al mismo tiempo (hats rectos, snare apurada, bombo que arrastra) y los corrimientos se repiten iguales en cada compás. La página **groove** de swing_beats lo modela así:

| Control | Qué hace |
|---|---|
| swg / base | Swing de la canción, 50–75%. Base 16 retrasa las semicorcheas impares (MPC); base 8 retrasa la corchea débil y las semicorcheas del medio la siguen. Valores tuplet: 57% ≈ septillo, 60% quintillo, 62% ≈ áureo, 66% tresillo |
| sw (por pista) | Swing propio de cada voz; `--` sigue el de la canción |
| nudge | Corre toda la pista de −64 a +60 ms (entran las snares adelantadas: los eventos se programan con 100 ms de anticipación) |
| fl | Flam: un golpe ghost 10/20/30 ms antes de cada golpe medio o fuerte |
| grv | Groove template: offsets por paso en 1/48 de paso, así escalan con el tempo. **Tocando O** se aplica su preset (swing por pista, flam, humanización y deriva; los nudges vuelven a 0) |
| deriva | El swing crece 0–3% por compás en las pistas con swing y vuelve cada 4 compases |
| hum | 0–15 ms, modo **azar** (ruido blanco), **suave** (AR(1) correlacionado, más parecido a cómo deriva un baterista) o **fijo** (los mismos microdesfasajes en cada compás) |

Templates: ninguno, get dis (backbeat −4/48 y dos hats tarde), septillo (backbeat −1/64), 5/192 (snare 5/192 de compás antes, ≈ 69 ms a 90 BPM), quint (hats +0,4 paso), áureo, apurado (snare −1/4 de paso) y borracho. Son puntos de partida para escuchar, no valores medidos de Dilla.

Keys y noise siguen el swing de la canción; el ducking de noise sigue el timing de la pista de bombo. En keys el nudge por instrumento va de −64 a +60 ms (sirve para un bajo atrás del beat).

## Grabar por la salida de línea

1. Conectá la salida de auriculares a la interfaz o grabadora.
2. En cada cartucho: *Pausa → grabar canción*. Suena un compás de clicks (el primero más agudo), después el arreglo una vez, y se detiene solo.
3. En el DAW, alineá las tres tomas por el primer click y cortá el conteo. La humanización usa una semilla fija por canción, así que cada toma suena igual.

## Desarrollo

```
python3 build.py               # src/*.lua -> carts/{es,en}/*.p8; falla si un cartucho pasa los límites de PICO-8
bash tests/setup.sh            # compila fake-08 (libretro) + un frontend sin pantalla
bash tests/run_all.sh          # build + todos los tests de abajo
python3 tests/test_timing.py   # precisión de swing y nudge midiendo el audio
python3 tests/test_groove.py   # swing por pista, templates, flam, deriva, modos de humanización
python3 tests/test_sync.py     # graba los 3 stems y verifica que queden alineados
python3 tests/test_live_edit.py   # editar kit o afinación sonando no debe colgarse
python3 tests/screens.py       # capturas de todas las páginas -> docs/
```

- La CI (GitHub Actions) corre el chequeo de build y todos los tests en cada push. Al subir un tag `v*` se publica un release con el zip de cartuchos y la entrada correspondiente del CHANGELOG.
- `src/core.lua` es común a los tres cartuchos: canción, secuenciador, reloj de audio, input, páginas y paleta.
- Los tests corren los cartuchos en fake-08 con un **parche solo para pruebas** que agrega el canal PCM (`tests/fake08-test.patch`). Así se puede grabar a WAV y medir el sonido que daría el PICO-8 oficial.
- La CPU en el PICO-8 oficial está estimada, no medida en la consola: entre 15 y 26% para beats y entre 22 y 46% para noise con todo al máximo. Para chequearla en tu equipo, las páginas kit y fx muestran la CPU.

## Licencia

[MIT](LICENSE). `tests/fake08-test.patch` modifica [fake-08](https://github.com/jtothebell/fake-08), que también es MIT. PICO-8 es un producto de Lexaloffle Games; este proyecto no está afiliado a ellos.
