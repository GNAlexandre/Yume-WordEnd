# Promenade sur l'île n° 68

Le bouton **Découvrir l’île n° 68** du menu ouvre `island68.tscn`. Cette promenade permet
d'essayer les personnages directionnels et les décors du cahier `docs/ASSETS_HD2D.md`, avec
les cinq lieux de `docs/lore/MONDE.md`. Elle est indépendante des quêtes et des sauvegardes.

Les flèches, WASD ou ZQSD déplacent Chtholly au sol ; Maj lance la course, X l'épée et C la
charge. Les boutons du haut ou les touches 1 à 5 changent de lieu ; Échap retourne au menu.
Près d'un habitant, E déclenche son animation de conversation. Aucun dialogue de l'histoire
n'est inventé pour cette présentation. Sur une petite fenêtre, les cinq boutons deviennent
une liste déroulante.

Le sol utilise les tuiles à 96 pixels par mètre. Les façades et objets sont des panneaux
transparents ancrés au sol. Les volumes des bâtiments portent les matières des murs et des
toits ; les deux pans du toit ajoutent le relief visible sous la caméra orthographique.
Les murs, troncs et principaux objets ont des collisions. Les arbres au premier plan peuvent
masquer un personnage qui passe derrière. Aucune nouvelle géométrie de personnage n'est créée.

L'agencement est une composition de présentation compacte : les centres des cinq zones suivent
MONDE.md, tandis que leurs objets sont rapprochés pour vérifier les images dans un seul cadre.
Il ne remplace pas les fichiers d'emplacement de la carte narrative. Une image encore absente
est omise, avec un avertissement dans le journal de développement.

Vérification visuelle :

```sh
tools/screenshot.sh res://scenes/hd2d/island68.tscn build/shots/island68-courtyard.png
```

Le personnage utilise la ressource directionnelle générée de Chtholly lorsqu'elle existe,
puis le skin 2D existant comme repli. La fenêtre permet aussi le chargement autonome :

```sh
tools/godot res://scenes/hd2d/island68.tscn
```

Contrôles reproductibles de la priorité 1 :

```sh
tools/godot --headless --script tools/hd2d_priority1_preview.gd
```

Ce contrôle vérifie les trois orientations, les sept animations, leur horloge, les fenêtres
de coup, le départ de l'onde, le profil gauche et la densité de 96 px/m. Sous un affichage
graphique (Xvfb en cloud), l'option `-- --capture-dir=build/shots/priority1` produit la cour,
la colline et deux vrais instants de chaque animation principale de Chtholly.
