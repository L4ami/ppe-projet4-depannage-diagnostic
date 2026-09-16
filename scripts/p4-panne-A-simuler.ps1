<#
    p4-panne-A-simuler.ps1
    Projet 4 - PPE IT Essentials (GIT, classe E1B) - Paul Giocanti
    PANNE A : mise en panne du service Spouleur d'impression.

    Ce script SIMULE la panne, il ne la repare pas.
    La reparation se fera A LA MAIN pendant le diagnostic : c'est la partie notee.

    A lancer dans la VM PC01-PG, PowerShell EN ADMINISTRATEUR.
    (Texte sans accents volontairement : evite les caracteres casses dans la console.)
#>

$cle = "HKLM:\SYSTEM\CurrentControlSet\Services\Spooler"

# 1. On note la valeur saine avant de la casser, et on la range hors de vue
#    dans un fichier de secours : filet de securite si le snapshot merdait.
$valeurSaine = (Get-ItemProperty $cle).ImagePath
$secours = "C:\PPE-P4\doc\.valeur-saine-spooler.txt"
if (-not (Test-Path "C:\PPE-P4\doc")) { New-Item -ItemType Directory -Path "C:\PPE-P4\doc" -Force | Out-Null }
$valeurSaine | Out-File -FilePath $secours -Encoding ASCII
(Get-Item $secours).Attributes = 'Hidden'

# 2. On casse le chemin du binaire.
#    Le service pointera vers un fichier .exe qui n'existe pas.
#    Type ExpandString (REG_EXPAND_SZ) pour rester conforme a ce que Windows attend.
New-ItemProperty -Path $cle -Name "ImagePath" `
                 -Value "C:\WINDOWS\System32\spoolsvc.exe" `
                 -PropertyType ExpandString -Force | Out-Null

# 3. On arrete le service pour que la panne soit immediate.
Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Panne A posee." -ForegroundColor Yellow
Write-Host "Redemarre maintenant la VM, puis diagnostique le poste comme si tu ne savais rien." -ForegroundColor Yellow
Write-Host ""
