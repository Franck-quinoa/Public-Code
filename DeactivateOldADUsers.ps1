# Ce script désactive les utilisateurs inactifs d'Active Directory et envoie un e-mail avec la liste des utilisateurs désactivés
# Le fichier d'exclusions doit contenir les noms des utilisateurs à exclure, un par ligne
# Par exemple :
# Admin
# Service
# Test
# Le fichier SMTP doit contenir les paramètres du serveur SMTP, séparés par des signes égal
# Par exemple :
# Server=smtp.domaine.com
# Port=587
# Username=user@domaine.com
# Password=pass
# Le fichier To doit contenir les adresses e-mail des destinataires, séparées par des virgules
# Par exemple :
# Manager1@domaine.com,Manager2@domaine.com

# Définir le nombre de mois d'inactivité
$InactiveMonths = 6

# Définir la date limite d'inactivité
$Date = (Get-Date).AddMonths(-$InactiveMonths)

# Lister les utilisateurs inactifs depuis la date limite
$InactiveUsers = Search-ADAccount -AccountInactive -DateTime $Date -UsersOnly | Where-Object { $_.LastLogonDate }

# Lire le fichier texte contenant la liste d'exception
$ExclusionList = Get-Content -Path "C:\exclusion.txt"

# Désactiver les utilisateurs inactifs qui ne sont pas déjà désactivés ni dans la liste d'exception
$DisabledUsers = foreach ($User in $InactiveUsers) {
    if ($User.Enabled -and $User.Name -notin $ExclusionList) {
        Disable-ADAccount -Identity $User
        $User
    }
}

# Envoyer un e-mail avec la liste des utilisateurs désactivés
if ($DisabledUsers) {
    # Trier les utilisateurs désactivés par date de dernière connexion
    $SortedUsers = $DisabledUsers | Sort-Object -Property LastLogonDate

    # Créer un tableau HTML avec le nom et la date de dernière connexion des utilisateurs désactivés
    $Table = $SortedUsers | Select-Object Name, LastLogonDate | ConvertTo-Html -Fragment

    # Créer le corps du message en HTML
    $Body = "<html><body><p>Les utilisateurs suivants ont été désactivés :</p>$Table</body></html>"

    # Lire le fichier texte contenant les paramètres du serveur SMTP
    $SMTPParameters = Get-Content -Path "C:\SMTP.txt" | ConvertFrom-StringData

    # Créer un objet PSCredential avec l'identifiant et le mot de passe du serveur SMTP
    $Credential = New-Object System.Management.Automation.PSCredential ($SMTPParameters.Username, ($SMTPParameters.Password | ConvertTo-SecureString -AsPlainText -Force))

    # Lire le fichier texte contenant les adresses e-mail des destinataires
    $To = Get-Content -Path "C:\To.txt"

    # Convertir le contenu du fichier en un tableau de chaînes
    [string []]$To = $To.Split(',')

    # Définir l'expéditeur et le sujet du message
    $From = "dgfip@toto.com"
    $Subject = "Liste des utilisateurs désactivés"

    # Envoyer le message en HTML
    Send-MailMessage -To $To -From $From -Subject $Subject -Body $Body -SmtpServer $SMTPParameters.Server -Credential $Credential -Port $SMTPParameters.Port -UseSsl -BodyAsHtml
}
