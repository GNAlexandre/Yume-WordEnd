# Contrôle et adaptation des images HD-2D

Le contrat est `docs/ASSETS_HD2D.md`, inventorié dans `tools/hd2d_manifest.json`.
Le choix confirmé est le pixel art à 96 px/m. Les anciennes images anime restent
conservées. Ces outils ne génèrent aucun dessin ni remplaçant procédural.

```sh
python3 tools/hd2d_assets.py check --json build/hd2d-check.json
python3 tools/hd2d_assets.py fit assets/hd2d/props/well.png --source /chemin/brut.png
python3 tools/hd2d_assets.py fit assets/characters/chtholly/chtholly.png \
  --source /chemin/planche.png --frames-json /chemin/planche.json
python3 -m unittest discover -s tests/tools -v
```

`check` est strict : les images requises manquantes font échouer le contrôle.
`check --allow-missing` est un contrôle partiel explicite des images déjà fournies ;
il échoue également si aucune image n'est fournie. Un fichier présent mais non
conforme reste une erreur dans les deux modes. Les FX sont facultatifs.

Le contrôle vérifie PNG RGBA 8 bits, dimensions, poids, alpha, contact du bord bas
des panneaux, bords des façades et égalité des bords opposés des matières qui
doivent se répéter. Il vérifie aussi les JSON de sprites : rectangles, ancres,
hauteur de repos, animations, cadence, boucle, marqueurs de combat, rangées et
espacement transparent. La qualité du dessin, la continuité perceptuelle d'une
tuile et les cycles animés nécessitent toujours une revue visuelle.

`fit` prend une image fournie et conserve byte pour byte la source ainsi que la
cible préexistante sous `assets/source/hd2d_raw/`, ignoré par Godot. Il n'enlève
pas un fond opaque : une image détourée doit déjà posséder une transparence réelle.
La sortie est RGBA8, réduite au plus proche voisin et seuillée en alpha 0/255.
Les textures opaques sont adaptées à leur rectangle ; les panneaux transparents
sont cadrés entiers, centrés et alignés au sol. `--mode stretch` demande
explicitement une adaptation qui peut changer les proportions. Si la source
n'est pas assez grande, `--allow-upscale` permet un agrandissement, consigné dans
le rapport. Il ne crée pas de détail supplémentaire.

Une planche n'a pas de largeur/hauteur fixes dans le cahier : sa taille de repos
est la contrainte. Son JSON doit décrire exactement la source ; `fit` réduit
toute la planche ensemble et transforme rectangles et ancres, sans inventer de
découpage. Les premiers rectangles de repos doivent déjà correspondre aux corps
mesurés ; un rectangle de cellule entier contenant des marges ne fournit pas
une mesure physique fiable. Les marqueurs et cadences sont préservés. Les deux
originaux PNG/JSON sont archivés. `--resample linear` est disponible pour d'autres
usages, en dehors du workflow pixel art confirmé.

Les futurs brouillons directionnels sont produits séparément par
`tools/sukasuka2d/make_resources.py` :

- Combattants : trois PNG `front/back/right`, 6 colonnes, 7 rangées ; Ithea et
  Nephren peuvent ajouter `parle` dans une huitième rangée.
- PNJ : PNG combiné 6×12, quatre rangées par direction (face, dos, côté droit),
  ou trois PNG 6×4. `repos` 2/2 ips, `marche` 6/10 ips, `course` 4/12 ips,
  `parle` 2/6 ips ; gauche = miroir du côté droit.
- Les anciens formats 6×6 PNJ et 6×4 combats sont conservés avec leurs cadences
  historiques. Aucun atlas de brouillon n'est inscrit dans SkinRegistry.

`frames_json_path` ou `frames_json_paths` permet de fournir les découpes et ancres
mesurées. Sinon le générateur utilise des rectangles de grille et des ancres
provisoires au bas des cellules, annoncés comme brouillons.

Le manifeste couvre les chemins explicites du cahier. Les autres personnages
demandés sont inventoriés dans `assets/source/resumed_2d/catalog.json`. Le cahier
renvoie à `HISTOIRE.md` pour les objets et les fées de la communauté : ce document
est absent du checkout ; les icônes connues viennent de `data/items/` et les noms
de communauté ne sont pas inventés.

`src/world/island.tscn` existe dans ce checkout. Il s'agit encore de l'île actuelle,
avec son environnement précédent. Une capture de cette scène ne prouve pas que
tous les nouveaux panneaux et matières du cahier ont été intégrés.
