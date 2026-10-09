# Refonte : l'île n° 68 telle que dans *SukaSuka*

Plan d'envergure demandé le 9 octobre 2026 après la recette du monde posé : « un monde vide »,
« qui ne correspond pas à l'œuvre », « des quêtes superflues », « des Timeres qui n'ont rien à
faire sur les îles », « des personnages statiques », « aucun intérieur », « des dirigeables plats
qui cachent la vue ». Ce document dit ce qui ne va pas, ce qu'on vise, comment on y va et ce qu'il
faut trancher.

Sources : relecture intégrale des six volumes (traduction Yume Novel), faite pour ce plan et
consignée, paraphrasée et sourcée, dans `docs/lore/canon/v1_vex.md`, `v2_v3.md` et `v4_v5.md`.
Ces trois dossiers priment sur `docs/lore/BIBLE.md`, `MONDE.md` et `HISTOIRE.md` quand ils les
contredisent.

---

## 0. En bref

**Le constat.** L'utilisateur a raison sur les cinq points, et l'écart vient de nos propres
choix, pas d'un manque d'images :

1. **Monde vide.** Une miniature de 160 m découpée en cinq grands espaces ouverts : trois places
   vides de 15 m de rayon (arène, terrain, cour), de larges prés, aucun relief bâti, aucun
   intérieur.
2. **Infidélité.** Plusieurs inventions contredisent le canon :
   - la « saison des rejetons », avec des Timeres qui rôdent dans les bois ;
   - la « veille du Couchant » et son arène ;
   - les dunes de sable sur une île de forêts et de marais ;
   - un bourg réduit à une rue, alors que l'œuvre décrit une ville de pierre sur une pente et un
     village d'hommes-bêtes ;
   - six quêtes secondaires inventées.
3. **Personnages figés.** Les planches savent marcher, mais le moteur ne fait jamais bouger les
   PNJ.
4. **Aucun intérieur**, alors que l'œuvre décrit l'entrepôt pièce par pièce.
5. **Dirigeables plats et mal placés.** Amarrés au sud du quai, ils se trouvent entre la caméra
   (qui regarde le nord) et le joueur.

**Le cap.**
- L'île n° 68 de l'œuvre, construite comme les cartes d'*Octopath Traveler* : une suite de
  lieux compacts et denses, reliés par des sorties, avec leurs intérieurs.
- Des habitants qui vivent leur journée et des petites qui jouent.
- Une faune de forêt et de montagne, et aucune Bête.
- Une histoire qui suit le volume 1 et l'épisode du volume EX, jour après jour, sans quêtes à
  collecter.

**Ce qu'il faut trancher** (section 10). Quatre décisions, chacune avec ma recommandation :
- la structure de la carte ;
- le combat à l'acte 1 ;
- le sort des quêtes ;
- la première tranche à produire.

**La suite.**
1. Fusionner la PR n° 19 : elle remet `main` au vert et apporte l'application de bureau et la
   souris.
2. Lancer les fondations du moteur et le cahier n° 3 pour ChatGPT.
3. Produire une tranche verticale, « l'entrepôt » : extérieur, intérieur complet, vie des
   petites, premiers jours de l'acte 1.
4. Étendre lieu par lieu.

---

## 1. Diagnostic

### 1.1 Pourquoi le monde paraît vide

