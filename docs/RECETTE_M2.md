# Recette de l'acte 1 — jalon M2

L'acte 1, « Dans la forêt céleste » (docs/lore/HISTOIRE.md, sections 2 et 3), remplace la tranche
verticale du jalon M2 sur l'île n° 68 (docs/lore/MONDE.md, section 2). Cette recette reprend les
critères d'acceptation de PLAN.md (section 4) pour l'acte 1, ajoute ceux de l'histoire, et dit
pour chacun **comment le vérifier** et **le résultat** au 7 octobre 2026 (intégration narrative,
phase D). Trois statuts, sans complaisance :

- **Vérifié automatiquement** : un test GUT de `tools/check.sh` ou une mesure reproductible le
  prouve ; le test ou la commande est cité.
- **Vérifié en partie** : prouvé sur ce qu'une machine sans écran ni GPU peut voir ; le reste est
  dit.
- **À valider par un humain** : ce qui ne se mesure pas ici (fluidité, sensation, vrai réseau,
  vraie manette, direction artistique) ; quoi regarder et comment.

Rien ici n'a été joué par un humain : la porte du jalon (PLAN.md section 8 : « critères cochés ;
test par 3 membres de la communauté ») reste à franchir par le propriétaire.

Les tests d'intégration jouent la vraie partie (`src/main.tscn` : « Cliquer pour jouer », menu,
chargement, jeu) avec des événements d'entrée réels (`InputEventKey`, `InputEventJoypadButton`,
`InputEventJoypadMotion`, clics), sur une sauvegarde de test (base `tests/stubs/m2_game_test.gd`).
Captures : `build/shots/acte1_*.png`, rendues sous Xvfb (rendu logiciel) par les commandes de la
fin du document.

## Tableau de bord

| # | Critère | Comment le vérifier | Statut |
| --- | --- | --- | --- |
| 1 | Build Web chargé en moins de 10 s sur fibre, sans erreur console ; 25 Mo compressés au plus | `tools/build_size.sh` ; `tools/web_m2.js` (Chromium sans écran) | Vérifié en partie |
| 2 | Combat : coup sur les images `coup`, onde qui traverse, grand fragment qui ne recule que sous l'onde, pas deux dégâts en moins de 1,2 s | tests du combat | Vérifié automatiquement (sensation : humain) |
| 3 | La veille du Couchant : vague 5 atteignable, grand fragment dès la vague 3 jamais deux, score et bonus de l'easter egg ; fin de la veille au nom de la zone | tests de l'arène ; capture `acte1_fin_veille.png` | Vérifié en partie (« joueur moyen » : humain) |
| 4 | Défaite : retour à l'entrepôt, PV pleins, inventaire, quêtes et record gardés | tests de mort et de réapparition | Vérifié automatiquement |
| 5 | 60 images/s sur un portable (12 Timeres), 30 sur un téléphone récent | F3 ou `?trace=1` sur un vrai appareil | À valider par un humain (mesures logicielles ci-dessous) |
| 6 | La quête principale `act1_main` (13 étapes) de bout en bout, au clavier et à la manette | `test_m2_quest.gd` ; `tools/web_m2.js` (début, dans le navigateur) | Vérifié automatiquement (vraie manette : humain) |
| 7 | Fermer l'onglet puis revenir restaure position, inventaire, quête et étape, record | `test_m2_resume.gd` ; `tools/web_m2.js` | Vérifié automatiquement (navigateurs réels : humain) |
| 8 | Les 5 zones affichent leur nom (MONDE.md 2.1) ; aucun Timere à l'entrepôt ; pas de chute hors de l'île | `test_m2_world.gd`, `test_world_island.gd`, `test_sys_story.gd` | Vérifié automatiquement |
| 9 | Tests GUT verts (Health, AttackData/hitbox, WaveDirector, GameState, SaveManager, DialogueRunner, QuestTracker…) | `tools/check.sh` | Vérifié automatiquement |
| 10 | Les PNJ sont là selon l'histoire ; aucune étape « parler » ne devient impossible | `test_act1_presence.gd`, `test_npc_presence.gd` | Vérifié automatiquement |
| 11 | Les six quêtes secondaires se jouent dans la vraie partie, avec les objets de l'île | `test_act1_side_quests.gd`, `test_act1_items_in_world.gd`, `test_act1_*.gd` | Vérifié automatiquement |
| 12 | Les rejetons des bois ne bloquent jamais l'étape qui les vise | `test_free_enemies.gd` | Vérifié automatiquement |
| 13 | Les sauvegardes du jalon M2 se chargent dans l'acte 1, sans quête fantôme | `test_act1_saves.gd`, `test_save_migration.gd` | Vérifié automatiquement |
| 14 | Les textes : prénom de la protagoniste (`{player}`), voix des personnages, textes de l'histoire (cloche, fin de veille, chute, défaite), typographie | `test_player_name.gd`, `test_act1_dialogues.gd`, `test_story_texts.gd`, `test_sys_story_content.gd`, `test_quest_content.gd` | Vérifié automatiquement (ton : humain) |
| 15 | Les places de HISTOIRE.md 3.3 sur l'île n° 68 : au sol, hors du décor, atteignables à pied | `test_world_story_spots.gd`, `test_npc.gd`, `test_m1_world.gd` | Vérifié automatiquement |
| 16 | Plus de reste du jalon M2 (ses trois PNJ, ses objets retirés, l'ancienne graphie de l'épée) hors des traces historiques | `git grep` (section 16) | Vérifié automatiquement |
| 17 | Direction artistique au minimum proche de *Breath of the Wild* | captures `acte1_*.png` | À valider par un humain (écarts relevés plus bas) |

