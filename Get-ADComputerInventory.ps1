<#
.SYNOPSIS
    Exporte un inventaire détaillé des ordinateurs présents dans Active Directory.

.DESCRIPTION
    Interroge Active Directory et collecte les informations utiles disponibles
    sur chaque objet ordinateur : identité, domaine, système d'exploitation,
    réseau, activité, mot de passe, sécurité, délégation, groupes, emplacement
    et gestion.

    Les ordinateurs activés et désactivés sont inclus. Les propriétés contenant
    plusieurs valeurs sont réunies avec le séparateur " | " afin de conserver
    une ligne par ordinateur dans le fichier CSV.

.PARAMETER Server
    Nom DNS du domaine ou nom d'un contrôleur de domaine à interroger.
    Par défaut, le domaine courant est utilisé.

.PARAMETER SearchBase
    Distinguished Name d'une unité d'organisation à inventorier.
    Exemple : OU=Postes,DC=contoso,DC=local
    Par défaut, tout le domaine est interrogé.

.PARAMETER CheminCSV
    Chemin du fichier CSV à créer.
    Par défaut : Inventaire_Ordinateurs_AD.csv dans le dossier du script.

.EXAMPLE
    .\Get-ADComputerInventory.ps1

.EXAMPLE
    .\Get-ADComputerInventory.ps1 -Server contoso.local

.EXAMPLE
    .\Get-ADComputerInventory.ps1 -Server contoso.local -SearchBase "OU=Postes,DC=contoso,DC=local" -CheminCSV "C:\Exports\Inventaire_AD.csv"

.NOTES
    Prérequis :
    - Module ActiveDirectory (outils RSAT).
    - Droits de lecture sur Active Directory.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Server,

    [Parameter()]
    [string]$SearchBase,

    [Parameter()]
    [string]$CheminCSV
)

# ---------------------------------------------------------------------------
# Détermination du chemin d'export
# ---------------------------------------------------------------------------

# Le chemin est calculé après le bloc param, car certaines versions ou certains
# modes d'exécution de PowerShell ne renseignent pas encore $PSScriptRoot lors
# de l'évaluation de la valeur par défaut d'un paramètre.
if ([string]::IsNullOrWhiteSpace($CheminCSV)) {
    if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $DossierScript = Split-Path -Parent $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $DossierScript = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    else {
        $DossierScript = (Get-Location).Path
    }

    $CheminCSV = Join-Path -Path $DossierScript -ChildPath 'Inventaire_Ordinateurs_AD.csv'
}

# ---------------------------------------------------------------------------
# Vérification des prérequis
# ---------------------------------------------------------------------------

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw "Le module ActiveDirectory est introuvable. Installez les outils RSAT avant d'exécuter ce script."
}

Import-Module ActiveDirectory -ErrorAction Stop

# ---------------------------------------------------------------------------
# Préparation de la requête
# ---------------------------------------------------------------------------

$ParametresDomaine = @{}
if ($Server) {
    $ParametresDomaine.Server = $Server
}

try {
    $Domaine = Get-ADDomain @ParametresDomaine -ErrorAction Stop
    $Foret = Get-ADForest @ParametresDomaine -ErrorAction Stop
}
catch {
    throw "Impossible d'obtenir les informations du domaine Active Directory : $($_.Exception.Message)"
}

$Proprietes = @(
    'AccountExpirationDate'
    'AccountNotDelegated'
    'BadLogonCount'
    'CanonicalName'
    'Created'
    'Description'
    'DisplayName'
    'DNSHostName'
    'DoesNotRequirePreAuth'
    'IPv4Address'
    'KerberosEncryptionType'
    'LastBadPasswordAttempt'
    'LastLogonDate'
    'Location'
    'LockedOut'
    'logonCount'
    'ManagedBy'
    'MemberOf'
    'Modified'
    'OperatingSystem'
    'OperatingSystemHotfix'
    'OperatingSystemServicePack'
    'OperatingSystemVersion'
    'PasswordExpired'
    'PasswordLastSet'
    'PasswordNeverExpires'
    'PasswordNotRequired'
    'PrimaryGroupID'
    'ProtectedFromAccidentalDeletion'
    'ServicePrincipalNames'
    'SID'
    'TrustedForDelegation'
    'TrustedToAuthForDelegation'
    'userAccountControl'
)

$ParametresRecherche = @{
    Filter      = '*'
    Properties  = $Proprietes
    ErrorAction = 'Stop'
}

if ($Server) {
    $ParametresRecherche.Server = $Server
}

if ($SearchBase) {
    $ParametresRecherche.SearchBase = $SearchBase
}

