# ALL IN — Etapa 4.31.36 | Subfusil más pequeño + borde blanco

Proyecto **Godot completo** para PC y Android, en una única carpeta de importación.
**Estado:** comprobaciones estáticas y de recursos realizadas; ejecución en Godot pendiente de prueba del usuario.

## Cambios de 4.31.36

- Se retocaron exclusivamente los cuatro atlas visuales del **subfusil** (**común, rara, épica y legendaria**).
- El subfusil ahora se renderiza **ligeramente más pequeño** dentro de su celda 32 × 32 para que ya no se sienta tan alto como el Apostador.
- Se añadió un **contorno blanco** alrededor de cada sprite del subfusil para mejorar legibilidad y reconocimiento visual futuro.
- No se alteró el orden de direcciones ni la lógica de la brújula: se conserva el mapeo **0 ↓, 1 ↙, 2 ←, 3 ↖, 4 ↑, 5 ↗, 6 →, 7 ↘**.
- Se conservan sin cambios la pistola, la escopeta, la Desert Eagle, el laboratorio de armas, las hitboxes, disparos, daño, economía, enemigos y menús.

## Cómo probar esta entrega

1. Importa `project.godot` desde la carpeta raíz en Godot 4.
2. Abre una partida y entra a **Pausa → LABORATORIO DE ARMAS**.
3. Equipa el **subfusil** en común, rara, épica y legendaria.
4. Verifica que el arma ahora se perciba **más pequeña** y con **borde blanco** en las ocho direcciones.
5. Comprueba que pistola y escopeta sigan intactas para descartar regresiones.

## Base conservada

# ALL IN — Etapa 4.31.35 | Subfusil (Uzi) brújula y cuatro rarezas

Proyecto **Godot completo** para PC y Android, en una única carpeta de importación.
**Estado:** comprobaciones estáticas y de recursos realizadas; ejecución en Godot pendiente de prueba del usuario.

## Cambios de 4.31.35

- Reemplazados los cuatro atlas visuales del subfusil (**común, rara, épica, legendaria**) por la hoja de Uzi con cargador extendido aprobada. La progresión muestra arma humana → primeras señales de corrupción → corrupción épica → oro infernal.
- Cada atlas: 8 celdas **32 × 32 px**, transparentes, en orden exacto para Godot: **0 ↓, 1 ↙, 2 ←, 3 ↖, 4 ↑, 5 ↗, 6 →, 7 ↘**.
- Reordenación desde las columnas originales de la imagen: **5, 6, 7, 8, 1, 2, 3, 4**. No se reflejaron sprites ni se intercambiaron vistas por aproximación.
- Subfusil flotante: su propia órbita visual con seguimiento del apuntado, cambio entre ocho dibujos sin rotación, interpolación, coordenadas redondeadas y límite dentro de la arena. **Sin aro visible**.
- Se conservan los atlas de pistola y escopeta aprobados, el laboratorio de armas para cambiar rarezas de inmediato, y toda la lógica de colisiones, disparos, daño, economía y progreso.

## Cómo probar esta entrega

1. Importa `project.godot` desde la carpeta raíz en Godot 4.
2. Abre una partida y ve a **Pausa → LABORATORIO DE ARMAS**.
3. Equipa subfusil común, raro, épico y legendario, uno a uno.
4. Observa el cargador extendido y las vistas **↙ (1), ↖ (3), ↗ (5), ↘ (7)**; camina y apunta cerca de paredes.
5. Cambia a pistola y escopeta para comprobar que ambas siguen funcionando sin regresiones; revisa una muerte y reanimación si es posible.

## Base conservada

# ALL IN — Etapa 4.31.34 | Escopeta brújula y 4 rarezas

Proyecto **Godot completo** (PC + Android), una carpeta raíz para importar.
**Estado:** ZIP comprobado de forma estática; pendiente de validación en Godot por el usuario.

## Qué cambió en 4.31.34

- Escopeta con 4 atlas nuevos: común, rara, épica, legendaria. Los diseños salen de la última hoja visual aprobada: normal → primeras grietas → corrupción épica → metal dorado maldito.
- Cada atlas contiene 8 celdas **32 × 32**, en el mismo orden interno que la pistola: **0 ↓, 1 ↙, 2 ←, 3 ↖, 4 ↑, 5 ↗, 6 →, 7 ↘**.
- Procedencia de columnas de la referencia, contando desde 1: **5, 6, 7, 8, 1, 2, 3, 4**. No se reflejan ni inventan direcciones. La vista ↙ usa la columna 6, no un espejo de la ↗.
- La escopeta flota alrededor del Apostador siguiendo el autoapuntado con suavizado y ocho ilustraciones discretas, sin giros borrosos ni aro visible en juego.
- La ilustración de escopeta es ligeramente más grande que la de pistola pero utiliza una celda 32 × 32 y los bordes de la arena siguen limitando su posición.
- La pistola 4.31.33, las otras armas, el laboratorio de selección rápida, el combate, hitboxes, balance y cinemáticas se conservan.

## Cómo probar en Godot

1. Importar `project.godot` desde esta carpeta en Godot 4.
2. Abrir una partida, pausar y entrar en **LABORATORIO DE ARMAS**.
3. Equipar escopeta común, rara, épica y legendaria sucesivamente (el laboratorio las concede sin ascenso manual).
4. Probar las **ocho direcciones** frente a enemigos. En particular verificar **↙ (1), ↖ (3), ↗ (5) y ↘ (7)**, más las vistas verticales.
5. Caminar cerca de las cuatro paredes; verificar que la escopeta permanece dentro de la arena y la pistola sigue funcionando.
6. Probar daño, muerte/reanimación y cambiar de escopeta a pistola desde el laboratorio.

