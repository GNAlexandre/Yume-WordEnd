# Recette du jalon M2 — tranche verticale

Chaque critère d'acceptation de PLAN.md (section 4, « Critères d'acceptation de la tranche
verticale ») avec son statut au 6 octobre 2026 (intégration M2). Trois statuts, sans complaisance :

- **Vérifié automatiquement** : un test GUT de `tools/check.sh` ou une mesure reproductible le
  prouve ; le test ou la commande est cité.
- **Vérifié en partie** : prouvé sur ce qu'une machine sans écran ni GPU peut voir ; le reste est
  dit.
- **À valider par un humain** : ce qui ne se mesure pas ici (fluidité, sensation, vrai réseau,
  vraie manette) ; quoi regarder et comment.

Rien ici n'a été joué par un humain : la porte du jalon (PLAN.md section 8 : « critères cochés ;
test par 3 membres de la communauté ») reste à franchir par le propriétaire.

Les tests d'intégration M2 jouent la vraie partie (`src/main.tscn` : « Cliquer pour jouer »,
menu, chargement, jeu) avec des événements d'entrée réels (`InputEventKey`,
`InputEventJoypadButton`, `InputEventJoypadMotion`, clics), sur une sauvegarde de test :
`tests/integration/test_m2_{menu,quest,arena,resume,world}.gd` (base
`tests/stubs/m2_game_test.gd`). Captures : `build/shots/` (rendues par
`tools/screenshot.sh` sous Xvfb, rendu logiciel), à régénérer par les commandes données.

## Tableau de bord

| # | Critère (PLAN.md section 4) | Statut |
| --- | --- | --- |
| 1 | Build Web chargé en moins de 10 s sur fibre, sans erreur console | Vérifié en partie |
| 2 | Combat : coup sur les images `coup`, onde qui traverse, Grand qui ne recule que sous l'onde, pas deux dégâts en moins de 1,2 s | Vérifié automatiquement (la sensation : humain) |
| 3 | Arène : vague 5 atteignable, Grand dès la vague 3 jamais deux, score et bonus de l'easter egg | Vérifié en partie (« joueur moyen » : humain) |
| 4 | Mort dans l'arène ou la forêt : village, PV pleins, inventaire et quêtes gardés, meilleur score gardé | Vérifié automatiquement |
| 5 | 60 images/s sur un portable (12 Timeres), 30 sur un téléphone récent | À valider par un humain |
| 6 | Quête des pages de bout en bout au clavier et à la manette | Vérifié automatiquement (vraie manette : humain) |
| 7 | Fermer l'onglet puis revenir restaure position, inventaire, quête, meilleur score | Vérifié automatiquement (navigateur réel : humain) |
| 8 | Les 5 zones affichent leur nom ; aucun ennemi au village ; pas de chute hors de l'île | Vérifié automatiquement |
| 9 | Tests GUT verts sur Health, AttackData/hitbox, WaveDirector, GameState, SaveManager, DialogueRunner, QuestTracker | Vérifié automatiquement |

## 1. Chargement du build Web — vérifié en partie

- **Prouvé** : `tools/check.sh` exporte le build sans erreur ni avertissement ; taille mesurée par
  `tools/build_size.sh` : **10,6 Mo compressés** (wasm 9,7 Mo, pck 0,9 Mo) pour un budget de
  25 Mo. `tools/web_m2.js` (Chromium sans écran de Playwright, build servi en local, rendu
  logiciel SwiftShader) : menu affiché **1,9 à 2,2 s** après le début de la page (repère
  `window.wordendMenuMs`), 1,6 à 3,6 s au rechargement ; partie chargée 3 à 7,6 s après
  « Nouvelle partie », la page continuant d'afficher des images pendant le chargement (12 en
  6,6 s, compteur `requestAnimationFrame` : elle ne se fige pas) ; **aucune erreur dans la
  console** (seuls avertissements : « GPU stall due to ReadPixels » du pilote logiciel de
  Chromium). Icône et écran de démarrage du jeu (plus de logo Godot). Captures
  `m2_web_menu.png`, `m2_web_village.png`, `m2_web_dialogue.png`.
- **Pas prouvé** : le réseau. La page était servie en local (aucun temps de téléchargement) ; sur
  fibre (100 Mb/s), les 10,6 Mo ajoutent environ 1 s, plus la compilation du wasm.
- **À valider** : ouvrir https://jeu.yumenovel.fr/ (ou la page GitHub Pages) dans Chrome et
  Firefox, outils de développement ouverts, cache vidé : chronométrer jusqu'au « Cliquer pour
  jouer » (objectif < 10 s), vérifier la console (rouge interdit). La CI GitHub et le
  déploiement Pages n'ont encore jamais tourné (voir « Points connus »).

