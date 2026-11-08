# ALL IN — Etapa 4.31.38 | FICHA INFERNAL

**CAMBIAMOS:** primer escenario de fondo animado + infraestructura reutilizable para escenarios nuevos.

- Fondo pixel art, 9:16, rojo/dorado; ficha con pentagrama central tenue.
- Luces de borde con seis fotogramas, a 5,55 FPS (no se anima el fondo completo).
- Dibujado SIEMPRE por debajo de personajes, proyectiles, enemigos, obstáculos y HUD.
- Sin colisiones visuales; los obstáculos procedurales siguen con sus cuerpos sólidos.
- Listo para registrar otros suelos desde `RoomThemeCatalog.gd`.
- No se tocó balance ni el funcionamiento de las cuatro armas.

**PRUEBA:** iniciar partida, pausar, luchar, avanzar salas y comprobar rendimiento Android.
**LÍMITE:** tests estáticos efectuados; falta ejecución dentro de Godot.
