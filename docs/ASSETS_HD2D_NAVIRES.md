# Assets de bord : silhouettes et intérieurs des navires volants

Ce complément des cahiers n° 2 et 3 répond à la demande de reprendre les dirigeables d’après les planches officielles des ZIP et de fournir leurs intérieurs. Le pixel art HD-2D, la densité de 96 px/m, les PNG RGBA et les ancrages des cahiers restent applicables.

## Références et périmètre

- Sources visuelles : planches officielles p093–095 (navires), p135 (cabine) et p137 (infirmerie et mess), conservées hors dépôt. Aucune page du settei n’est redistribuée dans les assets.
- Les deux silhouettes existantes du passeur et du Barocupot sont adaptées aux nacelles, stabilisateurs et volumes des planches. Ce sont des interprétations pour le cadrage jouable, pas des reproductions de chaque navire nommé sur les références.
- La silhouette du passeur garde sa coque civile en bois. Le Barocupot garde sa bande rouge et ses deux hélices latérales animées. La palette devient plus sobre et les appareils plus utilitaires.
- Les descriptions marquées « original » complètent les pièces que les sources ne détaillent pas ; elles ne sont pas présentées comme du canon.
- Cette livraison comprend 2 silhouettes refaites, 18 PNG du cahier n° 3 §6.4 et 30 compléments de bord. Les matières de plafond sont fournies pour réutilisation ; le moteur ne les affiche pas encore.
- Les nouvelles vues de navires en volume (`ships/*`), leurs rotors et trappes E7 restent différés selon le §9.4. La livraison ne crée pas de cartes d’intérieur ni de navigation sur le pont.

## Silhouettes reprises

| Fichier | Taille | Intégration |
| --- | --- | --- |
| `assets/hd2d/props/airship_barocupot.png` | 2304 × 1056 | deux moyeux nus ; hélices existantes repositionnées sur les nouveaux centres |
| `assets/hd2d/props/airship_ferry.png` | 1344 × 672 | un moyeu nu ; hélice et fumée existantes repositionnées |

## Lot L : conseil, coursive et pont

