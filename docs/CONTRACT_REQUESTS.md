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
