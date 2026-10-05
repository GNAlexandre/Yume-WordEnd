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
