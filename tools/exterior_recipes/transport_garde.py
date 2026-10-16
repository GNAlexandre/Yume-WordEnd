"""(E7) Le pont du transport de la Garde : la pose de la carte `transport_garde` d'après docs/lore/CARTE.md, section 6.3
(bloc ```plan lu par tools/carte_plans.py).

Ce que dit l'œuvre (6.1) : le transport de la Garde est petit, militaire ; deux pales de rotor, une chaudière enchantée,
une trappe qui s'ouvre sous la pression, une passerelle ; seuls les guerriers montent là où se tiennent les guerriers (à
l'acte 1, on n'y monte pas : la carte sert aux actes suivants).

Composition vue de la caméra (elle regarde le nord) :
- le pont praticable (16 × 5 m, de x 2 à 18), vu de dessus : le pont du navire en décalque (`ships/garde_transport_deck`,
  proue à l'est), son bastingage au nord et au sud, la passerelle de commandement, les caisses arrimées, la manche à air,
  l'écoutille ; les deux rotors en bout de bras, à la poupe et à la proue, arrêtés (le navire est à quai) ;
- au nord, le vide : la mer de nuages, des rochers qui flottent, des îles lointaines ;
- au sud, par la passerelle de planches, une bande du quai du port (tôle, bittes, cordages), d'où l'on redescend.

Aucune lumière : Atmosphere éclaire.
"""

import exterior_ground
from exterior_pose import Rect, poisson

SETTINGS = {
    "groups": ["Deck", "Rail", "Rotors", "Gangway", "Quay", "Sky"],
    # Le pont tient à l'écran (20 m de large) : la caméra ne suit qu'en z, du nord du pont au quai.
    "camera_bounds": (9.5, 2, 1, 5),
    "no_lights": True,
}

DEVIATIONS = [
    "la passerelle (`decor gangway 10 7.25 2 2.5 1.1`) est le plancher de planches du quai (`gangway_quay`, 2 × 3,6 m, "
    "son dessus à 8 cm du sol) : elle franchit le vide de z 6 à 8,5 et déborde sur le pont et le quai ; le sol sous elle "
    "est de tôle (le plan ne peint rien de x 9 à 11, z 6 à 8,5)",
    "le pont est le décalque du navire (`ships/garde_transport_deck`, 16 × 5 m, remplaçant, cahier n° 6, D.1) posé sur la "
    "tôle du plan, sa coque dessous (`ships/garde_transport_hull` en façade d'un volume de 15 × 5 × 2,45 m, sa façade 0,4 m au sud du pont, devant la roche du sol : le bas "
    "du flanc) ; les rotors (`garde_transport_rotor`) sont la bande du cahier (C.1), arrêtée (navire à quai)",
    "le quai s'arrête aux bords de la carte (le vide à l'ouest et à l'est, la suite du port au sud : des bords "
    "invisibles) ; on ne repart que par la sortie du haut de la passerelle",
    "le bastingage du plan (`bord rambarde`) est la rambarde de bord `deck_railing` (lot L) ; au sud, elle laisse la "
    "passerelle libre (x 9 → 11)",
]

# Scène posée à la place de l'image du plan (tools/exterior_maps.py, plan_gaps).
SCENE_ALIASES = {"gangway": "gangway_quay", "garde_transport_rotor": "ships/garde_transport_rotor"}


def ground_plan(m):
    """Le sol : le pont de tôle, le quai de tôle, le vide tout autour du pont (la mer de nuages)."""
    plan = exterior_ground.ground_from_plan(
        m, comment="Sol du pont du transport de la Garde (lot E7), d'après docs/lore/CARTE.md, section 6.3 : le pont de "
                   "tôle (de x 2 à 18, z 1 à 6) au-dessus du vide, la passerelle, une bande du quai du port au sud. Lu "
                   "par tools/map_build.py gen transport_garde ; le jeu ne lit pas ce fichier.")
    plan["edges"]["north"] = "void"
    plan["edges"]["east"] = "void"
    plan["edges"]["west"] = "void"
    plan["base"]["material"] = "tole"
    steps = plan["steps"]
    first = exterior_ground.step_index(steps, "face")
    voids = [{"op": "void", "shape": {"rect": [-3, -3, 26, 4]}}]
    for b in m.borders:
        if b.name == "vide":
            r = b.rect
            x0, z0, x1, z1 = r.x0, r.z0, r.x1, r.z1
            # Les bords de la carte : le vide continue au-delà (au nord, à l'ouest et à l'est du pont).
            x0 = -3 if x0 <= 0 else x0
            x1 = m.w + 3 if x1 >= m.w else x1
            z0 = -3 if z0 <= 0 else z0
            voids.append({"op": "void", "shape": {"rect": [x0, z0, x1 - x0, z1 - z0]}})
    steps[first:first] = voids
    return plan


def prepare(p):
    # La passerelle franchit le vide (x 9 → 11, z 6 → 7) : rien n'y bloque ; le bastingage sud ne la ferme pas. Le quai
    # s'arrête aux bords de la carte (le vide à l'ouest et à l'est, la suite du port au sud, par la sortie seulement).
    p.edges += [Rect(-1.0, 8.5, 0.0, 11.0), Rect(20.0, 8.5, 21.0, 11.0), Rect(0.0, 11.0, 20.0, 12.0)]


