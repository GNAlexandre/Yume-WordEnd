# Cahier des charges n° 7 : l'île n° 68, la profondeur et le mouvement

Ce document se donne à ChatGPT (ou à Codex), **lot par lot**, et se suffit à lui-même : il n'y a aucun autre
fichier à lire. Il est établi le 16 octobre 2026 d'après l'état du dépôt (`5acaa50`), après l'essai de
l'utilisateur dans le navigateur (« les décors, on dirait un vieux copié-collé », « aucune profondeur sur certains
passages », « catastrophique au niveau animation ») et deux audits mesurés : l'un sur le décor (6 cartes, 89 vues
posées une à une, 3 866 éléments posés comptés), l'autre sur l'animation (rafales d'images de la marche, de l'arrêt, du
demi-tour et de la course de Chtholly). Il commande **deux choses** :

- **le lot A, le décor** : mettre fin au copié-collé et donner de la profondeur. La **ville haute** d'abord (toutes ses
  images sont encore des remplaçants dessinés par les outils du jeu), puis le **village**, puis des **variantes de
  nature** pour les images que le jeu répète le plus, puis les images qui font la **profondeur** : premiers plans
  peints, lisières de second rang, bords de talus, taches de lumière ;
- **le lot B, le mouvement des personnages** : des planches de mouvement qui ajoutent des rangées aux planches
  existantes (un repos vivant, un départ, un arrêt, un demi-tour, une marche et une course dont le pas **colle à la
  vitesse du jeu**), pour Chtholly d'abord, puis Willem et les fées principales.

Ce que le dessin dit des lieux et des gens vient de l'œuvre (*SukaSuka*, traduction Yume Novel), d'après les dossiers
du canon (`docs/lore/canon/`), **paraphrasé** : le dépôt est public, on ne recopie jamais les volumes ; ce que l'œuvre
ne dit pas est marqué **(original)**. Les attitudes de repos des personnages (mains jointes, dos voûté, regard qui
fuit) sont **(original)** : l'œuvre n'en dit rien.

| Cahier | Fichier | État au 16 octobre 2026 |
| --- | --- | --- |
| n° 1 | `docs/ASSETS_HD2D.md` | livré |
| n° 2 | `docs/ASSETS_HD2D_MONDE.md` | livré |
| n° 3 | `docs/ASSETS_HD2D_SUKASUKA.md` | livré en partie ; le reste a été repris au n° 5, puis au n° 6 |
| n° 4 | `docs/ASSETS_HD2D_COMPLEMENTS.md` | livré en entier |
| compléments | `docs/ASSETS_HD2D_NAVIRES.md` | livré |
| n° 5 | `docs/ASSETS_HD2D_ILE68.md` | R0, R1 et R2 livrés ; le reste a été repris au n° 6 |
| n° 6 | `docs/ASSETS_HD2D_ILE68_LIVRAISON6.md` | en cours de livraison ; **38 de ses lignes sont reprises ici** (section 0.2) |
| **n° 7** | `docs/ASSETS_HD2D_ILE68_LIVRAISON7.md` | **ce document** |


## 0. Mode d'emploi

1. Lis la section 0.1 : **deux lots**, avec le nombre d'images de chacun, et la section 0.2 : ce que ce cahier
   **reprend** du n° 6 (ne commande jamais deux fois la même image).
2. Choisis un lot, puis **un groupe** de ce lot (A.1, A.2, …, B.1, …) : un groupe est une conversation.
3. Dans la conversation, **colle dans l'ordre** : le bloc de style (section 1) ; le rappel du format (section 2 pour des
   images, section 3 pour des planches de personnages) ; le tableau du groupe ; puis joins les images de « Références à
   joindre ».
4. Pour chaque ligne du tableau, demande : « Image `<chemin>`, `<taille>` px, `<genre et ancre>` : » suivi de la
   **consigne**, en rappelant la colonne **À ne pas faire**. Pour une planche : la formule de la section 3.1, puis la
   fiche 3.2 et les chiffres 3.3.
5. Vérifie chaque livraison avec la section 6 avant de la déposer ; ne livre que les fichiers de la liste.

### 0.1 Ce que ce cahier commande : deux lots

Les priorités (1, 2 ou 3) sont celles **de la liste** : 1 = sans cette image, la carte ou la scène se joue avec un défaut
que le joueur voit tout de suite (remplaçant, même image vingt fois, aucune profondeur, pieds qui glissent) ; 2 = la
densité et la vie du lieu ; 3 = le bonus.

| Lot | Section | Contenu | Images | Planches | Fichiers PNG | Prio 1 | Prio 2 | Prio 3 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **A** | 4 | le décor : ville haute, village, variantes de nature, profondeur (premiers plans, second rang, talus, lumière) | 89 | 0 | 89 | 38 images | 40 images | 11 images |
| **B** | 5 | le mouvement : une planche de mouvement par personnage, trois vues (150 images dessinées par vue, 450 en tout) | 0 | 10 | 30 | 1 planche (81 images) | 4 planches (189 images) | 5 planches (180 images) |
| **Total** | | | **89** | **10** (450 images dessinées) | **119** | | | |

