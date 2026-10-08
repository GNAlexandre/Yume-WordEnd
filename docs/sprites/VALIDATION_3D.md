# Vérification des personnages 3D

> **Ancienne livraison chibi refusée visuellement.** Les résultats techniques ci-dessous concernent cet ancien pack. La nouvelle direction et les concepts de Chtholly sont dans `assets/source/chtholly/` et `docs/sprites/ATELIER_CHTHOLLY.html`. Ce pipeline de modélisation procédurale ne respecte pas les consignes mises à jour.


Livraison du 7 octobre 2026 : **45 modèles**, dont 7 personnages de combat et 38 PNJ/formes distinctes, avec **163 clips**. Les correspondances avec les pages des références sont dans [REFERENCES.md](REFERENCES.md) ; les résultats par GLB sont dans [validation3d.json](validation3d.json).

| Contrôle | Résultat |
| --- | --- |
| GLB 2.0 officiels, validateur Khronos | 45 fichiers ; 0 erreur, 0 avertissement |
| Contrats du projet | 45 réussites : budgets, squelette, influences, UV, textures PNG incorporées, racines, absence de déplacement horizontal, clips, durées et portraits |
| Godot / CharacterVisual | 45 scènes instanciées ; cadences, boucles, coups, onde, progression des images, orientation et masquage du sprite vérifiés |
| Intégration dédiée | 1 282 assertions sur les 45 modèles |
| Registre de sélection | 11 profils : 4 existants et 7 modèles 3D ; 112 assertions |
| Suite complète du projet | 506 tests réussis, 8 146 assertions ; lint et format réussis |
| Fumée des scènes du jeu | 92 scènes, 0 échec |
| Export Web | 17 Mo compressés, budget de 25 Mo respecté |
| Ressources dans le pack exporté | Les 7 personnages de combat instanciés ; événements coup/onde disponibles |
| Galerie Three.js / Chromium WebGL | 45 modèles chargés, changement de personnage et d’animation, pause, squelette et maillage ; 0 erreur navigateur |
| Rendu Godot Compatibility | Chtholly 3D capturée sous Xvfb/Mesa |

Les GLB totalisent 13 721 896 octets. Un modèle utilise 20 os et un matériau ; maximum 7 834 triangles pour les PNJ, 8 566 pour le combat. Portraits transparents de 256 × 256. Les textures de palette font 256 × 256 et sont embarquées.

Les poses armées ont été contrôlées depuis la géométrie exportée : charge vers +Z, balayage frontal de l’attaque. Les animations restent sur place ; le bassin varie verticalement. La pose terminale de Chtholly a été évaluée dans Blender après import du GLB et conserve le corps et l’épée hors du sol.

## Usage

Ouvrir [ATELIER_3D.html](ATELIER_3D.html) dans un navigateur WebGL 2 pour inspecter les volumes et animations. Dans le jeu, choisir une apparence portant « · 3D », par exemple « Chtholly Nota Seniorious · 3D ». Les PNJ sont livrés comme ressources prêtes à instancier ; leur placement dans les lieux attend les volumes du récit.

## Portée artistique

Adaptations chibi low-poly procédurales, avec une tenue principale par personnage. Visages, coiffures, dentelles et ornements sont simplifiés. Les hauteurs hors Chtholly sont des dimensions de travail, pas des données canoniques. Souwong jeune/sage et Eboncandle ancien/crâne sont deux formes de leurs personnages respectifs. Les noms indicatifs et les palettes adaptées des planches au trait sont signalés dans l’inventaire et les spécifications.

Les cartes, les zones du récit et les autres tenues ne sont pas générées dans ce lot. Les scans originaux restent hors du dépôt. Provenance par fichier dans [assets/CREDITS.md](../../assets/CREDITS.md).
