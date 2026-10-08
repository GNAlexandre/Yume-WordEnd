# Livraison HD-2D — priorité 3

69 PNG, 30 JSON d'animation, 9.5 Mo de textures.
Personnages : almita, baker, cat_waiter, collon, egg_vendor, ferryman, garde_lookout, lakhesh, ramikeldi, snack_vendor.
Types : {'sprite': 30, 'portrait': 10, 'ground': 3, 'cliff': 1, 'facade': 2, 'material': 1, 'prop': 9, 'horizon': 4, 'item': 9}.

Ouvrir `PRIORITE_3.html` après extraction du ZIP. Copier `assets/` et
`data/visuals2d/characters/` dans le projet en conservant les chemins. Les atlas
de face et dos complètent le profil droit ; le côté gauche est un miroir.
Les PNJ ont repos, marche, course et dialogue. Les combattants ont aussi
attaque, charge, dégâts et chute ; les PNJ ordinaires ne reçoivent pas de combat.
Les portraits mesurent 256 × 256 px. Les JSON décrivent les poses réellement
dessinées, leurs rectangles, cadence, boucles et marqueurs de combat.

Le contrôle technique est strict sur ce lot : aucun fichier requis manquant,
dimensions et densité prévues, alpha binaire, rectangles d'atlas et raccords
des bords. Chaque PNG pèse moins de 1 Mo. Les ancres calculées et cycles restent
signalés pour revue visuelle ; ce contrôle ne certifie pas la qualité artistique.
Les textures répétées doivent aussi être inspectées en contexte.

Les priorités viennent des tableaux de `ASSETS_HD2D.md`. Les orientations et
portraits héritent de celle du personnage. Les personnages et objets demandés
en complément sont des adaptations de travail, sans inventer une liste canonique
issue de HISTOIRE.md. Les effets facultatifs restent procéduraux dans le jeu.
Les sources natives et les premiers dessins anime sont conservés dans le dépôt.

```sh
python tools/hd2d_assets.py --manifest tools/hd2d_priority3_manifest.json check
python tools/sukasuka2d/make_priority_package.py --priority 3
```

Le budget de 25 Mo est vérifié pour chaque lot de textures. La bibliothèque
complète couvre plusieurs lots et dépasse ce poids ; l'export Web ne contient
que les personnages utilisés dans ses scènes et possède son propre contrôle
de taille. Une archive de lot n'est pas un export du jeu complet.
