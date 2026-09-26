# NEON CAT: Station X — G-7 0.3.0 (arquitectura refactorizada)

Proyecto Godot **4.2.1** para Android. Esta versión conserva el contenido jugable del ZIP base de G-7 0.3.0, pero reemplaza la arquitectura monolítica de `scripts/game.gd` por escenas, nodos nativos y scripts con responsabilidades separadas.

## Contenido que se conserva

- Estación G-7 continua de **8600 px** y sus **9 sectores**.
- Salto, doble salto, disparo y dash con los mismos valores de movimiento.
- Tres pozos, plataformas one-way, rutas elevadas y los tres secretos.
- Checkpoints, mapa persistente, pausa y tranvía bidireccional.
- Vestíbulos de **Minas Bioluminosas** y **Fábrica Omega**, conservando el estado de G-7 al entrar y volver.
- Patrulleros, trenes, torretas, drones y Sentinel-G7.
- Sentinel con **10 HP**, dos fases y los mismos tres patrones/tiempos de ataque.
- Guardado **v3** y migración desde guardados v1/v2.
- Controles táctiles Android y controles de teclado existentes.
- Resolución lógica **960 × 540** y orientación horizontal.
- Todos los archivos existentes bajo `assets/` sin modificaciones.

## Arquitectura

La escena principal sigue siendo:

```text
res://scenes/game.tscn
```

Responsabilidades principales:

- `game/game_manager.gd`: flujo general, salas, señales, UI y coordinación.
- `player/`: `CharacterBody2D`, movimiento, animación y efectos del Astro-Gato.
- `projectiles/`: proyectiles del jugador y enemigos mediante `Area2D`.
- `enemies/`: una escena por familia de enemigo y una base común.
- `bosses/sentinel/`: Sentinel y sus fases separadas.
- `world/station_g7/sectors/`: los 9 sectores como escenas editables visualmente.
- `world/shared/`: plataformas, límites, checkpoints, pickups, gates y terminales reutilizables.
- `ui/`: HUD, mapa, pausa y controles táctiles separados.
- `autoload/save_system.gd`: único Autoload nuevo; guarda, carga, valida y migra saves.

El antiguo `scripts/game.gd` ya no forma parte del proyecto.

Consulta `docs/ARQUITECTURA_REFACTORIZADA.md` para el mapa completo de responsabilidades.

## Controles

### PC

- A/D o flechas: mover.
- Espacio, W o ↑: salto / doble salto.
- J o Z: disparar.
- Shift: dash cuando esté desbloqueado.
- E: usar terminal.
- M: mapa.
- P o Esc: pausa.

### Android

Se conservan los botones táctiles de izquierda, derecha, dash, salto, fuego y usar, además de MAPA y PAUSA. Admiten multitouch mediante acciones de `InputMap`.

## Guardado

Ruta:

```text
user://station_g7_save.json
```

Versión actual: **3**.

Se conservan checkpoint, Sentinel derrotado/dash, secreto inicial, rutas secretas, sectores visitados, finalización de G-7, puntuación y preferencia de audio. `SaveSystem` mantiene compatibilidad con v1 y v2, incluido el caso histórico de checkpoint `2420 → 6550` tras Sentinel.

## Pruebas de regresión

`tests/test_station.gd` conserva las **24 verificaciones** de la línea base, con los mismos nombres y valores esperados, adaptando solamente dónde vive ahora cada dato/comportamiento.

Ejecución local equivalente:

```bash
NEON_TEST_RUN=1 XDG_DATA_HOME=/tmp/neon-test-data godot --headless --path . --script res://tests/test_station.gd
```

El resultado esperado es:

```text
24 líneas PASS
RESULT: 0 failures
```

`.github/workflows/android.yml` importa el proyecto con Godot 4.2.1, comprueba que arranca, ejecuta esas 24 pruebas, exporta el APK y verifica la orientación del manifiesto antes de publicar el artefacto.

**Importante:** `docs/pruebas_godot_4_2_1.txt` es el log de referencia de la versión base anterior al refactor. El refactor debe considerarse validado únicamente cuando tu nuevo Action produzca nuevamente `24 PASS / 0 failures` y completes la prueba manual del APK.

## APK horizontal

Los presets de `export_presets.cfg` se conservaron sin cambios respecto al ZIP base. El Action genera `build/NEON_CAT_STATION_X.apk` y ejecuta:

```bash
python3 tools/verify_apk.py build/NEON_CAT_STATION_X.apk
```

La comprobación exige `screenOrientation=0` (landscape) para `GodotApp`.

## Verificación manual

Después de que el Action quede verde, sigue los 15 puntos de:

```text
docs/CHECKLIST_MANUAL_ANDROID.md
```

## Cómo agregar contenido nuevo

Consulta:

```text
docs/COMO_AGREGAR_CONTENIDO.md
```

La regla principal es mantener cada responsabilidad en su escena/script correspondiente y no volver a centralizar gameplay en un único archivo.

## Sentinel-G7: animaciones y audio integrados

El jefe utiliza `AnimatedSprite2D` con recursos separados para caminata, daño, disparo, descarga vertical, transición a fase 2, núcleo expuesto y muerte. Las imágenes de producción están en `assets/bosses/sentinel/`; las hojas originales aprobadas se conservan en `docs/sentinel_sources/` y no se exportan al APK.

Los eventos del jefe usan nombres de sonido semánticos (`sentinel_shot`, `sentinel_phase2`, etc.) que `audio/station_audio.gd` resuelve hacia los WAV existentes, por lo que no se duplican archivos de audio. Consulta `docs/SENTINEL_INTEGRACION.md` para el mapeo exacto de estados, animaciones y sonidos.
