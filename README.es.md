# swing_pico8

[![ci](https://github.com/santiago-giordano/swing_pico8/actions/workflows/ci.yml/badge.svg)](https://github.com/santiago-giordano/swing_pico8/actions/workflows/ci.yml) [![release](https://img.shields.io/github/v/release/santiago-giordano/swing_pico8)](https://github.com/santiago-giordano/swing_pico8/releases/latest) [![license: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

*[Read in English](README.md)*

Cuatro cartuchos de PICO-8 para armar y grabar **lofi por stems**, pensados para consolas de mano (el diseño está probado para la Anbernic RG CubeXX, de pantalla cuadrada):

| Cartucho | Qué hace |
|---|---|
| `swing_beats.p8` | Batería por PCM: 5 pistas, swing con precisión de muestra (estilo MPC y grooves por pista estilo Dilla), nudge por pista, 4 kits, recorte de inicio por pista, una pista polirrítmica, color, saturación, sala y crush |
| `swing_keys.p8` | Bajo, lead y acordes por grados de la escala, con reverb, filtro, detune, wobble y eco sincronizado por instrumento |
| `swing_noise.p8` | Ambiente por PCM: vinilo, cinta, lluvia, fuego, mar y noche, con presets, ducking con el bombo, fades y aguja de vinilo |
| `swing_mix.p8` | Reproduce las tres partes juntas para escuchar la canción completa, con nivel, mute y solo por stem; también graba la mezcla |

Los cuatro comparten un **archivo de canción** con tempo, swing, tono, escala y arreglo. Cada cartucho graba su stem empezando con un compás de click de conteo, para alinear las tomas en el DAW.

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

### Imágenes y videos en la lista (Knulli / Batocera)

La carpeta `knulli/` trae la metadata para que los tres cartuchos aparezcan con descripción, captura y video en la lista de PICO-8:

1. Copiá `knulli/images/` y `knulli/videos/` dentro de `roms/pico8/` (quedan `roms/pico8/images/…` y `roms/pico8/videos/…`).
2. Si **no** tenés `roms/pico8/gamelist.xml`, copiá `knulli/gamelist.xml` ahí (o `gamelist.en.xml` renombrado, para la versión en inglés).
3. Si **ya** tenés uno (por haber scrapeado otros juegos), abrilo y pegá los tres bloques `<game>…</game>` de `knulli/gamelist.xml` antes de `</gameList>`.
4. Start → *Game Settings → Update Gamelists*.

Hacelo con la interfaz de Knulli cerrada o reiniciala después: EmulationStation reescribe el gamelist al salir.

### ¿Qué PICO-8?

| Motor | beats | keys | noise |
|---|---|---|---|
| PICO-8 oficial (0.2.4+) | completo (PCM) | completo | completo |
| fake-08 (el de Knulli por defecto) | modo "chip" de respaldo | completo | sin sonido |

La batería y los ruidos usan el canal PCM de PICO-8 (`serial(0x808)`), que fake-08 no implementa. En Knulli el oficial se instala desde *Device Settings → Install Pico-8*; después elegí el emulador **LEXALOFFLE: PICO8 OFFICIAL**. Más detalles en la [documentación de Knulli](https://knulli.org/systems/pico-8).

## Controles (iguales en los cuatro)

| Acción | Control |
|---|---|
| Mover el cursor | D-pad |
| Acción sobre la celda o el ítem (activar, escuchar) | tocar **O** |
| Ajustar un valor | mantener **O** + flechas |
| Play / stop | tocar **X** |
| Cambiar de página | mantener **X** + ← → |
| Patrón A–D | mantener **X** + ↑ ↓ |
| Duplicar | mantener **X** y tocar **O**: en la grilla de un patrón lo copia a la letra siguiente (solo si está vacía) y va ahí; sobre un bloque de la página canción inserta una copia a continuación |
| Grabar, copiar/pegar/borrar patrón, cambiar canción | menú de pausa |

## Canciones

- Al abrir un cartucho elegís la canción, de c1 a c8. **Elegí la misma en los tres.**
- Cada canción es un archivo de cartdata, `swingbox_cancionN.p8d.txt`, en la carpeta `cdata` de PICO-8. Copiando ese archivo respaldás o compartís la canción entera.
- En la página **canción** se configuran BPM, swing, tono, escala, largo del arreglo, click y modo (loop o cadena). **click**: *no*; *rec* = un compás de conteo solo al grabar (por defecto); *met* = el mismo conteo más un metrónomo en cada tiempo mientras tocás, nunca en la grabación. En swing_keys el metrónomo comparte canal con los acordes, así que puede cortar la 7.ª del acorde en cada tiempo. El arreglo tiene 16 bloques. Cada bloque elige un patrón de beats (letra de arriba) y uno de keys (letra de abajo), y se repite de ×1 a ×8. Cada parte se puede silenciar por bloque para hacer breaks. **relleno** (swing_beats y swing_mix): en el último compás de cada bloque que se repite ×2 o más suma un hat abierto en el paso 16 (*hat*), un redoble de caja en los pasos 13–16 (*caja*) o ambos; también queda en las grabaciones, y los bloques que suenan una vez no llevan relleno. **poli** (swing_beats y swing_mix): una pista por canción (k, s, r, h u o) corre en su propia grilla de 12 (tresillos de corchea), 10 (quintillos de corchea), 14 (septillos de corchea) u 8 celdas por compás, contra las 16 rectas de las demás. O+←→ elige la pista, O+↑↓ la grilla. En la página patrón esa fila muestra menos celdas, más anchas. El nudge y la humanización siguen valiendo; el swing, los templates de groove y el relleno no. **ref bat** (swing_keys): hace sonar la batería de la canción debajo de las teclas mientras tocás, para escribir contra el groove. Se apaga al grabar, así el stem de keys queda limpio; las notas de keys se demoran lo que tarda el PCM (~100 ms) para quedar a tiempo con la batería, y necesita el PICO-8 oficial (en fake-08 no hace nada).

## Groove: timing estilo Dilla

El feel "borracho" de J Dilla sale de que cada voz de la batería va en su propia rejilla al mismo tiempo (hats rectos, snare apurada, bombo que arrastra), con corrimientos que se repiten iguales en cada compás. La página **groove** de swing_beats lo modela así:

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

La página **kit** de swing_beats tiene cuatro kits (polvo, suave, cinta y boom, este último con bombo y caja más pegadores en medios), afinación, color, saturación, sala y crush. **trim** (un valor por pista, 0–3, unos 3 ms por paso) salta el comienzo del sonido, así el ataque cae antes y más seco; sirve junto con el nudge para ubicar sonidos de ataque blando.

## Grabar por la salida de línea

1. Conectá la salida de auriculares a la interfaz o grabadora.
2. En cada cartucho: *Pausa → grabar canción*. Suena un compás de clicks (el primero más agudo), después el arreglo una vez, y se detiene solo.
3. En el DAW, alineá las tres tomas por el primer click y cortá el conteo. La humanización usa una semilla fija por canción, así que cada toma suena igual.

## Escuchar todo junto: swing_mix

Ningún cartucho guarda audio: cada uno guarda su parte de la partitura (pasos, notas, kit, groove, niveles) en el archivo de canción, y el sonido se genera al dar play. `swing_mix` lee esas tres partes de la misma canción y las hace sonar juntas. Como PICO-8 corre un cartucho a la vez, lleva adentro los tres motores: batería y ruido por PCM, teclas por los canales de chip. Abrí la misma canción, tocá X y reproduce el arreglo (o el patrón A–D en modo loop).

- Página **mezcla**: por stem, un fader (O+↑↓), un medidor y **M**ute / **S**olo (tocar O), más la opción **parlante** (es la misma de swing_beats: cambia el bombo de la canción para los dos). Los niveles se guardan en la canción. Solo afectan a swing_mix; los stems que grabás desde cada cartucho no cambian.
- Página **canción**: tempo, swing, tono y modo. El arreglo acá es de solo lectura; se edita en beats o keys.
- *Pausa → grabar mezcla* graba la mezcla completa con el mismo conteo, por si querés una toma rápida por la salida de línea.
- Si la CPU queda por encima de ~88 % sonando, el ruido pasa a media tasa hasta el próximo stop (la página muestra *ruido 1/2*). La batería mantiene siempre la calidad completa.
- Las teclas se disparan una vez por cuadro, así que en la mezcla pueden quedar hasta un cuadro (~16 ms) corridas de la batería. Los stems grabados no se ven afectados. En los modos de humanización *azar* y *suave*, la mezcla sortea corrimientos distintos a los de los stems, con el mismo carácter; en *fijo* coinciden.

## Desarrollo

```
python3 build.py               # src/*.lua -> carts/{es,en}/*.p8; falla si un cartucho pasa los límites de PICO-8
bash tests/setup.sh            # compila fake-08 (libretro) + un frontend sin pantalla
bash tests/run_all.sh          # build + todos los tests de abajo
python3 tools/media.py         # regenera knulli/ (imágenes, videos y gamelist para el scraper)
python3 tests/test_timing.py   # precisión de swing y nudge midiendo el audio
python3 tests/test_groove.py   # swing por pista, templates, flam, deriva, modos de humanización
python3 tests/test_sync.py     # graba los 3 stems y verifica que queden alineados
python3 tests/test_live_edit.py   # editar kit o afinación sonando no debe colgarse
python3 tests/screens.py       # capturas de todas las páginas -> docs/
```

- La CI (GitHub Actions) corre el chequeo de build y todos los tests en cada push. Al subir un tag `v*` se publica un release con el zip de cartuchos y la entrada correspondiente del CHANGELOG.
- `src/core.lua` es común a los tres cartuchos: canción, secuenciador, reloj de audio, input, páginas y paleta.
- Los tests corren los cartuchos en fake-08 con un **parche solo para pruebas** que agrega el canal PCM (`tests/fake08-test.patch`). Así se puede grabar a WAV y medir el sonido que daría el PICO-8 oficial.
- Parlante: el de una consola portátil no reproduce el cuerpo del bombo (50–160 Hz). La opción **parlante** de la página kit (activada por defecto) le suma un golpe corto en medios y saturación para que se siga oyendo como bombo. Con auriculares o por la salida de línea podés apagarla y queda un bombo más redondo. En swing_keys, la página sonido tiene otra opción **parlante** para el bajo (activada por defecto): las notas por debajo de mi3 (~160 Hz) suben una octava, porque ese parlante no las reproduce; en swing_mix el bajo sigue la opción de la página mezcla. Al parar, la sala se apaga del todo: cuando terminan las voces y la cola, se vacían sus buffers.
- CPU: en una Anbernic RG CubeXX (Knulli, PICO-8 oficial) swing_beats midió alrededor de 35–40 % sonando. La de swing_noise sigue estimada (22–46 % con todas las capas al máximo). Las páginas kit y fx muestran la CPU.

## Licencia

[MIT](LICENSE). `tests/fake08-test.patch` modifica [fake-08](https://github.com/jtothebell/fake-08), que también es MIT. PICO-8 es un producto de Lexaloffle Games; este proyecto no está afiliado a ellos.
