# Get status of rules in the group
Get-NetFirewallRule -DisplayGroup "Partage de fichiers et d’imprimantes" | Group-Object enabled | Select-Object Name | FT
if($args[0]){
#Write-Host "un paramètre ! on passe à true !"
Set-NetFirewallRule -DisplayGroup "Partage de fichiers et d’imprimantes" -Enabled True
}
else{
#Write-Host "pas de paramètre, on passe à False !"
Set-NetFirewallRule -DisplayGroup "Partage de fichiers et d’imprimantes" -Enabled False
}