###################################################################
# Commandes rapides pour désactiver ou ordonner des utilisateurs. #
###################################################################

# Désactiver les utilisateurs qui ne se sont pas connectés ces 6 derniers mois
#Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 180.00:00:00 | Disable-ADAccount

# Déplacer dans une Unité d'Organisation des utilisateurs qui ne se sont pas connectés ces 6 derniers mois
#Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 180.00:00:00 | Move-ADObject -TargetPath "OU=Disabled Users,DC=domain,DC=com"

###########################################################################
# Script pour désactiver les utilisateurs et envoyer par mail le rapport. #
###########################################################################

# Définir le nombre de mois d'inactivité
$InactiveMonths = 6

# Définir la date limite d'inactivité
$Date = (Get-Date).AddMonths(-$InactiveMonths)

# Lister les utilisateurs inactifs depuis la date limite
$InactiveUsers = Search-ADAccount -AccountInactive -DateTime $Date -UsersOnly | Where-Object { $_.LastLogonDate }

# Désactiver les utilisateurs inactifs qui ne sont pas déjà désactivés
$DisabledUsers = foreach ($User in $InactiveUsers) {
    if ($User.Enabled) {
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

    # Définir le sujet, le destinataire, l'expéditeur et le serveur SMTP du message
    $Subject = "Liste des utilisateurs désactivés"
    $To = "votre_adresse_email@domaine.com"
    $From = "noreply@domaine.com"
    $SMTPServer = "smtp.domaine.com"

    # Envoyer le message en HTML
    Send-MailMessage -To $To -From $From -Subject $Subject -Body $Body -SmtpServer $SMTPServer -BodyAsHtml
}
