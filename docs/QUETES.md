# Écrire des quêtes

Le moteur de quêtes (Lot Q) fait vivre des quêtes **écrites uniquement en données** : un fichier
JSON par quête, des répliques dans les dialogues JSON des PNJ, et, si besoin, des déclencheurs de
lieu posés dans les fichiers d'emplacement des zones. Aucun script à toucher. Ce document suffit
pour écrire une quête principale en plusieurs actes ou des quêtes secondaires, et pour les tester.

Les exemples cités existent et sont testés : la quête `example_patrol`
(`tests/data/quests/example_patrol.json`), le dialogue du forgeron qui va avec
(`tests/data/dialogues/example_blacksmith.json`) et leur test (`tests/unit/test_quest_example.gd`).
Les quêtes d'exemple vivent sous `tests/` : elles ne sont pas dans le jeu exporté.

## En bref

1. Écrire la quête : `data/quests/<id>.json` (le nom du fichier est l'id).
2. Écrire ses répliques dans le dialogue de chaque PNJ concerné (`data/dialogues/<pnj>.json`) :
   la proposition (`start_quest`), une réplique par étape (`quest_step`), le rendu.
3. Si une étape demande d'atteindre un lieu précis : poser un déclencheur dans
   `src/npc/placements/<zone>.tscn`.
4. Si la quête utilise un nouvel objet ou un nouveau PNJ : `data/items/<id>.tres` (et son icône),
   `data/npcs/<id>.tres` et son emplacement (voir CLAUDE.md, recette des fichiers).
5. Vérifier : `tools/test.sh tests/unit/test_quest_content.gd`, puis un test de scénario
   (copie de `tests/unit/test_quest_example.gd`), puis `tools/check.sh`.

## Ce que voit le joueur

- Un **« ! »** doré au-dessus du PNJ qui donne une quête disponible (`giver`), un **« ? »** au-dessus
  du PNJ à qui parler ou rendre des objets pour valider l'étape en cours.
- Le **HUD** affiche la quête suivie : son titre, l'objectif de l'étape courante et sa progression
  (« Fragment de page : 3/5 », « Ennemis vaincus : 1/2 »), et « +n quêtes · Tab / Select » s'il y
  en a d'autres. Le panneau s'illumine à chaque nouvelle étape ; « Quête terminée ! » à la fin.
- Le **journal** (Tab ou L, bouton Select / Back ; il met le jeu en pause) liste les quêtes en
  cours puis terminées. Pour la quête choisie : son type (principale, secondaire), son donneur, son
  résumé, ses étapes validées, l'étape courante avec son aide et sa progression (les étapes
  suivantes restent cachées : pas de spoiler), sa récompense. Entrée / A en fait la quête suivie.