| Ce qu'on a | Ce que fait *Octopath Traveler* |
| --- | --- |
| Une seule île ouverte de 160 × 160 m, cinq zones de 40 à 60 m de côté | Des cartes compactes (une à trois largeurs d'écran), chacune construite autour d'un parcours |
| Trois places vides de 15 m de rayon (arène, terrain, cour), des prés entre les zones | Pas de vide gratuit : un chemin bordé de murs, de clôtures, de talus, d'objets |
| Sol presque plat (seules la colline et les dunes montent) | Plusieurs niveaux par carte : terrasses, escaliers, ponts, murets, falaises |
| Aucun intérieur | Chaque maison, auberge, boutique et église se visite |
| 17 PNJ immobiles pour toute l'île | 10 à 30 habitants par ville, qui bougent, plus des animaux |
| Le décor pose des objets sur un fond | Le décor fait le lieu : façades serrées, linge, caisses, enseignes, lumières, fumées |

La pose du cahier n° 2 a multiplié les décors par 3 à 10, ce qui n'a pas suffi : un pré de 40 m
garni de 1 000 éléments reste un pré. Le problème est la forme des lieux, pas le nombre
d'images.

### 1.2 Ce qui contredit l'œuvre

| Dans le jeu | Dans l'œuvre | Source |
| --- | --- | --- |
| Des Timeres errent dans les bois, la « saison des rejetons » **(original)** | Aucune Bête ne vole ; Timere reste à la surface et n'envoie au ciel que des fragments, rarement, prévus des semaines ou des mois à l'avance ; une île touchée est absorbée en six à huit heures puis tombe. On n'en voit jamais sur une île habitée : la plupart des soldats de la Garde n'en ont jamais vu. | V1, « Les valeureux et leurs successeurs » ; V2, « Chasseur d'âmes — A » ; V5, « Les anciennes villes et les fées », « Les qualités d'un Brave » |
| La « veille du Couchant », arène et cloche **(original)** | Rien de tel ; dans le V1, aucun combat contre une Bête n'est montré sur l'île n° 68, et les fées partent se battre ailleurs | dossiers V1/VEX, rubriques 7 et 9 |
| Le « bord du Couchant », dunes de sable pâle | L'île est presque entièrement couverte de forêt, avec des marais de toutes tailles dans les trouées | V1, « L'Homme sans Marque » ; VEX, « Cinq cents ans » |
| Le bourg = une rue au bord du port | Un centre-ville de **centaines de bâtiments de pierre sur une légère pente**, à 2 000 marmer du port ; plus un **village d'hommes-bêtes à quelques pas de l'entrepôt**, avec son café-bar | V1, « Directeur en carton » ; VEX, « Cinq cents ans » |
| L'entrepôt au milieu d'une cour fermée par une palissade à quatre portails | Une clairière défrichée au cœur de la forêt, entourée de bois denses et de marais ; un champ de ballon dans la forêt, bordé d'un bosquet ; une clairière d'entraînement derrière le bâtiment ; un potager minuscule et un parterre juste à côté ; un grand arbre où grimpent les petites | V1 ; V2, « De ce côté-ci de l'écran » ; V5, « La fin imminente » ; VEX |
| Un sentier de dalles éclairé de lampadaires | Un sentier étroit, sans aucune lumière, aux pierres clairsemées envahies d'herbe | V1, « L'Homme sans Marque » ; V3, « Je suis à la maison » |
| Des dirigeables à ballon, puis plats | Des navires à coque de métal, rotors, chaudière enchantée, bras d'ancrage, passerelle, trappe, plusieurs ponts, aucun ballon | V1, « Entrepôt de fées » ; V2 ; V3 ; V5 |
| Six quêtes secondaires, dont quatre inventées | L'œuvre fournit d'elle-même ses scènes du quotidien : le dessert spécial (cuisiné par Willem, pas cueilli par la joueuse), la salle de lecture, le match après la pluie, l'horloge des Limashenka… | dossier V1/VEX, rubrique 10 |

L'erreur de fond était la nôtre. La bible avait relevé ces faits, mais `MONDE.md` (section 1.1)
a inventé « la saison des rejetons » pour donner au jeu d'action des ennemis sur l'île. La
refonte retire cette invention et tout ce qui en découlait.

### 1.3 Ce qui manque de vie

- **Les PNJ** : 17, chacun cloué à sa place, avec deux animations (repos, parle), alors que les
  planches ont aussi « marche » dans trois vues.
- **Les petites** ne jouent pas, alors que l'œuvre déborde de leurs jeux :
  - le ballon en équipes rouge et blanche, la balle contre le mur, les avalanches devant les
    portes, la « tour de fées » sur le dos de Willem ;
  - les embuscades avec cri de guerre, les poursuites dans le couloir en pariant le dessert ;
  - l'escalade interdite du grand arbre, les courses dans la boue, les clés de bras sur une
    peluche.
- **Pas d'habitants** : aucun homme-bête en ville, aucun client au café, aucun marchand.
- **Pas d'animaux** : seuls passent des oiseaux et des feuilles (`AmbientSprites`).

### 1.4 Ce qui manque de lieux

- **L'entrepôt** a, dans l'œuvre :
  - **au rez-de-chaussée** : un couloir au parquet usé, aux murs plâtrés, avec plannings de
    corvées et écriteaux ; un réfectoire avec sa grande fenêtre, son évier, son vaisselier
    vitré, son menu et la ligne « dessert du jour », et des marques de taille au mur ; une
    cuisine à fourneau de cristal, réservée à la cuisinière du jour ; une salle de lecture
    silencieuse avec un siège à la fenêtre ; les archives, un océan de papiers avec horloge et
    canapé beige ; une infirmerie avec lit, rideaux, vase et calendrier ; une salle de jeux
    avec tapis, peluches et jeux de société ; une salle de bains à grand miroir ;
  - **à l'étage** : la chambre de Nygglatho (cheminée, service à thé, lampe à huile), la chambre
    nue de Willem, les chambres des fées, dont celle de Chtholly (bureau, miroir, calendrier,
    chapeau, broche), et un couloir qui fuit ;
  - **le toit**, avec son séchoir à linge et sa rambarde branlante à hauteur de fée ;
  - **la salle des armes**, crypte derrière une porte rivetée à cinq serrures.
  Rien de tout cela n'existe dans le jeu.
- **Le village voisin et son café à clochette**, la **maison Limashenka** et son horloge à peigne
  doré (VEX), le **snack-bar** du jeune lycanthrope (V1), la **boulangerie** où travaille Lakhesh,
  la **salle de projection**, la **librairie**, le **café habituel** (V2, V3) : tous absents ou
  réduits à une façade.

### 1.5 Ce qui pèse

- Un encadré d'objectif toujours affiché, des « ! » et « ? » sur les têtes, un journal de sept
  quêtes.
- Des objets à ramasser (pages, baies, draps, engrenages, myosotis) qui ne racontent rien.
- Une quête principale dont 4 étapes sur 13 sont inventées (gagner les bois, abattre les
  rejetons, ramener Pannibal, tenir la veille).

---

## 2. Le cap

Six principes, qui valent pour tous les lots de la refonte :

1. **Fidèle d'abord.**
   - Un lieu, un personnage, un geste ou une scène vient de l'œuvre, avec sa source (dossiers
     `docs/lore/canon/`).
   - L'original ne fait que combler un silence, est marqué **(original)** et ne contredit rien.
   - On n'invente plus de menace.
2. **Dense comme Octopath.** Chaque écran est un lieu composé :
   - un parcours lisible, des bords pleins (murs, haies, talus, bois), au moins deux niveaux de
     relief par carte ;
   - entre 40 et 120 éléments à l'écran, aucune surface de sol nue de plus de 6 × 6 m hors des
     places voulues (terrain de ballon, cour) ;
   - de la vie dans chaque vue : un personnage, un animal ou une animation.
3. **Vivant.**
   - Chaque personnage a une journée : où il est, ce qu'il fait, avec qui.
   - Les petites jouent pour de vrai. Les habitants passent, achètent, discutent.
   - La forêt a ses bêtes.
4. **Habitable.** On entre dans l'entrepôt, dans chaque pièce, dans les boutiques, dans le café,
   à bord des dirigeables.
5. **Raconté, pas listé.**
   - L'acte 1 est le volume 1 et l'épisode du volume EX, joués jour après jour, en scènes.
   - Entre les scènes, on vit à l'entrepôt.
   - Pas de collecte ni de compteur ; un seul indice discret quand l'histoire attend quelque
     chose du joueur.
6. **Léger à l'écran.** Pas d'encadré permanent, pas de marqueurs au-dessus des têtes. Le
   calendrier de Chtholly, qu'elle raye chaque jour dans sa chambre (V1), tient lieu de journal.

---

## 3. L'île n° 68 réinventée : une carte faite de lieux

### 3.1 Le modèle

Une carte (`Map`) par lieu, comme *Octopath Traveler*. Chacune est un diorama de 30 à 90 m :
son relief, ses bords naturels (forêt, falaise, murs), ses sorties. On en charge **une seule à
la fois**, ce qui permet beaucoup plus de détail par écran et fait aussi gagner en fluidité, sur
le Web comme sur le bureau.

**On passe d'une carte à l'autre** :
- par une sortie (bout de sentier, porte, passerelle), avec un fondu ;
- ou par la carte de l'île, qui mène aux lieux déjà découverts, avec une durée de marche
  indicative.

On garde l'**ordre** et les **distances relatives** de l'œuvre : 500 marmer du port à l'entrepôt,
2 000 du port au centre-ville, le village à quelques pas de l'entrepôt.

**Règle de caméra** : la caméra regarde le nord. Tout ce qu'on doit contempler au-delà d'un bord
(mer de nuages, dirigeables à quai, horizon) se place **au nord** de la carte ; jamais rien de
haut au sud d'un endroit où l'on marche (c'était l'erreur des dirigeables).

### 3.2 Les lieux

