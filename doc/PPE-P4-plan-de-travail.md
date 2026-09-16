# Projet 4 — Dépannage et diagnostic d'un poste en panne

**Plan de travail** — PPE IT Essentials (CFC 187), classe E1B, GIT
Étudiant : Paul « Lami » Giocanti — Date de démarrage : 16.09.2026

---

## 0. Ce qu'on va produire (et pourquoi)

Le sujet est noté sur 4 critères. Voilà ce qui rapporte des points et comment on le couvre :

| Critère | Poids | Comment on le gagne |
|---|---|---|
| Démarche de diagnostic méthodique | 30 % | On applique **la même méthode en 6 étapes** aux 3 pannes, et on montre les hypothèses **écartées**, pas seulement la bonne |
| Utilisation pertinente des outils | 20 % | 3 pannes = 3 familles d'outils différentes (journaux d'événements / gestionnaire de périphériques / outils de performance au démarrage) |
| Résolution effective du problème | 25 % | Preuve **avant / après** pour chaque panne (le service tourne, la carte réseau ping, le démarrage est redescendu de X secondes) |
| Qualité du rapport d'intervention | 25 % | Format **ticket** professionnel, captures encadrées de texte, section « problèmes rencontrés » |

**Périmètre retenu** : 3 pannes simulées sur la VM Windows 11 Pro **PC01-PG** (celle du Projet 3), avec snapshot de sécurité avant de casser quoi que ce soit.

- **Panne A** — un service système en échec (spouleur d'impression)
- **Panne B** — un pilote manquant (carte réseau)
- **Panne C** — un démarrage anormalement lent

---

## 1. Vocabulaire — à lire une fois, tout le reste en découle

| Terme | Ce que ça veut dire concrètement |
|---|---|
| **Service Windows** | Un programme qui tourne en arrière-plan, sans fenêtre, souvent démarré avant même que tu ouvres ta session. Exemple : le spouleur d'impression, qui met les documents en file d'attente avant de les envoyer à l'imprimante. |
| **Spouleur (spooler)** | Le service `Spooler`. Sans lui : plus aucune imprimante visible, plus rien qui s'imprime. C'est LA panne la plus courante en support d'entreprise. |
| **Pilote (driver)** | Le petit logiciel qui sert de traducteur entre Windows et un composant matériel (carte réseau, carte son, GPU). Sans pilote, le matériel est physiquement présent mais inutilisable. |
| **Observateur d'événements** (`eventvwr.msc`) | Le « journal de bord » de Windows. Chaque démarrage, plantage, échec de service y laisse une ligne horodatée avec un numéro (**ID d'événement**). C'est le premier réflexe d'un technicien : lire les journaux avant de toucher à quoi que ce soit. |
| **ID d'événement** | Le numéro qui identifie un type d'événement. Ex. **7000** = « un service n'a pas pu démarrer », **100** = « durée du démarrage de Windows ». Un ID se google : c'est une clé de recherche universelle. |
| **Gestionnaire de périphériques** (`devmgmt.msc`) | La liste de tout le matériel vu par Windows. Un **point d'exclamation jaune** = matériel détecté mais qui ne fonctionne pas, avec un **code d'erreur** (ex. code 28 = pilote non installé). |
| **Registre Windows** (`regedit`) | La grande base de configuration de Windows. Les services y ont chacun une clé qui contient notamment `ImagePath` = le chemin du fichier `.exe` à lancer. Si ce chemin est faux, le service ne démarre plus. |
| **Snapshot (instantané)** | Une photo de l'état complet de la VM à un instant T. On peut y revenir en 10 secondes. C'est notre filet de sécurité. |
| **`sc.exe`** | Commande Windows pour interroger/piloter les services (`sc query`, `sc qc`, `sc start`). |
| **Élévation / « en tant qu'administrateur »** | Beaucoup de ces outils refusent d'agir sans droits admin. Si une commande répond « Accès refusé », c'est presque toujours ça. |

---

## 2. La méthode de diagnostic — le cœur du projet (30 % de la note)

On utilise les **6 étapes du dépannage** du référentiel Cisco IT Essentials / CompTIA. C'est la méthode enseignée dans le cours, donc c'est celle que le formateur attend. On l'applique **à l'identique** aux 3 pannes — c'est justement la répétition qui prouve la méthode.