- Une quête qui commence devient la quête suivie ; quand elle se termine, la première quête active
  (principale d'abord) prend sa place.

## Le fichier de quête

### Exemple commenté : une quête en trois étapes

```json
{
  "_comment": "Exemple commenté de docs/QUETES.md.",
  "id": "example_patrol",
  "title": "La ronde de la forêt",
  "summary": "Le forgeron s’inquiète : des Timeres rôdent dans la clairière de la forêt…",
  "giver": "blacksmith",
  "requires": { "quests": ["pages"] },
  "steps": [
    {
      "id": "clearing",
      "type": "reach",
      "trigger": "forest_clearing",
      "objective": "Rejoindre la clairière de la forêt",
      "hint": "La forêt est au nord du village, par la porte en bois."
    },
    {
      "id": "timeres",
      "type": "kill",
      "enemy": "timere_small",
      "count": 2,
      "zone": "forest",
      "objective": "Chasser 2 petits Timeres de la forêt"
    },
    {
      "id": "report",
      "type": "talk",
      "npc": "blacksmith",
      "objective": "Faire ton rapport au forgeron"
    }
  ],
  "rewards": { "items": { "shell": 2 }, "flags": ["forest_patrol_done"] }
}
```

Ligne par ligne :

- `_comment` : toute clé qui commence par `_` est un commentaire, ignoré (JSON n'a pas de
  commentaires). Partout ailleurs, une clé inconnue est une erreur : une faute de frappe ne passe
  pas inaperçue.
- `id` : identifiant (lettres, chiffres, `_`), égal au nom du fichier. Il ne change plus une fois
  la quête publiée : la sauvegarde des joueurs le retient.
- `title` : titre du HUD et du journal (40 caractères au plus) ; `summary` : résumé du journal.
- `giver` : le PNJ (`NpcData.id`) qui propose la quête ; il porte le « ! » tant qu'elle est
  disponible. Son dialogue doit la proposer (`start_quest`).
- `requires` : la quête n'est disponible qu'une fois la quête des pages terminée.
- `steps` : les étapes, **dans l'ordre**. Une seule est en cours à la fois : la ronde commence par
  la clairière (étape `reach` sur un déclencheur), puis deux petits Timeres à chasser dans la forêt
  (`kill`), puis le rapport au forgeron (`talk`).
- `objective` : le texte du HUD pour cette étape (70 caractères au plus) ; `hint` : une aide
  facultative, affichée par le journal sous l'objectif.
- `rewards` : donnée quand la dernière étape est validée : deux coquillages et un drapeau qu'une
  autre quête ou un dialogue peut tester.

### Champs d'une quête

| Champ | Obligatoire | Valeur | Effet |
| --- | --- | --- | --- |
| `id` | oui | identifiant | nom du fichier, clé de la sauvegarde |
| `title` | oui | texte | HUD, journal, bannière « Quête terminée ! » |
| `steps` | oui | liste d'étapes (au moins une) | voir ci-dessous |
| `summary` | non | texte | journal |
| `giver` | non | id de PNJ | « ! » au-dessus de lui quand la quête est disponible ; journal |
| `main` | non | `true` / `false` (défaut) | quête principale : en tête du journal, « Quête principale » |
| `requires` | non | `{ "quests": […], "flags": […], "not_flags": […] }` | prérequis pour être disponible : quêtes terminées, drapeaux posés, drapeaux absents |
| `auto_start` | non | `true` / `false` (défaut) | démarre seule dès que `requires` est rempli (pas de « ! ») |
| `rewards` | non | `{ "items": {objet: quantité}, "flags": […], "max_hp": n }` | donnée à la fin : objets, drapeaux posés, PV max portés à n s'ils sont plus bas |

### Les étapes

Champs communs : `id` (unique dans la quête ; les dialogues et la sauvegarde le nomment), `type`,
`objective` (obligatoires), `hint` et `rewards` (facultatifs, mêmes clés que la récompense de la
quête, donnée quand l'étape est validée).

| `type` | Champs | Validée quand… |
| --- | --- | --- |
| `talk` | `npc` | une conversation avec ce PNJ se termine, si elle a commencé alors que l'étape était déjà en cours ; ou par l'effet de dialogue `advance_quest` |
| `reach` | `zone` **ou** `trigger` | le joueur entre dans la zone (`village`, `dunes`, `forest`, `beach`, `hill`), ou s'y trouve déjà quand l'étape commence ; ou entre dans le déclencheur nommé (même s'il y est déjà quand l'étape commence) |
| `kill` | `count` (1), `enemy` (`"any"` par défaut, ou `timere_small`, `timere_normal`, `timere_runner`, `timere_big`), `zone` (facultative) | `count` ennemis correspondants vaincus **pendant l'étape** ; avec `zone`, le joueur doit s'y trouver au coup fatal. Les Timeres d'une série d'arène comptent aussi |
| `collect` | `item`, `count` (1), `consume` (`false`), `npc` (facultatif) | sans `npc` : dès que le joueur possède `count` objets (déjà en poche compris). Avec `npc` (« rapporter à ») : à la fin d'une conversation avec ce PNJ, s'il les a. `consume: true` les retire à la validation |
| `arena` | `arena` (`dunes`), `wave` **ou** `score` | une vague au moins égale commence, ou le score de la série atteint `score`, pendant l'étape (les records d'avant ne comptent pas) |
| `flag` | `flag` | le drapeau est posé (par un dialogue, un déclencheur, une récompense) ; s'il l'est déjà quand l'étape commence, tout de suite |

Une étape validée donne sa récompense, puis l'étape suivante commence (son compteur repart de
zéro). Après la dernière, la quête est terminée et sa récompense donnée. Les étapes que l'état de
la partie valide déjà (objets en poche, drapeau posé, joueur dans la zone) passent aussitôt : une
quête peut ainsi franchir plusieurs étapes d'un coup.

