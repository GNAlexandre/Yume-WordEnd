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

## L5 — savoir si une zone est sûre
- Besoin : un Timere abandonne la poursuite quand le joueur est dans une zone `safe` (village).
  Aucune API ne dit si une zone est sûre : Enemy (L5) lit `WorldManager.current_zone()` puis
  `Zone.safe` de la racine du groupe `zones` qui porte ce nom.
- Proposition : `func is_zone_safe(zone_id: StringName) -> bool` dans WorldManager (L2), vrai si la
  Zone `zone_id` a `safe = true` ; Enemy l'appellerait avec `current_zone()`.
- En attendant : lecture défensive de `Zone.safe` via le groupe `zones` (src/enemies/enemy.gd,
  `_player_in_safe_zone`), mise en cache tant que la zone courante ne change pas.
