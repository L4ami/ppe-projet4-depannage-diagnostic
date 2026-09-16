<#
    r.ps1  (copie courte de p4-panne-C-nettoyer.ps1)
    Projet 4 - PPE IT Essentials (GIT, classe E1B) - Paul Giocanti

    NETTOYAGE apres reparation de la panne C.
    Desactiver via le gestionnaire des taches traite le symptome ;
    ce script supprime la cause : les trois entrees de demarrage
    et le script qu'elles lancaient.

    A lancer dans la VM, PowerShell EN ADMINISTRATEUR.
#>

$run = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$entrees = "SyncDocuments", "AgentComptaMAJ", "IndexationDocs"

Write-Output ""
Write-Output "=== AVANT NETTOYAGE : entrees de demarrage de l'utilisateur ==="
(Get-ItemProperty $run) | Select-Object * -Exclude PS* | Format-List | Out-String

foreach ($e in $entrees) {
    if ((Get-ItemProperty $run).PSObject.Properties.Name -contains $e) {
        Remove-ItemProperty -Path $run -Name $e -Force
        Write-Output "Entree supprimee : $e"
    } else {
        Write-Output "Entree deja absente : $e"
    }
}

$charge = "C:\PPE-P4\scripts\charge-demarrage.ps1"
if (Test-Path $charge) {
    Remove-Item $charge -Force
    Write-Output "Fichier supprime : $charge"
} else {
    Write-Output "Fichier deja absent : $charge"
}

Write-Output ""
Write-Output "=== APRES NETTOYAGE : entrees de demarrage de l'utilisateur ==="
(Get-ItemProperty $run) | Select-Object * -Exclude PS* | Format-List | Out-String

Write-Output "Seules OneDrive et MicrosoftEdgeAutoLaunch doivent rester : ce sont des composants legitimes du poste."
Write-Output ""
