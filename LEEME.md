# MMORPG Táctico — Demo de combate (Godot 4)

## Cómo abrirlo
1. Descomprimí esta carpeta donde quieras (por ejemplo `Documentos\mmo_godot`).
2. Abrí Godot (el .exe que **no** dice "console").
3. En el Administrador de proyectos tocá **Importar**, buscá la carpeta y elegí el archivo `project.godot`.
4. Tocá **Importar y editar**. La primera vez tarda unos segundos.
5. Para jugar, apretá **F5** o el botón ▶ de arriba a la derecha.

## Controles (PC)
- **WASD**: moverte · **clic izquierdo** o **Espacio**: ataque básico
- **Mantené 1 2 3 4** (o Q E R F): aparece el indicador; apuntá con el mouse y **soltá** para lanzar. Clic derecho cancela
- **Clic derecho + arrastrar** o **flechas**: girar la cámara · **rueda**: zoom
- **P**: puntos de habilidad · **O**: aceite del básico (fuego / rayo)

## Qué hay adentro
- `scripts/data.gd`: clases, tipos de arma, habilidades y enemigos. Para cambiar números (daño, enfriamiento, vida) se toca este archivo.
- `scripts/main.gd`: todo el juego (mundo, cámara, combate, mundo vivo e interfaz).
- El progreso (maestría y puntos) se guarda solo en la carpeta de usuario de Godot.

Probado con Godot 4.7.2 y renderizador Compatibility (anda con gráficos integrados).

## Héroes con modelo 3D
- Si existe `assets/heroes/<clase>.glb` (por ejemplo `tanque.glb`), el juego usa ese modelo con sus animaciones en vez de la figura provisoria.
- Animaciones que busca: `idle`, `run` (correr; si falta usa `strafe`), `attack` (básico), `skill` (habilidades) y `death`.
- La espada y el escudo se agregan aparte, agarrados a los huesos de las manos (`mixamorig_RightHand` / `mixamorig_LeftHand`).

## El mapa: corazón del Imperio de la Luz (1 × 1 km)
- `scripts/terrain.gd` arma el relieve: cordillera nevada al norte, río que baja al lago del este, bosque al este, cañadón seco al oeste, campos de cultivo al sur y la capital **Lumen** en el centro (zona segura).
- Los caminos salen de Lumen hacia los cuatro puntos cardinales.
- `shaders/terreno.gdshader` le da textura al suelo y `shaders/agua.gdshader` mueve el agua.
- Arriba a la derecha hay un minimapa (punto amarillo = vos, rojos = ogros).
- La primera vez que abre, el mundo tarda unos segundos en generarse.

## Pasto alto, muros y dash
- **Pasto alto:** si estás adentro, los enemigos no te ven (los que te perseguían te pierden de vista). Atacar te revela un segundo. Se puede quemar, y **se corta con ataques de espada** (básicos cuerpo a cuerpo y habilidades físicas): queda bajito durante 60 segundos y deja de esconder.
- **Muros y construcciones:** murallas de Lumen, torres de vigía, ruinas, granjas con cercos y muros cerca de los campamentos. Bloquean el paso a pie (a vos y a los enemigos).
- **Dash, saltos y teletransportes atraviesan los muros**, como en MLBB: sirven para escapar o emboscar. Si el dash terminaría adentro de un muro, te deja del otro lado.

## Vegetación y árboles que se rompen
- Cuatro especies (pinos, árboles redondos, abedules y de otoño) en tres tamaños, más pasto bajo y flores que solo se dibujan cerca de la cámara.
- **Chicos:** se rompen con un par de golpes. **Medianos:** aguantan; los voltea una habilidad fuerte o varios golpes. **Grandes:** no se rompen y bloquean el paso.
- El daño que hacés es el que reciben, así que cuanto más fuerte sos (rangos de habilidad), más fácil los volteás. Los proyectiles chocan con los troncos.
- Al caer dejan un tocón y dan madera (chico 1, mediano 3). Vuelven a crecer: los chicos a los 2 minutos y los medianos a los 5.
- Hay cuatro árboles antiguos gigantes como puntos de referencia del mapa.

## Ciudades y zonas de monstruos
- **Lumen** (capital): empiezan Tanque, Luchador y Soporte.
- **Sapientia** (oeste, hacia el cañadón): empiezan Mago, Tirador y Asesino. Academia con cúpula, observatorio, torre del reloj y un engranaje gigante en la plaza.
- Franjas de nivel (se ven abajo del minimapa y en los puntos de color):
  - Nv 1–15 · animales cerca de las ciudades (conejo cornudo, jabalí, lobo, oso pardo).
  - Nv 15–35 · humanoides en los caminos (bandidos, arqueros, jefe bandido), en empalizadas con arco de piedra.
  - Nv 35–45 · orcos y goblins en las fronteras (goblin, hondero, orco, ogro), en empalizadas oscuras.
  - Nv 45+ · criaturas de las cumbres del norte (gólem, espectro, troll de las nieves), entre ruinas.
- Varios bichos sueltan ingredientes de cocina (panceta de jabalí, musgo de gólem…).
- Cercos rústicos de madera en granjas y praderas: bloquean, pero los dashes los atraviesan.

## Comportamiento de los monstruos (estilo BotW)
- **Sospecha "?"**: cuando te ven se llena un medidor; al llenarse sale "!" y te atacan. De espaldas te ven menos; en el pasto, casi nada.
- **Ataque sigiloso**: si golpeás a un bicho que no te vio (o duerme), hace el doble de daño.
- **Campamentos**: la mitad duerme junto al fuego ("Zzz"); el arquero es vigía y ve más lejos. El que te ve grita "¡Alerta!" y despierta al resto.
- **Te perdió en el pasto**: va a buscarte adonde te vio por última vez, mira para todos lados y vuelve.
- Conejo cornudo huye · jabalí no ataca si no lo provocás, pero embiste en línea · lobos rodean y entran de a uno · oso solo ataca de cerca · goblins huyen heridos y salen corriendo si cae el ogro · gólem duerme como roca hasta que lo pisás · espectro casi invisible, se teletransporta · troll se regenera si dejás de pegarle (el fuego lo frena).

## Vetas de mineral
Rocas con cristales que se rompen a golpes y vuelven a aparecer a los 5 minutos. Espada larga, espada y escudo y explosiones rompen el doble; la magia, la mitad.
- **Piedra** (gris, Nv 1–35): pedernal y sal de roca.
- **Hierro** (óxido, caminos Nv 15–35): hierro.
- **Azufre** (amarilla, cañadón del oeste): azufre y ámbar.
- **Cuarzo solar** (dorada, brilla): el mineral propio del Imperio de la Luz (gemas de Defensa).
- **Plata** (fronteras Nv 35–45) y **mithril** (celeste, cumbres).
- **Veta extranjera** (roja, en los bordes del mapa): un mineral de otra facción. Por eso la frontera se pelea.

## Lugares para descubrir
- **12 santuarios** con un haz de luz naranja que se ve de lejos. Al tocarlos se vuelven celestes y aparecen en el minimapa: hacé clic en uno (o en una ciudad) para viajar.
- **Cofres**: uno en cada campamento (se abre cuando no queda ningún monstruo) y 18 escondidos.
- **Posadas** con corral y caballos en los caminos, **fogatas** de viajeros, un **puente** sobre el río, **carteles** con direcciones, **arcos de piedra** en el campo, **bandadas de pájaros** y **viajeros** que van y vienen por los caminos.
