# Assets, textures et sons pour BLIND SPOT : sources, licences et pipeline Blender vers Roblox

Notes de recherche, pages consultées le **2026-11-06**. Les citations entre guillemets sont reprises de la page source telle qu'elle s'affichait ce jour-là (l'outil de lecture coupe les citations à environ 125 caractères ; quand une phrase est paraphrasée, c'est indiqué). **Ce n'est pas un avis juridique.** Les points marqués « avocat » sont à faire valider par un juriste avant la sortie du jeu.

Ce que BLIND SPOT doit respecter : le jeu rapporte des Robux (usage commercial), et tout asset est téléversé sur Roblox, où Roblox reçoit une licence large sur le contenu et où le client télécharge les meshes et les textures pour les afficher.

---

## 1. Licences des sources de modèles, textures et HDRI, appliquées à un jeu Roblox commercial

### Takeaway
Seules les sources **CC0** (Poly Haven, ambientCG, et les modèles CC0 de Sketchfab) ne posent aucune question de redistribution : usage commercial, pas d'attribution, redistribution permise. Les licences de magasin (Fab Standard, Sketchfab Store, Blendkit Royalty Free, CGTrader, TurboSquid) autorisent un jeu commercial mais interdisent la redistribution « standalone » ou l'extraction par l'utilisateur final. **TurboSquid et CGTrader visent explicitement les mondes virtuels, plateformes et communautés 3D** : à éviter pour Roblox sans accord écrit.

### Cited Findings

**Tableau de synthèse** (détails et citations dans les puces qui suivent)

| Source | Licence | Commercial | Attribution | Téléverser sur Roblox (dans le jeu) | Publier sur le Creator Store |
|---|---|---|---|---|---|
| Poly Haven | CC0 | Oui | Non | Oui | Oui (CC0) |
| ambientCG | CC0 1.0 | Oui | Non | Oui | Oui (CC0) |
| Fab (Megascans compris) | Fab Standard (paliers Personal / Professional) | Oui | Non (Standard) | Oui, intégré au projet | **Non** (redistribution standalone) |
| Fab, annonces CC-BY | CC BY | Oui | **Oui** | Oui | À éviter |
| Sketchfab, téléchargements gratuits | CC0 / CC BY / BY-SA / BY-ND / BY-NC | Selon la licence (NC interdit) | Oui sauf CC0 | CC0 et CC BY : oui | CC0 seulement |
| Sketchfab Store (fermé) | Standard / Editorial | Standard oui, Editorial **non** | Non | Standard : oui, sans permettre l'extraction | **Non** |
| Blendkit (ex-BlenderKit) | Royalty Free ou CC0 | Oui | Non | RF : « si pas extractible facilement » | **Non** (RF) |
| CGTrader | Royalty Free (21A) | Oui | Non | **Risqué** : clause « monde virtuel / plateforme » | **Non** |
| TurboSquid | Royalty Free (2020) | Oui | Non | **Risqué** : clauses 7(c) et 7(d) | **Non** |
| Textures.com | Non vérifiée | ? | ? | ? | ? |

