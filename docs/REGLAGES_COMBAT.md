# Réglages de la sensation de combat (jalon M1, lisibilité HD-2D du lot H7)

Tous les chiffres qui font la sensation du combat, pour les ajuster sans lire le code. Chaque
ligne donne le fichier, la propriété, la valeur actuelle, son effet et la valeur de l'easter egg
2D (`jeu.js`, Yume-WordPress). Conversions de PLAN.md section 4 : une **distance** de l'easter egg
se convertit à l'échelle du personnage (72 px = 1,5 m, soit 1 px ≈ 2,1 cm), une **vitesse** se
rapporte à la marche (72 px/s = 4 m/s, soit 1 px/s ≈ 5,6 cm/s).

Comment régler :

- un fichier `data/…/*.tres` s'ouvre dans l'éditeur (inspecteur) ou se modifie au texte ; il vaut
  pour tout le jeu ;
- un `@export` d'un script (`player.gd`, `player_combat.gd`, `camera_rig.gd`, `enemy.gd`) se règle
  dans l'inspecteur du nœud concerné de la scène (`src/player/player.tscn` : nœuds `Player`,
  `Combat`, `CameraRig` ; `src/enemies/enemy.tscn`) ;
- une constante (`const`) se change dans le script ;
- après un changement, jouer `tests/integration/demo_m1.tscn` (F6, arène des dunes avec le vrai
  joueur) puis lancer `tools/check.sh` : les tests `tests/integration/test_m1_*.gd` disent si une
  règle de l'easter egg ou une portée a cassé (voir la dernière colonne des tableaux de portées).

Valeurs changées à l'intégration M1 : **recul des deux premiers coups d'épée** 5 → 2,5 m/s (le
premier coup sortait un Normal de la portée du deuxième) et **rayon d'activation du panneau**
1,3 → 0,9 m (docs/DECISIONS.md, section « Intégration M1 »).

Ajouts du lot H7 (combat lisible en vue fixe) : **préparation** des coups et des charges des
Timeres (`windup`), **arrêt sur image** (`hitstop`) et **secousse** (`shake`) dans
`data/attacks`, préparation plus lente du Grand, teinte de chaque corps et tremblement du sol
dans `data/enemies` ; aucune règle de l'easter egg ne change (section « Lisibilité en vue
fixe » plus bas ; tests `test_combat_fx.gd`, `test_enemy.gd`, `test_combat_vigil.gd`).

## Joueur : déplacement

