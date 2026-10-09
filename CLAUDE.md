# Yume-WordEnd — règles pour Claude Code

## Le projet
Jeu d'action-aventure en HD-2D dans Godot 4.7.2 (GDScript typé, export Web) : Chtholly et son
épée contre des vagues de Timeres, un village, des PNJ et des quêtes. Direction artistique : HD-2D
à la manière d'*Octopath Traveler* : personnages en sprites (planches de l'easter egg), décor en
relief fait uniquement d'images (sol en tuiles de pixel art, façades et décors en panneaux debout,
ciel peint), caméra fixe inclinée, flou de profondeur, lueur, lumière chaude ; tout à 96 px par
mètre. Cahier des charges des images : docs/ASSETS_HD2D.md.
Le plan complet est dans PLAN.md. Ses contrats d'interface (section 3 : signaux, API, ressources,
couches de collision, « Structure figée au Lot 0 ») font foi : on code contre eux, on ne les
change pas sans PR « contrats ».

## Avant de commencer
1. Lis PLAN.md section 3 (contrats et structure figée) et section 7 (ton lot : dossiers, critères).
2. Lance `tools/check.sh` pour vérifier que l'environnement est sain (25 s environ).
3. Travaille sur la branche de ton lot ; une PR par lot vers `main`.

## Commandes
- Vérification complète (= « vert ») : `tools/check.sh` ; itération rapide sans export ni
  capture : `CHECK_FAST=1 tools/check.sh` (jamais pour valider une PR).
- Tests ciblés : `tools/test.sh tests/unit/test_x.gd` (un fichier), `tools/test.sh tests/unit`
  (un dossier), `tools/test.sh tests/unit/test_x.gd -gunit_test_name=morceau_du_nom` (un test).
- Import après avoir créé, renommé ou supprimé un script, une scène ou un asset :
  `tools/import.sh` (liste les .uid / .import à commiter et les orphelins).
- Capture d'une scène : `tools/screenshot.sh res://src/world/island.tscn build/shots/island.png`,
  puis ouvre le PNG avec l'outil de lecture d'images. Vues HD-2D de la vraie partie (menu, cinq
  zones, conversation, veille ; draw calls dans le journal) : `tools/hd2d_shots.sh [vue…]`.
- Images du décor (docs/ASSETS_HD2D.md, liste dans `tools/hd2d_manifest.json`) :
  `python3 tools/hd2d_assets.py gen` (remplaçants absents ; `--force`, ou des noms), `check`,
  `fit <fichier>` (image livrée trop grande), `atlas` (après une tuile de sol). Puis
  `tools/import.sh`.