```
                         ┌──────────────────────┐
                         │ Forêt profonde,      │
                         │ mares cachées,       │──── Montagne aux ours (Nygglatho)
                         │ refuge de Chtholly   │
                         └──────────┬───────────┘
   ┌───────────────┐    ┌───────────┴──────────┐    ┌────────────────────┐
   │ Village des   │────│ L'ENTREPÔT (dehors)  │────│ Colline des étoiles│
   │ hommes-bêtes, │    │ clairière, champ de  │    │ (vent calme)       │
   │ café, maison  │    │ ballon, clairière    │    └────────────────────┘
   │ Limashenka    │    │ d'entraînement       │
   └───────────────┘    └──┬───────────────┬───┘
                           │ portes        │ sentier sans lumière (500 marmer)
              ┌────────────┴─────┐   ┌─────┴──────────────────┐
              │ Intérieur :      │   │ Le sentier et le marais│
              │ rez-de-chaussée, │   │ (embuscade de Pannibal)│
              │ étage, toit,     │   └─────┬──────────────────┘
              │ salle des armes  │         │
              └──────────────────┘   ┌─────┴──────────────────┐      ┌────────────────────────┐
                                     │ Le port, rue du port,  │──────│ Centre-ville en pente  │
                                     │ panneau aux flèches,   │ 2000 │ (2 ou 3 cartes) :      │
                                     │ aire-port, colline     │marmer│ snack-bar, boulangerie,│
                                     │ venteuse ; navires au  │      │ café habituel,         │
                                     │ nord du quai           │      │ librairie, salle de    │
                                     └─────┬──────────────────┘      │ projection, horloger,  │
                                           │ passerelles             │ boucher, marché        │
                                     ┌─────┴──────────────────┐      └────────────────────────┘
                                     │ À bord : transport de  │
                                     │ la Garde, Barocupot    │
                                     │ (ponts, salle du       │
                                     │ conseil de guerre)     │
                                     └────────────────────────┘
```

| Lieu | Ce que dit l'œuvre | Ce qu'on y fait | Taille |
| --- | --- | --- | --- |
| **L'entrepôt, dehors** | Clairière défrichée au cœur d'une forêt dense, marais tout autour (VEX ; V2) ; bâtiment de bois à deux niveaux pour une cinquantaine de personnes (V2), délabré comme une étable en ruine (V5) ; potager minuscule et parterre juste à côté, terrain de jeux un peu petit et boueux un peu plus loin (V2) ; « le champ dans la forêt » où l'on joue au ballon, bordé d'un bosquet profond et de fourrés (V1) ; grand arbre où grimpent les petites (V5) ; banc devant l'entrée (V3) ; toit à linge (V2) ; clairière d'entraînement « à l'arrière », herbe, sol meuble, un arbre, des bâtons (VEX) ; la cour en terre du duel (V1) | Le cœur du jeu : jeux des petites, ballon, entraînement, linge, retour des aînées | 70 × 60 m, plus la clairière d'entraînement |
| **L'entrepôt, dedans** | Pièces de la section 1.4 | Repas, lecture, archives la nuit, infirmerie, thé chez Nygglatho, toit aux étoiles, salle des armes | Rez-de-chaussée, étage, toit, crypte |
| **Le sentier et le marais** | Sentier étroit sans lumière, si couvert la nuit qu'on ne voit pas ses pieds ; marais qui sent l'eau, la terre et le vent ; pierres clairsemées envahies d'herbe (V1 ; V3) | Arrivée de nuit et embuscade de Pannibal ; le trajet vers le port et la ville ; les fuites de Chtholly dans la forêt (VEX) | 80 × 40 m |
| **Le village des hommes-bêtes** | À quelques pas de l'entrepôt, pas très grand, campagnard ; un café qui fait tout (café le jour, alcool le soir), sonnette à la porte, arrière-boutique, serveur homme-chat en tablier ; la maison Limashenka et son horloge (VEX) | Goûter avec l'argent de poche, jus offerts, l'horloge et la comptine | 50 × 40 m, plus deux intérieurs |
| **Le centre-ville** | Des centaines de bâtiments de pierre sur une légère pente, idyllique (V1) ; snack-bar d'un jeune lycanthrope à tête de chien (V1) ; librairie, horloger, salle de projection, accessoires, café, boucher (V2) ; boulangerie au patron grincheux où travaille Lakhesh, marché du matin, café habituel (V3) ; apothicaire **(déduction)** | Déjeuner au snack-bar, marché, cinéma avec les petites, travail de Lakhesh | 2 ou 3 cartes (rue en pente avec escaliers, place du marché, ruelles), plus 4 à 6 intérieurs |
| **Le port et l'aire-port** | Rue du port au bord du vide, panneau usé aux flèches rouges (V1) ; bras d'ancrage, passerelle, rampe, sifflet à vapeur, charrettes de sacs (V1 ; V2) ; colline toujours ventée à côté de l'aire-port, d'où l'on voit tout arriver (V2 ; V3) ; pluie fine au crépuscule (V1) | Retour des aînées, départ au couchant, Barocupot | 70 × 50 m ; les navires au **nord** du quai |
| **À bord** | Transport de la Garde : trappe sous pression, deux rotors, chaudière (V1) ; Barocupot : au moins deux ponts, petite salle du conseil de guerre, thé amer dans des tasses minuscules (V1) | La conversation avec Limeskin | Un pont et une salle par navire |
| **La colline des étoiles** | Petite colline de la périphérie, au vent calme et à l'air limpide, herbeuse (V1) | La promesse, le réglage de Seniorious | 40 × 40 m |
| **La forêt profonde** | Bosquets profonds, fourrés aux branches qui percent la peau, eaux cachées dans les creux (V1 ; V5) ; lieu où Chtholly s'enfuit quand c'est trop (VEX) | Exploration, faune, moments seuls | 80 × 60 m |
| **La montagne** | Montagnes où vivent les ours, qui hibernent l'hiver ; Nygglatho y chasse quand elle a du chagrin (V2 ; V5) | Faune plus dangereuse, chasse (facultatif) | 80 × 60 m, plus tard |

Ces lieux remplacent les cinq zones actuelles :
- le **Couchant** disparaît ;
- l'**arène** part à l'acte 2 (section 5) ;
- la **colline** est reprise telle quelle ;
- la **forêt** et l'**entrepôt** sont redessinés ;
- le **port** est retourné face au nord, et la ville devient un lieu à part.

---

## 4. La vie

### 4.1 La journée de l'entrepôt

L'emploi du temps reconstitué d'après les trois dossiers (V1 ; V3 ; VEX ; V5) :

