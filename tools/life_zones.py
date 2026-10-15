#!/usr/bin/env python3
"""(V1) Les places de la vie des cartes de l'entrepôt : les zones (une place et ses points enfants), les
départs (`vers_<carte>`) et les orientations des points nommés du plan. Données seulement : elles sont
lues par tools/interior_maps.py (entrepot_rdc, entrepot_etage, entrepot_toit, salle_des_armes) et par
tools/exterior_maps.py (entrepot), qui les écrivent dans `Life/Places` de chaque carte, et par leurs
sous-commandes `places` (la liste de CARTE.md).

Format (PLAN.md, « (E4) La vie ») : une place est un Marker3D de `Life/Places` ; ses enfants Marker3D en
font une zone de points (sièges d'une table, terrain d'un jeu, points où l'on erre). Un point est tourné
vers où l'on regarde (son −Z). Ici, en mètres dans le repère de la carte (x vers l'est, z vers le sud) :

    zone(nom, [(x, z, regard[, dy]), …], pourquoi)   une zone : points enfants ; dy : hauteur au-dessus du sol
    seul(nom, x, z, regard, pourquoi)                une place sans enfant
    regard : degrés (0 : le nord, 180 : le sud, 90 : l'ouest, -90 : l'est), ou N, S, E, O

Dehors, la hauteur du sol vient de la carte (paliers) ; dedans, le sol est à 0 (les lits : BED_HEIGHT).
Ce que le plan ne dit pas est dit dans docs/DECISIONS.md (V1).
"""

import math

YAWS = {"N": 0.0, "S": 180.0, "E": -90.0, "O": 90.0, "W": 90.0}
# Hauteur du dormeur sur un lit simple, sur le lit du bas et sur celui du haut d'un lit superposé (m).
BED_HEIGHT = 0.45
BUNK_HEIGHT = 1.35


def _yaw(value):
    return YAWS[value] if isinstance(value, str) else float(value)


def zone(name, points, why):
    pts = []
    for p in points:
        pts.append((float(p[0]), float(p[1]), _yaw(p[2]), float(p[3]) if len(p) > 3 else 0.0))
    return {"name": name, "pts": pts, "why": why}


def seul(name, x, z, yaw, why):
    return {"name": name, "pts": [], "at": (float(x), float(z), _yaw(yaw), 0.0), "why": why}


def row(z, xs, yaw):
    return [(x, z, yaw) for x in xs]


def ring(cx, cz, radius, count, offset=0.0):
    """Points sur un cercle, tournés vers son centre."""
    out = []
    for k in range(count):
        a = offset + 2.0 * math.pi * k / count
        x, z = cx + radius * math.cos(a), cz + radius * math.sin(a)
        out.append((round(x, 2), round(z, 2), round(math.degrees(math.atan2(-(cx - x), -(cz - z))), 1)))
    return out


def anchor(entry):
    """(x, z, regard, dy) du marqueur d'une place : son point seul, ou le centre de ses points."""
    if not entry["pts"]:
        return entry["at"]
    xs = [p[0] for p in entry["pts"]]
    zs = [p[1] for p in entry["pts"]]
    return (round(sum(xs) / len(xs), 3), round(sum(zs) / len(zs), 3), 0.0, 0.0)


# Orientation des points nommés du plan (le plan n'en donne pas : N par défaut).
POINT_YAW = {
    "entrepot": {
        "porche_banc": "S", "porte_seuil": "S", "cour_willem": "S", "clairiere_banc": "S", "coin_soleil": "S",
        "champ_centre": "S",
    },
    "entrepot_rdc": {
        "refectoire_bout_est": "O", "refectoire_bout_ouest": "E", "lecture_table": "N", "jeux_tapis": "N",
        "jeux_mur_balle": "O", "bains_baignoire": "N", "entree": "N", "infirmerie_bureau": "N",
    },
    "entrepot_etage": {"nygglatho_the": "O", "nygglatho_bureau": "O", "willem_fenetre": "N"},
}

# --- Le réfectoire : chaises du plan (x = 7,75 + 0,5 k) ; assis devant l'image de la chaise vue de face
# (+0,4 m au sud), derrière celle d'une chaise vue de dos (−0,1 m), PLAN.md « (E4) ». Le rang du fond (z 7,9,
# collé au mur sud, derrière la table) n'a pas de place : on n'y arrive qu'à travers la table. ---------
SEATS = [8.25, 9.25, 10.25, 11.25, 12.25, 13.25, 14.25]
ROW_A, ROW_B, ROW_C = 3.6, 4.6, 6.8

