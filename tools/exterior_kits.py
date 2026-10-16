"""(RC) Les recettes de cartes du dehors, refonte image : ce que tools/exterior_recipes/*.py emploient
pour en finir avec le « vieux copié-collé » et donner de la profondeur (docs/lore/CARTE.md 0.5), et les
deux mesures de tools/exterior_maps.py check. Rien ici n'écrit de fichier.

- `row(...)` : une rangée irrégulière (clôture, garde-corps, haie, lisière) : pas variable (± 30 % par
  défaut), recul en profondeur (± 0,6 m par défaut), retournement au hasard, quelques éléments sautés ou
  remplacés par un accent ; les images tirées d'une famille (au moins trois quand elles existent), jamais la
  même deux fois de suite ; `place_row(p, ...)` la pose (décors uniques, teinte variée `tone`).
- `foreground_kit(p, ...)` : le premier plan de chaque vue de la série QC et de chaque passage : deux à
  quatre feuillages ou troncs de premier plan près du bord sud de la vue, jamais devant une place où l'on se
  tient (exterior_pose.clear_of_places, la règle QC2 de CARTE.md 0.3).
- `middle_kit(p, ...)` : des masses de 1,5 à 3 m dans les places nues (plan moyen), loin des chemins, des
  points, des places de la vie et des jeux.
- `second_rank(p, ...)` : le second rang d'une lisière, décalé d'un demi-pan, derrière le premier.
- `view_repeats(p, ...)` et `view_south(p, ...)` : les mesures du contrôle (la même image trop souvent dans le
  champ d'une vue ; les objets hauts au sud de chaque vue).

Tirages : random.Random(graine) (même suite sous Python 3.11 et 3.12) ; les positions s'additionnent pas à
pas, jamais par sum() (Python 3.12 compense la somme des flottants : les cartes changeraient d'une version à
l'autre) ; math.fsum pour les moyennes.
"""

import json
import math
import os
import random

from exterior_pose import FOREGROUND, Rect, clear_of_places, prop

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QC_VIEWS = os.path.join(ROOT, "tools", "qc_views.json")

# --- Familles d'images ----------------------------------------------------------------------------------------
#
# Une famille : les images interchangeables d'un même rôle. Une variante livrée plus tard (cahier n° 7 :
# variantes de nature, premiers plans peints, second rang de lisière) entre seule dans sa famille : il suffit
# que sa scène existe dans src/world/props/ (family() ne garde que les scènes présentes).

FAMILIES = {
    # Grands arbres d'automne : or, rouille, sombres.
    "trees_gold": ["tree_autumn_yellow", "beech_a", "maple_b", "oak_b", "beech_c", "maple_c",
                   "tree_autumn_yellow_b", "maple_d"],
    "trees_rust": ["tree_autumn_rust", "maple_a", "oak_c", "beech_b", "oak_d", "tree_autumn", "tree_autumn_rust_b",
                   "oak_e"],
    "trees_dark": ["pine_tall_b", "tree_old_pine", "tree_pine", "oak_a", "pine_dead", "pine_tall_c"],
    # Haies et fourrés (le bord sud du village et du port).
    "hedges": ["thicket_a", "thicket_b", "thicket_c", "bramble_hedge", "thicket_d"],
    # Feuillages et troncs de premier plan (s'effacent autour du joueur ; sans collision).
    "fg_foliage": ["fg_bush", "fg_fern", "fg_bush_b", "fg_fern_b", "fg_foliage_a", "fg_foliage_b"],
    "fg_trunks": ["fg_trunk_a", "fg_trunk_b", "fg_trunk_c"],
    # Pans de lisière à raccord : premier rang, second rang (cahier n° 7 : forest_wall_back_*).
    "lisiere_front": ["forest_wall_a", "forest_wall_b", "forest_wall_c", "forest_wall_d"],
    "lisiere_back": ["forest_wall_back_a", "forest_wall_back_b", "forest_wall_deep", "forest_wall_b", "forest_wall_c",
                     "forest_wall_a"],
    # Garde-corps de la ville haute : le fer, avec ses pans de muret et de balustre ; du port : la fonte, avec les
    # pans rapiécés de cordage et de rambarde de tôle ; clôtures du village : le plessis, la palissade basse.
    "town_rail": ["town_railing", "town_railing_b"],
    "town_rail_accents": ["edge_parapet", "planter_long"],
    "port_rail": ["edge_railing", "edge_railing_b"],
    "port_rail_accents": ["rope_fence", "deck_railing"],
    "wattle": ["fence_wattle", "fence_wattle_b"],
    "wattle_accents": ["fence_low", "bush_c", "berry_bush_b", "bush_e"],
    # Bordures d'herbe le long des chemins (décalques couchés).
    "grass_edges": ["grass_edge_a", "grass_edge_b", "grass_edge_c", "grass_edge_d"],
    # Masses du plan moyen (1,5 à 3 m).
    "mid_nature": ["thicket_a", "thicket_b", "thicket_c", "sapling_a", "sapling_b", "boulder_b", "haystack"],
    "mid_port": ["crates_barrels", "cargo_cart_b", "pallet_sacks", "crate_stack", "sacks_pile"],
    "mid_town": ["sapling_a", "sapling_b", "planter_long", "barrel_group", "crate_stack"],
}


