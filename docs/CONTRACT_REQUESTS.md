# Demandes de contrat

Un lot qui a besoin d'un contrat hors de son périmètre (signal d'EventBus, méthode d'autoload,
nœud ou propriété d'une scène figée, couche de collision, action d'entrée, champ d'une ressource
d'un autre lot) l'écrit ici, continue avec un stub local (tests/stubs/, sans class_name) et le
signale dans la description de sa PR. L'orchestrateur tranche dans une PR « contrats ».

Ajoute ta demande en bas (fusion par union entre lots), au format :

```
## L<N> — titre court
- Besoin : ce qui manque et pourquoi (qui émet, qui écoute).
- Proposition : signature exacte, ex. `signal boss_defeated(boss_id: StringName)` dans EventBus,
  émis par …, écouté par ….
- En attendant : le contournement utilisé (stub, signal local…).
```

## Demandes

## L8 — fin du suivi de la partie au retour au menu
- Besoin : quand main.gd revient au menu, la partie n'est plus suivie : l'écriture en attente
  (au plus 0,5 s de changements) doit être faite tout de suite, puis l'auto-sauvegarde coupée
  jusqu'au prochain `game_loaded`.
- Proposition : dans `src/main.gd`, `show_menu()` appelle `SaveManager.close_game()` avant de
  libérer la partie (fichier d'intégration du Lot 0, à faire à l'intégration).
- En attendant : le minuteur de SaveManager tourne aussi sans partie et écrit l'attente au plus
  0,5 s plus tard ; au menu, aucun signal de jeu n'arrive, donc rien d'autre n'est écrit.
## L4 — Combat tourné vers « devant » par le joueur
- Besoin : PlayerCombat vise avec le −Z de son nœud : secteur de l'épée (enfant SwordHitbox) et
  direction de l'onde. La règle n'est écrite que dans les consignes des lots, pas dans PLAN.md.
- Proposition : contrat de player.tscn : « player.gd (L1) tourne `Combat` (rotation y) pour que
  son −Z local soit la direction de déplacement, ou la cible verrouillée ; Combat appelle
  `Visual.set_facing(-Z de Combat)` au début d'un coup ou d'une charge ».
- En attendant : sans rotation, le joueur frappe et lance l'onde vers −Z du monde (nord).

## L4 — show_frame émet frame_changed
- Besoin : PlayerCombat lance l'onde quand le Visual affiche l'image « onde » de la charge : il
  appelle `show_frame(&"charge", wave_frame(&"charge"))` et attend `frame_changed(&"charge", 3)`.
  Il s'appuie aussi sur `play(anim, true)` (relance une animation, même terminée) et sur
  `animation_finished(&"attaque")` pour finir un coup. Le squelette L0 de CharacterVisual (L3) fait
  tout cela (AnimatedSprite3D émet frame_changed quand `frame` change).
- Proposition : préciser dans le contrat de CharacterVisual : « show_frame(anim, frame) émet
  frame_changed(anim, frame) quand l'image affichée change ».
- En attendant : si le signal ne vient pas, l'onde part aussitôt après show_frame (repli) ; un coup
  sans animation_finished se termine après `PlayerCombat.animation_timeout` (2 s).
## L5 — savoir si une zone est sûre
- Besoin : un Timere abandonne la poursuite quand le joueur est dans une zone `safe` (village).
  Aucune API ne dit si une zone est sûre : Enemy (L5) lit `WorldManager.current_zone()` puis
  `Zone.safe` de la racine du groupe `zones` qui porte ce nom.
- Proposition : `func is_zone_safe(zone_id: StringName) -> bool` dans WorldManager (L2), vrai si la
  Zone `zone_id` a `safe = true` ; Enemy l'appellerait avec `current_zone()`.
- En attendant : lecture défensive de `Zone.safe` via le groupe `zones` (src/enemies/enemy.gd,
  `_player_in_safe_zone`), mise en cache tant que la zone courante ne change pas.
## L7 — auto-sauvegarde après la récompense de quête
- Besoin : SaveManager (autoload) est branché sur `quest_updated` avant le QuestTracker de
  game.tscn. S'il écrit pendant l'émission de `quest_updated(&"pages", &"done")`, le fichier
  contient la quête finie sans sa récompense (fragments encore là, pas de marque-page, 5 PV max)
  et la récompense est perdue si l'onglet se ferme avant la sauvegarde suivante.
- Proposition : L8 regroupe ses auto-sauvegardes en fin d'image (`save.call_deferred()`, une
  seule par image), ce qui couvre aussi `inventory_changed` + `item_collected` d'un même
  ramassage. Aucune signature ne change.
- En attendant : rien à contourner (le SaveManager du Lot 0 ne sauvegarde pas tout seul) ;
  QuestTracker applique tout avant la fin de l'émission (tests/unit/test_quest_tracker.gd).

## L7 — fragments lâchés par les Timeres de la forêt
- Besoin : la quête demande 5 fragments ; la forêt en contient 3 uniques (`forest_page_1..3`),
  les 4 Timeres libres de la forêt doivent lâcher le reste (PLAN.md section 4), mais pas ceux de
  l'arène, qui partagent les mêmes EnemyData.
- Proposition (L5) : à la mort d'un Timere de la forêt, instancier
  `res://src/items/pickup.tscn` avec `item_id = &"page_fragment"`, `quantity = 1`,
  `persistent = false`, ajouté au nœud `Pickups` de la zone (ou au parent de l'ennemi) à sa
  position ; réglage par ennemi placé (ex. `@export var drop_item: StringName`) plutôt que
  `EnemyData.drops`, commun avec l'arène.
- En attendant : test_quest_in_game.gd simule les deux fragments lâchés par `add_item`.
## L6 — fin de dialogue : l'appui qui ferme la conversation ne doit rien déclencher
- Besoin : la dernière réplique se ferme sur `interact` (E, bouton A) ou `ui_accept` (Entrée,
  Espace). `dialogue_ended` est émis pendant la distribution de cet événement ; un joueur (L1)
  qui lit `interact` ou `jump` par sondage (`Input.is_action_just_pressed` dans
  `_physics_process`) voit encore l'appui dans la même image : il saute (Espace et A sont aussi
  `jump`) ou réinteragit aussitôt.