Une **planche de mouvement** compte pour trois PNG et trois JSON (profil, face, dos) ; ses **images** sont les cases de
ses rangées (le détail est en 3.2). Les images comptées du lot A sont celles à **dessiner** : 37 sont encore des
remplaçants dessinés par les outils du jeu (le fichier livré les remplace au même nom), 52 sont nouvelles (dont une
image de nuit qui n'existe pas encore).

**Répartition du lot A par groupe**

| Groupe | Contenu | Images | Prio 1 | Prio 2 | Prio 3 | dont reprises du n° 6 |
| --- | --- | --- | --- | --- | --- | --- |
| A.1 | la ville haute : maisons, boutiques, pierre | 23 | 17 | 5 | 1 | 21 |
| A.2 | la ville haute : garde-corps, murets, clôtures, enseignes, toits | 16 | 6 | 10 | 0 | 10 |
| A.3 | le village : clôtures, torchis, maison de pierre, appentis | 9 | 2 | 5 | 2 | 7 |
| A.4 | variantes de nature : roseaux, haies, chênes, tas de feuilles, cailloux | 15 | 5 | 8 | 2 | 0 |
| A.5 | premiers plans peints | 10 | 4 | 5 | 1 | 0 |
| A.6 | lisières de second rang | 4 | 2 | 2 | 0 | 0 |
| A.7 | bords de talus : lèvres, angles, pieds | 9 | 2 | 3 | 4 | 0 |
| A.8 | taches de lumière de sous-bois | 3 | 0 | 2 | 1 | 0 |
| **Total** | | **89** | **38** | **40** | **11** | **38** |

**Ordre de commande conseillé.** (1) **A.1 et A.2 en priorité 1** : la ville haute est la carte où le joueur passe le plus de
temps au jour 3 et celle qui répète le plus (`town_railing` posé 41 fois, `town_wall_low` 27, `fence_wattle` 44, `town_house_c`
8 fois). (2) **B.1 (Chtholly)** en parallèle : c'est le personnage à l'écran dans chaque vue. (3) **A.4 et A.5 en priorité 1**
(roseaux, haies, chênes, feuillages de premier plan) : ils brisent le copié-collé des cartes de nature. (4) **A.6 et A.7**.
(5) Les priorités 2 puis 3 de chaque groupe, puis **B.2 à B.4** dans l'ordre : Willem, Ithea, Nephren, Tiat, Pannibal, Collon,
Lakhesh, Almita, Nygglatho.

### 0.2 Ce que ce cahier reprend du n° 6, et ce qu'il laisse

**Reprise.** Les lignes ci-dessous du n° 6 sont **annulées** : elles sont recopiées ici, mot pour mot (sauf `town_railing`,
`town_wall_low` et `fence_wattle`, redéfinies avec une règle de raccord commune à leurs variantes), avec une nouvelle
priorité. Ne les commande **que** dans ce cahier. Toutes sont encore des remplaçants (sauf l'image de nuit
`village_house_stone_night.png`, qui n'existe pas) : `python3 tools/hd2d_assets.py check` les connaît, la livraison les remplace au
même nom.

| Groupe du n° 6 | Lignes reprises | Ici |
| --- | --- | --- |
| A.4 (maisons et boutiques de la ville haute) | `wall_stone_town`, `shop_snack` et `_side`, `cafe_town` et `_side`, `town_house_a` à `town_house_f` et leurs flancs (12), `shop_accessories` et `_side`, `shop_apothecary` et `_side` : **21 lignes** | A.1 |
| A.5 (enseignes, murets, lointain) | `hanging_sign_pan`, `hanging_sign_cup`, `town_planter_stone`, `town_wall_fountain`, `town_doorsteps`, `town_cellar_hatch`, `town_wall_low`, `town_railing`, `town_roofs_a`, `town_roofs_b` : **10 lignes** | A.2 |
| C.5 (village) | `fence_wattle`, `wall_wattle_daub`, `village_house_stone`, `_side` et `_night`, `village_shed` et `_side` : **7 lignes** | A.3 |

Au total **38 lignes** reprises, dont 37 remplaçants. Aucune image du n° 6 n'est donc commandée deux fois.

**Changement de priorité sans reprise** (les lignes restent celles du n° 6, inchangées) : `town_house_g` et `town_house_h` avec leurs
flancs (n° 6, D.4, priorité 3) passent en **priorité 2** : le jeu n'a que six maisons de ville, et l'audit en compte huit identiques
(`town_house_c`) dans une même rue.

**Le reste des remplaçants** du dépôt (intérieurs du café et de la maison Limashenka, pluie, navire de la Garde, forêt profonde,
papillons, talisman) **reste au n° 6**, à sa priorité : ce cahier ne touche ni à ces images ni à leurs groupes.

### 0.3 Découper et joindre (règles de découpe)

1. **Une conversation par groupe** (A.1, A.2…), ou par moitié de groupe s'il dépasse une douzaine d'images : colle le bloc de
   style, le rappel, le tableau du groupe, joins les références.
2. **La priorité 1 d'abord**, dans chaque conversation, puis les priorités 2 et 3 ; ne passe jamais au groupe suivant avant la
   livraison vérifiée du groupe en cours (sauf accord de l'utilisateur).
3. **Un bâtiment = une façade, puis son flanc dans la même conversation**, en joignant la façade finie au flanc ; une image de
   nuit se commande **après** celle du jour, en joignant celle-ci.
4. **Une famille de variantes** (`town_railing`, `_b`, `_c` ; `fence_wattle`, `_b`, `_c` ; `bank_lip_a`, `_b`, `_c`…) se commande **dans
   une seule conversation**, la variante A d'abord, puis les autres en joignant la A finie : la règle de raccord de la ligne est
   la même pour toutes (un poteau coupé en deux, la hauteur d'un haut de mur, un profil de lèvre).
5. **Demande une image à la fois** quand elle est grande (lisières 1536 px, chênes, planches) ; ne laisse pas l'outil « améliorer »
   une image déjà livrée.
6. **Une planche de mouvement par conversation**, dans l'ordre : le **profil** d'abord ; la **face** puis le **dos** ensuite, en
   joignant le profil fini (« même personnage, même hauteur, mêmes rangées, mêmes nombres d'images, vu de face »).
7. **Une rangée à la fois** si la planche dérive : demande la rangée seule (marche d'abord), vérifie-la avec le tableau du pas
   (section 3.3), puis assemble les rangées dans l'ordre du tableau. Donne **toujours la hauteur debout en pixels** et rappelle-la à
   chaque correction.
8. **Fais dessiner sur un gabarit** : des cases de même taille (donnée à la ligne), une ligne de sol commune à toute la rangée,
   un trait à la hauteur debout, **un trait vertical à l'axe du bassin** (l'ancre) ; puis fais effacer le gabarit.
9. **Joins toujours les images déjà livrées** du même lieu ou du même personnage (même palette, mêmes contours).
10. **Après toute correction, repasse toute la vérification** : une vue redessinée pour un détail change souvent d'échelle ailleurs.

### 0.4 Ce que ce cahier ne commande pas

- tout ce qui est au n° 6 et que la section 0.2 ne reprend pas (intérieurs, pluie, navire, forêt profonde, faune, gens de la
  ville, planches de tenue, de geste et de bâton) ;
- le **mouvement des tenues** (`_home`, `_rain`, `_pajamas`, `_life`…) : les planches de mouvement sont dessinées dans la **tenue de
  base** ; le moteur décide s'il lui faut aussi celles des tenues (section 7) ;
- les effets que le jeu génère (`fx/shadow`, `fx/glow`, `fx/light_pool`, `fx/rain_drop`), l'ombre portée, le flou de profondeur et le
  vent des panneaux : le jeu s'en charge ;
- le mouvement des animaux et des Timeres ; les portraits ; la **marche des personnages de la foule** (fées génériques, hommes-bêtes) :
  leur planche garde sa marche d'aujourd'hui, qui colle à 1,3 m/s.

## 1. Bloc de style v7 (à coller au début de chaque conversation)

C'est le bloc v6 du cahier n° 6 (projection oblique des meubles, pointe d'arme au-dessus de la ligne des pieds, JSON sans clé
de suivi, rien de retouché ni de renommé, leçons des livraisons), auquel s'ajoutent les **leçons de l'audit du 16 octobre 2026** :
des variantes de silhouette, des raccords communs, de la profondeur dessinée, pas de pixel isolé qui scintille, un mouvement qui se
mesure.

```text

Tu produis des images pour WordEnd, un jeu d'action-aventure en « HD-2D » à la manière
d'Octopath Traveler : des personnages et des décors en pixel art posés dans de petits lieux en
relief, vus par une caméra fixe inclinée qui regarde le nord. Univers : l'île flottante n° 68 du
roman SukaSuka (traduction Yume Novel), une dalle de pierre au-dessus d'une mer de nuages,
presque entièrement couverte d'une forêt dense semée de marais. Au cœur de la forêt, dans une
clairière défrichée, un vieil entrepôt de bois délabré où vivent une trentaine de fées (des
fillettes de 7 à 15 ans aux cheveux de couleurs vives), la jeune troll qui les élève et le
jeune homme qui veille sur elles ; à quelques pas, un village campagnard d'hommes-bêtes
(hommes-chiens, hommes-chats, lézards, ours, oiseaux, grenouilles) ; plus loin, une petite ville
de maisons de pierre sur une pente douce, et un port au bord du vide où se posent des navires
volants à coque de métal, à rotors et à chaudière enchantée, sans aucun ballon. Saison : la fin
de l'automne, qui tourne à l'hiver.
Style obligatoire :
- pixel art net : 1 pixel de l'image = 1 pixel d'art, aucun flou, aucun anticrénelage vers le
  fond, aucun dégradé lisse de peinture numérique ; aplats et dégradés en paliers, tramage léger
  permis ; contours de 1 px d'une teinte sombre de la couleur voisine (jamais noir pur) ;
- échelle fixe : 96 pixels par mètre partout (une porte de 2,2 m mesure 211 px, une petite fée
  de 1,2 m mesure 115 px, un adulte de 1,75 m mesure 168 px) ; chaque objet a sa taille réelle ;
- modelé marqué, comme dans Octopath Traveler : volumes lisibles, lumière douce de jour venant de
  la gauche et d'un peu au-dessus, reflets chauds sur les arêtes éclairées, ombres propres
  froides (brun violacé), assombrissement au contact ; aucune ombre portée au sol (le jeu ajoute
  les ombres, l'heure, la nuit, la pluie et la lueur des lampes) ;
- projection des meubles, tables, lits, bancs et objets : **orthographique oblique à 32°**, comme la caméra du jeu, jamais en perspective conique : aucun point de fuite, les arêtes parallèles restent parallèles, les arêtes verticales restent
  verticales, le dessus d'un plateau est un rectangle ; une surface horizontale de profondeur p apparaît avec une hauteur de
  0,53 × p × 96 px, une face verticale de hauteur h avec 0,85 × h × 96 px ; un meuble qu'on peut voir de côté a une vue de face
  et une vue de flanc de même hauteur, de même échelle et de même matière ;
- matières crédibles et usées : bois patiné, fendu, rapiécé ; pierre ébréchée et moussue ; fer
  riveté rouillé aux joints ; tissu reprisé ; rien de neuf, rien de symétrique au pixel près ;
- palette naturelle, un peu désaturée et chaude : or, rouille, mousse, pierre claire, bois brun,
  laiton ; lumière des cristaux jaune pâle (#FFE6A6) ; ni blanc pur ni noir pur ;
- univers européen rustique : village de bois, de torchis et de chaume, ville de pierre,
  ardoise, tuiles, cuivre, fer riveté, mobilier de ferme et de vieille pension ; rien d'asiatique
  dans l'architecture ni le mobilier (ni torii, ni lanterne de papier, ni cerisier en fleurs, ni
  toit recourbé, ni cloison ou porte de papier, ni tatami, ni bambou) ; rien de moderne (ni
  plastique, ni ampoule, ni prise, ni robinet chromé, ni affichage) ; la lumière vient de
  cristaux, du feu et des fenêtres ;
- aucun texte, chiffre, logo ni signature : un écriteau, un menu, un livre, une carte ou un
  cadran porte des lignes grises, des traits ou de petits dessins, jamais de lettres ni de
  chiffres lisibles ;
- fond transparent (PNG RGBA, alpha 0 ou 255 seulement) pour tout ce qui n'est pas une tuile ;
  alpha continu seulement pour les images marquées « alpha doux » (vapeur, brume, pluie,
  lumière, nuages) ;
- respecte exactement le chemin du fichier, sa taille en pixels et son cadrage, et ne livre que
  les fichiers demandés ; ne retouche, ne « améliore » ni ne renomme aucune image déjà livrée ;
- un sprite ou un décalque qui flotte (centré) garde une marge transparente d'au moins 4 px tout
  autour ; un panneau touche le bord bas, jamais le haut ni les côtés sauf s'il se raccorde.
Personnages et animaux (planches de sprites) :
- proportions des sprites d'Octopath Traveler : deux têtes et demie à trois têtes de haut, jamais
  une grosse tête sur un corps minuscule ; le profil est tourné vers la droite ;
- la même échelle dans toute la planche : chaque image debout mesure la « hauteur debout »
  demandée, du sol sous les pieds au sommet de la tête (cheveux compris) ; le personnage ne
  grandit ni ne rapetisse quand il marche, court ou parle ;
- trois vues (profil, face, dos) à la même hauteur debout, avec exactement les mêmes animations
  et les mêmes nombres d'images ;
- une seule silhouette par case : jamais deux figures empilées, jamais de double fantôme ;
- un accessoire porté d'un seul côté (couette, tresse, arme, queue, sac) reste du même côté du
  corps dans toutes les images et les trois vues (de dos, il passe donc de l'autre côté de
  l'image) ;
- rien sous la ligne des pieds (ni pointe d'épée, ni queue, ni ombre) : une arme ou un bâton tenu vers le
  bas se raccourcit ou se relève pour que sa pointe touche la ligne du sol sans la dépasser ;
- le JSON d'une planche ne contient que les clés du format (version, echelle, planche, direction, format,
  animations) : aucune clé de suivi, aucun commentaire.
Leçons des livraisons précédentes (chaque ligne vient d'un défaut constaté ; elles valent pour tout
ce que tu dessines) :
- chaque fichier a la taille exacte demandée, au pixel près, en RGBA, alpha net (0 ou 255) sauf « alpha doux » ; si ton outil ne sait pas produire cette taille, livre plus grand et plus net, puis
  réduis au plus proche voisin, jamais lissé ; une bande animée est faite de n images de la taille
  demandée, côte à côte, sans marge ;
- dans une planche, toute image debout (marche, parle, porte, travaille, hanches) a exactement la
  hauteur debout de repos ; la course peut être plus basse, jamais plus haute ; les trois vues ont
  la même hauteur ; une planche complémentaire, de tenue ou de geste recopie la rangée repos de la
  planche existante au pixel près (c'est l'étalon : elle ne se redessine pas) ;
- quand une planche porte deux personnages dans un seul dessin (Willem qui porte quelqu'un), la
  hauteur debout est celle de Willem, des pieds au sommet de ses cheveux, pas celle de la personne
  portée ;
- la planche tient dans son JSON : les clés du format de l'easter egg, une ligne par image, et rien
  d'autre ; les ancres (le point au sol entre les deux pieds) ne glissent pas d'une image immobile à
  l'autre ;
- une image « de nuit » (`<nom>_night.png`) a exactement le même cadrage, la même taille et le même
  dessin que celle du jour ; seules la lumière et les couleurs changent ; les vitres allumées sont
  en aplat #FFE6A6 (à 6 près par canal), jamais orangées ; une fenêtre éteinte d'un bâtiment du jour
  est bleutée et sombre, avec un reflet clair ;
- un décalque de sol (traces, ornières, flaques, pas, pierres) n'a jamais de bout coupé net : il
  s'estompe, ou se raccorde à sa suite ; pas de contour noir, un contraste faible avec le sol ;
- un toit de chaume ressemble à du chaume : des rangées de bottes irrégulières, de la mousse par
  plaques inégales, jamais de rayures régulières ni de taches identiques répétées (on y a vu de la
  tôle) ;
- une pluie, un rideau de brume ou un faisceau de lumière est en alpha doux et se raccorde sur ses
  bords quand la ligne le dit ; une icône d'interface reste lisible réduite à 20 px, sans lettre ni
  chiffre ;
- les cotes d'usage de la ligne (passage d'une porte, hauteur d'une assise, hauteur d'un appui) sont
  des contraintes, pas des suggestions ; seulement le sujet demandé, rien autour (ni île, ni nuage,
  ni personnage ajouté) ;
- ne livre que les fichiers de la liste (PNG et JSON) : ni source, ni galerie, ni aperçu, ni outil,
  ni code, ni image non demandée ; ne retouche, n'« améliore » et ne renomme aucune image déjà
  livrée ; le nom du fichier est exactement celui de la ligne.
Leçons de l'audit du 16 octobre 2026 (décor et mouvement ; elles valent pour tout ce que tu dessines) :
- ce qui se répète se voit : une image posée vingt fois dans une rue doit avoir des variantes de
  **silhouette**, pas seulement de teinte ; deux variantes d'une même famille se reconnaissent (même
  matière, même palette, même lumière) mais ne se superposent pas : réduites à 40 px, on doit encore
  les distinguer ;
- une image qui se pose en rangée (garde-corps, muret, clôture, lèvre de talus, lisière) se raccorde
  sur ses bords gauche et droit **et** avec ses variantes : la règle de raccord est donnée à la ligne,
  et elle est la même dans toute la famille ;
- la profondeur se dessine : ce qui est près de la caméra est plus grand, plus sombre, plus simple et
  moins contrasté ; ce qui est loin est plus petit, plus bas et plus violacé ; un second plan n'a jamais
  plus de contraste que le premier ;
- le jeu réduit les personnages à l'écran : un pixel isolé et clair (étincelle, reflet d'1 px, brin de
  cheveu seul) scintille ; un reflet ou un contour isolé fait au moins 2 px de large, et le reflet d'une
  arme garde les mêmes pixels d'une image à l'autre quand la lame ne bouge pas ;
- un mouvement de personnage se mesure : le pas, le recul du pied d'appui et la hauteur de la tête sont
  donnés en pixels, et la planche est refusée si elle sort de la tolérance ;
- la référence de style est toujours celle des images et des planches jointes, jamais celle d'une autre
  œuvre ni d'un genre.
Pour chaque image, je te donnerai : son chemin, sa taille exacte, son genre, son ancrage et son
sujet.
```

**Couleurs de référence** (cahiers n° 1 et 2) : herbe `#87A35E`, herbe sèche `#AFA764` ;
feuillages or `#CC9446`, rouille `#A95A3A`, sapins `#3D5946` ; pierre claire `#C2B49F`, ombre
`#837667` ; bois clair `#A57C58`, foncé `#654D3C` ; plâtre crème `#EAE0CB` ; ardoise `#5E6C86`,
tuiles `#B65E4B` ; fer `#717B84`, laiton `#B4955E` ; eau du marais `#4A675F`, roseaux `#9C9563` ;
cristaux lumineux `#FFE6A6` ; rouge de la Garde ailée `#AE4A3E` ; nuages `#F4DCC6`, `#BBA3BF`,
`#82769C`. Ajoutées au cahier n° 5 : bleu nuit `#2E3552` (ciel et vitres de nuit), gris de pluie
`#7D7F86`, lin beige `#D9CBB0` (rideaux, draps), vert sauge `#8E9E82` (papier peint fané).

## 2. Rappel du format des images (à coller avec les groupes d'images)

Chaque ligne d'un tableau donne le **chemin complet** du fichier (`assets/…`), sa taille exacte, son genre et son ancre.

### 2.1 Les règles

| Règle | Valeur |
| --- | --- |
| Densité | **96 px par mètre** ; lointain (montagnes, nuages, ville au loin) : 48 px/m, précisé à la ligne |
| Format | PNG RGBA 8 bits ; tuiles, matières et ciels : opaques |
| Taille | exacte au pixel près ; si l'outil ne sait pas la produire, livre plus grand et plus net, puis `python3 tools/hd2d_assets.py fit <fichier>` (réduction au plus proche voisin) |
| Transparence | découpée (alpha 0 ou 255), sauf « alpha doux » annoncé (pluie, brume, lumière, nuages, flaques) |
| Ancre | **milieu du bord bas = point posé au sol** : l'objet touche le bord bas de l'image, centré ; exceptions dites à la ligne (ce qui vole : centré, marge de 4 px ; ce qui pend : ancre libre, accroché par le haut ; décalques : centre) |
| Angle de vue | tuiles, matières de sol et décalques : strictement de dessus ; murs, portes, fenêtres, façades et flancs : de face, sans perspective ; meubles, objets, personnages et animaux : de face, très légèrement plongeant, **en projection orthographique oblique** (section 2.3) |
| Orientation | personnages, animaux et navires tournés **vers la droite** (le jeu les retourne) ; tout le reste vu de face |
| Lumière | jour doux venant de la gauche ; le jeu fait le matin, le couchant, la nuit, la pluie et la lueur des lampes, sauf pour les ciels, les pluies, les vitres éclairées et les images « de nuit », qui disent leur heure |
| Qualité avant poids | ni compression avec perte, ni réduction de couleurs ; une image de plus de 1,5 Mo (3 Mo pour les grands navires, les lisières et les ciels) n'est souvent pas du pixel art net : vérifie-la |
| Livraison | seulement les fichiers listés, à leur chemin exact (section 6) |

### 2.2 Les genres d'images

| Genre | Cadrage | Exemple |
| --- | --- | --- |
| **Sol** (`tile`, `ground/`, `interior/floor_*`) | 384 × 384 (4 × 4 m), vue de dessus, opaque, **sans raccord sur les quatre bords**, sans objet ni ombre | `floor_stone_town.png` : colle-la à côté d'elle-même dans les deux sens : aucune couture |
| **Mur** (`interior/wall_*`) | 384 × 288 (4 m de long × 3 m de haut), de face, opaque, **sans raccord à gauche et à droite**, plinthe en bas et corniche en haut comprises, ni porte ni objet | `wall_stone_inside.png` |
| **Face de palier** (`cliff/`) | de face, opaque, sans raccord à gauche et à droite ; le haut de l'image est au niveau du palier supérieur, le bas à celui du palier inférieur | `bank_earth.png` : 384 × 96 |
| **Matière de volume** (`buildings/materials/`) | 192 × 192 (2 × 2 m), opaque, sans raccord, de face (murs) ou dans le sens de la pente (toits : rangées parallèles au bas de l'image) | `roof_thatch.png` |
| **Façade** (`buildings/<nom>.png`) | élévation de la face sud, sans perspective, fond transparent, mur collé aux bords gauche, droit et bas ; type `long` (faîtage parallèle à la façade) : l'image s'arrête à l'égout du toit, bordure du toit comprise (10 à 20 cm), et mesure largeur × hauteur du mur ; type `pignon` (faîtage qui part vers le fond) : l'image va jusqu'au faîtage avec le triangle du pignon, transparente de part et d'autre, et mesure largeur × faîte | `cafe_town.png` |
| **Flanc** (`buildings/<nom>_side.png`) | le mur est en élévation, le côté gauche de l'image à l'angle de la façade ; pignon (pour un bâtiment `long`) ou mur gouttereau (pour un `pignon`) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné (le jeu le plaque aussi sur le flanc ouest) ; l'avancée du toit ne descend jamais sous le haut du mur | `shop_snack_side.png` |
| **Panneau extérieur** (`props/<nom>.png`) | objet debout vu de face, légèrement plongeant, fond transparent, collé au bord bas et centré ; « sans raccord » : bords gauche et droit libres, il se pose en rangée | `signpost_port.png` |
| **Lisière / lointain** (`props/town_roofs_*`, `sky/…`) | pan de 16 m de large (1536 px), bords gauche et droit qui s'enchaînent, bas collé au sol ; lointain : à 48 px/m, adouci et violacé par la distance, raccord à gauche et à droite quand la ligne le dit | `town_roofs_a.png` |
| **Porte, fenêtre, élément de mur** (`interior/door_*`, `window_*`, `wallitem_*`) | à l'échelle, de face, collé contre le mur, ancre au milieu du bord bas ; une porte touche le sol, une fenêtre ou un élément de mur est posé à la hauteur donnée à la ligne | porte de 1,1 × 2,2 m = 106 × 211 px |
| **Meuble, objet** (`interior/props/<nom>.png`) | à l'échelle, de face, très légèrement plongeant, **projection oblique** ; un objet « posé sur un meuble » a son ancre sur le plateau | `snack_meal_tray.png` : 48 × 24 |
| **Décalque** (`decals/<nom>.png`) | vu strictement de dessus, fond transparent, **bord irrégulier et effiloché** qui se fond dans n'importe quel sol, ancre au centre ; un tapis a un **bord plein** voulu | `path_flagstones_a.png` |
| **Bande animée** (`anim/<nom>.png`) | n images côte à côte, chacune de la taille donnée, sans marge, boucle sans saut, seul ce qui bouge change ; la pluie et la lumière sont en alpha doux ; ce qui tourne (rotor) est centré dans chaque image | `mooring_arm_clamp.png` : 4 × 288 × 384 |
| **Ciel, mer de nuages** (`sky/`) | ciel : panorama équirectangulaire de 2048 × 1024, horizon à mi-hauteur, raccord gauche-droite, opaque ; mer de nuages : 1024 × 1024 vue de dessus, sans raccord sur les quatre bords ; nuage : à 48 px/m, alpha doux, centré, marge tout autour | `sky_overcast.png` |
| **Navire en volume** (`ships/`) | flanc `_side` (quille au bord bas, moyeux sans pales), pont `_deck` (de dessus, ancre au centre), poupe `_stern`, trois quarts `_34` (centré, marge) | `garde_transport_side.png` |
| **Icône d'interface** (`fx/sign_*.png`) | 64 × 64, fond transparent, alpha doux, centrée, le bas du dessin à 4 px du bord bas, remplit 80 % du carré | `sign_talk.png` |
| **Premier plan peint** (`props/fg_*`) | panneau de grande taille, collé au bord bas, **alpha doux sur le pourtour seulement** (6 à 10 px), dessin simplifié en grandes masses, plus sombre et moins contrasté que le plan moyen ; un bord peut être coupé net **quand la ligne le dit** (tronc hors cadre) | `fg_leaves_low_a.png` |
| **Lisière de second rang** (`props/treeline_back_*`) | pan de 16 m de large (1536 px) mais **plus bas** (6,5 m : 624 px), bords gauche et droit qui s'enchaînent, plus sombre et plus violacé que la lisière du premier rang, bas collé au sol | `treeline_back_a.png` |
| **Lèvre, angle et pied de talus** (`decals/bank_*`) | décalque vu strictement de dessus, bord irrégulier, alpha doux sur le bas ; une lèvre et un pied se raccordent sur eux-mêmes à gauche et à droite ; un angle (192 × 192) a ses deux bras au milieu de deux bords voisins ; le jeu les tourne par quarts de tour | `bank_lip_a.png` |
| **Tache de lumière de sous-bois** (`decals/sun_dapple_*`) | décalque vu de dessus, jaune pâle `#FFE6A6`, alpha doux (40 à 70 %), jamais d'ombre | `sun_dapple_b.png` |

### 2.3 Tailles et projection des meubles

**Calcul des tailles** : mètres × 96, arrondis au pixel (0,45 m = 43 px ; 1,25 m = 120 px ; 2,4 m = 230 px). Les
mètres entre parenthèses servent au dessinateur pour l'échelle des détails (une marche fait 17 cm, une poignée de
porte est à 1 m du sol, une chaise a son assise à 45 cm, une table son plateau à 75 cm, un lit son matelas à 50 cm).

**Projection** (tables, comptoirs, étagères, bancs, objets) : **orthographique oblique à 32°**, comme la caméra du jeu,
jamais en perspective conique : aucun point de fuite, les arêtes parallèles restent parallèles, les arêtes verticales
restent verticales, le dessus d'un plateau est un **rectangle**. Une surface horizontale de profondeur *p* apparaît avec
une hauteur de **0,53 × p × 96 px**, une face verticale de hauteur *h* avec **0,85 × h × 96 px** : une table de 0,75 m
de haut et 0,9 m de profondeur fait 46 px de plateau et 61 px de pieds, soit 107 px avec la tranche. Un meuble qu'on peut
voir de côté a une vue de face et une vue de flanc de même hauteur, de même échelle, de même matière.

## 3. Rappel du format des planches (à coller avec les groupes de personnages et d'animaux)

### 3.1 Le format

Les personnages sont des **planches de sprites** au format de l'easter egg, repris tel quel : une planche PNG et son
JSON **par vue**.

- `<id>.png` + `<id>.json` : le **profil**, tourné vers la droite (le jeu en fait la gauche en miroir) ;
  `<id>_front.png` + `.json` : la **face** (vers la caméra) ; `<id>_back.png` + `.json` : le **dos**. Les trois vues ont
  exactement les mêmes animations, nombres d'images, `ips`, `boucle`, `coup` et `onde`. **Les animaux n'ont que le
  profil** (`assets/fauna/<id>/<id>.png` + `.json`).
- Une **rangée par animation**, de haut en bas dans l'ordre du tableau de la planche ; les images d'une rangée de gauche
  à droite, séparées d'au moins 2 px transparents. Fond transparent, alpha 0 ou 255.
- Le JSON, **sans aucune autre clé** :

```json
{ "version": 1, "echelle": 1, "planche": [largeur, hauteur], "direction": "right",
  "format": "images: [x,y,width,height,anchor_x,anchor_y] in atlas pixels",
  "animations": {
    "repos":  { "ips": 2,  "boucle": true,  "images": [[x, y, l, h, ax, ay], [x, y, l, h, ax, ay]] },
    "course": { "ips": 14, "boucle": true,  "images": [ … 5 images … ] },
    "frappe": { "ips": 14, "boucle": false, "images": [ … 4 images … ], "coup": [2] } } }
```

- `ancre` (`ax`, `ay`) : le point au sol entre les deux pieds, en px depuis le coin haut gauche de l'image ; il ne bouge
  pas d'une image à l'autre quand le personnage ne se déplace pas. Les ancres se recalculent par
  `python3 tools/hd2d_sheets.py anchors <json> --write`.
- Les images sont **numérotées à partir de 0**, comme dans le JSON : `coup : [2]` désigne la troisième image de la rangée.
- **Hauteur debout** : la 1re image de `repos` mesure exactement la hauteur donnée en px, de l'ancre au sommet de la
  tête (cheveux compris). Toutes les images debout (`repos`, `marche`, `parle`, `porte`, `travaille`, `hanches`) gardent
  cette taille ; `course` peut être un peu plus basse (penchée), jamais plus haute ; les autres (saut, chute, assis,
  couché) dépassent ou descendent librement, à la même échelle.
- **Trois vues de même hauteur**, **une seule silhouette par case**, **accessoires du même côté** (de dos, ils passent
  de l'autre côté de l'image), **rien sous la ligne des pieds**.
- Ce qu'on tient (ballon, livre, plateau, panier, outil) est dessiné dans la main quand la consigne le dit ; le siège, le
  lit, l'arbre, la marmite ou la table ne le sont **jamais** : le jeu pose le personnage dessus ou devant.

**La seule sorte de planche de ce cahier : la planche de mouvement** (nom proposé : `<id>_motion`).

| Sorte | Nom | Ce qu'elle contient |
| --- | --- | --- |
| **De mouvement** (complémentaire) | `<id>_motion` | pour un personnage déjà livré qui garde sa tenue : sa 1re rangée est `repos`, **recopiée au pixel près** de la planche existante de la même vue (c'est l'étalon de taille, ne la redessine pas), puis seulement les rangées nouvelles de la fiche 3.2. La planche existante (`<id>`, `<id>_front`, `<id>_back`) **n'est pas touchée** : aucune de ses rangées n'est redessinée, déplacée ou renommée. |

Toutes les planches de mouvement ont leurs trois vues (`<id>_motion`, `<id>_motion_front`, `<id>_motion_back`) et leurs trois JSON,
dans `assets/characters/<dossier>/`, à côté de la planche du personnage. Les rangées **s'ajoutent** : le format de l'easter egg
(ancres par image, `coup`, `onde`) ne change pas, et il n'y a ici ni `coup` ni `onde`.

**La formule de la demande** : « Planches de sprites `assets/characters/<id>/<id>_motion.png` (profil tourné vers la droite),
`<id>_motion_front.png` (de face) et `<id>_motion_back.png` (de dos), avec leurs JSON, fond transparent, mêmes rangées et mêmes
nombres d'images dans les trois vues, une rangée par animation dans l'ordre du tableau, une seule silhouette par case, hauteur
debout **<n> px** dans toutes les images debout et les trois vues, **pas de marche et de course mesurés comme dans le tableau 3.3** : »
puis la ligne du tableau.

**Références à joindre** : les trois vues existantes du personnage ; pour les planches suivant la première, `chtholly_motion`
(trois vues) livrée et validée, pour le rythme et le niveau de détail des rangées.

### 3.2 La fiche des rangées de mouvement, image par image

Les nombres d'images et les cadences sont **proposés au lot AN du moteur** (section 7) et ne changent plus une fois la planche
livrée. `ips` : images par seconde. Les rangées se dessinent **sur place** : le personnage ne se déplace pas dans la case (le jeu le
déplace) ; l'ancre est le point au sol **sous le bassin**, et elle ne bouge pas de plus de 2 px d'une image à l'autre de la rangée.
Hauteur de la tête : **H** est la hauteur debout de la ligne de la planche ; aucune image ne dépasse H.

| Rangée | Images | ips | Boucle | Consigne commune (profil ; les vues de face et de dos au 3.4) |
| --- | --- | --- | --- | --- |
| `repos` | 2 | 2 | oui | **recopiée au pixel près** de la planche existante de la même vue : c'est l'étalon ; ne la redessine pas |
| `repos_vivant` | 6 (Chtholly, Willem) ou 5 (les autres) | 3 | oui | un repos qui **vit**, boucle de 2 s (6 images) ou 1,7 s (5 images) : image 0 = image 0 de `repos` **recopiée au pixel près** ; 1 **inspire** : épaules 1 px plus haut, cheveux et vêtement 1 px en retard ; 2 **sommet** : épaules +2 px, tête +1 px, le point le plus éloigné de la pose de repos ; 3 **expire** : retour par un autre chemin (cheveux 1 px en avance), le poids bascule d'une jambe à l'autre (un genou fléchit d'1 px), **les pieds ne bougent pas** ; 4 **clignement** : paupières closes, c'est la **seule** image aux yeux fermés ; 5 (6 images seulement) **regard** : la tête tournée d'1 à 2 px vers la caméra, les yeux ouverts, l'arme ou l'accessoire immobile. Deux images voisines diffèrent de 3 px au plus ; pieds, ancre, arme au sol et accessoire tenu **identiques au pixel près** d'une image à l'autre (hors épaules, tête, cheveux, vêtement). Elle remplace la « respiration » que le jeu simulait en étirant l'image de 2 % : cet étirement disparaît |
| `marche` | 8 | voir 3.3 | oui | (Chtholly et Willem seulement) un cycle de **marche rapide** à 8 phases, deux pas par cycle, décrit phase par phase au 3.3 : 0 contact, 1 appui, 2 passage, 3 élan, puis 4 à 7 pareil de l'autre pied ; bras opposés aux jambes ; la tête monte et descend de 4 px au plus et **jamais plus haut que H** ; l'ancre au bassin ; la dernière image se raccorde à la première sans saut |
| `course` | 6 | voir 3.3 | oui | (Chtholly et Willem seulement) un cycle de **course** à 6 phases, deux foulées par cycle, avec **un instant où les deux pieds quittent le sol** (images 2 et 5) ; buste penché de 8 à 12° vers l'avant ; la tête de H−6 à H−16 px, **jamais plus haute que H** ; chiffres au 3.3. (Elle remplace la course de 5 images, dont les deux foulées ne sont pas symétriques) |
| `depart` | 2 | 12 | non | de l'immobilité au premier pas : 0 **mise en mouvement** : le buste s'incline de 6° vers l'avant, le talon arrière se lève, le poids passe sur la jambe avant, l'arme et le bras partent légèrement en arrière, les cheveux restent en arrière ; 1 **premier pas** : le pied arrière décolle et se porte en avant, **à un détail près la pose de la dernière image de `marche`** (image 7) avec le buste un peu plus penché ; elle mène à l'image 0 de `marche` (contact) |
| `arret` | 2 | 12 | non | de la marche à l'immobilité : 0 **freinage** : pieds écartés comme à un contact de marche (image 0), buste incliné de 4 à 6° vers l'arrière, le poids sur le pied arrière, l'arme et les cheveux continuent vers l'avant d'1 à 2 px ; 1 **rassemblement** : les pieds se rapprochent à 20 px l'un de l'autre, genoux fléchis (H−4), le buste se redresse, les cheveux rattrapent ; elle mène à l'image 0 de `repos`. **La même rangée sert aussi après la course** : le freinage reste un petit recul de 6° au plus, sans glissade |
| `demi_tour` | 3 | 16 | non | un changement de sens sans glisser à rebours : **de profil** : 0 **dérapage** : comme `arret` 0 mais le buste plus incliné (8°), le pied avant planté devant le bassin (talon à +28 px), la tête qui commence à se tourner vers la caméra, l'arme part en avant par l'élan ; 1 **pivot** : **de trois quarts face** (le corps tourné de 45 à 60° vers la caméra, entre `<id>` et `<id>_front`), pieds écartés de 30 px **plantés**, la tête déjà tournée vers la **gauche de l'image** (le nouveau sens), cheveux en gerbe, l'arme et l'accessoire **dans la même main** (ils passent devant le corps) ; 2 **relance** : de profil, tournée **vers la droite** comme toute la planche (le jeu retourne l'image : elle regarde alors à gauche), buste penché de 6° vers l'avant, pose de `depart` 0. Le jeu retourne l'image entre le pivot et la relance : l'image 1, presque symétrique, cache le saut. Les images 0 et 2 sont **toutes deux tournées vers la droite** |

**Les rangées par jeu** (le tableau 5.2 dit lequel s'applique à chaque personnage) :

| Jeu | Rangées, dans cet ordre | Images dessinées par vue |
| --- | --- | --- |
| **complet** (Chtholly, Willem) | `repos` (copie), `repos_vivant` (6), `marche` (8), `course` (6), `depart` (2), `arret` (2), `demi_tour` (3) | 27 |
| **court** (les fées principales, Nygglatho) | `repos` (copie), `repos_vivant` (5), `depart` (2), `arret` (2), `demi_tour` (3) | 12 |

Pour le jeu **court**, `depart` mène à l'image 0 de la `marche` **de la planche existante** (jointe) et `arret` part de son contact ; leur pas
reste celui de leur planche d'aujourd'hui (leur marche n'est pas refaite : elle colle à 1,3 m/s).

### 3.3 Les chiffres du mouvement : le pas, le recul du pied, la cadence

**Le problème, mesuré.** Chtholly (1,5 m, 144 px) dessine aujourd'hui un pas d'environ 0,44 m (42 px entre les pieds au contact) ; son
cycle de marche (6 images à 10 ips) dure 0,6 s et couvre 0,88 m : une allure naturelle de **1,47 m/s**. Le jeu la fait marcher à 4 m/s
(les pieds glissent d'un facteur 2,7) et courir à 7 m/s pour une foulée d'environ 4,3 m/s (facteur 1,6). La décision du plan
(`docs/REFONTE.md`) : **marche à 3,0 à 3,2 m/s, course à 5,5 à 6 m/s, cadence ajustée au pas dessiné, aucun patinage**.

**Le calcul pour la marche** (vitesse de 3,1 m/s ; un cycle = deux pas ; `ips` = images ÷ durée du cycle) :

| Hypothèse | Pas | Cycle | Durée du cycle à 3,1 m/s | Images | ips nécessaires |
| --- | --- | --- | --- | --- | --- |
| pas dessiné aujourd'hui (Chtholly, 6 images) | 0,44 m | 0,88 m | 0,284 s | 6 | 21,1 |
| pas de 0,45 m, 8 images | 0,45 m | 0,90 m | 0,290 s | 8 | 27,6 |
| **pas de 0,70 m, 8 images (retenu)** | 0,70 m | 1,40 m | 0,452 s | 8 | 17,7 |
| pas de 0,80 m, 8 images | 0,80 m | 1,60 m | 0,516 s | 8 | 15,5 |

**Un pas de 0,45 m n'est pas cohérent avec 3,1 m/s** : il faudrait 8 images en 0,29 s, soit **27,6 ips** (une image dure 36 ms, deux
images d'écran), 6,9 pas par seconde : les jambes s'agiteraient, et aucune image ne se lirait. À 3,1 m/s, un personnage de 1,5 m
est à la limite de la marche et de la course (sa jambe mesure 0,75 m du bassin au sol) : il lui faut une foulée plus longue que celle d'aujourd'hui, sinon ses jambes s'agitent. On retient donc un
**pas de 0,70 m (0,47 fois la hauteur debout)** : un cycle de **1,40 m**, 8 images, **18 ips** (cycle de 0,444 s, 2,25 cycles par
seconde) donne **1,40 × 18 ÷ 8 = 3,15 m/s**. Le moteur règle la cadence finale de ± 3 % (17,5 à 18,3 ips pour 3,0 à 3,2 m/s) : **c'est le pas
dessiné qui compte, pas l'ips**. Le pas de 0,80 m, plus long, ferait une marche qui ressemble à un trot (jambes à 32° de la verticale).

**La course** : cycle de **2,0 m** (foulée de 1,0 m), **6 images**, **17 ips** donnent 2,0 × 17 ÷ 6 = **5,67 m/s** (5,5 à 6 m/s pour 16,5 à
18 ips).

**Les chiffres par personnage** (la hauteur debout H en mètres = px ÷ 96 ; le pas = 0,467 × H ; le cycle de course = 1,333 × H) :

| Personnage | H | Pas (contact à contact) | Cycle de marche | Marche : images, ips, vitesse | Avance du corps par image | Course : cycle, images, ips, vitesse | Avance du corps par image |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Chtholly | 144 px (1,5 m) | 0,70 m = 67 px | 1,40 m | 8 images, **18 ips**, 3,15 m/s | 17 px | 2,00 m, 6 images, **17 ips**, 5,67 m/s | 32 px |
| Willem | 168 px (1,75 m) | 0,82 m = 78 px | 1,63 m | 8 images, **15 ips**, 3,06 m/s | 20 px | 2,33 m, 6 images, **15 ips**, 5,83 m/s | 37 px |

L'avance du corps par image est **la quantité dont le pied d'appui recule dans l'image** : c'est elle qui supprime le patinage. Le jeu déplace
le personnage de 17 px par image à la marche (Chtholly), le pied posé doit donc **reculer de 17 px (± 3) d'une image à la suivante** tant qu'il touche le sol.

**Exception à la règle de hauteur du 3.1** : à la marche et à la course, la tête rebondit ; les hauteurs du sommet de la tête données dans les deux tableaux ci-dessous
l'emportent sur « toute image debout a la hauteur de `repos` » ; elles ne dépassent jamais H.

**La marche, phase par phase** (Chtholly ; pour Willem, multiplie **toutes les positions par 1,167**) : position horizontale des deux pieds par
rapport à l'axe du bassin, en px, positive vers l'avant (la droite de l'image) ; « sol » : le pied touche le sol ; « levé de n » : le talon ou la
semelle est à n px au-dessus de la ligne du sol. La hauteur du sommet de la tête est donnée par image. **Tolérance : ± 4 px.**

| Image | Phase | Pied A (celui qui est devant au contact 0) | Pied B | Sommet de la tête |
| --- | --- | --- | --- | --- |
| 0 | contact de A | +34, talon au sol | −34, sur la pointe (le talon se lève de 6) | H − 3 |
| 1 | appui de A | +17, sol | −26, levé de 10 | H − 5 |
| 2 | passage de A | 0, sol (genou d'appui à peine plié) | +4, levé de 14 (genou haut, sous le corps) | H − 1 |
| 3 | élan de B | −17, sol | +30, levé de 4 (jambe lancée en avant) | H − 2 |
| 4 | contact de B | −34, sur la pointe | +34, talon au sol | H − 3 |
| 5 | appui de B | −26, levé de 10 | +17, sol | H − 5 |
| 6 | passage de B | +4, levé de 14 | 0, sol | H − 1 |
| 7 | élan de A | +30, levé de 4 | −17, sol | H − 2 |

Le bras opposé à la jambe qui avance se lève de 8 à 10 px devant ; **le bras qui tient l'arme ne balance presque pas** (6 px au plus à la marche,
12 px à la course) et reste dans la même main. L'écart des deux pieds aux images de contact (0 et 4) est de **67 px (Chtholly) ou 78 px (Willem)**.

**La course, phase par phase** (Chtholly ; Willem × 1,167), même convention, **tolérance ± 6 px** :

| Image | Phase | Pied A | Pied B | Sommet de la tête |
| --- | --- | --- | --- | --- |
| 0 | contact de A | +40, sol | −40, levé de 40 (talon près de la fesse) | H − 14 |
| 1 | appui de A | +8, sol | 0, levé de 34 (genou haut devant) | H − 12 |
| 2 | **vol** (les deux pieds en l'air) | −24, levé de 6 (décollage) | +50, levé de 22 (jambe tendue) | H − 6 |
| 3 | contact de B | −40, levé de 40 | +40, sol | H − 14 |
| 4 | appui de B | 0, levé de 34 | +8, sol | H − 12 |
| 5 | **vol** (les deux pieds en l'air) | +50, levé de 22 | −24, levé de 6 | H − 6 |

Le pied d'appui recule de **32 px par image** (Chtholly) ou **37 px** (Willem) pendant les images de contact. Les cheveux, le manteau et la jupe
**montent pendant le vol et retombent après le contact**.

**Ce que le script de contrôle (6.3) vérifie** : le nombre d'images et les `ips` de chaque rangée, le pixel exact de `repos` et de
`repos_vivant` image 0, la hauteur debout, l'alpha net, les ancres, et les mêmes rangées dans les trois vues. **Il ne mesure pas le pas** : mesure-le
à la main sur l'aperçu `python3 tools/hd2d_sheets.py strip` (ligne du sol, axe de l'ancre) : l'écart des pieds aux images 0 et 4 et leur recul d'une
image à l'autre doivent tomber dans le tableau. La cadence finale (`ips`) peut encore bouger de ± 3 % sans toucher à l'image.

### 3.4 Les trois vues

Les trois vues ont **exactement les mêmes rangées, les mêmes nombres d'images et les mêmes `ips`**, et les **mêmes phases** (la même jambe est devant
aux mêmes images).

- **De face** (`_motion_front`, le personnage marche vers la caméra) et **de dos** (`_motion_back`) : le pas se lit par la **hauteur des pieds** et
  non par leur écart : le pied levé monte de 10 à 14 px, le pied d'appui reste **à la même place dans l'image** et ne recule pas ; le pied qui avance
  est 6 à 10 px plus bas dans l'image que celui qui recule (il est plus proche de la caméra) ; les genoux et les épaules se décalent de 2 à 3 px au
  rythme des pas ; la tête monte et descend comme de profil.
- **Les accessoires portés d'un seul côté** (épée, couette, bâton) restent du même côté du corps : **de dos, ils passent de l'autre côté de
  l'image**, comme dans la planche existante.
- **`demi_tour` de face et de dos** (inversion nord-sud) : 0 **freinage** vu de face (ou de dos), le buste incliné de 6° vers l'arrière ; 1 **pivot** : de
  trois quarts de profil, le corps tourné de 45 à 60° vers la droite de l'image ; 2 **relance** : de profil, tourné vers la droite, penché de 6° vers
  l'avant (pose de `depart` 0 du profil). Le jeu passe ensuite à l'autre vue.
- **`depart` et `arret`** de face et de dos : mêmes poses que de profil, vues de face ou de dos (le buste qui s'incline, les pieds qui se rassemblent).

## 4. Lot A : le décor, de la profondeur et la fin du copié-collé

**Total du lot A : 89 images** (37 sont encore des remplaçants, 52 sont nouvelles), dont 38 en priorité 1, 40 en priorité 2 et 11 en priorité 3.

**Pourquoi ce lot.** L'audit du 16 octobre 2026 a posé les 89 vues du jeu une à une (entrepôt, sentier, village, colline, port, ville haute)
et compté ce que chacune montre. Les défauts qu'il mesure, et ce que ce lot y répond :

- **Toutes les images propres à la ville haute sont encore des remplaçants** : les six maisons, le café, le snack-bar, l'apothicaire, le magasin d'accessoires, la pierre
  des façades, les murets, les garde-corps, les toits et les enseignes (groupes A.1 et A.2). La carte répète aussi les mêmes images : elle pose `fence_wattle` 44 fois (une
  clôture de **village**, en ville), `town_railing` 41 fois et `town_wall_low` 27 fois, dont 20 garde-corps identiques dans une seule vue (celle de la librairie, tous les
  2 m, retournés un sur deux) et 8 `town_house_c` identiques alignées aux bords. **Réponse** : trois variantes de garde-corps, de muret et de pierre de façade, deux
  clôtures de ville, les maisons dessinées d'abord (A.1, A.2).
- **Le village** répète `fence_wattle` (12 fois dans une seule vue) et garde six remplaçants (A.3).
- **Les mêmes images de nature, trop souvent** : quatre roseaux répétés 55 fois dans le champ du sentier, deux haies `thicket_a_fg` et `thicket_b_fg`
  posées tous les 2,2 m, **trois `oak_a` identiques côte à côte** à la lisière nord de l'entrepôt, `pebbles_a` et `pebbles_b` 14 fois chacun dans la cour,
  `leaves_rust_b` (8 fois) et `clover_patch` (6 fois) posés comme des tampons dans le champ. **Réponse** : A.4 (4 roseaux, 3 haies, 3 chênes autres que `oak_a`, 3 tas de feuilles, 2 cailloux).
- **Aucune profondeur** : sur 89 vues, 24 n'ont aucun premier plan et 47 en ont un ou moins ; au sud du joueur, le champ, la cour et l'aire du port sont des
  places plates sans rien de plus haut que 0,8 m ; le fond est un seul pan à raccord (`forest_wall`) ; les paliers sont des rectangles au liseré uniforme.
  **Réponse** : des premiers plans peints en plusieurs tailles (A.5), des lisières de second rang plus sombres et plus basses (A.6), des bords de talus
  irréguliers (A.7), des taches de lumière (A.8).

**Ce qui ne se dessine pas ici** : l'ombre au sol, l'occlusion au pied des murs, le flou de profondeur, le vent, la variation de teinte et d'échelle : le jeu les
ajoute ; **dessine chaque image en pleine lumière, sans ombre portée**, comme toujours.

**Les cartes qui attendent ces images** : `ville_haute` (`CARTE.md` 9.2 et 9.4), `village`, `sentier`, `entrepot`, `colline`, `port`.

### A.1 La ville haute : maisons, boutiques et pierre (jours 3 et suivants)

Les six maisons `town_house_a` à `f`, le café, le snack-bar, l'apothicaire, le magasin d'accessoires et la pierre de taille des façades : **tout est encore un remplaçant**. Les lignes sont celles du n° 6 (A.4), recopiées mot pour mot avec une priorité plus haute ; les **façades de la ville sont éteintes** (vitres bleutées sombres avec un reflet clair), les enseignes sont des objets peints, **jamais des mots**. Les deux variantes de pierre (`wall_stone_town_b`, `_c`) sont nouvelles : elles servent à ce que deux murs voisins ne soient pas le même calque.

**Références à joindre** : `assets/hd2d/buildings/house_narrow.png`, `house_timber_a.png`, `shop_bookshop.png`, `projection_hall.png`, `cafe.png`, `limashenka_house.png` (et leurs flancs `_side`), `assets/hd2d/buildings/materials/wall_stone_b.png`, `assets/hd2d/interior/wall_stone_inside.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/buildings/materials/wall_stone_town.png` | 192 × 192 | matière ; opaque, sans ancre | pierre de taille gris-beige appareillée en assises régulières, joints fins, quelques blocs plus clairs ou ébréchés (la ville) | un raccord visible ; des assises qui se répètent en damier ; des fenêtres ou des portes | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/shop_snack.png` | 480 × 336 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 3,5 m, faîte 6 m, profondeur 5 m ; matières `wall_stone_town`, `roof_tiles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | snack-bar : petite boutique de pierre au comptoir ouvert sur la rue sous un auvent de toile, plaque de cuisson derrière, trois tabourets hauts devant, enseigne en forme de poêle (V1) ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/shop_snack_side.png` | 480 × 576 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 3,5 m, faîte 6 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `shop_snack.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_tiles`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/cafe_town.png` | 672 × 384 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 4 m, faîte 6 m, profondeur 6 m ; matières `wall_stone_town`, `roof_slate_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le café habituel de la ville, au coin d'une rue : grandes fenêtres, porte vitrée, deux tables rondes dehors, enseigne en forme de tasse (V3 ; V5) ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/cafe_town_side.png` | 576 × 576 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 4 m, faîte 6 m, profondeur 6 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `cafe_town.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_slate_b`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_a.png` | 480 × 864 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 6 m, faîte 9 m, profondeur 6 m ; matières `wall_stone_town`, `roof_slate_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | haute maison de pierre de taille à trois niveaux, porte en haut de trois marches, fenêtres à volets bleu passé, corniche de pierre, socle nu de 0,5 m ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_a_side.png` | 576 × 576 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 6 m, profondeur 6 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `town_house_a.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_slate_b`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_b.png` | 768 × 576 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 6 m, faîte 8,5 m, profondeur 6 m ; matières `wall_stone_town`, `roof_tiles_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison bourgeoise à deux étages, rez-de-chaussée de boutique fermée par des volets de bois, balcon de fer forgé à l'étage, jardinières ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_b_side.png` | 576 × 816 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 6 m, faîte 8,5 m, profondeur 6 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `town_house_b.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_tiles_b`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_c.png` | 384 × 720 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 4,5 m, faîte 7,5 m, profondeur 5 m ; matières `wall_plaster`, `roof_tiles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison étroite : pierre au rez-de-chaussée, étage à colombages en encorbellement, porte bleue, une fenêtre par niveau ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_c_side.png` | 480 × 432 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 4,5 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `town_house_c.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_plaster`, `roof_tiles`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_d.png` | 576 × 432 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 4,5 m, faîte 7 m, profondeur 5 m ; matières `wall_stone_b`, `roof_slate` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison basse de pierre claire avec une porte cochère au milieu (arc de pierre sur un passage sombre), deux fenêtres de part et d'autre ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_d_side.png` | 480 × 672 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 4,5 m, faîte 7 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `town_house_d.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_b`, `roof_slate`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_e.png` | 576 × 960 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 7,5 m, faîte 10 m, profondeur 6 m ; matières `wall_stone_town`, `roof_slate_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | grande maison de quatre niveaux en haut de la pente, chaînages d'angle, lucarne dans le pignon, girouette en forme de poisson volant (original) ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_e_side.png` | 576 × 720 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 7,5 m, profondeur 6 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `town_house_e.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_slate_b`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_f.png` | 576 × 336 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 3,5 m, faîte 6 m, profondeur 5 m ; matières `wall_plaster_b`, `roof_tiles_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison d'un niveau à enduit ocre, porte entre deux fenêtres, un banc et des pots de géraniums ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 A.4, reprise |
| 1 | `assets/hd2d/buildings/town_house_f_side.png` | 480 × 576 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 3,5 m, faîte 6 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `town_house_f.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_plaster_b`, `roof_tiles_b`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 A.4, reprise |
| 2 | `assets/hd2d/buildings/shop_accessories.png` | 384 × 624 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 4 m, faîte 6,5 m, profondeur 5 m ; matières `wall_plaster`, `roof_tiles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | magasin d'accessoires : vitrine de chapeaux sur des têtes de bois, rubans et broches, auvent vert, enseigne en forme de chapeau ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 A.4, reprise |
| 2 | `assets/hd2d/buildings/shop_accessories_side.png` | 480 × 384 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 4 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `shop_accessories.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_plaster`, `roof_tiles`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 A.4, reprise |
| 2 | `assets/hd2d/buildings/shop_apothecary.png` | 384 × 624 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 4 m, faîte 6,5 m, profondeur 5 m ; matières `wall_stone_town`, `roof_slate` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | apothicaire : vitrine de bocaux de verre colorés, porte vitrée, enseigne en forme de mortier et de pilon ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 A.4, reprise |
| 2 | `assets/hd2d/buildings/shop_apothecary_side.png` | 480 × 384 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 4 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `shop_apothecary.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_slate`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 A.4, reprise |
| 2 | `assets/hd2d/buildings/materials/wall_stone_town_b.png` | 192 × 192 | matière ; opaque, sans ancre ; sans raccord visible sur les quatre bords | variante de `wall_stone_town.png` (jointe : même pierre, même palette, même lumière) : mêmes blocs gris-beige mais **assises plus hautes** (30 à 40 cm), joints un peu plus larges, quelques blocs noircis par la fumée des cheminées, une traînée de mousse verte et d'humidité sur le bas de l'image (le pied du mur) ; elle sert à casser la répétition d'une rue : deux murs voisins ne doivent pas se lire comme le même calque | un raccord visible sur un bord ; des assises qui se répètent en damier ; une copie de `wall_stone_town.png` éclaircie ou assombrie ; des fenêtres, des portes, une ombre portée ; de la mousse en taches rondes identiques | n° 7 |
| 3 | `assets/hd2d/buildings/materials/wall_stone_town_c.png` | 192 × 192 | matière ; opaque, sans ancre ; sans raccord visible sur les quatre bords | variante de `wall_stone_town.png` (jointe) : **moellons équarris**, plus petits et plus irréguliers que la pierre de taille, un enduit crème qui s'écaille par plaques inégales et laisse voir la pierre dessous, une fissure fine en escalier, quelques réparations de mortier plus clair ; c'est le mur des maisons modestes du bas de la ville | un raccord visible sur un bord ; des plaques d'enduit toutes de la même forme ; un enduit uniforme sans pierre dessous ; des fenêtres ou des portes ; un motif en brique | n° 7 |

### A.2 La ville haute : garde-corps, murets, clôtures, enseignes, toits

Les rangées au cordeau de la ville haute : **trois variantes** de garde-corps, de muret et (nouveau) deux clôtures de jardin **de ville** pour remplacer les clôtures de branches du village. **Règle de raccord commune à chaque famille** : un poteau coupé en deux sur chaque bord (garde-corps, clôtures), un haut de mur à la même hauteur sur chaque bord (murets) ; dessine **toute la famille dans une seule conversation**. Les huit autres lignes sont reprises du n° 6 (A.5).

**Références à joindre** : `assets/hd2d/props/edge_railing.png`, `edge_parapet.png`, `bench_stone.png`, `street_lamp_double.png`, `wall_lantern.png`, `window_box.png`, `flower_pots.png`, `fence_low.png`, `assets/hd2d/props/stone_steps.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/props/town_railing.png` | 192 × 96 (2 × 1 m) | panneau, **se raccorde sur lui-même à gauche et à droite**, et **s'enchaîne aussi avec `town_railing_b` et `town_railing_c`** ; ancre : milieu du bord bas ; REMPLACE le remplaçant du moteur (même nom, même taille) | garde-corps de fer forgé d'une terrasse, volutes simples, rouille ; **règle de raccord commune aux trois variantes** : un poteau de fer de 8 px de large, de teinte identique, coupé en deux dans le sens de la hauteur sur chaque bord (4 px à gauche, 4 px à droite), de la hauteur complète de l'image, de sorte que n'importe quelle suite de variantes forme une rangée continue ; entre les poteaux, des volets de fer rythmés à la main, **aucun motif ne se répète deux fois dans l'image** | des bords gauche et droit qui ne se raccordent pas ; un poteau plus large ou plus clair sur un bord que sur l'autre ; de l'acier moderne ; des motifs asiatiques ; une ombre portée ; un motif de volute copié-collé quatre fois | n° 6 A.5 |
| 1 | `assets/hd2d/props/town_railing_b.png` | 192 × 96 (2 × 1 m) | panneau, **se raccorde sur lui-même à gauche et à droite** et avec `town_railing.png` et `town_railing_c.png` ; ancre : milieu du bord bas | variante B de `town_railing.png` (jointe, même fer, même rouille, même règle de poteau coupé en deux de 8 px sur chaque bord) : **barreaux droits terminés en pointes de lance**, deux traverses, un barreau tordu et un barreau manquant, coulures de rouille sous les traverses | un poteau de bord différent de celui de `town_railing.png` ; des volutes (c'est la variante à barreaux) ; des pointes acérées de grille de prison ; des bords qui ne se raccordent pas ; de l'acier moderne | n° 7 |
| 1 | `assets/hd2d/props/town_wall_low.png` | 192 × 77 (2 × 0,8 m) | panneau, **se raccorde sur lui-même à gauche et à droite**, et **s'enchaîne aussi avec `town_wall_low_b` et `town_wall_low_c`** ; ancre : milieu du bord bas ; REMPLACE le remplaçant du moteur (même nom, même taille) | muret de pierre sèche à couronnement de dalles, mousse ; **règle de raccord commune aux trois variantes** : sur chaque bord, le haut du mur est à 70 px du bord bas, la dalle de couronnement est épaisse de 10 px et de la même teinte, et le parement est un lit de pierres plates ; entre les bords, la silhouette du haut monte jusqu'à 77 px et redescend, **la suite des pierres est irrégulière**, une pierre plus claire, une plaque de mousse | des bords gauche et droit qui ne se raccordent pas ; un haut de mur plat comme une règle ; un mur de briques ; un joint de ciment moderne ; une ombre portée | n° 6 A.5 |
| 1 | `assets/hd2d/props/town_wall_low_b.png` | 192 × 77 (2 × 0,8 m) | panneau, **se raccorde sur lui-même à gauche et à droite** et avec `town_wall_low.png` et `town_wall_low_c.png` ; ancre : milieu du bord bas | variante B de `town_wall_low.png` (jointe, mêmes cotes de raccord aux bords : haut à 70 px, couronnement de 10 px) : **muret enduit d'ocre écaillé**, couronné d'un chaperon de tuiles rondes (rouge passé), l'enduit tombé par plaques sur le bas laisse voir la pierre | des bords qui ne se raccordent pas ; un haut de mur différent aux bords ; des tuiles neuves ; un toit de pagode | n° 7 |
| 1 | `assets/hd2d/props/town_fence_a.png` | 192 × 106 (2 × 1,1 m) | panneau, **se raccorde sur lui-même à gauche et à droite** et avec `town_fence_b.png` ; ancre : milieu du bord bas | **clôture de jardin de la ville** (elle remplace les clôtures de branches tressées du village, que le jeu pose encore dans les rues de la ville par défaut) : lattes de bois grisé aux sommets pointus et inégaux, deux traverses, une latte manquante, un piquet de 8 px de large coupé en deux sur chaque bord (4 px de chaque côté) pour le raccord | des bords qui ne se raccordent pas ; des branches tressées (c'est la clôture du village) ; un piquet de bord différent de `town_fence_b.png` ; des lattes neuves et alignées au cordeau ; du plastique ; des pointes de lance en fer | n° 7 |
| 1 | `assets/hd2d/props/hanging_sign_pan.png` | 96 × 115 | panneau ; ancre : milieu du bord bas | enseigne en forme de poêle à frire | des lettres ou des mots ; une potence dessinée si la ligne n'en demande pas ; un fond | n° 6 A.5, reprise |
| 2 | `assets/hd2d/props/town_railing_c.png` | 192 × 96 (2 × 1 m) | panneau, **se raccorde sur lui-même à gauche et à droite** et avec `town_railing.png` et `town_railing_b.png` ; ancre : milieu du bord bas | variante C de `town_railing.png` (jointe, même règle de poteau coupé en deux de 8 px sur chaque bord) : **balustrade basse** : un soubassement de pierre grise de 20 cm, au-dessus des barres de fer en croisillons et une main courante de bois usé, un croisillon plié | un poteau de bord différent ; un soubassement qui ne se raccorde pas ; du bois neuf ; des croisillons en treillis de jardin moderne | n° 7 |
| 2 | `assets/hd2d/props/town_wall_low_c.png` | 192 × 77 (2 × 0,8 m) | panneau, **se raccorde sur lui-même à gauche et à droite** et avec `town_wall_low.png` et `town_wall_low_b.png` ; ancre : milieu du bord bas | variante C de `town_wall_low.png` (jointe, mêmes cotes de raccord aux bords) : **muret de pierres rondes de rivière**, plus bas au milieu où il s'est affaissé, lierre qui le recouvre par endroits, quelques feuilles d'automne prises dans les creux | des bords qui ne se raccordent pas ; un lierre vert vif de printemps (il est sombre, fin d'automne) ; des pierres taillées ; une ombre portée | n° 7 |
| 2 | `assets/hd2d/props/town_fence_b.png` | 192 × 106 (2 × 1,1 m) | panneau, **se raccorde sur lui-même à gauche et à droite** et avec `town_fence_a.png` ; ancre : milieu du bord bas | variante B de `town_fence_a.png` (jointe, même piquet de bord de 8 px coupé en deux) : **planches jointives** peintes d'un bleu passé (#5E6C86 éclairci) qui s'écaille et laisse voir le bois, piquets des poteaux plus hauts que les planches, une planche penchée | des bords qui ne se raccordent pas ; un bleu vif ; une peinture intacte ; un poteau de bord différent | n° 7 |
| 2 | `assets/hd2d/props/hanging_sign_cup.png` | 96 × 115 (1 × 1,2 m) | panneau (potence au mur, ancre au bas de la potence) | enseigne de fer pendue à une potence, découpée en tasse fumante | des lettres ou des mots ; de la fumée en alpha continu (la tasse fume en pixels nets) | n° 6 A.5, reprise |
| 2 | `assets/hd2d/props/town_planter_stone.png` | 154 × 77 (1,6 × 0,8 m) | panneau ; ancre : milieu du bord bas | bac de pierre fleuri d'asters et de bruyère | des fleurs d'été vives ; une ombre portée ; un sol dessiné | n° 6 A.5, reprise |
| 2 | `assets/hd2d/props/town_wall_fountain.png` | 115 × 154 (1,2 × 1,6 m) | panneau ; ancre : milieu du bord bas | fontaine murale : bec de cuivre vert-de-grisé, auge de pierre, une tasse de fer à une chaînette | de l'eau animée (c'est une image fixe) ; un robinet moderne ; une ombre portée | n° 6 A.5, reprise |
| 2 | `assets/hd2d/props/town_doorsteps.png` | 115 × 48 (1,2 × 0,5 m) | panneau ; ancre : milieu du bord bas | trois marches de pierre devant une porte, un paillasson | un mur ou une porte dessinés ; du texte sur le paillasson | n° 6 A.5, reprise |
| 2 | `assets/hd2d/props/town_cellar_hatch.png` | 115 × 58 (1,2 × 0,6 m) | panneau ; ancre : milieu du bord bas | trappe de cave de bois inclinée contre un mur, pentures de fer | un mur dessiné derrière ; une trappe neuve | n° 6 A.5, reprise |
| 2 | `assets/hd2d/props/town_roofs_a.png` | 1536 × 768 (16 × 8 m) | lisière, raccord à gauche et à droite ; ancre : milieu du bord bas | la ville qui descend au-delà du bord de la carte, vue de haut et de loin : rangées serrées de toits d'ardoise et de tuiles en écailles, cheminées qui fument, lucarnes, un clocher de pierre, quelques arbres dorés entre les toits ; pour fermer l'horizon des rues | un bord net ; des raccords visibles à gauche et à droite ; des toits asiatiques ; un ciel | n° 6 A.5, reprise |
| 2 | `assets/hd2d/props/town_roofs_b.png` | 1536 × 768 | lisière, raccord ; ancre : milieu du bord bas | Comme `town_roofs_a.png` (jointe, à dessiner d'abord), mais : même chose, toits plus bas et plus épars, jardins et murets entre eux, le bord de la ville qui rejoint la forêt | un bord net ; des raccords visibles à gauche et à droite ; un ciel | n° 6 A.5, reprise |

### A.3 Le village : clôtures de branches, torchis, maison de pierre, appentis

`fence_wattle` en **trois variantes** (haute, basse et effondrée, standard) avec un piquet de bord commun, puis les cinq images du village encore à l'état de remplaçant, reprises du n° 6 (C.5) : le torchis `wall_wattle_daub`, la maison de pierre aisée avec sa version de nuit, l'appentis à bois.

**Références à joindre** : `assets/hd2d/buildings/cafe.png`, `limashenka_house.png`, `assets/hd2d/buildings/materials/roof_thatch.png`, `wall_planks.png`, `wall_stone.png`, `roof_shingles.png`, `assets/hd2d/props/fence_low.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/props/fence_wattle.png` | 192 × 86 (2 × 0,9 m) | panneau, **se raccorde sur lui-même à gauche et à droite**, et **s'enchaîne aussi avec `fence_wattle_b` et `fence_wattle_c`** ; ancre : milieu du bord bas ; REMPLACE le remplaçant du moteur (même nom, même taille) | clôture de branches tressées entre des piquets, quelques brins cassés ; **règle de raccord commune aux trois variantes** : un piquet de bois de 8 px de large, de teinte identique, coupé en deux sur chaque bord (4 px de chaque côté), dont le sommet dépasse le tressage de 6 à 10 px ; le tressage change d'une image à l'autre, mais le piquet de bord ne change jamais | des bords gauche et droit qui ne se raccordent pas ; une ombre portée au sol ; une marge transparente sur les côtés ; du texte ; un tressage régulier en grillage | n° 6 C.5 |
| 1 | `assets/hd2d/props/fence_wattle_b.png` | 192 × 67 (2 × 0,7 m) | panneau, **se raccorde sur lui-même à gauche et à droite** et avec `fence_wattle.png` et `fence_wattle_c.png` ; ancre : milieu du bord bas | variante B de `fence_wattle.png` (jointe, même piquet de bord de 8 px coupé en deux) : **clôture basse à moitié effondrée**, piquets penchés, le tressage troué par endroits, une plaque de mousse | des bords qui ne se raccordent pas ; un piquet de bord différent ; un effondrement qui coupe le haut de l'image net ; une ombre portée | n° 7 |
| 2 | `assets/hd2d/props/fence_wattle_c.png` | 192 × 106 (2 × 1,1 m) | panneau, **se raccorde sur lui-même à gauche et à droite** et avec `fence_wattle.png` et `fence_wattle_b.png` ; ancre : milieu du bord bas | variante C de `fence_wattle.png` (jointe, même piquet de bord de 8 px coupé en deux) : **clôture haute** de 1,1 m au tressage serré, un piquet central plus haut que les autres, une corde de chanvre qui tient le haut, de la mousse sur la face nord | des bords qui ne se raccordent pas ; un piquet de bord différent ; un grillage ; une ombre portée | n° 7 |
| 2 | `assets/hd2d/buildings/materials/wall_wattle_daub.png` | 192 × 192 | matière ; opaque, sans ancre | torchis ocre clair grumeleux, brins de paille visibles, petites fissures, sans colombages (ils sont dans les façades) | un raccord visible sur un bord ; un motif qui se répète à intervalle régulier ; un objet, un joint isolé ou une ombre portée | n° 6 C.5, reprise |
| 2 | `assets/hd2d/buildings/village_house_stone.png` | 480 × 576 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 3 m, faîte 6 m, profondeur 5 m ; matières `wall_stone`, `roof_shingles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison de pierre un peu plus aisée, toit de bardeaux, porte à heurtoir, deux fenêtres à volets, une plus petite à l'étage dans le pignon, lierre au coin | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 C.5, reprise |
| 2 | `assets/hd2d/buildings/village_house_stone_side.png` | 480 × 288 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 3 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `village_house_stone.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone`, `roof_shingles`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 C.5, reprise |
| 2 | `assets/hd2d/buildings/village_house_stone_night.png` | 480 × 576 | façade de nuit : même cadrage et même taille que celle du jour, au pixel près ; ancre : milieu du bord bas | `village_house_stone.png` (jointe) la nuit : une fenêtre de l'étage allumée (#FFE6A6), les volets du bas fermés ; pénombre bleue | changer le cadrage ou le dessin ; des vitres orangées ; un ciel ou un fond ; plus d'une fenêtre allumée | n° 6 C.5, reprise |
| 3 | `assets/hd2d/buildings/village_shed.png` | 384 × 216 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 2,25 m, faîte 3,5 m, profondeur 3 m ; matières `wall_planks_b`, `roof_shingles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | appentis à bois de planches grises, bûches empilées sous l'avancée, une hache plantée dans un billot devant | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | n° 6 C.5, reprise |
| 3 | `assets/hd2d/buildings/village_shed_side.png` | 288 × 336 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 2,25 m, faîte 3,5 m, profondeur 3 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `village_shed.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_planks_b`, `roof_shingles`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | n° 6 C.5, reprise |

### A.4 Variantes de nature : roseaux, haies, chênes, tas de feuilles, cailloux

Les images que le jeu répète le plus. **Une silhouette nouvelle à chaque image** : réduite à 40 px, elle ne doit pas se confondre avec ses sœurs. Les haies `thicket_d` à `f` servent aussi au premier plan (le jeu pose les mêmes images plus près et les floute) : ne les dessine pas flous. Les chênes sont **tous différents de `oak_a.png`** (c'est le bouche-trou du jeu depuis le début).

**Références à joindre** : `assets/hd2d/props/reeds.png`, `reeds_b.png`, `cattails.png`, `marsh_reed_wall.png`, `thicket_a.png`, `thicket_b.png`, `thicket_c.png`, `bramble_hedge.png`, `oak_a.png`, `oak_b.png`, `oak_c.png`, `oak_d.png`, `tree_autumn.png`, `assets/hd2d/decals/leaves_gold_a.png`, `leaves_rust_a.png`, `pebbles_a.png`, `pebbles_b.png`, `assets/hd2d/ground/leaf_litter.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/props/reeds_c.png` | 134 × 173 (1,4 × 1,8 m) | panneau ; ancre : milieu du bord bas | touffe de roseaux **hauts**, penchée vers la droite, tiges fines d'un jaune pâle (#9C9563), plumeaux gris, deux tiges cassées qui pendent, quelques feuilles rousses tombées dans le pied | une touffe symétrique ; des tiges vertes ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 1 | `assets/hd2d/props/reeds_d.png` | 96 × 106 (1 × 1,1 m) | panneau ; ancre : milieu du bord bas | petite touffe **clairsemée** : une dizaine de tiges basses, certaines couchées, des feuilles de laîche sèches au pied | une touffe dense ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 1 | `assets/hd2d/props/thicket_d.png` | 211 × 173 (2,2 × 1,8 m) | panneau ; ancre : milieu du bord bas | **aubépine** d'automne : buisson épineux d'un seul tenant, branches tordues, feuilles rouille et or clairsemées, baies rouge sombre en grappes, un nid vide dans la fourche ; la même version sert au premier plan (le jeu la pose plus près et la floute) | un buisson rond comme une boule ; des fleurs ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 1 | `assets/hd2d/props/thicket_e.png` | 336 × 134 (3,5 × 1,4 m) | panneau ; ancre : milieu du bord bas | **haie basse et longue** de fusain et de cornouiller : rameaux rouge brique dressés, feuilles roses et orangées, quelques fruits roses, un trou au pied où passe un petit animal | une haie taillée au cordeau ; un dessus plat ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 1 | `assets/hd2d/props/oak_e.png` | 480 × 720 (5 × 7,5 m) | panneau ; ancre : milieu du bord bas | **chêne penché** : le tronc s'incline vers la droite, couronne déséquilibrée, plus fournie à droite, rouille et or, branches basses maîtresses dont l'une touche presque le sol, racines apparentes à gauche, un lierre sur le tronc | la silhouette de `oak_a.png` (jointe : à ne pas recopier) ; un tronc droit et symétrique ; un houppier rond ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 2 | `assets/hd2d/props/reeds_e.png` | 192 × 144 (2 × 1,5 m) | panneau ; ancre : milieu du bord bas | **massif large** de roseaux et de massettes brunes mêlés, plus épais à gauche qu'à droite, une trouée au milieu où l'on voit le fond, deux massettes éclatées dont le duvet pend | un rideau régulier sur toute la largeur ; un bord droit à droite ou à gauche ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 2 | `assets/hd2d/props/reeds_f.png` | 77 × 192 (0,8 × 2 m) | panneau ; ancre : milieu du bord bas | **tiges très hautes et peu nombreuses** (5 à 7), courbées par le vent, les plumeaux lourds, une tige à demi pliée, un peu de laîche au pied | une touffe large ; des tiges rectilignes comme des poteaux ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 2 | `assets/hd2d/props/thicket_f.png` | 163 × 192 (1,7 × 2 m) | panneau ; ancre : milieu du bord bas | **haut fourré de noisetiers et de ronces mortes**, presque sans feuilles, tiges grises arquées qui retombent, quelques feuilles dorées accrochées, un lierre sombre à la base | un arbre ; un feuillage dense et vert ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 2 | `assets/hd2d/props/oak_f.png` | 672 × 816 (7 × 8,5 m) | panneau ; ancre : milieu du bord bas | **vieux chêne large et bas** : tronc court et énorme, creux sombre à la base, couronne très large qui descend, feuillage presque entièrement doré, quelques branches mortes grises dans le haut | la silhouette de `oak_a.png` ; une couronne haute et étroite ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 2 | `assets/hd2d/props/oak_g.png` | 576 × 672 (6 × 7 m) | panneau ; ancre : milieu du bord bas | **chêne foudroyé** : le tronc fendu en deux jusqu'à mi-hauteur, une moitié morte et grise sans feuilles, l'autre couronnée de feuillage rouille ; des éclats de bois clair à la fente | la silhouette de `oak_a.png` ; une fente nette comme une coupe de scie ; du feu ou de la fumée ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 2 | `assets/hd2d/props/leaf_pile_a.png` | 115 × 58 (1,2 × 0,6 m) | panneau ; ancre : milieu du bord bas | **tas de feuilles mortes** poussées contre un mur ou un tronc : une butte irrégulière de feuilles de chêne rouille et or, quelques feuilles qui débordent au pied, une brindille qui dépasse | une butte lisse comme une dune ; des feuilles toutes identiques ; un sol dessiné ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 2 | `assets/hd2d/props/leaf_pile_b.png` | 154 × 77 (1,6 × 0,8 m) | panneau ; ancre : milieu du bord bas | **grand tas** de feuilles d'érable rouges et de feuilles d'orme jaunes, un râteau de bois couché à moitié enfoui (le manche dépasse à droite) | un râteau moderne ; un personnage ; un sol dessiné ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 2 | `assets/hd2d/decals/pebbles_c.png` | 192 × 144 (2 × 1,5 m) | décalque ; ancre : centre | semis de galets : une grande pierre plate à demi enfoncée et une dizaine de cailloux de tailles très différentes, de la terre et des brins d'herbe entre eux ; vu strictement de dessus | un bord net ou ovale ; une pierre qui touche le bord de l'image ; des contours noirs ; la même disposition que `pebbles_a.png` ou `pebbles_b.png` ; un contraste fort avec le sol | n° 7 |
| 3 | `assets/hd2d/props/leaf_pile_c.png` | 77 × 48 (0,8 × 0,5 m) | panneau ; ancre : milieu du bord bas | **petit tas** de feuilles brunes détrempées, collées, une flaque sombre à son pied (dessinée dans l'image, pas en alpha doux) | une butte sèche et gonflée ; une flaque bleue ; une ombre portée ; un contour noir ; un fond ; la même silhouette que l'image jointe (elle doit se distinguer au premier coup d'œil, même réduite à 40 px) ; des couleurs d'été (c'est la fin de l'automne) | n° 7 |
| 3 | `assets/hd2d/decals/pebbles_d.png` | 96 × 96 (1 × 1 m) | décalque ; ancre : centre | trois cailloux serrés et des miettes de gravier qui s'éparpillent sur un seul côté, quelques brins de mousse ; vu strictement de dessus | un bord net ; des cailloux ronds comme des billes ; des contours noirs ; un contraste fort avec le sol | n° 7 |

### A.5 Premiers plans peints

Des masses de feuillage, de branches, de hautes herbes et de roseaux qui **entrent dans le cadre par le bas et par les côtés**, en **trois tailles** (feuillage bas de 1,5 à 2 m, moyen de 3 à 4 m, haut de 6 m) et **trois branches de côté** de 6 à 10 m. Le jeu les pose entre la caméra et le joueur et leur ajoute le flou de profondeur : **on les dessine simplifiés** (grandes masses, rien de plus fin que 3 px, plus sombres et moins contrastés), **jamais flous**. Elles touchent **toutes** le bord bas : rien ne se suspend en l'air (le premier plan suspendu du n° 6, D.2, reste en attente).

**Références à joindre** : `assets/hd2d/props/fg_bush.png`, `fg_fern.png`, `fg_grass.png`, `fg_trunk_a.png`, `bush.png`, `oak_b.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/props/fg_leaves_low_a.png` | 288 × 144 (3 × 1,5 m) | panneau de premier plan, **alpha doux sur le pourtour seulement** (6 à 10 px) ; ancre : milieu du bord bas ; tout touche le bord bas, rien ne se suspend | feuillage bas qui entre dans le cadre **par le bas** : une masse de grandes feuilles de chêne rouille et or serrées sur un tronc de jeune arbre hors cadre, plus haute à gauche ; dessin **simplifié en grandes masses** (aucun détail plus fin que 3 px, contours de 2 px d'une teinte sombre du feuillage), couleurs **15 à 25 % plus sombres et moins saturées** que `bush.png`, reflets chauds larges | du flou gaussien dans l'image (le jeu ajoute le flou de profondeur : on dessine des masses franches et simples) ; un détail plus fin que 3 px ; un liseré clair autour des feuilles ; des contrastes aussi forts que les images du plan moyen ; une ombre portée ; un objet suspendu en l'air qui ne touche pas le bord bas | n° 7 |
| 1 | `assets/hd2d/props/fg_leaves_low_b.png` | 480 × 192 (5 × 2 m) | panneau de premier plan, **alpha doux sur le pourtour seulement** (6 à 10 px) ; ancre : milieu du bord bas ; tout touche le bord bas, rien ne se suspend | long bandeau de feuillage et de fougères qui monte de **tout le bas** du cadre, bord supérieur très irrégulier (touffes, trouées), quelques tiges sèches qui dépassent ; dessin **simplifié en grandes masses** (aucun détail plus fin que 3 px, contours de 2 px d'une teinte sombre du feuillage), couleurs **15 à 25 % plus sombres et moins saturées** que `bush.png`, reflets chauds larges | du flou gaussien dans l'image (le jeu ajoute le flou de profondeur : on dessine des masses franches et simples) ; un détail plus fin que 3 px ; un liseré clair autour des feuilles ; des contrastes aussi forts que les images du plan moyen ; une ombre portée ; un objet suspendu en l'air qui ne touche pas le bord bas ; un bord supérieur régulier | n° 7 |
| 1 | `assets/hd2d/props/fg_leaves_mid_a.png` | 384 × 288 (4 × 3 m) | panneau de premier plan, **alpha doux sur le pourtour seulement** (6 à 10 px) ; ancre : milieu du bord bas ; tout touche le bord bas, rien ne se suspend | masse **moyenne** de feuillage doré penchée vers la droite : une grosse touffe de branches à feuilles d'orme jaunes, des tiges nues qui plongent vers le bas de l'image ; dessin **simplifié en grandes masses** (aucun détail plus fin que 3 px, contours de 2 px d'une teinte sombre du feuillage), couleurs **15 à 25 % plus sombres et moins saturées** que `bush.png`, reflets chauds larges | du flou gaussien dans l'image (le jeu ajoute le flou de profondeur : on dessine des masses franches et simples) ; un détail plus fin que 3 px ; un liseré clair autour des feuilles ; des contrastes aussi forts que les images du plan moyen ; une ombre portée ; un objet suspendu en l'air qui ne touche pas le bord bas | n° 7 |
| 1 | `assets/hd2d/props/fg_limb_a.png` | 384 × 768 (4 × 8 m) | panneau de premier plan, **alpha doux sur le pourtour seulement** (6 à 10 px) ; ancre : milieu du bord bas ; tout touche le bord bas, rien ne se suspend ; **le bord gauche est coupé net, voulu** (c'est un arbre hors cadre) | **branche qui entre par le côté** : un tronc brun sombre coupé par le bord gauche de l'image, qui monte du bord bas, une grosse branche qui part vers la droite en montant puis retombe, feuillage rouille et or en grappes qui pend ; le jeu la retourne pour l'autre côté ; dessin **simplifié en grandes masses** (aucun détail plus fin que 3 px, contours de 2 px d'une teinte sombre du feuillage), couleurs **15 à 25 % plus sombres et moins saturées** que `bush.png`, reflets chauds larges | du flou gaussien dans l'image (le jeu ajoute le flou de profondeur : on dessine des masses franches et simples) ; un détail plus fin que 3 px ; un liseré clair autour des feuilles ; des contrastes aussi forts que les images du plan moyen ; une ombre portée ; un objet suspendu en l'air qui ne touche pas le bord bas ; un bord gauche flou (il est net) ; un bord droit net (le feuillage s'y estompe) | n° 7 |
| 2 | `assets/hd2d/props/fg_leaves_mid_b.png` | 288 × 384 (3 × 4 m) | panneau de premier plan, **alpha doux sur le pourtour seulement** (6 à 10 px) ; ancre : milieu du bord bas ; tout touche le bord bas, rien ne se suspend | masse **haute et étroite** : le bas d'un jeune bouleau ou d'un noisetier au feuillage jaune citron, penchée vers la gauche, dense en bas, clairsemée en haut ; dessin **simplifié en grandes masses** (aucun détail plus fin que 3 px, contours de 2 px d'une teinte sombre du feuillage), couleurs **15 à 25 % plus sombres et moins saturées** que `bush.png`, reflets chauds larges | du flou gaussien dans l'image (le jeu ajoute le flou de profondeur : on dessine des masses franches et simples) ; un détail plus fin que 3 px ; un liseré clair autour des feuilles ; des contrastes aussi forts que les images du plan moyen ; une ombre portée ; un objet suspendu en l'air qui ne touche pas le bord bas | n° 7 |
| 2 | `assets/hd2d/props/fg_leaves_high.png` | 576 × 576 (6 × 6 m) | panneau de premier plan, **alpha doux sur le pourtour seulement** (6 à 10 px) ; ancre : milieu du bord bas ; tout touche le bord bas, rien ne se suspend | **grosse** masse de feuillage rouille, plus large que haute, qui couvre le bas d'un côté et laisse l'autre côté vide ; dessin **simplifié en grandes masses** (aucun détail plus fin que 3 px, contours de 2 px d'une teinte sombre du feuillage), couleurs **15 à 25 % plus sombres et moins saturées** que `bush.png`, reflets chauds larges | du flou gaussien dans l'image (le jeu ajoute le flou de profondeur : on dessine des masses franches et simples) ; un détail plus fin que 3 px ; un liseré clair autour des feuilles ; des contrastes aussi forts que les images du plan moyen ; une ombre portée ; un objet suspendu en l'air qui ne touche pas le bord bas ; une masse centrée et symétrique | n° 7 |
| 2 | `assets/hd2d/props/fg_limb_b.png` | 288 × 576 (3 × 6 m) | panneau de premier plan, **alpha doux sur le pourtour seulement** (6 à 10 px) ; ancre : milieu du bord bas ; tout touche le bord bas, rien ne se suspend ; **le bord gauche est coupé net, voulu** | branche plus **petite et plus basse**, le tronc coupé par le bord gauche, deux branches courtes, feuillage maigre et jaune, une branche morte grise ; dessin **simplifié en grandes masses** (aucun détail plus fin que 3 px, contours de 2 px d'une teinte sombre du feuillage), couleurs **15 à 25 % plus sombres et moins saturées** que `bush.png`, reflets chauds larges | du flou gaussien dans l'image (le jeu ajoute le flou de profondeur : on dessine des masses franches et simples) ; un détail plus fin que 3 px ; un liseré clair autour des feuilles ; des contrastes aussi forts que les images du plan moyen ; une ombre portée ; un objet suspendu en l'air qui ne touche pas le bord bas ; la même branche que `fg_limb_a.png` réduite | n° 7 |
| 2 | `assets/hd2d/props/fg_grass_tall.png` | 384 × 192 (4 × 2 m) | panneau de premier plan, **alpha doux sur le pourtour seulement** (6 à 10 px) ; ancre : milieu du bord bas ; tout touche le bord bas, rien ne se suspend | **herbes hautes sèches** qui montent du bas du cadre : touffes de graminées couleur paille et or grisé, épis lourds, quelques chardons secs ; dessin **simplifié en grandes masses** (aucun détail plus fin que 3 px, contours de 2 px d'une teinte sombre du feuillage), couleurs **15 à 25 % plus sombres et moins saturées** que `bush.png`, reflets chauds larges | du flou gaussien dans l'image (le jeu ajoute le flou de profondeur : on dessine des masses franches et simples) ; un détail plus fin que 3 px ; un liseré clair autour des feuilles ; des contrastes aussi forts que les images du plan moyen ; une ombre portée ; un objet suspendu en l'air qui ne touche pas le bord bas ; des brins verts | n° 7 |
| 2 | `assets/hd2d/props/fg_reeds.png` | 384 × 288 (4 × 3 m) | panneau de premier plan, **alpha doux sur le pourtour seulement** (6 à 10 px) ; ancre : milieu du bord bas ; tout touche le bord bas, rien ne se suspend | **roseaux de premier plan** pour les marais et les berges : une rangée irrégulière de grandes tiges pâles et de plumeaux bruns, plus denses sur les côtés, une trouée au milieu ; dessin **simplifié en grandes masses** (aucun détail plus fin que 3 px, contours de 2 px d'une teinte sombre du feuillage), couleurs **15 à 25 % plus sombres et moins saturées** que `bush.png`, reflets chauds larges | du flou gaussien dans l'image (le jeu ajoute le flou de profondeur : on dessine des masses franches et simples) ; un détail plus fin que 3 px ; un liseré clair autour des feuilles ; des contrastes aussi forts que les images du plan moyen ; une ombre portée ; un objet suspendu en l'air qui ne touche pas le bord bas ; une rangée au cordeau | n° 7 |
| 3 | `assets/hd2d/props/fg_limb_c.png` | 480 × 960 (5 × 10 m) | panneau de premier plan, **alpha doux sur le pourtour seulement** (6 à 10 px) ; ancre : milieu du bord bas ; tout touche le bord bas, rien ne se suspend ; **le bord gauche est coupé net, voulu** | **grand** tronc coupé par le bord gauche, écorce profonde, une branche maîtresse qui s'étire sur toute la largeur de l'image en montant, feuillage dense et sombre en haut, trouées de lumière ; dessin **simplifié en grandes masses** (aucun détail plus fin que 3 px, contours de 2 px d'une teinte sombre du feuillage), couleurs **15 à 25 % plus sombres et moins saturées** que `bush.png`, reflets chauds larges | du flou gaussien dans l'image (le jeu ajoute le flou de profondeur : on dessine des masses franches et simples) ; un détail plus fin que 3 px ; un liseré clair autour des feuilles ; des contrastes aussi forts que les images du plan moyen ; une ombre portée ; un objet suspendu en l'air qui ne touche pas le bord bas ; un tronc lisse | n° 7 |

### A.6 Lisières de second rang

Quatre pans de 16 m de large mais de 6,5 m de haut, **plus sombres, plus violacés et plus bas** que `forest_wall_a` à `d` et `treeline_autumn_a` et `b` (jointes) : le jeu les pose **derrière** une lisière du premier rang pour faire deux plans de forêt au lieu d'un seul pan à raccord.

**Références à joindre** : `assets/hd2d/props/forest_wall_a.png`, `forest_wall_b.png`, `treeline_autumn_a.png`, `treeline_autumn_b.png`, `assets/hd2d/sky/mist_band.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/props/treeline_back_a.png` | 1536 × 624 (16 × 6,5 m) | lisière, **se raccorde à gauche et à droite** ; ancre : milieu du bord bas | **lisière de second rang**, à poser derrière un premier pan : arbres d'automne (chênes, hêtres) plus **sombres, plus bas et plus fins** que `forest_wall_a.png` (jointe), teintes ramenées de 25 % vers le violet sombre (#4A3F52) comme par la distance, troncs de 20 à 50 cm de large espacés de façon irrégulière, entre eux un troisième plan encore plus sombre ; au pied, un voile de brume sombre et des fougères fanées (sans sol dessiné) | un bord gauche ou droit qui ne se raccorde pas ; un ciel ou un sol dessinés ; un contraste fort ; des troncs alignés à intervalles égaux ; un arbre qui dépasse 6,5 m ; la même lisière que `forest_wall_a.png` ou `treeline_autumn_a.png` (jointes) en plus sombre : il faut une autre silhouette | n° 7 |
| 1 | `assets/hd2d/props/treeline_back_b.png` | 1536 × 624 (16 × 6,5 m) | lisière, **se raccorde à gauche et à droite** ; ancre : milieu du bord bas | second rang de **sapins** sombres, vert très foncé (#3D5946 assombri), de hauteurs inégales, quelques sapins morts gris, des trous où l'on voit le troisième plan violacé ; au pied, de la brume basse | un bord gauche ou droit qui ne se raccorde pas ; un ciel ou un sol dessinés ; un contraste fort ; des troncs alignés à intervalles égaux ; un arbre qui dépasse 6,5 m ; la même lisière que `forest_wall_a.png` ou `treeline_autumn_a.png` (jointes) en plus sombre : il faut une autre silhouette | n° 7 |
| 2 | `assets/hd2d/props/treeline_back_c.png` | 1536 × 624 (16 × 6,5 m) | lisière, **se raccorde à gauche et à droite** ; ancre : milieu du bord bas | second rang **mêlé** : bouleaux pâles et chênes rouille dans la pénombre, plus de troncs que de feuillage, la moitié des arbres déjà nus, de petites clairières sombres entre eux ; au pied, de la brume basse | un bord gauche ou droit qui ne se raccorde pas ; un ciel ou un sol dessinés ; un contraste fort ; des troncs alignés à intervalles égaux ; un arbre qui dépasse 6,5 m ; la même lisière que `forest_wall_a.png` ou `treeline_autumn_a.png` (jointes) en plus sombre : il faut une autre silhouette | n° 7 |
| 2 | `assets/hd2d/props/treeline_back_d.png` | 1536 × 624 (16 × 6,5 m) | lisière, **se raccorde à gauche et à droite** ; ancre : milieu du bord bas | second rang **de marais** : aulnes et saules bas aux troncs penchés, feuillage clairsemé gris-vert et rouille, des roseaux sombres au pied, un voile de brume plus épais ; plus bas que les trois autres (5 m au plus) | un bord gauche ou droit qui ne se raccorde pas ; un ciel ou un sol dessinés ; un contraste fort ; des troncs alignés à intervalles égaux ; un arbre qui dépasse 6,5 m ; la même lisière que `forest_wall_a.png` ou `treeline_autumn_a.png` (jointes) en plus sombre : il faut une autre silhouette ; de l'eau dessinée | n° 7 |

### A.7 Bords de talus : lèvres, angles, pieds

L'audit voit des paliers à angles droits et un liseré vert uniforme. Les **lèvres** (trois), les **angles sortants et rentrants** (quatre) et les **pieds** (deux) se posent le long du haut et au pied des talus : ils rendent le bord irrégulier et arrondi. Ce sont des décalques de sol, vus de dessus ; `cliff/bank_earth.png` (la face, livrée) reste intacte.

**Références à joindre** : `assets/hd2d/cliff/bank_earth.png`, `assets/hd2d/cliff/lip.png`, `assets/hd2d/decals/grass_edge_a.png`, `grass_edge_b.png`, `assets/hd2d/ground/grass.png`, `garden_soil.png`, `path_dirt.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/decals/bank_lip_a.png` | 384 × 96 (4 × 1 m) | décalque de sol, vu strictement de dessus, **se raccorde sur lui-même à gauche et à droite** et avec les deux autres lèvres (`bank_lip_a`, `_b`, `_c`) ; bord haut plein, bas irrégulier et en alpha doux ; ancre : centre | **lèvre d'herbe d'un talus** : en haut, l'herbe du pré qui continue le sol ; en bas, le bord du talus : l'herbe déborde en touffes irrégulières, quelques brins pendants, de la terre brune (#56402C) qui apparaît entre les touffes, une racine ; sous le bord, une bande de terre sombre qui s'estompe vers le bas (alpha doux) ; règle de raccord commune aux trois lèvres : sur chaque bord, le haut de l'image est de l'herbe pleine (couleur de `ground/grass.png`, #87A35E) sur les 40 premiers px, et le bord inférieur de la lèvre passe à 62 px du haut | un bord ondulé de façon régulière (des vagues égales) ; un liseré vert uniforme ; un bord inférieur net ; des raccords visibles ; un contour noir ; des touffes identiques répétées | n° 7 |
| 1 | `assets/hd2d/decals/bank_lip_b.png` | 384 × 96 (4 × 1 m) | décalque de sol, vu strictement de dessus, **se raccorde sur lui-même à gauche et à droite** et avec les deux autres lèvres (`bank_lip_a`, `_b`, `_c`) ; bord haut plein, bas irrégulier et en alpha doux ; ancre : centre | variante B : lèvre **plus abrupte**, deux grosses mottes d'herbe qui surplombent, une pierre à moitié déchaussée, un éboulis de terre sous le bord, des feuilles mortes prises dans les racines ; règle de raccord commune aux trois lèvres : sur chaque bord, le haut de l'image est de l'herbe pleine (couleur de `ground/grass.png`, #87A35E) sur les 40 premiers px, et le bord inférieur de la lèvre passe à 62 px du haut | un bord ondulé de façon régulière ; un bord inférieur net ; des raccords visibles ; un contour noir | n° 7 |
| 2 | `assets/hd2d/decals/bank_lip_c.png` | 384 × 96 (4 × 1 m) | décalque de sol, vu strictement de dessus, **se raccorde sur lui-même à gauche et à droite** et avec les deux autres lèvres (`bank_lip_a`, `_b`, `_c`) ; bord haut plein, bas irrégulier et en alpha doux ; ancre : centre | variante C : lèvre **éboulée**, l'herbe clairsemée qui laisse voir la terre, des fougères fanées au bord, un petit éboulement de cailloux ; règle de raccord commune aux trois lèvres : sur chaque bord, le haut de l'image est de l'herbe pleine (couleur de `ground/grass.png`, #87A35E) sur les 40 premiers px, et le bord inférieur de la lèvre passe à 62 px du haut | un bord ondulé de façon régulière ; des raccords visibles ; un contour noir ; une herbe de pelouse tondue | n° 7 |
| 2 | `assets/hd2d/decals/bank_corner_out_a.png` | 192 × 192 (2 × 2 m) | décalque de sol, vu de dessus, alpha doux ; ancre : centre ; **angle sortant** (le coin du palier qui avance dans le vide), le jeu le tourne par quarts de tour et le retourne | angle **sortant arrondi** (rayon de 0,8 m) d'un talus : la lèvre d'herbe de `bank_lip_a.png` (jointe) tourne autour du coin ; ses deux bras ont le même profil que la lèvre et sortent **au milieu de deux bords voisins de l'image** (à mi-hauteur de la bande de 96 px) pour se raccorder à elle ; touffes qui débordent, terre brune sous le bord | un angle droit ; un cercle parfait ; des bras qui ne tombent pas au milieu du bord ; un bord net ; un contour noir | n° 7 |
| 2 | `assets/hd2d/decals/bank_corner_in_a.png` | 192 × 192 (2 × 2 m) | décalque de sol, vu de dessus, alpha doux ; ancre : centre ; **angle rentrant** (le talus qui recule dans le pré), le jeu le tourne par quarts de tour et le retourne | angle **rentrant arrondi** (rayon de 0,8 m) : la lèvre d'herbe de `bank_lip_a.png` (jointe) fait une anse ; mêmes bras, au milieu de deux bords voisins ; l'herbe y déborde plus qu'ailleurs, une petite touffe de roseaux secs au creux | un angle droit ; un demi-cercle parfait ; des bras qui ne tombent pas au milieu du bord ; un bord net | n° 7 |
| 3 | `assets/hd2d/decals/bank_corner_out_b.png` | 192 × 192 (2 × 2 m) | décalque de sol, vu de dessus, alpha doux ; ancre : centre ; **angle sortant**, le jeu le tourne et le retourne | variante B de l'angle sortant : rayon **plus large** (1,2 m), un éboulement de terre au sommet de la courbe, deux touffes de bruyère ; mêmes bras que `bank_corner_out_a.png` (jointe), au milieu de deux bords voisins | un angle droit ; des bras qui ne tombent pas au milieu du bord ; un contour noir | n° 7 |
| 3 | `assets/hd2d/decals/bank_corner_in_b.png` | 192 × 192 (2 × 2 m) | décalque de sol, vu de dessus, alpha doux ; ancre : centre ; **angle rentrant**, le jeu le tourne et le retourne | variante B de l'angle rentrant : anse **peu profonde et large** (rayon 1,2 m), une souche mangée par la terre ; mêmes bras que `bank_corner_in_a.png` (jointe) | un angle droit ; des bras mal placés ; un bord net | n° 7 |
| 3 | `assets/hd2d/decals/bank_foot_a.png` | 384 × 58 (4 × 0,6 m) | décalque de sol, vu de dessus, **se raccorde sur lui-même à gauche et à droite**, alpha doux ; ancre : centre | **pied de talus** : terre éboulée, cailloux, herbes folles et feuilles mortes à l'endroit où la face du talus rejoint le sol ; haut irrégulier qui se glisse sous la face, bas qui s'estompe dans le sol | un bord net ; une bande de terre régulière ; des raccords visibles ; un contour noir | n° 7 |
| 3 | `assets/hd2d/decals/bank_foot_b.png` | 384 × 58 (4 × 0,6 m) | décalque de sol, vu de dessus, **se raccorde sur lui-même à gauche et à droite**, alpha doux ; ancre : centre | variante B du pied de talus : **humide**, une flaque brune étroite, des racines noires, de la mousse sur les pierres | un bord net ; une flaque bleue ; des raccords visibles ; un contour noir | n° 7 |

### A.8 Taches de lumière de sous-bois

Il n'existe qu'une tache de lumière (`sun_dapple.png`) : trois autres, de forme et de taille différentes, pour les sous-bois et les clairières.

**Références à joindre** : `assets/hd2d/decals/sun_dapple.png`, `canopy_shadow_a.png`, `sun_window.png`, `assets/hd2d/sky/light_shaft_a.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/decals/sun_dapple_b.png` | 288 × 288 (3 × 3 m) | décalque de sol, vu de dessus, **alpha doux** ; ancre : centre | taches de **lumière de sous-bois** : plages irrégulières de jaune pâle (#FFE6A6) à 40 à 70 % d'alpha, bords doux, une grande tache et quatre petites, comme le soleil bas qui traverse un feuillage clairsemé | des bords nets ; du noir ou du gris sombre (c'est de la lumière : jaune pâle, jamais de l'ombre) ; des disques parfaits ; la même disposition que `sun_dapple.png` (jointe) ; un alpha supérieur à 70 % | n° 7 |
| 2 | `assets/hd2d/decals/sun_dapple_c.png` | 480 × 288 (5 × 3 m) | décalque de sol, vu de dessus, **alpha doux** ; ancre : centre | **traînée** de taches de lumière étirée dans un sens (le soleil entre deux troncs) : une dizaine de plages inégales, plus denses au centre | des bords nets ; du noir ou du gris sombre (c'est de la lumière : jaune pâle, jamais de l'ombre) ; des disques parfaits ; la même disposition que `sun_dapple.png` (jointe) ; un alpha supérieur à 70 % | n° 7 |
| 3 | `assets/hd2d/decals/sun_dapple_d.png` | 192 × 192 (2 × 2 m) | décalque de sol, vu de dessus, **alpha doux** ; ancre : centre | **une seule tache** de lumière un peu ovale, avec deux éclats plus petits à côté, bords très doux | des bords nets ; du noir ou du gris sombre (c'est de la lumière : jaune pâle, jamais de l'ombre) ; des disques parfaits ; la même disposition que `sun_dapple.png` (jointe) ; un alpha supérieur à 70 % | n° 7 |

## 5. Lot B : le mouvement des personnages

**Total du lot B : 10 planches de mouvement** (30 PNG et 30 JSON), soit **450 images dessinées** (150 par vue) : Chtholly **81** (priorité 1), Willem et les trois premières fées **189** (priorité 2), les cinq autres **180** (priorité 3).

### 5.1 Pourquoi, et ce que le jeu fait aujourd'hui

L'audit d'animation du 16 octobre 2026 (rafales d'images de la marche, de l'arrêt, du demi-tour) :

- **le repos de Chtholly n'a que 2 images à 2 ips** : elle est une statue qui respire d'un pixel ;
- **aucune image de départ, d'arrêt ni de demi-tour** : au demi-tour, la vitesse passe sous le seuil d'arrêt, **une image de repos s'affiche**, puis la marche repart
  à l'image 0 ; pendant 2 à 3 images le personnage glisse à rebours, et l'épée change de côté en plein pas ;
- **une marche de 6 images dont le pas ne colle pas à la vitesse** (3.3) : les pieds glissent.

Le moteur (lot AN) règle l'allure, la vue qui suit la vitesse et la transition entre rangées ; ce lot donne **les images qui lui manquent**. Chtholly est
le personnage que le joueur voit dans chaque vue : elle passe d'abord, puis Willem (compagnon de ses scènes), Ithea, Nephren et Tiat (les fées de ses scènes),
puis Pannibal, Collon, Lakhesh, Almita et Nygglatho.

### 5.2 Ce que contient chaque planche, et les chiffres de chacune

Chaque planche de mouvement est la planche `<id>_motion` (trois vues, section 3.1) ; ses rangées sont celles du jeu **complet** ou **court** (3.2) ; sa 1re rangée,
`repos`, est recopiée de la planche existante. Les cadences `marche` et `course` sont celles du 3.3 (aucun autre personnage ne reçoit de marche ni de course : la foule
et les compagnons gardent la leur, qui colle à 1,3 m/s).

| Id | Hauteur debout | Case de gabarit | Jeu de rangées | `marche` | `course` | Images par vue | Priorité |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `chtholly` | 144 px (1,50 m) | 192 × 160 px | complet | 8 images, 18 ips | 6 images, 17 ips | 27 | 1 |
| `willem` | 168 px (1,75 m) | 192 × 184 px | complet | 8 images, 15 ips | 6 images, 15 ips | 27 | 2 |
| `ithea` | 139 px (1,45 m) | 176 × 152 px | court | — | — | 12 | 2 |
| `nephren` | 125 px (1,30 m) | 160 × 136 px | court | — | — | 12 | 2 |
| `tiat` | 106 px (1,10 m) | 128 × 120 px | court | — | — | 12 | 2 |
| `pannibal` | 120 px (1,25 m) | 136 × 136 px | court | — | — | 12 | 3 |
| `collon` | 115 px (1,20 m) | 136 × 128 px | court | — | — | 12 | 3 |
| `lakhesh` | 115 px (1,20 m) | 136 × 128 px | court | — | — | 12 | 3 |
| `almita` | 91 px (0,95 m) | 112 × 104 px | court | — | — | 12 | 3 |
| `nygglatho` | 178 px (1,85 m) | 208 × 200 px | court | — | — | 12 | 3 |

La **case de gabarit** est la taille d'une case de travail (largeur × hauteur) qui contient toutes les poses du personnage (arme et cheveux compris) ; elle sert au
dessinateur, pas au jeu : la planche livrée est découpée au plus juste, les images séparées d'au moins 2 px transparents.

**Répartition du lot B par groupe**

| Groupe | Contenu | Planches | Images dessinées (trois vues) | Priorité |
| --- | --- | --- | --- | --- |
| B.1 | Chtholly (le joueur) | 1 | 81 | 1 |
| B.2 | Willem | 1 | 81 | 2 |
| B.3 | les fées principales : Ithea, Nephren, Tiat | 3 | 108 | 2 |
| B.4 | Pannibal, Collon, Lakhesh, Almita, Nygglatho | 5 | 180 | 3 |
| **Total** | | **10** | **450** | |

### 5.3 Ce qu'il ne faut pas faire (toutes les planches de mouvement)

- redessiner la rangée `repos`, ou la 1re image de `repos_vivant` : elles sont **identiques** à la planche existante, au pixel près ;
- un personnage qui **grandit ou rapetisse** en marchant : toute image debout reste à H au plus, la marche à H − 5 px au moins ;
- **faire avancer le personnage dans la case** : les rangées sont sur place, l'ancre ne bouge pas ;
- un pied d'appui qui **ne recule pas** (patinage) ou recule d'une autre valeur que celle du 3.3 ; deux pas de longueurs différentes dans le même cycle ;
- **un accessoire qui change de côté** d'une image à l'autre, ou d'une vue à l'autre sans passer de l'autre côté de l'image de dos ;
- **un détail de 1 px** qui n'existe que sur une image (étincelle, reflet, brin de cheveu isolé) : le jeu réduit le sprite à l'écran et il scintille ;
- deux silhouettes dans une case, un fantôme de l'image précédente, une ombre au sol, du texte ;
- des rangées de la planche existante (`attaque`, `charge`, `mort`…) : ce cahier n'y touche pas.

**Pour toutes les planches** : `repos` recopiée ; `repos_vivant` image 0 recopiée de `repos` image 0 ; hauteur debout rappelée à la ligne ; **rien sous la ligne des pieds** ;
une seule silhouette par case ; accessoires du même côté (de dos, ils passent de l'autre côté de l'image) ; ancres au bassin ; un fond transparent à alpha net (0 ou 255) ;
**mêmes rangées, mêmes nombres d'images dans les trois vues** ; JSON **sans autre clé** que `version`, `echelle`, `planche`, `direction`, `format`, `animations` (les planches existantes de ce
dossier portent des clés de suivi : ne les recopie pas).

**Les noms des rangées** (`repos_vivant`, `depart`, `arret`, `demi_tour`) et le nom de la planche (`<id>_motion`) sont **proposés** : le lot AN les confirme (section 7). Ne les change pas
sans l'accord de l'utilisateur ; si le nom d'une rangée change, il change **dans toutes les planches** à la fois.

### B.1 Chtholly, la planche de mouvement du joueur (priorité 1)

Le personnage que le joueur voit dans chaque vue. **Jeu complet** : `repos_vivant`, `marche` (8 images), `course` (6 images), `depart`, `arret`, `demi_tour`. Dessine **la `marche` d'abord**, vérifie le pas avec le tableau 3.3, puis les autres rangées. **Rappel des cotes** : hauteur debout **144 px** ; pas de **67 px** à la marche (contact à contact), le pied d'appui recule de **17 px** par image ; foulée de course de 96 px et recul de **32 px** par image.

**Références à joindre** : les trois vues de la planche existante de chaque personnage de la ligne (`assets/characters/chtholly/chtholly.png`, `chtholly_front.png`, `chtholly_back.png`) et `chtholly_home.png` pour le rendu du pas.

| Prio | Planche (profil ; `_motion_front` et `_motion_back` à côté) | Hauteur debout | Rangées (images à ips) | Apparence et consignes propres | À ne pas faire | Joindre | Réf. |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/characters/chtholly/chtholly_motion.png` + `.json` (et `_front`, `_back`) | 144 px | `repos` 2 à 2 (copie) ; `repos_vivant` 6 à 3 ; `marche` 8 à 18 ; `course` 6 à 17 ; `depart` 2 à 12 (non) ; `arret` 2 à 12 (non) ; `demi_tour` 3 à 16 (non) | Chtholly (le joueur) : cheveux bleus très longs retenus en deux hautes couettes, uniforme sombre à jupe plissée et bottes, la grande épée de cristal tenue **dans sa main droite** (la main proche de nous en profil), lame vers l'avant et vers le bas, pointe à la ligne du sol ; **mêmes cheveux, même visage, mêmes couleurs que la planche jointe**. La marche et la course d'aujourd'hui patinent : c'est la planche la plus importante du cahier. Les cheveux et les couettes ont **un temps de retard** sur le corps (ils s'élèvent après la foulée, retombent après le contact) ; la jupe suit d'un demi-temps ; **l'épée reste dans la même main dans toutes les images et les trois vues** : sa pointe monte et descend de 6 px au plus pendant la marche, de 12 px à la course, sans jamais passer sous la ligne des pieds et sans jamais changer de côté, y compris au demi-tour (de face, elle est à gauche de l'image, du côté de la main droite) | une épée qui change de main ou de côté ; une pointe d'épée sous la ligne des pieds ; une épée portée sur l'épaule ou levée ; un personnage plus haut que 144 px ; des cheveux qui restent raides pendant la course ; la rangée `repos` redessinée ; une autre coiffure ou une autre tenue ; un pied qui glisse (le pied d'appui doit reculer de la valeur du tableau 3.3) | `chtholly` (trois vues), `chtholly_home` (le pas de ce style de planche) | n° 7 |

### B.2 Willem (priorité 2)

Le compagnon de ses scènes. **Jeu complet**, au pas de Willem (1,75 m) : hauteur debout **168 px**, pas de **78 px**, recul du pied de **20 px** par image à la marche, de **37 px** à la course (3.3). Joins `chtholly_motion` finie : le rythme est le même, l'allure est plus économe.

**Références à joindre** : les trois vues de la planche existante de chaque personnage de la ligne, puis `chtholly_motion` (trois vues) une fois livrée et validée.

| Prio | Planche (profil ; `_motion_front` et `_motion_back` à côté) | Hauteur debout | Rangées (images à ips) | Apparence et consignes propres | À ne pas faire | Joindre | Réf. |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/characters/willem/willem_motion.png` + `.json` (et `_front`, `_back`) | 168 px | `repos` 2 à 2 (copie) ; `repos_vivant` 6 à 3 ; `marche` 8 à 15 ; `course` 6 à 15 ; `depart` 2 à 12 (non) ; `arret` 2 à 12 (non) ; `demi_tour` 3 à 16 (non) | Willem : cheveux noirs courts en pointes, long manteau sombre à boutons dorés et bottes noires, une épée droite à garde tenue **dans sa main** comme sur la planche jointe, lame vers le bas et l'avant, pointe à la ligne du sol ; **mêmes cheveux, même visage, mêmes couleurs**. Il marche et court **les épaules basses, sans élan théâtral** : une foulée économe, le buste droit, les pans du manteau qui suivent d'un demi-temps ; l'épée reste dans la même main dans toutes les images et les trois vues (pointe à 6 px de débattement au plus à la marche) | une épée qui change de main ; une pointe d'épée sous la ligne des pieds ; un manteau qui flotte comme une cape de héros ; un personnage plus haut que 168 px ; la rangée `repos` redessinée ; un pied qui glisse | `willem` (trois vues), `willem_home`, et `chtholly_motion` (la planche de Chtholly, livrée la première : pour le rythme) | n° 7 |

### B.3 Les fées principales : Ithea, Nephren, Tiat (priorité 2)

Les fées des scènes de Chtholly. **Jeu court** : `repos_vivant` (5 images), `depart`, `arret`, `demi_tour`. `depart` mène à la `marche` **existante** de leur planche (jointe).

**Références à joindre** : les trois vues de la planche existante de chaque personnage de la ligne, puis `chtholly_motion` (trois vues) une fois livrée et validée.

| Prio | Planche (profil ; `_motion_front` et `_motion_back` à côté) | Hauteur debout | Rangées (images à ips) | Apparence et consignes propres | À ne pas faire | Joindre | Réf. |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/characters/ithea/ithea_motion.png` + `.json` (et `_front`, `_back`) | 139 px | `repos` 2 à 2 (copie) ; `repos_vivant` 5 à 3 ; `depart` 2 à 12 (non) ; `arret` 2 à 12 (non) ; `demi_tour` 3 à 16 (non) | Ithea : cheveux orange en mèches dressées comme des oreilles et deux tresses fines, écharpe orange aux pointes en flammes, haut crème, jupe rouge, bas sombres ; la grande arme enveloppée de bandes tenue vers l'arrière, **du même côté dans toutes les images** ; l'écharpe flotte derrière elle (elle suit avec un temps de retard et ne change jamais de côté) | une arme qui change de côté ; une écharpe qui passe devant le visage ; un personnage plus haut que 139 px ; la rangée `repos` redessinée ; du feu dessiné (les pointes de l'écharpe sont des tissus orange) | `ithea` (trois vues), `chtholly_motion` | n° 7 |
| 2 | `assets/characters/nephren/nephren_motion.png` + `.json` (et `_front`, `_back`) | 125 px | `repos` 2 à 2 (copie) ; `repos_vivant` 5 à 3 ; `depart` 2 à 12 (non) ; `arret` 2 à 12 (non) ; `demi_tour` 3 à 16 (non) | Nephren : cheveux gris-lilas avec une couette sur le côté, long manteau violet à col blanc, bottes, la lame sombre tenue en avant et vers le bas ; **la couette reste du même côté** ; elle bouge très peu, l'air calme : mouvements de 1 px de moins que les autres (visage impassible) | une couette qui change de côté ; une lame sous la ligne des pieds ; un personnage plus haut que 125 px ; la rangée `repos` redessinée ; un air joyeux (elle est impassible) | `nephren` (trois vues), `chtholly_motion` | n° 7 |
| 2 | `assets/characters/tiat/tiat_motion.png` + `.json` (et `_front`, `_back`) | 106 px | `repos` 2 à 2 (copie) ; `repos_vivant` 5 à 3 ; `depart` 2 à 12 (non) ; `arret` 2 à 12 (non) ; `demi_tour` 3 à 16 (non) | Tiat : cheveux verts courts et ébouriffés, tunique verte à col blanc, bottines ; la plus enjouée du groupe : le clignement est vif, la respiration plus rapide, les mains toujours en mouvement ; ses mains sont vides | un objet dans les mains ; un personnage plus haut que 106 px ; la rangée `repos` redessinée ; une grosse tête sur un petit corps | `tiat` (trois vues), `chtholly_motion` | n° 7 |

### B.4 Pannibal, Collon, Lakhesh, Almita, Nygglatho (priorité 3)

Le reste de la distribution. **Jeu court** comme en B.3. Les planches de Pannibal, Collon, Lakhesh et Almita sont de petits personnages : respecte leur hauteur debout au pixel près.

**Références à joindre** : les trois vues de la planche existante de chaque personnage de la ligne, puis `chtholly_motion` (trois vues) une fois livrée et validée.

| Prio | Planche (profil ; `_motion_front` et `_motion_back` à côté) | Hauteur debout | Rangées (images à ips) | Apparence et consignes propres | À ne pas faire | Joindre | Réf. |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3 | `assets/characters/pannibal/pannibal_motion.png` + `.json` (et `_front`, `_back`) | 120 px | `repos` 2 à 2 (copie) ; `repos_vivant` 5 à 3 ; `depart` 2 à 12 (non) ; `arret` 2 à 12 (non) ; `demi_tour` 3 à 16 (non) | Pannibal : cheveux violets mi-longs, capuche et vêtement bleu nuit, un bâton de bois porté dans le dos du même côté dans toutes les images ; il se tient un peu voûté, les mains dans les poches ou serrées contre lui, le regard fuyant : le clignement est lent | un bâton qui change de côté ; un bâton sous la ligne des pieds ; un personnage plus haut que 120 px ; la rangée `repos` redessinée | `pannibal` (trois vues), `chtholly_motion` | n° 7 |
| 3 | `assets/characters/collon/collon_motion.png` + `.json` (et `_front`, `_back`) | 115 px | `repos` 2 à 2 (copie) ; `repos_vivant` 5 à 3 ; `depart` 2 à 12 (non) ; `arret` 2 à 12 (non) ; `demi_tour` 3 à 16 (non) | Collon : cheveux roses relevés en chignon avec un bandeau rouge, vêtement clair rosé, bottines ; elle attend sagement, mains jointes devant elle ; le chignon et le bandeau bougent d'1 px en retard sur la tête | un chignon qui change de côté ; un personnage plus haut que 115 px ; la rangée `repos` redessinée | `collon` (trois vues), `chtholly_motion` | n° 7 |
| 3 | `assets/characters/lakhesh/lakhesh_motion.png` + `.json` (et `_front`, `_back`) | 115 px | `repos` 2 à 2 (copie) ; `repos_vivant` 5 à 3 ; `depart` 2 à 12 (non) ; `arret` 2 à 12 (non) ; `demi_tour` 3 à 16 (non) | Lakhesh : cheveux saumon noués en deux chignons, robe brune à volants crème, bottines ; elle respire lentement, un peu raide ; les chignons restent symétriques et bougent ensemble | des chignons qui bougent de façon indépendante ; un personnage plus haut que 115 px ; la rangée `repos` redessinée | `lakhesh` (trois vues), `chtholly_motion` | n° 7 |
| 3 | `assets/characters/almita/almita_motion.png` + `.json` (et `_front`, `_back`) | 91 px | `repos` 2 à 2 (copie) ; `repos_vivant` 5 à 3 ; `depart` 2 à 12 (non) ; `arret` 2 à 12 (non) ; `demi_tour` 3 à 16 (non) | Almita : la plus petite : cheveux blonds courts, tablier gris clair sur une robe sombre, bottines ; ses mouvements sont courts et vifs, le poids passe d'un pied à l'autre dès qu'elle attend ; ne pas agrandir la tête pour la rendre mignonne | une grosse tête ; un personnage plus haut que 91 px ; la rangée `repos` redessinée | `almita` (trois vues), `chtholly_motion` | n° 7 |
| 3 | `assets/characters/nygglatho/nygglatho_motion.png` + `.json` (et `_front`, `_back`) | 178 px | `repos` 2 à 2 (copie) ; `repos_vivant` 5 à 3 ; `depart` 2 à 12 (non) ; `arret` 2 à 12 (non) ; `demi_tour` 3 à 16 (non) | Nygglatho : grande, cheveux longs ondulés, serre-tête de bonne, robe noire à tablier blanc : **cheveux et tenue exactement ceux de la planche jointe la plus récente** (la précision artistique du 16 octobre 2026 du cahier n° 6 vaut : bonne noire et blanche, cheveux rose saumon, yeux verts, si la planche jointe l'a déjà reprise). Les jambes se cachent sous la jupe : le **pas se lit par le balancement de la jupe** (le bas de la jupe avance d'un demi-pas avant les pieds) et les bouts de chaussures ; elle se tient très droite, les mains jointes devant le tablier ; ses cheveux ont un temps de retard et un grand débattement | des jambes visibles à travers la jupe ; une jupe rigide ; un personnage plus haut que 178 px (cheveux compris) ; la rangée `repos` redessinée ; un mouvement brusque (elle est composée) | `nygglatho` (trois vues), `nygglatho_life`, `chtholly_motion` | n° 7 |

## 6. Livrer et vérifier

### 6.1 Liste de contrôle de la livraison

1. Pars de la **dernière version de `main`**.
2. Dépose chaque image à son **chemin exact** (colonne « Fichier ») ; pour une planche de mouvement, les trois PNG et les trois JSON (`<id>_motion`,
   `_motion_front`, `_motion_back`). **Ne livre que les fichiers de ce document** : ni sources, ni galeries, ni aperçus, ni outils, ni code, ni autre
   personnage, **ni changement des fichiers existants** (les planches `<id>.png` et leurs JSON restent intactes). **Une image livrée à son chemin exact remplace le
   remplaçant du même nom, sans changer le code.**
3. Lance `python3 tools/hd2d_assets.py check` : pour chaque image **inscrite au manifeste** (`tools/hd2d_manifest.json`) il vérifie la taille exacte, l'opacité, l'alpha net,
   l'ancrage, les décalques, les raccords. **Il voit les 37 remplaçants repris** (A.1 à A.3), pas les images nouvelles ni les planches : elles ne sont inscrites au manifeste
   que par les lots du moteur qui les posent (clé `lot` proposée : `N7A` pour le décor, `N7B` pour les planches). **Contrôle donc à la main** les images nouvelles avec le script
   6.2, et les planches avec le script 6.3.
4. Lance `python3 tools/hd2d_sheets.py strip <aperçu.png> <json>` sur chaque planche de mouvement : il trace la ligne du sol, l'axe de l'ancre et la hauteur debout ; **mesure le
   pas sur cet aperçu** (3.3).
5. Une image trop grande se ramène à sa taille par `python3 tools/hd2d_assets.py fit <fichier>` (pour les images inscrites au manifeste) ; une nouvelle tuile de sol demande
   `python3 tools/hd2d_assets.py atlas` (ce cahier n'en commande aucune).
6. `tools/import.sh` (il crée les `.import` des nouvelles images, à livrer avec elles), puis `tools/check.sh`.
7. Note la provenance en bas de `assets/CREDITS.md` (et de `assets/characters/CREDITS.md` pour les planches) : « généré avec ChatGPT le …, cahier n° 7, lot … ».
8. Dans la description de la PR : les fichiers livrés, ceux qui manquent, les écarts connus (taille, cadrage, côté d'un accessoire, pas mesuré), et ce qui est **produit**,
   **contrôlé techniquement**, **placé dans le jeu** et **validé en jeu** : l'état des lots ne change qu'après la livraison effective.


### 6.2 Contrôle des images de ce document

Ce script lit les tableaux de ce fichier, et pour chaque image listée vérifie qu'elle existe, sa taille exacte (celle de la colonne « Taille »), son mode RGBA, son alpha net
(sauf « alpha doux »), l'opacité de ce qui doit l'être.

```text
python3 -I - docs/ASSETS_HD2D_ILE68_LIVRAISON7.md <<'PY'
import os, re, sys
from PIL import Image
n = bad = absent = 0
for line in open(sys.argv[1], encoding="utf8"):
    if not line.startswith("|"):
        continue
    c = [x.strip() for x in line.strip().strip("|").split("|")]
    if len(c) < 5:
        continue
    m = re.match(r"^`(assets/[^`\s]+\.png)`", c[1])
    s = re.search(r"fichier : (\d+) × (\d+)", c[2]) or re.match(r"^(\d+) × (\d+)", c[2])
    if not (m and s):
        continue
    p, want, n = m.group(1), (int(s.group(1)), int(s.group(2))), n + 1
    if not os.path.exists(p):
        absent += 1
        continue
    im = Image.open(p)
    a = im.convert("RGBA").getchannel("A")
    h = a.histogram()
    err = []
    if im.size != want:
        err.append("taille %dx%d au lieu de %dx%d" % (im.size + want))
    if im.mode != "RGBA":
        err.append("mode " + im.mode)
    if "alpha doux" not in c[3] and sum(h[1:255]) > 0.01 * a.width * a.height:
        err.append("alpha flou")
    if "opaque" in c[3] and h[255] != a.width * a.height:
        err.append("doit être opaque")
    if err:
        bad += 1
        print(p, " ; ".join(err))
print("%d image(s) listée(s), %d absente(s), %d à reprendre" % (n, absent, bad))
PY
```


### 6.3 Contrôle des planches de mouvement

`hd2d_sheets.py check` ne connaît pas encore les rangées de ce cahier. Ce script contrôle une planche de mouvement (les trois vues) : l'argument est l'identifiant du
personnage, puis `complet` ou `court` (section 3.2). Il vérifie les fichiers, les clés du JSON, le PNG (RGBA, taille égale à celle du JSON, alpha net), les rangées (noms, ordre,
nombres d'images, `ips`, `boucle`), les images dans la planche et non vides, l'ancre dans l'image (à 2 px près), la rangée `repos` **identique au pixel près** à la planche existante, la
1re image de `repos_vivant` identique à la 1re image de `repos`, la hauteur debout (jamais plus que H + 2 px ; la marche pas plus basse que 94 % de H), et les mêmes rangées dans les
trois vues. **Il ne mesure pas le pas** (3.3).

```text
python3 -I - chtholly complet <<'PY'
import json, os, sys
from PIL import Image
ident, kind = sys.argv[1], sys.argv[2]
IPS = {"chtholly": (18, 17), "willem": (15, 15)}
if kind == "complet":
    TABLE = {"repos": (2, 2, True), "repos_vivant": (6, 3, True), "marche": (8, IPS[ident][0], True),
             "course": (6, IPS[ident][1], True), "depart": (2, 12, False), "arret": (2, 12, False),
             "demi_tour": (3, 16, False)}
else:
    TABLE = {"repos": (2, 2, True), "repos_vivant": (5, 3, True), "depart": (2, 12, False),
             "arret": (2, 12, False), "demi_tour": (3, 16, False)}
KEYS = {"version", "echelle", "planche", "direction", "format", "animations"}
folder = os.path.join("assets", "characters", ident)
problems = []


def bad(view, msg):
    problems.append("%s%s : %s" % (ident, view or " (profil)", msg))


def top_of(img, rect):
    x, y, w, h = rect[:4]
    box = img.crop((x, y, x + w, y + h)).getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()
    return None if box is None else (box[1], box)


shape = {}
for view in ("", "_front", "_back"):
    jp = os.path.join(folder, "%s_motion%s.json" % (ident, view))
    pp = os.path.join(folder, "%s_motion%s.png" % (ident, view))
    bp = os.path.join(folder, "%s%s.json" % (ident, view))
    bq = os.path.join(folder, "%s%s.png" % (ident, view))
    if not (os.path.exists(jp) and os.path.exists(pp)):
        bad(view, "fichier absent")
        continue
    data = json.load(open(jp, encoding="utf8"))
    base = json.load(open(bp, encoding="utf8"))
    extra = set(data) ^ KEYS
    if extra:
        bad(view, "clés en trop ou manquantes : %s" % sorted(extra))
    img = Image.open(pp)
    if img.mode != "RGBA":
        bad(view, "mode " + img.mode)
    img = img.convert("RGBA")
    if list(img.size) != list(data.get("planche", [])):
        bad(view, "planche %s dans le JSON, PNG de %s" % (data.get("planche"), img.size))
    alpha = img.getchannel("A").histogram()
    if sum(alpha[1:255]) > 0.01 * img.width * img.height:
        bad(view, "alpha flou")
    anims = data.get("animations", {})
    if list(anims) != list(TABLE):
        bad(view, "rangées %s au lieu de %s" % (list(anims), list(TABLE)))
    shape[view] = {k: len(v["images"]) for k, v in anims.items()}
    bimg = Image.open(bq).convert("RGBA")
    bh = None
    for name, (n, ips, loop) in TABLE.items():
        a = anims.get(name)
        if a is None:
            continue
        if len(a["images"]) != n:
            bad(view, "%s : %d images au lieu de %d" % (name, len(a["images"]), n))
        if a.get("ips") != ips:
            bad(view, "%s : %s ips au lieu de %s" % (name, a.get("ips"), ips))
        if a.get("boucle") != loop:
            bad(view, "%s : boucle %s au lieu de %s" % (name, a.get("boucle"), loop))
        if "coup" in a or "onde" in a:
            bad(view, "%s : coup ou onde en trop" % name)
        for i, r in enumerate(a["images"]):
            x, y, w, h, ax, ay = r
            if x < 0 or y < 0 or x + w > img.width or y + h > img.height:
                bad(view, "%s %d : hors de la planche" % (name, i))
                continue
            t = top_of(img, r)
            if t is None:
                bad(view, "%s %d : image vide" % (name, i))
                continue
            if not (-2 <= ax <= w + 2 and -2 <= ay <= h + 2):
                bad(view, "%s %d : ancre hors de l'image" % (name, i))
            stand = ay - t[0]
            if bh is None and name == "repos" and i == 0:
                bh = stand
            if bh is not None and name in ("repos_vivant", "marche", "course", "depart", "arret") and stand > bh + 2:
                bad(view, "%s %d : %d px, plus haut que la hauteur debout %d" % (name, i, stand, bh))
            if bh is not None and name == "marche" and stand < 0.94 * bh:
                bad(view, "marche %d : %d px, plus bas que 94 %% de %d" % (i, stand, bh))
    # repos identique à la planche existante
    for i, (r, b) in enumerate(zip(anims.get("repos", {}).get("images", []), base["animations"]["repos"]["images"])):
        c1 = img.crop((r[0], r[1], r[0] + r[2], r[1] + r[3]))
        c2 = bimg.crop((b[0], b[1], b[0] + b[2], b[1] + b[3]))
        if c1.size != c2.size or c1.tobytes() != c2.tobytes():
            bad(view, "repos %d : pas identique à la planche existante" % i)
    if "repos_vivant" in anims and "repos" in anims:
        r, v = anims["repos"]["images"][0], anims["repos_vivant"]["images"][0]
        c1 = img.crop((r[0], r[1], r[0] + r[2], r[1] + r[3]))
        c2 = img.crop((v[0], v[1], v[0] + v[2], v[1] + v[3]))
        if c1.size != c2.size or c1.tobytes() != c2.tobytes():
            bad(view, "repos_vivant 0 : pas identique à repos 0")
if len({str(v) for v in shape.values()}) > 1:
    problems.append("%s : les trois vues n'ont pas les mêmes rangées ni les mêmes nombres d'images" % ident)
for p in problems:
    print(p)
print("%s : %d problème(s)" % (ident, len(problems)))
PY
```

Pour voir ce qui est mesuré : `python3 tools/hd2d_sheets.py strip <aperçu.png> assets/characters/<id>/<id>_motion.json`.


## 7. Ce qui attend le moteur (formats à confirmer)

Tout ce qui suit est **commandable tout de suite** : seul l'usage dans le jeu attend la décision du lot du moteur concerné.

| Format | Images | Lot du moteur | État au 16 octobre 2026 |
| --- | --- | --- | --- |
| **Planches de mouvement** `<id>_motion` : une planche **complémentaire** (trois vues) à côté de la planche existante ; rangées `repos_vivant`, `depart`, `arret`, `demi_tour` et, pour Chtholly et Willem, **`marche` et `course` de remplacement** (8 images à 18 ou 15 ips, 6 images à 17 ou 15 ips) | 10 planches (lot B) | AN (animation, `src/player/`, `CharacterVisual`) | **proposé** : noms des rangées, fusion avec la planche existante (une planche complémentaire dont les rangées `marche` et `course` remplacent celles de la base), cadences ajustées au pas dessiné (`walk_speed` 3,1 m/s, course 5,75 m/s), sens du `demi_tour` (le jeu retourne l'image entre le pivot et la relance), inscription aux `sheets` du manifeste et tableau `motion` de `hd2d_sheets.py` ; les planches de tenue (`_home`, `_rain`…) n'ont pas de mouvement propre : à décider |
| Premiers plans peints `fg_*` (10 images, A.5) | 10 | RD (profondeur) | l'image est une **image ordinaire collée au bord bas** (aucun format nouveau) ; le moteur la pose au sud du joueur et la floute selon la profondeur ; le drapeau `soft_alpha` du manifeste à ajouter à l'inscription |
| Lisières de second rang `treeline_back_*` | 4 | RC (recettes) | image ordinaire (`wrap x`), à poser derrière le premier rang |
| Lèvres, angles et pieds de talus `decals/bank_*` | 9 | RC et SOL | décalques ordinaires ; **`GroundDecal` doit pouvoir les tourner par quarts de tour** (les angles) et les enchaîner (les lèvres : `wrap x`) |
| Haies `thicket_d` à `f` | 3 | RC | les versions `_fg` (premier plan) sont des **scènes du jeu** qui réutilisent la même image (`foreground = true`) : aucune image en plus |
| Variantes de garde-corps, de muret et de clôtures (règle du poteau coupé en deux) | 11 | RC | `PropScatter` doit tirer **parmi les variantes** d'une famille ; sans ça, on retombe sur le copié-collé |
| Les 38 images reprises du n° 6 | 38 | — | déjà inscrites au manifeste (37 remplaçants) ; l'image de nuit `village_house_stone_night.png` s'inscrit à la pose |

## 8. Écarts relevés, et ce que ce cahier tranche

| Écart | Ce que ce cahier a décidé |
| --- | --- |
| Le pas actuel de Chtholly (environ 0,45 m) et une marche de 8 images à 3,0 à 3,2 m/s : le calcul de la 3.3 | **incohérent** (3.3) : 27,6 ips, 6,9 pas par seconde. On retient un pas de **0,70 m** (8 images, 18 ips, 3,15 m/s) ; le pas de 0,45 m n'est gardé que pour les personnages de la foule, qui marchent à 1,3 m/s |
| Le tableau `life` de `hd2d_sheets.py` et les planches livrées donnent une course de **5 images** | **6 images** : un cycle de course a deux foulées symétriques, ce qu'un nombre impair ne permet pas ; le moteur adapte son tableau |
| Le cahier n° 6 (8.1) dit que les images ne sont inscrites au manifeste que par les lots du moteur ; on pourrait les inscrire dès la commande | **ce n'est pas l'usage** : ce cahier n'ajoute **aucune** entrée au manifeste (un remplaçant exige une recette de dessin dans `tools/`, hors du périmètre d'un cahier). Les 37 remplaçants repris y sont déjà ; les 52 images nouvelles s'inscrivent à la pose, par le lot du moteur |
| Les JSON des planches existantes portent des clés de suivi (`status`, `anchors_validated`, `anchor_method`…) | les planches de mouvement **n'en portent aucune** (règle du bloc de style) : le moteur lit uniquement `version`, `echelle`, `planche`, `direction`, `format`, `animations` |
| Le n° 6 range `town_roofs_a` et `town_roofs_b` en priorité 3 et le lointain `town_roofs_far` avec eux | `town_roofs_a` et `_b` passent en priorité 2 (la ville haute a besoin d'un fond) ; `town_roofs_far` reste au n° 6 |
| Le n° 6 (D.2) attend l'accord du moteur pour le premier plan **suspendu** (`fg_canopy_a`, `_b`) | non commandé ici : les premiers plans de A.5 **touchent tous le bord bas** et ne demandent aucun accord |
| L'audit voit `fence_wattle` (clôture de branches du village) posée 44 fois dans la ville haute, et aucun cahier ne commande de clôture de ville | la ville a **sa** clôture (`town_fence_a` et `_b`) ; la clôture de branches reste celle du village |

## 9. Comptes du cahier

- **Lot A** : 89 images dont 38 prio 1, 40 prio 2, 11 prio 3 ; 37 remplaçants repris du n° 6, 52 images nouvelles.
- **Lot B** : 10 planches de mouvement (30 PNG, 30 JSON), 450 images dessinées en tout (150 par vue) ; Chtholly (prio 1) 81, prio 2 (4 planches) 189, prio 3 (5 planches) 180.
- **Total** : 119 fichiers PNG.