def exists(scene):
    return os.path.exists(os.path.join(ROOT, "src", "world", "props", scene + ".tscn"))


def family(name, extra=()):
    """Les scènes présentes d'une famille (FAMILIES[name] + extra), dans l'ordre, sans doublon."""
    out = []
    for scene in list(FAMILIES.get(name, [])) + list(extra):
        if scene not in out and exists(scene):
            out.append(scene)
    return out


# --- Rangées --------------------------------------------------------------------------------------------------


def _polyline(points):
    """[(x0, z0, ux, uz, longueur, cumul)] des segments d'une polyligne."""
    segs = []
    total = 0.0
    for k in range(len(points) - 1):
        (ax, az), (bx, bz) = points[k], points[k + 1]
        length = math.hypot(bx - ax, bz - az)
        if length == 0:
            continue
        segs.append((ax, az, (bx - ax) / length, (bz - az) / length, length, total))
        total += length
    return segs, total


def _at(segs, t):
    for ax, az, ux, uz, length, start in segs:
        if t <= start + length or (ax, az, ux, uz, length, start) == segs[-1]:
            d = t - start
            return ax + ux * d, az + uz * d, ux, uz
    return None


def pick_images(count, pool, rng, accents=(), accent_every=(0, 0)):
    """count images tirées de pool, jamais la même deux fois de suite (dès que pool en a deux), chaque image
    du pool servie avant qu'une autre ne revienne une troisième fois ; un accent (accents) tous les
    accent_every = (a, b) éléments, tiré au hasard dans [a, b] (0 : jamais)."""
    used = {s: 0 for s in pool}
    out = []
    wait = rng.randint(*accent_every) if accent_every[1] else -1
    last_accent = None
    for k in range(count):
        if accents and wait == 0:
            choices = [a for a in accents if a != last_accent] or list(accents)
            scene = choices[rng.randrange(len(choices))]
            last_accent = scene
            out.append(scene)
            wait = rng.randint(*accent_every)
            continue
        wait -= 1
        prev = out[-1] if out else None
        choices = [s for s in pool if s != prev] or list(pool)
        least = min(used[s] for s in choices)
        # Les moins servies d'abord, au hasard parmi elles (une image n'attend jamais deux tours de trop).
        fair = [s for s in choices if used[s] <= least + 1]
        scene = fair[rng.randrange(len(fair))]
        used[scene] += 1
        out.append(scene)
    return out