- Proposition : le joueur lit `interact` et `jump` dans `_unhandled_input` (la boîte de
  dialogue consomme ces touches dans `_input` tant qu'elle est ouverte), ou les ignore dans
  l'image où il reçoit `dialogue_ended` ; il reste immobile entre `dialogue_started` et
  `dialogue_ended` (déjà prévu). `DialogueRunner.is_any_running()` (statique) dit à tout
  moment si une conversation est en cours. Implémenté par L1.
- En attendant : `Npc.interact()` est ignoré 0,3 s après la fin de son dialogue
  (`talk_cooldown`), ce qui empêche la relance ; le saut parasite reste à traiter par L1.
## L9 — icône et démarrage du moteur (project.godot)
- Besoin : `html/export_icon` exporte `application/config/icon`, vide : favicon et icône iPhone
  sont celles de Godot ; entre le shell et le menu, le moteur montre son splash (logo Godot sur
  fond gris), qui jure avec le shell et l'écran de chargement.
- Proposition : une icône du jeu à la racine (`res://icon.svg`, dans le pck), puis dans
  project.godot `config/icon="res://icon.svg"`, `boot_splash/show_image=false` et
  `boot_splash/bg_color=Color(0.106, 0.071, 0.192, 1)` (#1b1231, le fond du shell et du site).
- En attendant : icône et splash par défaut de Godot (aucune erreur).

## L9 — main.gd : chargement qui progresse
- Besoin : main.gd charge game.tscn par `load()` ; sans threads, l'écran de chargement reste
  figé à 0 % pendant tout le chargement.
- Proposition : dans `start_game()`, si la racine de loading.tscn a `load_scene`,
  `var game_scene: PackedScene = await loading.call(&"load_scene", GAME_SCENE)` au lieu de
  `load(GAME_SCENE)` (loading.gd appelle lui-même `set_progress` de 0 à 1).
- En attendant : `set_progress(0)` puis `set_progress(1)`, barre vide pendant le chargement.

## L9 — caméra souris sur écran tactile (L1)
- Besoin : sur écran tactile, Godot émule une souris (`device == InputEvent.DEVICE_ID_EMULATION`)
  et le navigateur envoie aussi des mouvements de souris quand un doigt glisse : une caméra qui
  les lit tournerait en double avec `camera_*`.
- Proposition : CameraRig lit la souris dans `_unhandled_input` (décision L0) et ignore les
  événements `device == InputEvent.DEVICE_ID_EMULATION` ; TouchControls consomme déjà ces
  événements dans `_unhandled_input` (UI/TouchControls passe avant Player dans cet ordre).
- En attendant : rien à faire tant que la caméra respecte `_unhandled_input`.

## L10 — boutons de manette pour ui_accept et ui_cancel
- Besoin : dans Godot 4.7, `ui_accept` et `ui_cancel` n'ont aucun bouton de manette : A ne presse pas
  le bouton qui a le focus et B ne ferme rien. Chaque écran le contourne à sa façon : DialogueBox
  lit `interact` (L6), les écrans du L10 lisent A et B au relâchement (`src/ui/main_menu_input.gd`),
  l'inventaire (L7) n'a pas de B.
- Proposition : PR « contrats » sur project.godot : JOY_BUTTON_A (0) dans `ui_accept`, JOY_BUTTON_B
  (1) dans `ui_cancel`. Point d'attention : A est aussi jump et interact, B est charge, lus par
  sondage par le joueur ; un écran qui se ferme sur l'**appui** ferait sauter ou charger le joueur
  dans l'image où la pause est levée (BaseButton, lui, presse au relâchement, ce qui l'évite).
  Ensuite, `main_menu_input.gd` pourra se réduire au retour par B.
- En attendant : `src/ui/main_menu_input.gd` (menu principal, crédits, pause, fin d'arène).

## Intégration M2 — suite donnée aux demandes
- L8, fin du suivi au retour au menu : faite. Le menu pause (L10) appelait déjà `save()` puis
  `close_game(false)` avant `reload_current_scene()` (vérifié dans le vrai jeu,
  `test_m2_world.gd`) ; `main.show_menu()` écrit la partie si elle a changé
  (`SaveManager.save_on_leave()`) puis appelle `close_game(false)` (`test_m2_resume.gd`).
- L4, Combat tourné vers « devant » : faite par L1 (`Combat.rotation.y` suit la visée).
- L4, `show_frame` émet `frame_changed` : faite par L3.
- L5, zone sûre : faite à l'intégration M1 (`WorldManager.is_zone_safe`).
- L7, auto-sauvegarde après la récompense : satisfaite par le regroupement de 0,5 s du L8.
- L7, pages lâchées par les Timeres de la forêt : faite par L5 (`EnemyData.drops`,
  `drops_enabled`).
- L6, fin de dialogue : faite par L1 et L6 ; vérifiée dans le vrai jeu (Espace, E, A :
  `test_m2_quest.gd`).
- L9, icône et démarrage du moteur : faite (`assets/ui/icon.png`, `boot_splash.png`,
  `tools/gen_branding.py`, project.godot ; écran de démarrage affiché plutôt que masqué).
- L9, main.gd et chargement qui progresse : faite (`Loading.load_scene`).
- L9, caméra souris sur écran tactile : satisfaite (L1 n'oriente la caméra à la souris que
  pointeur capturé, et ne le capture pas sur un toucher émulé).
- L10, boutons de manette pour `ui_accept` / `ui_cancel` : refusée ; le contournement
  (`src/ui/main_menu_input.gd`) est gardé et appliqué à l'inventaire (docs/DECISIONS.md,
  section « Intégration M2 »).

## Lot Q — bouton tactile du journal de quêtes
- Besoin : le journal de quêtes (action `journal` : Tab, L, bouton Select / Back) n'a pas de bouton
  tactile ; sur téléphone, il ne s'ouvre pas.
- Proposition : dans `src/ui/touch_controls.tscn` (L9), un bouton « Journal » à côté de « Sac »
  (même contexte : visible aussi en pause pour le refermer), qui émet l'action `journal`.
- En attendant : le journal s'ouvre au clavier et à la manette ; le HUD rappelle « Tab / Select »
  quand plusieurs quêtes sont actives.

## Lot Q — rappel des commandes du menu pause
- Besoin : l'écran « Commandes » du menu pause (`src/ui/pause_menu.gd`, L10) ne cite pas le
  journal de quêtes.
- Proposition : une ligne `["Journal de quêtes", "Tab ou L", "Select"]` dans `CONTROLS`, après
  « Sac ».
- En attendant : docs/QUETES.md et le pied du journal citent ses touches.

## Systèmes et textes — `{player}` dans `src/ui/journal.gd`
- Besoin : le journal affiche les textes de quête tels quels ; `journal.gd` est hors du périmètre
  du lot.
- Proposition : dans `journal.gd`, passer `quest.title`, `quest.summary`, `step.objective` et
  `step.hint` par `DialogueRunner.format_text`, puis retirer `src/ui/hud_journal.gd` et sa ligne
  `script = …` de `hud.tscn`.
- En attendant : `src/ui/hud_journal.gd` (sous-classe posée sur `HUD/Journal`) le fait après
  chaque mise à jour du détail ; testé par `tests/unit/test_player_name.gd`.

## Systèmes et textes — la quête des pages et les drops
- Besoin : les corps de Timere ne lâchent plus rien (HISTOIRE.md, sections 3.2 et 7.2), mais
  `tests/integration/test_m2_quest.gd` (contenu) joue encore `pages` avec quatre pages lâchées, et
  `data/quests/pages.json` en demande cinq quand trois seulement sont posées.
- Proposition : le contenu de l'acte 1 remplace `pages` par `picture_book` (cinq pages posées) et
  réécrit ce test ; l'aide de `tests/data/quests/demo_tour.json` (« Les Timeres de la forêt en
  lâchent… ») peut devenir « Des pages traînent dans la clairière. ».
- En attendant : ce test seul échoue dans la branche « Systèmes et textes ».

## Intégration acte 1 — suite donnée aux demandes
- Lot Q, rappel des commandes du menu pause : faite (`src/ui/pause_menu.gd`, ligne « Journal de
  quêtes » : Tab ou L, Select ; le panneau « Commandes » tient toujours dans 1280 × 720).
- Systèmes et textes, la quête des pages et les drops : satisfaite par le contenu de l'acte 1
  (`picture_book`, cinq pages posées ; `test_m2_quest.gd` joue `act1_main`) ; l'aide de
  `tests/data/quests/demo_tour.json` dit « Des pages traînent dans la clairière. ».
- Lot Q, bouton tactile du journal : toujours ouverte (L9) ; au toucher, le HUD montre la quête
  suivie et son objectif, mais le journal ne s'ouvre pas.
- Systèmes et textes, `{player}` dans `src/ui/journal.gd` : toujours ouverte ;
  `src/ui/hud_journal.gd` reste la solution (testée par `test_player_name.gd`).

## H1 / H6 — trois vues dans les contrats (PLAN.md sections 3 et 5)
- Besoin : `SkinData` a quatre propriétés facultatives de plus (`front_sheet`, `front_json`,
  `back_sheet`, `back_json`), `SheetLoader` les constantes `SIDE` / `FRONT` / `BACK` et
  `view_texture`, `view_json`, `has_view`, `view_problem`, `frames_for(skin, view)`,
  `read_sheet(skin, view)`, `pixel_size(skin, sheet, view_sheet)`, et `CharacterVisual`
  `current_view()` ; l'interface existante est inchangée (`test_contracts.gd` vert).
- Proposition : à la prochaine PR « contrats », ajouter ces noms aux lignes `SkinData`,
  `SheetLoader` et `CharacterVisual` de PLAN.md section 3, et à la section 5 (« Comment les
  sprites 2D vivent… ») : trois vues par personnage, vue choisie selon la direction à l'écran.
- En attendant : documentés dans `src/visuals/*.gd` et docs/DECISIONS.md (H6).

## H1 — marge du budget de l'export Web
- Besoin : avec les images livrées, l'export pèse environ 23,5 Mo compressés sur 25 ; les douze
  tuiles de sol (`assets/hd2d/ground/*.png`, 1,1 Mo une fois importées) partent dans l'export alors
  que le jeu ne lit que l'atlas (`ground/atlas/ground_atlas.png`).
