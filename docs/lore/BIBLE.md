# Bible du canon — WordEnd

Référence commune de toutes les équipes du jeu (direction narrative, quêtes, dialogues, carte,
sprites). Le canon est *Que faites-vous à la fin du monde ? Êtes-vous occupés ? Voulez-vous bien
nous sauver ?* (*SukaSuka*, *WorldEnd*), d'Akira Kareno, illustré par ue, volumes 1 à 5 et EX, dans
la traduction française de Yume Novel (traduction Angeloids, correction Shadowadow). Ce document
fusionne les six fiches de lecture de `docs/lore/volumes/` et en vérifie les points douteux sur le
texte. Les fiches restent la source de détail (résumés complets, matière à jeu, illustrations).

Sommaire : 1. Mode d'emploi · 2. Glossaire · 3. Le monde · 4. Atlas des lieux · 5. Personnages ·
6. Bestiaire · 7. Armes, magie et techniques · 8. Chronologie · 9. Ton et écriture · 10. Audit du
jeu actuel · 11. Incertitudes.

## 1. Mode d'emploi

### 1.1 Sources et périmètre

- **Canon** : le texte des six volumes dans la traduction Yume Novel. Les illustrations d'ue de ces
  éditions servent de référence visuelle.
- **Hors canon ici** : la série suivante, annoncée par la postface du volume 5 (même archipel,
  des années plus tard) ; l'anime et le manga (par exemple, *Scarborough Fair* n'apparaît dans
  aucun des six volumes) ; les autres traductions (« Dug Weapons » de l'anglais se dit *Carillon*
  ici, « Seniolis » n'existe nulle part).
- **Niveau de détail** : ce qui manque ici se trouve dans `docs/lore/volumes/vol<N>.md`.

### 1.2 Niveaux de spoiler

Le jeu dévoile l'histoire dans l'ordre des volumes. Chaque fait porte le niveau du **premier volume
qui le révèle** :

| Niveau | Contenu | Utilisable dans le jeu |
| --- | --- | --- |
| **S0** | Prémisse : prologue et chapitre 1 du V1 (« Dans ce monde crépusculaire »), de la rencontre au Market Medley à la première nuit à l'entrepôt (le monde, les Bêtes, Willem dernier emnetwiht, Chtholly, « les armes, ce sont elles ») | dès le début |
| **S1** | Reste du volume 1 | après l'étape V1 |
| **S2** à **S5** | Volumes 2 à 5 | après l'étape du volume |
| **SEX** | Volume EX, dont le cadre se passe **après** le V5 | à la toute fin |
| **SEX/Sn** | Fait révélé par l'EX mais situé pendant ou avant le récit, qui ne dévoile rien au-delà de Sn (ex. : le café du village est SEX/S1) | dès Sn |

Règles :

1. Un personnage ou un lieu a plusieurs couches : chacune porte son niveau. Nephren est laconique
   [S1] ; elle absorbe une part du Chanteur [S4]. Les textes du jeu (dialogue, codex, description
   d'objet, nom de zone) et les **apparences** (skin, couleur de cheveux) respectent ces niveaux :
   la Chtholly aux cheveux qui virent au rouge est un visuel S3.
2. En cas de doute, on prend le niveau le plus élevé.

### 1.3 Canon, déduction, original

- **Canon** : écrit dans le texte, avec sa source.
- **(ill.)** : vu seulement sur une illustration. Le texte prime en cas de conflit (signalé).
- **(déduit)** : inférence raisonnable que le texte ne formule pas.
- **(original)** : invention du jeu. Permise si elle ne contredit rien de cette bible, et toujours
  marquée comme telle dans les documents du projet.

### 1.4 Citer

- Forme : `(V2, chap. « Chasseur d'âmes — A »)`. Le titre est celui de la **section** (les titres
  des grandes parties, perdus à l'extraction, sont restitués dans les fiches). Parties sans section :
  `(V1, prologue)`, `(V1, épilogue)`, `(V3, chap. « Rêve lointain — B »)`, `(V5, chap. « Puis-je me
  blottir contre toi ? »)`, `(V5, épilogue)`, `(VEX, intermède)` (« Les réminiscences d'un troll »),
  `(VEX, final)` (« L'épée étincelante »), `(Vn, postface)`.
- Illustration : `(V3, ill. image4)`, selon la numérotation des fiches.
- **Droits** : le dépôt est public. On paraphrase. Une citation reste rare, de quelques mots, entre
  guillemets et sourcée. Aucune illustration ni aucun extrait long n'entre dans le dépôt ; les
  sprites sont des dessins originaux.

### 1.5 Orthographe

- On écrit les termes comme la traduction : forme **en gras** dans le glossaire. Les variantes
  servent à chercher dans les textes, pas à écrire le jeu.
- Pièges : *Seniorious* (jamais « Seniolis ») ; *emnetwiht* (minuscule, invariable) ; *Carillon* et
  *Bête* (majuscule) ; *Garde ailée* ; *Timere* (singulier pour la Bête, voir §6.3) ; *Chtholly* (deux
  h) ; *Nygglatho* (deux g).

## 2. Glossaire

Colonnes : terme retenu (gras), variantes de la traduction, définition, première apparition, niveau.

### 2.1 Monde et lieux

| Terme | Variantes | Définition | 1re apparition | Niv. |
| --- | --- | --- | --- | --- |
| **Regule Aire** | Regule Air | Archipel de plus d'une centaine d'îles flottantes, dernier refuge des peuples | V1, chap. « Le chat qui filait et la jeune fille » | S0 |
| **île flottante** ; **île n° 68** | Île n°68, île No. 68, île N°49 | Dalle de pierre géante qui dérive au vent ; numérotée en spirale depuis l'île n° 1, au centre | V1, idem ; chap. « L'Homme sans Marque » | S0 |
| **la surface** | la terre ; « la Terre » (nom ancien) | Le sol d'en bas, désert gris abandonné aux Bêtes | V1, chap. « Le chat qui filait… » | S0 |
| **Market Medley** | Marché Paumé, marché de Medley | Bazar labyrinthique de l'île n° 28 | V1, idem | S0 |
| **Rue des Échoppes d'Étain** | rue des étains | Rue étroite de l'île n° 28 (n° 7, à l'ouest) | V1, idem | S0 |
| **entrepôt des fées** | Entrepôt n°4 de l'Alliance d'Orlandry ; entrepôt de fées ; « Entrepôt de Alliance d'Orlandry No. 4 » (cartes) | Caserne où vivent les fées, île n° 68 | V1, chap. « L'Homme sans Marque » | S0 |
| **Collina di Luce** | — | Plus ancienne grande ville de Regule Aire, sur l'île n° 11 | V2, chap. « Villes et peuples anciens » | S2 |
| **place commémorative de Falcita** | Falcita Memorial Plaza | Place à fontaine et statue du Grand Sage | V2, idem | S2 |
| **Puits de Souhait** | — | Puits d'une placette de Collina di Luce | V2, chap. « Le mauvais usage de l'amour et de la justice » | S2 |
| **Cathédrale Centrale** | clocher de la cathédrale | Grand édifice de Collina di Luce | V2, chap. « Le bon usage de l'amour et de la justice » | S2 |
| **place de l'Orge** | Place de l'Orge, Barley Square | Ancienne halle à l'orge devenue place à spectacles | V2, chap. « Le mauvais usage… » | S2 |
| **Grande Bibliothèque Centrale** | (bibliothèque du **Grand Senato**, V2 : peut-être la même) | Tour blanche, plus grande collection de l'archipel | V5, chap. « Les Fées de Collina di Luce » | S5 |
| **Cœur de Regule Aire** | Cœur de Regule Air ; Cœur de l'Arbre-Monde | Surnom de l'île n° 2, sanctuaire central | V2, chap. « Les protecteurs du ciel d'azur » | S2 |
| **Collectif Elpis** | Elpis Collective, Elpis | Cité-État de la moitié ouest de l'île n° 13 | V5, chap. « Un retour non désiré » | S5 |
| **Empire ailé**, **Comté du thé des hortensias**, **Forêt boréale** | — | Puissances de Regule Aire, citées une fois | V5, chap. « La fin du combat » | S5 |
| **Empire Sacré** ; **l'Empire** | Saint Empire | Puissance emnetwiht de jadis ; les Bêtes sont apparues dans un château en son centre | V1, chap. « Le chat qui filait… » | S0 |
| **capitale impériale** | — | Capitale de l'Empire, quartiers numérotés | V2, chap. « Une fois la guerre terminée » | S2 |
| **Gomag** | cité impériale de Gomag | Petite ville natale de Willem, en lisière de l'Empire | V3, prologue | S3 |
| **ruines K96-MAL** | K96-M.A.L. | Nom de code des ruines de Gomag | V3, chap. « L'île N°49 » | S3 |
| **Dione** | Dioné ; royaume des chevaliers | Royaume de Lillia, rasé puis annexé par l'Empire | V3, prologue (Ordre de Dione) | S3 |
| **Garmando Ouest** | Garmando, North Garmando | Région aride, tribu de Navrutri | V3, chap. « L'Emnetwith suspect » | S3 |
| **Saints Pics de Fistirus** ; **sources chaudes de Fistirus** | — | Sommet de la surface le plus proche de l'archipel ; sources sur la route de Gomag | V2, chap. « Les protecteurs du ciel d'azur » | S2 |
| **district de Tihuana** | — | Confins de l'Empire, théâtre de la bataille contre le Visiteur | V2, prologue | S2 |
| **Narvant** | cité des seuils, ville des Weirs | Ville des plaines de l'ancienne Dione | VEX, chap. « Le Soleil Couchant » | SEX/S2 |

### 2.2 Peuples et êtres

| Terme | Variantes | Définition | 1re apparition | Niv. |
| --- | --- | --- | --- | --- |
| **emnetwiht** | Emnetwiht, emnetwith, Emnetwith, émetwiht | Race humaine éteinte il y a 526 ans | V1, chap. « Le chat qui filait… » | S0 |
| **sans traits** | sans-traits ; sans-marque, sans marque, sansmarques | Personne sans cornes, crocs ni écailles, qui ressemble aux emnetwiht et en subit le mépris | V1, idem | S0 |
| **fée** | **Leprechaun**/leprechaun (terme officiel), lutin, farfadet | Fillette aux cheveux vifs, arme de la Garde ; « pas vraiment vivante », née d'une âme d'enfant (S1) | V1, chap. « L'Homme sans Marque » | S0 (nature S1) |
| **fée soldate adulte** | guerrière fée adulte, soldat fée, fée soldat | Fée mûre et compatible avec un Carillon | V1, chap. « Les filles de l'entrepôt » | S1 |
| **reptilien** | lézard, homme-lézard | Race de taille très variable, très forte, au parler sifflant | V1, chap. « Le chat qui filait… » | S0 |
| **boggart** | — | Nain du folklore, souvent commerçant | V1, chap. « L'Homme sans Marque » | S0 |
| **troll** | — | Ogre d'apparence sans traits ; jadis, choyait ses hôtes puis les mangeait (S5) | V1, idem | S0 |
| **imp** | — | Ogre sans traits, jadis caché parmi les emnetwiht | V1, chap. « Le chat qui filait… » | S0 |
| **orc** | — | Race nombreuse ; compagnie Blackfur | V1, prologue | S0 |
| **ailuranthrope** | homme-chat, demi-chat | Race féline | V1, chap. « L'Homme sans Marque » | S0 |
| **lycanthrope** | homme-loup, femme-loup | Race canine ou lupine | V1, chap. « Le chat qui filait… » | S0 |
| **sang-mêlé** | — | Personne à traits animaux (chat, mouton, cerf, lapin) | V1, idem | S0 |
| **golem** | golem des services publics, golem-tonneau | Être artificiel de service | V1, idem | S0 |
| **semifère** | semifer | Race à oreilles animales (Kaya la servante) | V2, chap. « De ce côté-ci de l'écran » | S2 |
| **cyclope** | — | Race géante à un œil | V2, chap. « Villes et peuples anciens » | S2 |
| **prima** | primas, « race aux yeux de poisson » | Race dont l'oracle prédit les attaques de Timere | V2, chap. « Les protecteurs du ciel d'azur » | S2 |
| **homme-bête** | demi-bête | Villageois et commerçants de l'île n° 68 | V3, chap. « Je suis à la maison » | S3 (SEX/S1) |
| **gremian** | — | Race à peau violette | V3, chap. « L'île N°49 » | S3 |
| **homme-grenouille** ; **tourterelle** ; **homme-ballon** | hommesballons | Races secondaires | V2 à V5 | S2 |
| **elfe**, **nain**, **dragon**, **morian** | elfe noir, elfe des ténèbres | Races de la surface, éteintes | V1, chap. « Le chat qui filait… » | S0 |
| **Visiteur** | Visitor, Visiteuse | Être d'une puissance démesurée ; Elq Hrqstn, ennemie de l'Église, est attaquée par les Braves (S0) ; dieux créateurs pour l'Église (S4) ; venus d'un autre monde, Elq est la dernière (S5) | V1, prologue | S0 |
| **Poteau** | les trois Poteaux, piliers ; « Poteau de dieu » | Divinités subalternes au service des Visiteurs | V2, chap. « Le mauvais usage… » (légende du parjure) ; définis au chap. « Les protecteurs du ciel d'azur » | S2 |
| **les Dix-Sept Bêtes** | dix-sept Bêtes, Dix-sept Bêtes, dix-sept bêtes ; « Bête numéro Six », « les Six » | Dix-sept êtres d'« irrationalité » qui ont vidé la surface | V1, chap. « Le chat qui filait… » | S0 |

### 2.3 Institutions et groupes

| Terme | Variantes | Définition | 1re apparition | Niv. |
| --- | --- | --- | --- | --- |
| **Garde ailée** | Garde Ailée (V1-V2), Garde-Ailé ; « la Garde » | Armée publique de Regule Aire contre les Bêtes | V1, chap. « L'Homme sans Marque » | S0 |
| **Alliance des marchands d'Orlandry** | Alliance d'Orlandry (V1), Alliance Marchande d'Orlandry, Alliance Orlandry ; « Orlandry » | Compagnie marchande, propriétaire réelle des Carillons et de l'entrepôt. « Compagnie Orlandry » n'existe pas | V1, idem | S0 |
| **police militaire** ; **forces blindées** ; **première flotte** ; **service de recherche et de sauvetage** | — | Branches de la Garde ailée | V2, chap. « Le chemin du retour, toujours si loin » ; V5 | S2 |
| **Grand Sage** | grand sage | Suowong Kandel, fondateur et protecteur de Regule Aire | V2, chap. « Villes et peuples anciens » | S2 |
| **charte de Regule Aire** | charte des îles | Loi suprême établie par le Grand Sage | V5, chap. « Réunion secrète » | S5 |
| **récupérateur** | Récupérateur | Chasseur de trésors de la surface | V1, chap. « L'Homme sans Marque » | S0 |
| **Blackfur** | — | Compagnie d'orcs chassée de l'île n° 68 par Nygglatho | V1, chap. « Directeur en carton » | S1 |
| **Chevaliers de l'Annihilation** | de l'anéantissement, de la Destruction | Agitateurs de Collina di Luce payés par l'ancienne noblesse | V2, chap. « Villes et peuples anciens » | S2 |
| **Force de défense aérienne d'Elpis** | — | Armée du Collectif Elpis | V5, chap. « Un retour non désiré » | S5 |
| **Église de la Lumière Exaltée** | Lumière exaltée | Église de l'Empire, qui nomme les Braves | V1, prologue | S0 |
| **Legal Brave** | Brave légal, Braves Légaux | Le Brave officiel unique, réputé la personne la plus malheureuse du monde | V1, prologue | S0 (définition S3) |
| **Quasi Brave** | Quasi-Brave, QuasiBrave | Braves de second rang (une trentaine) | V1, prologue | S0 |
| **Aventuriers** ; **l'Alliance** ; **guilde des aventuriers** | — | Combattants classés par niveaux, fédérés par l'Alliance | V1, chap. « Le chat qui filait… » | S0 (niveaux S4) |
| **Vrai Monde** | — | Secte dont les recherches ont produit les Bêtes (S2) ; secte armée née de l'Église, dirigée par le maître de Willem (S3-S4) | V2, chap. « Les protecteurs du ciel d'azur » | S2 |
| **Tour impériale des Sages** ; **Ordre de Dione** | — | École de thaumaturges ; chevalerie de Dione | V2 ; V3, prologue | S2 ; S3 |

### 2.4 Armes, magie, phénomènes

| Terme | Variantes | Définition | 1re apparition | Niv. |
| --- | --- | --- | --- | --- |
| **Carillon** | arme enchantée, Armes Enchantées, arme antique, Armes antiques, armes creusées, lame sacrée | Grande épée faite de talismans assemblés | V1, chap. « Le chat qui filait… » | S0 |
| **talisman** | — | Objet gravé d'un sort ; brique des Carillons | V1, idem | S0 |
| **veines d'enchantement** | — | Liens magiques qui tiennent les talismans d'un Carillon | V1, chap. « Entrepôt de fées » | S1 |
| **venenum** | Venenum (V5), venin (V1) | Force magique qu'on « allume » ; tirée de la vie, elle brûle le corps (S1) | V1, chap. « Le chat qui filait… » | S0 |
| **la Vue** | — | Don de voir la magie et le venenum | V1, idem | S0 |
| **ouvrir les portes du village des fées** | ouvrir la porte du village des fées ; ouvrir les portes de la patrie des fées | Autodestruction d'une fée par surcharge de venenum | V1, chap. « Les valeureux et leurs successeurs » | S1 |
| **intoxication au venenum** | empoisonnement au venenum | Fièvre et troubles dus à l'abus de venenum | V1, idem | S1 |
| **empiètement** | empiétement, Empiètement | Retour de la vie antérieure d'une fée, qui efface sa personnalité | V2, chap. « Villes et peuples anciens » | S2 |
| **rêve de présage** | « rêve spécial » (V5) | Rêve qui marque la maturité d'une fée | V2, idem | S2 |
| **ajustement** | réglage ; « Initialisation de l'ajustement » | Fée : traitement d'un jour en clinique. Carillon : réglage des talismans | V1, chap. « Les valeureux… » | S1 (fées S2) |
| **thaumaturgie**, **nécromancie**, **malédiction**, **incantation interdite** | — | Arts magiques de l'ancien monde | V1, chap. « Directeur en carton » | S1 |
| **précognition tactique** | capteurs tactiques ; oracle des primas | Prévision des attaques de Timere | V1, chap. « Les valeureux… » | S1 |
| **niveau de tueuse** | niveaux tueurs ; « tueuse de dragons » ; Kinslayer ; Godslayer | Spécialisation d'un Carillon contre un type d'ennemi | V1, chap. « Le ciel étoilé sous le ciel étoilé » | S1 |
| **barrière** (« de la mini-cascade ») ; **Wessex Bordering** | grande barrière | Barrière qui entoure Regule Aire ; traitement des dirigeables pour la franchir | V2, chap. « Une fois la guerre terminée » ; V3, chap. « L'île N°49 » | S2 ; S3 |
| **argent purificateur** | — | Cendre qui noircit au contact des esprits | V3, chap. « Je suis à la maison » | S3 |

### 2.5 Objets, techniques, monnaie, nourriture

| Terme | Variantes | Définition | 1re apparition | Niv. |
| --- | --- | --- | --- | --- |
| **bradal** | — | Monnaie de Regule Aire | V1, chap. « L'Homme sans Marque » | S0 |
| **marmer** | — | Unité de distance (le port de l'île n° 68 indique 500 et 2 000 marmer) | V1, idem | S0 |
| **dirigeable** | navire, patrouilleur | Aéronef à four enchanté et hélices | V1, chap. « Le chat qui filait… » | S0 |
| **passeur** | — | Pilote privé qui dessert les îles hors des lignes publiques | V1, chap. « L'Homme sans Marque » | S0 |
| **aérogare** | aire-port, aireport | Gare des dirigeables | V2, chap. « Villes et peuples anciens » | S2 |
| **four enchanté** | chaudière enchantée | Moteur d'un dirigeable | V1, chap. « Entrepôt de fées » | S1 |
| **cristal lumineux** | cristal de luminescence | Éclairage des rues et des maisons | V1, chap. « L'Homme sans Marque » | S0 |
| **cristal de communication** | — | Appel avec image et voix | V1, chap. « La femme forte et robotique » | S1 |
| **cristal enregistreur** ; **salle de projection** | — | Images muettes enregistrées, projetées en salle | V2, chap. « De ce côté-ci de l'écran » | S2 |
| **fourneau de cristal** | réchaud de cristal | Cuisinière | V1, chap. « Directeur en carton » | S1 |
| **broche d'argent** | — | Broche à pierre bleue, transmise de fée en fée | V1, chap. « Le chat qui filait… » | S0 |
| **talisman de compréhension du langage** | Compréhension du Langage ; talisman de compréhension des langues | Pendentif qui fait parler à Willem la langue actuelle | V1, chap. « Celui qui ne devrait pas être en vie » | S1 |
| **gâteau au beurre** | — | Le gâteau promis : motif central de la série | V1, prologue | S0 |
| **agneau enveloppé** | — | Spécialité de Collina di Luce | V2, chap. « Le bon usage… » | S2 |
| ***Triade Passionnelle*** | *Bursting Triad* (7e tome, V5) | Roman d'amour à rebondissements lu à l'entrepôt | V1, chap. « Entrepôt de fées » | S1 |

## 3. Le monde

### 3.1 Regule Aire et ses îles

- **Un archipel dans le ciel** [S0]. Les survivants vivent sur des centaines de gigantesques dalles
  de pierre qui flottent et dérivent au gré du vent, sous un ciel d'un bleu profond ; on les appelle
  « îles flottantes ». Regule Aire en compte plus d'une centaine (V1, chap. « Le chat qui filait et
  la jeune fille » ; « L'Homme sans Marque »). Il n'y a **ni mer ni plage** : sous le bord des îles,
  une mer de nuages, et très loin dessous la surface grise (V1, chap. « Entrepôt de fées »).
- **Numérotation** [S0]. En spirale depuis l'île n° 1, au centre : petit numéro, île centrale ;
  grand numéro, périphérie. Jusqu'au n° 40, les îles sont proches, souvent stabilisées et reliées
  par des **chaînes et des ponts**, riches en commerce et en villes. À partir du n° 70, elles sont
  petites, isolées, rarement habitées et hors des lignes publiques (V1, chap. « L'Homme sans
  Marque »). Des numéros proches désignent en principe des îles proches (V2, chap. « Un Résultat »).
- **Ports** [S0]. Une partie du bord de l'île est plaquée de métal et équipée pour les dirigeables
  (V1, chap. « Le chat qui filait… »). Les grandes villes ont une **aérogare** [S2].
- **Fragilité** [S0-S2]. L'île n° 47 a sombré l'été précédant le V1 (V1, chap. « L'Homme sans
  Marque »). Tout ce qui flotte finira un jour par tomber, dit Limeskin (V2, chap. « Le bon usage de
  l'amour et de la justice »). En dernier recours, la Garde peut « lever les contraintes » d'une île
  pour la faire tomber (V2, chap. « Chasseur d'âmes — A »).
- **Barrière** [S2-S3]. Une grande barrière entoure l'archipel. Un dirigeable ordinaire s'y dérègle :
  pour descendre à la surface, il lui faut le traitement **Wessex Bordering** (V3, chap. « L'île
  N°49 »). Le Grand Sage l'a modifiée pour que les âmes ne tombent pas à la surface (V2, chap. « Une
  fois la guerre terminée »). De petites pierres flottantes se cachent dans les cumulonimbus et
  peuvent heurter un navire (V5, chap. « Un retour non désiré »).
- **Une civilisation copiée** [S2]. Les villes du ciel ressemblent à s'y méprendre aux colonies
  emnetwiht : architecture, cuisine, monnaie, vêtements, papier, institutions. C'est le plan de
  Suowong, le Grand Sage, au moment de la fondation ; à la surface, chaque race vivait autrement
  (semifères dans les arbres, orcs dans des tranchées, lézards sous des tentes d'herbe tressée)
  (V2, chap. « Les protecteurs du ciel d'azur »). **Conséquence pour la carte** : des villes de
  pierre et de brique d'allure humaine, peuplées de toutes les races.
- **Ressources** [S2]. Extraire la pierre d'une île revient à scier la branche où l'on est assis :
  la pierre est un matériau cher (V2, chap. « Villes et peuples anciens »). Le bois domine hors des
  vieilles villes (déduit).
- **Langue** [S4]. La langue commune de l'archipel diffère de la langue impériale d'autrefois
  (V4, chap. « Les étrangers »).
- **Politique** [S5]. Regule Aire n'est pas un bloc : îles et villes rivalisent ; la charte de
  Regule Aire du Grand Sage interdit de tuer, de voler, l'armement excessif et l'importation de
  Bêtes (V5, chap. « La fin du combat » ; « Les anciennes villes et les fées »).

**Îles connues par numéro**

| Île | Ce qu'on y trouve | Sources | Niv. |
| --- | --- | --- | --- |
| **n° 1** | Centre de l'archipel, origine de la spirale ; rien d'autre n'est décrit | V1, chap. « L'Homme sans Marque » | S0 |
| **n° 2** | « Cœur de Regule Aire » : sanctuaire presque au centre, plus haut que les autres, cerné d'orages, sans port, sans colonie ni ligne aérienne ; un bloc de cristal noir en forme de **pot de fleurs** couvert d'arbres où toutes les saisons fleurissent à la fois ; tour de cristal noir. Y vivent Ebon Candle et sa servante Kaya | V2, chap. « Les protecteurs du ciel d'azur » ; V5, chap. « Le Matin de ce jour » | S2 |
| | Puis Elq, Carmine Lake et Nephren ; le corps de Willem y repose ; « jardin d'été » nourricier | V5, chap. « Puis-je me blottir contre toi ? » | S5 |
| **n° 6** | Nephren associe à cette île le mot « impérial » ; rien d'autre | V4, chap. « Les étrangers » | S4 |
| **n° 11** | Collina di Luce (au sud de l'île) : quartier général de la Garde ailée, clinique générale d'Orlandry ; auberge d'Astartos près d'une grande route ; oliviers | V2, chap. « Villes et peuples anciens » ; V5 | S2 |
| **n° 13** | Ville du commerce du tabac (M. Rami) ; moitié ouest : Collectif Elpis, aireport à la pointe ouest | VEX, chap. « L'homme-chat » ; V5, chap. « Réunion secrète » | SEX/S1 ; S5 |
| **n° 15** | Grande île boisée visée par Timere ; champ de bataille ; coulée vers la surface | V1, chap. « Les valeureux et leurs successeurs » ; V2, chap. « Chasseur d'âmes — A » | S1 ; S2 |
| **n° 25** | Citée une fois par Willem (probable coquille pour n° 28) | V1, chap. « L'Homme sans Marque » | S0 |
| **n° 26** | Bois où naît une fée recueillie par la Garde | V5, chap. « La fin du combat » | S5 |
| **n° 28** | Île rude du sud-ouest, quartier de sang-mêlé hostile aux sans traits : Market Medley, Rue des Échoppes d'Étain ; Willem y vit dix-huit mois | V1, chap. « Le chat qui filait… » ; « L'Homme sans Marque » | S0 |
| **n° 31** | Port à étals (Glick y achète une tourte) | V3, chap. « Encore plus loin sous le ciel étoilé » | S3 |
| **n° 40** | Lac au bord duquel naît une fée | V5, chap. « La fin du combat » | S5 |
| **n° 47** | A sombré l'été avant le V1, avec un récupérateur | V1, chap. « L'Homme sans Marque » | S0 |
| **n° 48** | Bribe de conversation : « technologie rare » | VEX, chap. « Cinq cents ans » | SEX/S1 |
| **n° 49** | Base de la Garde ailée ; ville ordinaire de briques ; départ des expéditions de surface | V3, chap. « L'île N°49 » | S3 |
| **n° 53** | Communauté de reptiliens ; arrêt public le plus proche de l'île n° 68 (passeurs, bateau) | V1, chap. « L'Homme sans Marque » ; V3, chap. « L'île N°49 » | S0 |
| **n° 68** | Grande île périphérique couverte d'une immense forêt et de marais : l'entrepôt des fées, une ville, des villages d'hommes-bêtes | V1, chap. « L'Homme sans Marque » ; VEX, chap. « Cinq cents ans » | S0 |
| **n° 94** | Forêts natales de Chtholly ; monument de pierre moussu au bord de l'île | V3, chap. « La Fin d'un rêve, le début d'un rêve » ; « La Fin d'un rêve » | S3 (SEX/S1) |
| **n° 96** | Bataille contre Timere deux ans avant le V1 ; la fée Tuca y meurt | VEX, chap. « Cinq cents ans » | SEX/S1 |

### 3.2 Le ciel

- Ciel bleu profond le jour [S0], mer de nuages sous les îles [S1], cumulonimbus [S5] ; vents
  violents la nuit sur l'île n° 68 (V1, chap. « L'Homme sans Marque »).
- Couchers de soleil qui passent du bleu au violet puis au rouge (V3, chap. « La fille la plus
  heureuse du monde ») ; nuits très étoilées, comètes en hiver (V3, chap. « Des journées chaudes
  dans une saison froide »).
- Saisons : automne (V1), hiver et sa « saison des blizzards » (V2-V3), printemps (V5, VEX).
- On passe d'île en île en dirigeable, en passeur, ou, pour les fées, en volant : un vol vers les
  îles voisines est toléré (V3, chap. « Je suis à la maison »).

### 3.3 La surface et ses ruines

- **Vue d'en haut** [S1] : plus de vert, de bleu ni de jaune ; une poussière grise et boueuse couvre
  tout (V1, chap. « Entrepôt de fées »).
- **De près** [S1-S3] : les contours du monde sont conservés, mais des dunes ondulent là où étaient
  les collines (V1, épilogue). Sable gris si mou que le pied s'y enfonce, ruines de pierre comme
  trempées dans une teinture grise, tempêtes de sable (V3, chap. « Réunion »). Sous les ruines,
  souterrains froids, boueux, parfois gelés, et nids de Bêtes (V3, chap. « La Princesse souriante
  dans le cercueil de glace »).
- **Les Bêtes** y règnent. Seule Timere peut monter au ciel (§6).
- **Récupérateurs** [S0-S3] : ils fouillent les ruines pour des talismans et des reliques ; beaucoup
  meurent dès le premier jour (V1, chap. « L'Homme sans Marque »). Règle empirique : la survie
  chute nettement dès qu'un groupe atteint sept personnes, d'où de petites équipes (V3, chap. « La
  Princesse souriante… »). Descendre coûte cher (barrière, énergie, rations) (V5, chap. « Équipe
  d'urgence pour l'exploration de la surface »).
- **Points connus** : ruines K96-MAL (Gomag) [S3] ; Saints Pics de Fistirus, sommet le plus proche
  de l'archipel [S2] ; lac souterrain gelé où dormait Willem [S1].

### 3.4 Peuples et races

Loi commune : tuer un être intelligent est un crime (V1, chap. « Le chat qui filait… ») [S0]. Les
sangs sont rouges, bleus ou presque incolores selon les races (V5) [S5].

| Peuple | Aspect | Caractère, mœurs | Sources | Niv. |
| --- | --- | --- | --- | --- |
| **Sans traits** | Comme des humains : ni cornes, ni crocs, ni écailles | Parias, car ils rappellent les emnetwiht « maudits » des légendes ; trolls et imps en sont | V1, chap. « Le chat qui filait… » | S0 |
| **Reptiliens / lézards** | Stature très variable (Limeskin fait deux fois la taille de Chtholly) ; écailles ; palais qui déforme la prononciation | Très forts, culte du guerrier ; artilleurs en armure de la Garde | V1 ; V2, chap. « Chasseur d'âmes — A » | S0 |
| **Boggarts** | Nains du folklore ; Glick : peau gris-vert, petites cornes, oreilles pointues, crocs (ill.) | Simples, émotifs, instinctifs, souvent commerçants ; goûts très épicés | V1, chap. « L'Homme sans Marque » ; V3, ill. image7 | S0 |
| **Trolls** | Ogres d'aspect sans traits, grands | Coutume ancienne : choyer ses hôtes puis les manger ; aujourd'hui souvent aubergistes. Partager sa chair lie pour toujours ; funérailles « de démon » où l'on mange le défunt | V1 ; V3, chap. « La Fin d'un rêve » ; V4, prologue ; V5, chap. « Le jeune homme nommé Willem » | S0-S5 |
| **Imps** | Ogres sans traits | Vivaient jadis cachés parmi les emnetwiht pour les corrompre | V1, chap. « Le chat qui filait… » | S0 |
| **Orcs** | — | Nombreux ; jeunes orcs bruyants, compagnies (Blackfur) | V1 | S0 |
| **Lycanthropes** | Visage canin ou lupin, fourrure | Montrer ou toucher le ventre vaut engagement | V1 ; V2, chap. « Le mauvais usage… » | S0 ; S2 |
| **Ailuranthropes**, **sang-mêlé** | Traits de chat, de mouton, de cerf, de lapin | Très présents dans les villes | V1 ; V2 | S0 |
| **Semifères** | Oreilles animales (chat) | — | V2, chap. « Les protecteurs du ciel d'azur » | S2 |
| **Cyclopes** | Géants à un œil | Le médecin des fées en est un | V2, chap. « Villes et peuples anciens » | S2 |
| **Golems** | Golems de service, golems-tonneaux porteurs de caisses | Renseignent, portent, guident les touristes | V1 ; V2 ; V5 | S0 |
| **Gremians** | Peau violette, crâne chauve | — | V3, chap. « L'île N°49 » | S3 |
| **Hommes-bêtes**, **demi-bêtes** | Têtes et traits animaux | Villageois de l'île n° 68 | V3 ; VEX, chap. « Cinq cents ans » | S3 (SEX/S1) |
| **Primas** | Yeux de poisson | Leur oracle prédit les attaques de Timere | V5, chap. « La fin du combat » | S5 |
| Autres | Hommes-grenouilles, hommes-loups, hommes-lapins, tourterelles ailées, hommes-ballons | — | V2 à V5 | S2-S5 |
| Disparus | Emnetwiht, elfes, nains, dragons, morians | Éteints par les Bêtes en moins d'un an | V1, chap. « Le chat qui filait… » | S0 |

### 3.5 Les fées (Leprechauns)

- **Ce qu'elles sont** [S0-S1]. Des fillettes aux cheveux de couleur vive, toutes de sexe féminin,
  semblables aux emnetwiht pour le reste (V1, chap. « Directeur en carton »). Les archives les
  disent âmes d'enfants morts trop jeunes pour comprendre leur propre mort, égarées au lieu de
  partir ; pas vivantes au sens strict : des fantômes (V1, chap. « Les valeureux et leurs
  successeurs »). Le terme officiel est *Leprechaun* ; les vieux livres parlent aussi de feux
  follets, d'enfants ailés auréolés de lumière, de petites personnes hautes comme un genou.
- **Naissance** [S1-S5]. Une fée naît seule, dans une forêt ou au bord d'un lac (Chtholly pleurait
  seule dans une forêt sombre) ; la Garde ailée la recueille et l'amène à l'entrepôt (V1, ill.
  image3 ; V5, chap. « La fin du combat »).
- **Vie à l'entrepôt** [S0-S1]. Près de trente, puis plus de trente fées de 7 à 15 ans environ, avec
  une gardienne d'Orlandry (Nygglatho) et un responsable de la Garde (Willem) (V1 ; V2). Corvées,
  cuisinière du jour, lecture, jeux de ballon, argent de poche (V1 ; VEX). Sans autorisation, une
  fée ne quitte pas l'île n° 68, mais toute l'île lui est tacitement ouverte (V2 ; VEX).
- **Statut** [S1-S5]. Juridiquement des armes de la Garde, propriété d'Orlandry en réalité ; elles
  ne comptent ni comme soldats ni parmi les morts (V1, chap. « Les valeureux… » ; V3). Secret même
  au sein de la Garde ; un officier doit les accompagner pour les sortir (V5).
- **Maturité** [S1-S2]. Vers 13-15 ans, une fée « mûrit » : un **rêve de présage** l'annonce, puis
  un **ajustement** d'un jour à la clinique générale d'Orlandry de Collina di Luce (médicaments,
  hypnose), puis le test d'une épée compatible (V2, chap. « Villes et peuples anciens » ; V5). Elle
  devient **fée soldate adulte** et prend un nom en trois parties qui finit par celui de son
  Carillon : *Chtholly Nota Seniorious* (V1 ; VEX).
- **Pouvoirs** [S0-S3]. Allumer le venenum ; déployer des **ailes** de lumière, immatérielles, qui
  ignorent la physique (Chtholly : phosphorescence bleu-argent ; Ithea : ailes d'or couleur de blé ;
  Nephren : blanc-gris) ; faire de petites lumières ; manier les Carillons, car elles ressemblent
  assez aux emnetwiht pour tromper leur authentification (V1 ; V2, chap. « Le mauvais usage… » ;
  V3, chap. « Des journées chaudes… » ; V4, chap. « Les étrangers »). Elles banalisent la douleur et
  rient de leurs blessures (V1, chap. « Entrepôt de fées »).
- **Ce que ça coûte** : voir §7.4 (intoxication, empiètement, autodestruction).
- **Fin** [S1-S4]. Aucune ne devient adulte au sens de l'âge (V2). Une fée morte se dissipe en grains
  de lumière ; Chtholly est une exception : elle laisse un corps (V4, prologue). L'autodestruction
  se dit **ouvrir les portes du village des fées** (V1).
- **Le secret** [S2, S5]. Le Grand Sage et Ebon Candle font naître les fées par un rite sur une
  « âme géante » qui leur sert de matière, pour qu'elles ressemblent aux emnetwiht (V2, chap. « Une
  fois la guerre terminée »). Cette âme est celle d'Elq Hrqstn, brisée : chaque fée en est un éclat,
  et Elq a rêvé leurs vies (V5, chap. « Le visiteur Elq Hrqstn » ; « Les Fées de Collina di Luce »).

### 3.6 Les emnetwiht

- [S0] Race sans don particulier (ni écailles, ni crocs, ni ailes, magie faible, moins fertile que
  les orcs) qui dominait pourtant le monde grâce aux **Aventuriers**, à l'**Alliance**, aux
  **Braves** et aux **Carillons** (V1, chap. « Le chat qui filait… »). Éteinte il y a 526 ans ;
  Willem en est le dernier.
- [S1] Les légendes et livres d'images d'aujourd'hui en font des tyrans qui auraient invoqué les
  Bêtes (V1, chap. « Les filles de l'entrepôt »). Pour beaucoup, ils restent la « race maudite »
  qui a lâché les Bêtes sur le monde (V3, chap. « Les jours gris au sommet du gris »).
- [S2] Selon le Grand Sage, les Bêtes sont nées des recherches sur des armes biologiques des restes
  du **Vrai Monde**, culte armé révolté contre l'Empire que Willem et ses compagnons, menés par
  Lillia, avaient écrasé ; d'où l'idée que les emnetwiht ont détruit le monde (V2, chap. « Les
  protecteurs du ciel d'azur »).
- [S3-S4] Desperatio, un Carillon fait pour tuer des emnetwiht, fonctionne sur les Bêtes ; les Bêtes
  sont des emnetwiht transformés par une malédiction que le Vrai Monde a déclenchée (V3, chap.
  « L'Emnetwith suspect » ; V4, chap. « La nuit de la fin, la nuit du commencement »).
- [S5] Les Visiteurs ont fait créer les emnetwiht par les Poteaux en pétrissant les **bêtes
  primitives**, immortelles, avec des éclats de leurs propres âmes. Les emnetwiht se sont trop
  multipliés : la « croûte » d'âme s'est amincie et les dix-sept bêtes se sont libérées (V5, chap.
  « Les Fées de Collina di Luce »).

### 3.7 Les Visiteurs et les Poteaux

- [S0-S4] Pour l'Église, les Visiteurs sont des dieux venus d'une mer d'étoiles (V4, chap. « La fille
  aux cheveux cramoisis (I) »). On prie avant le repas : « que les Visiteurs nous bénissent » (V3).
  La dernière, **Elq Hrqstn**, était l'ennemie de l'Église ; une troupe de Braves l'a attaquée
  il y a plus de cinq siècles (V1, prologue).
- [S2] Trois **Poteaux** la protégeaient : **Ebon Candle**, **Jade Nail** et (S5) **Carmine Lake**
  (V2, chap. « Les protecteurs du ciel d'azur »).
- [S5] Les Visiteurs voyageaient entre les mondes dans un vaisseau que faisaient marcher les Poteaux ;
  ils ont oublié leur foyer et façonné ce monde à son image. Immortels, ils ne peuvent mourir que dans
  leur monde natal, sauf sous Seniorious (V5, prologue ; chap. « Le visiteur Elq Hrqstn »). Nils D.
  Foreigner, le maître de Willem, en est un (V5, prologue).

### 3.8 Les institutions

- **Garde ailée** [S0-S5]. Armée publique de Regule Aire contre les Bêtes (V1, chap. « L'Homme sans
  Marque ») ; n'appartient à aucune île et a le monopole de la guerre contre les Bêtes ; ne se mêle
  pas de politique (V2 ; V5). Branches : forces blindées (artillerie lézarde), première flotte,
  police militaire (insigne bouclier et faux, sabres courbes), service de recherche et de sauvetage
  (V2 ; V5). Quartier général à Collina di Luce, base sur l'île n° 49. Chef des fées : le commandant
  Limeskin. Le poste de responsable de l'entrepôt est une coquille vide, sans autorité ni promotion
  (V1, chap. « L'Homme sans Marque »).
- **Alliance des marchands d'Orlandry** [S0-S5]. Soutien majeur de la Garde, elle gère, entretient
  et possède réellement les Carillons et l'entrepôt ; elle y place une gardienne (Nygglatho) et
  possède la clinique générale de Collina di Luce (V1 ; V2 ; V3). Pas homogène : luttes de pouvoir
  internes (V5, chap. « La fin imminente »).
- **Le Grand Sage** [S2]. Suowong Kandel, fondateur et protecteur de Regule Aire, conseiller de la
  Garde (V2 ; V3).
- **Les villes** [S2-S3]. Collina di Luce a un maire depuis dix ans, contesté par l'ancienne
  noblesse (V2). La citoyenneté s'achète à la ville, comme une taxe facultative ; routes et ports
  sont payants (V3, chap. « L'île N°49 »).
- **Collectif Elpis** [S5]. Cité-État multiraciale de l'île n° 13, unie par une religion qui vénère
  son gros rocher, taxes d'entrée élevées ; veut remplacer Orlandry et la Garde (V5, chap. « Réunion
  secrète » ; « La fin imminente »).
- **Ancien monde** [S0-S4]. Empire et empereur ; Église de la Lumière Exaltée (un Legal Brave, une
  trentaine de Quasi Braves, traités comme des saints et payés comme des mercenaires) ; guildes des
  aventuriers fédérées par l'Alliance ; Tour impériale des Sages ; Vrai Monde (§8).

### 3.9 Technologie

- **Dirigeables** [S0-S5]. Pales ou hélices, **four enchanté** (ou chaudière enchantée) qui gronde
  et fait vibrer la coque, bras d'ancrage et stabilisateurs, rampe, sifflet ; lest d'altitude,
  plaques anti-poussière, canons (V1 ; V2, chap. « Le chemin du retour… » ; V3 ; V5). Lignes
  publiques à billets, passeurs privés, patrouilleurs de la Garde, navires d'observation de surface,
  transports « de classe semi-grande baleine ». Des « ailes de sauvetage » existent (V3, chap. « Le
  grand et jeune lézard »).
- **Cristaux** : cristaux lumineux (éclairage) [S0], cristal de communication avec image et voix
  [S1], fourneau ou réchaud de cristal [S1], cristaux enregistreurs pour les projections [S2].
- **Le reste** : lampes à gaz et à huile, horloges à cloches puis à cristaux, presses et journaux,
  pistolets, fusils à long canon, canons, golems (V1 à V5 ; VEX).
- **Savoir perdu** [S1] : personne ne sait plus fabriquer un Carillon (V1, chap. « Entrepôt de
  fées »).

### 3.10 Économie

- Monnaie : le **bradal** [S0] ; pièces de cuivre, pièces de vingt bradal (V2) ; une chambre
  d'auberge vers trente bradal (V5). Willem rembourse 32 000 bradal à Glick et en doit encore
  150 000 (V1, chap. « L'Homme sans Marque ») [S0]. Un Carillon en état de marche vaut plus qu'une
  saison de récupération : jusqu'à 8 millions de bradal, cinquante fois ce reste de dette (V1,
  chap. « Entrepôt de fées ») [S1].
- Échoppes soumises à certificat (V2) ; taxes d'entrée (Elpis) ; descentes de récupérateurs
  coûteuses (V5).

### 3.11 Vie quotidienne et nourriture

- **À l'entrepôt** [S1, SEX/S1] : tableau de corvées, cuisinière du jour (seule admise en cuisine),
  goûteuse, ballon (équipes rouge et blanche ; Willem a enseigné un jeu où même les maladroites
  touchent la balle), lecture, linge sur le toit, bains, jeux de société, argent de poche dépensé au
  café du village (V1 ; V3 ; VEX).
- **En ville** : snack-bar, café, boulangerie, librairie, horloger, boucher, salle de projection
  (V1 ; V2 ; V3).
- **Plats** :
  - entrepôt : ragoût, dessert spécial de Willem (œufs, sucre, lait, crème, baies, gélatine), gâteau
    au beurre (farine, beurre, œufs, lait, sucre, miel, noix, fruits secs), cheese-cake de
    Nygglatho, purée, porc sauté, soupe aux herbes et orange (V1 ; V3, chap. « Je suis à la
    maison » ; VEX) ;
  - villes : plateau du snack-bar (frites, lard épais, petit pain, soupe), agneau enveloppé de
    Collina di Luce (agneau frit et pommes de terre râpées dans de grandes feuilles, herbes
    acidulées), gaufres noisette et baies, brochettes, scones et confitures, tarte aux pommes,
    lait chaud au miel (V1 ; V2 ; V3 ; V5) ;
  - boissons : café (salé au café de l'île n° 28), thé amer et brûlant des lézards, thé au lait,
    café très sucré de Nephren, thé à la moutarde de Tiat (V1 ; VEX).
- **Romans** : *Triade Passionnelle*, roman d'amour à rebondissements, lu à l'entrepôt (V1) ;
  livres d'images sur les Braves et les emnetwiht.

### 3.12 Fêtes et croyances

- Prière avant le repas, « que les Visiteurs nous bénissent » (V3) [S3]. L'« idéologie du ciel »
  (partir vers les étoiles) est une idée surveillée (V3, chap. « Encore plus loin sous le ciel
  étoilé ») [S3].
- Anniversaires (le gâteau au beurre promis pour celui de Willem) [S0] ; fête de l'hiver de l'Empire,
  autrefois (VEX) [SEX/S2].
- Collina di Luce : un vœu d'amour devant la statue de Falcita vaudrait cinq ans de bonheur ;
  l'esprit du Puits de Souhait exauce un vœu sur mille pour une pièce de cuivre (V2) [S2].
- Les récupérateurs ont leurs superstitions (V3) ; Elpis vénère son rocher (V5).
- Trolls : partager sa chair lie pour toujours ; Nygglatho refuse de manger Chtholly morte selon les
  funérailles de démon (V3 ; V4, prologue) [S3-S4].

## 4. Atlas des lieux

Chaque fiche : où, aspect (architecture, matériaux, couleurs, végétation, taille, lumière,
ambiance), habitants, événements, niveau. Les couleurs données comme (ill.) viennent des
illustrations ; le reste vient du texte ou est marqué (déduit).

### 4.1 Île n° 68, vue d'ensemble [S0]

- **Où** : périphérie de l'archipel ; pas d'escale publique, on y vient depuis l'île n° 53 par
  passeur (V1, chap. « L'Homme sans Marque »).
- **Aspect** : grande île rurale presque entièrement couverte d'une immense forêt, un fragment de la
  nature d'autrefois transplanté dans le ciel ; des marais de toutes tailles dans les trouées ; des
  rivières ; une montagne où vivent des ours ; vents violents la nuit (V1, chap. « L'Homme sans
  Marque » ; V2 ; VEX, chap. « Cinq cents ans »).
- **Habitants** : hommes-bêtes dans de petits villages et une ville ; les fées et Nygglatho.
- **Événements** : tout le quotidien de l'entrepôt (V1 à V5, EX).

### 4.2 Port de l'île n° 68 [S0]

- **Aspect** : rue du port au bord du vide, vue sur la mer de nuages et la surface ; panneau usé par
  le vent, à flèches rouges : centre-ville à 2 000 marmer d'un côté, entrepôt n° 4 à 500 marmer de
  l'autre ; colline toujours ventée près de l'aire-port (V1, chap. « L'Homme sans Marque » ; V3,
  chap. « Le grand et jeune lézard »).
- **Événements** : arrivée nocturne de Willem [S0] ; retour des fées sous la pluie [S1] ; Nygglatho
  y livre ses cheveux coupés au vent [S3] (V3, chap. « La Fin d'un rêve »).

### 4.3 L'entrepôt des fées [S0-S5]

- **Où** : dans une clairière défrichée au bord de l'île, entre forêt dense et marécages sombres, au
  bout d'un sentier étroit sans lampadaire, à quelques pas d'un village d'hommes-bêtes (V1, chap.
  « L'Homme sans Marque » ; VEX, chap. « Cinq cents ans » ; final).
- **Bâtiment** : vieux **bâtiment de bois à deux étages** prévu pour une cinquantaine de personnes ;
  parquet usé, murs plâtrés, petites chambres alignées, tableaux de corvées et écriteaux (V1, chap.
  « L'Homme sans Marque » ; V2, chap. « De ce côté-ci de l'écran »). Délabré : plancher fragile,
  fuite au plafond du couloir du deuxième étage (planches assombries, marteau rangé au placard du
  bas), rambarde métallique branlante sur le toit (V2 ; V3 ; V5). Un orc d'Elpis le compare à une
  étable en ruine (V5, chap. « La fin imminente »).
- **Pièces** : réfectoire à grande fenêtre (tables de bois, grand vaisselier vitré, évier, marques
  de taille des fées sur le mur) ; cuisine à fourneau de cristal ; salle de lecture silencieuse, siège
  près de la fenêtre ; salle de stockage, dite aussi salle des matériaux ou des archives (plaque de
  bronze, mer de papiers, horloge, canapé) ; infirmerie (lit, rideaux, vase, calendrier) ; salle de
  récréation (tapis, peluches, jeux de société) ; chambre de Nygglatho (cheminée, service à thé,
  lampe à huile) ; chambre nue du responsable (lit, armoire, lampe murale, pas de rideaux) ;
  chambres des fées (rideaux beiges, miroir sur le bureau, murs minces) ; salle de bains à grand
  miroir, lavabos à l'eau froide ; vieux piano ; toit où sèche le linge, balustrade à hauteur de
  fée ; banc devant l'entrée ; **salle des armes** derrière une porte de métal rivetée à cinq
  serrures, crypte noire qui sent le moisi, où dorment les Carillons emmaillotés (V1, chap. « Entrepôt
  de fées » ; V2 ; V3, chap. « Des journées chaudes… » ; V4 ; V5 ; VEX, ill. image11).
- **Lumière, ambiance** : cristaux et lampes à huile, matins d'hiver froids, oiseaux bruyants, eau
  puisée à la rivière (V3) ; chahut permanent, avalanches de petites qui espionnent aux portes (V1).
- **Habitants** : plus de trente fées, Nygglatho, Willem (V2 ; V3).
- **Événements** : arrivée de Willem et quotidien du V1 [S0-S1] ; attente des aînées [S2] ; retour de
  Chtholly, gâteau au beurre, deuil [S3] ; menace de dissolution [S5] ; des années plus tard,
  Nygglatho envisage de le reconstruire, Willem revient [S5] ; Lakhesh y polit Seniorious [SEX].

### 4.4 Abords de l'entrepôt [S1-S5]

- **Terrain de jeux** : un peu petit, boueux, buts de ballon, bordé de fourrés ; minuscule potager
  et parterre fleuri ; terrain ou clairière d'entraînement derrière le bâtiment (herbe, sol meuble,
  banc, bâtons ramassés par terre) (V1, chap. « Entrepôt de fées » ; V2 ; VEX, chap. « Chtholly Nota
  Seniorious »).
- **Forêt** : forêt noire la nuit, éclairée par les étoiles ; marais qui sent l'eau, la terre et le
  vent ; mares cachées ; un **grand arbre** où grimpent les petites (V1 ; V5 ; ill. V5 image10).
- **Montagne** : derrière l'entrepôt ; Nygglatho y chasse l'ours quand elle a du chagrin (V2,
  chap. « Qu'est-il advenu de la promesse ? » ; V5).

### 4.5 La colline des étoiles [S1]

- **Où** : colline de la périphérie, près de l'entrepôt.
- **Aspect** : herbe, vent calme, air limpide, nuit étoilée. Quand Willem règle Seniorious, ses
  quarante et un talismans flottent autour de lui comme des étoiles et tintent (V1, chap. « Le ciel
  étoilé sous le ciel étoilé » ; ill. V1 image24).
- **Événement** : la promesse du gâteau au beurre (V1 ; VEX, chap. « L'endroit où je veux
  retourner »).

### 4.6 La ville de l'île n° 68 [S1-S3]

- **Aspect** : des centaines de bâtiments de pierre alignés sur une pente douce, idylliques, au bout
  d'un sentier forestier aux dalles envahies d'herbes ; on y circule sans se cacher, même sans traits
  (V1, chap. « Directeur en carton » ; V3, chap. « Je suis à la maison »).
- **Lieux** : snack-bar d'un jeune lycanthrope à tête de chien (fourrure châtaine) ; librairie,
  horloger, magasin d'accessoires, café, boucher ; **salle de projection** (scènes muettes et floues,
  lumière des cristaux en fin de séance) ; boulangerie d'un homme-bête grincheux ; « café habituel »
  sans thé ; marché du matin ; aérogare loin de l'entrepôt (V1 ; V2, chap. « De ce côté-ci de
  l'écran » ; V3).

### 4.7 Le village voisin et son café [SEX/S1]

- **Aspect** : petit village d'hommes-bêtes, à quelques pas de l'entrepôt, au bord de l'île ; son
  café est le seul endroit du coin où manger et boire (café le jour, alcool le soir), porte à
  clochette, arrière-boutique, serveur homme-chat en tablier qui offre des jus de fruits (VEX, chap.
  « Cinq cents ans »).
- **Maison Limashenka** : salon à vieille horloge murale à peigne doré, qui rejoue une comptine une
  fois réparée (VEX, chap. « L'homme-chat »).

### 4.8 Île n° 28 : Market Medley [S0]

- **Où** : île la plus rude du coin sud-ouest ; quartier de sang-mêlé décadent, hostile aux sans
  traits (V1, chap. « Le chat qui filait… »).
- **Aspect** : bazar mensuel devenu labyrinthe à force d'extensions : auvents d'échoppes, clôtures,
  rideaux, routes qui débouchent sur des toits, sol de plaques de métal bon marché, poulailler ;
  rues qui serpentent comme un organisme vivant ; toits de tuiles rouges (ill. V1 image3), pavés
  gris. **Rue des Échoppes d'Étain**, n° 7, à l'ouest : rue pavée étroite de pots et de couteaux,
  chapellerie voisine. Une **tour de débris** aux rambardes bricolées domine la ville, le port et le
  ciel. Avenues éclairées jour et nuit par des cristaux lumineux, fumée lavande, boggarts qui
  bonimentent, cloches au port, cafétéria bon marché (V1, chap. « Le chat qui filait… » ; « L'Homme
  sans Marque »). Il en tombe parfois bouilloires, bidons ou poulets (V3).
- **Événements** : poursuite du chat noir sur les toits, rencontre de Willem et Chtholly [S0].

### 4.9 Collina di Luce (île n° 11) [S2, S5]

- **Où** : au sud de l'île n° 11, au centre de l'archipel ; une journée de dirigeables depuis l'île
  n° 68, deux heures depuis l'île n° 15 (V2, chap. « Villes et peuples anciens » ; V5).
- **Aspect** : plus ancienne grande ville (plus de quatre cents ans), jamais touchée par la guerre,
  immense, tentaculaire, ouverte à toutes les races. Odeur de pierre et de brique patinées ; toits et
  murs **rouge brique et blanc gris** ; rues de briques, ruelles, statues de bronze partout, jusqu'au
  milieu des rues ; pigeons sur les réverbères ; jardins derrière des grilles de fer noir ; calèches ;
  bâtiments qui fuient sous la pluie, flaques qui brillent au soleil ; oliviers aux abords (V2 ;
  V5, chap. « Un retour non désiré » ; « Les anciennes villes et les fées »).
- **Habitants** : beaucoup de lycanthropes ; golems-tonneaux porteurs de caisses ; golems de
  l'office du tourisme (les enlèvements de touristes n'y sont pas rares).
- **Repères** :
  - **aérogare** : passerelle, rampe, place de marché aux tentes de toile usée ;
  - **place commémorative de Falcita** : fontaine, statue de bronze du Grand Sage en vieillard
    encapuchonné ; lieu des vœux d'amour ;
  - **quartier général de la Garde ailée** : mobilier pour grandes races, chambre de commandant à
    baldaquin sculpté de dragons, seau sous une fuite, boggarts et orcs en uniforme ;
  - **clinique générale d'Orlandry** : plafonds immenses à la taille du médecin cyclope ; ruelle
    arrière au linge tendu ;
  - **boucherie** au coin d'une petite place (le vrai agneau enveloppé), face à l'échoppe douteuse
    sur charrette ;
  - **tombe du parjure** (épitaphe d'un escroc vantant son honnêteté), **escalier des amoureux**
    (panneau municipal interdisant de dévaler les marches), **Puits de Souhait** (placette au
    croisement de six ruelles, puits banal) ;
  - **Cathédrale Centrale** et son clocher de trois siècles ; **place de l'Orge** (jongleur de
    couteaux, magicien grenouille cracheur de feu, musiciens masqués, bras de fer) [S5] ;
  - **Grande Bibliothèque Centrale** : tour blanc de craie, archives confidentielles « B-47 », café
    d'habitués à terrasse derrière [S5] ;
  - **marché du matin** : des centaines d'étals (légumes, viandes, œufs, pain, glace, épices, pierres
    pour lézards), vieux chapelier à vitrine [S5].
- **Événements** : soins de Tiat, retrouvailles, affaire Phyr [S2] ; réunion secrète, attaque des
  Auroras au marché, armure d'Elpis, mort de Willem [S5].

### 4.10 Auberge d'Astartos [S5]

- Bâtisse imposante et soignée, un peu isolée, au bord d'une grande route près de Collina di Luce ;
  grand salon du premier étage en petit restaurant (tables rondes, réchaud de cristal) ; escalier qui
  grince ; chambre de Willem et Elq dans un coin du deuxième étage ; chemin raide, ferme voisine au
  mur de pierre, pont public, nuits étoilées (V5, chap. « L'Homme sans passé » ; « Le Brave et le
  Visiteur »).

### 4.11 Île n° 15, le champ de bataille [S1-S2]

- Grande île boisée. Pendant la bataille : rangs de canons lézards, arbres fauchés, sol rasé, tente
  isolée à 1 200 marmer du front, caisses de rations (V2, chap. « Chasseur d'âmes — A »). Elle se
  fend comme une toile d'araignée de lumière quand Chtholly y plante Seniorious, puis tombe vers la
  surface (même réf.).

### 4.12 Île n° 49 [S3]

- Base de la Garde ailée (bureaux, arbre où dort un chat) et départ des expéditions de surface.
  Ville ordinaire bâtie pour ses habitants : ruelles pavées de briques, petits escaliers entre les
  maisons, enfants boggarts armés de bâtons, place avec café en terrasse sous parasols vert foncé,
  parc à bancs, chariot à gaufres, carillon au couchant ; routes rurales calmes (V3, chap. « L'île
  N°49 »).

### 4.13 Île n° 2, Cœur de Regule Aire [S2, S5]

- **De loin** : île plus haute que les autres, toujours enveloppée de nuages d'orage et de
  turbulences ; aucun navire ordinaire n'y arrive (V2, chap. « Les protecteurs du ciel d'azur »).
- **De près** : un immense **pot de fleurs de cristal noir** poli (un talisman géant), couvert
  d'arbres et de plantes où les saisons se mêlent (fleurs de printemps et d'automne, pommes et pêches
  côte à côte), grâce à une petite barrière qui règle le climat. Pas de port. Au centre, une **tour
  de cristal noir** hérissée d'épines, escalier en colimaçon, salle du trône vide ; les cristaux de
  communication n'y passent pas (même réf.). Colonnes blanches et ciel sans fin (ill. V5 image4),
  « jardin d'été » [S5].
- **Habitants** : Ebon Candle, Kaya [S2] ; Elq, Carmine Lake, Nephren, le corps de Willem [S5].

### 4.14 Collectif Elpis (île n° 13) [S5]

- Moitié ouest de l'île n° 13 : cité-État multiraciale, religion de son gros rocher, taxes d'entrée
  élevées, aireport à la pointe ouest (V5, chap. « Réunion secrète » ; « Le Matin de ce jour »). Peu
  décrit : à concevoir (original) sans contredire ces traits.

### 4.15 Les dirigeables [S1-S5]

- **Barocupot** [S1] : dirigeable de la Garde ailée ; salle du conseil de guerre exiguë au deuxième
  pont ; Limeskin y sert un thé brûlant (V1, chap. « La fille errante et le lézard volant »).
- **Saxifraga** [S3] : « vaisseau d'observation de surface » ; vibration grave des fours enchantés,
  cabine de gardes à lits de camp, soute à artefacts ; finit en épave échouée dans le sable (V3,
  chap. « Encore plus loin sous le ciel étoilé »).
- **Plantaginesta** [S3] : transport « de classe semi-grande baleine », solide mais inconfortable,
  qui tangue et roule ; tuyaux partout, odeur d'huile, graffitis, boîtes vides de pâte de viande,
  murs de tôles d'acier, de cuivre et d'étain, réserve labyrinthique au fond de la cale, soute à
  grande porte de service, salle de contrôle à annonces, grand canon, **vieille horloge déformée**
  (V3, chap. « L'Emnetwith suspect » ; « L'horloge en lambeaux et désuète »).
- **Patrouilleur de la Garde** [S4] : navire moyen qui fait des rondes entre les îles centrales ;
  chaudière qui berce la coque, grande fenêtre à croisillons (V4, prologue ; ill. V4 image7).
- **Tomorrow Grasper No. 7** [S5] : navire militaire d'Elpis déguisé en navire civil d'observation
  (plaques anti-poussière tachetées, hélices dépareillées, chat noir peint, « AGENCE D'AVENTURE
  BATO ») ; cales-forteresses à cercles de bois, de minéraux et d'os sur acier argenté (V5, chap.
  « Un retour non désiré »).

### 4.16 Ruines de Gomag (K96-MAL), au présent [S3]

- **Aspect** : sable gris si mou que le pied s'y enfonce ; ruines de pierre comme trempées dans une
  teinture grise ; tempêtes de sable ; épave du Saxifraga, tentes, feux de camp ; crépuscules du
  bleu au violet puis au rouge ; terrain vague desséché (V3, chap. « Réunion » ; « La fille la plus
  heureuse du monde » ; V4, chap. « Les étrangers »). Domaine de Timere (V4, chap. « La nuit de la
  fin… »).
- **Ce qui s'y passe** : soins de Nopht et Rhantolk, Desperatio, demande en mariage ; assaut des
  Timere de 18 h 26 à 18 h 51 ; dernier combat de Chtholly [S3]. Puis la Première Bête occupe le site
  et rend tout au sable [S4]. Camp d'Elpis, Nephren retrouvée [S5].
- **Couleurs** (ill. V3 image6) : gris de cendre, ciel pâle, uniforme noir de Willem pour contraste.

### 4.17 Souterrains de Gomag [S3-S4]

- Au moins quatre niveaux immenses, couloirs effondrés et tordus, boue et eau, froid croissant,
  flaques gelées au quatrième niveau ; seule lumière : un petit cristal lumineux ; **nid de Timere**
  ; salle presque entièrement prise dans une glace très transparente où dort une fillette aux très
  longs cheveux, plaie à la poitrine (V3, chap. « La Princesse souriante dans le cercueil de glace » ;
  ill. V3 image17). [S4] C'est l'installation souterraine du Vrai Monde sous la grande place de Gomag
  (V4, chap. « La nuit de la fin… »).

### 4.18 Gomag d'autrefois, le rêve [S4]

- **Ville** : petite ville de campagne (environ 3 000 habitants), à l'écart de la grande route
  commerciale nord-sud. Toits de briques colorées, pavés moussus, briques fissurées, graffitis sur le
  plâtre, cheminées fumantes ; canal d'irrigation entre quartier résidentiel et centre ; rues en
  pente, escaliers étroits, odeur d'épices le soir ; terres agricoles, chapelle, drapeau rouge de la
  guilde ; montagne au loin, forêts de châtaigniers. Hiver : neige, soleil couché tôt (V4, chap.
  « Les étrangers » ; « Les Quasi-Brave sont rentrés à la maison » ; « Les aventuriers »).
- **Orphelinat commémoratif Foreigner** : grand bâtiment de bois vieilli à deux étages, ancienne
  école promise à la démolition, murs et toit rapiécés ; toit accessible, couloir qui grince, salon
  (canapé usé, poêle), cuisine, cour (clôture, arbre, puits, linge) ; 21 enfants menés par Almaria
  (V4, chap. « Père et Fille » ; « Les étrangers » ; ill. V4 image4, image8).
- **Autres lieux** : quartier de l'université (librairies, café étudiant, menu sur tablette
  d'argile) ; guilde des aventuriers (taverne remaniée, horloge à coucou, cidre, interdite aux moins de
  quinze ans) ; hôpital (service gardé de comateux) ; promenade des canaux (barques, peintres,
  violonistes) ; quartier de l'est (immeubles serrés, puits public, châtaignes grillées) ; église et
  grande place au clocher, fontaine hors service ; installation souterraine aux couloirs blancs
  couverts de formules griffonnées, grande salle du pilier de cristal (V4).

### 4.19 L'ancien monde, il y a plus de cinq siècles [S1-SEX]

- **Orphelinat de Willem** [S1] : ancienne école maternelle délabrée, une vingtaine d'enfants, en
  bordure d'une petite ville aux rues pavées bordées d'arbres (V1, prologue ; ill. V1 image12 :
  cuisine à bocaux et pots).
- **Cabane du prologue** [S2] : cabane de bois abandonnée près du district de Tihuana, au-dessus
  des nuages (V2, prologue ; ill. V2 image9).
- **Capitale impériale** [S3-SEX/S2] : démesurée, quartiers numérotés (1er : le temple ; 2e et 4e :
  commerce ; 6e : auberges louches et bars), rue du Griffon, rue de la Salamandre, quartier des
  étudiants impériaux. **Premier Temple** sur un haut-plateau artificiel au milieu de la grande
  rivière Melchera, trois ponts pavés de tuiles géométriques, vitraux, autel de marbre ; salon de
  lumière de la Legal Brave (marbre blanc, laine rouge, bougies). **Atelier** sans fenêtre où
  flottent les fragments des Carillons. **Château impérial** et son jardin (V3, prologue ; V5,
  prologue ; VEX, chap. « La Capitale Impériale » ; « Sang Précieux »).
- **Front nord et bois sombres** [SEX/S2] : neige, tentes couleur de boue ; forêt empoisonnée
  striée de pourpre aux arbres déformés, conquise par les elfes ; **Narvant**, ville nouvelle aux
  fleurs orange, réduite en ruines calcinées (VEX, chap. « Le Soleil Couchant » ; « La fleur se
  balance au sommet du pic »).

### 4.20 Lieux du rêve et de l'âme [S2-S5]

- Ruines obscures du rêve de Chtholly : portes brisées, peluches, livres d'images illisibles,
  cristaux ; une enfant nommée Elq y guide Chtholly (V2, épilogue).
- Monde clos d'Elq : petit monde sans soleil ni lune, peluches cassées, livres d'images, où chaque
  jour reste « aujourd'hui » (V5, chap. « Le visiteur Elq Hrqstn »).
- Rêve final de Willem : minuscule plateforme pavée d'hexagones gris dans un vide noir, soleil
  couchant (V5, chap. « Puis-je me blottir contre toi ? »).

## 5. Personnages

Pour les sprites : les couleurs « indicatives » ont été relevées sur les illustrations et restent à
ajuster ; le texte prime. Les surnoms entre guillemets sont ceux de la traduction.

### 5.1 Chtholly Nota Seniorious

- **Identité** : fée (Leprechaun), fée soldate adulte, l'aînée et la plus grande de l'entrepôt ;
  15 ans ; compatible avec Seniorious, dont le nom termine le sien (V1, chap. « Les filles de
  l'entrepôt » ; « La femme forte et robotique ») [S0-S1]. Née dans une forêt de l'île n° 94 [S3 ;
  SEX/S1].
- **Apparence** :
  - cheveux longs **céruléen clair**, sous les épaules (indicatif #6C89BB à #92B6DB) ; deux petites
    couettes hautes sur les dessins en pied et en chibi (ill. V1 image9 ; VEX image4) ; elle n'aime
    pas cette couleur trop « fée » ;
  - yeux bleus un peu plus foncés que les cheveux, « couleur océan » (V1) ; petite à côté de Willem ;
  - **en ville** : grand chapeau et manteau gris souris, enfoncés pour cacher ses cheveux, puis le
    chapeau un peu grand que Willem lui achète ; plus tard un grand chapeau bleu foncé (V1, chap.
    « Le chat qui filait… » ; V3, chap. « Réunion »). Illustrations : chapeau sombre à large bord et
    pointe tombante, fleurs roses, col montant blanc, haut bleu nuit, corsage blanc lacé en
    croisillons, jupe blanche à volants, jupon noir (ill. V1 image1) ; ou chapeau marine à nœud bleu
    clair, blouse marine à grand col blanc (ill. VEX image1) ;
  - **broche d'argent** à pierre bleue en goutte, sur la poitrine (V1 ; ill. V1 image1) ;
  - **en mission** : uniforme de la Garde (veste sombre, jupe plissée), armure légère, Seniorious dans
    le dos, emmaillotée de tissu blanc (V1 ; V2) ; manteau militaire bleu marine à col droit et
    boutons argentés (ill. V3 image1) ;
  - **ailes** : lumière, phosphorescence bleu-argent (V3, chap. « Des journées chaudes… ») ;
  - **plus tard** : yeux qui rougissent sous l'empiètement [S2] ; mèches rouges, puis un tiers de la
    chevelure, puis rouge flamboyant [S3].
- **Personnalité** : fière, veut être traitée en adulte, rarement franche ; froide en public,
  spontanée quand elle s'oublie ; aînée exemplaire (pas de dessert ni de sucre devant les petites) ;
  romantique (romans d'amour), jalouse, observatrice redoutable ; résignée à mourir mais terrifiée,
  elle pleure en cachette (V1 ; V2 ; V3 ; VEX).
- **Parler** : tutoie Willem ; « Monsieur le responsable » puis son prénom, « idiot » quand elle est
  vexée ; bafouille quand elle est troublée ; vouvoie Limeskin (« commandant ») ; « Ren » pour
  Nephren, « Rhan » pour Rhantolk. Les petites l'appellent « Mlle Chtholly » ou « mademoiselle ».
  Ripostes sèches, aveux qui sortent de travers, jamais de déclaration directe.
- **Relations** : Willem (premier amour) ; Ithea et Nephren (camarades d'armes) ; Tiat (admiratrice) ;
  Nygglatho (mère de substitution, « rivale » déclarée) ; l'aînée morte qui lui a laissé la broche.
- **États** :
  - [S1] Doit ouvrir les portes du village des fées contre le fragment de Timere qui vise l'île
    n° 15 ; Willem règle Seniorious et promet un gâteau au beurre si elle revient (V1).
  - [S2] Au front, souvenirs d'une autre, yeux rouges ; fait tomber l'île n° 15 seule ; coma ; dans
    un rêve, une enfant nommée Elq la renvoie ; elle se réveille (V2).
  - [S3] N'est plus une Leprechaun et ne doit plus toucher un Carillon ; mange le gâteau promis ;
    oublis, cheveux qui rougissent ; Willem la demande en mariage ; à Gomag, elle prend Desperatio,
    tranche 715 Bêtes, remercie Willem et s'éteint (V3, chap. « La fille la plus heureuse du
    monde » ; « La Fin d'un rêve »).
  - [S4] Son corps est rapporté, déchiré par son propre venenum : elle ne s'est pas dissipée en
    lumière (V4, prologue).
  - [S5] Elq, dont elle est un éclat d'âme, a rêvé sa vie (V5, chap. « Le visiteur Elq Hrqstn ») ;
    une fillette aux cheveux céruléens, Ryehl, rejoue sa chute sur Willem (V5, épilogue ; lien non
    confirmé).

### 5.2 Willem Kmetsch

- **Identité** : le dernier **emnetwiht**, que l'on prend pour un sans traits, réveillé il y a un
  an et demi, environ dix-huit ans [S0] ; pétrifié plus de cinq siècles [S1] ; il avait seize ans le
  soir de son départ et son corps a vieilli de deux ans depuis son réveil [S4] (V1, chap. « L'Homme
  sans Marque » ; V4, chap. « Les étrangers »). Titre de façade :
  **sous-officier des Armes Enchantées** (variantes : officier en second, deuxième officier des
  enchantements), responsable de l'entrepôt (V1 ; V2). Ancien **Quasi Brave** [S1], niveau 69 [S4].
- **Apparence** : grand et mince ; cheveux noirs en bataille, yeux noirs, visage banal ; sourire
  vague, regard vide (V1, chap. « Le chat qui filait… » ; V4 ; VEX).
  - île n° 28 : manteau usé à capuche, capuche relevée pour cacher son absence de traits [S0] ;
  - entrepôt : uniforme militaire noir qui ne lui va pas (V1, chap. « Les filles de l'entrepôt ») ;
    ill. : uniforme croisé noir ou bleu nuit à boutons et liserés dorés, épaulettes, ceinturon,
    bottes (ill. V1 image22 ; V3 image6) ; tablier et mouchoir noué sur la tête pour pâtisser (V3) ;
    pendentif-talisman de langage (ill. V3 image18) ;
  - il y a cinq siècles : cape blanche de Quasi Brave à capuche, col et manches noirs (ill. V1
    image11) ;
  - [S5] œil droit **doré** de Bête sous un cache-œil, l'œil gauche reste noir (V5, chap. « L'Homme
    sans passé »).
- **Arme** : aucune au présent (son corps ne le permet plus) ; bâton d'entraînement ; il règle les
  Carillons ; il se bat surtout à mains nues avec ses techniques (§7.5).
- **Personnalité** : doux avec les enfants (le « papa » de l'orphelinat), autodérision, plaisante
  pour esquiver ; mélancolie, culpabilité de survivant ; ne fuit pas son poste, regarde la réalité en
  face, ne promet rien à la légère ; père jaloux ; travaille jusqu'à casser ; gauche avec les
  femmes ; sa tendresse passe par les actes (cuisiner, réparer, offrir) (V1 ; V3 ; V4 ; VEX).
- **Parler** : registre familier, parfois cru ; tutoie ses proches et les enfants, vouvoie avec une
  politesse ironique les supérieurs et les inconnus ; à quinze ans, laconique (« Yo. ») (VEX).
  Surnoms donnés : « Ren » (Nephren), « Al » (Almaria), « petite princesse paresseuse » (Elq), « ces
  chauves » (les prêtres). Surnoms reçus : « Willie » (les petites, Lillia, Elq), « papa »
  (orphelins), « Monsieur le Directeur », « tonton » (Collon le réclame), « Officier » (Ithea,
  Rhantolk), « être délicieux » (Nygglatho), « guerrier » (Limeskin).
- **États** :
  - [S0] Rembourse sa dette à Glick, accepte le poste à l'entrepôt.
  - [S1] Pétrifié après un combat de trois jours et des sorts interdits ; trouvé au fond d'un lac
    gelé ; corps en ruine (allumer son venenum le met en danger) ; règle Seniorious ; promet le
    gâteau ; décide de rester pour qu'on puisse l'accueillir (V1).
  - [S2] Retrouve le Grand Sage, refuse la reconquête de la surface ; « Bienvenue à la maison » à
    Chtholly endormie (V2).
  - [S3] Demande Chtholly en mariage ; tombe à la surface en sauvant Nephren ; porté disparu (V3).
  - [S4] Dans le rêve de Gomag, détruit le Chanteur (Almaria), en absorbe l'essence et devient une
    Bête (V4).
  - [S5] Amnésique, transporté par Elpis, aide d'auberge et masseur avec Elq ; la mémoire revient ;
    joue la Bête pour rendre aux fées leur valeur ; Lakhesh le tue avec Seniorious ; son corps repose
    sur l'île n° 2 ; il revient à l'entrepôt des années plus tard (V5).

### 5.3 Ithea Myse Valgulious

- **Identité** : fée soldate adulte, dans sa quatorzième année ; Carillon **Valgulious** (V1, chap.
  « Les filles de l'entrepôt ») [S1].
- **Apparence** : cheveux couleur de **blé mûr** (aussi « dorés et décolorés », « herbe flétrie »),
  iris couleur de bois délavé (ou dorés), yeux légèrement bridés, regard félin, sourire amical (V1 ;
  V2). Ill. : blond paille à orangé (indicatif #FDE7BD à #E4B68E), deux mèches pointues comme des
  oreilles de chat, longues tresses à perles, petit croc, écharpe rouge, collier de losanges sombres et
  rouges, veste vert pâle à larges manches, robe brun-rouge, short noir, bas vert olive, bottes brunes
  (ill. V1 image5) ; puis veste blanche à capuche et perle bleue (ill. V2 image1). Ailes d'or couleur
  de blé (V2). Porte une longue épée emmaillotée.
- **Personnalité** : taquine, bavarde, friande de ragots, entremetteuse, lucide et protectrice sous la
  blague ; sourire-masque (V1 ; V2 ; V3).
- **Parler** : rire **« Nya-ha-ha »** ; vouvoie Willem avec ironie (« Officier », « Monsieur
  l'Officier », une fois « Officier Scoundrel »), le tutoie parfois ; « M. Lézard » pour Limeskin,
  « minus » pour Tiat ; pour faire enrager Chtholly, appelle Willem « gros idiot de papa » (V1 ; V2 ;
  VEX).
- **États** : [S2] connaît l'empiètement de près (lueur rouge dans ses yeux dorés) et garde le secret
  de Chtholly. [S3] Avoue que sa propre vie antérieure l'a remplacée il y a deux ans : elle joue
  l'Ithea d'origine, apprise dans ses journaux (V3, chap. « La Fille sans visage »). [S5] Cette vie
  antérieure était une Leprechaun morte à dix-huit ans il y a près de vingt ans avec le Carillon
  **Parchem** (V5, chap. « Faire face au passé ») ; sa force vitale s'épuise ; des années plus tard,
  elle est en fauteuil roulant à l'entrepôt (V5, épilogue).

### 5.4 Nephren Ruq Insania (« Ren »)

- **Identité** : fée soldate adulte, dans sa treizième année, mûre depuis l'été ; Carillon
  **Insania**, grande et lourde (V1, chap. « Les filles de l'entrepôt » ; V3) [S1]. Paraît dix ans.
- **Apparence** : toute petite ; cheveux **gris terne, cendrés, ondulés**, d'un argent singulier ;
  yeux couleur charbon, anthracite, au regard lointain ; jamais d'expression (V1 ; V4). Ill. :
  couettes ondulées gris lilas très clair (indicatif #D3D0E6) nouées de rubans bruns ou noirs, yeux
  gris, tunique violette à capuche à frise de triangles blancs, livre rouge (ill. V1 image4 ; V2
  image1). Ailes blanc-gris (V4). [S5] œil gauche **doré** fermé puis caché sous un cache-œil, tissu
  rouge en guise de robe, puis manteau violet à capuche (V5 ; ill. V5 image4).
- **Personnalité** : laconique, logique, curieuse, grande lectrice, discrètement attentionnée (café
  très sucré et sandwich pour Willem, nuit d'archives) ; fait respecter le silence de la salle de
  lecture ; hantée par l'idée que le monde se brise ; s'endort sur Willem comme sur une couverture
  (V1 ; V3 ; VEX).
- **Parler** : phrases très courtes, « Mm. » ; tutoie Willem ; exige qu'il tienne parole ; pince
  quand il triche ; se dit « animal de compagnie » chargé de l'empêcher de s'effondrer (V2 ; V4).
- **États** : [S3] au bord de l'explosion, elle se jette du Plantaginesta pour épargner l'équipage ;
  Willem plonge et sacrifie Insania. [S4] Dans le rêve, apprend la langue impériale, manie Dindrane,
  absorbe une part du Chanteur. [S5] À moitié Bête : ne mange plus, ne vieillit plus, les Auroras
  l'ignorent ; seule à voir Carmine Lake ; vit sur l'île n° 2 près du corps de Willem (V5).

### 5.5 Nygglatho

- **Identité** : **troll** d'apparence sans traits ; environ dix-huit ans (V1) ou la vingtaine
  (V2-V3) en apparence ; gardienne de l'entrepôt pour Orlandry, infirmière (licences de médecine de
  base et de cuisine), cuisinière, vraie autorité du lieu ; a soigné Willem à son réveil (V1 ; V3)
  [S0-S1].
- **Apparence** : grande, une tête de plus que la foule ; longs cheveux **rouge pâle**, roux ou roses
  (indicatif #D98088 à #F3A3A6) ; yeux **vert printanier** ; visage enfantin ; chemisier vert vif,
  tablier blanc ; robes à volants, pantoufles ; blouse de laboratoire pour soigner (V1, chap.
  « L'Homme sans Marque » ; V2 ; V3 ; V5). Ill. : coiffe blanche à volants, col vert à ruban noir et
  broche (ill. V1 image6) ; serre-tête blanc et robe sombre (ill. V4 image7).
- **Personnalité** : douce, polie, maternelle, stricte sur les manières, d'une force terrifiante ;
  lit dans les pensées ; menace en souriant de manger les enfants ou Willem (neuf fois sur dix une
  blague) ; se force à être une mère forte et pleure seule ; quand une fée ne revient pas, elle part
  chasser l'ours dans la montagne ; n'oublie aucune des fées mortes (V1 ; V2 ; VEX).
- **Parler** : tutoie Willem (« être délicieux ») ; « mes filles » pour les fées ; compliments
  carnivores et sourires inquiétants ; clin d'œil (V1 ; V2 ; VEX).
- **États** : [S3] rivale déclarée de Chtholly ; se coupe les cheveux après sa mort. [S4] Refuse de
  manger son corps. [S5] Révèle sa nature de troll devant un orc d'Elpis et rase le café ; diplômée
  brillante d'Orlandry reléguée à l'entrepôt ; fille probable de l'aubergiste Astartos ; toujours
  tutrice des années plus tard, elle accueille Willem (V5).

### 5.6 Les petites fées

| Nom | Apparence | Caractère, parler | Devenir | Sources |
| --- | --- | --- | --- | --- |
| **Tiat** puis **Tiat Siba Ignareo** | Moins de dix ans d'apparence ; cheveux et yeux **verts**, « couleur de feuilles fraîches » (indicatif #78B89E) ; ill. : blouse blanche, gilet vert sombre | Romantique, nourrie de projections, gourmande, boit son lait d'un trait pour grandir, refuse d'être traitée en enfant ; idolâtre Chtholly (« mademoiselle »), copie son thé à la moutarde | [S2] rêve de présage ; [S3] reçoit la broche de Chtholly ; [S5] fée adulte, Carillon Ignareo ; devient stoïque | V2 ; V3 ; V5 ; VEX ; ill. V2 image4 |
| **Lakhesh** puis **Lakhesh Nyx Seniorious** | Cheveux **pêche** (orange sur ill., petite couette de côté), yeux bruns ; gilet brun clouté | Polie (« M. Willem », « Mlle Chtholly »), douce, rêveuse, s'excuse sans cesse, pense aux provisions ; aura printanière | [S5] rêve spécial, manie Seniorious et tue Willem-Bête ; [SEX] porteuse de Seniorious, la polit | V1 ; V3 ; V5 ; VEX |
| **Collon** | Longs cheveux **roses**, bandeau rouge, un petit croc, tunique lacée | Intenable, franche, jeux de mots ; grimpe sur Willem et exige qu'il crie « tonton » ; a jadis enfoncé un mur | [S3] fièvre, talisman de Seniorious sous l'oreiller | V1 ; V2 ; V3 |
| **Pannibal** | Une dizaine d'années ; cheveux et yeux **violet vif**, frange sur un œil ; cape ou veste à capuche sombre | Énergique, redoutable à l'épée de bois, pince-sans-rire, conseils violents ; triture sa frange, mâchonne une brindille | [S0] embusque Willem à son arrivée | V1 ; V2 ; VEX |
| **Almita** | Minuscule ; cheveux crépus **jaune citron** | — | [S3] tombe du toit la nuit des comètes ; [S5] cuisinière réputée de l'entrepôt | V3 ; V5 |
| Autres | Eudea, Pipe, Kana, Tazeka, Giniette ; **Ryehl** (cheveux céruléens, yeux indigo, moins de dix ans) | — | [S5 ; SEX] | V5, épilogue ; VEX |

Elles parlent en chœur, espionnent aux portes et s'effondrent en avalanche, rient de leurs blessures
(V1, chap. « L'Homme sans Marque »). **L'aînée à la broche**, sans nom, née cinq ans avant Chtholly
dans la même forêt, mangeait du gâteau au beurre au retour de chaque mission avant de mourir au combat
(V1, chap. « Entrepôt de fées ») [S1]. Fées mortes citées : **Tuca Kog Rosaureum** (grande, cheveux et
yeux vert profond, morte en ouvrant la porte il y a deux ans), **Orco Ros Ignareo**, Clakia, Ayol,
Katariella (VEX, chap. « Cinq cents ans ») [SEX/S1].

### 5.7 Nopht Keh Desperatio et Rhantolk Ytri Historia [S3]

- **Nopht** : fée soldate adulte du même âge que Chtholly ; cheveux **vermillon** courts et hérissés,
  allure de garçon (V3) ; ill. : rose-rouge (indicatif #EF7F7B), yeux rouges, sweat à capuche brun
  foncé, bretelles rouges, short bordeaux à ourlet déchiqueté sur jambières noires, brindille (ill.
  V3 image4). Carillon **Desperatio**. Énergique, gourmande, frappe d'abord, s'ennuie vite, se fie au
  jugement de Rhan ; joue du piano ; croque son orange avec la peau (V3 ; V4 ; VEX). [S5] sans épée,
  sportive, plus tard garde du corps de récupérateurs.
- **Rhantolk** (« Rhan ») : fée soldate adulte, cheveux **indigo** (ill. : bleu lavande, frange
  droite, indicatif #868BBF à #A1A1D0) ; fichu blanc, robe bleu ciel lacée à pèlerine, ceinture sombre
  nouée, lanterne (ill. V3 image5). Carillon **Historia** (rafales tranchantes). Lit un peu la langue
  emnetwiht, raisonne sur tout, avocate du diable, distante et timide avec les inconnus, longues
  tirades défensives ; se méfie de Willem parce qu'il est emnetwiht (V3 ; V5). Pour elle, seul
  l'intéressé peut juger de son bonheur (V3, chap. « La Fin d'un rêve »). [S5] rate un gâteau, cherche
  l'origine des fées ; plus tard agente de liaison de l'entrepôt avec Orlandry.

### 5.8 Limeskin [S1]

- **Identité** : **reptilien** géant, facilement deux fois la taille de Chtholly ; écailles blanc
  laiteux ; **commandant** de la Garde ailée (forces blindées), chef des fées et supérieur nominal de
  Willem (V1, chap. « La fille errante et le lézard volant » ; V2).
- **Apparence** : ill. : tête draconique cornue, tresse à plumes, collier tribal (ill. V2 image13) ;
  en civil, chemise de lin et veste de cuir brodée choisie par sa fille (V3, chap. « Le grand et jeune
  lézard »).
- **Caractère** : culte du guerrier, ne ment jamais, droit, pince-sans-rire, rusé ; sert un thé
  brûlant et amer (V1 ; V3).
- **Parler** : allonge les sifflantes (« Sss… », « Ccc… »), métaphores guerrières ou sur le vent,
  souvent incompréhensibles ; vouvoie Willem et l'appelle « guerrier » ; Chtholly est la « guerrière
  céruléenne » (V1 ; V2 ; V5).
- **États** : [S2] oncle de cœur de Phyr ; [S3] suspendu pour la forme après la chute de l'île n° 15 ;
  [S5] prévient que certains veulent dissoudre l'entrepôt.

### 5.9 Glick Graycrack [S0]

- **Identité** : boggart, jeune, vieil ami de Willem, **récupérateur** ; lui trouve le poste à
  l'entrepôt ; conseiller d'Orlandry pour les expéditions (V1 ; V3) ; nom complet en V5.
- **Apparence** : ill. : peau gris-vert, petites cornes, oreilles pointues, yeux ambrés, crocs,
  lunettes d'aviateur sur le front, gilet de cuir matelassé, mitaines (ill. V3 image7) ; chauve, sans
  sourcils, jumelles (V5).
- **Caractère, parler** : rationnel, chaleureux, débrouillard, langage cru ; dit « mesdames » aux
  fées ; réplique fétiche avec Willem : le café « un peu salé » (V1 ; V3).

### 5.10 Phyracorlybia Dorio (« Phyr ») [S2]

- Lycanthrope, fille du maire de Collina di Luce (**Gil-Andalus Dorio**, homme-loup à monocle, V5) ;
  nièce de cœur de Limeskin. Fine fourrure blanche, visage de loup, oreilles couleur paille brûlée,
  robe de soie (V2, chap. « Un Résultat ») ; ill. en couleur : cheveux bruns, chapeau à marguerite,
  ombrelle, robe turquoise (ill. V2 image3). Polie, droite, naïve, fière de sa ville ; vouvoie puis
  tutoie Willem ; dit « Mlle » aux fées (V2 ; V5). Gifle Willem (il lui a touché le ventre).

### 5.11 Le Grand Sage, Suowong Kandel [S2]

- Jadis petit thaumaturge blond aux yeux bleu clair, traits androgynes, cape blanche trop longue ;
  disciple favori de la Tour impériale des Sages, il se disait « Mage de l'Étoile Polaire » (V2,
  prologue ; ill. V4 image5). Aujourd'hui vieillard **colossal** et immortel, barbe et cheveux dorés,
  cape d'un blanc criard, une grande cavité à la place du cœur, sourire effrayant ; fondateur et
  protecteur de Regule Aire (V2, chap. « Les protecteurs du ciel d'azur » ; V5 ; ill. V2 image5).
  Bougon avec Willem, doux avec ses subordonnés ; tourné vers le long terme. [S2] fait naître les fées
  avec Ebon Candle ; [S5] le « vieil homme » qui rattrape les notes de Rhantolk et lui révèle l'origine
  des emnetwiht (V5, chap. « Les Fées de Collina di Luce »).

### 5.12 Elq Hrqstn [S2-S5]

- **La Visiteuse** : ennemie de l'Église, que les Braves vont attaquer [S0] ; enfant nommée Elq dans
  le rêve de Chtholly [S2] ; fillette de la glace sous Gomag [S3] ; la dernière des Visiteurs ; fille
  aux cheveux cramoisis qui appelle Willem « Willie », flanquée d'un poisson volant [S4].
- **Apparence** [S5] : fillette d'environ dix ans ; cheveux **roux** démesurément longs (rouges
  jusqu'au sol sur ill.), yeux cramoisis, corps froid, plaie béante au cœur (« cadavre vivant ») ;
  robe blanche à volants, pieds nus, éclat bleu lumineux sur la poitrine (ill. V5 image1) ; au marché,
  chapeau et long manteau mauve-gris (ill. V5 image3).
- **Caractère, parler** : enfantine mais veut passer pour adulte, emploie des mots de travers,
  déteste les carottes, adore le lait chaud au miel ; dit d'elle-même et des fées : elle est
  Chtholly sans être Chtholly (V5, chap. « Le jeune homme nommé Willem »).
- **Histoire** [S5] : tuée par Lillia avec Seniorious ; son âme, brisée à moitié par le Vrai Monde,
  donne les fées ; elle rêve leurs vies dans le monde du Chanteur ; rentre sur l'île n° 2 et refuse de
  quitter ce monde (V5).

### 5.13 Les Poteaux et l'île n° 2 [S2, S5]

- **Ebon Candle** (« Ebo ») : ancien Poteau vaincu par Willem, réduit à un énorme **crâne noir** aux
  orbites lumineuses, voix grave de vieillard, titres pompeux, presque sans pouvoir, émotif ; roule dans
  un chariot ou trône sur un coussin rouge dans un cadre de fer forgé ; appelle Willem « Brave de
  l'Humanité » (V2 ; V5 ; ill. V5 image4).
- **Kaya** : sa servante, semifère aux oreilles de chat (« demi-chat »), cheveux sombres, robe noire,
  tablier, coiffe à voile ; pousse le chariot (V2 ; V5 ; ill. V5 image4).
- **Carmine Lake** (« Carmy ») [S4-S5] : Poteau du vent et de la pluie ; grand poisson volant
  vermillon et blanc, à demi transparent, voix rauque de femme mûre, bavarde et théâtrale, soucieuse de
  beauté ; sans corps depuis cinq siècles (V4, chap. « La fille aux cheveux cramoisis (II) » ; V5).
- **Jade Nail** (« Jay ») : troisième Poteau, a tué Suowong et Emissa ; absent (V2 ; V5).

### 5.14 Le passé : l'orphelinat et les Braves [S1-S5]

- **Almaria Duffner** (« Al », « Allie ») [S0-S1, S4] : la « fille » de Willem sans lien de sang, aînée de
  l'orphelinat ; un peu plus petite que lui ; longs cheveux châtain foncé en longue tresse à ruban
  blanc, yeux bruns ; col marin blanc noué d'un foulard, haut rose, chemise blanche, robe-tablier rouge
  brique (ill. V4 image1, image4 ; V1 image11). Énergique, maternelle, gronde et taquine, santé
  fragile, excellente cuisinière (sauf la viande) ; appelle Willem « Papa ». [S4] Elle est le Chanteur.
- **Lillia Asplay** [S2-S5] : princesse de Dione, **vingtième Legal Brave**, porteuse de Seniorious,
  cadette de Willem auprès du même maître ; niveau 77 (VEX). Cheveux **cramoisis** en queue haute, yeux
  rouge-brun ; cuirasse blanche, cape rouge et or, sabre ; manteau rouge à liserés dorés (ill. V4
  image5 ; VEX image1). Moqueuse, gourmande, lucide, déteste les prêtres ; traite Willem d'« idiot »,
  appelle l'empereur « papy » ; l'aime et le déteste ; se bat pour qu'il ne devienne jamais Legal
  Brave. [S5] Tue Elq en mourant.
- **Nils D. Foreigner** (Nils Didek) [S1-S5] : le maître de Willem et de Lillia, ancien Legal Brave
  (18e), fondateur de l'orphelinat ; ivrogne génial, vantard, part sans payer ; homme mûr, cheveux en
  bataille, barbe de trois jours, manteau à boucles (ill. V5 image7). [S3] chef du Vrai Monde ; [S5]
  Visiteur d'un autre monde ; endort Willem, puis quitte ce monde.
- **Les sept** [S4] : Willem (« Le maître sans talent »), Lillia, **Suowong Kandel**, **Navrutri
  Teigozak** (Quasi Brave de Garmando Ouest, la trentaine, longs cheveux roux, bouc, turban, robe
  blanche ouverte, bracelets, dague courbe ; Carillon Lapidemsibilus ; séducteur, appelle Willem
  « Will » ; [S4] membre du Vrai Monde, meurt sous Gomag), **Emissa Hodwin** (boucles argent-lavande,
  béret à plume orange, explosions de venenum, niveau 61), **Hilgram Moto** (chauve, combat à mains
  nues, niveau 58), **Kaya Kaltran** (armure, grande épée, niveau 39, mère d'un petit garçon) (V4, chap.
  « Les sept du passé » ; ill. V4 image5 ; VEX).
- **Gomag du rêve** [S4] : **Ted** (Theodore Brickroad, aventurier de niveau 8 aux cheveux argentés,
  amoureux d'Almaria), **Luzie** (aventurière en armure de cuir rouge, terrifiée par les fantômes),
  le peintre Odle N. Gracis, les orphelins Falco, Nanette, Wendel, Maurice, Mineh, Detrov, Horace
  (V4).

### 5.15 Autres personnages

| Nom | Description | Niv. | Sources |
| --- | --- | --- | --- |
| **Le Docteur** | Médecin cyclope géant, chauve, crocs, lunettes noires, voix douce ; ajuste les fées | S2 | V2, chap. « Villes et peuples anciens » |
| **Baroni Makish** | Homme-lapin, longues oreilles et cheveux blancs (queue de cheval), lunettes noires puis rondes, uniforme croisé ; commandant de la police militaire, poli et calculateur | S2 ; S5 | V2 ; V5, chap. « Réunion secrète » ; ill. V5 image11 |
| **Commandant gremian** | Haut comme la taille de Willem, peau violette, crâne chauve, épaules couvertes d'insignes ; vaniteux | S3 | V3, chap. « L'île N°49 » |
| **Astartos** | Troll aubergiste, la cinquantaine mais sans âge visible, hospitalier et sage ; a une fille adulte qui s'occupe d'enfants sur une autre île | S5 | V5, chap. « L'Homme sans passé » ; « Le jeune homme nommé Willem » |
| **Ramikeldi Limashenka** (« M. Rami ») | Homme-chat d'âge mûr, chemise blanche, gilet rouge foncé, chapeau, yeux ambrés ; marchand de tabac sur l'île n° 13, revenu sur l'île n° 68 après vingt ans | SEX/S1 | VEX, chap. « L'homme-chat » |
| **Serveur homme-chat** | Tablier, canines visibles, jus de fruits offerts | SEX/S1 | VEX, chap. « Cinq cents ans » |
| **Lycanthrope du snack-bar** | Jeune, visage canin à fourrure châtaine, poêle à frire | S1 | V1, chap. « Directeur en carton » |
| **L'empereur** ; **Princesse** ; **Avgran T. Lontis** | Empereur théâtral et bienveillant ; sa nièce de 19 ans ; Quasi Brave porteur de Purgatorio, mort à Narvant | SEX/S2 | VEX |

## 6. Bestiaire

### 6.1 Les Dix-Sept Bêtes

- [S0] Il y a 527 ans, dix-sept « irrationalités » de formes différentes surgissent d'un château au
  centre de l'Empire Sacré. Deux pays disparaissent en quelques jours ; en moins d'un an, les
  emnetwiht, puis les elfes, les morians et les dragons ont péri (V1, chap. « Le chat qui filait et la
  jeune fille »).
- [S1] **Aucune ne vole** : c'est pourquoi le ciel reste un refuge. Chacune est d'une espèce
  différente ; leur « chant » ne parvient qu'à leurs semblables (V1, chap. « Les valeureux et leurs
  successeurs » ; épilogue).
- [S3] Elles ne cherchent pas à survivre : elles tuent ce qui vit, ou ce qui bouge (V3, chap. « Les
  jours gris au sommet du gris »). Les armes à feu ne les tuent pas ; seuls les Carillons et un
  venenum puissant y parviennent (V2 ; V5).
- [S5] Elles ne mangent pas, ne s'attaquent pas entre elles, veulent effacer ce qui est étranger et
  rendre au monde sa « mer grise » (V5, chap. « Les Fées de Collina di Luce »).
- **Origine** : légendes [S0], Vrai Monde [S2], emnetwiht transformés [S3-S4], bêtes primitives
  libérées [S5] : voir §3.6.

### 6.2 Les Bêtes connues

| N° | Nom | Apparence | Comportement, capacités | Parades | Niv. | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | **Le Chanteur**, la Première Bête « qui se lamente sur la Lune » | Pilier de cristal faiblement lumineux couvert de visages qui chantent, portant à mi-hauteur, en figure de proue, le buste de cristal d'une fille | Chant sans voix que nul ne peut entendre ; nostalgie qui paralyse puis transforme ; enferme des milliers d'esprits dans un rêve ; tout ce qui l'approche redevient sable ; affole le venenum des fées | Aucune connue ; détruit par Willem avec Lapidemsibilus reforgé, son essence cherche ensuite un hôte | S1 (existence) ; S4 | V1, épilogue ; V4, prologue ; chap. « Avant la fin du monde -C » |
| 2 | **Aurora**, « celle qui perce » (var. Aurore) | Corps tendu comme un fil, immense serpent sans tête ni queue, couvert d'épines ou de longs poils brillants, souples comme des cils ou raides comme des lances | La plus fréquente et la plus faible : une victime à la fois. Au repos, groupes d'une dizaine dressés au soleil, aiguilles rabattues ; en attaque, rampe très vite, s'agrippe aux chevilles, ses poils deviennent des milliers d'aiguilles qui percent l'acier ; ses mordus se transforment | À trois, un ou deux survivent ; marteau imprégné de venenum | S4 | V4, chap. « La nuit de la fin… » ; V5, chap. « Ce qui fut un jour Nephren » ; « Les qualités d'un Brave » |
| 3 | **Trois** | — | A dévoré une équipe de récupérateurs | — | S0 | V1, chap. « L'Homme sans Marque » |
| 4 | **Legitimitate**, « celle qui se Tord et Engloutit » | Silhouette vaguement humaine grande comme un manoir, carapace brun rougeâtre, des milliers d'yeux dans les jointures | Surgit après une tempête de sable ; chasse au son et au mouvement ; un revers coupe un homme en deux et tranche un dirigeable ; jamais deux dans le même secteur ; menace « faible » | Se taire, s'immobiliser, s'éloigner très lentement ; tuée par Nopht et Rhantolk | S3 | V3, chap. « Les jours gris au sommet du gris » |
| 5, 11 | **Cinq**, **Onze** | — | Vues de loin par Glick | — | S3 | V3, chap. « Encore plus loin sous le ciel étoilé » |
| 6 | **Timere** | Voir 6.3 | Voir 6.3 | Voir 6.3 | S1 | — |
| 7 (?) | **Septième Bête** (supposée par Willem) | Crustacé gris façon crabe, dix pattes ou plus qui s'allongent et se rétractent, couvert de bave | Réputée résister à l'artillerie concentrée ; détruit couloirs et cloisons | Willem la pousse dans le vide : une Bête sans ailes ne revient pas | S3 | V3, chap. « L'horloge en lambeaux et désuète » |
| ? | **La Bête inconnue** | Cachée dans Timere | Indétectable par les capteurs, éclose à la 217e mort de Timere, insensible à l'artillerie | Tombée avec l'île n° 15 | S2 | V2, chap. « Le bon usage… » ; « Chasseur d'âmes — A » |
| — | **Willem-Bête** (« sous-espèce de Chanteur ») | Corps de Willem, œil droit doré | Réduit en poussière grise tout ce qu'ont créé les Visiteurs (réverbère, banc, armure) ; ne peut plus utiliser le venenum | Seniorious | S5 | V5, chap. « Les qualités d'un Brave » |

Les autres numéros (8 à 10, 12 à 17) ne sont ni nommés ni décrits dans les six volumes : à inventer
seulement en le signalant (original).

### 6.3 Timere, la Sixième Bête

**Le nom.** « Timere » nomme la Bête numéro Six (V1, chap. « Les valeureux et leurs successeurs »).
Le texte l'emploie aussi pour chacun de ses corps : « un Timere particulièrement grand », « les
Timere » (invariable, V2-V3), plus rarement « les Timeres » (V4-V5), et « un Six », « les Six » ;
deux fois « Timère ». Le pronom varie (« elle », la Bête ; « il », le monstre). Dans l'ancienne langue
emnetwiht, le mot désignerait un cœur craintif, rongé d'angoisse (V3, chap. « L'horloge en lambeaux
et désuète »). Recommandation : §11.

**Ce qu'elle est** :

- [S1] Une Bête dont le **corps principal reste à la surface** ; elle se déchire en millions de
  fragments que le vent emporte. Un fragment hissé par hasard sur une île grandit très vite et absorbe
  l'île en six à huit heures. C'est la seule menace des Dix-Sept Bêtes pour Regule Aire depuis des
  siècles (V1, chap. « Les valeureux… »).
- [S2] Elle grandit et se divise vite ; tuée, elle se sert de son propre cadavre comme bouclier
  (une **carapace**, une « enveloppe ») et renaît de ses entrailles encore vivantes, un peu plus forte
  et **sous une autre forme** à chaque fois (V2, chap. « De ce côté-ci de l'écran » ; « Chasseur
  d'âmes — A »).
- [S3] À la surface, les Timere sont des êtres **amorphes** qui forment des **nids** d'une dizaine
  dans des grottes vastes et humides, collés aux murs et aux plafonds, endormis comme des plantes ; un
  ou deux intrus ne les réveillent pas, un groupe nombreux, si (V3, chap. « La Princesse souriante
  dans le cercueil de glace » ; « L'horloge en lambeaux et désuète »).

**Formes attestées** (à utiliser pour varier les ennemis) :

| Forme | Description | Niv. | Source |
| --- | --- | --- | --- |
| Masse à lianes | Masse verte qui se tord, d'où sortent d'innombrables lianes | S2 | V2, chap. « Chasseur d'âmes — A » |
| Géant de lierre | Être géant sans visage, fait de lierre noir enroulé sur lui-même | S2 | idem |
| Chrysalide | Corps mort fendu sur le dos, d'où sort la vie suivante | S2 | idem |
| Liquide | Substance liquéfiée qui jaillit de centaines de petits trous dans le sable | S3 | V3, chap. « L'horloge en lambeaux… » |
| Arbres | Silhouettes arborescentes qui étendent troncs et branches pour enserrer un navire | S3 | idem |
| Masse plaquée | Masse vert foncé collée aux vitres, qui pousse sur la coque | S3 | idem |
| Pattes et ressorts | Tentacules changés en pattes de crustacé épineux ; une moitié devient ressort pendant que l'autre bondit ; griffes et crocs | S3 | idem |
| Échelle | Corps empilés les uns sur les autres pour grimper | S3 | idem |

**Comportement** [S2-S3] : cri capable de déchirer une sphère de fer ; gerbes de lianes dont la
plupart sont des feintes (87 lianes, dont 65 qui tomberaient au sol sans danger) (V2). Les Timere
trouvent tout être vivant, même immobile, silencieux ou caché, mais **ignorent les machines**, même
bruyantes (V3). Ils ne volent pas : une fée en l'air garde l'avantage (V3).

**Arrivée dans le ciel** [S1, S5] : la **précognition tactique** (capteurs tactiques ; plus tard,
l'oracle des primas, réputé sûr à 100 %) détecte un fragment d'autant plus tôt qu'il est gros ; le
grand fragment de l'île n° 15 a été prédit six mois à l'avance (V1 ; V5, chap. « La fin du combat »).
Pour atteindre le ciel, il faut un corps assez grand pour se diviser, et seulement en très grand
nombre (V5, chap. « Les anciennes villes et les fées »).

**Comment on la tue** :

- seuls une **arme enchantée** ou un **Carillon** lui ôtent la vie ; l'artillerie sans venenum la
  brise et **suspend sa régénération**, ce qui donne du répit (V2, chap. « Chasseur d'âmes — A ») ;
- chaque corps se **divise juste avant de mourir** et rejette la mort sur une moitié, jusqu'à sa
  **limite de division** : dix au plus pour les petits corps, assez peu pour qu'une fée seule en
  vienne à bout (V3) ; il faut tuer chaque morceau au moins dix fois ; le corps de l'île n° 15 dépassait
  deux cents « couches » et a encaissé 217 morts (V2) ;
- **on se relaie** : fées et artillerie lézarde, sur des jours (plus de 120 heures à l'île n° 15)
  (V2) ;
- en dernier recours : une fée **ouvre les portes du village des fées** (V1), ou l'on **fait tomber
  l'île** (V2) ;
- sur un navire : combattre en vol, incliner le navire pour faire glisser les grappes, répandre de
  l'huile, vider la soute dans le vide ; le canon ne fait qu'intimider (V3, chap. « L'horloge en
  lambeaux… »).

**Repères chronologiques** : des siècles d'attaques repoussées (V1) ; île n° 96, deux ans avant le V1
(VEX) ; île n° 15 (V1-V2) ; Gomag, où Chtholly en anéantit jusqu'à ceux qui dormaient sous terre
(V3 ; V5) ; ensuite, plus aucune attaque prévue avant des années (V5, chap. « Les anciennes villes et
les fées »).

### 6.4 Autres créatures

- **Aujourd'hui, dans le ciel** [S0-S1] : ours et loups des forêts de l'île n° 68 ; chat noir voleur
  aux yeux verts ; crapaud, taureau, poules, pigeons (V1 ; ill. V1 image14).
- **Autrefois, à la surface** :
  - **elfes** (des ténèbres ; « esprits ancestraux » dans les rapports) : comme des arbres
    pourrissants et tordus, en essaims ; ils changent la terre en bois sombre empoisonné ; détruire
    l'essaim flétrit la forêt (VEX, chap. « Lillia Asplay » ; « Le Soleil Couchant ») [SEX/S2] ;
  - **orcs** (niveau moyen 5) : très féconds ; en horde, leurs émotions se propagent et ils ne
    craignent pas la mort (VEX) ; **fang-hares** : petits monstres de niveau 11 aux incisives qui
    déchirent le fer, en terriers (VEX) ;
  - **démons** (bufas, aeshma, immemoratio, mammon, succube) : enferment leur cible dans une **zone
    illusoire** tirée de son esprit ; on s'en échappe en restant attaché au réel et en brisant le noyau
    de l'illusion (VEX, chap. « La fleur se balance au sommet du pic ») ;
  - **dragons** (dragon violet, bébé dragon de rouille scellé près des sources de Fistirus),
    cocatrices, dryade géante, monstres modifiés par des malédictions, marionnettes de combat en
    acier, vampires (V1 ; V3 ; V4, chap. « Les sept du passé » ; VEX).
- **Armure d'Elpis** [S5] (non vivante) : colosse d'acier à marteau de guerre, heaume à fente en
  croix, assez vaste pour deux ou trois géants, alimenté par des fées captives rivées dedans, masques
  noirs ; point faible : les articulations (V5, chap. « Les qualités d'un Brave » ; ill. V5 image12).

## 7. Armes, magie et techniques

### 7.1 Les Carillons

- **Construction** [S0-S1] : épées hautes comme un homme, à deux mains, faites de **talismans** de
  métal de la taille d'un poing assemblés comme un puzzle et tenus par des **veines d'enchantement**
  autour d'un **cristal** central. Il en faut au moins 23 (V3). Leur lame paraît **fissurée** : chaque
  côté d'une fissure a une couleur différente (V1, chap. « Le chat qui filait… » ; « Entrepôt de
  fées » ; V3, chap. « Le béguin d'une fille et une femme amoureuse »).
- **Éveil** [S1] : on fait passer du venenum par la poignée ; une faible **lumière filtre par les
  fissures**, qui s'élargissent à mesure que la puissance monte (V1 ; V2 ; VEX).
- **Fonctionnement** [S1-S2] : ils transforment la magie en puissance et puisent dans la plus grande
  force parmi ceux qui touchent la lame ; ils « apprennent » ce qu'ils touchent et **gagnent en force
  face à un ennemi plus fort** (V1, chap. « Entrepôt de fées » ; V2, chap. « Chasseur d'âmes — A »).
- **Qui les manie** [S1] : autrefois les Braves ; aujourd'hui les fées, qui ressemblent assez aux
  emnetwiht pour tromper leur authentification. Les modèles inférieurs s'utilisent sans aptitude
  (V1 ; V4).
- **Réglage** [S1] : on peut ajuster résistances (poison, malédiction, confusion, vue de dragon) et
  **niveaux de tueuse** (« tueuse de dragons ») ; au réglage, les talismans se détachent, flottent
  autour du régleur comme des étoiles et tintent (V1, chap. « Le ciel étoilé sous le ciel étoilé » ;
  V3 ; V4). Personne ne sait plus en fabriquer ; seul Willem sait encore les régler (V1).
- **Valeur** : jusqu'à 8 millions de bradal (V1).

| Carillon | Porteur(s) | Traits | Niv. | Sources |
| --- | --- | --- | --- | --- |
| **Seniorious** | Nils (18e Legal Brave), Lillia (20e), Chtholly, Lakhesh | La plus ancienne (l'une des cinq plus anciennes lames sacrées) ; 41 talismans ; lame **blanc argenté**, vertueuse « lame blanche » fissurée, aussi longue que sa porteuse ; garde sombre et hérissée (ill.) ; tranche les Visiteurs, « Godslayer » : donne la mort même aux immortels ; ne frappe qu'un adversaire unique ; choisit des destins tragiques et n'obéit qu'à ceux qui ont renoncé à rentrer chez eux ; talismans dérisoires (§7.2) | S1-S5 | V1, chap. « Entrepôt de fées » ; « Le ciel étoilé… » ; V2 ; V4, chap. « La fille aux cheveux cramoisis (III) » ; V5, chap. « Les qualités d'un Brave » ; VEX |
| **Valgulious** | Ithea | — | S1 | V1 |
| **Insania** | Nephren (et une fée qui a survécu à trois morceaux de Six) | Grande et lourde ; sacrifiée par Willem en V3 | S1 ; S3 | V1 ; V3 |
| **Desperatio** | Nopht, puis Chtholly | 38 talismans ; « Kinslayer » faite pour tuer des emnetwiht, efficace sur les Bêtes ; perdue | S3 | V3, chap. « L'Emnetwith suspect » |
| **Historia** | Rhantolk | Rafales tranchantes | S3 | V3 ; V5 |
| **Ignareo** | Orco (morte), Tiat | Bas niveau ; son talent est de passer inaperçue | S3 | V3 ; V5 ; VEX |
| **Rosaureum** | Tuca (morte) | — | SEX/S1 | VEX |
| **Parchem** | la vie antérieure d'Ithea | — | S5 | V5, chap. « Faire face au passé » |
| **Lapidemsibilus** | Navrutri | Haut rang ; 35 talismans ; préserve le corps et l'esprit ; reforgé par Willem contre le Chanteur | S3-S4 | V3, chap. « L'île N°49 » ; V4 |
| **Percival** (var. Perceval), **Dindrane** | Willem (série), Nephren dans le rêve | Séries ; Dindrane, chef-d'œuvre de série de l'atelier impérial | S1 ; S4 | V1 ; V4 |
| **Locus Solus**, **Mulsum Aurea** | Quasi Braves d'autrefois | Revigoration musculaire ; défense de la Cité Brillante de Ristiel | S1 | V1, chap. « Entrepôt de fées » |
| **Purgatorio**, **Mournen**, **Zermelfior** | Avgran ; autres | Empêche les « pécheurs » de fuir puis reste inactif un mois ; prend trop de vies ; ronge son porteur | SEX/S2 | VEX |

### 7.2 Talismans

- Sorts gravés sur papier, céramique ou métal, rapportés de la surface et collectionnés par les riches
  (V1) ; autrefois fabriqués à partir du **Gray** tiré des labyrinthes (VEX).
- Grands talismans d'autrefois : **Dispersion**, **Protection du destin**, **Compréhension du
  Langage** (V1, chap. « Ce jour, il y a fort, fort longtemps » ; « Celui qui ne devrait pas être en
  vie »). Le pendentif de langage de Willem s'active d'une goutte de venenum et transmet les
  intentions, mais affaiblit la résistance mentale (V4, chap. « Les étrangers »).
- **Talismans dérisoires de Seniorious** [S1] : ne pas se brûler la langue, trouver le nord dans un
  lieu inconnu, éviter les cauchemars quand on est malade (Willem en détache un pour Collon), imiter un
  miaulement, ne pas se couper les ongles trop court, faire pile six fois sur dix (V1, chap. « Le ciel
  étoilé… » ; V3).

### 7.3 Le venenum

- [S0-S1] Force magique tirée de la vie qu'on **allume** dans le cœur comme un feu, lentement ; plus
  la vie est faible, plus il est fort ; la force vitale, selon la race, fixe la limite. Allumé, il
  aiguise les sens : les couleurs s'effacent, le temps ralentit (V1, chap. « Le chat qui filait… » ;
  « Entrepôt de fées » ; V3). Il donne des ailes aux fées, des sauts par-dessus les toits, la **Vue**.
- [S3] C'est un dérèglement volontaire de la force vitale, dont le cœur est le catalyseur (V3). Chez
  une fée, l'allumage est lent : l'enflammer en un instant devrait être impossible (Chtholly le fait
  pour sauver Almita, signe de l'empiètement) (V3, chap. « Des journées chaudes… »).
- [S5] La force d'une fée vient pour moitié du venenum, pour moitié du Carillon (V5).

### 7.4 Ce que les fées peuvent faire, et ce que ça leur coûte

| Pouvoir | Coût | Niv. | Sources |
| --- | --- | --- | --- |
| Allumer le venenum, voler, manier un Carillon | Le venenum brûle le corps ; l'abus provoque une **intoxication** (forte fièvre, arythmie) que Willem soigne par massage et points de pression | S1 | V1, chap. « Les valeureux… » ; V3 |
| Pousser le venenum à fond, longtemps | Accélère l'**empiètement** : la vie antérieure remonte (souvenirs d'une autre, yeux rouges, cheveux qui changent), la personnalité s'efface, puis le corps se dissipe ; rare et anormal avant vingt ans | S2-S3 | V2, chap. « Chasseur d'âmes — A » ; V3, chap. « La Fille sans visage » |
| **Ouvrir les portes du village des fées** | Surcharge volontaire du venenum : explosion qui creuse un cratère et ne laisse que le Carillon ; la fée meurt | S1 | V1, chap. « Entrepôt de fées » ; « Les valeureux… » |
| Ignorer la douleur | Elles rient de blessures graves ; leur vie compte peu à leurs propres yeux | S1 | V1, chap. « Entrepôt de fées » |

### 7.5 Techniques des Braves

- **Willem** (sans talent pour l'art de son maître, mais il « n'abandonne jamais ») : la Vue ;
  **Balayage du rossignol** et balayage rapide (pas aériens) ; techniques d'Hilgram (Baguette
  scintillante, Patte d'ours, Queue de renard, Coup d'aiguille, Tambour capricieux) ; pas de course des
  bardes de Garmando Ouest ; coup direct ; « festoiement draconique » ; soins par points de pression ;
  désarme d'un caillou ; ajustement des Carillons (V2 ; V3, chap. « L'Emnetwith suspect » ; V4, chap.
  « Les aventuriers » ; VEX). La **Grue de Gossamer** envoie Seniorious dans un marais (VEX, chap.
  « L'endroit où je veux retourner »).
- **Lillia** : « Perspicacité » ; dissoudre sa présence, « toucher le temps », coups paralysants,
  thaumaturgie (V4 ; VEX). **Navrutri** : Haze Step (pas de brume). **Emissa** : explosions de
  venenum. **Hilgram** : combat à mains nues.

### 7.6 Autres magies et armes

- **Thaumaturgie** (sceaux gravés sur parchemin ou tablette d'argile, imite les miracles de la
  création), **nécromancie**, **malédictions** (des « étiquettes » qui modifient la réalité),
  **incantations interdites** (Willem les a payées de son corps), magie de manipulation et
  pétrification, magie de transport ; la torture arcanique était proscrite par une charte
  internationale (V1 ; V2 ; V4 ; VEX).
- **Argent purificateur** : cendre qui noircit au contact des esprits (V3).
- **Armes ordinaires** : canons et artillerie lézarde, pistolets, sabres courbes de la police
  militaire, fusils à long canon, épées et bâtons de bois pour l'entraînement (V1 à V5 ; VEX).

## 8. Chronologie

Les dates relatives comptent à partir du présent du V1 (automne).

| Quand | Événement | Niv. | Sources |
| --- | --- | --- | --- |
| Temps mythiques | Les Visiteurs arrivent dans un monde peuplé des seules bêtes primitives, immortelles ; ils le façonnent à l'image de leur foyer perdu | S5 | V5, prologue ; chap. « Les Fées de Collina di Luce » |
| Temps mythiques | Les Poteaux créent les emnetwiht en pétrissant bêtes primitives et éclats d'âmes de Visiteurs | S5 | V5, idem |
| Âge des emnetwiht | Empire, Église de la Lumière Exaltée, Braves, Aventuriers ; Abel Melchera, premier Legal Brave, fonde Dione | S0 ; SEX/S2 | V1, chap. « Le chat qui filait… » ; VEX |
| ~97 ans avant la chute | Fondation du Vrai Monde, secte issue de l'Église | S4 | V4, chap. « La Première » |
| Enfance de Lillia | À 9 ans, Dione rasée par les elfes noirs ; à 10 ans, elle rencontre Willem | S1 ; SEX/S2 | V1, chap. « Entrepôt de fées » ; VEX, chap. « Lillia Asplay » |
| Il y a ~529 ans | Willem (14 ans) et ses six compagnons écrasent une armée de monstres modifiés | S4 | V4, chap. « Les sept du passé » |
| Un hiver | Lillia, vingtième Legal Brave : front nord, chute de Narvant, porte-bonheur de Willem | SEX/S2 | VEX |
| Il y a plus de 527 ans | Veille de l'assaut contre Elq Hrqstn : Willem promet à Almaria de revenir pour son anniversaire et son gâteau au beurre | S0 | V1, prologue |
| | Lillia et son maître la veille ; il veut sacrifier l'âme d'un Visiteur | S3 ; S5 | V3, prologue ; V5, prologue |
| La bataille | Suowong et Emissa tués par Jade Nail (Suowong se rend immortel) ; Willem vainc Ebon Candle au bout de trois jours et se pétrifie ; seuls Lillia et Navrutri reviennent | S1-S4 | V1, chap. « Ce jour, il y a fort, fort longtemps » ; V2 ; V4 |
| | Lillia, mourante, tue Elq avec Seniorious ; le Vrai Monde vole le corps, échoue à briser l'âme | S5 | V5, chap. « Le visiteur Elq Hrqstn » |
| Il y a 527 ans | Les Dix-Sept Bêtes surgissent au centre de l'Empire Sacré ; à Gomag, Almaria devient le Chanteur | S0 ; S4 | V1 ; V4 |
| Il y a 526 ans | Extinction des emnetwiht ; elfes, morians, dragons périssent | S0 | V1, chap. « Le chat qui filait… » |
| ~500 ans | Suowong mène les survivants vers le ciel depuis les Saints Pics de Fistirus et fonde Regule Aire | S2 | V2, chap. « Les protecteurs du ciel d'azur » |
| | Elq, prisonnière du monde du Chanteur, rêve la vie des fées ; Carmine Lake perd son corps | S5 | V5 |
| ~400 ans | Ebon Candle se réveille en crâne (cent ans après la fondation) ; Collina di Luce existe déjà | S2 | V2 |
| Siècles suivants | Attaques de Timere repoussées ; des îles tombent ; des fées s'autodétruisent pour les sauver | S1 ; S5 | V1 ; V5 |
| ~200 / ~50 ans | Le parjure de Collina di Luce ; prohibition des jeux (Puits de Souhait) | S2 | V2, chap. « Le mauvais usage… » |
| ~20 ans | La vie antérieure d'Ithea meurt (Parchem) ; M. Rami quitte l'île n° 68 | S5 ; SEX/S1 | V5 ; VEX |
| 10 ans | Collina di Luce prend un maire | S2 | V2 |
| 2 ans | Morts d'Orco, puis de Tuca sur l'île n° 96 ; empiètement d'Ithea | SEX/S1 ; S3 | VEX ; V3 |
| Printemps de l'an passé | Des récupérateurs trouvent Willem pétrifié au fond d'un lac gelé ; réveil, soins de Nygglatho ; dix-huit mois sur l'île n° 28 | S0-S1 | V1, chap. « L'Homme sans Marque » ; « Celui qui ne devrait pas être en vie » |
| 6 mois / l'été | Attaque de l'île n° 15 prédite, Chtholly désignée ; l'île n° 47 sombre | S1 ; S0 | V1 |
| **V1**, automne | Rencontre au Market Medley ; arrivée sur l'île n° 68 | S0 | V1 |
| | Environ deux semaines : dessert, ballon, salle des armes, archives, duel, promesse sur la colline ; départ des trois aînées au couchant ; Willem cuisine | S1 | V1 |
| (pendant le V1) | Entraînement au bâton, l'homme-chat, Seniorious au marais | SEX/S1 | VEX |
| **V2**, fin d'automne | Île n° 15 : plus de 120 heures de combat, 217e mort de Timere, Bête inconnue ; Chtholly fait tomber l'île | S2 | V2, chap. « Chasseur d'âmes — A » |
| | Voyage de Tiat, retrouvailles, affaire Phyr, Willem chez le Grand Sage et sur l'île n° 2 ; coma puis réveil de Chtholly | S2 | V2 |
| **V3**, hiver | Dix jours après : gâteau ; oublis, chute d'Almita ; le Saxifraga abattu ; île n° 49 ; Gomag ; assaut des Timere de 18 h 26 à 18 h 51 ; chutes de Nephren et Willem ; Chtholly s'éteint ; deux semaines de deuil | S3 | V3 |
| **V4** | Rêve de Gomag : Almaria, Navrutri, Ted ; la nuit de la fin ; le Chanteur détruit ; Willem devient Bête. Dans le réel : corps de Chtholly rapporté ; deuil à l'entrepôt | S4 | V4 |
| **V5**, fin d'hiver au printemps | Réveil de Nephren ; crash du Tomorrow Grasper No. 7 ; Willem amnésique chez Astartos ; plus d'attaque de Timere prévue ; réunion secrète ; Auroras au marché, armure d'Elpis ; Willem tué par Lakhesh ; Elq rentre sur l'île n° 2 ; Nils quitte ce monde | S5 | V5 |
| Printemps suivant (déduit) | Lakhesh polit Seniorious ; récits de Nygglatho | SEX | VEX, prologue ; intermède |
| Des années plus tard | Entrepôt délabré, règles assouplies ; Ithea en fauteuil ; Ryehl tombe d'un arbre sur un jeune homme : Willem revient, Nygglatho l'accueille | S5 | V5, épilogue |

## 9. Ton et écriture

### 9.1 L'atmosphère

- **Le quotidien au bord de la fin.** Cuisine, linge, ballon, lecture, chahut, thé : la douceur des
  jours ordinaires, sur fond de mort annoncée et de deuil d'un monde perdu (V1 ; V2 ; V4). La guerre
  reste souvent hors champ ; quand elle arrive, elle est brève, brutale, sans gloire.
- **Mélancolie sans pathos.** Les drames passent par des gestes simples (tenir une main, ébouriffer
  des cheveux, offrir une tasse de lait, cuire un gâteau). Personne ne fait de grand discours.
- **Humour constant.** Avalanches de fillettes, menaces cannibales de Nygglatho, taquineries
  d'Ithea, sifflantes de Limeskin, malentendus amoureux, Willem en père jaloux, éternuements et
  moutarde (V1 ; V4 ; VEX).
- **Un système cruel sans méchant.** Les fées sont des armes jetables, mais Garde, Orlandry et Grand
  Sage ont leurs raisons ; même la Bête la plus terrible a une histoire (V2 ; V4).
- **Espoir têtu.** Rentrer à la maison, être accueilli, tenir une promesse, choisir sa vie malgré le
  destin (VEX, intermède).

### 9.2 Ce qui rend l'œuvre reconnaissable

- **Motifs** : le **gâteau au beurre** promis ; **rentrer à la maison** et le « bienvenue à la
  maison » jamais échangé à temps ; la **broche** transmise ; la **chute d'en haut sur quelqu'un**
  (rencontre de Willem et Chtholly, rejouée par Ryehl) ; « dans cinq jours » ; les **cheveux** qui
  changent de couleur ; la **lumière dans les fissures** de Seniorious ; le **sable gris** ; les
  **étoiles** ; les horloges ; le couchant.
- **Structure** : des retours vers le passé (prologues « A », « B », « C » qui se répondent),
  plusieurs points de vue, des titres doubles poétiques (V1 à V5).
- **Les fées ne sont pas tristes en permanence** : elles rient, se chamaillent, mangent, lisent des
  romans d'amour, jusque dans les volumes les plus sombres (V1 ; V3 ; V5).

### 9.3 Écrire les personnages

Les exemples sont **originaux**, écrits pour montrer le registre ; ils ne citent pas le texte.

| Personnage | Registre et règles | Exemple original |
| --- | --- | --- |
| **Willem** | Familier, ironique, se dénigre ; tutoie les enfants, vouvoie ses supérieurs avec une politesse moqueuse ; esquive les sentiments par une plaisanterie, ne promet rien qu'il ne tiendra pas ; aucune tirade héroïque | « Je ne suis pas un héros. Je suis le type qui fait les gâteaux. Alors reviens en manger. » |
| **Chtholly** | Phrases courtes, fierté, ripostes sèches ; tutoie Willem, vouvoie Limeskin ; rougit, bafouille, nie ; ne dit jamais « je t'aime » en face | « Je ne m'inquiétais pas. Je… vérifiais seulement que tu n'avais rien cassé. Idiot. » |
| **Ithea** | Bavarde, moqueuse, « Nya-ha-ha » ; vouvoiement ironique (« Officier ») ; sérieuse d'un coup sous la blague | « Nya-ha-ha ! Officier, vous rougissez. Non ? Alors c'est le soleil. » |
| **Nephren** | Deux ou trois mots, « Mm. » ; logique, directe, aucun adjectif inutile ; tutoie | « Mm. Promets. » |
| **Nygglatho** | Douce, polie, maternelle, menace gourmande en souriant ; tutoie Willem (« être délicieux »), « mes filles » | « Si la vaisselle n'est pas faite avant le dîner, je mangerai la première venue. Nature, sans sauce. » |
| **Limeskin** | Vouvoie, siffle les « s » (écrire « sss » avec mesure, pas à chaque mot), métaphores guerrières ou de vent, ne ment jamais | « Le vent ssse lève, guerrier. Un vrai guerrier sssait quand rentrer. » |
| **Tiat** | Enthousiaste, veut être grande, admiration pour Chtholly | « Un jour, j'aurai une épée aussi grande que celle de mademoiselle Chtholly ! » |
| **Collon**, **Pannibal**, **Lakhesh** | Collon : cri, jeux de mots, ordres (« tonton ! ») ; Pannibal : pince-sans-rire, conseils violents ; Lakhesh : polie, « M. Willem », s'excuse ; souvent en chœur | Pannibal : « Si tu as peur du noir, frappe-le. » Lakhesh : « Pardon, pardon, je range tout de suite ! » |
| **Glick** | Rationnel, cru, chaleureux ; « mesdames » aux fées | « T'as encore ta tête d'enterrement. Assieds-toi, c'est moi qui paie. » |
| **Rhantolk** | Argumente, objecte, tirades défensives, précision | « Je ne doute pas de vous. Je doute de toutes les hypothèses, ce qui vous inclut. » |
| **Nopht** | Fonce, parle avant de penser, gourmande | « On cogne d'abord, Rhan expliquera après. » |
| **Elq** (S5) | Enfantine qui joue la grande, mots de travers | « Je suis très adulte. Je bois juste mon lait au miel pour la tradition. » |
| **Le Grand Sage** (S2) | Bougon, sec, vieux grand frère ; doux avec ses subordonnés | « Tu es en retard de cinq cents ans. Assieds-toi. » |
| **Phyr** (S2) | Formelle, droite, fière de sa ville, « Mlle » | « Permettez que je vous montre le véritable agneau enveloppé de Collina di Luce. » |

Règles générales : tutoiement entre proches ; aucune modernité trop marquée (pas d'anglicismes
techniques) ; peu de points d'exclamation hors des petites ; la tendresse passe par ce qu'on fait,
pas par ce qu'on dit ; les fées parlent de leur mort avec une légèreté qui doit gêner le joueur, pas
le séduire.

### 9.4 Sujets à traiter avec délicatesse

- **Des enfants utilisés comme armes**, qui s'autodétruisent (V1) : montrer l'étrangeté et la peine,
  ne jamais glorifier le sacrifice ni en faire une récompense de jeu.
- **La mort d'enfants** : les fées sont des âmes d'enfants morts (V1) ; le deuil (V3-V4) ; rester
  pudique, hors champ.
- **Romance** : Chtholly a 15 ans, Willem un corps de 18 ans ; dans l'œuvre, il la traite d'abord en
  enfant et refuse de l'épouser (V1), puis la demande en mariage (V3). Dans le jeu : sentiments
  implicites, aucun contenu sexualisé, **jamais** de fan-service sur les fées, surtout les petites.
- **Corps blessés** : le corps en ruine de Willem, le corps de Chtholly déchiré par son venenum (V4,
  prologue) : à évoquer, pas à montrer.
- **Idées noires** : Willem s'est demandé pourquoi il n'avait pas mis fin à ses jours à son réveil
  (V1, chap. « Même après la fin de cette guerre ») ; ne pas reprendre ce fil à la légère.
- **Rejet des sans traits** : discrimination de race (V1) ; à montrer comme une injustice.
- **Cannibalisme des trolls** : registre de blague chez Nygglatho ; pas de gore.
- **Spoilers** : les grandes révélations (nature des fées, des Bêtes, d'Almaria, d'Elq, fin de
  Chtholly et de Willem) ne doivent pas fuiter dans les textes des premières étapes (§1.2).

## 10. Audit du jeu actuel

État relevé le 7 octobre 2026 (README, PLAN sections 1 et 4, `data/`, zones, menu, crédits, et
`docs/ASSETS_3D.md` qui guide les visuels). Priorité : **A** = contredit le canon de façon visible,
à corriger d'abord ; **B** = à recadrer lors de la refonte ; **C** = détail.

| # | Élément du jeu | Fichier(s) | Problème | Correction (canon) ou recadrage | Prio. |
| --- | --- | --- | --- | --- | --- |
| 1 | Épée « **Seniolis** » | `README.md`, `PLAN.md` (§1, §5), `docs/ASSETS_3D.md`, `src/ui/credits.tscn`, `data/dialogues/blacksmith.json` (nœud `seniolis`), `tools/gen_branding.py` ; tests `tests/unit/test_credits.gd`, `test_dialogue_data.gd` qui attendent la chaîne | Le mot n'existe pas : la traduction écrit toujours **Seniorious** | Remplacer partout par *Seniorious* (et les deux tests dans le même commit) | A |
| 2 | Seniolis « grande épée bleu glacier » | `docs/ASSETS_3D.md` §1 et §4, planche `assets/characters/chtholly/chtholly.png` | Seniorious a une lame **blanc argenté** criblée de fissures ; aussi longue que sa porteuse ; garde sombre et hérissée (ill.) | Lame blanc argenté fissurée ; quand on charge, une faible lumière filtre par les fissures (la teinte de cette lumière est libre : bleutée = original) | B |
| 3 | « Les **Timeres** » comme une **espèce** à quatre **types** (Petit, Normal, Coureur, Grand) | `data/enemies/timere_*.tres` (`display_name`), `data/waves/dunes.json`, `PLAN.md` §4, `docs/ASSETS_3D.md` §5 | Timere est **une Bête**, la Sixième ; ses corps grandissent, se divisent, renaissent plus forts sous d'autres formes. Le pluriel « Timeres » est attesté (V4, V5), pas les « types » | Garder le pluriel pour les corps, mais présenter chaque ennemi comme un **corps de Timere** : « Fragment de Timere » (petit), « Timere » (normal), « Timere bondissant » (coureur : une moitié devient ressort et bondit, V3), « Timere à carapace » (grand : enveloppe, V2). Mécaniques canon à exploiter : division avant la mort, limite de division, régénération que l'artillerie suspend, formes à lianes, lierre noir, arbre (§6.3) | A |
| 4 | Île **entourée d'eau**, lagon, plage | `src/world/island.tscn` (nœud `Water`), `src/world/shaders/water.gdshader`, `src/world/terrain.gd`, `docs/ASSETS_3D.md` (palette « Eau du lagon », §7) | Regule Aire est un archipel **dans le ciel** : sous le bord des îles, une mer de nuages, puis la surface grise. Ni mer ni plage | Remplacer l'eau par une **mer de nuages** (shader de nuages), le rivage par une **falaise** au bord de l'île ; murs invisibles au bord du vide | A |
| 5 | Zone « **Plage aux coquillages** » (palmiers, parasols, ponton, bouée) | `src/world/zones/beach/beach.tscn`, props `palm`, `umbrella`, `pier`, `buoy` | Aucune plage dans le canon | En faire le **port de l'île** : bord plaqué de métal, quai d'amarrage de dirigeables (bras d'ancrage), panneau usé à flèches rouges « centre-ville / entrepôt n° 4 » (V1, chap. « L'Homme sans Marque ») ; parasols → étals ; palmiers → arbres de forêt | A |
| 6 | Objet « **Coquillage** » (« on entend la mer ») | `data/items/shell.tres` | Pas de mer | Le remplacer par un **talisman dérisoire** (anti-langue-brûlée, boussole, anti-cauchemar…, V1, chap. « Le ciel étoilé… ») ou un objet du quotidien de l'île n° 68 (original) | B |
| 7 | **Village** générique (place à puits, six maisons, haies, quatre portes) | `src/world/zones/village/village.tscn` (« Village »), HUD « Retour au village… » (`src/ui/hud.tscn`) | Le foyer du canon est l'**entrepôt des fées** dans sa clairière (bâtiment de bois à deux étages, terrain de jeux boueux, potager, linge sur le toit, grand arbre), avec un **village d'hommes-bêtes** et son café à côté (VEX) | Recentrer la zone sûre sur l'entrepôt et le village voisin ; « Retour à l'entrepôt… » ; on se réveille à l'**infirmerie**, soigné par Nygglatho | A |
| 8 | PNJ « **Forgeron** » (« on n'en forge plus des comme ça », forge, enclume) | `data/npcs/blacksmith.tres`, `data/dialogues/blacksmith.json`, skin `forgeron` | Personne ne sait plus forger un Carillon ; on les **règle** (V1) | Le rôle revient à **Willem** : il règle Seniorious et entraîne les fées au bâton (VEX, chap. « Chtholly Nota Seniorious ») ; ses conseils de combat deviennent un entraînement dans la clairière | A |
| 9 | PNJ « **Bibliothécaire** » (dame âgée, lunettes, robe violette) | `data/npcs/librarian.tres`, `data/dialogues/librarian.json`, skin `bibliothecaire` | Personnage générique | **Nephren** garde le silence de la salle de lecture (S1) ; **Rhantolk** pour les langues anciennes (S3) ; **Nygglatho** pour donner les tâches | B |
| 10 | PNJ « **Enfant** » (casquette rouge ; « mon frère dit… ») | `data/npcs/child.tres`, `data/dialogues/child.json`, skin `enfant` | Les fées n'ont pas de famille ; l'entrepôt n'a que des filles | Les **petites** : Collon (défi bruyant), Pannibal (pince-sans-rire), Lakhesh (polie), Tiat (admire Chtholly) | B |
| 11 | Quête « **Les pages envolées** » : les Timeres ont emporté cinq pages du « dernier tome » | `data/quests/pages.tres`, `data/dialogues/librarian.json`, `data/items/page_fragment.tres`, `drops` des `timere_*.tres` | Les Timere ne volent ni ne gardent d'objets : ils cherchent les vivants et ignorent les choses (V3) ; « dernier tome » est un clin d'œil hors du monde | Garder le titre, changer la cause : des feuilles **emportées par le vent** (comme les notes de Rhantolk, V5) ou des tomes de *Triade Passionnelle* / des rapports de la salle de stockage cachés par les petites (original) ; ramassées en forêt, pas lâchées par les Timere | A |
| 12 | Récompense « **marque-page porte-bonheur** » (trèfle, +1 cœur) | `data/items/bookmark.tres` | Neutre, mais un équivalent canon existe | Le **porte-bonheur** fait main par Willem, un animal laid façon chien (VEX, chap. « Ce qui est le plus important ») ; +1 cœur reste une convention de jeu | C |
| 13 | Zone « **Forêt des Timeres** » où ils rôdent en liberté | `src/world/zones/forest/forest.tscn`, `src/enemies/placements/forest.tscn` | Timere ne vit pas dans les forêts du ciel ; un fragment tombé sur une île est une alerte grave (il absorbe l'île en six à huit heures) | « Forêt de l'île n° 68 » (marais, mares cachées, grand arbre) ; les ennemis deviennent des **fragments arrivés par le vent**, annoncés par la précognition tactique, à abattre avant qu'ils grandissent | B |
| 14 | Zone « **Dunes au couchant** » et **arène à vagues** | `src/world/zones/dunes/dunes.tscn`, `src/enemies/arena.tscn`, `data/waves/dunes.json`, `PLAN.md` §4 | Pas de dunes dans le ciel ; à la surface, elles sont **grises** | Trois recadrages canon : (a) S0-S1 : **terrain d'entraînement** de l'entrepôt (score = entraînement) ; (b) S2 : **champ de bataille de l'île n° 15**, combats en relais ; (c) S3 : **ruines de Gomag au couchant**, assaut des Timere surgis du sable gris de 18 h 26 à 18 h 51 autour du Plantaginesta : dunes, couchant et vagues y sont canon (sable gris, pas doré) | B |
| 15 | Zone « **Colline du belvédère** » | `src/world/zones/hill/hill.tscn` | Compatible | La **colline des étoiles** de la promesse (V1) ; ou la **tour de débris** du Market Medley, vrai belvédère du canon | C |
| 16 | Skin de Chtholly : cheveux **bleus virant au rouge**, uniforme noir à liserés dorés | `assets/characters/chtholly/chtholly.png`, `docs/ASSETS_3D.md` §1 | Le rouge est l'**empiètement** (S3) : visuel spoiler dès l'écran titre | Skin de base aux cheveux **céruléens purs**, uniforme sombre de la Garde (bleu marine, boutons argentés) ou tenue de ville (chapeau, broche) ; garder le dégradé pour un skin tardif (S3) | B |
| 17 | Animation de mort de Chtholly (pétales roses, papillon bleu) | `assets/characters/chtholly/chtholly.png` | Une fée qui meurt se dissipe en **grains de lumière** (V4, prologue) | Grains de lumière ; les pétales restent un choix original acceptable | C |
| 18 | Planche des Timeres (masse vert sombre, long cou à gueule dentée, six pattes) | `assets/enemies/timere/timere.png`, `docs/ASSETS_3D.md` §5 | Compatible avec les formes du V3 (masse vert sombre, pattes de crustacé, griffes et crocs) | À garder comme une forme parmi d'autres ; ajouter les formes à lianes, lierre noir, arbre, liquide (§6.3) | C |
| 19 | Textes des **crédits** (« Seniolis », « les Timeres viennent de SukaSuka ») | `src/ui/credits.tscn` | Orthographe ; titre français absent | « Chtholly, son épée Seniorious et Timere, la Sixième Bête… » ; ajouter le titre de la traduction française (*Que faites-vous à la fin du monde ? Êtes-vous occupés ? Voulez-vous bien nous sauver ?*, traduction Yume Novel) | A |
| 20 | Pitch « village sûr et ses trois habitants… cinq pages du dernier tome » | `README.md`, `PLAN.md` §1 et §4 | Décrit le monde non canon | Réécrire après la refonte (direction narrative) | B |
| 21 | Sous-titre « **Chtholly – Bats-toi contre ton destin** » | `src/ui/main_menu.tscn`, `src/ui/loading.tscn`, `src/ui/credits.tscn` | Formule originale | À garder, marquée originale : elle répond au thème du destin et du choix (Seniorious choisit les destins tragiques ; « le destin ne fait que dresser le décor », VEX, intermède) | C |
| 22 | **Charge magique** et onde | `data/attacks/charge_wave.tres`, HUD « Charge », « Onde prête ! » | Abstraction de jeu | Recadrer comme **allumer le venenum** dans Seniorious (lumière des fissures) ; coût canon possible : fièvre d'intoxication si l'on abuse (original sur cette base) | C |
| 23 | Nom du jeu « **WordEnd** » | partout | La postface abrège l'œuvre en *WorldEnd* (VEX, postface) | Garder (jeu de mots assumé), mais ne pas écrire « WordEnd » pour parler de l'œuvre | C |
| 24 | Musique *Scarborough Fair* (prévue puis retirée) | `PLAN.md`, `assets/CREDITS.md`, crédits | Absente des six volumes (on l'associe à l'adaptation animée) | Ne pas la présenter comme canon | C |

## 11. Incertitudes

| Point | Ce que disent les sources | Recommandation |
| --- | --- | --- |
| **Timere** : singulier, pluriel, genre | « Timere » nomme la Bête n° 6 et chacun de ses corps ; pluriel invariable « les Timere » (V2-V3) ou « les Timeres » (V4-V5) ; « il » ou « elle » ; deux fois « Timère » | **Timere** pour la Bête (nom propre, sans article : « Timere attaque ») ; **les Timeres** pour plusieurs corps (attesté, déjà dans le jeu) ; « elle » pour la Bête, « il » pour un corps. Jamais « une espèce » ni « des types » |
| **Garde ailée** | « Garde Ailée » (V1-V2), « Garde ailée » (majoritaire, V3-V5), « Garde-Ailé » (coquille) | *Garde ailée* |
| **Orlandry** | « Alliance d'Orlandry » (V1), « Alliance des marchands d'Orlandry » (majoritaire), « Alliance Marchande d'Orlandry » (V3) ; « Compagnie Orlandry » jamais | *Alliance des marchands d'Orlandry*, abrégé *Orlandry* |
| **emnetwiht** | « Emnetwiht » en début de phrase ; « emnetwith », « Emnetwith » (titre de section du V3), « émetwiht » | *emnetwiht*, invariable ; citer le titre « L'Emnetwith suspect » tel quel |
| **fée / Leprechaun** | fée, Leprechaun, leprechaun, lutin, farfadet | *fée* dans les dialogues ; *Leprechaun* pour le terme officiel (rapports, Garde) |
| **venenum** | venenum (V1-V4), Venenum (V5), venin (V1) | *venenum*, minuscule |
| **Carillon / arme enchantée** | Carillon, arme enchantée, arme antique, armes creusées, lame sacrée : même objet | *Carillon* ; « arme enchantée » acceptable dans la bouche de la Garde |
| **sans traits** | sans traits, sans-traits, sans-marque, sans marque, sansmarques | *sans traits* ; « sans-marque » comme insulte possible |
| **Market Medley** | Market Medley, Marché Paumé, marché de Medley | *Market Medley* ; « Marché Paumé » comme surnom local |
| **Braves** | Legal Brave / Brave légal ; Quasi Brave / Quasi-Brave | *Legal Brave*, *Quasi Brave* |
| **aérogare** | aérogare, aire-port, aireport | *aérogare* |
| Noms à variantes | Aurora / Aurore ; Carmine Lake / Carmin Lake / « Carmy » ; Ebon Candle / « Ebo » ; Jade Nail / « Jay » ; Nils D. Foreigner / Nils Didek / Foreigner Nils ; Chtholly / Chtolly (coquille) ; Willem / Williem (coquille) | *Aurora*, *Carmine Lake*, *Ebon Candle*, *Jade Nail*, *Nils D. Foreigner* ; surnoms seulement en dialogue |
| **Titre de Willem** | sous-officier des Armes Enchantées (V1), officier en second, deuxième officier des enchantements, second officier militaire des armes enchantées | *sous-officier des Armes Enchantées* ; les fées disent « Officier » |
| **Chevaliers** | de l'Annihilation, de l'anéantissement, de la Destruction | *Chevaliers de l'Annihilation* |
| Île de Willem | Une fois « île n° 25 », partout ailleurs n° 28 (V1) | Île n° 28 |
| Prix d'un Carillon | « deux cents bradal au minimum », record de 8 millions (V1) | Probable coquille pour « deux cent mille » ; éviter le minimum |
| Âges | Nygglatho : environ 18 ans (V1), la vingtaine (V2-V3) ; elle dit Willem arrivé « depuis un mois » (V3) ; Lillia : va avoir 14 ans (VEX), « une vingtaine d'années ou un peu moins » (VEX, sans doute erreur), environ 16 ans à sa mort (V5) ; Willem : 15 ans quand Lillia en a 14 (VEX), 16 le dernier soir (V4) | Nygglatho : jeune femme sans âge (troll) ; Lillia : 14 à 16 ans selon l'époque ; Willem : 18 ans de corps au présent |
| Couleurs flottantes | Yeux de Chtholly « glacials », « océan », « céruléen profond » ; Ithea blé mûr, doré, « herbe flétrie », yeux bois délavé ou dorés ; Nephren gris, cendré (lilas sur ill.) ; Nygglatho rouge pâle, roux, rose ; uniforme de Willem noir (bleu nuit sur ill.), yeux noirs (gris ou bruns sur ill.) ; Rhantolk indigo (bleu lavande sur ill.) ; Nopht vermillon (rose-rouge sur ill.) ; Lakhesh pêche (orange sur ill.) ; Phyr fourrure blanche (cheveux bruns sur ill.) | Suivre le texte pour la teinte de base, l'illustration pour la nuance : voir les fiches §5 |
| Nombre de fées | Près de trente (V1), plus de trente (V2-V3), une vingtaine au réfectoire (V1) | Une trentaine ; cinq fées soldates adultes à l'époque du V1 |
| Seniorious | « la plus ancienne » des lames sacrées (V1-V2, V4) et « l'une des cinq plus anciennes » (V1) ; genre flottant (« le Seniorious », « couvert » et « composée ») | « La plus ancienne des épées sacrées » ; **féminin** (« l'épée », « elle »), plus naturel et accordé à « la lame » |
| Deux **Kaya** | Kaya, servante semifère d'Ebon Candle (V2, V5) ; Kaya Kaltran, aventurière des sept (V4, VEX) | Homonymes : ne pas les confondre |
| Bibliothèques | Bibliothèque du Grand Senato (V2) et Grande Bibliothèque Centrale (V5) | Peut-être la même ; si le jeu n'en montre qu'une, prendre la seconde |
| Fondateur de Regule Aire | Le Grand Sage selon le récit ; Ebon Candle selon Carmine Lake (V5) | Le Grand Sage, avec l'aide (secrète) d'Ebon Candle |
| Île n° 2 | Dite « lieu de commerce important » mais sans aucune ligne ni colonie (V2) | Lieu inaccessible ; ignorer le « commerce » |
| Bêtes non identifiées | La « Septième Bête » est une supposition de Willem ; la Bête cachée dans Timere à l'île n° 15 reste inconnue | Les présenter comme telles ; les numéros 8 à 10 et 12 à 17 sont libres (original signalé) |
| Ailes des fées | Le texte : ailes de lumière, immatérielles, colorées ; les visuels promotionnels de la traduction : ailes translucides d'insecte ou de papillon | Ailes de lumière aux couleurs de la fée ; une forme de papillon translucide est un choix de style acceptable |
| Elq et les fées | Les fées naissent seules en forêt (V1, V5) et sont faites par un rite sur une âme géante (V2) | Les deux sont vrais : le rite (S2) explique la naissance « naturelle » (S1), et l'âme est celle d'Elq (S5) |
| Fin ouverte | Retour de Willem inexpliqué, délai non chiffré ; Ryehl rappelle Chtholly sans confirmation (V5, épilogue) ; sort de Nephren après l'île n° 2 | Ne rien affirmer ; si le jeu y fait allusion, rester au niveau du clin d'œil |
| Structure | Titres de chapitres perdus à l'extraction, restitués par les sommaires ; « A », « B », « C » des prologues non expliqués | Citer les titres de section (§1.4) |

