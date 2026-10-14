# Cahier des charges n° 4 : accessoires modulaires de l’île n° 68

Établi le 10 octobre 2026 à la demande du propriétaire du projet. Ce document complète
[le cahier n° 1](ASSETS_HD2D.md), [le cahier n° 2](ASSETS_HD2D_MONDE.md) et
[le cahier n° 3](ASSETS_HD2D_SUKASUKA.md). Il commande **24 PNG nouveaux**, sans remplacement.
Les anciens dessins anime, les sources et les références officielles restent conservés.

## 0. Périmètre et état des commandes

Les grands décors, les personnages et leurs mouvements restent commandés par les trois cahiers
précédents. Ce cahier ajoute de petits objets **séparés** : on peut les placer, les retirer ou
les déplacer sur les meubles déjà livrés. Un ingrédient présent dans une table composée ne
constitue pas déjà un PNG modulaire. Aucun personnage supplémentaire, nouvelle carte ou scène
d’histoire n’est inventé ici. Pas de nouvelle pose de combat : celles des combattants restent
à produire ou corriger selon leur commande existante.

L’inventaire initial est fondé sur `main` au commit `c58d9ac` : lots I et J priorité 1 fusionnés
(PR 21 et 22). Les 24 chemins ci-dessous sont absents du dépôt et des listes de commande des
cahiers 1–3. Les groupes existants (table d’ingrédients, plateau de desserts, étagère de soins…)
sont conservés ; chaque ligne précise sa différence et son usage.

| Lot | Priorité | Sujet | PNG | État |
| --- | --- | --- | --- | --- |
| O1 | 1 | Cuisine : ingrédients et préparation séparés | 6 | Livré : six PNG et leurs imports, contrôlés dans Godot ; placement à faire |
| O2 | 2 | Entretien, réparations et reprises | 6 | À produire |
| P | 2 | Lecture, archives et infirmerie | 6 | À produire |
| Q | 3 | Accessoires des sorties | 6 | À produire |

**Ordre recommandé.** Livrer O1 maintenant, puis reprendre N priorité 1 du cahier 3 (temps et
lumière), avant O2, P et Q au fil des pièces qui les utilisent. Les lots I/J priorité 2 et K–N
non livrés restent dans le planning du cahier 3 : ce document ne les déclare pas terminés.
Un lot = une livraison autonome et, lors de sa publication, une PR dédiée.

**Canon et original.** La présence de lait, d’œufs, du dessert, des courses et des réparations
vient des synthèses `docs/lore/canon/v1_vex.md` (Cuisine) et `v2_v3.md` (réparations, marché).
Le dessin précis des contenants et outils est original. Une ligne marquée **Original** est un
accessoire compatible avec l’univers, pas une affirmation sur une illustration ou un objet
nommé des romans. Aucun extrait de roman n’est recopié.

## 1. Bloc de style à copier avec chaque commande

```text
Images pour WordEnd en HD-2D : décor en relief construit à partir de panneaux et de tuiles,
caméra fixe inclinée regardant le nord, circulation dans la profondeur comme Octopath Traveler.
Pixel art net cohérent avec les assets livrés, sans reprendre l’architecture ou les costumes
d’Octopath. Univers : île flottante n° 68 de SukaSuka, entrepôt rural des fées, Europe rustique,
fin d’automne. Bois patiné, fer terne, cuivre, grès, osier, toile et tissus reprisés.
Échelle : 96 pixels par mètre. Un pixel final = un pixel d’art ; contours en marches nettes,
dégradés en paliers et léger tramage, pas de flou, de grain photographique ou d’anticrénelage
vers le fond. Contours de couleur sombre voisine, ni noir pur ni blanc pur.
Lumière douce venant de la gauche et du haut, arêtes chaudes, ombres propres brun-violet froid.
Pas d’ombre portée, de sol, de table, de fond ni de décor supplémentaire dans le PNG.
Vue de face très légèrement plongeante (10–15 degrés), pas de vue isométrique ni de dessus.
Un seul objet ou groupe compact commandé par fichier, centré et posé au milieu du bord bas.
Matières usées mais maison entretenue ; palette chaude un peu désaturée, aucun élément moderne
ni mobilier asiatique. Aucun texte, chiffre, logo, signature ni symbole lisible.
PNG RGBA 8 bits, alpha strictement 0 ou 255, découpe propre sans fragments flottants.
Taille exacte demandée. Si nécessaire, générer plus grand et réduire au plus proche voisin,
sans réduction de palette, recoloration ou compression avec perte. Conserver l’original.
```

