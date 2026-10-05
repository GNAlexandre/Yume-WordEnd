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