def pose(p):
    M = p.map
    place, scatter = p.place, p.scatter
    free = p.free
    p.walk_grid()

    # === 1. Le pont (6.3) ================================================================================

    place("Deck", "ships/garde_transport_deck", 10.0, 3.5, name="PontNavire", check=False)
    # La coque sous le pont (le bas du flanc en façade, au sud ; ses murs cachent la roche du sol au bord du vide).
    place("Deck", "ships/garde_transport_hull", 10.0, 3.95, y=-2.55, name="Coque", check=False)
    rotors = 0
    for d in M.decors:
        x, z = (d.rect.x0 + d.rect.x1) / 2.0, (d.rect.z0 + d.rect.z1) / 2.0
        n = d.name
        if n == "gangway":
            # Le plancher de planches, du pont (z 4,7) au quai (z 8,3), son dessus à 8 cm du sol.
            place("Gangway", "gangway_quay", x, z, y=-0.17, name="Passerelle", check=False)
        elif n == "garde_transport_rotor":
            rotors += 1
            # Le rotor en bout de bras, au-dessus du vide : son moyeu à 1,2 m du pont.
            place("Rotors", "ships/garde_transport_rotor", x, z, y=0.2, name="Rotor%d" % rotors, check=False)
        elif n == "deck_bridge":
            place("Deck", n, x, z, name="PasserelleCommandement", check=False)
        else:
            place("Deck", n, x, z, name="".join(w.capitalize() for w in n.split("_")), check=False)
    # Le bastingage : au nord tout du long, au sud de part et d'autre de la passerelle.
    for k, x in enumerate(3.0 + 2.0 * i for i in range(8)):
        place("Rail", "deck_railing", x, 1.2, name="BastingageNord%d" % (k + 1), check=False)
    for k, x in enumerate((3.0, 5.0, 7.0, 8.0, 12.0, 14.0, 16.0, 17.0)):
        place("Rail", "deck_railing", x, 5.8, name="BastingageSud%d" % (k + 1), check=False)
    # Sur le pont : des taches d'huile, de la rouille, une bouche d'aération ; des caisses de la Garde.
    deck = poisson(Rect(2.6, 1.8, 17.4, 5.4), 1.6, 40, free(decal=True, places=False), seed=91)
    scatter("DeckStains", ["oil_stain", "rust_streak", "cracks_b", "drain_grate"], deck, seed=92, check=False)
    place("Deck", "garde_crate", 11.6, 2.3, name="CaisseGarde", check=False)
    place("Deck", "rope_coil", 3.2, 4.6, name="Cordage", check=False)

    # === 2. Le quai, au sud ==============================================================================

    for k, (x, z, scene) in enumerate(((3.0, 9.1, "bollard"), (17.0, 9.1, "bollard"), (6.0, 9.6, "rope_coil"),
                                       (14.4, 9.8, "chain_pile"), (2.2, 10.2, "crate"), (18.0, 10.2, "fuel_barrels"))):
        place("Quay", scene, x, z, name="Quai%d" % (k + 1), check=False)
    quay = poisson(Rect(0.6, 8.9, 19.4, 10.8), 1.6, 40, free(decal=True, places=False), seed=93)
    scatter("QuayStains", ["oil_stain", "rust_streak", "puddle_b", "pebbles_a", "leaves_rust_a"], quay, seed=94,
            check=False)

    # === 3. Le ciel au nord : des rochers qui flottent, des îles, des nuages ============================

    for k, (x, y, z, scale, scene) in enumerate(SKY):
        place("Sky", scene, x, z, y=y, scale=scale, name="Vide%d" % (k + 1), flip=k % 3 == 1, check=False)


# Le ciel et le vide : (x, y, z, échelle, scène). La nappe de nuages est à y = −60 ; le pont est à y = 0.
SKY = [
    (-6.0, -50.0, -100.0, 0.5, "distant_island_a"), (26.0, -44.0, -90.0, 0.45, "distant_island_e"),
    (8.0, -58.0, -150.0, 0.6, "distant_island_c"), (14.0, -58.0, -230.0, 4.0, "horizon_islands"),
    (4.0, -56.0, -120.0, 1.8, "cloud_c"), (24.0, -56.0, -140.0, 2.0, "cloud_a"), (-10.0, -57.0, -170.0, 2.2, "cloud_b"),
    (10.0, -50.0, -105.0, 2.2, "mist_band"),
    (22.0, -24.0, -66.0, 1.0, "airship_far_a"),
    (2.0, -9.0, -18.0, 0.9, "floating_rock_b"), (19.0, -14.0, -30.0, 1.0, "floating_rock_c"),
]


def ambient(p):
    """Vie ambiante : des oiseaux qui traversent le vide, devant le pont."""
    return [
        ("Birds", "birds_flock", 6, 10, 1, 3, (24, 6, 10), 5.0, (0, 0), 4.0, 0.8, 3, (10, 0, 2)),
    ]