### États, prérequis et enchaînement

| État (condition `quest`) | Sens |
| --- | --- |
| `""` | jamais commencée (disponible ou verrouillée) |
| `"available"` | jamais commencée et prérequis remplis : c'est ce que teste un dialogue qui propose la quête |
| `"active"` | en cours (une étape courante) |
| `"done"` | terminée |

« Disponible » n'est jamais écrit dans la sauvegarde : c'est calculé à chaque fois à partir de
`requires`. Une quête terminée rend donc aussitôt disponibles celles qui la requièrent (le « ! »
apparaît au-dessus de leur donneur). Pour enchaîner les **actes d'une quête principale**, donner
à chaque acte `"main": true`, `"requires": { "quests": ["acte_precedent"] }` et
`"auto_start": true` : l'acte suivant démarre seul et devient la quête suivie. Une quête qui doit
attendre un événement du monde sans être proposée par un PNJ utilise un drapeau dans `requires`.

## Le dialogue qui va avec

Les dialogues gardent le format de PLAN.md (section 4, « Format de dialogue ») ; le Lot Q ajoute
une condition et quatre effets. Le dialogue du forgeron de l'exemple, en abrégé :

```json
{
  "id": "example_blacksmith",
  "start": "hello",
  "entries": ["after", "report", "patrol", "offer"],
  "nodes": {
    "hello": { "text": "Bienvenue à la forge !", "next": null },
    "offer": {
      "if": { "quest": ["example_patrol", "available"] },
      "text": "Des Timeres rôdent dans la clairière de la forêt. Tu irais voir ?",
      "choices": [
        { "text": "J’y vais.", "start_quest": "example_patrol", "next": "go" },
        { "text": "Pas maintenant.", "next": null }
      ]
    },
    "go": { "text": "Chasse les plus petits, puis reviens me raconter.", "next": null },
    "patrol": {
      "if": { "quest": ["example_patrol", "active"] },
      "text": "Alors, cette clairière ?",
      "next": null
    },
    "report": {
      "if": { "quest_step": ["example_patrol", "report"] },
      "text": "Deux de moins ! Tiens, ces coquillages porte-bonheur.",
      "advance_quest": ["example_patrol", "report"],
      "next": "thanks"
    },
    "thanks": { "text": "La forêt respire mieux grâce à toi.", "next": null },
    "after": {
      "if": { "quest": ["example_patrol", "done"] },
      "text": "La clairière est calme depuis ta ronde.",
      "next": null
    }
  }
}
```

