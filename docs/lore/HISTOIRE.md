# L'histoire et les quêtes de WordEnd 3D

Document de direction narrative (phase B de `docs/lore/PLAN.md`) : arc principal, quêtes,
personnages, objets, ennemis, guide de ton et développements nécessaires. Le cadre, la carte et les
lieux sont dans [MONDE.md](MONDE.md) ; le joueur y est défini (section 1.2) : **la fée qui porte
Seniorious, aînée de l'entrepôt de l'île n° 68, par défaut Chtholly**.

Conventions : `(V1, chap. « … »)` renvoie aux fiches `docs/lore/volumes/vol<N>.md` (traduction Yume
Novel, `VEX` pour le volume EX) et à [BIBLE.md](BIBLE.md) ; **(original)** marque une invention ;
**SPOILER V<n>** signale ce que révèle le volume n (niveau S<n> de la bible). Les quêtes sont écrites
avec les briques du moteur de quêtes (format complet : `docs/QUETES.md`) :

- quête : `id`, `title`, `summary` (journal), `giver`, `main`, `auto_start`, `requires`
  (`quests`, `flags`, `not_flags`), `steps`, `rewards` ;
- étape : `id`, `type`, `objective` (texte du HUD), `hint` (journal), `rewards` ; `talk` → `npc` ;
  `reach` → `zone` ou `trigger` ; `kill` → `enemy` (id ou `any`), `count`, `zone` ; `collect` →
  `item`, `count`, `consume`, `npc` (« rapporter à ») ; `arena` → `arena` et `wave` ou `score` ;
  `flag` → `flag` ;
- récompenses : `items`, `flags`, `max_hp` (**valeur à atteindre**, pas un ajout : « PV max → 6 ») ;
- dialogues : conditions `flag`, `not_flag`, `count`, `quest`, `quest_step`, `best_score` ; effets
  `take_item`, `give_item`, `set_flag`, `clear_flag`, `start_quest`, `advance_quest`,
  `complete_quest` ; un nœud peut changer de `speaker`, ce qui permet les scènes à plusieurs voix.

## 1. Principes

- **L'histoire suit l'ordre de lecture.** Un acte par jalon, un volume (ou deux) par acte ; un acte
  ne révèle rien des volumes suivants (MONDE.md, section 1.5).
- **Le canon fait foi** ; l'original le complète là où il se tait (la vie quotidienne de l'entrepôt,
  les fragments de Timere sur l'île n° 68, les petites quêtes).
- **Le joueur vit les grandes scènes de l'intérieur** (la promesse, l'île n° 15, le retour), mais les
  actes décisifs du canon restent ceux du canon : on ne sauve pas ceux que le livre ne sauve pas, on
  n'ajoute pas de victoire qui contredise la suite.
- **Écriture des textes du HUD** : infinitif, 60 caractères au plus, sans mot d'heure avant le cycle
  jour/nuit (M3) ; jamais le nom du joueur en dur : `{player}` (développement n° 2), sinon « tu ».

## 2. Arc principal

| Acte | Jalon | Volumes | Lieux | Fil | Se termine sur |
| --- | --- | --- | --- | --- | --- |
| 1 « Dans la forêt céleste » | M2 | V1 (+ VEX, 2e épisode) | île n° 68 | l'arrivée de Willem, la saison des rejetons, la veille, la promesse | la nuit de la promesse, veille du départ |
| 2 « Le chemin du retour » | M3 | V2 | îles n° 15, 11, 68 | la bataille de l'île n° 15, Collina di Luce, le retour, le coma | « Bienvenue à la maison » |
| 3 « Le rayonnement actuel » | M4 | V3 | îles n° 68 et 49, la surface | le gâteau promis, l'oubli, Gomag, la dernière bataille | Tiat et la broche, deux semaines après |
| 4 « La relève » | M5 | V4, V5 (+ VEX, 1er épisode, en bonus) | Gomag en rêve, île n° 11, île n° 68 | le rêve de Gomag, Collina di Luce, Lakhesh et Seniorious | des années plus tard, un retour à l'entrepôt |

### Acte 1 — « Dans la forêt céleste » (M2, volume 1)

Titre repris du chapitre 2 du volume 1. Il remplace la tranche verticale actuelle sur l'île
principale, avec les cinq zones existantes. Le matin qui suit la nuit du grand vent, l'aînée de
l'entrepôt fait la connaissance du nouvel officier responsable, l'homme sans traits croisé au Market
Medley de l'île n° 28 (V1, chap. « Le chat qui filait et la jeune fille », « L'Homme sans Marque »).
Le vent a aussi semé des rejetons de Timere dans les bois **(original)** : elle les abat, ramène
Pannibal partie les « embusquer », puis tient la première veille au bord du Couchant. La fièvre du
venenum lui fait avouer ce qu'elle cachait : dans cinq jours, elle part pour l'île n° 15 et ne
compte pas revenir (V1, chap. « Les valeureux et leurs successeurs »). Willem la bat sans effort au
terrain d'entraînement, lui dit qu'elle peut devenir plus forte et qu'elle doit donc revenir, puis
chancelle ; seule au bord de l'île, elle est recueillie par le Barocupot, où Limeskin lui parle de
résolution et de résignation (V1, chap. « La fille errante et le lézard volant »). La nuit, sur la
colline, Willem règle Seniorious et promet un gâteau au beurre si elle revient (V1, chap. « Le ciel
étoilé sous le ciel étoilé »). Entre ces étapes, six quêtes secondaires tirées du quotidien de
l'entrepôt. Après la promesse, M2 reste jouable : ce sont les derniers soirs avant le départ.

### Acte 2 — « Le chemin du retour » (M3, volume 2)

Les trois aînées s'envolent dans le soleil couchant (V1, chap. « Même après la fin de cette guerre »).
Sur l'île n° 15, cinq jours de combat contre un Timere qu'il faut tuer encore et encore et qui renaît
chaque fois sous une autre forme ; au fond des failles de l'île **(original)**, la porteuse plante
Seniorious dans le sol de l'île et la fait tomber, au prix de presque toute sa vie, quand une Bête
inconnue sort de la carapace de Timere (SPOILER V2, chap. « Chasseur d'âmes — A »). À Collina di
Luce, retrouvailles avec Willem, puis l'affaire Phyr : une lettre de menace, une visite de la ville,
une embuscade de voyous qu'on assomme sans les tuer (V2, chap. « Un Résultat », « Le bon usage de
l'amour et de la justice », « Le mauvais usage de l'amour et de la justice »). Renvoyée à l'île
n° 68, elle cache son état jusqu'à ce qu'une inconnue aux yeux rouges la regarde dans le miroir ;
coma, rêve de ruines où une enfant nommée Elq la guide, puis réveil sur une phrase de Willem à
laquelle elle ne peut pas répondre (SPOILER V2, chap. « L'écoulement du temps depuis lors »,
épilogue). Le jalon M3 y trouve ses deux zones (champ de bataille de l'île n° 15, Collina di Luce),
son donjon à clés et son boss (Timere qui renaît), ses deux nouveaux ennemis (la gerbe de lianes, les
voyous à assommer) et le cycle jour/nuit (la veille du départ, les nuits du front).

### Acte 3 — « Le rayonnement actuel » (M4, volume 3)

Réveil à l'infirmerie, des mèches rouges dans les cheveux ; l'examen de Nygglatho : elle n'est plus
une fée soldat et ne doit plus toucher un Carillon. Willem cuit enfin le gâteau au beurre : la
promesse de l'acte 1 est tenue, et elle comprend qu'elle est vraiment rentrée (SPOILER V3, chap.
« Je suis à la maison »). Puis les oublis, la nuit des comètes, le secret d'Ithea, la fièvre de
Collon, le café avec Limeskin, l'île n° 49, le Plantaginesta et la surface : Gomag, Nopht et
Rhantolk, Desperatio, le cercueil de glace, la marée de Timere de 18 h 26 à 18 h 51, la chute de
Nephren et de Willem, le dernier retour accordé par Elq et la dernière bataille avec Desperatio
(SPOILER V3). L'épilogue se joue en Tiat, qui s'entraîne avec la broche. Particularité : le joueur
n'a plus d'épée jusqu'à la fin (il porte, guide, lance l'huile, se cache). M4 relie le jeu à
yumenovel.fr : classement des veilles du Couchant (jamais de classement sur la dernière bataille),
verrou de lecture par volume.

### Acte 4 — « La relève » (M5, volumes 4 et 5)

