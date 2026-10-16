extends Node
## EventBus : tous les signaux transverses du jeu (PLAN.md section 3). Aucune logique ici.
##
## Un système émet ses signaux ici ; les autres les écoutent. Personne ne lit directement les
## nœuds d'un autre système. L'émetteur attendu est indiqué au-dessus de chaque signal.
## Les signaux ne sont jamais émis dans cette classe, d'où l'annotation unused_signal.
## Fichier gelé : ne change qu'au Lot 0 ou dans une PR « contrats » (dernières : E1, cartes ; E9,
## lumière et temps ; X1, îles et surface ; F1, retrait de l'ancienne île : arène, vagues, quêtes
## et zones).

@warning_ignore_start("unused_signal")

# --- Combat -----------------------------------------------------------------------------------

## PV du joueur. Émis par PlayerCombat (L4) à chaque Health.changed du joueur, et une première
## fois en différé (call_deferred) après son _ready pour donner la valeur initiale au HUD.
signal player_health_changed(current: int, max_value: int)
## Le joueur a perdu des PV. Émis par PlayerCombat (L4).
signal player_damaged(amount: int, source: Node3D)
## Le joueur est mort. Émis par PlayerCombat (L4). WorldManager (L2) appelle respawn() après
## WorldManager.respawn_delay.
signal player_died
## Le joueur est réapparu (au marqueur par lequel il est arrivé dans la carte). Émis par
## WorldManager.respawn() (L2) ; PlayerCombat (L4) remet alors les PV au maximum.
signal player_respawned
## Demande de soin du joueur (n'importe quel système) ; PlayerCombat (L4) l'applique avec
## Health.heal().
signal player_heal_requested(amount: int)
## Un ennemi est entré en jeu. Émis par Enemy (L5) dans son _ready.
signal enemy_spawned(enemy: Node3D, enemy_id: StringName)
## Un ennemi a perdu des PV. Émis par Enemy (L5).
signal enemy_damaged(enemy: Node3D, amount: int)
## Un ennemi est mort (points : EnemyData.points). Émis par Enemy (L5).
signal enemy_killed(enemy_id: StringName, points: int)
## Jauge de la charge magique, 0..1. Émis par PlayerCombat (L4).
signal charge_progress(ratio: float)

# --- Monde et interaction ---------------------------------------------------------------------

## Objet ramassé. Émis par Pickup (L7) après GameState.add_item().
signal item_collected(item_id: StringName, quantity: int)
## L'inventaire a changé. Émis par GameState (L7) à chaque add_item / remove_item réussi,
## from_dict et reset.
signal inventory_changed
## Invite d'interaction devant le joueur ("" = aucune). Émis par le joueur (L1).
signal interaction_available(prompt: String)
## Un dialogue commence (le joueur ne bouge plus). Émis par DialogueRunner (L6).
signal dialogue_started(npc_id: StringName)
## Une réplique à afficher ; choices vide = simple « suite ». Émis par DialogueRunner (L6).
signal dialogue_line(speaker: String, text: String, choices: Array[String])
## Réponse de la boîte de dialogue : index du choix, ou -1 pour « suite » sans choix.
## Émis par DialogueBox (L6, src/ui/dialogue_box) ; écouté par le DialogueRunner actif.
signal dialogue_choice_made(index: int)
## Fin du dialogue (le joueur peut bouger). Émis par DialogueRunner (L6).
signal dialogue_ended(npc_id: StringName)
## (E1) Une carte vient d'être posée et le joueur placé dedans (encore sous le fondu au noir
## pendant un go_to). Émis par WorldManager (go_to, enter_map) ; la caméra prend les bornes de
## la carte et se recale, SaveManager demande une auto-sauvegarde.
signal map_entered(map_id: StringName)
## (X1) Le joueur vient d'arriver sur une autre île (data/world/islands/<island_id>.json) : par
## un voyage (WorldManager.travel), une sortie ou le début d'une partie. Émis par WorldManager
## juste après le map_entered de la carte d'arrivée (encore sous le fondu au noir), une fois
## GameState.island et les îles connues mis à jour ; jamais pour une carte hors de toute île.
signal island_entered(island_id: StringName)
## Phase du jour : &"morning", &"day", &"evening", &"night" (M3, cycle jour/nuit). (E9) Ancien
## nom : Atmosphere le traduit en moment (matin, apres_midi, couchant, nuit) ; préférer
## Atmosphere.set_moment ou GameState.moment.
signal day_phase_changed(phase: StringName)
## (E9) Moment de la journée ou temps qu'il fait changé (GameState.MOMENTS, GameState.WEATHERS).
## Émis par GameState quand moment ou weather change (setters, from_dict, reset) ; Atmosphere
## pose la lumière (transition douce, ou immédiate au chargement d'une partie et d'une carte).
signal atmosphere_changed(moment: StringName, weather: StringName)
## Skin actif. Émis par GameState quand GameState.skin_id change ; le joueur (L1) l'applique.
signal skin_changed(skin_id: StringName)
## PV max du joueur. Émis par GameState quand GameState.max_hp change ; PlayerCombat (L4) met à
## jour son Health.
signal max_hp_changed(max_value: int)
## Demande de sauvegarde (n'importe quel système, ex. menu pause). SaveManager (L8) sauvegarde.
signal save_requested
## Une partie est prête (nouvelle partie, Continuer, import). Émis par SaveManager (L8) ;
## main.gd quitte alors le menu et charge src/game.tscn.
signal game_loaded

# --- Récit -----------------------------------------------------------------------------------

## Un drapeau de GameState change de valeur. Émis par GameState.set_flag (pas par from_dict ni
## reset) ; les PNJ revoient leur présence (NpcData.visible_if).
signal flag_changed(flag: StringName, value: bool)

@warning_ignore_restore("unused_signal")
