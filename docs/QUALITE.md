# La qualité visuelle : grille de revue et registre des défauts

Le garant de la qualité visuelle (lot QC, rôle permanent) regarde chaque vue du jeu comme un joueur
exigeant qui connaît *Octopath Traveler*, relève les défauts que les tests ne voient pas, corrige ce
qui relève du code ou des données et commande à ChatGPT ce qui demande une image (cahier n° 5,
`docs/ASSETS_HD2D_ILE68.md`, lot R0). Ce document dit comment on regarde (sections 1 et 2), ce qu'on
cherche (section 3) et ce qu'on a trouvé (section 4, le registre).

## 1. La série standard de vues

- **Les vues sont des données** : `tools/qc_views.json`. Par carte de l'île
  (`data/world/islands/ile_68.json`) : son genre (`dehors`, `dedans`, `attente` pour les cartes
  d'attente et d'essai, vues d'ensemble seulement) et ses points de vue : `name`, `at` = [x, z] en
  mètres dans le repère de la carte (coin nord-ouest), `look` (N, S, E, O : où regarde le joueur ;
  la caméra regarde toujours le nord), `moments` (`matin`, `couchant`, `nuit`… ou `moment:temps`
  pour la pluie), `overview: true` pour une vue d'ensemble prise d'une caméra haute au sud de la
  carte.
- **Une carte nouvelle** entre dans `qc_views.json` avec ses vues, en même temps que dans
  `ile_68.json`. `python3 tools/qc_tool.py check` vérifie que chaque carte de l'île a ses vues et que
  chaque pièce, place et point nommé de `docs/lore/CARTE.md` est dans le champ d'au moins une vue
  (le point visé est à 2,5 m au nord du joueur, borné par `camera_bounds` ; on compte 9,5 m de part
  et d'autre, 14 m au nord et 6,5 m au sud) ; `tests/unit/test_qc_views.gd` vérifie le premier point
  avec le reste des tests.
- **Les captures** : `tools/qc_shots.sh` (toutes les vues, environ 45 min sous Xvfb) ou
  `tools/qc_shots.sh village cafe:comptoir village:rue:nuit:pluie` (des cartes, des vues, une
  capture). C'est la vraie partie (`game.tscn`), posée par `WorldManager.enter_map`, vue par la
  caméra du joueur avec le post-traitement et la lumière d'`Atmosphere`, la vie et l'interface.
  Sortie : `build/qc/<date>/` (ou `QC_OUT=build/qc/apres`), une image par vue
  (`<carte>_<vue>_<moment>[_<temps>].png`), `index.tsv` et `qc.log` (draw calls, primitives,
  objets, luminance moyenne et du centre, personnages visibles) et une **planche contact par
  carte** (`contact_<carte>.png`, en rouge les vues au-delà de 200 draw calls ou sous 0,1 de
  luminance).
- **Avant / après** : on recapture la même vue dans un autre dossier,
  `QC_OUT=build/qc/apres tools/qc_shots.sh village:rue`, et on ouvre les deux images.

## 2. Comment on regarde

1. Parcourir les planches contact, carte par carte, pour repérer les vues suspectes.
2. **Ouvrir en grand chaque vue suspecte** (outil de lecture d'images) : un défaut d'échelle, une
   couture ou un meuble de travers ne se voit pas sur une vignette.
3. Pour chaque défaut : le décrire comme un joueur le dirait (« le canapé est posé de travers »),
   puis en trouver la cause (image, pose, données, lumière, code) avant de choisir l'action.
4. **Corriger** dans le code ou les données ce qui s'y corrige, toujours par les générateurs et les
   plans (`tools/exterior_maps.py` et ses recettes, `tools/interior_maps.py`,
   `docs/lore/CARTE.md`), jamais à la main dans un `.tscn` généré ; recapturer la vue, comparer.
5. **Commander** ce qui demande une image : une ligne au cahier n° 5, section R0 (sur le modèle de
   R0.8) : le constat, le fichier, la taille, la consigne prête à copier, ce qu'il ne faut pas
   faire. Les images livrées ne sont jamais retouchées.
6. **Désigner le lot** quand le défaut relève de la vie, du récit ou des jeux (E6 le récit, E8 les
   jeux, C3 la colline, I2 l'intégration des images du lot R1…) : une ligne au registre, rien de
   plus.
7. Être sévère : dix défauts signalés valent mieux qu'un seul laissé passer.

## 3. La grille : ce qu'on cherche

| Défaut | Ce qu'on voit | Exemple |
| --- | --- | --- |
| **Échelle** | Un objet trop grand ou trop petit à côté des personnages (fée de 1,1 m, adulte de 1,75 m ; 96 px par mètre) ; une porte où l'on ne passe pas | Les pions de `game_table` plus hauts que la table n'est épaisse : la table paraît minuscule (R0.2) |
| **Perspective qui ne suit pas la caméra** (32°) | Plateau en trapèze, point de fuite, meuble vu de trop haut ou en élévation pure à côté d'un autre vu d'en haut | Les tables du réfectoire en perspective conique, qui se lisent comme des bancs bas (R0.2) |
| **Meuble de face contre un mur de côté** | Un meuble adossé au mur est ou ouest qui fait face au sud et sort du mur comme une péninsule | Le canapé des archives « posé de travers » (R0.3, `regard=` au plan) |
| **Raccords et coutures de sol** | Ligne droite visible entre deux matières, tuile qui se répète en damier, bord net d'un décalque | Le bord net d'une flaque sur les pavés |
| **Décalques qui se lisent mal** | Une trace qui se lit comme autre chose : sillons, taches, trous | Les ornières de la rue du village, lues comme des sillons de labour (R0.8) |
| **Répétition visible** | Le même décor trois fois en ligne, à intervalle régulier, ou la même touffe partout | Une rangée de chaises identiques qui fait palissade (R0.2, `chair_wood`) |
| **Vide ou surcharge** | Plus de 6 × 6 m de sol nu hors d'une place voulue ; ou un fouillis qui cache le chemin | Un pré sans une fleur ni un caillou entre deux décors |
| **Objets qui flottent ou s'enfoncent** | Pied qui ne touche pas le sol, panneau coupé par une marche, décor posé dans l'eau | Un tonneau à moitié dans une marche du palier |
| **Personnages cachés** | Le joueur ou un PNJ derrière un toit, un arbre ou un meuble haut, sans effacement | Le joueur caché derrière une façade au sud de lui (CARTE.md 0.3) |
| **Premier plan qui gêne** | Un panneau du bord sud qui couvre le tiers bas de l'écran ou ne s'efface pas | Une haie de premier plan qui coupe le joueur aux genoux |
| **Lumière** | Nuit illisible (luminance moyenne sous 0,1), vitres éteintes la nuit, lampe sans halo, intérieur noir, ombre portée dans le mauvais sens | Le café du village la nuit, éclairé par la seule lumière du joueur |
| **Texte ou interface qui déborde** | Invite qui sort de son cadre, bannière coupée, texte sur le visage d'un personnage | L'invite « Examiner » posée sur l'étagère du comptoir |
| **Remplaçants trop visibles** | Image de remplacement (aplats, formes simples) au premier rang d'une vue importante | Un meuble gris de remplacement au milieu d'une pièce livrée |
| **Fautes d'orthographe** | Dans les textes affichés : noms de cartes, invites, écriteaux, dialogues | — |
| **Le HUD de l'ancienne quête qui traîne** | Le suivi de quête de l'ancienne île affiché dans les nouvelles cartes | « Dans la forêt céleste — Rejoindre Nygglatho sous le porche » au village |

Gravité : **1** se voit tout de suite (un joueur le remarque dans la première seconde) ; **2** se
remarque (en s'arrêtant sur la vue) ; **3** détail.

## 4. Registre

Une ligne par défaut. Captures : `build/qc/<passage>/…` (hors dépôt ; un passage se refait par
`tools/qc_shots.sh`). Action : **corrigé** (commit), **commandé** (section du cahier n° 5), **lot**
(le lot désigné), **à trancher** (par l'utilisateur). État : ouvert, corrigé, commandé, signalé.

| Id | Carte et vue | Capture | Description | Grav. | Cause | Action | État |
| --- | --- | --- | --- | --- | --- | --- | --- |
