# Crédits des personnages

Une ligne par planche (personnage, ennemi, PNJ), ajoutée en bas (fusion par union entre lots).
Pour un dessin de membre : nom, œuvre, licence accordée au projet (ex. CC BY-NC 4.0) et trace de
l'accord écrit.

| Planche | Origine | Auteur / accord | Licence | Ajoutée par |
| --- | --- | --- | --- | --- |
| `assets/characters/chtholly/chtholly.png` + `.json` | Planche générée par Gemini, découpée par `tools/wordend/decouper-planche.py` (dépôt Yume-WordPress, voir `docs/wordend.md`), reprise telle quelle de l'easter egg WordEnd | — (image générée) | Personnage de *SukaSuka* (Akira Kareno) : hommage non commercial, décision avant M4 (PLAN.md section 13) | L0 |
| `assets/enemies/timere/timere.png` + `.json` | Deux planches en pixel art générées par Gemini, assemblées et découpées par `tools/wordend/decouper-planche.py` (Yume-WordPress, `docs/wordend.md`), reprises de l'easter egg | — (images générées) | Créature de *SukaSuka* : même réserve que ci-dessus | L0 |
| `assets/characters/chtholly/chtholly_portrait.png` | Tête de la 1re image de repos de `chtholly.png`, agrandie ×2 sans lissage par `tools/gen_placeholders.py portrait chtholly` (L3) | — (image générée, comme la planche) | Même réserve que la planche de Chtholly | L3 |
| `assets/characters/<id>/` des 17 PNJ de l'acte 1 (`nygglatho`, `willem`, `ithea`, `nephren`, `tiat`, `pannibal`, `collon`, `lakhesh`, `almita`, `limeskin`, `cat_waiter`, `ramikeldi`, `snack_vendor`, `baker`, `ferryman`, `egg_vendor`, `garde_lookout` : planche, `.json`, `<id>_portrait.png`) | Silhouettes et portraits de remplacement générés par `tools/gen_placeholders.py npcs` (couleurs et tailles de HISTOIRE.md 5.1 et 5.2), en attendant les vraies planches ; les trois silhouettes du jalon M2 ont été retirées | Projet Yume-WordEnd | Licence du code du projet (MIT proposée, PLAN.md section 13) | Acte 1 |
