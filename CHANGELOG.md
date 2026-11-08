# ALL IN — Historial consolidado de cambios

## 4.31.38 — Ficha Infernal: fondo animado y módulo reutilizable

- Convertido el prototipo GIF aprobado en un suelo PNG único de 180×320 más seis capas de bombillas transparentes. Se comprueba recomposición exacta de los seis frames.
- Nuevo `scripts/visual/RoomBackdrop.gd`: dos Sprite2D sin colisión, `z_index=-50`, filtrado nearest, animación de luces a 5,55 FPS mediante cambio de textura, pausables y reutilizados.
- Nuevo `scripts/visual/RoomThemeCatalog.gd`: punto único para añadir futuros escenarios y elegir su reparto por sala. Para esta prueba usa Ficha Infernal en todas las salas.
- `Main.gd` crea el nodo de fondo, aplica el tema al comenzar la sala y evita taparlo con el suelo clásico. Se conservan indicador de jefe y portal, colisiones y generación de obstáculos.
- Sin cambios a armas, protagonista, enemigos, proyectiles, interfaces, economía o balance.
- Validaciones estáticas, comparación con 4.31.37, recursos y ZIP autocontenido; pruebas en Godot pendientes de ejecución por el usuario.

## 4.31.37 — Desert Eagle pixel art + brújula flotante

- Se sustituyeron los cuatro atlas de Desert Eagle por los diseños aprobados: cuerpo robusto, cañón largo, mira tipo aleta y progresión de corrupción con borde blanco.
- Los cuatro atlas mantienen 8 celdas de 48×48 y las direcciones 0↓ 1↙ 2← 3↖ 4↑ 5↗ 6→ 7↘.
- `Player.gd` ahora incorpora una rama **exclusivamente visual** para la Deagle: brújula de seguimiento amortiguado, tamaño al 84 %, límites de arena y reseteo al revivir.
- No se modificaron pistola, escopeta ni subfusil, ni su sistema de brújula aprobado.
- Laboratorio de armas, colisiones, daño, cadencia, proyectiles, economía y enemigos conservados.
- Paquete autocontenido con una única carpeta raíz.

## 4.31.37 — Desert Eagle: nueva spritesheet (4 rarezas)

- Sustituidos únicamente los cuatro PNG de Desert Eagle por celdas RGBA transparentes de 48×48, ocho vistas bien ordenadas por rareza y contorno blanco.
- Diseño robusto de cañón largo y mira tipo aleta, evolución normal → corrupción rara → épica → dorada legendaria.
- Sin cambios en scripts, escenas, hitboxes, sistema de apuntado o comportamiento visual existente de Deagle (todavía no usa brújula flotante).
- Base conservada: 4.31.36 con pistola, escopeta y Uzi aprobadas.

## 4.31.36 — Subfusil más pequeño y con borde blanco

- Ajustados exclusivamente los cuatro atlas del subfusil (`smg_common`, `smg_rare`, `smg_epic`, `smg_legendary`).
- Reducción visual del subfusil dentro de cada celda 32 × 32 para que deje de sentirse tan alto como el personaje.
- Añadido contorno blanco legible en las ocho direcciones para mejorar reconocimiento visual sin tocar hitboxes ni lógica de disparo.
- Se mantiene intacto el orden de direcciones y la lógica de arma flotante implementada en 4.31.35.
- Sin cambios en pistola, escopeta, Desert Eagle, laboratorio, daño, economía, enemigos ni menús.

## 4.31.35 — Subfusil (Uzi) brújula, 4 rarezas y 8 direcciones

- Cuatro atlas de subfusil derivados de la spritesheet aprobada, respetando cargador extendido y progresión de corrupción (común → rara → épica → legendaria), con ocho vistas transparentes de 32 × 32 px.
- Atlas reordenados de ↑ ↗ → ↘ ↓ ↙ ← ↖ a **↓ ↙ ← ↖ ↑ ↗ → ↘**, siguiendo la misma conversión que funcionó para escopeta 4.31.34; sin espejados ni redefinición de direcciones.
- Subfusil incorporado a la brújula flotante con estado orbital propio, ocho dibujos discretos, interpolación, píxeles redondeados, limitación de arena y reinicio de estado al revivir.
- Conservados sin alterar: atlas y lógica de pistola y escopeta, laboratorio rápido de armas, colisiones, hitboxes, disparos, daño, economía, objetos, enemigos y audio.
- Verificados recursos, integridad de atlas, cambios de archivos y ZIP autocontenido; pendiente validación de ejecución en Godot.

## 4.31.34 — Escopeta brújula con progresión visual por rareza

- Se reemplazaron exclusivamente los cuatro atlas de la escopeta con sprites aprobados y recortados a 8 direcciones (32 × 32 por celda); orden Godot 0↓ 1↙ 2← 3↖ 4↑ 5↗ 6→ 7↘.
- Se añadió comportamiento de flotación visual a la escopeta siguiendo el apuntado real, con interpolación, redondeo de píxeles, ocultación durante daño/muerte y contención dentro de los límites de la arena.
- La escopeta comparte la lógica de brújula sin tocar ni sustituir la rama de pistola ya aprobada en 4.31.33.
- Conservados laboratorio de 16 opciones, armas de otros modelos, física, disparos, daño, estadísticas, colisiones y récords.
- Auditoría estática de recursos, estructura y ZIP. La ejecución en Godot no está disponible en el entorno de generación.

## 4.31.33 — Orientación correcta de pistola abajo-izquierda

- Sobre la base funcional **4.31.32**, el sprite en índice **1 (↙)** de cada pistola (común, rara, épica y legendaria) ahora es el espejo horizontal del sprite original en índice **7 (↘)**.
- Se mantienen íntegros los otros 28 fotogramas, los scripts, escenas, laboratorio de armas, cinemáticas y balance.
- Se corrigió el nombre descriptivo de la versión en `project.godot` y se actualizó `README_ES.md`.

## 4.31.32 — Estabilización del sistema brújula

- Se corrigió la llamada sin argumento a `_update_weapon_sprite(0.0)` durante `reset_death_cinematic()`; la función ahora siempre recibe el `delta` que exige su firma. Se reinicia además el estado de seguimiento orbital al revivir.
- Se limitó el centro del sprite de la pistola flotante al rectángulo de la arena con un margen de media celda más 1 px, evitando que la pistola se pierda detrás de las paredes al acercarse a los extremos.
- El ajuste particular de la dirección 3 pasa a formar parte del objetivo interpolado y deja de añadirse bruscamente al sprite después de la interpolación.
- Se añadió `tests/PruebaPistolaBrujula43132.gd` para revisar cambios de dirección, límites de arena y reinicio de cinemática.
- La corrección no modifica sprites, colisiones, daño, ritmo de ataque, economía, inventario ni el laboratorio de armas.
- Validación efectuada: comprobaciones estáticas de recursos/firma, prueba matemática de límites y de interpolación, y verificación del ZIP. No se ha ejecutado Godot en este entorno.

## 4.31.31 — Pistola brújula: corrección puntual dirección 3

- Se corrigió la posición visual de la pistola brújula en la **dirección 3 (arriba-izquierda)** para evitar que invada demasiado el rostro/cabello del Apostador.
- Se mantiene el sistema de arma flotante para la pistola, con cambio entre ocho direcciones dibujadas y sin rotación de textura.
- El **laboratorio de armas** se conserva para equipar rápidamente cualquiera de las 16 combinaciones arma/rareza.
- El aro mostrado en materiales de preview sigue siendo solo una referencia visual externa; **no aparece durante el gameplay**.

## 4.31.30 — Pistola brújula flotante y laboratorio de armas

- Partiendo de la última versión aprobada 4.31.28, se integró un nuevo
  comportamiento **puramente visual** de pistola flotante que sigue el
  autoapuntado, con suavizado continuo de posición y sprites en 8 direcciones.
- Las cuatro rarezas de pistola usan sprites de 32 × 32, tamaño homologado,
  contornos blanco/negro y siluetas legibles. La legendaria evoluciona del
  diseño épico autorizado, con grietas rojas y placas doradas limitadas.
- Se corrigió la orientación del cañón en las vistas hacia abajo.
- Se añadió un menú táctil de **laboratorio de armas** para obtener y equipar
  a demanda 16 combinaciones (4 modelos x 4 rarezas). Reutiliza objetos ya
  obtenidos y marca la partida como de desarrollo (sin récord).
- Se conserva la lógica de inventario/equipamiento existente; los cambios no
  alteran hitboxes, daño, cadencia, proyectiles ni estadísticas.
- Formato de ZIP con carpeta raíz única y nombre descriptivo, como en 4.31.24.

## 4.31.28 — Pistola ajuste fino

- Se conservó el sprite épico aprobado de la 4.31.27.
- Se regresó a la base de posiciones de la 4.31.26 para la pistola, con ajuste fino adicional en los frames 0 (abajo), 4 (arriba) y 6 (derecha).
- Objetivo del ajuste: que el arma se vea más natural en mano sin tocar hitboxes, colisiones ni balance.

## 4.31.27 — Pistola épica pulida y empaquetado claro

- Se reemplazó el atlas de la pistola **épica** por la fila aprobada por el usuario.
- Se corrigieron tres vistas problemáticas de la pistola (frente, derecha y espalda).
- Se reajustaron los offsets de sujeción visual para que la pistola se vea más natural en mano.
- No se tocaron hitboxes, colisiones ni balance; el cambio sigue siendo meramente estético.
- Se renombró el proyecto y la carpeta raíz para que en Godot se identifique como **ALL IN - ETAPA 4.31.27**.

## 4.31.26 — Pistola visual corregida (cuatro rarezas)

