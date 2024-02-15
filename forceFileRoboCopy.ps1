# Spécifiez le chemin des fichiers que vous avez
$source = "C:\\\\MesFichiers"

# Spécifiez le chemin des fichiers à remplacer
$destination = "$env:windir\\\\System32"

# Spécifiez les noms des fichiers à copier
$files = "mstsc.exe", "mstscax.dll"

# Spécifiez le nom du fichier journal
$log = "C:\\\\logs\\\\robocopy.log"

# Arrêtez tout processus contenant le terme "mstsc"
Get-Process -Name *mstsc* | Stop-Process -Force

# Remplacez les fichiers par ceux que vous avez
foreach ($file in $files) {
    robocopy $source $destination $file /copyall /b /r:0 /w:0 /log:$log /tee
}