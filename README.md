# WordEnd 3D (Yume-WordEnd)

Action-aventure 3D de Yume Novel, fait avec Godot 4.7.2 (GDScript typé, rendu Compatibility,
export Web mono-thread) : Chtholly et son épée Seniorious contre Timere, dans un monde chibi
et coloré. L'easter egg 2D du site devient l'île n° 68 de *SukaSuka* : l'entrepôt des fées et
ceux qui y vivent, les bois du marais où le vent a semé des rejetons de Timere, le bord du
Couchant où l'on tient la veille contre leurs vagues, le port et la colline des étoiles. Le joueur
incarne la fée qui porte Seniorious (Chtholly, ou une fée de la communauté qui prend sa place) ;
l'acte 1 (jalon M2) suit le volume 1 de la traduction de Yume Novel et se joue du menu à la
promesse, au clavier, à la souris, à la manette et au toucher, dans l'éditeur comme dans le
navigateur.

## Jouer

- **Dans l'éditeur** : ouvrir le projet avec Godot 4.7.2, F5 lance `src/main.tscn` (menu, puis la
  partie). `tests/integration/demo_m2.tscn` (F6) part directement du village, la quête prête ;
  `demo_m1.tscn`, de l'arène des dunes.
- **Commandes** : ZQSD / WASD ou flèches pour marcher, Maj pour courir, Espace pour sauter, E pour
  parler et ramasser, J / X pour l'épée (trois coups enchaînés), K / C maintenu pour la charge
  magique, clic molette pour verrouiller une cible, I pour le sac, Échap pour la pause, F3 pour
  les performances. Manette : stick gauche, L3 (course), A (saut, parler), X (épée), B maintenu
  (charge), Y (sac), R3 (cible), Start (pause) ; stick droit pour la caméra.
- **Dans le navigateur** : `tools/godot --headless --export-release Web build/web/index.html`,
  puis `python3 -m http.server 8000 --directory build/web` et http://localhost:8000/ (WebGL 2
  requis). Publication sur GitHub Pages et intégration à yumenovel.fr : [docs/web.md](docs/web.md).

## Développer et vérifier

- Environnement : `bash tools/setup.sh` (Godot, templates Web, gdtoolkit, Pillow).
- Vérification complète (« vert ») : `tools/check.sh` (import, lint, tests GUT, fumée, export
  Web, capture) ; tests ciblés : `tools/test.sh tests/integration/test_m2_quest.gd`.
- Captures : `tools/screenshot.sh res://src/world/island.tscn build/shots/island.png` ; vues de la
  tranche verticale : `M2_SHOT=village tools/screenshot.sh res://tests/integration/demo_m2.tscn
  build/shots/m2_village_hud.png 150`.
- Navigateur sans écran (Playwright) : `node tools/web_m2.js` (mode d'emploi en tête du fichier).

## Documents

- [PLAN.md](PLAN.md) : le plan complet, ses contrats d'interface (section 3) et les critères
  d'acceptation de la tranche verticale (section 4).
- [CLAUDE.md](CLAUDE.md) : règles et pièges pour les sessions Claude Code qui développent le jeu.
- [docs/web.md](docs/web.md) : export Web, site, raccourcis de test du navigateur.
- [docs/REGLAGES_COMBAT.md](docs/REGLAGES_COMBAT.md) : tous les chiffres de la sensation de combat.
- [docs/RECETTE_M2.md](docs/RECETTE_M2.md) : recette des critères d'acceptation du jalon M2.
- [docs/ASSETS_3D.md](docs/ASSETS_3D.md) : cahier des charges des assets 3D (personnages,
  corps de Timere, décors, île) à donner à qui les produit (IA ou artiste).
- [docs/QUETES.md](docs/QUETES.md) : écrire des quêtes, des dialogues (plusieurs voix,
  `{player}`), la présence des PNJ et les textes de l'histoire.
- [docs/lore/](docs/lore/PLAN.md) : la direction narrative ([MONDE.md](docs/lore/MONDE.md),
  [HISTOIRE.md](docs/lore/HISTOIRE.md)), la bible du canon et les fiches de lecture, faites à
  partir de la traduction de Yume Novel.
- [docs/DECISIONS.md](docs/DECISIONS.md) et [docs/CONTRACT_REQUESTS.md](docs/CONTRACT_REQUESTS.md) :
  choix faits par lot et demandes de contrat.

Code sous licence MIT proposée ; crédits des dessins et des assets dans
[assets/CREDITS.md](assets/CREDITS.md) et [assets/characters/CREDITS.md](assets/characters/CREDITS.md).
Chtholly, Seniorious, Timere et l'entrepôt des fées viennent de *Que faites-vous à la fin du
monde ? Êtes-vous occupés ? Voulez-vous bien nous sauver ?* (*SukaSuka*), le roman d'Akira Kareno,
lu dans la traduction française de Yume Novel : hommage non commercial (PLAN.md, section 5).