- Proposition (PR « contrats », `export_presets.cfg`) : ajouter `assets/hd2d/ground/*.png` à
  `exclude_filter` (l'atlas est dans un sous-dossier ; les démos et les tests lisent les tuiles
  depuis les sources) ; autre réserve : l'atlas (2,4 Mo importé) ne profite pas de la palette de
  chaque tuile (768 couleurs en tout) et gagnerait 1,1 Mo réduit à 256 couleurs.
- En attendant : rien ; `tools/check.sh` mesure l'export à chaque passage.
## H2 — chemin du porche (H5, masques du sol)
- Besoin : rien au sol ne mène de la cour au porche de Nygglatho (premier objectif de l'acte 1,
  « Rejoindre Nygglatho sous le porche ») : on y va par l'herbe ; un chemin de terre guiderait
  l'œil vers elle.
- Proposition : un segment de plus dans `PATHS` de `src/world/shaders/terrain.gdshader`, du bord
  de la cour aux marches du porche (centré sur la porte depuis la reprise : x −10,35) :
  (−6,4, −6,4) → (−10, −8,8), même demi-largeur que les autres chemins. Le décor du village
  laisse ce couloir libre (`test_village_decor.gd` : abord de Nygglatho).
- En attendant : la lampe à cristal du porche (entre Nygglatho et Nephren) et les parterres
  encadrent l'abord.

## H2 — découpe autour du joueur pour toutes les zones (H5)
- Besoin : la découpe du village (`src/world/zones/village/see_through.gd`) fabrique au
  lancement une copie de `panel.gdshader` augmentée de `see_through.gdshaderinc` ; le port et
  les bois en auraient besoin aussi (rue, grands sapins), et une seule source serait plus sûre.
