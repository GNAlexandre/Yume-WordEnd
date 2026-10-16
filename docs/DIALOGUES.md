# Écrire des dialogues

Les conversations du jeu sont **des données** : un fichier JSON par conversation, lu par
`DialogueRunner` (`src/npc/dialogue_runner.gd`) et affiché par la boîte de dialogue. Ce document
décrit leur format, les conditions et les effets qu'elles peuvent porter, le nom du joueur
(`{player}`), les scènes à plusieurs voix (`speaker_id`), la présence des PNJ (`visible_if`) et
les textes de l'histoire hors dialogues (`data/texts/story.json`).

(F1) Ce document remplace `docs/QUETES.md` : le moteur de quêtes (quêtes en étapes, journal,
marqueurs « ! » / « ? », déclencheurs de lieu, arènes) est parti avec l'ancienne île. L'histoire
de l'acte 1 se joue en scènes (`data/scenes/<île>/`, `src/story/`) ; les conversations libres
d'un personnage, hors des scènes, sont dans `data/dialogues/<île>/talk/<pnj>.json`.

## En bref

1. Écrire la conversation : `data/dialogues/<île>/talk/<pnj>.json` pour ce qu'un PNJ dit hors
   des scènes (StoryDirector la lance quand on lui parle), ou le dialogue d'une scène.
2. Si elle cite un nouvel objet ou un nouveau PNJ : `data/items/<id>.tres` (et son icône),
   `data/npcs/<id>.tres` (voir CLAUDE.md, recette des fichiers).
3. Vérifier : `tools/test.sh tests/unit/test_dialogue_effects.gd` (chaque dialogue du jeu est
   valide), `tools/test.sh tests/unit/test_sys_story_content.gd` (orateurs, `visible_if`), puis
   `tools/check.sh`.

## Le format

```json
{
  "_comment": "Ce que dit Nephren hors des scènes.",
  "id": "talk_nephren",
  "start": "hello",
  "entries": ["late", "day_two"],
  "nodes": {
    "day_two": {
      "if": { "day": 2 },
      "speaker_id": "nephren",
      "text": "Livre. Vent. Pages.",
      "choices": [
        { "text": "Je les retrouve.", "set_flag": "pages_promised", "next": "go" },
        { "text": "Plus tard.", "next": null }
      ]
    },
    "go": { "text": "Mm. Salle de lecture.", "next": null },
    "late": { "if": { "flag": "pages_promised" }, "text": "Encore {left:page:5}. Mm.", "next": null },
    "hello": { "text": "Mm.", "next": null }
  }
}
```

- `start` (obligatoire) et `entries` nomment des nœuds de `nodes`. Les **entrées** sont essayées
  dans l'ordre : `done` (nom réservé, toujours en premier s'il existe), puis `entries`, puis
  `start` ; la première dont le `if` est vrai ouvre la conversation. On met donc les cas les plus
  précis d'abord.
- Un nœud : `text` (obligatoire), `speaker` (nom affiché), `speaker_id` (voix d'un autre PNJ, plus
  bas), `if`, `next` (nœud suivant, `null` : fin), `choices` (au plus 2 ; chacun `text`, `if`,
  `next`), et ses effets. Une clé inconnue (faute de frappe) rend le dialogue invalide, sauf une
  clé qui commence par `_` (commentaire).
- Un nœud atteint par `next` est affiché même si son `if` est faux.

### Conditions (`"if"`, toutes doivent être vraies)

| Condition | Valeur | Vraie si… |
| --- | --- | --- |
| `flag` / `not_flag` | un nom ou une liste | tous les drapeaux sont posés / aucun ne l'est |
| `count` | `[objet, minimum]` | le joueur a au moins `minimum` objets |
| `day` | un jour (≥ 1) ou `[premier, dernier]` | le jour de l'acte (`GameState.day`) est celui-là ou dans l'intervalle |
| `slot` | un créneau ou une liste (`aube`, `matin`, `midi`, `apres_midi`, `soir`, `nuit`) | le créneau courant (`LifeSlots.current()`) en est un |
| `scene` / `not_scene` | un id de scène ou une liste | toutes ces scènes sont jouées / aucune ne l'est (`GameState.is_scene_done`) |

