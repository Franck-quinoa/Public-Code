# Script PowerShell pour réactiver l'add-in KoffAddIn.UserInterface dans Outlook
# Effectue les opérations de la partie "Clarifications About Inactive/Unloaded Add-Ins" de : https://support.kerioconnect.gfi.com/hc/en-us/articles/360015186420-Re-Enabling-Deactivated-KOFF-Add-In
# généré par Copilot https://copilot.microsoft.com/sl/gBJMj9jkFFI

# Vérifiez si Outlook est en cours d'exécution et fermez-le si nécessaire
$OutlookProcess = Get-Process | Where-Object {$_.ProcessName -eq "OUTLOOK"}
if ($OutlookProcess) {
    Write-Host "Fermeture d'Outlook..."
    $OutlookProcess | Stop-Process
    Start-Sleep -Seconds 5 # Attendre que le processus Outlook se termine
}

# Chemin vers la clé de registre de l'add-in KoffAddIn.UserInterface
$registryPath = "HKCU:\Software\Microsoft\Office\Outlook\Addins\KoffAddIn.UserInterface"

# Vérifiez si l'add-in KoffAddIn.UserInterface est inactif/non chargé (LoadBehavior != 3)
$addInValue = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
if ($addInValue.LoadBehavior -ne 3) {
    Write-Host "Réactivation de l'add-in KoffAddIn.UserInterface"
    Set-ItemProperty -Path $registryPath -Name "LoadBehavior" -Value 3
    Write-Host "L'add-in KoffAddIn.UserInterface a été réactivé."
} else {
    Write-Host "L'add-in KoffAddIn.UserInterface est déjà actif."
}

# Ajoutez la clé de registre DoNotDisableAddinList pour l'add-in spécifié
$officeVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name "ProductReleaseID").ProductReleaseID
$doNotDisableRegistryPath = "HKCU:\Software\Policies\Microsoft\Office\$officeVersion\Outlook\Resiliency\DoNotDisableAddinList"
New-ItemProperty -Path $doNotDisableRegistryPath -Name "KoffAddIn.UserInterface" -Value 1 -PropertyType DWORD -Force

# Relancez Outlook
Start-Process "OUTLOOK.EXE"
