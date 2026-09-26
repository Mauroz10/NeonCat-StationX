# Entrega del refactor G-7 0.3.0

## Línea base

La referencia funcional es el ZIP `NEON_CAT_G7_0.3.0_PROYECTO_COMPLETO(1).zip` proporcionado por el usuario. `docs/pruebas_godot_4_2_1.txt` dentro de esa línea base registra 24 PASS y `RESULT: 0 failures` con Godot 4.2.1.

## Qué cambió

- `scripts/game.gd` fue eliminado y dividido por responsabilidades.
- El jugador y enemigos móviles usan `CharacterBody2D`.
- Proyectiles, pickups, daño y triggers usan `Area2D` donde corresponde.
- Plataformas, gaps, gates, terminales, pickups, checkpoints y enemigos viven en escenas editables.
- Los 9 sectores siguen componiendo un único mundo G-7 continuo de 8600 px.
- Sentinel tiene su escena y dos controladores de fase independientes.
- HUD, mapa, pausa y touch están separados.
- `SaveSystem` es el único Autoload añadido.
- El Action fue adaptado a la nueva estructura y mantiene la barrera de 24 pruebas antes de exportar.

## Qué no cambió deliberadamente

- `assets/`.
- `export_presets.cfg`.
- `shaders/remove_green.gdshader`.
- Resolución/orientación.
- Save v3, ruta del save y migraciones v1/v2.
- Coordenadas, checkpoints, pozos, plataformas, enemigos, pickups, portales y tranvía del nivel base.
- Valores de movimiento, dash, disparos y ataques de Sentinel.

## Verificación realizada antes de empaquetar

- Todas las referencias `res://` apuntan a archivos existentes.
- No hay IDs `ExtResource`/`SubResource` huérfanos en escenas/recursos.
- No hay `class_name` duplicados.
- Los hashes de `assets/` coinciden con la línea base.
- `export_presets.cfg` coincide byte por byte con la línea base.
- Los nombres de las 24 pruebas permanecen iguales.

La ejecución real de Godot 4.2.1 del refactor queda a cargo del Action del repositorio del usuario, según el acuerdo de verificación.