## 1. Build Web — vérifié en partie

- **Taille** : `tools/build_size.sh` après `tools/godot --headless --export-release Web
  build/web/index.html` : **18,4 Mo compressés** (wasm 9,7 Mo, pck 8,8 Mo ; 47,3 Mo bruts) pour un
  budget de 25 Mo. Le pck a grossi avec l'île n° 68 et les 45 modèles 3D de la PR n° 1 (en
  attente de refonte).
- **Navigateur** : `tools/web_m2.js acte1` (Chromium 141 sans écran, build servi en local, rendu
  logiciel SwiftShader) : RESULTATS_NAVIGATEUR
- **Pas prouvé** : le réseau (page servie en local) ; sur fibre, les 18,4 Mo ajoutent 1 à 2 s.
- **À valider** : ouvrir le build publié dans Chrome et Firefox, outils de développement ouverts,
  cache vidé : chronométrer jusqu'au « Cliquer pour jouer » (objectif < 10 s), console sans
  rouge.

## 2. Combat — vérifié automatiquement ; sensation à juger

Inchangé depuis le jalon M2 : `test_combat_sword.gd` (`test_damage_only_on_coup_frames`),
`test_combat_charge.gd` (`test_wave_pierces_three_aligned_dummies`), `test_enemy.gd`
(`test_big_recoils_only_under_the_wave`), `test_health.gd`, `test_combat_player.gd`,
`test_m1_arena.gd`, `test_m1_combat.gd`. Les quatre corps de Timere portent les noms de l'acte 1
(rejeton, fragment, Timere bondissant, grand fragment ; `test_sys_timere_bodies.gd`) et ne
lâchent plus rien. **À valider** : la sensation, manette et clavier en main
([REGLAGES_COMBAT.md](REGLAGES_COMBAT.md)).

## 3. La veille du Couchant — vérifiée en partie

- Vagues, bonus, soins, grand fragment dès la vague 3 et jamais deux : `test_wave_director.gd`,
  `test_m1_arena.gd` (`test_big_from_wave_three_never_two_at_once`).
- La cloche de veille (`arena.tscn`, seule chose visible au départ, invite « Sonner la cloche de
  veille ») lance la veille : `test_m2_quest.gd`, `test_m1_shortcuts.gd`, `test_story_texts.gd`.
- Écran de fin : « Fin de la veille », sous-titre « Le bord du Couchant » (nom de la zone, MONDE.md
  2.1), « Nouveau record de veille ! », « Veilles tenues » : `test_story_texts.gd`,
  `test_arena_end.gd`, `test_m2_arena.gd` ; capture `acte1_fin_veille.png`.
- Le registre de Tiat : 4e vague puis 1 000 points en une veille, joués au Couchant dans la vraie
  partie (`test_act1_side_quests.gd`).
- **À valider** : « la vague 5 est atteignable par un joueur moyen » (trois membres, porte M2).

## 4. Défaite — vérifiée automatiquement