1. **Identifier le problème** — recueillir le symptôme tel que l'utilisateur le décrit, poser des questions fermées, relever ce qui a changé récemment. *Pourquoi :* un ticket qui dit « ça marche pas » n'est pas exploitable ; on ne peut pas vérifier une réparation si on n'a pas décrit précisément la panne.
2. **Établir une théorie des causes probables** — lister 3 à 5 causes plausibles, de la plus simple à la plus complexe. *Pourquoi :* sans liste écrite, on part dans tous les sens et on rate l'évidence.
3. **Tester la théorie** — vérifier chaque hypothèse une par une, avec un outil, et noter le résultat. *Pourquoi :* une hypothèse écartée est une information, pas une perte de temps — c'est exactement ce que le sujet demande de documenter.
4. **Établir un plan d'action et appliquer la solution** — décider quoi faire, évaluer le risque, sauvegarder si nécessaire, puis agir.
5. **Vérifier le fonctionnement complet et prévenir** — retester le service ET ce qui l'entoure, puis proposer une mesure pour que ça ne se reproduise pas.
6. **Documenter** — le ticket d'intervention. C'est l'étape que 90 % des gens bâclent, et elle vaut 25 % ici.

> **Règle d'or du TP :** toujours de la cause la plus simple vers la plus complexe. On ne réinstalle pas Windows avant d'avoir vérifié si le service est simplement arrêté.

**Important pour l'apprentissage :** c'est toi qui poses la panne, donc tu connais la réponse. Joue quand même le jeu à fond : une fois la panne posée, **repars du symptôme** et déroule les 6 étapes comme si tu ne savais rien. Les hypothèses écartées doivent être de vraies vérifications faites à l'écran (avec capture), pas des phrases écrites après coup.

---

## 3. Conventions de travail

