# Cahier des charges n° 6 : l'île n° 68, la série suivante

Ce document se donne à ChatGPT (ou à Codex), **lot par lot**, et se suffit à lui-même : il n'y a aucun autre
fichier à lire. Il est établi le 15 octobre 2026 d'après l'état du dépôt (`ab149ec`, après la PR n° 44), par un
inventaire fait par script de ce que le jeu utilise, comparé à ce que `assets/` contient : il commande **tout ce qui
manque encore** à l'île n° 68, trié par l'usage qu'en fait le jeu, et rien de plus. Il **remplace**, pour les
commandes encore ouvertes, le cahier n° 5 (`docs/ASSETS_HD2D_ILE68.md`), dont les lots R0 (tables, meubles et vues de
flanc), R1 (l'entrepôt) et la plus grande partie de R2 (les personnages de l'acte 1) sont livrés ; il en reprend,
corrigées par les livraisons et par le jeu, les consignes qui restent à servir. Ce que le dessin dit des lieux et
des gens vient de l'œuvre, d'après les dossiers du canon (`docs/lore/canon/`), **paraphrasé** : le dépôt est public,
on ne recopie jamais les volumes ; ce que l'œuvre ne dit pas est marqué **(original)**.

| Cahier | Fichier | État au 15 octobre 2026 |
| --- | --- | --- |
| n° 1 | `docs/ASSETS_HD2D.md` | livré ; sa section 12 est intégrée à ce document |
| n° 2 | `docs/ASSETS_HD2D_MONDE.md` | livré |
| n° 3 | `docs/ASSETS_HD2D_SUKASUKA.md` | livré en partie ; le reste a été repris au n° 5, puis ici |
| n° 4 | `docs/ASSETS_HD2D_COMPLEMENTS.md` | livré en entier |
| compléments | `docs/ASSETS_HD2D_NAVIRES.md` | livré (50 images : silhouettes et intérieurs de bord) |
| n° 5 | `docs/ASSETS_HD2D_ILE68.md` | R0 et R1 livrés, R2 livré en partie (PR n° 34, 35, 37, 39, 43) ; **le reste est repris ici** |
| **n° 6** | `docs/ASSETS_HD2D_ILE68_LIVRAISON6.md` | **ce document** |

## 0. Mode d'emploi

1. Lis la section 0.1 : **quatre lots**, dans l'ordre du jeu, avec le nombre d'images de chacun.
2. Choisis un lot, puis **un groupe** de ce lot (A.1, A.2, …) : un groupe est une conversation.
3. Dans la conversation, **colle dans l'ordre** : le bloc de style (section 1) ; le rappel du format (section 2 pour
   des images, section 3 pour des planches de personnages ou d'animaux) ; le tableau du groupe ; puis joins les
   images de « Références à joindre ».
4. Pour chaque ligne du tableau, demande : « Image `<chemin>`, `<taille>` px, `<genre et ancre>` : » suivi de la
   **consigne**, en rappelant la colonne **À ne pas faire**. Pour une planche : la formule de la section 3.1.
5. Vérifie chaque livraison avec la section 8 avant de la déposer ; ne livre que les fichiers de la liste.

### 0.1 Ce que ce cahier commande : quatre lots

Les lots sont classés **par l'usage qu'en fait le jeu** ; la priorité d'une ligne (1, 2 ou 3) est celle **dans son
lot** : 1 = sans cette image, une scène ou une carte se joue avec un repli visible (remplaçant, sprite d'un autre
personnage) ; 2 = la densité et la vie du lieu ; 3 = le bonus.

| Lot | Section | Contenu | Images | Planches | Fichiers PNG | Prio 1 | Prio 2 | Prio 3 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **A** | 4 | les jours 1 à 4 : le port, le sentier de nuit, la ville haute, le snack-bar | 58 | 8 | 82 | 20 images, 2 planches | 32 images, 6 planches | 6 images |
| **B** | 5 | l'existant qui se voit tout de suite : façades de nuit, village, signes, talus, fées de la foule | 13 | 4 | 25 | 8 images | 4 images, 4 planches | 1 image |
| **C** | 6 | la phase 3 (jours 5 à 12) : navire, pluie, colline, village, café, maison Limashenka, bâton, ballon | 69 | 21 | 128 | 16 images, 7 planches | 40 images, 14 planches | 13 images |
| **D** | 7 | le reste : navires, formats en attente, ville, forêt, montagne, faune, gens, reprises | 85 | 29 | 156 | — | 14 images | 71 images, 29 planches, 6 reprises |
| **Total** | | | **225** | **62** (+ 6 reprises) | **391** | | | |

Une **planche de personnage** compte pour trois PNG et trois JSON (profil, face, dos) ; une **planche de faune** pour un PNG et un JSON ; une **reprise** corrige une planche déjà livrée (aucun fichier nouveau). Les images comptées sont celles à **dessiner** : 58 sont encore des remplaçants dessinés par les outils du jeu (le fichier livré les remplace au même nom), 165 sont absentes, 2 sont des images livrées à refaire (`cart_ruts`, `footprints`).


- **Lot A, priorité absolue : les jours 1 à 4 de l'acte 1** (`docs/lore/ACTE1.md` ; scènes `data/scenes/ile_68/`).
  Le port (`CARTE.md` 6.2), le sentier de nuit, la ville haute avec le snack-bar (`CARTE.md` 9.2 et 9.4) se
  construisent en ce moment avec des remplaçants : ce lot donne **toutes leurs images** (façades, décors, sol, gens).
- **Lot B : ce qui se voit tout de suite dans l'existant** (registre de qualité `docs/QUALITE.md`, gravité 1 ;
  remplaçants au premier rang d'une carte déjà jouable) : pas de dépendance, peu d'images, un effet immédiat.
- **Lot C : la phase 3** (jours 5 à 12) : le transport de la Garde et le quai, la pluie, la colline des étoiles, le
  village, le café, la maison Limashenka, le bâton, le ballon, les tenues de pluie.
- **Lot D : le reste** : navires en volume (autres vues), ce qui attend un accord du moteur, la ville entière, la forêt
  profonde, la montagne, la faune, les gens de la ville, quelques reprises de planches livrées.

**Ordre de commande conseillé.** (1) **B.3 et B.1** tout de suite : peu d'images, effet immédiat. (2) **Lot A** dans
l'ordre du jeu : A.2 et A.1 (jour 1), A.3, puis A.6, A.4, A.5 et A.7 (jour 3) ; le lot B en parallèle. (3) **Lot C** :
C.10 (les planches de priorité 1 : ballon, bâton, geste du serveur), C.2, C.1 et C.3 (jours 7 et 8), puis C.5 à C.7
(jours 9 et 11). (4) **Lot D** : D.1, D.4, D.5 et D.9, puis le reste ; D.2 seulement après l'accord du moteur.

### 0.2 Ce qui est déjà livré (à ne pas redemander, à ne jamais retoucher)

| Livraison | Contenu | PR |
| --- | --- | --- |
| cahier n° 5, **R0** (54 images : R0.2 à R0.7) | tables, comptoirs, chaises, canapé et bureau refaits en projection oblique, 23 vues de flanc, 4 vues de dos, 5 lits vus par le pied, 6 meubles de la maison Limashenka et de la librairie, bancs et passerelle | n° 34 et n° 35 |
| cahier n° 5, **R1** (39 images) | l'entrepôt : façades et flancs (quatre), toit et sol du toit, vapeur, horloge, cristal d'appel, chambranle, sols et murs de la crypte, fourrés, haie, aulne, souche, bureaux, plante, tréteau | n° 37 (l'intégration par le moteur : n° 36) |
| cahier n° 5, **R2 priorité 1** (10 planches) | `willem_marsh`, `willem_carry`, `willem_piggyback`, `nygglatho_labcoat`, `snack_vendor_work`, `chtholly_pajamas`, `kana`, `giniette`, `fairy_11`, `fairy_12` | n° 39 |
| cahier n° 5, **R2 pyjamas** (3 planches) | `almita_pajamas`, `ithea_pajamas`, `nephren_pajamas` | n° 43 |
| cahiers n° 1 à 4 et compléments | tout le reste de `assets/` : le manifeste compte 761 images (dont 58 sont encore des remplaçants : elles sont **toutes** dans ce cahier) et 54 planches contrôlées ; 24 accessoires et 50 images de bord | n° 1 à 30 |

Les 13 planches de R2 sont dans `assets/characters/` ; elles ne sont pas encore inscrites aux `sheets` du manifeste
ni posées dans le jeu (travail du moteur, pas du dessinateur). `willem_carry` et `willem_piggyback` sont des planches
composites préparatoires approuvées. **Rien de cela ne se redemande.**

Les commandes du cahier n° 5 qui ne sont **pas** dans ce document sont soit livrées (ci-dessus), soit **annulées** :
la correction des vitres de l'entrepôt (n° 5, 3.6 : le moteur règle la couleur de lueur par bâtiment,
`Building.window_glow_color`), la demande du lot R0.10 (ses cinq images sont au lot B), les effets `fx/shadow`,
`fx/glow`, `fx/light_pool` et `fx/rain_drop` (le jeu les génère).

### 0.3 Découper et joindre (règles de découpe)

1. **Une conversation par groupe** (A.1, A.2…), ou par moitié de groupe s'il dépasse une douzaine d'images : colle le
   bloc de style, le rappel, le tableau du groupe, joins les références. Chaque groupe se suffit avec le bloc de style.
2. **La priorité 1 d'abord**, dans chaque conversation, puis les priorités 2 et 3 ; ne passe jamais au lot suivant
   avant la livraison vérifiée du lot en cours (sauf accord de l'utilisateur).
3. **Un bâtiment = une façade, puis son flanc dans la même conversation**, en joignant la façade finie au flanc ; une
   version de nuit se commande **après** la version du jour, en joignant celle-ci.
4. **Un meuble = sa face d'abord**, puis ses autres vues dans la même conversation (flanc tourné vers l'est, dos, par
   le pied) ; la projection est celle de la section 2.3.
5. **Une bande animée à part**, une bande à la fois, en joignant l'image du meuble, du bras ou du lieu qu'elle anime ;
   le pied de ce qui est animé reste immobile au pixel près.
6. **Une planche de personnage par conversation**, dans l'ordre : le **profil** d'abord ; la **face** puis le **dos**
   ensuite, en joignant le profil fini (« même personnage, même hauteur, mêmes animations, vu de face »).
7. **Donne toujours la hauteur debout en pixels**, pas seulement en mètres, et rappelle-la à chaque correction (« la
   1re image de `repos` mesure 115 px de l'ancre au sommet des cheveux »).
8. **Fais dessiner sur un gabarit** : des cases de même taille, une ligne de sol commune à toute la rangée, un trait à
   la hauteur debout ; puis fais effacer le gabarit. Une planche complémentaire part de la rangée `repos` recopiée.
9. **Pour les familles** (fées génériques, hommes-bêtes d'une même espèce, maisons d'une rue, animaux) : d'abord une
   planche d'ensemble, côte à côte à l'échelle, puis chaque élément à part : formes vraiment différentes, même rendu.
10. **Une animation à la fois** si la planche dérive : demande la rangée seule, vérifie-la, puis assemble les rangées
    dans l'ordre du tableau. Nomme le **côté** des accessoires dans chaque demande (« la couette du côté gauche de sa
    tête : à droite de l'image de face, à gauche de l'image de dos »).
11. **Joins toujours les images déjà livrées** du même lieu ou du même personnage (même palette, mêmes contours) ; ne
    laisse pas l'outil « améliorer » une image existante : une rangée recopiée reste identique au pixel près.
12. **Après toute correction, repasse toute la vérification** : une vue redessinée pour un détail change souvent
    d'échelle ailleurs.

### 0.4 Ce que ce cahier ne commande pas

- les 24 accessoires du cahier n° 4, les 50 images de bord, les effets `fx/shadow`, `fx/glow`, `fx/light_pool`,
  `fx/rain_drop` (générés par le jeu) ;
- les images de l'ancienne île seule (palissade, arène, Couchant, dunes), de la surface et des autres îles ;
- les portraits des habitants de métier (facultatifs, `<id>_portrait.png`, 256 × 256) ;
- les vues de face et de dos des animaux (le moteur ne lit que le profil) ;
- `willem_life.lance` : le moteur n'a demandé qu'**un** geste de pied à Willem, `frappe`. (La planche de duel de
  Willem avec le Carillon Percival est commandée en C.10 : décision de l'utilisateur du 15 octobre 2026.)

## 1. Bloc de style v6 (à coller au début de chaque conversation)

C'est le bloc v5 du cahier n° 5 (projection oblique des meubles, pointe d'arme au-dessus de la ligne des pieds, JSON
sans clé de suivi, rien de retouché ni de renommé), auquel s'ajoutent les **leçons des livraisons** (les erreurs
relevées sur les cahiers n° 1 à 5 : échelle des animations, silhouettes doublées, accessoires qui changent de côté,
cotes ignorées, fichiers en trop, coutures, bouts coupés, vitres allumées en orangé).

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
| Livraison | seulement les fichiers listés, à leur chemin exact (section 8) |

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

**Les trois sortes de planches de ce cahier** :

| Sorte | Nom | Ce qu'elle contient |
| --- | --- | --- |
| **Complémentaire ou de geste** | `<id>_life`, `<id>_work`, `willem_repair`… | pour un personnage déjà livré qui garde sa tenue : sa 1re rangée est `repos`, **recopiée au pixel près** de la planche existante de la même vue (c'est l'étalon de taille, ne la redessine pas), puis seulement les animations nouvelles |
| **De tenue** | `<id>_rain`, `<id>_pajamas`, `<id>_stick` | le même personnage dans une autre tenue : planche complète, avec ses propres `repos`, `marche` et `parle`, à la même hauteur debout, mêmes cheveux, même visage, mêmes couleurs |
| **Neuve** | `fairy_07`, `porter`, `villager_cat_m`… | un personnage qui n'a pas encore de planche |

Toutes les planches ont leurs trois vues (`<id>`, `<id>_front`, `<id>_back`) et leurs trois JSON, dans
`assets/characters/<dossier>/`. Une planche de tenue ou de geste va dans le dossier du personnage.

**La formule de la demande** : « Planches de sprites `assets/characters/<dossier>/<id>.png` (profil tourné vers la
droite), `<id>_front.png` (de face) et `<id>_back.png` (de dos), avec leurs JSON, fond transparent, mêmes animations et
nombres d'images dans les trois vues, une rangée par animation dans l'ordre du tableau, une seule silhouette par case,
hauteur debout **<n> px** dans toutes les images debout et les trois vues : » puis la ligne du tableau.

**Références à joindre** : les trois vues existantes du personnage ; pour une planche neuve, deux planches livrées de
même genre (une petite fée : `tiat.png` et `lakhesh.png` ; un homme-bête : `cat_waiter.png` et `baker.png`).

### 3.2 La fiche des animations, image par image

La fiche commune ; chaque planche y ajoute ses consignes propres.

