@echo off
setlocal enabledelayedexpansion

echo.
echo ==== Conversion Windows Server Evaluation vers Definitif ====
echo.

rem Detection de l'edition actuelle - mot cle sans majuscule
for /f "tokens=2 delims=:" %%i in ('DISM /online /Get-CurrentEdition ^| findstr /i "actuelle"') do (
    set "currentEdition=%%i"
)
set "currentEdition=!currentEdition:~1!"

echo Edition actuelle detectee : !currentEdition!
echo.

rem Determine l'edition cible selon version d'evaluation
if /i "!currentEdition!"=="ServerStandardEval" (
    set "targetEdition=ServerStandard"
    set "kmsKey=N69G4-B89J2-4G8F4-WWYCC-J464C"
) else if /i "!currentEdition!"=="ServerDatacenterEval" (
    set "targetEdition=ServerDatacenter"
    set "kmsKey=WMDGN-G9PQG-XVVXX-R3X43-63DFG"
) else (
    echo Edition inconnue ou non supportee : !currentEdition!
    pause
    exit /b
)

echo Edition cible : !targetEdition!
echo.
set /p productKey=Entrez votre cle produit (laisser vide pour utiliser une cle de test generique) :

if "!productKey!"=="" (
    echo Cle generique utilisee pour test : !kmsKey!
    set "productKey=!kmsKey!"
    set "activate=no"
) else (
    set "activate=yes"
)

echo.
echo Lancement de la conversion vers !targetEdition!...
DISM /online /Set-Edition:!targetEdition! /ProductKey:!productKey! /AcceptEula

if "!activate!"=="yes" (
    echo Activation en cours...
    slmgr.vbs /ipk !productKey!
    slmgr.vbs /ato
) else (
    echo Activation ignoree (cle test).
)

echo.
echo Conversion terminee. Redemarrage recommande.
pause