**Poly Haven** (textures, HDRI, modèles), [polyhaven.com/license](https://polyhaven.com/license), page sans date :
- « Our assets are all licensed as CC0, which is effectively Public Domain » — [Poly Haven License](https://polyhaven.com/license)
- « You can use our assets for any purpose, including commercial work. » — [Poly Haven License](https://polyhaven.com/license)
- « You do not need to give credit or attribution when using them (although it is appreciated). » — [Poly Haven License](https://polyhaven.com/license)
- « You can redistribute them, share them around, include them when sharing your own work, or even in a product you sell. » — [Poly Haven License](https://polyhaven.com/license)
- Les conditions du site interdisent « Web scraping or data mining without express permission. » Les logos ne sont pas CC0. — [Poly Haven License](https://polyhaven.com/license)

**ambientCG** (textures PBR, HDRI, modèles), page sans date :
- « All ambientCG assets are provided under the Creative Commons CC0 1.0 Universal License. » — [ambientCG License](https://docs.ambientcg.com/license/)
- « You can copy, modify, distribute and perform the assets, even for commercial purposes, all without asking permission. » — [ambientCG License](https://docs.ambientcg.com/license/)
- « You can include the raw files in your project, for example a video game. » — [ambientCG License](https://docs.ambientcg.com/license/)
- « You don't need to give credit but I would of course appreciate it, if you did it anyways. » — [ambientCG License](https://docs.ambientcg.com/license/)

**Fab / Quixel Megascans** (Epic) :
- Résumé de la licence Standard sur la page EULA (le résumé se dit non contraignant ; le texte complet de l'EULA n'a pas pu être lu, voir Gaps) : « Use the assets commercially or privately » ; « Use the assets with any compatible tools (usage is not limited to Unreal Engine) » ; « Commercially distribute your Projects with the Fab assets incorporated into it ». Interdit : « Resell or redistribute the asset for free on a standalone basis or allow others to do the same ». Page sans date de version (seulement « © 2026 Epic Games »). — [Fab EULA](https://www.fab.com/eula)
- Paliers de la licence Standard : Personal « For buyers who have not generated more than $100,000 USD in gross revenue from commercial activity in the last 12 months » ; Professional au-delà de 100 000 USD. La page note aussi « Epic Games is phasing out the UE Marketplace License » et liste « Creative Commons Attribution (CC-BY) (Free) » comme licence possible sur Fab. — [Epic Dev Docs, Licenses and pricing in Fab](https://dev.epicgames.com/documentation/en-us/fab/licenses-and-pricing-in-fab)
- Megascans, mise à jour Epic du 26 mars 2025 : « You can use Fab Standard licensed assets in any engine or tool, assuming the file formats are compatible. » Elle rappelle que l'ancienne Epic Content License (plan UE) « required that assets acquired under the UE plan only be used in Unreal Engine ». — [Megascans update, March 2025 (forum Unreal)](https://forums.unrealengine.com/t/megascans-update-march-2025/2419561)
- FAQ de transition Quixel vers Fab (septembre 2024, mise à jour ensuite) : les Megascans réclamés sur Fab « can be used in any tool or engine according to the Fab Standard License agreement » ; à partir de 2025, prix à l'unité : assets 2D et 3D dès 0,99 USD, kits procéduraux dès 4,99 USD, packs dès 24,99 USD. — [Quixel to Fab Transition FAQs](https://forums.unrealengine.com/t/quixel-to-fab-transition-faqs/2033839)
- Le contenu téléchargé par Bridge relève de l'ancienne Epic Content License, qui ne permet l'usage gratuit que dans Unreal Engine (selon CG Channel, octobre 2024). — [CG Channel](https://www.cgchannel.com/2024/10/epic-games-has-made-megascans-free-to-all-but-only-until-the-end-of-2024/)
- Source tierce (2026, « Not Legal Advice ») qui décrit un palier « Free with Unreal Engine » pour Megascans ; elle ne répond pas à la question des autres moteurs. Contradiction possible avec les sources d'Epic ci-dessus, non résolue. — [LicenseOrg, Quixel Megascans](https://licenseorg.com/guide/3d-assets/quixel-megascans)

**Sketchfab** :
- Licences des modèles téléchargeables : Standard, CC BY, CC BY-NC (« others cannot use your model commercially »), CC BY-ND (« it cannot be altered »), CC BY-SA (dérivés sous la même licence), CC0 (« No Rights Reserved »). Toutes les CC sauf CC0 exigent de créditer l'auteur. — [Sketchfab Help](https://help.sketchfab.com/en/articles/16152217)
- Licence de magasin de Sketchfab : article 2.2(b), interdiction de rendre disponible « the Licensed Material as a stand-alone file (or group of files) » ; 2.2(h), interdiction de le rendre disponible « in a manner intended to allow or invite a third party to download, extract » ; 2.2(c)(ii), restriction quand « the primary value of the Licensed Work lies with the Licensed Material itself ». Licence Editorial : aucun « commercial or promotional use ». — [Sketchfab Licenses](https://sketchfab.com/licenses)
- « The Sketchfab Store is now closed. » Les achats restent accessibles ; « Free and view-only models will remain where they are » ; Epic promet « plenty of notice before free downloadable content is no longer supported on Sketchfab ». — [Sketchfab blog, Fab update](https://sketchfab.com/blogs/community/sketchfab-update-what-you-need-to-know-now-that-fabs-live/)

**Blendkit (anciennement BlenderKit)** : blenderkit.com redirige maintenant vers blendkit.com, dont le pied de page dit « Blendkit (formerly known as BlenderKit) ».
- Pour les jeux, sous la licence Royalty Free : « Yes, if these can't be extracted by the users in an easy way » et « the assets shouldn't be directly extractable in the distribution ». La licence CC0 « technically allows you to do anything with the assets ». Revendre des scènes faites de modèles Blendkit sur d'autres marchés 3D : « No you can't ». — [Blendkit Licensing FAQ](https://www.blendkit.com/docs/licenses/licensing-faq/)

**CGTrader**, Royalty Free License, section 21A (page sans date de version) :
- Jeux : usage permis « as part of a game if the Product is contained inside a proprietary format » ; il faut « take all commercially reasonable measures to prevent the end user from gaining access to the Product ». — [CGTrader Terms](https://www.cgtrader.com/pages/terms-and-conditions)
- Condition : le produit doit être « not re-packaged as goods sold inside a virtual world, metaverse, application or platform » et « not downloadable by users of such virtual worlds, metaverses, applications or platforms ». — [CGTrader Terms](https://www.cgtrader.com/pages/terms-and-conditions)
- « The resale or redistribution by the Buyer of any Product, obtained from the Site is expressly prohibited. » Il existe une variante « Royalty Free License, No AI » (21B) : « Product use for machine learning or training of neural network models, including generative AI models, is not permitted. » — [CGTrader Terms](https://www.cgtrader.com/pages/terms-and-conditions)

**TurboSquid**, Royalty Free License (« effective for use with Stock Media Products for use on or after February 3, 2020 » ; page modifiée le 2023-03-16) :
- 7(b) : « Stock Media Products must be contained in proprietary formats so that they cannot be opened or imported » — [TurboSquid Royalty Free License](https://blog.turbosquid.com/royalty-free-license/)
- 7(c) : « You may NOT include Stock Media Products in Creations that have the general functionality for importing » — [TurboSquid](https://blog.turbosquid.com/royalty-free-license/)
- 7(d) : interdiction « in Creations of virtual goods or worlds for any 3D community » ; sur les mondes virtuels : « This use is prohibited if the virtual world-type is an open MMO, like Second Life. » — [TurboSquid](https://blog.turbosquid.com/royalty-free-license/)
- 6(d) : « You may NOT use Imagery in machine learning programs without prior authorization from TurboSquid. » Editorial : « may not be used for any commercial, promotional, advertising or merchandising use ». — [TurboSquid](https://blog.turbosquid.com/royalty-free-license/)

**Textures.com** : les pages de licence ([faq-license](https://www.textures.com/faq-license), [about/license](https://www.textures.com/about/license)) ne s'affichent qu'avec JavaScript, et l'outil de lecture n'a rien pu en tirer. Voir Gaps.

**Pixabay** (images, vidéo, audio ; utile pour des décalques ou des sons) : « Use Content without having to attribute the author » ; « You cannot sell or distribute Content (either in digital or physical form) on a Standalone basis » ; contenu avec marques ou logos : « you cannot use that Content for commercial purposes in relation to goods and services ». Page sans date. — [Pixabay License Summary](https://pixabay.com/service/license-summary/)

### Inferences
- **Choix par défaut pour BLIND SPOT : CC0 d'abord** (Poly Haven, ambientCG, CC0 de Sketchfab ou Blendkit). C'est le seul cas où publier sur le Creator Store, ou une fuite par extraction, ne viole aucune licence.
- **Fab Standard est utilisable dans Roblox** selon les propres mots d'Epic (« not limited to Unreal Engine », « any engine or tool »), à trois conditions : (1) vérifier sur chaque annonce que la licence affichée est bien « Standard » et pas l'ancienne UE Marketplace License ou Epic Content License (réservées à Unreal) ; (2) ne jamais rendre le mesh public sur le Creator Store (« allow others to do the same ») ; (3) rester sous 100 000 USD de revenus bruts sur 12 mois pour le palier Personal, sinon prendre Professional. Les Megascans réclamés par Bridge avant le 22 octobre 2024 sont **à exclure** (Epic Content License, Unreal seulement).
- **TurboSquid : à éviter.** Roblox est une plateforme de création ouverte, assimilable à une « 3D community » ou à un « open MMO, like Second Life » (7(d)), et Studio a une « general functionality for importing » (7(c)). Interprétation défavorable probable. **Avocat**, ou accord écrit de TurboSquid.
- **CGTrader : risqué.** La clause « not downloadable by users of such virtual worlds, metaverses, applications or platforms » vise justement un cas comme Roblox. Le mesh n'est pas téléchargeable comme fichier si l'asset reste « Restricted » (section 2), mais il est envoyé au client pour l'affichage. **Avocat.**
- **Sketchfab Store et Blendkit RF :** permis dans le jeu, à condition de ne pas « inviter » l'extraction (2.2(h)) ni de le rendre « directly extractable ». En pratique : assets privés, jamais sur le Creator Store, jamais dans un modèle partagé.
- **Voitures et marques :** les voitures de vraies marques sont souvent vendues sous licence Editorial (Sketchfab, TurboSquid), qui exclut tout usage commercial. Pixabay exclut aussi les logos en usage commercial. Pour le stationnement : des voitures génériques sans logo, ou des épaves stylisées. **Avocat** si un design de voiture reconnaissable est reproduit, même sans logo (dessins et modèles, marques de forme).
- **Attribution :** dès qu'un asset est CC BY (Sketchfab, Fab CC-BY, Freesound, Meshy gratuit), prévoir un écran « Crédits » dans le jeu et un fichier `CREDITS.md` dans le dépôt (titre, auteur, lien, licence). Exclure CC BY-SA (contamine les dérivés), BY-ND (pas de retopo ni de recadrage de texture) et BY-NC (le jeu rapporte des Robux).
- **Automatisation par Claude :** les conditions de Poly Haven interdisent le scraping sans permission. Un script qui aspire la bibliothèque en masse serait donc hors des règles ; télécharger asset par asset (site, add-on Blender) reste dans l'usage normal. L'existence d'une API officielle n'a pas été vérifiée ici.

### Gaps
- **Texte complet de l'EULA Fab non lu** : la page n'affiche que le résumé, et la version `?lang=en` a échoué. Restent inconnus : la définition exacte de « Project », une éventuelle obligation de protéger l'asset contre l'extraction, une clause IA côté acheteur, la date de version. À lire en entier sur fab.com avant tout achat. **Avocat.**
- **Megascans gratuits en 2026 :** une source tierce parle d'un palier « Free with Unreal Engine », mais je n'ai trouvé aucune page d'Epic qui le confirme ou qui précise ses limites hors Unreal. À vérifier annonce par annonce sur fab.com.
- **Textures.com :** licence non lue (page en JavaScript). Ce que j'en sais par ailleurs (usage autorisé dans les jeux à condition de ne pas redistribuer les textures seules, crédits gratuits limités) est **non vérifié**.
- **Roblox Creator Store comme source d'assets :** je n'ai pas trouvé de page de licence propre au Creator Store pour les modèles 3D. Les conditions de Roblox (section 2) disent seulement que d'autres peuvent utiliser le contenu d'un créateur qui l'a choisi. Risque connu mais non sourcé ici : des modèles volés sont republiés sur le Creator Store, donc un asset gratuit du Creator Store n'apporte aucune garantie de chaîne de droits.
- Pour Sketchfab, Fab et Poly Haven, aucune page n'affichait de date de version : toutes les citations sont datées du jour de consultation (2026-11-06).

---

## 2. Téléverser un asset sur Roblox : conditions de Roblox, confidentialité, et risque de « redistribution »

### Takeaway
En téléversant, on accorde à Roblox une licence très large (hébergement, copie, modification, distribution, **et entraînement de modèles d'apprentissage automatique**), et on garantit être propriétaire du contenu ou autorisé à le publier. Les meshes, images et décalques peuvent rester « Restricted » (invisibles hors des jeux autorisés), et l'audio est privé par défaut. Le partage aux autres créateurs n'a lieu que si on l'active. Le vrai risque juridique vient de la **licence accordée à Roblox** (sous-licenciable, apprentissage automatique compris), qui peut dépasser ce que permet une licence de magasin.

### Cited Findings
- Conditions d'utilisation de Roblox, « Last Updated: January 22, 2025 » (version affichée le 2026-11-06) : « you grant Roblox a nonexclusive, royalty-free, perpetual, irrevocable, and fully sublicensable right to host, use, copy ». Paraphrase de la suite de la phrase (citation trop longue) : la licence couvre aussi la modification, la distribution et l'affichage public sur les services, dans le monde entier, pour tout usage lié à l'exploitation ou à l'amélioration des services, **y compris l'entraînement de modèles d'apprentissage automatique**. — [Roblox Terms of Use](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use)
- Creator Terms, partage aux autres utilisateurs : « Creator is not required to do so, but if Creator does agree to grant this right, then other Users may use Creator's UGC ». — [Roblox Terms of Use](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use)
- Creator Terms, droits : « Creator must not Publish or otherwise make any UGC available on the Services if Creator is not the owner of » (suite paraphrasée : … ou pleinement autorisé à accorder les droits sur toutes ses composantes ; le créateur paie ce qui est dû à des tiers). — [Roblox Terms of Use](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use)
- Confidentialité des assets : « Asset Privacy controls only the default privacy state assigned to Images, Decals, and Meshes when they are created. » Un asset Restricted doit « be explicitly granted permission before they are visible or audible at runtime ». La permission peut être donnée à des amis, des groupes ou des jeux, et une permission accordée à un jeu « cannot be revoked ». Les métadonnées (nom, description) restent visibles. — [Roblox Creator Hub, Asset privacy](https://create.roblox.com/docs/projects/assets/privacy)
- Audio : « you are initially the only one who can view and use private audio assets » ; on peut accorder l'usage « to specific friends and experiences ». Les effets sonores « can be distributed on the Creator Store ». — [Roblox Creator Hub, Audio assets](https://create.roblox.com/docs/audio/assets)
- Importateur 3D : l'option « Upload to Roblox » (activée par défaut) ajoute le modèle à l'inventaire de la Toolbox et de l'Asset Manager ; la désactiver permet d'itérer sans créer de copies. « Import as Package » donne un format « auto-updating, scalable, and sharable ». — [Roblox Creator Hub, 3D Importer](https://create.roblox.com/docs/art/modeling/3d-importer)
- Expérience dans le dépôt d'Adrien (Break a Gem, CLAUDE.md, « Studio et Rojo ») : « `LoadAsset` ne charge que les assets du propriétaire (Studio d'un collaborateur, jeu passé à un groupe) ». Le projet garde donc une copie de chaque modèle dans `ServerStorage.ModelSources`. — [CLAUDE.md de Break a Gem](https://github.com/AMoncade/BreakAGem/blob/main/CLAUDE.md)

### Inferences
- **Trois niveaux de risque à distinguer :**
  1. **Publier l'asset sur le Creator Store** ou cocher le partage aux autres créateurs : c'est de la redistribution standalone, interdite par Fab, Sketchfab Store, Blendkit RF, CGTrader, TurboSquid et Pixabay. **À ne jamais faire**, sauf pour du CC0 ou nos propres créations.
  2. **Asset intégré au jeu, gardé Restricted** : c'est l'usage « incorporé dans un projet » que permettent Fab, Sketchfab Store et Blendkit, sous réserve des clauses anti-extraction. Le client Roblox télécharge quand même meshes et textures pour les afficher, et des outils d'extraction de la communauté existent (**non vérifié ici**, aucune source consultée). Est-ce que cela compte comme « commercially reasonable measures » (CGTrader) ou « proprietary formats » (TurboSquid) ? **Avocat.**
  3. **Licence accordée à Roblox** : on accorde à Roblox un droit sous-licenciable, apprentissage automatique compris, sur un contenu dont on n'est que licencié. Pour un asset CC0, aucun problème. Pour un asset de magasin, la licence d'origine ne nous donne probablement pas le droit de sous-licencier à Roblox, et elle interdit parfois l'IA (TurboSquid 6(d), CGTrader « No AI », tag NoAI sur Fab). **Point clé pour un avocat.** C'est un argument de plus pour privilégier le CC0 et les assets faits maison.
- **Organisation conseillée :** posséder les assets au nom du **groupe Roblox** qui publiera le jeu, dès le premier téléversement (le piège `LoadAsset` de Break a Gem), avec la confidentialité par défaut sur Restricted. Désactiver « Upload to Roblox » pendant les essais, pour ne pas multiplier les copies dans l'inventaire.
- **Registre des licences :** un fichier (CSV ou `CREDITS.md`) qui associe à chaque assetId sa source, son URL, sa licence, la date de téléchargement et une capture de la page de licence. Si Roblox reçoit une plainte DMCA, c'est la preuve de la chaîne de droits.

### Gaps
- Pas de source primaire consultée sur l'extraction des meshes et textures par les clients Roblox (outils d'exploitation, format `.mesh`). Le risque technique est réel, mais non sourcé ici.
- Je n'ai pas trouvé de position officielle de Fab, Sketchfab, CGTrader ou TurboSquid sur Roblox en particulier.
- La phrase complète de la licence UGC de Roblox n'a pu être citée qu'en partie, à cause de la limite de citation de l'outil. Relire la section « Intellectual Property and UGC » sur la page.

---

## 3. Photogrammétrie au téléphone (RealityScan, Polycam…)

### Takeaway
Avec RealityScan (Epic), **l'utilisateur garde les droits sur ses scans**. Epic n'y accède que pour le calcul, et la réutilisation pour améliorer ses outils se fait sur option. Aucune restriction commerciale ni obligation d'utiliser Unreal. Les conditions de Polycam n'ont pas pu être lues. Les scans bruts sont trop lourds pour Roblox : retopologie et cuisson (bake) obligatoires.

### Cited Findings
- EULA de RealityScan Mobile, section 5 : l'usage du logiciel « does not grant to Licensor any right, title, or interest in any of the content that you produce » (hors sections 3 et 4). — [RealityScan Mobile EULA](https://www.realityscan.com/eula-mobile)
- Section 4.1 : accès d'Epic aux données « for the sole purpose of generating 3D models and to store your relevant data for a limited time ». Section 4.2 : l'usage des scans pour améliorer les outils se fait sur option, et peut être retiré dans les réglages. — [RealityScan Mobile EULA](https://www.realityscan.com/eula-mobile)
- Section 1.1 : licence accordée « for any lawful purpose », sous les restrictions de la section 1.2 (dont le respect des droits de tiers). Le document ne mentionne pas Unreal Engine. Pour partager un résultat, « you may need to use other products of Licensor or its affiliates, such as Sketchfab ». Pas de date de version affichée. — [RealityScan Mobile EULA](https://www.realityscan.com/eula-mobile)
- Un mesh Roblox ne peut pas dépasser 20 000 triangles (« Individual meshes can not exceed 20,000 triangles ») et doit être « watertight without exposed holes or backfaces ». — [Roblox Creator Hub, Mesh specifications](https://create.roblox.com/docs/art/modeling/specifications)
- Les textures s'affichent jusqu'en 4096 × 4096 depuis le 30 janvier 2026 (voir section 6). — [DevForum, 4k Texture Rendering](https://devforum.roblox.com/t/4k-texture-rendering/4316229)

### Inferences
- **Processus type pour un scan destiné à Roblox :** capture au téléphone, puis mesh haute définition (souvent bien plus que 20 000 triangles), puis retopologie ou décimation dans Blender (un objet de taille moyenne tient bien sous 5 000 triangles), puis UV en 0–1, puis cuisson dans Blender du normal map et de l'albedo du haut vers le bas, puis délumination (*delighting*) de l'albedo (le scan contient l'éclairage du lieu), puis roughness à la main. Tout cela se scripte avec le MCP Blender.
- **Bon usage pour BLIND SPOT :** scanner des **matériaux et petits objets** (béton taché, bouche d'égout, cône, extincteur sans marque, boîte électrique, rouille, graffitis faits par l'équipe) plutôt que des voitures (trop grosses, surfaces réfléchissantes qui scannent mal, et marques déposées).
- **Droits de tiers :** posséder le scan ne donne aucun droit sur ce qui est scanné. Logos, œuvres d'art (graffiti d'un autre artiste), designs protégés restent aux tiers, d'où la réserve « lawful purpose » de l'EULA. Scanner dans un stationnement privé peut aussi demander une autorisation. **Avocat** pour tout objet reconnaissable.

### Gaps
- **Polycam** : la page de conditions (poly.cam/terms) n'a pas pu être lue. Inconnus : propriété des captures, licence accordée à Polycam (galerie publique, entraînement d'IA), limites d'export du plan gratuit. **Non vérifié.**
- **RealityScan 2.0 (bureau)** : l'EULA du logiciel de bureau ([realityscan.com/eula](https://www.realityscan.com/eula)) n'a pas été lue (gratuité sous un seuil de revenus, conditions commerciales).
- Pas de source sur la qualité réelle des scans de téléphone importés dans Roblox (pas de guide DevForum consulté : le forum était en maintenance).

---

## 4. Génération 3D par IA : outils de Roblox (Cube, Mesh Generation) et outils tiers (Meshy, Tripo)

### Takeaway
Roblox a rendu Cube open source en mars 2025 et annoncé le 16 avril 2026 une génération de meshes **texturés** dans l'assistant de Studio. La documentation de l'API ne dit rien des droits, des limites de triangles ni des cartes PBR. Chez Meshy, les plans payants donnent la **propriété** des assets (« Private & Customer owned »), et le plan gratuit les met sous **CC BY 4.0**. Tripo n'a pas pu être vérifié à la source. Pour un décor photoréaliste, ces outils servent surtout de base de blocage ou de petits objets à retravailler.

### Cited Findings
- Roblox : selon un article de la Machine Herald qui s'appuie sur TechCrunch, Mesh Generation « produces fully textured 3D objects directly inside a game world from natural-language prompts, replacing placeholder assets during early development ». Annonce du 16 avril 2026. Cube rendu open source en mars 2025 ; il alimente une Mesh Generation API dans Studio. — [Machine Herald (cite TechCrunch, 16 avril 2026)](https://machineherald-io.pages.dev/article/2026-04/27-roblox-studio-goes-agentic-with-planning-mode-mesh-generation-and-self-testing-ai-assistant) ; dépôt du modèle : [github.com/Roblox/cube](https://github.com/Roblox/cube)
- GenerationService : « Service that allows developers to generate 3D objects from text prompts. » `GenerateMeshAsync` est marqué « Deprecated » ; `GenerateModelAsync` (capacité DynamicGeneration) accepte un prompt, un schéma (« Car5 », « Body1 » ou un schéma maison) et une image en option. La page ne dit rien des textures, des triangles, des limites d'appel ni des droits. — [Roblox Engine API, GenerationService](https://create.roblox.com/docs/reference/engine/classes/GenerationService)
- Meshy, plan gratuit : « If you are on a free plan, we grant you a CC BY 4.0 license instead » ; « CC BY 4.0 license (commercial use with attribution) ». — [Meshy Pricing](https://www.meshy.ai/pricing)
- Meshy, plans payants : « If you are on a premium plan, you own all assets you create with Meshy » ; Pro, Premium, Ultra et Studio sont « Private & Customer owned ». Prix : Pro 20 USD par mois (1 000 crédits), Premium 40 USD, Ultra 100 USD, Studio 70 USD. La FAQ dit « premium plan » alors que le tableau donne la même licence de Pro à Studio : ambiguïté sur Pro. — [Meshy Pricing](https://www.meshy.ai/pricing)
- Tripo, source tierce seulement (revue du 31 mai 2026) : « Paid plans include commercial-use rights. Confirm the latest license terms before publishing » ; plans payants « around $10/month ». Le site de Tripo n'a pas pu être lu. — [ToolDirectory, Tripo](https://tooldirectory.ai/tools/tripo)

### Inferences
- **Pour le photoréalisme**, la génération IA donne au mieux des objets secondaires (boîtes, débris, sacs, objets de fond) qu'il faut ensuite retopologiser, déplier en UV et re-texturer avec des matériaux CC0 cohérents avec le kit. Le béton, les piliers et les murs se font mieux avec un kit modulaire et des matériaux tuilables (section 6).
- **Meshy gratuit (CC BY 4.0)** impose une attribution à Meshy et, selon la page, une mention « in the description of your commercial page ». À éviter ; prendre un plan payant le mois où l'on génère.
- **Mesh Generation de Roblox :** c'est le chemin le plus intégré (l'asset naît déjà sur Roblox, sans question de redistribution d'une licence tierce), mais ses droits et sa qualité ne sont pas documentés. À tester sur un objet, et à vérifier dans les conditions Roblox applicables aux outils d'IA avant de l'utiliser dans le jeu publié.
- **Protection par le droit d'auteur :** un asset produit par IA pourrait ne pas être protégeable (question non recherchée ici). Un concurrent pourrait alors le copier sans recours. **Avocat.**

### Gaps
- Droits d'usage commercial, limite de triangles, cartes PBR et coût de Mesh Generation et de Cube dans Studio : **non trouvés** (le DevForum était en maintenance et la référence de l'API n'en parle pas).
- **Tripo** : conditions officielles non lues (plusieurs pages de tripo3d.ai ont échoué). La licence du plan gratuit (on dit souvent CC BY 4.0 et modèles publics) est **non vérifiée**.
- Pas de comparaison de qualité sourcée entre Meshy, Tripo et Cube pour des objets réalistes.

---

## 5. Sons : Freesound, Sonniss GDC, autres banques libres, et règles audio de Roblox en 2026

### Takeaway
Utilisables pour un jeu qui rapporte des Robux : Freesound **CC0** (rien à faire) et **CC BY** (crédits obligatoires), Sonniss GDC (commercial, sans attribution, mais pas de revente des sons tels quels) et Pixabay (sans attribution, pas de redistribution standalone). **Exclus :** CC BY-NC et l'ancienne Sampling+. Sur Roblox : formats mp3, ogg, wav ou flac, moins de 20 Mo et 7 minutes, 48 kHz au plus, **2 000 imports gratuits par 30 jours** avec identité vérifiée (100 sans), audio privé par défaut.

### Cited Findings
- Freesound, CC0 : « for the "zero" license you can do pretty much what you want with the sound ». — [Freesound FAQ](https://freesound.org/help/faq/)
- Freesound, Attribution : « For "attribution" you should always mention the original creators of the sounds when you use them. » Modèle de crédit : « "sound1" by user1 ( http://freesound.org/s/soundID/ ) licensed under … ». — [Freesound FAQ](https://freesound.org/help/faq/)
- Freesound, NonCommercial : « you can't earn any money with the piece of work you create! » Sampling+ : « being removed by creative commons because it's a difficult license to interpret ». — [Freesound FAQ](https://freesound.org/help/faq/)
- Sonniss, licence des bundles GDC (sans date ni année) : « Licensee may use and modify the licensed sound effects for personal and commercial projects » ; « without attribution to the original creator » ; « unlimited number of projects » ; « Licensee may not sell any of the sound effects as they come » ; « (Although the sound effects may be sold as incorporated into licensee project) ». Rien sur l'IA. — [Sonniss GDC Bundle License](https://sonniss.com/gdc-bundle-license/)
- Pixabay : sans attribution ; pas de distribution « on a Standalone basis » ; la page ne parle pas des jeux vidéo. — [Pixabay License Summary](https://pixabay.com/service/license-summary/)
- Roblox, format : « It's a single track/stream in either .mp3, .ogg, .wav or .flac format » ; « less than 20 MB in size and 7 minutes in duration » ; 48 kHz au plus ; mono, stéréo, 3.0 ou 5.1. — [Roblox Creator Hub, Audio assets](https://create.roblox.com/docs/audio/assets)
- Roblox, quotas : « you can import 2,000 free audio assets per 30 days » (identité vérifiée) et 100 sans vérification ; la limite quotidienne est remplacée par cette limite mensuelle. La page ne mentionne aucun frais. — [Roblox Creator Hub, Audio assets](https://create.roblox.com/docs/audio/assets)
- Roblox, modération et droits : il faut avoir les droits légaux sur l'audio ; « After the audio assets pass moderation, you can reuse them in any project on the platform » ; audio privé par défaut ; les effets sonores « can be distributed on the Creator Store » ; l'audio du Creator Store est « free-to-use ». — [Roblox Creator Hub, Audio assets](https://create.roblox.com/docs/audio/assets)

### Inferences
- **Pile sonore conseillée :** Sonniss GDC (ambiances industrielles, néons qui grésillent, ventilation, gouttes, échos de béton, portes métalliques), Freesound CC0 en priorité, CC BY seulement avec crédits. Enregistrements maison (vrai stationnement souterrain : réverbération, pas sur béton, portes coupe-feu) : ce sont nos créations, sans question de licence.
- **Ne jamais publier un son Sonniss ou Pixabay sur le Creator Store** : ce serait les revendre ou redistribuer « as they come ». Laisser l'audio privé et accorder la permission au seul jeu.
- **Identité vérifiée** sur le compte qui importe (2 000 par mois contre 100). Un jeu d'horreur, avec ses nombreuses variantes de sons, peut dépasser 100 par mois.
- **Licence accordée à Roblox** (apprentissage automatique compris, section 2) : elle vaut aussi pour l'audio. La licence Sonniss lue ne mentionne pas l'IA, et Freesound CC0 ne pose pas de problème. **Avocat** pour les banques payantes qui interdisent l'IA.
- **Musique :** la musique sous licence du Creator Store est gratuite, mais seulement sur Roblox. Pour une bande-annonce hors Roblox (YouTube, TikTok), il faut une autre licence (non vérifié ici).

### Gaps
- Je n'ai pas lu la licence du bundle GDC de 2026 en particulier : la page lue est générique, sans année. Vérifier le PDF de licence fourni avec chaque bundle.
- Autres banques libres (Zapsplat, Soundly gratuit, BBC Sound Effects, qui est non commercial) : non vérifiées.
- Conditions de la musique sous licence du Creator Store (APM, Monstercat) hors Roblox : non lues (DevForum en maintenance).

---

## 6. Pipeline Blender vers Roblox Studio pour des assets PBR réalistes (kit modulaire, textures, collisions, LOD, mémoire sur téléphone)

### Takeaway
Exporter en **FBX ou glTF** (OBJ ne porte ni les PBR ni la hiérarchie), à 20 000 triangles au plus par mesh, **un seul matériau par MeshPart**, UV en 0–1. **Normal maps au format OpenGL**, roughness et metalness en niveaux de gris sur 8 bits, et **pas de carte d'AO** : il faut la cuire dans la ColorMap. Depuis le 30 janvier 2026, Roblox affiche jusqu'en 4K avec du *texture streaming*. Pour des téléphones, la règle reste la réutilisation : **MaterialVariant tuilables** pour les grandes surfaces (béton, sol), SurfaceAppearance pour les objets uniques, textures partagées entre pièces, collisions en Box, ombres limitées.

### Cited Findings

**Formats et import**
- « You can import meshes in the .fbx, .obj, or .gltf format » (.glb aussi). Seuls .fbx et .gltf/.glb prennent en charge plusieurs objets, les hiérarchies, les textures PBR, les rigs, l'animation et les couleurs de sommets. — [Roblox 3D Importer](https://create.roblox.com/docs/art/modeling/3d-importer)
- Réglages d'import : World Forward, World Up, **Scale Unit** (par défaut, Studs), Merge Meshes, Import as Package, Upload to Roblox, Set Pivot to Scene Origin, Anchored, Make Double Sided (plus coûteux). La page ne dit pas si un SurfaceAppearance est créé automatiquement (non vérifié). — [Roblox 3D Importer](https://create.roblox.com/docs/art/modeling/3d-importer)
- Export FBX depuis Blender : « change Path Mode to Copy, then toggle the Embed Textures button » ; « Set Transform > Apply Scalings to FBX Unit Scale » ; une capture montre « Transform Scale set to .01 » ; désactiver Add Leaf Bones. — [Roblox Export requirements](https://create.roblox.com/docs/art/modeling/export-requirements)
- Mesure faite sur le dépôt d'Adrien (Break a Gem, CLAUDE.md, « Pièges ») : avec l'export `axis_forward="-Z", axis_up="Y"`, Blender (x, y, z) arrive dans Roblox en (−x, z, y), « à 100 studs le mètre, chaque MeshPart recentré sur sa boîte » ; `py scripts/upload-bags.py --keep` permet de corriger les axes sans re-téléverser. — [CLAUDE.md de Break a Gem](https://github.com/AMoncade/BreakAGem/blob/main/CLAUDE.md)

**Échelle**
- Le tableau des unités de Roblox donne 1 stud = 28 cm (0,28 m). « Internally, the Roblox physics engine does not use unit conversions » ; on peut choisir sa propre interprétation, mais Roblox conseille les unités standard. — [Roblox Units](https://create.roblox.com/docs/physics/units)

**Contraintes de mesh**
- « Individual meshes can not exceed 20,000 triangles » ; géométrie « watertight » ; « Meshes cannot be 0 thickness ». — [Roblox Mesh specifications](https://create.roblox.com/docs/art/modeling/specifications)
- « Mesh objects can only have one material assigned » ; « All UVs must be created within a 0:1 space. » — [Roblox Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)

**Textures et SurfaceAppearance**
- Formats : .png, .jpg, .tga, .bmp. Albedo « RGB (24-bit) » ; normal « RGB (24-bit); Roblox only supports OpenGL format - Tangent Space normal maps » ; roughness, metalness et masque émissif « Single Channel Grayscale (8-bit) ». — [Roblox Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)
- Résolutions conseillées : 256 × 256 pour environ 5 × 5 studs, 512 × 512 pour 10 × 10, 1024 × 1024 pour 20 × 20. Les parts par défaut de Roblox mettent 1024 sur une face de 8 × 8 studs. « As a game loads, the engine automatically starts with lower quality versions of the texture and ramps up quality based on device resources. » — [Roblox Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)
- 4K : rendu « up to 4k resolution (4096 x 4096) » dans les jeux publiés depuis le **30 janvier 2026**, par le Texture Streaming. Import possible jusqu'en 8K (stocké, puis transcodé en 4K). Cela concerne les cartes Color, Normal, Metalness et Roughness des SurfaceAppearance, ainsi que MeshPart, Texture, Decal et MaterialVariant. Le streaming « will automatically serve a lower-resolution version that fits its memory budget ». — [DevForum, 4k Texture Rendering](https://devforum.roblox.com/t/4k-texture-rendering/4316229)
  - Contradiction datée : un guide DevForum de **juillet 2025** donne « Max texture size is 1024x1024 » ; il est antérieur au passage à la 4K. — [DevForum, Optimization For Roblox Environments](https://devforum.roblox.com/t/optimization-for-roblox-environments/3844846)
- SurfaceAppearance : propriétés ColorMap, Color (teinte), AlphaMode, EmissiveMaskContent, EmissiveTint, EmissiveStrength, plus les cartes normal, roughness et metalness. « Studio only uses the metalness workflow ». « In general, you can't modify SurfaceAppearance properties by scripts during a game. » « Tinting does not affect performance and you can save on memory by reusing a single color map with different tints. » — [Roblox PBR textures (SurfaceAppearance)](https://create.roblox.com/docs/art/modeling/surface-appearance)
- MaterialVariant : « Use MaterialVariant for reusable, tileable materials » (paraphrase) ; « Custom materials are represented by MaterialVariant instances within MaterialService » ; réglage par « Studs Per Tile » ; applicable aux parts et au terrain, « per-part or globally ». — [Roblox Materials](https://create.roblox.com/docs/parts/materials)

**Performance, collisions, LOD**
- Mémoire : « Reuse the same asset ID across objects » ; « a 1024x1024 pixel texture consumes four times the graphics memory of a 512x512 texture » ; teinter une seule texture avec SurfaceAppearance.Color. — [Roblox, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Draw calls : « Objects like decals, textures, and particles don't batch well and introduce additional draw calls. » — [Roblox, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Collisions : « Box has the lowest memory overhead » ; « It's generally safe to set any small anchored part's collision fidelity to Box » ; « For large and very complex objects, build out custom collisions using invisible parts when possible. » Couper CanCollide, CanTouch et CanQuery sur le décor non interactif. — [Roblox, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- LOD : RenderFidelity « allows meshes to fall back to less complex alternatives » quand la distance augmente. Le streaming d'instances est actif par défaut pour les nouvelles places. — [Roblox, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Lumières : « Handling shadows is an expensive process » ; « Limit the range and angle of light instances » ; couper les ombres des petites pièces et des objets mobiles. — [Roblox, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Guide de BlackoutCedar (DevForum, 27 juillet 2025) : garder la plupart des assets en 512 ou 256 ; regrouper les pièces par jeu de textures (l'exemple d'ascenseur passe « from 42 to around 8 max » MeshParts) ; « In 95% of cases everything should be set to performance » pour RenderFidelity ; viser environ **500 draw calls** sur les appareils modestes. — [DevForum, Optimization For Roblox Environments](https://devforum.roblox.com/t/optimization-for-roblox-environments/3844846)

### Inferences

**Échelle pour un décor réaliste**
- Deux conventions possibles : 1 stud = 0,28 m (la valeur officielle) ou une échelle calée sur la taille des avatars. Le plus simple : modéliser dans Blender en mètres réels, puis régler un facteur unique à l'import (Scale Unit) ou à l'export. Par exemple, à 0,28 m le stud, un plafond de stationnement de 2,5 m fait environ 8,9 studs, et une place de 2,5 × 5,5 m environ 9 × 20 studs.
- La hauteur d'un avatar R15 en studs n'a pas été sourcée ici. À **mesurer dans Studio** avec le personnage du jeu avant de figer l'échelle du kit : un écart d'échelle rend un décor réaliste « faux » à l'œil.

**Kit modulaire du stationnement**
- Grille métrique fixe (par exemple 4 m, avec des sous-multiples de 1 m et 0,5 m). Pièces : sol, mur, mur avec porte, pilier, poutre, rampe, bordure, chemin de câbles, tuyaux droits et coudés, rail de néon, bande peinte.
- Les **grandes surfaces** (sol, murs, plafond en béton) sur des **MaterialVariant tuilables** (Studs Per Tile), à partir de textures CC0 de Poly Haven ou d'ambientCG : une seule texture en mémoire pour des milliers de studs carrés.
- Les **détails** (bords de piliers, bandes jaunes et noires, plinthes, grilles, panneaux) sur une ou deux ***trim sheets*** en SurfaceAppearance de 2048 ou 4096, partagées par toutes les pièces du kit. Cela applique « Reuse the same asset ID ».
- Une seule texture de couleur grise teintée (SurfaceAppearance.Color) pour les variantes : peinture de pilier, portes.

**Densité de texels**
- Les recommandations de Roblox (256 px pour 5 studs, 512 pour 10, 1024 pour 20) reviennent toutes à environ **51 px par stud**, soit environ 180 px/m à 0,28 m le stud.
- En vue à la première personne, on peut viser plus pour les surfaces proches de l'œil, comme les parts par défaut de Roblox (1024 px pour 8 studs, soit 128 px par stud), en laissant le Texture Streaming réduire sur les téléphones.

**Cartes et cuisson**
- SurfaceAppearance n'a **pas de carte d'occlusion ambiante** (seulement Color, Normal, Roughness, Metalness et le masque émissif) : cuire l'AO dans Blender (Cycles, Bake > Ambient Occlusion) et la multiplier dans la ColorMap.
- Normal maps : exporter en **OpenGL**. Les textures d'ambientCG et de Poly Haven sont disponibles en variante GL ; ne pas prendre la variante DX, sinon le relief s'inverse. La disponibilité des deux variantes n'a pas été vérifiée sur les pages lues.
- Cuisson du haut vers le bas (high vers low) pour les objets complexes (tuyaux, épaves), sous les 20 000 triangles par MeshPart.
- Néons et panneaux de sortie : le masque émissif (EmissiveMaskContent et EmissiveStrength) d'une SurfaceAppearance, plus une PointLight ou SurfaceLight sans ombres et à portée courte.

**Saleté et décalques**
- Les Decal et Texture ajoutent des draw calls. Privilégier la saleté **cuite dans la trim sheet** ou dans des variantes de MaterialVariant (béton propre, taché, mouillé).
- Garder les décalques pour quelques endroits marquants (flaques, traînées, graffitis narratifs), sur des quads en MeshPart avec SurfaceAppearance (AlphaMode Transparency).

**Collisions**
- Tout le décor en Box (ou Hull pour les épaves).
- Collisions du stationnement faites de parts invisibles simples (sol, murs, piliers), les MeshParts visuels avec CanCollide, CanTouch et CanQuery à false. Exception : ce que le jeu doit viser par raycast (lampe torche, interactions), qui garde CanQuery.

**LOD et streaming**
- RenderFidelity Performance par défaut, Precise pour les seules pièces très grandes et proches.
- Le streaming d'instances, actif par défaut, convient à un stationnement découpé en niveaux (garder ce qui est vu d'un étage dans un même rayon).

**Mémoire sur téléphone : budget de départ**
- 1 trim sheet en 4K pour le béton et le métal, 1 en 2K pour la signalétique, 3 à 5 MaterialVariant (béton de sol, mur, plafond, asphalte, métal peint), des objets en 512 à 1024.
- Le streaming s'occupe des téléphones, mais **les ordres de grandeur restent** : une 1024 coûte 4 fois une 512.

**Automatisation avec le MCP Blender et Claude Code**
- Script de kit (comme `tools/blender/lobby_kit.py` dans Break a Gem) : pièces paramétriques, UV vers la trim sheet, nommage et export FBX par pièce.
- Script de cuisson (AO vers ColorMap, normal high vers low).
- Script de téléversement qui écrit les assetIds dans une Config, avec le registre des licences de la section 2.

### Gaps
- **Import automatique des cartes PBR** en SurfaceAppearance par l'importateur 3D (FBX ou glTF) : non confirmé par la documentation lue. À tester sur un premier objet.
- **LOD personnalisés** (importer ses propres niveaux de détail) : rien trouvé ; seul RenderFidelity, automatique, est documenté.
- **Budgets PBR chiffrés** pour les téléphones : la page des textures renvoie à des « PBR texture budgets » sans les donner.
- Hauteur des avatars R15 en studs, et échelle habituelle des jeux réalistes sur Roblox : non sourcées.
- Les modes Organic, Fixed et Overlay des MaterialVariant n'apparaissent pas dans la page lue (non vérifié).
- Les guides du DevForum sur les décors réalistes (trim sheets sur Roblox, retours d'expérience de jeux d'horreur réalistes) n'ont pas pu être lus au-delà d'un seul : le forum redirigeait vers une page de maintenance pendant la recherche.
- L'éclairage (Future, atmosphère, post-traitement) est hors de ce périmètre ; voir la note voisine `rendu_realiste_roblox.md`.