ZONES = {
    "entrepot_rdc": [
        # Départs : par où l'on quitte la carte (le premier : le repli des cartes à venir).
        seul("vers_entrepot", 13.0, 14.5, "S", "la porte d'entrée : on part dehors, vers le village, le sentier…"),
        seul("vers_entrepot_etage", 17.5, 6.3, "N", "le pied de l'escalier : on monte à l'étage"),
        seul("vers_entrepot_toit", 17.5, 6.3, "N", "le pied de l'escalier : on monte au toit par l'étage"),
        # Le réfectoire.
        zone("refectoire_rang_a", row(ROW_A, SEATS[:5], "S"), "cinq sièges du rang nord, face à la salle : les petites nommées"),
        seul("refectoire_siege_nygglatho", 7.75, ROW_A, "S", "le bout ouest du rang nord, près du vaisselier : Nygglatho"),
        seul("refectoire_siege_willem", 13.25, ROW_A, "S", "le rang nord, côté fenêtre : Willem"),
        zone("refectoire_rang_b", row(ROW_B, SEATS, "N"), "sept sièges dos à la caméra, côté sud de la table nord"),
        zone("refectoire_rang_c", row(ROW_C, SEATS[:4], "S"), "quatre sièges face à la salle, table sud"),
        zone("refectoire_aines", row(ROW_C, SEATS[4:], "S"), "trois sièges à l'est de la table sud : les aînées"),
        zone("refectoire_service", row(5.55, [8.5, 10.5, 12.5, 14.5], "S"), "l'allée entre les deux rangées : on sert, le plateau en main"),
        zone("refectoire_veillee", [(8.25, ROW_A, "S"), (9.25, ROW_A, "S"), (8.25, ROW_B, "N"), (9.25, ROW_B, "N")],
             "quatre sièges autour de la table ouest : la veillée (thé, cheese-cake)"),
        zone("epie_cuisine", [(6.25, 4.0, "O"), (6.25, 4.6, "O"), (6.25, 5.2, "O")],
             "collées à la porte de la cuisine, côté réfectoire (l'avalanche)"),
        # Le couloir.
        zone("couloir_course", [(3.5, 9.5, "E"), (28.0, 9.7, "E"), (22.0, 10.1, "O")],
             "la course du couloir : 0 départ, 1 arrivée (le point d'eau), 2 le poste de celle qui gronde"),
        zone("epie_infirmerie", [(23.4, 10.0, "S"), (24.0, 10.0, "S"), (24.6, 10.0, "S")],
             "collées à la porte de l'infirmerie, côté couloir (l'avalanche)"),
        zone("epie_archives", [(23.6, 9.0, "N"), (24.2, 9.0, "N"), (24.8, 9.0, "N")],
             "collées à la porte des archives, côté couloir (l'avalanche)"),
        zone("eau_toilette", [(28.6, 9.65, "N"), (29.4, 9.65, "N"), (30.0, 9.65, "N"), (30.6, 9.65, "N"),
                              (29.0, 10.2, "N"), (30.0, 10.2, "N")], "la toilette à l'eau glacée, devant l'auge du couloir"),
        # La salle de jeux, la lecture, les bains.
        zone("jeux_tour", [(19.4, 13.5, "S"), (17.8, 12.4, "E"), (17.8, 13.6, "E"), (21.0, 12.4, "O"), (21.0, 13.6, "O"),
                           (19.4, 11.9, "S"), (19.4, 14.5, "N")],
             "la tour de fées : 0 la base (Willem assis), les autres attendent leur tour autour du tapis"),
        zone("jeux_societe", [(17.8, 12.4, "E"), (17.8, 13.6, "E"), (21.0, 12.4, "O"), (21.0, 13.6, "O"),
                              (18.4, 11.9, "S"), (19.4, 11.9, "S"), (20.4, 11.9, "S"), (18.6, 14.5, "N"),
                              (19.4, 14.5, "N")], "assis par terre autour du tapis : les jeux de société"),
        zone("jeux_balle_mur", [(16.0, 12.7, "O"), (16.0, 13.6, "O")], "la balle contre le mur ouest"),
        zone("lecture_sieges", [(28.0, 5.2, "N"), (29.2, 5.2, "N"), (29.1, 2.4, "S"), (30.1, 2.4, "S")],
             "la table de lecture (au sud) et le banc de la fenêtre : lire en silence"),
        zone("bains_sechage", [(3.8, 12.7, "S"), (4.8, 12.7, "S"), (5.8, 12.4, "O"), (4.4, 13.5, "N")],
             "on sort du bain enveloppée d'une serviette : le séchage des cheveux"),
    ],
    "entrepot_etage": [
        seul("vers_entrepot_rdc", 17.5, 1.9, "N", "le haut de l'escalier : on descend au rez-de-chaussée"),
        seul("vers_entrepot", 17.5, 1.9, "N", "le haut de l'escalier : on descend, puis dehors"),
        seul("vers_entrepot_toit", 28.9, 9.6, "E", "le pied de l'échelle de la trappe : on monte au toit"),
        zone("epie_nygglatho", [(10.4, 9.0, "N"), (11.0, 9.0, "N"), (11.6, 9.0, "N")],
             "collées à la porte de Nygglatho, côté couloir (l'avalanche)"),
        zone("epie_willem", [(3.0, 9.0, "N"), (3.6, 9.0, "N"), (4.2, 9.0, "N")],
             "collées à la porte de Willem, côté couloir (l'avalanche)"),
    ],
    "entrepot_toit": [
        seul("vers_entrepot_etage", 13.1, 9.1, "E", "sous la trappe : on descend à l'étage"),
        zone("toit_linge", [(7.3, 6.9, "N"), (9.7, 6.9, "N"), (7.3, 11.9, "N"), (9.7, 11.9, "N")],
             "devant les deux séchoirs : on monte le linge, on l'étend"),
    ],
    "salle_des_armes": [
        seul("vers_entrepot_rdc", 2.5, 5.0, "S", "au pied des marches : on remonte"),
    ],
    "entrepot": [
        seul("vers_entrepot_rdc", 42.0, 27.3, "N", "le seuil du porche : on entre (le premier départ : le repli)"),
        seul("vers_entrepot_etage", 42.0, 27.3, "N", "le seuil du porche : on entre, puis on monte"),
        seul("vers_entrepot_toit", 42.0, 27.3, "N", "le seuil du porche : on entre, puis on monte au toit"),
        seul("vers_sentier", 86.6, 38.0, "E", "la sortie est : le sentier du port"),
        seul("vers_ville_boulangerie", 86.6, 38.0, "E", "la sortie est, pour la ville (par le sentier)"),
        seul("vers_village", 1.6, 40.0, "O", "la sortie ouest : le village"),
        seul("vers_colline", 14.0, 1.6, "N", "la sortie nord : la colline des étoiles"),
        seul("vers_foret_profonde", 40.0, 58.4, "S", "la sortie sud : la forêt profonde"),
        zone("herbes_chat", [(18.5, 32.2, "S"), (20.5, 34.5, "S"), (22.5, 32.6, "S"), (24.7, 34.0, "S"),
                             (26.2, 32.0, "S"), (19.5, 35.6, "S"), (23.4, 35.6, "S"), (21.4, 32.0, "S")],
             "le terrain du chat : les hautes herbes du coin d'herbe au soleil"),
        zone("potager_travail", [(20.0, 30.2, "N"), (21.5, 30.3, "N"), (23.0, 30.2, "N")],
             "au pied des carrés du potager"),
        zone("cour_corvee", [(35.5, 30.5, "S"), (38.5, 31.0, "N"), (46.5, 31.0, "S"), (49.5, 30.5, "N")],
             "les corvées de la cour : le balai devant la façade"),
        zone("marelle", [(51.0, 38.9, "S"), (51.0, 40.0, "S"), (51.0, 41.1, "S")], "les cases de la marelle à la craie : on saute à cloche-pied"),
        zone("cour_tour", [(33.0, 29.5, "S"), (50.0, 29.5, "S"), (31.0, 34.0, "E"), (56.0, 34.0, "O")],
             "on tourne autour du bâtiment (jours de la fuite)"),
        zone("cour_cercle", ring(44.0, 37.0, 4.0, 10) + ring(44.0, 37.0, 5.4, 14, 0.2),
             "le cercle de toute la maison autour de cour_centre, au couchant du départ (jour 12)"),
        zone("arbre_racines", [(62.7, 33.5, "N"), (64.1, 33.4, "N"), (61.8, 33.5, "N")],
             "au pied du grand arbre : on grimpe sur les racines"),
        zone("arbre_branche_basse", [(63.5, 33.0, "N", 2.3)], "le grand arbre, la branche basse à 2,3 m (la peur de Lakhesh)"),
        zone("arbre_branche_mi", [(62.4, 33.0, "N", 4.3)], "le grand arbre, mi-hauteur à 4,3 m (Pannibal)"),
        zone("arbre_branche_haute", [(63.2, 33.0, "N", 6.6)], "le grand arbre, tout en haut à 6,6 m, la main en visière (Collon)"),
        zone("champ_entrainement", row(22.0, [69.0, 72.0, 75.0, 78.0], "N") + row(24.0, [69.0, 72.0, 75.0, 78.0], "N"),
             "l'entraînement de base : deux rangées face à celle qui mène"),
        seul("champ_meneuse", 75.0, 19.5, "S", "celle qui mène l'entraînement, face aux rangées"),
        zone("champ_jeu", [(70.0, 13.0, "S"), (73.0, 16.0, "S"), (77.0, 13.0, "S"), (80.0, 16.0, "S"),
                           (71.0, 20.0, "S"), (79.0, 21.0, "S")],
             "le champ avant la partie (le ballon est du lot E8) : on court, on lance"),
        zone("champ_boue", [(68.0, 12.0, "S"), (72.0, 22.0, "S"), (76.0, 11.0, "S"), (80.0, 24.0, "S"),
                            (82.0, 14.0, "S"), (74.0, 26.0, "S")], "la boue du champ après la pluie : on saute dans les flaques"),
        zone("fourre_embuscade", [(83.6, 13.5, "E"), (83.6, 20.5, "E")], "les fourrés de l'est : l'embuscade de Pannibal"),
        seul("clairiere_nephren", 18.0, 16.0, "S", "la clairière : Nephren à l'entraînement au bâton"),
    ],
}


def zones_of(map_id):
    return ZONES.get(map_id, [])


def point_yaw(map_id, name):
    value = POINT_YAW.get(map_id, {}).get(name)
    return _yaw(value) if value is not None else 0.0
