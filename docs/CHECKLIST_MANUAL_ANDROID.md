# Checklist manual — APK refactorizado

Prueba estos puntos después de que GitHub Actions muestre 24 PASS / 0 failures:

1. **Movimiento:** camina a izquierda/derecha y confirma que la aceleración visual y velocidad se sienten iguales al APK anterior.
2. **Salto/doble salto:** comprueba altura, timing y que un tercer salto en el aire no sea posible.
3. **Plataformas one-way:** salta desde abajo atravesando las plataformas y aterriza encima sin rebotes ni enganches.
4. **Pozos:** cae por los tres pozos; confirma que no aparece suelo invisible y que reapareces correctamente.
5. **Dash:** tras derrotar a Sentinel, confirma distancia, duración, cooldown, estela/efecto y que atraviesa las barreras violetas.
6. **Animaciones:** revisa idle, correr, saltar, disparar, dash y recibir daño; no debe haber escalados bruscos, parpadeos incorrectos ni sprites cortados.
7. **Disparo:** verifica dirección izquierda/derecha, cadencia y colisión con patrulleros, trenes, torretas, drones y núcleo del jefe.
8. **Sentinel-G7:** confirma los tres patrones, la transición visual/sonora a fase 2, el núcleo vulnerable solo durante la ventana correcta y la música de jefe.
9. **Audio:** salto, disparo, dash, impactos, daño, pickups, alarma, victoria y música deben sonar en los mismos momentos que antes; prueba también apagar/encender sonido.
10. **Tranvía:** después del jefe, viaja desde 6630→180 y 180→6630; confirma que no quedan proyectiles peligrosos al reaparecer.
11. **Minas/Fábrica:** entra y regresa; confirma que enemigos muertos, pickups recogidos y estado de G-7 siguen como estaban.
12. **Mapa y pausa:** abre mapa y pausa desde teclado/touch; el mundo debe congelarse completamente y reanudarse sin saltos de física/audio.
13. **Controles táctiles Android:** prueba multitouch (mover+salto, mover+disparo, mover+dash), botón USAR, MAPA y PAUSA. Revisa especialmente bordes de pantalla en horizontal.
14. **Guardado:** alcanza varios checkpoints, cierra completamente la app, vuelve a abrir y confirma posición, jefe, dash, secretos, score, mapa visitado y audio.
15. **Orientación/rendimiento:** abre desde retrato y confirma que pasa a horizontal; recorre los 9 sectores buscando tirones, cámara temblorosa, arte ausente o colisiones desplazadas.
