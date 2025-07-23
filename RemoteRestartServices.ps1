######################################################################################
# Activer PSRemoting sur le serveur cible/distant en powershell : 
# Enable-PSRemoting 
######################################################################################
# Ajouter ici au préalable l'authent. (Nom/IP Serveur, user & pass de la cible) 
# au gestionnaire d'authentification de Windows, si ce n'est pas fait :
# cmdkey /add:monserveur.local /user:admin /pass:motdepasse
######################################################################################
# Créer si besoin une tâche planifiée avec comme suit :
# Programme/Script : Powershell.exe
# Arguments : -ExecutionPolicy Bypass -File "C:\chemin\vers\RemoteRestartServices.ps1"
#######################################################################################

# Configuration
$remoteServer = "monserveur.local"

# Liste des services à redémarrer
$services = @(
    "Service #1",
    "Service #2",
    "Service #3"
)

# Exécution distante
Invoke-Command -ComputerName $remoteServer -ScriptBlock {
    param($serviceList)

    foreach ($serviceName in $serviceList) {
        try {
            Restart-Service -Name $serviceName -ErrorAction Stop
            Write-Host "$serviceName redémarré avec succès"
        } catch {
            Write-Host "Échec du redémarrage de $serviceName : $_"
        }
    }

} -ArgumentList $services
