# NEON CAT: Station X — prototipo

Primer nivel jugable inspirado en el mapa conceptual: Estación G-7. Incluye al Astro-Gato de la hoja de poses proporcionada, salto, disparo, enemigos patrulla, energía, puntos de control y el jefe Guardián G-7. El resto del escenario y los enemigos se dibujan directamente en Godot como arte provisional. Las ocho zonas del mapa son una guía de desarrollo; solo la primera está implementada.

## Personaje principal

La imagen `assets/astro_gato.jpg` contiene seis poses. `scripts/game.gd` selecciona regiones de la imagen para quieto, caminar, saltar, disparar y dash, y voltea al personaje al mirar a la izquierda. El shader `shaders/remove_green.gdshader` vuelve transparente el fondo verde durante el juego. La estela de dash usa copias breves de la misma pose. Se mantiene la física existente; la imagen cambia su aspecto, no las colisiones. Es una primera integración: las poses proceden de una imagen JPEG con fondo verde y pueden mostrar bordes de color; para arte final conviene una hoja de sprites PNG con transparencia y cuadros uniformes.

## Primer ciclo de juego

Explora la estación, elimina enemigos y llega al Guardián G-7. Antes de cada ataque, el jefe muestra su nombre y un aviso naranja. Alterna tres patrones: disparos en abanico, onda baja que se salta y descargas verticales. **Tras cada ataque el núcleo del centro se ilumina: dispárale entonces**; el blindaje bloquea los disparos cuando el núcleo está apagado. Al vencerlo se desbloquea el dash. Úsalo para atravesar la compuerta violeta y alcanzar la salida. El juego guarda un punto de control antes del jefe y otro al vencerlo.

## Sala de prueba y regreso

El recorrido mide unas cuatro pantallas. En la primera se ve un **ítem verde** sobre una plataforma elevada, encerrado entre dos barreras violetas. Puedes seguir por debajo hacia el enemigo patrullero, el tren de tres vagones y el jefe. Al vencer al jefe, vuelve a la primera pantalla y cruza la barrera superior con el dash: el ítem aumenta tu vida máxima en uno. Luego vuelve a la derecha, atraviesa la compuerta final con dash y llega a la salida. El ítem es opcional. Cada dash deja una estela verde breve y el círculo verde del HUD muestra cuándo se recarga.

## Controles

- Android: botones visibles de izquierda, derecha, dash, salto y fuego. Admite varios dedos a la vez. El dash empieza bloqueado y se habilita tras el jefe.
- Computador: A/D o flechas para moverse, espacio para saltar, J o Z para disparar, Shift para dash.

## Descargar el APK de prueba

1. Abre la pestaña **Actions** de este repositorio.
2. Abre la última ejecución **Godot Android Export** cuyo resultado sea verde.
3. En **Artifacts**, descarga **NEON_CAT_STATION_X-APK**.
4. Descomprime el ZIP que entrega GitHub e instala `NEON_CAT_STATION_X.apk` en Android.

El APK es de prueba y no está preparado para publicar en Google Play. Todavía no contiene anuncios ni compras. El flujo comprueba que el archivo existe y es un ZIP/APK válido; si falla, la ejecución aparece en rojo.
