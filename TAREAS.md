# Tareas para Claude Code

Este archivo es el buzón entre la charla de diseño (en claude.ai, donde está la Biblia) y Claude Code. Cuando termines una tarea, marcala con [x] y anotá debajo, en una línea, qué hiciste. No borres las tareas: David las usa para ver el avance.

## 1. Clima y aclimatación (decidido)
Reglas:
- **Zonas de clima.** Usá los biomas de `terrain.gd`: **frío** en Cumbres nevadas y Montañas del norte, **calor** en el Desierto de Arena Blanca (de día, cuando haya ciclo de día; mientras tanto, siempre). Cada zona es **dura** o **extrema**: extremas son las cumbres altas (por ejemplo, altura > 45 en la nieve) y el centro del desierto (x < -420).
- **Sin protección,** el clima molesta pero no bloquea:
  - frío: perdés 1% de vida cada 2 s;
  - calor: −15% de velocidad y 0,5% de vida cada 2 s.
  - En zona extrema es el doble.
- **Protección** (nivel 1 cada una, se suman):
  - **Plato del Cocinero:** "picante" protege del frío (lleva Pimiento ardiente) y "fresco" protege del calor (lleva Menta glacial). Hoy existe el efecto "picante" (+ataque). Agregá el efecto de resistencia al frío al picante, y un efecto nuevo "fresco" para la menta (hoy la menta da "vigor"; pasale el vigor a otro ingrediente, por ejemplo la Grasa de troll).
  - **Gema o piedra de PvE con resistencia** (agregala en `herramientas/catalogo.py`; por ejemplo "Piedra de abrigo" = Ámbar + Sal de roca, y "Piedra de frescura" = Cristal de hielo + Sal de roca). Es permanente, pero ocupa una ranura.
  - Una zona dura necesita nivel 1. Una extrema necesita nivel 2 (gema + plato).
- **Aclimatados:** el jugador del Imperio de la Luz (la única facción de la demo) no sufre el clima de las zonas **duras** de su territorio. En las **extremas** tiene ventaja pero no total: sufre como si estuviera en una zona dura (le alcanza con nivel 1). Dejalo preparado para cuando haya territorio de otras facciones (por ejemplo, `es_local(x, z)`).
- **Mostrarlo en el HUD:** un ícono de frío o calor con el estado (protegido, aclimatado o sufriendo), y un aviso al entrar a una zona extrema.
- [ ] Hecho

## 2. Engarces del Armero (propuesta, todavía sin confirmar)
**Esperá el OK de David antes de programarlo.** Idea: cada pieza tiene un nivel de engarce del 1 al 6, y una gema de nivel N solo entra en una pieza con engarce ≥ N. El Armero forja los engarces con catalizadores del tramo (pedernal, hierro, plata, mithril…). Las apariencias se ponen encima, sin tocar el engarce.
- [ ] Esperando OK

## 3. Pendientes que ya estaban
- [ ] Pasivas de las gemas: empezar por las fáciles (Sello del cazador, Martillo del minero, Diente del gourmet, Corazón de roble, Coraza de espinas, Tomo del eco).
- [ ] Subir gemas de nivel con catalizadores (pestaña Oficio → Joyero).
- [ ] Pestañas Objetos clave y Apariencias en el menú.
- [ ] Ciclo de día y noche (de noche los campamentos duermen más; los espectros solo salen de noche).
