# Plan narratif — un WordEnd fidèle à SukaSuka

Objectif : que le jeu communautaire colle à l'œuvre (*Que faites-vous à la fin du monde ? Êtes-vous
occupés ? Voulez-vous bien nous sauver ?*, Akira Kareno) : lieux, personnages, créatures, ton et
chronologie cohérents avec les volumes 1 à 5 et EX traduits par Yume Novel, plus du contenu
original qui s'y insère sans contredire le canon.

## Règles

- **Le canon fait foi** : un fait du jeu qui touche à l'œuvre doit pouvoir citer sa source
  (volume, chapitre). Le contenu original est marqué comme tel dans les documents et ne contredit
  aucun fait établi.
- **Droits** : le dépôt est public. Les traductions ne sont jamais copiées dans le dépôt ; les notes
  de lecture résument et paraphrasent (citations brèves et rares). Les dialogues du jeu sont écrits
  pour le jeu.
- **Spoilers** : la progression du jeu suit l'ordre de lecture ; ce qui révèle la fin des volumes
  est réservé aux étapes tardives et signalé.

## Phases

| Phase | Agents en parallèle | Livrables |
| --- | --- | --- |
| **A. Lecture** | 6 lecteurs, un par volume (1, 2, 3, 4, 5, EX) | `docs/lore/volumes/vol<N>.md` : résumé, lieux, personnages, créatures, système du monde, objets, ton, chronologie, matière à jeu, illustrations de référence |
| **A'. Moteur de quêtes** (en même temps que A) | 1 agent Godot | quêtes en plusieurs étapes (parler, aller, vaincre, rapporter, arène, drapeau), déclencheurs de lieu, journal de quêtes, objectif courant dans le HUD, sauvegarde migrée, format d'écriture documenté (`docs/QUETES.md`) |
| **B. Conception** | 2 agents : bible canon ; direction narrative | `docs/lore/BIBLE.md` (canon fusionné, glossaire, chronologie) ; `docs/lore/MONDE.md` (cadre, carte et lieux pour ChatGPT) et `docs/lore/HISTOIRE.md` (arc principal, quêtes, PNJ, guide de ton) |
| **C. Production** | 3 à 4 agents Godot | quête principale ; quêtes secondaires et PNJ ; lieux, objets, textes et codex dans le jeu ; spécification de carte pour ChatGPT |
| **D. Intégration** | 1 agent | parcours complet testé, `tools/check.sh` vert, captures |

L'orchestrateur fusionne et vérifie entre chaque phase.