def row(points, pool, seed, step=None, spread=0.3, depth=0.6, depth_range=None, skip=0.08, accents=(),
        accent_every=(0, 0), scale=(1.0, 1.0), flip=True, overlap=0.9, keep=None, tone=(0.05, 0.02), ends=True):
    """Une rangée irrégulière le long de la polyligne points [(x, z), …] : [(scène, x, z, retourné, échelle,
    teinte)].

    - step : pas moyen (m) ; sans pas, chaque élément touche le précédent (demi-largeurs × overlap), une haie,
      une clôture ; spread : écart du pas (± part : 0,3 = ± 30 %) ;
    - depth : recul (± m, le long de la normale à la rangée ; z quand la rangée va d'est en ouest), ou
      depth_range = (de, à) pour un recul d'un seul côté (un garde-corps au bord du vide) ;
    - skip : part des éléments sautés (jamais deux de suite, jamais le premier ni le dernier) ;
    - accents, accent_every : une autre image tous les a à b éléments (un buisson dans une clôture) ;
    - pool : la famille (pick_images : jamais la même image deux fois de suite) ;
    - scale : (min, max) de l'échelle ; flip : retournement au hasard ; keep(x, z) : le point est-il permis ;
    - tone : (luminosité, teinte) au plus, tirées pour chaque élément (DecorPanel.tone) ;
    - ends : poser un élément aux deux bouts (une rangée fermée, une clôture d'un poteau à l'autre)."""
    rng = random.Random(seed)
    segs, total = _polyline(points)
    if not segs or not pool:
        return []
    widths = {s: prop(s).w for s in list(pool) + list(accents)}
    # Les images d'abord (assez pour la rangée la plus serrée), le chemin ensuite.
    narrow = min(widths[s] for s in pool)
    est = int(total / max(0.3, (step or narrow * overlap) * (1.0 - spread))) + 3
    images = pick_images(est, list(pool), rng, accents, accent_every)
    out = []
    t = 0.0
    k = 0
    skipped = False
    prev_w = None
    while k < len(images):
        scene = images[k]
        w = widths[scene]
        if step is None:
            if prev_w is not None:
                t += (prev_w + w) / 2.0 * overlap * (1.0 + rng.uniform(-spread, spread))
        elif k:
            t += step * (1.0 + rng.uniform(-spread, spread))
        if t > total + 0.01:
            break
        prev_w = w
        k += 1
        x, z, ux, uz = _at(segs, min(t, total))
        nx, nz = -uz, ux
        if depth_range is not None:
            off = rng.uniform(*depth_range)
        else:
            off = rng.uniform(-depth, depth)
        # La normale tournée vers le sud (z croissant) : un recul positif va vers la caméra.
        if nz < 0 or (nz == 0 and nx < 0):
            nx, nz = -nx, -nz
        px, pz = x + nx * off, z + nz * off
        s = round(rng.uniform(*scale), 3)
        flipped = rng.random() < 0.5 if flip else False
        tn = (round(rng.uniform(-tone[0], tone[0]), 3), round(rng.uniform(-tone[1], tone[1]), 3))
        first = not out
        last = t >= total - (step or w) * 0.5
        if not first and not last and not skipped and rng.random() < skip:
            skipped = True
            continue
        skipped = False
        if keep is not None and not keep(px, pz):
            continue
        out.append((scene, round(px, 3), round(pz, 3), flipped, s, tn))
    # Un élément sauté rapproche deux images que rien ne séparait plus : la seconde en prend une autre de la
    # famille, différente de ses deux voisines (même largeur ou presque, pour ne pas ouvrir de trou).
    if len(pool) >= 2:
        for k in range(1, len(out)):
            if out[k][0] != out[k - 1][0] or out[k][0] not in pool:
                continue
            after = out[k + 1][0] if k + 1 < len(out) else None
            others = [s for s in pool if s not in (out[k - 1][0], after) and abs(widths[s] - widths[out[k][0]]) < 0.6]
            if others:
                out[k] = (others[rng.randrange(len(others))],) + out[k][1:]
    return out


def along_irregular(points, step, offset, seed, spread=0.3, lateral=0.25, skip=0.15, yaw_jitter=10.0):
    """(QC-29) Points d'une bordure le long d'une polyligne, des deux côtés, pour des décalques couchés (bordures
    d'herbe) : pas variable (± spread), écart au bord variable (± lateral m), quelques trous (skip), lacet qui suit
    le chemin à ± yaw_jitter degrés près : [(x, z, lacet)]."""
    rng = random.Random(seed)
    out = []
    for k in range(len(points) - 1):
        (ax, az), (bx, bz) = points[k], points[k + 1]
        length = math.hypot(bx - ax, bz - az)
        if length == 0:
            continue
        ux, uz = (bx - ax) / length, (bz - az) / length
        nx, nz = -uz, ux
        yaw = math.degrees(math.atan2(-uz, ux))
        for side in (-1, 1):
            t = rng.uniform(0.0, step)
            while t < length:
                if rng.random() >= skip:
                    o = offset + rng.uniform(-lateral, lateral)
                    a = yaw + (180.0 if side > 0 else 0.0) + rng.uniform(-yaw_jitter, yaw_jitter)
                    out.append((round(ax + ux * t + nx * o * side, 3), round(az + uz * t + nz * o * side, 3),
                                round(a, 2)))
                t += step * (1.0 + rng.uniform(-spread, spread))
    return out


# --- Le sol sous un point ---------------------------------------------------------------------------------------