- Proposition : H5 inclut la découpe dans `panel.gdshader` (uniformes `see_through_*`, ligne
  d'effacement à la fin de `fragment()`) et un nœud commun (ou `PropBatcher`) pose le centre sur
  le joueur à chaque image ; `see_through.gd` ne ferait plus que poser les uniformes, ou
  disparaîtrait.
- En attendant : la copie suit le code de `panel.gdshader` (fonction `fragment()` augmentée au
  lancement) ; `test_village_decor.gd` vérifie que l'ajout se fait, compile et garde tous les
  uniformes du panneau.

## H2 — cheminée et terrasse à linge de l'entrepôt (H1, images)
- Besoin : MONDE.md (sections 2.2 et 3) cite la cheminée de briques qui fume et la terrasse à
  linge du toit (`warehouse_roof_deck`), absentes de `docs/ASSETS_HD2D.md` et de
  `tools/hd2d_manifest.json`.
- Proposition (section 7, priorité 3) : `assets/hd2d/props/warehouse_roof_deck.png`, 576 × 154 px
  (6 × 1,6 m) : terrasse plate vue de face, plancher, rambarde de fer basse (0,9 m, à hauteur de
  fée), cordes et deux draps blancs ; H2 la pose sur le toit de `warehouse_main` (panneau sans
  collision). Facultatif : `assets/hd2d/fx/chimney_smoke.png`, 96 × 192 px, panache de fumée
  pâle en pixel art.
- En attendant : la cheminée est faite en matières (`src/world/props/warehouse_chimney.tscn`,
  `Building` en `wall_stone` et `roof_slate`, au faîtage) ; pas de terrasse. Avec la caméra
  actuelle le toit sort du cadre dès qu'on est dans la cour.

## H2 — une vue de la cour dans `tools/hd2d_shots.sh` (H8)
- Besoin : les vues `village` (−5, −2,5) et `dialogue` cadrent le quart nord-ouest ; le grand
  arbre, le linge, le potager et l'aire de jeux n'y entrent pas.
- Proposition : une vue `cour` depuis le Spawn du village (0, 9), qui montre le puits, les deux
  cordes à linge, le potager, les bancs et l'entrée des chemins ; éventuellement une vue
  `arbre` (9, −8) pour le grand arbre, la balançoire et la remise.
- En attendant : captures faites à part par H2 (planches `build/shots/h2_avant_apres_*.png`).

## H2 — battants du portail de la palissade (H1, image livrée)
- Besoin : dans `assets/hd2d/props/palisade_gate.png` livrée (PR n° 3), les deux battants sont
  dessinés entrouverts au milieu du portail : le passage dessiné ne fait qu'un mètre (x −0,52 à
  +0,54 m de l'ancre) alors que le chemin fait 3 m et que la collision laisse 2,5 m entre les
  poteaux (±1,49 m, au droit des poteaux dessinés). On traverse les battants en passant.
- Proposition : redemander l'image, 384 × 288 px, « portail de bois à deux montants et linteau,
  lanterne de cristal suspendue, battants grands ouverts rabattus contre les montants (passage
  libre de 2,5 m au moins entre eux) ».
- En attendant : collision aux seuls poteaux ; `test_village_decor.gd` garde 1,2 m libres de part
  et d'autre de l'axe de chaque portail.

## H2 — cour de l'entrepôt et caméra (H5)
- Besoin : `test_village_decor.gd` lit `pitch_deg`, `fov_deg`, `distance` et `focus_height` dans
  `camera_rig.tscn` pour vérifier qu'aucun PNJ ne reste caché en marchant
  (`test_no_npc_stays_hidden_while_walking_the_yard`) ; un autre cadrage déplace ce que cachent
  les arbres du premier plan.
- Proposition : après un changement de cadrage, relancer
  `tools/test.sh tests/unit/test_village_decor.gd` ; le message nomme le PNJ, l'image du décor en
  cause et la place du joueur, à corriger dans `village.tscn` (H2). La cheminée
  (`WarehouseChimney`, faîtage à 10,1 m) n'apparaît que si le cadrage montre le toit.
- En attendant : vérifié avec la caméra du socle (32°, 30°, 21 m) et les images livrées.
## H7 Combat — secousse de l'écran dans `CameraRig` (H5)
- Besoin : la secousse et l'arrêt sur image sont réglés pour la caméra fixe, mais
  `src/player/camera_rig.*` est à H5 : `CameraRig` n'a pas d'API de secousse.
- Proposition : `CameraRig.shake(strength_m: float, direction: Vector3)` (décalage amorti, sans
  rotation, borné), que `ScreenShake` appellerait ; ou la règle « `Camera3D.h_offset` et
  `v_offset` appartiennent au combat » écrite dans PLAN.md section 3.
- En attendant : `src/combat/screen_shake.gd` (nœud `Combat/ScreenShake` du joueur) décale
  `Camera3D.h_offset` / `v_offset` de la caméra courante, que `CameraRig` ne règle pas (il ne pose
  que `global_transform`) ; il ne rend à zéro qu'un décalage qui est encore le sien. Si H5 se
  sert de ces décalages (cadrage, verrouillage), passer la secousse par son API.

## H7 Combat — ombre des personnages (`src/visuals/`, H6 et l'intégration des planches)
- Besoin : des ombres au sol nettes sous les combattants ; l'ombre du `CharacterVisual`
  (« Shadow », dégradé doux) ne se voit presque pas sur le sable et l'herbe, mais `src/visuals/`
  n'est pas à H7.
- Proposition : quand `CharacterVisual` sera repris, garder une seule ombre par personnage : soit
  l'ombre du Visual prend l'image nette `src/combat/fx/shadow.png` (cœur sombre, bord net, rien
  qui dépende du dessin), soit elle s'efface sous un combattant qui a la sienne.
- En attendant : les combattants ont leur `GroundShadow` (`CombatFx.make_shadow`), à la taille de
  leur corps (capsule × `EnemyData.scale`), posée juste au-dessus de l'ombre douce, qui reste là ;
  celle du joueur reste au sol pendant un saut.

## H7 Combat — marqueur de cible du HUD
- Besoin : le verrouillage se lit maintenant au sol (réticule `Combat/LockRing` sous la cible,
  chevron `Combat/AimMarker` devant le joueur) ; le triangle du HUD (`hud.gd`,
  `_update_lock_marker`, L10) se pose à la hauteur de la tête et peut cacher l'éclat de
  préparation du Timere verrouillé.
- Proposition : relever le triangle de 0,2 m (`_marker_height` : `height_m × scale + 0.5`), ou le
  retirer au profit du réticule au sol.
- En attendant : l'éclat de préparation se pose à 85 % de la hauteur du corps, sous le triangle.
## H5 — les planches des personnages scintillent encore
- Besoin : les `AnimatedSprite3D` des personnages et des Timeres (`src/visuals/`, H6 ; Timeres :
  H7) restent au plus proche voisin ; une planche de 144 px s'affiche sur ~97 px en 1280 × 720 :
  leurs pixels sautent quand ils marchent ou que la caméra glisse, comme le décor avant H5.
- Proposition : un `material_override` (ShaderMaterial, `render_mode unshaded` ou éclairé, alpha
  découpé, billboard Y) qui échantillonne la planche par `pixel_art()` de
  `src/world/shaders/pixel_art.gdshaderinc` (sampler `filter_linear`), et pour l'ombre,
  `DecorPanel.shadow_material()` / `shadow_mesh()` (même tache douce que le décor, 55 %).
- En attendant : rien dans `src/visuals/` ; le décor et le sol sont traités.

## H5 — contrats à mettre à jour dans PLAN.md section 3 (ajouts, rien de retiré)
- `Building.GROUP` (`&"hd2d_buildings"`) : chaque Building en jeu y est ; la caméra cadre leur
  façade sud.
- `CameraRig` : `limits` vaut Rect2(−71, −70, 142, 136) ; même API, cadrage des façades (le
  tangage descend jusqu'à 24° devant un bâtiment : `pitch()` rend le tangage courant,
  `pitch_deg` reste le réglage) et bande nette du flou posée à chaque image (constantes `FRAME_*`
  et `BAND_*`, pas d'export ajouté).
- Nouvelle classe `HD2DLighting` (`src/world/materials/hd2d_lighting.gd`) : `apply(island)`,
  `apply_post(material)`, `for_phase(phase)`, `active_sprite_tint()`, réglages
  `lighting_sunset|dusk|night.tres` ; nœud `Lighting` d'island.tscn (`day_phase_lighting.gd`),
  qui les pose sur `EventBus.day_phase_changed`.
- `CameraRig` écoute `EventBus.dialogue_started` / `dialogue_ended` (cadrage en conversation).
- `post_fx.gdshader` : `focus_center` et `focus_half` sont posés par la caméra ; `focus_soft` est
  retiré ; nouveaux uniformes d'étalonnage (`shadow_tint`, `highlight_tint`, `split_strength`,
  `haze_*`, `sun_*`, `glow_tint`).

## H5 — les personnages restent en plein jour la nuit
- Besoin : les planches (`AnimatedSprite3D` de `src/visuals/`, H6 ; Timeres : H7) ne sont pas
  éclairées ; sous le réglage de nuit (`lighting_night.tres`, posé quand l'histoire émet
  `EventBus.day_phase_changed(&"night")`), le décor s'assombrit et bleuit mais les personnages
  restent aussi clairs qu'au couchant.
- Proposition : `CharacterVisual` multiplie `Sprite.modulate` par
  `HD2DLighting.active_sprite_tint()` à `_ready` et sur `EventBus.day_phase_changed` (appelé
  après le nœud `Lighting` de l'île : `call_deferred`) ; blanc au couchant, rien ne change dans
  l'acte 1.
- En attendant : rien ne change de jour ; la nuit n'est pas encore jouée.
## H1 — marge du budget de l'export Web : réglé
- Le budget passe à 60 Mo compressés (docs/DECISIONS.md, « Budget Web relevé ») : la marge n'est
  plus nécessaire ; exclure les tuiles de sol de l'export reste un gain possible (1,1 Mo).
## H9 — la découpe du village et les nouveaux formats
- Besoin : `test_village_decor.gd` (H2) exige que chaque mesh fondu de `village/Geometry` porte
  un matériau de la découpe (`see_through.gd`), qui ne convertit que `panel.gdshader`. Un décalque
  au sol (`ground_decal*.gdshader`) ou un panneau de premier plan (`panel_foreground.gdshader`)
  posé dans la cour le fera échouer.
- Proposition : le test ne compte que les meshes dont le matériau d'origine est de
  `panel.gdshader` ; les décalques restent entiers (au sol, ils ne cachent rien), le premier plan a
  son propre effacement autour du joueur.
- En attendant : rien de neuf dans le village ; à régler avant la pose.
## H9 — cahier n° 2, section 17 (H10)
- « Île n° 53 au sud visible depuis le quai » : la caméra regarde toujours le nord, le sud est
  derrière elle ; l'île n° 53 (`Island53`, z = +560) ne se voit que dans la vue d'ensemble. À
  corriger : la poser au nord (au-delà du bord nord) ou la réserver à une cinématique.
- « Trois à six nuages » partout (section 14) : le haut de l'écran est à 17° sous l'horizon ; le
  ciel et ce qui flotte au-delà du bord ne se voient qu'au bord nord de l'île (bois). Les nuages
  ont la palette de la mer de nuages (pêche, lavande) : sans base plus sombre ou plus contrastée,
  ils s'y fondent (vu dans `demo_formats`).

## H10 — dirigeables du cahier n° 2 : densité et place (phase de pose)
- Besoin : `assets/hd2d/props/airship_ferry.png` (1344 × 672) et `airship_barocupot.png`
  (2304 × 1056) sont maintenant à 96 px/m (cahier n° 2, section 11), et leurs hélices sont des
  bandes à part (`assets/hd2d/anim/airship_*_propeller.png`, 4 images, 12 images/s, moyeu au
  centre de l'image). Les scènes `src/world/props/airship_ferry.tscn` et
  `airship_barocupot.tscn` gardent `pixels_per_meter = 48.0` : les navires s'affichent deux fois
  trop grands (28 m et 48 m), amarrés au sud du quai, hors du champ de la caméra.
- Proposition : `pixels_per_meter = 96.0`, navires de flanc à l'est et à l'ouest du quai (le
  Barocupot à son pylône `mooring_tower`), pales posées sur les moyeux (au milieu de la coque du
  passeur ; au tiers et aux deux tiers du Barocupot, à mi-hauteur de la coque).
- En attendant : rien ne change dans le jeu (navires hors champ).

## H10 — atlas du sol à 27 tuiles (H9)
- Besoin : l'atlas fait 7 rangées (1536 × 2688 px, ordre du contrat commun) ; le shader du sol
  doit déduire le nombre de rangées de la taille de l'atlas (contrat commun, point 6).
- En attendant : `ATLAS_ROWS = 7.0` dans `src/world/shaders/terrain.gdshader` et taille attendue
  1536 × 2688 dans `tests/unit/test_hd2d_decor.gd` (deux lignes, commit à part de H10) ; à la
  fusion, garder la version de H9.

## P0 — panneaux en alpha doux (moteur, H5 ou H9)
- Besoin : `DecorPanel` découpe toujours l'alpha à 0,5 (`panel.gdshader`, `ALPHA_SCISSOR`). Les
  images « alpha doux » posées en panneau perdent leur dégradé : fumée (`chimney_smoke`), vapeur
  (`furnace_steam`), cascade (`edge_waterfall`), nuages (`cloud_*`) deviennent des taches à bord
  net, et ce qui est plus pâle que 50 % disparaît tout entier : rais de lumière (`light_shaft_*`,
  15 à 35 %) et bande de brume (`mist_band`) sont invisibles dans `demo_props_monde`.
- Proposition : `DecorPanel.soft_alpha` (comme `GroundDecal`) : matériau mélangé, sans écriture de
  profondeur, priorité de rendu au-dessus des panneaux nets ; les scènes du cahier n° 2 dont
  l'image est marquée `soft_alpha` dans le manifeste l'activeraient (`tools/hd2d_scenes.py` :
  une ligne).
- En attendant : les scènes existent au bon format ; le ciel qui dérive (`SkyDrift`) mélange déjà
  ses nuages ; les rais de lumière et la brume ne se posent pas.

## P0 — dirigeables du cahier n° 2 : densité et hélices réglées (suite de la demande de H10)
- Fait : `airship_ferry.tscn` et `airship_barocupot.tscn` à 96 px/m, hélices posées sur les moyeux
  (docs/DECISIONS.md, « P0 — navires à quai »).
- Reste pour la pose : les amarrer de flanc à l'est et à l'ouest du quai, dans le champ de la
  caméra (ils sont encore au sud du quai, hors champ, dans `beach.tscn`).

## P0 — tests/unit/test_hd2d_decor.gd (H5, H9)
- Touché par P0 (quelques lignes) : les scènes du cahier n° 2 (métadonnée `hd2d_category`) ne
  sont plus vérifiées par sa liste `NON_BLOCKING` ni par sa règle de densité (noms en `island`,
  `airship`, `floating`) : `test_hd2d_scenes.gd` le fait d'après la table de
  `tools/hd2d_scenes.py` et le manifeste ; `MAX_IMAGES_PER_ZONE` passe de 40 à 48 (44 au port avec
  les flancs et les hélices). La pose le dépassera : à régler par H5 sur les draw calls mesurés.
## P0 — alpha doux des panneaux debout : réglé
- `DecorPanel.soft_alpha` (docs/DECISIONS.md, « Alpha doux des panneaux debout »).
## P3 — dirigeables à quai : réglé
- Amarrés de flanc au-delà du bord, de part et d'autre du quai (docs/DECISIONS.md, « P3 — navires
  à quai ») ; les scènes partagées `airship_*.tscn` ne changent pas.

## P3 — pavés de la rue du Port jusqu'aux façades (moteur, H5 ou H9)
- Besoin : le masque `m.street` de `terrain.gdshader` pave z = 43 à 47 (monde) ; les façades du
  rang nord sont à z = 41,5 : il reste 1,5 m d'herbe devant les boutiques (trottoir en herbe).
- Proposition : étendre la rue au nord jusqu'à z = 41,3 de x = −34 à 34 (hors du chemin de
  l'entrepôt), ou un masque « trottoir » de dalles.
- En attendant : bordures d'herbe (`grass_edge_*`) le long de la rue, terrasses et étals sur
  l'herbe.

## P3 — plafond d'images par zone (H5, `test_hd2d_decor.gd`)
- 132 matériaux au port pour un plafond de 140 : la variété demandée (3 à 6 variantes par
  famille, flancs, détails) le touche. Proposition : compter les matériaux par vue (le budget
  réel, ≤ 200 draw calls, est loin : 70 à 110 au port).

## P1 — premier plan : une mise à jour par image, pas un `_process` par panneau (H9, moteur)
- Constat : chaque `DecorPanel` de premier plan garde son `_process` (qui appelle
  `update_foreground`, une fois utile par image) ; les bois en ont environ 170 (arbres en variante
  `<arbre>_forest`, premier plan) : 170 appels de script par image pour rien, sensibles sur le Web.
- Proposition : que le PropBatcher (ou un seul nœud) appelle `DecorPanel.update_foreground` une
  fois par image, et que les panneaux fondus coupent leur `_process`.

## P1 — cascade de l'île (`Island/Waterfall`, H5)
- Constat : `IslandRock.WATERFALL_ANGLE` (−2,3) pose le ruban à (−58,4 ; −65,4) (monde), 5 m à
  l'est de la sortie du ruisseau (−62,5 ; −62,5, angle −3π/4 ≈ −2,356) ; depuis la caméra du jeu, on
  ne le voit pas (voir ci-dessous : la cascade des bois est à poser sur le nouveau bord).
- Proposition : aligner l'angle sur la sortie du ruisseau (−2,356), ou retirer le ruban.

## P1 — habiller le nouveau bord des bois (lot B1 ou suite de la pose)
- Fait par P1 : rien dans les 4 derniers mètres avant le bord actuel des bois (lisières à 4,8 m de
  la lèvre), à la demande de l'orchestrateur, pour que B1 rende le bord irrégulier.
- Reste : la cascade du ruisseau (`edge_waterfall`, au droit de la sortie du ruisseau, vers
  (−62,5 ; −62,5) monde ; la caméra, qui regarde le nord, n'en voit que le haut : 3 à 4 m au-delà
  de la lèvre, ancre à y = 0, elle montre sa lèvre de pierre et le départ de l'eau), les pierres et
  l'herbe de la lèvre (`edge_rocks_*`, `edge_grass`, de face sur le bord : `keep_orientation` au
  lacet du bord) et les racines (`edge_roots`, 2,5 m au-delà) dans les deux fenêtres sur le vide
  (nord-ouest x −66 à −52 ; nord-est x 62 à 70, local aux bois), sur les nouveaux caps.
## P2 — la découpe du village et les nouveaux formats : réglé
- `see_through.gd` ne convertit que `panel.gdshader` ; `test_village_decor.gd` ne compte que ces
  meshes et vérifie que décalques, premier plan et alpha doux gardent leur shader
  (docs/DECISIONS.md, « P2 — découpe et formats »).
## P2 — images de la cour (H1, ChatGPT)
- Besoin : (1) les pans de `treeline_autumn_*` sont coupés droit pour se raccorder : au portail
  nord, où la lisière s'ouvre sur le chemin des bois, le bord coupé se voit au-dessus de la
  palissade (deux jeunes sapins le masquent en partie) ; (2) `chimney_brick` est dessinée sur un
  pan de tuiles rouges, qui jure sur l'ardoise de l'entrepôt ; (3) la clôture basse du potager
  n'existe que de face.
- Proposition : (1) `treeline_autumn_end_l.png` et `_r.png` (768 × 768 px, lisière qui se
  termine par un arbre entier du côté du passage, raccordable de l'autre côté) ; (2)
  `chimney_brick_slate.png` (96 × 192 px, même cheminée, base sur ardoise bleu-gris) ; (3)
  `fence_low_side.png` (77 px de haut, la clôture vue de profil, comme `palisade_side`).
- En attendant : pans coupés au portail, cheminée en matières (`warehouse_chimney.tscn`,
  `wall_brick`), potager fermé devant et derrière seulement.

## B1 — bornes de la caméra (H5, `src/player/camera_rig.gd`)
- Besoin : le bord avance jusqu'à ±79,2 m (côte nord jusqu'à z ≈ −78,6, Couchant x ≈ −78, colline
  x ≈ 78, éperon nord-est (58,7 ; −75,1)) ; `limits` = Rect2(−71, −70, 142, 136) arrête le point
  visé à 7 à 9 m du joueur qui se tient sur la lèvre : il descend vers le bas de l'écran.
- Proposition : `limits` = Rect2(−75, −75, 150, 141) (le point visé suit le joueur jusqu'à 4 m de
  la lèvre ; au sud, le quai ne bouge pas).
- En attendant : le joueur reste à l'écran partout (captures `b1_apres_*`).

## B1 — habillage du nouveau bord (lots de pose : bois, Couchant, colline, port)
- Le bord a bougé (docs/lore/MONDE.md 2.8, docs/DECISIONS.md « B1 ») ; pour poser au bord, lire
  `IslandTerrain.edge_point(angle)`, `IslandEdge.normal(angle)` (vers le vide) et
  `IslandTerrain.distance_to_edge(x, z)` ; tests/unit/test_world_edge_margins.gd vérifie les
  marges (1 m pour un décor, 3 m pour ce qui bloque), mobilier du bord (`edge_*`…) exempté.
- Avancées nouvelles, à habiller (pierres, racines, herbe de la lèvre) : éperon du nord-est
  (pointe en (58,7 ; −75,1), +10 m) ; caps de part et d'autre de la cascade ((−51,6 ; −76,5) et
  (−78,3 ; −48,9), +7 m) ; cap du sud-ouest ((−74,3 ; 62,4), +7 m) et cap au sortir ouest du port
  ((−55,5 ; 76,4), +6 m) ; caps du sud-est ((77,2 ; 41,0) et (52,2 ; 74,5), +5 m) ; cap de la côte
  est sous l'éperon ((75,5 ; −43,6), +5 m) ; replat devant la ruine du Couchant ((−77,1 ; −0,7),
  +1,6 m). Partout ailleurs, la côte ondule de 0 à 3 m au-delà de l'ancien bord.
