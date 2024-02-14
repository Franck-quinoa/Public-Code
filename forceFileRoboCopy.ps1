# Spécifiez le chemin des fichiers que vous avez
$source = "C:\\\\MesFichiers"

# Spécifiez le chemin des fichiers à remplacer
$destination = "$env:windir\\\\System32"

# Spécifiez les noms des fichiers à copier
$files = "mstsc.exe", "mstscax.dll"

# Remplacez les fichiers par ceux que vous avez
foreach ($file in $files) {
    robocopy $source $destination $file /copyall /b /r:0 /w:0
}