- Sustituidas exclusivamente las cuatro spritesheets de la pistola (`common`, `rare`, `epic`, `legendary`) por 8 poses extraídas de la hoja de arte aprobada, con fondo transparente y márgenes seguros por dirección.
- Celda visual específica de pistola de 32×32 px y arma reducida a ~19 px de extensión máxima: ya no tapa el cabello ni el torso.
- Anclajes y profundidad específicos por dirección. Apuntado de la pistola sigue la orientación del disparo mientras dura la indicación visual del autoataque.
- Las otras tres armas quedan sin modificar, pendientes de una corrección individual.
- El nuevo ajuste es puramente estético: `WeaponSprite` no tiene colisiones; no se modificaron hitboxes, alcance, daño, enemigos ni balance.

## 4.31.25 — Armas estéticas del Apostador

- Se añadió una capa visual `WeaponSprite` al jugador; no tiene colisión y no modifica hitboxes, daño, alcance ni cadencia.
- El Apostador ahora muestra el arma equipada en 8 direcciones durante idle, caminata y apuntado automático.
- Se integraron sprites visuales para pistola, escopeta, subfusil y Desert Eagle.
- Cada una tiene variantes por rareza (`common`, `rare`, `epic`, `legendary`) para que el aspecto acompañe la progresión del botín.
- La Desert Eagle legendaria y las versiones altas usan acentos dorados para diferenciarse mejor de la pistola normal.
- Para no romper las animaciones aprobadas, el arma se oculta durante daño y cinemáticas de muerte.
- Se añadieron 16 atlas nuevos en `assets/player/weapons/` y una previsualización externa de apoyo.

## 4.31.24 — Mantenimiento y saneamiento

- Los reinicios de `RunManager` limpian también las acumulaciones, crisis, sobrecargas y efectos especiales de `PactManager`.
- La sala 1 presenta los pactos sin fortuna anterior; las etiquetas distinguen estado actual y resultados posibles.
- Los impactos bloqueados (escudo, evasión, parry o bloqueo) ya no se representan como daño real al protagonista; no cambian los cálculos ni ventanas de contacto.
- Se eliminan solicitudes de redibujo por fotograma de la sombra estática del jugador.
- Caché perezosa del joystick táctil para reducir búsquedas de nodos por frame en Android.
- Evita reasignar el mismo fotograma/color al `Sprite2D` en cada frame.
- Un único historial sustituye las notas individuales de versiones anteriores; se conservan íntegramente debajo.
- Prueba de regresión añadida: `tests/PruebaMantenimiento43124.gd`.

## Archivo histórico completo (extraído de las notas anteriores)

Esta sección conserva el texto de los registros antiguos y señala el archivo de procedencia, por trazabilidad.

### CAMBIOS_IMP_POLISH_PASS.md

ALL IN — IMP POLISH PASS (base 4.31.7)

Objetivo:
- Corregir partículas blancas / restos de fondo en los sprites del IMP.
- Alargar la animación de muerte sin afectar el gameplay.

Cambios realizados:
1. Limpieza visual
- Se eliminaron píxeles residuales blanco/gris muy claros en los frames del IMP.
- Archivos retocados: run_02.png, run_03.png, death_00.png.
- Se conservó el resto del arte original de 4.31.7.

2. Muerte más legible
- Se añadieron 2 frames extra de humo: smoke_03.png y smoke_04.png.
- Se ajustó assets/enemies/imp/ImpDeathAnimations.tres para usar 7 frames totales.
- La velocidad de la animación "vanish" se redujo de 18.0 a 8.0.

3. Gameplay intacto
- No se alteró la lógica de muerte del enemigo.
- El IMP sigue contando como derrotado inmediatamente al morir.
- La animación larga ocurre solo en la escena visual ImpDeathFX.

Resultado esperado:
- Sin partículas blancas visibles alrededor del IMP.
- Muerte más apreciable, clara y puramente visual.

---

### PRUEBA_CRANEO_INCUBADOR.md

# ALL IN 4.31.12 — Prueba jugable del Cráneo Incubador

**Proyecto completo basado en 4.31.10, con los sprites aprobados y la integración del Incubador de 4.31.11.**

## Cómo abrir el ZIP (importante)
1. Extraer **la carpeta `ALL_IN_4_31_12` completa**, no abrir el ZIP como proyecto.
2. En Godot 4.x, usar **Importar** y seleccionar `ALL_IN_4_31_12/project.godot`.
3. Ejecutar la escena principal (F5).

## Prueba inmediata en PC
1. Comenzar una partida, elegir el pacto o la opción de no apostar y entrar a la arena.
2. Pulsar **F10** en la ventana del juego: aparece **un Cráneo Incubador** adicional.
3. Observar su vuelo, persecución y reacción al daño. Al matarlo, debe reproducirse la animación de explosión y liberar **exactamente dos mini-Cráneos Ígneos**.
4. Los mini-Cráneos disparan y se recolocan igual que el minion original; no deben quedar restos blancos alrededor del sprite.
5. F10 está restringida a ejecuciones desde el editor de Godot (no es un botón de Android). No usar la tecla en partidas que quieras registrar como récord: se marca la sesión como depuración.

## En partidas normales
- El Incubador aparece por RNG desde la sala 25 como antes.
- Se conservan daño, velocidad, colisiones, botín y reglas de sala del proyecto base. El único ajuste en su script es impedir que la velocidad de sus crías sea menor que la normal al usar el atajo F10 en salas anteriores a la 25.
- El tercer enemigo comparte la IA de perseguidor del viejo SplitterEnemy. Su nueva identidad visual es un casco flotante con pica, ojo magenta, sombra y muerte explosiva.

## Arte
- Vuelo: 4 PNG de 64×64 px RGBA.
- Muerte/explosión: 5 PNG de 64×64 px RGBA.
- Sombra: 2 PNG de 64×64 px RGBA.
- Los minis utilizan sprites existentes de Ignel a escala 0.57 interna; la escala física heredada de enemigos sigue siendo 1.6.
- Las hitboxes conservan radios 15 y 9 unidades locales.

## Verificación
- Se validaron archivos ZIP, existencia de referencias `res://`, tamaños, canal alfa y ausencia de píxeles no transparentes en los bordes de los 11 PNG del Incubador.
- **No se ejecutó Godot en este entorno** (no hay editor/binario disponible). La confirmación final visual y de interacción la harás al probarlo, especialmente en Android, antes de darla por estable.

---

### REVISION_TECNICA.md

# Revisión técnica — ALL IN 4.27

**Origen:** ALL IN 4.26, proyecto extraído del ZIP original adjunto a la conversación.

## Cambios de código

- `ItemDatabase.gd`: 32 entradas nuevas `tp_...` y `jp_...`; 48 armaduras; progresión específica por pieza/rareza/nivel; ascensión mapea correctamente a la misma familia.
- `InventoryManager.gd`: chequeo de conjunto completo épico/legendario, afinidad de las cuatro ranuras, intervalos de escudo y bonificaciones JACKPOT.
- `RunManager.gd`: selección ponderada de conjunto 60/20/20 si hay un predominante; selección ponderada de pieza equipada 1.4 y penalización suave a repetición; temporizador de escudo independiente y no acumulable; reset de estado.
- `BasicEnemy.gd`: el catálogo puede crecer sin desplazar los objetos ajenos a armadura; ruta a selector inteligente.
- `BetManager.gd`: usa selector inteligente al obtener armadura en recompensa de apuesta de objeto.
- `Player.gd`: multiplicador JACKPOT antes de la instancia del único proyectil, penalización de cadencia, carga del siguiente ataque al hacer Parry.
- `Projectile.gd`: homing especial de JACKPOT al equipar su casco. BLACK JACK conserva límites previos.
- `PactManager.gd`: precio de 10 por confirmación; re-roll expone 3 opciones sin reemplazo de un pool de 9 (las anteriores sí pueden repetirse).
- `Main.gd`: integración UI, costos visibles/consumo, bloqueo de segundo re-roll por mesa y kits debug.
- Prueba `PruebaTresConjuntos427.gd` más actualización de regresiones que asumían 16 únicas o gratuidad.

## Límites de verificación

1. Aquí se realizan validaciones de integridad ZIP, referencias `res://`, composición del catálogo e inspección del código fuente.
2. **No hay ejecutable Godot instalado en el entorno**, por lo que NO se ejecutaron tests `.gd` en Godot. Es imprescindible usar Godot 4.7.2 PC/Android para certificar compilación y gameplay.
3. Los valores de daño y escudo son provisionales para esta prueba de balance. No incluye Armas 2.0 ni Gran Ruleta ALL IN.

---

### CAMBIOS_425.md

# ALL IN 4.25 — Corrección de impactos y dispersión de BLACK JACK

Objetivo: tres bugs de la 4.24.1 sin añadir conjuntos nuevos ni modificar Armas 2.0.

## Cambios realizados

1. **No hay penetración normal.** Los proyectiles del jugador desaparecen en el primer impacto contra enemigos u obstáculos. El antiguo efecto temporal de penetración de la Sobrecarga de Filo del Destino se reemplaza por **+8% de bonificación de daño** durante la misma Sobrecarga, conservando el resto de sus reglas. Las futuras penetraciones quedan reservadas para efectos consagrados todavía no programados.
2. **Daño fraccionario real.** Antes una bala con 45% de daño de un arma con daño base 1 tenía 55% de probabilidad de hacer **cero daño**, pese a que chocara. Ahora los enemigos tienen salud fraccionaria: una bala con daño 0.45 resta 0.45 de salud de forma consistente. La barra de salud refleja cada impacto. El cálculo evita convertir cuatro balas al 45% en cuatro puntos de daño completos.
3. **Barrido de colisiones.** Se consulta el primer obstáculo o enemigo entre la posición anterior y la siguiente del proyectil, para impedir que las mejoras de velocidad salten enemigos en un fotograma. La señal de colisión de área sigue disponible para impactos por roce; un cerrojo `spent` impide daños dobles.
4. **Dispersión legendaria reajustada.** Cuatro trayectorias simétricas: **−18°, −6°, +6°, +18°** respecto del objetivo. En lugar del anterior −27°, −9°, +9°, +27°, más abierto y difícil de aprovechar. El épico sigue con **−12° y +12°**.
5. **Sin cambios** en el set BLACK JACK (×2 al 70%, ×4 al 45%), las 16 armaduras, las fusiones, inventario, joystick, economía, enemigos, jefes ni la ruleta de nivel 25% ×4.

