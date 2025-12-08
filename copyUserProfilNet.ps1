param(
    [Parameter(Mandatory = $true)]
    [string]$SourceComputer,          # Nom ou IP de la machine source
    [Parameter(Mandatory = $true)]
    [string]$UserProfileName,         # Nom du dossier de profil (ex: jdupont)
    [string]$DestinationRoot = "C:\Users", # Racine de destination
    [string]$LogFile = "C:\copie_profil.log"
)

$SourcePath = "\\$SourceComputer\C$\Users\$UserProfileName"
$DestinationPath = Join-Path $DestinationRoot $UserProfileName

Write-Host "=== Copie du profil $UserProfileName depuis $SourceComputer ===" -ForegroundColor Cyan

if (-not (Test-Path $SourcePath)) {
    Write-Error "Impossible d'accéder au profil source."
    exit 1
}

if (-not (Test-Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath | Out-Null
}

# Compter le nombre total de fichiers à copier
Write-Host "Analyse des fichiers..." -ForegroundColor Yellow
$TotalFiles = (Get-ChildItem -Path $SourcePath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count
if ($TotalFiles -eq 0) {
    Write-Error "Aucun fichier trouvé dans le profil source."
    exit 1
}

Write-Host "Démarrage de la copie..." -ForegroundColor Yellow

# Lancer Robocopy et lire sa sortie en direct
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "robocopy.exe"
$psi.Arguments = "`"$SourcePath`" `"$DestinationPath`" /MIR /COPYALL /XJ /R:3 /W:5 /ZB /MT:16 /LOG+:`"$LogFile`" /NP"
$psi.RedirectStandardOutput = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
$process.Start() | Out-Null

$CopiedFiles = 0
while (-not $process.StandardOutput.EndOfStream) {
    $line = $process.StandardOutput.ReadLine()

    # Détection des lignes indiquant un fichier copié
    if ($line -match "^\s+\d+\s+[A-Z]") {
        $CopiedFiles++
        $Percent = [math]::Round(($CopiedFiles / $TotalFiles) * 100, 0)
        if ($Percent -gt 100) { $Percent = 100 }
        Write-Progress -Activity "Copie du profil utilisateur" -Status "$Percent% terminé ($CopiedFiles / $TotalFiles fichiers)" -PercentComplete $Percent
    }
}

$process.WaitForExit()
Write-Progress -Activity "Copie du profil utilisateur" -Completed
Write-Host "=== Copie terminée ===" -ForegroundColor Green
