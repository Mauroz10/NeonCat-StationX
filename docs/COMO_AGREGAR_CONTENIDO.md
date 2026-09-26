# Cómo agregar contenido sin volver a un archivo gigante

## Enemigo nuevo

1. Crea `enemies/<tipo>/<tipo>.tscn` y `<tipo>.gd`.
2. Si tiene movimiento físico, usa `CharacterBody2D`; si es fijo/sensor, usa `Area2D` o `Node2D` según corresponda.
3. Hereda `EnemyBase` solo si necesita vida, daño común y señales estándar.
4. Emite `projectile_requested`, `sound_requested`, `contact_damage` y `defeated` en vez de buscar al `GameManager` y cambiarle variables.
5. Instancia el enemigo directamente en la escena del sector correspondiente.

## Sala o sector nuevo

1. Crea una escena bajo `world/`.
2. Coloca plataformas, enemigos, terminales y pickups visualmente en esa escena.
3. No escribas arrays de coordenadas en scripts.
4. Si es una sala temporal, registra su transición en `game_manager.gd`; si pertenece a una estación continua, compónla desde la escena de esa estación.

## Power-up nuevo

1. Crea una escena reutilizable en `world/shared/` o una carpeta propia si necesita lógica compleja.
2. El pickup emite una señal con su ID/recompensa.
3. El sistema dueño del efecto aplica el cambio: por ejemplo, una habilidad del jugador se aplica en `player.gd`, no en la UI ni en la sala.
4. Si debe persistir, añade el dato al esquema de `save_system.gd` manteniendo compatibilidad con saves anteriores.

## Ataque o fase del jefe

- Ataques específicos de fase van en `bosses/sentinel/states/`.
- Vida, transición de fase, vulnerabilidad y muerte siguen siendo responsabilidad de `sentinel.gd`.
- No añadas nuevos `if boss_phase ...` al `GameManager`.

## UI

- HUD: `ui/hud/`.
- Mapa: `ui/map/`.
- Pausa: `ui/pause/`.
- Touch: `ui/touch/`.
- La UI lee estado público o responde a señales; no controla física ni IA.

## Regla de pruebas

Cada cambio de gameplay debe añadir o adaptar una prueba sin borrar regresiones existentes. El workflow exige exactamente 24 PASS actuales antes de exportar el APK; cuando se agreguen comportamientos nuevos, aumenta explícitamente ese número y documenta el motivo.