## Cómo probar en Godot 4.7.2

- Abre `project.godot` en una carpeta nueva.
- **PAUSA → PRUEBA BLACK JACK**, equipa las 4 piezas legendarias y dispara cerca de enemigos.
- Repite sin equipamiento, con 4 épicas y con 4 legendarias.
- Verifica que una bala desaparezca cuando impacta y no alcance al enemigo que esté justo detrás.
- En especial, observa que balas al 45% **sí** reducen la barra de vida.
- Comprueba la distribución 25%/25%/25%/25% en ruleta de subida de nivel.
- Opcional en PC: `godot --headless --path . --script res://tests/PruebaProyectiles425.gd` y `PruebaRuletaEquitativa4241.gd`.

**Validación:** revisiones estáticas y del ZIP realizadas, ejecución real pendiente de Godot en PC/Android.

---

### CAMBIOS_426.md

# ALL IN 4.26 — Ajuste acotado de economía y daño

## Cambios solicitados

- Cada enemigo normal eliminado abona **4, 5, 6 o 7 monedas**, con la misma probabilidad para cada cantidad. Antes eran 2–5. El promedio pasó de **3.5 a 5.5 monedas por enemigo** (2 monedas extra en promedio). Las monedas se acreditan directamente; no son objetos físicos en el suelo.
- Daño básico del personaje: **+10% global** desde el inicio de la partida, adicional a las mejoras por nivel y al pecho. El aumento es **aditivo** con estos otros porcentajes y se aplica **una sola vez al ataque base**, antes de repartir el daño entre las balas de BLACK JACK. Ejemplo con arma base de 1 daño: ataque sin críticos ni equipo = 1.10; BLACK JACK épico 2 × 0.77, legendario 4 × 0.495 (valores antes de dispersion e impactos).
- La pantalla de estadísticas muestra el nuevo +10% base.

## Lo que no cambió

- Vida y velocidad de enemigos: después del primer jefe conservan su aumento de vida x1.5.
- Bonos especiales de jefes, 8 monedas fijas por sala y recompensa escalonada COBRAR.
- Índice de botín y rarezas, costos y ascensiones, ruleta de nivel 25/25/25/25, pactos 60/40 y Sobrecargas.
- BLACK JACK: 2 disparos al 70% / 4 al 45%, abanico legendario [-18°, -6°, 6°, 18°], impacto sin penetración y daño fraccionario real.
- Joystick flotante, mochila 50 espacios, interfaz móvil; no se crearon TRAGAPERRAS ni JACKPOT, ni Armas 2.0.

## Prueba específica

`godot --headless --path . --script res://tests/PruebaBalance426.gd`

Verificar jugando desde Android y PC: dinero obtenido al matar, poder frente a la salud de sala 11+, y que el jefe no reciba bonificación de monedas por muerte normal. Todavía se requiere ejecución en Godot 4.7.2 para validar la experiencia.

---

### CAMBIOS_427.md

# ALL IN 4.27 — Cambios

- +32 armaduras (TRAGAPERRAS 16; JACKPOT 16) junto a las 16 BLACK JACK existentes = **48**.
- Stats interpoladas por rareza y nivel, ascensión identidad exacta, cuatro ranuras, duplicados y costos de forja originales.
- Pasiva TRAGAPERRAS: escudo independiente no acumulable, 25s épico / 18s legendario sin daño.
- Pasiva JACKPOT: daño x1.8 épico / x2.4 legendario, cadencia penalizada, Parry carga siguiente disparo; casco mejora tracking con un alcance angular más amplio.
- Afinidad automática del set predominante (60/20/20), peso 1.4 para piezas equipadas, antirracha suave por set/rareza. En empate se ponderan las piezas equipadas; sin set equipado: 1/3 cada uno.
- Mantiene probabilidad 2/3 armaduras, 1/3 armas/amuleto para que catálogo ampliado no desplace otras categorías.
- Pactos: apuesta 10 monedas y re-roll 50 una vez por mesa. 3 opciones únicas de los 9 acumulables; opciones anteriores NO excluidas. Se conserva 60/40.
- Kits de prueba en PAUSA; se conserva BLK JACK v4.25, daño base 4.26, ruleta nivel 4.24.1.
- Añade `PruebaTresConjuntos427.gd` y actualiza los tests heredados que asumían catálogo exclusivo de 16 o pactos gratuitos.

---

### CAMBIOS_428.md

# ALL IN 4.28 — Chatarrería + Armas 2.0 (prueba)

## Cambios
- Se conservan los 48 modelos de armadura (BLACK JACK, TRAGAPERRAS, JACKPOT) y el catálogo de 16 variantes por set.
- Armas 2.0: **4 arquetipos**, cada uno en cuatro rarezas para las fusiones (16 IDs): Pistola, Escopeta, Subfusil, Desert Eagle. El jugador inicia con pistola común equipada.
- Escopeta: **5 perdigones reales** (10 con BLACK JACK épico, 20 con legendario), caída de daño entre 90 y 250 px, alcance máximo 250 px. Daño por perdigón 52% del daño de ataque antes del factor BLACK JACK.
- Efectos secundarios de reliquias/instinto: máximo cuatro candidatos por ráfaga para evitar explosiones/encadenamientos excesivos con 20 perdigones. Los impactos de las 20 balas siguen siendo independientes.
- Subfusil: balas individuales, +75% cadencia base, daño por bala 73% antes del factor BLACK JACK, dispersión leve; Desert Eagle: +130% daño de ataque y -42% cadencia, disparo único fuerte. Estadísticas de prototipo sujetas a balance.
- Cuotas de botín **independientes del tamaño del catálogo**: 2/3 armadura, 1/3 otros; dentro de otros, 55% armas, 45% amuletos. Se eliminó la afinidad heredada de armas que sesgaba IDs anteriores. Afinidad de sets 60/20/20 preservada.
- Chatarrería desde menú pausa o mochila, sin coste de monedas. Apostar 1 o todos los duplicados de un ID+rareza, una tirada independiente por pieza y una confirmación. El premio es la ranura y set actualmente equipados, siempre nivel 1, sin trasladar mejoras.
- Recompensas de chatarrería: común 55% -> 1 común; rara 70% -> 2 comunes; épica 78% -> 2 raras; legendaria 85% -> **1 épica**. Una apuesta puede consumir todos los objetos elegidos. Nunca se apuesta el equipo actualmente equipado.
- Protección de capacidad: antes de apostar se comprueba que incluso el mejor resultado quepa en 50 espacios. No se consumen piezas si la mochila está demasiado llena.
- Ajuste de armaduras **sobre sus estadísticas positivas** (no puntos porcentuales): común +20%, rara +15%, épica +10%, legendaria +5%. Caps de Parry/Evasión 20%. Las pasivas completas de sets no se alteran.
- Enemigos rosas: desde sala 5, 1 disparo hasta sala 20, 2 disparos desde 21; máximo 3 concurrentes.
- Verde divisor: desde sala 25, probabilidad gradual 8–22%, máximo 2 concurrentes.
- Crecimiento vida normal tras jefes x1.30 en vez de x1.50; simultáneos 4–8 según sala.
- Rareza de armadura/arma/amuleto del suelo: poco rara desde 15, incremento después de 21 y 31, épica a partir de 40, legendaria a partir de 56. Los jefes y ascensiones mantienen sus reglas especiales.
- Joystick: elimina doble evento ratón/táctil, permite cancelar dedo capturado al abrir/cerrar menús y desactiva interceptación de toque por HUD no interactivo. Estos cambios reducen causas posibles, pero aún requieren pruebas en Android.
- Pactos del Destino: conservan 10 monedas por apuesta, reroll único de 50 y victoria base 60/40.

## Por verificar en Godot
No se dispone de ejecutable de Godot en este entorno: las pruebas `tests/Prueba428_Armas_Chatarreria.gd` deben ejecutarse en Godot 4.7.2; verificar especialmente joystick Android, ventanas de confirmación, proyectiles ×20, apuesta en lote y calidad del botín. No se implementó la Gran Ruleta ALL IN ni nuevas armaduras/amuletos.

---

### REVISION_TECNICA_428.md

# Revisión técnica estática — ALL IN 4.28

- Base de trabajo: `ALL_IN_Etapa4_27_Tres_Conjuntos_Pactos.zip`, descomprimida y modificada sobre sus escenas y scripts originales, sin sustituir el proyecto por un ejemplo vacío.
- Recuento: 48 variantes de armadura, 4 arquetipos de arma × 4 rarezas = 16 variantes de arma. Se mantienen amuletos existentes y recompensa especial de jefe.
- Botín por categoría ponderada e independiente del crecimiento del catálogo; las 48 armaduras de tres conjuntos permanecen elegibles y la afinidad de armadura 4.27 sigue activa.
- Apuesta Chatarrería: un roll independiente por pieza sacrificada; premio por victoria siempre Nv1 del mismo slot de la familia equipada. Se comprueba capacidad máxima y pertenencia a mochila antes de consumir.
- Proyectiles: 5/10/20 perdigones reales con dispersión no idéntica, cota de distancia y caída de daño; hasta cuatro candidatos de efectos secundarios por ráfaga.
- Script nuevo de prueba en Godot: `tests/Prueba428_Armas_Chatarreria.gd`.
- Comprobaciones ejecutadas aquí: estructura de 35 GDScript, delimitadores equilibrados, no duplicidad de funciones, referencias `res://` existentes, catálogo completo, reglas de apuesta y simulación Monte Carlo de 20,000 apuestas por rareza. Se corrigió un paréntesis del comparador antes de cerrar.
- **Limitación:** el motor Godot no está instalado en este entorno. NO se ha validado compilación ni ejecución de las escenas en Godot 4.7.2. Es una versión de test, especialmente para Android y control multitáctil. No afirmar estabilidad sin pruebas reales.

---

### CAMBIOS_429.md

# ALL IN v4.29 — móvil vertical, sonido, impactos y jefe más justo