| Animation | Images | ips | Boucle | Consigne commune |
| --- | --- | --- | --- | --- |
| `repos` | 2 | 2 | oui | debout, le poids sur les deux pieds, bras le long du corps ou tenant l'objet de la tenue ; image 1 : épaules soulevées d'1 px, cheveux qui bougent d'1 px (respiration) ; pieds immobiles |
| `marche` | 6 | 10 | oui | cycle de marche complet (contact, passage, contact de l'autre pied…), bras opposés aux jambes, tête qui monte et descend d'1 à 2 px, jamais plus grande que `repos` |
| `parle` | 2 | 6 | oui | debout comme `repos`, pieds à la même place ; image 0 bouche fermée, image 1 bouche ouverte et petit geste de la main |
| `course` | 5 | 14 | oui | course penchée en avant, grandes foulées, un instant où les deux pieds quittent le sol, bras pliés qui balancent ; la tête jamais plus haute que la hauteur debout |
| `saut` | 4 | 12 | non | 0 élan accroupi, bras en arrière ; 1 détente, bras levés, pieds qui quittent le sol ; 2 au plus haut, genoux repliés (le corps monte dans la case, l'ancre reste au sol) ; 3 réception accroupie |
| `frappe` | 4 | 14 | non | 0 élan, la jambe de frappe en arrière ; 1 pied d'appui planté à côté du ballon ; 2 **frappe** : la jambe de frappe tendue devant, à 20 cm du sol (`coup`) ; 3 accompagnement, bras écartés pour l'équilibre ; **le ballon n'est pas dessiné** (le jeu le pose) |
| `lance` | 4 | 12 | non | lancer à deux mains par-dessus la tête : 0 ballon de cuir (20 cm) tenu à deux mains devant le ventre ; 1 ballon derrière la tête, dos cambré ; 2 **lâcher** : bras tendus en avant au-dessus de la tête, le ballon vient de partir et n'est plus dessiné (`coup`) ; 3 suivi, buste penché |
| `grimpe` | 4 | 8 | oui | grimper à un tronc **non dessiné** : de dos (la vue principale), bras et jambes qui s'agrippent en alternance, le corps qui se hisse ; de profil, le tronc invisible juste à droite du personnage ; de face, comme de dos mais vu de face ; l'ancre est sous le pied le plus bas |
| `assis` | 2 | 2 | oui | assis sur un siège **non dessiné** dont l'assise est à 45 cm (43 px au-dessus de l'ancre) : cuisses horizontales, dos droit, mains sur les genoux ; les petites laissent pendre les pieds ; image 1 : respiration ; l'ancre est au sol sous le milieu de l'assise |
| `lit` | 2 | 2 | oui | assis comme `assis`, un livre ouvert tenu à deux mains ; image 1 : une page qui se soulève, les yeux qui descendent |
| `dort` | 2 | 1 | oui | couché sur le côté sur une surface **non dessinée** (lit, canapé, herbe), la tête à gauche de l'image, genoux un peu repliés, une main sous la joue ; image 1 : respiration (1 px) ; l'ancre au milieu du corps, sur la surface ; **les trois vues reprennent la même image couchée** (recopiée telle quelle) |
| `tombe` | 4 | 10 | non | chute en avant à plat ventre : 0 le pied accroche, buste en avant, bras qui partent ; 1 en l'air, presque à l'horizontale ; 2 impact, à plat ventre, bras écartés ; 3 étalée, la joue contre le sol, les jambes qui retombent (V1 : l'avalanche ; V2 : l'embuscade ratée, le nez rouge) ; ni sang, ni larmes |
| `porte` | 6 | 10 | oui | le cycle de `marche`, en portant l'objet de la planche (dessiné) à deux mains devant soi ou sur l'épaule ; l'objet monte et descend avec le corps |
| `travaille` | 4 | 6 | oui | le geste de métier de la planche, sur place (pieds immobiles), avec l'outil dessiné ; l'objet travaillé (marmite, plafond, table) n'est pas dessiné, sauf s'il tient dans les mains |
| `effondre` | 4 | 8 | non | 0 chancelle, une main sur la poitrine ; 1 un genou à terre ; 2 assis lourdement, le buste qui part en arrière ; 3 étendu au sol, immobile (V1, « Les valeureux… » : Willem s'effondre après le duel) ; ni sang |
| `hanches` | 2 | 2 | oui | debout, les poings sur les hanches, le buste un peu penché en avant, moue sévère ; image 1 : un hochement de tête d'1 px |
| `attaque` | 4 | 14 | non | (cahier n° 1, 3.1) coup d'arme de haut en bas ; `coup` : [1, 2, 3] |
| `etreinte` | 4 | 8 | non | **nom proposé, à confirmer par le moteur** : 0 bras qui s'ouvrent ; 1 elle se penche ; 2 et 3 les bras refermés sur une personne **non dessinée** devant elle (à droite), sourire |

### 3.3 Les hommes-bêtes : passants, métiers, Garde

Rangées des **passants** : `repos` (2, 2), `marche` (6, 10), `parle` (2, 6), `course` (5, 14), `assis` (2, 2). Rangées
des **métiers** : celles des passants, plus `travaille` (4, 6, leur geste) et, quand la ligne le dit, `porte` (6, 10, leur
objet). Les **marchands de passage** n'ont que `repos`, `marche`, `parle`, `assis` ; les gens de la **Garde**, `repos`,
`marche`, `parle`, `porte`. Une queue reste du même côté dans toutes les images et ne passe jamais sous la ligne des
pieds. Joindre `assets/characters/cat_waiter/cat_waiter.png`, `baker.png`, `snack_vendor.png` pour le rendu, la palette
et les proportions.

### 3.4 La faune (planches de profil seul)

Animations (`docs/REFONTE.md`, 8.1 ; nombres d'images et cadences **confirmés par le moteur**) : `repos`, `marche`,
`course` pour tous ; `attaque` (avec `coup`), `degats` et `mort` pour les bêtes dangereuses ; `fuite` (envol, bond) pour
les oiseaux et le petit gibier ; `broute` pour les paisibles. La « hauteur au repos » est celle de la 1re image de
`repos`, de l'ancre (le sol sous les pattes) au point le plus haut de la silhouette (oreilles, bois).

| Animation | Images | ips | Boucle | Consigne commune |
| --- | --- | --- | --- | --- |
| `repos` | 2 | 2 | oui | à l'arrêt sur ses pattes, la tête qui bouge un peu (oreille, regard), respiration |
| `marche` | 6 | 8 | oui | pas lent à quatre pattes (pattes en diagonale) ; oiseaux et grenouille : 4 images de petits sauts |
| `course` | 5 | 14 | oui | galop, pattes rassemblées puis étendues ; oiseaux et grenouille : 4 images de bonds rapides |
| `attaque` | 4 | 12 | non | 0 ramassé ; 1 élan ; 2 **coup** (coup de patte, morsure, coup de boutoir) ; 3 retour ; `coup` : [2] |
| `degats` | 1 | 1 | non | touché, il recule, tête rentrée |
| `mort` | 2 | 4 | non | 0 il vacille ; 1 couché sur le flanc, immobile, les yeux fermés ; aucun sang |
| `fuite` | 4 | 12 | oui (oiseaux), non (les autres) | oiseaux : envol puis battements d'ailes sur place (le jeu le déplace) ; renard, écureuil : grand bond vers la droite ; grenouille : plongeon |
| `broute` | 4 | 4 | oui | la tête baissée au ras du sol, il broute, relève la tête à l'image 3 |

Pour la faune, joins `assets/characters/tiat/tiat.png` pour le contour et l'ombrage.

## 4. Lot A : les jours 1 à 4 (le port, le sentier de nuit, la ville haute, le snack-bar)

**Total du lot A : 58 images et 8 planches de personnages ou d'animaux.**

**Pourquoi ce lot d'abord.** L'acte 1 se joue en jours (`docs/lore/ACTE1.md`). Les jours 1 à 4 ont besoin, en plus de
l'entrepôt (livré en entier : R0 et R1), de trois cartes que le moteur construit en ce moment avec des remplaçants : le
**sentier** (jour 1, de nuit : l'embuscade de Pannibal, Willem qui tombe dans le marais ; scènes 1.2 à 1.4), le **port**
(jour 1 : Willem débarque, le panneau aux flèches rouges ; scène 1.1) et la **ville haute** avec le **snack-bar** (jour 3 :
le déjeuner ; scènes 3.2 et 3.3). Les planches des personnages de ces quatre jours sont livrées (R2) ; il reste les images de
ces lieux et les gens du port et de la ville. **Ce lot n'attend rien** ; les lots B, C et D s'appuient sur lui.

**Ce que disent les sources.** *Le port* : la rue du port, au bord du vide, porte un panneau usé par les vents violents, aux
flèches rouges (2 000 marmer vers la ville à droite, 500 vers l'entrepôt à gauche) ; le port garde ce qu'il faut aux
dirigeables ; on s'y tient au bord du vide et l'on voit, sous quelques nuages, la surface grise ; rampe, sifflet à vapeur,
charrettes de sacs qui filent sur l'aire-port ; une colline toujours ventée juste à côté (V1, « L'Homme sans Marque » ;
V2 ; V3). *La ville* : des centaines de bâtiments de pierre sur une légère pente, une atmosphère idyllique, des passants
qui ne se soucient pas qu'on n'ait pas de traits (V1, « Directeur en carton ») ; on y descend de l'entrepôt par un sentier ;
un vent froid ; la librairie, le café, le snack-bar du jeune lycanthrope qui fait sauter sa poêle (pommes de terre frites,
légumes, lard épais, petit pain, soupe dans une tasse). Le dessin des façades et des rues est **(original)** là où l'œuvre se
tait : de la pierre, de l'ardoise, des tuiles, du fer, aucune architecture asiatique.

**Les cartes qui attendent ces images** : `sentier` (`CARTE.md` 4.2), `port` (6.2), `ville_haute` (9.2), `ville_snack` (9.4).
Les façades de la ville sont **éteintes** (vitres sombres bleutées avec un reflet clair) ; les enseignes sont des objets
peints ou découpés (poêle, tasse, chapeau, mortier), **jamais des mots**.

### A.1 Le sentier de nuit et le marais (jour 1, scènes 1.2 à 1.4)

**Références à joindre** : `assets/hd2d/props/tree_autumn.png`, `assets/hd2d/props/willow.png`, `assets/hd2d/props/alder.png`, `assets/hd2d/props/marsh_snag.png`, `assets/hd2d/props/cattails.png`, `assets/hd2d/decals/lily_pads.png`, `assets/hd2d/ground/forest_floor.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/decals/bog_pool_a.png` | 288 × 192 (3 × 2 m) | décalque ; ancre : centre | mare de tourbe à l'eau noire (#4A675F assombri), bord de sphaignes rouges et vertes, quelques reflets d'étoiles en points clairs | un bord net ou un ovale parfait ; un reflet de lune ou de soleil (c'est une nuit sans lune : des étoiles seulement) ; de l'eau claire et bleue (elle est noire) | 5.1 |
| 1 | `assets/hd2d/decals/path_stones_a.png` | 192 × 144 (2 × 1,5 m) | décalque ; ancre : centre | pierres plates clairsemées et mal posées, à demi enfoncées, herbe et mauvaises herbes dans les interstices (V3) | un dallage régulier ; des pierres alignées ; des contours noirs ; de la pierre neuve et nette | 5.1 |
| 1 | `assets/hd2d/props/marsh_hummock_a.png` | 115 × 77 (1,2 × 0,8 m) | panneau ; ancre : milieu du bord bas | touradon : grosse motte d'herbe dure et de carex qui sort de l'eau noire, le pied mouillé | de l'eau dessinée autour (le jeu pose l'eau) ; une touffe d'herbe tendre de pelouse (c'est du carex dur) | 5.1 |
| 1 | `assets/hd2d/props/marsh_reed_wall.png` | 384 × 192 (4 × 2 m) | panneau, sans raccord à gauche et à droite ; ancre : milieu du bord bas | rideau dense de roseaux pâles (#9C9563) et de massettes brunes, quelques tiges cassées | des bords gauche et droit qui ne se raccordent pas ; des roseaux d'un vert frais (ils sont pâles et secs, fin d'automne) ; une ombre portée | 5.1 |
| 2 | `assets/hd2d/decals/path_stones_b.png` | 144 × 96 (1,5 × 1 m) | décalque ; ancre : centre | deux pierres plates seules, l'une fendue, mangées par l'herbe | un dallage régulier ; des contours noirs ; une pierre entière et propre | 5.1 |
| 2 | `assets/hd2d/props/path_edge_ferns.png` | 384 × 106 (4 × 1,1 m) | panneau, sans raccord à gauche et à droite ; ancre : milieu du bord bas | bordure basse et serrée de fougères, d'herbes hautes et de ronces qui étrangle le sentier | des bords gauche et droit qui ne se raccordent pas ; des fleurs vives ; une bordure régulière de jardin | 5.1 |
| 2 | `assets/hd2d/props/marsh_hummock_b.png` | 86 × 58 (0,9 × 0,6 m) | panneau ; ancre : milieu du bord bas | touradon plus petit, à moitié couché | de l'eau dessinée autour ; une touffe de pelouse tendre | 5.1 |
| 2 | `assets/hd2d/props/path_root_step.png` | 192 × 58 (2 × 0,6 m) | panneau ; ancre : milieu du bord bas | grosse racine moussue en travers du sentier, qui fait marche | une racine lisse comme un tuyau ; un sol dessiné autour | 5.1 |

### A.2 Le port et la rue du port (jour 1, scène 1.1)

**Références à joindre** : `assets/hd2d/props/mooring_arm.png`, `assets/hd2d/props/gangway.png`, `assets/hd2d/buildings/port_hangar.png`, `assets/hd2d/buildings/harbor_office.png`, `assets/hd2d/props/crates_barrels.png`, `assets/hd2d/props/dock_lamp.png`, `assets/hd2d/props/hand_cart.png`, `assets/hd2d/props/pallet_sacks.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/props/signpost_port.png` | 154 × 288 (1,6 × 3 m) | panneau ; ancre : milieu du bord bas | le panneau du port d'après l'œuvre : poteau de bois fendu et penché par le vent, deux planches taillées en flèches et peintes d'un rouge écaillé, l'une vers la droite, l'autre vers la gauche ; sur celle de droite, de petites maisons de pierre peintes, sur celle de gauche un bâtiment de bois dans des arbres ; aucun texte, aucun chiffre ; usé, délavé, un clou qui tient mal (V1, « L'Homme sans Marque ») | du texte, des chiffres ou des lettres sur les flèches (de petites maisons peintes seulement) ; un poteau droit et neuf ; des flèches de la même couleur ou du même sens | 5.6 |
| 1 | `assets/hd2d/props/mooring_arm_open.png` | 288 × 384 (3 × 4 m) | panneau ; ancre : milieu du bord bas | bras d'ancrage de fer et de cuivre **déployé**, pince ouverte prête à saisir une coque, vérins, câbles, rivets ; complète `mooring_arm.png` (replié) | un bras replié (c'est le bras déployé, pince ouverte) ; une coque ou un navire dessiné ; de la vapeur | 5.6 |
| 2 | `assets/hd2d/props/steam_whistle.png` | 77 × 192 (0,8 × 2 m) | panneau ; ancre : milieu du bord bas | sifflet à vapeur de laiton terni au bout d'un tuyau de cuivre qui sort du quai, petite chaîne de manœuvre (V2) ; la vapeur est la bande `anim/furnace_steam.png` (livrée) | de la vapeur dessinée (c'est une bande à part, `anim/furnace_steam.png`) ; un sifflet moderne | 5.6 |
| 2 | `assets/hd2d/props/cargo_cart_a.png` | 288 × 173 (3 × 1,8 m) | panneau ; ancre : milieu du bord bas | charrette à bras à deux roues cerclées de fer, chargée de sacs de toile ficelés, brancards levés (V2) | un docker ou un animal attelé ; des sacs en tas informes ; un plateau de camion | 5.6 |
| 2 | `assets/hd2d/buildings/port_house_b.png` | 384 × 624 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 4 m, faîte 6,5 m, profondeur 5 m ; matières `wall_planks_b`, `roof_tin` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | cabane du gardien du port en planches grises, girouette, longue-vue posée sur l'appui de la fenêtre | allumer la fenêtre ; du texte sur la girouette ; un ciel ou un sol peint | 5.6 |
| 2 | `assets/hd2d/buildings/port_house_b_side.png` | 480 × 384 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 4 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `port_house_b.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_planks_b`, `roof_tin`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 5.6 |
| 3 | `assets/hd2d/props/capstan.png` | 96 × 86 (1 × 0,9 m) | panneau ; ancre : milieu du bord bas | cabestan de fer à barres de bois, un cordage enroulé | un cordage qui traîne au sol ; une ombre portée | 5.6 |
| 3 | `assets/hd2d/props/cargo_cart_b.png` | 240 × 134 (2,5 × 1,4 m) | panneau ; ancre : milieu du bord bas | diable de bois et de fer chargé de trois caisses, une sangle | un personnage ; des caisses neuves et propres | 5.6 |
| 3 | `assets/hd2d/props/wind_fence.png` | 192 × 134 (2 × 1,4 m) | panneau, sans raccord à gauche et à droite ; ancre : milieu du bord bas | palissade brise-vent de planches grises le long de la rue du port, deux planches cassées, un poteau penché | des bords gauche et droit qui ne se raccordent pas ; des planches neuves et droites | 5.6 |

### A.3 Les ornières des rues (port et ville haute)

**Références à joindre** : `assets/hd2d/ground/path_dirt.png`, `assets/hd2d/ground/cobble.png`, `assets/hd2d/decals/cart_ruts.png` (l'actuelle : à ne pas recopier).

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/decals/cart_ruts.png` (même nom, **remplace** l'actuel) | 192 × 384 (2 × 4 m) | décalque de sol, **raccordable en longueur** (le bord haut se raccorde au bord bas), alpha doux sur les bords gauche et droit ; ancre : centre | deux traces de roues de charrette **discrètes** dans la terre battue, parallèles, écartées de 1,2 m, vues de dessus : un léger creux plus foncé de 15 à 20 cm de large, terre tassée un peu plus lisse, quelques graviers épars sans bordure de cailloux ; contraste faible avec `path_dirt` (le chemin doit rester un chemin, pas un champ labouré) ; **aucun bout visible** : la trace continue hors de l'image en haut et en bas ; pas d'ombre portée, pas de relief marqué | des sillons profonds ; des bourrelets de cailloux ; des bouts coupés droits ; une couleur plus sombre que la terre de plus de 15 % ; recopier l'ancienne image (sillons de labour coupés net) | R0.8 |
| 2 | `assets/hd2d/decals/cart_ruts_end.png` | 192 × 192 (2 × 2 m) | décalque de sol, alpha doux, bord haut raccordé à `cart_ruts` ; ancre : centre | la fin des deux traces : elles s'estompent et disparaissent dans la terre sur 1,5 m (pour finir une traînée sans coupure) | un bout coupé net ; des sillons profonds ; un contour | R0.8 |

### A.4 La ville haute : maisons et boutiques (jour 3, scènes 3.2 et 3.3)

**Références à joindre** : `assets/hd2d/buildings/house_stone_b.png`, `house_narrow.png`, `house_timber_a.png`, `shop_bakery.png`, `shop_bookshop.png`, `clockmaker.png`, `butcher.png`, `projection_hall.png` (et leurs flancs `_side`).

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/buildings/materials/wall_stone_town.png` | 192 × 192 | matière ; opaque, sans ancre | pierre de taille gris-beige appareillée en assises régulières, joints fins, quelques blocs plus clairs ou ébréchés (la ville) | un raccord visible ; des assises qui se répètent en damier ; des fenêtres ou des portes | 6.7 |
| 1 | `assets/hd2d/buildings/shop_snack.png` | 480 × 336 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 3,5 m, faîte 6 m, profondeur 5 m ; matières `wall_stone_town`, `roof_tiles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | snack-bar : petite boutique de pierre au comptoir ouvert sur la rue sous un auvent de toile, plaque de cuisson derrière, trois tabourets hauts devant, enseigne en forme de poêle (V1) ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.5 |
| 1 | `assets/hd2d/buildings/shop_snack_side.png` | 480 × 576 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 3,5 m, faîte 6 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `shop_snack.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_tiles`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.5 |
| 1 | `assets/hd2d/buildings/cafe_town.png` | 672 × 384 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 4 m, faîte 6 m, profondeur 6 m ; matières `wall_stone_town`, `roof_slate_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le café habituel de la ville, au coin d'une rue : grandes fenêtres, porte vitrée, deux tables rondes dehors, enseigne en forme de tasse (V3 ; V5) ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.5 |
| 1 | `assets/hd2d/buildings/cafe_town_side.png` | 576 × 576 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 4 m, faîte 6 m, profondeur 6 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `cafe_town.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_slate_b`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.5 |
| 2 | `assets/hd2d/buildings/town_house_e.png` | 576 × 960 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 7,5 m, faîte 10 m, profondeur 6 m ; matières `wall_stone_town`, `roof_slate_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | grande maison de quatre niveaux en haut de la pente, chaînages d'angle, lucarne dans le pignon, girouette en forme de poisson volant (original) ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_e_side.png` | 576 × 720 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 7,5 m, profondeur 6 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `town_house_e.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_slate_b`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_a.png` | 480 × 864 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 6 m, faîte 9 m, profondeur 6 m ; matières `wall_stone_town`, `roof_slate_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | haute maison de pierre de taille à trois niveaux, porte en haut de trois marches, fenêtres à volets bleu passé, corniche de pierre, socle nu de 0,5 m ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_a_side.png` | 576 × 576 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 6 m, profondeur 6 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `town_house_a.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_slate_b`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_b.png` | 768 × 576 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 6 m, faîte 8,5 m, profondeur 6 m ; matières `wall_stone_town`, `roof_tiles_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison bourgeoise à deux étages, rez-de-chaussée de boutique fermée par des volets de bois, balcon de fer forgé à l'étage, jardinières ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_b_side.png` | 576 × 816 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 6 m, faîte 8,5 m, profondeur 6 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `town_house_b.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_tiles_b`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_c.png` | 384 × 720 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 4,5 m, faîte 7,5 m, profondeur 5 m ; matières `wall_plaster`, `roof_tiles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison étroite : pierre au rez-de-chaussée, étage à colombages en encorbellement, porte bleue, une fenêtre par niveau ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_c_side.png` | 480 × 432 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 4,5 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `town_house_c.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_plaster`, `roof_tiles`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_d.png` | 576 × 432 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 4,5 m, faîte 7 m, profondeur 5 m ; matières `wall_stone_b`, `roof_slate` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison basse de pierre claire avec une porte cochère au milieu (arc de pierre sur un passage sombre), deux fenêtres de part et d'autre ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_d_side.png` | 480 × 672 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 4,5 m, faîte 7 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `town_house_d.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_b`, `roof_slate`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_f.png` | 576 × 336 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 3,5 m, faîte 6 m, profondeur 5 m ; matières `wall_plaster_b`, `roof_tiles_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison d'un niveau à enduit ocre, porte entre deux fenêtres, un banc et des pots de géraniums ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.4 |
| 2 | `assets/hd2d/buildings/town_house_f_side.png` | 480 × 576 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 3,5 m, faîte 6 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `town_house_f.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_plaster_b`, `roof_tiles_b`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.4 |
| 2 | `assets/hd2d/buildings/shop_accessories.png` | 384 × 624 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 4 m, faîte 6,5 m, profondeur 5 m ; matières `wall_plaster`, `roof_tiles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | magasin d'accessoires : vitrine de chapeaux sur des têtes de bois, rubans et broches, auvent vert, enseigne en forme de chapeau ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.5 |
| 2 | `assets/hd2d/buildings/shop_accessories_side.png` | 480 × 384 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 4 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `shop_accessories.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_plaster`, `roof_tiles`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.5 |
| 2 | `assets/hd2d/buildings/shop_apothecary.png` | 384 × 624 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 4 m, faîte 6,5 m, profondeur 5 m ; matières `wall_stone_town`, `roof_slate` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | apothicaire : vitrine de bocaux de verre colorés, porte vitrée, enseigne en forme de mortier et de pilon ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.5 |
| 2 | `assets/hd2d/buildings/shop_apothecary_side.png` | 480 × 384 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 4 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `shop_apothecary.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone_town`, `roof_slate`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.5 |

### A.5 La ville haute : enseignes, jardinières, murets et lointain

**Références à joindre** : `assets/hd2d/props/street_lamp_double.png`, `assets/hd2d/props/wall_lantern.png`, `assets/hd2d/props/window_box.png`, `assets/hd2d/props/flower_pots.png`, `assets/hd2d/props/bench_stone.png`, `assets/hd2d/props/hanging_sign_key.png`, `assets/hd2d/props/hanging_sign_propeller.png`, `assets/hd2d/props/market_stall.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/props/hanging_sign_pan.png` | 96 × 115 | panneau ; ancre : milieu du bord bas | enseigne en forme de poêle à frire | des lettres ou des mots ; une potence dessinée si la ligne n'en demande pas ; un fond | 6.5 |
| 2 | `assets/hd2d/props/hanging_sign_cup.png` | 96 × 115 (1 × 1,2 m) | panneau (potence au mur, ancre au bas de la potence) | enseigne de fer pendue à une potence, découpée en tasse fumante | des lettres ou des mots ; de la fumée en alpha continu (la tasse fume en pixels nets) | 6.5 |
| 2 | `assets/hd2d/props/town_planter_stone.png` | 154 × 77 (1,6 × 0,8 m) | panneau ; ancre : milieu du bord bas | bac de pierre fleuri d'asters et de bruyère | des fleurs d'été vives ; une ombre portée ; un sol dessiné | 6.6 |
| 2 | `assets/hd2d/props/town_wall_fountain.png` | 115 × 154 (1,2 × 1,6 m) | panneau ; ancre : milieu du bord bas | fontaine murale : bec de cuivre vert-de-grisé, auge de pierre, une tasse de fer à une chaînette | de l'eau animée (c'est une image fixe) ; un robinet moderne ; une ombre portée | 6.6 |
| 2 | `assets/hd2d/props/town_doorsteps.png` | 115 × 48 (1,2 × 0,5 m) | panneau ; ancre : milieu du bord bas | trois marches de pierre devant une porte, un paillasson | un mur ou une porte dessinés ; du texte sur le paillasson | 6.6 |
| 2 | `assets/hd2d/props/town_cellar_hatch.png` | 115 × 58 (1,2 × 0,6 m) | panneau ; ancre : milieu du bord bas | trappe de cave de bois inclinée contre un mur, pentures de fer | un mur dessiné derrière ; une trappe neuve | 6.6 |
| 2 | `assets/hd2d/props/town_wall_low.png` | 192 × 77 (2 × 0,8 m) | panneau, sans raccord à gauche et à droite ; ancre : milieu du bord bas | muret de pierre sèche à couronnement de dalles, mousse | des bords gauche et droit qui ne se raccordent pas ; un mur de briques | 6.6 |
| 2 | `assets/hd2d/props/town_railing.png` | 192 × 96 (2 × 1 m) | panneau, sans raccord à gauche et à droite ; ancre : milieu du bord bas | garde-corps de fer forgé d'une terrasse, volutes simples, rouille | des bords gauche et droit qui ne se raccordent pas ; de l'acier moderne ; des motifs asiatiques | 6.6 |
| 3 | `assets/hd2d/props/town_roofs_a.png` | 1536 × 768 (16 × 8 m) | lisière, raccord à gauche et à droite ; ancre : milieu du bord bas | la ville qui descend au-delà du bord de la carte, vue de haut et de loin : rangées serrées de toits d'ardoise et de tuiles en écailles, cheminées qui fument, lucarnes, un clocher de pierre, quelques arbres dorés entre les toits ; pour fermer l'horizon des rues | un bord net ; des raccords visibles à gauche et à droite ; des toits asiatiques ; un ciel | 6.6 |
| 3 | `assets/hd2d/props/town_roofs_b.png` | 1536 × 768 | lisière, raccord ; ancre : milieu du bord bas | Comme `town_roofs_a.png` (jointe, à dessiner d'abord), mais : même chose, toits plus bas et plus épars, jardins et murets entre eux, le bord de la ville qui rejoint la forêt | un bord net ; des raccords visibles à gauche et à droite ; un ciel | 6.6 |
| 3 | `assets/hd2d/sky/town_roofs_far.png` | 2048 × 384 (à 48 px/m) | lointain, raccord à gauche et à droite ; ancre : milieu du bord bas | silhouette lointaine de la ville sur sa pente, toits et cheminées adoucis et violacés par la distance | un contraste fort (silhouette adoucie par la distance) ; des raccords visibles ; des îles ou des nuages ajoutés | 6.6 |

### A.6 Le snack-bar (jour 3, scène 3.3)

**Références à joindre** : `assets/hd2d/interior/props/china_cabinet.png`, `assets/hd2d/interior/props/chair_wood.png`, `assets/hd2d/interior/props/dining_table_long.png`, `assets/hd2d/props/snack_stall.png`, `assets/hd2d/interior/floor_planks_worn.png`, `assets/hd2d/interior/wall_wainscot.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/floor_stone_town.png` | 384 × 384 | tuile de sol ; opaque, sans ancre | dalles de pierre claire polies par les pas, joints fins, une dalle fendue (boutiques de la ville) | un raccord visible ; une dalle plus claire qui revient en damier ; un objet ou une ombre | 6.7 |
| 1 | `assets/hd2d/interior/wall_stone_inside.png` | 384 × 288 | mur ; opaque, sans ancre | pierre apparente jointoyée, moellons beiges, une poutre en haut (boulangerie, boucherie) | un raccord visible à gauche ou à droite ; une porte ou une fenêtre ; un meuble ; du texte | 6.7 |
| 1 | `assets/hd2d/interior/props/snack_counter.png` | 288 × 115 (3 × 1,2 m) | meuble ; ancre : milieu du bord bas | comptoir du snack-bar : plaque de cuisson de fonte sur un réchaud de cristal, une poêle où grésille du lard, une bassine de friture, des pommes de terre, un pot de soupe (V1 : le lycanthrope fait sauter sa poêle) | de la perspective conique (plateau en trapèze) ; un personnage ; de la vapeur dessinée ; du texte | 6.7 |
| 1 | `assets/hd2d/interior/props/snack_shelf.png` | 154 × 154 (1,6 × 1,6 m) | meuble ; ancre : milieu du bord bas | étagère de pots, de sacs de pommes de terre et de bouteilles d'huile | du texte sur les pots ; des produits modernes (conserves chromées, plastique) | 6.7 |
| 1 | `assets/hd2d/interior/props/snack_stools.png` | 154 × 77 (1,6 × 0,8 m) | meuble ; ancre : milieu du bord bas | rangée de trois tabourets hauts de bois devant le comptoir | des tabourets à dossier ; de la perspective conique | 6.7 |
| 1 | `assets/hd2d/interior/props/cafe_table_heavy.png` | 115 × 96 (1,2 × 1 m) | meuble ; ancre : milieu du bord bas | table carrée de bois épais, nappe à carreaux rouges et blancs, deux tasses ; avec les chaises `chair_wood` du lot I | de la perspective conique (plateau en trapèze) ; des chaises dessinées (elles sont `chair_wood`) ; du texte sur la nappe | 5.4 |
| 1 | `assets/hd2d/interior/props/snack_meal_tray.png` | 48 × 24 (0,5 × 0,25 m) | objet posé sur une table ; ancre : milieu du bord bas | plateau : pommes de terre frites, légumes, lard frit épais, petit pain, soupe dans une tasse (V1) | un plateau trop grand pour une table (50 × 24 px) ; de la vapeur dessinée | 6.7 |

### A.7 Les gens du port et de la ville haute (planches)

**Références à joindre** : assets/characters/cat_waiter/cat_waiter (trois vues), baker, snack_vendor, ferryman, garde_lookout.

| Prio | Planche (profil ; `_front` et `_back` à côté) | Hauteur debout | Rangées (images à ips) | Apparence et consignes propres | À ne pas faire | Joindre | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/characters/porter/porter.png` + `.json` | 192 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) : `porte` (un gros sac) et `travaille` (il pousse une charrette) | homme-lézard costaud gris-vert, chemise sans manches de toile épaisse, sangle, gants de cuir ; `porte` : un gros sac sur l'épaule ; `travaille` : il pousse une charrette non dessinée | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | snack_vendor, baker, ferryman | 6.1 |
| 1 | `assets/characters/villager_lizard_m/villager_lizard_m.png` + `.json` | 182 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | homme-lézard aux écailles ocre, blouse de charretier, chapeau de feutre | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 2 | `assets/characters/villager_cat_m/villager_cat_m.png` + `.json` | 158 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | homme-chat noir aux yeux jaunes, veste de velours râpée, casquette | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 2 | `assets/characters/villager_dog_f/villager_dog_f.png` + `.json` | 154 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | femme-chienne au pelage roux, robe de travail, châle, panier au bras (dessiné, même côté partout) | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 2 | `assets/characters/villager_bear_m/villager_bear_m.png` + `.json` | 192 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | homme-ours bûcheron, chemise à carreaux, hache au manche posée sur l'épaule (même côté partout) | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 2 | `assets/characters/villager_bird_f/villager_bird_f.png` + `.json` | 149 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | femme-oiseau à tête de pie, robe noire et blanche, petit chapeau | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 2 | `assets/characters/villager_frog_m/villager_frog_m.png` + `.json` | 134 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | homme-grenouille pêcheur des marais, ciré olive, nasse d'osier au dos | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 2 | `assets/characters/villager_lizard_f/villager_lizard_f.png` + `.json` | 173 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | femme-lézard aux écailles vert pâle, robe longue, foulard noué sur la tête | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |

**Les gens du port et de la ville haute.** Chaque espèce a sa silhouette : hommes-chiens et hommes-chats à museau, oreilles et queue, lézards massifs à écailles et longue queue, ours larges et lents, hommes-oiseaux à bec et plumes (bras humains, pas d'ailes), hommes-grenouilles trapus à grande bouche. Vêtements de travail de campagne : chemises de lin, gilets, tabliers, fichus, bottes, chapeaux de feutre ou de paille. Ils craignent l'entrepôt à cause de Nygglatho et ne montrent aucune hostilité envers les fées (V1 ; V5) : au jour 3, un passant change de trottoir en voyant les trois fées (`villager_cat_m`). Au port, `porter` pousse les charrettes de sacs de l'aire-port (V2) et `villager_lizard_m` est le commis du guichet (original) ; en ville, les six autres sont les passants de `ville_haute`. **Les familles se commandent en deux temps** (section 0.3, point 9) : d'abord une **planche d'ensemble** des huit, côte à côte à l'échelle, de formes vraiment différentes (deux lézards : un homme et une femme), puis chaque personnage à part. Rangées : voir la section 3.3.


## 5. Lot B : l'existant qui se voit tout de suite (village, signes, talus, entrepôt)

**Total du lot B : 13 images et 4 planches de personnages ou d'animaux.**

**Pourquoi ce lot.** Ces images corrigent des défauts qu'un joueur voit dans la première seconde sur des cartes **déjà
jouables** (registre `docs/QUALITE.md`, gravité 1 et priorités relevées). Le lot est court, **n'attend aucun autre lot**
et peut se commander en même temps que le lot A. Il contient : les deux façades de nuit dont le jour est livré (QC-16 : le
café, ouvert le soir, a l'air fermé), le premier rang du village (QC-17 et QC-18 : un toit de tôle, un lavoir en
rectangle pâle, de la paille en aplats), les quatre signes d'interaction (R0.13), le talus de terre des petits paliers
(le moteur n'en a qu'un, dessiné par ses outils) et les traces de pas (QC-28), plus les quatre fées génériques dont la
foule de l'entrepôt a besoin (elles portent aujourd'hui la planche d'une autre fée : on voit deux fois la même petite
dans le réfectoire).

### B.1 Les façades du café et de la maison Limashenka, la nuit (registre QC-16)

**Références à joindre** : `assets/hd2d/buildings/cafe.png`, `assets/hd2d/buildings/limashenka_house.png` (les deux façades du jour, livrées : le dessin de nuit les suit au pixel près).

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/buildings/cafe_night.png` | 672 × 528 (comme `cafe.png`) | façade, même cadrage au pixel près ; ancre : milieu du bord bas | `cafe.png` (jointe) **la nuit, café ouvert** : même dessin, mêmes contours ; la vitrine et la porte vitrée éclairées de l'intérieur, lumière chaude **en aplat #FFE6A6** sur les carreaux (silhouettes des tables et des lampes suspendues en contre-jour plus sombre), la lanterne de façade allumée (flamme et verre #FFE6A6), un halo doux peint autour d'elle sur le mur ; le reste de la façade dans la pénombre bleue de la nuit (pierre et colombages assombris, bleutés, sans noir pur) ; store replié | changer le cadrage, la taille ou le dessin (l'image de nuit remplace celle du jour au pixel près) ; peindre les vitres allumées en orangé ; un ciel ou un fond ; tout allumer à l'identique des autres maisons | R0.9 |
| 2 | `assets/hd2d/buildings/limashenka_house_night.png` | 576 × 576 | façade de nuit : même cadrage et même taille que celle du jour, au pixel près ; ancre : milieu du bord bas | `limashenka_house.png` (jointe) la nuit : une seule fenêtre du rez-de-chaussée allumée (carreaux #FFE6A6, rideau à demi tiré), les autres sombres ; pénombre bleue | changer le cadrage ou le dessin ; des vitres orangées ; un ciel ou un fond ; plus d'une fenêtre allumée | R0.9 |

### B.2 Le village au premier rang (registre QC-17 et QC-18)

**Références à joindre** : `assets/hd2d/buildings/materials/roof_shingles.png`, `assets/hd2d/buildings/materials/wall_planks.png`, `assets/hd2d/decals/hay_scatter.png`, `assets/hd2d/props/well.png`, `assets/hd2d/props/laundry_basket.png`, `assets/hd2d/props/wheelbarrow.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/buildings/materials/roof_thatch.png` | 192 × 192 | matière ; opaque, sans ancre | chaume de paille dorée grisée par la pluie, en rangées de bottes parallèles au bas de l'image, mousse verte par plaques, quelques brins plus clairs | des rayures régulières de planches ; les mêmes taches vertes répétées tous les 2 m (on y a vu un toit de tôle) ; un raccord visible ; du brillant | 5.3 |
| 1 | `assets/hd2d/props/washing_trough.png` | 288 × 96 (3 × 1 m) | panneau ; ancre : milieu du bord bas | lavoir : longue auge de pierre pleine d'eau, planche à laver, un panier de linge mouillé (original) | un rectangle pâle à liseré bleu ; un aplat sans matière ; de l'eau bleu vif | 5.3 |
| 2 | `assets/hd2d/props/haystack.png` | 192 × 154 (2 × 1,6 m) | panneau ; ancre : milieu du bord bas | meule de foin ronde, une fourche plantée dedans | des aplats jaunes sans paille ; une silhouette de dôme parfaite ; un contour noir | 5.3 |
| 2 | `assets/hd2d/props/cart_hay.png` | 288 × 192 (3 × 2 m) | panneau ; ancre : milieu du bord bas | charrette de bois à deux grandes roues chargée de foin, brancards posés au sol | des aplats jaunes sans paille ; des roues rondes comme des disques ; un cheval ou un homme attelé | 5.3 |
| 2 | `assets/hd2d/props/beehives.png` | 154 × 96 (1,6 × 1 m) | panneau ; ancre : milieu du bord bas | trois ruches de paille tressée sur une planche (le miel du marché, V3) | des ruches de bois modernes ; des abeilles dessinées une à une | 5.3 |

### B.3 Les signes d'interaction (R0.13 : vus à chaque rencontre)

**Références à joindre** : aucune (les quatre se commandent dans la même conversation : même contour, même ombre, même poids).

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/fx/sign_talk.png` | 64 × 64 | icône, fond transparent, alpha doux, centrée, bas du dessin à 4 px du bord bas | **parler** : une petite bulle de dialogue arrondie, sa pointe en bas à gauche, trois points « … » au milieu ; bulle crème #F6EEE4, contour doré #E8C98A fin (3 à 4 px), points prune #3A2A40 ; une ombre douce prune en dessous (2 px, floue) pour se détacher d'un sol clair | du texte ou une lettre de touche dans l'image (le jeu dessine « E » ou « A » à côté du signe) ; un fond ou un cadre carré ; des couleurs vives ou saturées (rouge, bleu électrique) ; du pixel art grossier (ces images sont réduites, pas agrandies) ; un contour noir épais | R0.13 |
| 1 | `assets/hd2d/fx/sign_examine.png` | 64 × 64 | icône, fond transparent, alpha doux, centrée, bas du dessin à 4 px du bord bas | Même épaisseur de contour, même ombre et même poids que `sign_talk.png` (les quatre signes se commandent dans la même conversation) : **examiner** : une étincelle à quatre branches fines (étoile de lumière), crème au cœur et dorée au bord, une seconde étincelle plus petite en haut à droite ; aucun œil ni loupe | un œil, une loupe, du texte ; un fond ou un cadre carré ; des couleurs vives ; un contour noir épais | R0.13 |
| 1 | `assets/hd2d/fx/sign_take.png` | 64 × 64 | icône, fond transparent, alpha doux, centrée, bas du dessin à 4 px du bord bas | Même épaisseur de contour, même ombre et même poids que `sign_talk.png` : **prendre** : une petite main ouverte, paume vers le spectateur, doigts serrés et pouce écarté, crème au contour doré, dessinée simplement (pas de jointures, pas d'ongles) | des jointures, des ongles, du texte ; un fond ou un cadre carré ; des couleurs vives ; un contour noir épais | R0.13 |
| 1 | `assets/hd2d/fx/sign_enter.png` | 64 × 64 | icône, fond transparent, alpha doux, centrée, bas du dessin à 4 px du bord bas | Même épaisseur de contour, même ombre et même poids que `sign_talk.png` : **entrer, sortir, embarquer** : une porte cintrée vue de face, encadrement doré, intérieur prune #3A2A40, une flèche crème qui monte au milieu (on passe la porte) | du texte ou une flèche en lettres ; un fond ou un cadre carré ; des couleurs vives ; un contour noir épais | R0.13 |

### B.4 Le talus de terre et les traces de pas (sols de toutes les cartes)

**Références à joindre** : `assets/hd2d/cliff/cliff.png`, `assets/hd2d/ground/garden_soil.png`, `assets/hd2d/ground/path_dirt.png`, `assets/hd2d/decals/footprints.png` (l'actuelle, pour le contraste).

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/cliff/bank_earth.png` | 384 × 96 (4 × 1 m) | face de palier, sans raccord à gauche et à droite ; REMPLACE le remplaçant du moteur (même nom, même taille) ; opaque, sans ancre | talus de terre vu de face, 1 m de haut, la face d'un petit palier : en haut l'herbe du pré qui déborde en touffes et ses racines qui pendent, puis une terre brune (#56402C) en strates molles, quelques cailloux et mottes ; en bas, les tons de la terre de potager. **Livre-le sous le nom `bank_earth.png`** : c'est celui que le moteur lit aujourd'hui pour tous les petits paliers (il n'a qu'un seul talus) ; `wall_earth_1m` ne se commande qu'après son accord (lot D, D.2) | un raccord visible à gauche ou à droite ; un haut qui ne se raccorde pas au pré (l'herbe déborde en touffes) ; une terre plus claire ou plus rouge que #56402C | 5.2 |
| 3 | `assets/hd2d/decals/footprints.png` (même nom, **remplace** l'actuel) | 96 × 288 (1 × 3 m) | décalque de sol, alpha doux ; ancre : centre | une traînée de **petits pas d'enfant** (pieds de 18 cm, pas de 45 cm) et de pas d'adulte mêlés, en léger zigzag, sur la terre battue : les premières et les dernières empreintes **s'estompent** (moins marquées, à demi couvertes de poussière) ; contraste faible, aucune ombre portée | six empreintes identiques en file ; des bouts nets ; un contraste plus fort que les cailloux du sol | R0.11 |

### B.5 Les quatre fées génériques qui manquent à la foule de l'entrepôt

**Références à joindre** : assets/characters/tiat/tiat (trois vues), lakhesh, fairy_01 à fairy_06 et fairy_11, fairy_12 (trois vues).

| Prio | Planche (profil ; `_front` et `_back` à côté) | Hauteur debout | Rangées (images à ips) | Apparence et consignes propres | À ne pas faire | Joindre | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/characters/fairy_07/fairy_07.png` + `.json` | 110 px | `repos` 2 images à 2 ips ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `saut` 4 à 12 (non) ; `frappe` 4 à 14 (non, `coup` [2]) ; `lance` 4 à 12 (non, `coup` [2]) ; `grimpe` 4 à 8 ; `assis` 2 à 2 ; `lit` 2 à 2 ; `dort` 2 à 1 ; `tombe` 4 à 10 (non) | cheveux vert d'eau tressés en couronne, robe de lainage bleu canard, châle croisé | des cheveux rouges (le rouge est la couleur de l'empiètement) ; les couleurs exactes d'une fée nommée ; la même tenue qu'une autre fée ; une couette ou un ruban qui change de côté | tiat, lakhesh, fairy_11 (trois vues chacune) | 4.5 |
| 2 | `assets/characters/fairy_08/fairy_08.png` + `.json` | 115 px | `repos` 2 images à 2 ips ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `saut` 4 à 12 (non) ; `frappe` 4 à 14 (non, `coup` [2]) ; `lance` 4 à 12 (non, `coup` [2]) ; `grimpe` 4 à 8 ; `assis` 2 à 2 ; `lit` 2 à 2 ; `dort` 2 à 1 ; `tombe` 4 à 10 (non) | cheveux ambre cuivré en queue de cheval, chemise à carreaux trop grande, pantalon roulé aux chevilles | des cheveux rouges (le rouge est la couleur de l'empiètement) ; les couleurs exactes d'une fée nommée ; la même tenue qu'une autre fée ; une couette ou un ruban qui change de côté | tiat, lakhesh, fairy_11 | 4.5 |
| 2 | `assets/characters/fairy_09/fairy_09.png` + `.json` | 120 px | `repos` 2 images à 2 ips ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `saut` 4 à 12 (non) ; `frappe` 4 à 14 (non, `coup` [2]) ; `lance` 4 à 12 (non, `coup` [2]) ; `grimpe` 4 à 8 ; `assis` 2 à 2 ; `lit` 2 à 2 ; `dort` 2 à 1 ; `tombe` 4 à 10 (non) | cheveux jaune paille lisses au carré, robe-tablier rayée bleu et blanc | des cheveux rouges (le rouge est la couleur de l'empiètement) ; les couleurs exactes d'une fée nommée ; la même tenue qu'une autre fée ; une couette ou un ruban qui change de côté | tiat, lakhesh, fairy_11 | 4.5 |
| 2 | `assets/characters/fairy_10/fairy_10.png` + `.json` | 130 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `frappe` 4 à 14 (non, `coup` [2]) ; `assis` 2 à 2 ; `lit` 2 à 2 ; `dort` 2 à 1 | cheveux rose poudré longs noués d'un ruban, robe de lainage gris-mauve, gilet | des cheveux rouges (le rouge est la couleur de l'empiètement) ; les couleurs exactes d'une fée nommée ; la même tenue qu'une autre fée ; une couette ou un ruban qui change de côté | fairy_11 et fairy_12 (grandes), lakhesh | 4.5 |

Près de trente fées vivent à l'entrepôt, des filles de 7 à 15 ans pour la plupart, aux cheveux de couleurs vives et naturelles (V1, « Directeur en carton »). Les tenues sont celles d'un orphelinat de campagne : robes simples, blouses, gilets tricotés, tabliers, salopettes, tout reprisé et un peu trop grand ou trop petit, bottines. **Aucune fée générique n'a les cheveux rouges** (le rouge est la couleur de l'empiètement, V3) ni les couleurs exactes des fées nommées (céruléen, orange, gris cendré, vert feuille, rose, violet, pêche, jaune citron, vermillon, indigo). Elles jouent avec entrain ; chacune garde son accessoire (ruban, bandage, livre) du même côté dans toutes les images. **Demande d'abord une planche d'ensemble des quatre, côte à côte à l'échelle, avec `fairy_11` et `fairy_12` livrées pour étalon**, puis chaque planche à part. Tableau : `fairy_07` à `fairy_09` ont les rangées des petites, `fairy_10` celles des grandes.


## 6. Lot C : la phase 3 (jours 5 à 12 : le transport de la Garde, la pluie, la colline, le village, le café, la maison Limashenka, le bâton)

**Total du lot C : 69 images et 21 planches de personnages ou d'animaux.**

**Pourquoi ce lot.** La phase 3 de la refonte joue les jours 5 à 12 : le ballon (jour 5), la pluie et le port sous la pluie
(jour 7), le duel, la fugue et la colline aux étoiles (jour 8), le café du village et le bâton (jour 9), la pluie, la tour de
fées et le linge (jour 10), la maison Limashenka et l'entraînement avec Seniorious (jour 11), le départ (jour 12).
**Seniorious et le duel** (`ACTE1.md` 3.3 et 3.4) ne demandent qu'**une** planche nouvelle, `willem_duel` (Willem et le
Carillon Percival, C.10) : Chtholly porte Seniorious dans sa planche livrée, la lueur des fissures et la désaturation sont
des effets du moteur.

**Dépendances** : `anim/mooring_arm_clamp` (C.1) se dessine en joignant `props/mooring_arm_open.png` (A.2) ; les versions
de nuit du village (C.5) se commandent **après** leur façade du jour, dans la même conversation ; le café (C.6) joint
`cafe_table_heavy.png` (A.6) et le village (C.5) `roof_thatch.png` (B.2).

### C.1 Le transport de la Garde et le quai (jour 7, scène 7.4)

**Références à joindre** : `assets/hd2d/props/airship_ferry.png`, `assets/hd2d/props/airship_barocupot.png`, `assets/hd2d/props/mooring_arm.png`, `assets/hd2d/props/mooring_arm_open.png` (livrée au lot A), `assets/hd2d/props/gangway.png`, `assets/hd2d/buildings/port_hangar.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/ships/garde_transport_side.png` | 1536 × 672 (16 × 7 m) | flanc, proue à droite ; ancre : milieu du bord bas | petit transport militaire de la Garde ailée, de flanc : coque trapue de tôle d'acier rivetée gris-bleu sombre, bande rouge de la Garde (#AE4A3E) le long du bordage, aile stylisée peinte à la proue (sans texte), quille de fer ; au milieu, une cabine basse à hublots ronds éclairés et une cheminée courte ; à l'arrière, la chaudière enchantée en nacelle sous la coque, grilles rougeoyantes ; **deux moyeux de rotor** au bout de bras courts qui sortent du flanc au-dessus du bordage, à un quart et aux trois quarts de la longueur, axe tourné vers la caméra (comme les hélices latérales (livrée)), **sans pales** ; une trappe ronde fermée sur le flanc à l'arrière ; massif, sérieux, entretenu ; **aucun ballon** | un ballon ou une enveloppe de gaz ; des pales de rotor (les moyeux sont nus, les pales sont une bande à part) ; du texte ; un fond ou des nuages dessinés autour | 9.1 |
| 1 | `assets/hd2d/anim/garde_transport_hatch.png` | 4 images de 192 × 192 (2 m), 8 ips, non bouclée ; fichier : 768 × 192 | bande animée ; ancre : milieu du bord bas de chaque image | la trappe ronde du flanc qui s'ouvre sous la pression : 0 fermée ; 1 le volant tourne, un jet de vapeur ; 2 entrouverte, vapeur ; 3 grande ouverte sur l'intérieur sombre (V1) | un navire dessiné autour de la trappe ; un décalage de la trappe d'une image à l'autre | 9.1 |
| 1 | `assets/hd2d/anim/garde_transport_rotor.png` | 4 images de 192 × 192 (2 m), 12 ips ; fichier : 768 × 192 | bande animée, centrée | rotor à deux pales de fer sombre aux bouts rouges, vu de face, qui tourne d'un huitième de tour (45°) d'une image à l'autre : en 4 images, chaque pale prend la place de l'autre, boucle sans à-coup ; moyeu au centre exact de chaque image | un moyeu qui bouge d'une image à l'autre ; des pales de couleur différente ; un flou de rotation | 9.1 |
| 1 | `assets/hd2d/anim/mooring_arm_clamp.png` | 4 images de 288 × 384, 6 ips ; fichier : 1152 × 384 | bande animée ; ancre : milieu du bord bas de chaque image | `mooring_arm_open.png` (jointe) : le bras s'abaisse et la pince se referme sur un anneau non dessiné ; image 3 : fermé ; le pied immobile au pixel près | un pied qui bouge (il est immobile au pixel près) ; un anneau ou un navire dessiné | 5.6 |
| 1 | `assets/hd2d/sky/ship_searchlight.png` | 384 × 768 (4 × 8 m) | lointain, **alpha doux**, ancre libre | cône de lumière blanche très forte qui descend à travers les nuages, plus intense en haut, qui s'élargit vers le bas ; aucun navire dessiné (V1) | un navire ou une silhouette dessinée dans le faisceau ; un bord net ; un cône régulier de projecteur moderne | 8.4 |
| 2 | `assets/hd2d/props/gangway_ramp.png` | 288 × 154 (3 × 1,6 m) | panneau ; ancre : milieu du bord bas | rampe d'embarquement inclinée de tôle striée, garde-corps de fer, vue de flanc, qui monte vers la droite (V2 : on monte par une passerelle et une rampe) | un navire ou un personnage dessiné ; des planches (c'est de la tôle striée) | 5.6 |

