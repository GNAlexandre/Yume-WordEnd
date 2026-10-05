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
