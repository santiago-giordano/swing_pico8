# swing_pico8

*[Read in English](README.md)*

Tres cartuchos de PICO-8 para armar y grabar **lofi por stems**, pensados para consolas de mano (el diseño está probado para la Anbernic RG CubeXX, de pantalla cuadrada):

| Cartucho | Qué hace |
|---|---|
| `swing_beats.p8` | Batería por PCM: 5 pistas, swing estilo MPC con precisión de muestra, nudge por pista, 3 kits, color, saturación, sala y crush |
| `swing_keys.p8` | Bajo, lead y acordes por grados de la escala, con reverb, filtro, detune, wobble y eco sincronizado por instrumento |
| `swing_noise.p8` | Ambiente por PCM: vinilo, cinta, lluvia, fuego, mar y noche, con presets, ducking con el bombo, fades y aguja de vinilo |

Los tres comparten un **archivo de canción** con tempo, swing, tono, escala y arreglo. Cada cartucho graba su stem empezando con un compás de click de conteo, para alinear las tomas en el DAW.

![los tres cartuchos](docs/swing_lofi.png)

## Instalación

Copiá una de las carpetas de idioma a la carpeta de cartuchos de PICO-8 (`roms/pico8` en Knulli):

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

## Grabar por la salida de línea

1. Conectá la salida de auriculares a la interfaz o grabadora.
2. En cada cartucho: *Pausa → grabar canción*. Suena un compás de clicks (el primero más agudo), después el arreglo una vez, y se detiene solo.
3. En el DAW, alineá las tres tomas por el primer click y cortá el conteo. La humanización usa una semilla fija por canción, así que cada toma suena igual.

## Desarrollo

```
python3 build.py               # src/*.lua -> carts/{es,en}/*.p8 (y cuenta tokens)
bash tests/setup.sh            # compila fake-08 (libretro) + un frontend sin pantalla
python3 tests/test_timing.py   # precisión de swing y nudge midiendo el audio
python3 tests/test_sync.py     # graba los 3 stems y verifica que queden alineados
python3 tests/screens.py       # capturas de todas las páginas -> docs/
```

- `src/core.lua` es común a los tres cartuchos: canción, secuenciador, reloj de audio, input, páginas y paleta.
- Los tests corren los cartuchos en fake-08 con un **parche solo para pruebas** que agrega el canal PCM (`tests/fake08-test.patch`). Así se puede grabar a WAV y medir el sonido que daría el PICO-8 oficial.
- La CPU en el PICO-8 oficial está estimada, no medida en la consola: entre 15 y 26% para beats y entre 22 y 46% para noise con todo al máximo. Para chequearla en tu equipo, las páginas kit y fx muestran la CPU.

## Licencia

[MIT](LICENSE). `tests/fake08-test.patch` modifica [fake-08](https://github.com/jtothebell/fake-08), que también es MIT. PICO-8 es un producto de Lexaloffle Games; este proyecto no está afiliado a ellos.
