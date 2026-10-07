# WordEnd 3D — Cahier des charges des assets 3D

Personnages, ennemis, décors et île : la direction artistique, la barre de qualité et le format
attendu par le jeu.

Ce document s'adresse à qui produit les assets : une IA (ChatGPT, Codex ou un autre outil), un ou
une artiste, ou un mélange des deux (Blender, VRoid Studio, générateurs image → 3D). Il dit
**exactement** ce que le projet Godot sait intégrer sans retoucher le gameplay, et **le niveau de
qualité attendu**. Tout ce qui est marqué **obligatoire** conditionne le fonctionnement du jeu : un
nom d'animation ou une durée qui ne correspond pas casse le combat. La direction artistique
(section 2) et la barre de qualité (section 2 bis) décident si un modèle est accepté.

> **Consigne pour l'IA qui lit ce document**
>
> 1. Lis la direction artistique (section 2) et la barre de qualité (section 2 bis) avant tout :
>    la première livraison a été refusée pour son rendu, pas pour son format.
> 2. Produis les fichiers listés en section 9, dans l'arborescence indiquée et dans l'ordre de
>    priorité de la section 9, en respectant les conventions des sections 3 à 7.
> 3. **Ne construis jamais un personnage, une créature ou un décor en assemblant des primitives
>    par script** (sphères, cylindres, cubes). Un script Blender (`bpy`) peut servir à convertir,
>    renommer des os, recaler des durées, exporter et vérifier ; pas à modéliser.
> 4. Si tu ne peux pas atteindre la barre de qualité, dis-le clairement et livre les planches de
>    concept et les fichiers intermédiaires (section 2 bis.3) plutôt qu'un modèle au rabais.
> 5. Pour chaque fichier, donne une ligne de crédit (section 10) ; pour chaque modèle, joins les
>    rendus de contrôle (section 2 bis.4). Ne livre jamais un modèle sans ses animations nommées
>    ni sans son fichier `.anim.json`.

---

## 1. Le jeu en bref

- **Genre** : action-aventure 3D à la 3e personne, centrée sur le combat à l'épée, jouable dans le
  navigateur (WebGL 2), sur ordinateur et téléphone. Inspiré de *SukaSuka* (*Que faites-vous à la
  fin du monde ? Êtes-vous occupés ? Voulez-vous bien nous sauver ?*, d'Akira Kareno, illustré par
  ue, traduction française de Yume Novel).
- **Moteur** : Godot 4.7, rendu « Compatibility » (OpenGL 3 / WebGL 2). Ni lancer de rayons ni
  effets lourds : une lumière directionnelle (le soleil couchant, orangé et rasant), une lumière
  ambiante lavande, une brume chaude légère. Caméra derrière l'héroïne, en orbite libre, entre 3 et
  10 m : on la voit surtout de dos et de trois-quarts.
- **Héroïne** : la fée soldat qui porte **Seniorious**, l'aînée de l'entrepôt des fées : par défaut
  **Chtholly Nota Seniorious**, 15 ans, longs cheveux bleu ciel (section 4.6). Elle frappe en trois
  coups enchaînés et lance une **onde** après une charge (elle allume son venenum dans l'épée).
- **Ennemi** : **Timere**, la Sixième Bête : une seule Bête qui se déchire en fragments ; ses corps
  (« des Timeres ») sont le Rejeton, le Fragment, le Timere bondissant et le Grand fragment. Un
  seul modèle, mis à l'échelle par le jeu (section 5).
- **Monde** : l'**île flottante n° 68**, une dalle de pierre de 160 × 160 m couverte d'une forêt
  d'automne, au-dessus d'une mer de nuages, toujours au soleil couchant. Cinq zones : l'entrepôt
  des fées au centre, les bois du marais au nord, le bord du Couchant à l'ouest (l'arène de la
  veille), le port et le bourg au sud, la colline des étoiles à l'est (section 7).
- **Aujourd'hui** : les personnages sont des planches de sprites 2D (celles de l'easter egg et des
  planches de remplacement) et les 45 modèles d'une première livraison 3D refusée pour son rendu
  (section 2 bis.1) ; le décor est fait de formes simples. Les assets 3D remplacent ces éléments
  **sans changer le code de jeu**.

Références dans le dépôt :

- l'histoire et le monde : [BIBLE.md](lore/BIBLE.md) (apparences du canon, orthographe de la
  traduction), [HISTOIRE.md](lore/HISTOIRE.md) (section 5 : personnages ; section 7 : Timere),
  [MONDE.md](lore/MONDE.md) (sections 2, 3 et 5 : île, décors, spécification de carte) ;
