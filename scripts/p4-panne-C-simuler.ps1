<#
    p4-panne-C-simuler.ps1
    Projet 4 - PPE IT Essentials (GIT, classe E1B) - Paul Giocanti
    PANNE C : poste anormalement lent au demarrage.

    Ce script SIMULE la panne, il ne la repare pas.
    La reparation se fera A LA MAIN pendant le diagnostic.

    A lancer dans la VM PC01-PG, PowerShell EN ADMINISTRATEUR.
    (Texte sans accents volontairement.)
#>

$dossier = "C:\PPE-P4\scripts"
if (-not (Test-Path $dossier)) { New-Item -ItemType Directory -Path $dossier -Force | Out-Null }

# Petit programme qui occupe le processeur pendant un moment.
$charge = @'
$fin = (Get-Date).AddSeconds(150)
while ((Get-Date) -lt $fin) { $null = [math]::Sqrt((Get-Random)) }
'@
$cheminCharge = Join-Path $dossier "charge-demarrage.ps1"
Set-Content -Path $cheminCharge -Value $charge -Encoding ASCII

# On declare trois "logiciels metier" au demarrage de la session.
# Noms volontairement credibles : en entreprise, personne ne se mefie
# d'une entree appelee "SyncDocuments".
$run = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$cmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$cheminCharge`""

foreach ($nom in @("SyncDocuments", "AgentComptaMAJ", "IndexationDocs")) {
    New-ItemProperty -Path $run -Name $nom -Value $cmd -PropertyType String -Force | Out-Null
}

Write-Host ""
Write-Host "Panne C posee." -ForegroundColor Yellow
Write-Host "Redemarre la VM DEUX FOIS, puis mesure de nouveau la duree de demarrage." -ForegroundColor Yellow
Write-Host ""
