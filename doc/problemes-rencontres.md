# Problèmes rencontrés pendant le Projet 4

Journal tenu au fil de l'intervention. Chaque entrée décrit le problème, son explication technique et la façon dont il a été contourné ou résolu.

---

## P1 — Faux symptôme : le Bluetooth ne fonctionne pas

**Contexte.** Au moment de constater la panne A, la fenêtre « Ajouter un appareil » de Windows affichait « Connexion impossible » pour le Bluetooth et le Miracast, en plus de l'erreur liée à l'impression.

**Explication.** La machine de test est une machine virtuelle VMware. VMware n'émule aucune puce Bluetooth : Windows ne trouve donc jamais d'adaptateur, quel que soit l'état du poste. Ce message était présent avant la panne et l'est resté après la réparation.

**Traitement.** Symptôme écarté du diagnostic dès l'étape d'identification, et documenté comme hypothèse non retenue. Le seul symptôme lié à la panne était le message explicite sur le service Spouleur d'impression.

**Ce que ça apprend.** Un utilisateur signale souvent plusieurs anomalies en même temps. Trier ce qui est lié de ce qui ne l'est pas fait partie de l'étape « identifier le problème » : partir sur le mauvais symptôme coûte plus de temps que la panne elle-même.

---

## P2 — Événement 7000 antérieur pouvant prêter à confusion

**Contexte.** Après réparation de la panne A et redémarrage, le journal Système filtré sur les erreurs affichait toujours un événement 7000 lié au spouleur.

**Explication.** Cet événement datait de 11:04:34, c'est-à-dire du démarrage **précédant** l'intervention. Le redémarrage de validation a eu lieu à 12:57:16 (repérable aux deux entrées `Eventlog 30 — Service startup`). Aucun nouvel événement 7000 n'a été écrit après cette heure. L'Observateur d'événements conserve l'historique : la présence d'une erreur ancienne ne signifie pas que la panne persiste.

**Traitement.** L'horodatage du redémarrage de validation a été précisé sous la capture, pour lever toute ambiguïté à la lecture.

**Ce que ça apprend.** Une preuve par « absence d'erreur » n'a de valeur que si la fenêtre temporelle est explicite. Toujours dater le point de référence.

---

## P3 — Case « Tenter de supprimer le pilote » absente lors de la désinstallation

**Contexte.** Pour simuler la panne B, la procédure prévoyait de désinstaller la carte réseau **en supprimant son paquet pilote**. La boîte de dialogue du Gestionnaire de périphériques ne proposait pas cette case.

**Explication.** Windows ne propose la suppression du paquet pilote que pour les pilotes **tiers**, installés par un fabricant. Le pilote de la carte Intel 82574L est un pilote **intégré** au système (« in-box ») : il fait partie de Windows et ne peut pas être retiré du magasin de pilotes (`DriverStore`). Seul le périphérique a donc pu être désinstallé.

**Traitement.** La simulation a été conservée telle quelle : la désinstallation du périphérique suffisait à produire le symptôme recherché (perte totale de connectivité, carte absente de l'inventaire). La réparation par « Rechercher les modifications sur le matériel » a fonctionné sans support externe, précisément parce que le pilote était resté dans le magasin.

**Ce que ça apprend.** La gravité d'une panne de pilote dépend de l'origine du pilote. Pilote intégré : réparation en un rescan. Pilote fabricant supprimé : il faut le récupérer ailleurs — d'où l'intérêt, en entreprise, de conserver une bibliothèque de pilotes pour le parc.

---

## P4 — Capture d'écran de la simulation oubliée

**Contexte.** La capture de la boîte de dialogue de désinstallation (panne B) n'a pas été prise avant validation.

**Traitement.** Le pilote a été réinstallé via **Action > Rechercher les modifications sur le matériel**, puis la désinstallation a été rejouée, capture prise au bon moment, avant de valider.

**Ce que ça apprend.** La capture se prend **pendant** la manipulation, pas après. Ici l'étape était rejouable sans conséquence ; sur un poste de production, rejouer une manipulation pour documenter n'est pas toujours possible — la trace doit être prise du premier coup.

---

## P5 — Perte du copier-coller et du glisser-déposer entre l'hôte et la VM

**Contexte.** En cours d'intervention, le transfert de fichiers par glisser-déposer vers le bureau de la VM et le copier-coller de commandes depuis l'hôte ont cessé de fonctionner. Ces deux fonctions marchaient au début de la session (les scripts des phases précédentes avaient été transférés ainsi).

**Explication.** Ces deux fonctions sont assurées par **VMware Tools**, l'ensemble de pilotes et de services que VMware installe à l'intérieur de la machine virtuelle. Son service `VMTools` gère le presse-papiers partagé, le glisser-déposer et l'intégration de la souris. Lorsqu'il s'arrête ou se bloque — ce qui arrive après une session longue ou de nombreux redémarrages — l'intégration hôte/invité est perdue, sans message d'erreur.

**Traitement.** Démarche appliquée, du plus simple au plus complexe :

1. Redémarrage de la machine virtuelle, qui relance le service ;
2. vérification de l'état du service dans l'invité (`Get-Service VMTools`), et redémarrage manuel si nécessaire ;
3. vérification des autorisations dans **VM > Paramètres > Options > Isolation de l'invité** (glisser-déposer et copier-coller activés) ;
4. solution de repli retenue en cas d'échec : dossier partagé VMware pointant sur le dossier de travail, plus fiable que le presse-papiers pour transférer des fichiers.

**Ce que ça apprend.** L'intégration hôte/invité n'est pas une propriété de la machine virtuelle mais un service applicatif qui tourne dedans, et qui peut tomber comme n'importe quel service. Le réflexe est le même que pour la panne A : identifier le service responsable de la fonction perdue, vérifier son état, puis remonter vers sa configuration.
