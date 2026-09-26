# NEON CAT: Station X — arquitectura refactorizada

## Regla principal

La escena `scenes/game.tscn` solo compone el juego. `game/game_manager.gd` coordina flujo, salas, señales, guardado y UI, pero no implementa física del jugador, IA de enemigos ni ataques del jefe.

## Responsabilidades

- `player/`: movimiento, salto, doble salto, dash, vida, animación y efectos del Astro-Gato.
- `projectiles/`: proyectiles del jugador y enemigos mediante `Area2D`.
- `enemies/`: una escena/script por familia de enemigo. La lógica compartida vive en `enemy_base.gd`.
- `bosses/sentinel/`: Sentinel-G7 y sus dos fases separadas.
- `world/station_g7/`: Estación G-7 continua y sus 9 sectores editables individualmente.
- `world/gateways/`: vestíbulos de Minas y Fábrica.
- `world/shared/`: plataformas, checkpoints, pickups, barreras de dash y terminales reutilizables.
- `ui/`: HUD, controles táctiles, pausa y mapa separados.
- `camera/`: encuadre y límites de cámara.
- `audio/`: reproducción de música y efectos.
- `autoload/save_system.gd`: única responsabilidad global: validar, migrar, guardar, cargar y borrar el save v3.

## Datos de compatibilidad congelados

- Resolución lógica: 960 × 540.
- Mundo G-7: 8600 px.
- Piso: y=454.
- Movimiento: 260 px/s.
- Gravedad: 1150.
- Salto: -475; doble salto: -427.5.
- Dash: 650 px/s por 0.24 s; cooldown 1.5 s.
- Bala del jugador: 670 px/s; lifetime 1.3 s; cooldown 0.22 s.
- Sentinel: 10 HP, fase 2 a 5 HP.
- Save: `user://station_g7_save.json`, versión 3, migración v1/v2 conservada.

## Comunicación

Los nodos no escriben directamente en el estado interno de otros sistemas. Los eventos importantes se emiten por señales: daño, muerte, proyectiles, pickups, checkpoints, secretos, sonido, cambio de fase y finalización de estación.