## 2. Combat — vérifié automatiquement ; sensation à juger

- Coup d'épée seulement sur les images `coup` : `tests/unit/test_combat_sword.gd`
  (`test_damage_only_on_coup_frames`, `test_split_coup_frames_keep_one_activation`) ; dans le
  vrai jeu, image « coup » relevée au moment du dégât : `tests/integration/test_m1_arena.gd`
  (`test_sword_kill_in_the_arena_scores`), `test_m1_combat.gd`.
- L'onde traverse plusieurs Timeres : `test_combat_charge.gd`
  (`test_wave_pierces_three_aligned_dummies`), `test_m1_combat.gd`
  (`test_charge_wave_pierces_aligned_timeres`, vrais Timeres).
- Le Grand ne recule que sous l'onde : `test_enemy.gd` (`test_big_recoils_only_under_the_wave`).
- Jamais deux dégâts en moins de 1,2 s : `test_health.gd`
  (`test_invincibility_refuses_second_hit`), `test_combat_player.gd`
  (`test_player_refuses_two_hits_within_1_2_s`), `test_m1_arena.gd` (mort sous quatre Timeres :
  cinq morsures espacées d'au moins 72 images physiques).
- **À valider** : la sensation (recul, enchaînement, onde, caméra verrouillée), manette et
  clavier en main, avec `tests/integration/demo_m1.tscn` ; tous les chiffres et les points à
  juger sont dans [REGLAGES_COMBAT.md](REGLAGES_COMBAT.md).

## 3. Arène — vérifié en partie

- Vague *n* = 3 + 2*n*, bonus 50 × *n*, soin toutes les deux vagues, Coureur dès la vague 2,
  Grand dès la vague 3 : `tests/unit/test_wave_director.gd` (`test_compose_counts_three_plus_two_n`,
  `test_generator_holds_back_runner_and_big`, `test_series_scores_points_bonus_and_heals`,
  `test_big_never_has_a_living_twin`) ; points 10/15/20/40 : `test_enemy.gd`
  (`test_data_matches_the_plan_table`).
- Dans le vrai jeu, vagues 1 à 6 jouées (joueur endurci, délais raccourcis) : un Grand dès la
  vague 3, jamais deux vivants : `test_m1_arena.gd` (`test_big_from_wave_three_never_two_at_once`).
  Score, record et écran de fin : `test_m2_arena.gd` ; capture `m2_arena_end.png`.
- **À valider** : « la vague 5 est atteignable par un joueur moyen » ne se teste pas sans
  joueur : faire jouer trois membres (porte du jalon M2), noter la vague atteinte.

## 4. Mort et réapparition — vérifié automatiquement

- Arène : `tests/integration/test_m2_arena.gd`
  (`test_death_in_the_arena_then_end_screen_at_the_village`) : mordu à mort pendant une série,
  l'écran de fin attend la réapparition sans figer le jeu, Chtholly revient au Spawn du village
  avec ses PV pleins, l'écran montre score, vague et « Nouveau record ! », Entrée continue ;
  inventaire (pages), quête en cours et meilleur score gardés, cinq cœurs pleins dans le HUD.
- Forêt : `test_m1_forest.gd` (`test_death_in_the_forest_respawns_at_the_village_without_arena`).
- Record écrit dans la sauvegarde : `test_m1_arena.gd`
  (`test_death_in_the_arena_records_the_score_and_respawns_at_the_village`).

## 5. Images par seconde — à valider par un humain

- **Rien de mesurable ici** : la VM n'a pas de GPU (Mesa llvmpipe et SwiftShader : 1 à
  6 images/s, sans valeur). Seuls indicateurs, les budgets de PLAN.md section 9, mesurés par
  `demo_m1` (`M1_SHOT=<vue> tools/screenshot.sh res://tests/integration/demo_m1.tscn
  build/shots/m2_after_<vue>.png 300`) : vue du village 79 draw calls et 104 700 primitives ; le
  village vu des quatre zones voisines (pire cas) 75 à 87 draw calls, 132 600 à 142 800
  primitives (151 000 à 155 000 avant l'intégration M2) ; 16 Timeres dans l'arène 92 draw calls,
  89 300 primitives. Budgets M2 : < 150 draw calls, < 150 000 primitives.
- **À valider** : sur un portable de bureau courant puis un téléphone récent, ouvrir le build
  avec `?zone=dunes&timeres=12` (douze Timeres devant le joueur), appuyer sur F3 (images/s,
  draw calls, primitives) ; objectifs 60 et 30 images/s. Regarder aussi la vue du village depuis
  l'entrée des dunes (le pire cas de triangles).

## 6. Quête des pages au clavier et à la manette — vérifié automatiquement

- `tests/integration/test_m2_quest.gd`, deux fois le même parcours, dans le vrai jeu, par des
  appuis réels : `test_pages_quest_with_keyboard_and_mouse` (menu à la souris, Z/Q/S/D, E,
  flèches, Espace, J, I, Échap) et `test_pages_quest_with_a_gamepad_only` (A pour le geste et
  « Nouvelle partie », stick, A, croix, X, Y, B). Bibliothécaire : on accepte ; objectif et
  progression dans le HUD ; la forêt à pied par la porte nord (« Forêt des Timeres » affiché) ;
  ses quatre Timeres tués à l'épée lâchent quatre pages, les trois pages uniques sont ramassées
  en marchant dessus ; retour au village ; la bibliothécaire termine la quête : cinq pages
  retirées, marque-page dans l'inventaire, 6 PV max, six cœurs dans le HUD ; elle remercie
  ensuite ; l'inventaire s'ouvre et se ferme. L'appui qui ferme une conversation (Espace, E, A)
  ne fait ni sauter ni repartir la conversation.
- Limite assumée : les Timeres de la forêt sont immobilisés pendant ce test (cibles de l'épée) ;
  leur combat est prouvé à part (`test_m1_forest.gd`). Menu à la manette seule :
  `test_m2_menu.gd` ; pause à la manette : `test_m2_world.gd`.
- Captures : `m2_dialogue.png` (la bibliothécaire et ses deux choix), `m2_forest.png` (la
  clairière, ses Timeres et ses pages, « Forêt des Timeres »), `m2_reward.png` (marque-page dans
  l'inventaire, six cœurs).
- **À valider** : jouer la quête avec une vraie manette (Xbox ou PlayStation, dans Chrome et
  Firefox : l'ordre des boutons vient du navigateur), et au toucher sur un téléphone.

## 7. Reprise après fermeture de l'onglet — vérifié automatiquement ; navigateur réel à valider

- `tests/integration/test_m2_resume.gd` (`test_walking_is_saved_and_continue_restores_everything`) :
  une partie avance (quête acceptée, page ramassée, record), le joueur se promène : sa position
  est écrite toutes les 5 s de jeu s'il a bougé, rien s'il reste immobile, et tout de suite quand
  la fenêtre perd le focus ; « fermeture de l'onglet » simulée (partie libérée, GameState à
  zéro), nouveau menu, « Continuer » : position, zone, skin, inventaire, quête, page déjà prise
  absente, meilleur score et objectif du HUD restaurés. `test_show_menu_closes_the_tracked_game`
  et `test_m2_world.gd` (`test_return_to_menu_from_pause`) : retour au menu, partie écrite, plus
  aucune auto-sauvegarde.
- Dans un vrai navigateur (Chromium sans écran, `tools/web_m2.js`) : nouvelle partie, quête
  acceptée, quelques pas, perte du focus, page rechargée (même IndexedDB), « Continuer » :
  même position (écart 0,00 m), zone « village », quête en cours.
- **Limite connue** : sur le Web, une écriture n'est conservée qu'une fois copiée dans IndexedDB
  (Godot la lance à l'image suivante) ; un onglet fermé dans la fraction de seconde qui suit
  peut la perdre : on perd alors au plus les 5 dernières secondes de marche.
- **À valider** : dans Chrome et Firefox (et Safari sur iPhone), se promener, attendre quelques
  secondes, fermer l'onglet, rouvrir le jeu : Continuer doit reprendre au même endroit, avec la
  quête et les objets. En navigation privée, le menu prévient que rien n'est conservé.

## 8. Zones, barrière, bords de l'île — vérifié automatiquement

- Les cinq zones affichent leur nom dans le HUD, une seule fois, même en longeant une frontière
  (allers-retours sur la frontière nord du village : une annonce, une auto-sauvegarde au plus) :
  `test_m2_world.gd` (`test_each_zone_shows_its_name_once_even_along_a_border`) ;
  `test_world_island.gd` (`test_every_zone_emits_zone_entered`). Capture `m2_village_hud.png`.
- Aucun ennemi n'entre au village : `test_m2_world.gd` (`test_no_timere_enters_the_village` :
  Grand et Petit au pied de la barrière, joueur juste derrière) ; `test_m1_forest.gd` (poursuite
  abandonnée, Grand repoussé contre la barrière) ; `test_enemy.gd`
  (`test_gives_up_at_the_real_village_border`).
- Aucune chute hors de l'île : `test_m2_world.gd` (`test_nothing_lets_the_player_fall_off_the_island` :
  KillZone sous la plage → Spawn de la plage ; mur du bord dans l'eau peu profonde) ;
  `test_world_island.gd` (sol partout dans les murs, murs fermés, KillZone, filet sous −30 m) ;
  `test_m1_world.gd` (tout objet, PNJ et Timere est au sol et atteignable à pied).

## 9. Tests GUT — vérifié automatiquement

`tools/check.sh` : **504 tests verts** (61 scripts, 6 799 assertions), dont Health
(`test_health.gd`), AttackData et hitbox (`test_combat_hitbox.gd`, `test_combat_sword.gd`,
`test_combat_charge.gd`), WaveDirector (`test_wave_director.gd`, `test_arena.gd`), GameState
(`test_game_state.gd`), SaveManager (`test_save_autosave.gd`, `test_save_file.gd`,
`test_save_migration.gd`, `test_save_roundtrip_l0.gd`), DialogueRunner (`test_dialogue_runner.gd`,
`test_dialogue_data.gd`, `test_dialogue_flow.gd`) et QuestTracker (`test_quest_tracker.gd`,
`test_quest_in_game.gd`), plus les 15 tests d'intégration M2.

## Points connus (documentés, non corrigés)

- **Sprites non éclairés par le couchant** (L3) : les planches sont non éclairées (alpha
  scissor, pas d'ombre propre) ; Chtholly et les Timeres gardent leurs couleurs au soleil comme à
  l'ombre. À juger sur les captures (`m2_village_hud.png`).
- **Caméra verrouillée** (M1) : une cible collée derrière Chtholly peut être cachée par elle (la
  caméra est dans l'axe joueur → cible) ; la caméra traverse le feuillage (seuls les troncs
  arrêtent le bras du ressort). Réglages possibles dans REGLAGES_COMBAT.md.
- **Verrouillage sans ligne de vue** (L1) : la cible la plus proche est verrouillée même derrière
  un mur ou un tronc.
- **Pas d'interpolation physique** (L1) : le joueur bouge à 60 Hz ; sur un écran à 120 ou
  144 Hz, des saccades sont possibles.
- **Invite « E / A » fixe** (L10) : la même invite au clavier, à la manette et au toucher.
- **CI GitHub et GitHub Pages jamais exécutées** (L9) : le workflow existe mais n'a jamais tourné
  sur GitHub ; à lancer une première fois (docs/web.md, « Déployer sur GitHub Pages »).
- **Cœur du marque-page** (L4) : les PV max passent à 6 mais le cœur gagné est vide jusqu'au
  prochain soin ou à la réapparition (« le maximum n'est pas un soin ») ; visible sur
  `m2_reward.png`. À trancher.
- **Zone courante après un effleurement** (L2) : après avoir effleuré la zone voisine sans y
  entrer, la zone courante reste la voisine jusqu'à l'entrée dans une autre (le nom n'est plus
  répété, intégration M2).

## Ce qui reste à valider par un humain

1. Charger le build publié (Pages ou jeu.yumenovel.fr) : temps jusqu'au menu, console (critère 1).
2. Jouer le combat et l'arène manette et clavier en main ; noter la vague atteinte par trois
   membres (critères 2 et 3, porte de M2).
3. Mesurer les images/s avec F3 sur un portable et un téléphone, `?zone=dunes&timeres=12`
   (critère 5).
4. Jouer la quête avec une vraie manette et au toucher (critère 6).
5. Fermer l'onglet en pleine promenade dans trois navigateurs, revenir, Continuer (critère 7).
6. Regarder les captures `build/shots/m2_*.png` et juger les points connus ci-dessus.

## Ce qui reste pour M3

Cycle jour/nuit (`day_phase_changed`), streaming des zones, donjon, musique et sons (licence de
*Scarborough Fair*), contrôles tactiles complets, éclairage des sprites, caméra qui évite le
feuillage et décale la cible verrouillée, interpolation physique, invite selon l'appareil,
découpe des lots de décor par cellules si les triangles redeviennent un problème.

## Refaire les captures

```bash
for v in menu dialogue forest reward arena_end; do
  M2_SHOT=$v tools/screenshot.sh res://tests/integration/demo_m2.tscn build/shots/m2_$v.png 150
done
M2_SHOT=village tools/screenshot.sh res://tests/integration/demo_m2.tscn build/shots/m2_village_hud.png 150
M1_SHOT=village_dunes tools/screenshot.sh res://tests/integration/demo_m1.tscn build/shots/m2_after_village_dunes.png 300
node tools/web_m2.js http://127.0.0.1:8347/index.html build/shots   # voir docs/web.md
```