| Fichier | Taille | Genre | Sujet |
| --- | --- | --- | --- |
| `assets/hd2d/interior/floor_ship_planks.png` | 384 × 384 | tile | plancher de bord : lames étroites de bois sombre verni, clous de cuivre, joints serrés, une plaque de tôle vissée par endroits |
| `assets/hd2d/interior/wall_ship_plate.png` | 384 × 288 | tile_h | cloison de tôle rivetée peinte gris-bleu, plinthe de tuyaux de cuivre, rangées de rivets, une couture soudée, traces d'usure |
| `assets/hd2d/interior/wallcut_ship.png` | 384 × 24 | tile_h | coupe d'une cloison double de tôle vue de dessus, isolant brun entre les deux |
| `assets/hd2d/interior/props/war_table.png` | 192 × 106 | panel | table du conseil de guerre : une carte de l'archipel déroulée (îles dessinées, sans chiffres ni noms), compas, règles, pions de laiton |
| `assets/hd2d/interior/props/war_chair.png` | 58 × 106 | panel | chaise lourde de bord à pied vissé au plancher, cuir brun |
| `assets/hd2d/interior/props/tea_set_tiny.png` | 48 × 24 | panel | théière de fonte et tasses minuscules, une serviette pliée à côté (V1) |
| `assets/hd2d/interior/window_porthole.png` | 58 × 58 | panel | hublot rond riveté de laiton, verre épais, les nuages derrière |
| `assets/hd2d/interior/door_bulkhead.png` | 106 × 211 | panel | porte étanche de tôle à coins arrondis, volant de fermeture, seuil haut |
| `assets/hd2d/interior/props/ship_ladder.png` | 96 × 288 | panel | échelle de coupée de fer raide vers une écoutille ouverte au plafond, mains courantes |
| `assets/hd2d/interior/wallitem_ship_pipes.png` | 192 × 96 | panel | tuyaux de cuivre, vannes à volant, deux manomètres sans chiffres, un porte-voix |
| `assets/hd2d/interior/wallitem_garde_emblem.png` | 77 × 77 | panel | aile stylisée de la Garde ailée peinte en rouge (#AE4A3E) sur une plaque de tôle ; aucun texte |
| `assets/hd2d/interior/props/map_cabinet.png` | 115 × 106 | panel | meuble à cartes à larges tiroirs plats, rouleaux de cartes dessus |
| `assets/hd2d/interior/wallitem_speaking_tube.png` | 29 × 58 | panel | porte-voix de cuivre en pavillon au bout d'un tuyau, bouchon à chaînette |
| `assets/hd2d/props/deck_railing.png` | 192 × 106 | panel | bastingage de fer riveté avec main courante et filières, peinture gris-bleu écaillée |
| `assets/hd2d/props/deck_hatch.png` | 115 × 58 | panel | écoutille fermée à surbau de tôle et volant |
| `assets/hd2d/props/deck_vent.png` | 58 × 134 | panel | manche à air de bord en col de cygne, peinte en rouge à l'intérieur |
| `assets/hd2d/props/deck_bridge.png` | 384 × 288 | panel | la passerelle de commandement vue depuis le pont : cabine de tôle et de verre, vitres en bandeau, porte étanche, barre visible à travers les vitres |
| `assets/hd2d/props/deck_crates_lashed.png` | 154 × 115 | panel | caisses de la Garde arrimées sous un filet de cordage, sangles, aile peinte sans texte |

## Lots S1 à S5 : compléments pour toutes les pièces

Les meubles et éléments de mur sont à fond transparent découpé ; les matières sont opaques et répétables. Les ancrages sont au milieu du bord bas (éléments muraux à poser à la hauteur voulue). Les cheminées, tuyaux et lampes n’intègrent pas de fumée ni de halo : ces effets restent séparés.

| Lot | Fichier | Taille | Genre | Consigne et provenance |
| --- | --- | --- | --- | --- |
| S1 | `assets/hd2d/interior/props/ship_helm.png` | 77 × 96 | panel | Barre de navigation : roue de bois sombre cerclée de fer, sur colonne mécanique vissée, pédale de blocage. |
| S1 | `assets/hd2d/interior/props/ship_engine_telegraph.png` | 48 × 115 | panel | Transmetteur d’ordres à levier : colonne de laiton terni, cadran à traits sans lettres ni nombres. |
| S1 | `assets/hd2d/interior/props/ship_navigation_desk.png` | 154 × 106 | panel | Bureau de navigation riveté, carte des îles sans texte, règle, compas et tiroirs étroits. |
| S1 | `assets/hd2d/interior/props/ship_compass.png` | 34 × 38 | panel | Compas de navigation de laiton en boîtier vitré, aiguille et traits sans nombres. |
| S1 | `assets/hd2d/interior/props/ship_pilot_chair.png` | 58 × 106 | panel | Siège de pilote en cuir brun, dossier étroit, pied mécanique fixé au pont. |
| S1 | `assets/hd2d/interior/ship_cockpit_window.png` | 230 × 96 | panel | Bandeau de trois vitres de passerelle, montants de métal olive, verre bleu pâle avec nuages, aucun décor autour. |
| S2 | `assets/hd2d/interior/props/ship_bunk.png` | 192 × 173 | panel | Deux couchettes superposées fixées à une armature de fer, matelas vert olive, petite échelle, rideaux roulés ; planche p135. |
| S2 | `assets/hd2d/interior/props/ship_locker.png` | 77 × 182 | panel | Vestiaire étroit en tôle gris-bleu, aérations, poignée, deux tiroirs bas, sans inscription ; p137. |
| S2 | `assets/hd2d/interior/props/ship_folding_table.png` | 115 × 86 | panel | Table de cabine rabattable en métal peint, deux équerres de fixation, plateau bois gris-vert ; p135. |
| S2 | `assets/hd2d/interior/props/ship_wall_bench.png` | 154 × 58 | panel | Banc de coursive fixé sur deux consoles métalliques, assise vert olive ; p135. |
| S2 | `assets/hd2d/interior/props/ship_hammock.png` | 192 × 77 | panel | Hamac de toile bise tendu entre deux crochets de fer, couchage vide sans personne (original). |
| S2 | `assets/hd2d/interior/props/ship_washstand.png` | 77 × 86 | panel | Lavabo de cabine : vasque émaillée crème dans un meuble métallique bas, broc en étain, aucun robinet moderne (original). |
| S3 | `assets/hd2d/interior/props/ship_boiler.png` | 154 × 211 | panel | Chaudière enchantée cylindrique à grille rougeoyante, tuyaux épais et vannes, isolant réfractaire, sans fumée dessinée (original). |
| S3 | `assets/hd2d/interior/props/ship_motor.png` | 154 × 134 | panel | Moteur mécanique d’atelier : carter olive nervuré, piston, transmission et pied boulonné, sans hélice (original). |
| S3 | `assets/hd2d/interior/props/ship_fuel_bin.png` | 96 × 106 | panel | Bac de charbon en fer sombre rempli à moitié, pelle de fer contre un côté (original). |
| S3 | `assets/hd2d/interior/props/ship_tool_rack.png` | 154 × 96 | panel | Panneau d’outils de bord : clés, marteau et pinces fixés à des crochets sur plaque de tôle (original). |
| S3 | `assets/hd2d/interior/props/ship_workbench.png` | 192 × 106 | panel | Établi de mécanicien à ossature de fer, plateau bois usé, étau, pièces dans un tiroir ouvert (original). |
| S3 | `assets/hd2d/interior/props/ship_pressure_tank.png` | 77 × 134 | panel | Réservoir cylindrique vertical, cerclages, manomètre à traits sans nombres, vanne de cuivre (original). |
| S4 | `assets/hd2d/interior/props/ship_medical_cot.png` | 192 × 86 | panel | Lit d’infirmerie de bord bas en métal gris-bleu, matelas crème et oreiller, sans patient ; p137. |
| S4 | `assets/hd2d/interior/props/ship_medical_cabinet.png` | 77 × 134 | panel | Meuble médical en tôle à deux portes et tiroirs, bandages et deux flacons sans étiquettes ; p137. |
| S4 | `assets/hd2d/interior/props/ship_mess_counter.png` | 192 × 115 | panel | Buffet du mess de tôle gris-bleu : étagère à gobelets d’étain et petites portes, sobre ; p137. |
| S4 | `assets/hd2d/interior/props/ship_mess_bench.png` | 154 × 58 | panel | Banc du mess à cadre métallique, assise vert olive, pieds vissés ; p137. |
| S4 | `assets/hd2d/interior/props/ship_water_can.png` | 48 × 58 | panel | Bidon d’eau de bord en étain terni à bec court, couvercle et poignée, sans texte (original). |
| S4 | `assets/hd2d/interior/props/ship_crystal_lamp.png` | 38 × 58 | panel | Lampe de cristal crème dans une cage de fer, attache murale, sans halo extérieur, pas d’ampoule (adaptation de p135–137). |
| S5 | `assets/hd2d/interior/props/ship_latrine.png` | 77 × 96 | panel | Toilette de bord rustique à petite vasque émaillée sur coffrage de bois cerclé de fer, aucun mécanisme moderne (original). |
| S5 | `assets/hd2d/interior/props/ship_privacy_curtain.png` | 96 × 173 | panel | Rideau de cabine en toile olive sombre sur rail de cuivre, attaches et ourlet usé, sans mur derrière (original). |
| S5 | `assets/hd2d/interior/props/ship_cargo_trolley.png` | 154 × 106 | panel | Chariot de soute bas à roues de fer, deux caisses arrimées par des sangles, aucun sol ni ombre (original). |
| S5 | `assets/hd2d/interior/props/ship_sword_rack.png` | 154 × 154 | panel | Râtelier fermé de transport d’armes : cinq fourreaux de fer sobres retenus par sangles sur cadre de métal, pas d’armes nommées inventées (original). |
| S5 | `assets/hd2d/interior/floor_ship_grating.png` | 384 × 384 | tile | Caillebotis de salle des machines vu strictement de dessus, grille sombre, plaques antidérapantes olive, raccords XY (original). |
| S5 | `assets/hd2d/interior/ceiling_ship_plate.png` | 384 × 384 | tile | Plafond de tôle gris-bleu rivetée vu perpendiculairement, opaque sans lampe ni conduite, raccords XY ; p135–137. |

## Assemblage conseillé et réemploi

| Pièce | Assets de cette livraison | Réemploi |
| --- | --- | --- |
| Passerelle | S1, porte étanche, conduites, porte-voix | lampe de cristal, cabinet de cartes |
| Conseil | table de guerre, chaise, thé miniature, emblème, hublot | serviettes et livres existants |
| Coursive | murs, coupe de mur, sol, hublots, portes, échelle, banc | panneaux de conduites et lampes |
| Cabines | S2 et rideau de S5 | livres, gobelets, coffres existants |
| Infirmerie | lit et cabinet médical de S4, lavabo de S2 | bandages et bouteilles déjà livrés dans le lot I |
| Mess / office | buffet et banc de S4, bidon, table rabattable | vaisselle et ustensiles du lot I, thé miniature |
| Machines / entretien | S3, sol en caillebotis | conduites, lampes, caisses |
| Sanitaires | toilette et rideau de S5, lavabo de S2 | bidon et lampe |
| Soute | chariot et râtelier de S5, caisses arrimées et écoutille de L | autres caisses et cordages existants |
| Pont extérieur | bastingage, écoutille, manche à air, passerelle, caisses | panneaux uniquement ; pont praticable dépend encore de E7 |

## Livraison et vérification

Les sources, planches groupées et aperçus restent hors dépôt. Chaque objet est découpé séparément, mis au format au plus proche voisin, sans réduction de palette. Vérifier les 50 PNG avec le contrôleur existant par invocation directe (les nouveaux noms ne sont pas tous au manifeste), les imports, les raccords, l’alignement des hélices dans les quatre scènes et `tools/check.sh` complet. Conserver les anciens dessins dans l’historique Git et conserver tous les autres assets existants. Quelques pixels de teintes extrêmes natifs peuvent subsister ; ne pas recolorer les images pour les supprimer.