## 2. Contrat de livraison et références

- **Genre** : panneau fixe `panel`, déjà pris en charge par `DecorPanel` ; aucune bande animée.
- **Format** : PNG RGBA 8 bits. Les dimensions du tableau comprennent le dessus légèrement
  visible des objets. La largeur et la hauteur divisées par 96 donnent le rectangle en mètres.
- **Ancre** : centre du bord bas, l’objet touche la dernière ligne. Pour O1, O2 et P, l’ancre
  se pose **sur le plateau du meuble**, pas automatiquement sur le sol. Les sacs, bottes et
  baluchons de Q se posent au sol ; le piquet est planté au sol.
- **Placement** : pas de nouveau JSON de sprite, de `.tres`, de scène ni de mécanique. Les PNG
  s’importent et sont utilisables dans le format existant ; leur placement dans les cartes reste
  un travail du moteur. Ne pas déclarer une scène jouable livrée sur la seule base de ces PNG.
- **Références de rendu** : joindre `interior/props/kitchen_table_ingredients.png`,
  `dessert_flans.png`, `kitchen_counter.png` pour O1 ; `props/workbench.png` et
  `interior/props/wardrobe_plain.png` pour O2 ; `reading_table.png` et `medicine_cabinet.png`
  pour P ; `props/luggage.png` et `props/warehouse_roof_deck.png` pour Q.
  Ces chemins abrégés sont sous `assets/hd2d/`.
- **Références officielles** : ZIP de settei fournis au début du projet, conservés hors du
  dépôt. O1 : page de fichier **105** (page imprimée 104, cuisine). Pour les pièces : fichiers
  103–107. Ces planches guident les matériaux et l’ambiance ; leurs détails divergents du cahier
  pixel art ne remplacent pas les contrats de jeu. Pas de réutilisation de scan dans un asset.
- **Personnages** : si un futur lot en ajoute, identifier sa référence avant production, garder
  trois vues et les mêmes hauteurs, nombres de phases, cadences et ancres du cahier 3. Ithea garde
  l’apparence des planches officielles anime choisie par le propriétaire. Combats uniquement
  pour les combattants. Ce cahier ne change aucun sprite existant.

## 3. Listes des images à créer

Pour chaque ligne, coller le bloc de style, puis : « Image `<chemin>`, <largeur> × <hauteur> px,
panneau fixe, ancre milieu du bord bas : <consigne>. » Joindre les références du lot.

### Lot O1 — Cuisine : préparation du dessert