- Le bord recule (anses) : au sud du Couchant, autour de (−73,9 ; 30,6), jusqu'à 2,2 m en deçà de
  l'ancien bord (secteur 150° à 165°) ; ailleurs, jamais plus de 0,3 m (ébréchures, sud-est).
- Mobilier resté à l'intérieur : les parapets du Couchant (dunes, `Parapets` : 1,6 à 1,8 m de la
  lèvre pour les trois du milieu et du nord, 0,6 et 0,9 m pour les deux du sud, près de l'anse) et
  du pied de la colline (hill, `Parapets` : 1,6 à 2,4 m) étaient à 0,7 m de l'ancienne lèvre : à
  reposer sur la nouvelle. Le garde-corps et les bittes du quai ne bougent pas.
- La cascade (`Island/Waterfall`) tombe désormais au bout du lit du ruisseau, en (−62,1 ; −62,4)
  (`IslandEdge.WATERFALL_ANGLE`) : l'image `edge_waterfall` se pose là, sous la lèvre.

## E2 — sol en relief des cartes (pour E1, E9, E10 et le propriétaire de `GroundDecal`)
- **E1 (fusion)** — *fait par E2 à la fusion d'E1* : `essai_relief.tscn` a pour racine
  `res://src/world/map.gd`, le remplaçant `tests/stubs/e2_map_stub.gd` est retiré, et la carte
  passe `tests/unit/test_maps.gd`. Son `Ground` est un `MapGround` qui lit `data/maps/<nom de la Map>/`.