| Moment | Ce qui se passe | Où |
| --- | --- | --- |
| Aube | Oiseaux bruyants ; lever en pyjama, toilette du visage à l'eau froide, brosse à dents (Collon refuse l'eau glacée) ; Willem part au marché | chambres, point d'eau du couloir, sentier |
| Petit-déjeuner | Heure fixe : en retard, plus rien | réfectoire |
| Matinée | Entraînement de base des petites sur le terrain ; entraînement des aînées au bâton, dans la clairière derrière (VEX) ; Lakhesh à la boulangerie ; linge sur le toit | terrain, clairière, toit, ville |
| Midi | Prière collective, fourchettes levées ensemble ; après le déjeuner, ballon dehors | réfectoire, champ |
| Après-midi | Ballon, lecture (silence imposé par Nephren), sieste, goûter au café du village avec l'argent de poche, cinéma en ville avec un adulte, thé et réunion chez Nygglatho | champ, salle de lecture, village, ville, chambre de Nygglatho |
| Soir | Dîner de la cuisinière du jour ; jeux de société dans la salle de jeux, « tour de fées » sur Willem | réfectoire, salle de jeux |
| Nuit | Bain, séchage des cheveux (on fuit la serviette) ; étoiles sur le toit ; petites couchées tôt ; aînées et Nygglatho veillent au réfectoire ; Willem aux archives ; lumière sous la porte de Nygglatho | salle de bains, toit, réfectoire, archives |

Chaque personnage a sa ligne dans ce tableau, adaptée à l'état de l'histoire : un jour de fièvre
ou de départ change les places.

### 4.2 Les jeux des petites (à animer)

- **Le ballon** : équipes rouge et blanche, buts, mi-temps, ballon envoyé haut dans le ciel,
  meilleures buteuses gardées pour la seconde mi-temps (V1 ; V5).
  - **Jouable** : le joueur peut entrer dans la partie (section 6.3).
- **Le chat (poursuite)** dans les hautes herbes, au milieu des papillons orange (VEX, ill.).
- **L'avalanche** : collées à une porte pour épier, elles s'écroulent quand on l'ouvre (V1).
  - **Moment scripté** : il se rejoue quand le joueur ouvre certaines portes.
- **L'escalade du grand arbre**, interdite. Collon tout en haut, une main en visière ; Pannibal à
  mi-hauteur ; Lakhesh tremblante sur une branche basse (V5).
- **Les embuscades** avec cri de guerre (Pannibal, Collon) : on s'écarte, elles s'étalent (V2).
- **La balle contre le mur** et les clés de bras sur une peluche, dans la salle de jeux (V2).
- **La course dans le couloir**, dessert du soir en jeu (V5) ; « on ne court pas dans les
  couloirs » (V1).
- **La tour de fées** sur Willem assis, et Nygglatho qui saute sur la pile (VEX).
- **Les courses dans la boue** après la pluie, puis le bain (V2 ; V3).

### 4.3 Les habitants

- **Les fées** : près de trente, toutes des filles de 7 à 15 ans aux cheveux de couleurs vives
  (V1).
  - **Nommées à l'acte 1** : Chtholly (le joueur), Ithea, Nephren, Tiat, Collon, Pannibal,
    Lakhesh, Almita, Kana, Giniette.
  - **Les autres** : une douzaine de variantes de planches, auxquelles la communauté peut donner
    ses propres fées.
- **Nygglatho** et **Willem**, avec leurs gestes notés dans les dossiers :
  - Nygglatho : mains jointes près du visage, poings sur les hanches, plateau, panier de linge,
    blouse à l'infirmerie ;
  - Willem : tablier en cuisine, assis au rebord de la fenêtre, bâtons sous le bras, marteau au
    plafond qui fuit.
- **Les hommes-bêtes** :
  - au village et en ville : serveur homme-chat, lycanthrope du snack, boulanger grincheux,
    marchands, buveurs du café, passants ;
  - huit à douze silhouettes génériques par espèce (chien, chat, lézard, ours, oiseau,
    grenouille).
  - Ils craignent l'entrepôt à cause de Nygglatho (V1 ; V5), et l'œuvre ne décrit pas
    d'hostilité envers les fées.

### 4.4 La faune

**Ce que dit l'œuvre** :
- **ours** dans les montagnes, chassés par Nygglatho et hibernant l'hiver (V2 ; V5 ; VEX) ;
- **oiseaux** bruyants au matin (V3) ;
- un **petit animal grimpeur** que poursuit une fillette (V5) ;
- **papillons orange** (VEX, ill.) ;
- les **loups** ne sont qu'une crainte de Willem la première nuit, mais il les juge « pas
  impensables » dans une forêt de cette taille (V1).

**Ce qu'on ajoute (original, plausible et demandé)** : loups dans la forêt profonde, sangliers
(on en mange sur l'île n° 11, V5), cerfs, renards, écureuils (le « drôle d'animal »), grenouilles
et libellules au marais, corbeaux.

**Comportements** :
- **Animaux paisibles** : ils errent, broutent et fuient le joueur ; les oiseaux s'envolent à son
  approche.
- **Animaux dangereux** : loups en meute au crépuscule dans la forêt profonde, sanglier qui charge,
  ours dans la montagne.
- **Où on ne les croise pas** : ni à l'entrepôt, ni au village, ni en ville. La loi ne protège que
  les êtres intelligents, et chasser l'ours est permis (V1 ; VEX).

---

## 5. Le combat

L'œuvre ne montre aucune Bête sur l'île n° 68 ; le volume 1 tient tout entier sans un combat
contre Timere. Le jeu reste un jeu d'action, mais ses combats changent de nature selon l'acte :

| Acte | Combats | Source |
| --- | --- | --- |
| 1 (île n° 68) | **Entraînement** : bâtons dans la clairière, parer, dévier, esquiver à trois contre un avec Ithea et Nephren (VEX) ; **duel contre Willem**, ingagnable, dans la cour (V1) ; **entraînement spécial avec Seniorious** et la Grue de Gossamer (VEX) ; **embuscade de Pannibal** à l'épée de bois (V1) ; **faune** de la forêt profonde et de la montagne (section 4.4) | V1 ; VEX |
| 2 (île n° 15) | **Timere, pour la première fois** : le grand fragment, une bataille de plusieurs jours, la Bête qui renaît sans cesse. L'arène à vagues de l'easter egg (score, meilleur score, vagues) y trouve sa vraie place : tenir une ligne sur le champ de bataille | V2, « Chasseur d'âmes — A » |
| 3 (surface) | Timere à la surface (nids sous terre), autres Bêtes | V3 |

Le système de combat ne change pas (épée, charge, verrouillage, souris). Le **Timere** et ses
quatre corps vont à l'acte 2. Les ennemis de l'acte 1 sont des animaux : leurs données passent
de `data/enemies/` à `data/fauna/`.

