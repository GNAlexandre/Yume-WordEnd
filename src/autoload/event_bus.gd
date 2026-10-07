extends Node
## EventBus : tous les signaux transverses du jeu (PLAN.md section 3). Aucune logique ici.
##
## Un système émet ses signaux ici ; les autres les écoutent. Personne ne lit directement les
## nœuds d'un autre système. L'émetteur attendu est indiqué au-dessus de chaque signal.
## Les signaux ne sont jamais émis dans cette classe, d'où l'annotation unused_signal.
## Fichier gelé : ne change qu'au Lot 0 ou dans une PR « contrats » (dernière : Lot Q, quêtes).

@warning_ignore_start("unused_signal")

# --- Combat -----------------------------------------------------------------------------------

## PV du joueur. Émis par PlayerCombat (L4) à chaque Health.changed du joueur, et une première
## fois en différé (call_deferred) après son _ready pour donner la valeur initiale au HUD.
signal player_health_changed(current: int, max_value: int)
## Le joueur a perdu des PV. Émis par PlayerCombat (L4).
signal player_damaged(amount: int, source: Node3D)
## Le joueur est mort. Émis par PlayerCombat (L4). WorldManager (L2) appelle respawn() après
## WorldManager.respawn_delay ; WaveDirector (L5) termine la série en cours.
signal player_died
## Le joueur est réapparu au Spawn du village. Émis par WorldManager.respawn() (L2) ;
## PlayerCombat (L4) remet alors les PV au maximum.
signal player_respawned
## Demande de soin du joueur (1 PV toutes les deux vagues). Émis par WaveDirector (L5) ;
## PlayerCombat (L4) l'applique avec Health.heal().
signal player_heal_requested(amount: int)
## Un ennemi est entré en jeu. Émis par Enemy (L5) dans son _ready.
signal enemy_spawned(enemy: Node3D, enemy_id: StringName)
## Un ennemi a perdu des PV. Émis par Enemy (L5).
signal enemy_damaged(enemy: Node3D, amount: int)
## Un ennemi est mort. Émis par Enemy (L5) ; le WaveDirector actif compte les points.
signal enemy_killed(enemy_id: StringName, points: int)
## Début d'une vague. Émis par WaveDirector (L5).
signal wave_started(arena_id: StringName, wave: int, enemy_count: int)
## Vague terminée, bonus = 50 × n. Émis par WaveDirector (L5).
signal wave_cleared(arena_id: StringName, wave: int, bonus: int)
## Score courant de la série (points + bonus). Émis par WaveDirector (L5) ; affiché par le HUD.
signal arena_score_changed(arena_id: StringName, score: int)
## Fin de série (mort ou sortie de l'arène) ; best = nouveau meilleur score. Émis par
## WaveDirector (L5) après GameState.record_score().
signal arena_finished(arena_id: StringName, score: int, best: bool)
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
## État d'une quête : &"available", &"active" ou &"done". Émis par GameState.set_quest_state (L7).
signal quest_updated(quest_id: StringName, state: StringName)
## Le joueur entre dans une zone. Émis par Zone (L2) quand le joueur touche sa zone Bounds.
signal zone_entered(zone_id: StringName)
## Phase du jour : &"morning", &"day", &"evening", &"night" (M3, cycle jour/nuit).
signal day_phase_changed(phase: StringName)
## Skin actif. Émis par GameState quand GameState.skin_id change ; le joueur (L1) l'applique.
signal skin_changed(skin_id: StringName)
## PV max du joueur. Émis par GameState quand GameState.max_hp change (récompense de quête) ;
## PlayerCombat (L4) met à jour son Health.
signal max_hp_changed(max_value: int)
## Demande de sauvegarde (n'importe quel système, ex. menu pause). SaveManager (L8) sauvegarde.
signal save_requested
## Une partie est prête (nouvelle partie, Continuer, import). Émis par SaveManager (L8) ;
## main.gd quitte alors le menu et charge src/game.tscn.
signal game_loaded

# --- Quêtes en étapes (Lot Q, moteur de quêtes : docs/QUETES.md) --------------------------------

## Un drapeau de GameState change de valeur. Émis par GameState.set_flag (pas par from_dict ni
## reset) ; le QuestTracker valide les étapes « flag », les PNJ revoient leur marqueur.
signal flag_changed(flag: StringName, value: bool)
## Étape courante d'une quête active et son compteur (ennemis vaincus, vague ou score atteints) ;
## step_id &"" : plus d'étape (quête terminée ou oubliée). Émis par GameState.set_quest_step,
## que le QuestTracker appelle ; HUD, journal et marqueurs des PNJ se mettent à jour.
signal quest_step_updated(quest_id: StringName, step_id: StringName, count: int)
## Une étape vient d'être validée (récompense d'étape donnée, avant le passage à la suivante ou la
## fin de la quête). Émis par QuestTracker ; SaveManager demande une auto-sauvegarde.
signal quest_step_completed(quest_id: StringName, step_id: StringName)
## Demande de validation de l'étape courante de quest_id (step_id &"" : quelle qu'elle soit,
## sinon seulement si c'est elle). Émis par DialogueRunner (effet advance_quest) ou tout autre
## système ; le QuestTracker l'applique.
signal quest_advance_requested(quest_id: StringName, step_id: StringName)
## Le joueur entre dans un déclencheur de quête (src/quests/quest_trigger.tscn). Émis par
## QuestTrigger ; le QuestTracker valide les étapes « reach » qui le nomment.
signal trigger_entered(trigger_id: StringName)
## Quête suivie (affichée par le HUD) ; &"" : aucune. Émis par GameState quand tracked_quest
## change (QuestTracker au démarrage d'une quête, journal à la demande du joueur).
signal tracked_quest_changed(quest_id: StringName)

@warning_ignore_restore("unused_signal")