| Priorité | Chemin exact | Taille (px) | Consigne à copier | Source et usage |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/flour_sack_open.png` | 48 × 58 | Un seul sac de farine ouvert en toile bise rapiécée ; farine crème visible dans le col replié, sans pelle ni farine éparpillée. | V3, marché du matin. Séparer l’ingrédient de kitchen_table_ingredients, qui reste inchangé. |
| 1 | `assets/hd2d/interior/props/egg_basket_low.png` | 58 × 34 | Un panier bas ovale d’osier brun contenant six œufs ivoire et beige distincts ; aucune grande anse verticale. | V1, cuisine ; V3, marché du matin. Préparation du dessert, achat déposé sur un comptoir. |
| 1 | `assets/hd2d/interior/props/milk_jug_stoneware.png` | 29 × 43 | Un broc de lait en grès crème patiné à décor bleu-gris discret, anse à droite et petit bec à gauche ; un seul récipient, bouche lisible. | V1, cuisine ; V3, marché du matin. Poser le lait à côté du bol sans redessiner le meuble. |
| 1 | `assets/hd2d/interior/props/butter_dish_open.png` | 34 × 19 | Une motte de beurre doré irrégulière sur un petit plat de grès crème, sans couteau ni couvercle. | V1, gâteau au beurre ; V3, courses. Préparation du gâteau ; accessoire distinct du gâteau terminé. |
| 1 | `assets/hd2d/interior/props/mixing_bowl_whisk.png` | 48 × 29 | Une jatte de grès clair contenant une pâte dorée ; un unique fouet de fer à manche de bois repose en biais dedans. Le manche reste dans le cadrage de 29 px. | V1, cuisine ; geste de willem_cook au cahier 3. Bol posé pendant le travail ; ne modifie pas l’accessoire dessiné dans les mains de Willem. |
| 1 | `assets/hd2d/interior/props/flan_mould_empty.png` | 38 × 24 | Un petit moule à flan vide en cuivre patiné, cône tronqué bas à cannelures, ouverture sombre visible ; sans flan, poignée ni vapeur. | Original, associé au dessert de V1. Montrer la préparation, à côté de dessert_flans déjà livré. |

### Lot O2 — Entretien de la maison

| Priorité | Chemin exact | Taille (px) | Consigne à copier | Source et usage |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/props/repair_nail_box.png` | 34 × 24 | Petite boîte de bois ouverte pleine de clous de fer inégaux, deux clous sur son rebord ; sans marteau ni planches. | V2–V3, réparations ; composition originale. Détail modulaire distinct du groupe repair_planks du cahier 3. |
| 2 | `assets/hd2d/interior/props/hand_plane_worn.png` | 38 × 19 | Rabot à main de bois usé, semelle sombre, lame de fer et poignée simple ; ni marque ni câble. | Original. Établi existant, travail de réparation sans nouvel équipement moderne. |
| 2 | `assets/hd2d/interior/props/hand_saw_short.png` | 58 × 24 | Scie courte à manche de bois brun à gauche, lame d’acier terne dentée vers la droite ; posée, sans main ni copeaux. | Original. Accessoire posé sur workbench, sans recréer le meuble. |
| 2 | `assets/hd2d/interior/props/mending_basket.png` | 48 × 34 | Petit panier d’osier contenant trois chutes de tissu reprises, une paire de ciseaux fermés et deux bobines ; pas de linge volumineux. | Original. Entretien des vêtements ; distinct du panier à linge existant. |
| 2 | `assets/hd2d/interior/props/thread_spools_pair.png` | 24 × 19 | Deux bobines de bois, l’une de fil rouge passé, l’autre de fil écru, reliées en un groupe compact ; aucun fil flottant hors du groupe. | Original. Accessoire de couture posé, réutilisable dans les chambres. |
| 2 | `assets/hd2d/interior/props/patched_cloth_folded.png` | 38 × 14 | Une seule pièce de toile verte pliée, reprisée d’un carré brun à points visibles, bord irrégulier mais propre. | Original. Montrer les reprises sans produire une nouvelle tenue de personnage. |

### Lot P — Lecture, archives et soins

