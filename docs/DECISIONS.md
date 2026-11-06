# Décisions

Les choix tranchés, avec leur raison. Les décisions ouvertes pour Adrien sont à la section 13 du plan.

## Les champs se calculent sur les boîtes de la config, pas par des rayons Roblox (6 novembre 2026)

Le serveur ne lance aucun `workspace:Raycast` pour savoir ce qui est filmé : chaque boîte de `content/map_p3.csv` qui a `occludes` arrête les rayons, dans un test segment-boîte en Luau pur (`Logic/Grid.segmentHits`). Ces boîtes sont aussi les collisions invisibles que l'art final gardera (CLAUDE.md : les Parts servent aux collisions). Ainsi les specs Lune, le futur simulateur de 1 000 nuits et le serveur calculent exactement les mêmes champs, et un modèle Blender plus détaillé ne change jamais une règle.

## Une case est filmée dès qu'un seul de ses points est vu (6 novembre 2026)

Chaque case est testée au centre et à quatre coins rentrés de 0,4 stud, à 0,5, 3 et 6,5 studs du sol (6,5 couvre la tête de l'Invisible de 8,5 studs). Un seul point vu suffit. Un joueur compte comme filmé si une case filmée touche son cercle de 1,5 stud plus 1 stud de marge de lag. Le doute profite au joueur, et l'Invisible ne peut se tenir nulle part où un bout de lui serait à l'image.

## Le caméscope est placé par le serveur (6 novembre 2026)

Le client n'envoie que « levé » et sa direction (lacet, tangage) dix fois par seconde. Le serveur place l'œil à la tête du personnage, limite la rotation à 540° par seconde et tient la batterie. Le caméscope teste seulement le centre des cases, à deux hauteurs, pour rester léger à quatre joueurs.

## Les néons clignotent par créneaux de 0,34 s minimum (6 novembre 2026)

Le motif du FLICKER est tiré du temps du serveur et de la graine de la nuit, donc identique chez tous les joueurs, et chaque état dure au moins 0,34 s : jamais plus de 3 flashs par seconde (WCAG 2.3.1). Avec « Réduire les flashs », les néons baissent au lieu de clignoter et les LED ne clignotent plus.

## Phase 0 : la nuit 3 en boucle, réveil au poste (6 novembre 2026)

Pour la preuve de la peur, le serveur joue la nuit 3 (les premiers blackouts) dès qu'un joueur est là, puis recommence. Une mort fige le joueur 2,2 s et le réveille au poste ; la reprise à la dernière tâche, la paie et la sauvegarde viennent en phase 1.

## Le lobby est dans la même place, avec des ascenseurs (6 novembre 2026)

Demande d'Adrien : un lobby où les gens lancent la partie, inspiré des autres jeux d'horreur. On a pris la forme la plus connue du genre, des ascenseurs où un groupe de 1 à 4 se forme avant un compte à rebours, et on l'a habillée pour l'histoire : le hall de nuit du Halloway, d'où les monte-charges descendent au P3. Tant qu'il n'y a pas de place de jeu séparée (Adrien seul peut la créer), le quart se joue dans la même place, un à la fois. Avec `game_place_id`, `LobbyService` envoie le groupe dans un serveur réservé.

## L'éclairage Realistic se règle par le plugin (6 novembre 2026)

La recherche disait que LightingStyle et PrioritizeLightingQuality ne se règlent pas par script. Un script de jeu ne le peut pas, mais le plugin en Edit le peut : la place est en Realistic, priorité à la qualité, comme le demande le plan (section 7).

## Les zones sûres se voient au sol (6 novembre 2026)

Demande d'Adrien : afficher clairement où les caméras protègent. Le plan voulait tout dire sans interface (la caméra qui pivote, le silence) ; on garde ces signes et on ajoute une lueur au sol, calculée case par case avec les mêmes champs que le serveur, donc qui ne ment jamais, plus l'état ON CAMERA / BLIND SPOT en haut de l'écran. Les deux se coupent dans les réglages pour qui veut l'ancienne version. La lueur montre les cases du champ ; un garde compte comme filmé un peu au-delà (marge de lag), donc elle est du côté sûr.

## Les tâches ont un effet sur la nuit (6 novembre 2026)

Le générateur, le fusible de la caméra 07 : tant qu'ils ne sont pas faits, des caméras sont mortes et une zone est noire. Faire sa ronde rend donc le niveau plus sûr, et les objets à chercher sont mis dans des angles morts : le joueur doit sortir des champs pour gagner de la sécurité.

## Les modèles Blender gardent les boîtes de la config (6 novembre 2026)

Les piliers et les voitures sont des modèles Blender, mais les boîtes de `map_p3.csv` restent, invisibles, comme collisions et comme bloqueurs des rayons de caméra : les champs ne dépendent jamais du détail d'un modèle (voir « Les champs se calculent sur les boîtes de la config »).