Base: **v4.28.3**. Versión de **prueba alfa**, sin modificar los números de economía, armas 2.0, armaduras o La Chatarrería.

## Escenario y personajes

- La arena pasó del cuadrado en medio de la pantalla a un rectángulo vertical adaptable al tamaño lógico del viewport: ancho útil hasta 500 unidades, alto = alto del viewport - 160 (800 unidades para 540×960). Se conservan paredes físicas.
- El jugador, enemigos, jefe y minienemigos divididos tienen escala 2× **también en sus colisiones**. No se duplicaron velocidades, daño ni vida.
- Se actualizaron validaciones de pasillos, áreas alrededor de obstáculos y navegación para cuerpos más grandes. El escenario puede generar menos pilares si no hay rutas válidas.
- HUD de combate compacto: **corazones, sala, monedas**, con avisos de texto temporales. Estadísticas detalladas en la pausa / mochila. Botones táctiles al borde inferior y posiciones ligadas al viewport.

## Feedback

- Música original **«Racha Nocturna»** (25,6 s, jazz-funk/synth enérgico, OGG con loop), no utiliza melodías de obras existentes. Al pausar se pausa también la reproducción.
- Archivos de sonido separados para pistola, escopeta, subfusil, Desert Eagle, disparos de enemigos, impactos, daño recibido, Parry, evasión, jefe y escudo. Pool de 10 reproductores con limitador para evitar ruido excesivo.
- Una sola voz por ráfaga, **no 20 sonidos** cuando BLACK JACK multiplica los perdigones.
- Impactos visuales: anillos/cruces breves y destello de los personajes; agrupación de impactos simultáneos y tope de 36 marcas activas, en un nodo compartido.

## Jefe

- **Sala 10:** se mantiene embestida anunciada y ataque circular. Se quita la ráfaga dirigida de 3–5 disparos.
- **Sala 20:** se incorpora ráfaga dirigida de tres proyectiles; **sala 30 en adelante:** cinco.
- Las ráfagas circular y dirigida comparten **1,35 s de recuperación mínima**; durante una embestida no se dispara y tras la embestida hay una ventana de recuperación adicional.
- El ataque circular se espacia: 4,0 s normal y 3,3 s en fase furiosa. Se mantienen estadísticas y recompensas.

## Límites de verificación

Comprobación estática de referencias, archivos de audio y estructura efectuada fuera de Godot. No hay motor Godot disponible en este entorno para ejecutar GDScript, por lo que **la compilación y respuesta en Android deben probarse en el teléfono**. Hay test `tests/PruebaVerticalAudioJefe429.gd` para ejecutarlo allí o en PC con el motor.

---

### CAMBIOS_430.md

# ALL IN 4.30 — Estabilidad de combate móvil

Base: **4.29**, conservando armas, armaduras, probabilidades, fusiones y economía, salvo cambios de escopeta solicitados durante las pruebas.

## Reparaciones

1. **Arena de pantalla completa**. El rectángulo jugable coincide con el viewport, desde (0,0) hasta el borde inferior y derecho. Los indicadores y controles se superponen al mundo en esta alfa; no lo recortan.
2. **Tamaño 1.6×** para jugador, enemigos y jefe, incluidos hijos divisores. Se reducen las distancias de contacto y las separaciones para concordar con los nuevos cuerpos.
3. **Jefes sin obstáculos** en todas las salas múltiples de diez. El generador devuelve distribución vacía y el gestor de habitaciones no coloca bloques; siguen intactas embestida, círculo, enfriamiento y desbloqueo de otros tiros en salas posteriores.
4. **Navegación de enemigos**. A* valida los corredores con el radio 1.6× en lugar del radio antiguo; los enemigos dejan de chocarse físicamente unos con otros, pero conservan separación suave. Recalcular rutas tras choques; no insistir en línea recta si no hay ruta libre. Ranged también usa separación.
5. **Escopeta 3 perdigones visibles**: el usuario esperaba tres, y la munición anterior de cinco se solapaba con el seguimiento agresivo de JACKPOT. Ahora: normal 3; BLACK JACK épico 6; legendario 12. Un cono simétrico por ataque, sin superposiciones; el guiado de la escopeta queda limitado a ±3° desde el lanzamiento para preservar los tres trazos, mientras otras armas retienen el seguimiento habitual de JACKPOT. Mantiene caída de daño y alcance corto.
6. **Chatarrería**. Se listan todos los tipos de armadura guardados en la mochila. Si la ranura correspondiente está vacía, la pieza se muestra deshabilitada con motivo explicativo, no desaparece. Nunca se permite apostar una pieza equipada.
7. **Música**. Nueva pista original *Fiebre del Casino*, 172 BPM, 44.65 s, jazz-funk/synth bailable y bucle, sin reutilizar melodías existentes. El volumen pasa de −15.5 a −4 dB, y el reproductor gestiona restauración tras pausa. Se incluye respaldo WAV mono si no carga OGG y preview MP3 externo.
8. **Sin rediseño de sprites**: continúa pendiente para cuando el gameplay sea sólido. Sin cambios en las probabilidades de botín ni en economía.

## Pruebas para ejecutar en Godot

`godot --headless --path . --script res://tests/PruebaEstabilidadMovil430.gd`

Se revisaron scripts, recursos y ZIP estáticamente. **No se ha podido validar reproducción/gestos ni IA en un dispositivo Android desde este entorno**. Conviene probar salas 9–11, 19–21 y 25–30 con escopeta JACKPOT y BLACK JACK; verificar música tras entrar y salir de cualquier menú.

---

### CAMBIOS_431.md

# ALL IN 4.31 — Progresión, economía y armas

Base: ALL IN 4.30. No incluye Gran Ruleta ALL IN ni nuevos sets, armas o amuletos.

## Economía

- Recompensa fija por sala normal completada: **10 monedas**, antes 8. Se abona solo una vez por sala; ninguna sala de jefe la recibe.
- Monedas por eliminación, conforme al número de sala:

| Sala | Antes | 4.31 |
|---|---:|---:|
| 1–20 | 4–7 | **4–7** |
| 21–30 | 4–7 | **6–9** |
| 31–40 | 4–7 | **8–11** |
| 41–50 | 4–7 | **10–13** |
| 51–60 | 4–7 | **12–15** |
| 61–70 | 4–7 | **14–17** |

A partir de la sala 21 aumenta +2 al mínimo y al máximo por bloque de 10 habitaciones. Se mantienen COBRAR por bloques (30,40,50,60...), costos de fusión, precios de apuestas y bonos de jefe (200, 250...).

## Armaduras y rarezas

- Mantiene la afinidad del set predominante (60/20/20) y el reparto suave antirrachas.
- Cuando alguna ranura de ese set queda por debajo de la mejor rareza que ya posees en otras ranuras, recibe **×2 peso de selección**. Se revisan mochila y equipo, por lo que una épica guardada no se interpreta como pieza faltante. No es una garantía de drop.
- Para tiradas de calidad en salas **40–55**: épica **10%** (antes 6%); sigue sin aparecer antes de sala 40. La protección por mala suerte se activa tras 25 tiradas de calidad válidas sin épico (antes 35), sin garantizar familia ni ranura.

## Armas y Chatarrería

- Dentro de un objeto de calidad, la cuota de categoría es **65% armadura / 23% arma / 12% amuleto**. Antes era 66.7% / 18.3% / 15%. La elección ocurre por categoría, sin depender del tamaño del catálogo.
- Si ya hay un arma Armas 2.0 equipada, los drops de armas tienen **45%** de elegir su tipo y **18.33%** para cada uno de los otros tres. Sin arma 2.0 equipada, reparto 25% cada una.
- **Chatarrería acepta armas de mochila**, incluidas armas antiguas comunes–legendarias, si llevas una de las cuatro armas 2.0 equipada. El resultado sigue la misma tabla de rareza y apuesta por lote de las armaduras. Por ejemplo, apostar una pistola épica con subfusil equipado puede dar 2 subfusiles raros por victoria. Una pieza legendaria apostada entrega 1 épica si gana; no se permiten apuestas de objetos equipados.
- Subfusil: factor de daño de 0.73 a **0.82** (+12.3% por proyectil). Sin cambios de cadencia ni cantidad de balas.

## Intacto

Los tres sets actuales, el audio de la 4.30, pantallas táctiles, IA y jefes, proporción vertical, pistola, escopeta, Desert Eagle, ruleta de nivel 25/25/25/25, pactos 60/40 y Chatarrería con sus probabilidades previas.

## Verificación

Prueba nueva: `tests/PruebaProgresionEconomia431.gd`, junto a las pruebas de regresión previas actualizadas para los valores actuales. Ejecutar en una instalación de Godot 4.7.2; el entorno de creación no dispuso del motor y por ello la compilación y ejecución Android aún necesitan verificación.

---

### CORRECCION_4221.md

# Corrección 4.22.1 — Análisis del problema

Archivo: `scripts/main/Main.gd`

Función: `_add_inventory_card`

Problema introducido durante el cambio 4.22:

```gdscript
        ascension_button.mouse_filter = Control.MOUSE_FILTER_PASS
    ascension_button.pressed.connect(_on_ascend_pressed.bind(uid))
        card.add_child(ascension_button)
```

La llamada `pressed.connect` se había desindentado, quedando fuera del `if` en el cual se declara `ascension_button`, mientras `card.add_child` permanecía dentro. Eso rompe la sintaxis y puede provocar varios errores de compilación en cascada.

Corrección:

```gdscript
    if lvl >= cap and DB.NEXT_RARITY.has(rarity):
        # ... inicialización y configuración del botón
        ascension_button.mouse_filter = Control.MOUSE_FILTER_PASS
        ascension_button.pressed.connect(_on_ascend_pressed.bind(uid))
        card.add_child(ascension_button)
```

No se modificó la lógica del inventario ni su economía.

Pendiente: ejecución real en Godot para validar todos los errores reportados.

---

### CAMBIOS_4241.md