| Fichier → propriété | Valeur | Effet | Easter egg |
| --- | --- | --- | --- |
| `src/player/player.gd` → `walk_speed` | 4 m/s | Marche | 72 px/s (4 m/s) |
| `player.gd` → `run_speed` | 7 m/s | Course (Maj, L3) | 138 px/s (7,7 m/s) |
| `player.gd` → `acceleration` | 45 m/s² | Démarrage au sol (0,09 s jusqu'à la marche) | instantané |
| `player.gd` → `deceleration` | 60 m/s² | Arrêt et demi-tour au sol, sans glisse | instantané |
| `player.gd` → `air_acceleration` | 18 m/s² | Contrôle en l'air | — (pas de saut) |
| `player.gd` → `jump_velocity` / `gravity_scale` | 5,4 m/s / × 1,5 | Saut d'environ 1 m | — |
| `player.gd` → `coyote_time` / `jump_buffer_time` | 0,1 s / 0,12 s | Tolérance du saut | — |
| `player.gd` → `knockback_damping` | 12 m/s² | Amortit le recul subi (3 m/s → 0,25 s, 0,38 m) | × 0,88 par image, 0,40 m |
| `player.gd` → `interact_cone_deg` | 120° | Cône où l'on trouve un panneau, un PNJ, un objet | — |
| `player.gd` → `lock_radius` / `lock_break_distance` | 12 m / 16 m | Recherche et perte du verrouillage | — |

## Joueur : vie, dégâts, épée, charge

| Fichier → propriété | Valeur | Effet | Easter egg |
| --- | --- | --- | --- |
| `src/player/player.tscn` → `Health.max_hp` (et `GameState.max_hp`) | 5 PV (6 avec la promesse du gâteau au beurre, 7 avec le registre des veilles : acte 1) | Vie | `PV_MAX` 5 |
| `player.tscn` → `Health.invincibility_time` | 1,2 s | Pas de second dégât pendant ce temps | `INVINCIBILITE` 1,2 s |
| `src/combat/player_combat.gd` → `hurt_time` | 0,35 s | Joueur figé après un dégât (coup ou charge interrompus) | `DUREE_DEGATS` 0,35 s |
| `player_combat.gd` → `blink_rate` | 12 bascules/s | Clignotement pendant l'invincibilité (visible / invisible) | 12 Hz, opacité 35 % / 100 % |
| `data/attacks/bite.tres`, `whip.tres` → `knockback` | 3 m/s | Recul subi à chaque morsure ou fouet | `RECUL` 150 px/s, 0,40 m au total |
| `player_combat.gd` → `combo_window` | 0,4 s | Délai après un coup pendant lequel un appui enchaîne le suivant (un appui *pendant* le coup enchaîne aussi) | pas d'enchaînement |
| `data/attacks/sword_1.tres`, `sword_2.tres` → `damage` / `knockback` | 1 / **2,5 m/s** (0,28 m) | Coups 1 et 2 | 1 dégât ; recul du Timere 170 px/s, 0,42 m |
| `data/attacks/sword_3.tres` → `damage` / `knockback` | 1 / 8 m/s (0,89 m) | 3e coup : grand recul final | — |
| `sword_1.tres`, `sword_2.tres` → `hitstop` / `shake` | 0,05 s / 0,025 m | (H7) Coup porté : planche du joueur et Timere touché figés, l'image tressaille | — |
| `sword_3.tres` → `hitstop` / `shake` | 0,08 s / 0,05 m | (H7) Le 3e coup pèse plus | — |
| `sword_3.tres` → `cooldown` | 0,3 s | Pause forcée après le 3e coup (un appui pendant ce temps est perdu) | — |
| `sword_*.tres` → `range_m` / `arc_deg` | 1,2 m / 90° | Secteur de l'épée devant le joueur (−Z de `Combat`) | boîte de 60 × 58 px devant (1,25 m) |
| `player_combat.gd` → `sword_height` | 1,4 m | Hauteur du secteur (de 0,1 à 1,5 m au-dessus des pieds) | 58 px |
| Planche `assets/characters/chtholly/chtholly.json` → `attaque` | 4 images à 14 ips, `coup` [1, 2, 3] | Durée d'un coup (0,29 s) et images qui touchent (0,07 à 0,29 s) | identique |
| `data/attacks/charge_wave.tres` → `charge_time` | 0,55 s | Maintien minimal de la charge (relâcher avant : rien) | `CHARGE_MIN` 0,55 s |
| `charge_wave.tres` → `cooldown` | 1,2 s | Recharge de l'onde, comptée depuis le relâcher | `RECHARGE_ONDE` 1,2 s |
| `charge_wave.tres` → `damage` / `pierces` | 3 / oui | L'onde traverse tous les Timeres | 3 dégâts, traverse |
| `charge_wave.tres` → `range_m` / `speed` / `duration` | 8 m / 19,05 m/s / 0,42 s | Portée, vitesse et vie du projectile ; le joueur reste figé `duration` | 250 px/s pendant 1,1 s (5,7 m) ; joueur figé `DUREE_ONDE` 0,42 s |
| `charge_wave.tres` → `width_m` | 2 m | Largeur de l'onde | 28 × 52 px |
| `charge_wave.tres` → `knockback` | 9 m/s (1 m) | Recul des Timeres touchés, Grand compris | 170 px/s |
| `charge_wave.tres` → `hitstop` / `shake` | 0,06 s / 0,04 m | (H7) Chaque Timere traversé se fige ; l'image tressaille dans le sens de l'onde | — |
| `player_combat.gd` → `charged_flicker_rate` | 8 bascules/s | Alternance des deux images de charge pleine | 8 Hz |
| `src/autoload/world_manager.gd` → `respawn_delay` | 2,2 s | Délai entre la mort et la réapparition au village | `DUREE_MORT` 2,2 s |

## Timeres

| Fichier → propriété | Petit | Normal | Coureur | Grand | Easter egg |
| --- | --- | --- | --- | --- | --- |
| `data/enemies/timere_*.tres` → `scale` | 0,8 | 1 | 0,9 | 1,3 | `taille` identique |
| → `max_hp` | 1 | 2 (3 dès la vague 6) | 1 | 5 | `pv` identique |
| → `speed` (m/s, avant bonus de vague) | 3,0 | 2,1 | 6,2 (charge) | 1,6 | 54 / 38 / 112 / 28 px/s |
| → `walk_speed` (hors charge) | — | — | 2,5 | — | min(vitesse, 46 px/s) |
| → `points` | 10 | 15 | 20 | 40 | identique |
| → `attacks` | morsure | morsure, fouet | morsure (+ charge) | fouet | identique |
| → `aggro_range_m` (Timeres libres) | 10 m | 10 m | 12 m | 10 m | — (arène seulement) |
| → `cooldown_scale` | 1 | 1 | 1 | 1,4 | Grand × 1,4 |
| → `stoic` | non | non | non | oui (ne recule que sous l'onde) | `stoique` |
| → `windup_scale` (H7) | 1 | 1 | 1 | 1,5 | — |
| → `tint` (H7, multiplie la planche) | (1 ; 1 ; 0,88) | blanc | (1 ; 0,8 ; 0,62) | (0,66 ; 0,74 ; 0,86) | — |
| → `strike_shake` (H7) | 0 | 0 | 0 | 0,04 m | — |

| Fichier → propriété | Valeur | Effet | Easter egg |
| --- | --- | --- | --- |
| `data/attacks/bite.tres` → `range_m` | 0,8 m × échelle | Portée de la morsure devant le corps | 40 px × taille (0,83 m) |
| `data/attacks/whip.tres` → `range_m` | 1,0 m × échelle | Portée du fouet | 48 px × taille (1,0 m) |
| `bite.tres`, `whip.tres` → `cooldown` | 1,15 s | Recharge moyenne entre deux attaques | — |
| `bite.tres` / `whip.tres` / `rush.tres` → `windup` (H7) | 0,3 / 0,35 / 0,4 s | Préparation avant le coup ou la charge (Grand : × 1,5, fouet 0,53 s) ; au contact, elle se loge dans la recharge | — |
| `bite.tres`, `whip.tres` → `hitstop` / `shake` (H7) | 0,06 s / 0,08 m | Joueur mordu : crocs du Timere figés, secousse dans le sens du coup | — |
| `src/enemies/enemy.gd` → `COOLDOWN_JITTER` | × [0,7 ; 1,3] | Recharge tirée entre 0,8 et 1,5 s (Grand 1,1 à 2,1 s) | hasard(0,8 ; 1,5) |
| `enemy.gd` → `FIRST_COOLDOWN` | 0,2 à 0,8 s | Première attaque après l'apparition | hasard(0,2 ; 0,8) |
| Planche `assets/enemies/timere/timere.json` → `morsure`, `fouet` | 4 images à 8 ips, `coup` [1, 2] | Attaque de 0,5 s ; elle ne blesse qu'entre 0,125 et 0,375 s | identique |
| `enemy.gd` → `HURT_TIME` | 0,35 à 0,45 s (0,42 s : `degats` 5 images à 12 ips) | Timere sonné après un coup (son attaque est interrompue) | min(0,45 ; 0,42) |
| `enemy.gd` → `KNOCKBACK_DECAY` | 9 /s | Amortit le recul des Timeres | × 0,86 par image |
| `enemy.gd` → `APPROACH_RATIO` | 0,85 | Le Timere s'arrête à 85 % de sa plus longue portée | portée + 6 px |
| `enemy.gd` → `SEPARATION_DISTANCE` / `SEPARATION_WEIGHT` | 1,1 m × échelle / 1,2 | Écart entre Timeres (ils ne se bloquent pas) | 18 px × (tailles) |
| `enemy.gd` → `RUSH_MIN_GAP` / `RUSH_OVERSHOOT` | 1 m / 1,5 m | Coureur : charge seulement au-delà de sa portée + 1 m, file 1,5 m plus loin | court au-delà de 50 px |
| `data/attacks/rush.tres` → `range_m` / `cooldown` | 8 m / 1,5 s | Distance où le Coureur se lance, recharge de la charge | — |
| `enemy.gd` → `leash_m` / `CHASE_KEEP_FACTOR` | 20 m / × 1,5 | Timeres libres : laisse autour de leur point de départ, poursuite tenue jusqu'à 1,5 × l'aggro | — |
| `enemy.gd` → `corpse_time` | 2,2 s | Le corps disparaît (rétrécit les 0,3 dernières s) | `mort` 0,75 s + fondu 0,6 s |
| `enemy.gd` → `DETOUR_HEAD_ON` / `DETOUR_TIME` | 0,8 / 0,5 s | Un mur heurté de face (poteau, tronc) est longé 0,5 s | — |

## Arène et vagues (`data/waves/dunes.json`)

| Clé | Valeur | Effet | Easter egg |
| --- | --- | --- | --- |
| `generator.count` | 3 + 2 × n | Timeres de la vague n (au-delà des 3 vagues listées) | identique |
| `waves` | 3 S + 2 N ; 3 S + 2 N + 2 C ; 4 S + 3 N + 1 C + 1 G | Vagues 1 à 3 écrites à la main | tirage aléatoire |
| `generator.min_wave` | Coureur 2, Grand 3 | Première vague de chaque type | identique |
| `generator.max_simultaneous` | Grand 1 | Jamais deux Grands vivants à la fois | identique |
| `generator.speed_bonus_per_wave` / `speed_bonus_max` | 4 % / 50 % | Vitesse × (1 + 0,04 n), plafonnée à la vague 13 | identique |
| `generator.hp_bonus` | Normal +1 dès la vague 6 | — | identique |
| `bonus_per_wave` | 50 × n | Bonus de vague nettoyée | identique |
| `heal_every_waves` / `heal_amount` | 2 / 1 PV | Soin toutes les deux vagues | identique |
| `timing.start_delay` | 1,2 s | Pause avant la vague 1 | 1,2 s |
| `timing.wave_pause` | 1,8 s | Pause entre deux vagues | 1,8 s |
| `timing.first_spawn_delay` | 0,8 s | Premier Timere d'une vague | 0,8 s |
| `timing.spawn_interval` / `_per_wave` / `_min` / `spawn_jitter` | 2,2 − 0,15 n s, au moins 0,5 s, × [0,7 ; 1,2] | Cadence des apparitions | identique |
| `src/enemies/wave_director.gd` → `SPAWN_SPREAD` | ± 1 m | Écart autour du point d'apparition | — |
| `src/enemies/arena.gd` → `bounds_radius_m` | 12 m | En sortir entre deux vagues termine la série | bords de l'écran |
| `src/enemies/arena.tscn` → `SphereShape3D_interact.radius` | **0,9 m** | Activation du panneau (jusqu'à ~2,5 m, toujours dans l'arène) | — |

## Caméra (`src/player/camera_rig.gd`, `camera_rig.tscn`, lot H5)

La caméra fixe HD-2D du socle (docs/DECISIONS.md, « Socle HD-2D — caméra fixe ») appartient au
lot H5 ; ses réglages vivent dans `camera_rig.gd` et ne sont pas recopiés ici. Ce qui compte pour
le combat : elle regarde toujours le nord (le haut de l'écran), inclinée de 32° (une distance
nord-sud paraît 0,53 fois plus courte qu'une distance est-ouest), à 21 m du point visé (zoom de
14 à 25 m) ; le verrouillage avance le point visé vers la cible (40 %, 5 m au plus) sans tourner.
La secousse du combat (`ScreenShake`, ci-dessous) décale l'image par `Camera3D.h_offset` /
`v_offset`, que `CameraRig` ne règle pas (docs/CONTRACT_REQUESTS.md, « H7 Combat »).

## Lisibilité en vue fixe (lot H7)

D'où vient un coup, quand frapper, quand s'écarter : ce qui doit se lire « où » est posé au sol à
la place exacte de ce qu'il montre, ce qui doit se lire « quand » se voit au-dessus du corps. Les
images sont dans `src/combat/fx/` (pixel art à 96 px/m, remplaçants de `make_fx.py`, qu'une image
dessinée remplace sans toucher au code) ; aucun signe ne dépend du dessin des planches.

| Fichier → propriété | Valeur | Effet |
| --- | --- | --- |
| `data/attacks/*.tres` → `windup` | morsure 0,3 s, fouet 0,35 s, charge 0,4 s | État `windup` du Timere : il se ramasse (`enemy.gd` → `WINDUP_SQUASH` : + 10 % de large, − 14 % de haut), un éclat brille à sa tête (`GLINT_HEIGHT` 85 % de sa hauteur) et la zone exacte de sa Hitbox se dessine au sol (`Telegraph` : cercle net, remplissage qui atteint le bord au moment du coup) ; pour la charge du bondissant, le couloir (largeur du corps, distance + 1,5 m) |
| `enemy.gd` → `_melee_lead()` | plus longue préparation de ses coups | La préparation commence quand la recharge n'en est plus qu'à cette durée : au contact, un coup toutes les 1,3 à 2 s comme avant ; seul le premier coup après l'approche attend sa préparation |
| `data/attacks/*.tres` → `hitstop` | 0,05 à 0,08 s | Arrêt sur image : la planche figée (`CombatFx.freeze`, temps physique), le corps touché attend puis recule de la même distance |
| `data/attacks/*.tres` → `shake` ; `data/enemies/timere_big.tres` → `strike_shake` | 0,025 à 0,08 m ; 0,04 m | Secousse de l'image, dans le sens du coup vu à l'écran, jamais de rotation |
| `src/combat/screen_shake.gd` → `frequency` / `decay` / `max_amplitude` / `cross_ratio` | 24 Hz / 9 /s / 0,18 m / 0,3 | Oscillation, amortissement (10 % en 0,26 s), plafond, part de travers |
| `src/combat/hit_flash.gd` → `flash_color` / `max_strength` | crème / 0,85 (joueur : rose, 0,75) | Éclair d'un combattant touché : sa silhouette exacte, 0,09 s (joueur 0,1 s : `player_combat.gd` → `FLASH_TIME`) |
| `src/combat/combat_fx.gd` → `COLOR_*` | or (épée), or plus chaud (3e coup), bleu (onde), corail (crocs), sable (poussière) | Teinte des éclats d'impact, des crocs, du fouet et de la poussière |
| `enemy.gd` → `IMPACT_SIZE` / `DUST_SIZE` / `DUST_KNOCKBACK` | × 1 / × 1,2 / 2 m/s | Éclats côté attaquant ; poussière soulevée par un recul d'au moins 2 m/s |
| `enemy.gd` → `RUSH_DUST_EVERY` / `RUSH_GHOST_EVERY` | 0,1 s / 0,06 s | Traînée du bondissant pendant sa charge (poussière, images rémanentes) |
| `player_combat.gd` → `SLASH_SIZE` | 2,5 × 1,25 m | Coup d'épée dessiné au sol sur les images « coup », mis à l'échelle de `range_m` (1,2 m ; l'image est dessinée pour l'arc de 90°), retourné au 2e coup, doré au 3e |
| `player_combat.gd` → `LOCK_RING_RADIUS` / `LOCK_RING_SPIN` ; `AIM_SIZE` / `AIM_AHEAD` | 0,62 m × échelle / 1,5 rad/s ; 0,34 m / 0,9 m | Réticule au sol sous la cible verrouillée ; chevron de visée devant les pieds (verrouillage et charge) |
| `player_combat.gd` → `SHADOW_RADIUS` ; `enemy.gd` → `SHADOW_MARGIN` | 0,4 m ; rayon du corps + 0,08 m | Ombre nette au sol (`GroundShadow`) ; celle du joueur reste au sol pendant un saut et rapetisse |
| `enemy.gd` → `FLANK_RANGE` / `FLANK_MIN_DEG` | 4 m / 30° | De près, un Timere vient par les côtés de l'écran plutôt que pile au nord ou au sud du joueur, où les sprites se cachent l'un l'autre (l'épée, 90°, l'atteint encore) |
| `enemy.gd` → `SEPARATION_DEPTH` | 0,7 | Dans l'écart entre Timeres, une distance nord-sud compte pour 0,7 fois sa longueur : deux Timeres l'un derrière l'autre (qui se chevauchent à l'écran) s'écartent de côté |
| `src/enemies/telegraph.gd` → `glint_size` | 1,3 (× l'échelle du Grand) | Taille de l'éclat de préparation |

## Durées : cohérence vérifiée

Mesuré dans le vrai jeu (`tests/integration/test_m1_*.gd`, horloge à 60 images/s) :

- **Coup d'épée** : 0,29 s, blesse de 0,07 à 0,29 s ; trois coups enchaînés en martelant la
  touche : 0,86 s, puis 0,3 s de recharge (cycle de 1,16 s pour trois coups ; l'easter egg
  permet un coup toutes les 0,29 s, sans enchaînement ni recharge).
- **Enchaînement** : un appui pendant un coup, ou dans les 0,4 s qui suivent, joue le coup
  suivant. Un Timere touché est sonné 0,42 s, plus longtemps qu'un coup : l'enchaînement
  l'empêche d'attaquer. Avec le recul de 2,5 m/s, un Normal au contact (1,16 m) reste à portée
  du deuxième coup (1,44 m pour 1,55 m de portée) et meurt en deux coups.
- **Portées réelles** (centre à centre, joueur et Timere sur le sol) : l'épée touche un Petit
  jusqu'à 1,48 m, un Normal jusqu'à 1,55 m, un Grand jusqu'à 1,66 m ; le Petit mord dès 0,96 m,
  le Normal fouette dès 1,40 m, le Coureur mord dès 1,08 m, le Grand fouette dès 1,82 m (il
  s'arrête à 1,55 m : l'épée l'atteint). Une morsure partie au contact rate un joueur qui a reculé
  à 1,7 m avant l'image « coup ».
- **Charge** : 0,55 s de maintien, onde de 0,42 s sur 8 m, recharge 1,2 s depuis le relâcher :
  au mieux une onde toutes les 1,75 s, comme l'easter egg.
- **Dégâts subis** : 1 PV, 0,35 s figé, recul de 0,38 m, 1,2 s d'invincibilité ; quatre Timeres
  au contact ne retirent jamais deux PV en moins de 1,2 s (mort en 5 morsures, ~6 s).
- **Rythme des Timeres** : une attaque toutes les 1,3 à 2 s chacun (recharge + 0,5 s
  d'animation), préparation comprise (`test_windup_does_not_slow_the_attack_cadence`) ; la
  préparation se voit 0,3 s (morsure), 0,35 s (fouet), 0,53 s (fouet du Grand) avant
  l'animation, puis on a encore 0,125 s pour reculer quand la morsure part. Un coup porté
  pendant la préparation l'annule (la recharge court), sauf sur le Grand, qui ne bronche que
  sous l'onde.
- **Arrêt sur image** : un coup d'épée porté allonge le coup de 0,05 s (0,08 s pour le 3e) ;
  trois coups qui touchent tous durent 1,04 s au lieu de 0,86 s.
- **Veille jouée** (`test_combat_vigil.gd`, vraie partie, rythme réel, 5 PV) : un joueur qui lit
  les signes atteint la vague 5 en 76 à 81 s avec 1 à 3 morsures reçues ; le même joueur sans
  lire les signes en reçoit 3 à 6 et peut tomber à la vague 4.
- **Vitesses par vague** : vague 1 × 1,04 (Petit 3,1 m/s), vague 5 × 1,2 (Petit 3,6 m/s, Coureur
  en charge 7,4 m/s), vague 13 et plus × 1,5 (Petit 4,5 m/s : plus rapide que la marche du joueur,
  qui doit courir ; Coureur en charge 9,3 m/s, plus rapide que la course). Mêmes rapports que
  l'easter egg (marche 72 px/s contre Petit 54 px/s × 1,5).

## À juger par le propriétaire (manette et clavier en main)

1. **Recul des coups 1 et 2** (2,5 m/s, 0,28 m) : assez visible ? Plus fort, le deuxième coup
   rate un Normal (il faut alors laisser le joueur avancer pendant l'enchaînement) ; plus faible,
   l'impact se sent moins.
2. **Fenêtre d'enchaînement** (0,4 s) et **recharge après le 3e coup** (0,3 s, appui perdu).
3. **Onde** : 19 m/s pendant 0,42 s (8 m, PLAN.md) ; dans l'easter egg elle file plus lentement et
   plus longtemps (1,1 s). Allonger `duration` (et `range_m`) si elle paraît trop brève.
4. **Recul subi** (3 m/s) et **clignotement** (invisible à 12 Hz ; l'easter egg passait à 35 %
   d'opacité, impossible avec l'alpha scissor des planches sans tri de transparence).
5. **Vitesse des Timeres** aux vagues hautes et **laisse des Timeres libres** (20 m : ceux de la
   forêt abandonnent ~9 m avant le village).
6. (H7) **Préparations** (0,3 / 0,35 / 0,4 s, Grand × 1,5) : assez longues pour s'écarter sans
   rendre les Timeres mous ? Plus courtes, la vue fixe redevient punitive ; plus longues, la
   veille devient facile.
7. (H7) **Arrêt sur image** (0,05 à 0,08 s) et **secousse** (2,5 à 8 cm, à 21 m de la caméra) :
   sensibles sans fatiguer l'œil pendant une vague de 13 Timeres ?
8. (H7) **Teintes des corps** : utiles tant que les quatre corps partagent une planche ; à
   retirer si chaque corps reçoit son dessin.