def solid(p, x, z):
    """Vrai si la case sous (x, z) a un sol (pas le vide du bord de l'île)."""
    import map_build
    i, j = int(math.floor(x)), int(math.floor(z))
    if not (0 <= i < p.W and 0 <= j < p.D):
        return False
    c = j * p.W + i
    return not (p.ground.kinds[c] == map_build.FLAT and p.ground.levels[c] is None)


def _standing_near(p, x, z, margin):
    for _label, sx, sz in p.standing_extra:
        if abs(sx - x) < margin and abs(sz - z) < margin:
            return True
    return False


def _clear(p, x, z, half, margin=1.0, paths=0.8):
    """Rien du plan ne gêne un décor de demi-emprise half en (x, z) : sorties, marqueurs, points, places de la vie,
    bâtiments, décors qui bloquent, places et chemins (à paths m de leur bande libre)."""
    box = Rect(x - half[0], z - half[1], x + half[0], z + half[1])
    if any(e.hits(box, 2.0) for e in p.exits):
        return False
    if any(box.has(mx, mz, 1.6 + margin) for mx, mz in p.markers.values()):
        return False
    if any(box.has(px, pz, 1.0 + margin) for px, pz in p.points.values()):
        return False
    if any(b.hits(box, 0.4) for b in p.buildings):
        return False
    if any(b.hits(box, 0.3) for b in p.blockers):
        return False
    if any(r.hits(box, 0.3) for r in p.places.values()):
        return False
    if p.path_distance(x, z) < max(half) + paths:
        return False
    return not _standing_near(p, x, z, max(half) + margin)


def _tall_near(p, x, z, gap):
    """Un décor unique haut (1,5 m ou plus) à moins de gap m."""
    for _group, _name, scene, sx, _y, sz, scale, _flip, _extra in p.singles:
        if abs(sx - x) < gap and abs(sz - z) < gap:
            q = prop(scene)
            if not q.decal and q.h * scale >= 1.5:
                return True
    return False


# --- Premier plan : feuillages et troncs au bord sud de chaque vue -----------------------------------------------


def passages(p, step=15.0, exit_margin=6.0):
    """Des points le long des chemins du plan, tous les step m, loin des sorties : [(nom, x, z)]."""
    out = []
    for name, _width, pts in p.paths:
        t0 = step / 2.0
        segs, total = _polyline(pts)
        t = t0
        k = 0
        while t < total:
            x, z, _ux, _uz = _at(segs, t)
            if p.in_map(x, z, 1.0) and not any(e.has(x, z, exit_margin) for e in p.exits):
                out.append(("passage %s %d" % (name, k + 1), x, z))
            k += 1
            t += step
    return out