**Les navires de l'œuvre.** Ce ne sont **jamais des ballons** : aucune enveloppe de gaz n'est mentionnée. Ce sont des navires volants à **coque de métal**, portés par une **chaudière enchantée** (un four enchanté qui gronde et fait vibrer la coque) et poussés par des **rotors** ou des hélices, avec des **bras d'ancrage**, une **passerelle** et une rampe, une **trappe** qui s'ouvre sous la pression, plusieurs **ponts** et salles, un sifflet à vapeur (V1, « Entrepôt de fées » ; V2, « Le chemin du retour, toujours si loin »). Les silhouettes plates du passeur et du Barocupot (`props/airship_*.png`) et tous les intérieurs de bord (`docs/ASSETS_HD2D_NAVIRES.md`) sont livrés ; ce groupe ne dessine que le **volume extérieur** du transport de la Garde : il descend au crépuscule du jour 7 d'au-dessus de la mer de nuages, précédé d'une lumière si forte qu'on ne voit pas sa silhouette ; il est **petit**, militaire ; deux pales de rotor s'arrêtent peu à peu, le bruit de la chaudière décroît, la trappe de sortie s'ouvre sous la pression, et le lézard géant doit se faire petit pour en sortir (V1, « Entrepôt de fées »). **Format d'un navire en volume** (dossier `ships/`, 96 px par mètre, proue à droite) : `_side` le flanc vu de face sans perspective, quille collée au bord bas, moyeux de rotor **sans pales** (les pales sont une bande animée à part) ; `_deck` le pont vu strictement de dessus, ancre au centre ; `_stern` la poupe vue de face ; `_34` le navire de trois quarts avant, centré, marge transparente (ces trois dernières vues sont au lot D). La caméra regarde le nord : les navires s'amarrent **au nord des quais**, de flanc ou par la poupe. **Format à confirmer par le moteur** (lot E7) : on peut commander `garde_transport_side` sans attendre, le plan du port le pose déjà (section 9).