- **E1** — *fait par E1* (`CameraRig.limits` ← `WorldManager.camera_bounds()`). Reste à savoir :
  une sortie `MapExit` d'une carte extérieure se pose en deçà du bord, une barrière invisible
  (couche 1) borde la carte sur ses bords « land » et le long du vide.
- **E1 / H8** : mesurer le chargement d'une carte en relief dans le build Web (lecture des images
  par `Texture2D.get_image()`, construction : 35 à 40 ms sans écran pour 80 × 60 m).
- **`GroundDecal.follow_ground`** (src/world/ground_decal.gd) — *fait par E2, avec l'accord du
  coordinateur* : il drape sur le `MapGround` de sa carte (`MapGround.triangles_in`), sinon sur
  `IslandTerrain`. Seule retouche de `ground_decal.gd` (`_ground_triangles`) ; ses caches restent
  à E1.
- **E9** : quand la lumière change (moment de la journée, préréglage d'une carte), appeler
  `MapGround.set_sun(direction vers le soleil)` ; au chargement, `MapGround` suit la première
  `DirectionalLight3D` de la scène (ombres portées des falaises dans le shader du sol).
- **E4 / E5 (navigation)** : `MapGround.is_walkable(x, z)` (eau dormante exclue, vide exclu),
  `height_at`, `level_at` ; les PNJ ne sautent pas les marches de 0,5 m (`tools/map_build.py check`
  dit lesquelles ne s'atteignent qu'en sautant).
## E3 — intérieurs (cartes : E1 ; lumière : E9 ; sol : E2)
- Fait à la fusion avec E1 (commit 7c13393) : racine `Map`, sortie `MapExit`, stubs locaux
  retirés ; `test_maps.gd` vert pour `entrepot_rdc_essai`.
- Sorties de l'étage d'essai à rebrancher quand les cartes existeront : `vers_entrepot` vise le
  `Spawn` de `ile_ancienne` (à faire viser `entrepot` / `from_entrepot_rdc_essai`) ; la porte rivetée
  (`id` « crypte », `door_position(&"crypte")`) recevra sa `MapExit` « Descendre » vers
  `entrepot_crypte` / `from_entrepot_rdc_essai` (marqueur d'arrivée `from_entrepot_crypte` déjà
  posé). Pour y entrer depuis la partie : une sortie dans `ile_ancienne` (porte de l'entrepôt du
  village) vers `entrepot_rdc_essai` / `from_ile_ancienne`, si E1 la veut avant la carte
  `entrepot` (sinon `WorldManager.enter_map(&"entrepot_rdc_essai")` et la démo).
- E9 : `light_preset = &"interieur"` désigne `src/world/materials/lighting_interieur.tres`
  (`HD2DLighting`), posé pour l'instant par l'enfant `Light` de la carte
  (`src/world/interior_light.tscn`). Le moment de la journée d'un intérieur passe par
  `InteriorRoom.apply_phase(phase)` (déjà branchée sur `EventBus.day_phase_changed`),
  `set_daylight(teinte, énergie)` et `set_lamps(énergie)` ; fond des intérieurs :
  `InteriorRoom.VOID_COLOR` (aucun ciel n'est visible).
- E2 : `InteriorRoom` offre `height_at`, `material_at`, `is_walkable` (et `room_at`) comme
  `MapGround` ; à garder alignés si leurs signatures changent.
- Cahier n° 3 (lot I, `docs/ASSETS_HD2D_SUKASUKA.md`, 3.2) : ajouter `door_frame_wood`
  (126 × 221, porte : chambranle de bois seul, seuil usé, **ouverture de 1,1 × 2,2 m
  transparente**) pour les portes qu'on franchit : `door_room` et `door_room_open` sont opaques et
  cacheraient le joueur sur le seuil. En attendant : remplaçant de `tools/hd2d_interior.py`, comme
  `floor_flagstone_cellar`, `wall_cellar_stone`, `wallcut_stone`, `door_armory` et
  `wallitem_height_marks` (prio 2, pas encore livrées).
- Lieux (D2) : la carte d'essai pose la chambre de Nygglatho au rez-de-chaussée, près de l'entrée
  (emplacement original) ; la vraie carte de l'entrepôt suivra le plan de D2.
- Budget de l'export Web (PLAN.md, section 9 ; `tools/build_size.sh`, 100 Mo compressés) :
  `origin/main` (db96511, livraison réelle des lots I et J) le dépasse déjà seul (wasm + pck :
  101,3 Mo compressés, mesuré sur une copie de main) ; la branche E3 y ajoute 0,1 Mo (101,4 Mo).
  `tools/check.sh` est donc rouge à l'export pour toute branche fusionnée avec main, quoi qu'elle
  fasse. À trancher hors E3 : relever le budget, ou ne plus exporter les images que rien
  n'emploie encore (`export_presets.cfg`, PR « contrats »), ou alléger les images livrées.
- (Orchestrateur) Budget de l'export Web : **tranché**, relevé à 150 Mo compressés (PR n° 23,
  `docs/DECISIONS.md`, « Budget Web relevé de 100 à 150 Mo »).
## D2 — images et planches que les documents de lieux demandent (cahier n° 3)

Hors du périmètre de D2 (documents seulement) ; à reprendre par qui tient le cahier n° 3
(`docs/ASSETS_HD2D_SUKASUKA.md`) :

- **Sept noms proposés** par `docs/lore/CARTE.md` (section 12.1), à ajouter au cahier avant toute
  commande : les façades et flancs de l'entrepôt de 30 × 14 m (`buildings/warehouse_front_a`,
  `warehouse_front_b`, `warehouse_front_a_side`, `warehouse_front_b_side`), l'échelle du toit
  (`interior/props/roof_ladder`), le bureau de la grande sœur sans la broche
  (`interior/props/desk_clean`) et le bureau de Chtholly au miroir relevé
  (`interior/props/desk_chtholly_mirror_up`). Tailles et consignes dans la section 12.1.
- **Des gestes `travaille`** pour les habitants déjà livrés (`snack_vendor` : la poêle ;
  `cat_waiter` : le balai ; `baker`) et un geste au marteau pour Willem (le plafond qui fuit),
  que `docs/lore/VIE.md` (section 2) et `docs/lore/ACTE1.md` (scènes 3.3 et 12.1) utilisent avec un
  repli.
- **Les planches de l'acte 1 encore à livrer**, par ordre d'usage dans `ACTE1.md` :
  `chtholly_pajamas` (jour 9), `nygglatho_labcoat` (jour 7), `kana` et `giniette` (jour 10), les
  planches de bâton `_stick` (jours 9 à 11, après accord du lot E8 sur `pare`).
## E9 — les personnages restent en plein jour la nuit (`src/visuals/`, E4 ou H6) — remplace la demande H5
- Besoin : les planches (`AnimatedSprite3D` non ombré de `CharacterVisual`, Timeres compris) ne
  sont pas éclairées ; la nuit, sous la pluie ou dans un intérieur, le décor s'assombrit mais les
  personnages restent aussi clairs qu'au couchant.
- Proposition : `CharacterVisual` multiplie `Sprite.modulate` par `Atmosphere.sprite_tint()` à
  chaque image (la teinte change pendant les transitions ; blanche au couchant et au clair : rien
  ne change dans l'acte 1 tel qu'il est). Teintes : `sprite_tint` des préréglages de
  `data/lighting/` (nuit 0,7 / 0,76 / 0,92), multipliée par celle du temps.