- Export Web : `tools/godot --headless --export-release Web build/web/index.html`
- Application Windows (docs/bureau.md) : `tools/build_desktop.sh` (exe, installateur NSIS et zip
  dans `build/dist`), `--linux` (le même pck en build Linux, lancé sans écran jusqu'à une partie) ;
  `tools/desktop_boot.sh --xvfb` (captures du menu). Une Release GitHub naît d'un tag `vX.Y.Z`.
- Lint : `gdlint src tests tools && gdformat --check src tests tools` (`gdformat src tests tools`
  pour corriger). gdtoolkit 4.5.0, réglages dans `gdlintrc`.
- Environnement neuf : `bash tools/setup.sh` (Godot, templates Web, Windows et Linux, gdtoolkit,
  Pillow, NSIS ; idempotent).
- Navigateur (à la main, hors check.sh) : export, `python3 -m http.server 8347 --bind 127.0.0.1
  --directory build/web`, puis `NODE_PATH=/opt/node-tools/node_modules node tools/web_m2.js
  http://127.0.0.1:8347/index.html build/shots` (début de l'acte 1, reprise, images/s par zone ;
  `tools/web_m1.js` : arène). Mode d'emploi et raccourcis `?zone=`, `?timeres=`, `?trace=1` :
  docs/web.md.
- Planches de remplacement : `python3 tools/gen_placeholders.py skin <id> --name "Nom" --tres`.
- Quêtes : format, dialogues, déclencheurs et tests dans docs/QUETES.md ; vérifier le contenu par
  `tools/test.sh tests/unit/test_quest_content.gd` ; tester un scénario sur le modèle de
  `tests/unit/test_quest_example.gd` (base `tests/stubs/q_quest_test.gd`).
- Textes : `{player}`, scènes à plusieurs voix (`speaker_id`), présence des PNJ
  (`NpcData.visible_if`) et textes de l'histoire (`data/texts/story.json`) dans docs/QUETES.md ;
  vérifier par `tools/test.sh tests/unit/test_sys_story_content.gd`.
- Toujours passer par `tools/godot` (pas `godot`) : chaque worktree y a son propre `user://`.

## Règles
- GDScript typé partout (`var hp: int`, `-> void`), `class_name` pour les ressources et les classes
  partagées, signaux au passé. Les avertissements GDScript sont des erreurs (project.godot) : une
  variable non typée ou inutilisée empêche le script de compiler.
- Code (identifiants) en anglais ; commentaires, docs et textes du jeu en français.
- Scènes et ressources au format texte (.tscn, .tres), écrites à la main selon la recette
  ci-dessous. Jamais d'édition manuelle des .uid et .import ; commite-les avec le fichier qui les
  fait naître.
- Les chiffres de combat vivent dans data/attacks et data/enemies, jamais en dur dans un script.
- Un système ne lit jamais un autre système directement : EventBus ou API des autoloads.
- **Chaque lot remplit les squelettes de ses dossiers ; on ne déplace ni ne renomme les nœuds
  nommés ni les fichiers figés** (liste : PLAN.md section 3, « Structure figée au Lot 0 »). On
  peut ajouter des nœuds et des fichiers dans ses propres dossiers.
- Peupler une zone (PNJ, ennemis libres, objets) se fait dans son fichier d'emplacement
  `src/npc|enemies|items/placements/<zone>.tscn`, jamais dans la scène de zone (L2). Les
  déclencheurs de quête (`src/quests/quest_trigger.tscn`) vont dans `src/npc/placements/<zone>.tscn`.
- Les quêtes sont des données : `data/quests/<id>.json` (étapes, prérequis, récompenses) et les
  répliques qui les font avancer dans `data/dialogues/*.json` ; aucun script par quête.
- Les textes que les systèmes affichent hors dialogues et quêtes (arène, chute, défaite) vivent
  dans `data/texts/story.json` (`DialogueRunner.story_text`), jamais en dur ; jamais le nom du
  joueur en dur non plus : `{player}`.
- Le décor est en images : un décor = une scène de `src/world/props/` dont la racine est un
  `DecorPanel` (panneau debout) ou un `Building` (volume, matières, façade), sa collision dans un
  enfant `Collision` (StaticBody3D, couche 1) ; jamais de maillage 3D modélisé ni de forme calculée
  pour l'apparence. Les images vont dans `assets/hd2d/`, à leur taille exacte (96 px par mètre).
- Ne modifie que les dossiers de ton lot. Hors périmètre : note le besoin dans
  docs/CONTRACT_REQUESTS.md et continue avec un stub local (dans tests/stubs/, sans class_name).
- project.godot, export_presets.cfg, src/autoload/event_bus.gd, src/main.*, src/game.* et les
  couches de collision ne changent qu'au Lot 0 ou dans une PR « contrats ».
- Un choix que le plan ne tranche pas va dans docs/DECISIONS.md (une ligne par décision, en bas).
- Toute scène doit passer tools/smoke.gd ; tout changement de rendu joint une capture à la PR.
- Commits conventionnels préfixés par le lot : `feat(l4): onde de charge magique`.
- Avant d'ouvrir la PR : `tools/check.sh` vert et `git status` propre (aucun .uid / .import oublié),
  description = fait / testé / capture / contrats touchés.

## Recette des fichiers écrits à la main (Godot 4.7.2)
- En-tête de scène : `[gd_scene format=3]`, de ressource : `[gd_resource type="Resource"
  script_class="AttackData" format=3]`. Pas de `load_steps` (Godot 4.7 ne l'écrit plus), pas de
  `uid=` dans l'en-tête, pas de `unique_id=` sur les nœuds (l'éditeur les ajoute s'il réenregistre).
- `ext_resource` par chemin seulement, sans `uid` : `[ext_resource type="Script"
  path="res://src/combat/health.gd" id="1_health"]`. Un `uid` faux produit un WARNING (donc un
  check rouge) ; un `uid` absent ne produit rien. Types : `Script`, `PackedScene`, `Resource`
  (un .tres), `Texture2D` (un .png importé), `JSON` (un .json).
- Ids libres et lisibles (`"1_health"`, `"BoxShape3D_sword"`), uniques dans le fichier.
- Instance : `[node name="Visual" parent="." instance=ExtResource("2_visual")]`.
- Référence à un nœud dans une propriété exportée (`@export var health: Health`) : déclarer la
  propriété dans `node_paths` du nœud, sinon elle reçoit un NodePath au lieu du nœud :
  `[node name="Hurtbox" parent="." node_paths=PackedStringArray("health") instance=ExtResource("4")]`
  puis `health = NodePath("../Health")`.
- Tableau typé d'une classe de script : le paramètre de type est l'ext_resource du **script** de
  la classe : `attacks = Array[ExtResource("3_attack_script")]([ExtResource("4_bite")])`.
  Tableau natif : `Array[StringName]([&"a", &"b"])`. Dictionnaire typé :
  `Dictionary[StringName, int]({ &"page_fragment": 5 })` (un `{}` simple se charge aussi).
- Valeurs : `&"id"` pour un StringName, `Vector3(1, 2, 3)`, `Color(1, 0.5, 0, 1)`,
  `Transform3D(xx, xy, xz, yx, yy, yz, zx, zy, zz, ox, oy, oz)` (base par lignes).
- Une forme partagée par toutes les instances (sous-ressource d'une scène instanciée) se modifie
  pour toutes : `resource_local_to_scene = true` (déjà le cas dans hitbox.tscn / hurtbox.tscn)
  ou `duplicate()` avant de la changer à l'exécution.
- Exemple minimal de scène :

  ```
  [gd_scene format=3]

  [ext_resource type="Script" path="res://src/items/pickup.gd" id="1_pickup"]

  [sub_resource type="SphereShape3D" id="SphereShape3D_pickup"]
  radius = 0.5

  [node name="forest_page_1" type="Area3D" groups=["interactable"]]
  collision_layer = 64
  collision_mask = 2
  script = ExtResource("1_pickup")
  item_id = &"page_fragment"

  [node name="CollisionShape3D" type="CollisionShape3D" parent="."]
  shape = SubResource("SphereShape3D_pickup")
  ```
- Exemple minimal de ressource :

  ```
  [gd_resource type="Resource" script_class="ItemData" format=3]

  [ext_resource type="Script" path="res://src/items/item_data.gd" id="1_item"]

  [resource]
  script = ExtResource("1_item")
  id = &"page_fragment"
  display_name = "Fragment de page"
  ```
- Après création : `tools/import.sh` génère le `.uid` de chaque nouveau script (`x.gd.uid`) et le
  `.import` de chaque nouvel asset (`x.png.import`) ; rien d'autre n'est réécrit (ni .tscn, ni
  .tres, ni project.godot). Commite-les : un worktree qui les régénère obtient d'autres UID et
  entre en conflit avec les autres. Renommer ou supprimer : `git mv` / `git rm` du fichier ET de
  son `.uid` / `.import` (Godot ne supprime pas les orphelins).

## Pièges connus
- Pas d'écran : valide par tests, smoke, export et captures Xvfb, jamais « ça devrait marcher ».
- Export Web mono-thread : pas de `Thread`, pas de `OS.execute`, pas de `SharedArrayBuffer`.
- Les planches de sprites utilisent le JSON de l'easter egg (ancres par image, `coup`, `onde`) : ne
  les reformate pas. Elles sont dessinées tournées vers la droite.
- (HD-2D) La caméra est fixe et regarde le nord (−Z) : le haut de l'écran est le nord, W/Z marche
  vers le nord quelle que soit la visée. Un test qui marche vers une cible passe par
  `hold_toward(direction)` / `release_move()` (tests/stubs/m1_game_test.gd) ou
  `walk_aim_until()` / `hold_aim()` (m2_game_test.gd), jamais par « W après set_aim_direction ».
- (HD-2D) Un panneau (`DecorPanel`) se tourne toujours vers le sud, quelle que soit la rotation de
  son nœud (PropScatter en tire une) ; sa collision, elle, garde la rotation. Le `PropBatcher` du
  nœud `Geometry` fond, au lancement, tout MeshInstance3D qui porte un `material_override` en un
  mesh par image (« Batch… ») : un décor sans `material_override` n'est pas fondu (un draw call de
  plus). Le sol lit `assets/hd2d/ground/atlas/ground_atlas.png` : après une tuile changée,
  `python3 tools/hd2d_assets.py atlas` (test_hd2d_assets.gd le vérifie).
- (HD-2D) Le post-traitement (flou de profondeur, lueur, étalonnage) est le `CanvasLayer`
  `CameraRig/PostFX` (couche −1, sous l'interface) : une capture sans joueur (island.tscn seule)
  ne l'a pas.
- Godot 4.7 n'affiche jamais les avertissements GDScript en ligne de commande : ils sont réglés en
  erreurs dans project.godot et apparaissent comme `SCRIPT ERROR: Parse Error: … (Warning treated
  as error.)`. Typer aussi les itérateurs (`for x: String in liste`), préfixer par `_` les
  paramètres inutilisés, ne pas masquer une propriété héritée (`name`, `position`, `root` dans un
  SceneTree, `reference` dans un RefCounted…). Signal jamais émis dans sa classe :
  `@warning_ignore("unused_signal")`.
- L'import ne compile pas les scripts : une erreur de script n'apparaît qu'au chargement (fumée,
  tests). GUT **ignore sans échouer** un fichier de test qui ne compile pas : tools/check.sh et
  tools/test.sh le rattrapent en cherchant `SCRIPT ERROR` dans le journal.
- GUT 9.7.1 fait échouer un test sur tout `push_error` ou erreur moteur imprévus ; une erreur
  attendue se déclare avec `assert_push_error("texte")` ou `assert_engine_error("texte")`.
- Les autoloads gardent leur état d'un test à l'autre : `GameState.reset()` dans `before_each`,
  et rétablir ce qu'on change (`SaveManager.save_path`, `WorldManager.respawn_delay`…) dans
  `after_each`. WorldManager ne fait réapparaître que le joueur mort encore dans l'arbre.
- Dans un script `extends SceneTree` (outils), les autoloads n'existent qu'après la première
  image : `await process_frame` avant de s'en servir. Libère tout avant `quit()`, sinon
  `ERROR: resources still in use at exit` rend le check rouge.
- Une ressource qui contient un `Array[SaClasse]` de sa propre classe fuit à la sortie (ERROR à
  l'import) : pas d'auto-référence typée.
- Les nombres lus dans un JSON sont des float : `int(data["max_hp"])`. Les clés String et
  StringName d'un Dictionary sont interchangeables (`d.has(&"a")` trouve `"a"`).
- AnimatedSprite3D a déjà des signaux `frame_changed` / `animation_finished` sans argument :
  CharacterVisual est donc un Node3D avec un enfant `Sprite`.
- Le rendu headless est factice, mais Godot 4.7 compile quand même les shaders : une erreur de
  shader sort en `SHADER ERROR` dans la fumée.
- Plusieurs worktrees peuvent lancer Godot en même temps : `tools/godot` isole `user://` et les
  réglages de l'éditeur dans `build/xdg/`. Un `godot` lancé à la main partage `~/.local/share`.
- `build/` est dans le dossier du projet : `tools/godot` y crée `.gdignore`, sans quoi Godot
  importerait les captures et l'export embarquerait `build/xdg`. Tout dossier de travail placé
  dans le projet doit contenir un `.gdignore` (les dossiers cachés, comme `.claude/`, sont ignorés).
- Les fichiers où plusieurs lots ajoutent des lignes (docs/DECISIONS.md, docs/CONTRACT_REQUESTS.md,
  tools/warnings_allow.txt, les CREDITS) fusionnent par union : ajoute en bas, ne réordonne pas.
- Tests dans la vraie partie : `tests/stubs/m2_game_test.gd` (main.tscn, appuis réels par
  `Input.parse_input_event`). Les attentes de GUT (`wait_*`) sont gelées quand l'arbre est en
  pause (pause, inventaire, fin d'arène) : attendre `get_tree().physics_frame`. Un appui doit
  durer au moins une image physique (sinon il est encore « just pressed » à la reprise). En
  headless, la fenêtre fait 64 × 64 px : un clic porte `root.get_final_transform() * position`,
  et la couche de GUT (`GutLayer`) prend les clics si elle n'est pas cachée.
- (bureau) `user://` porte le nom du jeu hors Web (`use_custom_user_dir`) : `build/xdg/data/WordEnd`
  sous `tools/godot`, `%APPDATA%\WordEnd` sous Windows ; le Web garde
  `/userfs/godot/app_userdata/WordEnd`. L'autoload `DesktopApp` (plein écran, « Quitter ») se croit
  sur le bureau dans les tests : `DesktopApp.simulated_web` (1 : Web), `settings_path` et
  `quit_enabled = false` (sinon « Quitter » ferme GUT), rétablis dans `after_each`.
- `zone_entered` n'est émis qu'au changement de zone (M2) : un test qui replace le joueur dans
  la zone où il est déjà ne le reçoit pas (`Zone.LAST_ZONE_META` sur le corps du joueur).
- Quêtes et dialogues JSON : une clé inconnue (faute de frappe) les rend invalides, sauf une clé
  qui commence par `_` (commentaire). `QuestData` garde les fichiers lus en cache : un test qui
  écrit ou retire des quêtes appelle `QuestData.clear_cache()` (ou `add_search_dir` /
  `remove_search_dir`, comme `tests/stubs/q_quest_test.gd`). Un test qui démarre une quête sans
  QuestTracker n'a pas d'étape enregistrée : `QuestData.current_step()` donne alors la première.
- Un QuestTracker dans l'arbre réagit à `GameState.set_quest_state(id, &"done")` (fin forcée) :
  sans les objets de ses étapes collect restantes, la quête revient à `&"active"`.
- Un PNJ absent (`NpcData.visible_if` fausse, ou skin du joueur) est caché, `process_mode`
  DISABLED : ni collision ni `InteractArea`. Sa présence est réévaluée en fin d'image (un test
  attend une image ou appelle `Npc.refresh_presence()`), jamais pendant sa conversation.
  `DialogueRunner.find_npc` (portraits, `speaker_id`) cherche `data/npcs` puis les dossiers
  d'`add_npc_dir` : un test qui en ajoute un le retire dans `after_each`.
- (Cartes, E1) `game.tscn` n'a plus d'`Island` : la carte courante est l'unique enfant de `World`
  (l'ancienne île : `World/ile_ancienne/Zones/<zone>`). Une seule carte à la fois
  (`WorldManager.go_to`, `enter_map`) ; un test qui change de carte pose
  `WorldManager.fade_time = 0.0` et le rétablit dans `after_each`. Créer une carte : mode
  d'emploi dans PLAN.md, section 3 ; `tools/test.sh tests/unit/test_maps.gd` la vérifie.