*Ordre* : `garde_transport_side` d'abord, puis, **joignant ce flanc**, la trappe, le rotor, puis `mooring_arm_clamp` en joignant `mooring_arm_open.png` du lot A.

### C.2 La pluie, les flaques et les ciels couverts (jours 7 et 10)

**Références à joindre** : `assets/hd2d/sky/sky.png`, `sky_rain.png`, `cloud_sea.png`, `cloud_a.png`, `assets/hd2d/anim/rain_splash.png`, `assets/hd2d/anim/rain_curtain.png`, `rain_drizzle.png` (les remplaçants du moteur : pour le rythme seulement).

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/anim/rain_curtain.png` | 4 images de 384 × 384 (4 × 4 m), 12 ips ; fichier : 1536 × 384 | bande animée, **alpha doux**, chaque image **sans raccord sur les quatre bords** ; pas d'ancre (le motif remplit l'image) ; format à confirmer par le moteur (section 9) | averse : traits de pluie fins et obliques (vers la droite en tombant), gris clair à 30-60 % d'opacité, de longueurs variées. **Méthode** (cette image n'a jamais été livrée correctement) : dessine d'abord **UNE tuile de pluie de 384 × 384 sans raccord sur les quatre bords** (un trait qui sort par un bord rentre par le bord opposé) ; puis fais les 4 images en décalant tous les traits vers le bas d'un quart de l'image (96 px) à chaque image, les traits qui sortent en bas rentrent en haut : la boucle tombe sans saut ; les 4 images se posent côte à côte (fichier 1536 × 384) | un raccord visible sur un des quatre bords de chaque image ; des traits qui ne descendent pas d'un quart exact entre deux images ; une pluie opaque (30 à 60 %) | 8.1 |
| 1 | `assets/hd2d/anim/rain_drizzle.png` | 4 images de 384 × 384, 10 ips ; fichier : 1536 × 384 | bande animée, alpha doux, sans raccord ; ancre : milieu du bord bas de chaque image ; format à confirmer par le moteur (section 9) | pluie fine : traits courts, plus rares et plus pâles (20 à 40 %), presque verticaux. Même méthode que `rain_curtain.png` (à dessiner d'abord, même conversation) : une tuile de 384 × 384 sans raccord sur les quatre bords, puis quatre images en décalant les traits d'un quart de l'image (96 px) vers le bas ; fichier 1536 × 384 | un raccord visible sur un bord ; des traits longs ou serrés ; une pluie opaque | 8.1 |
| 1 | `assets/hd2d/anim/puddle_rain_a.png` | 4 images de 192 × 115 (2 × 1,2 m), 8 ips ; fichier : 768 × 115 | décalque animé, vu de dessus ; ancre : milieu du bord bas ; format à confirmer par le moteur (section 9) | flaque d'eau boueuse sous la pluie, vue de dessus : petits cercles qui naissent et s'élargissent à des endroits différents d'une image à l'autre, reflets gris du ciel, bord de boue sombre irrégulier ; **chaque image garde exactement le même contour de flaque**, seuls les cercles changent | un contour de flaque qui change d'une image à l'autre (seuls les cercles changent) ; un bord net ; un reflet de soleil | 8.1 |
| 2 | `assets/hd2d/anim/eave_drip.png` | 4 images de 48 × 192 (0,5 × 2 m), 8 ips ; fichier : 192 × 192 | bande animée, suspendue (le haut de l'image est l'égout du toit) | trois gouttes qui tombent d'un bord de toit à des moments décalés, sur toute la hauteur de l'image | des gouttes qui tombent toutes ensemble ; un égout dessiné (le haut de l'image est l'égout, il n'est pas dessiné) | 8.1 |
| 2 | `assets/hd2d/anim/puddle_rain_b.png` | 4 images de 134 × 96 (1,4 × 1 m), 8 ips ; fichier : 536 × 96 | décalque animé ; ancre : milieu du bord bas ; format à confirmer par le moteur (section 9) | Comme `puddle_rain_a.png` (jointe, à dessiner d'abord) : petite flaque sous la pluie, même mouvement | un contour qui change d'une image à l'autre ; un bord net | 8.1 |
| 2 | `assets/hd2d/sky/cloud_rain_a.png` | 768 × 256 (à 48 px/m) | nuage, **alpha doux** ; ancre : milieu du bord bas | gros nuage de pluie gris, base plate et sombre d'où pendent des traînées de pluie | un contour net ; une ombre portée ; du blanc ou du noir pur ; des éléments ajoutés autour | 8.2 |
| 2 | `assets/hd2d/sky/cloud_rain_b.png` | 576 × 192 (à 48 px/m) | nuage, **alpha doux** ; ancre : milieu du bord bas | nuage de pluie plus petit, effiloché, gris-mauve | un contour net ; une ombre portée ; du blanc ou du noir pur ; des éléments ajoutés autour | 8.2 |
| 2 | `assets/hd2d/sky/cloud_sea_rain.png` | 1024 × 1024 | mer de nuages ; ancre : milieu du bord bas | la mer de nuages sous la pluie : crêtes gris cendre ternes, creux mauve sombre, nappes de bruine | un contour net ; une ombre portée ; du blanc ou du noir pur ; des éléments ajoutés autour | 8.2 |
| 2 | `assets/hd2d/sky/sky_overcast.png` | 2048 × 1024 | ciel ; ancre : milieu du bord bas | jour nuageux, la pluie menace : plafond gris cendre uniforme et bas, quelques nuages plus sombres qui pendent, lumière plate sans soleil ; mer de nuages grise | un soleil ; une couture visible à gauche et à droite ; des îles ou des navires | 8.2 |

### C.3 La colline des étoiles (jour 8, scène 8.8) : talismans, piliers de roche, dalles

**Références à joindre** : `assets/hd2d/sky/sky_night.png`, `assets/hd2d/sky/cloud_sea.png`, `assets/hd2d/sky/floating_rock.png`, `assets/hd2d/sky/distant_island_a.png`, `assets/hd2d/props/boulder_a.png`, `assets/hd2d/decals/ring_stone_flat_a.png` (comme contre-exemple : ovales sombres), `assets/hd2d/ground/path_dirt.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/anim/talisman_float.png` | 4 images de 24 × 24 (0,25 m), 6 ips ; fichier : 96 × 24 | bande animée, centrée ; alpha doux | un éclat de talisman : fragment de métal blanc gravé qui flotte et tourne lentement sur lui-même en luisant comme une étoile (le halo en alpha doux) | du texte gravé lisible ; une image qui change de taille d'une image à l'autre ; un halo qui coupe le bord | 8.4 |
| 2 | `assets/hd2d/sky/sea_stack_a.png` | 288 × 1152 (6 × 24 m à 48 px/m) | pilier dans la mer de nuages, **alpha doux** dans les 4 derniers mètres du bas, ancre milieu du bord bas | pilier de roche claire (#C2B49F) en strates horizontales et fissures verticales, vu de face (la face tournée vers le sud, lumière de la gauche), haut de 24 m, large de 6 m à la base et de 4,5 m au milieu, une couronne d'herbe d'automne (#A8B040) et de bruyère au sommet avec un petit arbre noueux ; la base se dissout dans une brume rose pâle et gris lavande (alpha doux), aucun sol sous le pilier | un pilier posé sur un sol (il flotte dans la brume : sa base est invisible) ; une silhouette plate sans strates ; un contour noir | R0.12 |
| 2 | `assets/hd2d/sky/sea_stack_b.png` | 384 × 1344 (8 × 28 m à 48 px/m) | pilier dans la mer de nuages, **alpha doux** dans les 4 derniers mètres du bas ; ancre : milieu du bord bas | Comme `sea_stack_a.png` (jointe, à dessiner d'abord), mais : pilier plus massif, deux ressauts (une corniche à mi-hauteur, des racines pendantes), mousse dans les fissures, herbe haute au sommet ; même lumière, même brume au pied | un pilier posé sur un sol ; une silhouette plate sans strates ; un contour noir | R0.12 |
| 2 | `assets/hd2d/decals/path_flagstones_a.png` | 192 × 192 (2 × 2 m) | décalque de sol, **alpha doux** sur le bord, centre = point posé | quatre dalles plates de calcaire clair (#C8BBA6), vues de dessus, de 40 à 70 cm, aux bords arrondis, jointoyées d'herbe courte et de mousse, un peu de terre battue (#C89A5A) autour ; contraste modéré avec la terre du sentier (plus clair, pas blanc), aucune ombre portée, **aucun contour noir** | des dalles en ovales sombres ou cernées de noir comme `ring_stone_flat_*` ; des dalles régulières alignées comme un dallage (le sentier est de terre, les dalles y sont posées ça et là) | R0.12 |
| 2 | `assets/hd2d/decals/path_flagstones_b.png` | 144 × 144 (1,5 × 1,5 m) | décalque de sol, **alpha doux** sur le bord ; ancre : centre | Comme `path_flagstones_a.png` (jointe, à dessiner d'abord), mais : deux dalles et un caillou, même matière, même terre autour | des dalles en ovales sombres ou cernées de noir ; un dallage régulier | R0.12 |
| 3 | `assets/hd2d/sky/sea_stack_c.png` | 192 × 768 (4 × 16 m à 48 px/m) | pilier dans la mer de nuages, **alpha doux** dans les 4 derniers mètres du bas ; ancre : milieu du bord bas | Comme `sea_stack_a.png` (jointe), mais : aiguille de roche étroite et penchée, quelques touffes d'herbe, une arche naturelle à mi-hauteur ; même brume au pied | un pilier posé sur un sol ; une silhouette plate sans strates ; une arche trop régulière | R0.12 |

### C.4 La nuit : fenêtres, vitres éclairées, clair de lune (jours 7, 8 et 10)

**Références à joindre** : `assets/hd2d/interior/window_bare.png`, `window_curtains_open.png`, `window_cross_small_night.png`, `assets/hd2d/decals/sun_window.png`, `assets/hd2d/buildings/warehouse_main.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/window_bare_night.png` | 106 × 134 | fenêtre, appui à 0,7 m ; ancre : milieu du bord bas | `window_bare.png` (jointe) la nuit : vitres d'un noir profond bleuté, sans étoile, un seul reflet (V1) | changer le cadrage ou la taille (même cadrage que `window_bare.png` au pixel près) ; une étoile | 8.3 |
| 2 | `assets/hd2d/interior/window_curtains_open_night.png` | 115 × 154 | fenêtre, appui à 0,8 m ; ancre : milieu du bord bas | `window_curtains_open.png` (jointe) la nuit : vitres bleu nuit, rideaux plus sombres | changer le cadrage ; des rideaux clairs | 8.3 |
| 2 | `assets/hd2d/props/window_lit_large.png` | 134 × 134 (1,4 × 1,4 m) | vitre éclairée ; ancre : milieu du bord bas | carreaux d'une grande fenêtre à croisillons (neuf carreaux) éclairés, l'ombre d'un rideau sur un côté | dessiner le cadre ou le mur (seulement les carreaux et les croisillons) ; du orangé | 8.3 |
| 2 | `assets/hd2d/props/window_lit_small.png` | 77 × 96 (0,8 × 1 m) | vitre éclairée ; ancre : milieu du bord bas | carreaux d'une petite fenêtre à croisillons (six carreaux) éclairés de l'intérieur d'un jaune chaud (#FFE6A6), plus clair au centre, croisillons sombres ; rien autour | dessiner le cadre ou le mur ; du orangé (jaune chaud #FFE6A6, plus clair au centre) | 8.3 |
| 2 | `assets/hd2d/decals/moon_window.png` | 192 × 144 | décalque de lumière, **alpha doux** ; ancre : centre | la tache de lumière de `sun_window.png` (jointe : la fenêtre que le soleil pose au sol), **la nuit** : lumière bleu pâle (20 à 35 % d'opacité), contours plus doux | un bord net ; un contraste fort ; la même couleur que `sun_window.png` | 8.4 |
| 3 | `assets/hd2d/props/window_lit_round.png` | 58 × 58 (0,6 m) | vitre éclairée ; ancre : milieu du bord bas | œil-de-bœuf éclairé, croisillon en croix | dessiner le cadre ou le mur ; du orangé | 8.3 |

### C.5 Le village des hommes-bêtes (jour 9) : chaumières, grange, maison de pierre, appentis, leurs versions de nuit

**Références à joindre** : `assets/hd2d/buildings/cafe.png`, `limashenka_house.png`, `assets/hd2d/buildings/materials/roof_thatch.png` (livrée au lot B), `wall_planks.png`, `wall_stone.png`, `roof_shingles.png`, `assets/hd2d/props/fence_low.png`, `assets/hd2d/props/palisade.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/buildings/materials/wall_wattle_daub.png` | 192 × 192 | matière ; opaque, sans ancre | torchis ocre clair grumeleux, brins de paille visibles, petites fissures, sans colombages (ils sont dans les façades) | un raccord visible sur un bord ; un motif qui se répète à intervalle régulier ; un objet, un joint isolé ou une ombre portée | 5.3 |
| 2 | `assets/hd2d/props/fence_wattle.png` | 192 × 86 (2 × 0,9 m) | panneau, **sans raccord à gauche et à droite** ; ancre : milieu du bord bas | clôture de branches tressées entre des piquets, quelques brins cassés | des bords gauche et droit qui ne se raccordent pas ; une ombre portée au sol ; une marge transparente sur les côtés ; du texte | 5.3 |
| 2 | `assets/hd2d/buildings/cottage_thatch_a.png` | 480 × 528 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 2,5 m, faîte 5,5 m, profondeur 5 m ; matières `wall_wattle_daub`, `roof_thatch` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | chaumière de torchis ocre clair sur soubassement de pierres, colombages bruns irréguliers, toit de chaume épais et arrondi qui descend bas, porte basse de planches, une petite fenêtre éteinte, pots de fleurs au seuil | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 5.3 |
| 2 | `assets/hd2d/buildings/cottage_thatch_a_side.png` | 480 × 240 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 2,5 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `cottage_thatch_a.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_wattle_daub`, `roof_thatch`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 5.3 |
| 2 | `assets/hd2d/buildings/cottage_thatch_b.png` | 672 × 240 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 2,5 m, faîte 5 m, profondeur 5 m ; matières `wall_wattle_daub`, `roof_thatch` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | longue chaumière basse : deux portes, trois petites fenêtres éteintes à volets, un banc de bois contre le mur, une corde à linge tendue d'un crochet à l'autre (sans linge), la bordure du chaume en haut de l'image | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 5.3 |
| 2 | `assets/hd2d/buildings/cottage_thatch_b_side.png` | 480 × 480 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 2,5 m, faîte 5 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `cottage_thatch_b.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_wattle_daub`, `roof_thatch`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 5.3 |
| 2 | `assets/hd2d/buildings/cottage_thatch_c.png` | 384 × 480 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 2,25 m, faîte 5 m, profondeur 4 m ; matières `wall_wattle_daub`, `roof_thatch` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | petite chaumière penchée, torchis fissuré rapiécé, une lucarne dans le chaume, porte peinte en vert passé | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 5.3 |
| 2 | `assets/hd2d/buildings/cottage_thatch_c_side.png` | 384 × 216 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 2,25 m, profondeur 4 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `cottage_thatch_c.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_wattle_daub`, `roof_thatch`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 5.3 |
| 2 | `assets/hd2d/buildings/village_barn.png` | 768 × 336 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 3,5 m, faîte 7 m, profondeur 6 m ; matières `wall_planks`, `roof_thatch` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | grange de planches brunes délavées, grande porte à deux battants entrouverte sur la pénombre et le foin, petite porte à côté, fourche appuyée | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 5.3 |
| 2 | `assets/hd2d/buildings/village_barn_side.png` | 576 × 672 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 3,5 m, faîte 7 m, profondeur 6 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `village_barn.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_planks`, `roof_thatch`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 5.3 |
| 2 | `assets/hd2d/buildings/village_house_stone.png` | 480 × 576 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 3 m, faîte 6 m, profondeur 5 m ; matières `wall_stone`, `roof_shingles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison de pierre un peu plus aisée, toit de bardeaux, porte à heurtoir, deux fenêtres à volets, une plus petite à l'étage dans le pignon, lierre au coin | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 5.3 |
| 2 | `assets/hd2d/buildings/village_house_stone_side.png` | 480 × 288 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 3 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `village_house_stone.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone`, `roof_shingles`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 5.3 |
| 2 | `assets/hd2d/buildings/village_house_stone_night.png` | 480 × 576 | façade de nuit : même cadrage et même taille que celle du jour, au pixel près ; ancre : milieu du bord bas | `village_house_stone.png` (jointe) la nuit : une fenêtre de l'étage allumée (#FFE6A6), les volets du bas fermés ; pénombre bleue | changer le cadrage ou le dessin ; des vitres orangées ; un ciel ou un fond ; plus d'une fenêtre allumée | R0.9 |
| 2 | `assets/hd2d/buildings/cottage_thatch_a_night.png` | 480 × 528 | façade de nuit : même cadrage et même taille que celle du jour, au pixel près ; ancre : milieu du bord bas | `cottage_thatch_a.png` (jointe) la nuit : la petite fenêtre allumée d'une lueur de bougie (#FFE6A6 au centre, plus orangé seulement sur le cadre de bois) ; chaume et torchis bleutés | changer le cadrage ou le dessin ; des vitres orangées (plus orangé seulement sur le cadre de bois) ; un ciel ou un fond ; tout allumer | R0.9 |
| 3 | `assets/hd2d/buildings/village_shed.png` | 384 × 216 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 2,25 m, faîte 3,5 m, profondeur 3 m ; matières `wall_planks_b`, `roof_shingles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | appentis à bois de planches grises, bûches empilées sous l'avancée, une hache plantée dans un billot devant | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 5.3 |
| 3 | `assets/hd2d/buildings/village_shed_side.png` | 288 × 336 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 2,25 m, faîte 3,5 m, profondeur 3 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `village_shed.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_planks_b`, `roof_shingles`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 5.3 |
| 3 | `assets/hd2d/buildings/cottage_thatch_b_night.png` | 672 × 240 | façade de nuit : même cadrage et même taille que celle du jour, au pixel près ; ancre : milieu du bord bas | `cottage_thatch_b.png` (jointe) la nuit : une des trois fenêtres allumée (#FFE6A6), volets des deux autres fermés | changer le cadrage ou le dessin ; des vitres orangées ; un ciel ou un fond ; allumer plus d'une fenêtre | R0.9 |
| 3 | `assets/hd2d/buildings/cottage_thatch_c_night.png` | 384 × 480 | façade de nuit : même cadrage et même taille que celle du jour, au pixel près ; ancre : milieu du bord bas | `cottage_thatch_c.png` (jointe) la nuit : la lucarne du chaume allumée (#FFE6A6) | changer le cadrage ou le dessin ; des vitres orangées ; un ciel ou un fond ; allumer autre chose que la lucarne | R0.9 |

### C.6 Le café à clochette (jour 9, scène 9.3) : l'intérieur

**Références à joindre** : `assets/hd2d/interior/props/china_cabinet.png`, `chair_wood.png`, `dining_table_long.png`, `assets/hd2d/interior/props/cafe_table_heavy.png` (livrée au lot A), `assets/hd2d/interior/wall_wainscot.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/floor_terracotta.png` | 384 × 384 | tuile de sol ; opaque, sans ancre | carreaux carrés de terre cuite de 20 cm, rouge-brun et ocre mêlés, usés, quelques-uns fêlés | un raccord visible ; un objet posé, une ombre ; de la perspective (vue strictement de dessus ou de face) | 5.4 |
| 1 | `assets/hd2d/interior/props/cafe_counter.png` | 288 × 115 (3 × 1,2 m) | meuble ; ancre : milieu du bord bas | comptoir de bois sombre ciré, usé au bord : une grande cafetière de cuivre sur un réchaud de cristal, des tasses retournées, un bocal de biscuits, un tonnelet à robinet de bois au bout | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 5.4 |
| 1 | `assets/hd2d/interior/props/juice_glasses.png` | 48 × 29 (0,5 × 0,3 m) | objet posé sur une table ; ancre : milieu du bord bas | trois verres de jus de fruits (orange, rouge, jaune) et une carafe (VEX : les jus offerts « pour la maison ») | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 5.4 |
| 1 | `assets/hd2d/interior/wall_panel_dark.png` | 384 × 288 | mur ; opaque, sans ancre | lambris de bois sombre jusqu'à 1,4 m, cimaise, enduit ocre au-dessus enfumé, plinthe (le café) | un raccord visible ; un objet posé, une ombre ; de la perspective (vue strictement de dessus ou de face) | 5.4 |
| 2 | `assets/hd2d/interior/door_backroom.png` | 106 × 211 (1,1 × 2,2 m) | porte ; ancre : milieu du bord bas | passage vers l'arrière-boutique masqué d'un rideau de toile rayée, chambranle de bois (VEX) | changer la hauteur du seuil ou la largeur du passage (cotes d'usage) ; un mur ou un fond dessiné autour ; du texte ; une ombre portée | 5.4 |
| 2 | `assets/hd2d/interior/props/cafe_bottle_shelf.png` | 192 × 192 (2 × 2 m) | meuble ; ancre : milieu du bord bas | étagères de bois derrière le comptoir : bouteilles d'alcool de toutes formes (le soir), pots de café, piles de tasses, chopes pendues | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 5.4 |
| 2 | `assets/hd2d/interior/props/cafe_cake_case.png` | 96 × 58 (1 × 0,6 m) | objet posé sur le comptoir ; ancre : milieu du bord bas | vitrine à gâteaux sous cloche de verre : une tarte aux pommes, des petits gâteaux à la crème | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 5.4 |
| 2 | `assets/hd2d/interior/props/cafe_drinkers_table.png` | 154 × 106 (1,6 × 1,1 m) | meuble ; ancre : milieu du bord bas | la table des buveurs : chopes renversées, cartes à jouer, un plat de saucisses entamé, flaques de bière (VEX : la tablée éméchée) | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 5.4 |
| 2 | `assets/hd2d/interior/wallitem_menu_cafe.png` | 77 × 96 (0,8 × 1 m) | élément de mur, bas à 1,2 m ; ancre : milieu du bord bas | ardoise du menu : dessins à la craie d'une tasse fumante, d'une chope et d'une part de gâteau, traits de craie à la place des mots | un cadre ou un mur dessiné autour ; du texte ou des chiffres lisibles ; une ombre portée | 5.4 |
| 3 | `assets/hd2d/props/cafe_backyard_crates.png` | 154 × 96 (1,6 × 1 m) | panneau (dehors) ; ancre : milieu du bord bas | derrière le café, près de la porte de service : caisses de bouteilles vides, deux tonnelets, un balai | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 5.4 |

### C.7 La maison Limashenka (jour 11, scène 11.3)

**Références à joindre** : `assets/hd2d/interior/props/armchair_sheeted.png`, `sofa_salon.png`, `display_cabinet.png`, `assets/hd2d/interior/wall_wallpaper_faded.png`, `assets/hd2d/interior/window_curtains_open.png`, `assets/hd2d/buildings/limashenka_house.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/toolbox_gears.png` | 77 × 48 (0,8 × 0,5 m) | meuble ; ancre : milieu du bord bas | boîte à outils de bois ouverte posée par terre : pinces, tournevis, burette, et un sachet de papier d'où sortent des engrenages neufs (VEX : les pièces de rechange commandées) | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 5.5 |
| 1 | `assets/hd2d/interior/wallitem_clock_limashenka.png` | 77 × 134 (0,8 × 1,4 m) | élément de mur, bas à 0,9 m ; ancre : milieu du bord bas | vieille horloge murale dans une grande caisse de bois sculpté de feuilles, cadran de laiton marqué de traits (aucun chiffre), aiguilles ouvragées, porte vitrée sur un balancier de laiton ; arrêtée | un cadre ou un mur dessiné autour ; du texte ou des chiffres lisibles ; une ombre portée | 5.5 |
| 1 | `assets/hd2d/interior/wallitem_clock_limashenka_open.png` | 77 × 134 | élément de mur, bas à 0,9 m ; ancre : milieu du bord bas | Comme `wallitem_clock_limashenka.png` (jointe, à dessiner d'abord) : la même horloge, caisse ouverte : engrenages de laiton, ressorts, vis, et au fond un peigne doré posé dans une petite caisse de résonance (celui d'une boîte à musique) ; même cadrage au pixel près | un cadre ou un mur dessiné autour ; du texte ou des chiffres lisibles ; une ombre portée | 5.5 |
| 2 | `assets/hd2d/interior/wall_wallpaper_floral.png` | 384 × 288 | mur ; opaque, sans ancre | papier peint à grandes fleurs fanées vert d'eau et rose sur fond crème, auréoles, plinthe et moulure (le salon des Limashenka) | un raccord visible ; un objet posé, une ombre ; de la perspective (vue strictement de dessus ou de face) | 5.5 |
| 2 | `assets/hd2d/interior/window_shutters.png` | 115 × 154 (1,2 × 1,6 m) | fenêtre, appui à 0,8 m ; ancre : milieu du bord bas | fenêtre aux volets intérieurs de bois entrouverts, rais de lumière entre les lames (la maison qui se rouvre) | changer l'appui ou le cadrage ; un mur dessiné autour ; une vue de paysage ou des personnages derrière la vitre ; du texte | 5.5 |
| 3 | `assets/hd2d/anim/clock_limashenka_swing.png` | 4 images de 77 × 134, 2 ips ; fichier : 308 × 134 | bande animée ; ancre : milieu du bord bas de chaque image | l'horloge réparée : le balancier va et vient, le reste identique au pixel près | deux images identiques ; un saut quand la boucle reprend ; un pied ou un support qui bouge d'une image à l'autre | 5.5 |
| 3 | `assets/hd2d/decals/rug_salon.png` | 288 × 192 (3 × 2 m) | décalque à bord plein ; ancre : centre | tapis à médaillon central bordeaux et vert, usé, franges | un bord net, un ovale parfait ou un rectangle plein (sauf un tapis) ; un contour noir ; une ombre portée | 5.5 |
| 3 | `assets/hd2d/interior/props/side_table_salon.png` | 58 × 67 (0,6 × 0,7 m) | meuble ; ancre : milieu du bord bas | guéridon à napperon, une petite boîte à couture et un portrait encadré posé | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 5.5 |
| 3 | `assets/hd2d/interior/wallitem_family_portrait.png` | 58 × 77 (0,6 × 0,8 m) | élément de mur, bas à 1,4 m ; ancre : milieu du bord bas | portrait peint d'une famille d'hommes-chats, une mère et un petit garçon, dans un cadre doré terni, accroché au mur du salon ; aucun texte (le cahier n° 5 donnait 256 × 256 : c'est la taille d'un portrait de dialogue, pas d'un tableau de salon) | un cadre ou un mur dessiné autour ; du texte ou des chiffres lisibles ; une ombre portée | 5.5 |

### C.8 Les insectes de la colline

**Références à joindre** : `assets/hd2d/anim/butterfly.png` (le papillon livré).

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/anim/butterfly_orange_b.png` | 4 images de 24 × 24, 12 ips ; fichier : 96 × 24 | bande animée, centrée | Comme `butterfly.png` (jointe, le papillon livré) : autre papillon orange vu de dessus, ailes plus arrondies bordées de brun, qui bat des ailes (ill. VEX : les papillons orange dans les hautes herbes) | deux images identiques ; un saut quand la boucle reprend ; un pied ou un support qui bouge d'une image à l'autre | 7.4 |
| 3 | `assets/hd2d/anim/dragonfly_amber.png` | 4 images de 32 × 24, 16 ips ; fichier : 128 × 24 | bande animée, centrée | Comme `dragonfly_blue.png` (à commander dans la même conversation) : libellule ambrée vue de dessus, même mouvement | deux images identiques ; un saut quand la boucle reprend ; un pied ou un support qui bouge d'une image à l'autre | 7.4 |
| 3 | `assets/hd2d/anim/dragonfly_blue.png` | 4 images de 32 × 24, 16 ips ; fichier : 128 × 24 | bande animée, centrée | libellule bleue vue de dessus, ailes transparentes nervurées (alpha net), qui vibrent | deux images identiques ; un saut quand la boucle reprend ; un pied ou un support qui bouge d'une image à l'autre | 7.4 |