- En attendant : rien ; ils ressortent la nuit, ce qui les garde lisibles.

## E9 — les cartes de E2 et E3 ne portent plus de lumière
- Besoin : `src/world/map_light.tscn` est retiré ; une carte qui l'instancie ne se charge plus.
  Une carte qui porte son propre `WorldEnvironment` ou sa `DirectionalLight3D` est réglée par
  Atmosphere comme l'ancienne île, mais le contrat (docs/REFONTE.md 7.1, PLAN.md « (E9) Lumière
  et temps ») veut qu'elle n'en ait pas.
- Proposition : retirer ces nœuds des cartes `essai_relief` (E2) et `entrepot_rdc_essai` (E3) ;
  E3 : `interior = true` (préréglage `interieur`, qui suit le moment du dehors), lampes et
  cheminées en `OmniLight3D` (énergie de jour : `lamp_energy` les multiplie), fenêtres de nuit
  `<nom>_night.png`.

## E9 — flaques animées sous la pluie (`GroundDecal`, H9 / E2)
- Besoin : `puddle_rain_a|b` (cahier n° 3, lot N : décalques animés) ; `GroundDecal` n'a pas de
  bande animée.
- Proposition : `frames` et `fps` sur `GroundDecal` comme sur `DecorPanel` (phase dans UV2) ;
  les flaques posées par image `puddle_*` ne se montreraient que sous la pluie (HD2DLightTargets
  les réglerait par leur nom, comme les vitres éclairées `window_lit_*`).
- En attendant : sol mouillé et reflets seulement.

## E9 — l'export Web dépasse le budget de 100 Mo depuis les images des lots I et J (`origin/main`)
- Constat : à `db96511` (`origin/main` : `c2b12aa` plus les images livrées des lots I et J du
  cahier n° 3, sans code), `tools/build_size.sh` mesure 101,3 Mo compressés (wasm + pck) : le
  `tools/check.sh` complet est rouge à l'étape « export web » avant tout lot de la refonte. E9 y
  ajoute 0,1 Mo (cinq images de remplacement du lot N, 40 ko de PNG ; 101,4 Mo).
