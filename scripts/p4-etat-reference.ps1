<#
    p4-etat-reference.ps1
    Projet 4 - PPE IT Essentials (GIT, classe E1B) - Paul Giocanti
    Objectif : figer l'etat SAIN du poste avant de simuler les pannes.
    Sans cet etat de reference, impossible de prouver ensuite que la panne est reparee.
    A lancer dans une console PowerShell ouverte EN ADMINISTRATEUR.
    (Texte sans accents volontairement : evite les caracteres casses dans la console.)
#>

# Chemin DANS LA VM (pas sur l'hote) : on garde un chemin court et neutre.
$dossier = "C:\PPE-P4\doc"
if (-not (Test-Path $dossier)) { New-Item -ItemType Directory -Path $dossier -Force | Out-Null }
$rapport = Join-Path $dossier "etat-reference.txt"

function Titre($t) {
    $ligne = "=" * 70
    Write-Output ""
    Write-Output $ligne
    Write-Output "  $t"
    Write-Output $ligne
}

$sortie = & {

    Titre "ETAT DE REFERENCE - $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
    Write-Output "Poste     : $env:COMPUTERNAME"
    Write-Output "Session   : $env:USERNAME"
    Write-Output "Systeme   : $((Get-CimInstance Win32_OperatingSystem).Caption) - version $((Get-CimInstance Win32_OperatingSystem).Version)"

    # --- 1. Services critiques -------------------------------------------------
    # On note l'etat (Running/Stopped) et le type de demarrage (Automatic/Manual/Disabled).
    Titre "1. SERVICES CRITIQUES"
    $services = "Spooler","Dhcp","Dnscache","RpcSs","LanmanWorkstation","W32Time","WSearch"
    Get-Service -Name $services -ErrorAction SilentlyContinue |
        Select-Object Name, DisplayName, Status, StartType |
        Format-Table -AutoSize | Out-String

    # --- 2. Chemin du binaire du spouleur -------------------------------------
    # ImagePath = le fichier .exe que Windows lance pour ce service.
    # C'est LA valeur a comparer si un service refuse de demarrer.
    Titre "2. CHEMIN DU BINAIRE DU SPOULEUR (valeur de reference)"
    (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Spooler").ImagePath
    Write-Output ""
    Write-Output "Dependances du spouleur :"
    (Get-Service Spooler).ServicesDependedOn | Select-Object Name, Status | Format-Table -AutoSize | Out-String

    # --- 3. Carte reseau -------------------------------------------------------
    Titre "3. CARTE RESEAU"
    Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed |
        Format-Table -AutoSize | Out-String
    Write-Output "Configuration IP :"
    Get-NetIPConfiguration | Out-String

    # --- 4. Duree du dernier demarrage ----------------------------------------
    # Journal Diagnostics-Performance, evenement 100 : Windows y ecrit a chaque
    # demarrage le temps qu'il a mis (en millisecondes).
    Titre "4. DUREE DES DERNIERS DEMARRAGES (evenement 100)"
    try {
        $evts = Get-WinEvent -LogName 'Microsoft-Windows-Diagnostics-Performance/Operational' `
                             -FilterXPath "*[System[EventID=100]]" -MaxEvents 5 -ErrorAction Stop
        foreach ($e in $evts) {
            $x = [xml]$e.ToXml()
            $d = @{}
            foreach ($n in $x.Event.EventData.Data) { $d[$n.Name] = $n.'#text' }
            $total = [int]$d['BootTime'] / 1000
            $principal = [int]$d['MainPathBootTime'] / 1000
            Write-Output ("{0} -> total {1,7:N1} s | phase principale {2,7:N1} s" -f `
                          $e.TimeCreated.ToString('dd.MM.yyyy HH:mm'), $total, $principal)
        }
    } catch {
        Write-Output "Journal Diagnostics-Performance indisponible ou vide."
        Write-Output "Contournement : mesure chronometree manuelle + onglet Demarrage du gestionnaire des taches."
        Write-Output "Detail : $($_.Exception.Message)"
    }

    # --- 5. Elements lances au demarrage --------------------------------------
    Titre "5. ELEMENTS LANCES AU DEMARRAGE"
    Write-Output "Cle registre Run (machine) :"
    Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue |
        Select-Object * -Exclude PS* | Format-List | Out-String
    Write-Output "Cle registre Run (utilisateur) :"
    Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue |
        Select-Object * -Exclude PS* | Format-List | Out-String
    Write-Output "Dossier Demarrage de l'utilisateur :"
    Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue |
        Select-Object Name | Format-Table -AutoSize | Out-String

    # --- 6. Ressources ---------------------------------------------------------
    # Disque plein ou RAM saturee sont les deux causes "bebetes" d'un poste lent :
    # on les releve maintenant pour pouvoir les ECARTER plus tard, preuve a l'appui.
    Titre "6. RESSOURCES (pour ecarter les causes simples)"
    Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, FileSystemLabel,
        @{n='Taille_Go';e={[math]::Round($_.Size/1GB,1)}},
        @{n='Libre_Go';e={[math]::Round($_.SizeRemaining/1GB,1)}},
        @{n='Libre_%';e={[math]::Round(($_.SizeRemaining/$_.Size)*100,0)}} |
        Format-Table -AutoSize | Out-String
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Output ("RAM totale : {0:N1} Go | RAM libre : {1:N1} Go" -f `
                  ($os.TotalVisibleMemorySize/1MB), ($os.FreePhysicalMemory/1MB))

    Titre "FIN DE L'ETAT DE REFERENCE"
}

$sortie | Tee-Object -FilePath $rapport
Write-Host ""
Write-Host "Etat de reference enregistre dans : $rapport" -ForegroundColor Green