### C.9 Les portraits de Kana et de Giniette (jour 10, scène 10.5)

**Références à joindre** : `assets/characters/tiat/tiat_portrait.png`, `assets/characters/kana/kana.png`, `assets/characters/giniette/giniette.png` (livrées).

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/characters/giniette/giniette_portrait.png` | 256 × 256 | portrait, fond transparent, buste de trois quarts vers la droite ; ancre : centre | Giniette : huit ans environ, cheveux miel doré en deux nattes nouées de rubans verts, grands yeux bruns, robe chasuble vert bouteille sur une chemise crème, un air timide ; buste de la tête aux épaules, même rendu que les portraits livrés | un fond ou un cadre ; un cadrage plus large que les épaules ; un visage de face (trois quarts vers la droite) ; du texte ; un rendu plus lisse que `tiat_portrait.png` |  |
| 2 | `assets/characters/kana/kana_portrait.png` | 256 × 256 | portrait, fond transparent, buste de trois quarts vers la droite ; ancre : centre | Kana : une dizaine d'années, cheveux turquoise vif coupés court en épis, taches de rousseur, sourire de chipeuse, col de chemise jaune moutarde sous une salopette de toile brune rapiécée ; buste de la tête aux épaules, même rendu que les portraits livrés | un fond ou un cadre ; un cadrage plus large que les épaules ; un visage de face (trois quarts vers la droite) ; du texte ; un rendu plus lisse que `tiat_portrait.png` |  |

### C.10 Les personnages : ballon, bâton, pluie, linge, marteau, café, colline (planches)

**Références à joindre** : les trois vues de la planche de base de chaque personnage (indiquées à chaque ligne).

| Prio | Planche (profil ; `_front` et `_back` à côté) | Hauteur debout | Rangées (images à ips) | Apparence et consignes propres | À ne pas faire | Joindre | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `assets/characters/willem/willem_life.png` + `.json` | 168 px | `repos` 2 à 2 (recopiée de `willem_home`) ; `frappe` 4 à 14 (non, `coup` [2]) | Willem joue au ballon avec les petites, sans jamais marquer ; planche complémentaire de `willem_home` (uniforme sans arme) | redessiner la rangée `repos` (elle est recopiée au pixel près de la planche existante) ; changer la hauteur debout ; un objet travaillé dessiné (marmite, pétrin, plafond) sauf s'il tient dans les mains | willem_home (trois vues) | 4.1 |
| 1 | `assets/characters/chtholly/chtholly_stick.png` + `.json` | 144 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `course` 5 à 14 ; `attaque` 4 à 14 (non, `coup` [1, 2, 3]) ; `pare` 2 à 2 (boucle) ; `degats` 1 à 1 ; `mort` 1 à 1 | Chtholly en tenue d'exercice : sa tenue de `_home` sans la veste, manches retroussées, cheveux attachés ; concentrée, rageuse quand elle rate (VEX, « Des émotions sans nom ») ; le bâton de bois brut de 1,2 m est tenu du même côté que l'épée dans la planche livrée | un bâton de métal ou taillé (il est de bois brut, 1,2 m) ; un bâton tenu d'un autre côté que l'épée de la planche livrée ; du sang ; la pointe du bâton sous la ligne des pieds ; une autre coiffure ou une autre tenue que celle demandée | chtholly, chtholly_home | 4.8 |
| 1 | `assets/characters/ithea/ithea_stick.png` + `.json` | 139 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `course` 5 à 14 ; `attaque` 4 à 14 (non, `coup` [1, 2, 3]) ; `pare` 2 à 2 (boucle) ; `degats` 1 à 1 ; `mort` 1 à 1 | Ithea, écharpe nouée serré, sourire ; elle s'allonge par terre après l'effort (son `mort`) ; le bâton de bois brut de 1,2 m est tenu du même côté que l'épée dans la planche livrée | un bâton de métal ou taillé (il est de bois brut, 1,2 m) ; un bâton tenu d'un autre côté que l'épée de la planche livrée ; du sang ; la pointe du bâton sous la ligne des pieds ; une autre coiffure ou une autre tenue que celle demandée | ithea, ithea_home | 4.8 |
| 1 | `assets/characters/nephren/nephren_stick.png` + `.json` | 125 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `course` 5 à 14 ; `attaque` 4 à 14 (non, `coup` [1, 2, 3]) ; `pare` 2 à 2 (boucle) ; `degats` 1 à 1 ; `mort` 1 à 1 | Nephren, couettes nouées en arrière, visage impassible même quand elle encaisse ; le bâton de bois brut de 1,2 m est tenu du même côté que l'épée dans la planche livrée | un bâton de métal ou taillé (il est de bois brut, 1,2 m) ; un bâton tenu d'un autre côté que l'épée de la planche livrée ; du sang ; la pointe du bâton sous la ligne des pieds ; une autre coiffure ou une autre tenue que celle demandée | nephren, nephren_home | 4.8 |
| 1 | `assets/characters/willem/willem_stick.png` + `.json` | 168 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `course` 5 à 14 ; `attaque` 4 à 14 (non, `coup` [1, 2, 3]) ; `pare` 2 à 2 (boucle) ; `degats` 1 à 1 ; `mort` 1 à 1 | Willem en tenue d'entraînement ample et terne (chemise de toile, pantalon serré aux chevilles), bâton sous le bras au `repos` ; il pare et contre « comme un serpent » sous des angles désagréables (VEX) ; son `mort` : assis, essoufflé, il se gratte la tête ; le bâton de bois brut de 1,2 m est tenu du même côté que l'épée dans la planche livrée | un bâton de métal ou taillé (il est de bois brut, 1,2 m) ; un bâton tenu d'un autre côté que l'épée de la planche livrée ; du sang ; la pointe du bâton sous la ligne des pieds ; une autre coiffure ou une autre tenue que celle demandée | willem, willem_home | 4.8 |
| 1 | `assets/characters/willem/willem_duel.png` + `.json` | 168 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `attaque` 4 à 14 (non, `coup` [2]) ; `pare` 2 à 2 (boucle) | Willem au duel du jour 8 (`ACTE1.md` 3.3 et 8.3) : la tenue ample de `willem_home` (chemise claire aux manches retroussées, pantalon sombre, pieds solides), et **le Carillon de série Percival** : une longue épée de fées faite de plaques de métal assemblées, gris acier, quelques runes gravées éteintes, tenue d'une main ; voir la fiche propre plus bas | une arme de cristal ou lumineuse au repos (Percival ne brille qu'un instant, et c'est un effet du moteur) ; une armure ; l'uniforme de la Garde | `willem_home.png`, `_front`, `_back` (étalon de taille et de tenue), `chtholly.png` (pour le style d'une épée de fées) | — |
| 1 | `assets/characters/cat_waiter/cat_waiter_work.png` + `.json` | 158 px | `repos` 2 à 2 (recopiée) ; `travaille` 4 à 6 ; `porte` 6 à 10 | le serveur homme-chat : homme-chat gris au long tablier blanc, gilet brun ; il balaie la terrasse le matin | redessiner la rangée `repos` (elle est recopiée au pixel près de la planche existante) ; changer la hauteur debout ; un objet travaillé dessiné (marmite, pétrin, plafond) sauf s'il tient dans les mains | cat_waiter (trois vues) | 4.3 |
| 2 | `assets/characters/almita/almita_rain.png` + `.json` | 91 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `saut` 4 à 12 (non : à pieds joints dans une flaque) | pèlerine jaune citron jusqu'aux chevilles, grosses bottes | du plastique ou du caoutchouc brillant ; un parapluie moderne ; une arme de métal ; un changement de hauteur debout ; le personnage qui rapetisse en marchant | almita, almita_life (trois vues) | 4.7 |
| 2 | `assets/characters/chtholly/chtholly_rain.png` + `.json` | 144 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 | pèlerine bleu marine à capuche relevée, quelques mèches bleues mouillées qui dépassent ; pas d'épée | du plastique ou du caoutchouc brillant ; un parapluie moderne ; une arme de métal ; un changement de hauteur debout ; le personnage qui rapetisse en marchant | chtholly, chtholly_home | 4.7 |
| 2 | `assets/characters/collon/collon_rain.png` + `.json` | 115 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `saut` 4 à 12 (non : à pieds joints dans une flaque) | pèlerine rouge, capuche rabattue en arrière exprès, cheveux trempés | du plastique ou du caoutchouc brillant ; un parapluie moderne ; une arme de métal ; un changement de hauteur debout ; le personnage qui rapetisse en marchant | collon, collon_life | 4.7 |
| 2 | `assets/characters/lakhesh/lakhesh_rain.png` + `.json` | 115 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `saut` 4 à 12 (non : à pieds joints dans une flaque) | pèlerine ocre jaune bien boutonnée, elle tient le bord de sa capuche à deux mains | du plastique ou du caoutchouc brillant ; un parapluie moderne ; une arme de métal ; un changement de hauteur debout ; le personnage qui rapetisse en marchant | lakhesh, lakhesh_life | 4.7 |
| 2 | `assets/characters/nygglatho/nygglatho_rain.png` + `.json` | 178 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 (sans `course`, sans `saut`) | châle de laine sur les épaules et grand parapluie de toile noire à manche de bois tenu au-dessus d'elle (rangées sans `course`, sans `saut`) | du plastique ou du caoutchouc brillant ; un parapluie moderne ; une arme de métal ; un changement de hauteur debout ; le personnage qui rapetisse en marchant | nygglatho, nygglatho_life | 4.7 |
| 2 | `assets/characters/pannibal/pannibal_rain.png` + `.json` | 120 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `saut` 4 à 12 (non : à pieds joints dans une flaque) | pèlerine violette, la brindille à la bouche, l'épée de bois sous la pèlerine (seule la poignée dépasse, du même côté que d'habitude) | du plastique ou du caoutchouc brillant ; un parapluie moderne ; une arme de métal ; un changement de hauteur debout ; le personnage qui rapetisse en marchant | pannibal, pannibal_life | 4.7 |
| 2 | `assets/characters/tiat/tiat_rain.png` + `.json` | 106 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `saut` 4 à 12 (non : à pieds joints dans une flaque) | pèlerine verte trop grande, capuche qui lui tombe sur les yeux | du plastique ou du caoutchouc brillant ; un parapluie moderne ; une arme de métal ; un changement de hauteur debout ; le personnage qui rapetisse en marchant | tiat, tiat_life | 4.7 |
| 2 | `assets/characters/nygglatho/nygglatho_laundry.png` + `.json` | 178 px | `repos` 2 à 2 (recopiée) ; `travaille` 4 à 6 | Nygglatho rentre le linge : même tenue que la planche livrée | redessiner la rangée `repos` (elle est recopiée au pixel près de la planche existante) ; changer la hauteur debout ; un objet travaillé dessiné (marmite, pétrin, plafond) sauf s'il tient dans les mains | nygglatho, nygglatho_life | 4.2 |
| 2 | `assets/characters/willem/willem_repair.png` + `.json` | 168 px | `repos` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 | Willem répare le plafond qui fuit : uniforme, manches retroussées, un clou entre les dents | redessiner la rangée `repos` (elle est recopiée au pixel près de la planche existante) ; changer la hauteur debout ; un objet travaillé dessiné (marmite, pétrin, plafond) sauf s'il tient dans les mains | willem_home | 4.1 |
| 2 | `assets/characters/cafe_owner/cafe_owner.png` + `.json` | 187 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) : `travaille` (il essuie une chope) et `porte` (un plateau de chopes) | homme-ours brun bedonnant, chemise aux manches retroussées, long tablier, torchon sur l'épaule ; `travaille` : il essuie une chope au torchon ; `porte` : un plateau de chopes | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | baker, cat_waiter, snack_vendor | 6.1 |
| 2 | `assets/characters/drinker_cat/drinker_cat.png` + `.json` | 158 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | homme-chat roux balourd, casquette de travers, veste de velours râpée ; `assis` : il chante, une patte levée | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | cat_waiter, baker | 6.1 |
| 2 | `assets/characters/drinker_dog/drinker_dog.png` + `.json` | 163 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | homme-chien hirsute gris, chemise ouverte, gilet déboutonné, une chope de bois dans la même main dans toutes les images ; `parle` : rire bruyant, chope levée ; `assis` : affalé | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | snack_vendor, baker | 6.1 |
| 2 | `assets/fauna/blackbird/blackbird.png` + `.json` (profil seul : pas de `_front` ni de `_back`) | 19 px | `repos` 2 à 2 ; `marche` 4 à 8 ; `course` 4 à 14 ; `fuite` 4 à 12 (boucle) | merle noir au bec jaune (les oiseaux bruyants du matin, V3) ; `repos` : il chante, bec ouvert à l'image 1 | du sang ; les vues de face et de dos (le profil seul suffit) ; un animal plus grand ou plus petit que la hauteur demandée ; un sol ou une ombre dessinés | `tiat.png` (contour et ombrage) et le remplaçant actuel `assets/fauna/blackbird/blackbird.png` | 7.3 |
| 2 | `assets/fauna/owl/owl.png` + `.json` (profil seul : pas de `_front` ni de `_back`) | 38 px | `repos` 2 à 2 ; `fuite` 4 à 12 (boucle) | chouette hulotte brun-roux aux grands yeux noirs, pour la nuit (original) ; `repos` : la tête qui pivote ; `fuite` : envol silencieux | du sang ; les vues de face et de dos (le profil seul suffit) ; un animal plus grand ou plus petit que la hauteur demandée ; un sol ou une ombre dessinés | `tiat.png` (contour et ombrage) et le remplaçant actuel `assets/fauna/owl/owl.png` | 7.3 |

**Les fiches propres des planches de ce groupe** (image par image ; les animations qui ne sont pas listées ici suivent la fiche commune de la section 3.2).

**Fiche propre de `willem/willem_life` : Willem joue au ballon**

Willem fait des passes avec les petites, sans jamais marquer (`VIE.md`, 2.1 ; V1, « Les filles de l'entrepôt »).
Planche complémentaire de `willem_home` (uniforme sans arme) : joindre `willem_home.png`, `_front`, `_back`.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de `willem_home` (étalon) |
| `frappe` | 4, 14 | passe du pied nonchalante, sans élan ; 0 la jambe en arrière ; 1 pied d'appui planté ; 2 **frappe** : la jambe tendue devant, à 20 cm du sol (`coup` : [2]) ; 3 accompagnement, bras un peu écartés ; le ballon n'est pas dessiné |

**Fiche propre de `willem/willem_duel` : Willem et le Carillon Percival (le duel ingagnable, jour 8)**

Willem ne pare jamais : il fait un pas de côté, puis, au premier coup chargé de Chtholly, il **retourne son élan** d'un
geste presque doux (`ACTE1.md` 3.3 ; V1, « Les valeureux et leurs successeurs »). Le Carillon est un Carillon de série,
banal à côté de Seniorious : pas de gemme qui luit, pas de flamme. Joindre `willem_home.png`, `_front`, `_back`.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, détendu, Percival posé sur l'épaule droite, la pointe vers l'arrière ; 0 et 1 : la respiration (1 px) |
| `marche` | 6, 10 | le même port, l'épée toujours sur l'épaule ; le pas de côté du duel se joue avec cette rangée |
| `parle` | 2, 6 | l'épée sur l'épaule, la main libre qui fait signe d'approcher (« viens ») |
| `attaque` | 4, 14 | la déviation qui retourne l'élan : 0 garde basse, la lame de biais devant lui ; 1 la lame croise (un trait) ; 2 **le geste** : la lame balaie vers l'extérieur et la main gauche ouverte pousse, à peine (`coup` : [2]) ; 3 retour au calme, la lame redescend |
| `pare` | 2, 2 | garde haute à deux mains, la lame en travers (la variante « Encore une fois ! » et l'entraînement avec Seniorious, jour 11) ; en boucle |

**Fiche propre de `willem/willem_repair` : Willem répare**

Scène 12 (il répare le plafond qui fuit) : uniforme, manches retroussées, un clou entre les dents (V4, transposé).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, marteau à la main, l'autre main sur la hanche |
| `travaille` | 4, 6 | martèle au-dessus de sa tête, bras levé, comme pour clouer une planche au plafond qui fuit (V2 ; V3) |
| `porte` | 6, 10 | marche avec trois planches sur l'épaule et le marteau à la ceinture |

**Fiche propre de `nygglatho/nygglatho_laundry` : le linge**

Même tenue que la planche livrée.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante |
| `travaille` | 4, 6 | décroche un drap d'une corde (bras levés, corde non dessinée), le plie et le laisse tomber dans un panier à ses pieds (panier dessiné) (V2 : on rentre les draps avant l'averse) |

**Fiche propre de `cat_waiter/cat_waiter_work` : le serveur homme-chat**

Hauteur debout : **158 px** (1,65 m). Homme-chat gris au long tablier blanc, gilet brun ; il balaie la
terrasse le matin et offre des jus aux fées en cachette du patron (VEX, « Cinq cents ans » ; scène 9.3).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante (plateau et tasse en main) |
| `travaille` | 4, 6 | il balaie d'un balai de paille, de gauche à droite et retour ; balai dessiné, sol non dessiné |
| `porte` | 6, 10 | marche en portant un plateau de trois verres de jus (orange, rouge, jaune) et une carafe |


**Les quatre planches de bâton** (`chtholly_stick`, `ithea_stick`, `nephren_stick`, `willem_stick` ; scènes 9.2, 10.1 et 11.4 ; format accepté par le moteur, lot E8). Dans la clairière derrière l'entrepôt, Willem entraîne les trois aînées avec des bâtons ramassés par terre : bloquer, dévier, parer, esquiver sans casser le rythme, puis à trois contre un ; les genoux lâchent (VEX, « Chtholly Nota Seniorious » ; « Cinq cents ans »). Ce sont des planches de tenue à la hauteur debout de chacun, avec un **bâton de bois brut de 1,2 m** à la place de l'arme, tenu du même côté que l'épée dans la planche livrée. Leur fiche d'animations :

| Animation | Images | ips | Boucle | Ce qu'on dessine |
| --- | --- | --- | --- | --- |
| `repos` | 2 | 2 | oui | debout en garde, le bâton tenu des deux mains en biais ; image 1 : respiration (épaules d'1 px) ; Willem : le bâton sous le bras |
| `marche` | 6 | 10 | oui | cycle de marche, le bâton porté en garde basse (la pointe ne passe jamais sous la ligne des pieds) |
| `course` | 5 | 14 | oui | course penchée, le bâton tenu en arrière d'une main |
| `attaque` | 4 | 14 | non | `coup` : [1, 2, 3] ; coup de bâton de haut en bas : 0 le bâton levé au-dessus de l'épaule ; 1 il descend (coup) ; 2 il arrive à l'horizontale devant, bras tendus (coup) ; 3 fin de course, le bâton baissé (coup) |
| `pare` | 2 | 2 | oui | **2 images, 2 ips, en boucle (tranché : section 10)** : la parade tenue ; 0 le bâton tenu à deux mains en travers du corps pour bloquer ; 1 la même pose, le bâton remonté d'1 px (respiration) |
| `degats` | 1 | 1 | non | touché, il recule d'un pas, le bâton baissé |
| `mort` | 1 | 1 | non | assise par terre, à bout de souffle, sans blessure : Chtholly le bâton posé en travers des genoux ; Ithea s'allonge par terre après l'effort ; Nephren reste droite et impassible ; Willem, essoufflé, se gratte la tête |

Pas de `charge` : à l'entraînement la charge est remplacée par la parade. **Une consigne propre par personnage** : Chtholly en tenue d'exercice (sa tenue de `_home` sans la veste, manches retroussées, cheveux attachés ; concentrée, rageuse quand elle rate, VEX « Des émotions sans nom ») ; Ithea (écharpe nouée serré, sourire) ; Nephren (couettes nouées en arrière, visage impassible même quand elle encaisse) ; Willem (tenue d'entraînement ample et terne, chemise de toile, pantalon serré aux chevilles ; il pare et contre « comme un serpent » sous des angles désagréables, VEX).

**Les sept tenues de pluie** (jours 7 et 10 ; `almita_rain`, `chtholly_rain`, `collon_rain`, `lakhesh_rain`, `nygglatho_rain`, `pannibal_rain`, `tiat_rain`). Les averses sont soudaines : le vent devient humide, la pluie tombe comme un seau renversé, il fait nuit en plein jour, et après la pluie le terrain est boueux (V2, « De ce côté-ci de l'écran » ; « L'écoulement du temps depuis lors »). Pèlerines de toile cirée à capuche, bottes de cuir graissé (rien de plastique ni de caoutchouc brillant). Willem met son pardessus (`willem_coat`, livré). Le `saut` des petites est « à pieds joints dans une flaque » (original).

**Le café du village et la colline** : les trois habitants du café (`cafe_owner`, `drinker_cat`, `drinker_dog` : le patron, et les buveurs du soir) ont leurs consignes dans le tableau ; leurs rangées sont celles de la section 3.3. Les deux oiseaux de la colline (`blackbird`, `owl`) sont des planches de **profil seul** : voir la fiche de la faune (section 3.4).


## 7. Lot D : le reste (navires en volume, formats à confirmer, ville entière, forêt, montagne, faune, gens, reprises)

**Total du lot D : 85 images et 29 planches de personnages ou d'animaux (et 6 reprises de planches livrées).**

**Pourquoi ce lot.** Il regroupe ce qui peut attendre : le monde autour de l'acte 1 (la ville entière, la forêt profonde, la
montagne, la faune) et les commandes **qui attendent un accord du moteur** (groupe D.2 : ne les commande qu'après la
décision de la section 9). Les groupes sont indépendants ; l'ordre de commande conseillé est D.1, D.4, D.5, D.9, puis le
reste.

### D.1 Les navires en volume : les autres vues

**Références à joindre** : `assets/hd2d/ships/garde_transport_side.png` (livrée au lot C), `assets/hd2d/props/airship_barocupot.png`, `assets/hd2d/props/mooring_arm.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/ships/garde_transport_34.png` | 1536 × 864 (16 × 9 m) | trois quarts avant ; ancre : milieu du bord bas | D'après `garde_transport_side.png` (jointe, livrée au lot C) : le même navire de trois quarts avant, en léger surplomb, rotors **avec** leurs pales immobiles, bande rouge, hublots éclairés | un ballon ; des nuages dessinés autour ; changer les couleurs du flanc | 9.1 |
| 3 | `assets/hd2d/ships/garde_transport_deck.png` | 1536 × 480 (16 × 5 m) | pont, vu de dessus ; ancre : milieu du bord bas | D'après `garde_transport_side.png` (jointe) : le pont du même navire vu de dessus, proue à droite : tôles rivetées, passavants, toit de la cabine, les bras des deux rotors qui dépassent de chaque bord, écoutille, bastingage de fer, caisses arrimées ; fond transparent autour de la coque | un ballon ; des personnages ; un fond autour de la coque | 9.1 |
| 3 | `assets/hd2d/ships/garde_transport_stern.png` | 480 × 672 (5 × 7 m) | poupe, de face ; ancre : milieu du bord bas | D'après `garde_transport_side.png` (jointe) : le même navire vu de l'arrière : poupe arrondie de tôle, gouvernails de direction, la nacelle de la chaudière sous la coque, de chaque côté, un bras de rotor et ses deux pales vues par la tranche, immobiles | un ballon ; des nuages autour ; changer les couleurs du flanc | 9.1 |
| 3 | `assets/hd2d/ships/barocupot_34.png` | 2688 × 1248 (28 × 13 m) | trois quarts avant ; ancre : milieu du bord bas | le Barocupot de trois quarts avant, en léger surplomb, dans les nuages : hélices latérales avec leurs pales, bande rouge, hublots éclairés ; massif | un ballon ; changer la bande rouge ; des nuages dessinés tout autour | 9.2 |
| 3 | `assets/hd2d/ships/barocupot_deck.png` | 2304 × 576 (24 × 6 m) | pont, vu de dessus ; ancre : milieu du bord bas | le pont supérieur du Barocupot vu de dessus, proue à droite, dans le style de `airship_barocupot.png` (joint) : tôles d'acier rivetées gris-bleu, bande rouge au bordage, toit de la passerelle de commandement vitrée à l'avant, écoutilles, canon court sous bâche, manches à air, rambardes ; fond transparent autour | un ballon ; des personnages ; un fond autour de la coque | 9.2 |
| 3 | `assets/hd2d/ships/barocupot_stern.png` | 576 × 1056 (6 × 11 m) | poupe, de face ; ancre : milieu du bord bas | le Barocupot vu de l'arrière : poupe haute, deux ponts de hublots, ailerons de queue, la grande trappe de soute fermée, les deux nacelles des fours sous la coque | un ballon ; un fond autour ; changer la bande rouge | 9.2 |

### D.2 Ce qui attend le moteur : premier plan suspendu, sol, faces de palier, escaliers (ne commander qu'après son accord, section 9)

**Références à joindre** : `assets/hd2d/cliff/cliff.png`, `assets/hd2d/cliff/bank_earth.png` (livrée au lot B), `assets/hd2d/ground/stream_bed.png`, `assets/hd2d/ground/forest_floor.png`, `assets/hd2d/props/outdoor_stairs.png`, `assets/hd2d/props/stone_steps.png`, `assets/hd2d/buildings/house_stone_b.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/props/fg_canopy_a.png` | 768 × 384 (8 × 4 m) | premier plan **suspendu** (accroché par le haut, ancre libre) ; format à confirmer par le moteur (section 9) | masse de feuillage sombre qui pend du haut de l'image, vue d'en dessous : la voûte au-dessus du sentier, branches, feuilles d'automne presque noires, quelques trouées par où passent les étoiles (V1) | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 5.1 |
| 2 | `assets/hd2d/cliff/step_earth.png` | 384 × 48 (4 × 0,5 m) | face de palier ; ancre : milieu du bord bas | talus de terre brune d'un demi-mètre, racines fines, cailloux, touffes d'herbe qui débordent du haut | un raccord visible à gauche ou à droite ; un haut ou un bas qui ne correspond pas aux niveaux (haut : palier supérieur, bas : inférieur) ; un objet posé devant | 5.2 |
| 2 | `assets/hd2d/cliff/step_marsh.png` | 384 × 48 | face de palier ; ancre : milieu du bord bas | berge de tourbe noire et de racines au bord d'un marais, herbe qui retombe | un raccord visible à gauche ou à droite ; un haut ou un bas qui ne correspond pas aux niveaux (haut : palier supérieur, bas : inférieur) ; un objet posé devant | 5.2 |
| 2 | `assets/hd2d/cliff/step_rock.png` | 384 × 48 | face de palier ; ancre : milieu du bord bas | petite marche de roche claire (#C2B49F) en strates, mousse dans les fissures | un raccord visible à gauche ou à droite ; un haut ou un bas qui ne correspond pas aux niveaux (haut : palier supérieur, bas : inférieur) ; un objet posé devant | 5.2 |
| 2 | `assets/hd2d/cliff/wall_earth_1m.png` | 384 × 96 (4 × 1 m) | face de palier ; ancre : milieu du bord bas | talus de terre d'un mètre, grosses racines qui sortent, fougères accrochées | un raccord visible à gauche ou à droite ; un haut ou un bas qui ne correspond pas aux niveaux (haut : palier supérieur, bas : inférieur) ; un objet posé devant | 5.2 |
| 3 | `assets/hd2d/props/fg_canopy_b.png` | 576 × 288 (6 × 3 m) | premier plan suspendu ; format à confirmer par le moteur (section 9) | Comme `fg_canopy_a.png` (jointe, à dessiner d'abord), mais : même chose, plus clairsemé, une grosse branche en travers | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 5.1 |
| 3 | `assets/hd2d/ground/path_overgrown.png` | 384 × 384 | tuile de sol ; opaque, sans ancre ; format à confirmer par le moteur (section 9) | sentier étroit de terre tassée envahi d'herbe : deux bandes de terre usée par les pas, herbe et mousse au milieu et sur les bords, racines, feuilles mortes | un raccord visible sur un des quatre bords ; un objet ou une ombre ; un motif qui se répète en damier | 5.1 |
| 3 | `assets/hd2d/ground/river_water.png` | 384 × 384 | tuile de sol ; opaque, sans ancre ; format à confirmer par le moteur (section 9) | eau de rivière courante, plus profonde que `stream_bed.png` : vert sombre et bleu-gris, reflets clairs en traits allongés dans le sens horizontal (le courant), quelques galets devinés au fond | un raccord visible sur un des quatre bords ; un objet ou une ombre ; un motif qui se répète en damier | 7.2 |
| 3 | `assets/hd2d/cliff/step_drystone.png` | 384 × 48 | face de palier ; ancre : milieu du bord bas | muret de pierres sèches d'un demi-mètre (bord de champ, village) | un raccord visible à gauche ou à droite ; un haut ou un bas qui ne correspond pas aux niveaux (haut : palier supérieur, bas : inférieur) ; un objet posé devant | 5.2 |
| 3 | `assets/hd2d/cliff/wall_rock_1m.png` | 384 × 96 | face de palier ; ancre : milieu du bord bas | ressaut de roche d'un mètre, lichen, une fissure avec une fougère | un raccord visible à gauche ou à droite ; un haut ou un bas qui ne correspond pas aux niveaux (haut : palier supérieur, bas : inférieur) ; un objet posé devant | 5.2 |
| 3 | `assets/hd2d/cliff/town_retaining_wall.png` | 384 × 96 (4 × 1 m) | mur sans raccord à gauche et à droite, opaque ; ancre : milieu du bord bas ; format à confirmer par le moteur (section 9) | mur de soutènement de pierre appareillée entre deux paliers de la rue, barbacanes, traînées d'humidité, lierre qui retombe du haut | un raccord visible à gauche ou à droite ; un haut ou un bas qui ne correspond pas aux niveaux (haut : palier supérieur, bas : inférieur) ; un objet posé devant | 6.6 |
| 3 | `assets/hd2d/props/town_stairs_a.png` | 192 × 192 (2 × 2 m) | panneau ; ancre : milieu du bord bas ; format à confirmer par le moteur (section 9) | volée de six marches de pierre de 2 m de large qui monte d'1 m vers le fond (le nord) entre deux murets, marches usées au milieu, herbe dans les joints | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 6.6 |
| 3 | `assets/hd2d/props/town_stairs_b.png` | 384 × 192 (4 × 2 m) | panneau ; ancre : milieu du bord bas ; format à confirmer par le moteur (section 9) | grand escalier de place, plus large, rampe de fer au milieu | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 6.6 |

### D.3 Le sentier et deux ciels : le bonus

**Références à joindre** : `assets/hd2d/props/willow.png`, `assets/hd2d/decals/bog_pool_a.png` (livrée au lot A), `assets/hd2d/decals/lily_pads.png`, `assets/hd2d/sky/cloud_sea.png`, `assets/hd2d/sky/sky_night.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/decals/bog_pool_b.png` | 192 × 144 (2 × 1,5 m) | décalque ; ancre : centre | mare plus petite, allongée, lentilles d'eau sur un bord | un bord net, un ovale parfait ou un rectangle plein (sauf un tapis) ; un contour noir ; une ombre portée | 5.1 |
| 3 | `assets/hd2d/props/willow_pollard.png` | 288 × 384 (3 × 4 m) | panneau ; ancre : milieu du bord bas | saule têtard : tronc court noueux, tête hérissée de longs rameaux jaunes | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 5.1 |
| 3 | `assets/hd2d/sky/cloud_sea_morning.png` | 1024 × 1024 | mer de nuages ; ancre : milieu du bord bas | la mer de nuages au matin : crêtes pêche pâle et gris rosé, creux lavande froid | une couture visible sur un des quatre bords ; des îles, des nuages isolés ou des navires ajoutés ; des couleurs de nuit | 8.2 |
| 3 | `assets/hd2d/sky/sky_night_comets.png` | 2048 × 1024 | ciel ; ancre : milieu du bord bas | nuit d'hiver claire et vive, étoiles très denses, deux comètes à longue queue pâle au nord (au milieu de l'image) (V3) | une couture visible à gauche et à droite ; des îles ou des navires | 8.2 |

### D.4 Le port et la ville : le reste des maisons, des enseignes et des étals

**Références à joindre** : `assets/hd2d/buildings/port_hangar.png`, `house_stone_b.png`, `house_timber_b.png`, `stone_house.png` (et leurs flancs), `assets/hd2d/props/market_stall.png`, `market_stall_fruit.png`, `market_stall_veg.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/buildings/port_house_a.png` | 576 × 336 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 3,5 m, faîte 6 m, profondeur 5 m ; matières `wall_stone`, `roof_slate_b` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison basse de pierre au bord du vide, volets fermés par le vent, câbles d'ancrage scellés au mur, fenêtres éteintes | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 5.6 |
| 3 | `assets/hd2d/buildings/port_house_a_side.png` | 480 × 576 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 3,5 m, faîte 6 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `port_house_a.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_stone`, `roof_slate_b`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 5.6 |
| 3 | `assets/hd2d/buildings/town_house_g.png` | 480 × 768 | façade, type pignon (l'image va jusqu'au faîtage, avec le triangle du pignon, transparente de part et d'autre) ; mur 5 m, faîte 8 m, profondeur 5 m ; matières `wall_brick`, `roof_tiles` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison de briques rouge-brun à deux niveaux, fenêtres à linteaux de pierre, linge à une fenêtre ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.4 |
| 3 | `assets/hd2d/buildings/town_house_g_side.png` | 480 × 480 | flanc est, mur gouttereau (le mur long, jusqu'à l'égout du toit) ; hauteur du mur 5 m, profondeur 5 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le mur long de `town_house_g.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_brick`, `roof_tiles`), même socle et même corniche ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière, un tuyau) ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.4 |
| 3 | `assets/hd2d/buildings/town_house_h.png` | 672 × 480 | façade, type long (l'image s'arrête à l'égout du toit, bordure du toit comprise) ; mur 5 m, faîte 7,5 m, profondeur 6 m ; matières `wall_plaster_c`, `roof_slate` ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | maison d'enduit rose pâle écaillé à deux niveaux, pierre visible par plaques, escalier extérieur de pierre vers la porte de l'étage ; le socle de pierre nue de 0,5 m en bas du mur est compris dans la hauteur du mur | changer les cotes ou le cadrage ; peindre un ciel, un sol ou une ombre portée ; allumer les vitres (elles sont éteintes : bleutées, avec un reflet clair) ; écrire sur une enseigne ; un toit qui descend sous le haut du mur | 6.4 |
| 3 | `assets/hd2d/buildings/town_house_h_side.png` | 576 × 720 | flanc est, pignon (le triangle jusqu'au faîtage, haut transparent de part et d'autre) ; mur 5 m, faîte 7,5 m, profondeur 6 m ; mur collé aux bords gauche, droit et bas ; ancre : milieu du bord bas | le pignon de `town_house_h.png` (jointe), vu de face : même bâtiment, mêmes matières (`wall_plaster_c`, `roof_slate`) ; le côté gauche de l'image est l'angle de la façade ; un ou deux détails discrets (une fenêtre éteinte, une gouttière) ; l'avancée du toit ne descend pas sous le haut du mur ; **modelé doux et symétrique**, rien qui ne supporte d'être retourné | un détail qui ne supporte pas d'être retourné (le jeu plaque aussi l'image sur le flanc ouest) ; un modelé lourd d'un seul côté ; un toit qui descend sous le haut du mur aux angles ; une fenêtre allumée | 6.4 |
| 3 | `assets/hd2d/props/town_arch.png` | 288 × 336 (3 × 3,5 m) | panneau ; ancre : milieu du bord bas | passage voûté de pierre entre deux maisons, l'ombre du passage, une lanterne de fer au sommet de l'arc | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 6.6 |
| 3 | `assets/hd2d/props/hanging_sign_hat.png` | 96 × 115 | panneau ; ancre : milieu du bord bas | enseigne en forme de chapeau à ruban | des lettres ou des mots ; un fond | 6.5 |
| 3 | `assets/hd2d/props/hanging_sign_mortar.png` | 96 × 115 | panneau ; ancre : milieu du bord bas | enseigne en forme de mortier et de pilon | des lettres ou des mots ; un fond | 6.5 |
| 3 | `assets/hd2d/props/market_stall_dairy.png` | 240 × 230 (2,5 × 2,4 m) | panneau ; ancre : milieu du bord bas | étal du marché du matin sous bâche crème : mottes de beurre, bidons de lait, fromages, paniers d'œufs (V3) | des lettres ou des mots sur les prix ; un étal à roulettes moderne | 6.5 |
| 3 | `assets/hd2d/props/market_stall_flour.png` | 240 × 230 | panneau ; ancre : milieu du bord bas | étal sous bâche grise : sacs de farine et de sucre, une balance à plateaux, une pelle (V3) | des lettres ou des mots sur les prix ; un étal à roulettes moderne | 6.5 |
| 3 | `assets/hd2d/props/market_stall_honey.png` | 240 × 230 | panneau ; ancre : milieu du bord bas | étal sous bâche ocre : pots de miel, sacs de noix et de fruits secs ouverts (V3) | des lettres ou des mots sur les prix ; un étal à roulettes moderne | 6.5 |

### D.5 Les intérieurs de la ville (boulangerie, café, librairie, projection, apothicaire, boucherie, horloger, accessoires)

**Références à joindre** : `assets/hd2d/buildings/shop_bakery.png`, `shop_bookshop.png`, `clockmaker.png`, `butcher.png`, `projection_hall.png`, `assets/hd2d/interior/props/china_cabinet.png`, `bookshop_counter.png`, `crystal_projector.png`, `assets/hd2d/interior/floor_stone_town.png` et wall_stone_inside.png (livrées au lot A).

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/props/bakery_counter.png` | 192 × 106 (2 × 1,1 m) | meuble ; ancre : milieu du bord bas | comptoir de boulangerie : balance, panier de petits pains, papier d'emballage (V3 : Lakhesh y sert le matin) | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 2 | `assets/hd2d/interior/props/bakery_oven.png` | 192 × 192 (2 × 2 m) | meuble ; ancre : milieu du bord bas | four à pain de briques, gueule voûtée fermée d'une porte de fonte entrouverte, braises au fond, pelle à enfourner appuyée | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 2 | `assets/hd2d/interior/props/bread_shelves.png` | 192 × 211 (2 × 2,2 m) | meuble ; ancre : milieu du bord bas | étagères de pains : miches rondes, pains longs, brioches, petits pains en paniers | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 2 | `assets/hd2d/interior/props/cafe_town_counter.png` | 288 × 115 (3 × 1,2 m) | meuble ; ancre : milieu du bord bas | comptoir du café habituel : grosse cafetière de cuivre, tasses, sandwichs au bacon sous cloche (V3 : on n'y sert pas de thé) | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 2 | `assets/hd2d/interior/props/cafe_town_table.png` | 134 × 96 (1,4 × 1 m) | meuble ; ancre : milieu du bord bas | lourde table de bois et deux petites chaises trop petites pour un lézard géant (V3 ; V5) | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 2 | `assets/hd2d/interior/props/kneading_trough.png` | 154 × 96 (1,6 × 1 m) | meuble ; ancre : milieu du bord bas | pétrin de bois plein de pâte, farine partout, un rouleau | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/wall_plaster_ochre.png` | 384 × 288 | mur ; opaque, sans ancre | enduit ocre clair, propre mais vieilli, plinthe de bois peint (boutiques) | un raccord visible ; un objet posé, une ombre ; de la perspective (vue strictement de dessus ou de face) | 6.7 |
| 3 | `assets/hd2d/anim/oven_glow.png` | 4 images de 96 × 58 (1 × 0,6 m), 6 ips ; fichier : 384 × 58 | bande animée ; ancre : milieu du bord bas de chaque image | lueur des braises dans la gueule du four, qui pulse doucement (sans le four) | deux images identiques ; un saut quand la boucle reprend ; un pied ou un support qui bouge d'une image à l'autre | 6.7 |
| 3 | `assets/hd2d/anim/projection_flicker.png` | 4 images de 288 × 192 (3 × 2 m), 8 ips ; fichier : 1152 × 192 | bande animée, **alpha doux** ; ancre : milieu du bord bas de chaque image | le film muet projeté sur la toile : un rectangle de lumière grise qui tremble, deux silhouettes floues de lézards sur un pont voûté entre des lampes (V2 : une romance de lézards) ; sans écran ni cadre | deux images identiques ; un saut quand la boucle reprend ; un pied ou un support qui bouge d'une image à l'autre | 6.7 |
| 3 | `assets/hd2d/interior/props/accessories_counter.png` | 154 × 173 (1,6 × 1,8 m) | meuble ; ancre : milieu du bord bas | comptoir surmonté d'un grand miroir ovale à cadre doré (verre gris bleuté uni) | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/apothecary_counter.png` | 192 × 106 (2 × 1,1 m) | meuble ; ancre : milieu du bord bas | comptoir d'apothicaire : balance de précision, mortier, fioles, papier plié | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/apothecary_shelves.png` | 192 × 230 (2 × 2,4 m) | meuble ; ancre : milieu du bord bas | étagères de bocaux de faïence à étiquettes vierges et de fioles colorées | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/bookshop_shelves.png` | 192 × 230 (2 × 2,4 m) | meuble ; ancre : milieu du bord bas | rayonnages de librairie du sol au plafond, échelle roulante accrochée à une tringle | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/bookshop_table.png` | 154 × 86 (1,6 × 0,9 m) | meuble ; ancre : milieu du bord bas | table de nouveautés : livres d'images et romans en piles, couvertures colorées sans titres | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/butcher_block.png` | 96 × 96 (1 × 1 m) | meuble ; ancre : milieu du bord bas | billot de bois sur pieds, couperet planté, torchon ; aucun sang | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/butcher_counter.png` | 192 × 106 (2 × 1,1 m) | meuble ; ancre : milieu du bord bas | comptoir à dessus de marbre, balance, papier d'emballage, couteaux rangés | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/cinema_benches.png` | 288 × 86 (3 × 0,9 m) | meuble ; ancre : milieu du bord bas | rangée de bancs de bois vus de dos (dossiers vers la caméra), pour la salle de projection | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/cinema_screen.png` | 384 × 288 (4 × 3 m) | meuble ; ancre : milieu du bord bas | toile blanche tendue sur un cadre de bois, rideaux de velours rouge passé de part et d'autre, estrade basse (V2) | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/hat_stands.png` | 154 × 154 (1,6 × 1,6 m) | meuble ; ancre : milieu du bord bas | présentoir de chapeaux sur des têtes de bois, dont un grand chapeau bleu foncé | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/herb_drawers.png` | 154 × 173 (1,6 × 1,8 m) | meuble ; ancre : milieu du bord bas | meuble d'herboriste à dizaines de petits tiroirs à boutons de laiton, étiquettes vierges | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/longcase_clock.png` | 58 × 211 (0,6 × 2,2 m) | meuble ; ancre : milieu du bord bas | horloge de parquet en bois sombre, cadran de laiton sans chiffres, balancier visible | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/ribbon_display.png` | 115 × 134 (1,2 × 1,4 m) | meuble ; ancre : milieu du bord bas | vitrine de rubans en bobines, broches, peignes, gants | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/props/watch_workbench.png` | 154 × 106 (1,6 × 1,1 m) | meuble ; ancre : milieu du bord bas | établi d'horloger : loupe sur bras, engrenages, ressorts, pinces fines, une horloge démontée | de la perspective conique (plateau en trapèze) ; une ombre au sol ; un personnage ; du texte lisible | 6.7 |
| 3 | `assets/hd2d/interior/wallitem_clocks.png` | 192 × 115 (2 × 1,2 m) | élément de mur, bas à 1,2 m ; ancre : milieu du bord bas | mur d'horloges de formes variées (rondes, carrées, à coucou de bois), cadrans sans chiffres, aiguilles à des heures différentes | un cadre ou un mur dessiné autour ; du texte ou des chiffres lisibles ; une ombre portée | 6.7 |
| 3 | `assets/hd2d/interior/wallitem_dried_herbs.png` | 154 × 77 (1,6 × 0,8 m) | élément de mur, bas à 1,6 m ; ancre : milieu du bord bas | bouquets d'herbes séchées pendus tête en bas à une perche | un cadre ou un mur dessiné autour ; du texte ou des chiffres lisibles ; une ombre portée | 6.7 |
| 3 | `assets/hd2d/interior/wallitem_meat_hooks.png` | 192 × 106 (2 × 1,1 m) | élément de mur, bas à 1,2 m ; ancre : milieu du bord bas | barre à crochets : jambons, saucisses, flèches de lard, paquets emballés ; aucune bête entière, aucun sang | un cadre ou un mur dessiné autour ; du texte ou des chiffres lisibles ; une ombre portée | 6.7 |
| 3 | `assets/hd2d/interior/wallitem_menu_town.png` | 96 × 115 (1 × 1,2 m) | élément de mur, bas à 1,1 m ; ancre : milieu du bord bas | carte affichée dans un cadre : lignes peintes illisibles, dessins d'une tasse et d'un sandwich (V3) | un cadre ou un mur dessiné autour ; du texte ou des chiffres lisibles ; une ombre portée | 6.7 |

### D.6 La forêt profonde

**Références à joindre** : `assets/hd2d/props/forest_wall_a.png`, `oak_a.png`, `beech_a.png`, `tree_old_pine.png`, `fern_a.png`, `assets/hd2d/decals/lily_pads.png`, `leaves_rust_a.png`, `assets/hd2d/ground/forest_floor.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/decals/hidden_pool_a.png` | 192 × 144 (2 × 1,5 m) | décalque ; ancre : centre | petite mare dans un creux, presque couverte de feuilles mortes flottantes : on devine à peine l'eau noire entre les feuilles, bord de mousse (V5 : le danger qu'on ne voit pas) | un bord net, un ovale parfait ou un rectangle plein (sauf un tapis) ; un contour noir ; une ombre portée | 7.1 |
| 2 | `assets/hd2d/props/forest_wall_deep.png` | 1536 × 1056 (16 × 11 m) | lisière, raccord à gauche et à droite ; ancre : milieu du bord bas | forêt profonde et sombre : vieux chênes moussus et sapins à trois profondeurs, troncs couverts de lierre, très peu de lumière, sous-bois de fougères noires | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.1 |
| 2 | `assets/hd2d/props/grove_dense.png` | 768 × 864 (8 × 9 m) | panneau ; ancre : milieu du bord bas | bosquet profond : trois arbres serrés (chêne, hêtre, sapin), taillis, lierre, ombre dense au pied ; on n'y voit que la pénombre | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.1 |
| 3 | `assets/hd2d/decals/hidden_pool_b.png` | 144 × 115 (1,5 × 1,2 m) | décalque ; ancre : centre | Comme `hidden_pool_a.png` (jointe, à dessiner d'abord), mais : même chose, plus petite, une branche tombée en travers | un bord net, un ovale parfait ou un rectangle plein (sauf un tapis) ; un contour noir ; une ombre portée | 7.1 |
| 3 | `assets/hd2d/props/fallen_pine.png` | 576 × 154 (6 × 1,6 m) | panneau ; ancre : milieu du bord bas | sapin abattu par le vent, couché en travers vers la droite, motte de racines à gauche, aiguilles rousses | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.1 |
| 3 | `assets/hd2d/props/pool_ferns.png` | 192 × 115 (2 × 1,2 m) | panneau ; ancre : milieu du bord bas | fougères penchées au-dessus d'une mare, leurs frondes qui touchent l'eau (le bas de l'image est le bord de l'eau) | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.1 |
| 3 | `assets/hd2d/props/refuge_oak.png` | 768 × 960 (8 × 10 m) | panneau ; ancre : milieu du bord bas | le refuge de Chtholly **(original)** : un énorme vieux chêne creux, racines comme des bras, un creux à sa base où une fée peut s'asseoir à l'abri, feuillage or et rouille | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.1 |
| 3 | `assets/hd2d/props/rowan.png` | 288 × 480 (3 × 5 m) | panneau ; ancre : milieu du bord bas | sorbier aux grappes de baies rouge vif et au feuillage orangé, tronc gris fin | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.1 |

### D.7 La montagne et la rivière

**Références à joindre** : `assets/hd2d/cliff/cliff.png`, `assets/hd2d/props/rock.png`, `boulder_a.png`, `tree_pine.png`, `assets/hd2d/sky/sky_morning.png` (pour la lumière), `assets/hd2d/ground/stream_bed.png`.

| Prio | Fichier (chemin exact) | Taille (px) | Genre et ancre | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/anim/river_rapids.png` | 4 images de 192 × 96 (2 × 1 m), 8 ips ; fichier : 768 × 96 | bande animée ; ancre : milieu du bord bas de chaque image | remous blancs et écume autour d'un rocher à fleur d'eau, le rocher immobile | deux images identiques ; un saut quand la boucle reprend ; un pied ou un support qui bouge d'une image à l'autre | 7.2 |
| 3 | `assets/hd2d/anim/small_waterfall.png` | 6 images de 192 × 288 (2 × 3 m), 10 ips ; fichier : 1152 × 288 | bande animée, **alpha doux** sur les bords ; ancre : milieu du bord bas de chaque image | petite cascade de torrent sur des rochers moussus, eau claire et écume ; le haut de l'image est la lèvre de pierre | deux images identiques ; un saut quand la boucle reprend ; un pied ou un support qui bouge d'une image à l'autre | 7.2 |
| 3 | `assets/hd2d/cliff/cliff_mountain.png` | 384 × 384 | tuile, sans raccord sur les quatre bords ; opaque, sans ancre | paroi de falaise de montagne, comme `cliff.png` mais grise et sombre, strates verticales, lichens, une touffe d'herbe | un raccord visible à gauche ou à droite ; un haut ou un bas qui ne correspond pas aux niveaux (haut : palier supérieur, bas : inférieur) ; un objet posé devant | 7.2 |
| 3 | `assets/hd2d/decals/animal_tracks.png` | 144 × 192 (1,5 × 2 m) | décalque ; ancre : centre | empreintes de cerf et de sanglier mêlées dans la boue, qui traversent l'image de bas en haut | un bord net, un ovale parfait ou un rectangle plein (sauf un tapis) ; un contour noir ; une ombre portée | 7.2 |
| 3 | `assets/hd2d/decals/scree.png` | 288 × 192 (3 × 2 m) | décalque ; ancre : centre | éboulis de pierres grises anguleuses de 5 à 30 cm | un bord net, un ovale parfait ou un rectangle plein (sauf un tapis) ; un contour noir ; une ombre portée | 7.2 |
| 3 | `assets/hd2d/props/bear_den.png` | 384 × 288 (4 × 3 m) | panneau ; ancre : milieu du bord bas | tanière d'ours : entrée sombre sous un surplomb de rocher et de racines, feuilles tassées au seuil ; aucun os, aucun sang (les ours y hibernent, V2) | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.2 |
| 3 | `assets/hd2d/props/boulder_mountain_a.png` | 384 × 288 (4 × 3 m) | panneau ; ancre : milieu du bord bas | gros rocher gris anguleux, lichens jaunes et gris, une fissure | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.2 |
| 3 | `assets/hd2d/props/boulder_mountain_b.png` | 240 × 192 (2,5 × 2 m) | panneau ; ancre : milieu du bord bas | rocher plus petit, posé de travers sur des éboulis | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.2 |
| 3 | `assets/hd2d/props/log_bridge_b.png` | 384 × 96 (4 × 1 m) | panneau ; ancre : milieu du bord bas | tronc équarri jeté en passerelle au-dessus d'un torrent, une main courante de corde | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.2 |
| 3 | `assets/hd2d/props/mountain_pine_a.png` | 240 × 576 (2,5 × 6 m) | panneau ; ancre : milieu du bord bas | sapin de montagne tordu par le vent, branches d'un seul côté, écorce grise | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.2 |
| 3 | `assets/hd2d/props/mountain_pine_b.png` | 192 × 432 (2 × 4,5 m) | panneau ; ancre : milieu du bord bas | petit sapin rabougri sur un rocher, racines à nu | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.2 |
| 3 | `assets/hd2d/props/river_bank.png` | 384 × 96 (4 × 1 m) | panneau, sans raccord à gauche et à droite ; ancre : milieu du bord bas | berge de galets ronds et de racines vue de face, le bas de l'image au ras de l'eau (V3 : on puise l'eau du bain à la rivière) | des bords gauche et droit qui ne se raccordent pas ; une ombre portée au sol ; une marge transparente sur les côtés ; du texte | 7.2 |
| 3 | `assets/hd2d/props/rock_overhang.png` | 480 × 336 (5 × 3,5 m) | panneau ; ancre : milieu du bord bas | surplomb rocheux moussu sous lequel on peut s'abriter, fougères au pied | une ombre portée au sol ; un objet qui ne touche pas le bord bas ; un fond, un sol ou un personnage dessiné autour ; du texte | 7.2 |
| 3 | `assets/hd2d/sky/mountain_backdrop_a.png` | 2048 × 512 (42 × 10 m à 48 px/m) | lointain, raccord à gauche et à droite ; ancre : milieu du bord bas | la montagne de l'île en arrière-plan : pentes couvertes de sapins sombres, crêtes de roche claire, premières neiges sur les sommets, adoucie et violacée par la distance (V2 ; V5) | des îles, des nuages ou des navires ajoutés autour du sujet ; un bord net ; une couture visible à gauche et à droite | 7.2 |
| 3 | `assets/hd2d/sky/mountain_backdrop_b.png` | 2048 × 512 | lointain, raccord ; ancre : milieu du bord bas | Comme `mountain_backdrop_a.png` (jointe, à dessiner d'abord) : même chaîne sous un autre angle : une gorge, une cascade lointaine en fil blanc | des îles, des nuages ou des navires ajoutés autour du sujet ; un bord net ; une couture visible à gauche et à droite | 7.2 |

### D.8 La faune (planches de profil seul)

**Références à joindre** : `assets/characters/tiat/tiat.png` (contour et ombrage) et les remplaçants actuels `assets/fauna/<id>/<id>.png` (pour les proportions).

| Prio | Planche (profil ; `_front` et `_back` à côté) | Hauteur debout | Rangées (images à ips) | Apparence et consignes propres | À ne pas faire | Joindre | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3 | `assets/fauna/bear/bear.png` + `.json` (profil seul : pas de `_front` ni de `_back`) | 115 px | `repos` 2 à 2 ; `marche` 6 à 8 ; `course` 5 à 14 ; `attaque` 4 à 12 (non, `coup` [2]) ; `degats` 1 à 1 ; `mort` 2 à 4 (non) | ours brun massif, pelage d'automne épais brun-roux plus sombre aux pattes, bosse aux épaules ; `attaque` : il se dresse à moitié et frappe de la patte (l'image 2 dépasse la hauteur au repos) ; `mort` : couché sur le flanc, comme endormi | du sang ; les vues de face et de dos (le profil seul suffit) ; un animal plus grand ou plus petit que la hauteur demandée ; un sol ou une ombre dessinés | `tiat.png` (contour et ombrage) et le remplaçant actuel `assets/fauna/bear/bear.png` | 7.3 |
| 3 | `assets/fauna/boar/boar.png` + `.json` (profil seul : pas de `_front` ni de `_back`) | 86 px | `repos` 2 à 2 ; `marche` 6 à 8 ; `course` 5 à 14 ; `attaque` 4 à 12 (non, `coup` [2]) ; `degats` 1 à 1 ; `mort` 2 à 4 (non) ; `broute` 4 à 4 (boucle) | sanglier noir-brun aux soies hérissées sur l'échine, défenses courtes ; `attaque` : charge tête baissée et coup de boutoir ; `broute` : il fouille le sol du groin | du sang ; les vues de face et de dos (le profil seul suffit) ; un animal plus grand ou plus petit que la hauteur demandée ; un sol ou une ombre dessinés | `tiat.png` (contour et ombrage) et le remplaçant actuel `assets/fauna/boar/boar.png` | 7.3 |
| 3 | `assets/fauna/crow/crow.png` + `.json` (profil seul : pas de `_front` ni de `_back`) | 38 px | `repos` 2 à 2 ; `marche` 4 à 8 ; `course` 4 à 14 ; `fuite` 4 à 12 (boucle) | corbeau noir aux reflets bleutés, bec fort ; `repos` : il tourne la tête ; `fuite` : envol lourd | du sang ; les vues de face et de dos (le profil seul suffit) ; un animal plus grand ou plus petit que la hauteur demandée ; un sol ou une ombre dessinés | `tiat.png` (contour et ombrage) et le remplaçant actuel `assets/fauna/crow/crow.png` | 7.3 |
| 3 | `assets/fauna/deer/deer.png` + `.json` (profil seul : pas de `_front` ni de `_back`) | 182 px | `repos` 2 à 2 ; `marche` 6 à 8 ; `course` 5 à 14 ; `broute` 4 à 4 (boucle) | cerf roux d'automne aux grands bois ; paisible, il s'enfuit au galop (sa `course`) | du sang ; les vues de face et de dos (le profil seul suffit) ; un animal plus grand ou plus petit que la hauteur demandée ; un sol ou une ombre dessinés | `tiat.png` (contour et ombrage) et le remplaçant actuel `assets/fauna/deer/deer.png` | 7.3 |
| 3 | `assets/fauna/fox/fox.png` + `.json` (profil seul : pas de `_front` ni de `_back`) | 43 px | `repos` 2 à 2 ; `marche` 6 à 8 ; `course` 5 à 14 ; `fuite` 4 à 12 (non) | renard roux à gorge blanche et pattes noires, queue en panache ; `fuite` : un bond dans les fourrés | du sang ; les vues de face et de dos (le profil seul suffit) ; un animal plus grand ou plus petit que la hauteur demandée ; un sol ou une ombre dessinés | `tiat.png` (contour et ombrage) et le remplaçant actuel `assets/fauna/fox/fox.png` | 7.3 |
| 3 | `assets/fauna/frog/frog.png` + `.json` (profil seul : pas de `_front` ni de `_back`) | 12 px | `repos` 2 à 2 ; `marche` 4 à 8 ; `course` 4 à 14 ; `fuite` 4 à 12 (non) | grenouille verte et brune du marais, gorge qui palpite au `repos` ; `fuite` : plongeon (image 3 : il ne reste qu'une petite gerbe) | du sang ; les vues de face et de dos (le profil seul suffit) ; un animal plus grand ou plus petit que la hauteur demandée ; un sol ou une ombre dessinés | `tiat.png` (contour et ombrage) et le remplaçant actuel `assets/fauna/frog/frog.png` | 7.3 |
| 3 | `assets/fauna/squirrel/squirrel.png` + `.json` (profil seul : pas de `_front` ni de `_back`) | 24 px | `repos` 2 à 2 ; `marche` 6 à 8 ; `course` 5 à 14 ; `fuite` 4 à 12 (non) | écureuil roux, queue en panache, oreilles à pinceaux ; `repos` : assis, une noisette dans les pattes ; `fuite` : il bondit et file vers le haut, comme vers un tronc (V5 : le petit animal grimpeur) | du sang ; les vues de face et de dos (le profil seul suffit) ; un animal plus grand ou plus petit que la hauteur demandée ; un sol ou une ombre dessinés | `tiat.png` (contour et ombrage) et le remplaçant actuel `assets/fauna/squirrel/squirrel.png` | 7.3 |
| 3 | `assets/fauna/wolf/wolf.png` + `.json` (profil seul : pas de `_front` ni de `_back`) | 82 px | `repos` 2 à 2 ; `marche` 6 à 8 ; `course` 5 à 14 ; `attaque` 4 à 12 (non, `coup` [2]) ; `degats` 1 à 1 ; `mort` 2 à 4 (non) | loup gris aux flancs fauves, queue basse, regard jaune ; ils vont en meute au crépuscule dans la forêt profonde ; `attaque` : bond et morsure | du sang ; les vues de face et de dos (le profil seul suffit) ; un animal plus grand ou plus petit que la hauteur demandée ; un sol ou une ombre dessinés | `tiat.png` (contour et ombrage) et le remplaçant actuel `assets/fauna/wolf/wolf.png` | 7.3 |

Ce que dit l'œuvre : des **ours** dans les montagnes, chassés par Nygglatho et qui hibernent l'hiver (V2 ; V5 ; VEX) ; des **oiseaux** bruyants au matin (V3) ; un petit animal grimpeur poursuivi par une fillette (V5, épilogue) ; des **papillons orange** (ill. VEX) ; des **loups**, seulement une crainte de Willem (V1). Ce qu'on ajoute (original) : loups de la forêt profonde, sangliers, cerfs, renards, écureuils, grenouilles, corbeaux, une chouette (`docs/REFONTE.md`, 4.4). On ne les croise ni à l'entrepôt, ni au village, ni en ville. **Jamais de sang** : une bête vaincue s'enfuit ou reste couchée, sans blessure visible. La fiche des animations de la faune est à la section 3.4. Demande d'abord **une planche d'ensemble des huit animaux, côte à côte à l'échelle**, puis chaque planche à part.

### D.9 Les gens de la ville, les marchands, la Garde, le boulanger au travail et deux pyjamas (planches)

**Références à joindre** : `assets/characters/cat_waiter/cat_waiter.png`, `assets/characters/baker/baker.png`, `assets/characters/snack_vendor/snack_vendor.png` (rendu, palette, proportions ; trois vues de chaque).

| Prio | Planche (profil ; `_front` et `_back` à côté) | Hauteur debout | Rangées (images à ips) | Apparence et consignes propres | À ne pas faire | Joindre | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3 | `assets/characters/baker/baker_work.png` + `.json` | 192 px | `repos` 2 à 2 (recopiée) ; `travaille` 4 à 6 ; `porte` 6 à 10 | le boulanger grincheux : homme-ours brun, bedonnant, tablier de farine, manches retroussées | redessiner la rangée `repos` (elle est recopiée au pixel près de la planche existante) ; changer la hauteur debout ; un objet travaillé dessiné (marmite, pétrin, plafond) sauf s'il tient dans les mains | baker (trois vues) | 4.3 |
| 3 | `assets/characters/fairy_02/fairy_02_pajamas.png` + `.json` | 101 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `tombe` 4 à 10 (non) ; `assis` 2 à 2 ; `dort` 2 à 1 ; `travaille` 4 à 6 (la toilette du matin) | la fée `fairy_02` en chemise de nuit blanche à pois bleus | des cheveux rouges ; des chaussures de ville ; un changement de hauteur debout ; un accessoire qui change de côté | fairy_02 (trois vues), chtholly_pajamas, almita_pajamas pour le rendu | 4.6 |
| 3 | `assets/characters/fairy_06/fairy_06_pajamas.png` + `.json` | 110 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `tombe` 4 à 10 (non) ; `assis` 2 à 2 ; `dort` 2 à 1 ; `travaille` 4 à 6 (la toilette du matin) | la fée `fairy_06` en pyjama de flanelle à carreaux verts | des cheveux rouges ; des chaussures de ville ; un changement de hauteur debout ; un accessoire qui change de côté | fairy_06 (trois vues), chtholly_pajamas, almita_pajamas | 4.6 |
| 3 | `assets/characters/apothecary/apothecary.png` + `.json` | 134 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) | homme-grenouille trapu vert olive, petites lunettes rondes, blouse vert sombre ; `travaille` : il pile au mortier (mortier et pilon dessinés) | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/bookseller/bookseller.png` + `.json` | 144 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) | vieille femme-chatte tigrée, lunettes au bout du museau, châle, cardigan ; `travaille` : elle range des livres sur une étagère haute ; `porte` : une pile de livres ficelés (les commandes de l'entrepôt) | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/butcher/butcher.png` + `.json` | 173 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) | homme-chien massif à tête de dogue, tablier de cuir, avant-bras épais ; `travaille` : il tranche au couperet sur un billot non dessiné (viande déjà parée, aucune bête entière, aucun sang) ; `porte` : un jambon emballé de papier sur l'épaule | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/cafe_town_waiter/cafe_town_waiter.png` + `.json` | 163 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) | jeune demi-bête : visage presque humain, oreilles et queue de chien beige, mince, gilet noir, long tablier ; `travaille` : il pose une tasse d'une main tremblante ; `porte` : un plateau | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/market_farmer/market_farmer.png` + `.json` | 154 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) | femme-chienne à longues oreilles d'épagneul, fichu, tablier, sabots ; `travaille` : elle pèse des œufs dans une petite balance tenue à la main ; `porte` : un cageot de légumes | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/market_honey/market_honey.png` + `.json` | 163 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) | homme-lézard trapu aux écailles vert-brun, gilet de cuir, chapeau de paille ; `porte` : une caisse de pots de miel | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/milliner/milliner.png` + `.json` | 154 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) | femme-oiseau au plumage gris-bleu et à petite crête, robe simple et soignée, un chapeau à plume ; `travaille` : elle noue un ruban sur un chapeau tenu dans ses mains | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/projectionist/projectionist.png` + `.json` | 168 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) | homme-lézard maigre aux écailles brun-vert, visière de toile, gilet à manchettes ; `travaille` : il tourne la manivelle d'un appareil non dessiné | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/watchmaker/watchmaker.png` + `.json` | 149 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 ; `travaille` 4 à 6 ; `porte` 6 à 10 (selon la ligne) | vieil homme-oiseau à tête de chouette, plumes grises, lorgnon et loupe vissée à l'œil, gilet brun ; `travaille` : il règle un petit mécanisme à la pince, penché | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/villager_bear_f/villager_bear_f.png` + `.json` | 182 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | femme-ourse, tablier, manches retroussées, foulard | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/villager_bird_m/villager_bird_m.png` + `.json` | 154 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | homme-oiseau à tête de corneille, veste sombre, sacoche de cuir en bandoulière (le facteur, original) | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/villager_cat_f/villager_cat_f.png` + `.json` | 149 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | femme-chatte tricolore, robe à fleurs passées, tablier | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/villager_dog_m/villager_dog_m.png` + `.json` | 168 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | homme-chien fermier brun et blanc, chemise de lin, gilet, pantalon à bretelles, bâton de marche | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/villager_frog_f/villager_frog_f.png` + `.json` | 130 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `course` 5 à 14 ; `assis` 2 à 2 | femme-grenouille, robe verte, panier de cresson | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.2 |
| 3 | `assets/characters/merchant_cat/merchant_cat.png` + `.json` | 163 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `assis` 2 à 2 | marchand homme-chat au pelage gris argenté lustré, costume trois pièces bleu sombre, chapeau melon, canne à pommeau (même côté partout), sacoche de cuir ; poli et pressé | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.3 |
| 3 | `assets/characters/merchant_lizard/merchant_lizard.png` + `.json` | 178 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `assis` 2 à 2 | marchand reptilien aux écailles bleu-vert, redingote bordeaux, gilet brodé, lorgnon, registre sous le bras | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | `cat_waiter`, `baker`, `snack_vendor` (trois vues chacune) | 6.3 |
| 3 | `assets/characters/garde_porter/garde_porter.png` + `.json` | 202 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `porte` 6 à 10 | lézard de la Garde en tenue de bord (veste courte, gants) ; `porte` : deux grandes épées emmaillotées de tissu blanc sur l'épaule (V1 : les épées qu'on rapporte du combat) | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | garde_lookout (trois vues) | 6.1 |
| 3 | `assets/characters/garde_soldier/garde_soldier.png` + `.json` | 211 px | `repos` 2 à 2 ; `marche` 6 à 10 ; `parle` 2 à 6 ; `porte` 6 à 10 | soldat lézard de la Garde ailée, écailles gris-vert, uniforme bleu nuit à liserés rouges (#AE4A3E), aile stylisée brodée sur l'épaule (sans texte), ceinturon, sabre court au fourreau ; aucune arme à feu ; `porte` : une caisse ferrée | une queue qui change de côté ou passe sous la ligne des pieds ; un vêtement moderne ; la même silhouette qu'un autre personnage de la famille ; du sang ; pour un homme-oiseau : des ailes à la place des bras | garde_lookout, garde_porter | 6.1 |

**Les familles.** Même méthode qu'au groupe A.7 : une planche d'ensemble de l'espèce, à l'échelle, puis chaque personnage à part. Les gens de métier ont `travaille` (leur geste, dans leur ligne) et, quand la ligne le dit, `porte` ; les marchands de passage (`merchant_cat`, `merchant_lizard`) n'ont que `repos`, `marche`, `parle`, `assis` ; les deux lézards de la Garde (`garde_porter`, `garde_soldier` : aucune scène de l'acte 1 ne les cite, le seul lézard qui débarque, Limeskin, est livré) n'ont que `repos`, `marche`, `parle`, `porte`. Pour `baker_work` : fiche propre ci-dessous.

