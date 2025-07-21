# Script PowerShell - Conversion Évaluation auto vers version finale

function Get-CurrentEdition {
    $output = dism /online /Get-CurrentEdition
    foreach ($line in $output) {
        if ($line -like "*Current Edition*") {
            return ($line -split ":")[1].Trim()
        }
    }
    return $null
}

# 🎯 Détection édition en cours
$currentEdition = Get-CurrentEdition

Write-Host "`n===== Conversion Windows Server $currentEdition =====`n" -ForegroundColor Cyan

# Détermination édition cible selon version détectée
switch ($currentEdition) {
    "ServerStandardEval" { $targetEdition = "ServerStandard" }
    "ServerDatacenterEval" { $targetEdition = "ServerDatacenter" }
    default {
        Write-Host "❌ Édition non reconnue ou incompatible." -ForegroundColor Red
        exit
    }
}

# 🔑 Saisie ou non de clé produit
$productKey = Read-Host "Entrez votre clé produit (laisser vide pour utiliser une clé KMS de test)"

# Choix de la clé
if ([string]::IsNullOrWhiteSpace($productKey)) {
    Write-Host "ℹ️ Clé KMS générique utilisée pour test." -ForegroundColor Yellow
    $productKey = if ($targetEdition -eq "ServerStandard") {
        "N69G4-B89J2-4G8F4-WWYCC-J464C"
    } else {
        "WMDGN-G9PQG-XVVXX-R3X43-63DFG"
    }
    $activate = $false
} else {
    $activate = $true
}

# 🛠 Lancement de conversion
Start-Process -FilePath "cmd.exe" -ArgumentList "/c DISM /online /Set-Edition:$targetEdition /ProductKey:$productKey /AcceptEula" -Verb RunAs -Wait

# 🔐 Activation si clé personnalisée
if ($activate) {
    slmgr.vbs /ipk $productKey
    slmgr.vbs /ato
    Write-Host "`n✅ Activation terminée." -ForegroundColor Green
} else {
    Write-Host "`n🔄 Clé KMS utilisée sans activation." -ForegroundColor Green
}

Write-Host "`n🎉 Conversion terminée vers $targetEdition. Redémarrage recommandé." -ForegroundColor Cyan
