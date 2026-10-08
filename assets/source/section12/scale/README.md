# Corrections de format — section 12

Ce lot corrige l'échelle des dessins déjà livrés, au plus proche voisin, conformément à
`docs/ASSETS_HD2D.md` sections 1, 2 et 12. Il ne dessine pas de nouvelles poses.

Exécution reproductible (Pillow) :

```sh
python assets/source/section12/scale/resize_standing.py
```

- `before/` conserve les 14 PNG et JSON avant correction. Leurs SHA-256 sont dans `report.json`.
- `historical/` conserve quatre PNG/JSON de `4475ff1` : les vraies poses de dialogue de Tiat
  (trois vues) et de la marchande d'œufs de dos, supprimées lors du remplacement du dialogue
  par le repos. Elles sont restaurées puis remises à l'échelle ; aucune pose de repos n'est
  utilisée pour fabriquer une animation de dialogue.
- `comparison-01.png` à `comparison-03.png` alignent les vraies images avant/après par leur
  ancre, à taille native. Pour le dialogue restauré, « avant » désigne le dessin historique.
- `report.json` donne la hauteur debout, le facteur appliqué et les SHA-256 des pixels de
  chaque pose. La hauteur debout est mesurée de l'ancre des pieds au premier pixel opaque,
  et non jusqu'au bas d'une épée ou d'une queue.

Les poses non citées par la correction gardent leurs pixels RGBA et leur ancre locale au
pixel près (40 poses vérifiées). Seules leurs coordonnées de rangement peuvent changer.
Le JSON garde les mêmes animations, nombres d'images, cadences, boucles, `coup` et `onde`.
Aucune course de PNJ supprimée par main n'est réintroduite. Les 14 planches restent sous
2048 × 2048, à alpha binaire et au plus 64 couleurs opaques.

Pannibal : repos, marche et dialogue de profil à 120 px. Chtholly : toute la face mise à
l'échelle par le même facteur 144/130, y compris les armes et poses de combat ; les variations
mineures de hauteur dues au mouvement sont conservées (premier repos exactement 144 px).
Tiat : marche et dialogue à 106 px dans les trois vues. Marchande d'œufs : marche et dialogue
de dos à 149 px, marche de profil à 149 px. Marche de Collon (face/dos), Almita (profil/dos),
Ramikeldi (face/dos), guetteur (dos) à la hauteur de leur premier repos.

Vérification du lot : 112 dessins ajustés, 40 dessins non ciblés strictement conservés ; une
seconde exécution produit les 14 mêmes PNG octet par octet. Le contrôle des planches passe
sans erreur ; les alias de dialogue du manifeste sont retirés par l'intégration du lot.