`test_m2_arena.gd` (`test_death_in_the_arena_then_end_screen_at_the_village`), `test_m1_forest.gd`
(mort dans les bois), `test_m1_arena.gd` (record écrit) : retour au Spawn de l'entrepôt, PV
pleins, inventaire, quêtes et record gardés. Textes : « Retour à l'entrepôt… » puis « Les autres
t'ont ramenée à l'entrepôt. » (`test_story_texts.gd`).

## 5. Images par seconde — à valider par un humain

- **Mesures logicielles** (indicatives : SwiftShader, sans GPU) : `tools/web_m2.js zones` charge
  `index.html?zone=<id>` pour chaque zone et relève les mesures « [m1] … i/s, draw calls,
  primitives » des raccourcis de test pendant 16 s : RESULTATS_ZONES
- Budgets natifs (draw calls et primitives, `demo_monde` et `demo_m1`) : sous 150 draw calls et
  150 000 primitives partout (docs/DECISIONS.md, « Monde — budget Web »).
- **À valider** : sur un portable de bureau courant puis un téléphone récent, `?zone=dunes&timeres=12`
  et F3 ; objectifs 60 et 30 images/s ; regarder aussi le port (la vue la plus chargée).

## 6. La quête principale au clavier et à la manette — vérifiée automatiquement

- `tests/integration/test_m2_quest.gd`, deux fois le même parcours, par des appuis réels :
  `test_first_act_with_keyboard_and_mouse` et `test_first_act_with_a_gamepad_only`. Nygglatho sous
  le porche, Willem et ses conseils, les bois à pied (« Les bois du marais »), quatre rejetons à
  l'épée, Pannibal, le rapport, la première veille (cloche, trois vagues, écran de fin), la fièvre
  (Nephren apporte les cafés), l'assaut au terrain d'entraînement, le bord du Couchant, le thé du
  Barocupot, la colline des étoiles et la promesse : quête terminée, la promesse du gâteau au
  beurre dans l'inventaire, 6 PV max, six cœurs ; après l'acte, Willem regarde les étoiles.
  L'objectif du HUD suit chaque étape ; l'appui qui ferme une conversation ne la relance pas.
- Le même parcours par le moteur seul, étape par étape : `test_act1_main.gd`.
- Dans le navigateur : `tools/web_m2.js acte1` joue les trois premières étapes à pied (Nygglatho,
  Willem, les bois).
- Captures : `acte1_nygglatho.png`, `acte1_willem.png`, `acte1_deux_voix.png` (la fièvre : Nephren
  parle dans le dialogue de Willem, avec son portrait), `acte1_journal.png`, `acte1_colline.png`.
- **À valider** : une vraie manette (Xbox, PlayStation ; Chrome et Firefox) et le toucher.

## 7. Reprise après fermeture de l'onglet — vérifiée automatiquement ; navigateurs réels à valider

- `test_m2_resume.gd` : position, zone, skin, inventaire, quêtes et étape d'`act1_main`, objets
  déjà pris, PV max et record restaurés par « Continuer ».
- Navigateur (`tools/web_m2.js acte1`) : la partie quittée dans les bois, à l'étape rejetons, est
  copiée dans IndexedDB puis reprise après rechargement (RESULTATS_REPRISE).
- **Limite connue** : sur le Web, une écriture n'est conservée qu'une fois copiée dans IndexedDB ;
  un onglet fermé juste après peut perdre au plus les 5 dernières secondes de marche.

## 8. Zones, barrière, bords de l'île — vérifiés automatiquement

Noms de MONDE.md 2.1 (« L'entrepôt des fées », « Les bois du marais », « Le bord du Couchant »,
« Le port et le bourg », « La colline des étoiles ») affichés une fois à l'entrée :
`test_m2_world.gd`, `test_world_island.gd`, `test_world_manager.gd`. Aucun Timere n'entre à
l'entrepôt : `test_m2_world.gd`, `test_enemy.gd`. Chute dans le vide : les ailes de lumière, « Tes
ailes se sont ouvertes : te revoilà au bord. » (`test_sys_story.gd`, `test_m2_world.gd`).

## 9. Tests GUT — vérifiés automatiquement

`tools/check.sh` : RESULTATS_CHECK

## 10. Présence des PNJ selon l'histoire — vérifiée automatiquement

