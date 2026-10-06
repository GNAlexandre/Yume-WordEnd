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