def foreground_kit(p, bounds, targets, seed, group="Foreground", base="PremierPlan", want=2, most=4,
                   foliage=None, trunks=None, trees=None, keep=None, lateral=(3.4, 8.6), near=(3.0, 5.6),
                   far=(5.0, 12.5)):
    """Le premier plan (CARTE.md 0.5) : pour chaque cible (nom, x, z) (vues de la série QC, passages), deux à
    quatre feuillages ou troncs de premier plan (`_fg`, sans collision, qui s'effacent autour du joueur) au sud du
    joueur, sur les côtés de l'écran (lateral m de part et d'autre), près du bord sud de la vue : les feuillages de
    near m au sud du joueur, les troncs de far m (seulement là où l'on ne marche pas : un tronc ne se traverse pas).
    Jamais devant une place où l'on se tient (exterior_pose.clear_of_places), jamais sur un chemin, une place, un
    point ou une place de la vie ; keep(x, z) : le point est-il permis. Rend le nombre de décors posés."""
    rng = random.Random(seed)
    foliage = foliage if foliage is not None else family("fg_foliage", ["fg_grass"])
    # (Essai) Un tronc de 10 m près de la caméra penche de toute la hauteur de l'écran (la perspective de la caméra
    # inclinée) : pas de tronc par défaut ; des arbres plus loin, dont seule la couronne paraît.
    trunks = trunks if trunks is not None else []
    if trees is None:
        # Les arbres de premier plan déjà posés sur la carte d'abord (une image de plus est un matériau, donc un draw
        # call, de plus : test_hd2d_decor borne les images d'une carte) ; sinon trois arbres d'automne.
        every = [FOREGROUND[s] for s in family("trees_gold") + family("trees_rust") if s in FOREGROUND]
        used = {q[2] for q in p.singles} | {s for spec in p.families.values() for s in spec["scenes"]}
        trees = [s for s in every if s in used] or every[:3]
    placed = []
    pools = {"fol": foliage, "trunk": trunks, "tree": trees}
    turn = {"fol": 0, "trunk": 0, "tree": 0}

    def fits(kind, scene, x, z, fz):
        """Le décor scene peut-il aller en (x, z) pour une vue de point visé en z fz ?"""
        q = prop(scene)
        half = (q.w / 2.0 * 0.8, 0.5)
        if kind == "trunk":
            if p.walkable_here(x, z) or any(b.has(x, z, 0.5) for b in p.buildings):
                return False
        elif kind == "tree":
            # Un arbre qui bloque (son tronc) : loin de tout ce où l'on passe, de la vie, des places.
            if not _clear(p, x, z, (0.6, 0.6), margin=1.6, paths=1.6):
                return False
        elif not _clear(p, x, z, half, margin=0.8, paths=0.6 if q.h >= 2.0 else 0.0):
            # Une herbe haute de premier plan (moins de 2 m) peut border un chemin : elle ne cache personne.
            return False
        beyond = z - (fz + BOTTOM_Z)
        if beyond > 0 and q.h < beyond * BOTTOM_SLOPE + 0.6:
            return False
        return clear_of_places(p, [scene], [(x, z)], 1.05) != []

    # Trois passes (grilles tirées à nouveau) : une cible voisine d'une autre déjà servie trouve sa place ensuite.
    for tname, tx, tz in list(targets) * 3:
        fx, fz = focus_of(tx, tz, bounds)
        have = view_south(p, bounds, [(tname, tx, tz)])[0][1]
        goal = rng.randint(want, most)
        if have >= goal:
            continue
        # Une grille de places tirée au hasard sur les côtés de l'écran (cases de 1,3 m sur 0,7 m pour les feuillages,
        # de 1,3 m sur 1,5 m pour les troncs et les arbres).
        cands = []
        for side in (-1, 1):
            dx = lateral[0]
            while dx <= lateral[1]:
                dz = near[0]
                while dz <= near[1]:
                    cands.append(("fol", fx + (dx + rng.uniform(0.0, 1.3)) * side, tz + dz + rng.uniform(0.0, 0.7)))
                    dz += 0.7
                dz = far[0]
                while dz <= far[1]:
                    if trunks:
                        cands.append(("trunk", fx + (dx + rng.uniform(0.0, 1.3)) * side, tz + dz + rng.uniform(0.0, 1.5)))
                    if trees:
                        cands.append(("tree", fx + (dx + rng.uniform(0.0, 1.3)) * side, tz + dz + rng.uniform(0.0, 1.5)))
                    dz += 1.5
                dx += 1.3
        rng.shuffle(cands)
        # Les feuillages d'abord (le bas de l'écran), puis troncs et arbres (les côtés).
        cands.sort(key=lambda c: 0 if c[0] == "fol" else 1)
        for kind, x, z in cands:
            if have >= goal:
                break
            x, z = round(x, 2), round(z, 2)
            # Au-delà du bord sud de la carte (on n'y marche jamais, le sol s'y prolonge), un premier plan tant qu'il
            # se voit.
            beyond_map = p.D - 0.2 < z <= p.D + 4.5 and 0.6 <= x <= p.W - 0.6 and solid(p, x, p.D - 0.5)
            if not beyond_map and (not p.in_map(x, z, 0.6) or not solid(p, x, z)):
                continue
            if keep is not None and not keep(x, z):
                continue
            if any(abs(x - px) < 2.4 and abs(z - pz) < 1.6 for px, pz in placed):
                continue
            if _tall_near(p, x, z, 1.8):
                continue
            # Les images de la famille, à tour de rôle (jamais deux fois de suite la même) ; la première qui va.
            pool = pools[kind]
            order = [pool[(turn[kind] + i) % len(pool)] for i in range(len(pool))]
            scene = next((s for s in order if fits(kind, s, x, z, fz)), None)
            if scene is None:
                continue
            turn[kind] = (pool.index(scene) + 1) % len(pool)
            s = round(rng.uniform(0.95, 1.05), 2)
            p.place(group, scene, x, z, scale=s, flip=rng.random() < 0.5, name="%s%d" % (base, len(placed) + 1),
                    check=False)
            placed.append((x, z))
            have += 1.0
    return len(placed)