`test_act1_presence.gd` joue `act1_main` étape par étape : à chaque étape « parler », le PNJ visé
est présent (`NpcData.visible_if`) et posé dans la zone de l'étape ; un seul Willem à la fois
pendant l'acte (à l'entrepôt, au terrain d'entraînement pendant `training`, au sommet à partir de
`promise`) ; Limeskin au port à partir du bord du Couchant ; les PNJ des quêtes secondaires restent
là (Willem s'absente pendant `training` et `promise`) ; une partie reprise à l'étape `promise`
trouve Willem au sommet. Après l'acte, Willem est à l'entrepôt et sur la colline (écart assumé,
docs/DECISIONS.md, jusqu'au cycle jour/nuit). Captures : `acte1_village.png` (l'entrepôt et ses
PNJ), `acte1_bois.png` (Willem au banc du terrain, les rejetons, Pannibal), `acte1_couchant.png`
(la cloche, le guetteur), `acte1_port.png` (Limeskin au bras d'ancrage du Barocupot, le marché,
le café), `acte1_colline.png` (Willem à côté du belvédère).

## 11. Les six quêtes secondaires — vérifiées automatiquement

`test_act1_side_quests.gd` les joue l'une après l'autre dans `main.tscn` : le livre d'images (cinq
pages des bois, la lecture), le dessert spécial (marché, baies, café, le grand arbre, le
réfectoire), le linge envolé (cinq draps du port à la colline, le thé), les myosotis (le vase),
l'homme-chat (café, M. Rami, engrenages, peigne du marais, Willem répare), le registre des veilles
(deux veilles) : six souvenirs, 7 PV max, sept cœurs. `test_act1_items_in_world.gd` : chaque étape
« réunir » trouve assez d'objets dans l'île ou chez un PNJ. Scénarios détaillés (dialogues,
refus, attentes) : `test_act1_picture_book.gd`, `test_act1_special_dessert.gd`,
`test_act1_flying_laundry.gd`, `test_act1_forget_me_nots.gd`, `test_act1_old_clock.gd`,
`test_act1_vigil_register.gd`.

## 12. Les rejetons des bois — vérifiés automatiquement

Tués avant l'étape `rejetons` (ou hors des bois, où ils ne comptent pas), ils reviennent quand
l'étape commence et quand le joueur rentre dans les bois (`src/enemies/free_enemies.gd`) ; hors
d'une étape qui les vise, un mort reste mort : `test_free_enemies.gd`.

## 13. Anciennes sauvegardes — vérifiées automatiquement

Une sauvegarde du jalon M2 (v1 : pages rendues ou pages en cours, objets et skin retirés) et une du moteur de quêtes (v2) se chargent dans la vraie partie : Chtholly, objets
retirés inconnus mais sans erreur, `act1_main` commence et prend le suivi, la quête des pages
n'est ni au journal ni dans le « +n quêtes » du HUD : `test_act1_saves.gd`.

## 14. Textes — vérifiés automatiquement ; le ton reste à lire

- `{player}` est le prénom de la protagoniste : « Chtholly » pour « Chtholly Nota Seniorious · 3D »
  (`test_player_name.gd`, règle dans docs/QUETES.md).
- Dialogues de l'acte 1 : typographie, longueurs, nœuds atteignables, scènes d'étape avant le
  reste, orateurs des scènes à plusieurs voix (`test_act1_dialogues.gd`) ; quêtes, objets et
  renvois (`test_quest_content.gd`, `test_sys_story_content.gd`).
- **À valider** : relire les scènes en jouant (voix des personnages, HISTOIRE.md section 8).

## 15. Places de l'histoire — vérifiées automatiquement

Les PNJ, objets et déclencheurs de HISTOIRE.md 3.3 sont à leur place, sans écart (le guetteur en
(−14 ; 0,2 ; −10), `couchant_edge` au sol, le myosotis de l'entrepôt en (17 ; 0 ; 5)) :
`test_npc.gd`, `test_item_data.gd` ; l'île les garantit au sol, hors du décor, à 3 m du vide et
reliés à pied à l'entrepôt : `test_world_story_spots.gd`, `test_m1_world.gd`.

## 16. Restes du jalon M2 — vérifiés automatiquement

La recherche des cinq mots de l'ancien contenu (deux PNJ du jalon M2, ses deux objets retirés,
l'ancienne graphie de Seniorious ; commande exacte dans docs/DECISIONS.md, section « Acte 1 —
intégration ») ne renvoie plus que des traces assumées : docs/DECISIONS.md et
docs/CONTRACT_REQUESTS.md (l'historique), docs/lore/ (bible et fiches de lecture), les dossiers
3D hors périmètre, les fixtures d'anciennes sauvegardes (`test_save_migration.gd`,
`test_act1_saves.gd`), les listes d'éléments retirés (`test_skin_registry.gd`,
`test_item_data.gd`) et les gardes contre l'ancienne graphie (`test_credits.gd`,
`test_sys_story_content.gd`, `test_act1_dialogues.gd`).

