# Script PowerShell pour convertir une version Evaluation de Windows Server
# Vers une version définitive pour une Machine Virtuelle Hyper-V automatiquement au travers de AVMA
# À exécuter en tant qu'administrateur !
# https://learn.microsoft.com/fr-fr/windows-server/get-started/automatic-vm-activation?tabs=server2025

# AVMA Key for automatic activation of Hyper-v VM (need data exchange integration service).
$ProductKey = "YQB4H-NKHHJ-Q6K4R-4VMY6-VCH67"
# Target Edition is Datacenter becaus is build for VM
$TargetEdition = "ServerDatacenter"

Write-Host "Vérification de l'édition actuelle..."
DISM /online /Get-CurrentEdition

Write-Host "Éditions cibles possibles..."
DISM /online /Get-TargetEditions

Write-Host "Conversion vers $TargetEdition en cours..."
DISM /online /Set-Edition:$TargetEdition /ProductKey:$ProductKey /AcceptEula

Write-Host "Conversion terminée. Un redémarrage est nécessaire."
Restart-Computer -Force