def foreground_views(p, map_id, seed, with_passages=True, **options):
    """foreground_kit pour les vues de la série QC d'une carte d'abord, puis pour ses passages (les vues sont servies
    en premier : ce sont elles que le contrôle compte ; with_passages faux : les vues seulement, une petite carte déjà
    dense). Rend le nombre de décors posés."""
    options.setdefault("most", 3)
    n = foreground_kit(p, p.view_bounds, qc_views(map_id), seed, **options)
    if not with_passages:
        return n
    options = dict(options, base=options.get("base", "PremierPlan") + "Passage", most=2)
    return n + foreground_kit(p, p.view_bounds, passages(p), seed + 1, **options)


# --- Plan moyen : des masses dans les places nues ----------------------------------------------------------------


def middle_kit(p, areas, pool, seed, group="Middle", base="Masse", spacing=4.5, avoid=(), margin=1.6, scale=(0.9, 1.1)):
    """Le plan moyen (CARTE.md 0.5) : des masses de 1,5 à 3 m (fourrés, jeunes arbres, meules, piles de caisses)
    dans les étendues nues, areas = [(Rect, nombre)] : loin des chemins, des points, des places de la vie
    (margin m), hors des places du plan et des rectangles avoid (un terrain de jeu) ; jamais devant une place où
    l'on se tient ; la règle de caméra (un décor qui cache un passage prend sa variante de premier plan, ou n'est
    pas posé). Rend le nombre de masses posées."""
    rng = random.Random(seed)
    images = pick_images(64, pool, rng)
    n = 0
    pts = []
    for area, count in areas:
        tries = 0
        got = 0
        while got < count and tries < count * 60:
            tries += 1
            x, z = round(rng.uniform(area.x0, area.x1), 2), round(rng.uniform(area.z0, area.z1), 2)
            scene = images[n % len(images)]
            q = prop(scene)
            s = round(rng.uniform(*scale), 2)
            half = (max(q.half[0], q.w * 0.35) * s, max(q.half[1], 0.4) * s)
            if not p.in_map(x, z, 1.0) or not solid(p, x, z) or not p.outside_edges(x, z, 0.3):
                continue
            if any(math.hypot(x - a, z - b) < spacing for a, b in pts):
                continue
            if any(r.has(x, z, max(half) + 0.8) for r in avoid):
                continue
            if not _clear(p, x, z, half, margin=margin, paths=0.9):
                continue
            if _tall_near(p, x, z, 2.0):
                continue
            if q.h * s >= 2.0 and not clear_of_places(p, [scene], [(x, z)], s):
                continue
            if q.h * s > 1.2 and p.hides_someone(x, z, p.height(x, z), q.w * s, q.h * s) and scene not in FOREGROUND:
                continue
            p.place(group, scene, x, z, scale=s, flip=rng.random() < 0.5, name="%s%d" % (base, n + 1))
            pts.append((x, z))
            n += 1
            got += 1
    return n


# --- Le fond : un second rang de lisière --------------------------------------------------------------------------


def second_rank(p, group, x0, x1, z, y, seed, base="LisiereFond", offset=8.0, scale=1.0, pool=None):
    """Le second rang d'une lisière (CARTE.md 0.5) : des pans à raccord de 16 m bout à bout, de x0 − 16 à x1 + 16
    (aucun bout libre dans le champ), décalés de offset m (un demi-pan) sur le premier rang, en z, à la hauteur y ;
    images de la famille lisiere_back (un pan peint pour le second rang, livré plus tard, y entre seul), jamais la
    même deux fois de suite, retournées au hasard."""
    rng = random.Random(seed)
    pool = pool or family("lisiere_back")
    width = 16.0 * scale
    x = x0 - width + offset
    count = int(math.ceil((x1 + width - x) / width)) + 1
    images = pick_images(count, pool, rng)
    for k in range(count):
        p.place(group, images[k], round(x, 3), z, y=y, scale=scale, flip=rng.random() < 0.5,
                name="%s%d" % (base, k + 1), check=False)
        x += width
        if x - width / 2.0 > x1 + width:
            break


