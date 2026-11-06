# Catálogo de minerales, piedras básicas y gemas del Imperio de la Luz (fuente única: genera data y doc)
CATALIZADORES = [("Pedernal",1),("Hierro",2),("Plata",3),("Mithril",4),("Oricalco",5),("Estelarita",6)]
ESENCIAS = {  # mineral: (dónde aparece en el Imperio, o None si no hay)
 "Cuarzo solar": "Praderas y montañas (abundante)",
 "Cobre": "Bosque del Este y praderas",
 "Luminita": "Montañas del norte",
 "Cristal de hielo": "Cumbres nevadas",
 "Ámbar": "Cañadón y vetas de plata (poco)",
 "Azufre": "Cañadón y desierto del oeste",
 "Sal de roca": "Playas del Lago Espejo",
 "Rubí ígneo": None, "Obsidiana del vacío": None, "Jade de viento": None,
 "Perla de marea": None, "Turquesa": None,
}
NATIVO = {"Rubí ígneo":"Tierras Salvajes","Obsidiana del vacío":"Abismo","Jade de viento":"Reinos de Oriente","Perla de marea":"Arenas y Mares","Turquesa":"Arenas y Mares"}
PIEDRAS = [  # id, nombre, categoría, receta, efecto
 ("filo","Piedra de filo","Ataque",["Cobre","Pedernal"],"+ataque físico"),
 ("mira","Piedra de mira","Ataque",["Cuarzo solar","Cobre"],"+probabilidad de crítico"),
 ("furia","Piedra de furia","Ataque",["Rubí ígneo","Azufre"],"+velocidad de ataque"),
 ("arcana","Piedra arcana","Magia",["Luminita","Pedernal"],"+poder mágico"),
 ("eco","Piedra de eco","Magia",["Cristal de hielo","Luminita"],"−enfriamiento de habilidades"),
 ("vacio","Piedra del vacío","Magia",["Obsidiana del vacío","Luminita"],"+penetración mágica"),
 ("muralla","Piedra de muralla","Defensa",["Cuarzo solar","Pedernal"],"+defensa física"),
 ("vida","Piedra de vida","Defensa",["Ámbar","Sal de roca"],"+vida máxima"),
 ("calma","Piedra de calma","Defensa",["Perla de marea","Cuarzo solar"],"+defensa mágica"),
 ("paso","Piedra de paso","Movimiento",["Cobre","Ámbar"],"+velocidad de movimiento (poca)"),
 ("viento","Piedra de viento","Movimiento",["Jade de viento","Pedernal"],"+velocidad de movimiento"),
 ("cazador","Piedra del cazador","PvE",["Ámbar","Colmillo de monstruo"],"+daño a monstruos"),
 ("presa","Piedra de presa","PvE",["Azufre","Sal de roca"],"+robo de vida contra monstruos"),
 ("guia","Piedra de guía","Soporte",["Luminita","Cuarzo solar"],"+regeneración de energía"),
 ("amparo","Piedra de amparo","Soporte",["Perla de marea","Ámbar"],"+curación y escudos que das"),
 ("temple","Piedra de temple","Soporte",["Turquesa","Cobre"],"+resistencia al control"),
]
GEMAS = [  # nombre, categoría, piedras, stats, pasiva
 # Ataque
 ("Hoja del alba","Ataque",["filo","filo","mira"],"Ataque, crítico","Después de un crítico, tu próximo básico hace +20%."),
 ("Ojo del tirador","Ataque",["mira","filo"],"Ataque, crítico","Acertar la H1 desde lejos potencia el próximo básico."),
 ("Furia carmesí","Ataque",["furia","filo"],"Ataque, vel. de ataque","Cada básico al mismo objetivo da +3% de velocidad de ataque (hasta 5 veces)."),
 ("Cuchilla del ocaso","Ataque",["filo","mira","furia"],"Ataque, penetración","+15% de daño a enemigos con menos del 40% de vida."),
 ("Sed de sangre","Ataque",["filo","vida"],"Ataque, vida","Robo de vida físico del 12%."),
 ("Martillo de asedio","Ataque",["filo","muralla","muralla"],"Ataque, defensa","+30% de daño a estructuras (guerra y asedio)."),
 ("Lanza del juicio","Ataque",["furia","eco"],"Ataque, vel. de ataque","Después de una habilidad, tu próximo básico atraviesa en línea."),
 ("Rompeescudos","Ataque",["mira","muralla"],"Ataque, crítico","Tus golpes le sacan un 30% extra al escudo del enemigo."),
 ("Daga de la bruma","Ataque",["mira","viento"],"Crítico, velocidad","Al salir del pasto, tu primer golpe hace +25%."),
 # Magia
 ("Ojo del vacío","Magia",["arcana","vacio"],"Poder mágico, penetración","Tus habilidades queman un % de la vida del objetivo."),
 ("Cetro del sol","Magia",["arcana","arcana","mira"],"Poder mágico","Cada 6 s tu próxima habilidad deja una zona de luz que quema."),
 ("Corona de escarcha","Magia",["eco","arcana"],"Poder mágico, enfriamiento","Tus habilidades ralentizan un 15%."),
 ("Tomo del eco","Magia",["eco","eco"],"Enfriamiento","Acertar una habilidad le resta 1 s a las demás."),
 ("Cristal de tormenta","Magia",["arcana","eco","eco"],"Poder mágico, enfriamiento","Tus rayos saltan a un enemigo más."),
 ("Velo del vacío","Magia",["vacio","eco"],"Penetración, enfriamiento","+12% de daño mágico a objetivos con más del 50% de vida."),
 ("Lámpara del erudito","Magia",["arcana","guia"],"Poder mágico, energía","Mientras más lejos estés del objetivo, más daño mágico (hasta +15%)."),
 ("Grimorio sangrante","Magia",["arcana","vida"],"Poder mágico, vida","Robo de vida con habilidades del 10%."),
 ("Prisma solar","Magia",["arcana","mira"],"Poder mágico, crítico","Las reacciones elementales (fuego, agua, rayo) que provocás hacen +15%."),
 # Defensa
 ("Coraza de espinas","Defensa",["muralla","muralla"],"Defensa física","Devuelve parte del daño de los básicos."),
 ("Égida del alba","Defensa",["muralla","calma"],"Defensa física y mágica","Al bajar del 40% de vida ganás un escudo (cada 60 s)."),
 ("Corazón de roble","Defensa",["vida","vida"],"Vida","Si no recibís daño por 5 s, regenerás un 2% de vida por segundo."),
 ("Manto de calma","Defensa",["calma","vida"],"Defensa mágica, vida","Los controles te duran un 20% menos."),
 ("Bastión inmortal","Defensa",["muralla","vida","calma"],"Vida, defensas","Al morir, revivís con el 20% de vida (cada 3 min)."),
 ("Cinturón del trueno","Defensa",["muralla","vida"],"Vida, defensa física","Cada 4 s tu próximo básico hace daño extra según tus defensas."),
 ("Yelmo del centinela","Defensa",["muralla","temple"],"Defensa física, enfriamiento","Después de un control, ganás +30% de defensa por 2 s."),
 ("Coraza antigua","Defensa",["muralla","filo"],"Defensa física, ataque","Al pegarle con una habilidad, el enemigo pierde un 8% de ataque por 2 s."),
 ("Hielo dominante","Defensa",["calma","eco"],"Defensa mágica, enfriamiento","Los enemigos cerca tuyo se curan un 30% menos."),
 # Movimiento (solo una)
 ("Sandalias del rayo","Movimiento",["paso","guia"],"Velocidad, enfriamiento","Corrés más rápido después de usar la definitiva."),
 ("Botas de guerrero","Movimiento",["paso","muralla"],"Velocidad, defensa física","Recibir básicos te da más defensa física (hasta 5 veces)."),
 ("Botas firmes","Movimiento",["paso","calma"],"Velocidad, defensa mágica","Los controles te duran un 30% menos."),
 ("Botas arcanas","Movimiento",["paso","arcana"],"Velocidad, penetración mágica","—"),
 ("Botas veloces","Movimiento",["paso","furia"],"Velocidad, vel. de ataque","—"),
 ("Botas del viento","Movimiento",["viento","viento"],"Mucha velocidad","Fuera de combate corrés un 20% más."),
 ("Botas del eco","Movimiento",["paso","eco"],"Velocidad, enfriamiento","—"),
 # PvE
 ("Sello del cazador","PvE",["cazador","filo"],"Ataque, vel. de ataque","Cada monstruo que matás te devuelve un 5% de vida."),
 ("Piedra matajefes","PvE",["cazador","cazador"],"Ataque","+15% de daño a jefes de mazmorra y de mundo."),
 ("Ojo del guardián","PvE",["cazador","vida"],"Vida, defensa","Generás el doble de amenaza."),
 ("Coraza de la cripta","PvE",["presa","muralla"],"Defensa","Recibís un 15% menos de daño de monstruos."),
 ("Diente del gourmet","PvE",["cazador","presa"],"Ataque","Los monstruos sueltan ingredientes con +25% de probabilidad."),
 ("Martillo del minero","PvE",["cazador","muralla"],"Ataque","Rompés vetas y árboles el doble de rápido."),
 ("Brújula del explorador","PvE",["presa","paso"],"Velocidad","+15% de velocidad en el mundo abierto (no cuenta en PvP)."),
 # Soporte
 ("Estandarte de guerra","Soporte",["guia","filo"],"Ataque, energía","Los aliados cerca tuyo hacen un 6% más de daño."),
 ("Lazo protector","Soporte",["amparo","vida"],"Vida, curación","Tus curas y escudos rinden un 20% más."),
 ("Marca del guía","Soporte",["guia","temple"],"Energía, resistencia al control","El enemigo que controlás queda marcado: tus aliados le pegan un 8% más."),
 ("Pluma del rescate","Soporte",["amparo","paso"],"Curación, velocidad","Si curás a un aliado por debajo del 30%, también le das un escudo."),
 ("Campana del santuario","Soporte",["amparo","guia"],"Curación, energía","Al usar tu definitiva, los aliados cerca se limpian de controles."),
 ("Lámpara del peregrino","Soporte",["guia","guia"],"Energía, enfriamiento","Los aliados cerca recuperan sus habilidades un 10% más rápido."),
 ("Velo de bruma","Soporte",["temple","calma"],"Resistencia al control, defensa mágica","Los aliados cerca siguen ocultos en el pasto después de su primer ataque."),
 # Híbridas
 ("Lanza del eclipse","Ataque·Magia",["filo","arcana"],"Ataque, poder mágico","Alternar básico y habilidad potencia el siguiente golpe un 10%."),
 ("Corona invernal","Defensa·Magia",["muralla","eco"],"Defensas, enfriamiento","Te congelás: inmune a todo por 2 s (cada 2 min)."),
 ("Sable del cielo","Ataque·Magia",["filo","mira","arcana"],"Ataque, poder mágico","Tus golpes ejecutan a enemigos con menos del 8% de vida."),
]
PID = {p[0]:p for p in PIEDRAS}
def facil(piedras):
    falt = set()
    for pid in piedras:
        for m in PID[pid][3]:
            if m in ESENCIAS and ESENCIAS[m] is None: falt.add(m)
    return falt

