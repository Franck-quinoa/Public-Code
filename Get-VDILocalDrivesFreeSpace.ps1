function Get-LocalDrives {
    param (
        $file = ".\cred.csv"
    )
    $listePC = Import-Csv -Path $file -Delimiter ","
    foreach ($PC in $listePC)
    {
        $pwd = ConvertTo-SecureString $PC.pass -AsPlainText -Force
        $Identite = New-Object System.Management.Automation.PSCredential($PC.user,$pwd)
        Invoke-Command -ComputerName $PC.name -Credential $Identite -ScriptBlock { 
            Get-WmiObject -Class win32_Logicaldisk | where {($_.DriveType -eq 3 -or $_.DriveType -eq 2) -and $_.FileSystem -ne $null -and $_.DeviceID -eq "E:" } | Select -Property @{Name = 'Volume';Expression = {$_.DeviceID -replace ":",""}}, @{Name = '%Free';Expression = { "{0:N0}%" -f (($_.FreeSpace/$_.Size) * 100) } }, @{Name = 'Go Free';Expression = {"{0:N0}Go" -f ($_.FreeSpace/1000000000)}}, @{Name = 'Total';Expression = {"{0:N0}Go" -f ($_.Size/1000000000)}}
        }
    }
}

Get-LocalDrives