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