# ALL IN 4.24.1 — Cambio puntual de ruleta de nivel

Solo se redistribuyeron las probabilidades de premios de nivel, de 35/30/20/15 a **25/25/25/25**.

| Premio | Probabilidad | Mejora |
|---|---:|---:|
| Daño | 25% | +4% |
| Cadencia | 25% | +4% |
| Movimiento | 25% | +3% |
| Velocidad de proyectiles | 25% | +6% |

Ningún otro sistema de combate, equipamiento, recompensas, inventario, economía o móvil fue cambiado.

Para verificar en Godot 4.7.2: `godot --headless --path . --script res://tests/PruebaRuletaEquitativa4241.gd`. En Android, comprueba los textos de la ruleta al subir de nivel.

Revisión del ZIP y chequeos estáticos realizados; ejecución del motor pendiente en el dispositivo del usuario.

---

### CAMBIOS_4281.md

# ALL IN 4.28.1 — Parche urgente: scroll de mochila

**Objetivo**: recuperar el desplazamiento vertical táctil de la mochila, sin alterar las mecánicas de la 4.28.

## Diagnóstico del código

Las tarjetas de inventario se componen de varios controles anidados (`VBoxContainer`, `HBoxContainer`, botones y etiquetas). Aunque los botones ya tenían `MOUSE_FILTER_PASS`, varios contenedores y etiquetas mantenían el filtrado predeterminado y podían interrumpir la propagación de los gestos antes de llegar al `ScrollContainer`. Al tener más ítems en la 4.28 y añadirse Chatarrería, el fallo impide administrar una mochila numerosa. El diagnóstico se fundamenta en inspección del proyecto; la causa exacta en Android deberá confirmarse ejecutándolo.

## Correcciones

- Los contenedores internos y las tarjetas utilizan `MOUSE_FILTER_PASS`; las etiquetas y separadores decorativos usan `MOUSE_FILTER_IGNORE`.
- Se conserva `MOUSE_FILTER_PASS` en los botones de equipar, fusionar, ascender y vender para no romper sus pulsaciones.
- Desplazamiento horizontal desactivado para que las tarjetas anchas no desvíen los gestos verticales.
- Barra vertical siempre visible y más ancha (22 px), usable como alternativa al arrastre.
- Umbral de arrastre ligeramente reducido: 6 px.
- Si el usuario arrastra mientras se cargan tarjetas (cinco por fotograma), no se restablece una posición anterior al terminar la carga.
- Incluida `tests/PruebaScrollMochila4281.gd` que verifica la estructura de los controles y que se puede desplazar una mochila con 40 objetos.

## Sin cambios

Armas 2.0, Chatarrería, tres conjuntos, probabilidades de pactos, enemigos, dificultad, monedas, botín y joystick de combate.

## Probar en Android

1. Abrir la mochila con 30–50 objetos y deslizar el dedo sobre el texto de las piezas y sobre los botones.
2. Comprobar que aparecen tarjetas al llegar al fondo; usar también la barra vertical.
3. Equipar, fusionar, vender y cambiar filtros. Abrir/cerrar Chatarrería y regresar a la mochila.
4. Confirmar que los botones todavía responden con un toque breve.

**Limitación**: no se pudo ejecutar Godot 4.7.2 en este entorno. Es un parche basado en revisión estática y requiere validación táctil en Android.

---

### CAMBIOS_4282.md

# ALL IN 4.28.2 — Hotfix de mochila Android

## Qué se corrigió

- Eliminados los `OptionButton` y sus menús emergentes: 9 filtros con botones táctiles directos, más clasificación cíclica.
- Encabezado de mochila reducido y botón **CERRAR Y JUGAR** visible en la cabecera. El resumen completo se consulta desde EQUIPO.
- Rehecha la captura del gesto vertical: identifica un dedo que inicia dentro del scroll y ajusta el desplazamiento con coordenadas locales del CanvasLayer. Evita que las tarjetas y sus botones se apropien del arrastre.
- Zona de arrastre de 10 px para diferenciar clic de swipe; las acciones del inventario ignoran las pulsaciones accidentales tras un swipe.
- Controles adicionales **▲ SUBIR / ▼ BAJAR**, útiles para pantallas y emuladores donde el arrastre todavía falla.
- Conserva la actualización del inventario en tandas de cinco tarjetas por fotograma. La restauración del scroll comprueba una generación de reconstrucción para evitar saltos tras cambiar de filtro.
- El estado de pausa se libera al cerrar la mochila incluso después de seleccionar filtros.

## Qué no se cambió

Balance de enemigos, equipo, armas 2.0, chatarrería, probabilidades, economía y controles de combate.

## Verificación

Se hizo inspección estática y de referencias. Se incluye `tests/PruebaMochilaTactil4282.gd` para ejecutar **en Godot 4.7.2**, que valida inventarios de 40 y 4 objetos, arrastre táctil sintético, filtros, orden, cierre y despausa. El motor Godot no está instalado en el entorno de elaboración; el funcionamiento en Android debe validarse en teléfono real.

---

### CAMBIOS_4283.md

# ALL IN 4.28.3 — Parche crítico: Chatarrería móvil

## Diagnóstico

En 4.28.2 se rediseñó **Mochila** para resolver sus bloqueos táctiles, pero **Chatarrería** todavía usaba la interfaz antigua: `ScrollContainer` sin captura explícita del gesto sobre tarjetas, botones dentro del scroll y un panel con tamaño mínimo que podía crecer verticalmente al añadir textos o resultados. El botón de salida podía desplazarse fuera del área visible.

## Cambios

- Rehecha la Chatarrería dentro de un panel limitado al área útil (540×960 de referencia), con encabezado **CERRAR Y JUGAR** fijo, visible y procesado durante pausa.
- **Desplazamiento vertical táctil** por identificador de dedo sobre la lista: separa arrastre de pulsación; los botones de apostar no se activan por un desplazamiento.
- Botones auxiliares **▲ SUBIR / ▼ BAJAR** y **◀ MOCHILA** accesibles sin desplazarse.
- El scroll horizontal se desactiva, la barra vertical siempre se muestra y su anchura aumenta para facilitar la interacción móvil.
- Las tarjetas se siguen construyendo en lotes de cinco por fotograma. Cuando se refresca tras una apuesta, se conserva la posición salvo que el usuario desplace la lista.
- El estado de arrastre, la apuesta pendiente y el diálogo de confirmación se limpian al salir o cambiar de menú; el mundo se despausa correctamente.
- Se limita a dos líneas el resumen de resultado para que una cadena larga no empuje la lista o el botón de cierre; el resultado completo queda en el tooltip.
- Prueba de regresión: `tests/PruebaChatarreriaTactil4283.gd` (40 grupos y una mochila pequeña).

## Sin cambios

Probabilidades, costo y recompensas de la Chatarrería; las cuatro armas, 48 armaduras, pactos, enemigos, economía y comportamiento de la mochila 4.28.2.

## Verificación

Inspección estática y comprobación de integridad del ZIP; la prueba automatizada está lista para correrse en Godot 4.7.2. En este entorno no hay ejecutable de Godot ni dispositivo Android; la funcionalidad táctil requiere confirmación en el teléfono.

---

### CAMBIOS_4311.md

# 4.31.1 — Primer cambio visual aprobado

HUD de salud: iconos pixel art con estados lleno/vacío, variantes extra preparadas pero inactivas hasta que exista una mecánica de salud máxima adicional. Solo se cambia Main.gd, project.godot y se incorporan PNG / prueba de HUD. Toda la jugabilidad previa 4.31 se conserva.

---

### CAMBIOS_4312.md

# ALL IN 4.31.2 — Diagnóstico de ralentización (Android)

## Hallazgos verificados (diferencia 4.31 → 4.31.1)

- Solo cambió `scripts/main/Main.gd`, `project.godot` y se incorporaron cuatro PNG 28x28, una prueba y documentación.
- No cambió `Player.gd`, `BasicEnemy.gd`, `AudioDirector.gd`, el OGG, los valores de velocidad, `Engine.time_scale` ni los temporizadores.
- `RunManager.health_changed` se emite ante eventos de salud/equipo/escudo, NO cada frame.
- Por tanto, no se ha demostrado que el HUD sea el origen de la ralentización, y no podemos reproducirla sin el móvil.

## Mejoras de bajo riesgo

- Cache de corazones: las texturas y medidas solo se reasignan cuando cambian, no en llamadas repetidas con el mismo estado.
- Audio: el estado `stream_paused` se comunica al mezclador únicamente cuando realmente cambia, evitando trabajo redundante a cada frame.
- Botón **FPS: OFF/ON** en la primera fila de Pausa, sin aumentar su altura ni cambiar controles de movimiento.
- Overlay visible sobre el combate, que no intercepta toques, con FPS, FPS mínimo, duración estimada de un fotograma, enemigos activos, `Engine.time_scale`, `AudioDirector.music.pitch_scale` y estado de música.
- Sin cambios en la lógica de apuestas, drops, monedas, armas, vida, físicas ni apariencia del corazón.

## Cómo comparar

1. Abre Pausa y pulsa `FPS: OFF` para convertirlo en `FPS: ON`.
2. Continúa. Observa FPS durante ~15 segundos en una sala sencilla, sin abrir menús.
3. Repite el test en una sala con varios enemigos y disparos. Hazlo con el mismo dispositivo y ajustes.
4. Si el movimiento y la música van lentos incluso con FPS estable, anota `Tiempo`, `Audio`, y el número de FPS; eso apuntaría a otra causa que no sería un simple atasco gráfico.
5. Repite la situación en v4.31.1 y v4.31, en la medida de lo posible. **No se puede demostrar la causa de un fallo intermitente solo con el diff del código.**

## Verificación y limitaciones

Se inspeccionaron los cambios, las 4 imágenes y el archivo OGG, se añadieron pruebas de regresión y se verificó el ZIP. No hay una ejecución del motor Godot/Android disponible en este entorno: la mejora no debe considerarse confirmación de haber eliminado todas las ralentizaciones.

---

### CAMBIOS_4313.md