- Les **entrées** sont essayées dans l'ordre : `done` (nom réservé, toujours en premier), puis
  `entries`, puis `start`. On met donc les cas les plus précis d'abord : `after` (quête finie),
  `report` (étape de rapport), `patrol` (quête en cours, n'importe quelle autre étape), `offer`
  (quête à prendre). Sinon, `hello`.
- `report` valide l'étape tout de suite avec `advance_quest` : la récompense arrive avec la
  réplique. Sans lui, l'étape `talk` se validerait de toute façon à la fin de la conversation.
- Le forgeron réel garderait ses nœuds actuels : on ajoute ceux de la quête, et leurs noms dans
  `entries`.

### Conditions (`"if"`, toutes doivent être vraies)

| Condition | Valeur | Vraie si… |
| --- | --- | --- |
| `flag` / `not_flag` | un nom ou une liste | tous les drapeaux sont posés / aucun ne l'est |
| `count` | `[objet, minimum]` | le joueur a au moins `minimum` objets |
| `quest` | `[quête, état]` | l'état de la quête est `""`, `"available"`, `"active"` ou `"done"` (voir plus haut) |
| `quest_step` | `[quête, étape]` ou `[quête, [étape, …]]` | la quête est en cours, à cette étape (ou à l'une de ces étapes) |
| `not_quest_step` | mêmes formes | la quête n'est à aucune de ces étapes (vraie aussi si elle n'est pas en cours) |
| `best_score` | `[arène, minimum]` | le meilleur score de l'arène atteint `minimum` |

Les mêmes conditions décident de la présence des PNJ (`visible_if`, plus bas).

### Effets (sur un nœud ou un choix)

| Effet | Valeur | Ce qu'il fait |
| --- | --- | --- |
| `take_item` | `"objet"`, `["objet", n]` ou `{"objet": n, …}` | retire les objets ; s'il en manque un, rien n'est retiré (avertissement) : le protéger par une condition `count` |
| `give_item` | mêmes formes | donne les objets |
| `set_flag` / `clear_flag` | un nom ou une liste | pose / retire des drapeaux |
| `start_quest` | `"quête"` | démarre la quête (première étape, devient la quête suivie) |
| `advance_quest` | `"quête"` ou `["quête", "étape"]` | valide l'étape courante ; la forme `[quête, étape]` ne fait rien si l'étape courante est une autre (plus sûr). Une étape `collect` exige les objets |
| `complete_quest` | `"quête"` | termine la quête d'office : les étapes restantes sont validées, à condition d'avoir les objets de ses étapes `collect` restantes ; sinon refus, la quête reste à la même étape |

### Ordre d'évaluation

1. Le joueur parle au PNJ : le moteur note les étapes `talk` et `collect` (avec `npc`) de ce PNJ
   qui sont en cours.
2. Choix de l'entrée : `done`, puis `entries` dans l'ordre, puis `start` ; le premier nœud dont
   le `if` est vrai. Un nœud atteint par `next` est affiché même si son `if` est faux.
3. Le nœud s'affiche : ses effets s'appliquent d'abord, **toujours dans cet ordre**, quel que soit
   l'ordre d'écriture : `take_item`, `give_item`, `set_flag`, `clear_flag`, `start_quest`,
   `advance_quest`, `complete_quest`. Le moteur de quêtes réagit à chacun aussitôt (un drapeau
   posé valide une étape `flag`, un objet donné une étape `collect`…).
4. Puis son texte est calculé (`{count:…}`, `{left:…}`, `{best:…}` voient l'état après les
   effets) et ses choix filtrés par leur `if` (après les effets du nœud aussi).
5. Un choix choisi : ses effets (même ordre), puis son `next`.
6. Fin de la conversation : les étapes notées au point 1 et toujours en cours sont validées
   (`collect` : si le joueur a les objets). Le dialogue qui **démarre** une quête ne valide donc
   jamais sa première étape, même si c'est « parler à ce PNJ ».

### Bonnes pratiques

- Une réplique par étape chez le PNJ concerné (`quest_step`), sinon le joueur valide une étape
  `talk` en entendant une réplique sans rapport.
- Pour une étape validée seulement par **un** choix précis (accepter, répondre juste) : étape
  `flag`, et `set_flag` sur ce choix.
- Répliques de moins de 160 caractères, choix de moins de 32 (2 choix au plus par nœud).
- Typographie des dialogues existants : espace insécable avant `!`, `?`, `:` et `;`, apostrophe
  typographique `’`, points de suspension `…`.
- Identifiants en anglais (`snake_case`), textes en français. Le canon et les spoilers suivent
  `docs/lore/PLAN.md` (à lire avant d'écrire l'histoire).
- Jamais le nom du joueur en dur : `{player}` (ci-dessous), sinon « tu ».

### Le nom du joueur : `{player}`

`{player}` est remplacé par le nom affiché du skin choisi (`SkinData.display_name` de
`GameState.skin_id`, sinon le skin par défaut : « Chtholly »). Il marche partout où le joueur lit
du texte de quête ou de dialogue : répliques, choix, `speaker` d'un nœud (`"speaker":
"{player}"` quand la protagoniste parle), titre, résumé, objectifs et aides des quêtes (HUD et
journal), textes de l'histoire (`data/texts/story.json`). Il se combine avec `{count:…}`,
`{left:…}` et `{best:…}`. Un nom de skin peut être plus long que « Chtholly » : un titre ou un
objectif qui cite `{player}` doit encore tenir dans le HUD avec le plus long nom de skin
(`tools/test.sh tests/unit/test_sys_story_content.gd` le vérifie). Avec parcimonie : les autres
personnages appellent souvent la protagoniste autrement (« mademoiselle », « guerrière »).

### Plusieurs voix : `speaker_id`

Un nœud peut être dit par un autre PNJ que celui du dialogue : `"speaker_id"` nomme ce PNJ
(`data/npcs/<id>.tres`). La boîte de dialogue montre alors **son portrait** (celui de son skin)
et, sans `"speaker"`, **son nom** ; le nœud suivant sans `speaker_id` revient au PNJ du dialogue.
Exemple, dans le dialogue de Willem (étape `fever` de `act1_main`) :

```json
"fever_night": {
  "if": { "quest_step": ["act1_main", "fever"] },
  "text": "Dors. Pas un mot de plus.",
  "next": "fever_coffee"
},
"fever_coffee": {
  "speaker_id": "nephren",
  "text": "Archives. Toute la nuit.",
  "next": null
}
```

- `"speaker"` garde la main sur le nom affiché (`"speaker": "Ren"` avec `"speaker_id":
  "nephren"` : le nom « Ren », le portrait de Nephren).
- Un `speaker_id` qui ne nomme aucun PNJ donne un avertissement et le portrait du PNJ du dialogue ;
  `tests/unit/test_sys_story_content.gd` vérifie que chaque `speaker_id` des dialogues existe et a
  un portrait.
- Parler avec ce PNJ n'est pas « lui parler » : seule la conversation avec le PNJ du dialogue
  valide une étape `talk`.

## La présence des PNJ : `visible_if`

Un PNJ n'est là que si la condition `visible_if` de ses données (`NpcData`, `data/npcs/<id>.tres`)
est vraie : **même grammaire et même évaluateur** que le `"if"` d'un nœud de dialogue (drapeaux,
objets, état et étape de quête, meilleur score). Sans `visible_if` (`{}`), il est toujours là.
Absent, il est caché, sans collision (on traverse sa place), sans invite « Parler », sans
dialogue et sans marqueur « ! » / « ? ». La présence est réévaluée en fin d'image quand une
quête, une étape, un drapeau, l'inventaire, le skin ou un record changent, et au chargement d'une
partie ; un PNJ en pleine conversation ne part qu'à la fin de celle-ci.

Exemple, l'acte 1 : Willem au terrain d'entraînement **seulement pendant l'étape `training`** de
`act1_main`, au village le reste du temps sauf pendant `training` et `promise` (où il attend au
sommet de la colline), et encore au sommet après l'acte (les derniers soirs avant le départ). Un
même personnage à plusieurs endroits = une `NpcData` par emplacement, chacune avec sa condition
(les instances `willem_training` et `willem_stars` de HISTOIRE.md, section 3.3) :

```
# data/npcs/willem_training.tres (posé au terrain d'entraînement, src/npc/placements/forest.tscn)
visible_if = {
"quest_step": ["act1_main", "training"]
}

# data/npcs/willem.tres (posé au village)
visible_if = {
"not_quest_step": ["act1_main", ["training", "promise"]]
}

# data/npcs/willem_stars.tres (posé au sommet, src/npc/placements/hill.tscn) : drapeau posé par la
# récompense de l'étape starry_hill, donc vrai pendant promise et pour toujours ensuite
visible_if = {
"flag": "starry_night"
}

# data/npcs/limeskin.tres (posée au port) : à partir de the_edge (récompense de training)
visible_if = {
"flag": "duel_lost"
}
```

Dans un `.tres`, les identifiants s'écrivent comme dans le JSON, entre guillemets
(`"act1_main"` ; `&"act1_main"` est aussi accepté). La grammaire n'a pas de « ou » : toutes les
clés doivent être vraies. Pour « à partir de telle étape et pour toujours » (même après la fin de
la quête, quand `quest_step` est faux), poser un drapeau par la récompense de l'étape précédente
et le tester (`"flag"`), comme `starry_night` et `duel_lost` ci-dessus ; pour « pendant ces
étapes seulement », `quest_step` avec une liste ; pour « sauf pendant ces étapes »,
`not_quest_step`. Chaque étape « parler » doit trouver son PNJ présent, dans la zone de l'étape :
`tests/unit/test_act1_presence.gd` le vérifie pour `act1_main`, étape par étape.

Le skin du joueur prime : **le PNJ dont le skin est celui que le joueur a choisi n'est jamais
là** (la fée de la communauté choisie comme héroïne n'est pas aussi un PNJ ; Chtholly n'est
jamais un PNJ). Les dialogues de cette fée l'appellent alors par `{player}`.

Vérifier : `tools/test.sh tests/unit/test_sys_story_content.gd` (chaque `visible_if` est une
condition valide) ; scénarios : `tests/unit/test_npc_presence.gd` (le mécanisme) et
`tests/unit/test_act1_presence.gd` (l'acte 1).

## Les textes de l'histoire : `data/texts/story.json`

Les textes que les systèmes affichent hors dialogues et quêtes vivent dans un seul fichier de
données, lu par `DialogueRunner.story_text("chemin/de/la/clé")` (variables et `{player}`
remplacés) :

| Clé | Texte (acte 1) | Où |
| --- | --- | --- |
| `arenas/<arène>/prompt` | « Sonner la cloche de veille » | invite du panneau de l'arène |
| `arenas/<arène>/sign` | « Cloche de veille » | texte écrit sur le panneau |
| `arenas/<arène>/end_title` | « Fin de la veille » | titre de l'écran de fin de série |
| `arenas/<arène>/new_record` | « Nouveau record de veille ! » | bandeau du nouveau record |
| `fall/message` | « Tes ailes se sont ouvertes : te revoilà au bord. » | après un rattrapage de chute, sur un fondu au blanc |
| `defeat/fade` | « Retour à l'entrepôt… » | fondu au noir de la mort |
| `defeat/message` | « Les autres t'ont ramenée à l'entrepôt. » | à la réapparition |

Une arène sans entrée prend celles de `arenas/default` (`DialogueRunner.arena_text`). Une
nouvelle arène (île n° 15, M3) ajoute son objet `arenas/<arena_id>` ; un nouveau texte de
système, une clé de plus (et le code qui la lit). Toute clé qui commence par `_` est un
commentaire. Test : `tests/unit/test_story_texts.gd`.

## Poser un déclencheur

Une étape `reach` avec `"trigger": "forest_clearing"` attend que le joueur entre dans le
déclencheur de ce nom : une instance de `src/quests/quest_trigger.tscn` (cylindre vertical qui ne
détecte que le joueur), posée dans le fichier d'emplacement des PNJ de la zone,
`src/npc/placements/<zone>.tscn`, en coordonnées locales à la zone (sol à y = 0) :

```
[ext_resource type="PackedScene" path="res://src/quests/quest_trigger.tscn" id="5_trigger"]

[node name="forest_clearing" parent="." instance=ExtResource("5_trigger")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
trigger_id = &"forest_clearing"
radius = 6.0
set_flag = &"forest_clearing_seen"
```

- `trigger_id` : le nom que citent les étapes (par défaut, le nom du nœud) ; unique sur l'île.
- `radius` (2 m) et `height` (3 m) : taille du cylindre, posé sur le sol.
- `set_flag` (facultatif) : drapeau posé à chaque entrée du joueur.
- Le placer au sol, hors du décor, atteignable à pied depuis le village (`tests/integration/
  test_m1_world.gd` le vérifie pour tout ce qui est posé dans les emplacements).
- Exemple complet : `tests/data/placements/village.tscn` (un PNJ et un déclencheur) et
  `tests/data/placements/forest.tscn`.

## Tester une quête

1. **Vérifier les données** : `tools/test.sh tests/unit/test_quest_content.gd`. Chaque quête de
   `data/quests` doit être un JSON valide dont tous les renvois existent : PNJ (avec un
   dialogue), objets, ennemis, zones, arènes, déclencheurs posés, quêtes prérequises (sans
   cycle) ; chaque quête sans `auto_start` doit être proposée par un dialogue (`start_quest`) ;
   les dialogues ne nomment que des quêtes, étapes et objets qui existent ; titres et objectifs
   assez courts pour le HUD. Un échec liste tous les problèmes avec leur fichier.
2. **Jouer le scénario** : copier `tests/unit/test_quest_example.gd` en
   `tests/unit/test_quest_<id>.gd` et jouer chaque étape avec les raccourcis de
   `tests/stubs/q_quest_test.gd` (vrai moteur, vrais dialogues, sans scène de jeu) :

   | Raccourci | Effet |
   | --- | --- |
   | `talk(find_npc(&"blacksmith"), [0, -1])` | conversation avec le vrai dialogue du PNJ ; réponses dans l'ordre (rang du choix, -1 = suite) ; renvoie les répliques |
   | `chat(&"blacksmith")` | conversation sans dialogue (début, fin) |
   | `enter_zone(&"forest")`, `enter_trigger(&"forest_clearing")` | le joueur entre dans une zone, un déclencheur |
   | `kill(&"timere_small", 2)` | ennemis vaincus (dans la zone courante) |
   | `reach_wave(&"dunes", 3)`, `reach_score(&"dunes", 300)` | arène |
   | `GameState.add_item(&"shell", 2)`, `GameState.set_flag(&"x")` | objets, drapeaux |
   | `start_quest(&"id")`, `complete_quest(&"id")` | démarrer, terminer d'office (objets manquants donnés) |
   | `step_of(&"id")`, `count_of(&"id")`, `QuestData.state_of(&"id")`, `QuestData.npc_marker(&"pnj")` | étape courante, compteur, état, marqueur |
   | `write_quest({…})` | quête écrite par le test lui-même |

   Puis `tools/test.sh tests/unit/test_quest_<id>.gd`.
3. **Dans le jeu** : lancer la partie, ouvrir le journal (Tab) à chaque étape. Les raccourcis
   `?zone=<id>` de l'adresse (docs/web.md) mènent directement à une zone.
4. Avant la PR : `tools/check.sh` complet.

## Sauvegarde et évolution des quêtes

- L'état de chaque quête, son étape courante (par son `id`) et son compteur, ainsi que la quête
  suivie, sont sauvegardés (schéma v2 ; les sauvegardes v1 sont migrées : chaque quête en cours
  reprend à sa première étape). Une étape validée déclenche une auto-sauvegarde.
- Après publication : ne pas renommer une quête ni une étape. Une étape disparue ou renommée
  ramène les joueurs qui y étaient à la première étape de la quête ; ajouter des étapes à la fin
  ou en cours de route est sans risque pour ceux qui ne les ont pas encore atteintes.

## Limites connues

- Étapes linéaires : ni branches, ni étapes facultatives ou simultanées. Pour un choix qui change
  la suite, deux quêtes et un drapeau (`requires.flags` / `not_flags`).
- `kill` avec `zone` : c'est la zone du **joueur** au coup fatal qui compte.
- `arena` : seules les séries jouées pendant l'étape comptent.
- Une seule quête affichée par le HUD (la quête suivie) ; les autres dans le journal.
- Contrôles tactiles : pas encore de bouton Journal (demande au Lot 9, docs/CONTRACT_REQUESTS.md).

## Référence pour les développeurs

- `src/quests/quest_data.gd` (`QuestData` : lecture et vérification du JSON, `find`, `all`,
  `status`, `current_step`, `npc_marker`, `shown_quest`), `quest_step.gd` (`QuestStep`),
  `quest_tracker.gd` (`QuestTracker`, nœud de `src/game.tscn`), `quest_trigger.gd/.tscn`.
- EventBus : `flag_changed`, `quest_step_updated`, `quest_step_completed`,
  `quest_advance_requested`, `trigger_entered`, `tracked_quest_changed` ; GameState :
  `quest_step`, `quest_step_count`, `set_quest_step`, `quest_progress`, `tracked_quest`.
  Contrats : PLAN.md section 3 ; choix : docs/DECISIONS.md, section « Lot Q ».
- (Systèmes et textes) `DialogueRunner` : `format_text` (`{player}` et les autres variables),
  `player_name`, `player_skin`, `current_speaker_id` (orateur de la réplique en cours, lu par
  `DialogueBox`), `find_npc` / `add_npc_dir` / `remove_npc_dir`, `evaluate` et
  `condition_problem` (conditions des dialogues et de `visible_if`), `story_text`, `arena_text`,
  `load_story_texts`, `story_problem`, `clear_story_cache`. `NpcData.visible_if`,
  `is_present()`, `is_player_skin()`, `visible_if_problem()` ; `Npc.is_present()`,
  `refresh_presence()`. `WorldManager.rescued(zone_id)` (rattrapage de chute) ; HUD :
  `show_story_message`, `story_message`, `quest_title` ; le journal du HUD est
  `src/ui/hud_journal.gd` (journal.gd + `{player}`).