## Base conservada

# ALL IN — Etapa 4.31.33 | Pistola: orientación abajo-izquierda

Proyecto Godot COMPLETO (PC + Android) • Una sola carpeta de importación.  
**Estado:** paquete listo para probar; falta verificación de ejecución en Godot.

## Qué cambió en 4.31.33

- En cada uno de los cuatro atlas de pistola, el fotograma **1 (↙ abajo-izquierda)** se reemplazó por una **copia reflejada horizontalmente del fotograma 7 (↘ abajo-derecha)**.
- No se modificaron los otros siete fotogramas de cada rareza ni el sistema brújula, laboratorio, combate o las colisiones.
- Base funcional: **4.31.32**, cuya estabilización se conserva intacta.

## Cambios conservados de 4.31.32

- Corregida la llamada sin argumento a `_update_weapon_sprite(delta)` que impedía analizar correctamente `Player.gd` al reiniciar la cinemática de muerte; el seguimiento orbital también se reinicia al reanimar para evitar posiciones viejas.
- La pistola flotante queda totalmente dentro de los límites de la arena al acercarse a paredes, usando su tamaño real de celda.
- La corrección de la dirección **3 (arriba-izquierda)** participa del suavizado orbital y ya no se aplica como un salto instantáneo.
- No se modificaron sprites, daño, enemigos, hitboxes, inventario ni las demás armas.
- Sigue disponible el **LABORATORIO DE ARMAS** en PAUSA (4 modelos × 4 rarezas); usarlo invalida el récord de esa partida.
- El aro de las previews no existe en gameplay.

## Prueba recomendada en Godot

1. Importar `project.godot` de esta carpeta en Godot 4.
2. Comprobar que el proyecto inicia sin errores de análisis de scripts.
3. Abrir **PAUSA → LABORATORIO DE ARMAS** y equipar pistola común, rara, épica y legendaria.
4. Apuntar hacia arriba-izquierda (dirección 3), alternar rápidamente entre las direcciones 2, 3 y 4 y revisar que el arma se desplace sin saltos.
5. Acercarse a las cuatro esquinas y comprobar que el arma nunca se recorta contra los bordes de la arena.
6. Comprobar una muerte/reanimación y el regreso a la partida (el error original afectaba esta ruta).
7. Si lo deseas, ejecutar `tests/PruebaPistolaBrujula43132.gd` con Godot en modo headless.

## Referencia histórica

Las funciones previas del sistema brújula y laboratorio están descritas abajo.


---

## Descripción anterior (4.31.30–4.31.31)

# ALL IN — Etapa 4.31.30 | Pistola brújula y laboratorio de armas

Proyecto **completo** de Godot para PC y Android. Basado en la **4.31.28**
(última base autorizada anterior): no se incorporan cambios de la 4.31.29
experimental.

## Cambios de esta entrega

- La **pistola** ahora flota alrededor del Apostador en la dirección de su
  apuntado automático. La posición se interpola suavemente en 360 grados,
  pero la imagen utiliza ocho direcciones de pixel art sin rotación borrosa.
- Orden comprobable de las direcciones del atlas: `0↓, 1↙, 2←, 3↖, 4↑, 5↗, 6→, 7↘`.
- Cuatro atlas de pistola de 8 fotogramas de 32 × 32 píxeles. Las cuatro
  rarezas tienen tamaño consistente, contorno doble negro/blanco y márgenes
  transparentes. Las direcciones hacia abajo se reorientaron para que el
  cañón apunte realmente hacia abajo.
- La **legendaria** reutiliza la silueta y las grietas rojas de la épica;
  incorpora dorados parciales sin pintar toda el arma de amarillo.
- **Laboratorio de armas** en PAUSA (PC y Android): 4 modelos × 4 rarezas,
  un botón por variante para obtenerla/equiparla inmediatamente. No entrega
  objetos por duplicado si se vuelve a elegir la misma combinación.
- Acceder al laboratorio y equipar armas de prueba desactiva el récord de
  esa partida. En la versión pública este laboratorio debe ocultarse.
- La escopeta, el subfusil y la Desert Eagle conservan los sprites anteriores.
  Tampoco se modifican daño, cadencia, alcance, proyectiles ni hitboxes.

## Prueba recomendada

1. Extrae el ZIP completo: **una sola carpeta principal**.
2. Importa `project.godot` en Godot.
3. Entra en una partida, abre **PAUSA** y toca **LABORATORIO DE ARMAS**.
4. Selecciona **PISTOLA** en COMÚN, RARA, ÉPICA y LEGENDARIA de una en una.
5. Cierra el laboratorio, prueba las 8 direcciones con enemigos próximos
   (autoapuntado) y luego revisa las otras 12 variantes del laboratorio.
6. Reporta rareza + dirección + qué debería cambiar, por ejemplo:
   `Pistola legendaria, 0 (abajo): separar 2 px del cuerpo`.

## Historial

Consulta `CHANGELOG.md` para cambios anteriores.

**Nota de pruebas:** se comprobó la integridad del archivo ZIP y de los
recursos gráficos, pero no se ejecutó Godot en este entorno. Las verificaciones
finales de jugabilidad y de posición deben hacerse dentro del editor.