Partie A, en Nephren : le rêve de Gomag d'hiver, l'orphelinat, Almaria, la guilde, la nuit de la fin
et le Chanteur (SPOILER V4). Partie B, en « relève » (Lakhesh par défaut, Tiat ou une fée de la
communauté) : le printemps à l'entrepôt menacé de dissolution, Collina di Luce, l'attaque des Auroras
au marché du matin, l'armure d'Elpis, le choix de Willem et le geste de Lakhesh avec Seniorious, puis
l'épilogue des années plus tard (SPOILER V5). Bonus du volume EX : les rêves de Seniorious, où l'on
joue Lillia **(original, d'après le VEX)**. Après M5 : la suite de la série quand Yume la traduira.

## 3. Acte 1 : fiche de production (M2)

Tout se produit avec les briques du moteur. Coordonnées **locales à la zone** (celles des fichiers
`src/npc|enemies|items/placements/<zone>.tscn`), y = hauteur du sol. Les identifiants techniques
sont en anglais, les textes en français.

### 3.1 Quête principale `act1_main` — « Dans la forêt céleste »

- `main` : vrai ; `auto_start` : vrai (dès la nouvelle partie) ; `giver` : `nygglatho` ; `requires` :
  rien ; récompense de fin : drapeau `act1_done`.
- `summary` : « La nuit du grand vent, le nouveau responsable est arrivé à l'entrepôt, et le vent a
  semé des rejetons de Timere dans les bois. Tu es l'aînée : veille sur l'île, et prépare ton départ
  pour l'île n° 15. »

| # | `id` | Type | Cible | `objective` (HUD) | Zone | Récompense d'étape | Source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `morning` | `talk` | `npc: nygglatho` | Rejoindre Nygglatho sous le porche | village | — | V1, « L'Homme sans Marque » ; rejetons **(original)** |
| 2 | `new_officer` | `talk` | `npc: willem` | Saluer le nouveau responsable | village | drapeau `met_willem` | V1, « L'Homme sans Marque », « Directeur en carton » |
| 3 | `to_the_woods` | `reach` | `zone: forest` | Gagner les bois du marais, au nord | forest | — | **(original)** |
| 4 | `rejetons` | `kill` | `enemy: any`, `count: 4`, `zone: forest` | Abattre les rejetons de Timere dans les bois | forest | — | **(original)** |
| 5 | `pannibal` | `talk` | `npc: pannibal` | Ramener Pannibal, partie en chasse au marais | forest | — | V1, « L'Homme sans Marque » ; **(original)** |
| 6 | `report` | `talk` | `npc: nygglatho` | Faire ton rapport à Nygglatho | village | — | précognition (V1) ; veille **(original)** |
| 7 | `first_vigil` | `arena` | `arena: dunes`, `wave: 3` | Tenir la veille du Couchant jusqu'à la 3e vague | dunes | drapeau `first_vigil_done` | **(original)** |
| 8 | `fever` | `talk` | `npc: willem` | Laisser Willem soigner ta fièvre | village | drapeau `departure_told` | V1, « Entrepôt de fées », « Les valeureux et leurs successeurs » |
| 9 | `training` | `talk` | `npc: willem` (repli : `willem_training`) | Retrouver Willem au terrain d'entraînement | forest | drapeau `duel_lost` | V1, « Les valeureux et leurs successeurs », « La femme forte et robotique » ; VEX, « Chtholly Nota Seniorious » |
| 10 | `the_edge` | `reach` | `trigger: couchant_edge` | Aller seule au bord de l'île, face au couchant | dunes | — | V1, « La fille errante et le lézard volant » (adapté) |
| 11 | `barocupot` | `talk` | `npc: limeskin` | Monter à bord du Barocupot, au port | beach | — | V1, « La fille errante et le lézard volant » |
| 12 | `starry_hill` | `reach` | `trigger: hill_summit` | Gravir la colline des étoiles | hill | — | V1, « Le ciel étoilé sous le ciel étoilé » |
| 13 | `promise` | `talk` | `npc: willem` (repli : `willem_stars`) | Écouter Willem, au sommet | hill | objet `butter_cake_promise` ×1, PV max → 6, drapeau `act1_promise` | V1, « Le ciel étoilé sous le ciel étoilé » |

Aides du journal (`hint`) : étape 2, « Il attend près de la porte rivetée de la salle des armes » ;
étape 4, « Ils rôdent autour du terrain d'entraînement » ; étape 7, « Sonne la cloche du vieux poste
de guet pour commencer la veille » ; étape 10, « Si tu sautes, tes ailes te ramèneront ».

**Idées des dialogues clés** (à écrire pour le jeu ; ne rien recopier des volumes) :

1. **Nygglatho**, toute en sourires : la nuit a soufflé fort ; le nouveau responsable est arrivé
   dans le noir, il a l'air délicieux, elle le mangerait s'il n'était pas si maigre ; Pannibal l'a
   « accueilli » au marais. Puis, sans changer de sourire : à l'aube, le cristal de communication a
   transmis un message de la Garde, des rejetons de Timere sont tombés dans les bois ; minuscules,
   mais ça grandit. Ithea et Nephren gardent les petites ; toi, tu es l'aînée. « Va d'abord saluer
   le nouveau. » Deux choix (« J'y vais. » / « Le nouveau ? »), même suite. Pour qui n'a rien lu, la
   scène pose l'entrepôt, les fées, l'officier, Timere et les Carillons, sur un ton léger.
2. **Willem**, mal à l'aise dans un uniforme trop étroit et un titre trop grand (sous-officier des
   Armes Enchantées). Il reconnaît la fille du Market Medley qui lui avait demandé de l'oublier.
   Choix : « On se connaît ? » (elle fait semblant) / « Tu devais m'oublier. » (il dit qu'il a fait
   de son mieux). Il jette un œil à Seniorious, la trouve mal réglée ; elle lui interdit d'y
   toucher. Puis trois conseils, sans dire d'où il les tient : enchaîner trois coups, le dernier
   repousse ; tenir la charge, le venenum prend lentement comme un feu, puis l'onde traverse tout ;
   verrouiller sa cible quand ils sont plusieurs (ce sont les conseils de l'ancien forgeron).
3. —
4. —
5. **Pannibal**, impassible, une brindille à la bouche : fière de son embuscade de la nuit, elle
   voulait en tendre une aux rejetons avec son épée de bois ; conseils violents (« toujours viser
   les genoux »). Choix : « Rentre. Tout de suite. » / « Montre-moi ton embuscade. » (elle essaie, tu
   esquives sans y penser). Elle repart en promettant de recommencer sur le nouveau.
6. **Nygglatho** : la précognition de la Garde annonce d'autres rejetons avec le vent du soir, sur
   le bord ouest ; il faut « tenir la veille » : sonner la vieille cloche du poste de guet et les
   abattre avant qu'ils prennent racine. Elle remarque, l'air de rien, que le nouveau t'a regardée
   partir.
7. Pendant la veille, le guetteur de la Garde commente le vent ; Tiat accourt à la fin (sa quête
   s'ouvre).
8. **Willem**, puis **Nephren** comme second orateur. La veille t'a donné la fièvre du venenum
   (l'intoxication, V1) ; Willem sait la dénouer en pressant les bons points du dos. Dans la fièvre,
   tu en dis trop. Choix : « Dans cinq jours, je dois ouvrir les portes. » / « Rien. Laisse-moi
   dormir. » (dans les deux cas, il a compris). Il te fait taire d'un baiser sur le front et dit de
   dormir ; pas de discours. À la porte, Nephren tient deux tasses de café très sucré : « Archives.
   Toute la nuit. » (V1 : ils lisent ensemble ce que sont les fées). L'expression « ouvrir les
   portes » (se faire exploser) est dite une fois, simplement.
9. **Willem**, un Carillon de série sur l'épaule (V1), propose un assaut « pour voir ». Le combat
   tient en trois répliques : il te désarme sans même s'essouffler ; il dit que tu peux devenir
   beaucoup plus forte, et donc que tu dois revenir ; puis il chancelle et s'assied. **Nygglatho**
   arrive en courant : « Il est juste fatigué » (elle sait que son corps est en ruine et ne le dit
   pas, V1) ; le cristal a confirmé le départ, dans trois jours, au couchant. Choix : « Encore une
   fois ! » / « … D'accord. »
10. Aucun dialogue : le bord, le vent, le vide. Si le joueur saute, le rattrapage (MONDE.md, section
    2.8) le ramène au bord, et l'étape est déjà validée.
11. **Limeskin**, au pied du Barocupot : de son navire, une fée seule qui regarde le vide se voit de
    loin. Un thé brûlant et amer. Il parle de résolution et de résignation comme de deux lames qui se
    ressemblent sans couper de la même façon (image originale, pas une citation) ; il ne ment pas, ne
    promet pas qu'elle reviendra ; il dit qu'un guerrier qui a un endroit où rentrer ne se bat pas
    pareil. Il ajoute que l'officier Willem a demandé Seniorious, ce soir, sur la colline. Choix :
    « Ce n'est pas la même chose ? » / « Merci pour le thé. »
12. —
13. **Willem**, au sommet. Il démonte Seniorious : les quarante et un talismans flottent autour d'eux
    comme des étoiles (effet visuel en M3 ; en M2, le texte le dit). Amusé, il en nomme quelques-uns
    d'inutiles : ne pas se brûler la langue, trouver le nord, imiter un miaulement, ne pas se couper
    les ongles trop court (V1). Il remet les résistances à zéro et monte un peu celle aux
    malédictions. Choix : « Épouse-moi. » (il refuse doucement : pour lui, c'est une enfant) /
    « Tu sais faire un gâteau au beurre ? » (il soupire : son maître l'a forcé à apprendre, quelqu'un
    le faisait mieux que lui). La promesse : il lui en fera manger une montagne, à condition qu'elle
    revienne. Elle sourit et lui dit de la laisser faire. Récompense : la promesse, un cœur de plus.

**Après la quête** (`act1_done`) : chaque PNJ a une réplique de veille de départ (Nygglatho repasse
les uniformes, Ithea « on revient, hein ? », Nephren « Mm. », Tiat « Revenez, mademoiselle », les
petites préparent un dessin, Willem a acheté du beurre et de la farine) ; Nygglatho annonce que la
suite est à l'acte 2, au prochain jalon.

### 3.2 Quêtes secondaires

#### `picture_book` — « Le livre d'images »

- **Origine** : V1, chap. « Les filles de l'entrepôt » (les petites racontent à Willem leur livre
  d'images, où les emnetwiht sont les méchants et les Braves les héros) ; pages dispersées par le
  vent **(original)**. Remplace la quête des pages.
- **Donneuse** : `nephren`. **Prérequis** : drapeau `met_willem`.
- **Résumé** : « Le grand vent a arraché les pages du livre d'images des petites et les a semées
  dans les bois. Nephren veut le livre entier pour la lecture du soir. »

| `id` | Type | Cible | `objective` |
| --- | --- | --- | --- |
| `pages` | `collect` | `item: page_fragment`, `count: 5`, `npc: nephren`, `consume: true` | Rapporter 5 pages du livre d'images à Nephren |
| `reading` | `talk` | `npc: willem` | Demander à Willem de lire le livre aux petites |

- **Lieux** : bois du marais, cinq pages au sol (les trois actuelles et deux nouvelles), dont deux au
  milieu des rejetons. Les rejetons ne les lâchent plus : Timere ignore les objets (V3) ; supprimer
  les `drops` de `data/enemies/timere_*.tres`.
- **Récompenses** : objet `picture_book`, drapeau `book_read`.
- **Dialogues clés** : Nephren en trois mots (« Livre. Vent. Pages. ») et la règle du silence de la
  salle de lecture. La lecture est une scène à plusieurs voix dans le dialogue de Willem : les
  petites expliquent que les emnetwiht faisaient du tort à tous les peuples et ont appelé les
  Bêtes, que les Braves les combattaient, qu'elles-mêmes sont des Braves ; Pannibal demande si les
  Braves aussi étaient inventés ; Willem, le dernier emnetwiht, répond doucement que ce n'est qu'un
  livre d'images et que les emnetwiht n'étaient sans doute que des gens, puis se tait.

#### `special_dessert` — « Le dessert spécial »

- **Origine** : V1, chap. « Directeur en carton » (les petites fuient Willem ; il les gagne avec un
  dessert : œufs, sucre, lait, crème, baies, gélatine d'os de poulet) ; avalanche de fillettes
  derrière une porte (V1, chap. « L'Homme sans Marque »).
- **Donneur** : `willem`. **Prérequis** : drapeau `met_willem`.
- **Résumé** : « Les petites fuient le nouveau responsable. Willem a un plan : un dessert. Il lui
  manque des œufs, des baies et de la crème. »

| `id` | Type | Cible | `objective` |
| --- | --- | --- | --- |
| `eggs` | `collect` | `item: eggs`, `count: 1` | Acheter des œufs au marché du port |
| `berries` | `collect` | `item: wild_berries`, `count: 3` | Cueillir 3 grappes de baies dans les bois |
| `cream` | `collect` | `item: fresh_cream`, `count: 1` | Demander de la crème au café La Clochette |
| `cook` | `talk` | `npc: willem` | Apporter les ingrédients à Willem |
| `hiding` | `talk` | `npc: collon` | Trouver où se cachent les petites |
| `served` | `talk` | `npc: lakhesh` | Appeler tout le monde au réfectoire |

- **Mécanique** : la marchande d'œufs et le serveur du café donnent leur objet une seule fois, dès
  que la quête est active (`give_item`, puis drapeaux `eggs_given`, `cream_given`) ; le dialogue de
  l'étape `cook` retire les cinq objets (`take_item`, protégé par des conditions `count`, comme le
  demande `docs/QUETES.md`).
- **Récompenses** : objet `dessert_cup`, drapeau `little_ones_trust_willem`.
- **Dialogues clés** : Willem a les recettes de son maître et, détail comique, les os de poulet pour
  la gelée sont déjà prêts. La marchande se méfie (« c'est pour l'entrepôt ? ») puis s'adoucit quand
  on lui dit que c'est pour des enfants. Collon, dans le grand arbre, « espionne le monstre » avec les
  autres ; elles dégringolent toutes en avalanche. Lakhesh, très polie, appelle au réfectoire. Après :
  les petites appellent Willem « Willie » ; Pannibal reste méfiante.

#### `flying_laundry` — « Le linge envolé »

- **Origine** : **(original)**, d'après V2, chap. « De ce côté-ci de l'écran » (rentrer le linge
  avec Nygglatho avant l'averse, puis le thé où elle explique Timere).
- **Donneuse** : `nygglatho`. **Prérequis** : drapeau `met_willem`.
- **Résumé** : « Le vent du soir a arraché les draps du toit et les a semés jusqu'aux bords de
  l'île. Un drap qui tombe dans les nuages ne revient jamais. »

| `id` | Type | Cible | `objective` |
| --- | --- | --- | --- |
| `sheets` | `collect` | `item: laundry_sheet`, `count: 5`, `npc: nygglatho`, `consume: true` | Rapporter 5 draps envolés à Nygglatho |
| `tea` | `talk` | `npc: nygglatho` | Prendre le thé avec Nygglatho |

- **Lieux** : port (2), bord du Couchant (1), colline (1), bois (1) ; aide : « Port, Couchant,
  colline, bois : le vent n'a rien épargné. »
- **Récompenses** : objet `cheesecake_slice`, drapeau `laundry_done`.
- **Dialogues clés** : elle menace gaiement de te manger s'il en manque un. Au thé, dans sa chambre
  (cheminée, service à thé), elle explique Timere sans drame : il se divise quand il meurt, seuls les
  Carillons le tuent, un fragment avale une île en quelques heures, la précognition voit venir les
  gros de loin (V1). Une plaisanterie gourmande pour finir, et une part de cheese-cake, son remède
  des jours tristes (VEX, chap. « Cinq cents ans »).

#### `vigil_register` — « Le registre des veilles »

- **Origine** : **(original)** ; remplace le défi des 300 points de l'enfant.
- **Donneuse** : `tiat`. **Prérequis** : drapeau `first_vigil_done`.
- **Résumé** : « Tiat note toutes tes veilles dans un carnet. Elle veut y inscrire un record digne
  de mademoiselle. »

| `id` | Type | Cible | `objective` |
| --- | --- | --- | --- |
| `wave4` | `arena` | `arena: dunes`, `wave: 4` | Atteindre la 4e vague d'une veille |
| `tell_tiat` | `talk` | `npc: tiat` | Raconter ta veille à Tiat |
| `score` | `arena` | `arena: dunes`, `score: 1000` | Faire 1 000 points en une seule veille |
| `record` | `talk` | `npc: tiat` | Faire inscrire ton record au registre |

- **Réglage** : on cumule environ 110, 310, 605 et 985 points à la fin des vagues 1 à 4 ; la 4e vague
  commence vers 605 points et 1 000 points tombent au début de la 5e, le critère M2 « atteignable
  par un joueur moyen ». À revoir après les essais de la communauté.
- **Récompenses** : PV max → 7, objet `tiat_drawing`, drapeau `vigil_record`. Que cette quête se
  termine avant ou après la principale, le joueur finit à 7 PV.
- **Dialogues clés** : Tiat vouvoie l'aînée (« mademoiselle »), boit son lait d'un trait pour
  grandir (V2), veut un jour une épée aussi grande que Seniorious (clin d'œil V2-V3), a essayé le thé
  à la moutarde « comme vous » (VEX, chap. « Cinq cents ans ») ; elle lit ton record avec
  `{best:dunes}` ; son dessin te montre avec une épée qui dépasse de la feuille.

#### `old_clock` — « L'homme-chat »

- **Origine** : VEX, chap. « Cinq cents ans », « L'homme-chat » (scènes qui se passent pendant le
  volume 1).
- **Donneuse** : `ithea`. **Prérequis** : drapeau `met_willem`.
- **Résumé** : « Ithea a vu Willem serrer la main d'un homme-chat très élégant au café. Et si on
  venait le recruter ailleurs ? »

| `id` | Type | Cible | `objective` |
| --- | --- | --- | --- |
| `cafe` | `talk` | `npc: cat_waiter` | Interroger le serveur du café |
| `rami` | `talk` | `npc: ramikeldi` | Trouver M. Rami devant sa maison |
| `gears` | `collect` | `item: clock_gear`, `count: 3` | Récupérer 3 engrenages de laiton |
| `comb` | `collect` | `item: clock_comb`, `count: 1` | Repêcher un peigne de carillon dans le marais |
| `repair` | `talk` | `npc: willem` | Porter les pièces à Willem |
| `chime` | `talk` | `npc: ramikeldi` | Écouter sonner l'horloge de M. Rami |

- **Lieux** : café et maison Limashenka (port) ; engrenages dans la vieille lanterne du poste de
  guet (Couchant, 2) et dans la ferraille du port (1) ; peigne d'une boîte à musique tombée dans le
  marais.
- **Récompenses** : objet `rami_card`, drapeau `rami_clock_fixed`.
- **Dialogues clés** : Ithea et ses ragots (« on va nous le prendre, nya-ha-ha ») ; elle et Nephren
  savaient tout et n'ont rien dit (gag du VEX). M. Rami, courtois : né sur l'île, parti il y a vingt
  ans faire commerce de tabac sur l'île n° 13, revenu après la mort de sa mère le mois dernier ; la
  vieille horloge de la maison, toute mécanique, sans cristal, s'est arrêtée et il voudrait
  l'entendre sonner encore une fois (une phrase, avec douceur). Willem, les pièces en main : à côté
  d'un Carillon, une horloge, c'est un jeu d'enfant. L'horloge joue une comptine. Dernier choix avec
  Willem : « Ne pars pas. » / « … Rien. » ; il ne comprend pas de quoi elle parle.

#### `forget_me_nots` — « Celles dont on se souvient »

- **Origine** : **(original)**, d'après VEX, chap. « Cinq cents ans » (Nygglatho n'a oublié aucune
  des fées parties sans revenir) et V1, chap. « Entrepôt de fées » (l'aînée à la broche, morte au
  combat).
- **Donneuse** : `nygglatho`. **Prérequis** : quête `flying_laundry` terminée.
- **Résumé** : « Nygglatho garde dans sa chambre un vase toujours fleuri. Elle te demande des
  myosotis, ceux de la colline. »

| `id` | Type | Cible | `objective` |
| --- | --- | --- | --- |
| `flowers` | `collect` | `item: flower_blue`, `count: 5`, `npc: nygglatho`, `consume: true` | Cueillir 5 myosotis pour le vase de Nygglatho |
| `vase` | `talk` | `npc: nygglatho` | Rester un moment avec Nygglatho |

- **Lieux** : colline (3), entrepôt (1), Couchant (1), bois (1).
- **Récompenses** : objet `pressed_forget_me_not`, drapeau `forget_me_nots_given`.
- **Dialogues clés** : le vase est « pour celles qui ne sont pas revenues » ; elle cite quelques
  noms, simplement (Tuca, Orco, VEX ; « l'aînée qui portait ta broche », V1) ; elle se souvient de
  chacune ; son sourire ne bouge pas. Elle te demande de revenir, pour ne pas avoir à rajouter de
  fleurs. Choix : « Je rentrerai. » / « … » ; elle te donne une fleur à faire sécher dans un livre.
  Pas de larmes à l'écran : Nygglatho pleure seule (V1, chap. « La femme forte et robotique »).

### 3.3 Emplacements de l'acte 1

**PNJ** (`src/npc/placements/<zone>.tscn`, nœud nommé comme le PNJ) :

| Zone | Nœud | `NpcData.id` | Position | Note |
| --- | --- | --- | --- | --- |
| village | `Nygglatho` | `nygglatho` | (−9, 0,2, −8,5) | sous le porche |
| village | `Willem` | `willem` | (−13,5, 0,2, 0) | près de la porte de la salle des armes |
| village | `Nephren` | `nephren` | (−4, 0,2, −9,5) | banc sous la fenêtre de la salle de lecture |
| village | `Ithea` | `ithea` | (3, 0,2, 2,5) | adossée au puits |
| village | `Tiat` | `tiat` | (−3,5, 0,2, 5) | ancienne place de l'enfant |
| village | `Collon` | `collon` | (10, 0,2, −10) | au pied du grand arbre |
| village | `Lakhesh` | `lakhesh` | (−12, 0,2, −6) | devant la fenêtre du réfectoire |
| village | `Almita` | `almita` | (11, 0,2, 7) | entre les draps |
| village | fées de la communauté | `fairy_<prénom>` | autour de la cour | à plus de 2 m des chemins et du Spawn |
| forest | `Pannibal` | `pannibal` | (−20, 0,2, −3) | au bord du marais |
| forest | `WillemTraining` | `willem_training` | (−9, 0,2, 10) | repli sans le développement n° 1 : banc du terrain |
| dunes | `GardeLookout` | `garde_lookout` | (−14, 0,2, −10) | facultatif, hors du cercle |
| beach | `Limeskin` | `limeskin` | (−20, 0,2, 12) | au bras d'ancrage du Barocupot |
| beach | `CatWaiter` | `cat_waiter` | (−14, 0,2, −6,5) | terrasse du café |
| beach | `EggVendor` | `egg_vendor` | (−24, 0,2, 2) | marché |
| beach | `SnackVendor` | `snack_vendor` | (−6, 0,2, 1) | snack |
| beach | `Ramikeldi` | `ramikeldi` | (26, 0,2, −6,5) | devant la maison Limashenka |
| beach | `Ferryman` | `ferryman` | (12, 0,2, 13) | tête de la passerelle |
| beach | `Baker` | `baker` | (−4, 0,2, −7) | porte de la boulangerie |
| hill | `WillemStars` | `willem_stars` | (3, 8,2, 0) | repli : sommet, à côté du belvédère |

Avec le développement n° 1, il n'y a qu'un `willem`, présent au village sauf pendant les étapes 9
(terrain d'entraînement) et 13 (sommet) ; sans lui, les deux instances de repli restent toujours là
et disent hors de leur étape une phrase d'ambiance (il s'entraîne seul ; il regarde le ciel).
Limeskin et le Barocupot n'apparaissent idéalement qu'à partir de l'étape 10 (le navire vient la
chercher) ; sans le développement, Limeskin reste au port et parle d'une escale de ravitaillement.

**Objets** (`src/items/placements/<zone>.tscn`, nœuds uniques `<zone>_<objet>_<n>`) :

| Zone | Nœud | `item_id` | Position | Note |
| --- | --- | --- | --- | --- |
| village | `village_flower_1` | `flower_blue` | (17, 0, 5) | déplacé : l'ancienne position (−17, 0, −3) tombe dans l'aile ouest |
| forest | `forest_page_1` à `_3` | `page_fragment` | inchangées | dans la clairière |
| forest | `forest_page_4`, `forest_page_5` | `page_fragment` | (−12, 0, −13), (11, 0, −7) | au pied des grands sapins ; côté est de la clairière |
| forest | `forest_berries_1` à `_3` | `wild_berries` | (14, 0, −12), (−16, 0, 12), (20, 0, 6) | sur des buissons à baies |
| forest | `forest_sheet_1` | `laundry_sheet` | (3, 0, 24) | dans un arbre près du portail nord |
| forest | `forest_comb_1` | `clock_comb` | (−32, 0, −8) | dans le marais |
| forest | `forest_flower_1` | `flower_blue` | (−8, 0, 18) | myosotis de réserve |
| dunes | `dunes_sheet_1` | `laundry_sheet` | (−16, 0, 1) | au pied de la ruine ouest (ajuster au décor) |
| dunes | `dunes_gear_1` | `clock_gear` | (−15, 0, −7) | vieille lanterne tombée |
| dunes | `dunes_gear_2` | `clock_gear` | (−5, 0, −18) | pied du pan de mur nord |
| dunes | `dunes_flower_1` | `flower_blue` | (8, 0, 19) | creux d'une dune |
| beach | `beach_sheet_1` | `laundry_sheet` | (−25, 0, 13) | remplace `beach_shell_1` |
| beach | `beach_sheet_2` | `laundry_sheet` | (27, 0, 14) | remplace `beach_shell_2` |
| beach | `beach_gear_1` | `clock_gear` | (30, 0, 10) | tas de ferraille |
| hill | `hill_flower_1`, `_2` | `flower_blue` | inchangées | |
| hill | `hill_flower_3` | `flower_blue` | (−22, 0, −10) | au pied ouest de la colline |
| hill | `hill_sheet_1` | `laundry_sheet` | (−2, 8, −3) | accroché au belvédère |

**Déclencheurs** (instances de `src/quests/quest_trigger.tscn`, cylindres posés sur le sol, dans le
fichier d'emplacement des PNJ de la zone, `src/npc/placements/<zone>.tscn`) :

| Zone | `trigger_id` | Position | `radius`, `height` | Rôle |
| --- | --- | --- | --- | --- |
| dunes | `couchant_edge` | (−21, 0, −12) | 3 m, 3 m | étape `the_edge` (à 3 m du vide, au nord des ruines) |
| hill | `hill_summit` | (1, 8, −3) | 4 m, 3 m | étape `starry_hill` (le sol du sommet est à 8 m) |

**Ennemis** : inchangés (quatre Timere libres dans les bois, vagues de `data/waves/dunes.json`).
Seuls changent les noms affichés (section 7.2).

### 3.4 Drapeaux de l'acte 1

| Drapeau | Posé par | Lu par |
| --- | --- | --- |
| `met_willem` | `act1_main` / `new_officer` | prérequis de `picture_book`, `special_dessert`, `flying_laundry`, `old_clock` ; répliques |
| `first_vigil_done` | `act1_main` / `first_vigil` | prérequis de `vigil_register` ; guetteur |
| `departure_told` | `act1_main` / `fever` | répliques de l'entrepôt (tout le monde sait) |
| `duel_lost` | `act1_main` / `training` | répliques de Pannibal, Ithea, Nephren (« Il est fissuré. », clin d'œil VEX) |
| `act1_promise`, `act1_done` | `act1_main` | répliques de veille de départ ; prérequis de l'acte 2 |
| `book_read`, `little_ones_trust_willem`, `laundry_done`, `vigil_record`, `rami_clock_fixed`, `forget_me_nots_given` | fins des quêtes secondaires | répliques des PNJ concernés |
| `eggs_given`, `cream_given` | dialogues de la marchande et du serveur | évitent de redonner l'objet |

### 3.5 Textes du jeu à changer pour l'acte 1

- Noms des zones (MONDE.md, section 2.1) et des quatre corps de Timere (section 7.2) ; HUD
  « Retour au village… » devient « Retour à l'entrepôt… ».
- Animation `mort` des skins : des grains de lumière plutôt que des pétales (une fée qui meurt se
  dissipe en lumière, SPOILER V4, prologue), sans l'expliquer : à l'écran, c'est une défaite, pas
  une mort.
- Arène : invite « Sonner la cloche de veille » (constante de `src/enemies/arena_panel.gd` :
  développement n° 4), titre de fin « Fin de la veille », « Nouveau record de veille ! ».
- Chute : « Tes ailes se sont ouvertes : te revoilà au bord. » ; défaite : « Les autres t'ont ramenée
  à l'entrepôt. »
- Menu : sous les vignettes, « Ta fée prend la place de Chtholly dans l'histoire. »
- Crédits, `README.md`, `PLAN.md`, `docs/ASSETS_3D.md`, `tools/gen_branding.py` : Seniorious et
  Timere ; dans les crédits, le titre de la traduction française (*Que faites-vous à la fin du
  monde ? Êtes-vous occupés ? Voulez-vous bien nous sauver ?*, Yume Novel). Tests à adapter : la
  chaîne « Seniolis » de `tests/unit/test_dialogue_data.gd` et `tests/unit/test_credits.gd`, et les
  tests M2 qui jouent `pages` et la bibliothécaire (`test_m2_quest.gd` et voisins).
- Carton d'ouverture (avec le développement n° 6 ; sinon, la première réplique de Nygglatho) :
  « Île n° 68, fin de l'automne. Cette nuit, le vent a hurlé sur la forêt. À l'entrepôt des fées, le
  nouveau responsable est arrivé dans le noir. »

### 3.6 Écrire les dialogues de l'acte 1

- Chaque PNJ a un seul fichier `data/dialogues/<id>.json`. Ordre des `entries` : l'étape de la
  quête principale qui le concerne (`quest_step`), puis les étapes des quêtes secondaires, puis
  l'après-acte (`act1_done`), puis des répliques par défaut qui changent avec les drapeaux.
- Une scène fait 3 à 6 nœuds de deux lignes au plus, avec au plus deux choix ; les choix sont la voix
  de la protagoniste (section 8).
- Les scènes à plusieurs voix (Nephren à l'étape 8, Nygglatho à l'étape 9, les petites à la lecture)
  passent par le `speaker` d'un nœud.

## 4. Actes 2 à 4 : quêtes

Moins détaillées que l'acte 1 : elles fixent l'ordre, les briques et les sources ; chaque jalon
détaillera la sienne comme la section 3. « Dév. » renvoie à la section 9.

### 4.1 Acte 2 — « Le chemin du retour » (M3, V2)

Nouvelles zones : `island15` (champ de bataille de l'île n° 15), `island15_rifts` (donjon des failles
**(original)**), `collina_di_luce` (quartier de la place de Falcita), `dream_ruins` (les ruines du
rêve) ; intérieurs de l'entrepôt.

| `id` | Titre | Type | Source | Donneur, prérequis | Étapes (briques) | Récompenses, résumé |
| --- | --- | --- | --- | --- | --- | --- |
| `act2_departure` | Au couchant | principale, `auto_start` | V1, « Même après la fin de cette guerre » | `nygglatho` ; quête `act1_main` | `talk` nygglatho (armure informelle, épée sur le dos) → `talk` tiat (les adieux des petites) → `reach` trigger `couchant_edge` (Ithea et Nephren ; l'envol dans le soleil couchant) | drapeau `act2_departed` ; on ne se retourne pas, la broche brille |
| `act2_front` | Les deux cent dix-sept morts | principale | V2, « Chasseur d'âmes — A » (SPOILER V2) | `limeskin` ; `act2_departure` | `talk` limeskin (tente à 1 200 *marmer* du front) → `arena` island15 `wave: 5` (Timere renaît ; les batteries lézards figent sa régénération, dév. n° 9) → `reach` trigger `rift_entrance` → `collect` `constraint_key` ×3 (donjon **(original)**) → `kill` `timere_reborn` ×1 (boss : masse de lianes, puis géant de lierre noir) → `flag` `unknown_beast_hatched` (scène) → `reach` trigger `island15_heart` (planter Seniorious ; l'île tombe ; Ithea t'emporte) | PV max → 8 ; l'empiètement (souvenirs d'une autre, yeux qui rougissent) est montré, jamais expliqué |
| `act2_reunion` | Un résultat | principale | V2, « Un Résultat » | `willem` ; `act2_front` | `reach` zone collina_di_luce → `talk` willem (il te serre à t'étouffer, tu le gifles) → `talk` limeskin (Phyr et la lettre de menace) | — |
| `act2_phyr` | Le bon usage de l'amour et de la justice | principale | V2, « Le bon usage de l'amour et de la justice », « Le mauvais usage de l'amour et de la justice » | `phyr` ; `act2_reunion` | `talk` phyr → `collect` `wrapped_lamb` (chez le boucher, pas à l'échoppe sans certificat) → `reach` triggers `perjurer_tomb`, `lovers_stairs`, `wishing_well` (tu refuses de faire un vœu) → `kill` `thug` ×5 (assommer, dév. n° 10) → `talk` willem (il s'est servi de Phyr comme appât) → `talk` phyr (elle pardonne en disant le détester) | choix canon : « les fées porteront tes combats » |
| `act2_way_home` | Le chemin du retour, toujours si loin | principale | V2, « Le chemin du retour, toujours si loin », « L'écoulement du temps depuis lors » (SPOILER V2) | `willem` ; `act2_phyr` | `talk` willem (renvoyées sous escorte ; Nephren lui fait promettre de rentrer directement) → `reach` zone village → `talk` nygglatho (cacher ton état : choix) → `reach` trigger `warehouse_mirror` (l'inconnue aux yeux rouges ; tu t'effondres) | drapeau `coma` |
| `act2_dream` | Un rêve lointain | principale | V2, épilogue (SPOILER V2) | `elq_child` ; drapeau `coma` | `reach` zone dream_ruins → `collect` `dream_keepsake` ×4 (peluche, livre illisible, cristal, broche) → `talk` elq_child (elle te laisse rentrer) → `talk` willem (« Bienvenue à la maison » ; aucun choix : tu ne peux pas répondre) | drapeau `act2_done` |
| `wrapped_lamb_hunt` | Le vrai agneau enveloppé | secondaire | V2, « Le bon usage de l'amour et de la justice » | `phyr` | `talk` → `collect` `wrapped_lamb` → `talk` | Phyr, fière de sa ville |
| `collina_legends` | Les légendes de Collina di Luce | secondaire | lieux du V2 ; collection **(original)** | `phyr` | `reach` ×5 (place de Falcita, tombe du parjure, escalier des amoureux, Puits de Souhait, place de l'Orge) | objets `falcita_legend` ×5 (codex) |
| `wishing_coins` | Une pièce pour le puits | secondaire | V2 ; récompense **(original)** | esprit du puits | `collect` `copper_coin` ×10 → `talk` | objet `white_feather` (cosmétique) |
| `leaky_roof` | Le marteau introuvable | secondaire | V2, « L'écoulement du temps depuis lors » | `nygglatho` | `collect` `hammer` (dans le placard du bas, pas là où on le cherche) → `talk` | répliques |
| `projection_evening` | La séance | secondaire | V2, « De ce côté-ci de l'écran » ; **(original)** | `collon` | quatre étapes `talk` (une par petite) → `reach` trigger `projection_hall` → `talk` (une romance muette entre lézards) | répliques |

Bonus M3 : `market_medley` « Le chat qui filait » (V1, chap. « Le chat qui filait et la jeune
fille »), souvenir jouable sur l'île n° 28 (zone `isle28_market`) : trois étapes `reach` de toit en
toit derrière le chat noir qui a volé la broche → `collect` `stolen_brooch` (retirée à la fin) →
`talk` willem en haut de la tour de débris. Et `seniorious_in_the_marsh` « Seniorious dans le
marais » (VEX, chap. « L'endroit où je veux retourner ») : la Grue de Gossamer de Willem envoie
l'épée dans le marais, qu'il faut fouiller sans arme (dév. n° 10 : joueur désarmé).

### 4.2 Acte 3 — « Le rayonnement actuel » (M4, V3)

Nouvelles zones : `island49`, `plantaginesta` (pont du navire, arène), `gomag_ruins`,
`gomag_underground` (donjon). Le joueur n'a pas d'épée jusqu'à la dernière bataille (dév. n° 10) ;
skin aux cheveux qui rougissent (planche actuelle de Chtholly).

| `id` | Titre | Type | Source (SPOILER V3) | Étapes (briques) | Récompenses, résumé |
| --- | --- | --- | --- | --- | --- |
| `act3_home` | Je suis à la maison | principale, `auto_start` | « La Fin d'un rêve, le début d'un rêve », « Je suis à la maison » | `talk` nygglatho (l'examen : plus de Carillon ; tu deviens son assistante) → quatre étapes `collect` (`butter`, `flour`, `honey`, `walnuts`, au marché du port ; recette du V3) → `talk` willem (il cuit le gâteau : `take_item` `butter_cake_promise`, `give_item` `butter_cake`) | la promesse de l'acte 1 tenue ; tu pleures contre lui, sans choix |
| `act3_warm_days` | Des journées chaudes dans une saison froide | principale | même titre | quatre étapes `talk` (nuit des comètes : sécher les cheveux de chaque petite) → `reach` trigger `warehouse_roof` → scène : Almita tombe, ton venenum s'allume d'un coup → `talk` nephren | le souvenir de l'île n° 28 s'efface du journal **(original)** |
| `act3_faceless` | La fille sans visage | principale | même titre | `reach` trigger `windy_mound` (la butte au vent du port, la nuit) → `talk` ithea (son secret) | choix : te taire (canon) |
| `act3_collon` | Le talisman sous l'oreiller | secondaire | « Le béguin d'une fille et une femme amoureuse » | `talk` willem (il détache un talisman de Seniorious) → `talk` collon | objet `talisman_nightmare` |
| `act3_lizard_cafe` | Le grand et jeune lézard | principale | même titre | `talk` limeskin au café (en civil, veste choisie par sa fille) → la fausse « expérience » → la nouvelle du Saxifraga | — |
| `act3_island49` | L'île n° 49 | principale | « L'île N°49 » | `reach` zone island49 → `collect` `waffle` ×3 → `collect` `book` ×1 (la librairie en dernier) → `talk` le commandant gremian → course contre le couchant (minuteur, dév. n° 10) | tu t'imposes comme « secrétaire » |
| `act3_gomag` | Réunion | principale | « Réunion », « L'Emnetwith suspect » | `reach` zone gomag_ruins → `talk` nopht (elle te prend pour un fantôme) → `talk` rhantolk → `talk` willem (Desperatio ; sa demande) | — |
| `act3_ice_coffin` | La princesse souriante dans le cercueil de glace | principale, donjon M4 | même titre | `reach` zone gomag_underground (groupe de trois avec Glick et Willem ; nid endormi à contourner, discrétion) → `reach` trigger `ice_hall` (la fillette dans la glace ; ton venenum s'emballe) | — |
| `act3_last_stand` | La fille la plus heureuse du monde | principale | « L'horloge en lambeaux et désuète », « La fille la plus heureuse du monde » | `arena` plantaginesta (18 h 26 → 18 h 51 : barils d'huile, navire qu'on incline ; Timeres en ressort, en arbre, en échelle ; la Septième Bête poussée dans le vide) → scène : Nephren saute, Willem la suit → `talk` elq (un dernier retour) → `arena` gomag_ruins avec Desperatio | fin de l'histoire de Chtholly |
| `act3_epilogue` | La fin d'un rêve | principale (joué en Tiat) | « La Fin d'un rêve » | `talk` nygglatho (au port, elle coupe ses cheveux et les donne au vent) → `talk` lakhesh → `reach` zone forest (Tiat s'entraîne avec la broche) | objet `silver_brooch` ; drapeau `act3_done` |
| `rhantolk_glossary` | Le glossaire de Rhantolk | secondaire | idée du V3 **(original)** | `collect` `emnetwiht_page` ×6 dans les ruines | une entrée de codex par page, sans révéler la nature des Bêtes |
| `lakhesh_bakery` | Le pain du matin | secondaire | Lakhesh aide à la boulangerie (V3) ; **(original)** | `collect` livraisons → `talk` | tartines qui soignent (dév. n° 10) |

Interlude `act3_grey_days` « Les jours gris au sommet du gris » (V3) : on joue Nopht puis Rhantolk
contre Legitimitate (s'immobiliser quand elle écoute, s'éloigner lentement, puis la combattre ;
dév. n° 10).

### 4.3 Acte 4 — « La relève » (M5, V4, V5, VEX)

Partie A, jouée en Nephren (SPOILER V4) ; partie B, jouée par la relève : le menu propose Lakhesh
(canon, nouvelle porteuse de Seniorious), Tiat ou une fée de la communauté (SPOILER V5).

| `id` | Titre | Partie | Source | Étapes (briques) | Résumé |
| --- | --- | --- | --- | --- | --- |
| `act4_strangers` | Les étrangers | A | V4, « Les étrangers » | `reach` zone gomag_dream → corvées de l'orphelinat : `collect` `planks` (la clôture), `talk` almaria, `collect` `wet_laundry` (le linge de la cour), `talk` almaria (le petit-déjeuner) | Gomag intacte, Almaria ; le rêve est un piège doux |
| `act4_guild` | Ce qui doit être protégé | A | V4, « Ce qui doit être protégé », « Les aventuriers » | `talk` navrutri → escorte d'Odle (dév.) → `kill` `hooded_agent` ×4 (assommer) → `talk` ted, luzie | l'enquête sur les comas et le désert gris |
| `act4_hospital` | Une chanson nostalgique | A | V4, même titre | rondes : `reach` ×3 triggers → défendre les comateux | la rumeur du chant |
| `act4_night_end` | La nuit de la fin | A | V4, « La nuit de la fin, la nuit du commencement », « Avant la fin du monde -C » | `kill` `aurora` ×10 dans la neige → donjon sous la grande place (M5) → le Chanteur (scène) | Nephren prend sa part de la Bête |
| `act4_spring` | Faire face au passé | B | V5, « La fin du combat », « Faire face au passé » | `talk` limeskin (plus de Timere prévu avant des années ; l'entrepôt menacé) → gâteau raté et match de ballon de Rhantolk (mini-jeu) | le printemps |
| `act4_collina` | Les anciennes villes et les fées | B | V5, même titre | `reach` zone collina_di_luce → guider un vieil homme égaré (repères : clocher, tour blanche, fontaine) → `collect` `rhantolk_note` ×6 (envolées autour du café de la bibliothèque) | — |
| `act4_market` | Le matin de ce jour | B | V5, « Le Matin de ce jour », « Les qualités d'un Brave » | `arena` collina_market (Auroras lâchées d'un dirigeable) → `kill` `elpis_armor` ×1 (articulations ; **(original adouci)** : libérer les fées captives) | — |
| `act4_brave` | Les qualités d'un Brave | B | V5, même titre | scène (Willem joue la Bête pour rendre aux fées leur valeur ; Lakhesh et Seniorious) → `talk` nygglatho | jamais un combat contre Willem |
| `act4_epilogue` | Des années plus tard | B | V5, épilogue | `reach` zone forest → `talk` (une petite aux cheveux bleus tombe d'un arbre sur un jeune homme qui va à l'entrepôt ; Nygglatho l'accueille) | fin du jeu |
| `seniorious_dreams` | Les rêves de Seniorious | bonus | **(original)** d'après le VEX, épisode 1 | Lakhesh s'endort en astiquant l'épée ; on joue Lillia : front nord (essaim d'elfes), Narvant, zone illusoire d'une succube (briser son noyau), bébé dragon de rouille de Fistirus | les porteuses d'avant |

## 5. Personnages

### 5.1 PNJ du canon

Apparences : modèles 3D réalisés selon `docs/ASSETS_3D.md` (proportions réalistes stylisées,
direction artistique au minimum proche de *Breath of the Wild* ; section 4 pour chaque
personnage) ; en attendant, des planches de remplacement au format de l'easter egg. Références dans
les fiches (`vol<N>.md`, section 4 « Personnages » et section 11 « Illustrations de référence »), à
interpréter, jamais à décalquer. Visuels dans `data/npcs/visuals/<id>.tres` (non jouables).

**Acte 1**

| `id` | Nom | Rôle dans le jeu | Zone | Apparence | Parole |
| --- | --- | --- | --- | --- | --- |
| `nygglatho` | Nygglatho | gardienne de l'entrepôt pour l'Alliance, infirmière et cuisinière ; quête principale, linge, myosotis ; réapparition | village | troll à l'air de jeune femme, une tête de plus que tout le monde (≈ 1,85 m), longs cheveux rose saumon, yeux vert printanier, chemisier vert vif à volants, tablier blanc, coiffe blanche à volants ; blouse blanche pour soigner (vol1.md, image6 ; vol5.md) | douce, polie, gaie, tutoie ; menace en souriant de manger les gens |
| `willem` | Willem Kmetsch | officier responsable de l'entrepôt ; règle Seniorious, enseigne le combat, cuisine | village ; bois et colline pendant ses étapes | grand (≈ 1,75 m), cheveux noirs en bataille, yeux sombres, sourire vague et fatigué ; uniforme militaire noir-bleu nuit croisé à boutons dorés, un peu trop étroit, ceinturon, bottes ; tablier et mouchoir noué pour cuisiner (vol1.md, images 22-23 ; vol3.md, image6) | familier, ironique, tutoie ; plaisante pour esquiver |
| `ithea` | Ithea Myse Valgulious | fée soldat adulte, 14 ans ; ragots ; l'homme-chat | village | cheveux blond paille, longue tresse à perle bleue, yeux ambre au regard félin, écharpe rouge, veste vert pâle sur robe brun-rouge, bas vert olive (vol1.md, image5 ; vol2.md) | vouvoie Willem par ironie, rit « nya-ha-ha » |
| `nephren` | Nephren Ruq Insania (« Ren ») | fée soldat adulte, 13 ans ; salle de lecture ; le livre d'images | village | toute petite (≈ 1,3 m), cheveux gris cendré à reflets lavande en deux couettes ondulées à rubans noirs, yeux gris anthracite, visage impassible, tunique violette à capuche et frise de triangles blancs, livre rouge (vol1.md, image4 ; vol2.md) | deux ou trois mots, « Mm. » |
| `tiat` | Tiat | petite fée qui admire l'aînée ; le registre des veilles | village | moins de dix ans d'apparence (≈ 1,1 m), cheveux et yeux vert feuille, blouse et gilet (vol2.md, image4 ; volEX.md) | enthousiaste, « mademoiselle » |
| `pannibal` | Pannibal | petite fée à l'épée de bois | bois | une dizaine d'années, cheveux violet vif sur un œil, petite cape, épée de bois, brindille (vol1.md ; vol2.md, image4 ; volEX.md, image8) | pince-sans-rire, conseils violents |
| `collon` | Collon | petite fée intenable | village | longs cheveux roses, bandeau rouge, une canine qui dépasse, tunique lacée (vol2.md) | franche, bruyante, jeux de mots |
| `lakhesh` | Lakhesh | petite fée polie ; aide à la cuisine | village | cheveux pêche à petite couette sur le côté, gilet brun clouté (vol2.md, image4 ; volEX.md, image8) | polie, s'excuse sans cesse |
| `almita` | Almita | toute petite fée | village | minuscule (≈ 0,95 m), cheveux crépus jaune citron (vol3.md) | trois mots |
| `limeskin` | Limeskin | commandant de la Garde ailée ; vient sur le Barocupot | port | lézard géant aux écailles blanc laiteux (≈ 2,8 m, exception aux tailles d'`ASSETS_3D.md`), tête draconique cornue, tresse à plumes, collier tribal, uniforme d'officier (vol1.md ; vol2.md) | vouvoie, sifflantes, images de guerrier |
| `cat_waiter` | le serveur du café | café La Clochette ; la crème | port | homme-chat en tablier, canines visibles (volEX.md) | aimable, « mesdemoiselles » |
| `ramikeldi` | M. Rami (Ramikeldi Limashenka) | revenu au pays ; l'horloge | port | homme-chat d'âge mûr, chemise blanche, gilet rouge foncé, chapeau, yeux ambrés (volEX.md) | courtois, vouvoie |
| `snack_vendor` | le jeune lycanthrope du snack | frites, lard épais, petit pain, soupe | port | jeune lycanthrope à tête de chien, tablier taché (vol1.md) | jovial, bavard, un peu inquiet de l'entrepôt |
| `baker` | le boulanger | boulanger homme-bête grincheux | port | homme-bête massif (tête d'ours), farine partout (vol3.md) | bourru, cœur tendre |
| `ferryman` | le passeur | passeur lézard de l'île n° 53 ; voyages en M3 | port | reptilien en ciré, casquette de pilote, lunettes (vol1.md : passeurs de l'île n° 53) | sifflant ; rappelle que les fées ne partent pas sans officier |

**Actes suivants** (apparence et parole à détailler au jalon) : `glick` (boggart gris-vert, petites
cornes, yeux ambrés, lunettes d'aviateur, gilet de cuir matelassé, vol3.md image7 ; bourru,
chaleureux, dit « mesdames » aux fées) ; `phyr` (lycanthrope, fourrure blanche, chapeau à
marguerite, ombrelle, robe turquoise, vol2.md image3 ; formelle, fière de sa ville) ; `doctor`
(médecin cyclope géant, lunettes noires, voix douce) ; `baroni_makish` (homme-lapin, cheveux blancs
en queue, lunettes rondes, uniforme à col montant, vol5.md image11) ; `suowong` (vieillard colossal,
barbe dorée, cape blanche) ; `nopht` (cheveux vermillon hérissés, sweat brun, bretelles rouges,
vol3.md image4 ; fonce, gourmande) ; `rhantolk` (longs cheveux indigo à frange droite, fichu blanc,
robe bleu ciel, lanterne, vol3.md image5 ; argumente) ; `gremian_commander` (peau violette, crâne
chauve, insignes) ; `elq` (fillette aux cheveux roux jusqu'au sol, yeux cramoisis, robe blanche,
vol5.md images 1 et 3 ; enfantine qui joue les grandes) ; `carmine_lake` (poisson volant vermillon
et blanc) ; `ebon_candle` et `kaya` (vol5.md image4) ; `almaria` (longue tresse brune à ruban blanc,
col marin, robe-tablier rouge brique, vol4.md images 1 et 4) ; `navrutri`, `ted`, `luzie`, `odle`
(vol4.md) ; `astartos` (troll aubergiste) ; `lillia` (cheveux cramoisis en queue haute, manteau rouge
et or, volEX.md image1).

### 5.2 PNJ originaux

| `id` | Nom | Rôle | Zone | Apparence | Parole |
| --- | --- | --- | --- | --- | --- |
| `egg_vendor` | la marchande d'œufs | œufs du dessert spécial | port | sang-mêlé mouton (race citée au V2) : oreilles et laine bouclée, fichu, panier de paille | méfiante envers l'entrepôt, puis gentille |
| `garde_lookout` | le guetteur | lézard de la Garde au poste du Couchant ; commente le vent et les veilles (facultatif) | dunes | lézard en uniforme, longue-vue | sifflant ; il ne peut que regarder, seules les fées tuent un fragment |
| `willem_training`, `willem_stars` | Willem | instances de repli de Willem (section 3.3) | bois, colline | visuel de `willem` | — |

### 5.3 Places pour la communauté

- **Fées de l'entrepôt** (`fairy_<prénom>`, à la fois PNJ et skin jouable). L'entrepôt compte une
  trentaine de fées et le canon n'en nomme qu'une douzaine : la place est là. Règles du canon :
  - des filles de 7 à 15 ans d'apparence, semblables aux humains (ni oreilles animales, ni queue, ni
    cornes) mais aux cheveux d'une couleur vive (V1) ; éviter les couleurs signature du canon (bleu
    ciel, blond paille, gris cendré, vert feuille, violet vif, rose, pêche, jaune citron, vermillon,
    indigo) : turquoise, corail, menthe, lilas pâle, abricot, argent bleuté, mèches bicolores… ;
  - tenues du quotidien de l'entrepôt (robes-tabliers, gilets, capes, écharpes, bottines, tons
    d'automne) ; une fée adulte (13-15 ans) porte l'uniforme féminin informel de la Garde (bleu nuit,
    boutons d'or ou d'argent, armure légère) et un grand Carillon dans le dos ;
  - nom : un prénom ; une adulte y ajoute une particule de deux à quatre lettres et le nom de son
    Carillon (sur le modèle de Nota, Myse, Ruq, Keh, Ytri, Siba, Nyx) ; Carillons sans porteuse
    connue dans le canon : *Locus Solus*, *Mulsum Aurea*, les séries *Percival* et *Dindrane* (V1,
    chap. « Entrepôt de fées »), ou un nom latinisant inventé ;
  - un trait de caractère, une habitude du quotidien (corvée, jeu, plat) et un petit souhait ; pas
    de passé tragique raconté : les fées naissent seules dans une forêt et ne se souviennent pas
    d'avant (V1 ; V2).
  - Dans l'acte 1 : une place dans la cour, trois ou quatre répliques qui changent avec les drapeaux,
    et une micro-quête sur ce modèle : `talk` (elle a perdu un objet sur l'île) → `collect` 1 (posé
    dans une zone) → `talk` ; récompense : un souvenir et un drapeau.
  - Choisie comme skin, elle disparaît des PNJ (dév. n° 1) et les dialogues l'appellent par
    `{player}`. À l'acte 4, elle peut être la relève.
- **Habitants du bourg** (`townsfolk_<prénom>`) : commerçants, passeurs, soldats de la Garde,
  voyageurs. Ce sont des hommes-bêtes (lycanthropes, hommes-chats, lézards, boggarts, orcs, trolls,
  sang-mêlés de mouton, de cerf, de lapin…) : un trait animal visible est obligatoire, car les sans
  traits sont rares et mal vus (V1, chap. « Le chat qui filait et la jeune fille »).
- Chaque dessin de membre suit la règle de `PLAN.md`, section 5 : accord écrit, ligne dans
  `assets/characters/CREDITS.md`.

### 5.4 Ce que deviennent les PNJ actuels

| Actuel | Devient | Pourquoi | À faire |
| --- | --- | --- | --- |
| `librarian` (Bibliothécaire) | `nephren` | Nephren fait respecter le silence de la salle de lecture (V1) ; le thème des livres continue avec le livre d'images | retirer `data/npcs/librarian.tres`, `data/dialogues/librarian.json` et le skin `bibliothecaire` ; `pages` reste jouable jusqu'à l'arrivée de `picture_book` |
| `blacksmith` (Forgeron) | `willem` | plus personne ne sait forger un Carillon ; Willem les règle (V1) ; ses conseils de combat passent à Willem | idem ; `blacksmith_tips_heard` devient `met_willem` |
| `child` (Enfant) | `tiat` et les petites | le défi des 300 points devient le registre des veilles | idem |

## 6. Objets

**Acte 1** (icônes 64 × 64, `assets/items/<id>.png`) :

| `id` | Nom | Description (inventaire) | Où | Usage |
| --- | --- | --- | --- | --- |
| `page_fragment` (id gardé) | Page du livre d'images | Une page du livre d'images des petites, arrachée par le grand vent. Des Braves y terrassent de terribles emnetwiht. | bois : 5 au sol | `picture_book` |
| `flower_blue` (id gardé) | Myosotis | Petite fleur bleue des pentes de la colline. On l'appelle aussi « ne m'oubliez pas ». | colline 3, entrepôt 1, Couchant 1, bois 1 | `forget_me_nots` |
| `laundry_sheet` | Drap envolé | Un drap de l'entrepôt arraché du toit par le vent du soir. Il sent le savon et le grand air. | port 2, Couchant 1, colline 1, bois 1 | `flying_laundry` |
| `eggs` | Œufs frais | Une douzaine d'œufs du marché, calés dans de la paille. | la marchande d'œufs | `special_dessert` |
| `wild_berries` | Baies sauvages | Des baies rouges et acidulées des bois du marais. | bois 3 | `special_dessert` |
| `fresh_cream` | Crème fraîche | Un pot de crème du café La Clochette. | le serveur du café | `special_dessert` |
| `clock_gear` | Engrenage de laiton | Un vieil engrenage, encore bon pour le service. | Couchant 2, port 1 | `old_clock` |
| `clock_comb` | Peigne de carillon | Le peigne d'acier d'une boîte à musique repêchée dans le marais. | marais 1 | `old_clock` |
| `picture_book` | Le livre d'images | Le livre des petites, recollé page à page. Willem l'a lu à voix haute. | récompense | souvenir |
| `dessert_cup` | Dessert spécial | La recette du maître de Willem : œufs, lait, crème, baies et un secret. | récompense | souvenir (M3 : rend 1 PV) |
| `cheesecake_slice` | Part de cheese-cake | Nygglatho en garde toujours une part pour les jours tristes. | récompense | souvenir (M3 : rend tous les PV) |
| `tiat_drawing` | Dessin de Tiat | Toi, avec une épée si grande qu'elle dépasse de la feuille. | récompense | souvenir |
| `rami_card` | Carte de M. Rami | Ramikeldi Limashenka, marchand de tabac, île n° 13. | récompense | souvenir |
| `pressed_forget_me_not` | Myosotis séché | Une fleur du vase de Nygglatho, glissée entre deux pages. | récompense | souvenir |
| `butter_cake_promise` | La promesse du gâteau au beurre | Willem t'en a promis une montagne, à condition que tu rentres. Avoir une raison de rentrer rend le cœur plus solide. | récompense de `act1_main` (PV max → 6) | objet clé, retiré à l'acte 3 |

Retirés : `shell` (pas de coquillages sur une île du ciel) et `bookmark` (remplacé par la promesse) ;
leurs icônes et données disparaissent, les sauvegardes qui en contiennent les ignorent (à vérifier
par le lot de la sauvegarde).

**Actes suivants** : acte 2, `constraint_key` (borne de contrainte, **(original)**),
`wrapped_lamb` (agneau enveloppé, V2), `copper_coin` (pièce de cuivre, V2), `falcita_legend`
(légende de Collina di Luce, **(original)**), `white_feather` (plume blanche, V2), `threat_letter`
(lettre de menace, V2), `hammer` (marteau, V2), `dream_keepsake` (souvenir du rêve, d'après
l'épilogue du V2) ; acte 3, `butter`, `flour`, `honey`, `walnuts`, `butter_cake` (gâteau au beurre
aux noix, V3), `talisman_nightmare` (talisman contre les cauchemars, V1 et V3), `waffle` (gaufre
noisette et baies, V3), `emnetwiht_page` (**(original)**), `silver_brooch` (la broche d'argent,
V1 à V3) ; acte 4, `rhantolk_note` (V5), `singing_crystal_shard` (**(original)** d'après le V4),
`dream_shard` (**(original)** d'après le V5), `ugly_dog_charm` (porte-bonheur au chien laid, VEX).
Les talismans dérisoires de Seniorious (ne pas se brûler la langue, trouver le nord, imiter un
miaulement, faire pile six fois sur dix…, V1) deviennent en M3 des entrées de codex que Willem
débloque en réglant l'épée, pas des objets : ils font partie de Seniorious.

## 7. Ennemis

### 7.1 Timere dans le jeu

- **Une seule Bête**, la Sixième (« les Six »), qui se déchire en fragments (V1) : on écrit
  « Timere » pour la Bête (sans article : « Timere attaque »), « un Timere », « des Timeres »,
  « fragments » ou « rejetons » pour ses corps (pluriel attesté aux V4 et V5, BIBLE.md, section
  11) ; jamais « une espèce » ni des « types ».
- **Règles du canon à respecter** : elle grandit et se divise vite, se scinde en mourant jusqu'à sa
  limite de division (V3) ; elle renaît plus forte sous une autre forme (V2) ; seuls un Carillon ou
  une arme enchantée la tuent, l'artillerie ne fait que figer sa régénération (V2) ; elle trouve tout ce
  qui vit, même caché, mais ignore les machines bruyantes (V3) ; elle n'a pas d'ailes et dérive avec
  le vent (V1).
- **Apparence** : une masse vert sombre, amorphe, dont les tentacules deviennent des pattes de
  crustacé épineuses, avec griffes et crocs (V3) ; des formes de plante, masse de lianes, géant de
  lierre noir (V2). La silhouette de la planche de l'easter egg (vert sombre, long cou terminé par
  une gueule dentée, six pattes) reste la base du modèle 3D (`docs/ASSETS_3D.md`, section 5), traité
  dans la même direction artistique que le reste du jeu ; éviter qu'elle ressemble à un animal réel.
  Le volume 1 ne la décrit jamais : à l'acte 1, les dialogues disent « rejeton » et « fragment »,
  sans décrire.

### 7.2 Les quatre corps de l'acte 1

Mêmes données (`data/enemies/timere_*.tres`), mêmes chiffres, nouveaux noms affichés. À l'acte 1,
les noms restent au niveau du volume 1 (des fragments plus ou moins gros) ; les formes décrites par
les volumes 2 et 3 n'arrivent qu'avec leurs actes :

| `id` | Nom affiché (acte 1) | Appui dans le canon | Forme qu'il pourra prendre ensuite | Comportement (inchangé) |
| --- | --- | --- | --- | --- |
| `timere_small` | Rejeton de Timere | petit fragment (V1) ; nom **(original)** | moitié détachée d'un corps qui se scinde (V3) | rapide, morsure |
| `timere_normal` | Fragment de Timere | fragment (V1) | masse vert sombre à pattes de crustacé (V3) | morsure et fouet |
| `timere_runner` | Timere bondissant | nom descriptif (le même que dans la bible) | une moitié devient ressort et l'autre bondit (V3, « L'horloge en lambeaux et désuète ») | charge en ligne droite |
| `timere_big` | Grand fragment de Timere | plus un fragment est gros, plus il est dangereux (V1) | masse à lianes, carapace (V2, « Chasseur d'âmes — A ») | fouet long, ne recule que sous l'onde |

Variantes visuelles pour les actes 2 et 3 : pattes en ressort, lianes, carapace (matériau ou
maillage à part dans le même modèle, même squelette). La veille garde ses vagues et ses points ;
dans les bois, les rejetons ne lâchent plus d'objets.

### 7.3 Ennemis des actes suivants

| Ennemi | Source | Acte | Comportement proposé |
| --- | --- | --- | --- |
| `timere_vine_burst`, gerbe de lianes | V2 : 87 lianes d'un coup, dont 65 feintes | 2 | attaque de zone annoncée par des dizaines de lianes ; seules quelques-unes frappent |
| `timere_reborn`, Timere aux deux cents morts | V2 | 2 (boss) | chaque mort : carapace, puis renaissance plus forte sous une autre forme ; les batteries lézards figent sa régénération |
| la Bête inconnue | V2 (SPOILER) | 2 | scène seulement : elle sort de la carapace à la 217e mort et résiste aux armes à feu |
| `thug`, voyou au bandana cuivré | V2 | 2 | humanoïde : on l'assomme, il s'enfuit ; jamais tué |
| `timere_tree`, Timere-arbre | V3 | 3 | prend la forme d'un arbre et enserre le navire ou le joueur |
| `timere_ladder`, échelle de Timere | V3 | 3 | ils s'empilent pour grimper ; frapper la base fait tout tomber |
| `timere_sand`, Timere liquide | V3 | 3 | jaillit du sable par des trous sous les pieds |
| la Septième Bête (supposée) | V3 | 3 | crabe gris aux pattes extensibles, réputé résister à l'artillerie : il faut le pousser dans le vide |
| Legitimitate, la Quatrième Bête | V3 | 3 (interlude) | chasse au son et au mouvement : s'immobiliser, se taire, s'éloigner lentement |
| `aurora`, la Deuxième Bête | V4 ; V5 | 4 | serpent de cordes couvert de poils-aiguilles ; immobile au soleil en groupe ; rampe vite, s'agrippe aux chevilles (ralentit), salve d'aiguilles ; sensible à la charge |
| `hooded_agent`, agent du Vrai Monde | V4 | 4 | capuche, épée noire recourbée ; assommé, jamais tué |
| le Chanteur, la Première Bête | V4 (SPOILER) | 4 | pilier de cristal couvert de visages qui chantent sans voix ; le chant paralyse ; scène finale plutôt que combat |
| `elpis_armor`, armure d'Elpis | V5 | 4 (boss) | colosse d'acier au marteau de guerre, articulations fragiles ; **(original adouci)** : on libère les fées captives au lieu de les voir mourir |
| Willem changé en Bête | V5 (SPOILER) | 4 | jamais un combat : une scène |
| rêves de Seniorious : elfes en essaims d'arbres, démons des zones illusoires, lièvres-crocs, bébé dragon de rouille | VEX | bonus | créatures du passé, propres aux souvenirs de Lillia |

Jamais d'ours ni de loups à abattre (ceux de Nygglatho restent hors champ), jamais de peuple
intelligent tué (MONDE.md, section 1.5).

## 8. Guide de ton

Pour écrire les dialogues sans recopier l'œuvre : on reprend les voix, pas les phrases.

| Personnage | Registre et tutoiement | Tics | Ne dirait jamais |
| --- | --- | --- | --- |
| **La protagoniste** (Chtholly par défaut ; ce sont les choix du joueur) | fière, sèche en public, rougissante seule ; tutoie Willem (« Monsieur le responsable », « idiot »), les fées et Nygglatho ; vouvoie Limeskin | répond par une question, bafouille quand on la trouble, joue l'adulte ; ne mange jamais de dessert devant les petites (V3 ; VEX) | ce qu'elle ressent, en face ; une plainte sur son sort ; qu'elle a peur |
| **Willem** | familier, ironique ; tutoie les fées, Nygglatho, Glick ; vouvoie Limeskin et les inconnus avec une politesse moqueuse | se dénigre, plaisante pour esquiver, appelle Nephren « Ren » à sa demande ; la tendresse passe par des actes (cuisiner, réparer, régler) | un discours héroïque ; une promesse à la légère ; une déclaration (avant le V3) ; parler de son passé de lui-même |
| **Nygglatho** | douce, polie, gaie ; tutoie ; « mes filles » | menace en souriant de manger les petites ou Willem (« délicieux ») ; stricte sur les manières | une vraie menace ; pleurer devant les fées ; mentir aux petites sur ce qui compte (elle se tait plutôt) |
| **Ithea** | taquine, bavarde ; vouvoie Willem par ironie (« Monsieur l'officier »), appelle Limeskin « M. Lézard », Tiat « minus » | rire « nya-ha-ha », ragots, entremetteuse ; sérieuse sous la blague | son propre secret ; une phrase sans sourire en public |
| **Nephren** | une à cinq paroles ; tutoie ; dit « Willem » | « Mm. », logique implacable, attentions muettes (café très sucré, se coller pour réchauffer) | une longue phrase ; une exclamation |
| **Tiat** | enthousiaste, romantique ; vouvoie l'aînée (« mademoiselle ») et d'abord Willem | boit son lait d'un trait, imite l'aînée | qu'elle est petite |
| **Pannibal** | pince-sans-rire ; tutoie | conseils violents, brindille, embuscades | qu'elle a eu peur |
| **Collon** | franche, bruyante ; tutoie tout le monde | jeux de mots, grimpe sur les gens et les arbres | « chut » |
| **Lakhesh** | polie, prévenante ; vouvoie (« M. Willem », « Mlle {player} ») | s'excuse sans cesse, pense aux provisions, remercie l'épée | un mot plus haut que l'autre |
| **Almita** | trois mots | répète ce que disent les grandes | une phrase complète |
| **Limeskin** | vouvoie tout le monde (« guerrier », « guerrière ») | redouble les sifflantes (« sssi »), images de guerre et de vent, culte du guerrier, thé brûlant | un mensonge ; une phrase pressée |
| **Gens du bourg** | polis, prudents avec l'entrepôt (V1) ; le serveur dit « mesdemoiselles », M. Rami est cérémonieux | s'adoucissent au fil des quêtes | une insulte envers les fées ou les sans traits à l'écran (la méfiance passe par le regard, le silence, une porte qui se ferme) |

Règles communes :

- **Court** : deux lignes de boîte au plus par nœud (≈ 140 caractères), trois à six nœuds par scène,
  deux choix au plus.
- **De l'humour dans chaque scène**, même triste ; la tristesse est dans ce qui n'est pas dit.
- **La mort** : les fées en parlent avec une légèreté qui doit sembler étrange, jamais belle ;
  l'expression canon « ouvrir les portes » s'emploie rarement ; pas de sang à l'écran ni de
  description de blessure ; pas de « sacrifice » glorifié.
- **Le monde a ses mots** : *bradal*, *marmer*, cristal lumineux, dirigeable, Garde ailée ; ni
  argot moderne ni anglicisme.
- **Jamais de phrase recopiée** des volumes ; une citation très courte reste exceptionnelle.
- **Variables** : `{best:dunes}`, `{left:<objet>:<n>}`, `{count:<objet>}` (existent) ; `{player}`
  (à développer, section 9).

## 9. Ce qui demande un nouveau développement

Au-delà du moteur de quêtes décrit (étapes, prérequis, récompenses, conditions, effets, journal,
marqueurs), par priorité :

1. **Présence des PNJ selon l'histoire** (M2, prioritaire) : afficher ou masquer un PNJ selon des
   conditions (même grammaire que les dialogues), pour que Willem et Limeskin se déplacent ; masquer
   la fée de la communauté choisie comme skin. Sans lui, le repli de la section 3.3.
2. **`{player}`** dans les textes : le nom affiché du skin (M2, petit).
3. **L'île flottante** (M2) : côte et plage de `terrain.gd` changées en lèvre de pierre et falaise,
   shader de mer de nuages sur le nœud `Water`, message de rattrapage, dessous de l'île.
4. **Textes de l'arène et de la réapparition en données** (M2, petit) : invite de la cloche (constante
   de `arena_panel.gd`), titre de fin de série, messages de chute et de défaite.
5. **Un portrait par orateur** (M2, petit) : une scène à plusieurs voix montre le portrait de celui
   qui parle.
6. **Narration sans PNJ** (M3) : un déclencheur ou un effet de dialogue affiche un carton (ouverture
   et fin d'acte, avertissement de spoiler, pensée de la protagoniste).
7. **Placements conditionnels d'ennemis et d'objets** (M3) : rejetons selon la saison, bois
   nettoyés après l'acte 1, contenu des donjons.
8. **Voyages entre îles** (M3) : plusieurs îles chargées à la demande, dialogue du passeur ou d'un
   officier vers une destination débloquée.
9. **Timere qui se divise et renaît** (M3) : compteur de divisions à la mort, boss à formes
   successives, batteries qui figent sa régénération.
10. **Gameplay des actes 2 à 4** (M3 à M5) : assommer sans tuer, discrétion, escorte, minuteur,
    objets qui soignent, joueur sans épée, changement de personnage jouable et de skin par acte
    (Tiat, Nephren, la relève), nuit étoilée et talismans en orbite.
11. **Verrou de lecture** (M4) : « Je lis jusqu'au volume… » dans le menu ; au-delà, les actes restent
    fermés ou s'ouvrent après un avertissement, au rythme des parutions de Yume.