- Proposition : trancher ce que la section 8 de docs/REFONTE.md annonçait (« le Web dépasserait
  les 100 Mo ») : budget relevé (PLAN.md section 9, `tools/build_size.sh`), ou version Web allégée
  (images en WebP avec perte pour le seul Web), ou exclusion de l'export Web des images pas
  encore posées (filtre d'`export_presets.cfg`, PR « contrats »).
- En attendant : `BUILD_BUDGET_MB=110 tools/check.sh` vérifie tout le reste (vert pour E9).

## R1 — raccord de la lumière (suites des demandes E2, E3 et E9)
- *Fait* : « E9 — les personnages restent en plein jour la nuit » (`CharacterVisual` pose
  `HD2DLighting.active_sprite_tint()`, quelques lignes, la couleur d'un ennemi gardée) ;
  « E9 — les cartes de E2 et E3 ne portent plus de lumière » pour `entrepot_rdc_essai`
  (`interior_light.tscn` retirée ; les lampes restent les `lights[]` d'`interior.json`, sans
  `OmniLight3D`) ; « E2 — E9 appelle `MapGround.set_sun` » (à chaque pose et transition).
- Cahier n° 3, lot N (images) : les fenêtres de nuit livrées (`window_cross_small_night`,
  `window_cross_large_night`, `window_reading_seat_night`) se posent seules la nuit ; une
  fenêtre sans image de nuit (`window_curtains_open`, `window_bare`…) est assombrie et bleuie par
  `interior_panel.gdshader` (`night_view`) en attendant la sienne.
- Pour les lots qui construisent des intérieurs (T2…) : une carte intérieure ne porte aucune
  lumière (ni `Light`, ni `WorldEnvironment`, ni `DirectionalLight3D`) ; ses lampes sont les
  `lights[]` de son `interior.json` ; `InteriorRoom.apply_phase` n'est plus qu'un passage vers
  `Atmosphere.set_moment`.
## T2 — images et préréglages pour l'entrepôt
- `roof_ladder` (échelle du couloir de l'étage vers le toit) : absente du cahier n° 3 ;
  remplaçant à la taille du plan, 77 × 288 px (0,8 × 3,0 m), lot I de `tools/hd2d_manifest.json`.
  À ajouter au cahier.
- `floor_roof_deck` et `roof_edge_slate` (« à confirmer », CARTE.md 3.3) : le toit se fait sans
  eux (matière `planches`, toit `roof_slate` d'un `Building`) ; à trancher au cahier.
- Préréglage `noir` (CARTE.md 3.4, salle des armes sans lumière) : absent de `data/lighting` (E9) ;
  la carte prend `interieur` en attendant.
- Halo des appliques `wallitem_crystal_sconce` (GLOWS d'`InteriorRoom`) : la lumière d'une
  applique est déclarée en carte de lumière, mais l'image elle-même ne luit pas ; à voir avec R1.
- Remplaçants encore en place (cahier n° 3, lot I) : `anim/drying_frame_wave`, `anim/leak_drip`,
  `anim/pot_steam`, `decals/bath_puddles`, `decals/cards_floor`, `decals/clothes_floor`,
  `decals/papers_floor`, `decals/runner_rug`, `interior/props/piano_old`, `interior/props/roof_hatch`,
  `interior/props/roof_ladder`, `interior/props/roof_railing_broken`, `interior/wallitem_clippings`,
  `interior/window_dusty`.
## T1 — L'entrepôt vu du dehors
- **CARTE.md 12.1, `warehouse_front_a_side`** : la consigne met la porte de service « à 8 m de
  l'angle sud » ; les données (2.7 : sortie z 19,4 → 20,6 ; 2.4 : « (30 ; 20) dehors ») la mettent
  à 6 m. Le remplaçant suit les données (6 m). À corriger dans 12.1 avant la commande (lot D2).
  Au passage, 2.4 écrit « (1 ; 9,5) dedans » pour (30 ; 20) dehors, alors que dedans = dehors −
  (29, 11) donne (1 ; 9) : le couloir du dedans est centré sur 9,5.
- **E2, faces des paliers** : `cliff/step_earth`, `wall_earth_1m` et `step_marsh` (cahier n° 3, 7.6)
  ne sont pas encore lus par `MapGround` (un seul talus, `bank_earth.png`) : une couleur de
  `structures.png` par face nommée permettrait de les poser (berges de tourbe au marais).
- **Manifeste, lot I** : `interior/props/roof_railing.png` et `drying_frame.png` (livrées) sont
  posées dehors sur le toit-terrasse ; leur entrée au manifeste est laissée au lot I (T2).
- **Cahier des façades (CARTE.md 12.1), vitres** : les panneaux s'allument la nuit par les pixels
  proches de `glow_color` (#FFE6A6, `panel_core.gdshaderinc`, fois `window_glow`) ; les vitres de
  `warehouse_main` (#ECBF79) n'en sont pas assez près et restent éteintes la nuit. Les
  remplaçants de T1 repeignent leurs vitres près de #FFE6A6 : à dire au dessinateur des vraies
  façades (ou un masque de lueur par image, PR « contrats »).
- **Tests rouges hérités d'`integ-monde` (f393bb1, avant T1)** : `test_interior_entrepot`
  (« préréglage » 0,568 au lieu de 0,34) et `test_interior_in_game` (« étalonnage ») échouent dans
  la suite complète, déjà sur f393bb1 seul : la lumière d'Atmosphere habille la carte d'essai
  intérieure par-dessus `interior_light`. Le raccord est la mission de R1 ; T1 n'y touche pas.
## X1 — îles et surface : ce que les lots suivants adoptent
- **Toute nouvelle carte** (C-sentier, C-village, C-port, C-colline, C-foret, C-ville,
  C-montagne, E7) : l'ajouter à la liste `maps` de son île (`data/world/islands/ile_68.json`) et,
  si c'est un lieu de la carte de l'île, aux `maps` de son lieu (`places`, dont l'id est la
  `region` de la carte) ; `Map.island` vaut `ile_68` par défaut. `tests/unit/test_world_atlas.gd`
  refuse une carte rangée nulle part.
- **C-port** : la carte `port` reprend le port de l'île n° 68 : dans `ile_68.json`, `ports.essai`
  (ou un nouvel id, et les quais qui le visent) passe sur `port`, marqueur `from_dirigeable` au
  quai, avec un `AirshipDock` sous un nœud `Docks` ; les deux quais provisoires de `essai`
  peuvent alors partir.
- **E7 (navires)** : les dirigeables à quai et leurs intérieurs (`transport_garde`, `barocupot`)
  sont des cartes d'une île (celle du port) ; « Monter à bord » reste une `MapExit` ;
  `AirshipDock` (ou le récit) lance `WorldManager.travel(île, port)`. La vue du voyage
  (`src/world/travel_view.tscn`) peut prendre le navire du port de départ au lieu du ferry.
- **E4 (la vie)** : ses données vont dans `data/life/ile_68/` (`WorldAtlas.data_path("life",
  &"ile_68", "<fichier>")`, ou `data_dirs("life", île)` pour lister) ; tant que les fichiers sont
  à la racine de `data/life/`, `find_data` les trouve encore. Migration : un `git mv` vers
  `data/life/ile_68/`, sans autre changement si le code passe par `find_data` / `data_dirs`.
- **E5 (faune)** : `data/fauna/<island_id>/` pour ce qui est propre à une île (ou `data/fauna/` pour
  les espèces communes) ; avant de faire apparaître un animal, demander
  `WorldAtlas.rules_for(map_id).fauna` (liste vide pour l'instant : la remplir dans
  `ile_68.json`, `rules.fauna`, ou par lieu si E5 en a besoin : clé à ajouter par PR « contrats ») ;
  un animal qui réutilise `Enemy` doit passer outre sa garde des Timeres (`enemies_allowed`), par
  exemple par une classe fille ou un drapeau d'`EnemyData`.
- **E6 (récit)** : les scènes et textes propres à une île dans `data/<kind>/ile_68/` (scènes :
  `data/scenes/ile_68/` si E6 garde ce nom ; textes : `data/texts/ile_68/`). `data/texts/story.json`
  (textes des systèmes) reste commun ; `data/texts/entrepot.json` (T2, `Examinable.texts_path`)
  rejoindra `data/texts/ile_68/entrepot.json` avec la migration (défaut d'`Examinable` à changer
  dans la même PR). Les voyages se déclenchent par `WorldManager.travel(île, port)` ; écouter
  `EventBus.island_entered` ; `GameState.island` et `known_islands()` sont sauvegardés.
- **E6 / début de partie** : `WorldManager.START_MAP` reste `ile_ancienne` ; la carte d'arrivée
  de l'île n° 68 (`arrival_map` : `entrepot`) est là pour le début de partie à l'entrepôt.
- **Images (cahier, surface)** : une face de falaise grise (`cliff/` pour la surface) et des décors
  de la surface sans mousse ni automne (roches, ruines, épaves) ; en attendant, les terres grises
  teintent les leurs.

- **C1 — premier plan suspendu** (E10, cahier n° 5, section 5.1 : `fg_canopy_a`, `fg_canopy_b`) : un
  panneau accroché en haut de l'écran au-dessus du joueur (une couche de l'interface, ou un
  `DecorPanel` qui suit la caméra). En attendant, les voûtes du sentier sont des panneaux de premier
  plan posés en l'air à 2,6 m (`tools/exterior_recipes/sentier.py`, `CANOPY_LIFT`), qui s'effacent
  devant le joueur ; quand le moteur les accroche à l'écran, les retirer de la recette.
- **C1 — préréglage `nuit_sans_lune`** (E9) : CARTE.md (4.2) l'appelle pour le sentier, il n'existe pas
  (`data/lighting/` : `nuit` seulement, une nuit claire). Le sentier de nuit de l'acte 1 (jour 1 :
  « on ne voit pas ses pieds ») le demande : plus sombre que `nuit`, la lumière des fées du joueur
  restant seule à éclairer. Mesure du sentier avec `nuit` dans docs/DECISIONS.md (C1) : l'écran à 0,12,
  autour du joueur 0,2 avec sa lumière. Une fois le préréglage posé, c'est le moment de la scène (E6) qui
  le choisit, ou `light_preset` de la carte (un écart : la carte serait noire aussi les autres nuits).
- **C1 — images du lot R3 livrées** : quand le cahier livre `marsh_reed_wall`, `path_edge_ferns`,
  `path_root_step`, `fg_canopy_a`, `bog_pool_a`, `path_stones_a/b`, elles remplacent les remplaçants
  du même nom (même taille) sans toucher au code ; retirer alors leurs recettes de
  `tools/hd2d_sentier.py` et leurs entrées du manifeste (lot I1).
- **C1 — sortie `vers_ville` du sentier** : la carte `ville_haute` (C-ville) n'existe pas ; sa
  sortie s'écrit d'elle-même dès qu'elle existe (`python3 tools/exterior_maps.py gen sentier`, qui retire
  aussi l'écriteau) ; elle demande le marqueur `from_sentier` dans `ville_haute`.
## E4 — la vie : poses et planches manquantes (cahier n° 3), et suites
- **`chtholly_home` sans combat** : la planche livrée (repos, marche, parle, course, frappe, assis,
  lit, dort, hanches) n'a ni `attaque`, ni `charge`, ni `degats`, ni `mort` : le joueur ne peut pas
  la porter dans l'entrepôt (on y frappe encore de l'épée). Ajouter ces rangées à
  `chtholly_home` (sans arme ? avec un bâton ?) ou décider qu'on ne se bat pas dedans
  (`LifeDirector.player_home_outfit` la posera seule).
- **Pas de pose empilée ni de pose « collée à une porte »** : la tour de fées décale les sprites
  `assis` et `grimpe` en hauteur ; l'avalanche part de `repos` tourné vers la porte. Deux poses
  aideraient (cahier n° 3, lot J, prio 3) : `pile` (assise à califourchon sur des épaules, vue de
  face) et `epie` (penchée, l'oreille contre une porte, vue de dos).
- **`nygglatho_tea` n'a pas de `marche`** : elle se déplace en `porte` (le plateau) ; acceptable.
  `nygglatho_life` complète la planche de base sans `parle` ni `marche` (pris à `nygglatho`).
- **Gestes `travaille` des fées génériques** : `toilette` et `balayer` retombent sur `parle` ou
  `repos` faute de planche ; les pyjamas des génériques (`fairy_02_pajamas`, prio 3) manquent.
- **E6 (récit)** : `GameState.day` est ajouté (0 par défaut) pour qu'E6 le tienne ; le créneau se
  pose par `LifeDirector.set_slot` ; une scène qui déplace des personnages peut prendre la main
  par `LifeDirector.npc(id)` / `spawn_actor` puis `LifeActor.walk_to`, et rendre la main par
  `LifeDirector.refresh(false)`. Les marqueurs de quête « ! » / « ? » restent sur les PNJ de la
  vie qui ont une quête (Nygglatho), jusqu'à leur retrait par E6.
- **V1 (la vie sur les vraies cartes)** : les places de `docs/lore/CARTE.md` (« Points nommés »)
  deviennent des `Marker3D` de `Life/Places` ; les sièges du réfectoire se posent comme dans
  `entrepot_rdc_essai` ; les emplois du temps de VIE.md, section 2, remplacent ceux de
  démonstration (`data/life/`, qui visent les cartes d'essai).
- **E8 (ballon)** : le cadre des jeux (`LifeGame` : `assign_teams`, `formation`, joueur qui entre
  et sort, `on_player_attack`) ; un jeu `src/life/games/ballon.gd` et l'activité qui le nomme.
- **C2 (porte fermée jusqu'au jour 11)** : `MapExit` ne sait pas se fermer. La porte `porte_limashenka` du
  village (maison Limashenka, ouverte au jour 11, ACTE1.md 11.3) porte les métadonnées `open_from_day = 11` et
  `closed_text_key = "village/maison_close"` (texte de `data/texts/village.json`) ; il faudrait que `MapExit`
  (ou le récit, E6) refuse l'invite avant ce jour et lise ce texte. Tant que ce n'est pas fait, la porte
  s'ouvre à tout moment (le test de la vraie partie l'emprunte).
- **C2 (fenêtres allumées la nuit)** : le café n'a aucune lampe de carte (règle V1). Une image
  `window_lit_*` (fenêtres éclairées de nuit) serait à livrer par le cahier d'images si l'on veut que la
  façade du café se lise de nuit.