La grammaire n'a pas de « ou » : toutes les clés doivent être vraies. Les mêmes conditions
décident de la présence des PNJ (`visible_if`, plus bas). (F1) Les conditions `quest`,
`quest_step`, `not_quest_step` et `best_score` de l'ancienne île n'existent plus : un dialogue qui
les emploie est invalide.

### Effets (sur un nœud ou un choix)

| Effet | Valeur | Ce qu'il fait |
| --- | --- | --- |
| `take_item` | `"objet"`, `["objet", n]` ou `{"objet": n, …}` | retire les objets ; s'il en manque un, rien n'est retiré (avertissement) : le protéger par une condition `count` |
| `give_item` | mêmes formes | donne les objets |
| `set_flag` / `clear_flag` | un nom ou une liste | pose / retire des drapeaux |

### Ordre d'évaluation

1. Choix de l'entrée : `done`, puis `entries` dans l'ordre, puis `start` ; le premier nœud dont
   le `if` est vrai.
2. Le nœud s'affiche : ses effets s'appliquent d'abord, **toujours dans cet ordre**, quel que soit
   l'ordre d'écriture : `take_item`, `give_item`, `set_flag`, `clear_flag`.
3. Puis son texte est calculé (`{count:objet}`, `{left:objet:n}` voient l'état après les effets)
   et ses choix filtrés par leur `if` (après les effets du nœud aussi).
4. Un choix choisi : ses effets (même ordre), puis son `next`.

### Bonnes pratiques

- Répliques de moins de 160 caractères, choix de moins de 32 (2 choix au plus par nœud).
- Typographie des dialogues existants : espace insécable avant `!`, `?`, `:` et `;`, apostrophe
  typographique `’`, points de suspension `…`.
- Identifiants en anglais (`snake_case`), textes en français. Le canon et les spoilers suivent
  `docs/lore/PLAN.md` (à lire avant d'écrire l'histoire).
- Jamais le nom du joueur en dur : `{player}` (ci-dessous), sinon « tu ».

### Le nom du joueur : `{player}`

`{player}` est remplacé par le **prénom** de la protagoniste : le nom affiché du skin choisi
(`SkinData.display_name` de `GameState.skin_id`, sinon le skin par défaut), sans sa variante
(ce qui suit « · » : « Ithea Myse Valgulious · 3D ») et réduit à son premier mot (une fée adulte
ajoute à son prénom une particule et le nom de son Carillon) : « Chtholly » pour « Chtholly Nota
Seniorious · 3D », « Ithea » pour « Ithea Myse Valgulious · 3D », « Chtholly » si le nom est vide
(`DialogueRunner.player_name()`, `first_name()`). Les répliques appellent la protagoniste comme
on l'appelle dans l'œuvre, par son prénom (« Alors reviens, {player} », « Mlle {player} ») ; ne
pas écrire un nom de skin sans prénom en tête. Il marche partout où le joueur lit du texte de
dialogue : répliques, choix, `speaker` d'un nœud (`"speaker": "{player}"` quand la protagoniste
parle), textes de l'histoire (`data/texts/story.json`). Il se combine avec `{count:…}` et
`{left:…}` (`tests/unit/test_player_name.gd` vérifie la règle du prénom). Avec parcimonie : les
autres personnages appellent souvent la protagoniste autrement (« mademoiselle », « guerrière »).

### Plusieurs voix : `speaker_id`

Un nœud peut être dit par un autre PNJ que celui du dialogue : `"speaker_id"` nomme ce PNJ
(`data/npcs/<id>.tres`, ou une fée générique de `data/npcs/generic/`). La boîte de dialogue
montre alors **son portrait** (celui de son skin) et, sans `"speaker"`, **son nom** ; le nœud
suivant sans `speaker_id` revient au PNJ du dialogue.