# ALL IN 4.31.3 — Moneda Infernal animada (solo visual)

- Base exacta: ALL IN 4.31.2 con diagnóstico de FPS y corazones pixel art.
- Se reemplaza el símbolo `$` del HUD compacto por una moneda dorada con cara de demonio.
- Animación de seis fotogramas transparentes, textura filtrada por NEAREST, 0.14 segundos por fotograma.
- Los fotogramas se cargan una vez y se actualiza únicamente un TextureRect del HUD; al pausar se congela su animación.
- No hay monedas recogibles en el suelo en el juego actual: las recompensas ya se depositaban directamente. No se crean nuevos pickups ni se modifican ingresos, drops ni costos.
- La moneda no tiene hitbox y toda la interfaz conserva MOUSE_FILTER_IGNORE.
- Se incluye el spritesheet 3x2 (64 px por celda) y los seis PNG RGBA independientes.
- Se conserva el medidor opt-in de FPS de 4.31.2 para comprobar fluidez en Android.
- Pruebas manuales: entrar al juego, ver icono girar junto al saldo; recibir monedas por derrotar enemigo y completar sala; abrir Pausa, confirmar que se congela; cerrar y reanudar.
- **Limitación:** se verificó estructura e imágenes estáticamente; el motor Godot no está instalado en el entorno y Android no se ha podido ejecutar.

---

### CAMBIOS_4314.md

# ALL IN 4.31.4 — Fichas de botín infernales (presentación)

- Sustituye el dibujo de rombo por **24 combinaciones de ficha de casino** (4 rarezas × 6 iconos).
- Gráficos extraídos y limpiados de la hoja pixel art aprobada; recursos transparentes en `assets/loot/`.
- Levitación discreta ±2 unidades; luz de contención corta y anillo, cada rareza con color propio.
- Se dibuja por dos `Sprite2D` y **solo cuatro atlas compartidos**, sin `queue_redraw()` continuo.
- Rareza y ranura vienen de `ItemDatabase`; las recompensas especiales de jefe usan icono dorado de arma (solo visualmente).
- El botín aparece, se recoge, se almacena y se vende con las **mismas reglas** que en 4.31.3.
- **No modifica:** enemigos, armas, corazones, moneda animada, tasas de aparición, economía, fusión, tacto ni música.

## Validación en Android
1. Dejar caer una pieza común y comprobar que la ficha cambia según casco/pecho/pantalón/bota/arma/amuleto.
2. Conseguir raras, épicas y legendarias: el color y halo coinciden con la rareza.
3. Comprobar movimiento, anillo, recogida al acercarse y mochila llena (permanece en suelo).
4. Abrir/cerrar Pausa o Mochila: la animación se detiene y se reanuda sin bloquear controles.
5. Medir FPS con la opción de diagnóstico de 4.31.2 cuando haya varios drops.

El análisis de referencias y la estructura del proyecto pueden validarse sin motor, pero las pruebas reales de Android/Godot son necesarias para confirmar ejecución.

---

### CAMBIOS_4315.md

# ALL IN 4.31.5 — Corrección visual y legibilidad (2026-11-06)

Base: 4.31.4. Solo se modifica la presentación de botín, el contador de monedas y el feedback visual de los corazones.

- **Corrección crítica:** el loot usa `z_index=1` por encima del suelo (0), pero por debajo del jugador y enemigos (`z_index=2`) y proyectiles (`z_index=3`); los efectos de impacto están en `z_index=4`. Esto no depende del orden de creación en el árbol de nodos y evita ocultar personajes, disparos y el propio loot. Su radio de recogida y reglas de inventario no cambian.
- **Glow:** cuatro imágenes RGBA de 64×64 reemplazadas por auras suaves y una pequeña elipse luminosa de suelo; sin cilindro sólido. Conserva la levitación de 2 píxeles y su brillo discreto.
- **HUD:** moneda animada aumentada de 28 a 34 píxeles y texto del saldo de 16 a 19. Se conservan los seis fotogramas.
- **Corazones:** solo tras perder un corazón de verdad, su icono vacío da un destello rojizo de 0.22 s y vuelve al tamaño normal; no se anima al bloquear, evadir ni cambiar de equipo.
- **No cambió:** IA, enemigos, daño, drops, porcentajes, economía, mochila, joystick, música ni colisiones.

## Verificación

La comparación de archivos y la integridad del ZIP se han revisado por separado. No se dispone de una ejecución real de Godot en el contenedor, por lo que el comportamiento final debe validarse en Android.

---

### CAMBIOS_4316.md

# ALL IN 4.31.6 — Estabilidad de atlas y optimización conservadora

## Causa del defecto visual

Los cuatro archivos `chips_*.png` de la 4.31.5 tenían sprites de 48×48 extraídos y escalados con regiones insuficientes. En múltiples categorías, la imagen original quedaba **recortada por la derecha y por abajo antes de que Godot la cargara**. El atlas ya estaba incompleto. No era una falla de probabilidad de loot, profundidad Z ni renderizado de Godot.

## Corrección de gráficos

- Se reconstruyeron **24 fichas** usando la hoja de pixel art aprobada por el usuario, detectando el objeto completo y escalando sin suavizado.
- Cada celda es ahora de **56×56** (cuatro atlas de 336×56), con al menos 4 píxeles de margen transparente, sin recortes.
- Se conservan ángulo, iconos, rarezas, halo suave separado, capa por debajo de personajes y levitación.
- No se cambió ninguna imagen de HUD, audio, escena de enemigo, cámara ni regla de botín.

## Optimización limitada y auditable

1. `DroppedItem.gd`: cálculo de proximidad por distancia al cuadrado (sin raíz cuadrada en cada fotograma); eliminación de un contador no usado; pausas, capas y filtros de textura quedan declarados en la escena en vez de repetirse al instanciar el objeto.
2. `Projectile.gd`: reutilización por proyectil de `PhysicsRayQueryParameters2D` y del arreglo de exclusión; se siguen usando exactamente la misma máscara 18, la misma detección de cuerpos y las mismas reglas de impacto, penetración y guiado.
3. No se tocaron IA, balance, movimiento, economía, inventario ni controles táctiles. Los problemas potenciales de esos subsistemas requieren pruebas separadas, no una refactorización general.

## Comprobaciones

- Atlases RGBA con 24/24 celdas, iconos por ranura y margen transparente verificados fuera de Godot.
- ZIP completo e integridad de recursos revisados.
- Pruebas `tests/PruebaFichasLoot4314.gd` y `tests/PruebaIntegridadAtlas4316.gd` actualizadas para el nuevo atlas.
- Godot y pruebas reales en Android no disponibles en este entorno: compilación y rendimiento requieren ejecución en el teléfono.

---

### CAMBIOS_4317.md

# ALL IN 4.31.7 — IMP animado (primera integración visual)

- La hoja APROBADA de IMP se dividió en 13 fotogramas pixel art 64x64 RGBA, con fondo transparente y escala uniforme.
- Se mantuvieron cola de punta de flecha, ojos amarillos y cuerpo rojo en persecución y zarpazo.
- Solo `scenes/enemies/BasicEnemy.tscn` contiene un `AnimatedSprite2D` (4 frames persecución, 4 zarpazo).
- Al hacer contacto, se reproduce zarpazo; NO se añade anticipación ni se retrasa el daño.
- Al morir, 2 frames de colapso más 3 de humo: FX independiente que se autodestruye sin retrasar el conteo de muertes.
- Sin animación de quietud ni sprites de daño; modulación rojiza breve al recibir impacto.
- `BasicEnemy.gd` sigue siendo clase padre de RangedEnemy, SplitterEnemy y SplitMinion, pero el cambio solo se activa si la escena contiene el nodo `ImpSprite`.
- Se preservaron economía, botín, armaduras, armas, proyectiles, joystick, inventario, audio y probabilidades.
- Prueba adicional en `tests/PruebaIMP4317.gd`.

## Validación pendiente
No se dispone de un ejecutable de Godot/Android para probar compilación, tiempo real, orientación y control táctil aquí. Ejecutar primero salas 1-5 y comprobar movimiento, zarpazo, tinta de daño, muerte y drops; después salas 25+ para confirmar que los otros enemigos no cambiaron.

---

### CAMBIOS_4319.md

# ALL IN — Etapa 4.31.9 · Cráneo Ígneo

Base: ZIP COMPLETO `ALL_IN_Etapa4_31_8_IMP_Polish_Pass(1).zip` proporcionado por el usuario.

## Cambio visual aislado
- El enemigo rosado conserva su IA, salud, movimiento, ritmo de disparos y colisiones.
- Nuevo Cráneo Ígneo: cuatro fotogramas de flotación, cuatro de ataque, cinco de muerte.
- Sombra circular animada independiente y flotación suave del cuerpo, sin mover la hitbox.
- Bolas de fuego: cuatro fotogramas. El script hereda la física, daño, velocidad, máscara de choque y duración del proyectil anterior.
- La muerte aparece como un FX autónomo sin hitbox ni grupo de enemigos, mientras el enemigo entrega el loot y se elimina inmediatamente.
- Otros enemigos (IMP, Incubador, mini-cráneos) y jefe no cambian sus sprites ni proyectiles.

## Integración
- `scenes/enemies/RangedEnemy.tscn` y `scripts/enemies/RangedEnemy.gd`: sprite y sombra del cráneo; animaciones por estado.
- `scenes/enemies/IgnelDeathFX.tscn`, `scripts/enemies/IgnelDeathFX.gd`: muerte independiente.
- `scenes/combat/IgnelFireball.tscn`, `scripts/combat/IgnelFireball.gd`: nueva apariencia del proyectil exclusivamente para Cráneo Ígneo.
- `assets/enemies/ignel/*`: imágenes PNG RGBA de 64×64 px con fondo transparente y SpriteFrames.

No se han modificado economía, armas, Pactos, inventario, daño ni controles.

---

### CAMBIOS_43110.md

# ALL IN 4.31.10 — IMP: sprites corregidos