## 17. Direction artistique — à valider par un humain

Le décor (île n° 68, travail du « Monde ») vise *Breath of the Wild* dans les limites du rendu
Compatibility : palette naturelle, cel discret, grands paysages, herbe. Ce qui la dessert encore,
relevé sur les captures :

- **Les personnages** sont des planches 2D en pixel art, à grosse tête (Chtholly) ou des
  silhouettes de remplacement (les PNJ), posées en billboards dans un décor 3D : rien de plus
  éloigné des proportions réalistes stylisées voulues ; les modèles 3D de la PR n° 1 sont en
  refonte (docs/ASSETS_3D.md).
- **L'interface** (cœurs roses, panneaux crème à bords arrondis, boutons roses) reste celle de
  l'easter egg : plus « mignonne » que la sobriété de *Breath of the Wild*.
- **Le décor** : volumes en facettes franches à couleurs de sommets (pas de textures peintes,
  que MONDE.md 5.4 demande) ; bâtiments et navires en boîtes (le Barocupot, la grue, les maisons
  du bourg) ; ciel de jour bleu, quand MONDE.md 5.4 décrit un couchant orange et un ciel du violet
  au pêche (choix du « Monde », docs/DECISIONS.md) ; mer de nuages plate vue de près.
- **Le Barocupot** est toujours amarré, alors que Limeskin n'arrive qu'à l'étape 10 (placements
  conditionnels : développement n° 7, M3).

## Points connus (documentés, non corrigés)

- **Deux Willem après l'acte** (entrepôt et colline) : voir section 10.
- **Willem apparaît au sommet** quand le joueur entre dans `hill_summit` (pas d'arrivée mise en
  scène en M2).
- **Cœur de la promesse** (L4) : les PV max passent à 6 (puis 7), mais le cœur gagné reste vide
  jusqu'au prochain soin ou à la réapparition (« le maximum n'est pas un soin ») ; à trancher.
- **Skins 3D de Willem, Ithea, Nephren** : les choisir ne cache pas leur PNJ (ids différents) ;
  les cacher rendrait leurs quêtes impossibles ; à trancher avec la refonte des modèles.
- **Journal au toucher** : pas de bouton tactile (demande au L9, docs/CONTRACT_REQUESTS.md).
- **Sprites non éclairés**, **caméra verrouillée**, **pas d'interpolation physique**, **invite
  « E / A » fixe** : inchangés depuis le jalon M2.
- **CI GitHub et GitHub Pages jamais exécutées** (L9) : à lancer une première fois
  (docs/web.md).

## Ce qui reste à valider par un humain

1. Charger le build publié : temps jusqu'au menu, console (critère 1).
2. Jouer l'acte 1 en entier, manette et clavier en main, puis au toucher (critères 2, 3, 6) ;
   noter la vague atteinte par trois membres.
3. Mesurer les images/s avec F3 sur un portable et un téléphone (critère 5).
4. Fermer l'onglet en pleine promenade dans trois navigateurs, revenir, Continuer (critère 7).
5. Relire les scènes en jouant : voix, humour, ce qui n'est pas dit (critère 14).
6. Regarder les captures `build/shots/acte1_*.png` et juger la direction artistique (critère 17).

## Ce qui reste pour M3

Acte 2 (îles n° 15 et n° 11, Collina di Luce), cycle jour/nuit (Willem au sommet la nuit
seulement), voyages entre îles, placements conditionnels (le Barocupot, les bois nettoyés après
l'acte 1), narration sans PNJ (cartons), talismans en orbite, modèles 3D des personnages,
musique et sons, contrôles tactiles complets (bouton du journal).

## Refaire les captures

```bash
for v in village bois couchant port colline nygglatho willem deux_voix journal fin_veille; do
  ACT1_SHOT=$v tools/screenshot.sh res://tests/integration/demo_act1.tscn build/shots/acte1_$v.png 100
done
tools/godot --headless --export-release Web build/web/index.html
python3 -m http.server 8347 --bind 127.0.0.1 --directory build/web &
NODE_PATH=/opt/node-tools/node_modules node tools/web_m2.js http://127.0.0.1:8347/index.html build/shots
```
