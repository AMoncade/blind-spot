# BLIND SPOT

Jeu d'horreur Roblox en Luau : première personne, solo ou coop de 1 à 4, décor photoréaliste. La seule chose qui protège le joueur, c'est l'œil d'une caméra : l'Invisible n'existe que dans les angles morts. Lancement visé : vendredi 12 février 2027 (à confirmer par Adrien). Ce dépôt contient le plan et la recherche ; le code vient ensuite, bâti avec Claude Code en 4 phases (plan, section 12).

## À lire d'abord

- [`blind-spot-plan.md`](blind-spot-plan.md) : tout le plan. La version vivante est le [doc Claude](https://claude.ai/artifact/VMZVexNFcuM3uneHSmL6jm) ; le md en est l'export. La section 11 est le plan technique, la section 12 les phases et ce que « fini » veut dire pour chacune.
- [`research/plan/`](research/plan/) : la recherche derrière le plan (The Locust et les références, rendu réaliste sur Roblox, assets et licences, atmosphère et son, maturité et monétisation).
- [`research/concurrence/`](research/concurrence/) : ce qui existe déjà sur Roblox dans le genre (4 novembre 2026).

## Règles

- **Le serveur décide.** Il calcule qui est filmé, où est l'Invisible, qui meurt, ce qui est payé et sauvegardé. Le client envoie des intentions et anime. Chaque remote vérifie ses arguments et a une limite de débit.
- **Le doute profite au joueur.** Un joueur au bord d'un champ de caméra compte comme filmé ; le lag ne doit jamais tuer.
- **Les règles de l'Invisible ne changent jamais** (plan, section 4) : jamais dans un champ, jamais à l'écran, il voyage par l'ombre, il tue au contact dans un angle mort.
- **Tous les chiffres viennent de la config** : caméras (position, angle, portée), phases, Invisible, batteries, paie. Aucun chiffre en dur dans le code.
- **Un seul profil ProfileStore par joueur.** S'il ne charge pas, le joueur ne joue pas ; on ne démarre jamais personne sur une sauvegarde vide.
- **Téléphone d'abord :** tout marche au tactile, cibles d'au moins 44 px, testé à 844 × 390, et les budgets de rendu du plan (section 7) tenus sur un téléphone d'entrée de gamme.
- **Réaliste, rien de blocky.** Matériaux PBR, éclairage réglé à la main, aucune texture studs. Chaque asset importé a sa ligne dans `assets/SOURCES.csv` (source, licence, lien, date) avant d'être téléversé sur Roblox ; aucune source sans licence commerciale claire (plan, section 7).
- **Blender d'abord.** Tout objet plus complexe qu'une simple dalle (piliers, tuyaux, portes, caméras, néons, voitures, mobilier, caméscope, mains, l'Invisible) se modélise en 3D dans Blender par le MCP Blender, puis s'importe en MeshPart avec sa SurfaceAppearance. Jamais d'objet fait de Parts assemblés : les Parts ne servent qu'aux collisions, aux zones invisibles et à la version grise. Chaque modèle est un script dans `tools/blender/` qui le reconstruit de zéro ; budgets de triangles et de textures au plan, section 7.
- **Peur sans gore :** pas de sang, jamais plus de 3 flashs par seconde, et les options d'accessibilité du plan (sections 2 et 8).
- **Ne jamais créer de produits Robux, publier le jeu ou changer ses réglages.** Demander à Adrien.
- **Le dépôt est public** (choix d'Adrien du 6 novembre 2026) : n'y mettre ni secret, ni clé, ni nom d'utilisateur d'un autre joueur, ni capture qui en montre.
- Une tâche, un commit. Avant de dire qu'une tâche est finie : lint, format, specs, un playtest dans Studio, une console sans erreur, et une capture comparée aux images de référence.

## Break a Gem et Roll an Anomaly, les jeux d'Adrien

Dépôts **AMoncade/BreakAGem** et **AMoncade/roll-an-anomaly**, en lecture seule : les cloner à côté de celui-ci au besoin, ne jamais y pousser. Reprendre leur façon de travailler et leurs outils, pas leur art (Roll an Anomaly est en studs et en part-builder : rien de ça ici).

- `BreakAGem/CLAUDE.md` : la pile (Rojo, Rokit, Selene, StyLua, specs Lune, le MCP de Roblox Studio pour les playtests et les captures, ProfileStore) et une longue liste de pièges.
- `BreakAGem/tools/blender/` : des modèles écrits en code dans Blender.
- `BreakAGem/scripts/check.sh` : la seule porte avant chaque commit.
- `docs/WORKLOG.md` et `docs/DECISIONS.md` : ce qui a été fait, dans l'ordre, et les choix tranchés.

Pièges de Break a Gem qui toucheront ce jeu aussi :

- Les téléportations, Analytics, les vrais DataStores, `ProcessReceipt`, la voix et les parties à plusieurs clients ne se prouvent pas dans Studio : les marquer « à vérifier sur le jeu publié », jamais « fini ».
- Le MCP de Studio est une seule instance partagée : ne pas lancer de playtest pendant qu'une autre session s'en sert.
- `InsertService:LoadAsset` ne charge que les assets du propriétaire : garder une copie de chaque modèle dans la place, dans `ServerStorage`.
- `screen_capture` ne dessine pas les BillboardGui `AlwaysOnTop` : une invite absente d'une capture n'est pas un défaut.
- Une porte se juge à son code de sortie : `./scripts/check.sh | tail -1 && git commit` commite même quand la vérification échoue.
- Python écrit en CRLF sur le PC Windows d'Adrien : écrire les fichiers avec `newline="\n"`.
- Avec les réglages d'export FBX de Break a Gem, Blender (x, y, z) arrive dans Roblox en (−x, z, y) : vérifier les axes et l'échelle sur le premier modèle.

## Où on en est (6 novembre 2026)

Le plan et la recherche sont faits. Roll an Anomaly passe d'abord (lancement le 24 novembre). Ensuite : la phase 0, la preuve de la peur (plan, section 12) : le calcul des champs de caméra, l'Invisible de base, le cycle du courant, le contrôleur en première personne et une salle réaliste testée sur un vrai téléphone. Les décisions ouvertes pour Adrien sont à la section 13 du plan.