| Priorité | Chemin exact | Taille (px) | Consigne à copier | Source et usage |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/props/book_open_stand.png` | 48 × 48 | Un petit lutrin de table en bois patiné portant un livre ouvert relié de cuir brun ; lignes grises illisibles, aucune lettre. | Original ; salle de lecture V1. Lecture sur table, distinct de reading_table et des piles de livres. |
| 2 | `assets/hd2d/interior/props/inkwell_quill.png` | 29 × 34 | Un encrier de grès sombre à col étroit et une seule plume brun-crème fichée dedans ; aucune tache ni feuille. | Original. Bureau des archives ; ne crée pas une lettre canonique. |
| 2 | `assets/hd2d/interior/props/letter_sealed_bundle.png` | 34 × 14 | Petit paquet de feuilles pliées lié de ficelle, cachet de cire rouge sans emblème lisible ; aucun texte. | Original. Courrier neutre pour les bureaux, sans destinataire inventé. |
| 2 | `assets/hd2d/interior/props/bandage_rolls.png` | 34 × 19 | Deux rouleaux de bandage écru dans un groupe compact, un bord de tissu légèrement déroulé sur le plateau ; pas de sang. | Original ; infirmerie du cahier 3. Soins du quotidien, distinct de medicine_cabinet. |
| 2 | `assets/hd2d/interior/props/medicine_bottles_tray.png` | 48 × 34 | Petit plateau de bois avec deux flacons ambrés bouchés de liège et une cuillère de bois ; étiquettes par traits illisibles. | Original ; infirmerie du cahier 3. Soins : ne représente ni médicament nommé ni technologie moderne. |
| 2 | `assets/hd2d/interior/props/compress_bowl.png` | 34 × 24 | Cuvette de faïence bleu passé contenant une compresse de lin humide repliée ; rien hors du bord, pas de vapeur. | Original ; infirmerie du cahier 3. Accessoire posé à côté d’un lit existant, sans nouveau meuble. |

### Lot Q — Accessoires des sorties

| Priorité | Chemin exact | Taille (px) | Consigne à copier | Source et usage |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/interior/props/field_satchel_set_down.png` | 48 × 48 | Sacoche de toile brune posée, boucle de laiton ternie, rabat fermé, bandoulière repliée contre le corps ; sans contenu visible. | Original. Départ ou retour d’une sortie, sans inventer une possession d’un personnage. |
| 3 | `assets/hd2d/interior/props/leather_canteen.png` | 29 × 38 | Gourde de cuir brun à bouchon de bois, couture visible, sangle courte pliée contre le flanc ; aucun métal moderne. | Original. Équipement neutre posé, sans animation ni nouvelle mécanique. |
| 3 | `assets/hd2d/interior/props/oilskin_cloak_folded.png` | 58 × 24 | Une pèlerine de toile cirée gris-mousse pliée en paquet irrégulier, capuche repliée visible ; aucun cintre. | Original ; pluie du cahier 3. Vestiaire lors des sorties sous la pluie ; ne remplace pas les planches _rain. |
| 3 | `assets/hd2d/interior/props/walking_boots_drying.png` | 48 × 43 | Deux bottes de cuir graissé usées, côte à côte, l’une légèrement en arrière, semelles boueuses ; sans flaque ni support. | Original. Entrée de l’entrepôt ; distinct du meuble shoe_rack. |
| 3 | `assets/hd2d/interior/props/provisions_cloth_bundle.png` | 48 × 29 | Petit baluchon de toile beige entrouvert sur un pain rustique et une pomme ; nœud court, aucune assiette. | Original. Provisions posées avant le trajet, distinct des grands luggage existants. |
| 3 | `assets/hd2d/props/trail_ribbon_stake.png` | 19 × 77 | Un piquet de bois fendu planté droit, ruban de tissu ocre noué près du sommet et retombant contre le piquet ; aucun texte, panneau ni symbole. | Original. Repère discret sur les sentiers déjà prévus, sans nouvelle destination canonique. |

## 4. Vérifications et acceptation

1. Contrôler l’absence de doublon de chemin et de fonction dans les cahiers précédents et le
   dépôt ; conserver les fichiers existants. Partir du dernier `main` sans écraser les travaux
   présents dans l’espace de travail.
2. Inspecter chaque PNG sur fond clair et sombre à taille native et agrandi au plus proche
   voisin : objet identifiable, angle cohérent, matière et proportions lisibles, aucun fantôme,
   détourage sale, texte, membre ou fragment ajouté. Pour O1 : six œufs, une anse à droite,
   un fouet seulement, moule vide. Corriger le dessin par génération d’image si nécessaire.
3. Vérifier dimensions, RGBA, alpha binaire, point de contact en bas, absence de composant
   détaché et fichier non vide. Les opérations techniques autorisées sont découpe, placement,
   réduction nearest-neighbor et nettoyage du masque ; pas de dessin substitut par script.
4. Si les PNG ne sont pas inscrits dans `tools/hd2d_manifest.json`, les vérifier explicitement
   selon ce tableau. Ne pas prétendre que le vérificateur de manifeste les a couverts. Le lot
   moteur pourra les inscrire avec leur placement ; la production d’images ne change pas ce code.
5. Lancer `tools/import.sh`, livrer les `.png.import` générés, confirmer la compression sans
   perte et comparer les pixels visibles du PNG et de la texture importée. Puis exécuter
   `tools/check.sh` et annoncer les échecs éventuels, y compris le budget Web en vigueur.
6. Conserver sources, références et rapports de découpe hors du dépôt ; joindre un aperçu
   véritable des PNG livrés. L’aperçu est une planche de contrôle, pas une capture d’une carte.
7. Ajouter la provenance en bas de `assets/CREDITS.md` : outil, date, cahier n° 4, lot et fichiers.
   Livrer uniquement les PNG de ce lot, leurs imports, les crédits et ce cahier des charges.
   Aucun asset préexistant, code, format moteur, budget, manifeste ou scène ne doit être modifié.
8. Dans chaque livraison, distinguer produit, contrôlé techniquement, placé dans le jeu et
   validé visuellement en jeu. Les états du planning ne changent qu’après la livraison effective.