**Fiche propre de `baker/baker_work` : le boulanger grincheux**

Hauteur debout : **192 px** (2 m). Homme-ours brun, bedonnant, tablier de farine, manches retroussées ;
patron grincheux de la boulangerie où travaille Lakhesh (V3, « Je suis à la maison »).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante (une miche à la main) |
| `travaille` | 4, 6 | il pétrit une grosse pâte de ses deux pattes, penché, puis la retourne ; la pâte et le pétrin ne sont pas dessinés |
| `porte` | 6, 10 | marche en portant une pile de six miches rondes contre le ventre |

**Les deux pyjamas qui restent** (`fairy_02_pajamas`, `fairy_06_pajamas` ; les huit autres sont livrés). Le soir et le matin : les petites couchées tôt, les sorties dans le couloir en se frottant les yeux (V2, épilogue), la toilette du visage à l'eau glacée (VEX, « L'homme-chat »). Pieds nus ou en chaussons, cheveux défaits. `travaille` est ici **la toilette du matin** (même nom, autre geste) : elle s'asperge le visage d'eau au-dessus d'une cuvette non dessinée, puis s'essuie d'une serviette dessinée. `fairy_02` : chemise de nuit blanche à pois bleus ; `fairy_06` : pyjama de flanelle à carreaux verts.