- `assets/characters/chtholly/chtholly.png` et `assets/enemies/timere/timere.png` : les planches de
  l'easter egg, pour les poses de chaque animation et la silhouette du Timere ; pas pour le style
  (grosses têtes) ni pour les cheveux rouges de Chtholly (un spoiler de l'acte 3) ;
- [docs/sprites/REFERENCES.md](sprites/REFERENCES.md) : les 45 personnages déjà livrés, tous à
  refaire, et les pages des planches de référence qui les montrent (scans fournis par
  l'utilisateur, hors du dépôt).

## 2. Direction artistique

Cible : **au minimum la direction artistique de *The Legend of Zelda: Breath of the Wild*** (et de
*Tears of the Kingdom*, du même style) : des personnages aux proportions réalistes stylisées, un
ombrage cel doux, des couleurs naturelles, des matières peintes à la main, de grands paysages
lisibles. Appliquée à *SukaSuka* : des fées aux cheveux vifs et un vieil entrepôt de bois dans une
forêt d'automne, sur une île de pierre qui flotte au-dessus des nuages, au couchant. Ni jouet ni
style à grosses têtes : le ton du roman, doux et mélancolique.

### 2.1 Personnages

- **Proportions réalistes stylisées** : adultes et adolescentes ≈ 6,5 à 7 têtes ; petites fées
  (7 à 10 ans d'apparence) ≈ 5 têtes ; Nephren, qui paraît dix ans, ≈ 6 têtes. Mains, pieds et cou
  à l'échelle du corps. Silhouettes élancées, lisibles à 10 m : la coiffure, la tenue, l'épée et la
  couleur dominante suffisent à reconnaître quelqu'un, même en ombre chinoise.
- **Visages** : style anime sobre, comme Link ou Zelda dans *Breath of the Wild* : yeux expressifs
  peints dans la texture (iris en dégradé, reflet, cils supérieurs marqués), nez et bouche discrets
  mais modelés, pommettes et menton construits ; **aucun contour noir** (ni trait encré, ni coque
  inversée). Expression calme au repos ; clignement recommandé (section 4.2).
- **Cheveux** : modélisés en mèches et en volumes, avec raie, épis et pointes ; dégradés et reflets
  peints (l'anneau de lumière des cheveux anime est permis) ; cartes à alpha découpé seulement pour
  les pointes fines. Jamais de calotte lisse ni de blocs.
- **Vêtements** : plis principaux modélisés (coudes, taille, genoux, jupe), coutures, ourlets,
  revers, boutons et boucles en relief ou peints ; épaisseur visible aux cols et aux bords ;
  matières distinctes : tissu mat, cuir plus lisse et plus sombre, métal (boutons, armure légère,
  garde de l'épée).
- **Mouvement secondaire** : cheveux, tresses, jupe, cape, écharpe et tablier suivent le mouvement,
  par des os dédiés animés à la main ou simulés puis **cuits dans les animations** : le jeu ne
  simule rien, il lit les animations telles quelles.
- **Hommes-bêtes** (serveur homme-chat, lycanthrope, boulanger à tête d'ours, reptiliens) :
  anatomie animale stylisée et expressive, à la manière des peuples de *Breath of the Wild* (Rito,
  Zora, Gorons) : tête, mains, pelage ou écailles crédibles, vêtements de tous les jours ; ni animal
  réaliste ni peluche.
- **Pudeur** : les fées sont des enfants et des adolescentes ([BIBLE.md](lore/BIBLE.md), section
  9.4). Aucune sexualisation, ni dans les tenues ni dans les poses ; short ou jupon sous les jupes.

### 2.2 Rendu et matériaux

- **Le jeu fait l'ombrage** : un ombrage cel (toon) doux à 2 ou 3 paliers, avec un liseré de
  lumière (rim light) sur les contours, sous un soleil couchant rasant et orangé et une ambiance
  lavande. Le shader des personnages reste à écrire (section 11) ; il ne change rien à ce qu'on
  livre.
- **Albédos peints à la main** : dégradés subtils (plus clair vers le haut, plus froid et plus
  sombre dans les creux), touche visible mais propre ; léger AO peint accepté dans les plis, sous
  le menton et sous les cheveux. **Pas de lumière ni d'ombre fortement cuites** : ni ombre portée
  peinte, ni reflet spéculaire peint, sauf l'anneau de lumière des cheveux et le reflet des yeux.
- **Matériaux** : `metallic` 0 partout sauf sur le métal réel (boutons, armure, garde de l'épée,
  fer du port : `metallic` entre 0,5 et 1) ; rugosité élevée (0,7 à 0,9 ; 0,4 à 0,6 pour le
  métal). Pas de normal map pour les personnages ; une normal map est permise sur les grandes
  surfaces de roche et d'écorce des décors (512 × 512 au plus).
- **Transparence seulement découpée** (alpha clip / mask, seuil 0,5) : pointes de cheveux,
  feuillages, franges, herbe. Jamais d'alpha mélangé (blend) ni de verre transparent : les vitres
  sont peintes et opaques.
- **Émission** : seulement pour ce qui éclaire (cristaux lumineux, fenêtres éclairées) et pour les
  fissures de Seniorious (section 4.6).

### 2.3 Couleurs

- **Naturelles, harmonieuses, un peu désaturées**, chaudes au couchant : la palette des décors est
  celle de [MONDE.md](lore/MONDE.md), section 5.4 (herbe jaune-vert, feuillages or et rouille,
  pierre beige gris, bois brun, ardoise bleu-gris, tuiles de terre cuite). Les couleurs vives sont
  réservées à ce qui doit attirer l'œil : les cheveux des fées, le fanion de la Garde, les
  cristaux.
- **Contrastes de valeur d'abord** (clair / sombre), de teinte ensuite : un personnage se détache du
  sol par sa valeur (cheveux clairs, tenue sombre sur l'herbe moyenne), un toit de son mur, un
  chemin de l'herbe, un Timere du sable. Vérifier chaque modèle en niveaux de gris.
- **Ni blanc pur ni noir pur** dans les albédos (de `#1E1B1A` à `#F2EDE4` environ) : sous le soleil
  orangé, ils deviennent illisibles.

### 2.4 Décors

- **Échelle réelle** : portes ≈ 2,2 m de haut et 1,1 m de large, marches de 15 à 18 cm,
  garde-corps à 1 m (la rambarde de la terrasse des fées à 0,9 m), appuis de fenêtre à 1 m, bancs à
  0,45 m, tables à 0,75 m.
- **Formes nettes et organiques** : roches massives aux plans francs (cassures, strates, arêtes
  usées) ; arbres à tronc élancé dont les branches portent le feuillage en grandes masses
  découpées, jamais en boules ; herbe haute en touffes ; bâtiments un peu de travers, bois qui a
  joué. Assez de segments sur les formes courbes (troncs, colonnes, tonneaux) pour qu'aucun
  polygone ne se lise à 5 m.
- **Matériaux peints et usure** : bois veiné, pierre, ardoise, tuiles, fer riveté, cuivre, tissu ;
  arêtes éclaircies, mousse au pied des murs, coulures de pluie, planches rapiécées de teintes
  différentes, rouille sur le fer.
- **Univers européen rustique**, rien d'asiatique ni de moderne (MONDE.md, section 5.4) : pas de
  torii, de lanternes de papier ni de cerisiers en fleurs.

### 2.5 Animations

- **Fluides et pesantes** : anticipation avant un coup, suivi et amorti après, chevauchement (les
  cheveux, la jupe et l'épée arrivent après le corps) ; poids crédible dans les appuis.
- **Pieds qui ne glissent pas** : sur place, la distance couverte par un cycle vaut vitesse × durée
  (marche de Chtholly : 4 m/s × 0,6 s = 2,4 m, soit deux pas de 1,2 m, une marche très rapide ou un
  petit trot ; course : 7 m/s × 0,357 s = 2,5 m) ; le pied d'appui reste planté pendant le contact.
- **Lisibles de loin et de dos** : poses franches aux images clés (attaque, charge, dégâts), arcs de
  mouvement clairs.
- **Boucles sans à-coup** : la dernière pose rejoint exactement la première.
- **Ton** : à l'écran, une défaite n'est pas une mort : ni sang ni pose macabre.

## 2 bis. Barre de qualité et filières

### 2 bis.1 Ce qui a été refusé

La première livraison (45 personnages dans `assets/models/characters/`, PR n° 1) a été refusée pour
son rendu, alors que son format technique était bon :

- personnages assemblés par un script Blender à partir de primitives (sphères, cylindres, cubes) :
  silhouettes de jouet, raccords visibles, aucune topologie de personnage ;
- proportions chibi : une tête d'environ un tiers de la hauteur ;
- visages réduits à des yeux plaqués, sans nez, sans bouche, sans modelé ;
- couleurs unies tirées d'une palette, sans texture peinte, sans dégradé ni matière ;
- cheveux en blocs, sans mèches ni volume.

Ce qui était bon reste la règle : noms et durées des animations, fichier `.anim.json`, enveloppe
`.tscn` avec `model_metadata.gd`, portraits 256 × 256, ressource `SkinData` (sections 3 et 4). Les
nouveaux modèles remplacent ceux de `assets/models/characters/<id>/` (section 4.1).

### 2 bis.2 Filières acceptables

Le niveau visé est celui d'un personnage de *Breath of the Wild*, ou d'un jeu anime en ombrage cel
de la même ambition. Trois filières y mènent, seules ou combinées :

1. **Un ou une artiste 3D** : sculpture ou modélisation, retopologie propre (boucles autour des
   yeux, de la bouche et des articulations), UV, textures peintes à la main (Blender, Krita,
   Substance Painter, 3D-Coat), rig et animation. C'est la filière de référence.
2. **VRoid Studio**, pour les personnages anime aux proportions normales : régler les curseurs
   jusqu'à 6,5 à 7 têtes (5 pour une petite fée), coiffure en mèches dans l'éditeur de cheveux,
   textures repeintes ; export VRM → Blender (module VRM) → glTF. Puis ramener le modèle au format
   du jeu : matériaux MToon convertis en albédos simples (le jeu fait son propre ombrage), contour
   MToon supprimé, 2 ou 3 matériaux (atlas), os des cheveux et de la jupe réduits pour tenir en
   64 os, os renommés (section 4.2), mouvement des cheveux et de la jupe cuit dans les animations,
   budgets de la section 3.3 (VRoid sait réduire polygones, matériaux et os à l'export).
3. **Générateurs image → 3D** (Meshy, Tripo, Rodin, Hunyuan3D…), à partir de **planches de face,
   de profil et de dos** à la même échelle (dessinées ou générées d'après la section 4), puis, dans
   Blender : nettoyage, **retopologie** (les maillages générés sont denses et désordonnés), UV,
   **textures repeintes** (celles des générateurs ont la lumière cuite et le visage flou : repeindre
   au moins le visage, les yeux et les cheveux), rig (Mixamo, AccuRIG ou Rigify, en n'exportant que
   les os de déformation) et animations. Un modèle généré brut n'est pas acceptable.

Animations : Mixamo fournit des bases de marche et de course (option « In Place ») à recaler sur
les durées exactes (section 3.4) ; l'attaque, la charge et les poses des PNJ se font à la main. Les
conditions d'utilisation de ces outils se notent dans les crédits (section 10).

### 2 bis.3 Si tu ne peux pas atteindre la barre

- **Dis-le**, avant de livrer et dans le compte rendu de livraison, au lieu de livrer un modèle au
  rabais : un modèle refusé coûte plus cher que pas de modèle.
- **Livre ce qui fait avancer** :
  - les **planches de concept** de chaque personnage : face, profil et dos à la même échelle (pose
    en A, fond uni clair, 2048 px de haut), gros plans du visage (face et trois-quarts), de la
    coiffure (dessus et dos) et des accessoires, palette en codes hexadécimaux ;
  - les **fichiers intermédiaires** : `.vrm`, `.blend`, maillages générés ou sculptés, textures de
    travail, rig sans animations…

  dans `assets/source/<id>/`, un dossier que Godot ignore (il contient un fichier vide
  `.gdignore`, à créer s'il manque) ; `.blend` et `.vrm` passent par Git LFS.
- Ne remplace jamais un modèle existant par un modèle qui ne passe pas la check-list ci-dessous.

### 2 bis.4 Check-list visuelle et rendus de contrôle

Pour chaque modèle, joins des **rendus de contrôle** en PNG 1024 × 1024 dans
`assets/source/<id>/renders/` : face, profil, dos et trois-quarts face (pose de `repos`, fond gris
neutre, lumière douce de trois-quarts) ; une silhouette en aplat noir sur blanc (face et profil) ;
une image de chaque animation clé : `repos` (image 0), `marche` et `course` (contact), `attaque`
(images 0 et 2), `charge` (images 0 à 3), `degats` (image 2), `mort` (dernière image). Pour un PNJ :
`repos`, `marche`, `parle` ; pour le Timere : `repos`, `course`, `fouet` et `morsure` (image 1),
`mort`.

- [ ] **Silhouette** : reconnaissable en aplat noir, lisible à 10 m ; rien qui flotte ni traverse.
- [ ] **Proportions** : 6,5 à 7 têtes (≈ 5 pour une petite fée, ≈ 6 pour Nephren) ; mains, pieds et
      cou à l'échelle ; taille de la section 4 à 2 cm près.
- [ ] **Visage** : yeux peints expressifs, nez et bouche présents, visage modelé, regard droit, pas
      de contour noir ; il ressemble à la description.
- [ ] **Cheveux** : mèches et volumes, raie, dégradés et reflets peints, aucun trou vu de dos ou de
      dessus.
- [ ] **Vêtements** : plis principaux, coutures, ourlets, épaisseurs ; tissu, cuir et métal se
      distinguent ; tenue conforme à la description.
- [ ] **Textures** : albédo peint, dégradés subtils, ni lumière ni ombre fortes cuites, pas de grand
      aplat uni, aucun texte, densité de pixels homogène (le visage peut en avoir plus).
- [ ] **Animations** : fluides, poids, anticipation et suivi, pieds qui ne glissent pas, aucune
      pénétration (épée dans le corps, mains dans les cuisses), boucles sans à-coup, coups et onde
      sur les bonnes images.

## 3. Conventions communes à tous les modèles (obligatoire)

### 3.1 Format

- **glTF 2.0 binaire : `.glb`**, une scène par fichier, textures **embarquées** dans le `.glb`.
- Textures **PNG**, dimensions en **puissance de deux** (256, 512, 1024 ; 2048 pour la seule
  texture tolérée de Chtholly), espace sRGB pour la couleur.
- Pas de caméras ni de lumières dans les fichiers.
- Un seul jeu d'UV (`TEXCOORD_0`).
- Pas de couleurs de sommets, sauf usage voulu et signalé : Godot les multiplie à l'albédo.
- Pas de suffixe que Godot interprète à l'import dans les noms d'objets (`-col`, `-noimp`,
  `-rigid`, `-loop`…), sauf `-colonly` et `-convcolonly` pour les collisions des décors (6.2).

### 3.2 Repère et échelle

- **1 unité = 1 mètre.**
- **Y vers le haut.**
- **L'avant du modèle regarde vers +Z** (convention glTF ; dans Blender, avant = −Y avant export,
  l'exporteur glTF convertit). Le jeu fait tourner le modèle autour de Y pour que son +Z pointe
  dans la direction de marche ou vers la cible.
- **Origine** :
  - personnages et ennemis : **au sol, au centre entre les pieds** (sous le centre du corps pour
    le Timere) ;
  - décors : **au centre de la base, au niveau du sol** (y = 0 = point de contact avec le sol).
- Transformations « appliquées » (position 0, rotation 0, échelle 1 sur l'objet racine) avant
  export.

### 3.3 Budgets (obligatoire : le jeu tourne dans un navigateur, jusque sur téléphone)

| Asset | Triangles max | Matériaux | Côté des textures | Poids du `.glb` |
| --- | --- | --- | --- | --- |
| Chtholly (Seniorious comprise) | 20 000 | 2 à 3 | 1024 (une 2048 tolérée) | ≤ 10 Mo |
| Autre personnage jouable | 18 000 | 2 à 3 | 1024 | ≤ 6 Mo |
| PNJ | 12 000 | 2 à 3 | 1024 | ≤ 5 Mo |
| Corps de Timere (jusqu'à 12 à l'écran) | 6 000 | 1 à 2 | 1024 | ≤ 3 Mo |
| Décor (prop) | 3 000 (arbre : 4 000) | 1 à 2, partagés | atlas partagés (6.1) | ≤ 1 Mo hors atlas |

- Une texture d'albédo par matériau au plus ; les 2 ou 3 matériaux d'un personnage (par exemple :
  corps et vêtements opaques, cheveux à alpha découpé, yeux) se partagent de préférence un seul
  atlas de 1024 × 1024. Exceptions des décors : section 6.3.
- Os : 64 au plus, **4 influences par sommet** au plus, poids normalisés.
- **LOD** : Godot génère les niveaux de détail à l'import ; ne livre pas de LOD. Les budgets
  valent pour le modèle complet.
- Toute la scène affichée doit rester sous **300 000 triangles** et **200 appels de dessin** (draw
  calls) : chaque matériau d'un objet coûte un appel de dessin, deux avec son ombre ; préférer peu
  de matériaux, partagés, et peu d'objets séparés.
- Le jeu complet doit rester sous **25 Mo compressés** jusqu'au jalon M3 (17 Mo aujourd'hui) et
  sous 60 Mo au jalon M4 : le jeu compresse les textures à l'import, mais chacune compte ; ne
  dépasse pas les tailles ci-dessus.

### 3.4 Réglages d'export (Blender → glTF)

- Format : **glTF Binary (.glb)**.
- Inclure : objets sélectionnés ou visibles, **Apply Modifiers**, **+Y Up** coché.
- Maillage : UVs, normales ; pas de tangentes nécessaires ; pas de couleurs de sommets (3.1).
- Animation : **Animations** cochées, mode d'animation **« Actions »** (chaque action Blender
  devient une animation glTF qui porte son nom : nomme les actions exactement comme en section
  4.3), échantillonnage forcé (« Always Sample Animations »), **pas de « root motion »**.
- **Durées exactes** : règle la cadence de la scène Blender sur un multiple commun des `ips` pour
  que chaque durée tombe sur une image entière : **70 im/s pour les personnages** (10 et 14 ips :
  `repos` 140 images Blender, `marche` 42, `course` 25, `attaque` 20, `charge` 28, `degats` 28,
  `mort` 84) et **84 im/s pour le Timere** (6, 7, 8 et 12 ips : `repos` 70, `marche` 48, `course`
  42, `fouet` 42, `morsure` 42, `degats` 35, `mort` 63). Chaque action commence à l'image 0 ; pour
  une boucle, la dernière image reprend exactement la pose de l'image 0.
- Skinning : **Skinning** coché, « Include All Bone Influences » décoché (4 au plus), « Export
  Deformation Bones Only » coché (avec Rigify ou Auto-Rig Pro, seuls les os de déformation partent).
- Compression Draco : **non** (le jeu ne la lit pas).

## 4. Personnages

### 4.1 Fichiers par personnage

Pour un personnage d'identifiant `<id>` (minuscules ASCII, chiffres et `_` : `chtholly`,
`cat_waiter`), dans `assets/models/characters/<id>/` :

```
<id>.glb            modèle + squelette + animations (obligatoire)
<id>.anim.json      cadence et images clés de chaque animation (obligatoire, section 4.4)
<id>_portrait.png   portrait carré 256 × 256, fond transparent (obligatoire)
<id>.tscn           enveloppe Godot qui applique le .anim.json au modèle
<id>.tres           ressource SkinData qui rend le modèle utilisable par le jeu
```

- **Remplacement** : quand le dossier existe déjà (les 45 personnages de la première livraison,
  listés dans [REFERENCES.md](sprites/REFERENCES.md)), le nouveau modèle le remplace sous le même
  identifiant et les mêmes noms de fichiers ; l'enveloppe et le `SkinData` restent valables. Seuls
  changent d'identifiant les personnages que la première livraison n'écrivait pas comme la
  traduction (section 4.9).
- **Enveloppe** `<id>.tscn` : copie `assets/models/characters/chtholly/chtholly.tscn` en
  remplaçant `chtholly` par `<id>` : racine `Character3D` (Node3D) portant le script
  `assets/models/characters/model_metadata.gd` et `animation_metadata` = le `.anim.json` ; enfant
  `Model` = instance du `.glb`. **`SkinData`** `<id>.tres` : copie `chtholly.tres` (`display_name`,
  `mesh_scene` = l'enveloppe, `portrait`, `height_m` = la taille ; garde l'`id` d'un fichier
  existant). Si tu ne travailles pas dans le dépôt, la session d'intégration les écrit
  (section 11).
- **Portrait** : buste de face ou de trois-quarts, cadré serré, regard vers le joueur, expression
  neutre ou souriante selon le caractère, éclairage doux sans ombre dure, fond transparent ; un
  rendu du modèle dans le style du jeu, ou une peinture fidèle au modèle. Il sert à la boîte de
  dialogue et au menu.

### 4.2 Modèle

- **Tailles debout** (sommet du crâne, sans l'épée) : Chtholly **1,50 m** ; les autres aux sections
  4.7 à 4.9, en général entre 0,9 et 2,0 m. Exceptions : Limeskin ≈ 2,8 m, et plus tard le Grand
  Sage et le médecin cyclope, des géants. La taille va aussi dans `hauteur_m` (4.4) et `height_m`.
- **Largeur** : le corps tient dans un cylindre vertical de **0,35 m de rayon** (la collision du
  joueur et des PNJ), bras le long du corps. Seuls l'épée, les cheveux, la cape et une queue peuvent
  en sortir ; les grands PNJ (boulanger, Limeskin) peuvent aller jusqu'à 0,5 m (le jeu adaptera leur
  collision).
- **Pose de repos du squelette** : T-pose ou A-pose.
- **Squelette** humanoïde, un seul maillage « skinné » de préférence (cheveux et épée peuvent être
  des maillages à part sur le même squelette). **Noms d'os obligatoires**, ceux des modèles déjà
  livrés, identiques d'un personnage à l'autre pour partager les animations : `root` (au sol, à
  l'origine, jamais déplacé à l'horizontale), `hips`, `spine`, `chest`, `neck`, `head`,
  `shoulder.L`, `upper_arm.L`, `lower_arm.L`, `hand.L`, `upper_leg.L`, `lower_leg.L`, `foot.L` (et
  `.R`). Os en plus permis, aux noms clairs : `toe.L`, doigts (`thumb_1.L`…), `jaw`, `eye.L`,
  paupières, chaînes de mouvement secondaire (`hair_1`…, `skirt_1`…, `cape_1`…, `scarf_1`…).
  Renomme les os d'un rig automatique (Mixamo `mixamorig:Hips`, VRoid `J_Bip_C_Hips`…).
- **Budget d'os** (64 au plus) : ≈ 20 pour le corps, 10 à 16 pour des mains simplifiées (pouce et
  deux groupes de doigts, ou doigts complets s'il reste de la place), le reste pour le visage et le
  mouvement secondaire.
- **Visage** : clignement recommandé dans `repos` et `parle`, par des os de paupières ou par des
  morph targets (`blink`, et `mouth_open` pour `parle`) ; 8 morph targets au plus, sur le visage
  seulement.

### 4.3 Animations (noms et durées : obligatoire)

- **Noms exacts**, en minuscules, sans accent ni suffixe : `repos`, `marche`, `course`, `attaque`,
  `charge`, `degats`, `mort`. Le jeu appelle les animations par ces noms. Une animation en plus est
  tolérée (le jeu l'ignore), une animation manquante ne l'est pas.
- **Sur place** : aucune translation horizontale de la racine (le jeu déplace le personnage
  lui-même). Le bassin peut monter et descendre.
- **Cadence et images** : le jeu raisonne en « images » comme l'easter egg 2D. Une animation a une
  cadence `ips` (images par seconde) et un nombre d'images ; **sa durée doit valoir exactement
  `images / ips` secondes**, à 1 ms près (sinon le jeu signale une erreur et ignore ses
  métadonnées). Les images « coup » (l'épée touche) et l'image « onde » (l'onde part) sont des
  numéros d'image, à partir de 0 ; l'image n commence à l'instant n / ips. Le modèle est lu en
  continu, à la cadence de l'écran : anime avec autant de clés qu'il faut, les « images » ne sont
  que les repères de temps du combat.

| Animation | ips | Images | Durée | Boucle | Coup | Onde | Contenu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `repos` | 10 | 20 | 2,0 s | oui | | | respiration, léger balancement, cheveux qui bougent ; épée en main, en biais, pointe sans toucher le sol |
| `marche` | 10 | 6 | 0,6 s | oui | | | un cycle de 2 pas sur place pour 4 m/s : 2,4 m par cycle (marche très rapide ou petit trot) |
| `course` | 14 | 5 | 0,357 s | oui | | | un cycle de 2 foulées pour 7 m/s : 2,5 m par cycle, buste penché, épée tenue en arrière |
| `attaque` | **14** | **4** | **0,286 s** | non | **1, 2, 3** | | coup horizontal devant soi, arc de 90° centré sur +Z, lame à hauteur de taille (≈ 0,8 m), portée ≈ 1,2 m du centre du corps : image 0 armé, images 1 à 3 la lame balaie l'avant, fin sur une pose de garde d'où le même coup repart (trois coups enchaînés) |
| `charge` | **10** | **4** | **0,4 s** | non | | **3** | le jeu n'en montre que quatre poses figées, aux instants 0 ; 0,1 ; 0,2 et 0,3 s : images 0 puis 1 pendant que la jauge monte, alternance 1-2 (8 bascules par seconde) quand elle est pleine, image 3 au relâchement, épée pointée vers l'avant (+Z) quand l'onde part ; chaque pose doit tenir seule |
| `degats` | 10 | 4 | 0,4 s | non | | | recul sous un coup, buste rejeté en arrière, retour vers la garde |
| `mort` | 10 | 12 | 1,2 s | non | | | elle s'effondre (genoux puis au sol) ; **la dernière image reste à l'écran** ; c'est une défaite, pas une mort : ni sang ni pose macabre (les grains de lumière sont un effet du jeu) |

En gras : valeurs **imposées** par le combat. Les autres peuvent varier (garder alors
`durée = images / ips` et les indiquer dans le `.anim.json`) ; les modèles livrés utilisent celles
du tableau.

### 4.4 Fichier `<id>.anim.json` (obligatoire)

Le glTF ne sait pas dire qu'une animation boucle ni quelles images touchent : ce fichier le dit au
jeu. Mêmes clés que les planches 2D de l'easter egg ; `model_metadata.gd` lit `ips`, `images`,
`boucle`, `coup` et `onde`, vérifie chaque durée et les inscrit sur les animations du modèle.

```json
{
  "version": 1,
  "modele": "chtholly.glb",
  "hauteur_m": 1.5,
  "usage": "combat",
  "animations": {
    "repos":   { "ips": 10, "images": 20, "boucle": true },
    "marche":  { "ips": 10, "images": 6,  "boucle": true },
    "course":  { "ips": 14, "images": 5,  "boucle": true },
    "attaque": { "ips": 14, "images": 4,  "boucle": false, "coup": [1, 2, 3] },
    "charge":  { "ips": 10, "images": 4,  "boucle": false, "onde": 3 },
    "degats":  { "ips": 10, "images": 4,  "boucle": false },
    "mort":    { "ips": 10, "images": 12, "boucle": false }
  }
}
```

`usage` : `combat` (jeu complet de la section 4.3), `npc` (PNJ, section 4.5) ou `enemy` (Timere) ;
`hauteur_m` : la taille debout (4.2).

### 4.5 PNJ : format et animations

- Même format, mêmes conventions et même squelette (noms d'os de 4.2) que les personnages
  jouables, dossier `assets/models/characters/<id>/`, `"usage": "npc"`.
- Animation **obligatoire** : `repos` (boucle d'environ 2 s, par exemple 10 ips × 20 images).
  **Recommandées** : `marche` (boucle ; allure de promenade, par exemple 10 ips × 10 images = 1 s
  pour ≈ 1,4 m/s, pieds plantés) et `parle` (boucle d'environ 2 s : gestes légers de la tête et des
  mains, bouche si le visage le permet). Les personnages déjà livrés ont les trois : garde-les.
- Pas d'épée en main pour un PNJ ; un Carillon emmailloté de tissu dans le dos est permis pour une
  fée soldat.
- Portrait obligatoire : c'est lui que montre la boîte de dialogue.

### 4.6 Chtholly (acte 1) et Seniorious

- `chtholly`, **1,50 m**, ≈ 7 têtes ; 15 ans, l'aînée et la plus grande de l'entrepôt ; jeu
  complet (4.3), 20 000 triangles au plus avec l'épée (planches de référence : pages 11 à 20).
- **Cheveux** : longs, bleu ciel céruléen clair (indicatif `#6C89BB` à `#92B6DB`), sous les
  épaules jusqu'au milieu du dos, avec deux petites couettes hautes de part et d'autre du haut de
  la tête ; **aucune mèche rouge à l'acte 1** (les cheveux qui rougissent sont un spoiler de l'acte
  3, qui aura sa variante).
- **Yeux** bleu océan, un peu plus foncés que les cheveux ; visage fin, air fier et sérieux.
- **Tenue**, l'uniforme de fée soldat de la Garde ailée : veste courte bleu nuit à col droit et
  boutons argentés, chemisier blanc, jupe plissée sombre (short sombre dessous), bas sombres,
  bottines de cuir brun ; une armure légère discrète (quelques pièces de métal mat aux épaules ou
  aux avant-bras) ; la **broche d'argent** à pierre bleue en goutte, sur la poitrine. Plus tard, une
  variante : la tenue de ville (grand chapeau sombre à large bord, manteau gris souris).
- **Seniorious**, l'épée : maillage à part nommé `Seniorious`, dans le même `.glb`, attaché à l'os
  `hand.R` (enfant de l'os, ou pondéré à 100 % sur lui) ; elle remplace l'épée « bleu glacier » de
  la planche de l'easter egg :
  - presque aussi haute que sa porteuse : ≈ 1,4 m du pommeau à la pointe ; une grande épée à deux
    mains, à lame large ;
  - lame **blanc argenté** faite de plaques de métal grandes comme un poing (des talismans)
    ajustées comme un puzzle, séparées par des fissures nettes ; chaque bord de fissure a une
    nuance un peu différente (argent, blanc chaud, gris froid) ;
  - garde sombre et hérissée, un cristal au cœur de la garde, poignée gainée de cuir sombre ;
  - **lumière des fissures** : quand la porteuse charge, une lumière filtre par les fissures (sa
    teinte bleutée est un choix du jeu). Livre un masque des fissures en niveaux de gris, aux mêmes
    UV que l'épée (blanc = fissure, 512 × 512) :
    `assets/models/characters/chtholly/seniorious_glow.png` ; le jeu s'en servira (section 11).
    Pas d'émission dans la texture de base.

### 4.7 Autres skins jouables

- **Règles communes** : même squelette (noms d'os de 4.2), mêmes animations et mêmes durées que
  Chtholly (4.3), qui peuvent être reprises et ajustées ; Seniorious en main (le maillage de 4.6,
  réutilisé), car le joueur en est toujours la porteuse ([MONDE.md](lore/MONDE.md), section 1.2) ;
  18 000 triangles au plus ; `"usage": "combat"`.
- **Modèle qui sert aussi de PNJ** (Ithea et Nephren à l'acte 1, les fées de la communauté) : ajoute
  `parle` ; l'épée reste un maillage à part (`Seniorious`) que le jeu cache pour le PNJ, et le
  `repos` doit rester naturel sans elle (main droite basse, près du corps).
- **Fées soldats adultes du canon** :
  - `ithea` — **Ithea Myse Valgulious**, 14 ans, ≈ 1,45 m, ≈ 6,5 têtes (réf. p. 21 à 26).
    Cheveux blond paille tirant sur l'orangé (indicatif `#FDE7BD` à `#E4B68E`), deux mèches
    pointues comme des oreilles de chat, une longue tresse à perle bleue ; yeux ambrés au regard
    félin, petit croc, sourire taquin. Écharpe rouge, collier de losanges sombres et rouges,
    veste vert pâle à larges manches sur une robe brun-rouge, short noir, bas vert olive, bottes
    brunes. PNJ à l'acte 1 (au puits).
  - `nephren` — **Nephren Ruq Insania** (« Ren »), 13 ans qui en paraît dix, ≈ 1,30 m, ≈ 6 têtes
    (réf. p. 27 à 32). Cheveux gris cendré ondulés à reflets lavande (indicatif `#D3D0E6`), en deux
    couettes nouées de rubans noirs ; yeux gris anthracite, visage impassible. Tunique violette à
    capuche bordée d'une frise de triangles blancs ; un livre rouge à la main en PNJ. PNJ à l'acte 1
    (banc sous la fenêtre de la salle de lecture).
  - `nopht` — **Nopht Keh Desperatio** (acte 3), ≈ 1,40 m (réf. p. 33 à 36) : cheveux vermillon
    courts et hérissés (rose-rouge, indicatif `#EF7F7B`), yeux rouges, allure de garçon ; sweat à
    capuche brun foncé, bretelles rouges, short bordeaux à l'ourlet effiloché sur des jambières
    noires.
  - `rhantolk` — **Rhantolk Ytri Historia** (acte 3), ≈ 1,48 m (réf. p. 37 à 40) : cheveux indigo
    bleu lavande à frange droite (indicatif `#868BBF` à `#A1A1D0`) ; fichu blanc, robe bleu ciel
    lacée à pèlerine, ceinture sombre nouée, lanterne.
- **Fées de la communauté** (`fairy_<prénom>`, à la fois PNJ et skin jouable ; règles complètes
  dans [HISTOIRE.md](lore/HISTOIRE.md), section 5.3) : filles de 7 à 15 ans d'apparence,
  semblables aux humains (ni oreilles animales, ni queue, ni cornes), aux cheveux d'une couleur vive
  qui n'est pas celle d'une fée du canon (turquoise, corail, menthe, lilas pâle, abricot, argent
  bleuté, mèches de deux couleurs…) ; tenues du quotidien de l'entrepôt aux tons d'automne
  (robes-tabliers, gilets, capes, écharpes, bottines) ; une fée adulte (13 à 15 ans) porte
  l'uniforme informel de la Garde (bleu nuit, boutons d'or ou d'argent, armure légère). Le dessin du
  membre sert de planche de concept, avec son accord écrit (section 10).
- **Plus tard** : Tiat (épilogue de l'acte 3), Nephren (acte 4, partie A), Lakhesh (la relève de
  l'acte 4) et Lillia (bonus) deviennent jouables ; leurs modèles gardent le squelette commun pour
  recevoir le jeu complet le moment venu.

### 4.8 PNJ de l'acte 1 (priorité)

Apparences d'après [HISTOIRE.md](lore/HISTOIRE.md) (sections 5.1 et 5.2) et
[BIBLE.md](lore/BIBLE.md) (section 5). La description fait foi pour les couleurs et les traits ; les
planches de référence (pages de [REFERENCES.md](sprites/REFERENCES.md), hors du dépôt) servent pour
les formes, les coupes et les détails de costume, à interpréter, jamais à décalquer. Les tailles que
HISTOIRE.md ne donne pas sont des tailles de travail, à reporter dans le `height_m` du visuel du PNJ
(`data/npcs/visuals/<id>.tres`). Ordre de livraison, du plus urgent au moins urgent :

- `nygglatho` — **Nygglatho**, 1,85 m (une tête de plus que tout le monde), ≈ 7 têtes (réf. p. 51
  à 53). Troll à l'air de jeune femme, sans aucun trait animal ; visage enfantin et doux.
  Longs cheveux rose saumon (indicatif `#D98088` à `#F3A3A6`), yeux vert printanier. Chemisier vert
  vif à volants, col à ruban noir et petite broche, tablier blanc, coiffe blanche à volants ;
  pantoufles ou souliers plats. Plus tard : la blouse blanche pour soigner.
- `willem` — **Willem Kmetsch**, 1,75 m, ≈ 7 têtes, grand et mince (réf. p. 5 à 10). Cheveux noirs
  en bataille, yeux sombres, visage ordinaire, sourire vague et fatigué. Uniforme militaire noir
  (ou bleu nuit) croisé, à boutons et liserés dorés et épaulettes, un peu trop étroit, ceinturon,
  bottes ; petit pendentif-talisman au cou. Un seul modèle sert aussi à `willem_training` et
  `willem_stars`. Accessoire facultatif : un Carillon de série porté sur l'épaule. Plus tard : un
  tablier et un mouchoir noué sur la tête pour cuisiner.
- `nephren` et `ithea` : section 4.7.
- `tiat` — **Tiat**, 1,10 m, ≈ 5 têtes, moins de dix ans d'apparence (réf. p. 41 à 44). Cheveux
  courts et yeux vert feuille (indicatif `#78B89E`), air enthousiaste. Blouse blanche, gilet vert
  sombre, jupe, bottines.
- `collon` — **Collon**, 1,20 m, ≈ 5 têtes (réf. p. 47 et 48). Très longs cheveux roses, bandeau
  rouge, un petit croc qui dépasse, air espiègle ; tunique lacée.
- `lakhesh` — **Lakhesh**, 1,20 m, ≈ 5 têtes (réf. p. 49 et 50). Cheveux pêche, orangés, avec une
  petite couette sur le côté ; yeux bruns, air doux et poli ; gilet brun clouté sur une robe claire.
- `almita` — **Almita**, 0,95 m, ≈ 5 têtes, la plus petite (réf. p. 64, en haut). Cheveux crépus
  jaune citron ; tenue d'après la planche (boléro gris-vert, tablier blanc à poches, jupe sombre).
- `pannibal` — **Pannibal**, 1,25 m, ≈ 5 têtes, une dizaine d'années (réf. p. 45 et 46). Cheveux
  et yeux violet vif, frange qui cache un œil, air impassible ; petite cape ou veste à capuche
  sombre, épée de bois, brindille au coin des lèvres.
- `limeskin` — **Limeskin**, ≈ 2,8 m, exception de taille (réf. p. 55 et 56) : commandant de la
  Garde ailée, reptilien géant aux écailles blanc laiteux, tête draconique cornue, tresse ornée de
  plumes, collier tribal, uniforme d'officier de la Garde ; mâchoire articulée bienvenue (il parle
  en sifflant).
- `cat_waiter` — **le serveur du café** La Clochette, 1,65 m : homme-chat aimable, canines
  visibles, tablier de service sur chemise et gilet.
- `egg_vendor` — **la marchande d'œufs** (personnage original), 1,55 m : sang-mêlé de mouton,
  oreilles de mouton et laine bouclée, fichu, panier de paille au bras.
- `snack_vendor` — **le jeune lycanthrope du snack**, 1,60 m : jeune homme à tête de chien,
  fourrure châtaine, tablier taché de graisse, poêle à frire.
- `ramikeldi` — **M. Rami** (Ramikeldi Limashenka), 1,70 m : homme-chat d'âge mûr, yeux ambrés,
  chemise blanche, gilet rouge foncé, chapeau ; allure courtoise.
- `ferryman` — **le passeur** de l'île n° 53, 1,70 m : reptilien en ciré, casquette de pilote,
  lunettes de vol.
- `baker` — **le boulanger**, 2,00 m : homme-bête massif à tête d'ours, couvert de farine, tablier
  et manches retroussées, air bourru.
- `garde_lookout` — **le guetteur** (personnage original, facultatif), 1,90 m : lézard en uniforme
  de la Garde ailée, longue-vue.

Les habitants du bourg sont des hommes-bêtes : un trait animal bien visible est obligatoire.
Animations : section 4.5 (Ithea et Nephren : 4.7).

### 4.9 Personnages des actes suivants (liste courte)

À faire après les priorités de l'acte 1 ; apparences à préciser au jalon (HISTOIRE.md, section 5.1)
avec les identifiants de la traduction :

- `glick` — Glick Graycrack, boggart récupérateur, ami de Willem : peau gris-vert, petites cornes,
  oreilles pointues, crocs, yeux ambrés, lunettes d'aviateur sur le front, gilet de cuir matelassé,
  mitaines.
- `phyr` — Phyracorlybia Dorio (« Phyr »), lycanthrope : fine fourrure blanche, visage de loup,
  oreilles couleur paille brûlée ; chapeau à marguerite, ombrelle, robe turquoise.
- `suowong` — le Grand Sage, Suowong Kandel : vieillard colossal, barbe et cheveux dorés, cape d'un
  blanc éclatant ; `suowong_young`, sa forme d'autrefois : petit thaumaturge blond, cape blanche
  trop longue.
- `kaya` — Kaya, servante semifère : oreilles de chat, cheveux sombres, robe noire, tablier, coiffe
  à voile.
- `ebon_candle` — Ebon Candle : énorme crâne noir aux orbites lumineuses, dans un chariot ou sur un
  coussin rouge dans un cadre de fer forgé ; `ebon_candle_ancient`, son ancien corps.
- `doctor` (médecin cyclope géant, lunettes noires, blouse), `baroni_makish` (homme-lapin aux
  cheveux blancs en queue, lunettes rondes, uniforme à col montant), `elq`, `almaria`, `lillia`
  (jouable en bonus : jeu complet), `carmine_lake`, puis ceux que HISTOIRE.md liste sans apparence.

Ces identifiants remplacent ceux de la première livraison, qui ne suivaient pas la traduction :

| Dossier livré | Identifiant |
| --- | --- |
| `grick` | `glick` |
| `kaiya` | `kaya` |
| `souwong_sage`, `souwong_young` | `suowong`, `suowong_young` |
| `eboncandle_skull`, `eboncandle_ancient` | `ebon_candle`, `ebon_candle_ancient` |
| `cyclops_doctor` | `doctor` |
| `baroni` | `baroni_makish` |

Les autres modèles déjà livrés gardent leur identifiant et seront refaits en dernier : les petites
fées de la page 64 (`sarya`, `willemia`, `ecluecla`, `jorget`, `tilfey`, `bitora`, `illustote`,
`rinsha`), les soldats et chevaliers (`frog_soldier`, `bird_soldier`, `wolf_soldier`,
`hawk_soldier`, `cat_soldier`, `rabbit_soldier`, `knight_canine`, `knight_feline`), les golems
(`golem`, `police_golem`), `ballman` et `godrey`.

## 5. Ennemis : Timere

Fichiers :

```
assets/models/enemies/timere/timere.glb
assets/models/enemies/timere/timere.anim.json
assets/models/enemies/timere/timere.tscn       enveloppe, comme en 4.1 (model_metadata.gd)
```

- Timere est **une seule Bête** ([HISTOIRE.md](lore/HISTOIRE.md), sections 7.1 et 7.2) ; le jeu en
  montre des corps de tailles différentes, tirés du **même modèle à l'échelle 1** : Rejeton de
  Timere × 0,8 (`timere_small`), Timere bondissant × 0,9 (`timere_runner`), Fragment de Timere × 1
  (`timere_normal`), Grand fragment de Timere × 1,3 (`timere_big`). Ne pas livrer quatre modèles.
  Bonus : une variante de matière pour le Grand fragment (plus sombre, croûte qui annonce une
  carapace), en matériau séparé dans le même fichier.
- À l'échelle 1 : hauteur au repos **1,03 m** (sommet de la tête), longueur ≈ 1,3 m ; face vers
  **+Z**, origine **au sol sous le centre du corps** ; le corps et les pattes au repos tiennent dans
  un cylindre de **0,4 m de rayon** (la collision), seuls le cou et la tête dépassent vers l'avant.
- **Apparence**, dans la même direction artistique que le reste du jeu : une créature crédible et
  inquiétante, ni monstre de dessin animé ni animal réel.
  - La silhouette de la planche de l'easter egg reste la base : corps voûté, long cou souple
    terminé par une gueule dentée, six pattes.
  - Une masse vert sombre, amorphe, à la chair humide et granuleuse (reflets huileux peints, pas de
    spéculaire), qui semble mal tenir sa forme : bourrelets, plis, pustules.
  - Des tentacules devenus pattes de crustacé épineuses : base molle et charnue, segments durcis
    vers le bout, épines et griffes.
  - Une gueule irrégulière à crocs, intérieur rouge sombre ; quelques petits yeux pâles en grappe,
    sans regard animal.
  - Couleurs : verts sombres un peu désaturés (`#46533A` à `#66774F`), dessous plus sombre, pointes
    des pattes et crocs ivoire sale ; contraste de valeur net avec le sable pâle du Couchant et
    l'herbe des bois.
  - Rien qui évoque un animal réel (ni araignée, ni crabe, ni dinosaure reconnaissables).
- **Squelette** : `root`, colonne (3 os au moins), cou (4 os au moins pour onduler), tête,
  mâchoire, tentacule du fouet (4 os au moins), pattes (2 ou 3 os chacune) ; 64 os au plus.
  Budgets : 6 000 triangles, 1 ou 2 matériaux, textures de 1024 au plus.
- **Plus tard** (actes 2 et 3, même squelette, maillages ou matériaux à part dans le même fichier,
  cachés par défaut) : pattes en ressort, lianes, carapace.

| Animation | ips | Images | Durée | Boucle | Coup | Contenu |
| --- | --- | --- | --- | --- | --- | --- |
| `repos` | 6 | 5 | 0,833 s | oui | | le cou ondule, les pattes tapotent, la masse respire |
| `marche` | 7 | 4 | 0,571 s | oui | | marche de crustacé, cou bas ; ≈ 1,2 m par cycle à l'échelle 1 |
| `course` | 12 | 6 | 0,5 s | oui | | la charge du Timere bondissant, en ligne droite : bonds, l'arrière se comprime comme un ressort et l'avant bondit, cou tendu ; ≈ 3 m par cycle |
| `fouet` | **8** | **4** | **0,5 s** | non | **1, 2** | un tentacule jaillit de la gueule et cingle devant (comme sur la planche), portée ≈ 1 m |
| `morsure` | **8** | **4** | **0,5 s** | non | **1, 2** | la tête plonge vers l'avant et mord, portée ≈ 0,8 m |
| `degats` | 12 | 5 | 0,417 s | non | | secousse, recul de la masse |
| `mort` | 8 | 6 | 0,75 s | non | | s'effondre, pattes repliées ; la dernière image reste (le jeu réduit ensuite le corps) |

`timere.anim.json` : même structure qu'en 4.4, avec `"usage": "enemy"`, `"hauteur_m": 1.03` et ces
valeurs (`"coup": [1, 2]` pour `fouet` et `morsure`). Pas de portrait.

## 6. Décors (props)

### 6.1 Fichiers et matériaux partagés

```
assets/models/props/<nom>.glb
assets/models/props/atlas_<matière>.png     atlas peints partagés, 1024 × 1024
```

- Les décors se partagent **cinq atlas peints** de 1024 × 1024 : `atlas_wood` (planches, rondins,
  poutres, écorce), `atlas_stone` (pierre de l'île, maçonnerie, ardoise, tuiles, briques),
  `atlas_metal` (fer riveté, tôle, cuivre, laiton, cristaux), `atlas_plants` (feuillages en cartes à
  alpha découpé, herbe, roseaux, fleurs, mousse) et `atlas_cloth` (draps, bâches, fanions, cordes,
  cuir). Chacun mêle des bandes tuilables et des motifs (trim sheet), peints selon la section 2.
- Un décor utilise 1 ou 2 matériaux, nommés **exactement** `prop_wood`, `prop_stone`, `prop_metal`,
  `prop_plants` ou `prop_cloth` (même nom = même matériau et même atlas dans tous les fichiers),
  plus `prop_glow` pour ce qui éclaire (fenêtres éclairées, cristaux) : une couleur claire unie que
  le jeu rend sans ombrage.
- Le `.glb` embarque les atlas qu'il utilise (section 3.1) ; le jeu n'en garde qu'une copie et
  remplace ces matériaux par les siens à l'import (section 11).
- Une texture propre (1024 au plus, un matériau de plus) n'est admise que pour les décors uniques
  de la section 6.3 qui ont un budget particulier.

### 6.2 Conventions

- Origine au **centre de la base, au sol**, avant vers +Z, échelle réelle (section 2.4).
- **Collisions** : ajouter dans le même `.glb` une forme simplifiée **invisible** dont le nom se
  termine par **`-colonly`** (boîte, cylindre ou enveloppe grossière, quelques dizaines de
  triangles), ou **`-convcolonly`** pour une forme convexe. Godot en fait automatiquement un corps
  statique. Une collision pour les troncs, murs, rochers, palissades, garde-corps et étals ; aucune
  pour le feuillage, les fleurs, l'herbe, les roseaux et les mares.
- Pas de faces cachées sous le sol ; pas de faces doubles ; portes et fenêtres fermées (pas
  d'intérieur à l'acte 1).

### 6.3 Liste des décors

La liste fait foi dans [MONDE.md](lore/MONDE.md) : section 3 (nom, description, taille, zone,
élément remplacé) et section 5.6 (la même, groupée par zone, pour la commande à ChatGPT). Elle
remplace l'ancienne liste (maisons, haies, arches de style torii, palmiers, parasols, ponton,
bouées…). Ordre de livraison pour l'acte 1 :

1. **L'entrepôt et sa cour** : `warehouse_main`, `warehouse_wing`, `warehouse_porch`,
   `warehouse_roof_deck`, `armory_door`, `well`, `palisade`, `palisade_gate`, `crystal_lamp`,
   `laundry_line`, `climbing_tree`, `bench`, `tool_shed`, `vegetable_patch`, `play_goal`, `ball`.
2. **Les bois** : `tree_autumn` (trois teintes), `tree_old_pine`, `berry_bush`, `reeds`,
   `marsh_pool`, `log_bridge`, `bear_rock`, `stick_rack`, `mushroom`.
3. **Le Couchant** : `vigil_bell`, `watch_post_ruin`, `ruined_wall`, `signal_pillar`,
   `garde_pennant`, `wind_rock`, `edge_parapet`.
4. **Le port et le bourg** : `metal_quay`, `gangway`, `edge_railing`, `mooring_arm`,
   `cargo_crane`, `crates_barrels`, `scrap_pile`, `signpost`, `market_stall`, `snack_stall`,
   `cafe`, `shop_front`, `projection_hall`, `stone_house`, `limashenka_house`, `wind_sock`.
5. **La colline** : `lookout`, `lone_tree`, `flowers` (massif de myosotis).
6. **Les bords et l'horizon** : `island_underside`, `floating_rock`, `distant_island_a|b|c`,
   `edge_waterfall`, `airship_ferry`, `airship_barocupot`.

**Budgets particuliers** (au-delà de 3 000 triangles, 4 000 pour un arbre) : `warehouse_main`
6 000, `climbing_tree` 6 000, `airship_ferry` 6 000, `airship_barocupot` 8 000 (ou deux modules),
`island_underside` 12 000 ; `distant_island_*` 1 000 au plus ; objets au sol à ramasser (page,
drap, engrenage, baies, myosotis, peigne) 500 au plus chacun.

Nouveaux décors bienvenus, dans le même univers et le même format : charrette à bras, tonneaux,
caisses, sacs, outils de jardin, pots de fleurs, lanternes à cristal suspendues, abreuvoir.

## 7. L'île et ses zones (cartes)

**La spécification de carte complète est [MONDE.md](lore/MONDE.md), section 5** (mission, repères,
plan détaillé, style, ambiance, décors, formats, vérifications) : c'est elle qu'on donne à ChatGPT
pour la carte illustrée, les décors et le terrain. Ce qui suit en rappelle l'essentiel et les règles
de jeu, obligatoires.

L'île n° 68 est une dalle de pierre qui flotte au-dessus d'une mer de nuages : une lèvre de pierre
nette et irrégulière (le tracé de la côte actuelle, rayon d'environ 74,5 m), une falaise de 15 à
20 m, puis un cône de roche inversé (strates, racines qui pendent) ; ni eau autour ni plage, la mer
de nuages est un plan très bas que le jeu dessine (MONDE.md, section 2.8). Trois façons de remplacer
le terrain actuel, calculé par le jeu, de la plus simple à intégrer à la plus lourde :

**A. Garder le terrain, remplacer les décors (recommandé d'abord)** : les décors de la section 6
suffisent à changer l'allure du monde. Rien à livrer de plus.

**B. Terrain en images** (idéal pour une IA qui génère des images) :

```
assets/models/island/island_height.png    carte de hauteur, niveaux de gris 16 bits, 257 × 257 px
assets/models/island/island_albedo.png    couleur du sol vue de dessus, 1024 × 1024 px
assets/models/island/island_layout.json   rappel des repères (centres de zones, échelle)
```

- L'image couvre le carré de 160 × 160 m : **haut de l'image = nord (−Z)**, **gauche = ouest
  (−X)** ; 1 pixel de hauteur = 0,625 m.
- Hauteur linéaire : noir (0) = −1,3 m, blanc (65535) = +12 m ; le sol courant (0 m) vaut 6 406, le
  sommet de la colline (8 m) 45 825, le marais (−0,3 m) 4 927. **Hors de l'île, du noir** : le jeu
  y met le vide et les falaises ; le bord est net (le dernier mètre au niveau du sol voisin, puis
  noir).
- L'albédo peint, sans ombres portées ni texte : l'herbe et l'herbe sèche, les chemins de terre et
  de vieilles dalles (3 m de large au moins), la cour de l'entrepôt, les pavés de la rue du Port, la
  tôle du quai, le sable et la pierre du Couchant, le cercle de veille et son anneau, le sous-bois,
  le marais.
- `island_layout.json` : modèle dans MONDE.md, section 5.7.

**C. Île complète en `.glb`** : `assets/models/island/island.glb`, sol visible de 60 000 triangles
au plus, avec une forme de collision séparée `ground-colonly` simplifiée (20 000 triangles au
plus) ; falaises et dessous de l'île peuvent être inclus. Respecter exactement les repères
ci-dessous.

### Repères à respecter (obligatoire pour B et C)

Coordonnées en mètres, centre de l'île = (0, 0), x vers l'est, z vers le sud, y vers le haut. Les
identifiants, les centres, les limites et les points d'apparition des cinq zones ne changent pas
(PLAN.md, section 3).

| Zone (`zone_id`) | Nom | Centre (x, z) | Contraintes de jeu |
| --- | --- | --- | --- |
| `village` | L'entrepôt des fées | (0, 0) | cour plate de 9 m de rayon, puits au centre ; palissade à 21 m du centre avec **4 portails** (N, S, E, O) au bout des chemins ; apparition du joueur en (0, 9), dégagée ; entrepôt en L au nord-ouest (x −19 → −3, z −19 → −11 ; aile x −19 → −13, z −11 → −2) |
| `dunes` | Le bord du Couchant | (−51, 0) | **cercle plat de 15 m de rayon, totalement dégagé** (rien de plus haut que 0,3 m) ; 4 points d'apparition d'ennemis à 13 m du centre (N, S, E, O) ; cloche en (−42, −2) ; ruines et dunes au-delà de 17 m |
| `forest` | Les bois du marais | (0, −51) | **clairière de 15 m de rayon sans arbre ni obstacle** ; forêt dense autour ; marais plat vers (−32, −56) |
| `beach` | Le port et le bourg | (0, 51) | rue du Port à z ≈ 45 ; quai de z 59 à 68 ; passerelle qui part de (12, 62) vers le sud ; panneau en (2, 35) |
| `hill` | La colline des étoiles | (52, −3) | rayon 21 m, **sommet plat de 4 m de rayon à 8 m de haut**, belvédère de 4 × 4 m au sommet |

Règles de jeu sur tout le terrain : **pentes praticables ≤ 40°** (45° au maximum), aucun trou,
aucune marche de plus de 10 cm sur les chemins, chemins d'au moins 3 m de large entre les zones,
ruisseau et mares peints au ras du sol (jamais de trou d'eau), rien d'utile à moins de 3 m du vide ;
le bord de l'île reste dans le carré de ±78 m, les murs invisibles sont au carré de ±80,5 m.

## 8. Images 2D associées

- **Portraits** : 256 × 256, PNG transparent (section 4.1).
- **Icônes d'objets** (facultatif) : 64 × 64, PNG transparent, `assets/items/<id>.png`, peintes
  dans la même direction ; objets de l'acte 1 dans [HISTOIRE.md](lore/HISTOIRE.md), section 6 (page
  du livre d'images, myosotis, drap envolé, œufs frais, baies sauvages, crème fraîche, engrenage de
  laiton, peigne de carillon, et les souvenirs).
- **Carte illustrée** : `assets/textures/map_island68.png`, 2048 × 2048, sans aucun texte
  (MONDE.md, section 5.1).
- **Textures** : puissance de deux, 1024 au plus (2048 tolérée pour Chtholly), PNG ; aucun texte
  écrit dans les textures (le jeu est en français et pourra être traduit).
- **Planches 2D** (si l'on garde des sprites pour un personnage plutôt qu'un modèle 3D) : même
  format que `assets/characters/chtholly/chtholly.png` + `.json` (une image par pose, ancre aux
  pieds, mêmes animations et mêmes nombres d'images que le JSON de Chtholly). Les planches de
  remplacement de `tools/gen_placeholders.py` ne servent qu'en attendant les modèles.

## 9. Livraison

Arborescence attendue (seuls les dossiers des assets livrés) :

```
assets/
├── CREDITS.md                     une ligne par asset (section 10)
├── characters/CREDITS.md          personnages tirés du dessin d'un membre (section 10)
├── models/
│   ├── characters/
│   │   ├── model_metadata.gd      existe déjà : ne pas le modifier
│   │   ├── chtholly/              chtholly.glb, chtholly.anim.json, chtholly_portrait.png,
│   │   │                          chtholly.tscn, chtholly.tres, seniorious_glow.png
│   │   └── <id>/                  un dossier par personnage (sections 4.7 à 4.9)
│   ├── enemies/
│   │   └── timere/                timere.glb, timere.anim.json, timere.tscn
│   ├── props/                     <nom>.glb (section 6.3), atlas_<matière>.png
│   └── island/                    option B ou C (section 7)
└── source/                        .gdignore ; <id>/ : concept/, renders/, .blend, .vrm (2 bis)
```

**Ordre des lots**, chacun complet avant le suivant : 1. Chtholly (acte 1) et Seniorious ; 2. les
PNJ de l'acte 1, dans l'ordre de la section 4.8 ; 3. le Timere ; 4. les décors de l'acte 1, dans
l'ordre de la section 6.3, puis le terrain et la carte (MONDE.md, section 5) ; 5. le reste (skins
jouables de 4.7, personnages et figurants de 4.9). Un personnage complet et soigné vaut mieux que
dix ébauches.

Les `.glb`, `.vrm` et `.blend` sont suivis par **Git LFS** dans ce dépôt (déjà configuré dans
`.gitattributes`) : installer `git lfs` avant de les commiter.

### Check-list avant de livrer

- [ ] Le `.glb` s'ouvre sans erreur dans le validateur glTF de Khronos et dans Blender.
- [ ] Échelle : taille de la section 4 (Chtholly 1,50 m, Timere 1,03 m) ; origine aux pieds ; face
      vers +Z ; transformations appliquées.
- [ ] Squelette : noms d'os de la section 4.2, 64 os au plus, 4 influences, poids normalisés.
- [ ] Toutes les animations obligatoires sont présentes, **nommées exactement**, sur place.
- [ ] Chaque durée vaut `images / ips` du `.anim.json` à 1 ms près ; `attaque` = 0,286 s,
      `charge` = 0,4 s, `fouet` et `morsure` = 0,5 s.
- [ ] Budgets de la section 3.3 respectés (triangles, matériaux, textures, poids du fichier).
- [ ] Textures embarquées, PNG, puissance de deux ; alpha seulement découpé ; pas de couleurs de
      sommets.
- [ ] Portrait 256 × 256 transparent pour chaque personnage.
- [ ] Décors : matériaux `prop_*` partagés, formes `-colonly` pour ce qui bloque, feuillage sans
      collision.
- [ ] Check-list visuelle et rendus de contrôle de la section 2 bis.4.
- [ ] Une ligne de crédit par asset.
- [ ] Si tu travailles dans le dépôt avec Godot : `tools/import.sh`, puis `tools/check.sh` vert.

## 10. Licence et provenance

Pour chaque fichier livré, une ligne dans `assets/CREDITS.md` : chemin ; auteur ou outil (par
exemple « Blender, par … », « VRoid Studio et Blender, par … », « Meshy, le JJ/MM/AAAA, retopologie
et textures par … », « généré avec ChatGPT, modèle X, le JJ/MM/AAAA ») ; licence accordée au
projet ; sources (packs CC0 avec leur URL) et conditions des outils (licence de sortie d'un
générateur, conditions de Mixamo ou de VRoid). Les assets générés ou assistés par IA sont marqués
comme tels, comme les planches générées avec Gemini. Un personnage tiré du dessin d'un membre a
aussi sa ligne dans `assets/characters/CREDITS.md`, avec l'accord écrit de l'auteur (PLAN.md,
section 5).

Chtholly, **Seniorious**, Timere et les autres personnages de *SukaSuka* viennent de l'œuvre
d'Akira Kareno, illustrée par ue : le jeu reste un hommage non commercial, clairement crédité, tant
que la décision de PLAN.md (section 13) n'est pas prise. Les scans de référence (planches et
illustrations fournies par l'utilisateur) restent hors du dépôt : on s'en inspire sans les
décalquer, et aucune texture n'en est tirée.

## 11. Intégration dans le jeu (pour la session Claude Code qui suivra)

À donner à une session Claude Code une fois les fichiers commités :

> Projet Yume-WordEnd. Intègre les assets 3D livrés selon `docs/ASSETS_3D.md`.
>
> 1. **Le chemin qui existe** : `assets/models/characters/<id>/<id>.glb` + `<id>.anim.json` →
>    enveloppe `<id>.tscn` (racine `Character3D`, script `model_metadata.gd` : boucles, métadonnées
>    `ips`, `coup`, `onde`, durées vérifiées à 1 ms près ; enfant `Model`) → `SkinData`
>    (`mesh_scene` = l'enveloppe, `sprite_sheet` vide, `portrait`, `height_m`) → `CharacterVisual`
>    (scène instanciée sous `Mesh`, premier `AnimationPlayer`, +Z tourné vers la direction, pose
>    lue à l'instant de l'horloge). Skins jouables : `data/skins/<id>.tres` (aujourd'hui
>    `sukasuka_<id>.tres`). PNJ : `data/npcs/<id>.tres` → `skin` = `data/npcs/visuals/<id>.tres`,
>    où la planche de remplacement cède la place au modèle (`sprite_sheet` et `frames_json` vidés,
>    `mesh_scene`, `portrait`, `height_m`).
> 2. **Remplacements** : un modèle qui en remplace un autre garde son identifiant et ses noms de
>    fichiers ; `tools/import.sh`, puis `git rm` des textures extraites devenues orphelines
>    (`<id>_<image>.png` et leur `.import`). Identifiants renommés (section 4.9) : `git mv` des
>    dossiers et fichiers avec leurs `.import`, chemins mis à jour dans les `.tscn` et `.tres`.
> 3. **Inventaire et tests** : `docs/sprites/reference_inventory.json` et
>    `tests/integration/test_sukasuka_models.gd` (45 identifiants, jeux d'animations exacts : les 7
>    de 4.3 pour `combat`, `repos`, `marche` et `parle` pour `npc`) suivent les identifiants et les
>    jeux d'animations livrés (un modèle jouable qui sert aussi de PNJ ajoute `parle`) ;
>    `tools/sukasuka3d/validate.py` porte encore les anciens budgets (15 000, 12 000 et 8 000
>    triangles, textures de 1024 au plus) : l'aligner sur la section 3.3.
> 4. **Ce qui reste à faire côté jeu** :
>    - **ombrage des personnages** : un matériau cel doux à 2 ou 3 paliers avec liseré de lumière
>      (par exemple `StandardMaterial3D` en diffusion toon avec `rim`, ou un shader), appliqué aux
>      matériaux importés en gardant leurs albédos (script `EditorScenePostImport`, ou remplacement
>      dans `CharacterVisual`) ; lumière des fissures de Seniorious pendant la charge
>      (`seniorious_glow.png`) ; épée `Seniorious` cachée quand un modèle jouable sert de PNJ ;
>    - **PNJ** : jouer `parle` pendant un dialogue et `marche` quand ils se déplaceront ; adapter la
>      collision de `src/npc/npc.tscn` (capsule fixe de 0,35 × 1,5 m) aux grands PNJ ;
>    - **Timere** : `data/enemies/visuals/timere.tres` → `mesh_scene` =
>      `assets/models/enemies/timere/timere.tscn` ; `src/enemies/enemy.gd` lit encore les durées
>      d'attaque et de dégâts dans le JSON de la planche (`SheetLoader.read_sheet`) et retomberait
>      sur 0,5 s : les lire dans les clips du visuel ;
>    - **décors** : remplacer les maillages de `src/world/props/` par les `.glb` ; matériaux
>      `prop_*` remplacés à l'import par des matériaux partagés (un atlas chacun, textures
>      embarquées ignorées pour les décors) ; adapter `PropBatcher`, qui regroupe aujourd'hui les
>      maillages à une surface sous `toon.tres` avec une couleur par instance et perdrait les
>      textures ; collisions sur la couche 1 ;
>    - **terrain** (option B ou C) : adapter `src/world/terrain.gd` (`IslandTerrain`) en gardant la
>      structure figée des zones et les repères de la section 7, avec l'île flottante (falaises,
>      mer de nuages sur le nœud `Water` : HISTOIRE.md, section 9, développement n° 3) ;
>    - **poids** : compression des textures importées (VRAM ou Basis Universal) choisie pour tenir
>      le budget du build ; les LOD sont déjà générés à l'import (`meshes/generate_lods`).
> 5. **Vérifie** : `tools/check.sh` vert, tests de combat M1 avec les images « coup » des vrais
>    modèles, captures de l'entrepôt, du Couchant et des bois, moins de 200 appels de dessin et
>    de 300 000 triangles (surcouche F3), taille du build Web sous le budget.
