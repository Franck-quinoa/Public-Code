<#
.SYNOPSIS
    Recherche les ordinateurs Active Directory inactifs et propose de les désactiver.

.DESCRIPTION
    Recherche les ordinateurs activés dont LastLogonDate est vide ou antérieure
    à un an. Le résultat est trié par LastLogonDate.

    Pour chaque ordinateur trouvé, le script demande une confirmation avant de
    désactiver son compte Active Directory. Il affiche ensuite le bilan et
    l'exporte dans PC_AD_Inactifs.csv, dans le même dossier que ce script.

    Le CSV contient les colonnes Name, LastLogonDate et DateDesactivation.
    DateDesactivation reste vide lorsque la désactivation n'a pas été validée
    ou lorsqu'elle a échoué.

.NOTES
    Prérequis :
    - Module ActiveDirectory (outils RSAT).
    - Droits suffisants pour désactiver les comptes ordinateurs concernés.
#>

[CmdletBinding()]
param()

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Un ordinateur est considéré comme inactif si sa dernière connexion remonte
# à plus d'un an.
$DateLimite = (Get-Date).AddYears(-1)

# Le fichier CSV est créé dans le même dossier que le script.
$CheminCSV = Join-Path -Path $PSScriptRoot -ChildPath 'PC_AD_Inactifs.csv'

# ---------------------------------------------------------------------------
# Vérification des prérequis
# ---------------------------------------------------------------------------

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw "Le module ActiveDirectory est introuvable. Installez les outils RSAT avant d'exécuter ce script."
}

Import-Module ActiveDirectory -ErrorAction Stop

# ---------------------------------------------------------------------------
# Recherche Active Directory
# ---------------------------------------------------------------------------

try {
    $OrdinateursInactifs = @(
        Get-ADComputer -Filter { Enabled -eq $true } -Properties LastLogonDate -ErrorAction Stop |
            Where-Object {
                # Conserve les ordinateurs sans date de connexion ou dont la
                # dernière connexion est antérieure à la date limite.
                -not $_.LastLogonDate -or $_.LastLogonDate -lt $DateLimite
            } |
            Sort-Object LastLogonDate
    )
}
catch {
    throw "La recherche Active Directory a échoué : $($_.Exception.Message)"
}

Write-Host ''
Write-Host "Ordinateurs AD activés sans connexion depuis plus d'un an : $($OrdinateursInactifs.Count)"
Write-Host ''

# ---------------------------------------------------------------------------
# Confirmation et désactivation
# ---------------------------------------------------------------------------

$Resultats = foreach ($Ordinateur in $OrdinateursInactifs) {
    $DateDesactivation = $null

    if ($Ordinateur.LastLogonDate) {
        $DerniereConnexion = $Ordinateur.LastLogonDate.ToString('yyyy-MM-dd HH:mm:ss')
    }
    else {
        $DerniereConnexion = 'Jamais'
    }

    do {
        $Reponse = Read-Host "Désactiver '$($Ordinateur.Name)' (dernière connexion : $DerniereConnexion) ? [O/N]"
        $Reponse = $Reponse.Trim()
    }
    until ($Reponse -match '^[OoNn]$')

    if ($Reponse -match '^[Oo]$') {
        try {
            Disable-ADAccount -Identity $Ordinateur.DistinguishedName -ErrorAction Stop
            $DateDesactivation = Get-Date

            Write-Host "Compte ordinateur '$($Ordinateur.Name)' désactivé." -ForegroundColor Green
        }
        catch {
            Write-Warning "Impossible de désactiver '$($Ordinateur.Name)' : $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "Compte ordinateur '$($Ordinateur.Name)' conservé actif."
    }

    [PSCustomObject]@{
        Name               = $Ordinateur.Name
        LastLogonDate      = $Ordinateur.LastLogonDate
        DateDesactivation = $DateDesactivation
    }
}

# ---------------------------------------------------------------------------
# Affichage et export CSV
# ---------------------------------------------------------------------------

Write-Host ''
$Resultats | Format-Table -AutoSize

$Resultats |
    Export-Csv -Path $CheminCSV -Delimiter ';' -Encoding UTF8 -NoTypeInformation

Write-Host ''
Write-Host "Export CSV créé : $CheminCSV"