### D.10 Les reprises de planches livrées (corrections ponctuelles)

**Références à joindre** : la planche à corriger, trois vues.

| Prio | Fichier (`assets/characters/…`) | Défaut | Consigne à coller | À ne pas faire | Réf. n° 5 |
| --- | --- | --- | --- | --- | --- |
| 3 | `chtholly/chtholly_front.png` | la pointe de Seniorious passe 16 px sous la ligne des pieds au `repos` et 10 px en `marche` | relève ou raccourcis la pointe de l'épée : elle touche la ligne du sol sans la dépasser, dans toutes les images debout ; le reste de la silhouette ne bouge pas | recopier au pixel près tout ce qui n'est pas cité ; ne livrer que le fichier corrigé et son JSON ; recalculer les ancres (`python3 tools/hd2d_sheets.py anchors <json> --write`) | 4.9 |
| 3 | `pannibal/pannibal.png` (et `pannibal_life.png`, dont le `repos` est recopié) | la pointe de l'épée de bois passe 10 px sous les pieds dans la 1re image de `repos` | raccourcis la pointe pour qu'elle touche la ligne du sol ; recopie ensuite la rangée `repos` dans `pannibal_life` | recopier au pixel près tout ce qui n'est pas cité ; ne livrer que le fichier corrigé et son JSON ; recalculer les ancres (`python3 tools/hd2d_sheets.py anchors <json> --write`) | 4.9 |
| 3 | `willem/willem_front.png` | la pointe de l'arme passe 4 à 7 px sous les pieds au `repos` | même correction | recopier au pixel près tout ce qui n'est pas cité ; ne livrer que le fichier corrigé et son JSON ; recalculer les ancres (`python3 tools/hd2d_sheets.py anchors <json> --write`) | 4.9 |
| 3 | `limeskin/limeskin_back.png` | la queue passe 5 à 6 px sous les pieds au `repos` et au `parle` | relève la queue au ras du sol | recopier au pixel près tout ce qui n'est pas cité ; ne livrer que le fichier corrigé et son JSON ; recalculer les ancres (`python3 tools/hd2d_sheets.py anchors <json> --write`) | 4.9 |
| 3 | `snack_vendor/snack_vendor_front.png` | la dernière image de `marche` (image 5) est dessinée plus grande que `repos` (remarque de `hd2d_sheets.py check`) | image 5 de `marche` à la hauteur de la 1re image de `repos` : 154 px | recopier au pixel près tout ce qui n'est pas cité ; ne livrer que le fichier corrigé et son JSON ; recalculer les ancres (`python3 tools/hd2d_sheets.py anchors <json> --write`) | 4.9 |
| 3 | `tiat/tiat_front.png`, `tiat/tiat_back.png` | une image de `marche` (image 2 de la face, image 3 du dos) a l'ancre 10 à 12 px au-dessus des pieds | **pas de redessin** : `python3 tools/hd2d_sheets.py anchors <json> --write`, puis vérifier la planche de contrôle | recopier au pixel près tout ce qui n'est pas cité ; ne livrer que le fichier corrigé et son JSON ; recalculer les ancres (`python3 tools/hd2d_sheets.py anchors <json> --write`) | 4.9 |