**Base de trabajo:** ALL IN 4.31.9 (Cráneo Ígneo integrado).

- Se sustituyeron únicamente los 15 PNG del IMP (4 persecución, 4 zarpazo, 2 caída, 5 humo) utilizando la última hoja aprobada, que tiene canal alfa real.
- Se usó la cuadrícula 4×4 original, transparencia verificada, escala común y lienzos de 64×64 píxeles con márgenes.
- Se evitó el fondo blanco de generaciones anteriores. Los píxeles con alfa residual bajo se hicieron totalmente transparentes y la reducción se hizo sin suavizado para conservar el pixel art.
- Se mantiene la muerte como FX visual independiente y con la duración ya definida en 4.31.9.
- No cambian IA, vida, daño, ataques, colisiones, economía, inventario, UI, jefe, Incubador ni Cráneo Ígneo.

**Validación realizada:** integridad de los 15 PNG; canal alfa y márgenes; referencias a recursos; comparación de archivos respecto a 4.31.9; integridad del ZIP completo.

**Pendiente:** prueba ejecutada en Godot y Android para confirmar el aspecto y las animaciones durante una partida real.

---

### CAMBIOS_43111.md

# ALL IN 4.31.11 — Cráneo Incubador y mini-Cráneos Ígneos

**Base real:** ALL IN 4.31.10 (IMP sprites corregidos), proporcionada por el usuario.

## Arte
- El `SplitterEnemy` verde existente representa ahora al **Cráneo Incubador**: cápsula demoníaca cerrada, dorada/marfil, pica negra en la frente, ojo magenta y cuernos; **sin mini-cráneos visibles dentro**. Sigue apareciendo en la progresión original desde las salas 25+.
- `IncubatorSprite`: 4 fotogramas de vuelo/flotación a 64x64 PNG RGBA con alfa real; `IncubatorShadow`: sombra independiente animada en 2 fotogramas.
- Muerte/liberación: 5 fotogramas de grietas, explosión y humo, mediante `IncubatorDeathFX`, una escena visual sin colisiones ni grupo `enemies`.
- Al morir, la mecánica ya existente continúa liberando **exactamente 2** `SplitMinion`; ahora se ven como **mini-Cráneos Ígneos** con los sprites originales de Ignel reducidos y sombras independientes. Sus disparos, daño, salud, botín y velocidades NO cambian; su muerte tiene un pequeño efecto visual separado.
- Se preservan los 15 sprites y animaciones corregidos del IMP, además de todos los recursos del Cráneo Ígneo grande.

## Sin cambios de gameplay
- `CollisionShape2D`: Incubador radio 15, minis radio 9 (sin cambios).
- Sin cambios en IA, navegación, frecuencia de aparición, economía, drops, cálculo de daño, armas, boss, UI, Pactos, música, controles, Android o integridad de partida.
- El Incubador se elimina y entrega botín en el mismo fotograma en que muere; las animaciones no bloquean la sala.

## Verificación
- Integridad de los 11 nuevos PNG 64x64 (4 vuelo + 5 muerte + 2 sombra), canal alfa y transparencia en bordes.
- Se incluyó test estructural `tests/PruebaIncubador43111.gd`.
- **Pendiente:** ejecutar el proyecto en Godot 4.7.2 / Android para validar las animaciones durante combate y medir rendimiento real.

## Cómo probar
1. Abre `project.godot` en Godot 4.7.2.
2. En las salas 25+, comprueba la cápsula flotante y su barra de vida.
3. Destrúyela: una sola muerte + máximo un loot, explosión visual y exactamente dos mini-Cráneos Ígneos.
4. Comprueba que los mini siguen persiguiendo/recolocándose y disparando igual que antes; al morir siguen dando sus monedas/XP de costumbre.
5. Vuelve a salas iniciales: IMP y Cráneo Ígneo permanecen como en 4.31.10.

---

### CAMBIOS_43112.md

# Cambios ALL IN 4.31.12

- Se mantiene el sprite aprobado del Cráneo Incubador de 4.31.11 y el contenido de 4.31.10.
- Atajo de diagnóstico F10 en Godot editor para invocar al Incubador y observar la liberación de dos mini-Cráneos Ígneos sin avanzar hasta la sala 25.
- Las muertes de F10 se contabilizan como oleada adicional para no despejar la habitación antes de tiempo.
- Corregido el límite inferior de velocidad de los minis en las salas <25 por F10; la progresión normal es idéntica.
- Se marcó debug_used al usar F10 para evitar registros de récord de una partida de test.
- Documentada la importación y las limitaciones de validación.

---

### CAMBIOS_43114.md

# ALL IN 4.31.14 - Apostador fiel al concepto / primera etapa

BASE: ALL IN 4.31.12, versión jugable aprobada. Se DESCARTA el arte de la 4.31.13.

INTEGRADO:
- Cuerpo del Apostador recortado directamente de la hoja conceptual aprobada.
- Cuatro fotogramas reales de respiración frontal (idle); ocho orientaciones básicas tomadas del concepto.
- Sprites PNG transparentes, atlas con 64x64 por celda, filtro nearest.
- Orientación visual en la dirección del disparo real, sin objetos de arma falsos.
- Se mantienen la colisión, movimiento, armaduras, vida, i-frames, economía, jefe y enemigos de la 4.31.12.
- Feedback de daño: mismo temporizador hurt_cooldown del juego existente.

NO INCLUIDO AUN (intencional):
- Animación de caminata/carrera completa, poses de disparo, muertes de cara/espaldas.
- Sprites de armas: NO hay armas falsas; se harán por separado y se aprobarán visualmente.
- Skin alternativas y cambios de interfaz, sonido o balance.

PRUEBA: extraer ZIP; importar project.godot en Godot 4.7; abrir juego y comprobar
fidelidad del rostro/traje, tamaño y ocho direcciones. Los disparos siguen activos,
aunque el arma visual queda pendiente de una aprobación de arte.

La hoja referencia original es la fuente del sprite; no una recreación manual.

---

### CAMBIOS_43115.md

# ALL IN 4.31.15 - El Apostador / idle y 8 direcciones

BASE: 4.31.14 (misma partida, misma logica de combate; sprites revisados).

REEMPLAZO LIMPIO:
- Eliminados los atlas viejos assets/player/skins/apostador/idle.png y facing.png.
- Un solo atlas real de 8 filas (direcciones) x 4 columnas (reposo), de 64x64 por celda.
- Las cuatro poses frontales provienen de la revision visual v2 aprobada.
- Las otras siete vistas provienen de esa misma revision; tienen 4 celdas
  compatibles con el futuro sistema de skins y una respiracion de 1 px.
- El tercer cuadro frontal incluye la nubecita de respiracion aprobada.
- Sin borde blanco, sin armas falsas, sin sprites de pistola ni codigo adicional.
- El personaje visible mide aprox. 42 px de alto como el IMP (~38-39 px).
- Un unico Sprite2D y una sola funcion de actualizacion visual.
- Las fisicas, armas mecanicas, enemigos, economia y salud no cambian.

CONTENIDO DEL ZIP: una carpeta raiz, project.godot, escenas, scripts, assets,
sonido y tests originales. PREVIEW_APOSTADOR_43115.png es solo ilustrativo.

PRUEBA: importar project.godot en Godot, comprobar el tamano junto al IMP,
la cara, los ojos, reposo y hacia que direccion mira al moverse/disparar.
No se han agregado aun animaciones de caminar, disparo ni muerte (proximas fases).

NOTA: no se pudo ejecutar Godot en este entorno. La integridad del archivo y
las referencias se revisaron de forma estatica; la prueba de juego queda pendiente.

---

### CAMBIOS_43116.md

# ALL IN 4.31.16 — Reparacion puntual de los recortes del Apostador

Base directa: ALL IN 4.31.15 aprobada por el usuario.

- Se corrigieron los limites de extraccion de las poses ESPALDAS y DERECHA.
- Por compartir el mismo defecto de recorte, se ajustaron tambien ARRIBA-DERECHA
  y ABAJO-DERECHA, sin modificar sus poses ni redisenar el personaje.
- La extraccion recorta el fondo por color local en lugar de cortar la silueta
  con una linea vertical que eliminaba parte del cabello.
- Mantiene el atlas de 256x512 (8 direcciones x 4 fotogramas, celdas de 64x64).
- Conserva exactamente los cuatro fotogramas del idle y las otras direcciones.
- No se crean scripts, nodos ni shaders; Player.gd y escenas son identicos.
- La escala frente al IMP, control, armas, colisiones, enemigos y economia son
  las mismas que en la 4.31.15.
- Incluye PREVIEW_APOSTADOR_43116.png para inspeccionar ANTES/DESPUES.

SIGUIENTE TRABAJO (NO INCLUIDO): caminar, dos muertes y 4 sprites provisionales.

VALIDACION: verificacion estatica de transparencia/atlas, recursos y empaquetado.
No se ejecuto Godot en este entorno; comprobar visualmente en PC/Android.

---

### CAMBIOS_43117.md

# ALL IN 4.31.17 — Caminata de El Apostador

Base: 4.31.16 (Apostador con recortes corregidos), ya validada visualmente.

## Incluido
- 8 direcciones de caminar, 4 fotogramas por direccion (32 en total).
- Derivados del pixel art aprobado para preservar cara, ropa, color, escala y silueta.
- Se mantiene EXACTAMENTE el idle de 4 cuadros, incluyendo su pequena exhalacion.
- Un solo atlas RGBA de 256x1024: filas 0-7 idle, filas 8-15 caminata.
- Un solo Sprite2D: Player.gd intercambia la fila segun la velocidad real.
- Movimiento se orienta por input, evitando caminar hacia atras cuando el
  autoataque elige un objetivo a espaldas del jugador.
- El cambio es visual: las stats, hitboxes, dano, enemigos, HUD y balance NO cambian.
- Los 4 tipos de arma existentes (pistol, shotgun, smg, deagle) conservan
  comportamiento de combate y proyectiles, pero NO tienen sprite de arma
  sostenida ni placeholder aprobado. NO se ha dibujado ningun arma al cuerpo.

