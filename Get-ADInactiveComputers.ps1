<#
.SYNOPSIS
    Liste les ordinateurs Active Directory activés considérés comme inactifs.

.DESCRIPTION
    Recherche les ordinateurs activés dont LastLogonDate est vide ou antérieure
    à un an. Le résultat est trié par LastLogonDate, affiché à l'écran puis
    exporté dans le fichier PC_AD_Inactifs.csv, situé dans le même dossier que
    ce script.

.NOTES
    Prérequis : module ActiveDirectory (outils RSAT).
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
            Select-Object Name, LastLogonDate |
            Sort-Object LastLogonDate
    )
}
catch {
    throw "La recherche Active Directory a échoué : $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# Affichage et export CSV
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host "Ordinateurs AD activés sans connexion depuis plus d'un an : $($OrdinateursInactifs.Count)"
Write-Host ''

$OrdinateursInactifs | Format-Table -AutoSize

$OrdinateursInactifs |
    Export-Csv -Path $CheminCSV -Delimiter ';' -Encoding UTF8 -NoTypeInformation

Write-Host ''
Write-Host "Export CSV créé : $CheminCSV"