**Méthode.** Ces six corrections ont été mesurées sur les planches livrées. **Seules les images citées changent**, les autres restent identiques au pixel près ; commence par `python3 tools/hd2d_sheets.py strip <out.png> <json>` pour voir la ligne du sol. Pour chaque ligne : colle le bloc de style, puis « Corrige la planche `<fichier>` (format de la section 3.1, JSON compris) : » et la consigne. Après la correction de `pannibal.png`, recopie la rangée `repos` dans `pannibal_life.png` (qui la recopie). La correction de `tiat` ne se dessine pas : c'est un recalcul des ancres.


## 8. Livrer et vérifier

### 8.1 Liste de contrôle de la livraison

1. Pars de la **dernière version de `main`**.
2. Dépose chaque image à son **chemin exact** (colonne « Fichier ») ; pour une planche de personnage, les trois PNG et les
   trois JSON ; pour une planche d'animal, un PNG et un JSON. **Ne livre que les fichiers de ce document** : ni sources, ni
   galeries, ni aperçus, ni outils, ni code, ni autre personnage, ni changement des fichiers existants, sauf les deux
   images livrées à refaire (`cart_ruts.png` et `footprints.png`, qui gardent leur nom). **Une image livrée à son chemin exact
   remplace le remplaçant du même nom, sans changer le code** (`bank_earth.png` compris).
3. Lance `python3 tools/hd2d_assets.py check` : pour chaque image **inscrite au manifeste** (`tools/hd2d_manifest.json`),
   il vérifie :
   - **la taille exacte** (une bande animée : nombre d'images × la largeur d'une image) ;
   - **l'opacité** des tuiles, matières, murs et ciels ; **l'alpha net** (0 ou 255) de tout le reste, sauf les images
     « alpha doux » ;
   - **l'ancrage** : un panneau, une façade, un flanc ou une image de bande touche le bord bas ; un sprite centré n'est coupé
     par aucun bord et sa masse est au centre à 10 % près ; une façade et un flanc ont le mur plein sur les bords gauche et
     droit ; un flanc en pignon a le haut transparent de part et d'autre du triangle, un gouttereau a le mur plein ;
   - **les décalques** : coupés par aucun bord (au-delà de 12 % de la ligne extérieure), ni rectangle plein, ni ellipse nette ;
   - **les bandes animées** : aucune image identique à sa voisine, boucle sans saut de la dernière image à la première ;
   - **les raccords** : tuiles sans raccord visible sur les quatre bords, murs et panorama à gauche et à droite, bordures
     (`wrap`) sur leur axe ; l'atlas du sol à jour.
4. Lance `python3 tools/hd2d_sheets.py check` : pour chaque planche **inscrite aux `sheets` du manifeste**, il vérifie le PNG
   en RGBA à alpha net, la taille de la planche égale à celle de son JSON, les animations, nombres d'images, `ips`, `boucle`
   et `coup` du tableau, les images dans la planche et non vides, l'ancre dans l'image (à 2 px près), **la hauteur debout de
   la 1re image de `repos` à 6 % près**, la même échelle que `repos` pour `marche` et `parle` (12 %), et **les mêmes animations
   dans les trois vues**. Pour voir ce qu'il mesure : `python3 tools/hd2d_sheets.py strip <out.png> <json>` (ligne du sol, axe
   de l'ancre, hauteur debout en orange).
5. **Ce que ces deux outils ne voient pas encore** : les images et les planches de ce cahier ne sont inscrites au manifeste
   que par les lots du moteur qui les posent (clé `lot` proposée : `N6A` à `N6D`) ; les planches `_stick` ont des animations
   (`pare`, `degats`, `mort`) que le tableau `life` de `hd2d_sheets.py` ne connaît pas encore. En attendant, **contrôle à la
   main** avec le script ci-dessous (taille, mode, alpha, opacité de chaque image listée), puis ouvre chaque image.
6. Une image trop grande se ramène à sa taille par `python3 tools/hd2d_assets.py fit <fichier>` (une fois inscrite) ; une
   nouvelle tuile de sol demande `python3 tools/hd2d_assets.py atlas`.
7. `tools/import.sh` (il crée les `.import` des nouvelles images, à livrer avec elles), puis `tools/check.sh`.
8. Note la provenance en bas de `assets/CREDITS.md` (et de `assets/characters/CREDITS.md` pour les planches) : « généré avec
   ChatGPT le …, cahier n° 6, lot … ».
9. Dans la description de la PR : les fichiers livrés, ceux qui manquent, les écarts connus (taille, cadrage, côté d'un
   accessoire), et ce qui est **produit**, **contrôlé techniquement**, **placé dans le jeu** et **validé en jeu** : l'état des
   lots ne change qu'après la livraison effective.

### 8.2 Contrôle des images de ce document

Ce script lit les tableaux de ce fichier, et pour chaque image listée vérifie qu'elle existe, sa taille exacte (celle de la
colonne « Taille » ; pour une bande, la taille du fichier), son mode RGBA, son alpha net (sauf « alpha doux »), l'opacité de
ce qui doit l'être. Les planches se contrôlent par `hd2d_sheets.py` (point 4).

```text
python3 -I - docs/ASSETS_HD2D_ILE68_LIVRAISON6.md <<'PY'
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

## 9. Ce qui attend le moteur (formats à confirmer)

Certaines images supposent un format que le jeu n'a pas encore tranché. Elles sont **commandables tout de suite** quand
la colonne « Commander » le dit ; sinon elles attendent la décision du lot du moteur concerné (la ligne du tableau le
rappelle).

| Format | Images | Lot du moteur | État au 15 octobre 2026 | Commander |
| --- | --- | --- | --- | --- |
| Navires en volume : flanc, trappe et rotor (`ships/garde_transport_side`, `anim/garde_transport_*`, `anim/mooring_arm_clamp`) | 4 (C.1) | E7 navires | pas encore posé ; **le plan du port (`CARTE.md` 6.2) pose déjà `garde_transport_side` en permanence** alors que le poste est vide hors scènes | tout de suite (seul l'usage change) |
| Navires en volume : pont, poupe, trois quarts (`ships/*_deck`, `_stern`, `_34`) | 6 (D.1) | E7 | non tranché (pont praticable, navire au nord du quai) | après accord |
| Flaques animées `puddle_rain_a`, `puddle_rain_b` | 2 (C.2) | E9 lumière et temps | `GroundDecal` n'a pas de bande animée ; demande dans `docs/CONTRACT_REQUESTS.md` | tout de suite (l'image est une bande de 4) |
| Planches `_stick` et animation `pare` | 4 planches (C.10) | E8 jeux | **accepté** : `pare` 2 images, 2 ips, en boucle, et un `mort` assis sans blessure (`docs/DECISIONS.md`, E8) ; le tableau `life` de `hd2d_sheets.py` ne connaît ni `pare`, ni `degats`, ni `mort` | tout de suite |
| Planches de tenue, de geste et complémentaires (`_rain`, `_work`, `willem_life`, `_repair`, `_laundry`, `_pajamas`) | 14 planches (C.10, D.9) | E4 vie | **accepté** : tenues dans `data/npcs/outfits/<id>.tres`, ou fusion dans la planche de base | tout de suite |
| Planches composites déjà livrées (`willem_carry`, `willem_piggyback`) | 2 (livrées) | E4, E6 | préparatoires approuvées ; **intégration moteur à faire** | — |
| Premier plan suspendu `fg_canopy_a`, `fg_canopy_b` | 2 (D.2) | E10 densité | non tranché : les voûtes posées en l'air au sentier ont été **retirées** (QC-12) ; `fg_canopy_a` est un remplaçant qu'aucune carte ne montre | après accord |
| Faces de palier `cliff/step_*`, `wall_*_1m`, `town_retaining_wall` ; escaliers `town_stairs_*` | 9 (D.2) | E2 sol en relief | **non lues** : `MapGround` n'a qu'un talus (`bank_earth`, groupe B.4) | après accord |
| Sol `ground/path_overgrown`, `ground/river_water` | 2 (D.2) | E2 | l'atlas du sol a 27 couches ; le moteur peint le chemin du sentier avec `path_dirt_b`, sur la bande du chemin seulement | après accord |
| Faces des façades de ville sur deux paliers (socle de pierre nue de 0,5 m, compris dans la hauteur du mur) | les maisons de A.4, D.4 | E2 | à confirmer ; **sans risque** : c'est un bas de mur en pierre nue | tout de suite |
| Vitres des façades du jour | — | I2, QO | **tranché** : `Building.window_glow_color` et `window_glow_tolerance` ; les façades de nuit (B.1, C.5) demandent que le moteur règle la couleur à #FFE6A6 pour elles | tout de suite |
| Planches d'animaux | 8 + 2 (C.10, D.8) | E5 faune | **tranché** : profil seul ; nombres d'images et cadences du tableau 3.4 | tout de suite |

## 10. Écarts relevés entre les documents, et ce que ce cahier tranche

| Écart | Ce que ce cahier a décidé |
| --- | --- |
| Le n° 5 (R0.9) commande les versions de nuit de quatre façades dont **le jour est encore un remplaçant** (`cottage_thatch_a`, `_b`, `_c`, `village_house_stone`) : une image de nuit doit suivre le jour **au pixel près**, elle serait donc caduque dès que le jour est redessiné | ces quatre façades de nuit se commandent **avec** leur façade du jour, dans la même conversation (groupe C.5) ; les deux dont le jour est livré (`cafe`, `limashenka_house`) sont au lot B |
| Le n° 5 (5.5) donne `wallitem_family_portrait` en **256 × 256** (taille d'un portrait de dialogue) ; le plan du salon le pose à 0,6 m de large et le remplaçant du manifeste fait **58 × 77** | 58 × 77 (0,6 × 0,8 m), bas à 1,4 m (groupe C.7) |
| Le n° 5 (4.8) décrit `pare` en **3 images, 12 ips, non bouclée** ; l'accord du moteur (E8, `PLAN.md`) est **2 images, 2 ips, en boucle** | 2 images, 2 ips, en boucle (fiche des planches de bâton, C.10) |
| Le n° 5 (7.3) demande aux animaux **trois vues** ; le moteur ne lit que le profil (`SkinData` sans `front_*` ni `back_*` pour la faune) | profil seul (section 3.4) |
| Le n° 5 (5.2 et 10.4) range `bank_earth` parmi des remplaçants « inutiles si `wall_earth_1m` est livré » ; or le moteur **ne lit que `bank_earth`** et pas `wall_earth_1m` | `bank_earth` se commande tout de suite (B.4) ; `wall_earth_1m` attend E2 (D.2) |
| `CARTE.md` 12.2 donne 37 images pour **« livrées »** (`cafe_table_heavy`, `cottage_thatch_*`, `fg_canopy_a`, `wallitem_family_portrait`, …) qui sont des **remplaçants** générés par les outils ; elle compte 329 livrées sur 398 | ce cahier part de l'état réel (pixels comparés à la recette) : 62 remplaçants au manifeste, dont 4 effets que le jeu génère ; les 58 autres sont commandés ici |
| `CONTRACT_REQUESTS.md` (E6) et `DECISIONS.md` (E6) tiennent encore `willem_marsh`, la pose « hanches » de Chtholly et la planche propre de `fairy_12` pour **à livrer** | `willem_marsh` et `fairy_12` (avec son `travaille`) sont livrés (PR n° 39) ; `chtholly_home` a sa rangée `hanches` depuis le cahier n° 3 : ni l'un ni l'autre ne se redemandent ; leur **pose dans le jeu** (tenues, `sheets`, scènes) est du travail du moteur |
| `ACTE1.md` (section 6) place `chtholly_pajamas` en priorité 2 et les planches de bâton en 3 ; le n° 5 les met en 1 et en 2 | `chtholly_pajamas` est livrée ; les planches de bâton sont de priorité 1 du lot C (jours 9 à 11) |
| `ACTE1.md` 8.3 donne à Willem « le Carillon de série Percival » dans `willem_home`, qui n'a **pas d'arme** (n° 5, 4.1) | **tranché par l'utilisateur** (15 octobre 2026) : la planche `willem/willem_duel` (Willem et Percival) est commandée en C.10, priorité 1 |
| `CARTE.md` 6.2 pose `garde_transport_side` au quai en permanence ; le même texte dit « en dehors des scènes, le poste est vide » et `ACTE1.md` 6 : « le transport ne paraît qu'au crépuscule du jour 7 » | `garde_transport_side` est au lot C ; si le port le garde au quai en tout temps, le passer en priorité 1 du lot A |
| `CARTE.md` 9.4 donne `ville_snack` à 7 × 5 m et `ville_cafe` à 9 × 6 m ; les plans font 9 × 7 et 11 × 8 | aucun effet sur les images (les cotes des meubles sont celles des plans) |
| `CARTE.md` 12.1 place la porte de service du flanc de l'entrepôt à 8 m de l'angle ; les données la mettent à 6 m | sans objet : `warehouse_front_a_side` est livrée |
| `town_house_g`, `town_house_h`, `town_stairs_a`, `town_arch`, `hanging_sign_hat`, `hanging_sign_mortar` sont au n° 5 mais **aucune carte de `CARTE.md` ne les pose** | lot D, priorité 3 (D.2, D.4) |
| Le manifeste décrit `cart_ruts` et `footprints` (décalques) **sans `soft_alpha`**, alors que R0.8 et R0.11 demandent un alpha doux sur leurs bords ; les quatre `fx/sign_*` (genre `fx`) n'ont aucun contrôle d'alpha | à l'inscription de la livraison, le moteur ajoute `soft_alpha` aux entrées de `cart_ruts` et de `footprints` (sans quoi `hd2d_assets.py check` y verrait de l'« alpha flou ») |
| Les 13 planches de R2 livrées ne sont **inscrites ni aux `sheets` du manifeste** (`hd2d_sheets.py check` ne les lit pas : 54 planches contrôlées) **ni aux tenues** (`data/npcs/outfits/`) | contrôlées à la main pour ce cahier avec les règles de `hd2d_sheets.py` : 0 problème (hauteur debout du `repos` exacte à 1 px près, mêmes animations dans les trois vues, aucune clé en trop dans les JSON) ; seule `willem_piggyback` mesure 176, 185 et 169 px au lieu de 168, parce que la passagère dépasse Willem (consigne du cahier n° 5) ; inscription et pose dans le jeu : le moteur |

### Précision artistique — Nygglatho (16 octobre 2026)

À la demande de l’utilisateur, toutes les variantes de Nygglatho reprennent désormais la tenue de bonne noire et blanche des planches officielles de l’anime (ZIP, page 51), avec cheveux rose saumon et yeux verts. Les anciennes consignes de chemisier vert ne s’appliquent plus à la production ; les sources et anciens rendus restent conservés. La blouse de laboratoire blanche et le châle de pluie brun sont conservés.