## No incluido (pendiente por disenar/aprobar)
- Poses de ataque/apuntado con capa de arma independiente.
- Daño y muerte con sprites dedicados.
- Armas visuales independientes (pistola, escopeta, SMG y Deagle).

## Como probar
1. Extraer este ZIP; abrir project.godot en Godot 4.7.2.
2. En la sala, mover WASD o joystick en cada una de las ocho direcciones.
3. Soltar el movimiento y comprobar que regresa al idle, incluida la exhalacion.
4. Moverse mientras auto-dispara para revisar la orientacion de la caminata.
5. Revisar escala/cabello/pies y comprobar en Android el joystick.

## Verificacion
Revision estatica de atlas, transparencia, rutas y ZIP. No se pudo ejecutar
Godot en este entorno; las pruebas del juego en PC y Android siguen pendientes.

---

### CAMBIOS_43118.md

# ALL IN 4.31.18 — Apostador: feedback de daño A + destello rojo

Base de trabajo: ALL IN 4.31.17, caminata aprobada.

## Agregado
- 32 fotogramas de reacción (4 por 8 direcciones), derivados de los sprites
  exactos del Apostador ya aprobado; no se reemplazó su cara ni su ropa.
- Reaccion al daño: golpe inmediato + destello rojo de 0.10 segundos,
  retroceso *solo visual*, recuperacion a los 0.32 segundos.
- Parpadeo de invulnerabilidad reutilizando un solo BodySprite; dura
  exactamente el temporizador existente (1.25 s base, pactos intactos).
- Atlas unico de cuerpo de 256x1536 (filas 0..7 reposo, 8..15 caminata,
  16..23 daño). Ningun arma dibujada en el personaje.
- Se retira el antiguo aro que aparecia al recibir golpes, ya redundante.

## Intacto
- Todos los fotogramas originales de idle y caminata, byte por byte.
- Estadisticas, colisiones, IA enemiga, armas, proyectiles, interfaz,
  balance, vida y temporizador de invulnerabilidad.
- Los sprites de arma siguen pendientes: no existen placeholders aprobados.

## Prueba
1. Importar project.godot de la carpeta extraida; iniciar el juego.
2. Acercarse al IMP; al recibir golpe debe aparecer destello rojo, retroceso
   visual corto y parpadeo hasta terminar los i-frames.
3. Comprobar que el movimiento funciona durante la invulnerabilidad; el
   retroceso NO empuja al jugador ni altera hitbox o velocidad.
4. Probar con distintas orientaciones y en Android.

## Control de calidad
Se inspeccionaron atlas, limites, transparencia, referencias y contenido ZIP.
No hay un ejecutable de Godot disponible en este entorno para la prueba jugable.

---

### CAMBIOS_43119.md

# ALL IN 4.31.19 — Variante C: daño dramático con tambaleo

Basado en 4.31.18 (variante A), que queda disponible por separado. Esta variante C es para comparación y NO sustituye la opción A aprobada definitivamente.

## Solo arte y lógica de presentación
- 8 poses de daño por cada una de las 8 direcciones (64 fotogramas): impacto,
  retroceso, desestabilización, tambaleo, rodillas flexionadas, agachón,
  recuperación parcial y casi erguido.
- El estado de daño dura la totalidad de `hurt_cooldown`; se calcula
  como proporción del tiempo de invulnerabilidad YA EXISTENTE.
- La postura no vuelve por completo a idle/caminata hasta que las
  invulnerabilidades terminen. Cambios de duración por Pactos funcionan
  automáticamente, sin otro temporizador.
- Destello rojo de impacto ~0.10 s; parpadeo posterior sobre la animación.
- Un solo Sprite2D, un único atlas; filas 0-7 idle, 8-15 caminar,
  16-23 daño C (8 columnas). Sin armas visuales ni placeholders.
- El sprite es sólo presentación; NO desplaza al jugador ni altera la
  física, las colisiones, el daño ni la velocidad.

## Sin cambios
- Píxeles originales de idle/caminata: exactamente idénticos.
- Escenas, enemigos, economía, balance, equipamiento, controles,
  mecánicas de ataque y duración base de invulnerabilidad: intactos.

## Prueba
1. Cargar `project.godot` y jugar normalmente.
2. Dejar que un IMP dañe al Apostador.
3. Observar impacto rojo, desequilibrio fuerte y caída/agachón.
4. Durante las i-frames debe seguir tambaleándose sin perder control.
5. Cuando se incorpora totalmente deja de ser invulnerable.
6. Comparar con la versión 4.31.18 (Propuesta A) y elegir una.

El ZIP y las referencias de recursos pasan revisión estática. No se ha
podido ejecutar el motor Godot desde este entorno.

---

### CAMBIOS_43120.md

# ALL IN 4.31.20 - EL APOSTADOR: DANO C v2 (equilibrio)

Base jugable: 4.31.19. Este paquete completo reemplaza la animacion C anterior.

- 8 orientaciones; cuatro sprites nuevos por orientacion, extraidos del concepto aprobado (no deformaciones calculadas).
- Impacto rojo; ojos cerrados y dientes apretados; se tambalea sobre una pierna intentando no caerse.
- Se mantiene inestable durante TODA la invulnerabilidad existente, incluso si los pactos cambian su duracion.
- Volvera a estar erguido EXACTAMENTE cuando desaparezcan las i-frames. Sin nuevo reloj de jugabilidad.
- Un unico atlas player de 256x1536 (las secciones idle y caminar no se retocan).
- No incluye sprites de armas; las mecanicas de armas se conservan.
- No altera movimiento, estadisticas, corazon, dano, hitboxes, enemigos, RNG, economia ni pactos.

PRUEBA EN GODOT: abrir project.godot, iniciar partida, dejar que un IMP haga dano.
Revisar destello, expresion de dolor, pierna en el aire y vuelta a postura al terminar la invulnerabilidad.
Las variantes A (4.31.18) y C anterior (4.31.19) siguen disponibles en sus ZIP originales para comparar.
Comprobacion: integridad ZIP y rutas de recursos; no se ha ejecutado Godot dentro de este entorno.

---

### CAMBIOS_43121.md

# ALL IN 4.31.21 — MUERTE B (DE ESPALDAS)

Basado en ALL IN 4.31.20, a partir de la PRIMERA hoja de referencia de animaciones
aportada y elegida por el usuario ("Referencia de animaciones del Apostador(1).png").

- Nueve fotogramas de muerte B; extracción de la fila exacta de la referencia original.
- Arte transparente, misma escala en los 9 cuadros, no hay estiramientos, deformaciones,
  algoritmos que cambien proporciones ni nueva interpretación del rostro.
- Un atlas adicional 3×3 (96×96 por cuadro), reutilizando el Sprite2D del personaje.
- Comienza con impacto y dolor C v2; continúa con caída hacia atrás y estrellas.
- Al llegar salud a cero se congela la arena y se reproduce la cinemática (1.48 s).
- El menú de ruleta 50/50 y/o el resumen de partida aparecen SOLO al concluirla.
- Si falla la ruleta, la muerte no vuelve a reproducirse.
- Al revivir, el sprite vuelve al atlas normal y obtiene la protección existente.
- Se mantiene el 50/50 y todas las mecánicas, niveles y atributos del juego.
- Aún NO se ha integrado Muerte A ni la aleatoriedad; solo Muerte B para evaluar.

PRUEBA: abre project.godot, recibe daño mortal, observa caída B completa,
ruleta y eventual resurrección. Revisar proporciones, transición y estrellas.
No se ha ejecutado el proyecto en Godot en este entorno.

---

### CAMBIOS_43122.md

# ALL IN 4.31.22 — Corrección puntual de la Muerte B

- Se corrigió SOLO el cuadro 9 de 9, recuperando la silueta completa de la cabeza, cuerpo y extremidades desde la referencia original.
- La causa era un recorte vertical corto y una máscara que descartaba zonas oscuras del cuerpo.
- Se preservan los otros ocho cuadros, el ritmo de animación, las estrellas y todas las mecánicas, scripts y lógica de ruleta de la 4.31.21.
- Prueba: recibe daño mortal, mira la caída B y comprueba el cuadro final antes del menú.
- Pendiente de ejecutar y validar visualmente en Godot.

---

### CAMBIOS_43123.md

# ALL IN 4.31.23 — El Apostador: Muerte A y Muerte B

Base: proyecto completo ALL IN 4.31.22.

- Muerte A: 8 fotogramas extraidos directamente de la hoja PIXEL ART
  «Hoja de referencia del apostador pixel art(1).png» que aprobo el usuario.
  Conserva rostro, expresion, equilibrio sobre una pierna, caida de cara y polvo.
- Muerte B: exactamente los PRIMEROS 8 fotogramas previamente probados;
  eliminado el 9º fotograma y su textura 3x3 antigua.
- Dos atlas transparentes 4x2 de 96x96 por celda. Sin cambio de escala por
  fotograma ni deformaciones de Sprite2D.
- Cuando el golpe es letal, se reutiliza primero el dano C v2 y se elige
  aleatoriamente A o B. Queda bloqueado el combate durante la cinemática.
- La ruleta de segunda oportunidad o el resumen aparecen DESPUES de terminar
  los 1.48 segundos de cinematica. Revivir restablece el sprite normal.
- Si pierde la ruleta, NO se reproduce otra vez la muerte vista.
- El 50/50 de resurreccion sigue intacto e independiente de la eleccion A/B.
- Sin cambios a idle, caminata, impacto C v2, enemigos, armas, IA, economia,
  corazones, colisiones, tiempos de invulnerabilidad, pactos ni balance.

Prueba manual en Godot: recibir muerte mortal varias veces, observar la seleccion
aleatoria A/B, confirmar que B se queda en fotograma 8, comprobar que el menu
no aparezca hasta acabar y que resucitar restaure el sprite normal.

Validacion en este entorno: ZIP, transparencia, orden de atlas y referencias de
recursos. No se ha ejecutado Godot.

---