# K&V SUPPLY : les améliorations

Le magasin du lobby, à l'est du hall (porte sous l'enseigne K&V SUPPLY) : un comptoir et quatre présentoirs. Chaque présentoir ouvre l'écran des améliorations sur la sienne ; le comptoir les montre toutes. On paie avec la paie des nuits. Les niveaux sont gardés dans le profil (`profile.upgrades`).

Sans amélioration, le jeu est dur exprès (demande d'Adrien, 8 novembre 2026) : la barre SIGNAL se vide en 14 s hors caméra en LIVE, 10 s quand les lumières vacillent, 7 s dans un blackout, et encore plus vite les nuits avancées (×0,85 la nuit 1 à ×1,35 la nuit 6). Finir les six nuits sans rien acheter doit être très difficile.

Les chiffres sont dans `content/upgrades.csv` (un niveau par valeur, le prix monte à chaque niveau : `cost_base × cost_growth^(niveau − 1)`, arrondi à 10). La logique est dans `src/shared/Logic/Upgrades.luau`, le serveur dans `src/server/Services/UpgradeService.luau`.

## Aujourd'hui

| Amélioration | Niveaux | Effet du niveau 1 au dernier | Prix (niveau 2 → dernier) |
| --- | --- | --- | --- |
| **SIGNAL** (ta tête) | 10 | la barre se vide ×1,00 → ×0,42 aussi vite | 150 $ → environ 1 400 $ |
| **SPRINT** (tes jambes) | 5 | 2 s de course, 22 s de recharge → 4 s, 10 s | 200 $ → environ 820 $ |
| **CAMCORDER** (bande et batterie) | 8 | 5 s de bande, 0,4 s rechargée par seconde sous une caméra → 45 s, 1,2 s/s | 150 $ → environ 1 400 $ |
| **FLARES** (fusées rouges) | 5 | 1 fusée par nuit qui brûle 18 s → 4 fusées, 35 s | 250 $ → environ 930 $ |

Tout acheter coûte environ 13 600 $, soit une vingtaine de nuits.

## Prochainement (idées notées, pas encore faites)

- **TRÉPIED** : poser une caméra pour une minute, avec un vrai cône (un champ de caméra mobile). Niveaux : durée, portée, nombre par nuit.
- **LEURRE** : une radio qui grésille et l'attire dans un angle mort loin de toi pendant quelques secondes. Niveaux : durée, nombre.
- **LAMPE** : une lampe torche qui ralentit la barre quand elle est allumée, mais qu'il voit de loin (il saute plus près plus souvent).
- **MAINS SÛRES** : les tâches se font plus vite (scans, générateur, fusible). Niveaux : −10 % du temps par niveau.
- **RADIO** : la répartitrice te prévient quand il est derrière toi (une seule fois par nuit au niveau 1).
- **VIES** : une vie de plus pour l'équipe, une fois par nuit (ne change pas la paie multipliée).
- **BADGE** : en coop, ramener le badge d'un coéquipier plus vite.
- **CAMÉRAS RÉPARÉES** : une caméra morte de la nuit remise en marche au début.

Chaque nouvelle amélioration : une ligne dans `content/upgrades.csv`, son icône (même style que les autres), un présentoir dans `content/shop_stations.csv` et `content/lobby_props.csv` (modèle Blender), et l'endroit du jeu qui lit son niveau.
