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
