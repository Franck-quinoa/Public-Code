#==========================================================================
#
# <APPLICATION NAME>
#
# AUTHOR: <AUTHOR>
# DATE  : <DATE>
#
# COMMENT: <COMMENT>
#
# Note: see the article 'https://dennisspan.com/powershell-scripting-template-for-sccm-packages/' for a detailed description how to use this template
#
# Note: for an overview of all functions in the PowerShell function library 'DS_PowerShell_Function_Library.psm1' see:
#       -Windows functions: https://dennisspan.com/powershell-function-library/powershell-functions-for-windows/
#       -Citrix functions: https://dennisspan.com/powershell-function-library/powershell-functions-for-citrix/
#          
# Change log:
# -----------
# 29.12.2019 Dennis Span: the scope of the variables LogDir and LogFile is now set to "global". 
#                         This solves an issue when using the template in an MDT task sequence.
#==========================================================================

# Get the script parameters if there are any
param
(
    # The only parameter which is really required is 'Uninstall'
    # If no parameters are present or if the parameter is not
    # 'uninstall', an installation process is triggered
    [string]$Installationtype
)

# define Error handling
# note: do not change these values
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

############################
# Preparation              #
############################

# Disable File Security
$env:SEE_MASK_NOZONECHECKS = 1

# Custom variables [edit]
$BaseLogDir = "C:\Logs"               # [edit] add the location of your log directory here
$PackageName = "MyApp"                # [edit] enter the display name of the software (e.g. 'Acrobat Reader' or 'Microsoft Office')

# Global variables
$StartDir = $PSScriptRoot # the directory path of the script currently being executed
if (!($Installationtype -eq "Uninstall")) { $Installationtype = "Install" }
$global:LogDir = (Join-Path $BaseLogDir $PackageName).Replace(" ","_")
$LogFileName = "$($Installationtype)_$($PackageName).log"
$global:LogFile = Join-path $LogDir $LogFileName

# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }

# Create new log file (overwrite existing one)
New-Item $LogFile -ItemType "file" -force | Out-Null

# Import the Dennis Span PowerShell Function Library
Import-Module "C:\Scripts\DS_PowerShell_Function_Library.psm1"

DS_WriteLog "I" "START SCRIPT - $Installationtype $PackageName" $LogFile
DS_WriteLog "-" "" $LogFile

############################
# Pre-launch commands      #
############################

# Delete a registry value
DS_DeleteRegistryValue -RegKeyPath "hklm:\SOFTWARE\MyApp" -RegValueName "MyValue"

# Create a directory
DS_CreateDirectory -Directory "C:\Temp\MyNewFolder"

# Stop a service (+ dependencies)
DS_StopService -ServiceName "Spooler"

############################
# Installation             #
############################

# Install or uninstall software
$FileName = "MyApp.msi"                                                 # [edit] enter the name of the installation file (e.g. 'MyApp.msi' or 'setup.exe')
if ( $Installationtype -eq "Uninstall" ) {   
    $Arguments = ""                                                     # [edit] enter arguments (for MSI file the following arguments are added by default: /i #File# /qn /norestart / l*v #LogFile#)
} else {
    $Arguments = "Transforms=""MyApp.mst"" LANG_LIST=""en_US,de_DE"""   # [edit] enter arguments (for MSI file the following arguments are added by default: /i #File# /qn /norestart / l*v #LogFile#)
}
$FileSubfolder = "Files"                                                # [edit] enter the name of the subfolder which contains the installation file (e.g. 'Files' or 'MSI')
$FileFullPath = Join-Path $StartDir $FileSubfolder                      # Concatenate the two directories $StartDit and $InstallFileFolder
DS_InstallOrUninstallSoftware -File ( Join-Path $FileFullPath $FileName ) -InstallationType $Installationtype -Arguments $Arguments

############################
# Post-launch commands     #
############################

# Delete a registry key
DS_DeleteRegistryKey -RegKeyPath "hklm:\Software\MyApp"

# Start a service (+ dependencies)
DS_StartService -ServiceName "Spooler"

############################
# Finalize                 #
############################

# Enable File Security  
Remove-Item env:\SEE_MASK_NOZONECHECKS

DS_WriteLog "-" "" $LogFile
DS_WriteLog "I" "End of script" $LogFile