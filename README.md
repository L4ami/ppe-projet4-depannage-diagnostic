# 🧰 Dépannage et diagnostic d'un poste Windows 11 en panne

![Windows 11](https://img.shields.io/badge/Windows_11_Pro-24H2-0078D4?logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-scripts-5391FE?logo=powershell&logoColor=white)
![Event Viewer](https://img.shields.io/badge/diagnostic-Observateur_d'%C3%A9v%C3%A9nements-4B5563)
![VMware](https://img.shields.io/badge/VMware_Workstation-snapshots-607078?logo=vmware&logoColor=white)
![Statut](https://img.shields.io/badge/statut-termin%C3%A9-brightgreen)

> **En une phrase :** j'ai diagnostiqué et réparé trois pannes réelles sur un poste Windows 11 (impression impossible, plus de réseau, démarrage très lent) avec une méthode structurée : 18 hypothèses testées, et un démarrage ramené de 101,9 s à 42,6 s.

Ce dépôt est écrit pour être compris **même sans rien connaître** au dépannage : tous les mots techniques sont expliqués.
👉 Le rapport d'intervention complet, ticket par ticket, est dans [`doc/rapport-intervention.md`](doc/rapport-intervention.md).

> **Projet 4/5** du PPE IT Essentials, module CFC 187 *« Mettre en service un poste de travail ICT avec le système d'exploitation »*, classe E1B, Geneva Institute of Technology (GIT), septembre 2026.

**Date :** 16 septembre 2026

---

## 🎯 Objet

Diagnostiquer et résoudre trois pannes distinctes sur un poste Windows 11 Pro, en appliquant une méthodologie de dépannage structurée, en exploitant les outils de diagnostic intégrés au système, et en produisant un rapport d'intervention professionnel documentant **chaque hypothèse testée, y compris celles écartées**.

## 🖥️ Poste de test

| | |
|---|---|
| Machine | PC01-PG — Windows 11 Pro 24H2 (build 10.0.26100) |
| Environnement | VMware Workstation, réseau VMnet8 (NAT) |
| Compte | tech.pg (administrateur local) |
| Adressage | 192.168.190.135 / passerelle 192.168.190.2 |
| Filet de sécurité | Snapshot `P4-etat-sain-avant-pannes` pris avant toute intervention |

## ✅ Les trois interventions

| Ticket | Panne | Cause identifiée | Résolution | Preuve |
|---|---|---|---|---|
| **2026-041** | Impossible d'imprimer | Valeur `ImagePath` du service `Spooler` altérée : `spoolsvc.exe` au lieu de `spoolsv.exe` | `sc config` + redémarrage du service | Service `Running` après redémarrage autonome, plus aucun événement 7000 |
| **2026-042** | Perte totale de connectivité | Périphérique réseau Intel 82574L désinstallé de l'inventaire système | Rescan matériel, pilote réinstallé depuis le magasin de pilotes | IP obtenue par DHCP, passerelle et Internet joignables à 0 % de perte |
| **2026-043** | Démarrage anormalement lent | Trois entrées `Run` lançant un script PowerShell masqué | Désactivation puis suppression des entrées et du script | Démarrage ramené de 101,9 s à 42,6 s (**− 58 %**) |

**18 hypothèses formulées — 3 confirmées, 14 écartées avec preuve, 1 rendue sans objet.**

## 📊 Résultat chiffré de la panne C

| Indicateur | Poste sain | En panne | Après réparation |
|---|---|---|---|
| Durée totale de démarrage | 44,8 s | 101,9 s | **42,6 s** |
| Phase noyau, pilotes et services | ≈ 19 s | 18,2 s | 18,1 s |
| Phase après ouverture de session | 25,6 s | 83,8 s | **24,5 s** |

## 📁 Contenu du dépôt

```
.
├── README.md                     ce fichier
├── doc/
│   ├── rapport-intervention.md   rapport complet : 3 tickets, hypothèses, captures commentées
│   ├── problemes-rencontres.md   journal des incidents rencontrés pendant l'intervention
│   └── PPE-P4-plan-de-travail.md plan de travail initial
├── scripts/
│   ├── p4-etat-reference.ps1     relevé de l'état sain du poste
│   ├── p4-panne-A-simuler.ps1    simulation du service en échec
│   ├── p4-mesure-demarrage.ps1   mesure des durées de démarrage (événement 100)
│   ├── p4-panne-C-simuler.ps1    simulation des programmes de démarrage indésirables
│   └── p4-panne-C-nettoyer.ps1   suppression des entrées et du script associé
└── captures/                     40 captures d'écran numérotées, référencées dans le rapport
```

Le document principal est **[`doc/rapport-intervention.md`](doc/rapport-intervention.md)**.

## 🧪 Méthodologie appliquée

Les six étapes du dépannage (référentiel Cisco IT Essentials / CompTIA) ont été appliquées à l'identique aux trois pannes : identifier le problème, établir une théorie des causes probables, tester la théorie, appliquer la solution, vérifier le fonctionnement complet, documenter.

Le rapport détaille en outre une méthode de **production d'hypothèses par chaîne de dépendances** — décomposer la fonction en panne en maillons successifs, du plus physique au plus logiciel, et tester dans l'ordre. Trois chaînes y sont établies et réutilisables : panne réseau, service qui refuse de démarrer, poste lent au démarrage.

## 🛠️ Outils de diagnostic employés

Observateur d'événements (journaux Système et Diagnostics-Performance), `services.msc`, `sc qc`, Gestionnaire de périphériques, Gestionnaire des tâches, registre Windows (clés de services et clés `Run`), `ipconfig`, `ping`, PowerShell.

Identifiants d'événements exploités : **7000** (échec de démarrage d'un service), **100** (durée de démarrage), **101** (application ralentissant le démarrage), **103** (service ralentissant le démarrage), **30** (repère d'heure de démarrage du système).

## ⚠️ Notes

- Les scripts de simulation servent à reproduire les pannes sur un poste de test. Ils modifient le registre et créent des entrées de démarrage : **à n'exécuter que sur une machine virtuelle disposant d'un snapshot**.
- Les trois entrées de démarrage créées par le scénario C (`SyncDocuments`, `AgentComptaMAJ`, `IndexationDocs`) reproduisent volontairement les techniques de persistance d'un logiciel indésirable : noms crédibles, exécution masquée, emplacement de registre rarement consulté.
- Le rapport comporte une section « problèmes rencontrés » et une section « ce que cette intervention m'a appris », qui documentent les incidents de parcours et les méthodes acquises pendant le travail.

---

## 🔗 Les 5 projets du PPE IT Essentials

| Projet | Sujet | Dépôt |
|---|---|---|
| 1/5 | Poste de travail pour un cabinet comptable | [`ppe-projet1-cabinet-comptable`](https://github.com/L4ami/ppe-projet1-cabinet-comptable) |
| 2/5 | Poste multi-utilisateurs en salle informatique | [`ppe-projet2-salle-informatique`](https://github.com/L4ami/ppe-projet2-salle-informatique) |
| 3/5 | Migration et sauvegarde d'un poste | [`ppe-projet3-migration-sauvegarde`](https://github.com/L4ami/ppe-projet3-migration-sauvegarde) |
| 4/5 | Dépannage et diagnostic d'un poste en panne | **ce dépôt** |
| 5/5 | Déploiement standardisé d'un poste | [`ppe-projet5-deploiement-image-systeme`](https://github.com/L4ami/ppe-projet5-deploiement-image-systeme) |

---

**Auteur :** Paul Giocanti ([@L4ami](https://github.com/L4ami)) · Septembre 2026<br>
CFC d'informaticien + Bachelor (double certification) · Geneva Institute of Technology
