# Corrections des images — section 12

Livraison du 8 octobre 2026, sur `main` à `1ff21b9`.

[Ouvrir les comparaisons animées et télécharger les PNG/JSON](CORRECTIONS_SECTION12.html).
La page contient ses images : elle fonctionne seule. « Avant » montre les animations
réellement jouées par la version de `main`, y compris le repos qui remplaçait certains dialogues.

- Priorité 1 : dialogues de Nygglatho et Limeskin à leur hauteur debout ; couette de Lakhesh
  du même côté anatomique dans les trois vues et son portrait ; profil de Pannibal à 120 px.
- Priorité 2 : Chtholly de face à 144 px ; six nouveaux dessins de dialogue de Willem ; quatre
  dialogues de Nephren avec livre rouge ; dialogues et marches concernés remis à l'échelle.
- Priorité 3 : queue de Limeskin cohérente au dos ; marche des sept PNJ cités à la hauteur
  de leur repos ; fouet de Timere vers la droite ; portail grand ouvert ; pierre du cercle
  de veille en 58 × 20 px.
- Ithea : apparition corrigée selon les planches officielles de l'anime, à la demande de
  l'utilisateur ; trois vues, 25 poses par vue et portrait. La lame pointe vers l'arrière
  pendant repos et marche de profil. Le portrait blond précédent reste conservé.

Les simples ajustements de taille utilisent le plus proche voisin autorisé au §2. Les
nouvelles poses et corrections de dessin utilisent `image_gen`. Les originaux, tentatives,
prompts et rapports sont conservés dans `assets/source/section12/`, exclu des imports et de
l'export grâce à `.gdignore`. Les poses de PNJ retirées par `main` ne sont pas réintroduites.

Contrôles reproductibles :

```sh
python3 tools/hd2d_correction_review.py
python3 tools/hd2d_sheets.py check
python3 tools/hd2d_assets.py check
tools/check.sh
tools/hd2d_shots.sh village beach dialogue vigil
```

Le contrôle ciblé vérifie 35 vues, les hauteurs mesurées depuis l'ancre des pieds et 206 poses
non concernées conservées au pixel et à l'ancre près. Les douze poses d'attaque corrigées de
Nephren restent identiques. Le portail laisse au minimum 292 px libres sous la lanterne
(3,04 m). La fluidité des cycles et la lisibilité des armes restent à juger en jeu.

Rendus Godot après intégration : [entrepôt](section12/village-after.png),
[port](section12/beach-after.png), [conversation](section12/dialogue-after.png),
[veille](section12/vigil-after.png). Les captures avant correction sont dans le même dossier.
Les quatre vues restent sous 200 draw calls (172, 63, 73 et 51).

Validation de la page seule : 109 images décodées, 35 aperçus animés affichés, 37 PNG et 35
JSON effectivement téléchargés et comparés octet par octet, zéro erreur navigateur, zéro
requête réseau et aucun débordement sur écran de 390 px. Import/lint et 154 scènes de fumée
validés ; export Web à 24,2 Mo compressés, sous le budget de 25 Mo.

Le contrôle des planches laisse une remarque préexistante sur `snack_vendor_front`, marche 5,
vue hors de la liste reçue. La vérification globale signale aussi un défaut déjà présent sur
`main` : `test_timeres_in_a_column_spread_across_the_screen` attend un écart latéral supérieur
à 0,6 m et mesure 0,24894 m. Il échoue aussi dans une copie propre de `1ff21b9`, sans ces
corrections d'images. Aucun changement du comportement des ennemis n'est inclus ici.
