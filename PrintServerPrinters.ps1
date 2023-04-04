################
# Get Printers #
#####################################
function GetPrintServerPrinters{
    param (
        $ReportFileName = ".\RapportImprimante.csv", 
        # name,user,pass -> One identity per line
        $Identities = ".\Identite.csv" 
    )
# Getting list of pc to connect to
    $listePC = Import-Csv -Path $Identities -Delimiter ","
# Loop to extract data
    $allprinters = @() # Initializing global data container
    foreach( $PC in $listePC ){ 
        Write-Host "checking " $PC.name " ..." 
        $printers = $null #Clearing current printer container value
# Getting Login/password
        $pwd = ConvertTo-SecureString $PC.pass -AsPlainText -Force # Getting and hashing password
        $Identite = New-Object System.Management.Automation.PSCredential($PC.user,$pwd) # Creating Credential Object containing login/password
# Fetching Server's printers
        $printers = Get-WmiObject -class Win32_Printer -computername $PC.name -Credential $Identite | select Name,Shared,ShareName,Local, DriverName, PortName,@{n="PrinterIp";e={(((gwmi win32_tcpipprinterport -ComputerName $PC.name -filter "name='$($_.PortName)'") | select HostAddress).HostAddress)}},@{n='PrintServer';e={$_.SystemName}}, Location,Comment,SpoolEnabled,Published
        $allprinters += $printers 
    } 
# Writing gathered data to file
    Write-Host "exporting to printers.csv" 
    $allprinters | Export-CSV -Path $ReportFileName -NoTypeInformation -Force -Encoding UTF8
    Write-Host "Done!"
 }
#####################################

########
# Main #
#######################
GetPrintServerPrinters
#######################