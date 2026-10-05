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
