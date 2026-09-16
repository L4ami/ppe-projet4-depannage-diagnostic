<#
    p4-mesure-demarrage.ps1
    Projet 4 - PPE IT Essentials (GIT, classe E1B) - Paul Giocanti

    Affiche la duree des N derniers demarrages de Windows.
    Source : journal "Diagnostics-Performance", evenement 100, que Windows ecrit
    automatiquement a chaque demarrage.

    Les trois chiffres :
      - TOTAL          : duree complete percue par l'utilisateur
      - PHASE PRINCIPALE : chargement du noyau, des pilotes et des services
      - APRES OUVERTURE : ce qui se lance APRES l'ouverture de session
                          (c'est la colonne qui grossit quand on ajoute des
                           programmes au demarrage)

    A lancer dans la VM, PowerShell EN ADMINISTRATEUR.
    (Texte sans accents volontairement.)
#>

param([int]$Nombre = 8)

Write-Output ""
Write-Output ("MESURE DES DEMARRAGES - releve du {0}" -f (Get-Date -Format 'dd.MM.yyyy HH:mm:ss'))
Write-Output ("=" * 78)
Write-Output ("{0,-18} {1,12} {2,18} {3,18}" -f "DATE DU DEMARRAGE", "TOTAL", "PHASE PRINCIPALE", "APRES OUVERTURE")
Write-Output ("=" * 78)

try {
    $evts = Get-WinEvent -LogName 'Microsoft-Windows-Diagnostics-Performance/Operational' `
                         -FilterXPath "*[System[EventID=100]]" -MaxEvents $Nombre -ErrorAction Stop

    $totaux = @()
    foreach ($e in $evts) {
        $x = [xml]$e.ToXml()
        $d = @{}
        foreach ($n in $x.Event.EventData.Data) { $d[$n.Name] = $n.'#text' }

        $total     = [double]$d['BootTime'] / 1000
        $principal = [double]$d['MainPathBootTime'] / 1000
        $apres     = [double]$d['BootPostBootTime'] / 1000
        $totaux += $total

        Write-Output ("{0,-18} {1,9:N1} s {2,15:N1} s {3,15:N1} s" -f `
                      $e.TimeCreated.ToString('dd.MM HH:mm'), $total, $principal, $apres)
    }

    Write-Output ("=" * 78)
    $moy = ($totaux | Measure-Object -Average).Average
    Write-Output ("Moyenne sur {0} demarrages : {1:N1} s" -f $totaux.Count, $moy)
    Write-Output ""
    Write-Output "Rappel : une seule mesure ne prouve rien, la duree varie naturellement."
    Write-Output "C'est la MOYENNE avant/apres qui fait la preuve."
}
catch {
    Write-Output "Journal Diagnostics-Performance indisponible."
    Write-Output "Contournement : chronometrage manuel + onglet Demarrage du gestionnaire des taches."
    Write-Output "Detail : $($_.Exception.Message)"
}
Write-Output ""