# ---------------------------------------------------------------------------
# Collecte et mise en forme de l'inventaire
# ---------------------------------------------------------------------------

try {
    $Ordinateurs = @(
        Get-ADComputer @ParametresRecherche |
            Sort-Object Name
    )
}
catch {
    throw "La recherche des ordinateurs Active Directory a échoué : $($_.Exception.Message)"
}

Write-Host ''
Write-Host "Domaine interrogé : $($Domaine.DNSRoot)"
Write-Host "Ordinateurs trouvés : $($Ordinateurs.Count)"
Write-Host ''

$Inventaire = @(
    foreach ($Ordinateur in $Ordinateurs) {
        # Le Distinguished Name de l'OU correspond à tout ce qui suit le
        # premier composant CN=NomOrdinateur.
        $UniteOrganisation = if ($Ordinateur.DistinguishedName -match '^[^,]+,(.+)$') {
            $Matches[1]
        }
        else {
            $null
        }

        [PSCustomObject][ordered]@{
            Name                            = $Ordinateur.Name
            DisplayName                     = $Ordinateur.DisplayName
            SamAccountName                  = $Ordinateur.SamAccountName
            DNSHostName                     = $Ordinateur.DNSHostName
            IPv4Address                     = $Ordinateur.IPv4Address
            Enabled                         = $Ordinateur.Enabled
            DomaineDNS                      = $Domaine.DNSRoot
            DomaineNetBIOS                  = $Domaine.NetBIOSName
            Foret                           = $Foret.Name
            UniteOrganisation               = $UniteOrganisation
            CanonicalName                   = $Ordinateur.CanonicalName
            DistinguishedName               = $Ordinateur.DistinguishedName
            Description                     = $Ordinateur.Description
            Location                        = $Ordinateur.Location
            ManagedBy                       = $Ordinateur.ManagedBy
            OperatingSystem                 = $Ordinateur.OperatingSystem
            OperatingSystemVersion          = $Ordinateur.OperatingSystemVersion
            OperatingSystemServicePack      = $Ordinateur.OperatingSystemServicePack
            OperatingSystemHotfix           = $Ordinateur.OperatingSystemHotfix
            LastLogonDate                   = $Ordinateur.LastLogonDate
            LastBadPasswordAttempt          = $Ordinateur.LastBadPasswordAttempt
            LogonCount                      = $Ordinateur.logonCount
            BadLogonCount                   = $Ordinateur.BadLogonCount
            PasswordLastSet                 = $Ordinateur.PasswordLastSet
            PasswordExpired                 = $Ordinateur.PasswordExpired
            PasswordNeverExpires            = $Ordinateur.PasswordNeverExpires
            PasswordNotRequired             = $Ordinateur.PasswordNotRequired
            AccountExpirationDate           = $Ordinateur.AccountExpirationDate
            LockedOut                       = $Ordinateur.LockedOut
            Created                         = $Ordinateur.Created
            Modified                        = $Ordinateur.Modified
            ObjectGUID                      = $Ordinateur.ObjectGUID
            SID                             = $Ordinateur.SID
            PrimaryGroupID                  = $Ordinateur.PrimaryGroupID
            ProtectedFromAccidentalDeletion = $Ordinateur.ProtectedFromAccidentalDeletion
            AccountNotDelegated             = $Ordinateur.AccountNotDelegated
            DoesNotRequirePreAuth            = $Ordinateur.DoesNotRequirePreAuth
            TrustedForDelegation            = $Ordinateur.TrustedForDelegation
            TrustedToAuthForDelegation      = $Ordinateur.TrustedToAuthForDelegation
            KerberosEncryptionType          = ($Ordinateur.KerberosEncryptionType -join ' | ')
            UserAccountControl              = $Ordinateur.userAccountControl
            MemberOf                        = ($Ordinateur.MemberOf -join ' | ')
            ServicePrincipalNames           = ($Ordinateur.ServicePrincipalNames -join ' | ')
        }
    }
)

# ---------------------------------------------------------------------------
# Export CSV
# ---------------------------------------------------------------------------

try {
    $Inventaire |
        Export-Csv -Path $CheminCSV -Delimiter ';' -Encoding UTF8 -NoTypeInformation -ErrorAction Stop
}
catch {
    throw "L'export CSV a échoué : $($_.Exception.Message)"
}

$Inventaire |
    Select-Object Name, DNSHostName, Enabled, OperatingSystem, LastLogonDate |
    Format-Table -AutoSize

Write-Host ''
Write-Host "Inventaire exporté : $CheminCSV" -ForegroundColor Green