---

## 6. L'histoire

### 6.1 L'acte 1, jour après jour

L'acte 1 suit le volume 1, auquel s'ajoute l'épisode du volume EX, qui se passe entre la nuit de
la colline et le départ. Les dossiers relèvent 33 scènes de l'île n° 68 dans l'ordre du récit
(`docs/lore/canon/v1_vex.md`, rubrique 10). Elles se jouent en une douzaine de **jours**.

Chaque jour combine :
- ses **scènes clés**, qui se déclenchent à un lieu et un moment ;
- du **temps libre**, la vie de l'entrepôt (section 4) ;
- ses **moments de vie** facultatifs, sur la carte.

Le joueur passe au jour suivant en se couchant : Chtholly raye son calendrier.

| Jour | Scènes clés (V1, puis VEX) |
| --- | --- |
| 1, nuit | Vent qui hurle, Willem arrive sans lumière ; Pannibal l'attaque au marais, Chtholly arrive avec sa lumière ; bain, couloirs aux écriteaux, thé chez Nygglatho, première avalanche ; dîner de restes, seconde avalanche, « nous sommes les armes » |
| 2-3 | Les petites fuient Willem ; il s'ennuie au rebord de la fenêtre ; déjeuner en ville au snack-bar avec les trois aînées ; le dessert spécial (cuisine interdite, espionnes à la porte, réfectoire « illuminé ») |
| 4 | Salle de lecture : Chtholly à la fenêtre regarde le ballon dans le champ ; le livre d'images sur les emnetwiht |
| 5 | Le souvenir de la grande sœur et du gâteau au beurre ; match après la pluie (jouable), plongeon dans le fourré, Willem porte la petite à l'infirmerie ; la salle des armes ; départ des aînées en mission, hors de l'île |
| 6 | Le port sous la pluie : le transport de la Garde se pose, Limeskin jette les épées, Willem porte Chtholly ; nuit de fièvre à l'infirmerie, l'aveu (l'île n° 15), le baiser sur le front |
| 7 | Réveil honteux, roulades, Collon et Lakhesh en visite ; Willem et Nephren endormis aux archives ; le duel dans la cour (Willem s'effondre) ; Nygglatho au cristal, les petites en larmes |
| 8 | Réunion au réfectoire, vingt fées écoutent l'histoire de Willem, l'infirmerie envahie ; la fugue de Chtholly, l'envol, la chute dans les nuages, le Barocupot et Limeskin ; **la nuit sur la colline : la promesse du gâteau au beurre** |
| 9 (VEX) | Premier matin d'entraînement : Chtholly en pyjama, bâtons dans la clairière, trois contre un ; au café du village, jus offerts ; le thé à la moutarde et Tiat ; la veillée au réfectoire, cheese-cake et chasse à l'ours |
| 10 (VEX) | Jour nuageux : Chtholly rate tout et s'enfuit dans la forêt ; le toit la nuit, Nephren et l'écharpe ; la tour de fées |
| 11 (VEX) | La toilette du matin, « ne pars pas ! » dans le couloir ; l'horloge des Limashenka et la comptine ; l'entraînement avec Seniorious, l'épée dans le marais, « après, tu iras où ? » |
| 12 | Le départ au soleil couchant : les trois aînées s'envolent. Épilogue facultatif : Willem revient, les petites au ballon, la cuisine et le gâteau au beurre |

**Le joueur est Chtholly.** Les scènes où elle n'est pas présente se jouent en courtes
séquences vues d'ailleurs, sans le contrôle : l'arrivée de Willem au port, Willem et Nephren aux
archives, Nygglatho au cristal. La première partie peut s'ouvrir sur un prologue jouable :
l'île n° 28, le chat noir, la broche et la rencontre (V1).

### 6.2 Ce qui disparaît

- **La quête principale à étapes** : elle devient le récit en jours.
- **Les quêtes secondaires** : `picture_book`, `special_dessert` (sous sa forme de collecte),
  `flying_laundry`, `vigil_register` et `forget_me_nots` sont retirées.
- **`old_clock`** devient la scène de l'horloge des Limashenka, au jour 11.
- **À l'écran** : les « ! » et « ? » au-dessus des têtes, l'encadré d'objectif permanent, le
  journal des quêtes.
- **Ce qui les remplace** :
  - le calendrier de la chambre de Chtholly, avec une ligne par jour ;
  - un indice discret quand une scène attend le joueur, par exemple « Willem t'attend dans la
    clairière », affiché quelques secondes, puis rappelé par une touche.

### 6.3 Ce qu'on garde comme jeu

- **Moments de vie** facultatifs, tous tirés de l'œuvre :
  - le thé chez Nygglatho, le goûter au café, la lecture à la fenêtre ;
  - rentrer le linge avant l'averse ;
  - aider la cuisinière du jour ;
  - le cinéma avec les petites ;
  - suivre Lakhesh à la boulangerie.
- **Le ballon** : un vrai jeu court (deux équipes, un ballon, des buts), rejouable chaque
  après-midi.
- **L'entraînement au bâton**, qui apprend le combat (parer, dévier, esquiver).
- **L'exploration** de la forêt profonde et de la montagne, avec leur faune.

---

## 7. Le moteur

Ce qui reste :
- le joueur et le combat (épée, charge, verrouillage, souris) ;
- les visuels des personnages et leurs planches ;
- les formats de décor : `DecorPanel` (animé, retourné, premier plan, alpha doux), `Building`,
  `GroundDecal`, `PropScatter`, `PropBatcher`, `AmbientSprites`, `SkyDrift` ;
- le post-traitement ;
- les dialogues et `{player}`, la sauvegarde, les menus, l'application de bureau.

Ce qui change, en lots :

| Lot | Contenu | Dépend de |
| --- | --- | --- |
| **E1 Cartes** | Une carte par lieu (`Map`, remplace l'île à cinq zones) ; sorties, portes et fondus ; une seule carte chargée ; arrivée par marqueur ; carte de l'île et voyage vers les lieux découverts ; sauvegarde par carte ; bornes de caméra par carte. PR « contrats » (`game.tscn`, `WorldManager`, `PLAN.md` section 3) | — |
| **E2 Sol en relief** | Le sol d'une carte décrit par des **données** (grille de hauteurs à paliers, falaises, escaliers, rampes, masques peints : herbe, terre, pavés, boue, eau), bâti par un outil (`tools/map_build.py`) ; plus de relief codé en fonctions ; falaises et murets texturés par images ; eau peinte au ras du sol | E1 |
| **E3 Intérieurs** | Pièces : sol et murs en images ; mur sud coupé (toujours ouvert côté caméra) ; portes ; étages par cartes ; lumière chaude (lampes, cristaux, cheminée) ; objets à examiner (lire le menu, le calendrier, les écriteaux) | E1 |
| **E4 Vie** | Emplois du temps (moment de la journée × état de l'histoire) ; déplacements sur un maillage de navigation ; activités animées (balayer, porter, lire, cuisiner) ; groupes (ballon, chat, avalanche, escalade, tour de fées) ; foules de passants ; réactions au joueur | E1, planches (lot d'images J) |
| **E5 Faune** | Animaux paisibles, fuyards et dangereux ; meutes ; IA reprise du `Enemy` actuel ; données `data/fauna/` | E1 |
| **E6 Récit** | Le jour et le moment de la journée ; scènes scriptées (déplacer des personnages, cadrer la caméra, enchaîner les dialogues, fondus) ; indice discret ; calendrier ; retrait des quêtes secondaires et du HUD de quête | E1, E4 |
| **E7 Navires** | Dirigeables en volume : coque en images vues de profil et de trois quarts, pont praticable, rotors animés, bras d'ancrage ; amarrés au nord des quais ; intérieurs (pont, salle du conseil de guerre) | E1, E3 |
| **E8 Jeux** | Ballon (balle physique, équipes, buts) ; entraînement au bâton (parades en rythme) | E4 |
| **E9 Lumière et temps** | Matin, après-midi, couchant, nuit, pluie fine et averse : étalonnage, ciel, lumières des fenêtres et des cristaux, gouttes. Les grandes scènes du V1 sont de nuit ou sous la pluie | — |
| **E10 Densité** | Kits par lieu (bord de chemin, mur de ville, sous-bois, quai, intérieur), outils de pose, mesures automatiques (éléments par écran, sol nu, draw calls), revue des captures | E2 |

Les lots E1, E2, E3 et E9 ouvrent le chantier. E4 à E8 suivent dès que les cartes existent.

### 7.1 Contrat des cartes

Ce contrat fait foi pour E1, E2, E3 et tous les lots suivants. Il ne change que par une PR
« contrats ». (E1) Les précisions marquées « (E1) » viennent de sa mise en œuvre (PR « contrats »
E1, docs/DECISIONS.md) ; le mode d'emploi pour créer une carte est dans PLAN.md, section 3.

**Où et comment s'appelle une carte**
- Fichier : `src/world/maps/<map_id>/<map_id>.tscn`.
- Racine : `Map` (`src/world/map.gd`, `class_name Map`, `Node3D`), nommée comme son `map_id`
  (`snake_case` sans accent : `entrepot`, `entrepot_rdc`, `sentier`, `village`, `port`…).
- (E1) `Map.problems(carte)` et `Map.exit_problems(carte, marqueurs)` disent ce qui manque ;
  `tests/unit/test_maps.gd` les applique à chaque carte de `src/world/maps/`, posée dans l'arbre
  (un `MapGround` ou une `InteriorRoom` construit sa collision dans son `_ready`).

**Repères**
- Origine au **coin nord-ouest** ; x vers l'est, z vers le sud, y vers le haut ; 1 unité = 1 m.
- La carte occupe `[0, largeur] × [0, profondeur]`, ce qui fait coïncider un pixel d'une image de
  disposition avec une case.
- Le sol courant est à y = 0 ; les paliers montent par pas de 0,5 m.
- (E1) Exception : la carte héritée `ile_ancienne` garde les coordonnées de l'île, centrée sur
  l'origine (`area()` = [−80, 80]², redéfinie par `island.gd`) : sauvegardes, PNJ, déclencheurs,
  masques du sol et tests en dépendent.

**Exports de `Map`**
- `display_name: String` : nom affiché à l'entrée.
- `region: StringName` : lieu sur la carte de l'île, plusieurs cartes pouvant partager un lieu
  (`entrepot` et `entrepot_rdc`).
- `interior: bool`.
- `size: Vector2` : largeur et profondeur, en m.
- `camera_bounds: Rect2` : en x et z, par défaut la carte entière (un `Rect2` vide).
  (E1) Ce sont les bornes du **point visé** (à 2,5 m au nord du joueur), pas de ce qu'on voit :
  la vue s'étend d'environ 10 m de part et d'autre du point visé et de 21 m au nord ; une carte
  qui ne veut pas montrer ses bords resserre ses bornes (carte d'essai : `Rect2(10, 9, 20, 13)`
  pour 40 × 30 m).
- `light_preset: StringName` : préréglage de lumière de E9 ; vide = celui du moment de la journée.

**Enfants figés**
- `Ground` : le sol et sa collision (couche 1 world). C'est un `MapGround` (E2) dehors, une
  `InteriorRoom` (E3) dedans. (E1) En attendant, un `StaticBody3D` plat suffit (carte d'essai) ;
  dans `ile_ancienne`, c'est le sol de l'île (`IslandTerrain`).
- `Geometry` : le décor (scènes de `src/world/props/`), avec le `PropBatcher` comme script du
  nœud, comme aujourd'hui.
- `Markers` : des `Marker3D` nommés, points d'arrivée. `Spawn` est obligatoire, plus un marqueur
  par sortie, nommé comme la carte d'où l'on vient (`from_sentier`…). (E1) Si plusieurs sorties
  d'une même carte mènent ici : `from_sentier_<suffixe>`. Le joueur est posé au sol sous le
  marqueur et regarde son −Z ; un marqueur se place à 2 ou 3 m de la sortie qui y ramène, hors
  de sa forme et de toute collision.
- `Exits` : des `MapExit` (`Area3D`, couche 0, masque 2 player), avec les exports
  `target_map: StringName`, `target_marker: StringName` et `prompt: String`.
  - `prompt` vide : on passe en marchant dedans (bout de sentier).
  - `prompt` rempli : on passe par une interaction (« Entrer », « Monter à bord »). (E1) Le joueur
    ne détecte que les couches 6 et 7 : une sortie à invite passe elle-même sur la couche 6
    (interactable) et dans le groupe `interactable` à son `_ready` (dans la scène, on la laisse en
    couche 0).
  - (E1) Rien ne part pendant un changement de carte, ni pendant les `SETTLE_FRAMES` images
    physiques qui suivent l'arrivée : un joueur posé dans une sortie doit en sortir et y revenir.
- `Life` : les PNJ, les animaux et les objets (E4, E5).
- (E1) D'autres enfants sont permis. En attendant les préréglages de E9 (`light_preset`), une
  carte porte sa lumière : une instance de `src/world/map_light.tscn` (`WorldEnvironment`, `Sun`
  et `Lighting`, réglages de l'île).

**API de `WorldManager`** (E1)
- `go_to(map_id: StringName, marker: StringName = &"Spawn") -> void` : fondu, chargement de la
  carte, retrait de l'ancienne, pose du joueur sur le marqueur, regard tourné comme lui.
  (E1) Coroutine : `await WorldManager.go_to(…)` attend la fin du fondu de retour.
- `current_map() -> StringName`.
- `EventBus.map_entered(map_id: StringName)` : nouveau signal, au passé.
- `GameState` retient la carte et la position pour la sauvegarde.
- (E1) Aussi : `enter_map(map_id, marker, at)` (sans fondu : début de partie, démonstrations),
  `current_map_node()`, `starting_map()`, `map_display_name(map_id)`, `camera_bounds()`,
  `is_transitioning()`, `fade_alpha()`, `last_transition()` (mesures), signaux
  `transition_started(map_id)` et `transition_finished(map_id)`, constantes `LEGACY_MAP` et
  `START_MAP` (`ile_ancienne`). Détail : PLAN.md, section 3.

**Le joueur, la caméra et l'interface** restent dans `game.tscn` ; seule la carte change
dessous. (E1) La carte courante est l'unique enfant du nœud `World` (groupe `map_slot`) ; le
fondu et le nom de la carte sont dessinés par `UI/MapFade`.

**Transition** : l'île actuelle reste jouable comme une carte héritée (`ile_ancienne`) jusqu'à
la phase 5. (E1) `src/world/maps/ile_ancienne/ile_ancienne.tscn` est une scène héritée
d'`island.tscn` (dont le script étend `Map`) : ses zones restent des zones (`zone_entered`
inchangé), `World/ile_ancienne/Zones/<zone>`. Une sauvegarde d'avant la refonte (schéma v2) y
reprend à la même place (schéma v3 : champ `map`). Une sortie de test, au coin est du hangar du
port, mène à la carte d'essai `essai`.

---

## 8. Les images : cahier n° 3 pour ChatGPT

Il sera écrit dès les décisions de la section 10 prises, au même format que les cahiers n° 1 et
n° 2 (taille exacte, 96 px par mètre, une consigne prête à copier par image). Sa liste, par lots
et par ordre de besoin :

| Lot | Contenu | Ordre de grandeur |
| --- | --- | --- |
| **I. Intérieur de l'entrepôt** | Sols (parquet usé, carrelage de salle de bains, dalles de la crypte), murs (plâtre, lambris, papier peint fané) en bandes raccordables, portes, fenêtres à croisillons ; mobilier de chaque pièce de la section 1.4 (vaisselier vitré, tables et bancs, fourneau de cristal, évier, siège de fenêtre, rayonnages, piles de papiers, horloge murale, canapé beige, lits, rideaux, bureau à miroir, cheminée, service à thé, lampe à huile, tapis, peluches, jeux de société, grand miroir, baquet, épées emmaillotées, porte rivetée…) ; écriteaux et plannings sans texte lisible | 120 à 160 images |
| **J. Personnages** | Planches complètes (trois vues) : pour les petites, course, saut, lancer et frapper le ballon, grimper, assise, lire, dormir, tomber ; pour les grands, activités (Willem : cuisiner, porter, réparer, s'effondrer ; Nygglatho : plateau, panier, mains aux hanches, étreinte) ; fées nommées sans planche (Almita, Kana, Giniette) et une douzaine de fées génériques ; hommes-bêtes génériques (chien, chat, lézard, ours, oiseau, grenouille ; métiers et passants) ; tenues de nuit (pyjamas) et de pluie | 40 à 60 planches |
| **K. Village et ville** | Chaumières et maisons du village, le café à clochette (dehors et dedans), la maison Limashenka (salon, horloge) ; façades de pierre en pente, escaliers, murets, terrasses, toits vus de haut pour les arrière-plans ; boutiques (snack-bar, boulangerie, librairie, horloger, boucher, salle de projection, accessoires, café habituel, apothicaire) et leurs intérieurs ; étals du marché | 120 à 150 images |
| **L. Port et navires** | Rue du port, panneau aux flèches rouges, quai et bras d'ancrage, charrettes de sacs ; navires en volume (coque, pont, rotors animés, passerelle et rampe), transport de la Garde, Barocupot (pont et salle du conseil de guerre), dirigeables de passage en arrière-plan | 40 à 60 images |
| **M. Nature et faune** | Sentier sans lumière, marais de nuit, mares cachées, fourrés, bosquets profonds, rochers et falaises de montagne, rivière ; animaux en planches (ours, loup, sanglier, cerf, renard, écureuil, grenouille, oiseaux, papillons, libellules) | 60 à 80 images |
| **N. Temps et lumière** | Ciels du matin, de l'après-midi, de nuit étoilée et de pluie ; mer de nuages de nuit ; gouttes, flaques animées, fenêtres éclairées | 20 à 30 images |

En tout, **400 à 550 images**.

- **Le poids** : l'application de bureau n'a pas de limite, mais le Web dépasserait les
  100 Mo. Il faudra choisir entre une version Web allégée (images en WebP avec perte pour le
  seul Web) et le bureau seul pour la version complète.
- **Les images du cahier n° 2** restent : arbres, rochers, façades, décalques, animations. La
  pose les reprend dans les nouveaux lieux.
- **Le cahier est écrit** : `docs/ASSETS_HD2D_SUKASUKA.md` (404 images, 90 planches et 2
  portraits ; ses formats à confirmer par le moteur sont listés dans sa section 9.4).

---

### 8.1 Conventions d'images de la refonte

Elles font foi pour le cahier n° 3 et pour les lots du moteur. Les règles communes des cahiers
n° 1 et n° 2 restent valables :
- 96 px par mètre ;
- PNG RGBA ;
- taille exacte ;
- panneaux collés au bord bas et centrés ;
- personnages et animaux tournés vers la droite ;
- transparence découpée, sauf alpha doux annoncé.

**Intérieurs** (`assets/hd2d/interior/`) :

| Genre | Nom | Taille | Règle |
| --- | --- | --- | --- |
| Sol | `floor_<matière>.png` | 384 × 384 (4 × 4 m) | sans raccord, vue de dessus, opaque (genre `tile`) |
| Mur | `wall_<matière>.png` | 384 × 288 (4 m × 3 m) | raccord horizontal (genre `tile_h`), vue de face sans perspective, plinthe et corniche comprises, opaque |
| Haut de mur coupé | `wallcut_<matière>.png` | 384 × 24 (4 × 0,25 m) | dessus d'un mur vu d'en haut, raccord horizontal ; le jeu ne dessine pas le mur sud d'une pièce, seulement son épaisseur au ras du sol |
| Porte, fenêtre, élément de mur | `door_<nom>.png`, `window_<nom>.png`, `wallitem_<nom>.png` | à l'échelle (porte : 1,1 × 2,2 m = 106 × 211) | panneau posé contre un mur, ancré en bas |
| Meuble, objet | `props/<nom>.png` | à l'échelle | panneau ancré en bas ; vue de face légèrement plongeante (10 à 15°) |

Les matières de l'entrepôt sont fixées dès maintenant ; le cahier les reprend et le moteur fait
leurs remplaçants :
- sols : `floor_planks_worn` (parquet usé), `floor_planks_dark` (chambres), `floor_tiles_bath`
  (salle de bains), `floor_flagstone_cellar` (crypte), `floor_kitchen_tiles` ;
- murs : `wall_plaster_worn` (plâtre usé), `wall_wainscot` (lambris bas et plâtre),
  `wall_wallpaper_faded` (chambres), `wall_kitchen_tiles`, `wall_cellar_stone` ;
- dessus de mur : `wallcut_wood`, `wallcut_stone`.

**Personnages** : le format des planches ne change pas (`docs/ASSETS_HD2D.md`, section 3 :
trois vues, mêmes animations, même hauteur debout). Les animations nouvelles portent ces noms :

| Animation | Images | ips | Boucle | Qui | Contenu |
| --- | --- | --- | --- | --- | --- |
| `course` | 5 | 14 | oui | petites, aînées, habitants | course |
| `saut` | 4 | 12 | non | petites | élan, saut, réception |
| `frappe` | 4 | 14 | non | petites, aînées | frappe du pied dans le ballon ; `coup` : [2] |
| `lance` | 4 | 12 | non | petites | lancer à deux mains par-dessus la tête ; `coup` : [2] |
| `grimpe` | 4 | 8 | oui | petites | grimper à un tronc (vue de dos surtout) |
| `assis` | 2 | 2 | oui | tous | assis sur un banc ou une chaise, respiration |
| `lit` | 2 | 2 | oui | tous | assis, un livre ouvert, page qui tourne |
| `dort` | 2 | 1 | oui | tous | couché sur le côté, respiration |
| `tombe` | 4 | 10 | non | petites | chute en avant à plat ventre (avalanche, embuscade ratée) |
| `porte` | 6 | 10 | oui | Willem, Nygglatho, habitants | marche en portant un panier, un plateau ou une caisse (objet dessiné) |
| `travaille` | 4 | 6 | oui | Willem, Nygglatho, habitants | geste de métier : remuer une marmite, marteler, balayer, servir (une planche par geste et par personnage) |
| `effondre` | 4 | 8 | non | Willem | chancelle et tombe assis, puis à terre |
| `hanches` | 2 | 2 | oui | Nygglatho, Chtholly | poings sur les hanches, réprimande |

**Animaux** (`assets/fauna/<id>/`) : même format de planche, trois vues ; `repos`, `marche`,
`course` pour tous ; `attaque` (avec `coup`), `degats` et `mort` (une bête vaincue s'enfuit ou
reste à terre, sans sang) pour les animaux dangereux ; `fuite` (envol, bond) pour les oiseaux et
le petit gibier.

## 9. Phasage

| Phase | Contenu | Fin de phase |
| --- | --- | --- |
| **0. Maintenant** | Fusionner la PR n° 19 (`main` au vert, bureau, souris) ; décisions de la section 10 ; corriger la bible (`MONDE.md`, `HISTOIRE.md`) d'après les dossiers du canon | Décisions prises |
| **1. Fondations** | E1 Cartes, E2 Sol en relief, E3 Intérieurs, E9 Lumière ; cahier n° 3 écrit et envoyé à ChatGPT (lots I et J d'abord) ; la carte de l'île dessinée lieu par lieu (`docs/lore/CARTE.md`) | Une carte d'essai avec relief, intérieur et sortie |
| **2. Tranche « l'entrepôt »** | L'entrepôt dehors et dedans, la clairière, le champ ; E4 Vie (journée de l'entrepôt, jeux des petites) ; E6 Récit (jours 1 à 4) ; E8 Ballon | Tu joues les jours 1 à 4, juges, et on corrige le cap |
| **3. Le reste de l'acte 1** | Sentier et marais, village et café, port et navires (E7), colline ; jours 5 à 12 | L'acte 1 entier, fidèle |
| **4. Le monde autour** | Centre-ville et intérieurs, forêt profonde et faune (E5), montagne ; moments de vie | L'île n° 68 complète |
| **5. Finitions** | Densité (E10), performances Web et bureau, retrait de l'ancienne île et de son code, nouvelle version de bureau (tag) | Une version publiée |

Chaque phase se termine par une version jouable, des captures avant/après et ta recette. Les
lots tournent en parallèle comme jusqu'ici : trois ou quatre agents à la fois, pas plus, pour ne
pas retomber sur la limite de session.

**Ce qu'on fait de l'existant** :
- l'ancienne île reste jouable jusqu'à ce que les nouveaux lieux la remplacent ;
- son code (zones, quêtes secondaires, arène du Couchant, Timeres de l'acte 1) est retiré en
  phase 5 ;
- l'arène, elle, rejoint l'acte 2.

---

## 10. Décisions

**Tranchées le 9 octobre 2026**, toutes selon la recommandation :
1. carte faite de lieux séparés, façon *Octopath Traveler* ;
2. à l'acte 1, entraînement et faune, Timere à partir de l'acte 2 ;
3. histoire en jours et en scènes, moments de vie facultatifs, plus de quêtes à collecter ;
4. première tranche : l'entrepôt.

Les options proposées au moment du choix :

1. **Structure de la carte.**
   - **Recommandé** : une carte par lieu, à la manière d'*Octopath Traveler*, avec intérieurs et
     carte de l'île (section 3).
   - Autre voie : garder une seule île ouverte et la densifier. Les lieux y restent petits,
     l'œuvre n'y tient pas, et l'on bute sur la performance.
2. **Combat à l'acte 1.**
   - **Recommandé** : entraînement, duels et faune de la forêt profonde et de la montagne ;
     Timere seulement à partir de l'acte 2 (section 5).
   - Autres voies : seulement l'entraînement, sans faune hostile ; ou aucun combat à l'acte 1.
3. **Quêtes.**
   - **Recommandé** : l'histoire en jours et en scènes, plus des moments de vie facultatifs, sans
     collecte ni marqueurs (section 6).
   - Autre voie : garder quelques quêtes secondaires réécrites d'après l'œuvre.
4. **Première tranche.**
   - **Recommandé** : « l'entrepôt » (dehors, dedans, vie des petites, jours 1 à 4), pour juger
     le cap sur pièce avant d'étendre.
   - Autre voie : toutes les fondations d'abord, puis tout le contenu.