def place_row(p, group, base, items, check=True, y=None, lift=0.0):
    """Pose une rangée (row) : décors uniques nommés <base><n>, teinte variée ; y : hauteur imposée (sinon
    le sol) ; lift : m au-dessus du sol."""
    placed = []
    for k, (scene, x, z, flipped, s, tn) in enumerate(items):
        yy = y if y is not None else p.height(x, z) + lift
        q = prop(scene)
        extra = {"tone": tn} if any(tn) and not (q.decal or q.building or q.frames > 1) else {}
        placed.append(p.place(group, scene, x, z, y=yy, scale=s, flip=flipped, name="%s%d" % (base, k + 1),
                              extra=extra, check=check))
    return placed


# --- Les vues de la série QC ----------------------------------------------------------------------------------


def qc_views(map_id):
    """Les vues de jeu d'une carte (tools/qc_views.json, sans les vues d'ensemble) : [(nom, x, z)]."""
    with open(QC_VIEWS, encoding="utf-8") as handle:
        views = json.load(handle)["maps"].get(map_id, {}).get("views", [])
    return [(v["name"], float(v["at"][0]), float(v["at"][1])) for v in views if "at" in v and not v.get("overview")]


def focus_of(x, z, bounds):
    """Le point visé de la caméra quand le joueur est en (x, z) : 2,5 m au nord, borné."""
    bx, bz, bw, bd = bounds
    return min(max(x, bx), bx + bw), min(max(z - 2.5, bz), bz + bd)


# Le champ d'une vue (docs/QUALITE.md, 1) : 9,5 m de part et d'autre du point visé, 14 m au nord, 6,5 m au sud.
FIELD = (9.5, 14.0, 6.5)
# Le rayon du bas de l'écran (32° + 15° sous l'horizon, caméra à 21 m) touche le sol 6,7 m au sud du point visé :
# au-delà, un objet ne se voit que s'il dépasse ce rayon (pente tan 47°).
BOTTOM_Z = 6.7
BOTTOM_SLOPE = math.tan(math.radians(47.0))


def _items(p):
    """Les panneaux debout posés : [(image, x, z, hauteur, poids, premier plan)] ; une famille compte chacune de
    ses scènes pour sa part (le tirage se fait au lancement)."""
    out = []
    for _group, _name, scene, x, _y, z, scale, _flip, _extra in p.singles:
        q = prop(scene)
        if q.decal or q.building or not q.image or q.frames > 1:
            continue
        out.append((q.image, x, z, q.h * scale, 1.0, q.fg))
    for _fam, spec in p.families.items():
        scenes = spec["scenes"]
        mean = math.fsum(spec["scale"]) / 2.0
        for point in spec["points"]:
            for scene in scenes:
                q = prop(scene)
                if q.decal or q.building or not q.image or q.frames > 1:
                    continue
                out.append((q.image, point[0], point[1], q.h * mean, 1.0 / len(scenes), q.fg))
    return out


def view_repeats(p, bounds, views, min_h=0.75):
    """Pour chaque vue : (nom, image la plus répétée, nombre) parmi les panneaux de min_h m ou plus dans son
    champ (une famille compte pour sa part)."""
    items = [q for q in _items(p) if q[3] >= min_h]
    out = []
    for name, x, z in views:
        fx, fz = focus_of(x, z, bounds)
        counts = {}
        for image, ix, iz, _h, weight, _fg in items:
            if fx - FIELD[0] <= ix <= fx + FIELD[0] and fz - FIELD[1] <= iz <= fz + FIELD[2]:
                counts[image] = counts.get(image, 0.0) + weight
        if counts:
            image = max(sorted(counts), key=lambda i: counts[i])
            out.append((name, os.path.basename(image)[:-4], counts[image]))
        else:
            out.append((name, "", 0.0))
    return out


def view_south(p, bounds, views, min_h=1.5):
    """Pour chaque vue : (nom, objets hauts au sud) : les panneaux de min_h m ou plus au sud du joueur (à plus
    d'un mètre), dans la largeur du champ, qui se voient au bas de l'écran (leur sommet dépasse le rayon du bas
    de l'écran)."""
    items = [q for q in _items(p) if q[3] >= min_h]
    out = []
    for name, x, z in views:
        fx, fz = focus_of(x, z, bounds)
        n = 0.0
        for _image, ix, iz, h, weight, _fg in items:
            if iz <= z + 1.0 or abs(ix - fx) > FIELD[0]:
                continue
            beyond = iz - (fz + BOTTOM_Z)
            if beyond > 0 and h < beyond * BOTTOM_SLOPE + 0.4:
                continue
            n += weight
        out.append((name, n))
    return out
