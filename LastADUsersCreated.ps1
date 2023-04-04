#######################################################################
# To execute :                                                        #
# & '.\testLastADUsersCreated .ps1' -jours 15 -tolist .\emaillist.csv #
#######################################################################
param (
    $jours=30, 
    $tolist='.\emaillist.csv',
    $ListeServeurs='.\ServeursAD.csv'
)

#####################################
#Define date to start from (-30Days)#
#####################################
$DateCutOff=(Get-Date).AddDays(-$Jours)

##########################
#Formatting Table headers#
##########################
#To choose what to get here is the powershell command to liste available properties :
#Get-ADUser -Filter * -Properties * | Get-Member -MemberType Property

$NomUtilisateur=@{label="Nom de l'utilisateur";expression={$_.Name}}
$NomLogin=@{label="Log In";expression={$_.SamAccountName}}
$Groupes=@{label="Membre de";expression={$_.MemberOf}}
$creationDate=@{label="Date de cr&eacute;ation";expression={$_.whenCreated}}

##############
#Search users# created after the start date : Users created the last 30 days
##############

$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

#Init LastUsers
$LastUsers = ""
#Object from CSV
Import-Csv $ListeServeurs | ForEach-Object {
    $LastUsers += "<br /><h3>Active directory " + $_.Domaine + "</h3>" 
    $ServeurFQDN = $_.Serveur+"."+$_.Domaine
    try
    {
    $TempGetAD = Get-ADUser -Filter * -Properties whencreated,memberof -Server $ServeurFQDN | Where {$_.whenCreated -gt $datecutoff}
    if($TempGetAD){
        #$TempGetAD | ForEach-Object {
        #    $LastUsers += echo $_.MemberOf | ConvertTo-Html -Head $Header | Out-String
        #}
        $LastUsers += $TempGetAD | Select-Object $NomUtilisateur, $NomLogin, $creationDate | ConvertTo-Html -Head $Header | Out-String
    }
    else
    {
        $LastUsers += "<p>Pas d'utilisateurs cr&eacute;&eacute;s dans cette p&eacute;riode</p>"
    }
    }
    catch
    {
        $LastUsers += '<p style="color:red;"><b>Erreur : '+$_.Exception.Message+'</b></p>'
    }
}

##################################
#Preparing recipients of the mail#
##################################
#CSV Format
# LINE 1 User 1<user1@domain.org>
# LINE 2 User2<user2@domain.org>
# LINE 3 User 3<user3@domain.org>

$list = import-csv $tolist -Header Emails

$destMail = $list.Emails

#####################
#Send Mail to inform#
#####################
Send-MailMessage -To $destMail -From “informatique@quinoa-groupe.fr”  -Subject “Utilisateurs AD - $Jours derniers jours” -Body $LastUsers -BodyAsHtml -SmtpServer “webmail.quinoa-groupe.fr” 
$LastUsers | Out-File C:\Users\Administrateur\Documents\web.html