- **Dossier de travail** : `C:\Users\Lami\Documents\PPE-P4\` avec les sous-dossiers `captures\`, `scripts\`, `doc\`
- **Captures** : `NN-sujet.png` (ex. `03-event-7000-spooler.png`), outil Screenpresso
- **Numérotation des tickets** : `TICKET-2026-041` (panne A), `-042` (panne B), `-043` (panne C)
- **Machine de test** : VM `PC01-PG`, Windows 11 Pro 24H2, utilisateur `tech.pg`, VMware Workstation, réseau VMnet8 (NAT)
- **Dépôt final** : `ppe-projet4-depannage-diagnostic` (GitHub, compte L4ami)

---

## 4. Phase 0 — Préparer le poste de test

Avant de casser : on prend le filet, et on relève **l'état sain**. Sans état de référence, impossible de prouver ensuite qu'on a réparé.

- [ ] Démarrer la VM `PC01-PG` et ouvrir la session `tech.pg`
- [ ] Créer les dossiers `PPE-P4\captures`, `PPE-P4\scripts`, `PPE-P4\doc`
- [ ] **Snapshot VMware** nommé `P4-etat-sain-avant-pannes` (VM > Snapshot > Take Snapshot)
- [ ] Relever l'état sain avec le script `p4-etat-reference.ps1` (fourni à l'étape suivante) : liste des services critiques, état de la carte réseau, durée du dernier démarrage
- [ ] **capture** `01-snapshot-cree.png` — le gestionnaire de snapshots montrant `P4-etat-sain-avant-pannes`
- [ ] **capture** `02-etat-reference.png` — la sortie du script d'état de référence

---

## 5. Panne A — Service en échec (spouleur d'impression)

**Symptôme joué :** « Depuis ce matin je ne peux plus imprimer, mes imprimantes ont disparu de la liste. »

| Étape | Ce qu'on fait | Outil |
|---|---|---|
| Simulation | Casser le chemin du binaire du service `Spooler` dans le registre | `regedit` / script |
| 1. Identifier | Constater : aucune imprimante dans Paramètres, échec à l'impression d'une page de test | Paramètres Windows |
| 2. Théoriser | Imprimante débranchée / pilote d'imprimante HS / service arrêté / service en échec de démarrage / profil utilisateur | — |
| 3. Tester | Journal système filtré sur les erreurs → chercher l'ID **7000** ; `services.msc` → état du spouleur ; `sc qc spooler` → comparer le chemin avec la référence | Observateur d'événements, `services.msc`, `sc` |
| 4. Résoudre | Remettre le bon `ImagePath`, redémarrer le service | `regedit` / `sc config` |
| 5. Vérifier | Service « En cours d'exécution », imprimantes revenues, page de test imprimée (vers PDF) | `services.msc` |
| 6. Documenter | Ticket TICKET-2026-041 | — |

**Hypothèses à écarter explicitement** (avec capture à l'appui) : câble/imprimante hors ligne, dépendance `RPC` arrêtée, démarrage du service passé en « Désactivé ».

---

## 6. Panne B — Pilote manquant (carte réseau)

**Symptôme joué :** « Plus d'accès réseau ni Internet, l'icône réseau affiche un globe barré. »

| Étape | Ce qu'on fait | Outil |
|---|---|---|
| Simulation | Désinstaller le périphérique réseau et son paquet pilote | Gestionnaire de périphériques |
| 1. Identifier | `ipconfig` → plus d'adresse IPv4 valide ; `ping` passerelle → échec | Invite de commandes |
| 2. Théoriser | Câble/VMnet déconnecté / DHCP en panne / IP en conflit / pare-feu / **pilote absent** | — |
| 3. Tester | Vérifier l'état de la carte dans VMware, puis Gestionnaire de périphériques → point d'exclamation, **code 28**, onglet Événements du périphérique | Gestionnaire de périphériques |
| 4. Résoudre | « Rechercher les modifications sur le matériel » → réinstallation du pilote depuis le magasin de pilotes | `devmgmt.msc` / `pnputil` |
| 5. Vérifier | `ipconfig /all` → IP récupérée, `ping 8.8.8.8` et `ping` vers l'hôte OK | Invite de commandes |
| 6. Documenter | Ticket TICKET-2026-042 | — |

**Hypothèses à écarter explicitement** : carte virtuelle déconnectée dans VMware, service DHCP client arrêté, adresse IP fixe erronée, pare-feu bloquant.

---

## 7. Panne C — Démarrage anormalement lent

**Symptôme joué :** « Le poste met plusieurs minutes avant d'être utilisable le matin. »

| Étape | Ce qu'on fait | Outil |
|---|---|---|
| Mesure initiale | Relever la durée de démarrage saine : journal `Diagnostics-Performance`, **ID 100** | Observateur d'événements |
| Simulation | Ajouter plusieurs programmes lourds au démarrage (dossier Démarrage + clé `Run` du registre) | script |
| 1. Identifier | Chronométrer, comparer à la mesure initiale | ID 100 |
| 2. Théoriser | Disque saturé / RAM insuffisante / trop de programmes au démarrage / service qui tarde / pilote lent / malware | — |
| 3. Tester | IDs **101** (application lente), **102** (pilote lent), **103** (service lent) ; onglet **Démarrage** du gestionnaire des tâches (colonne « Impact ») ; espace disque et RAM | Observateur d'événements, Gestionnaire des tâches |
| 4. Résoudre | Désactiver les éléments de démarrage inutiles | Gestionnaire des tâches / `msconfig` |
| 5. Vérifier | Nouvelle mesure ID 100 → **gain chiffré en secondes** | Observateur d'événements |
| 6. Documenter | Ticket TICKET-2026-043 | — |

**Hypothèses à écarter explicitement** : disque système plein, RAM saturée, antivirus tiers, pilote graphique lent.

> Si le journal `Diagnostics-Performance` est vide sur la VM (ça arrive), on bascule sur une mesure chronométrée reproductible + l'onglet Démarrage. On documentera ce contournement dans la section « problèmes rencontrés ».

---

## 8. Livrables

- [ ] `README.md` — présentation du projet, contexte, sommaire
- [ ] `rapport-intervention.md` — méthodologie + les 3 tickets complets + hypothèses écartées + problèmes rencontrés + recommandations préventives
- [ ] `scripts/` — scripts PowerShell de simulation, d'état de référence et de restauration
- [ ] `captures/` — captures numérotées, **chacune encadrée de texte** dans le rapport : une phrase de contexte au-dessus, la lecture de l'image en dessous
- [ ] Dépôt GitHub `ppe-projet4-depannage-diagnostic` publié
- [ ] Vérification finale : chaque capture citée dans le rapport existe, chaque ticket a sa preuve avant/après

---

## 9. Ordre d'exécution

Phase 0 → Panne A → Panne B → Panne C → Rapport → GitHub.

Chaque panne est traitée **complètement** (simulation → résolution → captures) avant de passer à la suivante, et on **ne restaure pas le snapshot entre les pannes** : le snapshot est là uniquement en cas d'accident.