```json
"night": {
  "speaker_id": "willem",
  "text": "Dors. Pas un mot de plus.",
  "next": "coffee"
},
"coffee": {
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

## La présence des PNJ : `visible_if`

Un PNJ n'est là que si la condition `visible_if` de ses données (`NpcData`, `data/npcs/<id>.tres`)
est vraie : **même grammaire et même évaluateur** que le `"if"` d'un nœud de dialogue (drapeaux,
objets, jour, créneau, scènes jouées). Sans `visible_if` (`{}`), il est toujours là. Absent, il est
caché, sans collision (on traverse sa place), sans invite « Parler » et sans dialogue. La présence
est réévaluée en fin d'image quand un drapeau, l'inventaire ou le skin changent, et au chargement
d'une partie ; un PNJ en pleine conversation ne part qu'à la fin de celle-ci.

```
# data/npcs/<id>.tres : présent les jours 2 et 3, tant que le drapeau « away » n'est pas posé
visible_if = {
"day": [2, 3],
"not_flag": "away"
}
```

Dans un `.tres`, les identifiants s'écrivent comme dans le JSON, entre guillemets (`"away"` ;
`&"away"` est aussi accepté). Pour « à partir de tel moment et pour toujours », poser un drapeau
(effet d'une réplique ou d'une scène) et le tester (`"flag"`).

Le skin du joueur prime : **le PNJ dont le skin est celui que le joueur a choisi n'est jamais
là** (la fée de la communauté choisie comme héroïne n'est pas aussi un PNJ ; Chtholly n'est
jamais un PNJ). Les dialogues de cette fée l'appellent alors par `{player}`.

Vérifier : `tools/test.sh tests/unit/test_sys_story_content.gd` (chaque `visible_if` est une
condition valide) ; le mécanisme : `tests/unit/test_npc_presence.gd`.

## Les textes de l'histoire : `data/texts/story.json`

Les textes que les systèmes affichent hors dialogues vivent dans un seul fichier de données, lu
par `DialogueRunner.story_text("chemin/de/la/clé")` (variables et `{player}` remplacés) :

| Clé | Texte | Où |
| --- | --- | --- |
| `fall/message` | « Tes ailes se sont ouvertes : te revoilà au bord. » | après un rattrapage de chute, sur un fondu au blanc |
| `defeat/fade` | « Retour à l'entrepôt… » | fondu au noir de la mort |
| `defeat/message` | « Les autres t'ont ramenée à l'entrepôt. » | à la réapparition |
| `maps/waiting/…` | l'écriteau des cartes d'attente | `src/world/props/waiting_sign.gd` |
| `travel/caption`, `travel/dock_prompt` | « En dirigeable, cap sur {island} » | voyage entre îles |
| `desktop/…` | boutons de l'application de bureau | `DesktopApp` |
| `save/migrated` | « Ta partie se passait sur l'ancienne île, qui n'existe plus : l'histoire reprend au premier jour. » | (F1) menu, au chargement d'une sauvegarde d'avant la refonte |

Un nouveau texte de système, une clé de plus (et le code qui la lit). Toute clé qui commence par
`_` est un commentaire. Test : `tests/unit/test_story_texts.gd`.

## Tester un dialogue

- Tout dialogue de `data/dialogues/` est vérifié par `tests/unit/test_dialogue_effects.gd`
  (`DialogueRunner.validate`) ; un dialogue de test va dans `tests/data/dialogues/` (exemple :
  `l6_nephren.json`, joué par `tests/unit/test_dialogue_flow.gd` avec de vrais appuis).
- Un PNJ de test (`tests/data/npcs/`) se trouve par `DialogueRunner.add_npc_dir` ; un objet de
  test (`tests/data/items/`) par `ItemData.add_search_dir`. Les retirer dans `after_each`.

## Référence pour les développeurs

- `DialogueRunner` : `format_text` (`{player}` et les autres variables), `player_name`,
  `player_skin`, `current_speaker_id` (orateur de la réplique en cours, lu par `DialogueBox`),
  `find_npc` / `add_npc_dir` / `remove_npc_dir`, `evaluate` et `condition_problem` (conditions
  des dialogues et de `visible_if`), `apply_effects`, `validate`, `story_text`,
  `load_story_texts`, `story_problem`, `clear_story_cache`.
- `NpcData.visible_if`, `is_present()`, `is_player_skin()`, `visible_if_problem()` ;
  `Npc.is_present()`, `refresh_presence()`.
- `WorldManager.rescued(map_id)` (rattrapage de chute) ; HUD : `show_story_message`,
  `story_message`.
- EventBus : `flag_changed`, `inventory_changed`, `dialogue_started`, `dialogue_line`,
  `dialogue_choice_made`, `dialogue_ended`. Contrats : PLAN.md section 3 ; choix :
  docs/DECISIONS.md.