if __name__ == "__main__":
    # Uso (desde la raíz del proyecto):  python herramientas/catalogo.py
    # Reescribe el bloque marcado en scripts/data.gd y deja herramientas/gemas.md para pegar en la Biblia.
    import os, re
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    g = ["# --- generado por herramientas/catalogo.py: catálogo de gemas (uno solo para todo el juego; cualquiera se equipa cualquiera) ---",
         "# El Alquimista talla minerales en piedras básicas; el Joyero combina piedras en gemas finales.",
         "const PIEDRAS = {"]
    for pid,n,c,rec,ef in PIEDRAS:
        g.append('\t"%s": {"name": "%s", "cat": "%s", "recipe": %s, "effect": "%s"},' % (pid,n,c,str(rec).replace("'",'"'),ef))
    g.append("}")
    g.append("const GEMAS = [")
    for n,c,ps,st,pa in GEMAS:
        g.append('\t{"name": "%s", "cat": "%s", "stones": %s, "stats": "%s", "passive": "%s"},' % (n,c,str(ps).replace("'",'"'),st,pa))
    g.append("]")
    data = os.path.join(raiz, "scripts", "data.gd")
    s = open(data, encoding="utf-8").read()
    ini = "# >>> CATÁLOGO DE GEMAS (generado por herramientas/catalogo.py: no editar a mano)\n"
    fin = "# <<< CATÁLOGO DE GEMAS\n"
    a, b = s.index(ini) + len(ini), s.index(fin)
    s = s[:a] + "\n".join(g) + "\n" + s[b:]
    open(data, "w", encoding="utf-8").write(s)
    md=[]
    md.append("| Piedra | Categoría | Receta | Efecto |\n|---|---|---|---|")
    for pid,n,c,rec,ef in PIEDRAS:
        r=" + ".join(rec)
        if [m for m in rec if ESENCIAS.get(m,"x") is None]: r += " ⚠"
        md.append(f"| {n} | {c} | {r} | {ef} |")
    md.append("")
    md.append("| Gema | Categoría | Piedras | Stats | Pasiva | Dificultad en el Imperio |\n|---|---|---|---|---|---|")
    for n,c,ps,st,pa in GEMAS:
        f=facil(ps)
        dif = "Fácil" if not f else "Difícil (" + ", ".join(sorted(f)) + ")"
        md.append(f"| {n} | {c} | {' + '.join(PID[p][1].replace('Piedra ','').replace('de ','').replace('del ','') for p in ps)} | {st} | {pa} | {dif} |")
    open(os.path.join(raiz, "herramientas", "gemas.md"), "w", encoding="utf-8").write("\n".join(md)+"\n")
    print(len(PIEDRAS),"piedras",len(GEMAS),"gemas -> scripts/data.gd y herramientas/gemas.md")
