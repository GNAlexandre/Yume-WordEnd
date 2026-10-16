# WordEnd (Yume-WordEnd)

Action-aventure en HD-2D de Yume Novel, fait avec Godot 4.7.2 (GDScript typé, rendu Compatibility,
export Web mono-thread) : Chtholly et son épée Seniorious contre Timere, à la manière d'*Octopath
Traveler* : des personnages en sprites de pixel art (les planches de l'easter egg) dans un petit
monde en relief construit uniquement avec des images (sol en tuiles, façades, décors en panneaux,
ciel peint), vu par une caméra fixe inclinée, avec flou de profondeur, lueur et lumière chaude du
couchant. L'easter egg 2D du site devient l'île n° 68 de
*SukaSuka* : l'entrepôt des fées et ceux qui y vivent, le village, la ville et le port, les bois et
la colline. Le joueur incarne la fée qui porte Seniorious (Chtholly, ou une fée de la
communauté qui prend sa place) ; l'acte 1 (jalon M2) suit le volume 1 de la traduction de Yume Novel
et se joue du menu à la promesse, au clavier, à la souris, à la manette et au toucher, dans
l'éditeur comme dans le navigateur.

## Jouer

- **Sur Windows** (10 ou 11, 64 bits) : télécharger `WordEnd-Setup-X.Y.Z.exe` sur la page des
  [Releases](https://github.com/GNAlexandre/Yume-WordEnd/releases/latest) et le lancer
  (installation pour toi seul, sans droits d'administrateur ; raccourcis dans le menu Démarrer et
  sur le Bureau), ou le zip portable (`WordEnd.exe` seul). Le jeu n'est pas signé : si Windows
  affiche « Windows a protégé votre ordinateur », cliquer sur « Informations complémentaires »
  puis « Exécuter quand même ». Plein écran : F11 ou Alt+Entrée ; sauvegardes dans
  `%APPDATA%\WordEnd`. Détails, mise à jour et désinstallation : [docs/bureau.md](docs/bureau.md).
- **En ligne** : https://jeu.yumenovel.fr/ (navigateur avec WebGL 2), sans rien installer.
- **L'acte 1** se joue en jours et en scènes, à l'entrepôt des fées de l'île n° 68
  (`data/scenes/ile_68/`) ; le calendrier (Tab) garde une ligne par jour. (F1) L'ancienne île et
  ses quêtes sont retirées : une sauvegarde d'avant la refonte reprend au premier jour.
- **Dans l'éditeur** : ouvrir le projet avec Godot 4.7.2, F5 lance `src/main.tscn` (menu, puis la
  partie). `tests/integration/demo_hd2d.tscn` (F6, vue choisie par `HD2D_VIEW`) montre la vraie
  partie sur les cartes de l'île n° 68, en conversation ou pendant un combat à la surface.
- **Commandes** : ZQSD / WASD ou flèches pour marcher, Maj pour courir, Espace pour sauter, E pour
  parler et ramasser, J / X pour l'épée (trois coups enchaînés), K / C maintenu pour la charge
  magique, clic molette pour verrouiller une cible, I pour le sac, Tab ou L pour le calendrier, Échap pour la pause, F3 pour les performances, molette pour un léger zoom. Le haut de
  l'écran est le nord : la caméra fixe ne tourne pas. Manette : stick gauche, L3 (course), A
  (saut, parler), X (épée), B maintenu (charge), Y (sac), Select (calendrier), R3 (cible), Start
  (pause) ; stick droit (haut, bas) pour le zoom.
- **Dans le navigateur** : `tools/godot --headless --export-release Web build/web/index.html`,
  puis `python3 -m http.server 8000 --directory build/web` et http://localhost:8000/ (WebGL 2
  requis). Publication sur GitHub Pages et intégration à yumenovel.fr : [docs/web.md](docs/web.md).

## Développer et vérifier

- Environnement : `bash tools/setup.sh` (Godot, templates Web, Windows et Linux, gdtoolkit,
  Pillow, NSIS).
- Vérification complète (« vert ») : `tools/check.sh` (import, lint, tests GUT, fumée, export
  Web, capture) ; tests ciblés : `tools/test.sh tests/integration/test_e6_day1.gd`.
- Captures : `tools/hd2d_shots.sh` (menu, cartes de l'île n° 68, conversation, combat :
  `build/shots/hd2d_<vue>.png`, draw calls dans le journal) ; une scène :
  `tools/screenshot.sh res://src/world/maps/essai/essai.tscn build/shots/essai.png`.
- Images du décor : `python3 tools/hd2d_assets.py gen | check | fit | atlas` (remplaçants en
  pixel art, vérification des images livrées ; liste dans `tools/hd2d_manifest.json`).
- Application Windows : `tools/build_desktop.sh` (installateur et zip dans `build/dist`) ;
  `--linux` vérifie en plus que le même jeu démarre (build Linux sans écran). Une Release GitHub
  avec l'installateur se publie en créant un tag `vX.Y.Z` sur GitHub ([docs/bureau.md](docs/bureau.md)).
- Navigateur sans écran (Playwright) : `node tools/web_maps.js` (changements de carte),
  `tools/web_life.js`, `tools/web_atmosphere.js` (mode d'emploi en tête des fichiers et dans
  docs/web.md).

## Documents

- [PLAN.md](PLAN.md) : le plan complet, ses contrats d'interface (section 3) et les critères
  d'acceptation de la tranche verticale (section 4).
- [CLAUDE.md](CLAUDE.md) : règles et pièges pour les sessions Claude Code qui développent le jeu.
- [docs/web.md](docs/web.md) : export Web, site, raccourcis de test du navigateur.
- [docs/bureau.md](docs/bureau.md) : application Windows, installateur, publier une version,
  SmartScreen, sauvegardes.
- [docs/REGLAGES_COMBAT.md](docs/REGLAGES_COMBAT.md) : tous les chiffres de la sensation de combat.
- [docs/RECETTE_M2.md](docs/RECETTE_M2.md) : recette de l'acte 1 (jalon M2) : critères, comment
  les vérifier, résultats.
- [docs/ASSETS_HD2D.md](docs/ASSETS_HD2D.md) : cahier des charges des images HD-2D
  (personnages, sol, falaises, façades, décors, ciel), une consigne prête à copier par image,
  à donner à ChatGPT ou à un artiste.
- [docs/DIALOGUES.md](docs/DIALOGUES.md) : écrire des dialogues (conditions, effets, plusieurs
  voix, `{player}`), la présence des PNJ et les textes de l'histoire.
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
