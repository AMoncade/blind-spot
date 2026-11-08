# L'Invisible : sans visage, sauf quand il te prend

Décision d'Adrien (8 novembre 2026) : « de base le Unseen doit être mystérieux ». En jeu, il n'a pas de visage : une silhouette grise, la tête penchée, qui te regarde sans yeux (`ReplicatedStorage.ClientModels.Unseen`, `Controllers/UnseenView`).

Au chapitre 1, il n'a de visage nulle part, même dans la prise (Adrien, 8 novembre 2026 : « faceless pour le chap 1 »). La prise (`Controllers/Death`) suit l'image d'Adrien :

1. La vue se retourne : sa tête lisse juste devant tes yeux, éclairée froid par en haut, bordée de rouge ; la vue avance pendant que sa tête penche.
2. La bande saute : il est penché vers toi, ses deux longues mains griffues de chaque côté de sa tête.
3. Il te saisit (cri, choc, la vue secoue), l'image se fige : bords rouges, lignes de bande, REC, SIGNAL LOST, YOU WERE CAUGHT.
4. S'il te reste une vie : combien il en reste, puis le poste. Sinon : RETRY (la même nuit) ou LOBBY.

## Les modèles

Tout vient de `tools/blender/unseen.py`, à partir du modèle FBX d'Adrien (une conversion Tripo, pas dans le dépôt) :

| `POSE` | Collection, puis modèle Studio | Visage |
| --- | --- | --- |
| `stand` | `Unseen` | non (le jeu) |
| `catch` | `UnseenCatch` (plus dans Studio : à reconstruire pour un niveau futur) | oui |
| `reach` | `UnseenReach` | non (la prise, les mains) |

Le visage est posé sur la tête par des rayons tirés de face : deux orbites noires en biais (`Sockets`), un œil pâle dans chacune (`Eyes`, que le client allume en néon), la bouche (`Mouth`) et deux rangées de dents en aiguilles (`TeethTop`, `TeethBottom`). Chaque partie est un objet à part pour que le client les fasse sortir et ouvrir.

## Garder le visage pour plus tard

Pour un niveau futur où il aurait un visage en jeu :

- `FACE = True` avant d'exécuter `tools/blender/unseen.py` met le visage sur n'importe quelle pose ;
- `assets/models/unseen_face.obj` (avec son `.mtl`) garde les cinq parties du visage, placées sur la pose debout (pieds à 0, face vers −Y, 1 unité = 1 stud) ;
- `POSE = "catch"` reconstruit la pose debout avec le visage ; importée comme `ClientModels.UnseenCatch`, `Controllers/UnseenView` peut la cloner à la place de `Unseen` (yeux en néon).
