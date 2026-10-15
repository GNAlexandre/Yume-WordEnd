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
- **Planche comparative** (QO) : `python3 tools/qc_tool.py board <sortie.png> <titre> "A avant=<dossier>"
  "B après=<dossier>" -- <vue>[@x0,y0,x1,y1]…` : une colonne par option (son nom en gros), une ligne par
  capture (nom sans `.png`), réduite à 640 px ; `@x0,y0,x1,y1` ajoute le détail de ce cadre, agrandi. Le
  journal donne aussi la place du joueur à l'écran (« joueur à l'écran x ; y pieds ; y tête », de −1 à 1).

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
(le lot désigné), **à trancher** (par l'utilisateur). État : ouvert, corrigé, atténué, commandé, signalé,
à trancher, non retenu (voulu par le plan).

| Id | Carte et vue | Capture | Description | Grav. | Cause | Action | État |
| --- | --- | --- | --- | --- | --- | --- | --- |
| QC-01 | entrepot : facade, porche (nuit) ; toutes les façades | `build/qc/2026-10-15-avant/entrepot_porche_nuit.png` → `…-apres/entrepot_porche_nuit.png` | La nuit, aucune vitre ne s'allume : les fenêtres peintes en jaune chaud deviennent grises, l'entrepôt a l'air abandonné | 1 | Moteur : `glow_color` (`panel_core.gdshaderinc`) portait `source_color` ; le rendu Compatibility comparait une couleur sRGB au pixel de l'image lu en linéaire : distance toujours au-delà du seuil, lueur nulle partout (vérifié : `glow_strength` forcé à 6, rien ne change) | Corrigé : comparaison en sRGB (commit e2a4872) | corrigé |
| QC-02 | entrepot : façades livrées du lot R1 (fusion d'I2) ; village : café | `build/qo/avant/entrepot_ensemble_nuit.png` → `build/qo/apres02/` ; planche `build/qo/QC-02.png` | Défaut relevé par I2 : la nuit, les carreaux de l'aile ouest restent à demi éteints, ceux du flanc est aussi ; la vitrine du café reste sombre | 1 | Moteur : une seule règle de lueur (#FFE6A6 à 0,12 voulue, en fait #FFCA63 : le rendu Compatibility lit l'image sans la convertir en linéaire) pour des carreaux dessinés de #FCD069 à #FCE18F ; élargir la règle commune allumerait le torchis ocre des chaumières | Corrigé (QO) : `Building.window_glow_color` et `window_glow_tolerance`, réglées par bâtiment (aile ouest #FCDB86 à 0,12, aile est #FCD070 à 0,15) ; le café garde la règle par défaut (une règle propre à ses lampes de vitrine en faisait des taches blanches bruitées) : sa vitrine attend la façade de nuit commandée (cahier n° 5, R0.9 ; QC-16) ; chaumières à la règle par défaut, éteintes (`test_window_glow.gd`) ; la commande du cahier n° 5 (3.6) devient inutile | corrigé |
| QC-03 | entrepot : arbre, riviere, bois_sud, potager, ouest, sentier_est | `…-avant/entrepot_arbre_nuit.png`, `entrepot_riviere_matin.png` → `…-apres/` | Des flaques bleues à quatre pierres en travers des chemins secs | 2 | Pose : `stepping_stones` (pierres de gué dans l'eau claire) semé tous les 7 m sur les chemins | Corrigé : un seul gué, sur la rivière (recette `entrepot.py`) | corrigé |
| QC-04 | entrepot : cour | `…-avant/entrepot_cour_matin.png` → `…-apres/` | Une dizaine de traînées de pas identiques, à tous les angles : des pistes de fourmis en travers de la cour | 2 | Pose : `footprints` dans les familles tirées au hasard de la cour et du duel | Corrigé : restent les quatre traces posées | corrigé |
| QC-05 | entrepot : champ | `…-avant/entrepot_champ_matin.png` → `…-apres/` | Des plaques de boue brunes à bords nets sur l'herbe sèche : des carrés bêchés | 2 | Pose : `mud_patch` et `footprints` tirés au hasard au champ | Corrigé : restent l'usure des deux buts et trois traces | corrigé |
| QC-06 | entrepot : marais | `…-avant/entrepot_marais_matin.png` → `…-apres/` | La berge entre le pré et le marais de l'ouest est une droite de 20 m | 2 | Données du sol : rectangle franc `[0, 4, 6, 20]` sous la berge bruitée | Corrigé : rectangle ramené à x = 5, le bruit fait la berge | corrigé |
| QC-07 | entrepot : marais, clairière | `…-avant/entrepot_marais_matin.png` | Des encoches de talus d'une case au bout des paliers (petits rectangles sombres qui pendent) | 3 | Sol en relief : faces des paliers sur des cases isolées | Lot E2 (sol en relief) | signalé |
| QC-08 | entrepot_rdc : couloir, bains, entrée, jeux, infirmerie (nuit) | `…-avant/entrepot_rdc_jeux_nuit.png`, `entrepot_rdc_infirmerie_nuit.png` → `…-apres/` | La nuit, la bande sud et le couloir n'ont que la lumière du joueur | 2 | Plan : aucune lampe dans ces pièces | Corrigé : deux suspensions au couloir, appliques aux bains, à l'entrée et aux jeux, suspension et lampe de bureau à l'infirmerie (CARTE.md 3.1) | corrigé |
| QC-09 | entrepot_etage : couloir, couloir_fuite (nuit) | `…-avant/entrepot_etage_couloir_fuite_nuit.png` → `…-apres/` | Le bout est du couloir (la fuite, la trappe) est noir la nuit | 2 | Plan : une seule applique, au pignon ouest | Corrigé : deux suspensions (CARTE.md 3.2) | corrigé |
| QC-10 | entrepot_toit : bord_sud, terrasse | `…-avant/entrepot_toit_bord_sud_matin.png` → `…-apres/` | À l'est, le sous-bois 6,5 m plus bas se lit comme un pré au niveau des planches : le toit semble posé par terre | 2 | Pose : rien ne cache le sol en contrebas au sud-est | Atténué : deux couronnes d'arbres au ras de la terrasse au sud-est (`interior_maps.py`, ROOF_TREES) ; le tronc du grand arbre de l'est se voit encore au niveau des planches. À revoir après fusion d'I2 (bord du toit `roof_edge_slate` livré) ; sinon, à trancher : un bord de toit visible à l'est | atténué |
| QC-11 | salle_des_armes : toutes (nuit) | `build/qc/2026-10-15-avant/salle_des_armes_crypte_nuit.png` | La crypte est presque noire la nuit (luminance 0,04, centre 0,06), et la lumière qu'on y apporte (la lueur de fée du joueur) ne l'éclaire pas | 1 | Voulu par le plan : « crypte sans lumière », seulement celle qu'on apporte (CARTE.md 3.4 ; `test_salle_des_armes.gd`) ; mais la lumière du joueur reste sans effet dans cet intérieur | Lot E9 (la lumière du joueur dans une pièce sans lampe : rayon de 4 m, CARTE.md 3.4). Essai d'appliques retiré : il contredisait le plan | signalé |
| QC-12 | sentier : entree, berge, est | `…-avant/sentier_entree_matin.png` → `…-apres/` | Une masse sombre de feuillage flotte au milieu de l'écran, au-dessus du sentier | 1 | Pose : `fg_canopy_a` (voûte vue d'en dessous) posé en l'air à 2,6 m, faute de premier plan accroché à l'écran | Corrigé : retiré du plan (CARTE.md 4.2) ; il attend E10 ; test mis à jour | corrigé |
| QC-13 | village : toutes ; cafe : toutes | `…-avant/village_rue_matin.png`, `cafe_comptoir_matin.png` | Aucun habitant au village ni au café (pas de serveur homme-chat, pas de buveurs) : un village fantôme | 1 | Vie : pas encore d'habitants sur ces cartes | Lot V2 (habitants) ; à revoir après la fusion de V1 | signalé |
| QC-14 | cafe : comptoir, entree, arriere (nuit) | `…-avant/cafe_comptoir_nuit.png` → `…-apres/` | Le soir, une seule flaque de lumière brûlée au milieu du noir | 2 | Plan : une suspension et la lampe du comptoir | Corrigé : applique au mur est (CARTE.md 5.3) ; une seconde suspension, essayée, faisait une silhouette noire devant la table (QC-23) et brûlait le carrelage : retirée | corrigé |
| QC-15 | maison_limashenka : toutes (nuit) | `…-avant/maison_limashenka_salon_nuit.png` → `…-apres/` | La maison est noire la nuit (luminance 0,04) | 1 | Plan : seule la lumière de la fenêtre | Corrigé : lampe à huile sur la table du salon, applique dans l'entrée (CARTE.md 5.3) | corrigé |
| QC-16 | village : cafe, rue, limashenka (nuit) | `…-avant/village_cafe_nuit.png` | Toutes les façades sont éteintes la nuit ; le café, ouvert le soir, a l'air fermé ; sa lanterne n'a ni flamme ni halo | 1 | Images : pas de version de nuit des façades ; vitres peintes bleu-noir ; carte sans lumières (`no_lights`) | Commandé : cahier n° 5, R0.9 (`<façade>_night.png`) ; lanterne : CONTRACT_REQUESTS (C2) | commandé |
| QC-17 | village : chaumieres, lavoir, grange | `…-avant/village_chaumieres_matin.png` | Le toit des chaumières : rayures régulières et mêmes taches vertes répétées, un toit de tôle | 1 | Image : remplaçant de `roof_thatch` (lot R3) | Commandé : R3 (5.3), priorité relevée (R0.10) | commandé |
| QC-18 | village : jardin, lavoir, ruches | `…-avant/village_jardin_matin.png`, `village_lavoir_matin.png` | Meule, charrette à foin, lavoir et ruches en aplats au premier rang | 2 | Images : remplaçants du lot R3 | Commandé : R3, priorités relevées (R0.10) | commandé |
| QC-19 | toutes les cartes | toutes les captures | Le suivi de l'ancienne quête « Dans la forêt céleste — Rejoindre Nygglatho sous le porche » reste affiché partout | 1 | HUD de quête de l'ancienne île | Lot E6 (retrait des quêtes et de leur HUD) | signalé |
| QC-20 | intérieurs : entrepot_rdc, entrepot_etage, cafe, maison_limashenka | `build/qo/avant/entrepot_rdc_bout_ouest_matin.png` → `build/qo/apres20/` ; planche `build/qo/QC-20.png` | Un tiers à la moitié de l'écran est noir : la caméra suit le joueur jusqu'au pignon et montre le vide au-delà | 2 | Bornes de caméra élargies à tout le bâtiment (décision T2) ; bornes plates du café et de la maison ignorées par `Map.bounds()` | Corrigé (QO) : bornes resserrées jusqu'à la dernière cloison de chaque bout (rez-de-chaussée x 6 → 26, étage 5,5 → 26,5, café 5,5 → 8,5, maison 3,5 → 5 : plus serrées, la cloison vue de biais cache le joueur) ; vide noir ramené à environ un quart de la largeur en haut aux bouts, joueur toujours dans le cadre (à moins de 0,55 du centre) ; `Map.bounds()` respecte un rectangle plat | corrigé |
| QC-21 | entrepot_rdc : archives, lecture, jeux, infirmerie, bains ; etage | `…-avant/entrepot_rdc_lecture_nuit.png`, `entrepot_rdc_jeux_nuit.png` | Canapé, classeur, bibliothèque basse, étagère et coffre à jouets, pharmacie : de face, perpendiculaires à leur mur est ou ouest | 1 | Images : pas de vue de flanc | Commandé : R0.3 (déjà au cahier) ; le plan porte `regard=` | commandé |
| QC-22 | entrepot_rdc : refectoire ; cafe | `…-avant/entrepot_rdc_refectoire_matin.png`, `cafe_comptoir_matin.png` | Tables en perspective conique, plateaux en trapèze ; la table des buveurs paraît un banc bas | 2 | Images | Commandé : R0.2 et R3 (tables du café) | commandé |
| QC-23 | entrepot_rdc : refectoire ; cafe | `build/qo/a23/cafe_comptoir_matin.png` → `build/qo/b23/` ; planche `build/qo/QC-23.png` | Les suspensions de cristal sont un fouillis sombre de chaînes à hauteur de tête, sans plafond ni halo | 3 | Panneau `crystal_pendant` posé sans plafond | Corrigé (QO) : la lumière seule (les huit suspensions des plans, réfectoire, couloirs, infirmerie et café, gardent leur `lumiere`, sans image) ; essai d'une suspension remontée et lumineuse : toujours une silhouette noire, non retenu | corrigé |
| QC-24 | entrepot_toit : terrasse | `…-avant/entrepot_toit_bord_sud_matin.png` | Planches de 44 cm de large : trop larges pour un plancher de toit | 3 | Tuile `planks.png` (4 m pour 9 planches) | À revoir après fusion d'I2 (`floor_roof_deck` livré, posé en décalques) | signalé |
| QC-25 | sentier : marais, embuscade | `…-avant/sentier_marais_matin.png` | L'eau basse du marais, sans reflet, se lit comme une pelouse vert sombre | 3 | Tuile `water.png` mate, matière `eau_basse` sans ondulation | Lots E2 et E9 (reflet de l'eau) | signalé |
| QC-26 | entrepot_etage : dortoirs (nuit) | `…-avant/entrepot_etage_dortoir_a_nuit.png` | La nuit, les lits des dortoirs sont vides | 2 | Vie : pas de dormeuses | Lot V1 (vie) ; à revoir après sa fusion | signalé |
| QC-27 | entrepot : cour, champ | `build/qo/avant/entrepot_cour_matin.png` → `build/qo/apres27/` ; planche `build/qo/QC-27.png` | Cour (24 × 14 m) et champ (18 × 20 m) presque nus ; après QC-04 et QC-05, plus nus encore | 3 | Places voulues nues (CARTE.md 2.6) | Corrigé (QO) : bordures habitées par la recette (lessive, bancs, souches, bûches, brouette, caisse, jouets, seau, ballon de rechange), le duel, les buts et les places de la vie restent libres ; rien qui bloque dans les places (CARTE.md 2.6) | corrigé |
| QC-28 | entrepot : cour, champ | `…-avant/entrepot_cour_matin.png` | Les traces de pas commencent et finissent net, en pointillés de 3 m | 3 | Image `footprints.png` | Commandé : R0.11 | commandé |
| QC-29 | entrepot : potager, arbre ; sentier | `…-avant/entrepot_potager_matin.png` | Bordures d'herbe en bandes droites et régulières le long des chemins | 3 | Pose : `grass_edge_*` tous les 3,6 m, alignés | Lot E10 (densité) | signalé |
| QC-30 | entrepot_etage : nygglatho | `…-avant/entrepot_etage_nygglatho_matin.png` | Une fée à moitié dans la cloison nord-sud de la chambre voisine | 2 | Vie : place trop près d'un mur | Lot V1 (vie) | signalé |
| QC-31 | salle_des_armes : crypte | `…-avant/salle_des_armes_crypte_matin.png` | 12 × 8 m de dalles avec deux piliers, deux râteliers et un tréteau | 3 | Voulu par le plan (« le vide et le noir sont le sujet », CARTE.md 3.4) | Aucune ; à revoir après fusion d'I2 (tréteau de polissage) | non retenu |
| QC-32 | village : rue, jardin | `…-avant/village_jardin_matin.png` | Flaques et boue de la rue en taches brunes à bords nets | 3 | Décalques `mud_patch`, `puddle_a` | À revoir avec R0.8 (ornières) | signalé |
