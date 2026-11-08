# L'Invisible : sans visage, sauf quand il te prend

Décision d'Adrien (8 novembre 2026) : « de base le Unseen doit être mystérieux ». En jeu, il n'a pas de visage : une silhouette grise, la tête penchée, qui te regarde sans yeux (`ReplicatedStorage.ClientModels.Unseen`, `Controllers/UnseenView`).

Son visage ne sort que dans la prise (`Controllers/Death`, environ 6 s) :

1. La vue se retourne : sa tête lisse est juste devant tes yeux, éclairée par en dessous, bordée de rouge.
2. Les creux de ses yeux se creusent, deux yeux pâles en sortent et s'allument.
3. Un sourire beaucoup trop large se déchire d'un bout à l'autre de sa tête ; la mâchoire tombe et les aiguilles claquent.
4. La bande saute : il est penché vers toi, ses deux longues mains ouvertes qui viennent autour de ta tête.
5. Il te prend : les mains passent devant l'objectif, cri, choc, la vue secoue ; l'image se fige en noir et blanc, SIGNAL LOST.

Pas de sang. « Réduire les flashs » enlève la pulsation rouge et calme les secousses. Les temps et les distances sont dans `content/constants.csv` (`catch_*`, `death_seconds`).

## Les modèles

Tout vient de `tools/blender/unseen.py`, à partir du modèle FBX d'Adrien (une conversion Tripo, pas dans le dépôt) :

| `POSE` | Collection, puis modèle Studio | Visage |
| --- | --- | --- |
| `stand` | `Unseen` | non (le jeu) |
| `catch` | `UnseenCatch` | oui (la prise, premier plan) |
| `reach` | `UnseenReach` | oui (la prise, les mains) |

Le visage est posé sur la tête par des rayons tirés de face : deux orbites noires en biais (`Sockets`), un œil pâle dans chacune (`Eyes`, que le client allume en néon), la bouche (`Mouth`) et deux rangées de dents en aiguilles (`TeethTop`, `TeethBottom`). Chaque partie est un objet à part pour que le client les fasse sortir et ouvrir.

## Garder le visage pour plus tard

Pour un niveau futur où il aurait un visage en jeu :

- `FACE = True` avant d'exécuter `tools/blender/unseen.py` met le visage sur n'importe quelle pose ;
- `assets/models/unseen_face.obj` (avec son `.mtl`) garde les cinq parties du visage, placées sur la pose debout (pieds à 0, face vers −Y, 1 unité = 1 stud) ;
- dans Studio, `ClientModels.UnseenCatch` est déjà la pose debout avec le visage : `Controllers/UnseenView` peut le cloner à la place de `Unseen` (et laisser les parties du visage visibles, yeux en néon).
