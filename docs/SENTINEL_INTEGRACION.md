# Sentinel-G7 — Integración visual y de audio

## Archivos de producción

- `bosses/sentinel/sentinel.tscn`
- `bosses/sentinel/sentinel.gd`
- `bosses/sentinel/sentinel_sprite_frames.tres`
- `assets/bosses/sentinel/sentinel_idle_core.png`
- `assets/bosses/sentinel/sentinel_walk.png`
- `assets/bosses/sentinel/sentinel_hit.png`
- `assets/bosses/sentinel/sentinel_shoot.png`
- `assets/bosses/sentinel/sentinel_vertical_attack.png`
- `assets/bosses/sentinel/sentinel_phase_transition.png`
- `assets/bosses/sentinel/sentinel_death.png`

Las hojas originales aprobadas están en `docs/sentinel_sources/`. El script `tools/generate_sentinel_assets.py` normaliza escala, ancla los pies y genera las hojas usadas por Godot.

## Mapeo de gameplay a animación

- Patrulla: `walk` a 7 FPS.
- Abanico / onda: `shoot_charge` durante el windup y `shoot_release` al ejecutar el ataque.
- Descarga vertical: `vertical_charge` durante el windup y `vertical_release` al crear las columnas.
- Núcleo vulnerable: `core_open` seguido de `core_exposed`.
- Daño al núcleo: `hit`, sin detener la lógica del combate.
- Mitad de vida: `phase_transition`; la lógica de fase 2 se activa en el mismo punto que antes.
- Muerte: `death`; la derrota lógica se emite de inmediato para conservar checkpoint, dash y guardado, mientras el cuerpo completa la animación y queda en el último frame.

## Sonidos

`audio/station_audio.gd` mantiene los WAV existentes y añade aliases semánticos:

- `sentinel_charge` → `alarm.wav`
- `sentinel_shot` → `enemy_shot.wav`
- `sentinel_hit` → `hit.wav`
- `sentinel_phase2` → `alarm.wav`
- `sentinel_death_fault` → `hurt.wav`
- `sentinel_death_impact` → `hit.wav`

El sonido de victoria ya existente se mantiene cuando la estación registra la derrota del jefe.

## Regla de regresión

La integración visual no debe alterar los valores de combate existentes: 10 HP, cambio de fase a 5 HP, 3/5 proyectiles en abanico, 3/5 posiciones de descarga, velocidades y ventanas de exposición. `tests/test_station.gd` conserva esas verificaciones.
